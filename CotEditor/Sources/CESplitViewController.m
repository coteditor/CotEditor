/*
 
 CESplitViewController.m
 
 CotEditor
 http://coteditor.com
 
 Created by nakamuxu on 2006-03-26.
 
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

#import "CESplitViewController.h"
#import "CEEditorViewController.h"
#import "CENavigationBarController.h"
#import "CETextView.h"
#import "CEDefaults.h"


@interface CESplitViewController ()

@property (nonatomic, nonnull) NSMutableArray<CEEditorViewController *> *editorViewControllers;

@end




#pragma mark -

@implementation CESplitViewController

#pragma mark Superclass Methods

// ------------------------------------------------------
/// initialize instance
- (nullable instancetype)initWithCoder:(nonnull NSCoder *)coder
// ------------------------------------------------------
{
    self = [super initWithCoder:coder];
    if (self) {
        _editorViewControllers = [NSMutableArray array];
    }
    return self;
}


// ------------------------------------------------------
/// setup view
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
    // Need to set nil to NSSplitView's delegate manually since it is not weak but just assign,
    //     and may crash when closing split fullscreen window on El Capitan (2015-07)
    [[self splitView] setDelegate:nil];
}


// ------------------------------------------------------
/// return its view as NSSplitView (NSSplitViewController's method)
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
        NSString *title = [[self splitView] isVertical] ? @"Stack Editors Horizontally" : @"Stack Editors Vertically";
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
/// enumerate all subview's viewControllers as CEEditorViewController
- (void)enumerateEditorViewsUsingBlock:(nonnull void (^)(CEEditorViewController * _Nonnull viewController))block;
// ------------------------------------------------------
{
    for (CEEditorViewController *viewController in [self editorViewControllers]) {
        block(viewController);
    }
}


// ------------------------------------------------------
/// add subview for given viewController at desired position
- (void)addSubviewForViewController:(nonnull CEEditorViewController *)editorViewController relativeTo:(nullable NSView *)otherEditorView
// ------------------------------------------------------
{
    [[self editorViewControllers] addObject:editorViewController];
    [[self splitView] addSubview:[editorViewController view] positioned:NSWindowAbove relativeTo:otherEditorView];
    
    [self updateCloseSplitViewButton];
}


// ------------------------------------------------------
/// remove subview of given viewController
- (void)removeSubviewForViewController:(nonnull CEEditorViewController *)editorViewController
// ------------------------------------------------------
{
    [[editorViewController view] removeFromSuperview];
    [[self editorViewControllers] removeObject:editorViewController];
    
    [self updateCloseSplitViewButton];
}


// ------------------------------------------------------
/// find viewController for given subview
- (nullable CEEditorViewController *)viewControllerForSubview:(nonnull __kindof NSView *)view
// ------------------------------------------------------
{
    for (CEEditorViewController *viewController in [self editorViewControllers]) {
        if ([viewController view] == view) {
            return viewController;
        }
    }
    
    return nil;
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
- (nullable CEEditorViewController *)currentSubviewController
// ------------------------------------------------------
{
    return (CEEditorViewController *)[(NSTextView *)[[[self view] window] firstResponder] delegate];
}


// ------------------------------------------------------
/// 分割された前／後のテキストビューにフォーカス移動
- (void)focusSplitTextViewOnNext:(BOOL)onNext
// ------------------------------------------------------
{
    NSUInteger count = [[[self view] subviews] count];
    
    if (count < 2) { return; }
    
    NSArray<__kindof CEEditorViewController *> *subviewControllers = [self editorViewControllers];
    NSInteger index = [subviewControllers indexOfObject:[self currentSubviewController]];
    
    if (onNext) {
        index++;
    } else {
        index--;
    }
    
    CEEditorViewController *nextEditorViewController;
    if (index < 0) {
        nextEditorViewController = [subviewControllers lastObject];
    } else if (index >= count) {
        nextEditorViewController = [subviewControllers firstObject];
    } else {
        nextEditorViewController = subviewControllers[index];
    }
    
    [[[self view] window] makeFirstResponder:[nextEditorViewController textView]];
}


// ------------------------------------------------------
/// テキストビュー分割ボタンの画像を更新
- (void)updateOpenSplitViewButtons
// ------------------------------------------------------
{
    BOOL isVertical = [[self splitView] isVertical];
    
    [self enumerateEditorViewsUsingBlock:^(CEEditorViewController * _Nonnull editorView) {
        [[editorView navigationBarController] setSplitOrientationVertical:isVertical];
    }];
}


// ------------------------------------------------------
/// テキストビュー分割削除ボタンの有効／無効を更新
- (void)updateCloseSplitViewButton
// ------------------------------------------------------
{
    BOOL isEnabled = ([[[self view] subviews] count] > 1);
    
    [self enumerateEditorViewsUsingBlock:^(CEEditorViewController * _Nonnull editorView) {
        [[editorView navigationBarController] setCloseSplitButtonEnabled:isEnabled];
    }];
}

@end
