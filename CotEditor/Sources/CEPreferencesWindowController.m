/*
 
 CEPreferencesWindowController.m
 
 CotEditor
 http://coteditor.com
 
 Created by 1024jp on 2014-04-18.

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

#import "CEPreferencesWindowController.h"

#import "CotEditor-Swift.h"

#import "CEGeneralPaneController.h"
#import "CEAppearancePaneController.h"
#import "CEEditPaneController.h"
#import "CEFormatPaneController.h"
#import "CEFileDropPaneController.h"
#import "CEPrintPaneController.h"


@interface CEPreferencesWindowController ()

@property (nonatomic, nonnull, copy) NSArray<__kindof NSViewController *> *viewControllers;

@end




#pragma mark -

@implementation CEPreferencesWindowController

#pragma mark Singleton

// ------------------------------------------------------
/// return singleton instance
+ (nonnull CEPreferencesWindowController *)sharedController
// ------------------------------------------------------
{
    static dispatch_once_t onceToken;
    static id shared = nil;
    
    dispatch_once(&onceToken, ^{
        shared = [[self alloc] init];
    });
    
    return shared;
}



#pragma mark Superclass Methods

// ------------------------------------------------------
/// initialize
- (nonnull instancetype)init
// ------------------------------------------------------
{
    self = [super init];
    if (self) {
        _viewControllers = @[[[CEGeneralPaneController alloc] init],
                             [[WindowPaneController alloc] init],
                             [[CEAppearancePaneController alloc] init],
                             [[CEEditPaneController alloc] init],
                             [[CEFormatPaneController alloc] init],
                             [[CEFileDropPaneController alloc] init],
                             [[KeyBindingsPaneController alloc] init],
                             [[CEPrintPaneController alloc] init],
                             [[IntegrationPaneController alloc] init]];
    }
    return self;
}


// ------------------------------------------------------
/// nib name
- (nullable NSString *)windowNibName
// ------------------------------------------------------
{
    return @"PreferencesWindow";
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
        [view removeFromSuperviewWithoutNeedingDisplay];
    }
    
    // set window title
    [[self window] setTitle:[sender paletteLabel]];
    
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
