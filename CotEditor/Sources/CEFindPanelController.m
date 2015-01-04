/*
 ==============================================================================
 CEFindPanelController
 
 CotEditor
 http://coteditor.com
 
 Created on 2014-12-30 by 1024jp
 encoding="UTF-8"
 ------------------------------------------------------------------------------
 
 © 2014-2015 1024jp
 
 This program is free software; you can redistribute it and/or modify it under
 the terms of the GNU General Public License as published by the Free Software
 Foundation; either version 2 of the License, or (at your option) any later
 version.
 
 This program is distributed in the hope that it will be useful, but WITHOUT
 ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS
 FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.
 
 You should have received a copy of the GNU General Public License along with
 this program; if not, write to the Free Software Foundation, Inc., 59 Temple
 Place - Suite 330, Boston, MA  02111-1307, USA.
 
 ==============================================================================
 */

#import <OgreKit/OgreKit.h>
#import "CEFindPanelController.h"
#import "CETextFinder.h"
#import "constants.h"


// constants
static const NSUInteger kMaxHistorySize = 20;
static const int kMaxLeftMargin = 30;   // 検索結果の左側の最大文字数 (マッチ結果が隠れてしまうことを防ぐ)
static const int kMaxMatchedStringLength = 250; // 検索結果の最大文字数


@interface CEFindPanelController () <NSWindowDelegate>

@property (nonatomic, copy) NSString *findString;
@property (nonatomic, copy) NSString *replacementString;

@property (nonatomic) NSColor *highlightColor;

// settings
@property (readonly, nonatomic) BOOL usesRegularExpression;
@property (readonly, nonatomic) BOOL isWrap;
@property (readonly, nonatomic) BOOL inSection;
@property (readonly, nonatomic) BOOL closesIndicatorWhenDone;
@property (readonly, nonatomic) OgreSyntax syntax;

// options
@property (nonatomic) BOOL ignoreCaseOption;
@property (nonatomic) BOOL singleLineOption;
@property (nonatomic) BOOL multilineOption;
@property (nonatomic) BOOL extendOption;
@property (nonatomic) BOOL findLongestOption;
@property (nonatomic) BOOL findNotEmptyOption;
@property (nonatomic) BOOL findEmptyOption;
@property (nonatomic) BOOL negateSingleLineOption;
@property (nonatomic) BOOL captureGroupOption;
@property (nonatomic) BOOL dontCaptureGroupOption;
@property (nonatomic) BOOL delimitByWhitespaceOption;
@property (nonatomic) BOOL notBeginOfLineOption;
@property (nonatomic) BOOL notEndOfLineOption;

// outlets
@property (nonatomic, weak) IBOutlet NSMenu *findHistoryMenu;
@property (nonatomic, weak) IBOutlet NSMenu *replaceHistoryMenu;

@end




#pragma mark -

@implementation CEFindPanelController

#pragma mark Superclass Methods

// ------------------------------------------------------
/// initialize instance
- (instancetype)init
// ------------------------------------------------------
{
    self = [super init];
    if (self) {
        _findString = @"";
        _replacementString = @"";
        _highlightColor = [NSColor yellowColor];
        // Highlight color is currently not customizable. (2014-01-04)
        // It might better when it can be set in theme also for incompatible chars highlight.
        // Just because I'm lazy.
        
        // deserialize options setting from defaults
        [self setOptions:[[NSUserDefaults standardUserDefaults] integerForKey:CEDefaultFindOptionsKey]];
    }
    return self;
}


// ------------------------------------------------------
/// setup UI
- (void)awakeFromNib
// ------------------------------------------------------
{
    [super awakeFromNib];
    
    [self updateFindHistoryMenu];
    [self updateReplaceHistoryMenu];
    
    [[self textFinder] setEscapeCharacter:[[NSUserDefaults standardUserDefaults] stringForKey:CEDefaultFindEscapeCharacterKey]];
}


// ------------------------------------------------------
/// complemention notification for "Find All" (required)
- (BOOL)didEndFindAll:(id)anObject
// ------------------------------------------------------
{
    OgreTextFindResult *result = (OgreTextFindResult *)anObject;
    
    if ([result alertIfErrorOccurred]) { return NO; }
    if (![result isSuccess]) { return [self closesIndicatorWhenDone]; }
    
    // prepare result table
    [result setMaximumLeftMargin:kMaxLeftMargin];
    [result setMaximumMatchedStringLength:kMaxMatchedStringLength];
    // TODO: implement result display
    [self showFindPanel:self];
    
    return YES;
}


// ------------------------------------------------------
/// complemention notification for "Replace All" (required)
- (BOOL)didEndReplaceAll:(id)anObject
// ------------------------------------------------------
{
    NSTextView *target = [self target];
    
    // post notification
    dispatch_async(dispatch_get_main_queue(), ^{
        [[NSNotificationCenter defaultCenter] postNotificationName:CETextFinderDidReplaceAllNotification
                                                            object:target];
    });
    
    return [self closesIndicatorWhenDone];
}


// ------------------------------------------------------
/// complemention notification for "Highlight" (required)
- (BOOL)didEndHighlight:(id)anObject
// ------------------------------------------------------
{
    return [self closesIndicatorWhenDone];
}


// ------------------------------------------------------
/// add check mark to selectable menus
- (BOOL)validateMenuItem:(NSMenuItem *)menuItem
// ------------------------------------------------------
{
    if ([menuItem action] == @selector(changeSyntax:)) {
        OgreSyntax syntax = [[NSUserDefaults standardUserDefaults] integerForKey:CEDefaultFindRegexSyntaxKey];
        [menuItem setState:([menuItem tag] == syntax) ? NSOnState : NSOffState];
    
    } else if ([menuItem action] == @selector(changeEscapeCharacter:)) {
        NSString *escapeCharacter = [[self textFinder] escapeCharacter];
        [menuItem setState:([[menuItem title] isEqualToString:escapeCharacter]) ? NSOnState : NSOffState];
    }
    
    return YES;
}



#pragma mark Public Action Messages

// ------------------------------------------------------
/// activate find panel
- (IBAction)showFindPanel:(id)sender
// ------------------------------------------------------
{
    // sync search string
    if (![[self findPanel] isVisible] &&
        [[NSUserDefaults standardUserDefaults] boolForKey:CEDefaultSyncFindPboardKey])
    {
        [self setFindString:[self findStringFromPasteboard]];
    }
    
    [super showFindPanel:sender];
}


// ------------------------------------------------------
/// find next matched string
- (IBAction)findNext:(id)sender
// ------------------------------------------------------
{
    [self findFoward:YES];
}


// ------------------------------------------------------
/// find previous matched string
- (IBAction)findPrevious:(id)sender
// ------------------------------------------------------
{
    [self findFoward:NO];
}


// ------------------------------------------------------
/// perform find action with the selected string
- (IBAction)findSelectedText:(id)sender
// ------------------------------------------------------
{
    [self useSelectionForFind:sender];
    [self findNext:sender];
}


// ------------------------------------------------------
/// find all matched string in the target and show results in a table
- (IBAction)findAll:(id)sender
// ------------------------------------------------------
{
    OgreTextFindResult *result = [[self textFinder] findAll:[self findString]
                                                      color:[self highlightColor]
                                                    options:[self options]
                                                inSelection:[self inSelection]];
    
    [self appendFindHistory:[self findString]];
    
    if ([result isSuccess]) {
        
    } else {
        NSBeep();
    }
}


// ------------------------------------------------------
/// set selected string to find field
- (IBAction)useSelectionForFind:(id)sender
// ------------------------------------------------------
{
    NSString *selectedString = [[self textFinder] selectedString];
    
    if (selectedString) {
        [self setFindString:selectedString];
        [self showFindPanel:sender];
    } else {
        NSBeep();
    }
}


// ------------------------------------------------------
/// set selected string to replace field
- (IBAction)useSelectionForReplace:(id)sender
// ------------------------------------------------------
{
    NSString *selectedString = [[self textFinder] selectedString];
    
    if (selectedString) {
        [self setReplacementString:selectedString];
        [self showFindPanel:sender];
    } else {
        NSBeep();
    }
}


// ------------------------------------------------------
/// replace next matched string with given string
- (IBAction)replace:(id)sender
// ------------------------------------------------------
{
    OgreTextFindResult *result = [[self textFinder] replace:[self findString]
                                                 withString:[self replacementString]
                                                    options:[self options]];
    
    [self appendFindHistory:[self findString]];
    [self appendReplaceHistory:[self replacementString]];
}


// ------------------------------------------------------
/// replace next matched string with given string and select the one after the next match
- (IBAction)replaceAndFind:(id)sender
// ------------------------------------------------------
{
    OgreTextFindResult *result = [[self textFinder] replaceAndFind:[self findString]
                                                        withString:[self replacementString]
                                                           options:[self options]
                                                     replacingOnly:NO
                                                              wrap:[self isWrap]];
    
    [self appendFindHistory:[self findString]];
    [self appendReplaceHistory:[self replacementString]];
}


// ------------------------------------------------------
/// replace all matched strings with given string
- (IBAction)replaceAll:(id)sender
// ------------------------------------------------------
{
    OgreTextFindResult *result = [[self textFinder] replaceAll:[self findString]
                                                    withString:[self replacementString]
                                                       options:[self options]
                                                   inSelection:[self inSelection]];
    
    [self appendFindHistory:[self findString]];
    [self appendReplaceHistory:[self replacementString]];
}


// ------------------------------------------------------
/// highlight all matched strings
- (IBAction)highlight:(id)sender
// ------------------------------------------------------
{
    [[self textFinder] hightlight:[self findString]
                            color:[self highlightColor]
                          options:[self options]
                      inSelection:[self inSelection]];
    
    [self appendFindHistory:[self findString]];
}


// ------------------------------------------------------
/// remove all of current highlights
- (IBAction)unhighlight:(id)sender
// ------------------------------------------------------
{
    [[self textFinder] unhightlight];
}



#pragma mark Private Action Messages

// ------------------------------------------------------
/// perform segmented Find Next/Previous button
- (IBAction)clickSegmentedFindButton:(NSSegmentedControl *)sender
// ------------------------------------------------------
{
    switch ([sender selectedSegment]) {
        case 0:
            [self findPrevious:sender];
            break;
        case 1:
            [self findNext:sender];
            break;
        default:
            break;
    }
}


// ------------------------------------------------------
/// set selected history string to find field
- (IBAction)selectFindHistory:(id)sender
// ------------------------------------------------------
{
    [self setFindString:[sender title]];
}


// ------------------------------------------------------
/// set selected history string to replacement field
- (IBAction)selectReplaceHistory:(id)sender
// ------------------------------------------------------
{
    [self setReplacementString:[sender title]];
}


// ------------------------------------------------------
/// restore find history via UI
- (IBAction)clearFindHistory:(id)sender
// ------------------------------------------------------
{
    [[self findPanel] makeKeyAndOrderFront:self];
    
    [[NSUserDefaults standardUserDefaults] removeObjectForKey:CEDefaultFindHistoryKey];
    [self updateFindHistoryMenu];
}


// ------------------------------------------------------
/// restore replace history via UI
- (IBAction)clearReplaceHistory:(id)sender
// ------------------------------------------------------
{
    [[self findPanel] makeKeyAndOrderFront:self];
    
    [[NSUserDefaults standardUserDefaults] removeObjectForKey:CEDefaultReplaceHistoryKey];
    [self updateReplaceHistoryMenu];
}


// ------------------------------------------------------
/// change regex syntax setting via menu item
- (IBAction)changeSyntax:(id)sender
// ------------------------------------------------------
{
    [[NSUserDefaults standardUserDefaults] setInteger:[sender tag] forKey:CEDefaultFindRegexSyntaxKey];
}


// ------------------------------------------------------
/// change escape character setting via menu item
- (IBAction)changeEscapeCharacter:(id)sender
// ------------------------------------------------------
{
    NSString *escapeCharater = [sender title];
    
    [[self textFinder] setEscapeCharacter:escapeCharater];
    [[NSUserDefaults standardUserDefaults] setInteger:escapeCharater forKey:CEDefaultFindEscapeCharacterKey];
}


// ------------------------------------------------------
/// option is toggled
- (IBAction)toggleOption:(id)sender
// ------------------------------------------------------
{
    [[NSUserDefaults standardUserDefaults] setInteger:[self options] forKey:CEDefaultFindOptionsKey];
}



#pragma mark Private Methods

// ------------------------------------------------------
/// return current target textView
- (NSTextView *)target
// ------------------------------------------------------
{
    return [[self textFinder] targetToFindIn];
}


// ------------------------------------------------------
/// perform "Find Next" and "Find Previous"
- (void)findFoward:(BOOL)forward
// ------------------------------------------------------
{
    [[self textFinder] setSyntax:[self usesRegularExpression] ? [self syntax] : OgreSimpleMatchingSyntax];
    
    OgreTextFindResult *result = [[self textFinder] find:[self findString]
                                                 options:[self options]
                                                 fromTop:NO
                                                 forward:forward
                                                    wrap:[self isWrap]];
    
    [self appendFindHistory:[self findString]];
    
    if ([result alertIfErrorOccurred]) { return; }
    
    if ([result isSuccess]) {
        // add visual feedback
        [[self target] showFindIndicatorForRange:[[self target] selectedRange]];
        
    } else {
        NSBeep();
    }
}


// ------------------------------------------------------
/// update find history menu
- (void)updateFindHistoryMenu
// ------------------------------------------------------
{
    [self buildHistoryMenu:[self findHistoryMenu]
                defautsKey:CEDefaultFindHistoryKey
                  selector:@selector(selectFindHistory:)];
}


// ------------------------------------------------------
/// update replace history menu
- (void)updateReplaceHistoryMenu
// ------------------------------------------------------
{
    [self buildHistoryMenu:[self replaceHistoryMenu]
                defautsKey:CEDefaultReplaceHistoryKey
                  selector:@selector(selectReplaceHistory:)];
}


// ------------------------------------------------------
/// apply history to UI
- (void)buildHistoryMenu:(NSMenu *)menu defautsKey:(NSString *)key selector:(SEL)selector
// ------------------------------------------------------
{
    NSArray *history = [[NSUserDefaults standardUserDefaults] stringArrayForKey:key];
    
    // clear current history items
    for (NSMenuItem *item in [menu itemArray]) {
        if ([item action] == selector || [item isSeparatorItem]) {
            [menu removeItem:item];
        }
    }
    
    if ([history count] == 0) { return; }
    
    [menu insertItem:[NSMenuItem separatorItem] atIndex:1];  // the first item is invisible dummy
    
    for (NSString *stirng in history) {
        NSMenuItem *item = [[NSMenuItem alloc] initWithTitle:stirng
                                                      action:selector
                                               keyEquivalent:@""];
        [item setTarget:self];
        [menu insertItem:item atIndex:1];
    }
}


// ------------------------------------------------------
/// append given string to find history
- (void)appendFindHistory:(NSString *)string
// ------------------------------------------------------
{
    if ([string length] == 0) { return; }
    
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    
    // sync search string
    if ([defaults boolForKey:CEDefaultSyncFindPboardKey]) {
        [self setFindStringToPasteboard:string];
    }
    
    // append new string to history
    NSMutableArray *history = [NSMutableArray arrayWithArray:[defaults stringArrayForKey:CEDefaultFindHistoryKey]];
    [history removeObject:string];  // remove duplicated item
    [history addObject:string];
    if ([history count] > kMaxHistorySize) {  // remove overflow
        [history removeObjectsInRange:NSMakeRange(0, [history count] - kMaxHistorySize)];
    }
    
    [defaults setObject:history forKey:CEDefaultFindHistoryKey];
    
    [self updateFindHistoryMenu];
}


// ------------------------------------------------------
/// append given string to replace history
- (void)appendReplaceHistory:(NSString *)string
// ------------------------------------------------------
{
    if ([string length] == 0) { return; }
    
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    
    // append new string to history
    NSMutableArray *history = [NSMutableArray arrayWithArray:[defaults stringArrayForKey:CEDefaultReplaceHistoryKey]];
    [history removeObject:string];  // remove duplicated item
    [history addObject:string];
    if ([history count] > kMaxHistorySize) {  // remove overflow
        [history removeObjectsInRange:NSMakeRange(0, [history count] - kMaxHistorySize)];
    }
    
    [defaults setObject:history forKey:CEDefaultReplaceHistoryKey];
    
    [self updateReplaceHistoryMenu];
}


// ------------------------------------------------------
/// load find string from global domain
- (NSString *)findStringFromPasteboard
// ------------------------------------------------------
{
    NSPasteboard *pasteboard = [NSPasteboard pasteboardWithName:NSFindPboard];
    
    return [pasteboard stringForType:NSStringPboardType];
}


// ------------------------------------------------------
/// put local find string to global domain
- (void)setFindStringToPasteboard:(NSString *)string
// ------------------------------------------------------
{
    if ([string length] == 0) { return; }
    
    NSPasteboard *pasteboard = [NSPasteboard pasteboardWithName:NSFindPboard];
    
    [pasteboard declareTypes:@[NSStringPboardType] owner:nil];
    [pasteboard setString:string forType:NSStringPboardType];
}


// ------------------------------------------------------
/// serialize bit option value from instance booleans
- (unsigned)options
// ------------------------------------------------------
{
    unsigned options = OgreNoneOption;
    
    if ([self singleLineOption])          { options |= OgreSingleLineOption; }
    if ([self multilineOption])           { options |= OgreMultilineOption; }
    if ([self ignoreCaseOption])          { options |= OgreIgnoreCaseOption; }
    if ([self extendOption])              { options |= OgreExtendOption; }
    if ([self findLongestOption])         { options |= OgreFindLongestOption; }
    if ([self findNotEmptyOption])        { options |= OgreFindNotEmptyOption; }
    if ([self findEmptyOption])           { options |= OgreFindEmptyOption; }
    if ([self negateSingleLineOption])    { options |= OgreNegateSingleLineOption; }
    if ([self captureGroupOption])        { options |= OgreCaptureGroupOption; }
    if ([self dontCaptureGroupOption])    { options |= OgreDontCaptureGroupOption; }
    if ([self delimitByWhitespaceOption]) { options |= OgreDelimitByWhitespaceOption; }
    if ([self notBeginOfLineOption])      { options |= OgreNotBOLOption; }
    if ([self notEndOfLineOption])        { options |= OgreNotEOLOption; }
    
    return options;
}


// ------------------------------------------------------
/// deserialize bit option value to instance booleans
- (void)setOptions:(unsigned)options
// ------------------------------------------------------
{
    [self setSingleLineOption:((options & OgreSingleLineOption) != 0)];
    [self setMultilineOption:((options & OgreMultilineOption) != 0)];
    [self setIgnoreCaseOption:((options & OgreIgnoreCaseOption) != 0)];
    [self setExtendOption:((options & OgreExtendOption) != 0)];
    [self setFindLongestOption:((options & OgreFindLongestOption) != 0)];
    [self setFindNotEmptyOption:((options & OgreFindNotEmptyOption) != 0)];
    [self setFindEmptyOption:((options & OgreFindEmptyOption) != 0)];
    [self setNegateSingleLineOption:((options & OgreNegateSingleLineOption) != 0)];
    [self setCaptureGroupOption:((options & OgreCaptureGroupOption) != 0)];
    [self setDontCaptureGroupOption:((options & OgreDontCaptureGroupOption) != 0)];
    [self setDelimitByWhitespaceOption:((options & OgreDelimitByWhitespaceOption) != 0)];
    [self setNotBeginOfLineOption:((options & OgreNotBOLOption) != 0)];
    [self setNotEndOfLineOption:((options & OgreNotEOLOption) != 0)];
}



#pragma mark Private Dynamic Accessors

@dynamic usesRegularExpression;
// ------------------------------------------------------
/// return value from user defaults
- (BOOL)usesRegularExpression
// ------------------------------------------------------
{
    return [[NSUserDefaults standardUserDefaults] boolForKey:CEDefaultFindUsesRegularExpressionKey];
}


@dynamic isWrap;
// ------------------------------------------------------
/// return value from user defaults
- (BOOL)isWrap
// ------------------------------------------------------
{
    return [[NSUserDefaults standardUserDefaults] boolForKey:CEDefaultFindIsWrapKey];
}


@dynamic inSection;
// ------------------------------------------------------
/// return value from user defaults
- (BOOL)inSelection
// ------------------------------------------------------
{
    return [[NSUserDefaults standardUserDefaults] boolForKey:CEDefaultFindInSelectionKey];
}


@dynamic syntax;
// ------------------------------------------------------
/// return value from user defaults
- (OgreSyntax)syntax
// ------------------------------------------------------
{
    return [[NSUserDefaults standardUserDefaults] integerForKey:CEDefaultFindRegexSyntaxKey];
}


@dynamic closesIndicatorWhenDone;
// ------------------------------------------------------
/// return value from user defaults
- (BOOL)closesIndicatorWhenDone
// ------------------------------------------------------
{
    return [[NSUserDefaults standardUserDefaults] boolForKey:CEDefaultFindClosesIndicatorWhenDoneKey];
}

@end
