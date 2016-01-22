/*
 
 CETextFinder.m
 
 CotEditor
 http://coteditor.com
 
 Created by 1024jp on 2015-01-03.

 ------------------------------------------------------------------------------
 
 © 2015-2016 1024jp
 
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

#import <OgreKit/OgreKit.h>
#import "CETextFinder.h"
#import "CEFindPanelController.h"
#import "CEProgressSheetController.h"
#import "CEHUDController.h"
#import "NSTextView+CETextReplacement.h"
#import "CEErrors.h"
#import "CEDefaults.h"


// keys for Find All result
NSString * _Nonnull const CEFindResultRange = @"range";
NSString * _Nonnull const CEFindResultLineNumber = @"lineNumber";
NSString * _Nonnull const CEFindResultAttributedLineString = @"attributedLineString";
NSString * _Nonnull const CEFindResultLineRange = @"lineRange";

static NSString * _Nonnull const kEscapeCharacter = OgreBackslashCharacter;
static const NSUInteger kMaxHistorySize = 20;
//static const NSUInteger kMinLengthShowIndicator = 5000;  // not in use


@interface CETextFinder ()

@property (nonatomic, nonnull) CEFindPanelController *findPanelController;
@property (nonatomic, nonnull) NSNumberFormatter *integerFormatter;

// readonly
@property (readwrite, nonatomic, nonnull) NSColor *highlightColor;

#pragma mark Settings
@property (readonly, nonatomic) BOOL usesRegularExpression;
@property (readonly, nonatomic) BOOL isWrap;
@property (readonly, nonatomic) BOOL inSelection;
@property (readonly, nonatomic) OgreSyntax syntax;
@property (readonly, nonatomic) unsigned options;
@property (readonly, nonatomic) BOOL closesIndicatorWhenDone;

@end




#pragma mark -

@implementation CETextFinder

#pragma mark Singleton

static CETextFinder	*singleton = nil;

// ------------------------------------------------------
/// return singleton instance
+ (nonnull CETextFinder *)sharedTextFinder
// ------------------------------------------------------
{
    if (!singleton) {
        singleton = [[self alloc] init];
    }
    
    return singleton;
}



#pragma mark Sueprclass Methods

// ------------------------------------------------------
/// register default setting for find panel
+ (void)initialize
// ------------------------------------------------------
{
    [super initialize];
    
    // register defaults for find panel here
    // sicne CEFindPanelController can be initialized before registering user defaults in CEAppDelegate. (2015-01 by 1024jp)
    NSDictionary<NSString *, id> *defaults = @{CEDefaultFindHistoryKey: @[],
                                               CEDefaultReplaceHistoryKey: @[],
                                               CEDefaultFindRegexSyntaxKey: @([OGRegularExpression defaultSyntax]),
                                               CEDefaultFindOptionsKey: @(OgreCaptureGroupOption),
                                               CEDefaultFindUsesRegularExpressionKey: @NO,
                                               CEDefaultFindInSelectionKey: @NO,
                                               CEDefaultFindIsWrapKey: @YES,
                                               CEDefaultFindNextAfterReplaceKey: @YES,
                                               CEDefaultFindClosesIndicatorWhenDoneKey: @YES,
                                               };
    
    [[NSUserDefaults standardUserDefaults] registerDefaults:defaults];
}


// ------------------------------------------------------
/// initialize instance
- (nonnull instancetype)init
// ------------------------------------------------------
{
    if (singleton) {
        return singleton;
    }
    
    self = [super init];
    if (self) {
        _findString = @"";
        _replacementString = @"";
        _findPanelController = [[CEFindPanelController alloc] init];
        _integerFormatter = [[NSNumberFormatter alloc] init];
        [_integerFormatter setUsesGroupingSeparator:YES];
        
        _highlightColor = [NSColor colorWithCalibratedHue:0.24 saturation:0.8 brightness:0.8 alpha:0.4];
        // Highlight color is currently not customizable. (2015-01-04)
        // It might better when it can be set in theme also for incompatible chars highlight.
        // Just because I'm lazy.
        
        // add to responder chain
        [NSApp setNextResponder:self];
        
        // observe application activation to sync find string with other apps
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(applicationDidBecomeActive:)
                                                     name:NSApplicationDidBecomeActiveNotification
                                                   object:nil];
        
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(applicationWillResignActive:)
                                                     name:NSApplicationWillResignActiveNotification
                                                   object:nil];
        
        // make singleton
        singleton = self;
    }
    return self;
}


// ------------------------------------------------------
/// clean up
- (void)dealloc
// ------------------------------------------------------
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}


// ------------------------------------------------------
/// validate menu item
- (BOOL)validateMenuItem:(nonnull NSMenuItem *)menuItem
// ------------------------------------------------------
{
    SEL action = [menuItem action];
    
    if (action == @selector(findNext:) ||
        action == @selector(findPrevious:) ||
        action == @selector(findSelectedText:) ||
        action == @selector(findAll:) ||
        action == @selector(replace:) ||
        action == @selector(replaceAndFind:) ||
        action == @selector(replaceAll:) ||
        action == @selector(centerSelectionInVisibleArea:))
    {
        return ([self client] != nil);
        
    } else if (action == @selector(useSelectionForFind:)) {
        return ([self selectedString] != nil);
        
    } else if (action == @selector(useSelectionForReplace:)) {
        return ([self client] != nil);  // replacement string accepts empty string
    }
    
    return YES;
}



#pragma mark Notification

// ------------------------------------------------------
/// sync search string on activating application
- (void)applicationDidBecomeActive:(nonnull NSNotification *)notification
// ------------------------------------------------------
{
    if ([[NSUserDefaults standardUserDefaults] boolForKey:CEDefaultSyncFindPboardKey]) {
        NSString *sharedFindString = [self findStringFromPasteboard];
        if (sharedFindString) {
            [self setFindString:sharedFindString];
        }
    }
}


// ------------------------------------------------------
/// sync search string on activating application
- (void)applicationWillResignActive:(nonnull NSNotification *)notification
// ------------------------------------------------------
{
    if ([[NSUserDefaults standardUserDefaults] boolForKey:CEDefaultSyncFindPboardKey]) {
        [self setFindStringToPasteboard:[self findString]];
    }
}



#pragma mark Action Messages

// ------------------------------------------------------
/// activate find panel
- (IBAction)showFindPanel:(nullable id)sender
// ------------------------------------------------------
{
    [[self findPanelController] showWindow:sender];
}


// ------------------------------------------------------
/// find next matched string
- (IBAction)findNext:(nullable id)sender
// ------------------------------------------------------
{
    if ([NSEvent modifierFlags] & NSShiftKeyMask) {
        // find backwards if Shift key pressed
        [self findForward:NO];
    } else {
        [self findForward:YES];
    }
}


// ------------------------------------------------------
/// find previous matched string
- (IBAction)findPrevious:(nullable id)sender
// ------------------------------------------------------
{
    [self findForward:NO];
}


// ------------------------------------------------------
/// perform find action with the selected string
- (IBAction)findSelectedText:(nullable id)sender
// ------------------------------------------------------
{
    [self useSelectionForFind:sender];
    [self findNext:sender];
}


// ------------------------------------------------------
/// find all matched string in the target and show results in a table
- (IBAction)findAll:(nullable id)sender
// ------------------------------------------------------
{
    if (![self checkIsReadyToFind]) { return; }
    
    NSNumberFormatter *integerFormatter = [self integerFormatter];
    NSTextView *textView = [self client];
    NSString *findString = [self sanitizedFindString];
    OGRegularExpression *regex = [self regex];
    NSArray<NSValue *> *scopeRanges = [self scopeRanges];
    
    NSRegularExpression *lineRegex = [NSRegularExpression regularExpressionWithPattern:@"\n" options:0 error:nil];
    NSString *string = [textView string];
    
    // setup progress sheet
    __block BOOL isCancelled = NO;
    CEProgressSheetController *indicator = [[CEProgressSheetController alloc] initWithMessage:NSLocalizedString(@"Find All", nil)];
    [indicator setIndetermine:YES];
    [indicator beginSheetForWindow:[textView window] completionHandler:^(NSModalResponse returnCode) {
        if (returnCode == NSCancelButton) {
            isCancelled = YES;
        }
    }];
    
    __weak typeof(self) weakSelf = self;
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        typeof(self) self = weakSelf;
        if (!self) { return; }
        
        NSMutableArray<NSDictionary *> *result = [NSMutableArray array];
        for (NSValue *rangeValue in scopeRanges) {
            NSRange scopeRange = [rangeValue rangeValue];
            NSEnumerator<OGRegularExpressionMatch *> *enumerator = [regex matchEnumeratorInString:string range:scopeRange];
            NSUInteger lineNumber = [lineRegex numberOfMatchesInString:string options:0 range:NSMakeRange(0, scopeRange.location)] + 1;
            
            OGRegularExpressionMatch *match;
            while ((match = [enumerator nextObject])) {
                if (isCancelled) {
                    [indicator close:self];
                    return;
                }
                
                // calc line number
                NSRange diffRange = NSMakeRange([match rangeOfStringBetweenMatchAndLastMatch].location - [match rangeOfLastMatchSubstring].length,
                                                [match rangeOfStringBetweenMatchAndLastMatch].length + [match rangeOfLastMatchSubstring].length);
                lineNumber += [lineRegex numberOfMatchesInString:string options:0 range:diffRange];
                
                // get highlighted line string
                NSRange lineRange = [string lineRangeForRange:[match rangeOfMatchedString]];
                NSRange inlineRange = [match rangeOfMatchedString];
                inlineRange.location -= lineRange.location;
                NSString *lineString = [string substringWithRange:lineRange];
                NSMutableAttributedString *lineAttrString = [[NSMutableAttributedString alloc] initWithString:lineString];
                [lineAttrString addAttributes:@{NSBackgroundColorAttributeName: [self highlightColor]} range:inlineRange];
                
                [result addObject:@{CEFindResultRange: [NSValue valueWithRange:[match rangeOfMatchedString]],
                                    CEFindResultLineNumber: @(lineNumber),
                                    CEFindResultAttributedLineString: lineAttrString,
                                    CEFindResultLineRange: [NSValue valueWithRange:inlineRange]}];
                
                NSString *informative = ([result count] == 1) ? @"%@ string found." : @"%@ strings found.";
                NSString *countStr = [integerFormatter stringFromNumber:@([result count])];
                dispatch_async(dispatch_get_main_queue(), ^{
                    [indicator setInformativeText:[NSString stringWithFormat:NSLocalizedString(informative, nil), countStr]];
                });
            }
        }
        
        dispatch_async(dispatch_get_main_queue(), ^{
            [indicator doneWithButtonTitle:nil];
            
            if ([result count] > 0) {
                if ([[self delegate] respondsToSelector:@selector(textFinder:didFinishFindingAll:results:textView:)]) {
                    [[self delegate] textFinder:self didFinishFindingAll:findString results:result textView:textView];
                }
                [indicator close:self];
                
            } else {
                NSBeep();
                [indicator setInformativeText:NSLocalizedString(@"Not Found.", nil)];
                if ([self closesIndicatorWhenDone]) {
                    [indicator close:self];
                }
            }
        });
    });
    
    [self appendFindHistory:[self findString]];
}


// ------------------------------------------------------
/// replace matched string in selection with replacementStirng
- (IBAction)replace:(nullable id)sender
// ------------------------------------------------------
{
    if (![self checkIsReadyToFind]) { return; }
    
    BOOL success = [self replace];
    if (!success) {
        NSBeep();
    } else {
        [[self client] scrollRangeToVisible:[[self client] selectedRange]];
    }
    
    [self appendFindHistory:[self findString]];
    [self appendReplaceHistory:[self replacementString]];
}


// ------------------------------------------------------
/// replace matched string with replacementStirng and select the next match
- (IBAction)replaceAndFind:(nullable id)sender
// ------------------------------------------------------
{
    if (![self checkIsReadyToFind]) { return; }
    
    [self replace];  // don't care if succeed
    [self findForward:YES];
}


// ------------------------------------------------------
/// replace all matched strings with given string
- (IBAction)replaceAll:(nullable id)sender
// ------------------------------------------------------
{
    if (![self checkIsReadyToFind]) { return; }
    
    NSNumberFormatter *integerFormatter = [self integerFormatter];
    NSTextView *textView = [self client];
    OGRegularExpression *regex = [self regex];
    OGReplaceExpression *repex = [self repex];
    NSArray<NSValue *> *scopeRanges = [self scopeRanges];
    BOOL inSelection = [self inSelection];
    NSString *string = [textView string];
    
    // setup progress sheet
    __block BOOL isCancelled = NO;
    CEProgressSheetController *indicator = [[CEProgressSheetController alloc] initWithMessage:NSLocalizedString(@"Replace All", nil)];
    [indicator setIndetermine:YES];
    [indicator beginSheetForWindow:[textView window] completionHandler:^(NSModalResponse returnCode) {
        if (returnCode == NSCancelButton) {
            isCancelled = YES;
        }
    }];
    
    __weak typeof(self) weakSelf = self;
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        typeof(self) self = weakSelf;
        if (!self) { return; }
        
        NSMutableArray<NSString *> *replacementStrings = [NSMutableArray array];
        NSMutableArray<NSValue *> *replacementRanges = [NSMutableArray array];
        NSMutableArray<NSValue *> *selectedRanges = [NSMutableArray array];
        NSUInteger count = 0;
        NSInteger delta = 0;
        
        for (NSValue *rangeValue in scopeRanges) {
            NSRange scopeRange = [rangeValue rangeValue];
            NSEnumerator<OGRegularExpressionMatch *> *enumerator = [regex matchEnumeratorInString:string range:scopeRange];
            
            NSRange selectedRange = scopeRange;
            selectedRange.location += delta;
            
            OGRegularExpressionMatch *match;
            while ((match = [enumerator nextObject])) {
                if (isCancelled) {
                    [indicator close:self];
                    return;
                }
                
                NSString *replacedString = [repex replaceMatchedStringOf:match];
                NSRange replacementRange = [match rangeOfMatchedString];
                
                [replacementStrings addObject:replacedString];
                [replacementRanges addObject:[NSValue valueWithRange:replacementRange]];
                selectedRange.length -= (NSInteger)replacementRange.length - [replacedString length];
                count++;
                
                NSString *informative = (count == 1) ? @"%@ string replaced." : @"%@ strings replaced.";
                NSString *countStr = [integerFormatter stringFromNumber:@(count)];
                dispatch_async(dispatch_get_main_queue(), ^{
                    [indicator setInformativeText:[NSString stringWithFormat:NSLocalizedString(informative, nil), countStr]];
                });
            }
            
            delta += (NSInteger)selectedRange.length - scopeRange.length;
            [selectedRanges addObject:[NSValue valueWithRange:selectedRange]];
        }
        
        dispatch_async(dispatch_get_main_queue(), ^{
            [indicator doneWithButtonTitle:nil];
            
            if (count > 0) {
                // apply found strings to the text view
                [textView replaceWithStrings:replacementStrings ranges:replacementRanges
                              selectedRanges:inSelection ? selectedRanges : nil
                                  actionName:NSLocalizedString(@"Replace All", nil)];
                
            } else {
                NSBeep();
                [indicator setInformativeText:NSLocalizedString(@"Not Found.", nil)];
            }
            
            if ([self closesIndicatorWhenDone]) {
                [indicator close:self];
            }
        });
    });
    
    [self appendFindHistory:[self findString]];
    [self appendReplaceHistory:[self replacementString]];
}


// ------------------------------------------------------
/// set selected string to find field
- (IBAction)useSelectionForFind:(nullable id)sender
// ------------------------------------------------------
{
    NSString *selectedString = [self selectedString];
    
    if (selectedString) {
        [self setFindString:selectedString];
    } else {
        NSBeep();
    }
}


// ------------------------------------------------------
/// set selected string to replace field
- (IBAction)useSelectionForReplace:(nullable id)sender
// ------------------------------------------------------
{
    NSString *selectedString = [self selectedString] ?: @"";
    
    [self setReplacementString:selectedString];
}


// ------------------------------------------------------
/// jump to selection in client
- (IBAction)centerSelectionInVisibleArea:(nullable id)sender
// ------------------------------------------------------
{
    [[self client] centerSelectionInVisibleArea:sender];
}



#pragma mark Private Methods

// ------------------------------------------------------
/// target text view
- (nullable NSTextView *)client
// ------------------------------------------------------
{
    id<CETextFinderClientProvider> provider = [NSApp targetForAction:@selector(focusedTextView)];
    if (provider) {
        return [provider focusedTextView];
    }
    
    return nil;
}


// ------------------------------------------------------
/// selected string in the current tareget
- (nullable NSString *)selectedString
// ------------------------------------------------------
{
    NSRange selectedRange = [[self client] selectedRange];
    
    if (selectedRange.length == 0) { return nil; }
    
    return [[[self client] string] substringWithRange:selectedRange];
}


// ------------------------------------------------------
/// ranges to find in
- (NSArray<NSValue *> *)scopeRanges
// ------------------------------------------------------
{
    NSTextView *textView = [self client];
    
    return [self inSelection] ? [textView selectedRanges] : @[[NSValue valueWithRange:NSMakeRange(0, [[textView string] length])]];
}


// ------------------------------------------------------
/// find string of which line endings are standardized to LF
- (NSString *)sanitizedFindString
// ------------------------------------------------------
{
    return [OGRegularExpression replaceNewlineCharactersInString:[self findString]
                                                   withCharacter:OgreLfNewlineCharacter];
}


// ------------------------------------------------------
/// syntax (and regex enability) setting in textFinder
- (OgreSyntax)textFinderSyntax
// ------------------------------------------------------
{
    return [self usesRegularExpression] ? [self syntax] : OgreSimpleMatchingSyntax;
}


// ------------------------------------------------------
/// OgreKit regex object with current settings
- (nullable OGRegularExpression *)regex
// ------------------------------------------------------
{
    return [OGRegularExpression regularExpressionWithString:[self sanitizedFindString]
                                                    options:[self options]
                                                     syntax:[self textFinderSyntax]
                                            escapeCharacter:kEscapeCharacter];
}


// ------------------------------------------------------
/// OgreKit replacement object with current settings
- (nullable OGReplaceExpression *)repex
// ------------------------------------------------------
{
    return [OGReplaceExpression replaceExpressionWithString:[self replacementString] ?: @""
                                                     syntax:[self textFinderSyntax]
                                            escapeCharacter:kEscapeCharacter];
}


// ------------------------------------------------------
/// perform "Find Next" or "Find Previous" and return number of found
- (NSUInteger)findForward:(BOOL)forward
// ------------------------------------------------------
{
    if (![self checkIsReadyToFind]) { return 0; }
    
    NSTextView *textView = [self client];
    NSUInteger startLocation = forward ? NSMaxRange([textView selectedRange]) : [textView selectedRange].location;
    
    NSEnumerator<OGRegularExpressionMatch *> *enumerator = [[self regex] matchEnumeratorInString:[textView string] options:0];
    NSArray<OGRegularExpressionMatch *> *matches = [enumerator allObjects];
    OGRegularExpressionMatch *foundMatch = nil;
    
    if (forward) {  // forward
        for (OGRegularExpressionMatch *match in matches) {
            if ([match rangeOfMatchedString].location >= startLocation) {
                foundMatch = match;
                break;
            }
        }
    } else {  // backward
        for (OGRegularExpressionMatch *match in [matches reverseObjectEnumerator]) {
            if ([match rangeOfMatchedString].location < startLocation) {
                foundMatch = match;
                break;
            }
        }
    }
    
    // wrap search
    BOOL isWrapped = NO;
    if (!foundMatch && [self isWrap]) {
        if ((foundMatch = forward ? [matches firstObject] : [matches lastObject])) {
            isWrapped = YES;
        }
    }
    
    // found feedback
    if (foundMatch) {
        NSRange foundRange = [foundMatch rangeOfMatchedString];
        [textView setSelectedRange:foundRange];
        [textView scrollRangeToVisible:foundRange];
        [textView showFindIndicatorForRange:foundRange];
        
        if (isWrapped) {
            if (NSAppKitVersionNumber >= NSAppKitVersionNumber10_10) {
                CEHUDController *HUDController = [[CEHUDController alloc] initWithSymbolName:CEWrapSymbolName];
                [HUDController setReversed:!forward];
                [HUDController showInView:[[textView enclosingScrollView] superview]];
            }
        }
    } else {
        NSBeep();
    }
    if ([[self delegate] respondsToSelector:@selector(textFinder:didFound:textView:)]) {
        [[self delegate] textFinder:self didFound:[matches count] textView:textView];
    }
    
    [self appendFindHistory:[self findString]];
    
    return [matches count];
}


// ------------------------------------------------------
/// replace matched string in selection with replacementStirng
- (BOOL)replace
// ------------------------------------------------------
{
    NSTextView *textView = [self client];
    
    unsigned options = [self options] & ~(OgreNotBOLOption | OgreNotEOLOption);  // see OgreReplaceAndFindThread.m
    OGRegularExpressionMatch *match = [[self regex] matchInString:[textView string] options:options range:[textView selectedRange]];
    
    if (!match) { return NO; }
    
    NSRange replacementRange = [match rangeOfMatchedString];
    NSString *replacedString = [[self repex] replaceMatchedStringOf:match];
    
    // apply replacement to text view
    return [textView replaceWithString:replacedString range:replacementRange
                         selectedRange:NSMakeRange(replacementRange.location, [replacedString length])
                            actionName:NSLocalizedString(@"Replace", nil)];
}


// ------------------------------------------------------
/// check Find can be performed and alert if needed
- (BOOL)checkIsReadyToFind
// ------------------------------------------------------
{
    if (![self client]) {
        NSBeep();
        return NO;
    }
    
    NSWindow *findPanel = [[self findPanelController] window];
    if ([findPanel attachedSheet]) {
        [findPanel makeKeyAndOrderFront:self];
        NSBeep();
        return NO;
    }
    
    if ([[self findString] length] == 0) {
        NSBeep();
        return NO;
    }
    
    // check regex syntax of find string and alert if invalid
    if ([self usesRegularExpression]) {
        @try {
            [self regex];
            
        } @catch (NSException *exception) {
            if ([[exception name] isEqualToString:OgreException]) {
                NSError *error = [NSError errorWithDomain:CEErrorDomain
                                                     code:CERegularExpressionError
                                                 userInfo:@{NSLocalizedDescriptionKey: NSLocalizedString(@"Invalid regular expression", nil),
                                                            NSLocalizedRecoverySuggestionErrorKey: [exception reason]}];
                NSWindow *findPanel = [[self findPanelController] window];
                [self presentError:error modalForWindow:findPanel delegate:nil didPresentSelector:NULL contextInfo:NULL];
            } else {
                [exception raise];
            }
            return NO;
        }
    }
    
    return YES;
}


// ------------------------------------------------------
/// load find string from global domain
- (nullable NSString *)findStringFromPasteboard
// ------------------------------------------------------
{
    NSPasteboard *pasteboard = [NSPasteboard pasteboardWithName:NSFindPboard];
    
    return [pasteboard stringForType:NSStringPboardType];
}


// ------------------------------------------------------
/// put local find string to global domain
- (void)setFindStringToPasteboard:(nonnull NSString *)string
// ------------------------------------------------------
{
    if ([string length] == 0) { return; }
    
    NSPasteboard *pasteboard = [NSPasteboard pasteboardWithName:NSFindPboard];
    
    [pasteboard declareTypes:@[NSStringPboardType] owner:nil];
    [pasteboard setString:string forType:NSStringPboardType];
}


// ------------------------------------------------------
/// append given string to find history
- (void)appendFindHistory:(nonnull NSString *)string
// ------------------------------------------------------
{
    if ([string length] == 0) { return; }
    
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    
    // append new string to history
    NSMutableArray<NSString *> *history = [NSMutableArray arrayWithArray:[defaults stringArrayForKey:CEDefaultFindHistoryKey]];
    [history removeObject:string];  // remove duplicated item
    [history addObject:string];
    if ([history count] > kMaxHistorySize) {  // remove overflow
        [history removeObjectsInRange:NSMakeRange(0, [history count] - kMaxHistorySize)];
    }
    
    [defaults setObject:history forKey:CEDefaultFindHistoryKey];
    
    if ([[self delegate] respondsToSelector:@selector(textFinderDidUpdateFindHistory)]) {
        [[self delegate] textFinderDidUpdateFindHistory];
    }
}


// ------------------------------------------------------
/// append given string to replace history
- (void)appendReplaceHistory:(nonnull NSString *)string
// ------------------------------------------------------
{
    if ([string length] == 0) { return; }
    
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    
    // append new string to history
    NSMutableArray<NSString *> *history = [NSMutableArray arrayWithArray:[defaults stringArrayForKey:CEDefaultReplaceHistoryKey]];
    [history removeObject:string];  // remove duplicated item
    [history addObject:string];
    if ([history count] > kMaxHistorySize) {  // remove overflow
        [history removeObjectsInRange:NSMakeRange(0, [history count] - kMaxHistorySize)];
    }
    
    [defaults setObject:history forKey:CEDefaultReplaceHistoryKey];
    
    if ([[self delegate] respondsToSelector:@selector(textFinderDidUpdateReplaceHistory)]) {
        [[self delegate] textFinderDidUpdateReplaceHistory];
    }
}



#pragma mark Private Dynamic Accessors

// ------------------------------------------------------
/// return value from user defaults
- (BOOL)usesRegularExpression
// ------------------------------------------------------
{
    return [[NSUserDefaults standardUserDefaults] boolForKey:CEDefaultFindUsesRegularExpressionKey];
}


// ------------------------------------------------------
/// return value from user defaults
- (BOOL)isWrap
// ------------------------------------------------------
{
    return [[NSUserDefaults standardUserDefaults] boolForKey:CEDefaultFindIsWrapKey];
}


// ------------------------------------------------------
/// return value from user defaults
- (BOOL)inSelection
// ------------------------------------------------------
{
    return [[NSUserDefaults standardUserDefaults] boolForKey:CEDefaultFindInSelectionKey];
}


// ------------------------------------------------------
/// return value from user defaults
- (OgreSyntax)syntax
// ------------------------------------------------------
{
    return [[NSUserDefaults standardUserDefaults] integerForKey:CEDefaultFindRegexSyntaxKey];
}


// ------------------------------------------------------
/// return value from user defaults
- (unsigned)options
// ------------------------------------------------------
{
    return [[NSUserDefaults standardUserDefaults] integerForKey:CEDefaultFindOptionsKey];
}


// ------------------------------------------------------
/// return value from user defaults
- (BOOL)closesIndicatorWhenDone
// ------------------------------------------------------
{
    return [[NSUserDefaults standardUserDefaults] boolForKey:CEDefaultFindClosesIndicatorWhenDoneKey];
}

@end
