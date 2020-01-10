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

#import "DDHidQueue.h"
#import "DDHidElement.h"
#import "NSXReturnThrowError.h"
#import "DDHidValue.h"

static void queueCallbackFunction(void* target,  IOReturn result,
                                  void* sender);

@interface DDHidQueue ()

- (void) handleQueueCallback;

@end

@implementation DDHidQueue
@synthesize delegate = mDelegate;
@synthesize started = mStarted;

- (id) initWithHIDQueue: (IOHIDQueueRef) queue
                   size: (unsigned) size;
{
    self = [super init];
    if (self == nil)
        return nil;
    
    mQueue = queue;
     
    return self;
}

- (void) dealloc;
{
    [self stop];
    CFRelease(mQueue);
}

- (void) addElement: (DDHidElement *) element;
{
    IOHIDQueueAddElement(mQueue, element.element);
}

- (void) addElements: (NSArray *) elements;
{
    return [self addElements: elements recursively: NO];
}

- (void) addElements: (NSArray *) elements recursively: (BOOL) recursively;
{
    for (DDHidElement *element in elements)
    {
        [self addElement: element];
        if (recursively)
            [self addElements: [element elements]];
    }
}

- (void) startOnCurrentRunLoop;
{
    [self startOnRunLoop: [NSRunLoop currentRunLoop]];
}

- (void) startOnRunLoop: (NSRunLoop *) runLoop;
{
    if (mStarted)
        return;
    
    mRunLoop = runLoop;
    
    IOHIDQueueScheduleWithRunLoop(mQueue, [mRunLoop getCFRunLoop], kCFRunLoopDefaultMode);
    IOHIDQueueRegisterValueAvailableCallback(mQueue, queueCallbackFunction, (__bridge void * _Nullable)(self));
    IOHIDQueueStart(mQueue);
    mStarted = YES;
}

- (void) stop;
{
    if (!mStarted)
        return;
    
    IOHIDQueueStop(mQueue);
    IOHIDQueueUnscheduleFromRunLoop(mQueue, mRunLoop.getCFRunLoop, kCFRunLoopDefaultMode);
    
    mRunLoop = nil;
    mStarted = NO;
}

- (DDHidValue*) nextValue;
{
    IOHIDValueRef val = IOHIDQueueCopyNextValue(mQueue);
    if (val) {
        return [DDHidValue valueWithValue:val];
    } else {
    return NULL;
    }
}

- (void) handleQueueCallback;
{
    if ([mDelegate respondsToSelector: @selector(ddhidQueueHasEvents:)])
    {
        [mDelegate ddhidQueueHasEvents: self];
    }
}

@end

static void queueCallbackFunction(void* target,  IOReturn result,
                                  void* sender)
{
    @autoreleasepool {
        DDHidQueue * queue = (__bridge DDHidQueue *) target;
        [queue handleQueueCallback];
    }
}
