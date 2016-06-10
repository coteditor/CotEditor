/*
 
 CETextView+Accessories.m
 
 CotEditor
 http://coteditor.com
 
 Created by 1024jp on 2016-06-10.
 
 ------------------------------------------------------------------------------
 
 © 2014-2016 1024jp
 
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

#import "CETextView.h"

#import "CEUnicodeInputPanelController.h"
#import "CEColorCodePanelController.h"


@implementation CETextView (UnicodeInput)

#pragma mark Action Messages

// ------------------------------------------------------
/// show Unicode input panel
- (IBAction)showUnicodeInputPanel:(nullable id)sender
// ------------------------------------------------------
{
    [[CEUnicodeInputPanelController sharedController] showWindow:self];
}



#pragma mark Protocol

// ------------------------------------------------------
/// insert an Unicode character from Unicode input panel
- (IBAction)insertUnicodeCharacter:(nullable id)sender
// ------------------------------------------------------
{
    if (![sender isKindOfClass:[CEUnicodeInputPanelController class]]) { return; }
    
    NSString *character = [sender characterString];
    NSRange range = [self rangeForUserTextChange];
    
    if ([self shouldChangeTextInRange:range replacementString:character]) {
        [self replaceCharactersInRange:range withString:character];
        [self didChangeText];
    }
}

@end




#pragma mark -

@implementation CETextView (ColorCode)

// ------------------------------------------------------
/// avoid changeing text color by color panel
- (IBAction)changeColor:(nullable id)sender
// ------------------------------------------------------
{
    // do nothing.
}



#pragma mark Action Messages

// ------------------------------------------------------
/// tell selected string to color code panel
- (IBAction)editColorCode:(nullable id)sender
// ------------------------------------------------------
{
    NSString *selectedString = [[self string] substringWithRange:[self selectedRange]];
    
    [[CEColorCodePanelController sharedController] showWindow:sender];
    [[CEColorCodePanelController sharedController] setColorWithCode:selectedString];
}



#pragma mark Protocol

// ------------------------------------------------------
/// insert color code from color code panel
- (IBAction)insertColorCode:(nullable id)sender
// ------------------------------------------------------
{
    if (![sender isKindOfClass:[CEColorCodePanelController class]]) { return; }
    
    NSString *colorCode = [sender colorCode];
    NSRange range = [self rangeForUserTextChange];
    
    if ([self shouldChangeTextInRange:range replacementString:colorCode]) {
        [self replaceCharactersInRange:range withString:colorCode];
        [[self undoManager] setActionName:NSLocalizedString(@"Insert Color Code", nil)];
        [self didChangeText];
        [self setSelectedRange:NSMakeRange(range.location, [colorCode length])];
        [self scrollRangeToVisible:[self selectedRange]];
    }
}

@end
