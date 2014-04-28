/*
 =================================================
 CEScriptErrorPanelController
 (for CotEditor)
 
 Copyright (C) 2014 CotEditor Project
 http://coteditor.github.io
 =================================================
 
 encoding="UTF-8"
 Created:2014-03-27 by 1024jp
 
 -------------------------------------------------
 
 This program is free software; you can redistribute it and/or
 modify it under the terms of the GNU General Public License
 as published by the Free Software Foundation; either version 2
 of the License, or (at your option) any later version.
 
 This program is distributed in the hope that it will be useful,
 but WITHOUT ANY WARRANTY; without even the implied warranty of
 MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 GNU General Public License for more details.
 
 You should have received a copy of the GNU General Public License
 along with this program; if not, write to the Free Software
 Foundation, Inc., 59 Temple Place - Suite 330, Boston, MA  02111-1307, USA.
 
 
 =================================================
 */

#import "CEScriptErrorPanelController.h"


@interface CEScriptErrorPanelController ()

@property (nonatomic, strong) IBOutlet NSTextView *textView;  // on 10.8 NSTextView cannot be weak
@property (nonatomic) IBOutlet NSTextFinder *textFinder;

@end




#pragma mark -

@implementation CEScriptErrorPanelController

#pragma mark Superclass Mthods

// ------------------------------------------------------
/// initializer of panelController
- (instancetype)init
// ------------------------------------------------------
{
    return [super initWithWindowNibName:@"ScriptErrorPanel"];
}


// ------------------------------------------------------
/// ウインドウをロードした直後
- (void)windowDidLoad
// ------------------------------------------------------
{
    [[self textView] setFont:[NSFont messageFontOfSize:11]];
}



#pragma mark Public Methods

// ------------------------------------------------------
/// Scriptエラーログを追加
- (void)addErrorString:(NSString *)string
// ------------------------------------------------------
{
    [[self textView] setEditable:YES];
    [[self textView] setSelectedRange:NSMakeRange([[[self textView] string] length], 0)];
    [[self textView] insertText:[NSString stringWithFormat:@"%@\n", string]];
    [[self textView] setEditable:NO];
}



#pragma mark Action Messages

// ------------------------------------------------------
/// Scriptエラーログを削除
- (IBAction)cleanScriptError:(id)sender
// ------------------------------------------------------
{
    [[self textView] setString:@""];
}

@end




#pragma mark -

@implementation CEScriptErrorView

// ------------------------------------------------------
/// ショートカットキーを捕まえる
- (BOOL)performKeyEquivalent:(NSEvent *)theEvent
// ------------------------------------------------------
{
    // 通常の検索メニューが OgreKit によって書き換えられているので、自力でショートカットキーを捕まえる必要がある
    NSTextFinder *textFinder = [(CEScriptErrorPanelController *)[[self window] windowController] textFinder];
    
    if ([[theEvent characters] isEqualToString:@"f"]) {
        [textFinder performAction:NSTextFinderActionShowFindInterface];
        return YES;
        
    } else if ([[theEvent characters] isEqualToString:@"g"] && [theEvent modifierFlags] & NSShiftKeyMask) {
        [textFinder performAction:NSTextFinderActionPreviousMatch];
        return YES;
        
    } else if ([[theEvent characters] isEqualToString:@"g"]) {
        [textFinder performAction:NSTextFinderActionNextMatch];
        return YES;
        
    } else if ([[theEvent characters] isEqualToString:@"e"]) {
        [textFinder performAction:NSTextFinderActionSetSearchString];
        return YES;
        
    }
    
    return NO;
}

@end
