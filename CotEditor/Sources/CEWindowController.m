/*
 
 CEWindowController.m
 
 CotEditor
 http://coteditor.com
 
 Created by nakamuxu on 2004-12-13.

 ------------------------------------------------------------------------------
 
 © 2004-2007 nakamuxu
 © 2013-2016 1024jp
 
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

#import "CEWindowController.h"
#import "CEWindow.h"
#import "CEDocument.h"
#import "CEToolbarController.h"
#import "CEStatusBarController.h"
#import "CEIncompatibleCharsViewController.h"
#import "CEEditorWrapper.h"
#import "CEDocumentAnalyzer.h"
#import "CEDefaults.h"


// sidebar mode
typedef NS_ENUM(NSUInteger, CESidebarTag) {
    CEDocumentInspectorTag = 1,
    CEIncompatibleCharsTag,
};


@interface CEWindowController () <NSSplitViewDelegate, NSSharingServicePickerDelegate>

@property (nonatomic) CESidebarTag selectedSidebarTag;
@property (nonatomic) CGFloat sidebarWidth;


// IBOutlets
@property (nonatomic, nullable) IBOutlet CEStatusBarController *statusBarController;
@property (nonatomic, nullable) IBOutlet NSViewController *documentInspectorViewController;
@property (nonatomic, nullable) IBOutlet CEIncompatibleCharsViewController *incompatibleCharsViewController;
@property (nonatomic, nullable, weak) IBOutlet NSSplitView *sidebarSplitView;
@property (nonatomic, nullable, weak) IBOutlet NSView *sidebar;
@property (nonatomic, nullable, weak) IBOutlet NSView *sidebarPlaceholderView;

// IBOutlets (readonly)
@property (readwrite, nonatomic, nullable, weak) IBOutlet CEToolbarController *toolbarController;
@property (readwrite, nonatomic, nullable, weak) IBOutlet CEEditorWrapper *editor;

@end




#pragma mark -

@implementation CEWindowController

#pragma mark Superclass Methods

// ------------------------------------------------------
/// clean up
- (void)dealloc
// ------------------------------------------------------
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    [[NSUserDefaults standardUserDefaults] removeObserver:self forKeyPath:CEDefaultWindowAlphaKey];
    
    // Need to set nil to NSSplitView's delegate manually since it is not weak but just assign,
    //     and may crash when closing split fullscreen window on El Capitan (2015-07)
    [_sidebarSplitView setDelegate:nil];
}


// ------------------------------------------------------
/// nib name
- (nullable NSString *)windowNibName
// ------------------------------------------------------
{
    return @"DocumentWindow";
}


// ------------------------------------------------------
/// prepare window and other UI
- (void)windowDidLoad
// ------------------------------------------------------
{
    [super windowDidLoad];
    
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    
    [[self window] setContentSize:NSMakeSize((CGFloat)[defaults doubleForKey:CEDefaultWindowWidthKey],
                                             (CGFloat)[defaults doubleForKey:CEDefaultWindowHeightKey])];
    
    // setup background
    [(CEWindow *)[self window] setBackgroundAlpha:[defaults doubleForKey:CEDefaultWindowAlphaKey]];
    
    // ???: needs to set contentView's layer to mask rounded window corners
    if (floor(NSAppKitVersionNumber > NSAppKitVersionNumber10_10_Max)) {
        [[[self window] contentView] setWantsLayer:YES];
    }
    
    // setup sidebar
    [[[self sidebar] layer] setBackgroundColor:[[NSColor colorWithCalibratedWhite:0.94 alpha:1.0] CGColor]];
    // The following line is required for NSSplitView with Autolayout on OS X 10.8 (2015-02-10 by 1024jp)
    // Otherwise, visibility of splitView's subviews can not be initialized.
    [[self sidebarSplitView] layoutSubtreeIfNeeded];
    [self setSidebarShown:[defaults boolForKey:CEDefaultShowDocumentInspectorKey]];
    
    // set document instance to sidebar views
    [[self incompatibleCharsViewController] setDocument:[self document]];
    [[self documentInspectorViewController] setRepresentedObject:[[self document] analyzer]];
    
    // setup status bar
    [[self statusBarController] setDocumentAnalyzer:[[self document] analyzer]];
    [[self statusBarController] setShown:[defaults boolForKey:CEDefaultShowStatusBarKey] animate:NO];
    
    // apply document state to UI
    [[self document] applyContentToWindow];
    
    // observe opacity setting change
    [[NSUserDefaults standardUserDefaults] addObserver:self
                                            forKeyPath:CEDefaultWindowAlphaKey
                                               options:NSKeyValueObservingOptionNew
                                               context:nil];
}



#pragma mark Protocol

//=======================================================
// NSMenuValidation Protocol
//=======================================================

// ------------------------------------------------------
/// validate menu items
- (BOOL)validateMenuItem:(nonnull NSMenuItem *)menuItem
// ------------------------------------------------------
{
    if ([menuItem action] == @selector(toggleStatusBar:)) {
        NSString *title = [self showsStatusBar] ? @"Hide Status Bar" : @"Show Status Bar";
        [menuItem setTitle:NSLocalizedString(title, nil)];
    }
    
    return YES;
}


//=======================================================
// NSKeyValueObserving Protocol
//=======================================================

// ------------------------------------------------------
/// apply user defaults change
-(void)observeValueForKeyPath:(nullable NSString *)keyPath ofObject:(nullable id)object change:(nullable NSDictionary<NSString *, id> *)change context:(nullable void *)context
// ------------------------------------------------------
{
    if ([keyPath isEqualToString:CEDefaultWindowAlphaKey]) {
        [(CEWindow *)[self window] setBackgroundAlpha:(CGFloat)[change[NSKeyValueChangeNewKey] doubleValue]];
    }
}



#pragma mark Public Methods

// ------------------------------------------------------
/// show incompatible char list
- (void)showIncompatibleCharList
// ------------------------------------------------------
{
    [self setSelectedSidebarTag:CEIncompatibleCharsTag];
    [self setSidebarShown:YES];
}


// ------------------------------------------------------
/// update incompatible char list if it is currently shown
- (void)updateIncompatibleCharsIfNeeded
// ------------------------------------------------------
{
    [[self incompatibleCharsViewController] updateIfNeeded];
}



#pragma mark Public Accessors

// ------------------------------------------------------
/// return whether status bar is shown
- (BOOL)showsStatusBar
// ------------------------------------------------------
{
    return [[self statusBarController] isShown];
}


// ------------------------------------------------------
/// set visibility of status bar
- (void)setShowsStatusBar:(BOOL)showsStatusBar
// ------------------------------------------------------
{
    if (![self statusBarController]) { return; }
    
    [[self statusBarController] setShown:showsStatusBar animate:YES];
    [[self toolbarController] toggleItemWithTag:CEToolbarShowStatusBarItemTag
                                          setOn:showsStatusBar];
    
    [[[self document] analyzer] setNeedsUpdateStatusEditorInfo:showsStatusBar];
    if (showsStatusBar) {
        [[[self document] analyzer] invalidateEditorInfo];
    }
}



#pragma mark Delegate

//=======================================================
// NSWindowDelegate  < window
//=======================================================

// ------------------------------------------------------
/// save window state
- (void)window:(nonnull NSWindow *)window willEncodeRestorableState:(nonnull NSCoder *)state
// ------------------------------------------------------
{
    [state encodeBool:[[self statusBarController] isShown] forKey:CEDefaultShowStatusBarKey];
    [state encodeBool:[[self editor] showsNavigationBar] forKey:CEDefaultShowNavigationBarKey];
    [state encodeBool:[[self editor] showsLineNum] forKey:CEDefaultShowLineNumbersKey];
    [state encodeBool:[[self editor] showsPageGuide] forKey:CEDefaultShowPageGuideKey];
    [state encodeBool:[[self editor] showsInvisibles] forKey:CEDefaultShowInvisiblesKey];
    [state encodeBool:[[self editor] isVerticalLayoutOrientation] forKey:CEDefaultLayoutTextVerticalKey];
    [state encodeBool:[self isSidebarShown] forKey:CEDefaultShowDocumentInspectorKey];
    [state encodeDouble:[self sidebarWidth] forKey:CEDefaultSidebarWidthKey];
}


// ------------------------------------------------------
/// restore window state from the last session
- (void)window:(nonnull NSWindow *)window didDecodeRestorableState:(nonnull NSCoder *)state
// ------------------------------------------------------
{
    if ([state containsValueForKey:CEDefaultShowStatusBarKey]) {
        [[self statusBarController] setShown:[state decodeBoolForKey:CEDefaultShowStatusBarKey] animate:NO];
    }
    if ([state containsValueForKey:CEDefaultShowNavigationBarKey]) {
        [[self editor] setShowsNavigationBar:[state decodeBoolForKey:CEDefaultShowNavigationBarKey] animate:NO];
    }
    if ([state containsValueForKey:CEDefaultShowLineNumbersKey]) {
        [[self editor] setShowsLineNum:[state decodeBoolForKey:CEDefaultShowLineNumbersKey]];
    }
    if ([state containsValueForKey:CEDefaultShowPageGuideKey]) {
        [[self editor] setShowsPageGuide:[state decodeBoolForKey:CEDefaultShowPageGuideKey]];
    }
    if ([state containsValueForKey:CEDefaultShowInvisiblesKey]) {
        [[self editor] setShowsInvisibles:[state decodeBoolForKey:CEDefaultShowInvisiblesKey]];
    }
    if ([state containsValueForKey:CEDefaultLayoutTextVerticalKey]) {
        [[self editor] setVerticalLayoutOrientation:[state decodeBoolForKey:CEDefaultLayoutTextVerticalKey]];
    }
    if ([state containsValueForKey:CEDefaultShowDocumentInspectorKey]) {
        [self setSidebarWidth:[state decodeDoubleForKey:CEDefaultSidebarWidthKey]];
        [self setSidebarShown:[state decodeBoolForKey:CEDefaultShowDocumentInspectorKey]];
    }
}


//=======================================================
// NSSplitViewDelegate  < sidebarSplitView
//=======================================================

// ------------------------------------------------------
/// only sidebar can collapse
- (BOOL)splitView:(nonnull NSSplitView *)splitView canCollapseSubview:(nonnull NSView *)subview
// ------------------------------------------------------
{
    return (subview == [self sidebar]);
}


// ------------------------------------------------------
/// hide sidebar divider when collapsed
- (BOOL)splitView:(nonnull NSSplitView *)splitView shouldHideDividerAtIndex:(NSInteger)dividerIndex
// ------------------------------------------------------
{
    return YES;
}


// ------------------------------------------------------
/// store current sidebar width
- (void)splitViewDidResizeSubviews:(nonnull NSNotification *)notification
// ------------------------------------------------------
{
    if ([notification userInfo][@"NSSplitViewDividerIndex"]) {  // check wheter the change coused by user's divider dragging
        if ([self isSidebarShown]) {
            CGFloat currentWidth = NSWidth([[self sidebar] bounds]);
            [self setSidebarWidth:currentWidth];
            [[NSUserDefaults standardUserDefaults] setDouble:currentWidth forKey:CEDefaultSidebarWidthKey];
        }
    }
}



#pragma mark Action Messages

// ------------------------------------------------------
/// toggle visibility of document inspector
- (IBAction)getInfo:(nullable id)sender
// ------------------------------------------------------
{
    if ([self isDocumentInspectorShown]) {
        [self setSidebarShown:NO];
    } else {
        [self setSelectedSidebarTag:CEDocumentInspectorTag];
        [self setSidebarShown:YES];
    }
}


// ------------------------------------------------------
/// toggle visibility of incompatible chars list view
- (IBAction)toggleIncompatibleCharList:(nullable id)sender
// ------------------------------------------------------
{
    if ([self isSidebarShown] && [self selectedSidebarTag] == CEIncompatibleCharsTag) {
        [self setSidebarShown:NO];
    } else {
        [self setSelectedSidebarTag:CEIncompatibleCharsTag];
        [self setSidebarShown:YES];
    }
}


// ------------------------------------------------------
/// toggle visibility of status bar
- (IBAction)toggleStatusBar:(nullable id)sender
// ------------------------------------------------------
{
    [self setShowsStatusBar:![self showsStatusBar]];
}



#pragma mark Private Methods

// ------------------------------------------------------
/// set sidebar visibility
- (void)setSidebarShown:(BOOL)shown
// ------------------------------------------------------
{
    if ([self selectedSidebarTag] == 0) {
        [self setSelectedSidebarTag:CEDocumentInspectorTag];
    }
    if ([self isSidebarShown] == shown) { return; }
    
    BOOL isInitial = ![[self window] isVisible];  // on `windowDidLoad` and `window:didDecodeRestorableState:`
    BOOL isFullscreen = ([[self window] styleMask] & NSFullScreenWindowMask) == NSFullScreenWindowMask;
    BOOL changesWindowSize = !isInitial && !isFullscreen;
    CGFloat sidebarWidth = [self sidebarWidth] ?: [[NSUserDefaults standardUserDefaults] doubleForKey:CEDefaultSidebarWidthKey];
    CGFloat dividerThickness = [[self sidebarSplitView] dividerThickness];
    CGFloat position = [[self sidebarSplitView] maxPossiblePositionOfDividerAtIndex:0];
    
    // adjust divider position
    if ((changesWindowSize && !shown) || (!changesWindowSize && shown)) {
        position -= sidebarWidth;
    }
    
    // update window width
    if (changesWindowSize) {
        NSRect windowFrame = [[self window] frame];
        windowFrame.size.width += shown ? (sidebarWidth + dividerThickness) : - (sidebarWidth + dividerThickness);
        [[self window] setFrame:windowFrame display:NO];
    }
    
    // apply
    [[self sidebarSplitView] setPosition:position ofDividerAtIndex:0];
    [[self sidebarSplitView] adjustSubviews];
    
    if (!shown) {
        // clear incompatible chars markup
        [[self editor] clearAllMarkup];
    }
    
    [[[self document] analyzer] setNeedsUpdateEditorInfo:shown];
}


// ------------------------------------------------------
/// return whether sidebar is opened
- (BOOL)isSidebarShown
// ------------------------------------------------------
{
    return ![[self sidebarSplitView] isSubviewCollapsed:[self sidebar]];
}


// ------------------------------------------------------
/// return whether document inspector is shown
- (BOOL)isDocumentInspectorShown
// ------------------------------------------------------
{
    return ([self selectedSidebarTag] == CEDocumentInspectorTag && [self isSidebarShown]);
}


// ------------------------------------------------------
/// switch sidebar view
- (void)setSelectedSidebarTag:(CESidebarTag)tag
// ------------------------------------------------------
{
    NSViewController *viewController;
    switch (tag) {
        case CEDocumentInspectorTag:
            viewController = [self documentInspectorViewController];
            [[[self document] analyzer] invalidateEditorInfo];
            break;
            
        case CEIncompatibleCharsTag:
            viewController = [self incompatibleCharsViewController];
            [[self incompatibleCharsViewController] update];
            break;
    }
    
    if (_selectedSidebarTag == tag) { return; }
    
    _selectedSidebarTag = tag;
    
    // swap views
    NSView *placeholder = [self sidebarPlaceholderView];
    NSView *currentView = [[placeholder subviews] firstObject];
    NSView *newView = [viewController view];
    
    // transit with animation
    [newView setFrame:[currentView frame]];
    [[placeholder animator] replaceSubview:currentView with:newView];
    
    // update autolayout constrains
    NSDictionary<NSString *, id> *views = NSDictionaryOfVariableBindings(newView);
    [placeholder addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:|[newView]|" options:0 metrics:nil views:views]];
    [placeholder addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|[newView]|" options:0 metrics:nil views:views]];
}

@end
