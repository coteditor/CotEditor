/*
 ==============================================================================
 CEColorHexTransformer
 
 CotEditor
 http://coteditor.github.io
 
 Created on 2014-09-12 by 1024jp
 encoding="UTF-8"
 ------------------------------------------------------------------------------
 
 © 2014 CotEditor Project
 
 This program is free software; you can redistribute it and/or modify it under
 the terms of the GNU General Public License as published by the Free Software
 Foundation; either version 2 of the License, or (at your option) any later
 version.
 
 This program is distributed in the hope that it will be useful, but WITHOUT
 ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS
 FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.
 
 You should have received a copy of the GNU General Public License along with
 this program; if not, write to the Free Software Foundation, Inc., 59 Temple
 Place - Suite 330, Boston, MA  02111-1307, USA.
 
 ==============================================================================
 */

#import "CEHexColorTransformer.h"
#import "NSColor+WFColorCode.h"


@implementation CEHexColorTransformer

#pragma mark Class Methods

//=======================================================
// Class method
//
//=======================================================

// ------------------------------------------------------
/// Class of transformed value
+ (Class)transformedValueClass
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



#pragma mark NSValueTransformer Methods

//=======================================================
// NSValueTransformer method
//
//=======================================================

// ------------------------------------------------------
/// From color code hex to NSColor (NSString -> NSColor)
- (id)transformedValue:(id)value
// ------------------------------------------------------
{
    if (!value) { return nil; }
    
    WFColorCodeType type = nil;
    NSColor *color = [NSColor colorWithColorCode:value codeType:&type];
    
    return (type == WFColorCodeHex) ? color : nil;
}


// ------------------------------------------------------
/// From NSColor to hex color code string (NSColor -> NSString)
- (id)reverseTransformedValue:(id)value
// ------------------------------------------------------
{
    if (![value isKindOfClass:[NSColor class]]) { return @"#000000"; }
    
    NSColor *color = [(NSColor *)value colorUsingColorSpaceName:NSDeviceColorSpaceName];
    
    return [color colorCodeWithType:WFColorCodeHex];
}

@end
