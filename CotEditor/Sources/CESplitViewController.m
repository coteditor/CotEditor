/*
 ==============================================================================
 CESplitViewController
 
 CotEditor
 http://coteditor.github.io
 
 Created on 2006-03-26 by nakamuxu
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

#import "CESplitViewController.h"
#import "CEEditorView.h"
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
    [[self splitView] setVertical:[[NSUserDefaults standardUserDefaults] boolForKey:k_key_splitViewVertical]];
    [self updateOpenSplitViewButtons];
}


// ------------------------------------------------------
/// メニューの有効化／無効化を制御
- (BOOL)validateMenuItem:(NSMenuItem *)menuItem
// ------------------------------------------------------
{
    if ([menuItem action] == @selector(toggleSplitOrientation:)) {
        NSString *title = [[self splitView] isVertical] ? @"Stack Views Horizontally" : @"Stack Views Vertically";
        [menuItem setTitle:NSLocalizedString(title, nil)];
        return ([[[self view] subviews] count] > 1);
        
    } else if (([menuItem action] == @selector(focusNextSplitTextView:)) ||
               ([menuItem action] == @selector(focusPrevSplitTextView:))) {
        return ([[[self view] subviews] count] > 1);
    }
    
    return YES;
}

// ------------------------------------------------------
/// 自身の view として NSSplitView を返す (NSSplitViewController のメソッド)
- (NSSplitView *)splitView
// ------------------------------------------------------
{
    return (NSSplitView *)[super view];
}



#pragma mark Public Methods

// ------------------------------------------------------
/// 全layoutManagerを配列で返す
- (NSArray *)layoutManagers
// ------------------------------------------------------
{
    NSMutableArray *managers = [NSMutableArray array];
    
    for (CEEditorView *subview in [[self view] subviews]) {
        [managers addObject:[[subview textView] layoutManager]];
    }
    
    return [managers copy];
}


// ------------------------------------------------------
/// 行番号表示の有無を設定
- (void)setShowLineNum:(BOOL)showLineNum
// ------------------------------------------------------
{
    for (CEEditorView *subview in [[self view] subviews]) {
        [subview setShowLineNum:showLineNum];
    }
}


// ------------------------------------------------------
/// ナビゲーションバー描画の有無を設定
- (void)setShowNavigationBar:(BOOL)showNavigationBar
// ------------------------------------------------------
{
    for (CEEditorView *subview in [[self view] subviews]) {
        [subview setShowNavigationBar:showNavigationBar];
    }
}


// ------------------------------------------------------
/// ラップする／しないを設定
- (void)setWrapLines:(BOOL)wrapLines
// ------------------------------------------------------
{
    for (CEEditorView *subview in [[self view] subviews]) {
        [subview setWrapLines:wrapLines];
    }
    [[self view] setNeedsDisplay:YES];
}


// ------------------------------------------------------
/// 横書き／縦書きを設定
- (void)setVerticalLayoutOrientation:(BOOL)isVerticalLayoutOrientation
// ------------------------------------------------------
{
    NSTextLayoutOrientation orientation = isVerticalLayoutOrientation ? NSTextLayoutOrientationVertical : NSTextLayoutOrientationHorizontal;
    for (CEEditorView *subview in [[self view] subviews]) {
        [[subview textView] setLayoutOrientation:orientation];
    }
}


// ------------------------------------------------------
/// 不可視文字の表示／非表示を設定
- (void)setShowInvisibles:(BOOL)showInvisibles
// ------------------------------------------------------
{
    for (CEEditorView *subview in [[self view] subviews]) {
        [subview setShowInvisibles:showInvisibles];
    }
}


// ------------------------------------------------------
/// ソフトタブの有効／無効を設定
- (void)setAutoTabExpandEnabled:(BOOL)isEnabled
// ------------------------------------------------------
{
    for (CEEditorView *subview in [[self view] subviews]) {
        [subview setAutoTabExpandEnabled:isEnabled];
    }
}


// ------------------------------------------------------
/// 文字にアンチエイリアスを使うかどうかを設定
- (void)setUseAntialias:(BOOL)useAntialias
// ------------------------------------------------------
{
    for (CEEditorView *subview in [[self view] subviews]) {
        [subview setUseAntialias:useAntialias];
    }
}


// ------------------------------------------------------
/// テキストビュー分割削除ボタンの有効／無効を更新
- (void)updateCloseSplitViewButton
// ------------------------------------------------------
{
    BOOL isEnabled = ([[[self view] subviews] count] > 1);
    
    for (CEEditorView *subview in [[self view] subviews]) {
        [subview updateCloseSplitViewButton:isEnabled];
    }
}


// ------------------------------------------------------
/// キャレットを先頭に移動
- (void)moveAllCaretToBeginning
// ------------------------------------------------------
{
    for (CEEditorView *subview in [[self view] subviews]) {
        [subview setCaretToBeginning];
    }
}


// ------------------------------------------------------
/// テーマを設定
- (void)setTheme:(CETheme *)theme
// ------------------------------------------------------
{
    if (!theme) { return; }
    
    for (CEEditorView *subview in [[self view] subviews]) {
        CETextView *textView = [subview textView];
        [textView setTheme:theme];
        [subview recolorAllTextViewString];
        [textView setSelectedRanges:[textView selectedRanges]];  //  選択範囲の再描画
    }
}


// ------------------------------------------------------
/// シンタックススタイルを設定
- (void)setSyntaxWithName:(NSString *)syntaxName
// ------------------------------------------------------
{
    if (!syntaxName) { return; }
    
    for (CEEditorView *subview in [[self view] subviews]) {
        [subview setSyntaxWithName:syntaxName];
    }
}


// ------------------------------------------------------
/// 全てを再カラーリング、文書表示処理の完了をポスト（ここが最終地点）
- (void)recolorAllTextView
// ------------------------------------------------------
{
    for (CEEditorView *subview in [[self view] subviews]) {
        [subview recolorAllTextViewString];
    }
    
    if (![self finishedOpen]) {
        [[NSNotificationCenter defaultCenter] postNotificationName:CEDocumentDidFinishOpenNotification
                                                            object:[[self view] window]];
        [self setFinishedOpen:YES];
    }
}


// ------------------------------------------------------
/// 全てのアウトラインメニューを再更新
- (void)updateAllOutlineMenu
// ------------------------------------------------------
{
    for (CEEditorView *subview in [[self view] subviews]) {
        [subview updateOutlineMenu];
    }
}


// ------------------------------------------------------
/// 全てのテキストビューの背景不透明度を設定
- (void)setAllBackgroundColorWithAlpha:(CGFloat)alpha
// ------------------------------------------------------
{
    for (CEEditorView *subview in [[self view] subviews]) {
        [subview setBackgroundColorAlpha:alpha];
    }
}



#pragma mark Delegate

// ------------------------------------------------------
/// 分割位置を調整
- (CGFloat)splitView:(NSSplitView *)splitView constrainSplitPosition:(CGFloat)proposedPosition ofSubviewAt:(NSInteger)dividerIndex
// ------------------------------------------------------
{
    // 0.5pxの端数が出ないようにする
    return floor(proposedPosition);
}



#pragma mark Action Messages

// ------------------------------------------------------
/// 分割方向を変更する
- (IBAction)toggleSplitOrientation:(id)sender
// ------------------------------------------------------
{
    [[self splitView] setVertical:![[self splitView] isVertical]];
    
    [self updateOpenSplitViewButtons];
}


// ------------------------------------------------------
/// 次の分割されたテキストビューへフォーカス移動
- (IBAction)focusNextSplitTextView:(id)sender
// ------------------------------------------------------
{
    [self focusOtherSplitTextViewOnNext:YES];
}


// ------------------------------------------------------
/// 前の分割されたテキストビューへフォーカス移動
- (IBAction)focusPrevSplitTextView:(id)sender
// ------------------------------------------------------
{
    [self focusOtherSplitTextViewOnNext:NO];
}



#pragma mark Private Methods

// ------------------------------------------------------
/// 現在フォーカスのある分割ビューを返す
- (CEEditorView *)currentSubview
// ------------------------------------------------------
{
    return (CEEditorView *)[(NSTextView *)[[[self view] window] firstResponder] delegate];
}


// ------------------------------------------------------
/// 分割された前／後のテキストビューにフォーカス移動
- (void)focusOtherSplitTextViewOnNext:(BOOL)onNext
// ------------------------------------------------------
{
    NSUInteger count = [[[self view] subviews] count];
    
    if (count < 2) { return; }
    
    NSArray *subviews = [[self view] subviews];
    NSInteger index = [subviews indexOfObject:[self currentSubview]];
    CEEditorView *nextSubview;
    
    if (onNext) {  // == Next
        index++;
    } else {  // == Prev
        index--;
    }
    
    if (index < 0) {
        nextSubview = [subviews lastObject];
    } else if (index >= count) {
        nextSubview = subviews[0];
    } else {
        nextSubview = subviews[index];
    }
    
    [[[self view] window] makeFirstResponder:[nextSubview textView]];
}


// ------------------------------------------------------
/// テキストビュー分割ボタンの画像を更新
- (void)updateOpenSplitViewButtons
// ------------------------------------------------------
{
    for (CEEditorView *subview in [[self view] subviews]) {
        [[subview navigationBar] setSplitOrientationVertical:[[self splitView] isVertical]];
    }
}

@end
