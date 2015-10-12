/*
 
 CEFindPanelController.m
 
 CotEditor
 http://coteditor.com
 
 Created by 1024jp on 2014-12-30.

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

#import <OgreKit/OgreKit.h>
#import "CEFindPanelController.h"
#import "CEFindResultViewController.h"
#import "CETextFinder.h"
#import "Constants.h"


// constants
static const CGFloat kDefaultResultViewHeight = 200.0;
static const NSUInteger kMaxHistorySize = 20;
static NSString *_Nonnull const kEscapeCharacter = @"\\";


@interface CEFindPanelController () <NSWindowDelegate, NSSplitViewDelegate, NSPopoverDelegate>

@property (nonatomic, nonnull, copy) NSString *findString;
@property (nonatomic, nonnull, copy) NSString *replacementString;

@property (nonatomic, nonnull) NSColor *highlightColor;
@property (nonatomic, nullable) NSLayoutConstraint *resultHeightConstraint;  // for autolayout on OS X 10.8

#pragma mark Settings
@property (readonly, nonatomic) BOOL usesRegularExpression;
@property (readonly, nonatomic) BOOL isWrap;
@property (readonly, nonatomic) BOOL inSection;
@property (readonly, nonatomic) BOOL closesIndicatorWhenDone;
@property (readonly, nonatomic) OgreSyntax syntax;

#pragma mark Options
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

#pragma mark Outlets
@property (nonatomic) IBOutlet CEFindResultViewController *resultViewController;
@property (nonatomic) IBOutlet NSPopover *regexPopover;
@property (nonatomic, nullable, weak) IBOutlet NSSplitView *splitView;
@property (nonatomic, nullable, weak) IBOutlet NSButton *disclosureButton;
@property (nonatomic, nullable, weak) IBOutlet NSMenu *findHistoryMenu;
@property (nonatomic, nullable, weak) IBOutlet NSMenu *replaceHistoryMenu;
@property (nonatomic, nullable, weak) IBOutlet NSButton *replaceButton;

@end




#pragma mark -

@implementation CEFindPanelController

#pragma mark Superclass Methods

// ------------------------------------------------------
/// initialize instance
- (nonnull instancetype)init
// ------------------------------------------------------
{
    // [attention] This method can be invoked before initializing user defaults in CEAppDelegate.
    
    self = [super init];
    if (self) {
        _findString = @"";
        _replacementString = @"";
        _highlightColor = [NSColor colorWithCalibratedHue:0.24 saturation:0.8 brightness:0.8 alpha:0.4];
        // Highlight color is currently not customizable. (2015-01-04)
        // It might better when it can be set in theme also for incompatible chars highlight.
        // Just because I'm lazy.
        
        // deserialize options setting from defaults
        [self setOptions:[[NSUserDefaults standardUserDefaults] integerForKey:CEDefaultFindOptionsKey]];
        
        // add to responder chain
        [NSApp setNextResponder:self];
        
        // observe default change for the "Replace" button tooltip
        [[NSUserDefaults standardUserDefaults] addObserver:self
                                                forKeyPath:CEDefaultFindNextAfterReplaceKey
                                                   options:NSKeyValueObservingOptionNew
                                                   context:NULL];
        
        // observe application activation
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(applicationDidBecomeActive:)
                                                     name:NSApplicationDidBecomeActiveNotification
                                                   object:nil];
    }
    return self;
}


// ------------------------------------------------------
/// clean up
- (void)dealloc
// ------------------------------------------------------
{
    [[NSUserDefaults standardUserDefaults] removeObserver:self forKeyPath:CEDefaultFindNextAfterReplaceKey];
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    
    [_splitView setDelegate:nil];  // NSSplitView's delegate is assign, not weak
}


// ------------------------------------------------------
/// setup UI
- (void)awakeFromNib
// ------------------------------------------------------
{
    // [attention] This method can be invoked before initializing user defaults in CEAppDelegate.
    
    [super awakeFromNib];
    
    [self updateFindHistoryMenu];
    [self updateReplaceHistoryMenu];
    
    [[self textFinder] setEscapeCharacter:kEscapeCharacter];
    
    [self toggleReplaceButtonBehavior];
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
    [[self resultViewController] setResult:result];
    [[self resultViewController] setTarget:[self target]];
    [self setResultShown:YES animate:YES];
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
- (BOOL)validateMenuItem:(nonnull NSMenuItem *)menuItem
// ------------------------------------------------------
{
    if ([menuItem action] == @selector(findNext:) ||
        [menuItem action] == @selector(findPrevious:) ||
        [menuItem action] == @selector(findSelectedText:) ||
        [menuItem action] == @selector(findAll:) ||
        [menuItem action] == @selector(replace:) ||
        [menuItem action] == @selector(replaceAndFind:) ||
        [menuItem action] == @selector(replaceAll:) ||
        [menuItem action] == @selector(unhighlight:) ||
        [menuItem action] == @selector(highlight:))
    {
        return ([self target] != nil);
        
    } else if ([menuItem action] == @selector(useSelectionForFind:) ||
               [menuItem action] == @selector(useSelectionForReplace:))
    {
        return ![[self textFinder] isSelectionEmpty];
        
    } else if ([menuItem action] == @selector(changeSyntax:)) {
        OgreSyntax syntax = [[NSUserDefaults standardUserDefaults] integerForKey:CEDefaultFindRegexSyntaxKey];
        [menuItem setState:([menuItem tag] == syntax) ? NSOnState : NSOffState];
    }
    
    return YES;
}



#pragma mark Protocol

//=======================================================
// NSKeyValueObserving Protocol
//=======================================================

// ------------------------------------------------------
/// observed user defaults are changed
- (void)observeValueForKeyPath:(nullable NSString *)keyPath ofObject:(nullable id)object change:(nullable NSDictionary<NSString *, id> *)change context:(nullable void *)context
// ------------------------------------------------------
{
    if ([keyPath isEqualToString:CEDefaultFindNextAfterReplaceKey]) {
       [self toggleReplaceButtonBehavior];
    }
}



#pragma mark Delegate

//=======================================================
// NSWindowDelegate  < findPanel
//=======================================================

// ------------------------------------------------------
/// collapse result view by resizing window
- (void)windowDidEndLiveResize:(nonnull NSNotification *)notification
// ------------------------------------------------------
{
    [self collapseResultViewIfNeeded];
}


//=======================================================
// NSSplitViewDelegate  < splitView
//=======================================================

// ------------------------------------------------------
/// collapse result view by dragging divider
- (void)splitViewDidResizeSubviews:(nonnull NSNotification *)notification
// ------------------------------------------------------
{
    // ignore programmical resize
    if (![notification userInfo][@"NSSplitViewDividerIndex"]) { return; }
    
    [self collapseResultViewIfNeeded];
}


// ------------------------------------------------------
/// only result view can collapse
- (BOOL)splitView:(nonnull NSSplitView *)splitView canCollapseSubview:(nonnull NSView *)subview
// ------------------------------------------------------
{
    return (subview == [[self resultViewController] view]);
}


// ------------------------------------------------------
/// hide divider when view collapsed
- (BOOL)splitView:(nonnull NSSplitView *)splitView shouldHideDividerAtIndex:(NSInteger)dividerIndex
// ------------------------------------------------------
{
    return YES;
}


// ------------------------------------------------------
/// avoid showing draggable cursor when result view collapsed
- (NSRect)splitView:(nonnull NSSplitView *)splitView effectiveRect:(NSRect)proposedEffectiveRect forDrawnRect:(NSRect)drawnRect ofDividerAtIndex:(NSInteger)dividerIndex
// ------------------------------------------------------
{
    if ([splitView isSubviewCollapsed:[[self resultViewController] view]] || dividerIndex == 1) {
        proposedEffectiveRect.size = NSZeroSize;
    }
    
    return proposedEffectiveRect;
}


//=======================================================
// NSPopoverDelegate  < regexPopover
//=======================================================

// ------------------------------------------------------
/// make popover detachable (on Yosemite and later)
- (BOOL)popoverShouldDetach:(nonnull NSPopover *)popover
// ------------------------------------------------------
{
    return YES;
}


#pragma mark Notification

// ------------------------------------------------------
/// sync search string on activating application
- (void)applicationDidBecomeActive:(nonnull NSNotification *)notification
// ------------------------------------------------------
{
    if ([[NSUserDefaults standardUserDefaults] boolForKey:CEDefaultSyncFindPboardKey]) {
        [self setFindString:[self findStringFromPasteboard]];
    }
}



#pragma mark Public Action Messages

// ------------------------------------------------------
/// activate find panel
- (IBAction)showFindPanel:(nullable id)sender
// ------------------------------------------------------
{
    // close result view
    if (![[self findPanel] isVisible]) {
        [self setResultShown:NO animate:NO];
    }
    
    // select text in find text field
    if ([[self findPanel] firstResponder] == [[self findPanel] initialFirstResponder]) {
        // force reset firstResponder to invoke becomeFirstResponder in CEFindPanelTextView every time
        // -> `becomeFirstResponder` will not be called on `makeFirstResponder:` if it given object is alrady set as first responder.
        [[self findPanel] makeFirstResponder:nil];
    }
    [[self findPanel] makeFirstResponder:[[self findPanel] initialFirstResponder]];
    
    [super showFindPanel:sender];
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
    
    [self invalidateSyntaxInTextFinder];
    
    OgreTextFindResult *result = [[self textFinder] findAll:[self sanitizedFindString]
                                                      color:[self highlightColor]
                                                    options:[self options]
                                                inSelection:[self inSelection]];
    
    [self appendFindHistory:[self findString]];
    
    if (![result isSuccess]) {
        NSBeep();
    }
}


// ------------------------------------------------------
/// set selected string to find field
- (IBAction)useSelectionForFind:(nullable id)sender
// ------------------------------------------------------
{
    NSString *selectedString = [[self textFinder] selectedString];
    
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
    NSString *selectedString = [[self textFinder] selectedString];
    
    if (selectedString) {
        [self setReplacementString:selectedString];
    } else {
        NSBeep();
    }
}


// ------------------------------------------------------
/// replace next matched string with given string
- (IBAction)replace:(nullable id)sender
// ------------------------------------------------------
{
    // perform "Replace & Find" instead of "Replace"
    if ([[NSUserDefaults standardUserDefaults] boolForKey:CEDefaultFindNextAfterReplaceKey]) {
        [self replaceAndFind:sender];
        return;
    }
    
    if (![self checkIsReadyToFind]) { return; }
    
    [self invalidateSyntaxInTextFinder];
    
    OgreTextFindResult *result = [[self textFinder] replaceAndFind:[self sanitizedFindString]
                                                        withString:[self replacementString] ? : @""
                                                           options:[self options]
                                                     replacingOnly:YES
                                                              wrap:NO];
    
    [self appendFindHistory:[self findString]];
    [self appendReplaceHistory:[self replacementString]];
    
    if ([result alertIfErrorOccurred]) { return; }
}


// ------------------------------------------------------
/// replace next matched string with given string and select the one after the next match
- (IBAction)replaceAndFind:(nullable id)sender
// ------------------------------------------------------
{
    if (![self checkIsReadyToFind]) { return; }
    
    [self invalidateSyntaxInTextFinder];
    
    OgreTextFindResult *result = [[self textFinder] replaceAndFind:[self sanitizedFindString]
                                                        withString:[self replacementString] ? : @""
                                                           options:[self options]
                                                     replacingOnly:NO
                                                              wrap:[self isWrap]];
    
    [self appendFindHistory:[self findString]];
    [self appendReplaceHistory:[self replacementString]];
    
    if ([result alertIfErrorOccurred]) { return; }
    
    if ([result isSuccess]) {
        // add visual feedback
        [[self target] showFindIndicatorForRange:[[self target] selectedRange]];
        
    } else {
        NSBeep();
    }
}


// ------------------------------------------------------
/// replace all matched strings with given string
- (IBAction)replaceAll:(nullable id)sender
// ------------------------------------------------------
{
    if (![self checkIsReadyToFind]) { return; }
    
    [self invalidateSyntaxInTextFinder];
    
    [[self textFinder] replaceAll:[self sanitizedFindString]
                       withString:[self replacementString] ? : @""
                          options:[self options]
                      inSelection:[self inSelection]];
    
    [self appendFindHistory:[self findString]];
    [self appendReplaceHistory:[self replacementString]];
}


// ------------------------------------------------------
/// highlight all matched strings
- (IBAction)highlight:(nullable id)sender
// ------------------------------------------------------
{
    if (![self checkIsReadyToFind]) { return; }
    
    [self invalidateSyntaxInTextFinder];
    
    [[self textFinder] hightlight:[self sanitizedFindString]
                            color:[self highlightColor]
                          options:[self options]
                      inSelection:[self inSelection]];
    
    [self appendFindHistory:[self findString]];
}


// ------------------------------------------------------
/// remove all of current highlights
- (IBAction)unhighlight:(nullable id)sender
// ------------------------------------------------------
{
    [[self textFinder] unhightlight];
}



#pragma mark Private Action Messages

// ------------------------------------------------------
/// perform segmented Find Next/Previous button
- (IBAction)clickSegmentedFindButton:(nonnull NSSegmentedControl *)sender
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
- (IBAction)selectFindHistory:(nullable id)sender
// ------------------------------------------------------
{
    [self setFindString:[sender representedObject]];
}


// ------------------------------------------------------
/// set selected history string to replacement field
- (IBAction)selectReplaceHistory:(nullable id)sender
// ------------------------------------------------------
{
    [self setReplacementString:[sender representedObject]];
}


// ------------------------------------------------------
/// restore find history via UI
- (IBAction)clearFindHistory:(nullable id)sender
// ------------------------------------------------------
{
    [[self findPanel] makeKeyAndOrderFront:self];
    
    [[NSUserDefaults standardUserDefaults] removeObjectForKey:CEDefaultFindHistoryKey];
    [self updateFindHistoryMenu];
}


// ------------------------------------------------------
/// restore replace history via UI
- (IBAction)clearReplaceHistory:(nullable id)sender
// ------------------------------------------------------
{
    [[self findPanel] makeKeyAndOrderFront:self];
    
    [[NSUserDefaults standardUserDefaults] removeObjectForKey:CEDefaultReplaceHistoryKey];
    [self updateReplaceHistoryMenu];
}


// ------------------------------------------------------
/// change regex syntax setting via menu item
- (IBAction)changeSyntax:(nullable id)sender
// ------------------------------------------------------
{
    [[NSUserDefaults standardUserDefaults] setInteger:[sender tag] forKey:CEDefaultFindRegexSyntaxKey];
}


// ------------------------------------------------------
/// option is toggled
- (IBAction)toggleOption:(nullable id)sender
// ------------------------------------------------------
{
    __weak typeof(self) weakSelf = self;
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.1 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        typeof(self) self = weakSelf;  // strong self
        if (!self) { return; }
        
        [[NSUserDefaults standardUserDefaults] setInteger:[self options] forKey:CEDefaultFindOptionsKey];
    });
}


// ------------------------------------------------------
/// close opening find result view
- (IBAction)closeResultView:(nullable id)sender
// ------------------------------------------------------
{
    [self setResultShown:NO animate:YES];
}


// ------------------------------------------------------
/// show regular expression reference as popover
- (IBAction)showRegexHelp:(nullable id)sender
// ------------------------------------------------------
{
    if ([[self regexPopover] isShown]) {
        [[self regexPopover] close];
    } else {
        [[self regexPopover] showRelativeToRect:[sender bounds] ofView:sender preferredEdge:NSMaxYEdge];
    }
}



#pragma mark Private Methods

// ------------------------------------------------------
/// find string of which line endings are standardized to LF
- (NSString *)sanitizedFindString
// ------------------------------------------------------
{
    return [OGRegularExpression replaceNewlineCharactersInString:[self findString]
                                                   withCharacter:OgreLfNewlineCharacter];
}


// ------------------------------------------------------
/// update syntax (and regex enability) setting in textFinder
- (void)invalidateSyntaxInTextFinder
// ------------------------------------------------------
{
    [[self textFinder] setSyntax:[self usesRegularExpression] ? [self syntax] : OgreSimpleMatchingSyntax];
}


// ------------------------------------------------------
/// whether result view is opened
- (BOOL)isResultShown
// ------------------------------------------------------
{
    return ![[self splitView] isSubviewCollapsed:[[self resultViewController] view]];
}


// ------------------------------------------------------
/// toggle result view visibility with/without animation
- (void)setResultShown:(BOOL)shown animate:(BOOL)performAnimation
// ------------------------------------------------------
{
    NSView *resultView = [[self resultViewController] view];
    CGFloat height = NSHeight([resultView bounds]);
    
    if ((!shown && ![self isResultShown]) || (shown && height > kDefaultResultViewHeight)) { return; }
    
    // make sure disclosure button points up before open result
    // (The buttom may point down if the view was closed by dragging.)
    if (shown) {
        [[self disclosureButton] setState:NSOnState];
    }
    
    // remove height constraint on 10.8 (see the last lines in `collapseResultViewIfNeeded`)
    if (NSAppKitVersionNumber < NSAppKitVersionNumber10_9) {
        if (shown) {
            [resultView removeConstraint:[self resultHeightConstraint]];
        }
    }
    
    NSPanel *panel = [self findPanel];
    NSRect panelFrame = [panel frame];
    CGFloat diff = shown ? kDefaultResultViewHeight - height : -height;
    
    // uncollapse and add divider without animation if needed
    if (shown && [resultView isHidden]) {
        CGFloat thickness = 2 * 1;
        
        [resultView setHidden:NO];
        panelFrame.size.height += thickness;
        panelFrame.origin.y -= thickness;
        [panel setFrame:panelFrame display:YES animate:NO];
    }
    
    // resize panel frame
    panelFrame.size.height += diff;
    panelFrame.origin.y -= diff;
    
    [panel setFrame:panelFrame display:YES animate:performAnimation];
    
    if (!shown) {
        [self collapseResultViewIfNeeded];
    }
}


// ------------------------------------------------------
/// collapse result view if closed
- (void)collapseResultViewIfNeeded
// ------------------------------------------------------
{
    NSView *resultView = [[self resultViewController] view];
    if ([resultView isHidden] || !NSIsEmptyRect([resultView visibleRect])) { return; }
    
    NSRect frame = [[self findPanel] frame];
    CGFloat thickness = 2 * [[self splitView] dividerThickness];
    [resultView setHidden:YES];
    
    // resize panel to avoid resizing input fields
    frame.size.height -= thickness;
    frame.origin.y += thickness;
    [[self findPanel] setFrame:frame display:YES animate:NO];
    
    // have a layout constraint to avoid opening result view by resizing window on OS X 10.8.
    // (This constraint is probably not needed on 10.9 and later.)
    if (NSAppKitVersionNumber < NSAppKitVersionNumber10_9) {
        if (![self resultHeightConstraint]) {
            NSLayoutConstraint *constraint = [NSLayoutConstraint constraintWithItem:resultView
                                                                          attribute:NSLayoutAttributeHeight
                                                                          relatedBy:NSLayoutRelationEqual
                                                                             toItem:nil
                                                                          attribute:NSLayoutAttributeHeight
                                                                         multiplier:1.0
                                                                           constant:0];
            [self setResultHeightConstraint:constraint];
        }
        [resultView addConstraint:[self resultHeightConstraint]];
    }
}


// ------------------------------------------------------
/// return current target textView
- (nullable NSTextView *)target
// ------------------------------------------------------
{
    return [[self textFinder] targetToFindIn];
}


// ------------------------------------------------------
/// perform "Find Next" and "Find Previous"
- (void)findForward:(BOOL)forward
// ------------------------------------------------------
{
    if (![self checkIsReadyToFind]) { return; }
    
    [self invalidateSyntaxInTextFinder];
    
    OgreTextFindResult *result = [[self textFinder] find:[self sanitizedFindString]
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
/// check Find can be performed and alert if needed
- (BOOL)checkIsReadyToFind
// ------------------------------------------------------
{
    if ([[self findPanel] attachedSheet]) {
        [[self findPanel] makeKeyAndOrderFront:self];
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
            [OGRegularExpression regularExpressionWithString:[self sanitizedFindString]
                                                     options:[self options]
                                                      syntax:[self syntax]
                                             escapeCharacter:kEscapeCharacter];
            
        } @catch (NSException *exception) {
            if ([[exception name] isEqualToString:OgreException]) {
                [self showAlertWithMessage:NSLocalizedString(@"Invalid regular expression", nil)
                               informative:[exception reason]];
            } else {
                [exception raise];
            }
            return NO;
        }
    }
    
    return YES;
}


// ------------------------------------------------------
/// show error message by OgreKit as alert
- (void)showAlertWithMessage:(nonnull NSString *)message informative:(nonnull NSString *)informative
// ------------------------------------------------------
{
    NSAlert *alert = [[NSAlert alloc] init];
    [alert setMessageText:message];
    [alert setInformativeText:informative];
    
    NSBeep();
    [[self findPanel] makeKeyAndOrderFront:self];
    [alert beginSheetModalForWindow:[self findPanel] modalDelegate:nil didEndSelector:NULL contextInfo:NULL];
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
- (void)buildHistoryMenu:(nonnull NSMenu *)menu defautsKey:(nonnull NSString *)key selector:(SEL)selector
// ------------------------------------------------------
{
    NSArray<NSString *> *history = [[NSUserDefaults standardUserDefaults] stringArrayForKey:key];
    
    // clear current history items
    for (NSMenuItem *item in [menu itemArray]) {
        if ([item action] == selector || [item isSeparatorItem]) {
            [menu removeItem:item];
        }
    }
    
    if ([history count] == 0) { return; }
    
    [menu insertItem:[NSMenuItem separatorItem] atIndex:2];  // the first item is invisible dummy
    
    for (NSString *string in history) {
        NSString *title = ([string length] < 64) ? string : [[string substringToIndex:64] stringByAppendingString:@"…"];
        NSMenuItem *item = [[NSMenuItem alloc] initWithTitle:title
                                                      action:selector
                                               keyEquivalent:@""];
        [item setRepresentedObject:string];
        [item setToolTip:string];
        [item setTarget:self];
        [menu insertItem:item atIndex:2];
    }
}


// ------------------------------------------------------
/// append given string to find history
- (void)appendFindHistory:(nonnull NSString *)string
// ------------------------------------------------------
{
    if ([string length] == 0) { return; }
    
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    
    // sync search string
    if ([defaults boolForKey:CEDefaultSyncFindPboardKey]) {
        [self setFindStringToPasteboard:string];
    }
    
    // append new string to history
    NSMutableArray<NSString *> *history = [NSMutableArray arrayWithArray:[defaults stringArrayForKey:CEDefaultFindHistoryKey]];
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
- (void)setFindStringToPasteboard:(nonnull NSString *)string
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


// ------------------------------------------------------
/// toggle replace button behavior and tooltip
- (void)toggleReplaceButtonBehavior
// ------------------------------------------------------
{
    if ([[NSUserDefaults standardUserDefaults] boolForKey:CEDefaultFindNextAfterReplaceKey]) {
        [[self replaceButton] setToolTip:NSLocalizedString(@"Replace the current selection with the replacement text, then find the next match.", nil)];
    } else {
        [[self replaceButton] setToolTip:NSLocalizedString(@"Replace the current selection with the replacement text.", nil)];
    }
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
