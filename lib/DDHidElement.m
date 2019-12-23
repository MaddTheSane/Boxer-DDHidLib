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

#import "DDHidElement.h"
#import "DDHidUsage.h"
#import "NSDictionary+DDHidExtras.h"
#include <IOKit/hid/IOHIDKeys.h>

@implementation DDHidElement

+ (NSArray *) elementsWithPropertiesArray: (NSArray *) propertiesArray;
{
    if(!propertiesArray) return nil;
    if(![propertiesArray isKindOfClass:[NSArray class]]) propertiesArray = @[propertiesArray];

    NSMutableArray * elements = [NSMutableArray array];
    
    for (NSDictionary *properties in propertiesArray)
    {
        DDHidElement * element = [DDHidElement elementWithProperties: properties];
        [elements addObject: element];
    }
    
    return elements;
}

+ (DDHidElement *) elementWithProperties: (NSDictionary *) properties;
{
    DDHidElement * element = [[DDHidElement alloc] initWithProperties: properties];
    return element;
}

- (id) initWithProperties: (NSDictionary *) properties;
{
    self = [super init];
    if (self == nil)
        return nil;
    
    mElement = IOHIDElementCreateWithDictionary(NULL, (__bridge CFDictionaryRef)properties);
    mProperties = [properties copy];
    unsigned usagePage = [properties ddhid_unsignedIntForString: kIOHIDElementUsagePageKey];
    unsigned usageId = [properties ddhid_unsignedIntForString: kIOHIDElementUsageKey];
    mUsage = [[DDHidUsage alloc] initWithUsagePage: usagePage
                                           usageId: usageId];
    
    NSArray * elementsProperties =
        [mProperties ddhid_objectForString: kIOHIDElementKey];
    mElements = [DDHidElement elementsWithPropertiesArray: elementsProperties];

    return self;
}

//=========================================================== 
// dealloc
//=========================================================== 
- (void) dealloc
{
    CFRelease(mElement);
}

- (NSDictionary *) properties;
{
    return mProperties;
}

- (NSString *) stringForKey: (NSString *) key;
{
    return [mProperties objectForKey: key];
}

- (NSString *) description;
{
    return [[self usage] usageNameWithIds];
}

- (IOHIDElementCookie) cookie;
{
    return IOHIDElementGetCookie(mElement);
}

@synthesize element=mElement;

- (unsigned) cookieAsUnsigned;
{
    return [mProperties ddhid_unsignedIntForString: kIOHIDElementCookieKey];
}

@synthesize usage = mUsage;

- (NSArray *) elements;
{
    return mElements;
}

- (NSString *) name;
{
    return (__bridge id)IOHIDElementGetName(mElement);
}

- (BOOL) hasNullState;
{
    return IOHIDElementHasNullState(mElement);
}

- (BOOL) hasPreferredState;
{
    return IOHIDElementHasPreferredState(mElement);
}

- (BOOL) isArray;
{
    return IOHIDElementIsArray(mElement);
}

- (BOOL) isRelative;
{
    return IOHIDElementIsRelative(mElement);
}

- (BOOL) isWrapping;
{
    return IOHIDElementIsWrapping(mElement);
}

- (long) maxValue;
{
    return [mProperties ddhid_longForString: kIOHIDElementMaxKey];
}

- (long) minValue;
{
    return [mProperties ddhid_longForString: kIOHIDElementMinKey];
}

- (NSComparisonResult) compareByUsage: (DDHidElement *) device;
{
    unsigned myUsagePage = [[self usage] usagePage];
    unsigned myUsageId = [[self usage] usageId];

    unsigned otherUsagePage = [[device usage] usagePage];
    unsigned otherUsageId = [[device usage] usageId];

    if (myUsagePage < otherUsagePage)
        return NSOrderedAscending;
    else if (myUsagePage > otherUsagePage)
        return NSOrderedDescending;
    
    if (myUsageId < otherUsageId)
        return NSOrderedAscending;
    else if (myUsageId > otherUsageId)
        return NSOrderedDescending;

    return NSOrderedSame;
}

@end
