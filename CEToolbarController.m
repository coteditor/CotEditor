/*
=================================================
CEToolbarController
(for CotEditor)

Copyright (C) 2004-2007 nakamuxu.
http://www.aynimac.com/
=================================================

encoding="UTF-8"
Created:2005.01.07

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

#import "CEToolbarController.h"

//=======================================================
// Private method
//
//=======================================================

@interface CEToolbarController (Private)
- (void)doUpdateToggleItem:(NSToolbarItem *)inItem setOn:(BOOL)inBool;
@end


//------------------------------------------------------------------------------------------




@implementation CEToolbarController

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

    [_lineEndingPopupButton release];
    [_encodingPopupButton release];
    [_syntaxPopupButton release];

    [super dealloc];
}


// ------------------------------------------------------
- (void)setupToolbar
// ツールバーをセットアップ
// ------------------------------------------------------
{
    _toolbar = [[NSToolbar alloc] initWithIdentifier:k_docWindowToolbarID]; // ===== alloc

    // ユーザカスタマイズ可、コンフィグ内容を保存、アイコン+ラベルに設定
    [_toolbar setAllowsUserCustomization:YES];
    [_toolbar setAutosavesConfiguration:YES];
    [_toolbar setDisplayMode:NSToolbarDisplayModeIconAndLabel];
    // デリゲートを自身に指定
    [_toolbar setDelegate:self];
    // ウィンドウへ接続
    [_mainWindow setToolbar:_toolbar];
}


// ------------------------------------------------------
- (void)updateToggleItem:(NSString *)inIdentifer setOn:(BOOL)inBool
// トグルアイテムの状態を更新
// ------------------------------------------------------
{
    NSEnumerator *theItems = [[_toolbar items] objectEnumerator];
    id theItem;

    while (theItem = [theItems nextObject]) {
        if ([[theItem itemIdentifier] isEqualToString:inIdentifer]) {
            [self doUpdateToggleItem:theItem setOn:inBool];
            break;
        }
    }
}


// ------------------------------------------------------
- (void)buildEncodingPopupButton
// エンコーディングポップアップアイテムを生成
// ------------------------------------------------------
{
    [_encodingPopupButton setMenu:[[[[NSApp delegate] encodingMenu] copy] autorelease]];
}


// ------------------------------------------------------
- (void)setSelectEncoding:(NSInteger)inEncoding
// エンコーディングポップアップの選択項目を設定
// ------------------------------------------------------
{
    NSEnumerator *theEnumerator = [[_encodingPopupButton itemArray] objectEnumerator];
    id theMenuItem;

    while (theMenuItem = [theEnumerator nextObject]) {
        if ([theMenuItem tag] == inEncoding) {
            [_encodingPopupButton selectItem:theMenuItem];
            break;
        }
    }
}


// ------------------------------------------------------
- (void)setSelectEndingItemIndex:(NSInteger)inIndex
// 行末コードポップアップの選択項目を設定
// ------------------------------------------------------
{
    NSInteger theMax = [[_lineEndingPopupButton itemArray] count];
    if ((inIndex < 0) || (inIndex >= theMax)) { return; }

    [_lineEndingPopupButton selectItemAtIndex:inIndex];
}


// ------------------------------------------------------
- (void)buildSyntaxPopupButton
// シンタックスカラーリングポップアップアイテムを生成
// ------------------------------------------------------
{
    [_syntaxPopupButton setMenu:[[[[NSApp delegate] syntaxMenu] copy] autorelease]];
}


// ------------------------------------------------------
- (NSString *)selectedTitleOfSyntaxItem
// シンタックスカラーリングポップアップアイテムで選択されているタイトル文字列を返す
// ------------------------------------------------------
{
    return [_syntaxPopupButton titleOfSelectedItem];
}


// ------------------------------------------------------
- (void)setSelectSyntaxItemWithTitle:(NSString *)inTitle
// シンタックスカラーリングポップアップの選択項目をタイトル名で設定
// ------------------------------------------------------
{
    id theMenuItem = [_syntaxPopupButton itemWithTitle:inTitle];
    if (theMenuItem != nil) {
        [_syntaxPopupButton selectItem:theMenuItem];
    } else {
        [_syntaxPopupButton selectItemAtIndex:0]; // "None" を選択
    }
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
    [_lineEndingPopupButton retain]; // ===== retain (Outletだが、片付けられてしまうため保持しておく)
    [_encodingPopupButton retain]; // ===== retain (Outletだが、片付けられてしまうため保持しておく)
    [_syntaxPopupButton retain]; // ===== retain (Outletだが、片付けられてしまうため保持しておく)
    [self buildEncodingPopupButton];
    [self buildSyntaxPopupButton];
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
    id theValues = [[NSUserDefaultsController sharedUserDefaultsController] values];
    NSToolbarItem *outToolbarItem = 
            [[[NSToolbarItem alloc] initWithItemIdentifier:inItemIdentifier] autorelease];

    // Get Info (target = FirstResponder)
    if ([inItemIdentifier isEqualToString:k_getInfoItemID]) {
        [outToolbarItem setLabel:NSLocalizedString(@"Get Info",@"")];
        [outToolbarItem setPaletteLabel:NSLocalizedString(@"Get Info",@"")];
        [outToolbarItem setToolTip:NSLocalizedString(@"Show document information",@"")];
        [outToolbarItem setImage:[NSImage imageNamed:@"getInfo"]];
        [outToolbarItem setAction:@selector(getInfo:)];

    // Show Incompatible Char (target = FirstResponder)
    } else if ([inItemIdentifier isEqualToString:k_showIncompatibleCharItemID]) {
        [outToolbarItem setLabel:NSLocalizedString(@"Incompatible Char",@"")];
        [outToolbarItem setPaletteLabel:NSLocalizedString(@"Show Incompatible Char(s)",@"")];
        [outToolbarItem setToolTip:NSLocalizedString(@"Show Incompatible Char for the encoding",@"")];
        [outToolbarItem setImage:[NSImage imageNamed:@"IncompatibleChar"]];
        [outToolbarItem setAction:@selector(toggleIncompatibleCharList:)];

    // Preferences
    } else if ([inItemIdentifier isEqualToString:k_preferencesItemID]) {
        [outToolbarItem setLabel:NSLocalizedString(@"Preferences",@"")];
        [outToolbarItem setPaletteLabel:NSLocalizedString(@"Preferences",@"")];
        [outToolbarItem setToolTip:NSLocalizedString(@"Open Preferences panel",@"")];
        [outToolbarItem setImage:[NSImage imageNamed:@"Preferences"]];
        [outToolbarItem setTarget:[NSApp delegate]]; // = CEAppController
        [outToolbarItem setAction:@selector(openPrefWindow:)];

    // Save (target = FirstResponder)
    } else if ([inItemIdentifier isEqualToString:k_saveItemID]) {
        [outToolbarItem setLabel:NSLocalizedString(@"Save",@"")];
        [outToolbarItem setPaletteLabel:NSLocalizedString(@"Save",@"")];
        [outToolbarItem setToolTip:NSLocalizedString(@"Save document",@"")];
        [outToolbarItem setImage:[NSImage imageNamed:@"Save"]];
        [outToolbarItem setAction:@selector(saveDocument:)];

    // Save As (target = FirstResponder)
    } else if ([inItemIdentifier isEqualToString:k_saveAsItemID]) {
        [outToolbarItem setLabel:NSLocalizedString(@"Save As",@"")];
        [outToolbarItem setPaletteLabel:NSLocalizedString(@"Save As",@"")];
        [outToolbarItem setToolTip:NSLocalizedString(@"Save document as other name",@"")];
        [outToolbarItem setImage:[NSImage imageNamed:@"SaveAs"]];
        [outToolbarItem setAction:@selector(saveDocumentAs:)];

    // Page setup (target = FirstResponder)
    } else if ([inItemIdentifier isEqualToString:k_pageSetupItemID]) {
        [outToolbarItem setLabel:NSLocalizedString(@"Page Setup",@"")];
        [outToolbarItem setPaletteLabel:NSLocalizedString(@"Page Setup",@"")];
        [outToolbarItem setToolTip:NSLocalizedString(@"Print page setup",@"")];
        [outToolbarItem setImage:[NSImage imageNamed:@"PageSetup"]];
        [outToolbarItem setAction:@selector(runPageLayout:)];

    // Open TransparencyPanel (target = FirstResponder(CEDocumentController))
    } else if ([inItemIdentifier isEqualToString:k_openTransparencyPanelItemID]) {
        [outToolbarItem setLabel:NSLocalizedString(@"Trans. Panel",@"")];
        [outToolbarItem setPaletteLabel:NSLocalizedString(@"Transparency Panel",@"")];
        [outToolbarItem setToolTip:NSLocalizedString(@"Open window Transparency Panel",@"")];
        [outToolbarItem setImage:[NSImage imageNamed:@"TransparencyPanel"]];
        [outToolbarItem setAction:@selector(openTransparencyPanel:)];

    // Bigger Font
    } else if ([inItemIdentifier isEqualToString:k_biggerFontItemID]) {
        [outToolbarItem setLabel:NSLocalizedString(@"Bigger",@"")];
        [outToolbarItem setPaletteLabel:NSLocalizedString(@"Bigger Font",@"")];
        [outToolbarItem setToolTip:NSLocalizedString(@"Increases Font size",@"")];
        [outToolbarItem setImage:[NSImage imageNamed:@"biggerFont"]];
        [outToolbarItem setTarget:[NSFontManager sharedFontManager]];
        [outToolbarItem setAction:@selector(modifyFont:)];
        [outToolbarItem setTag:NSSizeUpFontAction];

    // Smaller Font
    } else if ([inItemIdentifier isEqualToString:k_smallerFontItemID]) {
        [outToolbarItem setLabel:NSLocalizedString(@"Smaller",@"")];
        [outToolbarItem setPaletteLabel:NSLocalizedString(@"Smaller Font",@"")];
        [outToolbarItem setToolTip:NSLocalizedString(@"Decreases Font size",@"")];
        [outToolbarItem setImage:[NSImage imageNamed:@"smallerFont"]];
        [outToolbarItem setTarget:[NSFontManager sharedFontManager]];
        [outToolbarItem setAction:@selector(modifyFont:)];
        [outToolbarItem setTag:NSSizeDownFontAction];

    // Shift Left (target = FirstResponder)
    } else if ([inItemIdentifier isEqualToString:k_shiftLeftItemID]) {
        [outToolbarItem setLabel:NSLocalizedString(@"Shift Left",@"")];
        [outToolbarItem setPaletteLabel:NSLocalizedString(@"Shift Left",@"")];
        [outToolbarItem setToolTip:NSLocalizedString(@"Shift line to Left",@"")];
        [outToolbarItem setImage:[NSImage imageNamed:@"Shift_Left"]];
        [outToolbarItem setAction:@selector(shiftLeft:)];

    // Shift Right (target = FirstResponder)
    } else if ([inItemIdentifier isEqualToString:k_shiftRightItemID]) {
        [outToolbarItem setLabel:NSLocalizedString(@"Shift Right",@"")];
        [outToolbarItem setPaletteLabel:NSLocalizedString(@"Shift Right",@"")];
        [outToolbarItem setToolTip:NSLocalizedString(@"Shift line to Right",@"")];
        [outToolbarItem setImage:[NSImage imageNamed:@"Shift_Right"]];
        [outToolbarItem setAction:@selector(shiftRight:)];

    // Show Navigation Bar (target = FirstResponder)
    } else if ([inItemIdentifier isEqualToString:k_showNavigationBarItemID]) {
        [outToolbarItem setLabel:NSLocalizedString(@"Navigation Bar",@"")];
        [outToolbarItem setPaletteLabel:NSLocalizedString(@"Show / Hide Navigation Bar",@"")];
        [outToolbarItem setToolTip:NSLocalizedString(@"Show or Hide Navigation Bar of window",@"")];
        [self doUpdateToggleItem:outToolbarItem setOn:
                [[theValues valueForKey:k_key_showNavigationBar] boolValue]];
        [outToolbarItem setAction:@selector(toggleShowNavigationBar:)];

    // Show Line Num (target = FirstResponder)
    } else if ([inItemIdentifier isEqualToString:k_showLineNumItemID]) {
        [outToolbarItem setLabel:NSLocalizedString(@"LineNum",@"")];
        [outToolbarItem setPaletteLabel:NSLocalizedString(@"Show / Hide Line Number",@"")];
        [outToolbarItem setToolTip:NSLocalizedString(@"Show or Hide Line Number of text",@"")];
        [self doUpdateToggleItem:outToolbarItem setOn:[[theValues valueForKey:k_key_showLineNumbers] boolValue]];
        [outToolbarItem setAction:@selector(toggleShowLineNum:)];

    // Show Status Bar (target = FirstResponder)
    } else if ([inItemIdentifier isEqualToString:k_showStatusBarItemID]) {
        [outToolbarItem setLabel:NSLocalizedString(@"Status Bar",@"")];
        [outToolbarItem setPaletteLabel:NSLocalizedString(@"Show / Hide Status Bar",@"")];
        [outToolbarItem setToolTip:NSLocalizedString(@"Show or Hide Status Bar of window",@"")];
        [self doUpdateToggleItem:outToolbarItem setOn:[[theValues valueForKey:k_key_showStatusBar] boolValue]];
        [outToolbarItem setAction:@selector(toggleShowStatusBar:)];

    // Show Invisible Characters (target = FirstResponder)
    } else if ([inItemIdentifier isEqualToString:k_showInvisibleCharsItemID]) {
        BOOL theBoolToActivate = [[[_mainWindow windowController] document] canActivateShowInvisibleCharsItem];

        [outToolbarItem setLabel:NSLocalizedString(@"Invisible Chars",@"")];
        [outToolbarItem setPaletteLabel:NSLocalizedString(@"Show / Hide Invisible Chars",@"")];
        // ツールバーアイテムを有効化できなければツールチップを変更
        if (theBoolToActivate) {
            [outToolbarItem setToolTip:NSLocalizedString(@"Show or Hide Invisible Characters in Text",@"")];
            [self doUpdateToggleItem:outToolbarItem setOn:YES];
            [outToolbarItem setAction:@selector(toggleShowInvisibleChars:)];
        } else {
            [outToolbarItem setToolTip:NSLocalizedString(@"To display invisible characters, set in Preferences and re-open the document.",@"")];
            [self doUpdateToggleItem:outToolbarItem setOn:NO];
            [outToolbarItem setAction:nil];
        }

    // Show Page Guide (target = FirstResponder)
    } else if ([inItemIdentifier isEqualToString:k_showPageGuideItemID]) {
        [outToolbarItem setLabel:NSLocalizedString(@"Page Guide",@"")];
        [outToolbarItem setPaletteLabel:NSLocalizedString(@"Show / Hide Page Guide",@"")];
        [outToolbarItem setToolTip:NSLocalizedString(@"Show or Hide Page Guide Line",@"")];
        [self doUpdateToggleItem:outToolbarItem setOn:[[theValues valueForKey:k_key_showPageGuide] boolValue]];
        [outToolbarItem setAction:@selector(toggleShowPageGuide:)];

    // Wrap lines (target = FirstResponder)
    } else if ([inItemIdentifier isEqualToString:k_wrapLinesItemID]) {
        [outToolbarItem setLabel:NSLocalizedString(@"Wrap lines",@"")];
        [outToolbarItem setPaletteLabel:NSLocalizedString(@"Toggle Wrap lines",@"")];
        [outToolbarItem setToolTip:NSLocalizedString(@"Toggle Wrap lines",@"")];
        [self doUpdateToggleItem:outToolbarItem setOn:[[theValues valueForKey:k_key_wrapLines] boolValue]];
        [outToolbarItem setAction:@selector(toggleWrapLines:)];

    // Line Endings (target = FirstResponder)
    } else if ([inItemIdentifier isEqualToString:k_lineEndingsItemID]) {

        // （ツールバーアイテムメニューの選択項目にチェックマークが表示されない問題が起きている 2006.01.25）*****
        // （IB でのコネクション定義をやめソースコードでアクションを設定してみたが、効果なく、元に戻した。）
        // （原因／対処法、不明。2006.01.25）

        [outToolbarItem setLabel:NSLocalizedString(@"Line Endings",@"")];
        [outToolbarItem setPaletteLabel:NSLocalizedString(@"Line Endings",@"")];
        [outToolbarItem setToolTip:NSLocalizedString(@"Line Endings",@"")];
        [outToolbarItem setView:_lineEndingPopupButton];
        [outToolbarItem setMinSize:[_lineEndingPopupButton bounds].size];
        [outToolbarItem setMaxSize:[_lineEndingPopupButton bounds].size];

    // File Encoding (target = FirstResponder)
    } else if ([inItemIdentifier isEqualToString:k_fileEncodingsItemID]) {

        [outToolbarItem setLabel:NSLocalizedString(@"File Encoding",@"")];
        [outToolbarItem setPaletteLabel:NSLocalizedString(@"File Encoding",@"")];
        [outToolbarItem setToolTip:NSLocalizedString(@"File Encoding",@"")];
        [outToolbarItem setView:_encodingPopupButton];
        [outToolbarItem setMinSize:[_encodingPopupButton bounds].size];
        [outToolbarItem setMaxSize:[_encodingPopupButton bounds].size];

    // Syntax Coloring (target = FirstResponder)
    } else if ([inItemIdentifier isEqualToString:k_syntaxItemID]) {

        [outToolbarItem setLabel:NSLocalizedString(@"Syntax Coloring",@"")];
        [outToolbarItem setPaletteLabel:NSLocalizedString(@"Syntax Coloring",@"")];
        [outToolbarItem setToolTip:NSLocalizedString(@"Syntax Coloring",@"")];
        [outToolbarItem setView:_syntaxPopupButton];
        [outToolbarItem setMinSize:[_syntaxPopupButton bounds].size];
        [outToolbarItem setMaxSize:[_syntaxPopupButton bounds].size];

    // Re-color All (target = FirstResponder)
    } else if ([inItemIdentifier isEqualToString:k_syntaxReColorAllItemID]) {
        [outToolbarItem setLabel:NSLocalizedString(@"Re-color",@"")];
        [outToolbarItem setPaletteLabel:NSLocalizedString(@"Re-color All",@"")];
        [outToolbarItem setToolTip:NSLocalizedString(@"Do Re-color whole document",@"")];
        [outToolbarItem setImage:[NSImage imageNamed:@"RecolorAll"]];
        [outToolbarItem setAction:@selector(recoloringAllStringOfDocument:)];

    // Edit HexColorCode as Fore (target = FirstResponder)
    } else if ([inItemIdentifier isEqualToString:k_editHexAsForeItemID]) {
        [outToolbarItem setLabel:NSLocalizedString(@"Edit as Fore",@"")];
        [outToolbarItem setPaletteLabel:NSLocalizedString(@"Edit HexColorCode as Fore",@"")];
        [outToolbarItem setToolTip:NSLocalizedString(@"Open HexColorCode Editor to Edit as ForeColor",@"")];
        [outToolbarItem setImage:[NSImage imageNamed:@"EditHexAsFore"]];
        [outToolbarItem setAction:@selector(editHexColorCodeAsForeColor:)];

    // Edit HexColorCode as BG (target = FirstResponder)
    } else if ([inItemIdentifier isEqualToString:k_editHexAsBGItemID]) {
        [outToolbarItem setLabel:NSLocalizedString(@"Edit as BG",@"")];
        [outToolbarItem setPaletteLabel:NSLocalizedString(@"Edit HexColorCode as BG",@"")];
        [outToolbarItem setToolTip:NSLocalizedString(@"Open HexColorCode Editor to Edit as BackgroundColor",@"")];
        [outToolbarItem setImage:[NSImage imageNamed:@"EditHexAsBG"]];
        [outToolbarItem setAction:@selector(editHexColorCodeAsBGColor:)];

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
    return @[k_getInfoItemID, 
                k_showIncompatibleCharItemID, 
                k_preferencesItemID, 
                k_saveItemID, 
                k_saveAsItemID, 
                k_pageSetupItemID, 
                NSToolbarPrintItemIdentifier, 
                k_openTransparencyPanelItemID, 
                NSToolbarShowFontsItemIdentifier, 
                k_biggerFontItemID, 
                k_smallerFontItemID, 
                k_shiftLeftItemID, 
                k_shiftRightItemID, 
                k_showNavigationBarItemID, 
                k_showLineNumItemID, 
                k_showStatusBarItemID, 
                k_showInvisibleCharsItemID, 
                k_showPageGuideItemID, 
                k_wrapLinesItemID, 
                k_lineEndingsItemID, 
                k_fileEncodingsItemID, 
                k_syntaxItemID, 
                k_syntaxReColorAllItemID, 
                k_editHexAsForeItemID, 
                k_editHexAsBGItemID, 
                NSToolbarSeparatorItemIdentifier, 
                NSToolbarFlexibleSpaceItemIdentifier, 
                NSToolbarSpaceItemIdentifier, 
                NSToolbarCustomizeToolbarItemIdentifier];
}


// ------------------------------------------------------
- (NSArray *)toolbarDefaultItemIdentifiers:(NSToolbar *)inToolbar
// ツールバーアイテムデフォルト配列を返す
// ------------------------------------------------------
{
    return @[k_lineEndingsItemID, 
                k_fileEncodingsItemID, 
                k_syntaxItemID, 
                NSToolbarFlexibleSpaceItemIdentifier, 
                k_getInfoItemID];
}



@end



@implementation CEToolbarController (Private)

//=======================================================
// Private method
//
//=======================================================

// ------------------------------------------------------
- (void)doUpdateToggleItem:(NSToolbarItem *)inItem setOn:(BOOL)inBool
// トグルアイテムの状態を更新
// ------------------------------------------------------
{
    NSString *theIdentifer = [inItem itemIdentifier];
    NSString *imageName;

    if ([theIdentifer isEqualToString:k_showNavigationBarItemID]) {
        imageName = inBool ? @"NaviBar_Show" : @"NaviBar_Hide";
        
    } else if ([theIdentifer isEqualToString:k_showLineNumItemID]) {
        imageName = inBool ? @"LineNumber_Show" : @"LineNumber_Hide";
        
    } else if ([theIdentifer isEqualToString:k_showStatusBarItemID]) {
        imageName = inBool ? @"StatusArea_Show" : @"StatusArea_Hide";
        
    } else if ([theIdentifer isEqualToString:k_showInvisibleCharsItemID]) {
        imageName = inBool ? @"InvisibleChar_Show" : @"InvisibleChar_Hide";
        
    } else if ([theIdentifer isEqualToString:k_showPageGuideItemID]) {
        imageName = inBool ? @"PageGuide_Show" : @"PageGuide_Hide";
        
    } else if ([theIdentifer isEqualToString:k_wrapLinesItemID]) {
        imageName = inBool ? @"WrapLines_On" : @"WrapLines_Off";
    }
    
    if (imageName) {
        [inItem setImage:[NSImage imageNamed:imageName]];
    }
}



@end