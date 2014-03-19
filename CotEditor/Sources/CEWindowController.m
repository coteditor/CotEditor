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
#import "constants.h"


@interface CEWindowController ()

@property (nonatomic) NSUInteger tabViewSelectedIndex; // ドローワのタブビューでのポップアップメニュー選択用バインディング変数(#削除不可)

// document information (for binding)
@property (nonatomic) NSString *createdInfo;
@property (nonatomic) NSString *modificatedInfo;
@property (nonatomic) NSString *ownerInfo;
@property (nonatomic) NSString *typeInfo;
@property (nonatomic) NSString *creatorInfo;
@property (nonatomic) NSString *finderLockInfo;
@property (nonatomic) NSString *permissionInfo;

// IBOutlets
@property (nonatomic) IBOutlet NSArrayController *listController;
@property (nonatomic) IBOutlet NSObjectController *printSettingController;
@property (nonatomic) IBOutlet NSDrawer *drawer;
@property (nonatomic, weak) IBOutlet NSTabView *tabView;
@property (nonatomic, weak) IBOutlet NSPopUpButton *tabViewSelectionPopUpButton;
@property (nonatomic, weak) IBOutlet NSTableView *listTableView;
@property (nonatomic, weak) IBOutlet NSTextField *listErrorTextField;

// readonly
@property (nonatomic, weak, readwrite) IBOutlet CEEditorView *editorView;
@property (nonatomic, weak, readwrite) IBOutlet CEToolbarController *toolbarController;
@property (nonatomic, readwrite) IBOutlet NSView *printAccessoryView;

@end

@implementation CEWindowController

#pragma mark ===== Public method =====

//=======================================================
// Public method
//
//=======================================================

// ------------------------------------------------------
- (instancetype)init
// 初期化
// ------------------------------------------------------
{
    self = [super init];
    if (self) {
        [self setRecolorWithBecomeKey:NO];
    }
    return self;
}


// ------------------------------------------------------
- (void)windowDidLoad
// ウィンドウ表示の準備完了時、サイズを設定し文字列／不透明度をセット
// ------------------------------------------------------
{
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    NSSize size = NSMakeSize((CGFloat)[defaults doubleForKey:k_key_windowWidth],
                             (CGFloat)[defaults doubleForKey:k_key_windowHeight]);
    BOOL shouldCascade = [[self document] doCascadeWindow];

    [[self window] setContentSize:size];
    [self setShouldCascadeWindows:shouldCascade]; // ウィンドウのカスケード表示を制御（未変更のブランクウィンドウを上書き）
    if (!shouldCascade) {
        // カスケードしないときは、位置をずらす
        [[self window] setFrameTopLeftPoint:[[self document] initTopLeftPoint]];
    }
    // 背景をセットアップ
    [self setAlpha:(CGFloat)[[defaults valueForKey:k_key_windowAlpha] doubleValue]];
    [[self window] setBackgroundColor:[NSColor clearColor]]; // ウィンドウ背景色に透明色をセット
    [[self window] setOpaque:NO]; // ウィンドウを透明にする
    
    // ツールバーをセットアップ
    [[self toolbarController] setupToolbar];
    
    // ドキュメントオブジェクトに CEEditorView インスタンスをセット
    [[self document] setEditorView:[self editorView]];
    // デフォルト行末コードをセット
    [[self document] setLineEndingCharToView:[defaults integerForKey:k_key_defaultLineEndCharCode]];
    // 不可視文字の表示／非表示をセット
    [[self editorView] setShowInvisibleChars:[[self document] canActivateShowInvisibleCharsItem]];
    // プリントダイアログでの設定をセットアップ（ユーザデフォルトからローカル設定にコピー）
    [self setupPrintValues];
    // テキストを表示
    [[self document] setStringToEditorView];
}

// ------------------------------------------------------
- (BOOL)needsInfoDrawerUpdate
// 文書情報ドローワ内容を更新すべきかを返す
// ------------------------------------------------------
{
    NSInteger drawerState = [[self drawer] state];
    BOOL tabState = [[[[self tabView] selectedTabViewItem] identifier] isEqualToString:k_infoIdentifier];

    return (tabState && ((drawerState == NSDrawerOpenState) || (drawerState == NSDrawerOpeningState)));
}


// ------------------------------------------------------
- (BOOL)needsIncompatibleCharDrawerUpdate
// 非互換文字ドローワ内容を更新すべきかを返す
// ------------------------------------------------------
{
    NSInteger drawerState = [[self drawer] state];
    BOOL tabState = [[[[self tabView] selectedTabViewItem] identifier] isEqualToString:k_incompatibleIdentifier];

    return (tabState && ((drawerState == NSDrawerOpenState) || (drawerState == NSDrawerOpeningState)));
}


// ------------------------------------------------------
- (void)updateFileAttrsInformation
// すべての文書情報を更新
// ------------------------------------------------------
{
    NSDictionary *fileAttributes = [[self document] fileAttributes];

    [self setCreatorInfo:NSFileTypeForHFSTypeCode([fileAttributes fileHFSCreatorCode])];
    [self setTypeInfo:NSFileTypeForHFSTypeCode([fileAttributes fileHFSTypeCode])];
    [self setCreatedInfo:[[fileAttributes fileCreationDate] description]];
    [self setModificatedInfo:[[fileAttributes fileModificationDate] description]];
    [self setOwnerInfo:[fileAttributes fileOwnerAccountName]];
    
    NSString *finderLockInfo = [fileAttributes fileIsImmutable] ? NSLocalizedString(@"ON",@"") : nil;
    [self setFinderLockInfo:finderLockInfo];
    [self setPermissionInfo:[NSString stringWithFormat:@"%lu", (unsigned long)[fileAttributes filePosixPermissions]]];
}


// ------------------------------------------------------
- (void)updateIncompatibleCharList
// 変換不可文字列リストを更新
// ------------------------------------------------------
{
    NSArray *contents = [[self document] markupCharCanNotBeConvertedToCurrentEncoding];

    [[self listErrorTextField] setHidden:(contents != nil)]; // リストが取得できなかった時のメッセージを表示

    [[self listController] setContent:contents];
}


// ------------------------------------------------------
- (void)showIncompatibleCharList
// 非互換文字リストを表示
// ------------------------------------------------------
{
    [self updateIncompatibleCharList];
    [[self tabView] selectTabViewItemWithIdentifier:k_incompatibleIdentifier];
    [[self drawer] open];
}


// ------------------------------------------------------
- (CGFloat)alpha
// テキストビューの不透明度を返す
// ------------------------------------------------------
{
    return [[[[self editorView] textView] backgroundColor] alphaComponent];
}

// ------------------------------------------------------
- (void)setAlpha:(CGFloat)alpha
// テキストビューの不透明度を変更する
// ------------------------------------------------------
{
    CGFloat sanitizedAlpha = alpha;
    
    sanitizedAlpha = MAX(sanitizedAlpha, 0.2);
    sanitizedAlpha = MIN(sanitizedAlpha, 1.0);
    
    [[[self editorView] splitView] setAllBackgroundColorWithAlpha:sanitizedAlpha];
}


// ------------------------------------------------------
- (void)setupPrintValues
// プリントダイアログでの設定をセットアップ（ユーザデフォルトからローカル設定にコピー）
// ------------------------------------------------------
{
    id defaults = [[NSUserDefaultsController sharedUserDefaultsController] values];
    // （プリンタ専用フォント設定は含まない。プリンタ専用フォント設定変更は、プリンタダイアログでは実装しない 20060927）
    NSDictionary *settings = [defaults dictionaryWithValuesForKeys:@[k_printHeader,
                                                                     k_headerOneStringIndex,
                                                                     k_headerTwoStringIndex,
                                                                     k_headerOneAlignIndex,
                                                                     k_headerTwoAlignIndex,
                                                                     k_printHeaderSeparator,
                                                                     k_printFooter,
                                                                     k_footerOneStringIndex,
                                                                     k_footerTwoStringIndex,
                                                                     k_footerOneAlignIndex,
                                                                     k_footerTwoAlignIndex,
                                                                     k_printFooterSeparator,
                                                                     k_printLineNumIndex,
                                                                     k_printInvisibleCharIndex,
                                                                     k_printColorIndex]];

    [[self printSettingController] setContent:[settings mutableCopy]];
}


// ------------------------------------------------------
- (id)printValues
// プリンタローカル設定オブジェクトを返す
// ------------------------------------------------------
{
    return [[self printSettingController] content];
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
    [[self listTableView] setTarget:self];
    [[self listTableView] setAction:@selector(selectIncompatibleRange:)];
}


//=======================================================
// OgreKit Protocol
//
//=======================================================

// ------------------------------------------------------
- (void)tellMeTargetToFindIn:(id)textFinder
// *OgreKit method. to pass the main textView.
// ------------------------------------------------------
{
    [textFinder setTargetToFindIn:[[self editorView] textView]];
}



#pragma mark === Delegate and Notification ===

//=======================================================
// Delegate method (NSWindow)
//  <== mainWindow
//=======================================================

// ------------------------------------------------------
- (void)windowDidBecomeKey:(NSNotification *)notification
// ウィンドウがキーになった
// ------------------------------------------------------
{
    // 不可視文字表示メニューのツールチップを更新
    [[self editorView] updateShowInvisibleCharsMenuToolTip];
    

    // シートを表示していなければ、各種更新実行
    if ([[self window] attachedSheet] == nil) {
        // 情報の更新
        [[self document] getFileAttributes];
        // フラグがたっていたら、改めてスタイル名を指定し直して再カラーリングを実行
        if ([self recolorWithBecomeKey]) {
            [self setRecolorWithBecomeKey:NO];
            [[self document] doSetSyntaxStyle:[[self editorView] syntaxStyleNameToColoring]];
        }
    }
}


// ------------------------------------------------------
- (void)windowWillClose:(NSNotification *)notification
// ウィンドウが閉じる直前
// ------------------------------------------------------
{
    // デリゲートをやめる
    [[self drawer] setDelegate:nil];
    [[self tabView] setDelegate:nil];

    // バインディング停止
    //（自身の変数 tabViewSelectedIndex を使わせている関係で、放置しておくと自身が retain されたままになる）
    [[self tabViewSelectionPopUpButton] unbind:@"selectedIndex"];
    [[self tabView] unbind:@"selectedIndex"];
}


// ------------------------------------------------------
- (void)tabView:(NSTabView *)tabView willSelectTabViewItem:(NSTabViewItem *)tabViewItem
// ドローワのタブが切り替えられる直前に内容の更新を行う
// ------------------------------------------------------
{
    if ([[tabViewItem identifier] isEqualToString:k_infoIdentifier]) {
        [self updateFileAttrsInformation];
        [[self editorView] updateDocumentInfoStringWithDrawerForceUpdate:YES];
        [[self editorView] updateLineEndingsInStatusAndInfo:YES];
    } else if ([[tabViewItem identifier] isEqualToString:k_incompatibleIdentifier]) {
        [self updateIncompatibleCharList];
    }
}


// ------------------------------------------------------
- (void)drawerDidClose:(NSNotification *)notification
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
    [[self window] setBackgroundColor:[NSColor clearColor]];
}



#pragma mark Action Messages

//=======================================================
// Action messages
//
//=======================================================

// ------------------------------------------------------
- (IBAction)getInfo:(id)sender
// ファイル情報を表示
// ------------------------------------------------------
{
    NSInteger drawerState = [[self drawer] state];
    BOOL tabState = [[[[self tabView] selectedTabViewItem] identifier] isEqualToString:k_infoIdentifier];

    if ((drawerState == NSDrawerClosedState) || (drawerState == NSDrawerClosingState)) {
        if (tabState) {
            // 情報の更新
            [self updateFileAttrsInformation];
            [[self editorView] updateDocumentInfoStringWithDrawerForceUpdate:YES];
            [[self editorView] updateLineEndingsInStatusAndInfo:YES];
        } else {
            [[self tabView] selectTabViewItemWithIdentifier:k_infoIdentifier];
        }
        [[self drawer] open];
    } else {
        if (tabState) {
            [[self drawer] close];
        } else {
            [[self tabView] selectTabViewItemWithIdentifier:k_infoIdentifier];
        }
    }
}


// ------------------------------------------------------
- (IBAction)toggleIncompatibleCharList:(id)sender
// 変換不可文字列リストパネルを開く
// ------------------------------------------------------
{
    NSInteger drawerState = [[self drawer] state];
    BOOL tabState = [[[[self tabView] selectedTabViewItem] identifier] isEqualToString:k_incompatibleIdentifier];

    if ((drawerState == NSDrawerClosedState) || (drawerState == NSDrawerClosingState)) {
        if (tabState) {
            [self updateIncompatibleCharList];
        } else {
            [[self tabView] selectTabViewItemWithIdentifier:k_incompatibleIdentifier];
        }
        [[self drawer] open];
    } else {
        if (tabState) {
            [[self drawer] close];
        } else {
            [[self tabView] selectTabViewItemWithIdentifier:k_incompatibleIdentifier];
        }
    }
}


// ------------------------------------------------------
- (IBAction)selectIncompatibleRange:(id)sender
// 文字列を選択
// ------------------------------------------------------
{
    NSRange range = [[[[self listController] selectedObjects][0] valueForKey:k_incompatibleRange] rangeValue];

    [[self editorView] setSelectedRange:range];
    [[self window] makeFirstResponder:[[self editorView] textView]];
    [[[self editorView] textView] scrollRangeToVisible:range];

    // 検索結果表示エフェクトを追加
    [[[self editorView] textView] showFindIndicatorForRange:range];
}

@end
