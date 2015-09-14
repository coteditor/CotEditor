/*
 
 CEPreferencesWindowController.m
 
 CotEditor
 http://coteditor.com
 
 Created by 1024jp on 2014-04-18.

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

#import "CEPreferencesWindowController.h"
#import "CEGeneralPaneController.h"
#import "CEWindowPaneController.h"
#import "CEAppearancePaneController.h"
#import "CEEditPaneController.h"
#import "CEFormatPaneController.h"
#import "CEFileDropPaneController.h"
#import "CEKeyBindingsPaneController.h"
#import "CEPrintPaneController.h"
#import "CEIntegrationPaneController.h"


@interface CEPreferencesWindowController ()

@property (nonatomic, nonnull, copy) NSArray<__kindof NSViewController *> *viewControllers;

@end




#pragma mark -

@implementation CEPreferencesWindowController

#pragma mark Singleton

// ------------------------------------------------------
/// return singleton instance
+ (nonnull instancetype)sharedController
// ------------------------------------------------------
{
    static dispatch_once_t onceToken;
    static id shared = nil;
    
    dispatch_once(&onceToken, ^{
        shared = [[self alloc] initWithWindowNibName:@"PreferencesWindow"];
    });
    
    return shared;
}



#pragma mark Superclass Methods

// ------------------------------------------------------
/// initialize
- (nonnull instancetype)initWithWindowNibName:(nonnull NSString *)windowNibName
// ------------------------------------------------------
{
    self = [super initWithWindowNibName:windowNibName];
    if (self) {
        _viewControllers = @[[[CEGeneralPaneController alloc] initWithNibName:@"GeneralPane" bundle:nil],
                             [[CEWindowPaneController alloc] initWithNibName:@"WindowPane" bundle:nil],
                             [[CEAppearancePaneController alloc] initWithNibName:@"AppearancePane" bundle:nil],
                             [[CEEditPaneController alloc] initWithNibName:@"EditPane" bundle:nil],
                             [[CEFormatPaneController alloc] initWithNibName:@"FormatPane" bundle:nil],
                             [[CEFileDropPaneController alloc] initWithNibName:@"FileDropPane" bundle:nil],
                             [[CEKeyBindingsPaneController alloc] initWithNibName:@"KeyBindingsPane" bundle:nil],
                             [[CEPrintPaneController alloc] initWithNibName:@"PrintPane" bundle:nil],
                             [[CEIntegrationPaneController alloc] initWithNibName:@"IntegrationPane" bundle:nil]];
    }
    return self;
}


// ------------------------------------------------------
/// setup UI
- (void)windowDidLoad
// ------------------------------------------------------
{
    [super windowDidLoad];
    
    // select first view
    NSToolbarItem *leftmostItem = [[[[self window] toolbar] items] firstObject];
    [[[self window] toolbar] setSelectedItemIdentifier:[leftmostItem itemIdentifier]];
    [self switchView:leftmostItem];
    [[self window] center];
}



#pragma mark Delegate

// ------------------------------------------------------
/// window will close
- (void)windowWillClose:(nonnull NSNotification *)notification
// ------------------------------------------------------
{
    // finish current edit
    [[self window] makeFirstResponder:[self window]];
}



#pragma mark Action Messages

// ------------------------------------------------------
/// switch panes from toolbar
- (IBAction)switchView:(nullable id)sender
// ------------------------------------------------------
{
    // detect clicked icon and select the view to switch
    NSView *newView = [(NSViewController *)[self viewControllers][[sender tag]] view];
    
    // remove current view from the main view
    for (NSView *view in [[[self window] contentView] subviews]) {
        [view removeFromSuperview];
    }
    
    // set window title
    [[self window] setTitle:[sender label]];
    
    // resize window to fit to new view
    NSRect frame = [[self window] frame];
    NSRect newFrame = [[self window] frameRectForContentRect:[newView frame]];
    newFrame.origin = frame.origin;
    newFrame.origin.y += NSHeight(frame) - NSHeight(newFrame);
    [[self window] setFrame:newFrame display:YES animate:YES];
    
    // add new view to the main view
    [[[self window] contentView] addSubview:newView];
}

@end
