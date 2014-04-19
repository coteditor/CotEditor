/*
 =================================================
 CEByteCountTransformer
 (for CotEditor)
 
 Copyright (C) 2014 CotEditor Project
 http://coteditor.github.io
 =================================================
 
 encoding="UTF-8"
 Created:2014-04-04
 
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

#import "CEByteCountTransformer.h"


@implementation CEByteCountTransformer

#pragma mark Class Methods

//=======================================================
// Class method
//
//=======================================================

// ------------------------------------------------------
/// 変換後のオブジェクトのクラスを返す
+ (Class)transformedValueClass
// ------------------------------------------------------
{
    return [NSString class];
}


// ------------------------------------------------------
/// 逆変換が可能かどうかを返す
+ (BOOL)allowsReverseTransformation
// ------------------------------------------------------
{
    return NO;
}



#pragma mark NSValueTransformer Methods

//=======================================================
// NSValueTransformer method
//
//=======================================================

// ------------------------------------------------------
/// 変換された値を返す(NSNumber -> NSString)
- (id)transformedValue:(id)value
// ------------------------------------------------------
{
    if (value == nil) { return nil; }
    
    double size = [value doubleValue];
    
    if (size == 0) { return nil; }
    
    NSArray *tokens = @[@"bytes", @"KB", @"MB", @"GB"];
    NSUInteger factor = 0;
    
    while (size > 1024) {
        size /= 1024;
        factor++;
    }
    
    NSString *format = (factor == 0 || size < 10) ? @"%.0f %@" : @"%.1f %@";
    
    return [NSString stringWithFormat:format, size, tokens[factor]];
}

@end
