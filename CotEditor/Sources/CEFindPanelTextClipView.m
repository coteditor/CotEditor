/*
 
 CEFindPanelTextClipView.m
 
 CotEditor
 http://coteditor.com
 
 Created by 1024jp on 2015-03-05.

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
