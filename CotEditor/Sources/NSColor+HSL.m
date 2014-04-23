//
//  NSColor+HSL.h
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

#import "NSColor+HSL.h"


@implementation NSColor (HSL)

+ (NSColor *)colorWithDeviceHue:(CGFloat)hue
                     saturation:(CGFloat)saturation
                      lightness:(CGFloat)lightness
                          alpha:(CGFloat)alpha
{
    saturation *= (lightness < 0.5) ? lightness : 1 - lightness;
    
    return [NSColor colorWithHue:hue
                      saturation:(2 * saturation / (lightness + saturation))
                      brightness:(lightness + saturation)
                           alpha:alpha];
}


- (void)getHue:(CGFloat *)hue
    saturation:(CGFloat *)saturation
     lightness:(CGFloat *)lightness
         alpha:(CGFloat *)alpha
{
    CGFloat max = MAX(MAX([self redComponent], [self greenComponent]), [self blueComponent]);
    CGFloat min = MIN(MIN([self redComponent], [self greenComponent]), [self blueComponent]);
    CGFloat d = max - min;
    
    CGFloat l = (max + min) / 2;
    if (isnan(l)) { l = 0; }
    CGFloat s = (l > 0.5) ? d / (2 - max - min) : d / (max + min);
    if (isnan(s) || ([self saturationComponent] < 0.00001 && [self brightnessComponent] < 9.9999)) {
        s = 0;
    }
    
    *hue = (s == 0) ? 0 : [self hueComponent];
    *saturation = s;
    *lightness = l;
    *alpha = [self alphaComponent];
}

@end
