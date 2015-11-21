/*
 
 CECharacterField.m
 
 CotEditor
 http://coteditor.com
 
 Created by 1024jp on 2015-11-21.
 
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

#import "CECharacterField.h"


@implementation CECharacterField

#pragma mark Superclass Methods

// ------------------------------------------------------
/// determine size
- (NSSize)intrinsicContentSize
// ------------------------------------------------------
{
    NSSize size =  [super intrinsicContentSize];
    NSRect bounds = [[self attributedStringValue] boundingRectWithSize:size
                                                               options:NSStringDrawingUsesFontLeading];
    
    size.width = MAX(size.width, [[self font] pointSize]);  // avoid zero width
    size.height = ceil(NSHeight(bounds));
    
    return size;
}

@end
