/*
 
 CEEditPaneController.m
 
 CotEditor
 http://coteditor.com
 
 Created by 1024jp on 2014-04-18.

 ------------------------------------------------------------------------------
 
 © 2004-2007 nakamuxu
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

#import "CEEditPaneController.h"
#import "CEDefaults.h"


@interface CEEditPaneController ()

@property (nonatomic, nonnull, copy) NSString *completionHintMessage;

@end




#pragma mark -

@implementation CEEditPaneController

#pragma mark Superclass Methods

// ------------------------------------------------------
/// nib name
- (nullable NSString *)nibName
// ------------------------------------------------------
{
    return @"EditPane";
}


// ------------------------------------------------------
/// setup UI
- (void)viewDidLoad
// ------------------------------------------------------
{
    [super viewDidLoad];
    
    [self updateCompletionHintMessage];
}



#pragma mark Action Messages

// ------------------------------------------------------
///
- (IBAction)updateCompletionListWords:(nullable id)sender
// ------------------------------------------------------
{
    [self updateCompletionHintMessage];
}



#pragma mark Private Methods

// ------------------------------------------------------
- (void)updateCompletionHintMessage
// ------------------------------------------------------
{
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    NSString *message;
    
    if (![defaults boolForKey:CEDefaultCompletesDocumentWordsKey] &&
        ![defaults boolForKey:CEDefaultCompletesSyntaxWordsKey] &&
        ![defaults boolForKey:CEDefaultCompletesStandartWordsKey])
    {
        message = [NSString stringWithFormat:@"⚠️ %@", NSLocalizedString(@"Select at least one item to enable completion.", nil)];
    } else {
        message = [NSString stringWithFormat:NSLocalizedString(@"Completion can be performed manually with: %@ or %@", nil), @"Esc", @"⌘."];
    }
    
    [self setCompletionHintMessage:message];
}

@end
