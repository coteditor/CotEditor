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
#import "CEInvisibles.h"
#import "Defaults.h"


@interface CEEditPaneController ()

@property (nonatomic, nullable, weak) IBOutlet NSButton *smartQuoteCheckButton;

@property (nonatomic, nonnull, copy) NSArray<NSString *> *invisibleSpaces;
@property (nonatomic, nonnull, copy) NSArray<NSString *> *invisibleTabs;
@property (nonatomic, nonnull, copy) NSArray<NSString *> *invisibleNewLines;
@property (nonatomic, nonnull, copy) NSArray<NSString *> *invisibleFullWidthSpaces;
@property (nonatomic, nonnull, copy) NSString *completionHintMessage;

@end




#pragma mark -

@implementation CEEditPaneController

#pragma mark Superclass Methods

// ------------------------------------------------------
/// initialize
- (nullable instancetype)initWithNibName:(nullable NSString *)nibNameOrNil bundle:(nullable NSBundle *)nibBundleOrNil
// ------------------------------------------------------
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // setup popup menu items for invisible characters
        _invisibleSpaces = [CEInvisibles spaceStrings];
        _invisibleTabs = [CEInvisibles tabStrings];
        _invisibleNewLines = [CEInvisibles newLineStrings];
        _invisibleFullWidthSpaces = [CEInvisibles fullwidthSpaceStrings];
        
        [self updateCompletionHintMessage];
    }
    return self;
}

// ------------------------------------------------------
/// nib name
- (nullable NSString *)nibName
// ------------------------------------------------------
{
    return @"EditPane";
}



// ------------------------------------------------------
/// setup UI
- (void)loadView
// ------------------------------------------------------
{
    [super loadView];
    
    // disable Smart Quotes/Dashes setting on under Mavericks
    if (NSAppKitVersionNumber < NSAppKitVersionNumber10_9) {
        [[self smartQuoteCheckButton] setEnabled:NO];
        [[self smartQuoteCheckButton] setState:NSOffState];
        [[self smartQuoteCheckButton] setTitle:[NSString stringWithFormat:@"%@%@", [[self smartQuoteCheckButton] title],
                                                NSLocalizedString(@" (on Mavericks and later)", nil)]];
    }
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
