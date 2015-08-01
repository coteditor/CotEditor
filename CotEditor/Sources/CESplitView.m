/*
 
 CESplitView.m
 
 CotEditor
 http://coteditor.com
 
 Created by 1024jp on 2014-07-26.
 
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

#import "CESplitView.h"


@implementation CESplitView

#pragma mark Superclass Methods

// ------------------------------------------------------
/// change divider style depending on its split orientation
- (NSSplitViewDividerStyle)dividerStyle
// ------------------------------------------------------
{
    return [self isVertical] ? NSSplitViewDividerStyleThin : NSSplitViewDividerStylePaneSplitter;
}


// ------------------------------------------------------
/// override divider color (for Yosemite)
- (nonnull NSColor *)dividerColor
// ------------------------------------------------------
{
    // on Yosemite and later
    if (NSAppKitVersionNumber >= NSAppKitVersionNumber10_10) {
        return [NSColor windowFrameColor];
    }
    
    return [super dividerColor];
}

@end
