/*
=================================================
CEHexColorTransformer
(for CotEditor)

Copyright (C) 2004-2007 nakamuxu.
http://www.aynimac.com/
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

#pragma mark ===== Class method =====

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



#pragma mark ===== Public method =====

//=======================================================
// Public method
//
//=======================================================

// ------------------------------------------------------
- (id)transformedValue:(id)inValue
// 変換された値を返す(NSColor+NSArchiver -> NSString)
// ------------------------------------------------------
{
    if (inValue == nil) { return nil; }

    id theColor = [NSUnarchiver unarchiveObjectWithData:inValue];
    if (theColor == nil) { return nil; }
    CGFloat theRed, theGreen, theBlue;
    NSString *outString = nil, *theColorSpaceName = nil;

    // カラースペース名がRGB系でなかったらコンバートする
    theColorSpaceName = [theColor colorSpaceName];
    if ((![theColorSpaceName isEqualToString:NSCalibratedRGBColorSpace]) && 
            (![theColorSpaceName isEqualToString:NSDeviceRGBColorSpace])) {
        theColor = [theColor colorUsingColorSpaceName:NSCalibratedRGBColorSpace];
    }
    [theColor getRed:&theRed green:&theGreen blue:&theBlue alpha:nil];
    // 各色の値を文字列に整形
    outString = [NSString stringWithFormat:@"%2.2lx%2.2lx%2.2lx",
            (unsigned long)(theRed*255), (unsigned long)(theGreen*255), (unsigned long)(theBlue*255)];

    return outString;
}


// ------------------------------------------------------
- (id)reverseTransformedValue:(id)inValue
// 逆変換された値を返す(NSString -> NSColor+NSArchiver)
// ------------------------------------------------------
{
    if (inValue == nil) { return nil; }
    if ([inValue length] != 6) { return nil; }

    unsigned int theInt = 0;
    CGFloat theRed, theGreen, theBlue;
    NSInteger i;

    NSScanner *theScanner;
    for (i = 0; i < 3; i++) {
        theScanner = [NSScanner scannerWithString:[inValue substringWithRange:NSMakeRange(i * 2, 2)]];
        if ([theScanner scanHexInt:&theInt]) {
            if (i == 0) {
                theRed = (theInt > 0) ? ((CGFloat)theInt / 255) : 0.0;
            } else if (i == 1) {
                theGreen = (theInt > 0) ? ((CGFloat)theInt / 255) : 0.0;
            } else if (i == 2) {
                theBlue = (theInt > 0) ? ((CGFloat)theInt / 255) : 0.0;
            }
        }
    }
    NSColor *outColor = [NSColor colorWithCalibratedRed:theRed green:theGreen blue:theBlue alpha:1.0];

    return [NSArchiver archivedDataWithRootObject:outColor];
}



@end
