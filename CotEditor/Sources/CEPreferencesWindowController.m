/*
 ==============================================================================
 CEPreferencesWindowController
 
 CotEditor
 http://coteditor.com
 
 Created on 2014-04-18 by 1024jp
 encoding="UTF-8"
 ------------------------------------------------------------------------------
 
 © 2014-2015 1024jp
 
 This program is free software; you can redistribute it and/or modify it under
 the terms of the GNU General Public License as published by the Free Software
 Foundation; either version 2 of the License, or (at your option) any later
 version.
 
 This program is distributed in the hope that it will be useful, but WITHOUT
 ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS
 FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.
 
 You should have received a copy of the GNU General Public License along with
 this program; if not, write to the Free Software Foundation, Inc., 59 Temple
 Place - Suite 330, Boston, MA  02111-1307, USA.
 
 ==============================================================================
 */

#import "CEPreferencesWindowController.h"
#import "CEWindowPaneController.h"
#import "CEAppearancePaneController.h"
#import "CEEditPaneController.h"
#import "CEFormatPaneController.h"
#import "CEFileDropPaneController.h"
#import "CEKeyBindingsPaneController.h"
#import "CEPrintPaneController.h"
#import "CEIntegrationPaneController.h"


@interface CEPreferencesWindowController ()

@property (nonatomic, copy) NSArray *viewControllers;

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
- (instancetype)initWithWindowNibName:(NSString *)windowNibName
// ------------------------------------------------------
{
    self = [super initWithWindowNibName:windowNibName];
    if (self) {
        _viewControllers = @[[[NSViewController alloc] initWithNibName:@"GeneralPane" bundle:nil],
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
- (void)windowWillClose:(NSNotification *)notification
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
    NSRect frame    = [[self window] frame];
    NSRect newFrame = [[self window] frameRectForContentRect:[newView frame]];
    newFrame.origin    = frame.origin;
    newFrame.origin.y += NSHeight(frame) - NSHeight(newFrame);
    [[self window] setFrame:newFrame display:YES animate:YES];
    
    // add new view to the main view
    [[[self window] contentView] addSubview:newView];
}

@end
