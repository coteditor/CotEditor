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
#import "CETextView.h"
#import "CESyntaxStyle.h"


@interface CEEditorViewController ()

@property (nonatomic, nullable, weak) IBOutlet __kindof NSScrollView *scrollView;
@property (nonatomic, nonnull) NSTextStorage *textStorage;


// readonly
@property (readwrite, nullable, nonatomic) IBOutlet CETextView *textView;
@property (readwrite, nullable, nonatomic) IBOutlet CENavigationBarController *navigationBarController;

@end




#pragma mark -

@implementation CEEditorViewController

#pragma mark Superclass Methods

// ------------------------------------------------------
/// initialize instance
- (nonnull instancetype)initWithTextStorage:(nonnull NSTextStorage *)textStorage
// ------------------------------------------------------
{
    self = [super init];
    if (self) {
        _textStorage = textStorage;
    }
    return self;
}


// ------------------------------------------------------
/// clean up
- (void)dealloc
// ------------------------------------------------------
{
    [_textStorage removeLayoutManager:[_textView layoutManager]];
    
    _textView = nil;
}


// ------------------------------------------------------
/// nib name
- (nullable NSString *)nibName
// ------------------------------------------------------
{
    return @"EditorView";
}


// ------------------------------------------------------
/// setup UI
- (void)loadView
// ------------------------------------------------------
{
    [super loadView];
    
    [self addChildViewController:[self navigationBarController]];
    
    // set textStorage to textView
    [[[self textView] layoutManager] replaceTextStorage:[self textStorage]];
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
/// 行番号表示設定をセット
- (void)setShowsLineNum:(BOOL)showsLineNum
// ------------------------------------------------------
{
    [[self scrollView] setRulersVisible:showsLineNum];
}


// ------------------------------------------------------
/// ナビゲーションバーを表示／非表示
- (void)setShowsNavigationBar:(BOOL)showsNavigationBar animate:(BOOL)performAnimation;
// ------------------------------------------------------
{
    [[self navigationBarController] setShown:showsNavigationBar animate:performAnimation];
}


// ------------------------------------------------------
/// シンタックススタイルを設定
- (void)applySyntax:(nonnull CESyntaxStyle *)syntaxStyle
// ------------------------------------------------------
{
    [[self textView] setInlineCommentDelimiter:[syntaxStyle inlineCommentDelimiter]];
    [[self textView] setBlockCommentDelimiters:[syntaxStyle blockCommentDelimiters]];
    [[self textView] setSyntaxCompletionWords:[syntaxStyle completionWords]];
    [[self textView] setFirstSyntaxCompletionCharacterSet:[syntaxStyle firstCompletionCharacterSet]];
}



#pragma mark Action Messages

// ------------------------------------------------------
/// アウトラインメニューの前の項目を選択（メニューバーからのアクションを中継）
- (IBAction)selectPrevItemOfOutlineMenu:(nullable id)sender
// ------------------------------------------------------
{
    [[self navigationBarController] selectPrevItem:sender];
}


// ------------------------------------------------------
/// アウトラインメニューの次の項目を選択（メニューバーからのアクションを中継）
- (IBAction)selectNextItemOfOutlineMenu:(nullable id)sender
// ------------------------------------------------------
{
    [[self navigationBarController] selectNextItem:sender];
}

@end
