/*
=================================================
CEHexColorTransformer
(for CotEditor)

 Copyright (C) 2004-2007 nakamuxu.
 Copyright (C) 2014 CotEditor Project
 http://coteditor.github.io
=================================================

encoding="UTF-8"
Created:2005.07.14

-------------------------------------------------

This program is free software; you can redistribute it and/or
modify it under the terms of the GNU General Public License
as published by the Free Software Foundation; either version 2
of the License, or (at your option) any later version.

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU General Public License for more details.

You should have received a copy of the GNU General Public License
along with this program; if not, write to the Free Software
Foundation, Inc., 59 Temple Place - Suite 330, Boston, MA  02111-1307, USA. 


=================================================
*/

#import "CEHexColorTransformer.h"


@implementation CEHexColorTransformer

#pragma mark Class Methods

//=======================================================
// Class method
//
//=======================================================

// ------------------------------------------------------
+ (Class)transformedValueClass
// 変換後のオブジェクトのクラスを返す
// ------------------------------------------------------
{
    return [NSString class];
}


// ------------------------------------------------------
+ (BOOL)allowsReverseTransformation
// 逆変換が可能かどうかを返す
// ------------------------------------------------------
{
    return YES;
}



#pragma mark NSValueTransformer Methods

//=======================================================
// NSValueTransformer method
//
//=======================================================

// ------------------------------------------------------
- (id)transformedValue:(id)value
// 変換された値を返す(NSColor+NSArchiver -> NSString)
// ------------------------------------------------------
{
    if (value == nil) { return nil; }

    NSColor *color = [NSUnarchiver unarchiveObjectWithData:value];
    
    if (color == nil) { return nil; }
    
    CGFloat red, green, blue;
    NSString *outString = nil;
    NSString *colorSpaceName;

    // カラースペース名がRGB系でなかったらコンバートする
    colorSpaceName = [color colorSpaceName];
    if (![colorSpaceName isEqualToString:NSCalibratedRGBColorSpace] &&
        ![colorSpaceName isEqualToString:NSDeviceRGBColorSpace]) {
        color = [color colorUsingColorSpaceName:NSCalibratedRGBColorSpace];
    }
    [color getRed:&red green:&green blue:&blue alpha:nil];
    
    // 各色の値を文字列に整形
    outString = [NSString stringWithFormat:@"%2.2lx%2.2lx%2.2lx",
                 (unsigned long)(red*255), (unsigned long)(green*255), (unsigned long)(blue*255)];

    return outString;
}


// ------------------------------------------------------
- (id)reverseTransformedValue:(id)value
// 逆変換された値を返す(NSString -> NSColor+NSArchiver)
// ------------------------------------------------------
{
    if (value == nil) { return nil; }
    if ([value length] != 6) { return nil; }

    unsigned int theInt = 0;
    CGFloat red, green, blue;

    NSScanner *scanner;
    for (NSUInteger i = 0; i < 3; i++) {
        scanner = [NSScanner scannerWithString:[value substringWithRange:NSMakeRange(i * 2, 2)]];
        if ([scanner scanHexInt:&theInt]) {
            switch (i) {
                case 0: red   = (CGFloat)theInt / 255; break;
                case 1: green = (CGFloat)theInt / 255; break;
                case 2: blue  = (CGFloat)theInt / 255; break;
            }
        }
    }
    NSColor *color = [NSColor colorWithCalibratedRed:red green:green blue:blue alpha:1.0];

    return [NSArchiver archivedDataWithRootObject:color];
}

@end
