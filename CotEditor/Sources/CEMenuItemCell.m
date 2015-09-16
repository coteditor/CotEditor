/*
 
 CEMenuItemCell.m
 
 CotEditor
 http://coteditor.com
 
 Created by 1024jp on 2014-04-13.

 ------------------------------------------------------------------------------
 
 © 2014-2015 1024jp
 
 Licensed under the Apache License, Version 2.0 (the "License");
 you may not use this file except in compliance with the License.
 You may obtain a copy of the License at
 
 http://www.apache.org/licenses/LICENSE-2.0
 
 Unless required by applicable law or agreed to in writing, software
 distributed under the License is distributed on an "AS IS" BASIS,
 WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 See the License for the specific language governing permissions and
 limitations under the License.
 
 */

#import "CEMenuItemCell.h"
#import "Constants.h"


@implementation CEMenuItemCell

#pragma mark Superclass Methods

// ------------------------------------------------------
/// draw cell
- (void)drawInteriorWithFrame:(NSRect)cellFrame inView:(nonnull NSView *)controlView
// ------------------------------------------------------
{
    if ([self isSeparator]) {
        [[NSColor gridColor] set];
        [NSBezierPath strokeLineFromPoint:NSMakePoint(NSMinX(cellFrame), floor(NSMidY(cellFrame)) + 0.5)
                                  toPoint:NSMakePoint(NSMaxX(cellFrame), floor(NSMidY(cellFrame)) + 0.5)];
    
    } else {
        [super drawInteriorWithFrame:cellFrame inView:controlView];
    }
}



#pragma mark Public Methods

// ------------------------------------------------------
/// whether itself is a separator item
- (BOOL)isSeparator
// ------------------------------------------------------
{
    return [[self stringValue] isEqualTo:CESeparatorString];
}

@end
