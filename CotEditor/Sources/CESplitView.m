/*
=================================================
CESplitView
(for CotEditor)

 Copyright (C) 2004-2007 nakamuxu.
 Copyright (C) 2014 CotEditor Project
 http://coteditor.github.io
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
#import "constants.h"


@interface CESplitView ()

@property (nonatomic) BOOL finishedOpen;

@end




#pragma mark -

@implementation CESplitView

#pragma mark Superclass Methods

// ------------------------------------------------------
/// 初期化
- (instancetype)initWithFrame:(NSRect)frameRect
// ------------------------------------------------------
{
    self = [super initWithFrame:frameRect];
    if (self) {
        [self setFinishedOpen:NO];
        [self setDividerStyle:NSSplitViewDividerStylePaneSplitter];
    }
    return self;
}



#pragma mark Public Methods

// ------------------------------------------------------
/// 行番号表示の有無を設定
- (void)setShowLineNum:(BOOL)showLineNum
// ------------------------------------------------------
{
    [[self subviews] makeObjectsPerformSelector:@selector(setShowLineNumWithNumber:)
                                     withObject:@(showLineNum)];
}


// ------------------------------------------------------
/// ナビゲーションバー描画の有無を設定
- (void)setShowNavigationBar:(BOOL)showNavigationBar
// ------------------------------------------------------
{
    [[self subviews] makeObjectsPerformSelector:@selector(setShowNavigationBarWithNumber:)
                                     withObject:@(showNavigationBar)];
}


// ------------------------------------------------------
/// ラップする／しないを設定
- (void)setWrapLines:(BOOL)wrapLines
// ------------------------------------------------------
{
    [[self subviews] makeObjectsPerformSelector:@selector(setWrapLinesWithNumber:)
                                     withObject:@(wrapLines)];
}


// ------------------------------------------------------
/// 不可視文字の表示／非表示を設定
- (void)setShowInvisibles:(BOOL)showInvisibles
// ------------------------------------------------------
{
    [[self subviews] makeObjectsPerformSelector:@selector(setShowInvisiblesWithNumber:)
                                     withObject:@(showInvisibles)];
}


// ------------------------------------------------------
/// ソフトタブの有効／無効を設定
- (void)setAutoTabExpandEnabled:(BOOL)isEnabled
// ------------------------------------------------------
{
    [[self subviews] makeObjectsPerformSelector:@selector(setAutoTabExpandEnabledWithNumber:)
                                     withObject:@(isEnabled)];
}


// ------------------------------------------------------
/// 文字にアンチエイリアスを使うかどうかを設定
- (void)setUseAntialias:(BOOL)useAntialias
// ------------------------------------------------------
{
    [[self subviews] makeObjectsPerformSelector:@selector(setUseAntialiasWithNumber:)
                                     withObject:@(useAntialias)];
}


// ------------------------------------------------------
/// テキストビュー分割削除ボタンの有効／無効を設定
- (void)setCloseSubSplitViewButtonEnabled:(BOOL)isEnabled
// ------------------------------------------------------
{
    [[self subviews] makeObjectsPerformSelector:@selector(updateCloseSubSplitViewButtonWithNumber:)
                                     withObject:@(isEnabled)];
}


// ------------------------------------------------------
/// キャレットを先頭に移動
- (void)setAllCaretToBeginning
// ------------------------------------------------------
{
    [[self subviews] makeObjectsPerformSelector:@selector(setCaretToBeginning)];
}


// ------------------------------------------------------
/// subSplitView が持つ editorView への参照を削除
- (void)releaseAllEditorView
// ------------------------------------------------------
{
    // （dealloc は親階層から行われるため、あらかじめ「子」が持っている「親」を開放しておく）
    [[self subviews] makeObjectsPerformSelector:@selector(releaseEditorView)];
}


// ------------------------------------------------------
/// シンタックススタイルを設定
- (void)setSyntaxStyleNameToSyntax:(NSString *)syntaxName
// ------------------------------------------------------
{
    if (!syntaxName) { return; }

    [[self subviews] makeObjectsPerformSelector:@selector(setSyntaxStyleNameToSyntax:)
                                     withObject:syntaxName];
}


// ------------------------------------------------------
/// 全てを再カラーリング、文書表示処理の完了をポスト（ここが最終地点）
- (void)recoloringAllTextView
// ------------------------------------------------------
{
    [[self subviews] makeObjectsPerformSelector:@selector(recolorAllTextViewString)];
    if (![self finishedOpen]) {
        [[NSNotificationCenter defaultCenter] postNotificationName:CEDocumentDidFinishOpenNotification
                                                            object:[self superview]]; // superView = CEEditorView
        [self setFinishedOpen:YES];
    }
}


// ------------------------------------------------------
/// 全てのアウトラインメニューを再更新
- (void)updateAllOutlineMenu
// ------------------------------------------------------
{
    [[self subviews] makeObjectsPerformSelector:@selector(updateOutlineMenu)];
}


// ------------------------------------------------------
/// 全てのテキストビューの背景不透明度を設定
- (void)setAllBackgroundColorWithAlpha:(CGFloat)alpha
// ------------------------------------------------------
{
    [[self subviews] makeObjectsPerformSelector:@selector(setBackgroundColorAlphaWithNumber:)
                                     withObject:@(alpha)];
}

@end
