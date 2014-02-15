/*
=================================================
CEOutlineMenuButtonCell
(for CotEditor)

Copyright (C) 2004-2007 nakamuxu.
http://www.aynimac.com/
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

#pragma mark ===== Public method =====

//=======================================================
// Public method
//
//=======================================================


// ------------------------------------------------------
- (void)drawWithFrame:(NSRect)inCellFrame inView:(NSView *)inControlView
// セルの描画
// ------------------------------------------------------
{
    if (![self isEnabled]) { return; }
    NSImage *theBackgroundCenterImg = [NSImage imageNamed:@"popUpButtonBG_center"];
    NSImage *theBackgroundLeftImg = [NSImage imageNamed:@"popUpButtonBG_left"];
    NSImage *theArrowImg = [NSImage imageNamed:@"popUpButtonArrow"];
    CGFloat theImgHeight = k_navigationBarHeight - 1;

    [theBackgroundCenterImg setScalesWhenResized:YES];
    [theBackgroundCenterImg setSize:NSMakeSize(NSWidth(inCellFrame), theImgHeight)];
    [theBackgroundCenterImg compositeToPoint:NSMakePoint(NSMinX(inCellFrame), theImgHeight) 
            operation:NSCompositeSourceOver];
    [theBackgroundLeftImg compositeToPoint:NSMakePoint(NSMinX(inCellFrame), theImgHeight) 
            operation:NSCompositeSourceOver];
    [theArrowImg compositeToPoint:NSMakePoint(NSMaxX(inCellFrame) - 11.0, theImgHeight) 
            operation:NSCompositeSourceOver];
    [super drawInteriorWithFrame:inCellFrame inView:inControlView];
}

@end
