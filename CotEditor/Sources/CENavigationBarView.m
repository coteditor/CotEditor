/*
 ==============================================================================
 CENavigationBarView
 
 CotEditor
 http://coteditor.github.io
 
 Created on 2014-07-27 by 1024jp
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

#import "CENavigationBarView.h"


@implementation CENavigationBarView

#pragma mark Superclass Methods

// ------------------------------------------------------
/// draw background
- (void)drawRect:(NSRect)dirtyRect
// ------------------------------------------------------
{
    // fill in the background
    [[NSColor windowBackgroundColor] set];
    [NSBezierPath fillRect:dirtyRect];
    
    // draw frame border (only bottom)
    [[NSColor windowFrameColor] set];
    [NSBezierPath strokeLineFromPoint:NSMakePoint(NSMinX(dirtyRect), 0.5)
                              toPoint:NSMakePoint(NSMaxX(dirtyRect), 0.5)];
}

@end
