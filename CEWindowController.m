/*
=================================================
CEWindowController
(for CotEditor)

 Copyright (C) 2004-2007 nakamuxu.
 Copyright (C) 2014 CotEditor Project
 http://coteditor.github.io
=================================================

encoding="UTF-8"
Created:2004.12.13

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

#import "CEWindowController.h"
#import "CEDocumentController.h"

@implementation CEWindowController

#pragma mark ===== Public method =====

//=======================================================
// Public method
//
//=======================================================

// ------------------------------------------------------
- (id)init
// 初期化
// ------------------------------------------------------
{
    self = [super init];
    if (self) {
        _recolorWithBecomeKey = NO;
    }
    return self;
}


// ------------------------------------------------------
- (void)windowDidLoad
// ウィンドウ表示の準備完了時、サイズを設定し文字列／透明度をセット
// ------------------------------------------------------
{
    id theValues = [[NSUserDefaultsController sharedUserDefaultsController] values];
    NSSize theSize = NSMakeSize((CGFloat)[[theValues valueForKey:k_key_windowWidth] doubleValue],
                                (CGFloat)[[theValues valueForKey:k_key_windowHeight] doubleValue]);
    BOOL theBoolDoCascade = [[self document] doCascadeWindow];

    [[self window] setContentSize:theSize];
    [self setShouldCascadeWindows:theBoolDoCascade]; // ウィンドウのカスケード表示を制御（未変更のブランクウィンドウを上書き）
    if (!theBoolDoCascade) {
        // カスケードしないときは、位置をずらす
        [[self window] setFrameTopLeftPoint:[[self document] initTopLeftPoint]];
    }
    [[self document] setAlphaOnlyTextViewInThisWindow:
            [[theValues valueForKey:k_key_alphaOnlyTextView] boolValue]];
    [[self document] setAlphaToWindowAndTextViewDefaultValue];
    [[CEDocumentController sharedDocumentController] setTransparencyPanelControlsEnabledWithDecrement:NO];
    [[CEDocumentController sharedDocumentController] setGotoPanelControlsEnabledWithDecrement:NO];
    // ツールバーをセットアップ
    [_toolbarController setupToolbar];
    // ドキュメントオブジェクトに CEEditorView インスタンスをセット
    [[self document] setEditorView:_editorView];
    // デフォルト行末コードをセット
    [[self document] setLineEndingCharToView:[[theValues valueForKey:k_key_defaultLineEndCharCode] integerValue]];
    // 不可視文字の表示／非表示をセット
    [_editorView setShowInvisibleChars:[[self document] canActivateShowInvisibleCharsItem]];
    // プリントダイアログでの設定をセットアップ（ユーザデフォルトからローカル設定にコピー）
    [self setupPrintValues];
    // テキストを表示
    [[self document] setStringToEditorView];
}


// ------------------------------------------------------
- (void)setDocumentEdited:(BOOL)inFlag
// ダーティーフラグを立てる
// ------------------------------------------------------
{
    [super setDocumentEdited:inFlag];

    // UndoManager 関連で問題があるための対応措置（Mac OS 10.4.8で検証）。
    // 1. 編集したドキュメントを保存する
    // 2. アンドゥ
    // 3. キー入力またはペーストすると、ダーティーフラグが消えてしまう。
    // その後も、同一行に入力中はダーティーフラグが立たない。アンドゥすると保存直後にアンドゥした状態までは戻るが、
    // 保存の状態までは戻れない。TextEdit、Xcode 2.4 でも同じ問題が発生する。(2006.09.30)

    // 上記の問題への対処として、「3.」で消えたダーティーフラグを直後に復活させている。保存状態までは戻れない問題は
    // 残っていて根本的な解決ではないが、ダーティーフラグがないためにユーザが保存状態を勘違いしてドキュメントを
    // 閉じてしまうよりは、マシかと。(2006.09.30)

    if (!inFlag) {
        CEDocument *theDoc = [self document];

        if (([[theDoc undoManager] groupingLevel] > 0) && ([[theDoc undoManager] canUndo]) && 
            (![[theDoc undoManager] isRedoing]) && (![[theDoc undoManager] isUndoing])) {
            [theDoc updateChangeCount:NSChangeDone];
            [theDoc updateChangeCount:NSChangeDone];
        }
    }
}


// ------------------------------------------------------
- (id)toolbarController
// ツールバーコントローラを返す
// ------------------------------------------------------
{
    return _toolbarController;
}


// ------------------------------------------------------
- (BOOL)needsInfoDrawerUpdate
// 文書情報ドローワ内容を更新すべきかを返す
// ------------------------------------------------------
{
    NSInteger theDrawerState = [_drawer state];
    BOOL theTabState = [[[_tabView selectedTabViewItem] identifier] isEqualToString:k_infoIdentifier];

    return (theTabState && 
            ((theDrawerState == NSDrawerOpenState) || (theDrawerState == NSDrawerOpeningState)));
}


// ------------------------------------------------------
- (BOOL)needsIncompatibleCharDrawerUpdate
// 非互換文字ドローワ内容を更新すべきかを返す
// ------------------------------------------------------
{
    NSInteger theDrawerState = [_drawer state];
    BOOL theTabState = [[[_tabView selectedTabViewItem] identifier] isEqualToString:k_incompatibleIdentifier];

    return (theTabState && 
            ((theDrawerState == NSDrawerOpenState) || (theDrawerState == NSDrawerOpeningState)));
}


// ------------------------------------------------------
- (void)setInfoEncoding:(NSString *)inString
// 文書のエンコーディング情報を設定
// ------------------------------------------------------
{
    [_infoEncodingField setStringValue:inString];
}


// ------------------------------------------------------
- (void)setInfoLineEndings:(NSString *)inString
// 文書の行末コード情報を設定
// ------------------------------------------------------
{
    [_infoLineEndingsField setStringValue:inString];
}


// ------------------------------------------------------
- (void)setInfoLine:(NSString *)inString
// 文書の行情報を設定
// ------------------------------------------------------
{
    [_infoLinesField setStringValue:inString];
}


// ------------------------------------------------------
- (void)setInfoChar:(NSString *)inString
// 文書の文字情報を設定
// ------------------------------------------------------
{
    [_infoCharsField setStringValue:inString];
}


// ------------------------------------------------------
- (void)setInfoSelect:(NSString *)inString
// 文書の選択範囲情報を設定
// ------------------------------------------------------
{
    [_infoSelectField setStringValue:inString];
}


// ------------------------------------------------------
- (void)setInfoInLine:(NSString *)inString
// 文書の行頭からのキャレット位置をセット
// ------------------------------------------------------
{
    [_infoInLineField setStringValue:inString];
}


// ------------------------------------------------------
- (void)setInfoSingleChar:(NSString *)inString
// 文書の選択範囲情報を設定
// ------------------------------------------------------
{
    [_infoSingleCharField setStringValue:inString];
}


// ------------------------------------------------------
- (void)updateFileAttrsInformation
// すべての文書情報を更新
// ------------------------------------------------------
{
    NSDictionary *theFileAttr = [[self document] fileAttributes];
    NSDate *theDate = nil;
    NSString *theOwner = nil;

    [_infoCreatorField setStringValue:NSFileTypeForHFSTypeCode([theFileAttr fileHFSCreatorCode])];
    [_infoTypeField setStringValue:NSFileTypeForHFSTypeCode([theFileAttr fileHFSTypeCode])];
    theDate = [theFileAttr fileCreationDate];
    if (theDate) {
        [_infoCreatedField setStringValue:[theDate description]];
    } else {
        [_infoCreatedField setStringValue:@" - "];
    }
    theDate = [theFileAttr fileModificationDate];
    if (theDate) {
        [_infoModifiedField setStringValue:[theDate description]];
    } else {
        [_infoModifiedField setStringValue:@" - "];
    }
    theOwner = [theFileAttr fileOwnerAccountName];
    if (theOwner) {
        [_infoOwnerField setStringValue:theOwner];
    } else {
        [_infoOwnerField setStringValue:@" - "];
    }
    [_infoPermissionField setStringValue:[NSString stringWithFormat:@"%lu",(unsigned long)[theFileAttr filePosixPermissions]]];
    if ([theFileAttr fileIsImmutable]) {
        [_infoFinderLockField setStringValue:NSLocalizedString(@"ON",@"")];
    } else {
        [_infoFinderLockField setStringValue:@"-"];
    }
}


// ------------------------------------------------------
- (void)updateIncompatibleCharList
// 変換不可文字列リストを更新
// ------------------------------------------------------
{
    NSArray *theContentArray = [[self document] markupCharCanNotBeConvertedToCurrentEncoding];

    [_listErrorTextField setHidden:(theContentArray != nil)]; // リストが取得できなかった時のメッセージを表示

    [_listController setContent:theContentArray];
}


// ------------------------------------------------------
- (void)setRecolorWithBecomeKey:(BOOL)inValue
// ウィンドウがキーになったとき再カラーリングをするかどうかのフラグをセット
// ------------------------------------------------------
{
    _recolorWithBecomeKey = inValue;
}


// ------------------------------------------------------
- (void)showIncompatibleCharList
// 非互換文字リストを表示
// ------------------------------------------------------
{
    [self updateIncompatibleCharList];
    [_tabView selectTabViewItemWithIdentifier:k_incompatibleIdentifier];
    [_drawer open];
}


// ------------------------------------------------------
- (void)setupPrintValues
// プリントダイアログでの設定をセットアップ（ユーザデフォルトからローカル設定にコピー）
// ------------------------------------------------------
{
    id theValues = [[NSUserDefaultsController sharedUserDefaultsController] values];
    // （プリンタ専用フォント設定は含まない。プリンタ専用フォント設定変更は、プリンタダイアログでは実装しない 20060927）
    NSMutableDictionary *theDict = [NSMutableDictionary dictionaryWithObjectsAndKeys:
                                    [theValues valueForKey:k_printHeader], k_printHeader, 
                                    [theValues valueForKey:k_headerOneStringIndex], k_headerOneStringIndex, 
                                    [theValues valueForKey:k_headerTwoStringIndex], k_headerTwoStringIndex, 
                                    [theValues valueForKey:k_headerOneAlignIndex], k_headerOneAlignIndex, 
                                    [theValues valueForKey:k_headerTwoAlignIndex], k_headerTwoAlignIndex, 
                                    [theValues valueForKey:k_printHeaderSeparator], k_printHeaderSeparator, 
                                    [theValues valueForKey:k_printFooter], k_printFooter, 
                                    [theValues valueForKey:k_footerOneStringIndex], k_footerOneStringIndex, 
                                    [theValues valueForKey:k_footerTwoStringIndex], k_footerTwoStringIndex, 
                                    [theValues valueForKey:k_footerOneAlignIndex], k_footerOneAlignIndex, 
                                    [theValues valueForKey:k_footerTwoAlignIndex], k_footerTwoAlignIndex, 
                                    [theValues valueForKey:k_printFooterSeparator], k_printFooterSeparator, 
                                    [theValues valueForKey:k_printLineNumIndex], k_printLineNumIndex, 
                                    [theValues valueForKey:k_printInvisibleCharIndex], k_printInvisibleCharIndex, 
                                    [theValues valueForKey:k_printColorIndex], k_printColorIndex, 
                                    nil];

    [_printSettingController setContent:theDict];
}


// ------------------------------------------------------
- (id)printValues
// プリンタローカル設定オブジェクトを返す
// ------------------------------------------------------
{
    return [_printSettingController content];
}


// ------------------------------------------------------
- (NSView *)printAccessoryView
// プリントアクセサリビューを返す
// ------------------------------------------------------
{
    return _printAccessoryView;
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
    // クリック時に当該文字列を選択するように設定
    [_listTableView setTarget:self];
    [_listTableView setAction:@selector(selectIncompatibleRange:)];
}


//=======================================================
// OgreKit Protocol
//
//=======================================================

// ------------------------------------------------------
- (void)tellMeTargetToFindIn:(id)inTextFinder
// *OgreKit method. to pass the main textView.
// ------------------------------------------------------
{
    [inTextFinder setTargetToFindIn:[_editorView textView]];
}



#pragma mark === Delegate and Notification ===

//=======================================================
// Delegate method (NSWindow)
//  <== mainWindow
//=======================================================

// ------------------------------------------------------
- (void)windowDidBecomeKey:(NSNotification *)inNotification
// ウィンドウがキーになった
// ------------------------------------------------------
{
    CEEditorView *theEditorView = [[self document] editorView];

    // 不可視文字表示メニューのツールチップを更新
    [theEditorView updateShowInvisibleCharsMenuToolTip];
    // アルファ値を反映
    [[self document] setAlphaValueToTransparencyController];

    // シートを表示していなければ、各種更新実行
    if ([[self window] attachedSheet] == nil) {
        // 情報の更新
        [[self document] getFileAttributes];
        // フラグがたっていたら、改めてスタイル名を指定し直して再カラーリングを実行
        if (_recolorWithBecomeKey) {
            [self setRecolorWithBecomeKey:NO];
            [[self document] doSetSyntaxStyle:[_editorView syntaxStyleNameToColoring]];
        }
    }
}


// ------------------------------------------------------
- (void)windowWillClose:(NSNotification *)inNotification
// ウィンドウが閉じる直前
// ------------------------------------------------------
{
    // デリゲートをやめる
    [_drawer setDelegate:nil];
    [_tabView setDelegate:nil];

    // バインディング停止
    //（自身の変数 _tabViewSelectedIndex を使わせている関係で、放置しておくと自身が retain されたままになる）
    [_tabViewSelectionPopUpButton unbind:@"selectedIndex"];
    [_tabView unbind:@"selectedIndex"];

    // パネル類の片づけ
    [[CEDocumentController sharedDocumentController] setTransparencyPanelControlsEnabledWithDecrement:YES];
    [[CEDocumentController sharedDocumentController] setGotoPanelControlsEnabledWithDecrement:YES];
}


// ------------------------------------------------------
- (void)tabView:(NSTabView *)inTabView willSelectTabViewItem:(NSTabViewItem *)inTabViewItem
// ドローワのタブが切り替えられる直前に内容の更新を行う
// ------------------------------------------------------
{
    if ([[inTabViewItem identifier] isEqualToString:k_infoIdentifier]) {
        [self updateFileAttrsInformation];
        [_editorView updateDocumentInfoStringWithDrawerForceUpdate:YES];
        [_editorView updateLineEndingsInStatusAndInfo:YES];
    } else if ([[inTabViewItem identifier] isEqualToString:k_incompatibleIdentifier]) {
        [self updateIncompatibleCharList];
    }
}


// ------------------------------------------------------
- (void)drawerDidClose:(NSNotification *)inNotification
// ドローワが閉じたらテキストビューのマークアップをクリア
// ------------------------------------------------------
{
    [[self document] clearAllMarkupForIncompatibleChar];
    // テキストビューの表示だけをクリアし、リストはそのまま
}


// ------------------------------------------------------
- (void)windowWillEnterFullScreen:(NSNotification *)notification
// フルスクリーンを開始
// ------------------------------------------------------
{
    // ウインドウ背景をデフォルトにする（ツールバーの背景に影響）
    [[self window] setBackgroundColor:nil];
}


// ------------------------------------------------------
- (void)windowDidExitFullScreen:(NSNotification *)notification
// フルスクリーンを終了
// ------------------------------------------------------
{
    // ウインドウ背景を戻す
    if ([[self document] alphaOnlyTextViewInThisWindow]) {
        [[self window] setBackgroundColor:[NSColor clearColor]];
    }
}



#pragma mark ===== Action messages =====

//=======================================================
// Action messages
//
//=======================================================

// ------------------------------------------------------
- (IBAction)getInfo:(id)sender
// ファイル情報を表示
// ------------------------------------------------------
{
    NSInteger theDrawerState = [_drawer state];
    BOOL theTabState = [[[_tabView selectedTabViewItem] identifier] isEqualToString:k_infoIdentifier];

    if ((theDrawerState == NSDrawerClosedState) || (theDrawerState == NSDrawerClosingState)) {
        if (theTabState) {
            // 情報の更新
            [self updateFileAttrsInformation];
            [_editorView updateDocumentInfoStringWithDrawerForceUpdate:YES];
            [_editorView updateLineEndingsInStatusAndInfo:YES];
        } else {
            [_tabView selectTabViewItemWithIdentifier:k_infoIdentifier];
        }
        [_drawer open];
    } else {
        if (theTabState) {
            [_drawer close];
        } else {
            [_tabView selectTabViewItemWithIdentifier:k_infoIdentifier];
        }
    }
}


// ------------------------------------------------------
- (IBAction)toggleIncompatibleCharList:(id)sender
// 変換不可文字列リストパネルを開く
// ------------------------------------------------------
{
    NSInteger theDrawerState = [_drawer state];
    BOOL theTabState = [[[_tabView selectedTabViewItem] identifier] isEqualToString:k_incompatibleIdentifier];

    if ((theDrawerState == NSDrawerClosedState) || (theDrawerState == NSDrawerClosingState)) {
        if (theTabState) {
            [self updateIncompatibleCharList];
        } else {
            [_tabView selectTabViewItemWithIdentifier:k_incompatibleIdentifier];
        }
        [_drawer open];
    } else {
        if (theTabState) {
            [_drawer close];
        } else {
            [_tabView selectTabViewItemWithIdentifier:k_incompatibleIdentifier];
        }
    }
}


// ------------------------------------------------------
- (IBAction)selectIncompatibleRange:(id)sender
// 文字列を選択
// ------------------------------------------------------
{
    CEEditorView *theEditorView = [[self document] editorView];
    NSRange theRange = [[[_listController selectedObjects][0] 
                valueForKey:k_incompatibleRange] rangeValue];

    [theEditorView setSelectedRange:theRange];
    [[self window] makeFirstResponder:[theEditorView textView]];
    [[theEditorView textView] scrollRangeToVisible:theRange];

    // 検索結果表示エフェクトを追加
    [[theEditorView textView] showFindIndicatorForRange:theRange];
}



@end
