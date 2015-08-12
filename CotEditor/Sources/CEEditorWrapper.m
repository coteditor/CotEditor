/*
 
 CEEditorWrapper.m
 
 CotEditor
 http://coteditor.com
 
 Created by nakamuxu on 2004-12-08.
 
 ------------
 This class is based on JSDTextView (written by James S. Derry – http://www.balthisar.com)
 JSDTextView is released as public domain.
 arranged by nakamuxu, Dec 2004.
 
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

#import "CEEditorWrapper.h"
#import "CEDocument.h"
#import "CEEditorView.h"
#import "CEWindowController.h"
#import "CESplitViewController.h"
#import "CENavigationBarController.h"
#import "CESyntaxParser.h"
#import "CEGoToSheetController.h"
#import "Constants.h"


@interface CEEditorWrapper ()

@property (nonatomic, nullable) NSTimer *coloringTimer;
@property (nonatomic, nullable) NSTimer *outlineMenuTimer;

@property (nonatomic, nullable) IBOutlet CESplitViewController *splitViewController;


// readonly
@property (readwrite, nonatomic) CESyntaxParser *syntaxParser;
@property (readwrite, nonatomic) BOOL canActivateShowInvisibles;

@end




#pragma -

@implementation CEEditorWrapper

static NSTimeInterval basicColoringDelay;
static NSTimeInterval firstColoringDelay;
static NSTimeInterval secondColoringDelay;


#pragma mark Sperclass Methods

// ------------------------------------------------------
/// initialize class
+ (void)initialize
// ------------------------------------------------------
{
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
        
        basicColoringDelay = [defaults doubleForKey:CEDefaultBasicColoringDelayKey];
        firstColoringDelay = [defaults doubleForKey:CEDefaultFirstColoringDelayKey];
        secondColoringDelay = [defaults doubleForKey:CEDefaultSecondColoringDelayKey];
    });
}


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
    }
    return self;
}


// ------------------------------------------------------
/// clean up
- (void)dealloc
// ------------------------------------------------------
{
    [self stopColoringTimer];
    [self stopUpdateOutlineMenuTimer];
    
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
    
    CEEditorView *editorView = [[[[self splitViewController] view] subviews] firstObject];
    [editorView setEditorWrapper:self];
    [self setFocusedTextView:[editorView textView]];
    
    [self setupViewParamsOnInit:YES];
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
        if ([self isVerticalLayoutOrientation]) {
            return NO;
        }
        
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
            [menuItem setToolTip:NSLocalizedString(@"To display invisible characters, set them in Preferences and re-open the document.", nil)];
        }
        
        return [self canActivateShowInvisibles];
        
    } else if ([menuItem action] == @selector(toggleAutoTabExpand:)) {
        state = [[self focusedTextView] isAutoTabExpandEnabled] ? NSOnState : NSOffState;
        
    } else if ([menuItem action] == @selector(selectPrevItemOftimerMenu:)) {
        return ([[self navigationBar] canSelectPrevItem]);
    } else if ([menuItem action] == @selector(selectNextItemOfOutlineMenu:)) {
        return ([[self navigationBar] canSelectNextItem]);
        
    } else if ([menuItem action] == @selector(closeSplitTextView:)) {
        return ([[[[self splitViewController] view] subviews] count] > 1);
    }
    
    if (title) {
        [menuItem setTitle:NSLocalizedString(title, nil)];
    } else {
        [menuItem setState:state];
    }
    
    return YES;
}



#pragma mark Public Methods

// ------------------------------------------------------
/// メインtextViewの文字列を返す（改行コードはLF固定）
- (NSString *)string
// ------------------------------------------------------
{
    return [[self focusedTextView] string];
}


// ------------------------------------------------------
/// メインtextViewの指定された範囲の文字列を返す
- (NSString *)substringWithRange:(NSRange)range
// ------------------------------------------------------
{
    return [[self string] substringWithRange:range];
}


// ------------------------------------------------------
/// メインtextViewの選択された文字列を返す
- (NSString *)substringWithSelection
// ------------------------------------------------------
{
    return [[self string] substringWithRange:[[self focusedTextView] selectedRange]];
}


// ------------------------------------------------------
/// メインtextViewの選択された文字列を、改行コードを指定のものに置換して返す
- (NSString *)substringWithSelectionForSave
// ------------------------------------------------------
{
    return [[self substringWithSelection] stringByReplacingNewLineCharacersWith:[[self document] lineEnding]];
}


// ------------------------------------------------------
/// メインtextViewに文字列をセット
- (void)setString:(NSString *)string
// ------------------------------------------------------
{
    // UTF-16 でないものを UTF-16 で表示した時など当該フォントで表示できない文字が表示されてしまった後だと、
    // 設定されたフォントでないもので表示されることがあるため、リセットする
    NSDictionary *attributes = [[self focusedTextView] typingAttributes];
    NSAttributedString *attrString = [[NSAttributedString alloc] initWithString:string attributes:attributes];
    
    [[[self focusedTextView] textStorage] setAttributedString:attrString];
    
    // キャレットを先頭に移動
    if ([string length] > 0) {
        [[self splitViewController] enumerateEditorViewsUsingBlock:^(CEEditorView *editorView) {
            [editorView setCaretToBeginning];
        }];
    }
}


// ------------------------------------------------------
/// 選択文字列を置換する
- (void)insertTextViewString:(NSString *)string
// ------------------------------------------------------
{
    [[self focusedTextView] insertString:string];
}


// ------------------------------------------------------
/// 選択範囲の直後に文字列を挿入
- (void)insertTextViewStringAfterSelection:(NSString *)string
// ------------------------------------------------------
{
    [[self focusedTextView] insertStringAfterSelection:string];
}


// ------------------------------------------------------
/// 全文字列を置換
- (void)replaceTextViewAllStringWithString:(NSString *)string
// ------------------------------------------------------
{
    [[self focusedTextView] replaceAllStringWithString:string];
}


// ------------------------------------------------------
/// 文字列の最後に新たな文字列を追加
- (void)appendTextViewString:(NSString *)string
// ------------------------------------------------------
{
    [[self focusedTextView] appendString:string];
}


// ------------------------------------------------------
/// 選択範囲を返す
- (NSRange)selectedRange
// ------------------------------------------------------
{
    return [self documentRangeFromRange:[[self focusedTextView] selectedRange]];
}


// ------------------------------------------------------
/// 選択範囲を変更
- (void)setSelectedRange:(NSRange)charRange
// ------------------------------------------------------
{
    [[self focusedTextView] setSelectedRange:[self rangeFromDocumentRange:charRange]];
}


// ------------------------------------------------------
/// 現在のエンコードにコンバートできない文字列をマークアップ
- (void)markupRanges:(NSArray *)ranges
// ------------------------------------------------------
{
    NSColor *color = [[[self focusedTextView] theme] markupColor];
    NSArray *layoutManagers = [self layoutManagers];
    
    for (NSValue *rangeValue in ranges) {
        NSRange documentRange = [rangeValue rangeValue];
        NSRange range = [self rangeFromDocumentRange:documentRange];
        
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
    NSArray *managers = [self layoutManagers];
    
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
/// ナビゲーションバーを表示する／しないをセット
- (void)setShowsNavigationBar:(BOOL)showsNavigationBar animate:(BOOL)performAnimation
// ------------------------------------------------------
{
    _showsNavigationBar = showsNavigationBar;
    
    [[self splitViewController] enumerateEditorViewsUsingBlock:^(CEEditorView *editorView) {
        [editorView setShowsNavigationBar:showsNavigationBar animate:performAnimation];
    }];
    [[[self windowController] toolbarController] toggleItemWithTag:CEToolbarShowNavigationBarItemTag
                                                             setOn:showsNavigationBar];
    
    if (showsNavigationBar && ![self outlineMenuTimer]) {
        [self invalidateOutlineMenu];
    }
}


// ------------------------------------------------------
/// 行番号の表示をする／しないをセット
- (void)setShowsLineNum:(BOOL)showsLineNum
// ------------------------------------------------------
{
    _showsLineNum = showsLineNum;
    
    [[self splitViewController] enumerateEditorViewsUsingBlock:^(CEEditorView *editorView) {
        [editorView setShowsLineNum:showsLineNum];
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
    
    [[self splitViewController] enumerateEditorViewsUsingBlock:^(CEEditorView *editorView) {
        [editorView setWrapsLines:wrapsLines];
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
    
    [[self splitViewController] enumerateEditorViewsUsingBlock:^(CEEditorView *editorView) {
        [[editorView textView] setLayoutOrientation:orientation];
    }];
    [[[self windowController] toolbarController] toggleItemWithTag:CEToolbarTextOrientationItemTag
                                                             setOn:isVerticalLayoutOrientation];
}


// ------------------------------------------------------
/// フォントを返す
- (NSFont *)font
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
- (void)setThemeWithName:(NSString *)themeName
// ------------------------------------------------------
{
    if ([themeName length] == 0) { return; }
    
    CETheme *theme = [CETheme themeWithName:themeName];
    
    [[self splitViewController] enumerateEditorViewsUsingBlock:^(CEEditorView *editorView) {
        [[editorView textView] setTheme:theme];
    }];
    
    [[self syntaxParser] colorWholeStringInTextStorage:[self textStorage]];
}


// ------------------------------------------------------
/// 現在のテーマを返す
- (CETheme *)theme
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
    
    [[self splitViewController] enumerateEditorViewsUsingBlock:^(CEEditorView *editorView) {
        [[editorView textView] setShowsPageGuide:showsPageGuide];
        [[editorView textView] setNeedsDisplayInRect:[[editorView textView] visibleRect] avoidAdditionalLayout:YES];
    }];
    [[[self windowController] toolbarController] toggleItemWithTag:CEToolbarShowPageGuideItemTag
                                                             setOn:showsPageGuide];
}


// ------------------------------------------------------
/// シンタックススタイル名を返す
- (NSString *)syntaxStyleName
// ------------------------------------------------------
{
    return [[self syntaxParser] styleName];
}


// ------------------------------------------------------
/// シンタックススタイル名をセット
- (void)setSyntaxStyleWithName:(NSString *)name coloring:(BOOL)doColoring
// ------------------------------------------------------
{
    CESyntaxParser *syntaxParser = [[CESyntaxParser alloc] initWithStyleName:name];
    [self setSyntaxParser:syntaxParser];
    [[self splitViewController] enumerateEditorViewsUsingBlock:^(CEEditorView *editorView) {
        [editorView applySyntax:syntaxParser];
    }];
    
    if (doColoring) {
        [self invalidateSyntaxColoring];
        [self invalidateOutlineMenu];
    }
}


// ------------------------------------------------------
/// 全テキストを再カラーリング
- (void)invalidateSyntaxColoring
// ------------------------------------------------------
{
    [self stopColoringTimer];
    
    [[self syntaxParser] colorWholeStringInTextStorage:[self textStorage]];
}


// ------------------------------------------------------
/// アウトラインメニューを更新
- (void)invalidateOutlineMenu
// ------------------------------------------------------
{
    [self stopUpdateOutlineMenuTimer];
    
    NSString *wholeString = [[self textStorage] string] ? : @"";
    
    // 規定の文字数以上の場合にはインジケータを表示
    // （ただし、CEDefaultShowColoringIndicatorTextLengthKey が「0」の時は表示しない）
    NSUInteger indicatorThreshold = [[NSUserDefaults standardUserDefaults] integerForKey:CEDefaultShowColoringIndicatorTextLengthKey];
    if (indicatorThreshold > 0 && indicatorThreshold < [wholeString length]) {
        [[self splitViewController] enumerateEditorViewsUsingBlock:^(CEEditorView *editorView) {
            [[editorView navigationBar] showOutlineIndicator];
        }];
    }
    
    NSString *immutableWholeString = [NSString stringWithString:wholeString];  // 解析中に参照元が変更されると困るのでコピーする
    
    // 別スレッドでアウトラインを抽出して、メインスレッドで navigationBar に渡す
    CESyntaxParser *syntaxParser = [self syntaxParser];
    CESplitViewController *splitViewController = [self splitViewController];
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        NSArray *outlineItems = [syntaxParser outlineItemsWithWholeString:immutableWholeString];
        
        dispatch_sync(dispatch_get_main_queue(), ^{
            [splitViewController enumerateEditorViewsUsingBlock:^(CEEditorView *editorView) {
                [[editorView navigationBar] setOutlineItems:outlineItems];
                // （選択項目の更新も上記メソッド内で行われるので、updateOutlineMenuSelection は呼ぶ必要なし。 2008.05.16.）
            }];
        });
    });
}


// ------------------------------------------------------
/// 不可視文字の表示／非表示を返す
- (BOOL)showsInvisibles
// ------------------------------------------------------
{
    return [(CELayoutManager *)[[self focusedTextView] layoutManager] showsInvisibles];
}


// ------------------------------------------------------
/// 不可視文字の表示／非表示を設定
- (void)setShowsInvisibles:(BOOL)showsInvisibles
// ------------------------------------------------------
{
    [[self splitViewController] enumerateEditorViewsUsingBlock:^(CEEditorView *editorView) {
        [editorView setShowsInvisibles:showsInvisibles];
    }];
}


// ------------------------------------------------------
/// カラーリングタイマーのファイヤーデイトを設定時間後にセット
- (void)setupColoringTimer
// ------------------------------------------------------
{
    if ([[self syntaxParser] isNone]) { return; }
    
    BOOL delay = [[NSUserDefaults standardUserDefaults] boolForKey:CEDefaultDelayColoringKey];
    
    if ([self coloringTimer]) {
        NSTimeInterval interval = delay ? secondColoringDelay : basicColoringDelay;
        [[self coloringTimer] setFireDate:[NSDate dateWithTimeIntervalSinceNow:interval]];
        
    } else {
        NSTimeInterval interval = delay ? firstColoringDelay : basicColoringDelay;
        [self setColoringTimer:[NSTimer scheduledTimerWithTimeInterval:interval
                                                                target:self
                                                              selector:@selector(doColoringWithTimer:)
                                                              userInfo:nil repeats:NO]];
    }
}


// ------------------------------------------------------
/// アウトラインメニュー項目を更新
- (void)setupOutlineMenuUpdateTimer
// ------------------------------------------------------
{
    // アウトラインメニュー項目更新
    NSTimeInterval outlineMenuInterval = [[NSUserDefaults standardUserDefaults] doubleForKey:CEDefaultOutlineMenuIntervalKey];
    if ([self outlineMenuTimer]) {
        [[self outlineMenuTimer] setFireDate:[NSDate dateWithTimeIntervalSinceNow:outlineMenuInterval]];
    } else {
        [self setOutlineMenuTimer:[NSTimer scheduledTimerWithTimeInterval:outlineMenuInterval
                                                                   target:self
                                                                 selector:@selector(updateOutlineMenuWithTimer:)
                                                                 userInfo:nil
                                                                  repeats:NO]];
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
    
    [[self splitViewController] enumerateEditorViewsUsingBlock:^(CEEditorView *editorView) {
        [editorView setUsesAntialias:usesAntialias];
    }];
}


// ------------------------------------------------------
/// 不可視文字表示をトグルに切り替える
- (IBAction)toggleInvisibleChars:(nullable id)sender
// ------------------------------------------------------
{
    BOOL showsInvisibles = ![(CELayoutManager *)[[self focusedTextView] layoutManager] showsInvisibles];
    
    [[self splitViewController] enumerateEditorViewsUsingBlock:^(CEEditorView *editorView) {
        [editorView setShowsInvisibles:showsInvisibles];
    }];
    [[[self windowController] toolbarController] toggleItemWithTag:CEToolbarShowInvisibleCharsItemTag
                                                             setOn:showsInvisibles];
}


// ------------------------------------------------------
/// ソフトタブの有効／無効をトグルに切り替える
- (IBAction)toggleAutoTabExpand:(nullable id)sender
// ------------------------------------------------------
{
    BOOL isEnabled = ![[self focusedTextView] isAutoTabExpandEnabled];
    
    [[self splitViewController] enumerateEditorViewsUsingBlock:^(CEEditorView *editorView) {
        [[editorView textView] setAutoTabExpandEnabled:isEnabled];
    }];
    [[[self windowController] toolbarController] toggleItemWithTag:CEToolbarAutoTabExpandItemTag
                                                             setOn:isEnabled];
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
    [[self navigationBar] selectPrevItem:sender];
}


// ------------------------------------------------------
/// アウトラインメニューの次の項目を選択（メニューバーからのアクションを中継）
- (IBAction)selectNextItemOfOutlineMenu:(nullable id)sender
// ------------------------------------------------------
{
    [[self navigationBar] selectNextItem:sender];
}


// ------------------------------------------------------
/// テキストビュー分割を行う
- (IBAction)openSplitTextView:(nullable id)sender
// ------------------------------------------------------
{
    CEEditorView *currentEditorView;
    
    // find CEEditorView to base
    id view = [sender isMemberOfClass:[NSMenuItem class]] ? [[self window] firstResponder] : sender;
    while (view) {
        if ([view isKindOfClass:[CEEditorView class]]) {
            currentEditorView = (CEEditorView *)view;
            break;
        }
        view = [view superview];
    }
    
    if (!currentEditorView) { return; }
    
    // end current editing
    [[self class] endCurrentEditing];
    
    CEEditorView *newEditorView = [[CEEditorView alloc] initWithFrame:[currentEditorView frame]];

    [newEditorView replaceTextStorage:[self textStorage]];
    [newEditorView setEditorWrapper:self];
    
    // instert new editorView just below the editorView that the pressed button belongs to or has focus
    [[[self splitViewController] view] addSubview:newEditorView
                                       positioned:NSWindowAbove
                                       relativeTo:currentEditorView];
    
    // apply current status to the new editorView
    [self setupViewParamsOnInit:NO];
    [[newEditorView textView] setFont:[[currentEditorView textView] font]];
    [[newEditorView textView] setTheme:[[currentEditorView textView] theme]];
    [[newEditorView textView] setLineSpacing:[[currentEditorView textView] lineSpacing]];
    [[newEditorView textView] setSelectedRange:[[currentEditorView textView] selectedRange]];
    
    [newEditorView applySyntax:[self syntaxParser]];
    [self invalidateSyntaxColoring];
    [self invalidateOutlineMenu];
    
    // move focus to the new editor
    [[self window] makeFirstResponder:[newEditorView textView]];
    
    // adjust visible areas
    [[currentEditorView textView] centerSelectionInVisibleArea:self];
    [[newEditorView textView] centerSelectionInVisibleArea:self];
    
    // update split buttons state
    [[self splitViewController] updateCloseSplitViewButton];
}


// ------------------------------------------------------
//// 分割されたテキストビューを閉じる
- (IBAction)closeSplitTextView:(nullable id)sender
// ------------------------------------------------------
{
    CEEditorView *editorViewToClose;
    
    // find CEEditorView to close
    id view = [sender isMemberOfClass:[NSMenuItem class]] ? [[self window] firstResponder] : sender;
    while (view) {
        if ([view isKindOfClass:[CEEditorView class]]) {
            editorViewToClose = (CEEditorView *)view;
            break;
        }
        view = [view superview];
    }
    
    if (!editorViewToClose) { return; }
    
    // end current editing
    [[self class] endCurrentEditing];
    
    // move focus to the next text view if the view to close has a focus
    if ([[self window] firstResponder] == [editorViewToClose textView]) {
        NSArray *subViews = [[[self splitViewController] view] subviews];
        NSUInteger count = [subViews count];
        NSUInteger deleteIndex = [subViews indexOfObject:editorViewToClose];
        NSUInteger index = deleteIndex + 1;
        if (index >= count) {
            index = count - 2;
        }
        [[self window] makeFirstResponder:[subViews[index] textView]];
    }
    
    // close
    [editorViewToClose removeFromSuperview];
    
    // update split buttons state
    [[self splitViewController] updateCloseSplitViewButton];
}


// ------------------------------------------------------
/// ドキュメント全体を再カラーリング
- (IBAction)recolorAll:(nullable id)sender
// ------------------------------------------------------
{
    [self invalidateSyntaxColoring];
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
- (void)setupViewParamsOnInit:(BOOL)isInitial
// ------------------------------------------------------
{
    if (isInitial) {
        NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
        
        [self setShowsInvisibles:[defaults boolForKey:CEDefaultShowInvisiblesKey]];
        [self setShowsLineNum:[defaults boolForKey:CEDefaultShowLineNumbersKey]];
        [self setShowsNavigationBar:[defaults boolForKey:CEDefaultShowNavigationBarKey] animate:NO];
        [self setWrapsLines:[defaults boolForKey:CEDefaultWrapLinesKey]];
        [self setVerticalLayoutOrientation:[defaults boolForKey:CEDefaultLayoutTextVerticalKey]];
        [self setShowsPageGuide:[defaults boolForKey:CEDefaultShowPageGuideKey]];
    } else {
        [self setShowsInvisibles:[self showsInvisibles]];
        [self setShowsLineNum:[self showsLineNum]];
        [self setShowsNavigationBar:[self showsNavigationBar] animate:NO];
        [self setWrapsLines:[self wrapsLines]];
        [self setVerticalLayoutOrientation:[self isVerticalLayoutOrientation]];
        [self setShowsPageGuide:[self showsPageGuide]];
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
- (NSArray *)layoutManagers
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
- (CENavigationBarController *)navigationBar
// ------------------------------------------------------
{
    return [(CEEditorView *)[[self focusedTextView] delegate] navigationBar];
}


// ------------------------------------------------------
/// sanitized range for text view
- (NSRange)rangeFromDocumentRange:(NSRange)range
// ------------------------------------------------------
{
    if ([[self document] lineEnding] != CENewLineCRLF) {
        return range;
    }
    
    // sanitize for CR/LF
    NSString *tmpLocStr = [[[self document] stringForSave] substringToIndex:range.location];
    NSString *tmpLenStr = [[[self document] stringForSave] substringWithRange:range];
    NSString *locStr = [tmpLocStr stringByReplacingNewLineCharacersWith:CENewLineLF];
    NSString *lenStr = [tmpLenStr stringByReplacingNewLineCharacersWith:CENewLineLF];
    
    return NSMakeRange([locStr length], [lenStr length]);
}


// ------------------------------------------------------
/// sanitized range for document
- (NSRange)documentRangeFromRange:(NSRange)range
// ------------------------------------------------------
{
    if ([[self document] lineEnding] != CENewLineCRLF) {
        return range;
    }
    
    // sanitize for CR/LF
    NSString *tmpLocStr = [[self string] substringToIndex:range.location];
    NSString *tmpLenStr = [[self string] substringWithRange:range];
    NSString *locStr = [tmpLocStr stringByReplacingNewLineCharacersWith:[[self document] lineEnding]];
    NSString *lenStr = [tmpLenStr stringByReplacingNewLineCharacersWith:[[self document] lineEnding]];
    
    return NSMakeRange([locStr length], [lenStr length]);
}


// ------------------------------------------------------
/// カラーリング実行
- (void)doColoringNow
// ------------------------------------------------------
{
    if ([self coloringTimer]) { return; }
    
    NSTextView *textView = [self focusedTextView];
    NSRange glyphRange = [[textView layoutManager] glyphRangeForBoundingRect:[textView visibleRect]
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
    
    [[self syntaxParser] colorRange:updateRange
                        textStorage:[textView textStorage]];
}


// ------------------------------------------------------
/// タイマーの設定時刻に到達、カラーリング実行
- (void)doColoringWithTimer:(nonnull NSTimer *)timer
// ------------------------------------------------------
{
    [self stopColoringTimer];
    [self doColoringNow];
}


// ------------------------------------------------------
/// カラーリング更新タイマーを停止
- (void)stopColoringTimer
// ------------------------------------------------------
{
    if ([self coloringTimer]) {
        [[self coloringTimer] invalidate];
        [self setColoringTimer:nil];
    }
}


// ------------------------------------------------------
/// アウトラインメニュー更新
- (void)updateOutlineMenuWithTimer:(nonnull NSTimer *)timer
// ------------------------------------------------------
{
    [self invalidateOutlineMenu]; // （invalidateOutlineMenu 内で stopUpdateOutlineMenuTimer を実行している）
}


// ------------------------------------------------------
/// アウトラインメニュー更新タイマーを停止
- (void)stopUpdateOutlineMenuTimer
// ------------------------------------------------------
{
    if ([self outlineMenuTimer]) {
        [[self outlineMenuTimer] invalidate];
        [self setOutlineMenuTimer:nil];
    }
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
    NSTextView *textView = [self focusedTextView];
    NSUInteger wholeLength = [[textView string] length];
    NSRange range = NSMakeRange(0, 0);
    
    NSInteger newLocation = (location < 0) ? (wholeLength + location) : location;
    NSInteger newLength = (length < 0) ? (wholeLength - newLocation + length) : length;
    if ((newLocation < wholeLength) && ((newLocation + newLength) > wholeLength)) {
        newLength = wholeLength - newLocation;
    }
    if ((length < 0) && (newLength < 0)) {
        newLength = 0;
    }
    if ((newLocation < 0) || (newLength < 0)) {
        return range;
    }
    range = NSMakeRange(newLocation, newLength);
    if (wholeLength >= NSMaxRange(range)) {
        return range;
    }
    return range;
}


// ------------------------------------------------------
/// editor 内部の textView で指定された部分を文字単位で選択
- (void)setSelectedCharacterRangeWithLocation:(NSInteger)location length:(NSInteger)length
// ------------------------------------------------------
{
    NSRange selectionRange = [self rangeWithLocation:location length:length];
    
    [self setSelectedRange:selectionRange];
}


// ------------------------------------------------------
/// editor 内部の textView で指定された部分を行単位で選択
- (void)setSelectedLineRangeWithLocation:(NSInteger)location length:(NSInteger)length
// ------------------------------------------------------
{
    NSTextView *textView = [self focusedTextView];
    NSUInteger wholeLength = [[textView string] length];
    NSRegularExpression *regex = [NSRegularExpression regularExpressionWithPattern:@"^"
                                                                           options:NSRegularExpressionAnchorsMatchLines
                                                                             error:nil];
    NSArray *matches = [regex matchesInString:[textView string] options:0
                                        range:NSMakeRange(0, wholeLength)];
    NSInteger count = [matches count];
    
    if (count == 0) { return; }
    
    if (location == 0) {
        [textView setSelectedRange:NSMakeRange(0, 0)];
        
    } else if (location > count) {
        [textView setSelectedRange:NSMakeRange(wholeLength, 0)];
        
    } else {
        NSInteger newLocation, newLength;
        
        newLocation = (location < 0) ? (count + location + 1) : location;
        if (length < 0) {
            newLength = count - newLocation + length + 1;
        } else if (length == 0) {
            newLength = 1;
        } else {
            newLength = length;
        }
        if ((newLocation < count) && ((newLocation + newLength - 1) > count)) {
            newLength = count - newLocation + 1;
        }
        if ((length < 0) && (newLength < 0)) {
            newLength = 1;
        }
        if ((newLocation <= 0) || (newLength <= 0)) { return; }
        
        NSTextCheckingResult *match = matches[(newLocation - 1)];
        NSRange range = [match range];
        NSRange tmpRange = range;
        
        for (NSInteger i = 0; i < newLength; i++) {
            if (NSMaxRange(tmpRange) > wholeLength) {
                break;
            }
            range = [[textView string] lineRangeForRange:tmpRange];
            tmpRange.length = range.length + 1;
        }
        if (wholeLength < NSMaxRange(range)) {
            range.length = wholeLength - range.location;
        }
        [textView setSelectedRange:range];
    }
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
