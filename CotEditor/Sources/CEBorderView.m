/*
 ==============================================================================
 CEBorderView
 
 CotEditor
 http://coteditor.com
 
 Created on 2015-01-09 by 1024jp
 encoding="UTF-8"
 ------------------------------------------------------------------------------
 
 © 2015 1024jp
 
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

#import "CEBorderView.h"


@implementation CEBorderView

#pragma mark Superclass Methods

// ------------------------------------------------------
/// draw background
- (void)drawRect:(NSRect)dirtyRect
// ------------------------------------------------------
{
    // fill in background
    [[self fillColor] set];
    [NSBezierPath fillRect:dirtyRect];
    
    // draw borders
    const CGFloat strokeWidth = 1.0;
    NSRect frame = [self frame];
    
    [[self borderColor] set];
    if ([self drawsTopBorder] > 0) {
        [NSBezierPath strokeLineFromPoint:NSMakePoint(NSMinX(dirtyRect), NSMaxY(frame) - strokeWidth / 2)
                                  toPoint:NSMakePoint(NSMaxX(dirtyRect), NSMaxY(frame) - strokeWidth / 2)];
    }
    
    if ([self drawsBottomBorder]) {
        [NSBezierPath strokeLineFromPoint:NSMakePoint(NSMinX(dirtyRect), strokeWidth / 2)
                                  toPoint:NSMakePoint(NSMaxX(dirtyRect), strokeWidth / 2)];
    }
}


// ------------------------------------------------------
/// whether it's opaque view
- (BOOL)isOpaque
// ------------------------------------------------------
{
    return ([[self fillColor] alphaComponent] == 1.0);
}

@end
