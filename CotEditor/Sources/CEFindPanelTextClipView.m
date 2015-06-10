/*
 ==============================================================================
 CEFindPanelTextClipView
 
 CotEditor
 http://coteditor.com
 
 Created on 2015-03-05 by 1024jp
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

#import "CEFindPanelTextClipView.h"


@implementation CEFindPanelTextClipView

#pragma mark Superclass Methods

// ------------------------------------------------------
/// initialize
- (instancetype)initWithCoder:(NSCoder *)coder
// ------------------------------------------------------
{
    self = [super initWithCoder:coder];
    if (self) {
        // make sure frame to be initialized (Otherwise input area can be arranged in a wrong place.)
        [self setFrame:[self frame]];
    }
    return self;
}


// ------------------------------------------------------
/// add left padding for popup button
- (void)setFrame:(NSRect)frame
// ------------------------------------------------------
{
    const CGFloat padding = 28.0;
    
    frame.origin.x += padding;
    frame.size.width -= padding;
    
    [super setFrame:frame];
}

@end
