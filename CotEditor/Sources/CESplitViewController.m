/*
 ==============================================================================
 CESplitViewController
 
 CotEditor
 http://coteditor.com
 
 Created on 2006-03-26 by nakamuxu
 encoding="UTF-8"
 ------------------------------------------------------------------------------
 
 © 2004-2007 nakamuxu
 © 2014-2015 1024jp
 
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


@implementation CESplitViewController

#pragma mark Superclass Methods

// ------------------------------------------------------
/// ビューの読み込み
- (void)awakeFromNib
// ------------------------------------------------------
{
    [super awakeFromNib];
    
    [[self splitView] setVertical:[[NSUserDefaults standardUserDefaults] boolForKey:CEDefaultSplitViewVerticalKey]];
    [self updateOpenSplitViewButtons];
}


// ------------------------------------------------------
/// 自身の view として NSSplitView を返す (NSSplitViewController のメソッド)
- (NSSplitView *)splitView
// ------------------------------------------------------
{
    return (NSSplitView *)[super view];
}




#pragma mark Protocol

//=======================================================
// NSMenuValidation Protocol
//=======================================================

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
               ([menuItem action] == @selector(focusPrevSplitTextView:)))
    {
        return ([[[self view] subviews] count] > 1);
    }
    
    return YES;
}



#pragma mark Public Methods

// ------------------------------------------------------
/// enumerate all subviews as CEEditorView
- (void)enumerateEditorViewsUsingBlock:(void (^)(CEEditorView *))block
// ------------------------------------------------------
{
    for (CEEditorView *subview in [[self view] subviews]) {
        block(subview);
    }
}


// ------------------------------------------------------
/// テキストビュー分割削除ボタンの有効／無効を更新
- (void)updateCloseSplitViewButton
// ------------------------------------------------------
{
    BOOL isEnabled = ([[[self view] subviews] count] > 1);
    
    [self enumerateEditorViewsUsingBlock:^(CEEditorView *editorView) {
        [editorView updateCloseSplitViewButton:isEnabled];
    }];
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
    [self focusSplitTextViewOnNext:YES];
}


// ------------------------------------------------------
/// 前の分割されたテキストビューへフォーカス移動
- (IBAction)focusPrevSplitTextView:(id)sender
// ------------------------------------------------------
{
    [self focusSplitTextViewOnNext:NO];
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
- (void)focusSplitTextViewOnNext:(BOOL)onNext
// ------------------------------------------------------
{
    NSUInteger count = [[[self view] subviews] count];
    
    if (count < 2) { return; }
    
    NSArray *subviews = [[self view] subviews];
    NSInteger index = [subviews indexOfObject:[self currentSubview]];
    
    if (onNext) {
        index++;
    } else {
        index--;
    }
    
    CEEditorView *nextSubview;
    if (index < 0) {
        nextSubview = [subviews lastObject];
    } else if (index >= count) {
        nextSubview = [subviews firstObject];
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
    BOOL isVertical = [[self splitView] isVertical];
    
    [self enumerateEditorViewsUsingBlock:^(CEEditorView *editorView) {
        [[editorView navigationBar] setSplitOrientationVertical:isVertical];
    }];
}

@end
