/*
 
 CEColorHexTransformer.m
 
 CotEditor
 http://coteditor.com
 
 Created by 1024jp on 2014-09-12.
 
 ------------------------------------------------------------------------------
 
 © 2014-2015 1024jp
 
 Licensed under the Apache License, Version 2.0 (the "License");
 you may not use this file except in compliance with the License.
 You may obtain a copy of the License at
 
 http://www.apache.org/licenses/LICENSE-2.0
 
 Unless required by applicable law or agreed to in writing, software
 distributed under the License is distributed on an "AS IS" BASIS,
 WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 See the License for the specific language governing permissions and
 limitations under the License.
 
 */

#import "CEHexColorTransformer.h"
#import "NSColor+WFColorCode.h"


@implementation CEHexColorTransformer

#pragma mark Superclass Methods

// ------------------------------------------------------
/// Class of transformed value
+ (nonnull Class)transformedValueClass
// ------------------------------------------------------
{
    return [NSString class];
}


// ------------------------------------------------------
/// Can reverse transformeation?
+ (BOOL)allowsReverseTransformation
// ------------------------------------------------------
{
    return YES;
}


// ------------------------------------------------------
/// From color code hex to NSColor (NSString -> NSColor)
- (nullable id)transformedValue:(nullable id)value
// ------------------------------------------------------
{
    if (!value) { return nil; }
    
    WFColorCodeType type = WFColorCodeInvalid;
    NSColor *color = [NSColor colorWithColorCode:value codeType:&type];
    
    return (type == WFColorCodeHex || type == WFColorCodeShortHex) ? color : nil;
}


// ------------------------------------------------------
/// From NSColor to hex color code string (NSColor -> NSString)
- (nullable id)reverseTransformedValue:(nullable id)value
// ------------------------------------------------------
{
    if (![value isKindOfClass:[NSColor class]]) { return @"#000000"; }
    
    NSColor *color = [(NSColor *)value colorUsingColorSpaceName:NSCalibratedRGBColorSpace];
    
    return [color colorCodeWithType:WFColorCodeHex];
}

@end
