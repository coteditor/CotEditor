/*
 
 CEMainViewController.m
 
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

#import "CEMainViewController.h"
#import "CEStatusBarController.h"
#import "CEEditorWrapper.h"
#import "CEDocument.h"
#import "CEDefaults.h"


@interface CEMainViewController ()

@property (nonatomic, nullable) IBOutlet NSSplitViewItem *statusBarItem;

@property (nonatomic, nullable) IBOutlet CEEditorWrapper *editor;

@end



#pragma mark -

@implementation CEMainViewController

#pragma mark Split View Controller Methods

// ------------------------------------------------------
/// setup view
- (void)viewDidLoad
// ------------------------------------------------------
{
    [super viewDidLoad];
    
    // setup status bar
    [self setShowsStatusBar:[[NSUserDefaults standardUserDefaults] boolForKey:CEDefaultShowStatusBarKey]];
}


// ------------------------------------------------------
/// deliver document to child view controllers
- (void)setRepresentedObject:(id)representedObject
// ------------------------------------------------------
{
    [super setRepresentedObject:representedObject];
    
    if (![representedObject isKindOfClass:[CEDocument class]]) { return; }
    
    CEDocument *document = representedObject;
    
    [(CEStatusBarController *)[[self statusBarItem] viewController] setDocumentAnalyzer:[document analyzer]];
    [[self editor] setDocument:document];
}


// ------------------------------------------------------
/// keys to be restored from the last session
+ (nonnull NSArray<NSString *> *)restorableStateKeyPaths
// ------------------------------------------------------
{
    return @[NSStringFromSelector(@selector(showsStatusBar)),
             ];
}


// ------------------------------------------------------
/// avoid showing draggable cursor
- (NSRect)splitView:(nonnull NSSplitView *)splitView effectiveRect:(NSRect)proposedEffectiveRect forDrawnRect:(NSRect)drawnRect ofDividerAtIndex:(NSInteger)dividerIndex
// ------------------------------------------------------
{
    proposedEffectiveRect.size = NSZeroSize;
    
    return [super splitView:splitView effectiveRect:proposedEffectiveRect forDrawnRect:drawnRect ofDividerAtIndex:dividerIndex];
}


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



#pragma mark Action Messages

// ------------------------------------------------------
/// toggle visibility of status bar with fancy animation
- (IBAction)toggleStatusBar:(nullable id)sender
// ------------------------------------------------------
{
    [[[self statusBarItem] animator] setCollapsed:[self showsStatusBar]];
}



#pragma mark Private Methods

// ------------------------------------------------------
/// Whether status bar is visible
- (BOOL)showsStatusBar
// ------------------------------------------------------
{
    return ![[self statusBarItem] isCollapsed];
}


// ------------------------------------------------------
/// set if status bar is shown
- (void)setShowsStatusBar:(BOOL)showsStatusBar
// ------------------------------------------------------
{
    [[self statusBarItem] setCollapsed:!showsStatusBar];
}

@end
