/*
 ==============================================================================
 CEPreferencesWindowController
 
 CotEditor
 http://coteditor.com
 
 Created by 2014-04-18 by 1024jp
 encoding="UTF-8"
 ------------------------------------------------------------------------------
 
 © 2014 CotEditor Project
 
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
#import "CEAppDelegate.h"
#import "constants.h"


typedef NS_ENUM(NSUInteger, CEPreferencesToolbarTag) {
    CEGeneralPane,
    CEWindowPane,
    CEAppearancePane,
    CEEditPane,
    CEFormatPane,
    CEFileDropPane,
    CEKeyBindingsPane,
    CEPrintPane
};


@interface CEPreferencesWindowController ()

@property (nonatomic) NSViewController *generalPaneController;
@property (nonatomic) CEWindowPaneController *windowPaneController;
@property (nonatomic) CEAppearancePaneController *appearancePaneController;
@property (nonatomic) CEEditPaneController *editPaneController;
@property (nonatomic) CEFormatPaneController *formatPaneController;
@property (nonatomic) CEFileDropPaneController *fileDropPaneController;
@property (nonatomic) CEKeyBindingsPaneController *keyBindingsPaneController;
@property (nonatomic) CEPrintPaneController *printPaneController;

@end




#pragma mark -

@implementation CEPreferencesWindowController

#pragma mark Class Methods

//=======================================================
// Class method
//
//=======================================================

// ------------------------------------------------------
/// return singleton instance
+ (instancetype)sharedController
// ------------------------------------------------------
{
    static dispatch_once_t predicate;
    static id shared = nil;
    
    dispatch_once(&predicate, ^{
        shared = [[self alloc] initWithWindowNibName:@"PreferencesWindow"];
    });
    
    return shared;
}



#pragma mark Superclass Methods

//=======================================================
// Superclass method
//
//=======================================================

// ------------------------------------------------------
/// 初期化
- (instancetype)initWithWindowNibName:(NSString *)windowNibName
// ------------------------------------------------------
{
    self = [super initWithWindowNibName:windowNibName];
    if (self) {
        // 各ペインを読み込む
        _generalPaneController = [[NSViewController alloc] initWithNibName:@"GeneralPane" bundle:nil];
        _windowPaneController = [[CEWindowPaneController alloc] initWithNibName:@"WindowPane" bundle:nil];
        _appearancePaneController = [[CEAppearancePaneController alloc] initWithNibName:@"AppearancePane" bundle:nil];
        _editPaneController = [[CEEditPaneController alloc] initWithNibName:@"EditPane" bundle:nil];
        _formatPaneController = [[CEFormatPaneController alloc] initWithNibName:@"FormatPane" bundle:nil];
        _fileDropPaneController = [[CEFileDropPaneController alloc] initWithNibName:@"FileDropPane" bundle:nil];
        _keyBindingsPaneController = [[CEKeyBindingsPaneController alloc] initWithNibName:@"KeyBindingsPane" bundle:nil];
        _printPaneController = [[CEPrintPaneController alloc] initWithNibName:@"PrintPane" bundle:nil];
    }
    return self;
}


// ------------------------------------------------------
/// ウインドウをロードした直後
- (void)windowDidLoad
// ------------------------------------------------------
{
    [super windowDidLoad];
    
    // 最初のビューを選ぶ
    NSToolbarItem *leftmostItem = [[[self window] toolbar] items][0];
    [[[self window] toolbar] setSelectedItemIdentifier:[leftmostItem itemIdentifier]];
    [self switchView:leftmostItem];
    [[self window] center];
}



#pragma mark Delegate and Notification

//=======================================================
// Delegate method (NSWindow)
//  <== prefWindow
//=======================================================

// ------------------------------------------------------
/// ウインドウが閉じる
- (void)windowWillClose:(NSNotification *)notification
// ------------------------------------------------------
{
    // 編集中の設定値も保存
    [[self window] makeFirstResponder:[self window]];
}



#pragma mark Action Messages

//=======================================================
// Action messages
//
//=======================================================

// ------------------------------------------------------
/// ツールバーからビューをスイッチする
- (IBAction)switchView:(id)sender
// ------------------------------------------------------
{
    // detect clicked icon and select a view to switch
    NSView   *newView;
    switch ([sender tag]) {
        case CEGeneralPane:     newView = [[self generalPaneController] view];     break;
        case CEWindowPane:      newView = [[self windowPaneController] view];      break;
        case CEAppearancePane:  newView = [[self appearancePaneController] view];  break;
        case CEEditPane:        newView = [[self editPaneController] view];        break;
        case CEFormatPane:      newView = [[self formatPaneController] view];      break;
        case CEFileDropPane:    newView = [[self fileDropPaneController] view];    break;
        case CEKeyBindingsPane: newView = [[self keyBindingsPaneController] view]; break;
        case CEPrintPane:       newView = [[self printPaneController] view];       break;
    }
    
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


//------------------------------------------------------
/// ヘルプの環境設定説明部分を開く
- (IBAction)openPreferencesHelp:(id)sender
//------------------------------------------------------
{
    [(CEAppDelegate *)[NSApp delegate] openHelpAnchor:sender];
}

@end
