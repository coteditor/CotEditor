/*
 ==============================================================================
 CEEditorScrollView
 
 CotEditor
 http://coteditor.com
 
 Created on 2005-01-15 by 1024jp
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

#import "CEEditorScrollView.h"
#import "CELineNumberView.h"


@implementation CEEditorScrollView

#pragma mark Superclass Methods

// ------------------------------------------------------
/// use custom ruler view
+ (nonnull Class)rulerViewClass
// ------------------------------------------------------
{
    return [CELineNumberView class];
}


// ------------------------------------------------------
/// initialize instance
- (nonnull instancetype)initWithFrame:(NSRect)frameRect
// ------------------------------------------------------
{
    self = [super initWithFrame:frameRect];
    if (self) {
        [self setHasVerticalRuler:YES];
        [self setHasHorizontalRuler:NO];
    }
    return self;
}



#pragma mark Public Methods

// ------------------------------------------------------
/// initialize instance
- (void)invalidateLineNumber
// ------------------------------------------------------
{
    [[self lineNumberView] setNeedsDisplay:YES];
}



#pragma mark Private Methods

// ------------------------------------------------------
/// return current line number veiw
- (nullable NSRulerView *)lineNumberView
// ------------------------------------------------------
{
    return [self verticalRulerView];
}

@end
