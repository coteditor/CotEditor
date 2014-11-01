/*
 ==============================================================================
 CESplitView
 
 CotEditor
 http://coteditor.com
 
 Created on 2014-07-26 by 1024jp
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

#import "CESplitView.h"


@implementation CESplitView

#pragma mark Superclass Methods

// ------------------------------------------------------
/// change divider style depending on its split otientation
- (NSSplitViewDividerStyle)dividerStyle
// ------------------------------------------------------
{
    return [self isVertical] ? NSSplitViewDividerStyleThin : NSSplitViewDividerStylePaneSplitter;
}


// ------------------------------------------------------
/// override divider color (for Yosemite)
- (NSColor *)dividerColor
// ------------------------------------------------------
{
    // on Yosemite
    if (floor(NSAppKitVersionNumber) > 1265) {  // 1265 = NSAppKitVersionNumber10_9
        return [NSColor windowFrameColor];
    }
    
    return [super dividerColor];
}

@end
