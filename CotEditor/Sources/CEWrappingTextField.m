/*
 
 CEWrappingTextField.m
 
 CotEditor
 http://coteditor.com
 
 Created by 1024jp on 2014-12-26.
 
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

#import "CEWrappingTextField.h"


@implementation CEWrappingTextField

#pragma mark Superclass Methods

// ------------------------------------------------------
/// make text field vertically expandable on resize
- (void)setFrameSize:(NSSize)newSize;
// ------------------------------------------------------
{
    // Setting preferredMaxLayoutWidth on 10.8 makes application hang up on document with specific file names (2015-02 by 1024jp).
    if (NSAppKitVersionNumber >= NSAppKitVersionNumber10_9) {
        [self setPreferredMaxLayoutWidth:newSize.width - 4];  // 4 for 2 * inset
    }
    
    [super setFrameSize:newSize];
}

@end
