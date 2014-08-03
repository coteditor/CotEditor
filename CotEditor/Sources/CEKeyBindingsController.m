/*
 ==============================================================================
 CEKeyBindingsController
 
 CotEditor
 http://coteditor.github.io
 
 Created on 2014-04-18 by 1024jp
 encoding="UTF-8"
 ------------------------------------------------------------------------------
 
 © 2004-2007 nakamuxu
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

#import "CEKeyBindingsController.h"
#import "CEKeyBindingManager.h"


@implementation CEKeyBindingsController

#pragma mark Action Messages

//=======================================================
// Action messages
//
//=======================================================

// ------------------------------------------------------
/// キーバインディング編集シートを開き、閉じる
- (IBAction)openKeyBindingEditSheet:(id)sender
// ------------------------------------------------------
{
    // シートウィンドウを表示してモーダルループに入る
    // (閉じる命令は CEKeyBindingManager の closeKeyBindingEditSheet: で)
    NSWindow *sheet = [[CEKeyBindingManager sharedManager] editSheetWindowOfMode:[sender tag]];
    
    if (!sheet || ![[CEKeyBindingManager sharedManager] setupOutlineDataOfMode:[sender tag]]) {
        return;
    }
    
    [NSApp beginSheet:sheet
       modalForWindow:[[self view] window]
        modalDelegate:self
       didEndSelector:NULL
          contextInfo:NULL];
    [NSApp runModalForWindow:sheet];
    
    // シートを閉じる
    [NSApp endSheet:sheet];
    [sheet orderOut:self];
    [[[self view] window] makeKeyAndOrderFront:self];
}

@end
