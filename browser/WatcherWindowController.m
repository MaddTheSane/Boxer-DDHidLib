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

#import "WatcherWindowController.h"
#import <DDHidLib/DDHidQueue.h>
#import <DDHidLib/DDHidEvent.h>
#import <DDHidLib/DDHidUsage.h>

@interface WatcherEvent : NSObject
{
    NSString * mUsageDescription;
    DDHidEvent * mEvent;
    int mIndex;
}

- (id) initWithUsageDescription: (NSString *) anUsageDecription 
                          event: (DDHidEvent *) anEvent
                          index: (int) index;

@property (readonly, copy) NSString *usageDescription;
@property (readonly, retain) DDHidEvent *event;
@property (readonly) int index;

@end

@implementation WatcherEvent : NSObject

- (id) initWithUsageDescription: (NSString *) anUsageDescription 
                          event: (DDHidEvent *) anEvent
                          index: (int) index
{
    if (self = [super init])
    {
        mUsageDescription = [anUsageDescription copy];
        mEvent = [anEvent retain];
        mIndex = index;
    }
    return self;
}

//=========================================================== 
// dealloc
//=========================================================== 
- (void) dealloc
{
    [mUsageDescription release];
    [mEvent release];
    
    mUsageDescription = nil;
    mEvent = nil;
    [super dealloc];
}

//=========================================================== 
// - usageDescription
//=========================================================== 
@synthesize usageDescription=mUsageDescription;

//=========================================================== 
// - event
//=========================================================== 
@synthesize event=mEvent;

//=========================================================== 
// - index
//=========================================================== 
@synthesize index=mIndex;

@end

@interface WatcherWindowController () <DDHidQueueDelegate>

@end

@implementation WatcherWindowController

- (id) init
{
    self = [super initWithWindowNibName: @"EventWatcher" owner: self];
    if (self == nil)
        return nil;
    
    mEventHistory = [[NSMutableArray alloc] init];
    mNextIndex = 1;
    
    return self;
}


//=========================================================== 
// dealloc
//=========================================================== 
- (void) dealloc
{
    [mQueue release];
    [mDevice release];
    [mElements release];
    [mEventHistory release];
    
    mQueue = nil;
    mDevice = nil;
    mElements = nil;
    mEventHistory = nil;
    [super dealloc];
}

- (void)windowWillClose:(NSNotification *)notification
{
    [mQueue release];
    mQueue = nil;
    [mDevice close];
    [self autorelease];
}

- (IBAction)showWindow:(id)sender
{
    [super showWindow: sender];
}

- (void) ddhidQueueHasEvents: (DDHidQueue *) hidQueue;
{
    WatcherEvent * watcherEvent;
    watcherEvent =
        [[WatcherEvent alloc] initWithUsageDescription: @"-----------------------------"
                                                 event: nil
                                                 index: mNextIndex++];
    [watcherEvent autorelease];
    [mEventHistoryController addObject: watcherEvent];

    NSMutableArray * newEvents = [NSMutableArray array];
    DDHidEvent * event;
    while ((event = [hidQueue nextEvent]))
    {
        DDHidElement * element = [mDevice elementForCookie: [event elementCookie]];
        watcherEvent =
            [[WatcherEvent alloc] initWithUsageDescription: [[element usage] usageNameWithIds]
                                                     event: event
                                                     index: mNextIndex++];
        [watcherEvent autorelease];
        [newEvents addObject: watcherEvent];
    }
    
    [mEventHistoryController addObjects: newEvents];
}

- (void) windowDidLoad;
{
    [mDevice open];
    mQueue = [[mDevice createQueueWithSize: 30] retain];
    [mQueue setDelegate: self];
    [mQueue addElements: mElements];
    [self willChangeValueForKey: @"watching"];
    [mQueue startOnCurrentRunLoop];
    [self didChangeValueForKey: @"watching"];
}

//=========================================================== 
//  device 
//=========================================================== 
@synthesize device=mDevice;

//=========================================================== 
//  elements 
//=========================================================== 
@synthesize elements=mElements;

//=========================================================== 
//  eventHistory 
//=========================================================== 
@synthesize eventHistory=mEventHistory;
- (void) addToEventHistory: (id)mEventHistoryObject
{
    [[self eventHistory] addObject: mEventHistoryObject];
}
- (void) removeFromEventHistory: (id)mEventHistoryObject
{
    [[self eventHistory] removeObject: mEventHistoryObject];
}

- (BOOL) isWatching;
{
    if (mQueue == nil)
        return NO;
    return [mQueue isStarted];
}

- (void) setWatching: (BOOL) watching;
{
    BOOL isStarted = [mQueue isStarted];
    if (isStarted == watching)
        return;
    
    if (watching)
        [mQueue startOnCurrentRunLoop];
    else
        [mQueue stop];
}

- (IBAction) clearHistory: (id) sender;
{
    [self willChangeValueForKey: @"eventHistory"];
    [mEventHistory removeAllObjects];
    mNextIndex = 1;
    [self didChangeValueForKey: @"eventHistory"];
}

@end
