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
#import "CEWindowContentViewController.h"
#import "CESidebarViewController.h"
#import "CEMainViewController.h"
#import "CEStatusBarController.h"
#import "CEEditorWrapper.h"
#import "CEDefaults.h"


@interface CEWindowController ()

// IBOutlets
@property (nonatomic, nullable) IBOutlet CEToolbarController *toolbarController;
@property (nonatomic, nullable) IBOutlet CEWindowContentViewController *contentSplitViewController;

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
    [[[[self contentSplitViewController] sidebarViewController] tabView] selectTabViewItemAtIndex:CESidebarTabIndexIncompatibleChararacters];
    [[self contentSplitViewController] setSidebarShown:YES];
}


// ------------------------------------------------------
- (nullable CEEditorWrapper *)editor
// ------------------------------------------------------
{
    return [[self contentSplitViewController] editor];
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
    [state encodeBool:[[self editor] showsNavigationBar] forKey:CEDefaultShowNavigationBarKey];
    [state encodeBool:[[self editor] showsLineNum] forKey:CEDefaultShowLineNumbersKey];
    [state encodeBool:[[self editor] showsPageGuide] forKey:CEDefaultShowPageGuideKey];
    [state encodeBool:[[self editor] showsInvisibles] forKey:CEDefaultShowInvisiblesKey];
    [state encodeBool:[[self editor] isVerticalLayoutOrientation] forKey:CEDefaultLayoutTextVerticalKey];
}


// ------------------------------------------------------
/// restore window state from the last session
- (void)window:(nonnull NSWindow *)window didDecodeRestorableState:(nonnull NSCoder *)state
// ------------------------------------------------------
{
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
}



#pragma mark Private Methods

// ------------------------------------------------------
/// apply passed-in document instance to window
- (void)applyDocument:(nonnull CEDocument *)document
// ------------------------------------------------------
{
    [[self toolbarController] setDocument:document];
    [[[self window] toolbar] validateVisibleItems];
    
    [[self contentSplitViewController] setRepresentedObject:document];
}

@end
