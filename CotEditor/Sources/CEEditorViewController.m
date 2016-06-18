/*
 
 CEEditorViewController.m
 
 CotEditor
 http://coteditor.com
 
 Created by nakamuxu on 2006-03-18.
 
 ------------------------------------------------------------------------------
 
 © 2004-2007 nakamuxu
 © 2014-2016 1024jp
 
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

#import "CEEditorViewController.h"
#import "CENavigationBarController.h"
#import "CETextViewController.h"
#import "CETextView.h"


@interface CEEditorViewController ()

@property (nonatomic, nullable, weak) IBOutlet NSSplitViewItem *navigationBarItem;
@property (nonatomic, nullable, weak) IBOutlet NSSplitViewItem *textViewItem;

@end




#pragma mark -

@implementation CEEditorViewController

#pragma mark Superclass Methods

// ------------------------------------------------------
/// setup UI
- (void)viewDidLoad
// ------------------------------------------------------
{
    [super viewDidLoad];
    
    [[self navigationBarController] setTextView:[self textView]];
}


// ------------------------------------------------------
/// avoid showing draggable cursor
- (NSRect)splitView:(nonnull NSSplitView *)splitView effectiveRect:(NSRect)proposedEffectiveRect forDrawnRect:(NSRect)drawnRect ofDividerAtIndex:(NSInteger)dividerIndex
// ------------------------------------------------------
{
    proposedEffectiveRect.size = NSZeroSize;
    
    return [super splitView:splitView effectiveRect:proposedEffectiveRect forDrawnRect:drawnRect ofDividerAtIndex:dividerIndex];
}


// ------------------------------------------------------
/// validate actions
- (BOOL)validateMenuItem:(NSMenuItem *)menuItem
// ------------------------------------------------------
{
    if ([menuItem action] == @selector(selectPrevItemOfOutlineMenu:)) {
        return [[self navigationBarController] canSelectPrevItem];
    } else if ([menuItem action] == @selector(selectNextItemOfOutlineMenu:)) {
        return [[self navigationBarController] canSelectNextItem];
    }
    
    return YES;
}



#pragma mark Public Methods

// ------------------------------------------------------

- (void)setTextStorage:(NSTextStorage *)textStorage
// ------------------------------------------------------
{
    _textStorage = textStorage;
    
    // set textStorage to textView
    [[[self textView] layoutManager] replaceTextStorage:textStorage];
}


// ------------------------------------------------------

- (nullable CETextView *)textView
// ------------------------------------------------------
{
    return [[self textViewController] textView];
}


// ------------------------------------------------------

- (nullable CENavigationBarController *)navigationBarController
// ------------------------------------------------------
{
    return (CENavigationBarController *)[[self navigationBarItem] viewController];
}


// ------------------------------------------------------

- (nullable CETextViewController *)textViewController
// ------------------------------------------------------
{
    return (CETextViewController *)[[self textViewItem] viewController];
}


// ------------------------------------------------------
/// 行番号表示設定をセット
- (void)setShowsLineNumber:(BOOL)showsLineNumber
// ------------------------------------------------------
{
    [[self textViewController] setShowsLineNumber:showsLineNumber];
}


// ------------------------------------------------------
/// ナビゲーションバーを表示／非表示
- (void)setShowsNavigationBar:(BOOL)showsNavigationBar animate:(BOOL)performAnimation;
// ------------------------------------------------------
{
    if (performAnimation) {
        [[[self navigationBarItem] animator] setCollapsed:!showsNavigationBar];
    } else {
        [[self navigationBarItem] setCollapsed:!showsNavigationBar];
    }
}


// ------------------------------------------------------
/// シンタックススタイルを設定
- (void)applySyntax:(nonnull CESyntaxStyle *)syntaxStyle
// ------------------------------------------------------
{
    [[self textViewController] setSyntaxStyle:syntaxStyle];
}



#pragma mark Action Messages

// ------------------------------------------------------
/// アウトラインメニューの前の項目を選択（メニューバーからのアクションを中継）
- (IBAction)selectPrevItemOfOutlineMenu:(nullable id)sender
// ------------------------------------------------------
{
    [[self navigationBarController] selectPrevItemOfOutlineMenu:sender];
}


// ------------------------------------------------------
/// アウトラインメニューの次の項目を選択（メニューバーからのアクションを中継）
- (IBAction)selectNextItemOfOutlineMenu:(nullable id)sender
// ------------------------------------------------------
{
    [[self navigationBarController] selectNextItemOfOutlineMenu:sender];
}

@end
