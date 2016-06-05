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
#import "CEAlphaWindow.h"
#import "CEDocument.h"
#import "CEToolbarController.h"
#import "CESidebarViewController.h"
#import "CEEditorWrapper.h"
#import "CEDefaults.h"


@interface CEWindowController () <NSSplitViewDelegate>

@property (nonatomic) CGFloat sidebarWidth;


// IBOutlets
@property (nonatomic, nullable) IBOutlet CEToolbarController *toolbarController;
@property (nonatomic, nullable) IBOutlet CESidebarViewController *sidebarViewController;
@property (nonatomic, nullable, weak) IBOutlet NSSplitView *sidebarSplitView;

// IBOutlets (readonly)
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
    [(CEAlphaWindow *)[self window] setBackgroundAlpha:[defaults doubleForKey:CEDefaultWindowAlphaKey]];
    
    // ???: needs to set contentView's layer to mask rounded window corners
    if (floor(NSAppKitVersionNumber > NSAppKitVersionNumber10_10_Max)) {
        [[[self window] contentView] setWantsLayer:YES];
    }
    
    [self setSidebarShown:[[NSUserDefaults standardUserDefaults] boolForKey:CEDefaultShowDocumentInspectorKey]];
    
    [self applyDocument:[self document]];
    
    // apply document state to UI
    [[self document] applyContentToWindow];
    
    // observe opacity setting change
    [[NSUserDefaults standardUserDefaults] addObserver:self
                                            forKeyPath:CEDefaultWindowAlphaKey
                                               options:NSKeyValueObservingOptionNew
                                               context:nil];
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
        [(CEAlphaWindow *)[self window] setBackgroundAlpha:(CGFloat)[change[NSKeyValueChangeNewKey] doubleValue]];
    }
}



#pragma mark Public Methods

// ------------------------------------------------------
/// show incompatible char list
- (void)showIncompatibleCharList
// ------------------------------------------------------
{
    [[[self sidebarViewController] tabView] selectTabViewItemAtIndex:CESidebarTabIndexIncompatibleChararacters];
    [self setSidebarShown:YES];
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
    [state encodeBool:[[self editor] showsStatusBar] forKey:CEDefaultShowStatusBarKey];
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
        [[self editor] setShowsStatusBar:[state decodeBoolForKey:CEDefaultShowStatusBarKey] animate:NO];
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
    return (subview == [[self sidebarViewController] view]);
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
            CGFloat currentWidth = NSWidth([[[self sidebarViewController] view] bounds]);
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
    [self toggleVisibilityOfSidebarTabItemAtIndex:CESidebarTabIndexDocumentInspector];
}


// ------------------------------------------------------
/// toggle visibility of incompatible chars list view
- (IBAction)toggleIncompatibleCharList:(nullable id)sender
// ------------------------------------------------------
{
    [self toggleVisibilityOfSidebarTabItemAtIndex:CESidebarTabIndexIncompatibleChararacters];
}



#pragma mark Private Methods

// ------------------------------------------------------
/// apply passed-in document instance to window
- (void)applyDocument:(nonnull CEDocument *)document
// ------------------------------------------------------
{
    [[self editor] setDocument:document];
    
    [[self toolbarController] setDocument:document];
    [[[self window] toolbar] validateVisibleItems];
    
    // set document instance to sidebar views
    [[self sidebarViewController] setRepresentedObject:document];
}


// ------------------------------------------------------
/// return whether sidebar is opened
- (BOOL)isSidebarShown
// ------------------------------------------------------
{
    return ![[self sidebarSplitView] isSubviewCollapsed:[[self sidebarViewController] view]];
}


// ------------------------------------------------------
/// set sidebar visibility
- (void)setSidebarShown:(BOOL)shown
// ------------------------------------------------------
{
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
}


// ------------------------------------------------------
/// toggle visibility of pane in sidebar
- (void)toggleVisibilityOfSidebarTabItemAtIndex:(CESidebarTabIndex)index
// ------------------------------------------------------
{
    NSTabView *tabView = [[self sidebarViewController] tabView];
    NSUInteger currentIndex = [tabView indexOfTabViewItem:[tabView selectedTabViewItem]];
    
    if ([self isSidebarShown] && currentIndex == index) {
        [self setSidebarShown:NO];
    } else {
        [tabView selectTabViewItemAtIndex:index];
        [self setSidebarShown:YES];
    }
}

@end
