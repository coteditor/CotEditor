/*
 
 CESwitcherSegmentedCell.m
 
 CotEditor
 http://coteditor.com
 
 Created by 1024jp on 2015-09-17.
 
 ------------------------------------------------------------------------------
 
 © 2015 1024jp
 
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

#import "CESwitcherSegmentedCell.h"


@implementation CESwitcherSegmentedCell

#pragma mark Segmented Cell Methods

// ------------------------------------------------------
/// customize drawing items
- (void)drawWithFrame:(NSRect)cellFrame inView:(nonnull NSView *)controlView
// ------------------------------------------------------
{
    // draw only inside
    [self drawInteriorWithFrame:cellFrame inView:controlView];
}


// ------------------------------------------------------
/// draw each segment
- (void)drawSegment:(NSInteger)segment inFrame:(NSRect)frame withView:(nonnull NSSegmentedControl *)controlView
// ------------------------------------------------------
{
    // use another image on selected segment
    //   -> From a universal design point of view, it's better to use an image that has a different silhouette from the normal (unselected) one.
    //      Some of users may hard to distinguish the selected state just by the color.
    if ([self isSelectedForSegment:segment]) {
        // load "selected" icon template
        NSString *iconName = [[self imageForSegment:segment] name];
        NSImage *selectedIcon = [NSImage imageNamed:[@"Selected" stringByAppendingString:iconName]];
        
        // calculate area to draw
        NSRect imageRect = [self imageRectForBounds:frame];
        imageRect.origin.y += floor((imageRect.size.height - [selectedIcon size].height) / 2);
        imageRect.size = [selectedIcon size];
        
        // draw icon template
        // (On Mavericks and later, you can use simply `drawInRect:`)
        [selectedIcon drawInRect:imageRect fromRect:NSZeroRect operation:NSCompositeSourceOver fraction:1.0 respectFlipped:YES hints:@{}];
        
        // tint drawn icon template
        [[NSColor alternateSelectedControlColor] set];
        NSRectFillUsingOperation(frame, NSCompositeSourceIn);
        
    } else {
        [super drawSegment:segment inFrame:frame withView:controlView];
    }
}

@end
