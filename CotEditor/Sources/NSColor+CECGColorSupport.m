/*
 ==============================================================================
 NSColor+CECGColorSupport
 
 CotEditor
 http://coteditor.github.io
 
 Created on 2014-10-15 by 1024jp
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

#import "NSColor+CECGColorSupport.h"


@implementation NSColor (CECGColorSupport)


// ------------------------------------------------------
/// Lion 用のCGColor サポート
- (CGColorRef)CECGColor
// ------------------------------------------------------
{
    // Lion で NSColor から CGColor を生成するのはめんどくさい
    // Target が Mountain Lion 以降になって時点でこのカテゴリは捨てて良い
    
    CIColor *ciColor = [[CIColor alloc] initWithColor:self];
    CGColorSpaceRef colorSpace = [ciColor colorSpace];
    const CGFloat *components = [ciColor components];
    CGColorRef cgColor = CGColorCreate(colorSpace, components);
    CGColorSpaceRelease(colorSpace);
    
    return cgColor;
}

@end
