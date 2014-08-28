/*
 ==============================================================================
 CEEditorWrapper
 
 CotEditor
 http://coteditor.github.io
 
 Created on 2004-12-08 by nakamuxu
 encoding="UTF-8"
 
 ------------
 This class is based on JSDTextView (written by James S. Derry – http://www.balthisar.com)
 JSDTextView is released as public domain.
 arranged by nakamuxu, Dec 2004.
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

#import "CEEditorWrapper.h"
#import "CESplitViewController.h"
#import "CENavigationBarController.h"
#import "CELineNumberView.h"
#import "CESyntaxParser.h"
#import "constants.h"


@interface CEEditorWrapper ()

@property (nonatomic) NSTimer *coloringTimer;

@property (nonatomic) IBOutlet CESplitViewController *splitViewController;


// readonly
@property (readwrite, nonatomic) BOOL canActivateShowInvisibles;

@end




#pragma -

@implementation CEEditorWrapper

static NSTimeInterval basicColoringDelay;
static NSTimeInterval firstColoringDelay;
static NSTimeInterval secondColoringDelay;


#pragma mark Class Methods

//=======================================================
// Class method
//
//=======================================================

// ------------------------------------------------------
/// クラス初期化
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



#pragma mark Sperclass Methods

//=======================================================
// Sperclass method
//
//=======================================================

// ------------------------------------------------------
/// 初期化
- (instancetype)init
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
/// Nibファイル読み込み直後
- (void)awakeFromNib
// ------------------------------------------------------
{
    [[self window] setNextResponder:self];
    
    // Yosemite 未満の場合は手動で Responder Chain に入れる
    // （Yosemite 以降は自動的に追加されるためか以下の一行が入るとハングしてしまう）
    if (NSAppKitVersionNumber <= NSAppKitVersionNumber10_9) {
        [self setNextResponder:[self splitViewController]];
    }
    
    CEEditorView *editorView = [[[self splitViewController] view] subviews][0];
    [editorView setEditorWrapper:self];
    [self setTextView:[editorView textView]];
    
    [self setupViewParamsInInit:YES];
    [self setShowsInvisibles:[self canActivateShowInvisibles]];
}


// ------------------------------------------------------
/// 後片付け
- (void)dealloc
// ------------------------------------------------------
{
    [self stopColoringTimer];
    [self setTextView:nil];
}



#pragma mark Public Methods

//=======================================================
// Public method
//
//=======================================================

// ------------------------------------------------------
/// documentを返す
- (CEDocument *)document
// ------------------------------------------------------
{
    return [[self windowController] document];
}


// ------------------------------------------------------
/// windowControllerを返す
- (CEWindowController *)windowController
// ------------------------------------------------------
{
    return [[self window] windowController];
}


// ------------------------------------------------------
/// textStorageを返す
- (NSTextStorage *)textStorage
// ------------------------------------------------------
{
    return [[self textView] textStorage];
}


// ------------------------------------------------------
/// メインtextViewの文字列を返す（改行コードはLF固定）
- (NSString *)string
// ------------------------------------------------------
{
    return [[self textView] string];
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
    return [[self string] substringWithRange:[[self textView] selectedRange]];
}


// ------------------------------------------------------
/// メインtextViewの選択された文字列を、改行コードを指定のものに置換して返す
- (NSString *)substringWithSelectionForSave
// ------------------------------------------------------
{
    return [OGRegularExpression replaceNewlineCharactersInString:[self substringWithSelection]
                                                   withCharacter:[[self document] lineEnding]];
}


// ------------------------------------------------------
/// メインtextViewに文字列をセット。改行コードはLFに置換される
- (void)setString:(NSString *)string
// ------------------------------------------------------
{
    // UTF-16 でないものを UTF-16 で表示した時など当該フォントで表示できない文字が表示されてしまった後だと、
    // 設定されたフォントでないもので表示されることがあるため、リセットする
    [[self textView] setString:@""];
    [[self textView] applyTypingAttributes];
    [[self textView] setString:string];
    
    // キャレットを先頭に移動
    if ([string length] > 0) {
        [[self splitViewController] moveAllCaretToBeginning];
    }
}


// ------------------------------------------------------
/// 改行コードをセット
- (void)setLineEndingString:(NSString *)lineEndingString
// ------------------------------------------------------
{
    for (NSTextContainer *container in [[[self splitViewController] view] subviews]) {
        [(CETextView *)[container textView] setLineEndingString:lineEndingString];
    }
    
    [[self windowController] updateEncodingAndLineEndingsInfo:NO];
    [[self windowController] updateEditorStatusInfo:NO];
}


// ------------------------------------------------------
/// 選択文字列を置換する
- (void)replaceTextViewSelectedStringTo:(NSString *)string scroll:(BOOL)doScroll
// ------------------------------------------------------
{
    [[self textView] replaceSelectedStringTo:string scroll:doScroll];
}


// ------------------------------------------------------
/// 全文字列を置換
- (void)replaceTextViewAllStringTo:(NSString *)string
// ------------------------------------------------------
{
    [[self textView] replaceAllStringTo:string];
}


// ------------------------------------------------------
/// 選択範囲の直後に文字列を挿入
- (void)insertTextViewAfterSelectionStringTo:(NSString *)string
// ------------------------------------------------------
{
    [[self textView] insertAfterSelection:string];
}


// ------------------------------------------------------
/// 文字列の最後に新たな文字列を追加
- (void)appendTextViewAfterAllStringTo:(NSString *)string
// ------------------------------------------------------
{
    [[self textView] appendAllString:string];
}


// ------------------------------------------------------
/// 選択範囲を返す
- (NSRange)selectedRange
// ------------------------------------------------------
{
    if ([[[self textView] lineEndingString] length] > 1) {
        NSRange range = [[self textView] selectedRange];
        NSString *tmpLocStr = [[self string] substringWithRange:NSMakeRange(0, range.location)];
        NSString *locStr = [OGRegularExpression replaceNewlineCharactersInString:tmpLocStr
                                                                   withCharacter:[[self document] lineEnding]];
        NSString *lenStr = [self substringWithSelectionForSave];

        return NSMakeRange([locStr length], [lenStr length]);
    }
    return [[self textView] selectedRange];
}


// ------------------------------------------------------
/// 選択範囲を変更
- (void)setSelectedRange:(NSRange)charRange
// ------------------------------------------------------
{
    if ([[[self textView] lineEndingString] length] > 1) {
        NSString *tmpLocStr = [[[self document] stringForSave] substringWithRange:NSMakeRange(0, charRange.location)];
        NSString *locStr = [OGRegularExpression replaceNewlineCharactersInString:tmpLocStr
                                                                   withCharacter:OgreLfNewlineCharacter];
        NSString *tmpLenStr = [[[self document] stringForSave] substringWithRange:charRange];
        NSString *lenStr = [OGRegularExpression replaceNewlineCharactersInString:tmpLenStr
                                                                   withCharacter:OgreLfNewlineCharacter];
        [[self textView] setSelectedRange:NSMakeRange([locStr length], [lenStr length])];
    } else {
        [[self textView] setSelectedRange:charRange];
    }
}


// ------------------------------------------------------
/// フォントを返す
- (NSFont *)font
// ------------------------------------------------------
{
    return [[self textView] font];
}


// ------------------------------------------------------
/// フォントをセット
- (void)setFont:(NSFont *)font
// ------------------------------------------------------
{
    [[self textView] setFont:font];
}


// ------------------------------------------------------
/// 現在のエンコードにコンバートできない文字列をマークアップ
- (void)markupRanges:(NSArray *)ranges
// ------------------------------------------------------
{
    NSColor *color = [[[self textView] theme] markupColor];
    
    // ハイライト
    NSArray *layoutManagers = [[self splitViewController] layoutManagers];
    for (NSValue *rangeValue in ranges) {
        NSRange range = [rangeValue rangeValue];
        
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
    NSArray *managers = [[self splitViewController] layoutManagers];
    
    for (NSLayoutManager *manager in managers) {
        [manager removeTemporaryAttribute:NSBackgroundColorAttributeName
                        forCharacterRange:NSMakeRange(0, [[self string] length])];
    }
}


// ------------------------------------------------------
/// 行番号の表示をする／しないをセット
- (void)setShowsLineNum:(BOOL)showsLineNum
// ------------------------------------------------------
{
    _showsLineNum = showsLineNum;
    
    [[self splitViewController] setShowsLineNum:showsLineNum];
    [[[self windowController] toolbarController] toggleItemWithTag:CEToolbarShowLineNumItemTag
                                                             setOn:showsLineNum];
}


// ------------------------------------------------------
/// ナビバーを表示する／しないをセット
- (void)setShowsNavigationBar:(BOOL)showsNavigationBar
// ------------------------------------------------------
{
    _showsNavigationBar = showsNavigationBar;
    
    [[self splitViewController] setShowsNavigationBar:showsNavigationBar];
    [[[self windowController] toolbarController] toggleItemWithTag:CEToolbarShowNavigationBarItemTag
                                                             setOn:showsNavigationBar];
}


// ------------------------------------------------------
/// 行をラップする／しないをセット
- (void)setWrapsLines:(BOOL)wrapsLines
// ------------------------------------------------------
{
    _wrapsLines = wrapsLines;
    
    [[self splitViewController] setWrapsLines:wrapsLines];
    [[[self windowController] toolbarController] toggleItemWithTag:CEToolbarWrapLinesItemTag
                                                             setOn:wrapsLines];
}


// ------------------------------------------------------
/// 横書き／縦書きをセット
- (void)setVerticalLayoutOrientation:(BOOL)isVerticalLayoutOrientation
// ------------------------------------------------------
{
    _verticalLayoutOrientation = isVerticalLayoutOrientation;
    
    [[self splitViewController] setVerticalLayoutOrientation:isVerticalLayoutOrientation];
    [[[self windowController] toolbarController] toggleItemWithTag:CEToolbarTextOrientationItemTag
                                                             setOn:isVerticalLayoutOrientation];
}


// ------------------------------------------------------
/// アンチエイリアスでの描画の許可を得る
- (BOOL)usesAntialias
// ------------------------------------------------------
{
    CELayoutManager *manager = (CELayoutManager *)[[self textView] layoutManager];
    
    return [manager usesAntialias];
}


// ------------------------------------------------------
/// テーマを適応する
- (void)setThemeWithName:(NSString *)themeName
// ------------------------------------------------------
{
    if ([themeName length] == 0) { return; }
    
    CETheme *theme = [CETheme themeWithName:themeName];
    
    [[self splitViewController] setTheme:theme];
}


// ------------------------------------------------------
/// 現在のテーマを返す
- (CETheme *)theme
// ------------------------------------------------------
{
    return [[self textView] theme];
}


// ------------------------------------------------------
/// ページガイドを表示する／しないをセット
- (void)setShowsPageGuide:(BOOL)showsPageGuide
// ------------------------------------------------------
{
    [[self splitViewController] setShowsPageGuide:showsPageGuide];
    [[[self windowController] toolbarController] toggleItemWithTag:CEToolbarShowPageGuideItemTag
                                                             setOn:showsPageGuide];
    
    _showsPageGuide = showsPageGuide;
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
- (void)setSyntaxStyleName:(NSString *)name recolorNow:(BOOL)recolorNow
// ------------------------------------------------------
{
    if (![self syntaxParser]) { return; }
    
    [[self splitViewController] setSyntaxWithName:name];
    
    if (recolorNow) {
        [self recolorAllString];
        if ([self showsNavigationBar]) {
            [[self splitViewController] updateAllOutlineMenu];
        }
    }
}


// ------------------------------------------------------
/// 全テキストを再カラーリング
- (void)recolorAllString
// ------------------------------------------------------
{
    [self stopColoringTimer];
    [[self splitViewController] recolorAllTextView];
}


// ------------------------------------------------------
/// ディレイをかけて、全テキストを再カラーリング、アウトラインメニューを更新
- (void)updateColoringAndOutlineMenuWithDelay
// ------------------------------------------------------
{
    [self stopColoringTimer];
    
    __block CESplitViewController *splitViewController = [self splitViewController];
    dispatch_async(dispatch_get_main_queue(), ^{
        [splitViewController updateAllOutlineMenu];
        [splitViewController recolorAllTextView];
    });
}


// ------------------------------------------------------
/// 不可視文字の表示／非表示を返す
- (BOOL)showsInvisibles
// ------------------------------------------------------
{
    return [(CELayoutManager *)[[self textView] layoutManager] showsInvisibles];
}


// ------------------------------------------------------
/// 不可視文字の表示／非表示を設定
- (void)setShowsInvisibles:(BOOL)showsInvisibles
// ------------------------------------------------------
{
    [[self splitViewController] setShowsInvisibles:showsInvisibles];
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
/// 背景の不透明度をセット
- (void)setBackgroundAlpha:(CGFloat)alpha
// ------------------------------------------------------
{
    [[self splitViewController] setAllBackgroundColorWithAlpha:alpha];
}



#pragma mark Protocol

//=======================================================
// NSMenuValidation Protocol
//
//=======================================================

// ------------------------------------------------------
/// メニュー項目の有効・無効を制御
- (BOOL)validateMenuItem:(NSMenuItem *)menuItem
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
            [menuItem setToolTip:NSLocalizedString(@"To display invisible characters, set in Preferences and re-open the document.", nil)];
        }
        
        return [self canActivateShowInvisibles];
    
    } else if ([menuItem action] == @selector(toggleAutoTabExpand:)) {
        state = [[self textView] isAutoTabExpandEnabled] ? NSOnState : NSOffState;
        
    } else if ([menuItem action] == @selector(selectPrevItemOfOutlineMenu:)) {
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



#pragma mark Action Messages

//=======================================================
// Action messages
//
//=======================================================

// ------------------------------------------------------
/// 行番号表示をトグルに切り替える
- (IBAction)toggleLineNumber:(id)sender
// ------------------------------------------------------
{
    [self setShowsLineNum:![self showsLineNum]];
}


// ------------------------------------------------------
/// ナビゲーションバーの表示をトグルに切り替える
- (IBAction)toggleNavigationBar:(id)sender
// ------------------------------------------------------
{
    [self setShowsNavigationBar:![self showsNavigationBar]];
}


// ------------------------------------------------------
/// ワードラップをトグルに切り替える
- (IBAction)toggleLineWrap:(id)sender
// ------------------------------------------------------
{
    [self setWrapsLines:![self wrapsLines]];
}


// ------------------------------------------------------
/// 横書き／縦書きを切り替える
- (IBAction)toggleLayoutOrientation:(id)sender
// ------------------------------------------------------
{
    [self setVerticalLayoutOrientation:![self isVerticalLayoutOrientation]];
}


// ------------------------------------------------------
/// 文字にアンチエイリアスを使うかどうかをトグルに切り替える
- (IBAction)toggleAntialias:(id)sender
// ------------------------------------------------------
{
    CELayoutManager *manager = (CELayoutManager *)[[self textView] layoutManager];
    
    [[self splitViewController] setUsesAntialias:![manager usesAntialias]];
}


// ------------------------------------------------------
/// 不可視文字表示をトグルに切り替える
- (IBAction)toggleInvisibleChars:(id)sender
// ------------------------------------------------------
{
    BOOL showsInvisibles = [(CELayoutManager *)[[self textView] layoutManager] showsInvisibles];

    [[self splitViewController] setShowsInvisibles:!showsInvisibles];
    [[[self windowController] toolbarController] toggleItemWithTag:CEToolbarShowInvisibleCharsItemTag
                                                             setOn:!showsInvisibles];
}


// ------------------------------------------------------
/// ソフトタブの有効／無効をトグルに切り替える
- (IBAction)toggleAutoTabExpand:(id)sender
// ------------------------------------------------------
{
    BOOL isEnabled = ![[self textView] isAutoTabExpandEnabled];
    
    [[self splitViewController] setAutoTabExpandEnabled:isEnabled];
    [[[self windowController] toolbarController] toggleItemWithTag:CEToolbarAutoTabExpandItemTag
                                                             setOn:isEnabled];
}


// ------------------------------------------------------
/// ページガイド表示をトグルに切り替える
- (IBAction)togglePageGuide:(id)sender
// ------------------------------------------------------
{
    [self setShowsPageGuide:![self showsPageGuide]];
}


// ------------------------------------------------------
/// アウトラインメニューの前の項目を選択（メニューバーからのアクションを中継）
- (IBAction)selectPrevItemOfOutlineMenu:(id)sender
// ------------------------------------------------------
{
    [[self navigationBar] selectPrevItem:sender];
}


// ------------------------------------------------------
/// アウトラインメニューの次の項目を選択（メニューバーからのアクションを中継）
- (IBAction)selectNextItemOfOutlineMenu:(id)sender
// ------------------------------------------------------
{
    [[self navigationBar] selectNextItem:sender];
}


// ------------------------------------------------------
/// テキストビュー分割を行う
- (IBAction)openSplitTextView:(id)sender
// ------------------------------------------------------
{
    CEEditorView *currentEditorView;
    
    // 基準となる CEEditorView を探す
    id view = [sender isMemberOfClass:[NSMenuItem class]] ? [[self window] firstResponder] : sender;
    while (view) {
        if ([view isKindOfClass:[CEEditorView class]]) {
            currentEditorView = (CEEditorView *)view;
            break;
        }
        view = [view superview];
    }
    
    if (!currentEditorView) { return; }
    
    NSRange selectedRange = [[currentEditorView textView] selectedRange];
    CEEditorView *editorView = [[CEEditorView alloc] initWithFrame:[currentEditorView frame]];

    [editorView replaceTextStorage:[[self textView] textStorage]];
    [editorView setEditorWrapper:self];
    // 新たな subView は、押された追加ボタンが属する（またはフォーカスのある）editorView のすぐ下に挿入する
    [[[self splitViewController] view] addSubview:editorView positioned:NSWindowAbove relativeTo:currentEditorView];
    [self setupViewParamsInInit:NO];
    [[editorView textView] setFont:[[self textView] font]];
    [[editorView textView] setTheme:[self theme]];
    [[editorView textView] setLineSpacing:[[self textView] lineSpacing]];
    [self setShowsInvisibles:[(CELayoutManager *)[[self textView] layoutManager] showsInvisibles]];
    [[editorView textView] setSelectedRange:selectedRange];
    [editorView setSyntaxWithName:[[self syntaxParser] styleName]];
    [[editorView syntaxParser] colorAllString:[self string]];
    [[self textView] centerSelectionInVisibleArea:self];
    [[self window] makeFirstResponder:[editorView textView]];
    [[editorView textView] setLineEndingString:[[self document] lineEndingString]];
    [[editorView textView] centerSelectionInVisibleArea:self];
    [editorView setShowsNavigationBar:[self showsNavigationBar]];
    [[self splitViewController] updateCloseSplitViewButton];
}


// ------------------------------------------------------
//// 分割されたテキストビューを閉じる
- (IBAction)closeSplitTextView:(id)sender
// ------------------------------------------------------
{
    CEEditorView *editorViewToClose;
    
    // 閉じるべき CEEditorView を探す
    id view = [sender isMemberOfClass:[NSMenuItem class]] ? [[self window] firstResponder] : sender;
    while (view) {
        if ([view isKindOfClass:[CEEditorView class]]) {
            editorViewToClose = (CEEditorView *)view;
            break;
        }
        view = [view superview];
    }
    
    if (!editorViewToClose) { return; }
    
    // フォーカスのあるテキストビューの場合はフォーカスを隣に移す
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
    
    // 閉じる
    [editorViewToClose removeFromSuperview];
    [[self splitViewController] updateCloseSplitViewButton];
}


// ------------------------------------------------------
/// ドキュメント全体を再カラーリング
- (IBAction)recoloringAllStringOfDocument:(id)sender
// ------------------------------------------------------
{
    [self recolorAllString];
}



#pragma mark Private Methods

//=======================================================
// Private method
//
//=======================================================

// ------------------------------------------------------
/// サブビューに初期値を設定
- (void)setupViewParamsInInit:(BOOL)isInitial
// ------------------------------------------------------
{
    if (isInitial) {
        NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];

        [self setShowsLineNum:[defaults boolForKey:CEDefaultShowLineNumbersKey]];
        [self setShowsNavigationBar:[defaults boolForKey:CEDefaultShowNavigationBarKey]];
        [self setWrapsLines:[defaults boolForKey:CEDefaultWrapLinesKey]];
        [self setVerticalLayoutOrientation:[defaults boolForKey:CEDefaultLayoutTextVerticalKey]];
        [self setShowsPageGuide:[defaults boolForKey:CEDefaultShowPageGuideKey]];
    } else {
        [self setShowsLineNum:[self showsLineNum]];
        [self setShowsNavigationBar:[self showsNavigationBar]];
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
/// navigationBarを返す
- (CENavigationBarController *)navigationBar
// ------------------------------------------------------
{
    return [(CEEditorView *)[[self textView] delegate] navigationBar];
}


// ------------------------------------------------------
/// syntaxオブジェクトを返す
- (CESyntaxParser *)syntaxParser
// ------------------------------------------------------
{
    return [(CEEditorView *)[[self textView] delegate] syntaxParser];
}


// ------------------------------------------------------
/// カラーリング実行
- (void)doColoringNow
// ------------------------------------------------------
{
    if ([self coloringTimer]) { return; }
    
    NSRect visibleRect = [[[[self textView] enclosingScrollView] contentView] documentVisibleRect];
    NSRange glyphRange = [[[self textView] layoutManager] glyphRangeForBoundingRect:visibleRect
                                                                    inTextContainer:[[self textView] textContainer]];
    NSRange charRange = [[[self textView] layoutManager] characterRangeForGlyphRange:glyphRange
                                                                    actualGlyphRange:NULL];
    NSRange selectedRange = [[self textView] selectedRange];
    NSRange coloringRange = charRange;
    
    // = 選択領域（編集場所）が見えないときは編集場所周辺を更新
    if (!NSLocationInRange(selectedRange.location, charRange)) {
        NSInteger location = selectedRange.location - charRange.length;
        if (location < 0) { location = 0; }
        NSInteger length = selectedRange.length + charRange.length;
        NSInteger max = [[self string] length] - location;
        length = MIN(length, max);
        
        coloringRange = NSMakeRange(location, length);
    }
    
    [[self syntaxParser] colorVisibleRange:coloringRange wholeString:[self string]];
}


// ------------------------------------------------------
/// タイマーの設定時刻に到達、カラーリング実行
- (void)doColoringWithTimer:(NSTimer *)timer
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

@end
