/*
=================================================
CESplitView
(for CotEditor)

Copyright (C) 2004-2007 nakamuxu.
http://www.aynimac.com/
=================================================

encoding="UTF-8"
Created:2006.03.26

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

#import "CESplitView.h"


@implementation CESplitView

// ------------------------------------------------------
- (id)initWithFrame:(NSRect)inFrame
// 初期化
// ------------------------------------------------------
{
    self = [super initWithFrame:inFrame];
    if (self) {
        _finishedOpen = NO;
    }
    return self;
}


// ------------------------------------------------------
- (CGFloat)dividerThickness
// 分割線の高さを返す
// ------------------------------------------------------
{
    return k_splitDividerThickness;
}

// ------------------------------------------------------
- (void)drawDividerInRect:(NSRect)inRect
// 区切り線を描画
// ------------------------------------------------------
{
// （ウィンドウ背景色をクリアカラーにしているため、オーバーライドしないと区切り線の背景が透明になってしまう）

    // 背景を塗る
    [[NSColor gridColor] set];
    [NSBezierPath fillRect:inRect];
    // 区切り線を縁取る
    [[NSColor controlShadowColor] set];
    [NSBezierPath strokeRect:inRect];
    // 区切り線マークを描画
    [super drawDividerInRect:inRect];
}


// ------------------------------------------------------
- (void)setShowLineNum:(BOOL)inBool
// 行番号表示の有無を設定
// ------------------------------------------------------
{
    [[self subviews] makeObjectsPerformSelector:@selector(setShowLineNumWithNumber:) 
                        withObject:@(inBool)];
}


// ------------------------------------------------------
- (void)setShowNavigationBar:(BOOL)inBool
// ナビゲーションバー描画の有無を設定
// ------------------------------------------------------
{
    [[self subviews] makeObjectsPerformSelector:@selector(setShowNavigationBarWithNumber:) 
                        withObject:@(inBool)];
}


// ------------------------------------------------------
- (void)setWrapLines:(BOOL)inBool
// ラップする／しないを設定
// ------------------------------------------------------
{
    [[self subviews] makeObjectsPerformSelector:@selector(setWrapLinesWithNumber:) 
                        withObject:@(inBool)];
}


// ------------------------------------------------------
- (void)setShowInvisibles:(BOOL)inBool
// 不可視文字の表示／非表示を設定
// ------------------------------------------------------
{
    [[self subviews] makeObjectsPerformSelector:@selector(setShowInvisiblesWithNumber:) 
                        withObject:@(inBool)];
}


// ------------------------------------------------------
- (void)setUseAntialias:(BOOL)inBool
// 文字にアンチエイリアスを使うかどうかを設定
// ------------------------------------------------------
{
    [[self subviews] makeObjectsPerformSelector:@selector(setUseAntialiasWithNumber:) 
                        withObject:@(inBool)];
}


// ------------------------------------------------------
- (void)setCloseSubSplitViewButtonEnabled:(BOOL)inBool
// テキストビュー分割削除ボタンを有効／無効を設定
// ------------------------------------------------------
{
    [[self subviews] makeObjectsPerformSelector:@selector(updateCloseSubSplitViewButtonWithNumber:) 
                        withObject:@(inBool)];
}


// ------------------------------------------------------
- (void)setAllCaretToBeginning
// キャレットを先頭に移動
// ------------------------------------------------------
{
    [[self subviews] makeObjectsPerformSelector:@selector(setCaretToBeginning)];
}


// ------------------------------------------------------
- (void)releaseAllEditorView
// subSplitView が持つ editorView への参照を削除
// ------------------------------------------------------
{
    // （dealloc は親階層から行われるため、あらかじめ「子」が持っている「親」を開放しておく）
    [[self subviews] makeObjectsPerformSelector:@selector(releaseEditorView)];
}


// ------------------------------------------------------
- (void)setSyntaxStyleNameToSyntax:(NSString *)inName
// シンタックススタイルを設定
// ------------------------------------------------------
{
    if (inName == nil) { return; }

    [[self subviews] makeObjectsPerformSelector:@selector(setSyntaxStyleNameToSyntax:) withObject:inName];
}


// ------------------------------------------------------
- (void)recoloringAllTextView
// 全てを再カラーリング、文書表示処理の完了をポスト（ここが最終地点）
// ------------------------------------------------------
{
    [[self subviews] makeObjectsPerformSelector:@selector(recoloringAllTextViewString)];
    if (!_finishedOpen) {
        [[NSNotificationCenter defaultCenter] postNotificationName:k_documentDidFinishOpenNotification 
                    object:[self superview]]; // superView = CEEditorView
        _finishedOpen = YES;
    }
}


// ------------------------------------------------------
- (void)updateAllOutlineMenu
// 全てのアウトラインメニューを再更新
// ------------------------------------------------------
{
    [[self subviews] makeObjectsPerformSelector:@selector(updateOutlineMenu)];
}


// ------------------------------------------------------
- (void)setAllBackgroundColorWithAlpha:(float)inAlpha
// 全てのテキストビューの背景透明度を設定
// ------------------------------------------------------
{
    [[self subviews] makeObjectsPerformSelector:@selector(setBackgroundColorAlphaWithNumber:) 
                        withObject:@(inAlpha)];
}



@end
