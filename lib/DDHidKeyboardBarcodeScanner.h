/*
 * Copyright (c) 2007 Dave Dribin, Lucas Newman
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
#import <DDHidLib/DDHidDevice.h>

NS_ASSUME_NONNULL_BEGIN

@class DDHidElement;
@class DDHidQueue;
@protocol DDHidKeyboardBarcodeScannerDelegate;

@interface DDHidKeyboardBarcodeScanner : DDHidDevice
{
    @package
    NSMutableArray * mKeyElements;
    
    NSMutableString * mAccumulatedDigits;
    NSTimer *mBarcodeInputTimer;
    BOOL mIsLikelyKeyboardBarcodeScanner;
    
    id<DDHidKeyboardBarcodeScannerDelegate> mDelegate;
}

@property (readonly, copy, class, nullable) NSArray<DDHidKeyboardBarcodeScanner*> *allPossibleKeyboardBarcodeScanners;

- (nullable instancetype) initWithDevice: (io_object_t) device error: (NSError **) error_;

#pragma mark -
#pragma mark Keyboard Elements

@property (readonly, retain) NSArray<DDHidElement*> *keyElements;

@property (readonly) NSInteger numberOfKeys;

- (void) addElementsToQueue: (DDHidQueue *) queue;

#pragma mark -
#pragma mark Asynchronous Notification

@property (assign, nullable) id<DDHidKeyboardBarcodeScannerDelegate> delegate;

- (void) addElementsToDefaultQueue;

#pragma mark -
#pragma mark Properties

@property (readonly, getter=isLikelyKeyboardBarcodeScanner) BOOL likelyKeyboardBarcodeScanner;

@end

@protocol DDHidKeyboardBarcodeScannerDelegate <NSObject>

- (void) ddhidKeyboardBarcodeScanner: (DDHidKeyboardBarcodeScanner *) keyboardBarcodeScanner
                          gotBarcode: (NSString *) barcode;

@end

NS_ASSUME_NONNULL_END
