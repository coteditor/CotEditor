/*
 
 CEWindowContentViewController.h
 
 CotEditor
 http://coteditor.com
 
 Created by 1024jp on 2016-06-05.
 
 ------------------------------------------------------------------------------
 
 © 2016 1024jp
 
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

#import "CEWindowContentViewController.h"
#import "CESidebarViewController.h"
#import "CEEditorWrapper.h"
#import "CEDefaults.h"


@interface CEWindowContentViewController () <NSSplitViewDelegate>

@property (nonatomic) CGFloat sidebarWidth;

@property (readwrite, nonatomic) IBOutlet CESidebarViewController *sidebarViewController;
@property (readwrite, nonatomic) IBOutlet CEEditorWrapper *editor;

@end




#pragma mark -

@implementation CEWindowContentViewController

#pragma mark Split View Controller Methods

// ------------------------------------------------------
/// setup view
- (void)viewDidLoad
// ------------------------------------------------------
{
    [super viewDidLoad];
    
    [self addChildViewController:[self sidebarViewController]];
    
    [self setSidebarShown:[[NSUserDefaults standardUserDefaults] boolForKey:CEDefaultShowDocumentInspectorKey]];
}


// ------------------------------------------------------
/// clean up
- (void)dealloc
// ------------------------------------------------------
{
    // Need to set nil to NSSplitView's delegate manually since it is not weak but just assign,
    //     and may crash when closing split fullscreen window on El Capitan (2015-07)
    [[self splitView] setDelegate:nil];
}


// ------------------------------------------------------
/// save view state
- (void)encodeRestorableStateWithCoder:(nonnull NSCoder *)coder
// ------------------------------------------------------
{
    [coder encodeBool:[self isSidebarShown] forKey:CEDefaultShowDocumentInspectorKey];
    [coder encodeDouble:[self sidebarWidth] forKey:CEDefaultSidebarWidthKey];
}



// ------------------------------------------------------
/// restore view state from the last session
- (void)restoreStateWithCoder:(nonnull NSCoder *)coder
// ------------------------------------------------------
{
    if ([coder containsValueForKey:CEDefaultShowDocumentInspectorKey]) {
        [self setSidebarWidth:[coder decodeDoubleForKey:CEDefaultSidebarWidthKey]];
        [self setSidebarShown:[coder decodeBoolForKey:CEDefaultShowDocumentInspectorKey]];
    }
}



#pragma mark Split View Delegate

// ------------------------------------------------------
/// only sidebar can collapse
- (BOOL)splitView:(nonnull NSSplitView *)splitView canCollapseSubview:(nonnull NSView *)subview
// ------------------------------------------------------
{
    return [[[self splitView] subviews] indexOfObject:subview] == 1;
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



#pragma mark Public Methods

// ------------------------------------------------------
/// return whether sidebar is opened
- (BOOL)isSidebarShown
// ------------------------------------------------------
{
    return ![[self splitView] isSubviewCollapsed:[[self sidebarViewController] view]];
}


// ------------------------------------------------------
/// set sidebar visibility
- (void)setSidebarShown:(BOOL)shown
// ------------------------------------------------------
{
    if ([self isSidebarShown] == shown) { return; }
    
    BOOL isInitial = ![[[self view] window] isVisible];  // on `windowDidLoad` and `window:didDecodeRestorableState:`
    BOOL isFullscreen = ([[[self view] window] styleMask] & NSFullScreenWindowMask) == NSFullScreenWindowMask;
    BOOL changesWindowSize = !isInitial && !isFullscreen;
    CGFloat sidebarWidth = [self sidebarWidth] ?: [[NSUserDefaults standardUserDefaults] doubleForKey:CEDefaultSidebarWidthKey];
    CGFloat dividerThickness = [[self splitView] dividerThickness];
    CGFloat position = [[self splitView] maxPossiblePositionOfDividerAtIndex:0];
    
    // adjust divider position
    if ((changesWindowSize && !shown) || (!changesWindowSize && shown)) {
        position -= sidebarWidth;
    }
    
    // update window width
    if (changesWindowSize) {
        NSRect windowFrame = [[[self view] window] frame];
        windowFrame.size.width += shown ? (sidebarWidth + dividerThickness) : - (sidebarWidth + dividerThickness);
        [[[self view] window] setFrame:windowFrame display:NO];
    }
    
    // apply
    [[self splitView] setPosition:position ofDividerAtIndex:0];
    [[self splitView] adjustSubviews];
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
/// cast view to NSSplitView
- (nullable NSSplitView *)splitView
// ------------------------------------------------------
{
    return (NSSplitView *)[self view];
}

@end
