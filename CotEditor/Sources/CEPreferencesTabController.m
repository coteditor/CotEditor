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
#import "constants.h"


@interface CEPreferencesTabController ()

@property (nonatomic) NSToolbar *toolbar;

@property (nonatomic) IBOutlet NSWindow *prefWindow;
@property (nonatomic) IBOutlet NSTabView *tabView;

@end


#pragma mark -

@implementation CEPreferencesTabController

#pragma mark NSObject Methods

//=======================================================
// NSObject method
//
//=======================================================

// ------------------------------------------------------
- (void)dealloc
// 後片付け
// ------------------------------------------------------
{
    [[self toolbar] setDelegate:nil]; // デリゲート解除
}



#pragma mark Protocol

//=======================================================
// NSNibAwaking Protocol
//
//=======================================================

// ------------------------------------------------------
- (void)awakeFromNib
// Nibファイル読み込み直後
// ------------------------------------------------------
{
    [self setToolbar:[[NSToolbar alloc] initWithIdentifier:k_prefWindowToolbarID]];

    // ユーザカスタマイズ可、コンフィグ内容を保存、アイコン+ラベルに設定
    [[self toolbar] setAllowsUserCustomization:NO];
    [[self toolbar] setAutosavesConfiguration:NO];
    [[self toolbar] setDisplayMode:NSToolbarDisplayModeIconAndLabel];
    // デリゲートを自身に指定
    [[self toolbar] setDelegate:self];
    // ウィンドウへ接続
    [[self prefWindow] setToolbar:[self toolbar]];
    // 初期選択項目を選択、ウィンドウをリサイズ
    [[self toolbar] setSelectedItemIdentifier:k_prefGeneralItemID];
    (void)[self tabView:[self tabView] shouldSelectTabViewItem:[[self tabView] selectedTabViewItem]];
}



#pragma mark Delegate and Notification

//=======================================================
// Delegate method (NSToolbar)
//  <== toolbar
//=======================================================

// ------------------------------------------------------
- (NSToolbarItem *)toolbar:(NSToolbar *)toolbar
        itemForItemIdentifier:(NSString *)itemIdentifier 
        willBeInsertedIntoToolbar:(BOOL)flag
// ツールバーアイテムを返す
// ------------------------------------------------------
{
    NSToolbarItem *outToolbarItem = [[NSToolbarItem alloc] initWithItemIdentifier:itemIdentifier];
    [outToolbarItem setTarget:self];
    [outToolbarItem setAction:@selector(selectTab:)];

    // General
    if ([itemIdentifier isEqualToString:k_prefGeneralItemID]) {
        [outToolbarItem setLabel:NSLocalizedString(@"General", @"")];
        [outToolbarItem setImage:[NSImage imageNamed:@"Pref_General"]];

    // Window
    } else if ([itemIdentifier isEqualToString:k_prefWindowItemID]) {
        [outToolbarItem setLabel:NSLocalizedString(@"Window", @"")];
        [outToolbarItem setImage:[NSImage imageNamed:@"Pref_Window"]];

    // View
    } else if ([itemIdentifier isEqualToString:k_prefViewItemID]) {
        [outToolbarItem setLabel:NSLocalizedString(@"View", @"")];
        [outToolbarItem setImage:[NSImage imageNamed:@"Pref_View"]];

    // Format
    } else if ([itemIdentifier isEqualToString:k_prefFormatItemID]) {
        [outToolbarItem setLabel:NSLocalizedString(@"Format", @"")];
        [outToolbarItem setImage:[NSImage imageNamed:@"Pref_Format"]];

    // Syntax
    } else if ([itemIdentifier isEqualToString:k_prefSyntaxItemID]) {
        [outToolbarItem setLabel:NSLocalizedString(@"Syntax", @"")];
        [outToolbarItem setImage:[NSImage imageNamed:@"Pref_Syntax"]];

    // File Drop
    } else if ([itemIdentifier isEqualToString:k_prefFileDropItemID]) {
        [outToolbarItem setLabel:NSLocalizedString(@"File Drop", @"")];
        [outToolbarItem setImage:[NSImage imageNamed:@"Pref_FileDrop"]];

    // Key Bindings
    } else if ([itemIdentifier isEqualToString:k_prefKeyBindingsItemID]) {
        [outToolbarItem setLabel:NSLocalizedString(@"Key Bindings", @"")];
        [outToolbarItem setImage:[NSImage imageNamed:@"Pref_KeyBinding"]];

    // Print
    } else if ([itemIdentifier isEqualToString:k_prefPrintItemID]) {
        [outToolbarItem setLabel:NSLocalizedString(@"Print", @"")];
        [outToolbarItem setImage:[NSImage imageNamed:@"Pref_Print"]];

    } else {
        outToolbarItem = nil;
    }
    return outToolbarItem;
}


// ------------------------------------------------------
- (NSArray *)toolbarAllowedItemIdentifiers:(NSToolbar *)toolbar
// 設定画面でのツールバーアイテム配列を返す
// ------------------------------------------------------
{
    return [self toolbarDefaultItemIdentifiers:toolbar];
}


// ------------------------------------------------------
- (NSArray *)toolbarDefaultItemIdentifiers:(NSToolbar *)toolbar
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
- (NSArray *)toolbarSelectableItemIdentifiers:(NSToolbar *)toolbar
// 選択可能なツールバーアイテムの配列を返す
// ------------------------------------------------------
{
    return [self toolbarDefaultItemIdentifiers:toolbar];
}


//=======================================================
// Delegate method (NSToolbar)
//  <== toolbar
//=======================================================

// ------------------------------------------------------
- (BOOL)tabView:(NSTabView *)tabView shouldSelectTabViewItem:(NSTabViewItem *)tabViewItem
// タブの選択変更の許可
// ------------------------------------------------------
{
    id tabItemView = [[tabViewItem view] viewWithTag:k_prefTabItemViewTag];

    if (tabItemView != nil) {
        // 各タブビューの中に仕込んだカスタムビューの大きさに合わせてウィンドウをリサイズする。
        // タブビューは、ウィンドウに対して各辺が10pxずつ小さくなっている状態で配置される必要あり。
        NSRect frame = [[self prefWindow] frame];
        NSRect contentRect = [[self prefWindow] contentRectForFrameRect:frame];
        CGFloat oldHeight = NSHeight(frame);
        CGFloat widthMargin = NSWidth(frame) - NSWidth(contentRect);
        CGFloat heightMargin = oldHeight - NSHeight(contentRect);

        frame.size.width = NSWidth([tabItemView frame]) + widthMargin;
        frame.size.height = NSHeight([tabItemView frame]) + heightMargin;
        frame.origin.y += (oldHeight - frame.size.height);  // ウィンドウ左上を動かさない
        [tabView setHidden:YES];
        [[self prefWindow] setFrame:frame display:YES animate:YES];
        [tabView setHidden:NO];
    }
    return YES;
}



#pragma mark Action Messages

//=======================================================
// Action messages
//
//=======================================================

// ------------------------------------------------------
- (IBAction)selectTab:(id)sender
// タブを選択
//-------------------------------------------------------
{
    [[self toolbar] setSelectedItemIdentifier:[sender itemIdentifier]]; // ツールバーアイテムを選択し直す（Tab移動とSpaceキーでの決定で選択された時にアイテムが選択状態にならないことへの対策）
    [[self tabView] selectTabViewItemWithIdentifier:[sender itemIdentifier]];
}


@end
