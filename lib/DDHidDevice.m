/*
 * Copyright (c) 2007 Dave Dribin
 * 
 * Permission is hereby granted, free of charge, to any person
 * obtaining a copy of this software and associated documentation
 * files (the "Software"), to deal in the Software without
 * restriction, including without limitation the rights to use, copy,
 * modify, merge, publish, distribute, sublicense, and/or sell copies
 * of the Software, and to permit persons to whom the Software is
 * furnished to do so, subject to the following conditions:
 * 
 * The above copyright notice and this permission notice shall be
 * included in all copies or substantial portions of the Software.
 *
 * THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
 * EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
 * MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
 * NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS
 * BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN
 * ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN
 * CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
 * SOFTWARE.
 */

#import "DDHidDevice.h"
#import "DDHidUsage.h"
#import "DDHidElement.h"
#import "DDHidQueue.h"
#import "NSDictionary+DDHidExtras.h"
#import "NSXReturnThrowError.h"

#include <IOKit/hid/IOHIDUsageTables.h>

@interface DDHidDevice () <DDHidQueueDelegate>

+ (void) addDevice: (io_object_t) hidDevice
         withClass: (Class) hidClass
 skipZeroLocations: (BOOL) skipZeroLocations
      toDeviceList: (NSMutableArray *) devices;

- (BOOL) initPropertiesWithError: (NSError **) error_;
- (BOOL) createDeviceInterfaceWithError: (NSError **) error_;

@end

@implementation DDHidDevice

- (id) initWithDevice: (io_object_t) device error: (NSError **) error;
{
    return [self initLogicalWithDevice: device
                   logicalDeviceNumber: 0
                                 error: error];
}

- (id) initLogicalWithDevice: (io_object_t) device
         logicalDeviceNumber: (int) logicalDeviceNumber
                       error: (NSError **) error;
{
    self = [super init];
    if (self == nil)
        return nil;
    
    mHidDevice = device;
    IOObjectRetain(mHidDevice);
 
    if (![self initPropertiesWithError: error])
    {
        return nil;
    }
    
    if (![self createDeviceInterfaceWithError: error])
    {
        return nil;
    }
    
    mLogicalDeviceNumber = logicalDeviceNumber;
    mListenInExclusiveMode = NO;
    mDefaultQueue = nil;
    mTag = 0;
	
    return self;
}

//=========================================================== 
// dealloc
//=========================================================== 
- (void) dealloc
{
    CFRelease(mDeviceRef);
    IOObjectRelease(mHidDevice);
    
    mProperties = nil;
}

#pragma mark -
#pragma mark Finding Devices

+ (NSArray *) allDevices;
{
	// Set up a matching dictionary to search the I/O Registry by class
	// name for all HID class devices
	CFMutableDictionaryRef hidMatchDictionary =
        IOServiceMatching(kIOHIDDeviceKey);
    NSArray *retVal = nil;
    if(hidMatchDictionary) {
        retVal = [self allDevicesMatchingCFDictionary: hidMatchDictionary
                                      withClass: [DDHidDevice class]
                              skipZeroLocations: NO];
        //CFRelease(hidMatchDictionary);//dont free, it is freed by IOServiceGetMatchingServices
    }
    return retVal ? [NSArray arrayWithArray:retVal] : nil;
}

+ (NSArray *) allDevicesMatchingUsagePage: (unsigned) usagePage
                                  usageId: (unsigned) usageId
                                withClass: (Class) hidClass
                        skipZeroLocations: (BOOL) skipZeroLocations;
{
	// Set up a matching dictionary to search the I/O Registry by class
	// name for all HID class devices
	CFMutableDictionaryRef hidMatchDictionary =
        IOServiceMatching(kIOHIDDeviceKey);
    NSArray *retVal = nil;
    if(hidMatchDictionary) {
        NSMutableDictionary * objcMatchDictionary =
            (__bridge NSMutableDictionary *) hidMatchDictionary;
        [objcMatchDictionary ddhid_setObject: @(usagePage)
                                   forString: kIOHIDDeviceUsagePageKey];
        [objcMatchDictionary ddhid_setObject: @(usageId)
                                   forString: kIOHIDDeviceUsageKey];
        retVal = [self allDevicesMatchingCFDictionary: hidMatchDictionary
                                          withClass: hidClass
                                  skipZeroLocations: skipZeroLocations];
        //CFRelease(hidMatchDictionary);//dont free, it is freed by IOServiceGetMatchingServices
    }
    return retVal ? [NSArray arrayWithArray:retVal] : nil;
}

+ (NSArray *) allDevicesMatchingCFDictionary: (CFDictionaryRef) matchDictionary
                                   withClass: (Class) hidClass
                           skipZeroLocations: (BOOL) skipZeroLocations;
{
	// Now search I/O Registry for matching devices.
	io_iterator_t hidObjectIterator = MACH_PORT_NULL;
    NSMutableArray * devices = [NSMutableArray array];
    @try
    {
        NSXThrowError(IOServiceGetMatchingServices(kIOMasterPortDefault,
                                                   matchDictionary,
                                                   &hidObjectIterator));
        
        if (hidObjectIterator == 0)
            return [NSArray array];
        
        io_object_t hidDevice;
        while ((hidDevice = IOIteratorNext(hidObjectIterator)))
        {
            [self addDevice: hidDevice
                  withClass: hidClass
          skipZeroLocations: skipZeroLocations
               toDeviceList: devices];
        }
        
        // This makes sure the array return is consistent from run to run, 
        // assuming no new devices were added.
        [devices sortUsingSelector: @selector(compareByLocationId:)];
    }
    @finally
    {
        if (hidObjectIterator != MACH_PORT_NULL)
            IOObjectRelease(hidObjectIterator);
    }
    
    return [NSArray arrayWithArray:devices];
}

- (NSInteger) logicalDeviceCount;
{
    return 1;
}

#pragma mark -
#pragma mark I/O Kit Objects

@synthesize ioDevice = mHidDevice;

- (IOHIDDeviceRef) deviceRef;
{
    return mDeviceRef;
}

#pragma mark -
#pragma mark Operations

- (void) open;
{
    [self openWithOptions: kIOHIDOptionsTypeNone];
}

- (void) openWithOptions: (IOOptionBits) options;
{
    NSXThrowError(IOHIDDeviceOpen(mDeviceRef, options));
}

- (void) close;
{
    [self closeWithOptions:kIOHIDOptionsTypeNone];
}

- (void) closeWithOptions:(IOOptionBits)options;
{
    NSXThrowError(IOHIDDeviceClose(mDeviceRef, options));
}


- (DDHidQueue *) createQueueWithSize: (unsigned) size;
{
    IOHIDQueueRef queue = IOHIDQueueCreate(NULL, mDeviceRef, size, 0);
    if (queue == NULL)
        return nil;
    return [[DDHidQueue alloc] initWithHIDQueue: queue
                                           size: size];
}

- (long) getElementValue: (DDHidElement *) element;
{
    IOHIDValueRef theVal;
    NSXThrowError(IOHIDDeviceGetValue(mDeviceRef, element.element, &theVal));
    
    return IOHIDValueGetIntegerValue(theVal);
}

#pragma mark -
#pragma mark Asynchronous Notification

//=========================================================== 
//  listenInExclusiveMode 
//=========================================================== 
@synthesize listenInExclusiveMode = mListenInExclusiveMode;

- (void) startListening;
{
    if ([self isListening])
        return;
    
    UInt32 options = kIOHIDOptionsTypeNone;
    if (mListenInExclusiveMode)
        options = kIOHIDOptionsTypeSeizeDevice;
    [self openWithOptions: options];
    mDefaultQueue = [self createQueueWithSize: [self sizeOfDefaultQueue]];
    [mDefaultQueue setDelegate: self];
    [self addElementsToDefaultQueue];
    [mDefaultQueue startOnCurrentRunLoop];
}

- (void) stopListening;
{
    if (![self isListening])
        return;
    
    [mDefaultQueue stop];
    mDefaultQueue = nil;
    [self close];
}

- (BOOL) isListening;
{
    return (mDefaultQueue != nil);
}

#pragma mark -
#pragma mark Properties

- (NSDictionary *) properties;
{
    return mProperties;
}

//=========================================================== 
// - productName
//=========================================================== 
- (NSString *) productName
{
    NSString * productName = [mProperties ddhid_stringForString: kIOHIDProductKey];
    if ([self logicalDeviceCount] > 1)
    {
        productName = [productName stringByAppendingString:
                       [NSString stringWithFormat:@" #%d", mLogicalDeviceNumber + 1]];
    }
    return productName;
}

//=========================================================== 
// - manufacturer
//=========================================================== 
- (NSString *) manufacturer
{
    return [mProperties ddhid_stringForString: kIOHIDManufacturerKey];
}

//=========================================================== 
// - serialNumber
//=========================================================== 
- (NSString *) serialNumber
{
    return [mProperties ddhid_stringForString: kIOHIDSerialNumberKey];
}

//=========================================================== 
// - transport
//=========================================================== 
- (NSString *) transport
{
    return [mProperties ddhid_stringForString: kIOHIDTransportKey];
}

//=========================================================== 
// - vendorId
//=========================================================== 
- (long) vendorId
{
    return [mProperties ddhid_longForString: kIOHIDVendorIDKey];
}

//=========================================================== 
// - productId
//=========================================================== 
- (long) productId
{
    return [mProperties ddhid_longForString: kIOHIDProductIDKey];
}

//=========================================================== 
// - version
//=========================================================== 
- (long) version
{
    return [mProperties ddhid_longForString: kIOHIDVersionNumberKey];
}

//=========================================================== 
// - locationId
//=========================================================== 
- (long) locationId
{
    return [mProperties ddhid_longForString: kIOHIDLocationIDKey];
}

//=========================================================== 
// - usagePage
//=========================================================== 
- (long) usagePage
{
    return [mProperties ddhid_longForString: kIOHIDPrimaryUsagePageKey];
}

//=========================================================== 
// - usage
//=========================================================== 
- (long) usage
{
    return [mProperties ddhid_longForString: kIOHIDPrimaryUsageKey];
}

- (NSArray *) elements;
{
    return mElements;
}

- (DDHidElement *) elementForCookie: (IOHIDElementCookie) cookie;
{
    NSNumber * n = [NSNumber numberWithUnsignedInt: (unsigned) cookie];
    return [mElementsByCookie objectForKey: n];
}

- (DDHidUsage *) primaryUsage;
{
    return mPrimaryUsage;
}

- (NSArray *) usages;
{
    return mUsages;
}

- (NSComparisonResult) compareByLocationId: (DDHidDevice *) device;
{
    long myLocationId = [self locationId];
    long otherLocationId = [device locationId];
    if (myLocationId < otherLocationId)
        return NSOrderedAscending;
    else if (myLocationId > otherLocationId)
        return NSOrderedDescending;
    else
        return NSOrderedSame;
}

//=========================================================== 
//  tag 
//===========================================================
@synthesize tag = mTag;

+ (void) addDevice: (io_object_t) hidDevice
         withClass: (Class) hidClass
 skipZeroLocations: (BOOL) skipZeroLocations
      toDeviceList: (NSMutableArray *) devices;
{
    @try
    {
        NSError * error = nil;
        DDHidDevice * device = [[hidClass alloc] initWithDevice: hidDevice
                                                          error: &error];
        if (device == nil)
        {
            NSXRaiseError(error);
        }
        
        if (([device locationId] == 0) && skipZeroLocations)
            return;
        
        [devices addObject: device];

        // Add remainnig logical devices
        int i;
        for (i = 1; i < [device logicalDeviceCount]; i++)
        {
            device = [[hidClass alloc] initLogicalWithDevice: hidDevice
                                         logicalDeviceNumber: i
                                                       error: &error];
            
            if (device == nil)
            {
                NSXRaiseError(error);
            }
            
            [devices addObject: device];
        }
    }
    @finally
    {
        IOObjectRelease(hidDevice);
    }
}

- (void) indexElements: (NSArray *) elements;
{
    NSEnumerator * e = [elements objectEnumerator];
    DDHidElement * element;
    while (element = [e nextObject])
    {
        NSNumber * n = [NSNumber numberWithUnsignedInt: [element cookieAsUnsigned]];
        [mElementsByCookie setObject: element
                              forKey: n];
        NSArray * children = [element elements];
        if (children != nil)
            [self indexElements: children];
    }
}

- (BOOL) initPropertiesWithError: (NSError **) error_;
{
    NSError * error = nil;
    BOOL result = NO;
    NSArray * elementProperties;
    CFMutableDictionaryRef properties;
    NSArray * usagePairs;
    NSXReturnError(IORegistryEntryCreateCFProperties(mHidDevice, &properties,
                                                     kCFAllocatorDefault, kNilOptions));
    if (error)
        goto done;
    
    mProperties = (NSMutableDictionary *) CFBridgingRelease(properties);
    elementProperties = [mProperties ddhid_objectForString: kIOHIDElementKey];
    mElements = [DDHidElement elementsWithPropertiesArray: elementProperties];
    
    unsigned usagePage = [mProperties ddhid_unsignedIntForString: kIOHIDPrimaryUsagePageKey];
    unsigned usageId = [mProperties ddhid_unsignedIntForString: kIOHIDPrimaryUsageKey];
    
    mPrimaryUsage = [[DDHidUsage alloc] initWithUsagePage: usagePage
                                                  usageId: usageId];
    mUsages = [[NSMutableArray alloc] init];
    
    usagePairs = [mProperties ddhid_objectForString: kIOHIDDeviceUsagePairsKey];
    for (NSDictionary * usagePair in usagePairs)
    {
        usagePage = [usagePair ddhid_unsignedIntForString: kIOHIDDeviceUsagePageKey];
        usageId = [usagePair ddhid_unsignedIntForString: kIOHIDDeviceUsageKey];
        DDHidUsage * usage = [DDHidUsage usageWithUsagePage: usagePage
                                                    usageId: usageId];
        [mUsages addObject: usage];
    }
    
    mElementsByCookie = [[NSMutableDictionary alloc] init];
    [self indexElements: mElements];
    result = YES;
    
done:
        if (error_)
            *error_ = error;
    return result;
}

- (BOOL) createDeviceInterfaceWithError: (NSError **) error_;
{
	io_name_t className;
    NSError * error = nil;
    BOOL result = NO;
	
	mDeviceRef = NULL;
	
	NSXReturnError(IOObjectGetClass(mHidDevice, className));
    if (error)
        goto done;
    
    //Call a method of the intermediate plug-in to create the device interface
    mDeviceRef = IOHIDDeviceCreate(NULL, mHidDevice);
    if (!mDeviceRef) {
        error = [NSError errorWithDomain:NSCocoaErrorDomain code:-1 userInfo:nil];
    }
    if (error)
        goto done;
    
    result = YES;
    
done:
    if (error_)
        *error_ = error;
	return result;
}

@end

@implementation DDHidDevice (Protected)

- (unsigned) sizeOfDefaultQueue;
{
    return 10;
}

- (void) addElementsToDefaultQueue;
{
    [mDefaultQueue addElements: [self elements] recursively: YES];
}

@end
