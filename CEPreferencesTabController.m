/*
=================================================
CEPreferencesTabController
(for CotEditor)

 Copyright (C) 2004-2007 nakamuxu.
 Copyright (C) 2014 CotEditor Project
 http://coteditor.github.io
=================================================

encoding="UTF-8"
Created:2005.10.16
 
 -fno-objc-arc
 
------------
This class is based on a sample code written by mkino.
http://homepage.mac.com/mkino2/cocoaProg/AppKit/NSToolbar/NSToolbar.html

arranged by nakamuxu, Oct 2005.

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

#import "CEPreferencesTabController.h"


@implementation CEPreferencesTabController

#pragma mark ===== Public method =====

//=======================================================
// Public method
//
//=======================================================

// ------------------------------------------------------
- (void)dealloc
// 後片付け
// ------------------------------------------------------
{
    [_toolbar setDelegate:nil]; // デリゲート解除
    [_toolbar release];

    [super dealloc];
}



#pragma mark ===== Protocol =====

//=======================================================
// NSNibAwaking Protocol
//
//=======================================================

// ------------------------------------------------------
- (void)awakeFromNib
// Nibファイル読み込み直後
// ------------------------------------------------------
{
    _toolbar = [[NSToolbar alloc] initWithIdentifier:k_prefWindowToolbarID]; // ===== alloc

    // ユーザカスタマイズ可、コンフィグ内容を保存、アイコン+ラベルに設定
    [_toolbar setAllowsUserCustomization:NO];
    [_toolbar setAutosavesConfiguration:NO];
    [_toolbar setDisplayMode:NSToolbarDisplayModeIconAndLabel];
    // デリゲートを自身に指定
    [_toolbar setDelegate:self];
    // ウィンドウへ接続
    [_prefWindow setToolbar:_toolbar];
    // 初期選択項目を選択、ウィンドウをリサイズ
    [_toolbar setSelectedItemIdentifier:k_prefGeneralItemID];
    (void)[self tabView:_tabView shouldSelectTabViewItem:[_tabView selectedTabViewItem]];
}



#pragma mark === Delegate and Notification ===

//=======================================================
// Delegate method (NSToolbar)
//  <== toolbar
//=======================================================

// ------------------------------------------------------
- (NSToolbarItem *)toolbar:(NSToolbar *)inToolbar 
        itemForItemIdentifier:(NSString *)inItemIdentifier 
        willBeInsertedIntoToolbar:(BOOL)inFlag
// ツールバーアイテムを返す
// ------------------------------------------------------
{
    NSToolbarItem *outToolbarItem = 
            [[[NSToolbarItem alloc] initWithItemIdentifier:inItemIdentifier] autorelease];
    [outToolbarItem setTarget:self];
    [outToolbarItem setAction:@selector(selectTab:)];

    // General
    if ([inItemIdentifier isEqualToString:k_prefGeneralItemID]) {
        [outToolbarItem setLabel:NSLocalizedString(@"General",@"")];
        [outToolbarItem setImage:[NSImage imageNamed:@"Pref_General"]];

    // Window
    } else if ([inItemIdentifier isEqualToString:k_prefWindowItemID]) {
        [outToolbarItem setLabel:NSLocalizedString(@"Window",@"")];
        [outToolbarItem setImage:[NSImage imageNamed:@"Pref_Window"]];

    // View
    } else if ([inItemIdentifier isEqualToString:k_prefViewItemID]) {
        [outToolbarItem setLabel:NSLocalizedString(@"View",@"")];
        [outToolbarItem setImage:[NSImage imageNamed:@"Pref_View"]];

    // Format
    } else if ([inItemIdentifier isEqualToString:k_prefFormatItemID]) {
        [outToolbarItem setLabel:NSLocalizedString(@"Format",@"")];
        [outToolbarItem setImage:[NSImage imageNamed:@"Pref_Format"]];

    // Syntax
    } else if ([inItemIdentifier isEqualToString:k_prefSyntaxItemID]) {
        [outToolbarItem setLabel:NSLocalizedString(@"Syntax",@"")];
        [outToolbarItem setImage:[NSImage imageNamed:@"Pref_Syntax"]];

    // File Drop
    } else if ([inItemIdentifier isEqualToString:k_prefFileDropItemID]) {
        [outToolbarItem setLabel:NSLocalizedString(@"File Drop",@"")];
        [outToolbarItem setImage:[NSImage imageNamed:@"Pref_FileDrop"]];

    // Key Bindings
    } else if ([inItemIdentifier isEqualToString:k_prefKeyBindingsItemID]) {
        [outToolbarItem setLabel:NSLocalizedString(@"Key Bindings",@"")];
        [outToolbarItem setImage:[NSImage imageNamed:@"Pref_KeyBinding"]];

    // Print
    } else if ([inItemIdentifier isEqualToString:k_prefPrintItemID]) {
        [outToolbarItem setLabel:NSLocalizedString(@"Print",@"")];
        [outToolbarItem setImage:[NSImage imageNamed:@"Pref_Print"]];

    } else {
        outToolbarItem = nil;
    }
    return outToolbarItem;
}


// ------------------------------------------------------
- (NSArray *)toolbarAllowedItemIdentifiers:(NSToolbar *)inToolbar
// 設定画面でのツールバーアイテム配列を返す
// ------------------------------------------------------
{
    return [self toolbarDefaultItemIdentifiers:inToolbar];
}


// ------------------------------------------------------
- (NSArray *)toolbarDefaultItemIdentifiers:(NSToolbar *)inToolbar
// ツールバーアイテムデフォルト配列を返す
// ------------------------------------------------------
{
    return @[k_prefGeneralItemID, 
                k_prefWindowItemID, 
                k_prefViewItemID, 
                k_prefFormatItemID, 
                k_prefSyntaxItemID, 
                k_prefFileDropItemID, 
                k_prefKeyBindingsItemID, 
                k_prefPrintItemID];
}


// ------------------------------------------------------
- (NSArray *)toolbarSelectableItemIdentifiers:(NSToolbar *)inToolbar
// 選択可能なツールバーアイテムの配列を返す
// ------------------------------------------------------
{
    return [self toolbarDefaultItemIdentifiers:inToolbar];
}


//=======================================================
// Delegate method (NSToolbar)
//  <== toolbar
//=======================================================

// ------------------------------------------------------
- (BOOL)tabView:(NSTabView *)inTabView shouldSelectTabViewItem:(NSTabViewItem *)inTabViewItem
// タブの選択変更の許可
// ------------------------------------------------------
{
    id theTabItemView = [[inTabViewItem view] viewWithTag:k_prefTabItemViewTag];

    if (theTabItemView != nil) {
        // 各タブビューの中に仕込んだカスタムビューの大きさに合わせてウィンドウをリサイズする。
        // タブビューは、ウィンドウに対して各辺が10pxずつ小さくなっている状態で配置される必要あり。
        NSRect theFrame = [_prefWindow frame];
        NSRect theContentRect = [_prefWindow contentRectForFrameRect:theFrame];
        CGFloat theOldHeight = NSHeight(theFrame);
        CGFloat theWidthMargin = NSWidth(theFrame) - NSWidth(theContentRect);
        CGFloat theHeightMargin = theOldHeight - NSHeight(theContentRect);

        theFrame.size.width = NSWidth([theTabItemView frame]) + theWidthMargin;
        theFrame.size.height = NSHeight([theTabItemView frame]) + theHeightMargin;
        theFrame.origin.y += (theOldHeight - theFrame.size.height); // ウィンドウ左上を動かさない
        [inTabView setHidden:YES];
        [_prefWindow setFrame:theFrame display:YES animate:YES];
        [inTabView setHidden:NO];
    }
    return YES;
}



#pragma mark ===== Action messages =====

//=======================================================
// Action messages
//
//=======================================================

// ------------------------------------------------------
- (IBAction)selectTab:(id)sender
// タブを選択
//-------------------------------------------------------
{
    [_toolbar setSelectedItemIdentifier:[sender itemIdentifier]]; // ツールバーアイテムを選択し直す（Tab移動とSpaceキーでの決定で選択された時にアイテムが選択状態にならないことへの対策）
    [_tabView selectTabViewItemWithIdentifier:[sender itemIdentifier]];
}


@end
