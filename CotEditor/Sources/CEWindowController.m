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
@property (nonatomic, copy) NSString *createdInfo;
@property (nonatomic, copy) NSString *modificatedInfo;
@property (nonatomic, copy) NSString *ownerInfo;
@property (nonatomic, copy) NSString *typeInfo;
@property (nonatomic, copy) NSString *creatorInfo;
@property (nonatomic, copy) NSString *finderLockInfo;
@property (nonatomic, copy) NSString *permissionInfo;
@property (nonatomic) NSNumber *fileSizeInfo;

// IBOutlets
@property (nonatomic) IBOutlet NSArrayController *listController;
@property (nonatomic) IBOutlet NSDrawer *drawer;
@property (nonatomic, weak) IBOutlet NSTabView *tabView;
@property (nonatomic, weak) IBOutlet NSPopUpButton *tabViewSelectionPopUpButton;
@property (nonatomic, weak) IBOutlet NSTableView *listTableView;
@property (nonatomic, weak) IBOutlet NSTextField *listErrorTextField;

// readonly
@property (nonatomic, weak, readwrite) IBOutlet CEToolbarController *toolbarController;
@property (nonatomic, weak, readwrite) IBOutlet CEEditorView *editorView;

@end




#pragma mark -

@implementation CEWindowController

#pragma mark NSWindowController Methods

//=======================================================
// NSWindowController method
//
//=======================================================

// ------------------------------------------------------
/// ウィンドウ表示の準備完了時、サイズを設定し文字列／不透明度をセット
- (void)windowDidLoad
// ------------------------------------------------------
{
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    
    NSSize size = NSMakeSize((CGFloat)[defaults doubleForKey:k_key_windowWidth],
                             (CGFloat)[defaults doubleForKey:k_key_windowHeight]);
    [[self window] setContentSize:size];
    
    // 背景をセットアップ
    [self setAlpha:(CGFloat)[defaults doubleForKey:k_key_windowAlpha]];
    [[self window] setBackgroundColor:[NSColor clearColor]]; // ウィンドウ背景色に透明色をセット
    
    // ドキュメントオブジェクトに CEEditorView インスタンスをセット
    [[self document] setEditorView:[self editorView]];
    // デフォルト改行コードをセット
    [[self document] setLineEndingCharToView:[defaults integerForKey:k_key_defaultLineEndCharCode]];
    // テキストを表示
    [[self document] setStringToEditorView];
    
    // シンタックス定義の変更を監視
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(syntaxDidUpdate:)
                                                 name:CESyntaxDidUpdateNotification
                                               object:nil];
}


// ------------------------------------------------------
/// あとかたづけ
- (void)dealloc
// ------------------------------------------------------
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}



#pragma mark Public Methods

//=======================================================
// Public method
//
//=======================================================

// ------------------------------------------------------
/// 文書情報ドローワ内容を更新すべきかを返す
- (BOOL)needsInfoDrawerUpdate
// ------------------------------------------------------
{
    NSInteger drawerState = [[self drawer] state];
    BOOL tabState = [[[[self tabView] selectedTabViewItem] identifier] isEqualToString:k_infoIdentifier];

    return (tabState && ((drawerState == NSDrawerOpenState) || (drawerState == NSDrawerOpeningState)));
}


// ------------------------------------------------------
/// 非互換文字ドローワ内容を更新すべきかを返す
- (BOOL)needsIncompatibleCharDrawerUpdate
// ------------------------------------------------------
{
    NSInteger drawerState = [[self drawer] state];
    BOOL tabState = [[[[self tabView] selectedTabViewItem] identifier] isEqualToString:k_incompatibleIdentifier];

    return (tabState && ((drawerState == NSDrawerOpenState) || (drawerState == NSDrawerOpeningState)));
}


// ------------------------------------------------------
/// すべての文書情報を更新
- (void)updateFileAttrsInformation
// ------------------------------------------------------
{
    NSDictionary *fileAttributes = [[self document] fileAttributes];

    [self setCreatorInfo:NSFileTypeForHFSTypeCode([fileAttributes fileHFSCreatorCode])];
    [self setTypeInfo:NSFileTypeForHFSTypeCode([fileAttributes fileHFSTypeCode])];
    [self setCreatedInfo:[[fileAttributes fileCreationDate] description]];
    [self setModificatedInfo:[[fileAttributes fileModificationDate] description]];
    [self setOwnerInfo:[fileAttributes fileOwnerAccountName]];
    
    NSString *finderLockInfo = [fileAttributes fileIsImmutable] ? NSLocalizedString(@"ON", nil) : nil;
    [self setFinderLockInfo:finderLockInfo];
    [self setPermissionInfo:[NSString stringWithFormat:@"%tu", [fileAttributes filePosixPermissions]]];
    NSNumber *beforeFileSize = [self fileSizeInfo];
    [self setFileSizeInfo:@([fileAttributes fileSize])];
    if (![beforeFileSize isEqualToNumber:[self fileSizeInfo]]) {
        [[self editorView] updateLineEndingsInStatusAndInfo:false];
    }
}


// ------------------------------------------------------
/// 変換不可文字列リストを更新
- (void)updateIncompatibleCharList
// ------------------------------------------------------
{
    NSArray *contents = [[self document] findCharsIncompatibleWithEncoding:[[self document] encoding]];
    
    [self markupIncompatibleChars:contents];

    [[self listErrorTextField] setHidden:([contents count] > 0)]; // リストが取得できなかった時のメッセージを表示
    [[self listController] setContent:contents];
}


// ------------------------------------------------------
/// 非互換文字リストを表示
- (void)showIncompatibleCharList
// ------------------------------------------------------
{
    [self updateIncompatibleCharList];
    [[self tabView] selectTabViewItemWithIdentifier:k_incompatibleIdentifier];
    [[self drawer] open];
}


// ------------------------------------------------------
/// テキストビューの不透明度を返す
- (CGFloat)alpha
// ------------------------------------------------------
{
    return [[[[self editorView] textView] backgroundColor] alphaComponent];
}

// ------------------------------------------------------
/// テキストビューの不透明度を変更する
- (void)setAlpha:(CGFloat)alpha
// ------------------------------------------------------
{
    CGFloat sanitizedAlpha = alpha;
    
    sanitizedAlpha = MAX(sanitizedAlpha, 0.2);
    sanitizedAlpha = MIN(sanitizedAlpha, 1.0);
    
    [[[self editorView] splitView] setAllBackgroundColorWithAlpha:sanitizedAlpha];
    [[self window] setOpaque:(sanitizedAlpha == 1.0)];
}



#pragma mark Protocol

//=======================================================
// NSNibAwaking Protocol
//
//=======================================================

// ------------------------------------------------------
/// Nibファイル読み込み直後
- (void)awakeFromNib
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
/// *OgreKit method. to pass the main textView.
- (void)tellMeTargetToFindIn:(id)textFinder
// ------------------------------------------------------
{
    [textFinder setTargetToFindIn:[[self editorView] textView]];
}



#pragma mark Delegate and Notification

//=======================================================
// Delegate method (NSWindow)
//  <== mainWindow
//=======================================================

// ------------------------------------------------------
/// ウィンドウがキーになった
- (void)windowDidBecomeKey:(NSNotification *)notification
// ------------------------------------------------------
{
    // シートを表示していなければ、各種更新実行
    if ([[self window] attachedSheet] == nil) {
        // フラグがたっていたら、改めてスタイル名を指定し直して再カラーリングを実行
        if ([self recolorWithBecomeKey]) {
            [self setRecolorWithBecomeKey:NO];
            [[self document] doSetSyntaxStyle:[[self editorView] syntaxStyleNameToColoring]];
        }
    }
}


// ------------------------------------------------------
/// ウィンドウが閉じる直前
- (void)windowWillClose:(NSNotification *)notification
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
/// フルスクリーンを開始
- (void)windowWillEnterFullScreen:(NSNotification *)notification
// ------------------------------------------------------
{
    // ウインドウ背景をデフォルトにする（ツールバーの背景に影響）
    [[self window] setBackgroundColor:nil];
}


// ------------------------------------------------------
/// フルスクリーンを終了
- (void)windowDidExitFullScreen:(NSNotification *)notification
// ------------------------------------------------------
{
    // ウインドウ背景を戻す
    [[self window] setBackgroundColor:[NSColor clearColor]];
}


//=======================================================
// Delegate method (NSTabView)
//  <== tabView
//=======================================================

// ------------------------------------------------------
/// ドローワのタブが切り替えられる直前に内容の更新を行う
- (void)tabView:(NSTabView *)tabView willSelectTabViewItem:(NSTabViewItem *)tabViewItem
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


//=======================================================
// Delegate method (NSDrawer)
//  <== drawer
//=======================================================

// ------------------------------------------------------
/// ドローワが閉じたらテキストビューのマークアップをクリア
- (void)drawerDidClose:(NSNotification *)notification
// ------------------------------------------------------
{
    [self clearAllMarkup];
    // テキストビューの表示だけをクリアし、リストはそのまま
}



#pragma mark Action Messages

//=======================================================
// Action messages
//
//=======================================================

// ------------------------------------------------------
/// ファイル情報を表示
- (IBAction)getInfo:(id)sender
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
/// 変換不可文字列リストパネルを開く
- (IBAction)toggleIncompatibleCharList:(id)sender
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
/// 文字列を選択
- (IBAction)selectIncompatibleRange:(id)sender
// ------------------------------------------------------
{
    NSRange range = [[[self listController] selectedObjects][0][k_incompatibleRange] rangeValue];

    [[self editorView] setSelectedRange:range];
    [[self window] makeFirstResponder:[[self editorView] textView]];
    [[[self editorView] textView] scrollRangeToVisible:range];

    // 検索結果表示エフェクトを追加
    [[[self editorView] textView] showFindIndicatorForRange:range];
}



#pragma mark Private Methods

//=======================================================
// Private method
//
//=======================================================

// ------------------------------------------------------
/// 指定されたスタイルを適用していたら、リカラーフラグを立てる
- (void)syntaxDidUpdate:(NSNotification *)notification
// ------------------------------------------------------
{
    NSString *currentName = [[self editorView] syntaxStyleNameToColoring];
    NSString *oldName = [notification userInfo][CEOldNameKey];
    NSString *newName = [notification userInfo][CENewNameKey];
    
    if ([oldName isEqualToString:currentName]) {
        if (![oldName isEqualToString:newName]) {
            [[self editorView] setSyntaxStyleNameToColoring:newName recolorNow:NO];
        }
        if (![newName isEqualToString:NSLocalizedString(@"None", nil)]) {
            [self setRecolorWithBecomeKey:YES];
        }
    }
}


// ------------------------------------------------------
/// 背景色(検索のハイライト含む)の変更を取り消し
- (void)clearAllMarkup
// ------------------------------------------------------
{
    NSArray *managers = [[self editorView] allLayoutManagers];
    
    for (NSLayoutManager *manager in managers) {
        [manager removeTemporaryAttribute:NSBackgroundColorAttributeName
                        forCharacterRange:NSMakeRange(0, [[[self editorView] string] length])];
    }
}


// ------------------------------------------------------
/// 現在のエンコードにコンバートできない文字列をマークアップし、その配列を返す
- (void)markupIncompatibleChars:(NSArray *)uncompatibleChars
// ------------------------------------------------------
{
    // 非互換文字をハイライト
    // 文字色と背景色の中間色を得る
    NSColor *foreColor = [[[self editorView] textView] textColor];
    NSColor *backColor = [[[self editorView] textView] backgroundColor];
    CGFloat BG_R, BG_G, BG_B, F_R, F_G, F_B;
    [[foreColor colorUsingColorSpaceName:NSCalibratedRGBColorSpace] getRed:&F_R green:&F_G blue:&F_B alpha:nil];
    [[backColor colorUsingColorSpaceName:NSCalibratedRGBColorSpace] getRed:&BG_R green:&BG_G blue:&BG_B alpha:nil];
    NSColor *incompatibleColor = [NSColor colorWithCalibratedRed:((BG_R + F_R) / 2)
                                                           green:((BG_G + F_G) / 2)
                                                            blue:((BG_B + F_B) / 2)
                                                           alpha:1.0];
    
    // 現存の背景色カラーリングをすべて削除（検索のハイライトも削除される）
    [self clearAllMarkup];
    
    NSArray *layoutManagers = [[self editorView] allLayoutManagers];
    for (NSDictionary *uncompatible in uncompatibleChars) {
        for (NSLayoutManager *manager in layoutManagers) {
            [manager addTemporaryAttribute:NSBackgroundColorAttributeName
                                     value:incompatibleColor
                         forCharacterRange:[uncompatible[k_incompatibleRange] rangeValue]];
        }
    }
}

@end
