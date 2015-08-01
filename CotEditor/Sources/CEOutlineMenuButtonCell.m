/*
 
 CEOutlineMenuButtonCell.m
 
 CotEditor
 http://coteditor.com
 
 Created by nakamuxu on 2005-08-25.
 
 ------------------------------------------------------------------------------
 
 © 2004-2007 nakamuxu
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

#import "CEOutlineMenuButtonCell.h"


@implementation CEOutlineMenuButtonCell

#pragma mark Superclass Methods

// ------------------------------------------------------
/// draw cell
- (void)drawWithFrame:(NSRect)cellFrame inView:(nonnull NSView *)controlView
// ------------------------------------------------------
{
    // draw background
    [super drawBezelWithFrame:cellFrame inView:controlView];
    
    // draw popup arrow image
    NSImage *arrowImage = [NSImage imageNamed:@"PopUpButtonArrowTemplate"];
    NSRect imageFrame = NSMakeRect(NSMaxX(cellFrame) - [arrowImage size].width - 5, NSMinY(cellFrame),
                                   [arrowImage size].width, NSHeight(cellFrame));
    [self drawImage:arrowImage withFrame:imageFrame inView:controlView];
    
    // shift content 1px
    cellFrame.origin.y += 1.0;
    
    // draw text
    [super drawInteriorWithFrame:cellFrame inView:controlView];
}

@end
