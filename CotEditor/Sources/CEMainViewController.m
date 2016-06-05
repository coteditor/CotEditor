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

@property (nonatomic, nullable) IBOutlet CEStatusBarController *statusBarController;
@property (nonatomic, nullable) IBOutlet CEEditorWrapper *editor;

@end



#pragma mark -

@implementation CEMainViewController

// ------------------------------------------------------
/// setup view
- (void)viewDidLoad
// ------------------------------------------------------
{
    [super viewDidLoad];
    
    // setup status bar
    [[self statusBarController] setShown:[[NSUserDefaults standardUserDefaults] boolForKey:CEDefaultShowStatusBarKey] animate:NO];
}


// ------------------------------------------------------
- (void)setRepresentedObject:(id)representedObject
// ------------------------------------------------------
{
    [[self statusBarController] setDocumentAnalyzer:[representedObject analyzer]];
    [[self editor] setDocument:representedObject];
    
    [super setRepresentedObject:representedObject];
}


// ------------------------------------------------------
/// save view state
- (void)encodeRestorableStateWithCoder:(nonnull NSCoder *)coder
// ------------------------------------------------------
{
    [coder encodeBool:[self showsStatusBar] forKey:CEDefaultShowStatusBarKey];
}


// ------------------------------------------------------
/// restore view state from the last session
- (void)restoreStateWithCoder:(nonnull NSCoder *)coder
// ------------------------------------------------------
{
    if ([coder containsValueForKey:CEDefaultShowStatusBarKey]) {
        [self setShowsStatusBar:[coder decodeBoolForKey:CEDefaultShowStatusBarKey] animate:NO];
    }
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
        NSString *title = [[self statusBarController] isShown] ? @"Hide Status Bar" : @"Show Status Bar";
        [menuItem setTitle:NSLocalizedString(title, nil)];
    }
    return YES;
}



#pragma mark Action Messages

// ------------------------------------------------------
/// toggle visibility of status bar
- (IBAction)toggleStatusBar:(nullable id)sender
// ------------------------------------------------------
{
    [[self statusBarController] setShown:![[self statusBarController] isShown] animate:YES];
}



// ------------------------------------------------------
/// ステータスバーを表示する／しない
- (BOOL)showsStatusBar
// ------------------------------------------------------
{
    return [[self statusBarController] isShown];
}


// ------------------------------------------------------
/// ステータスバーを表示する／しないをセット
- (void)setShowsStatusBar:(BOOL)showsStatusBar animate:(BOOL)performAnimation
// ------------------------------------------------------
{
    [[self statusBarController] setShown:showsStatusBar animate:performAnimation];
}


@end
