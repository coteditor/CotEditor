/*
 
 CEFindPanelTextView.m
 
 CotEditor
 http://coteditor.com
 
 Created by 1024jp on 2015-03-04.

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

#import "CEFindPanelTextView.h"
#import "CEFindPanelLayoutManager.h"
#import "CEFindPanelController.h"
#import "Constants.h"


@interface CEFindPanelTextView ()

@property (nonatomic, nullable) IBOutlet CEFindPanelController *findPanelController;

@end




#pragma mark -

@implementation CEFindPanelTextView

#pragma mark Superclass Methods

// ------------------------------------------------------
/// initialize instance
- (nullable instancetype)initWithCoder:(nonnull NSCoder *)coder
// ------------------------------------------------------
{
    self = [super initWithCoder:coder];
    if (self) {
        // set system font (standard NSTextField behavior)
        NSFont *font = [NSFont systemFontOfSize:[NSFont systemFontSize]];
        [self setFont:font];
        
        // set inset a bit like NSTextField (horizontal inset is added in CEFindPanelTextClipView)
        [self setTextContainerInset:NSMakeSize(0.0, 2.0)];
        
        // avoid wrapping
        [[self textContainer] setWidthTracksTextView:NO];
        [[self textContainer] setContainerSize:NSMakeSize(CGFLOAT_MAX, CGFLOAT_MAX)];
        [self setHorizontallyResizable:YES];
        
        // disable automatic text substitutions
        if ([self respondsToSelector:@selector(setAutomaticQuoteSubstitutionEnabled:)]) {  // only on OS X 10.9 and later
            [self setAutomaticQuoteSubstitutionEnabled:NO];
            [self setAutomaticDashSubstitutionEnabled:NO];
        }
        [self setAutomaticTextReplacementEnabled:NO];
        [self setAutomaticSpellingCorrectionEnabled:NO];
        [self setSmartInsertDeleteEnabled:NO];
        
        // set subclassed layout manager for invisible characters
        CEFindPanelLayoutManager *layoutManager = [[CEFindPanelLayoutManager alloc] init];
        [[self textContainer] replaceLayoutManager:layoutManager];
    }
    return self;
}


// ------------------------------------------------------
/// view is on focus
- (BOOL)becomeFirstResponder
// ------------------------------------------------------
{
    // select whole string on focus (standard NSTextField behavior)
    [self setSelectedRange:NSMakeRange(0, [[self string] length])];
    
    return [super becomeFirstResponder];
}


// ------------------------------------------------------
/// view dismiss focus
- (BOOL)resignFirstResponder
// ------------------------------------------------------
{
    // clear current selection (standard NSTextField behavior)
    [self setSelectedRange:NSMakeRange(0, 0)];
    return [super resignFirstResponder];
}


// ------------------------------------------------------
/// swap '¥' with '\' if needed
- (void)insertText:(nonnull id)aString replacementRange:(NSRange)replacementRange
// ------------------------------------------------------
{
    NSString *string = ([aString isKindOfClass:[NSAttributedString class]]) ? [aString string] : aString;
    
    // swap '¥' with '\' if needed
    if ([[NSUserDefaults standardUserDefaults] boolForKey:CEDefaultSwapYenAndBackSlashKey] && ([string length] == 1)) {
        NSString *yen = [NSString stringWithCharacters:&kYenMark length:1];
        
        if ([string isEqualToString:@"\\"]) {
            string = yen;
        } else if ([string isEqualToString:yen]) {
            string = @"\\";
        }
    }
    
    [super insertText:string replacementRange:replacementRange];
}


// ------------------------------------------------------
/// jump to the next responder with tab key (standard NSTextField behavior)
- (void)insertTab:(nullable id)sender
// ------------------------------------------------------
{
    [[self window] makeFirstResponder:[self nextKeyView]];
}


// ------------------------------------------------------
/// perform Find Next with return
- (void)insertNewline:(nullable id)sender
// ------------------------------------------------------
{
    // -> do nothing if no findpanelController is connected (standard NSTextField behavior)
    if ([self findPanelController]) {
        [[self findPanelController] findNext:self];
    }
}

@end
