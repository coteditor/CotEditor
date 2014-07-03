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

#pragma mark NSPopUpButtonCell Methods

//=======================================================
// NSPopUpButtonCell method
//
//=======================================================

// ------------------------------------------------------
/// セルの描画
- (void)drawWithFrame:(NSRect)cellFrame inView:(NSView *)controlView
// ------------------------------------------------------
{
    if (![self isEnabled]) { return; }
    
    // fill background
    [[NSColor colorWithWhite:0.98 alpha:1.0] set];
    [NSBezierPath fillRect:cellFrame];
    
    // draw frame border (horizontal side lines)
    [[NSColor colorWithWhite:0.75 alpha:1] set];
    [NSBezierPath strokeLineFromPoint:NSMakePoint(0.5, 0)
                              toPoint:NSMakePoint(0.5, NSMaxY(cellFrame))];
    [NSBezierPath strokeLineFromPoint:NSMakePoint(NSMaxX(cellFrame) - 0.5, 0)
                              toPoint:NSMakePoint(NSMaxX(cellFrame) - 0.5, NSMaxY(cellFrame))];
    
    // draw popup arrow image
    NSImage *arrowImage = [NSImage imageNamed:@"popUpButtonArrowTemplate"];
    [arrowImage drawAtPoint:NSMakePoint(NSMaxX(cellFrame) - [arrowImage size].width - 4, 1)
                   fromRect:cellFrame operation:NSCompositeSourceOver fraction:0.67];
    
    [super drawInteriorWithFrame:cellFrame inView:controlView];
}

@end
