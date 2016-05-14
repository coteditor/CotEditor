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
#import "CEEditorViewController.h"
#import "CELayoutManager.h"
#import "CEWindowController.h"
#import "CEToolbarController.h"
#import "CESplitViewController.h"
#import "CENavigationBarController.h"
#import "CEThemeManager.h"
#import "CESyntaxStyle.h"
#import "CEGoToSheetController.h"
#import "CETextFinder.h"
#import "CEDefaults.h"

#import "NSString+CENewLine.h"
#import "NSString+CERange.h"


@interface CEEditorWrapper () <CETextFinderClientProvider>

@property (nonatomic, nullable, weak) NSTimer *syntaxHighlightTimer;
@property (nonatomic, nullable, weak) NSTimer *outlineMenuTimer;

@property (nonatomic, nullable) IBOutlet CESplitViewController *splitViewController;


// readonly
@property (readwrite, nonatomic) BOOL canActivateShowInvisibles;

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
        
        _canActivateShowInvisibles = ([defaults boolForKey:CEDefaultShowInvisibleSpaceKey] ||
                                      [defaults boolForKey:CEDefaultShowInvisibleTabKey] ||
                                      [defaults boolForKey:CEDefaultShowInvisibleNewLineKey] ||
                                      [defaults boolForKey:CEDefaultShowInvisibleFullwidthSpaceKey] ||
                                      [defaults boolForKey:CEDefaultShowOtherInvisibleCharsKey]);
        
        _showsInvisibles = [defaults boolForKey:CEDefaultShowInvisiblesKey];
        _showsLineNum = [defaults boolForKey:CEDefaultShowLineNumbersKey];
        _showsNavigationBar = [defaults boolForKey:CEDefaultShowNavigationBarKey];
        _wrapsLines = [defaults boolForKey:CEDefaultWrapLinesKey];
        _verticalLayoutOrientation = [defaults boolForKey:CEDefaultLayoutTextVerticalKey];
        _showsPageGuide = [defaults boolForKey:CEDefaultShowPageGuideKey];
    }
    return self;
}


// ------------------------------------------------------
/// clean up
- (void)dealloc
// ------------------------------------------------------
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    
    [_syntaxHighlightTimer invalidate];
    [_outlineMenuTimer invalidate];
    
    _focusedTextView = nil;
}


// ------------------------------------------------------
/// setup UI
- (void)awakeFromNib
// ------------------------------------------------------
{
    [[self window] setNextResponder:self];
    
    // Yosemite 未満の場合は手動で Responder Chain に入れる
    // （Yosemite 以降は自動的に追加されるためか以下の一行が入るとハングしてしまう）
    if (NSAppKitVersionNumber < NSAppKitVersionNumber10_10) {
        [self setNextResponder:[self splitViewController]];
    }
    
    CEEditorViewController *editorViewController = [[CEEditorViewController alloc] initWithTextStorage:[[NSTextStorage alloc] init]];
    [[self splitViewController] addSubviewForViewController:editorViewController relativeTo:nil];
    [self setupEditorViewController:editorViewController baseView:nil];
    
    // TODO: Refactoring
    // -> This is probably not the best position to apply sytnax style to the text view.
    //    However as a quick fix, I put it here tentatively. It works. But should be refactored later. (2016-01 1024jp)
    [editorViewController applySyntax:[self syntaxStyle]];
    
    [self setFocusedTextView:[editorViewController textView]];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(didChangeSyntaxStyle:)
                                                 name:CEDocumentSyntaxStyleDidChangeNotification
                                               object:[self document]];
}



#pragma mark Protocol

//=======================================================
// NSMenuValidation Protocol
//=======================================================

// ------------------------------------------------------
/// メニュー項目の有効・無効を制御
- (BOOL)validateMenuItem:(nonnull NSMenuItem *)menuItem
// ------------------------------------------------------
{
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
        
    } else if ([menuItem action] == @selector(toggleAntialias:)) {
        state = [self usesAntialias] ? NSOnState : NSOffState;
        
    } else if ([menuItem action] == @selector(togglePageGuide:)) {
        title = [self showsPageGuide] ? @"Hide Page Guide" : @"Show Page Guide";
        
    } else if ([menuItem action] == @selector(toggleInvisibleChars:)) {
        title = [self showsInvisibles] ? @"Hide Invisible Characters" : @"Show Invisible Characters";
        [menuItem setTitle:NSLocalizedString(title, nil)];
        
        if (![self canActivateShowInvisibles]) {
            [menuItem setToolTip:NSLocalizedString(@"To show invisible characters, set them in Preferences and re-open the document.", nil)];
        }
        
        return [self canActivateShowInvisibles];
        
    } else if ([menuItem action] == @selector(toggleAutoTabExpand:)) {
        state = [[self focusedTextView] isAutoTabExpandEnabled] ? NSOnState : NSOffState;
        
    } else if ([menuItem action] == @selector(selectPrevItemOftimerMenu:)) {
        return ([[self navigationBarController] canSelectPrevItem]);
    } else if ([menuItem action] == @selector(selectNextItemOfOutlineMenu:)) {
        return ([[self navigationBarController] canSelectNextItem]);
        
    } else if ([menuItem action] == @selector(closeSplitTextView:)) {
        return ([[[[self splitViewController] view] subviews] count] > 1);
        
    } else if ([menuItem action] == @selector(changeTheme:)) {
        state = [[[self theme] name] isEqualToString:[menuItem title]] ? NSOnState : NSOffState;
        
    } else if ([menuItem action] == @selector(recolorAll:)) {
        return [self canHighlight];
    }
    
    if (title) {
        [menuItem setTitle:NSLocalizedString(title, nil)];
    } else {
        [menuItem setState:state];
    }
    
    return YES;
}


//=======================================================
// NSToolbarItemValidation Protocol
//=======================================================

// ------------------------------------------------------
/// ツールバー項目の有効・無効を制御
- (BOOL)validateToolbarItem:(nonnull NSToolbarItem *)theItem
// ------------------------------------------------------
{
    if ([theItem action] == @selector(recolorAll:)) {
        return [self canHighlight];
    }
    
    return YES;
}



#pragma mark Public Methods

// ------------------------------------------------------
/// textView の文字列を返す（改行コードはLF固定）
- (nonnull NSString *)string
// ------------------------------------------------------
{
    return [[self textStorage] string] ?: @"";
}


// ------------------------------------------------------
/// 指定された範囲の textView の文字列を返す
- (nonnull NSString *)substringWithRange:(NSRange)range
// ------------------------------------------------------
{
    return [[self string] substringWithRange:range];
}


// ------------------------------------------------------
/// メイン textView で選択された文字列を返す
- (nonnull NSString *)substringWithSelection
// ------------------------------------------------------
{
    return [[self string] substringWithRange:[[self focusedTextView] selectedRange]];
}


// ------------------------------------------------------
/// メインtextViewに文字列をセット
- (void)setString:(nonnull NSString *)string
// ------------------------------------------------------
{
    // UTF-16 でないものを UTF-16 で表示した時など当該フォントで表示できない文字が表示されてしまった後だと、
    // 設定されたフォントでないもので表示されることがあるため、リセットする
    NSDictionary<NSString *, id> *attributes = [[self focusedTextView] typingAttributes];
    NSAttributedString *attrString = [[NSAttributedString alloc] initWithString:string attributes:attributes];
    
    [[self textStorage] setAttributedString:attrString];
    [[self focusedTextView] setSelectedRange:NSMakeRange(0, 0)];
    [[self focusedTextView] detectLinkIfNeeded];
}


// ------------------------------------------------------
/// 選択文字列を置換する
- (void)insertTextViewString:(nonnull NSString *)string
// ------------------------------------------------------
{
    [[self focusedTextView] insertString:string];
}


// ------------------------------------------------------
/// 選択範囲の直後に文字列を挿入
- (void)insertTextViewStringAfterSelection:(nonnull NSString *)string
// ------------------------------------------------------
{
    [[self focusedTextView] insertStringAfterSelection:string];
}


// ------------------------------------------------------
/// 全文字列を置換
- (void)replaceTextViewAllStringWithString:(nonnull NSString *)string
// ------------------------------------------------------
{
    [[self focusedTextView] replaceAllStringWithString:string];
}


// ------------------------------------------------------
/// 文字列の最後に新たな文字列を追加
- (void)appendTextViewString:(nonnull NSString *)string
// ------------------------------------------------------
{
    [[self focusedTextView] appendString:string];
}


// ------------------------------------------------------
/// 選択範囲を返す
- (NSRange)selectedRange
// ------------------------------------------------------
{
    NSTextView *textView = [self focusedTextView];
    
    return [[textView string] convertRange:[textView selectedRange]
                           fromNewLineType:CENewLineLF
                             toNewLineType:[[self document] lineEnding]];
}


// ------------------------------------------------------
/// 選択範囲を変更
- (void)setSelectedRange:(NSRange)charRange
// ------------------------------------------------------
{
    NSTextView *textView = [self focusedTextView];
    NSRange range = [[textView string] convertRange:charRange
                                    fromNewLineType:[[self document] lineEnding]
                                      toNewLineType:CENewLineLF];
    
    [textView setSelectedRange:range];
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
                        forCharacterRange:NSMakeRange(0, [[self string] length])];
    }
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
    [[self splitViewController] enumerateEditorViewsUsingBlock:^(CEEditorViewController * _Nonnull viewController) {
        [[viewController textView] setAutoTabExpandEnabled:enabled];
    }];
    [[[self windowController] toolbarController] toggleItemWithTag:CEToolbarAutoTabExpandItemTag
                                                             setOn:enabled];
}


// ------------------------------------------------------
/// ナビゲーションバーを表示する／しないをセット
- (void)setShowsNavigationBar:(BOOL)showsNavigationBar animate:(BOOL)performAnimation
// ------------------------------------------------------
{
    _showsNavigationBar = showsNavigationBar;
    
    [[self splitViewController] enumerateEditorViewsUsingBlock:^(CEEditorViewController * _Nonnull viewController) {
        [viewController setShowsNavigationBar:showsNavigationBar animate:performAnimation];
    }];
    [[[self windowController] toolbarController] toggleItemWithTag:CEToolbarShowNavigationBarItemTag
                                                             setOn:showsNavigationBar];
    
    if (showsNavigationBar && ![[self outlineMenuTimer] isValid]) {
        [self invalidateOutlineMenu];
    }
}


// ------------------------------------------------------
/// 行番号の表示をする／しないをセット
- (void)setShowsLineNum:(BOOL)showsLineNum
// ------------------------------------------------------
{
    _showsLineNum = showsLineNum;
    
    [[self splitViewController] enumerateEditorViewsUsingBlock:^(CEEditorViewController * _Nonnull viewController) {
        [viewController setShowsLineNum:showsLineNum];
    }];
    [[[self windowController] toolbarController] toggleItemWithTag:CEToolbarShowLineNumItemTag
                                                             setOn:showsLineNum];
}


// ------------------------------------------------------
/// 行をラップする／しないをセット
- (void)setWrapsLines:(BOOL)wrapsLines
// ------------------------------------------------------
{
    _wrapsLines = wrapsLines;
    
    [[self splitViewController] enumerateEditorViewsUsingBlock:^(CEEditorViewController * _Nonnull viewController) {
        [viewController setWrapsLines:wrapsLines];
    }];
    [[[self windowController] toolbarController] toggleItemWithTag:CEToolbarWrapLinesItemTag
                                                             setOn:wrapsLines];
}


// ------------------------------------------------------
/// 横書き／縦書きをセット
- (void)setVerticalLayoutOrientation:(BOOL)isVerticalLayoutOrientation
// ------------------------------------------------------
{
    _verticalLayoutOrientation = isVerticalLayoutOrientation;
    
    NSTextLayoutOrientation orientation = isVerticalLayoutOrientation ? NSTextLayoutOrientationVertical : NSTextLayoutOrientationHorizontal;
    
    [[self splitViewController] enumerateEditorViewsUsingBlock:^(CEEditorViewController * _Nonnull viewController) {
        [[viewController textView] setLayoutOrientation:orientation];
    }];
    [[[self windowController] toolbarController] toggleItemWithTag:CEToolbarTextOrientationItemTag
                                                             setOn:isVerticalLayoutOrientation];
}


// ------------------------------------------------------
/// フォントを返す
- (nullable NSFont *)font
// ------------------------------------------------------
{
    return [[self focusedTextView] font];
}


// ------------------------------------------------------
/// フォントをセット
- (void)setFont:(NSFont *)font
// ------------------------------------------------------
{
    [[self focusedTextView] setFont:font];
}


// ------------------------------------------------------
/// アンチエイリアスでの描画の許可を得る
- (BOOL)usesAntialias
// ------------------------------------------------------
{
    CELayoutManager *manager = (CELayoutManager *)[[self focusedTextView] layoutManager];
    
    return [manager usesAntialias];
}


// ------------------------------------------------------
/// テーマを適用する
- (void)setThemeWithName:(nonnull NSString *)themeName
// ------------------------------------------------------
{
    CETheme *theme = [[CEThemeManager sharedManager] themeWithName:themeName];
    
    [[self splitViewController] enumerateEditorViewsUsingBlock:^(CEEditorViewController * _Nonnull viewController) {
        [[viewController textView] setTheme:theme];
    }];
    
    [[self syntaxStyle] highlightWholeStringInTextStorage:[self textStorage] completionHandler:nil];
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
    
    [[self splitViewController] enumerateEditorViewsUsingBlock:^(CEEditorViewController * _Nonnull viewController) {
        [[viewController textView] setShowsPageGuide:showsPageGuide];
        [[viewController textView] setNeedsDisplayInRect:[[viewController textView] visibleRect] avoidAdditionalLayout:YES];
    }];
    [[[self windowController] toolbarController] toggleItemWithTag:CEToolbarShowPageGuideItemTag
                                                             setOn:showsPageGuide];
}


// ------------------------------------------------------
/// 不可視文字の表示／非表示を設定
- (void)setShowsInvisibles:(BOOL)showsInvisibles
// ------------------------------------------------------
{
    _showsInvisibles = showsInvisibles;
    
    [[self splitViewController] enumerateEditorViewsUsingBlock:^(CEEditorViewController * _Nonnull viewController) {
        [viewController setShowsInvisibles:showsInvisibles];
    }];
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
    [self setShowsNavigationBar:![self showsNavigationBar] animate:YES];
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
    BOOL usesAntialias = ![(CELayoutManager *)[[self focusedTextView] layoutManager] usesAntialias];
    
    [[self splitViewController] enumerateEditorViewsUsingBlock:^(CEEditorViewController * _Nonnull viewController) {
        [viewController setUsesAntialias:usesAntialias];
    }];
}


// ------------------------------------------------------
/// 不可視文字表示をトグルに切り替える
- (IBAction)toggleInvisibleChars:(nullable id)sender
// ------------------------------------------------------
{
    BOOL showsInvisibles = ![self showsInvisibles];
    [self setShowsInvisibles:showsInvisibles];
    
    [[[self windowController] toolbarController] toggleItemWithTag:CEToolbarShowInvisibleCharsItemTag
                                                             setOn:showsInvisibles];
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


// ------------------------------------------------------
/// テキストビュー分割を行う
- (IBAction)openSplitTextView:(nullable id)sender
// ------------------------------------------------------
{
    CEEditorViewController *currentEditorViewController;
    
    // find CEEditorViewController to base
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
    [[self class] endCurrentEditing];
    
    CEEditorViewController *newEditorViewController = [[CEEditorViewController alloc] initWithTextStorage:[self textStorage]];
    
    // instert new editorView just below the editorView that the pressed button belongs to or has focus
    [[self splitViewController] addSubviewForViewController:newEditorViewController relativeTo:[currentEditorViewController view]];
    
    // apply current status to the new editorView
    [self setupEditorViewController:newEditorViewController baseView:currentEditorViewController];
    
    [newEditorViewController applySyntax:[self syntaxStyle]];
    [self invalidateSyntaxHighlight];
    [self invalidateOutlineMenu];
    
    // move focus to the new editor
    [[self window] makeFirstResponder:[newEditorViewController textView]];
    
    // adjust visible areas
    [[currentEditorViewController textView] centerSelectionInVisibleArea:self];
    [[newEditorViewController textView] centerSelectionInVisibleArea:self];
}


// ------------------------------------------------------
//// 分割されたテキストビューを閉じる
- (IBAction)closeSplitTextView:(nullable id)sender
// ------------------------------------------------------
{
    CEEditorViewController *editorViewControllerToClose;
    
    // find CEEditorViewController to close
    id view = [sender isMemberOfClass:[NSMenuItem class]] ? [[self window] firstResponder] : sender;
    while (view) {
        if ([[view identifier] isEqualToString:@"EditorView"]) {
            editorViewControllerToClose = [[self splitViewController] viewControllerForSubview:view];
            break;
        }
        view = [view superview];
    }
    
    if (!editorViewControllerToClose) { return; }
    
    // end current editing
    [[self class] endCurrentEditing];
    
    // move focus to the next text view if the view to close has a focus
    if ([[self window] firstResponder] == [editorViewControllerToClose textView]) {
        NSArray<__kindof NSView *> *subViews = [[[self splitViewController] view] subviews];
        NSUInteger count = [subViews count];
        NSUInteger deleteIndex = [subViews indexOfObject:[editorViewControllerToClose view]];
        NSUInteger index = deleteIndex + 1;
        if (index >= count) {
            index = count - 2;
        }
        NSTextView *nextTextView = [[[self splitViewController] viewControllerForSubview:subViews[index]] textView];
        [[self window] makeFirstResponder:nextTextView];
    }
    
    // close
    [[self splitViewController] removeSubviewForViewController:editorViewControllerToClose];
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



#pragma mark Private Methods

// ------------------------------------------------------
/// fix current marked text
+ (void)endCurrentEditing
// ------------------------------------------------------
{
    id<NSTextInputClient> client = [[NSTextInputContext currentInputContext] client];
    if ([client hasMarkedText]) {
        [client doCommandBySelector:@selector(insertNewline:)];
    }
}


// ------------------------------------------------------
/// サブビューに初期値を設定
- (void)setupEditorViewController:(nonnull CEEditorViewController *)editorViewController baseView:(nullable CEEditorViewController *)baseViewController
// ------------------------------------------------------
{
    [editorViewController setEditorWrapper:self];
    
    [self setShowsInvisibles:[self showsInvisibles]];
    [self setShowsLineNum:[self showsLineNum]];
    [self setShowsNavigationBar:[self showsNavigationBar] animate:NO];
    [self setWrapsLines:[self wrapsLines]];
    [self setVerticalLayoutOrientation:[self isVerticalLayoutOrientation]];
    [self setShowsPageGuide:[self showsPageGuide]];
    
    // copy textView states
    if (baseViewController) {
        [[editorViewController textView] setFont:[[baseViewController textView] font]];
        [[editorViewController textView] setTheme:[[baseViewController textView] theme]];
        [[editorViewController textView] setLineSpacing:[[baseViewController textView] lineSpacing]];
        [[editorViewController textView] setSelectedRange:[[baseViewController textView] selectedRange]];
    }
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
    return [[self focusedTextView] textStorage];
}


// ------------------------------------------------------
/// windowControllerを返す
- (CEWindowController *)windowController
// ------------------------------------------------------
{
    return [[self window] windowController];
}


// ------------------------------------------------------
/// return all layoutManagers
- (NSArray<NSLayoutManager *> *)layoutManagers
// ------------------------------------------------------
{
    return [[[self focusedTextView] textStorage] layoutManagers];
}


// ------------------------------------------------------
/// documentを返す
- (CEDocument *)document
// ------------------------------------------------------
{
    return [[self windowController] document];
}


// ------------------------------------------------------
/// navigationBarを返す
- (CENavigationBarController *)navigationBarController
// ------------------------------------------------------
{
    return [(CEEditorViewController *)[[self focusedTextView] delegate] navigationBarController];
}

@end




#pragma mark -

@implementation CEEditorWrapper (SyntaxParsing)

#pragma mark Public Methods

// ------------------------------------------------------
/// シンタックススタイル名を返す
- (nullable CESyntaxStyle *)syntaxStyle
// ------------------------------------------------------
{
    return [[self document] syntaxStyle];
}


// ------------------------------------------------------
/// return if sytnax highlight works
- (BOOL)canHighlight
// ------------------------------------------------------
{
    BOOL isHighlightEnabled = [[NSUserDefaults standardUserDefaults] boolForKey:CEDefaultEnableSyntaxHighlightKey];
    BOOL isHighlightable = ([self syntaxStyle] != nil) && ![[self syntaxStyle] isNone];
    
    return isHighlightEnabled && isHighlightable;
}


// ------------------------------------------------------
/// 全テキストを再カラーリング
- (void)invalidateSyntaxHighlight
// ------------------------------------------------------
{
    [[self syntaxHighlightTimer] invalidate];
    
    [[self syntaxStyle] highlightWholeStringInTextStorage:[self textStorage] completionHandler:nil];
}


// ------------------------------------------------------
/// アウトラインメニューを更新
- (void)invalidateOutlineMenu
// ------------------------------------------------------
{
    [[self outlineMenuTimer] invalidate];
    
    if (![[NSUserDefaults standardUserDefaults] boolForKey:CEDefaultEnableSyntaxHighlightKey]) { return; }
    
    NSString *wholeString = [[self textStorage] string] ? : @"";
    
    // 規定の文字数以上の場合にはインジケータを表示
    // （ただし、CEDefaultShowColoringIndicatorTextLengthKey が「0」の時は表示しない）
    NSUInteger indicatorThreshold = [[NSUserDefaults standardUserDefaults] integerForKey:CEDefaultShowColoringIndicatorTextLengthKey];
    if (indicatorThreshold > 0 && indicatorThreshold < [wholeString length]) {
        [[self splitViewController] enumerateEditorViewsUsingBlock:^(CEEditorViewController * _Nonnull viewController) {
            [[viewController navigationBarController] showOutlineIndicator];
        }];
    }
    
    // extract outline and pass result to navigationBar
    CESplitViewController *splitViewController = [self splitViewController];
    [[self syntaxStyle] parseOutlineItemsInString:wholeString completionHandler:^(NSArray<NSDictionary<NSString *,id> *> * _Nonnull outlineItems)
     {
         [splitViewController enumerateEditorViewsUsingBlock:^(CEEditorViewController * _Nonnull viewController) {
             [[viewController navigationBarController] setOutlineItems:outlineItems];
             // -> The selection update will be done in the `setOutlineItems` method above, so you don't need invoke it (2008-05-16)
         }];
    }];
}


// ------------------------------------------------------
/// let parse syntax highlight after a delay
- (void)setupSyntaxHighlightTimer
// ------------------------------------------------------
{
    if (![self canHighlight]) { return; }
    
    NSTimeInterval interval = [[NSUserDefaults standardUserDefaults] doubleForKey:CEDefaultBasicColoringDelayKey];
    if ([[self syntaxHighlightTimer] isValid]) {
        [[self syntaxHighlightTimer] setFireDate:[NSDate dateWithTimeIntervalSinceNow:interval]];
    } else {
        [self setSyntaxHighlightTimer:[NSTimer scheduledTimerWithTimeInterval:interval
                                                                       target:self
                                                                     selector:@selector(updateSyntaxHighlightWithTimer:)
                                                                     userInfo:nil
                                                                      repeats:NO]];
    }
}


// ------------------------------------------------------
/// let parse outline after a delay
- (void)setupOutlineMenuUpdateTimer
// ------------------------------------------------------
{
    if (![self canHighlight]) { return; }
    
    NSTimeInterval interval = [[NSUserDefaults standardUserDefaults] doubleForKey:CEDefaultOutlineMenuIntervalKey];
    if ([[self outlineMenuTimer] isValid]) {
        [[self outlineMenuTimer] setFireDate:[NSDate dateWithTimeIntervalSinceNow:interval]];
    } else {
        [self setOutlineMenuTimer:[NSTimer scheduledTimerWithTimeInterval:interval
                                                                   target:self
                                                                 selector:@selector(updateOutlineMenuWithTimer:)
                                                                 userInfo:nil
                                                                  repeats:NO]];
    }
}


#pragma mark Action Messages

// ------------------------------------------------------
/// ドキュメント全体を再カラーリング
- (IBAction)recolorAll:(nullable id)sender
// ------------------------------------------------------
{
    [self invalidateSyntaxHighlight];
}


#pragma mark Private Methods

// ------------------------------------------------------
/// シンタックススタイル名をセット
- (void)didChangeSyntaxStyle:(NSNotification *)notification
// ------------------------------------------------------
{
    CESyntaxStyle *syntaxStyle = [[self document] syntaxStyle];
    [[self splitViewController] enumerateEditorViewsUsingBlock:^(CEEditorViewController * _Nonnull viewController) {
        [viewController applySyntax:syntaxStyle];
    }];
    
    [[[self windowController] toolbarController] setSelectedSyntaxWithName:[syntaxStyle styleName]];
    
    [self invalidateSyntaxHighlight];
    [self invalidateOutlineMenu];
}


// ------------------------------------------------------
/// update syntax highlight around edited area
- (void)invalidateSyntaxHighlightPartly
// ------------------------------------------------------
{
    if ([[self syntaxHighlightTimer] isValid]) { return; }
    
    NSTextView *textView = [self focusedTextView];
    NSRange glyphRange = [[textView layoutManager] glyphRangeForBoundingRectWithoutAdditionalLayout:[textView visibleRect]
                                                                                    inTextContainer:[textView textContainer]];
    NSRange visibleRange = [[textView layoutManager] characterRangeForGlyphRange:glyphRange
                                                                actualGlyphRange:NULL];
    NSRange selectedRange = [textView selectedRange];
    NSRange updateRange = visibleRange;
    
    // 選択領域（編集場所）が見えないときは編集場所周辺を更新
    if (!NSLocationInRange(selectedRange.location, visibleRange)) {
        NSUInteger location = MAX((NSInteger)(selectedRange.location - visibleRange.length), 0);
        NSInteger maxLength = [[textView string] length] - location;
        NSUInteger length = MIN(selectedRange.length + visibleRange.length, maxLength);
        
        updateRange = NSMakeRange(location, length);
    }
    
    [[self syntaxStyle] highlightRange:updateRange textStorage:[textView textStorage]];
}


// ------------------------------------------------------
/// タイマーの設定時刻に到達、カラーリング実行
- (void)updateSyntaxHighlightWithTimer:(nonnull NSTimer *)timer
// ------------------------------------------------------
{
    [[self syntaxHighlightTimer] invalidate];
    [self invalidateSyntaxHighlightPartly];
}


// ------------------------------------------------------
/// アウトラインメニュー更新
- (void)updateOutlineMenuWithTimer:(nonnull NSTimer *)timer
// ------------------------------------------------------
{
    [self invalidateOutlineMenu];  // (The outlineMenuTimer will be invalidated in this invalidateOutlineMenu method.)
}

@end




#pragma mark -

@implementation CEEditorWrapper (Locating)

#pragma mark Action Messages

// ------------------------------------------------------
/// show Go To sheet
- (IBAction)gotoLocation:(nullable id)sender
// ------------------------------------------------------
{
    CEGoToSheetController *sheetController = [[CEGoToSheetController alloc] init];
    [sheetController beginSheetForEditor:self];
}



#pragma mark Public Methods

// ------------------------------------------------------
/// convert minus location/length to NSRange
- (NSRange)rangeWithLocation:(NSInteger)location length:(NSInteger)length
// ------------------------------------------------------
{
    NSString *documentString = [[self string] stringByReplacingNewLineCharacersWith:[[self document] lineEnding]];
    
    return [documentString rangeForLocation:location length:length];
}


// ------------------------------------------------------
/// editor 内部の textView で指定された部分を文字単位で選択
- (void)setSelectedCharacterRangeWithLocation:(NSInteger)location length:(NSInteger)length
// ------------------------------------------------------
{
    NSRange range = [self rangeWithLocation:location length:length];
    
    if (range.location == NSNotFound) { return; }
    
    [self setSelectedRange:range];
}


// ------------------------------------------------------
/// editor 内部の textView で指定された部分を行単位で選択
- (void)setSelectedLineRangeWithLocation:(NSInteger)location length:(NSInteger)length
// ------------------------------------------------------
{
    // you can ignore actuall line ending type and directly comunicate with textView, as this handle just lines
    NSTextView *textView = [self focusedTextView];
    
    NSRange range = [[textView string] rangeForLineLocation:location length:length];
    
    if (range.location == NSNotFound) { return; }
    
    [textView setSelectedRange:range];
}


// ------------------------------------------------------
/// 選択範囲を変更する
- (void)gotoLocation:(NSInteger)location length:(NSInteger)length type:(CEGoToType)type
// ------------------------------------------------------
{
    switch (type) {
        case CEGoToLine:
            [self setSelectedLineRangeWithLocation:location length:length];
            break;
        case CEGoToCharacter:
            [self setSelectedCharacterRangeWithLocation:location length:length];
            break;
    }
    
    NSTextView *textView = [self focusedTextView];
    [[textView window] makeKeyAndOrderFront:self]; // 対象ウィンドウをキーに
    [textView scrollRangeToVisible:[textView selectedRange]]; // 選択範囲が見えるようにスクロール
    [textView showFindIndicatorForRange:[textView selectedRange]];  // 検索結果表示エフェクトを追加
}

@end
