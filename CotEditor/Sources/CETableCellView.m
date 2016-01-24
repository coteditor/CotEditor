/*
 
 CETableCellView.m
 
 CotEditor
 http://coteditor.com
 
 Created by 1024jp on 2016-01-25.
 
 ------------------------------------------------------------------------------
 
 © 2016 1024jp
 
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

#import "CETableCellView.h"


@implementation CETableCellView

// ------------------------------------------------------
/// inverse text color of highlighted cell
- (void)setBackgroundStyle:(NSBackgroundStyle)backgroundStyle
// ------------------------------------------------------
{
    BOOL isHighlighted = (backgroundStyle == NSBackgroundStyleDark);
    
    NSAttributedString *attrString = [[self textField] attributedStringValue];
    NSMutableAttributedString *mutableAttrString = [attrString mutableCopy];
    [attrString enumerateAttribute:NSForegroundColorAttributeName inRange:NSMakeRange(0, [attrString length]) options:0 usingBlock:^(NSColor  * _Nullable color, NSRange range, BOOL * _Nonnull stop)
    {
        if (isHighlighted && !color) {
            [mutableAttrString addAttribute:NSForegroundColorAttributeName value:[NSColor alternateSelectedControlTextColor] range:range];
        } else if (!isHighlighted && (color == [NSColor alternateSelectedControlTextColor])) {
            [mutableAttrString removeAttribute:NSForegroundColorAttributeName range:range];
        }
    }];
    [[self textField] setAttributedStringValue:mutableAttrString];
    
    [super setBackgroundStyle:backgroundStyle];
}

@end
