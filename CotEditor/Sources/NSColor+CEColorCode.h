//
//  NSColor+CEColorCode.h
//
//  Created by 1024jp on 2014-04-22.

/*
 The MIT License (MIT)
 
 Copyright (c) 2014 1024jp
 
 Permission is hereby granted, free of charge, to any person obtaining a copy
 of this software and associated documentation files (the "Software"), to deal
 in the Software without restriction, including without limitation the rights
 to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
 copies of the Software, and to permit persons to whom the Software is
 furnished to do so, subject to the following conditions:
 
 The above copyright notice and this permission notice shall be included in
 all copies or substantial portions of the Software.
 
 THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
 AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
 OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
 THE SOFTWARE.
 */

#import <Cocoa/Cocoa.h>


@interface NSColor (CEColorCode)

#pragma mark Color Code

/// color code type
typedef NS_ENUM(NSUInteger, CEColorCodeType) {
    CEColorCodeInvalid,   // nil
    CEColorCodeHex,       // #ffffff
    CEColorCodeShortHex,  // #fff
    CEColorCodeCSSRGB,       // rgb(255,255,255)
    CEColorCodeCSSRGBa,      // rgba(255,255,255,1)
    CEColorCodeCSSHSL,       // hsl(0,0%,100%)
    CEColorCodeCSSHSLa       // hsla(0,0%,100%,1)
};

/// Creates and returns an NSColor object using the given color code. Or returns nil if color code is invalid.
+ (NSColor *)colorWithColorCode:(NSString *)colorCode codeType:(CEColorCodeType *)codeType;

/// Returns the receiver’s color code in desired type.
/// This method works only with objects representing colors in the NSCalibratedRGBColorSpace or NSDeviceRGBColorSpace color space. Sending it to other objects raises an exception.
- (NSString *)colorCodeWithType:(CEColorCodeType)codeType;



# pragma mark HSL

/// Creates and returns an NSColor object using the given opacity and HSL components.
/// Values below 0.0 are interpreted as 0.0, and values above 1.0 are interpreted as 1.0.
+ (NSColor *)colorWithDeviceHue:(CGFloat)hue saturation:(CGFloat)saturation lightness:(CGFloat)lightness alpha:(CGFloat)alpha;

/// Returns the receiver’s HSL component and opacity values in the respective arguments.
/// This method works only with objects representing colors in the NSCalibratedRGBColorSpace or NSDeviceRGBColorSpace color space. Sending it to other objects raises an exception.
- (void)getHue:(CGFloat *)hue saturation:(CGFloat *)saturation lightness:(CGFloat *)lightness alpha:(CGFloat *)alpha;

@end
