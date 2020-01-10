//
//  DDHidValue.h
//  DDHidLib
//
//  Created by C.W. Betts on 12/23/19.
//

#import <Foundation/Foundation.h>
#include <IOKit/hid/IOHIDLib.h>

NS_ASSUME_NONNULL_BEGIN
CF_IMPLICIT_BRIDGING_ENABLED

@interface DDHidValue : NSObject
{
    IOHIDValueRef mValue;
}

+ (instancetype)valueWithValue:(IOHIDValueRef CF_RELEASES_ARGUMENT) val;

- (instancetype)initWithValue:(IOHIDValueRef CF_RELEASES_ARGUMENT) val;

@property (readonly) IOHIDValueRef value;


- (IOHIDElementRef)getElement CF_RETURNS_NOT_RETAINED;

- (IOHIDElementCookie)elementCookie;
- (UInt32)elementCookieAsUnsigned;

@property (readonly) uint64_t timeStamp;

@property (readonly) NSInteger length;

- (const uint8_t *)bytePtr;

@property (readonly) NSInteger integerValue;

- (double_t)scaledValueWithType:(IOHIDValueScaleType)type;

@end

CF_IMPLICIT_BRIDGING_DISABLED
NS_ASSUME_NONNULL_END
