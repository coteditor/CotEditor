/*
 =================================================
 CESplitViewController
 (for CotEditor)
 
 Copyright (C) 2004-2007 nakamuxu.
 Copyright (C) 2014 CotEditor Project
 http://coteditor.github.io
 =================================================
 
 encoding="UTF-8"
 Created on 2006-03-26 by nakamuxu
 
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

#import "CESplitViewController.h"
#import "CESplitView.h"
#import "CESubSplitView.h"
#import "constants.h"


@interface CESplitViewController ()

@property (nonatomic) BOOL finishedOpen;

@end



#pragma mark -

@implementation CESplitViewController

// ------------------------------------------------------
/// Nibファイル読み込み直後
- (void)awakeFromNib
// ------------------------------------------------------
{
    [(NSSplitView *)[self view] setVertical:[[NSUserDefaults standardUserDefaults] boolForKey:k_key_splitViewVertical]];
}



#pragma mark Public Methods

// ------------------------------------------------------
/// 行番号表示の有無を設定
- (void)setShowLineNum:(BOOL)showLineNum
// ------------------------------------------------------
{
    for (CESubSplitView *subview in [[self view] subviews]) {
        [subview setShowLineNum:showLineNum];
    }
}


// ------------------------------------------------------
/// ナビゲーションバー描画の有無を設定
- (void)setShowNavigationBar:(BOOL)showNavigationBar
// ------------------------------------------------------
{
    for (CESubSplitView *subview in [[self view] subviews]) {
        [subview setShowNavigationBar:showNavigationBar];
    }
}


// ------------------------------------------------------
/// ラップする／しないを設定
- (void)setWrapLines:(BOOL)wrapLines
// ------------------------------------------------------
{
    for (CESubSplitView *subview in [[self view] subviews]) {
        [subview setWrapLines:wrapLines];
    }
}


// ------------------------------------------------------
/// 不可視文字の表示／非表示を設定
- (void)setShowInvisibles:(BOOL)showInvisibles
// ------------------------------------------------------
{
    for (CESubSplitView *subview in [[self view] subviews]) {
        [subview setShowInvisibles:showInvisibles];
    }
}


// ------------------------------------------------------
/// ソフトタブの有効／無効を設定
- (void)setAutoTabExpandEnabled:(BOOL)isEnabled
// ------------------------------------------------------
{
    for (CESubSplitView *subview in [[self view] subviews]) {
        [subview setAutoTabExpandEnabled:isEnabled];
    }
}


// ------------------------------------------------------
/// 文字にアンチエイリアスを使うかどうかを設定
- (void)setUseAntialias:(BOOL)useAntialias
// ------------------------------------------------------
{
    for (CESubSplitView *subview in [[self view] subviews]) {
        [subview setUseAntialias:useAntialias];
    }
}


// ------------------------------------------------------
/// テキストビュー分割削除ボタンの有効／無効を設定
- (void)setCloseSubSplitViewButtonEnabled:(BOOL)isEnabled
// ------------------------------------------------------
{
    for (CESubSplitView *subview in [[self view] subviews]) {
        [subview updateCloseSubSplitViewButton:isEnabled];
    }
}


// ------------------------------------------------------
/// キャレットを先頭に移動
- (void)setAllCaretToBeginning
// ------------------------------------------------------
{
    for (CESubSplitView *subview in [[self view] subviews]) {
        [subview setCaretToBeginning];
    }
}


// ------------------------------------------------------
/// シンタックススタイルを設定
- (void)setSyntaxWithName:(NSString *)syntaxName
// ------------------------------------------------------
{
    if (!syntaxName) { return; }
    
    for (CESubSplitView *subview in [[self view] subviews]) {
        [subview setSyntaxWithName:syntaxName];
    }
}


// ------------------------------------------------------
/// 全てを再カラーリング、文書表示処理の完了をポスト（ここが最終地点）
- (void)recoloringAllTextView
// ------------------------------------------------------
{
    for (CESubSplitView *subview in [[self view] subviews]) {
        [subview recolorAllTextViewString];
    }
    
    if (![self finishedOpen]) {
        [[NSNotificationCenter defaultCenter] postNotificationName:CEDocumentDidFinishOpenNotification
                                                            object:[[self view] superview]]; // superView = CEEditorView
        [self setFinishedOpen:YES];
    }
}


// ------------------------------------------------------
/// 全てのアウトラインメニューを再更新
- (void)updateAllOutlineMenu
// ------------------------------------------------------
{
    for (CESubSplitView *subview in [[self view] subviews]) {
        [subview updateOutlineMenu];
    }
}


// ------------------------------------------------------
/// 全てのテキストビューの背景不透明度を設定
- (void)setAllBackgroundColorWithAlpha:(CGFloat)alpha
// ------------------------------------------------------
{
    for (CESubSplitView *subview in [[self view] subviews]) {
        [subview setBackgroundColorAlpha:alpha];
    }
}

@end
