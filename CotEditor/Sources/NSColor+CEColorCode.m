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

#import "NSColor+CEColorCode.h"


@implementation NSColor (CEColorCode)

#pragma mark Color Code

// ------------------------------------------------------
/// Creates and returns an NSColor object using the given color code or nil.
+ (NSColor *)colorWithColorCode:(NSString *)colorCode
                       codeType:(CEColorCodeType *)codeType;
// ------------------------------------------------------
{
    colorCode = [colorCode stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
    NSRange codeRange = NSMakeRange(0, [colorCode length]);
    CEColorCodeType detectedCodeType;
    
    NSDictionary *patterns = @{@(CEColorCodeHex): @"^#([0-9a-fA-F]{2})([0-9a-fA-F]{2})([0-9a-fA-F]{2})$",
                               @(CEColorCodeShortHex): @"^#([0-9a-fA-F])([0-9a-fA-F])([0-9a-fA-F])$",
                               @(CEColorCodeCSSRGB): @"^rgb\\( ?([0-9]{1,3}), ?([0-9]{1,3}), ?([0-9]{1,3})\\)$",
                               @(CEColorCodeCSSRGBa): @"^rgba\\( ?([0-9]{1,3}), ?([0-9]{1,3}), ?([0-9]{1,3}), ?([0-9.]+)\\)$",
                               @(CEColorCodeCSSHSL): @"^hsl\\( ?([0-9]{1,3}), ?([0-9.]+)%, ?([0-9.]+)%\\)$",
                               @(CEColorCodeCSSHSLa): @"^hsla\\( ?([0-9]{1,3}), ?([0-9.]+)%, ?([0-9.]+)%, ?([0-9.]+)\\)$"
                               };
    NSRegularExpression *regex;
    NSArray *matchs;
    NSTextCheckingResult *result;
    
    // detect code type
    for (NSString *key in patterns) {
        regex = [NSRegularExpression regularExpressionWithPattern:patterns[key] options:0 error:nil];
        matchs = [regex matchesInString:colorCode options:0 range:codeRange];
        if ([matchs count] == 1) {
            detectedCodeType = [key integerValue];
            result = matchs[0];
            break;
        }
    }
    
    if (!result) {
        if (codeType) {
            *codeType = CEColorCodeInvalid;
        }
        return nil;
    }
    
    // create color from result
    NSColor *color;
    switch (detectedCodeType) {
        case CEColorCodeHex: {
            unsigned int r, g, b;
            [[NSScanner scannerWithString:[colorCode substringWithRange:[result rangeAtIndex:1]]] scanHexInt:&r];
            [[NSScanner scannerWithString:[colorCode substringWithRange:[result rangeAtIndex:2]]] scanHexInt:&g];
            [[NSScanner scannerWithString:[colorCode substringWithRange:[result rangeAtIndex:3]]] scanHexInt:&b];
            color = [NSColor colorWithDeviceRed:((CGFloat)r/255) green:((CGFloat)g/255) blue:((CGFloat)b/255) alpha:1.0];
        } break;
            
        case CEColorCodeShortHex: {
            unsigned int r, g, b;
            [[NSScanner scannerWithString:[colorCode substringWithRange:[result rangeAtIndex:1]]] scanHexInt:&r];
            [[NSScanner scannerWithString:[colorCode substringWithRange:[result rangeAtIndex:2]]] scanHexInt:&g];
            [[NSScanner scannerWithString:[colorCode substringWithRange:[result rangeAtIndex:3]]] scanHexInt:&b];
            color = [NSColor colorWithDeviceRed:((CGFloat)r/15) green:((CGFloat)g/15) blue:((CGFloat)b/15) alpha:1.0];
        } break;
            
        case CEColorCodeCSSRGB: {
            CGFloat r = (CGFloat)[[colorCode substringWithRange:[result rangeAtIndex:1]] doubleValue];
            CGFloat g = (CGFloat)[[colorCode substringWithRange:[result rangeAtIndex:2]] doubleValue];
            CGFloat b = (CGFloat)[[colorCode substringWithRange:[result rangeAtIndex:3]] doubleValue];
            color = [NSColor colorWithDeviceRed:r/255 green:g/255 blue:b/255 alpha:1.0];
        } break;
            
        case CEColorCodeCSSRGBa: {
            CGFloat r = (CGFloat)[[colorCode substringWithRange:[result rangeAtIndex:1]] doubleValue];
            CGFloat g = (CGFloat)[[colorCode substringWithRange:[result rangeAtIndex:2]] doubleValue];
            CGFloat b = (CGFloat)[[colorCode substringWithRange:[result rangeAtIndex:3]] doubleValue];
            CGFloat a = (CGFloat)[[colorCode substringWithRange:[result rangeAtIndex:4]] doubleValue];
            color = [NSColor colorWithDeviceRed:r/255 green:g/255 blue:b/255 alpha:a];
        } break;
            
        case CEColorCodeCSSHSL: {
            CGFloat h = (CGFloat)[[colorCode substringWithRange:[result rangeAtIndex:1]] doubleValue];
            CGFloat s = (CGFloat)[[colorCode substringWithRange:[result rangeAtIndex:2]] doubleValue];
            CGFloat l = (CGFloat)[[colorCode substringWithRange:[result rangeAtIndex:3]] doubleValue];
            color = [NSColor colorWithDeviceHue:h/360 saturation:s/100 lightness:l/100 alpha:1.0];
        } break;
            
        case CEColorCodeCSSHSLa: {
            CGFloat h = (CGFloat)[[colorCode substringWithRange:[result rangeAtIndex:1]] doubleValue];
            CGFloat s = (CGFloat)[[colorCode substringWithRange:[result rangeAtIndex:2]] doubleValue];
            CGFloat l = (CGFloat)[[colorCode substringWithRange:[result rangeAtIndex:3]] doubleValue];
            CGFloat a = (CGFloat)[[colorCode substringWithRange:[result rangeAtIndex:4]] doubleValue];
            color = [NSColor colorWithDeviceHue:h/360 saturation:s/100 lightness:l/100 alpha:a];
        } break;
            
        default:
            color = nil;
            break;
    }
    
    if (color && codeType) {
        *codeType = detectedCodeType;
    }
    
    return color;
}


// ------------------------------------------------------
/// Returns the receiver’s color code string as desired type.
- (NSString *)colorCodeWithType:(CEColorCodeType)codeType
// ------------------------------------------------------
{
    NSString *code;
    
    int r = (int)roundf(255 * [self redComponent]);
    int g = (int)roundf(255 * [self greenComponent]);
    int b = (int)roundf(255 * [self blueComponent]);
    double alpha = (double)[self alphaComponent];
    
    switch (codeType) {
        case CEColorCodeHex:
            code = [NSString stringWithFormat:@"#%02x%02x%02x", r, g, b];
            break;
            
        case CEColorCodeShortHex:
            code = [NSString stringWithFormat:@"#%1x%1x%1x", r/16, g/16, b/16];
            break;
            
        case CEColorCodeCSSRGB:
            code = [NSString stringWithFormat:@"rgb(%d,%d,%d)", r, g, b];
            break;
            
        case CEColorCodeCSSRGBa:
            code = [NSString stringWithFormat:@"rgba(%d,%d,%d,%g)", r, g, b, alpha];
            break;
            
        case CEColorCodeCSSHSL:
        case CEColorCodeCSSHSLa: {
            CGFloat hue, saturation, lightness, alpha;
            [self getHue:&hue saturation:&saturation lightness:&lightness alpha:&alpha];
            
            int h = (int)roundf(360 * hue);
            int s = (int)roundf(100 * saturation);
            int l = (int)roundf(100 * lightness);
            
            if (codeType == CEColorCodeCSSHSLa) {
                code = [NSString stringWithFormat:@"hsla(%d,%d%%,%d%%,%g)", h, s, l, alpha];
            } else {
                code = [NSString stringWithFormat:@"hsl(%d,%d%%,%d%%)", h, s, l];
            }
        } break;
            
        case CEColorCodeInvalid:
            break;
    }
    
    return code;
}



#pragma mark HSL

// ------------------------------------------------------
/// Creates and returns an NSColor object using the given opacity and HSL components.
+ (NSColor *)colorWithDeviceHue:(CGFloat)hue
                     saturation:(CGFloat)saturation
                      lightness:(CGFloat)lightness
                          alpha:(CGFloat)alpha
// ------------------------------------------------------
{
    saturation *= (lightness < 0.5) ? lightness : 1 - lightness;
    
    return [NSColor colorWithDeviceHue:hue
                            saturation:(2 * saturation / (lightness + saturation))
                            brightness:(lightness + saturation)
                                 alpha:alpha];
}


// ------------------------------------------------------
/// Returns the receiver’s HSL component and opacity values in the respective arguments.
- (void)getHue:(CGFloat *)hue
    saturation:(CGFloat *)saturation
     lightness:(CGFloat *)lightness
         alpha:(CGFloat *)alpha
// ------------------------------------------------------
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
    if (alpha) {
        *alpha = [self alphaComponent];
    }
}

@end
