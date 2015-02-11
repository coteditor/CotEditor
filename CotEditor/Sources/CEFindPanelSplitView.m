/*
 ==============================================================================
 CEFindPanelSplitView
 
 CotEditor
 http://coteditor.com
 
 Created on 2015-01-05 by 1024jp
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

#import "CEFindPanelSplitView.h"


@implementation CEFindPanelSplitView

#pragma mark Superclass Methods

// ------------------------------------------------------
/// hide divider completely when the second view (Find All result) is collapsed
- (CGFloat)dividerThickness
// ------------------------------------------------------
{
    if ([self isSubviewCollapsed:[self subviews][1]]) {
        return 0;
    }
        
    return [super dividerThickness];
}


// ------------------------------------------------------
/// hide divider completely when the second view (Find All result) is collapsed on OS X 10.8
- (NSColor *)dividerColor
// ------------------------------------------------------
{
    // -> This override is not important on Mavericks and later.
    if (NSAppKitVersionNumber < NSAppKitVersionNumber10_9) {
        if ([self isSubviewCollapsed:[self subviews][1]]) {
            return [NSColor clearColor];
        }
    }
    
    return [super dividerColor];
}

@end
