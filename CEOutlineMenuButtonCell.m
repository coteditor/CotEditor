/*
=================================================
CEOutlineMenuButtonCell
(for CotEditor)

 Copyright (C) 2004-2007 nakamuxu.
 Copyright (C) 2014 CotEditor Project
 http://coteditor.github.io
=================================================

encoding="UTF-8"
Created:2005.08.25

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

#import "CEOutlineMenuButtonCell.h"


@implementation CEOutlineMenuButtonCell

#pragma mark Public Methods

//=======================================================
// Public method
//
//=======================================================

// ------------------------------------------------------
- (void)drawWithFrame:(NSRect)cellFrame inView:(NSView *)controlView
// セルの描画
// ------------------------------------------------------
{
    if (![self isEnabled]) { return; }
    
    NSImage *centerImage = [NSImage imageNamed:@"popUpButtonBG_center"];
    NSImage *leftImage = [NSImage imageNamed:@"popUpButtonBG_left"];
    NSImage *rightImage= [NSImage imageNamed:@"popUpButtonArrow"];
    
    NSDrawThreePartImage(cellFrame, leftImage, centerImage, rightImage, NO, NSCompositeSourceOver, 1.0, YES);
    
    [super drawInteriorWithFrame:cellFrame inView:controlView];
}

@end
