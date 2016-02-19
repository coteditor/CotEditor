/*
 
 CEFindPanelController.m
 
 CotEditor
 http://coteditor.com
 
 Created by 1024jp on 2014-12-30.

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

#import <OgreKit/OgreKit.h>
#import "CEFindPanelController.h"
#import "CEFindResultViewController.h"
#import "CETextFinder.h"
#import "CEDefaults.h"


// constants
static const CGFloat kDefaultResultViewHeight = 200.0;


@interface CEFindPanelController () <CETextFinderDelegate, NSWindowDelegate, NSSplitViewDelegate, NSTextViewDelegate, NSPopoverDelegate>

@property (nonatomic, nullable) NSLayoutConstraint *resultHeightConstraint;  // for autolayout on OS X 10.8
@property (nonatomic, nullable, copy) NSString *resultMessage;  // binding
@property (nonatomic, nullable, weak) NSLayoutManager *currentResultMessageTarget;  // grab layoutManager instead of NSTextView to use weak reference on OS X 10.8

#pragma mark Outlets
@property (nonatomic, nullable, weak) IBOutlet CETextFinder *textFinder;
@property (nonatomic, nullable) IBOutlet CEFindResultViewController *resultViewController;
@property (nonatomic, nullable) IBOutlet NSPopover *regexReferencePopover;
@property (nonatomic, nullable) IBOutlet NSPopover *preferencesPopover;
@property (nonatomic, nullable, weak) IBOutlet NSNumberFormatter *integerFormatter;
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
        // observe default change for the "Replace" button tooltip
        [[NSUserDefaults standardUserDefaults] addObserver:self
                                                forKeyPath:CEDefaultFindNextAfterReplaceKey
                                                   options:NSKeyValueObservingOptionNew
                                                   context:NULL];
    }
    return self;
}


// ------------------------------------------------------
/// clean up
- (void)dealloc
// ------------------------------------------------------
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    [[NSUserDefaults standardUserDefaults] removeObserver:self forKeyPath:CEDefaultFindNextAfterReplaceKey];
    
    [_splitView setDelegate:nil];  // NSSplitView's delegate is assign, not weak
}


// ------------------------------------------------------
/// window nib name
- (nullable NSString *)windowNibName
// ------------------------------------------------------
{
    return @"FindPanel";
}


// ------------------------------------------------------
/// setup UI
- (void)windowDidLoad
// ------------------------------------------------------
{
    // [attention] This method can be invoked before initializing user defaults in CEAppDelegate.
    
    [super windowDidLoad];
    
    [self updateFindHistoryMenu];
    [self updateReplaceHistoryMenu];
    
    [self toggleReplaceButtonBehavior];
}


// ------------------------------------------------------
/// activate find panel
- (IBAction)showWindow:(nullable id)sender
// ------------------------------------------------------
{
    // close result view
    if (![[self window] isVisible]) {
        [self setResultShown:NO animate:NO];
    }
    
    // select text in find text field
    if ([[self window] firstResponder] == [[self window] initialFirstResponder]) {
        // force reset firstResponder to invoke becomeFirstResponder in CEFindPanelTextView every time
        // -> `becomeFirstResponder` will not be called on `makeFirstResponder:` if it given object is alrady set as first responder.
        [[self window] makeFirstResponder:nil];
    }
    [[self window] makeFirstResponder:[[self window] initialFirstResponder]];
    
    [super showWindow:sender];
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
// CETextFinderDelegate < textFinder
//=======================================================

// ------------------------------------------------------
/// complemention notification for "Find All"
- (void)textFinder:(nonnull CETextFinder *)textFinder didFinishFindingAll:(nonnull NSString *)findString results:(nonnull NSArray<NSDictionary *> *)results textView:(nonnull NSTextView *)textView
// ------------------------------------------------------
{
    // highlight in text view
    NSLayoutManager *layoutManager = [textView layoutManager];
    [layoutManager removeTemporaryAttribute:NSBackgroundColorAttributeName
                          forCharacterRange:NSMakeRange(0, [[layoutManager textStorage] length])];
    for (NSDictionary<NSString *, id> *result in results) {
        NSRange range = [result[CEFindResultRange] rangeValue];
        [layoutManager addTemporaryAttribute:NSBackgroundColorAttributeName value:[textFinder highlightColor] forCharacterRange:range];
    }
    
    NSString *documentName = [[[[textView window] windowController] document] displayName];
    
    // prepare result table
    [[self resultViewController] setTarget:textView];
    [[self resultViewController] setDocumentName:documentName];
    [[self resultViewController] setFindString:findString];
    [[self resultViewController] setResult:results];  // result must set at last
    [self setResultShown:YES animate:YES];
    [self showWindow:self];
}


// ------------------------------------------------------
/// recieve number of found
- (void)textFinder:(CETextFinder *)textFinder didFound:(NSInteger)numberOfFound textView:(nonnull NSTextView *)textView
// ------------------------------------------------------
{
    switch (numberOfFound) {
        case -1:
            [self setResultMessage:nil];
            break;
        case 0:
            [self setResultMessage:NSLocalizedString(@"Not Found", nil)];
            break;
        default:
            [self setResultMessage:[NSString stringWithFormat:NSLocalizedString(@"%@ found", nil), [[self integerFormatter] stringFromNumber:@(numberOfFound)]]];
            break;
    }
    
    // dismiss result either client text or find string did change
    [self setCurrentResultMessageTarget:[textView layoutManager]];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(invalidateNumberOfFound:)
                                                 name:NSTextStorageDidProcessEditingNotification object:[textView textStorage]];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(invalidateNumberOfFound:)
                                                 name:NSWindowWillCloseNotification object:[textView window]];
}


// ------------------------------------------------------
/// find history did update
- (void)textFinderDidUpdateFindHistory
// ------------------------------------------------------
{
    [self updateFindHistoryMenu];
}


// ------------------------------------------------------
/// replacement history did update
- (void)textFinderDidUpdateReplaceHistory
// ------------------------------------------------------
{
    [self updateReplaceHistoryMenu];
}



//=======================================================
// NSTextViewDeleage < find string field
//=======================================================

// ------------------------------------------------------
/// find string did change
- (void)textDidChange:(NSNotification *)notification
// ------------------------------------------------------
{
    if ([[notification object] isKindOfClass:[NSTextView class]]) {
        [self invalidateNumberOfFound:nil];
    }
}



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


// ------------------------------------------------------
/// find panel will close
- (void)windowWillClose:(NSNotification *)notification
// ------------------------------------------------------
{
    [self unhighlight];
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



#pragma mark Action Messages

// ------------------------------------------------------
/// replace next matched string with given string
- (IBAction)replace:(nullable id)sender
// ------------------------------------------------------
{
    // perform "Replace & Find" instead of "Replace"
    if ([[NSUserDefaults standardUserDefaults] boolForKey:CEDefaultFindNextAfterReplaceKey]) {
        [[self textFinder] replaceAndFind:sender];
        return;
    }
    
    [[self textFinder] replace:sender];
}


// ------------------------------------------------------
/// perform segmented Find Next/Previous button
- (IBAction)clickSegmentedFindButton:(nonnull NSSegmentedControl *)sender
// ------------------------------------------------------
{
    switch ([sender selectedSegment]) {
        case 0:
            [[self textFinder] findPrevious:sender];
            break;
        case 1:
            [[self textFinder] findNext:sender];
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
    [[self textFinder] setFindString:[sender representedObject]];
}


// ------------------------------------------------------
/// set selected history string to replacement field
- (IBAction)selectReplaceHistory:(nullable id)sender
// ------------------------------------------------------
{
    [[self textFinder] setReplacementString:[sender representedObject]];
}


// ------------------------------------------------------
/// restore find history via UI
- (IBAction)clearFindHistory:(nullable id)sender
// ------------------------------------------------------
{
    [[self window] makeKeyAndOrderFront:self];
    
    [[NSUserDefaults standardUserDefaults] removeObjectForKey:CEDefaultFindHistoryKey];
    [self updateFindHistoryMenu];
}


// ------------------------------------------------------
/// restore replace history via UI
- (IBAction)clearReplaceHistory:(nullable id)sender
// ------------------------------------------------------
{
    [[self window] makeKeyAndOrderFront:self];
    
    [[NSUserDefaults standardUserDefaults] removeObjectForKey:CEDefaultReplaceHistoryKey];
    [self updateReplaceHistoryMenu];
}


// ------------------------------------------------------
/// close opening find result view
- (IBAction)closeResultView:(nullable id)sender
// ------------------------------------------------------
{
    [self setResultShown:NO animate:YES];
    
    [self unhighlight];
}


// ------------------------------------------------------
/// show find panel preferences as popover
- (IBAction)showPreferences:(nullable id)sender
// ------------------------------------------------------
{
    if ([[self preferencesPopover] isShown]) {
        [[self preferencesPopover] close];
    } else {
        [[self preferencesPopover] showRelativeToRect:[sender bounds] ofView:sender preferredEdge:NSMaxXEdge];
    }
}


// ------------------------------------------------------
/// show regular expression reference as popover
- (IBAction)showRegexHelp:(nullable id)sender
// ------------------------------------------------------
{
    if ([[self regexReferencePopover] isShown]) {
        [[self regexReferencePopover] close];
    } else {
        [[self regexReferencePopover] showRelativeToRect:[sender bounds] ofView:sender preferredEdge:NSMaxYEdge];
    }
}



#pragma mark Private Methods

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
    
    NSWindow *panel = [self window];
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
    
    NSRect frame = [[self window] frame];
    CGFloat thickness = 2 * [[self splitView] dividerThickness];
    [resultView setHidden:YES];
    
    // resize panel to avoid resizing input fields
    frame.size.height -= thickness;
    frame.origin.y += thickness;
    [[self window] setFrame:frame display:YES animate:NO];
    
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
/// number of found in find string field becomes no more valid
- (void)invalidateNumberOfFound:(nullable NSNotification *)notification
// ------------------------------------------------------
{
    [self setResultMessage:nil];
    
    // -> specify the object to remove osberver to avoid removing the windowWillClose notification (via delegate) from find panel itself.
    if ([self currentResultMessageTarget]) {
        NSTextView *textView = [[self currentResultMessageTarget] firstTextView];
        [[NSNotificationCenter defaultCenter] removeObserver:self name:NSTextStorageDidProcessEditingNotification object:[textView textStorage]];
        [[NSNotificationCenter defaultCenter] removeObserver:self name:NSWindowWillCloseNotification object:[textView window]];
        [self setCurrentResultMessageTarget:nil];
    }
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


// ------------------------------------------------------
/// remove current highlight by Find All
- (void)unhighlight
// ------------------------------------------------------
{
    NSTextView *tareget = [[self resultViewController] target];
    if (tareget) {
        [[tareget layoutManager] removeTemporaryAttribute:NSBackgroundColorAttributeName
                                        forCharacterRange:NSMakeRange((0), [[tareget string] length])];
    }
}

@end
