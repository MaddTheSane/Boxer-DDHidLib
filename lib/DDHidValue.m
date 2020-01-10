//
//  DDHidValue.m
//  DDHidLib
//
//  Created by C.W. Betts on 12/23/19.
//

#import "DDHidValue.h"

@implementation DDHidValue

@synthesize value=mValue;

- (instancetype)initWithValue:(IOHIDValueRef) val
{
    if (self = [super init]) {
        mValue=val;
    }
    return self;
}

+ (instancetype)valueWithValue:(IOHIDValueRef CF_RELEASES_ARGUMENT) val
{
    return [[self alloc] initWithValue:val];
}

- (IOHIDElementRef)getElement
{
    return IOHIDValueGetElement(mValue);
}

- (IOHIDElementCookie)elementCookie
{
    return IOHIDElementGetCookie([self getElement]);
}

- (UInt32)elementCookieAsUnsigned;
{
    return (UInt32)[self elementCookie];
}

- (uint64_t)timeStamp
{
    return IOHIDValueGetTimeStamp(mValue);
}

- (NSInteger)length
{
    return IOHIDValueGetLength(mValue);
}

- (const uint8_t *)bytePtr
{
    return IOHIDValueGetBytePtr(mValue);
}

- (NSInteger)integerValue
{
    return IOHIDValueGetIntegerValue(mValue);
}

- (void)dealloc
{
    CFRelease(mValue);
}

- (double_t)scaledValueWithType:(IOHIDValueScaleType)type
{
    return IOHIDValueGetScaledValue(mValue, type);
}

@end
