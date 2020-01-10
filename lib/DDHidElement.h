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
#include <IOKit/hid/IOHIDKeys.h>

NS_ASSUME_NONNULL_BEGIN

@class DDHidUsage;

@interface DDHidElement : NSObject
{
    @package
    IOHIDElementRef mElement;
    NSDictionary * mProperties;
    DDHidUsage * mUsage;
    NSArray * mElements;
}

+ (NSArray<DDHidElement*> *) elementsWithPropertiesArray: (NSArray<NSDictionary*> *) propertiesArray;

+ (instancetype) elementWithProperties: (NSDictionary *) properties;

- (instancetype) initWithProperties: (NSDictionary *) properties;

@property (readonly, retain) NSDictionary *properties;

- (nullable NSString *) stringForKey: (NSString *) key;

@property (readonly) IOHIDElementCookie cookie;
@property (readonly) IOHIDElementRef element;
@property (readonly) unsigned cookieAsUnsigned;

@property (readonly, retain) NSArray<DDHidElement*> *elements;
@property (readonly, retain) DDHidUsage *usage;
@property (readonly, copy) NSString *name;
@property (readonly) BOOL hasNullState;
@property (readonly) BOOL hasPreferredState;
@property (readonly, getter=isArray) BOOL array;
@property (readonly, getter=isRelative) BOOL relative;
@property (readonly, getter=isWrapping) BOOL wrapping;
@property (readonly) long maxValue;
@property (readonly) long minValue;

- (BOOL)isEqualToElement: (IOHIDElementRef)otherElem;

- (NSComparisonResult) compareByUsage: (DDHidElement *) device;

@end

NS_ASSUME_NONNULL_END
