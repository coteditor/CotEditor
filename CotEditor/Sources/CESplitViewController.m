/*
 
 CESplitViewController.m
 
 CotEditor
 http://coteditor.com
 
 Created by nakamuxu on 2006-03-26.
 
 ------------------------------------------------------------------------------
 
 © 2004-2007 nakamuxu
 © 2014-2015 1024jp
 
 Licensed under the Apache License, Version 2.0 (the "License");
 you may not use this file except in compliance with the License.
 You may obtain a copy of the License at
 
 http://www.apache.org/licenses/LICENSE-2.0
 
 Unless required by applicable law or agreed to in writing, software
 distributed under the License is distributed on an "AS IS" BASIS,
 WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 See the License for the specific language governing permissions and
 limitations under the License.
 
 */

#import "CESplitViewController.h"
#import "CEEditorView.h"
#import "Constants.h"


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
/// clean up
- (void)dealloc
// ------------------------------------------------------
{
    // Need to set nil to NSSPlitView's delegate manually since it is not weak but just assign,
    //     and may crash when closing split fullscreen window on El Capitan beta 5 (2015-07)
    [[self splitView] setDelegate:nil];
}


// ------------------------------------------------------
/// 自身の view として NSSplitView を返す (NSSplitViewController のメソッド)
- (nonnull NSSplitView *)splitView
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
- (BOOL)validateMenuItem:(nonnull NSMenuItem *)menuItem
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
- (void)enumerateEditorViewsUsingBlock:(nonnull void (^)(CEEditorView * _Nonnull editorView))block;
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
- (CGFloat)splitView:(nonnull NSSplitView *)splitView constrainSplitPosition:(CGFloat)proposedPosition ofSubviewAt:(NSInteger)dividerIndex
// ------------------------------------------------------
{
    // 0.5pxの端数が出ないようにする
    return floor(proposedPosition);
}



#pragma mark Action Messages

// ------------------------------------------------------
/// 分割方向を変更する
- (IBAction)toggleSplitOrientation:(nullable id)sender
// ------------------------------------------------------
{
    [[self splitView] setVertical:![[self splitView] isVertical]];
    
    [self updateOpenSplitViewButtons];
}


// ------------------------------------------------------
/// 次の分割されたテキストビューへフォーカス移動
- (IBAction)focusNextSplitTextView:(nullable id)sender
// ------------------------------------------------------
{
    [self focusSplitTextViewOnNext:YES];
}


// ------------------------------------------------------
/// 前の分割されたテキストビューへフォーカス移動
- (IBAction)focusPrevSplitTextView:(nullable id)sender
// ------------------------------------------------------
{
    [self focusSplitTextViewOnNext:NO];
}



#pragma mark Private Methods

// ------------------------------------------------------
/// 現在フォーカスのある分割ビューを返す
- (nullable CEEditorView *)currentSubview
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
    
    NSArray<__kindof NSView *> *subviews = [[self view] subviews];
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
