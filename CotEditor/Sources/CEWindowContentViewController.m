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
#import "CEMainViewController.h"
#import "CESidebarViewController.h"
#import "CEDefaults.h"


@interface CEWindowContentViewController () <NSSplitViewDelegate>

@property (nonatomic, nullable) IBOutlet NSSplitViewItem *mainViewItem;
@property (nonatomic, nullable) IBOutlet NSSplitViewItem *sidebarViewItem;

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
    
    // set behavior to glow window size on sidebar toggling rather than opening sidebar indraw (only on El Capitan or later)
    if (NSAppKitVersionNumber > NSAppKitVersionNumber10_10_Max) {
        [[self sidebarViewItem] setCollapseBehavior:NSSplitViewItemCollapseBehaviorPreferResizingSplitViewWithFixedSiblings];
    }
    
    [self setSidebarShown:[[NSUserDefaults standardUserDefaults] boolForKey:CEDefaultShowDocumentInspectorKey]];
    [self setSidebarThickness:(CGFloat)[[NSUserDefaults standardUserDefaults] doubleForKey:CEDefaultSidebarWidthKey]];
}


// ------------------------------------------------------
/// deliver represented object to child view controllers
- (void)setRepresentedObject:(id)representedObject
// ------------------------------------------------------
{
    [super setRepresentedObject:representedObject];
    
    for (__kindof NSViewController *viewController in [self childViewControllers]) {
        [viewController setRepresentedObject:representedObject];
    }
}


// ------------------------------------------------------
/// store current sidebar width
- (void)splitViewDidResizeSubviews:(nonnull NSNotification *)notification
// ------------------------------------------------------
{
    if ([notification userInfo][@"NSSplitViewDividerIndex"]) {  // check wheter the change coused by user's divider dragging
        if ([self isSidebarShown]) {
            [[NSUserDefaults standardUserDefaults] setDouble:[self sidebarThickness] forKey:CEDefaultSidebarWidthKey];
        }
    }
}



#pragma mark Public Methods

// ------------------------------------------------------
/// display desired sidebar pane
- (void)showSidebarPaneWithIndex:(CESidebarTabIndex)index
// ------------------------------------------------------
{
    [[[self sidebarViewController] tabView] selectTabViewItemAtIndex:index];
    [[[self sidebarViewItem] animator] setCollapsed:NO];
}


// ------------------------------------------------------
/// deliver editor to outer view controllers
- (nullable CEEditorWrapper *)editor
// ------------------------------------------------------
{
    return [(CEMainViewController *)[[self mainViewItem] viewController] editor];
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
/// split view item to view controller
- (nullable NSTabViewController *)sidebarViewController
// ------------------------------------------------------
{
    return (NSTabViewController *)[[self sidebarViewItem] viewController];
}


// ------------------------------------------------------
/// return sidebar thickness
- (CGFloat)sidebarThickness
// ------------------------------------------------------
{
    return NSWidth([[[self sidebarViewController] view] frame]);
}


// ------------------------------------------------------
/// return sidebar thickness
- (void)setSidebarThickness:(CGFloat)sidebarThickness
// ------------------------------------------------------
{
    NSSize size = [[[self sidebarViewController] view] frame].size;
    
    size.width = sidebarThickness;
    
    [[[self sidebarViewController] view] setFrameSize:size];
}


// ------------------------------------------------------
/// return whether sidebar is opened
- (BOOL)isSidebarShown
// ------------------------------------------------------
{
    return ![[self sidebarViewItem] isCollapsed];
}


// ------------------------------------------------------
/// set sidebar visibility
- (void)setSidebarShown:(BOOL)shown
// ------------------------------------------------------
{
    [[self sidebarViewItem] setCollapsed:!shown];
}


// ------------------------------------------------------
/// toggle visibility of pane in sidebar
- (void)toggleVisibilityOfSidebarTabItemAtIndex:(CESidebarTabIndex)index
// ------------------------------------------------------
{
    NSTabViewController *sidebarViewController = [self sidebarViewController];
    BOOL collapsed = ([self isSidebarShown] && index == [sidebarViewController selectedTabViewItemIndex]);
    
    [sidebarViewController setSelectedTabViewItemIndex:index];
    [[[self sidebarViewItem] animator] setCollapsed:collapsed];
}

@end
