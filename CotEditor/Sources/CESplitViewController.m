/*
 
 CESplitViewController.m
 
 CotEditor
 http://coteditor.com
 
 Created by nakamuxu on 2006-03-26.
 
 ------------------------------------------------------------------------------
 
 © 2004-2007 nakamuxu
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

#import "CESplitViewController.h"
#import "CEEditorViewController.h"
#import "CENavigationBarController.h"
#import "CETextView.h"
#import "CEDefaults.h"


@interface CESplitViewController ()

// readonly
@property (readwrite, nonatomic, nullable, weak) CEEditorViewController *focusedSubviewController;

@end




#pragma mark -

@implementation CESplitViewController

#pragma mark Split View Controller Methods

// ------------------------------------------------------
/// initialize instance
- (nullable instancetype)initWithCoder:(nonnull NSCoder *)coder
// ------------------------------------------------------
{
    self = [super initWithCoder:coder];
    if (self) {
        // observe focus change
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(textViewDidBecomeFirstResponder:)
                                                     name:CETextViewDidBecomeFirstResponderNotification object:nil];
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
/// setup view
- (void)viewDidLoad
// ------------------------------------------------------
{
    [super viewDidLoad];
    
    [[self splitView] setVertical:[[NSUserDefaults standardUserDefaults] boolForKey:CEDefaultSplitViewVerticalKey]];
    [self invalidateOpenSplitEditorButtons];
}


// ------------------------------------------------------
/// update close split view button state after remove
- (void)removeSplitViewItem:(NSSplitViewItem *)splitViewItem
// ------------------------------------------------------
{
    [super removeSplitViewItem:splitViewItem];
    
    [self invalidateCloseSplitEditorButtons];
}


// ------------------------------------------------------
/// apply current state to related menu items
- (BOOL)validateMenuItem:(nonnull NSMenuItem *)menuItem
// ------------------------------------------------------
{
    if ([menuItem action] == @selector(toggleSplitOrientation:)) {
        NSString *title = [[self splitView] isVertical] ? @"Stack Editors Horizontally" : @"Stack Editors Vertically";
        [menuItem setTitle:NSLocalizedString(title, nil)];
        return ([[self splitViewItems] count] > 1);
        
    } else if (([menuItem action] == @selector(focusNextSplitTextView:)) ||
               ([menuItem action] == @selector(focusPrevSplitTextView:)))
    {
        return ([[self splitViewItems] count] > 1);
    }
    
    return YES;
}



#pragma mark Public Methods

// ------------------------------------------------------
/// add subview for given viewController at desired position
- (void)addSubviewForViewController:(nonnull CEEditorViewController *)editorViewController relativeTo:(nullable CEEditorViewController *)otherEditorViewController
// ------------------------------------------------------
{
    NSSplitViewItem *splitViewItem = [NSSplitViewItem splitViewItemWithViewController:editorViewController];
    
    if (otherEditorViewController) {
        NSUInteger baseIndex = [[self childViewControllers] indexOfObject:otherEditorViewController] ;
        [self insertSplitViewItem:splitViewItem atIndex:baseIndex + 1];
    } else {
        [self addSplitViewItem:splitViewItem];
    }
    
    [self invalidateCloseSplitEditorButtons];
}


// ------------------------------------------------------
/// find viewController for given subview
- (nullable CEEditorViewController *)viewControllerForSubview:(nonnull __kindof NSView *)view
// ------------------------------------------------------
{
    for (CEEditorViewController *viewController in [self childViewControllers]) {
        if ([viewController view] == view) {
            return viewController;
        }
    }
    
    return nil;
}



#pragma mark Action Messages

// ------------------------------------------------------
/// toggle divider orientation
- (IBAction)toggleSplitOrientation:(nullable id)sender
// ------------------------------------------------------
{
    [[self splitView] setVertical:![[self splitView] isVertical]];
    
    [self invalidateOpenSplitEditorButtons];
}


// ------------------------------------------------------
/// move focus to next text view
- (IBAction)focusNextSplitTextView:(nullable id)sender
// ------------------------------------------------------
{
    [self focusSplitTextViewOnNext:YES];
}


// ------------------------------------------------------
/// move focus to previous text view
- (IBAction)focusPrevSplitTextView:(nullable id)sender
// ------------------------------------------------------
{
    [self focusSplitTextViewOnNext:NO];
}



#pragma mark Notifications

// ------------------------------------------------------
/// editor's focus did change
- (void)textViewDidBecomeFirstResponder:(nonnull NSNotification *)notification
// ------------------------------------------------------
{
    NSAssert([[notification object] isKindOfClass:[CETextView class]], @"");
    
    for (CEEditorViewController *viewController in [self childViewControllers]) {
        if ([viewController textView] == [notification object]) {
            [self setFocusedSubviewController:viewController];
        }
    }
}



#pragma mark Private Methods

// ------------------------------------------------------
/// move focus to next/previous text view
- (void)focusSplitTextViewOnNext:(BOOL)onNext
// ------------------------------------------------------
{
    NSUInteger count = [[self splitViewItems] count];
    
    if (count < 2) { return; }
    
    NSInteger index = [[self childViewControllers] indexOfObject:[self focusedSubviewController]];
    
    if (onNext) {
        index++;
    } else {
        index--;
    }
    
    if (index < 0) {
        index = count - 1;
    } else if (index >= count) {
        index = 0;
    }
    
    CEEditorViewController *nextEditorViewController = [self childViewControllers][index];
    
    [[[self view] window] makeFirstResponder:[nextEditorViewController textView]];
}


// ------------------------------------------------------
/// update "Split Editor" button state
- (void)invalidateOpenSplitEditorButtons
// ------------------------------------------------------
{
    BOOL isVertical = [[self splitView] isVertical];
    
    for (CEEditorViewController *viewController in [self childViewControllers]) {
        [[viewController navigationBarController] setSplitOrientationVertical:isVertical];
    }
}


// ------------------------------------------------------
/// update "Close Split Editor" button state
- (void)invalidateCloseSplitEditorButtons
// ------------------------------------------------------
{
    BOOL isEnabled = ([[self splitViewItems] count] > 1);
    
    for (CEEditorViewController *viewController in [self childViewControllers]) {
        [[viewController navigationBarController] setCloseSplitButtonEnabled:isEnabled];
    }
}

@end
