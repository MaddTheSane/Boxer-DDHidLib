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

#import <Cocoa/Cocoa.h>
#include <IOKit/IOKitLib.h>
#include <IOKit/IOCFPlugIn.h>
#include <IOKit/hid/IOHIDLib.h>
#include <IOKit/hid/IOHIDKeys.h>

NS_ASSUME_NONNULL_BEGIN

@class DDHidUsage;
@class DDHidElement;
@class DDHidQueue;

@interface DDHidDevice : NSObject
{
    @package
    io_object_t mHidDevice;
	IOHIDDeviceInterface122** mDeviceInterface;

    NSMutableDictionary<NSString*,id> * mProperties;
    DDHidUsage * mPrimaryUsage;
    NSMutableArray<DDHidUsage*> * mUsages;
    NSArray<DDHidElement*> * mElements;
    NSMutableDictionary * mElementsByCookie;
    BOOL mListenInExclusiveMode;
    DDHidQueue * mDefaultQueue;
    int mTag;
    int mLogicalDeviceNumber;
}

- (nullable instancetype) initWithDevice: (io_object_t) device error: (NSError **) error;
- (nullable instancetype) initLogicalWithDevice: (io_object_t) device
                            logicalDeviceNumber: (int) logicalDeviceNumber
                                          error: (NSError **) error;
@property (readonly) NSInteger logicalDeviceCount;

#pragma mark -
#pragma mark Finding Devices

@property (readonly, copy, class, nullable) NSArray<DDHidDevice*> *allDevices;

+ (nullable NSArray<DDHidDevice*> *) allDevicesMatchingUsagePage: (unsigned) usagePage
                                                         usageId: (unsigned) usageId
                                                       withClass: (Class) hidClass
                                               skipZeroLocations: (BOOL) emptyLocation;

+ (nullable NSArray<DDHidDevice*> *) allDevicesMatchingCFDictionary: (CF_RELEASES_ARGUMENT CFDictionaryRef) matchDictionary
                                                          withClass: (Class) hidClass
                                                  skipZeroLocations: (BOOL) emptyLocation;

#pragma mark -
#pragma mark I/O Kit Objects

@property (readonly) io_object_t ioDevice;
@property (readonly) IOHIDDeviceInterface122*__nonnull*__nonnull deviceInterface;

#pragma mark -
#pragma mark Operations

- (void) open;
- (void) openWithOptions: (IOOptionBits) options;
- (void) close;
- (nullable DDHidQueue *) createQueueWithSize: (unsigned) size;
- (long) getElementValue: (DDHidElement *) element;

#pragma mark -
#pragma mark Asynchronous Notification

@property BOOL listenInExclusiveMode;

- (void) startListening;

- (void) stopListening;

@property (readonly, getter=isListening) BOOL listening;

#pragma mark -
#pragma mark Properties

@property (readonly, retain) NSDictionary<NSString*,id> *properties;

@property (readonly, retain) NSArray<DDHidElement*> *elements;
- (nullable DDHidElement *) elementForCookie: (IOHIDElementCookie) cookie;

@property (readonly, copy) NSString *productName;
@property (readonly, copy) NSString *manufacturer;
@property (readonly, copy) NSString *serialNumber;
@property (readonly, copy) NSString *transport;
@property (readonly) long vendorId;
@property (readonly) long productId;
@property (readonly) long version;
@property (readonly) long locationId;
@property (readonly) long usagePage;
@property (readonly) long usage;
@property (readonly, retain) DDHidUsage *primaryUsage;
@property (readonly, copy) NSArray<DDHidUsage*> *usages;

- (NSComparisonResult) compareByLocationId: (DDHidDevice *) device;

@property int tag;

@end

@interface DDHidDevice (Protected)

- (unsigned) sizeOfDefaultQueue;
- (void) addElementsToDefaultQueue;

@end

NS_ASSUME_NONNULL_END
