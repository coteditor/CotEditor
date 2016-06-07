/*
 
 CEEditorWrapper.m
 
 CotEditor
 http://coteditor.com
 
 Created by nakamuxu on 2004-12-08.
 
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

#import "CEEditorWrapper.h"
#import "CEDocument.h"
#import "CEDocumentAnalyzer.h"
#import "CEIncompatibleCharacterScanner.h"
#import "CEEditorViewController.h"
#import "CESplitViewController.h"
#import "CENavigationBarController.h"
#import "CETextView.h"
#import "CEThemeManager.h"
#import "CESyntaxStyle.h"
#import "CEToggleToolbarItem.h"
#import "CETextFinder.h"

#import "CEDefaults.h"
#import "Constants.h"

#import "NSTextView+CELayout.h"
#import "NSString+Indentation.h"


@interface CEEditorWrapper () <CETextFinderClientProvider, CESyntaxStyleDelegate, NSTextStorageDelegate>

@property (nonatomic) BOOL showsNavigationBar;

@property (nonatomic, nullable) IBOutlet NSSplitViewItem *splitViewItem;

@end




#pragma -

@implementation CEEditorWrapper

// ------------------------------------------------------
/// initialize instance
- (nonnull instancetype)init
// ------------------------------------------------------
{
    self = [super init];
    if (self) {
        NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
        
        _showsInvisibles = [defaults boolForKey:CEDefaultShowInvisiblesKey];
        _showsLineNum = [defaults boolForKey:CEDefaultShowLineNumbersKey];
        _showsNavigationBar = [defaults boolForKey:CEDefaultShowNavigationBarKey];
        _wrapsLines = [defaults boolForKey:CEDefaultWrapLinesKey];
        _verticalLayoutOrientation = [defaults boolForKey:CEDefaultLayoutTextVerticalKey];
        _showsPageGuide = [defaults boolForKey:CEDefaultShowPageGuideKey];
        
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(didUpdateTheme:)
                                                     name:CEThemeDidUpdateNotification
                                                   object:nil];
    }
    return self;
}


// ------------------------------------------------------
/// clean up
- (void)dealloc
// ------------------------------------------------------
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    
    [[self textStorage] setDelegate:nil];
}


// ------------------------------------------------------
/// join to responder chain
- (void)awakeFromNib
// ------------------------------------------------------
{
    [[self window] setNextResponder:self];
}


// ------------------------------------------------------
/// keys to be restored from the last session
+ (nonnull NSArray<NSString *> *)restorableStateKeyPaths  // TODO: currently does not work
// ------------------------------------------------------
{
    return @[NSStringFromSelector(@selector(showsNavigationBar)),
             NSStringFromSelector(@selector(showsLineNum)),
             NSStringFromSelector(@selector(showsPageGuide)),
             NSStringFromSelector(@selector(showsInvisibles)),
             NSStringFromSelector(@selector(verticalLayoutOrientation)),
             ];
}


// ------------------------------------------------------
/// apply current state to related menu items
- (BOOL)validateMenuItem:(nonnull NSMenuItem *)menuItem
// ------------------------------------------------------
{
    if ([menuItem action] == @selector(recolorAll:)) {
        return [[self syntaxStyle] canParse];
    }
    
    NSInteger state = NSOffState;
    NSString *title;
    
    if ([menuItem action] == @selector(toggleLineNumber:)) {
        title = [self showsLineNum] ? @"Hide Line Numbers" : @"Show Line Numbers";
        
    } else if ([menuItem action] == @selector(toggleNavigationBar:)) {
        title = [self showsNavigationBar] ? @"Hide Navigation Bar" : @"Show Navigation Bar";
        
    } else if ([menuItem action] == @selector(toggleLineWrap:)) {
        title = [self wrapsLines] ? @"Unwrap Lines" : @"Wrap Lines";
        
    } else if ([menuItem action] == @selector(toggleLayoutOrientation:)) {
        NSString *title = [self isVerticalLayoutOrientation] ? @"Use Horizontal Orientation" :  @"Use Vertical Orientation";
        [menuItem setTitle:NSLocalizedString(title, nil)];
        
    } else if ([menuItem action] == @selector(togglePageGuide:)) {
        title = [self showsPageGuide] ? @"Hide Page Guide" : @"Show Page Guide";
        
    } else if ([menuItem action] == @selector(toggleInvisibleChars:)) {
        title = [self showsInvisibles] ? @"Hide Invisible Characters" : @"Show Invisible Characters";
        [menuItem setTitle:NSLocalizedString(title, nil)];
        
        // disable button if item cannot be enable
        if ([[self class] canActivateShowInvisibles]) {
            [menuItem setToolTip:NSLocalizedString(@"Show or hide invisible characters in document", nil)];
        } else {
            [menuItem setToolTip:NSLocalizedString(@"To show invisible characters, set them in Preferences", nil)];
            return NO;
        }
        
    } else if ([menuItem action] == @selector(toggleAutoTabExpand:)) {
        state = [[self focusedTextView] isAutoTabExpandEnabled] ? NSOnState : NSOffState;
        
    } else if ([menuItem action] == @selector(toggleAntialias:)) {
        state = [[self focusedTextView] usesAntialias] ? NSOnState : NSOffState;
        
    } else if ([menuItem action] == @selector(changeTabWidth:)) {
        state = ([[self focusedTextView] tabWidth] == [menuItem tag]) ? NSOnState : NSOffState;
        
    } else if ([menuItem action] == @selector(closeSplitTextView:)) {
        return ([[[[self splitViewController] view] subviews] count] > 1);
        
    } else if ([menuItem action] == @selector(changeTheme:)) {
        state = [[[self theme] name] isEqualToString:[menuItem title]] ? NSOnState : NSOffState;
    }
    
    if (title) {
        [menuItem setTitle:NSLocalizedString(title, nil)];
    } else {
        [menuItem setState:state];
    }
    
    return YES;
}


// ------------------------------------------------------
/// apply current state to related toolbar items
- (BOOL)validateToolbarItem:(nonnull NSToolbarItem *)theItem
// ------------------------------------------------------
{
    if ([theItem action] == @selector(recolorAll:)) {
        return [[self syntaxStyle] canParse];
    }
    
    // validate button image state
    if ([theItem isKindOfClass:[CEToggleToolbarItem class]]) {
        CEToggleToolbarItem *imageItem = (CEToggleToolbarItem *)theItem;
        
        if ([theItem action] == @selector(toggleLineWrap:)) {
            [imageItem setState:[self wrapsLines] ? NSOnState : NSOffState];
            
        } else if ([theItem action] == @selector(toggleLayoutOrientation:)) {
            [imageItem setState:[self isVerticalLayoutOrientation] ? NSOnState : NSOffState];
            
        } else if ([theItem action] == @selector(togglePageGuide:)) {
            [imageItem setState:[self showsPageGuide] ? NSOnState : NSOffState];
            
        } else if ([theItem action] == @selector(toggleInvisibleChars:)) {
            [imageItem setState:[self showsInvisibles] ? NSOnState : NSOffState];
            
            // disable button if item cannot be enable
            if ([[self class] canActivateShowInvisibles]) {
                [theItem setToolTip:NSLocalizedString(@"Show or hide invisible characters in document", nil)];
            } else {
                [theItem setToolTip:NSLocalizedString(@"To show invisible characters, set them in Preferences", nil)];
                return NO;
            }
            
        } else if ([theItem action] == @selector(toggleAutoTabExpand:)) {
            [imageItem setState:[self isAutoTabExpandEnabled] ? NSOnState : NSOffState];
        }
    }
    
    return YES;
}



#pragma mark Delegate

//=======================================================
// NSTextStorageDelegate Protocol
//=======================================================

// ------------------------------------------------------
/// text did edit
- (void)textStorageDidProcessEditing:(nonnull NSNotification *)notification
// ------------------------------------------------------
{
    NSTextStorage *textStorage = [notification object];
    
    // ignore if only attributes did change
    if (([textStorage editedMask] & NSTextStorageEditedCharacters) == 0) { return; }
    
    // update editor information
    // -> In case, if "Replace All" performed without moving caret.
    [[[self document] analyzer] invalidateEditorInfo];
    
    // parse syntax
    [[self syntaxStyle] invalidateOutline];
    if ([[self syntaxStyle] canParse]) {
        // invalidate only edited lines
        NSRange updateRange = [[textStorage string] lineRangeForRange:[textStorage editedRange]];
        // perform highlight in the next run loop to give layoutManager time to update temporary attribute
        CESyntaxStyle *syntaxStyle = [self syntaxStyle];
        dispatch_async(dispatch_get_main_queue(), ^{
            [syntaxStyle highlightRange:updateRange];
        });
    }
    
    // update incompatible chars list
    [[[self document] incompatibleCharacterScanner] invalidate];
}


//=======================================================
// CESyntaxStyleDelegate Protocol
//=======================================================

// ------------------------------------------------------
/// update outline menu in navigation bar
- (void)syntaxStyle:(nonnull CESyntaxStyle *)syntaxStyle didParseOutline:(nullable NSArray<CEOutlineItem *> *)outlineItems
// ------------------------------------------------------
{
    for (CEEditorViewController *viewController in [[self splitViewController] childViewControllers]) {
        [[viewController navigationBarController] setOutlineItems:outlineItems];
        // -> The selection update will be done in the `setOutlineItems` method above, so you don't need invoke it (2008-05-16)
    }
}



#pragma mark Notifications

//=======================================================
// NSTextView
//=======================================================

// ------------------------------------------------------
/// selection did change
- (void)textViewDidChangeSelection:(nonnull NSNotification *)notification
// ------------------------------------------------------
{
    // update document information
    [[[self document] analyzer] invalidateEditorInfo];
}


//=======================================================
// CEDocument
//=======================================================

// ------------------------------------------------------
/// document updated syntax style
- (void)didChangeSyntaxStyle:(nonnull NSNotification *)notification
// ------------------------------------------------------
{
    CESyntaxStyle *syntaxStyle = [self syntaxStyle];
    
    for (CEEditorViewController *viewController in [[self splitViewController] childViewControllers]) {
        [viewController applySyntax:syntaxStyle];
        if ([syntaxStyle canParse]) {
            [[viewController navigationBarController] showOutlineIndicator];
        }
    }
    
    [syntaxStyle invalidateOutline];
    [self invalidateSyntaxHighlight];
}


//=======================================================
// Notification  < CEThemeManager
//=======================================================

// ------------------------------------------------------
/// テーマが更新された
- (void)didUpdateTheme:(nonnull NSNotification *)notification
// ------------------------------------------------------
{
    NSString *oldThemeName = [notification userInfo][CEOldNameKey];
    NSString *newThemeName = [notification userInfo][CENewNameKey];
    
    if ([oldThemeName isEqualToString:[[self theme] name]]) {
        [self setThemeWithName:newThemeName];
    }
}



#pragma mark Public Methods

// ------------------------------------------------------
///
- (void)setDocument:(CEDocument *)document
// ------------------------------------------------------
{
    if (!document) { return; }
    
    _document = document;
    
    // detect indent style
    if ([[NSUserDefaults standardUserDefaults] boolForKey:CEDefaultDetectsIndentStyleKey]) {
        switch ([[[document textStorage] string] detectIndentStyle]) {
            case CEIndentStyleTab:
                [self setAutoTabExpandEnabled:NO];
                break;
            case CEIndentStyleSpace:
                [self setAutoTabExpandEnabled:YES];
                break;
            case CEIndentStyleNotFound:
                break;
        }
    }
    
    [[document textStorage] setDelegate:self];
    [[document syntaxStyle] setDelegate:self];
    
    CEEditorViewController *editorViewController = [self createEditorBasedViewController:nil];
    
    // start parcing syntax highlights and outline menu
    if ([[document syntaxStyle] canParse]) {
        [[editorViewController navigationBarController] showOutlineIndicator];
    }
    [[document syntaxStyle] invalidateOutline];
    [self invalidateSyntaxHighlight];
    
    // focus text view
    [[self window] makeFirstResponder:[editorViewController textView]];
    
    // observe syntax/theme change
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(didChangeSyntaxStyle:)
                                                 name:CEDocumentSyntaxStyleDidChangeNotification
                                               object:document];
}


// ------------------------------------------------------
/// return textView focused on
- (nullable CETextView *)focusedTextView
// ------------------------------------------------------
{
    return [[[self splitViewController] focusedSubviewController] textView];
}


// ------------------------------------------------------
/// 現在のエンコードにコンバートできない文字列をマークアップ
- (void)markupRanges:(nonnull NSArray<NSValue *> *)ranges
// ------------------------------------------------------
{
    NSColor *color = [[[self focusedTextView] theme] markupColor];
    NSArray<NSLayoutManager *> *layoutManagers = [self layoutManagers];
    
    for (NSValue *rangeValue in ranges) {
        NSRange documentRange = [rangeValue rangeValue];
        NSRange range = [[[self textStorage] string] convertRange:documentRange
                                                  fromNewLineType:[[self document] lineEnding]
                                                    toNewLineType:CENewLineLF];
        
        for (NSLayoutManager *manager in layoutManagers) {
            [manager addTemporaryAttribute:NSBackgroundColorAttributeName value:color
                         forCharacterRange:range];
        }
    }
}


// ------------------------------------------------------
/// 背景色(検索のハイライト含む)の変更を取り消し
- (void)clearAllMarkup
// ------------------------------------------------------
{
    NSArray<NSLayoutManager *> *managers = [self layoutManagers];
    
    for (NSLayoutManager *manager in managers) {
        [manager removeTemporaryAttribute:NSBackgroundColorAttributeName
                        forCharacterRange:NSMakeRange(0, [[manager attributedString] length])];
    }
}


// ------------------------------------------------------
/// ナビゲーションバーを表示する／しないをセット
- (void)setShowsNavigationBar:(BOOL)showsNavigationBar
// ------------------------------------------------------
{
    _showsNavigationBar = showsNavigationBar;
    
    for (CEEditorViewController *viewController in [[self splitViewController] childViewControllers]) {
        [viewController setShowsNavigationBar:showsNavigationBar animate:NO];
    }
}


// ------------------------------------------------------
/// 行番号の表示をする／しないをセット
- (void)setShowsLineNum:(BOOL)showsLineNum
// ------------------------------------------------------
{
    _showsLineNum = showsLineNum;
    
    for (CEEditorViewController *viewController in [[self splitViewController] childViewControllers]) {
        [viewController setShowsLineNum:showsLineNum];
    }
}


// ------------------------------------------------------
/// 行をラップする／しないをセット
- (void)setWrapsLines:(BOOL)wrapsLines
// ------------------------------------------------------
{
    _wrapsLines = wrapsLines;
    
    for (CEEditorViewController *viewController in [[self splitViewController] childViewControllers]) {
        [[viewController textView] setWrapsLines:wrapsLines];
    }
}


// ------------------------------------------------------
/// 横書き／縦書きをセット
- (void)setVerticalLayoutOrientation:(BOOL)isVerticalLayoutOrientation
// ------------------------------------------------------
{
    _verticalLayoutOrientation = isVerticalLayoutOrientation;
    
    NSTextLayoutOrientation orientation = isVerticalLayoutOrientation ? NSTextLayoutOrientationVertical : NSTextLayoutOrientationHorizontal;
    
    for (CEEditorViewController *viewController in [[self splitViewController] childViewControllers]) {
        [[viewController textView] setLayoutOrientation:orientation];
    }
}


// ------------------------------------------------------
/// フォントを返す
- (nullable NSFont *)font
// ------------------------------------------------------
{
    return [[self focusedTextView] font];
}


// ------------------------------------------------------
/// 現在のテーマを返す
- (nullable CETheme *)theme
// ------------------------------------------------------
{
    return [[self focusedTextView] theme];
}


// ------------------------------------------------------
/// ページガイドを表示する／しないをセット
- (void)setShowsPageGuide:(BOOL)showsPageGuide
// ------------------------------------------------------
{
    _showsPageGuide = showsPageGuide;
    
    for (CEEditorViewController *viewController in [[self splitViewController] childViewControllers]) {
        [[viewController textView] setShowsPageGuide:showsPageGuide];
        [[viewController textView] setNeedsDisplayInRect:[[viewController textView] visibleRect] avoidAdditionalLayout:YES];
    }
}


// ------------------------------------------------------
/// 不可視文字の表示／非表示を設定
- (void)setShowsInvisibles:(BOOL)showsInvisibles
// ------------------------------------------------------
{
    _showsInvisibles = showsInvisibles;
    
    for (CEEditorViewController *viewController in [[self splitViewController] childViewControllers]) {
        [[viewController textView] setShowsInvisibles:showsInvisibles];
    }
}



#pragma mark Action Messages

// ------------------------------------------------------
/// 行番号表示をトグルに切り替える
- (IBAction)toggleLineNumber:(nullable id)sender
// ------------------------------------------------------
{
    [self setShowsLineNum:![self showsLineNum]];
}


// ------------------------------------------------------
/// ナビゲーションバーの表示をトグルに切り替える
- (IBAction)toggleNavigationBar:(nullable id)sender
// ------------------------------------------------------
{
    BOOL showsNavigationBar = ![self showsNavigationBar];
    
    _showsNavigationBar = showsNavigationBar;
    
    for (CEEditorViewController *viewController in [[self splitViewController] childViewControllers]) {
        [viewController setShowsNavigationBar:showsNavigationBar animate:YES];
    }
}


// ------------------------------------------------------
/// ワードラップをトグルに切り替える
- (IBAction)toggleLineWrap:(nullable id)sender
// ------------------------------------------------------
{
    [self setWrapsLines:![self wrapsLines]];
}


// ------------------------------------------------------
/// 横書き／縦書きを切り替える
- (IBAction)toggleLayoutOrientation:(nullable id)sender
// ------------------------------------------------------
{
    [self setVerticalLayoutOrientation:![self isVerticalLayoutOrientation]];
}


// ------------------------------------------------------
/// 文字にアンチエイリアスを使うかどうかをトグルに切り替える
- (IBAction)toggleAntialias:(nullable id)sender
// ------------------------------------------------------
{
    BOOL usesAntialias = ![[self focusedTextView] usesAntialias];
    
    for (CEEditorViewController *viewController in [[self splitViewController] childViewControllers]) {
        [[viewController textView] setUsesAntialias:usesAntialias];
    }
}


// ------------------------------------------------------
/// 不可視文字表示をトグルに切り替える
- (IBAction)toggleInvisibleChars:(nullable id)sender
// ------------------------------------------------------
{
    BOOL showsInvisibles = ![self showsInvisibles];
    [self setShowsInvisibles:showsInvisibles];
}


// ------------------------------------------------------
/// ソフトタブの有効／無効をトグルに切り替える
- (IBAction)toggleAutoTabExpand:(nullable id)sender
// ------------------------------------------------------
{
    BOOL isEnabled = [[self focusedTextView] isAutoTabExpandEnabled];
    
    [self setAutoTabExpandEnabled:!isEnabled];
}


// ------------------------------------------------------
/// ページガイド表示をトグルに切り替える
- (IBAction)togglePageGuide:(nullable id)sender
// ------------------------------------------------------
{
    [self setShowsPageGuide:![self showsPageGuide]];
}


// ------------------------------------------------------
/// change tab width from the main menu
- (IBAction)changeTabWidth:(nullable id)sender
// ------------------------------------------------------
{
    NSUInteger tabWidth = [sender tag];
    
    for (CEEditorViewController *viewController in [[self splitViewController] childViewControllers]) {
        [[viewController textView] setTabWidth:tabWidth];
    }
}


// ------------------------------------------------------
/// 新しいテーマを適用
- (IBAction)changeTheme:(nullable id)sender
// ------------------------------------------------------
{
    NSString *name = [sender title];
    
    if ([name length] > 0) {
        [self setThemeWithName:name];
    }
}


// ------------------------------------------------------
/// ドキュメント全体を再カラーリング
- (IBAction)recolorAll:(nullable id)sender
// ------------------------------------------------------
{
    [self invalidateSyntaxHighlight];
}


// ------------------------------------------------------
/// テキストビュー分割を行う
- (IBAction)openSplitTextView:(nullable id)sender
// ------------------------------------------------------
{
    CEEditorViewController *currentEditorViewController;
    
    // find target CEEditorViewController
    id view = [sender isMemberOfClass:[NSMenuItem class]] ? [[self window] firstResponder] : sender;
    while (view) {
        if ([[view identifier] isEqualToString:@"EditorView"]) {
            currentEditorViewController = [[self splitViewController] viewControllerForSubview:view];
            break;
        }
        view = [view superview];
    }
    
    if (!currentEditorViewController) { return; }
    
    // end current editing
    [[[NSTextInputContext currentInputContext] client] unmarkText];
    
    CEEditorViewController *newEditorViewController = [self createEditorBasedViewController:currentEditorViewController];
    
    [[newEditorViewController navigationBarController] setOutlineItems:[[self syntaxStyle] outlineItems]];
    [self invalidateSyntaxHighlight];
    
    // adjust visible areas
    [[newEditorViewController textView] setSelectedRange:[[currentEditorViewController textView] selectedRange]];
    [[currentEditorViewController textView] centerSelectionInVisibleArea:self];
    [[newEditorViewController textView] centerSelectionInVisibleArea:self];
    
    // move focus to the new editor
    [[self window] makeFirstResponder:[newEditorViewController textView]];
}


// ------------------------------------------------------
//// 分割されたテキストビューを閉じる
- (IBAction)closeSplitTextView:(nullable id)sender
// ------------------------------------------------------
{
    CEEditorViewController *currentEditorViewController;
    
    // find target CEEditorViewController
    id view = [sender isMemberOfClass:[NSMenuItem class]] ? [[self window] firstResponder] : sender;
    while (view) {
        if ([[view identifier] isEqualToString:@"EditorView"]) {
            currentEditorViewController = [[self splitViewController] viewControllerForSubview:view];
            break;
        }
        view = [view superview];
    }
    
    if (!currentEditorViewController) { return; }
    
    // end current editing
    [[[NSTextInputContext currentInputContext] client] unmarkText];
    
    // move focus to the next text view if the view to close has a focus
    if ([[self window] firstResponder] == [currentEditorViewController textView]) {
        NSArray<CEEditorViewController *> *childViewControllers = [[self splitViewController] childViewControllers];
        NSUInteger count = [childViewControllers count];
        NSUInteger deleteIndex = [childViewControllers indexOfObject:currentEditorViewController];
        NSUInteger index = deleteIndex + 1;
        if (index >= count) {
            index = count - 2;
        }
        
        [[self window] makeFirstResponder:[childViewControllers[index] textView]];
    }
    
    // close
    NSSplitViewItem *splitViewItem = [[self splitViewController] splitViewItemForViewController:currentEditorViewController];
    [[self splitViewController] removeSplitViewItem:splitViewItem];
}



#pragma mark Private Methods

// ------------------------------------------------------
/// whether at least one of invisible characters is enabled in the preferences currently
+ (BOOL)canActivateShowInvisibles
// ------------------------------------------------------
{
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    
    return ([defaults boolForKey:CEDefaultShowInvisibleSpaceKey] ||
            [defaults boolForKey:CEDefaultShowInvisibleTabKey] ||
            [defaults boolForKey:CEDefaultShowInvisibleNewLineKey] ||
            [defaults boolForKey:CEDefaultShowInvisibleFullwidthSpaceKey] ||
            [defaults boolForKey:CEDefaultShowOtherInvisibleCharsKey]);
}


// ------------------------------------------------------
/// apply text styles from text view
- (void)invalidateStyleInTextStorage
// ------------------------------------------------------
{
    [[self focusedTextView] invalidateStyle];
}


// ------------------------------------------------------
/// 全テキストを再カラーリング
- (void)invalidateSyntaxHighlight
// ------------------------------------------------------
{
    [[self syntaxStyle] highlightWholeStringWithCompletionHandler:nil];
}


// ------------------------------------------------------
/// サブビューに初期値を設定
- (nonnull CEEditorViewController *)createEditorBasedViewController:(nullable CEEditorViewController *)baseViewController
// ------------------------------------------------------
{
    CEEditorViewController *editorViewController = [[CEEditorViewController alloc] initWithTextStorage:[[self document] textStorage]];
    
    // instert new editorView just below the editorView that the pressed button belongs to or has focus
    [[self splitViewController] addSubviewForViewController:editorViewController relativeTo:baseViewController];
    
    [editorViewController setShowsLineNum:[self showsLineNum]];
    [editorViewController setShowsNavigationBar:[self showsNavigationBar] animate:NO];
    [[editorViewController textView] setWrapsLines:[self wrapsLines]];
    [[editorViewController textView] setShowsInvisibles:[self showsInvisibles]];
    [[editorViewController textView] setLayoutOrientation:([self isVerticalLayoutOrientation] ?
                                                           NSTextLayoutOrientationVertical : NSTextLayoutOrientationHorizontal)];
    [[editorViewController textView] setShowsPageGuide:[self showsPageGuide]];
    
    [editorViewController applySyntax:[self syntaxStyle]];
    
    // copy textView states
    if (baseViewController) {
        [[editorViewController textView] setFont:[[baseViewController textView] font]];
        [[editorViewController textView] setTheme:[[baseViewController textView] theme]];
    }
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(textViewDidChangeSelection:)
                                                 name:NSTextViewDidChangeSelectionNotification
                                               object:[editorViewController textView]];
    
    return editorViewController;
}


// ------------------------------------------------------
- (CESplitViewController *)splitViewController
// ------------------------------------------------------
{
    return (CESplitViewController *)[[self splitViewItem] viewController];
}


// ------------------------------------------------------
/// ウインドウを返す
- (NSWindow *)window
// ------------------------------------------------------
{
    return [[[self splitViewController] view] window];
}


// ------------------------------------------------------
/// text storage を返す
- (NSTextStorage *)textStorage
// ------------------------------------------------------
{
    return [[self document] textStorage];
}


// ------------------------------------------------------
/// return all layoutManagers
- (NSArray<NSLayoutManager *> *)layoutManagers
// ------------------------------------------------------
{
    return [[[self document] textStorage] layoutManagers];
}


// ------------------------------------------------------
/// シンタックススタイル名を返す
- (nullable CESyntaxStyle *)syntaxStyle
// ------------------------------------------------------
{
    return [[self document] syntaxStyle];
}


// ------------------------------------------------------
/// ソフトタブの有効／無効を返す
- (BOOL)isAutoTabExpandEnabled
// ------------------------------------------------------
{
    CETextView *textView = [self focusedTextView];
    
    if (textView) {
        return [textView isAutoTabExpandEnabled];
    } else {
        return [[NSUserDefaults standardUserDefaults] boolForKey:CEDefaultAutoExpandTabKey];
    }
}


// ------------------------------------------------------
/// ソフトタブの有効／無効をセット
- (void)setAutoTabExpandEnabled:(BOOL)enabled
// ------------------------------------------------------
{
    for (CEEditorViewController *viewController in [[self splitViewController] childViewControllers]) {
        [[viewController textView] setAutoTabExpandEnabled:enabled];
    }
}


// ------------------------------------------------------
/// テーマを適用する
- (void)setThemeWithName:(nonnull NSString *)themeName
// ------------------------------------------------------
{
    CETheme *theme = [[CEThemeManager sharedManager] themeWithName:themeName];
    
    if (!theme) { return; }
    
    for (CEEditorViewController *viewController in [[self splitViewController] childViewControllers]) {
        [[viewController textView] setTheme:theme];
        
        // re-select to update current line highlight
        [[viewController textView] setSelectedRanges:[[viewController textView] selectedRanges]];
    }
    
    [self invalidateSyntaxHighlight];
}

@end
