/*
=================================================
CEEditorView
(for CotEditor)

 Copyright (C) 2004-2007 nakamuxu.
 Copyright (C) 2014 CotEditor Project
 http://coteditor.github.io
=================================================

encoding="UTF-8"
Created:2004.12.08
 
------------
This class is based on JSDTextView (written by James S. Derry – http://www.balthisar.com)
JSDTextView is released as public domain.
arranged by nakamuxu, Dec 2004.
-------------------------------------------------

This program is free software; you can redistribute it and/or
modify it under the terms of the GNU General Public License
as published by the Free Software Foundation; either version 2
of the License, or (at your option) any later version.

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU General Public License for more details.

You should have received a copy of the GNU General Public License
along with this program; if not, write to the Free Software
Foundation, Inc., 59 Temple Place - Suite 330, Boston, MA  02111-1307, USA. 


=================================================
*/

#import "CEEditorView.h"
#import "CESplitViewController.h"
#import "CEToolbarController.h"
#import "CENavigationBarController.h"
#import "CELineNumberView.h"
#import "CESyntaxParser.h"
#import "constants.h"


@interface CEEditorView ()

@property (nonatomic) NSTimer *coloringTimer;
@property (nonatomic) IBOutlet CESplitViewController *splitViewController;


// readonly
@property (nonatomic, readwrite) BOOL canActivateShowInvisibles;

@end




#pragma -

@implementation CEEditorView

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
        
        basicColoringDelay = [defaults doubleForKey:k_key_basicColoringDelay];
        firstColoringDelay = [defaults doubleForKey:k_key_firstColoringDelay];
        secondColoringDelay = [defaults doubleForKey:k_key_secondColoringDelay];
    });
}



#pragma mark Sperclass Methods

//=======================================================
// Sperclass method
//
//=======================================================

// ------------------------------------------------------
/// 初期化
- (instancetype)initWithFrame:(NSRect)frameRect
// ------------------------------------------------------
{
    self = [super initWithFrame:frameRect];
    if (self) {
        NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
        
        _canActivateShowInvisibles = ([defaults boolForKey:k_key_showInvisibleSpace] ||
                                      [defaults boolForKey:k_key_showInvisibleTab] ||
                                      [defaults boolForKey:k_key_showInvisibleNewLine] ||
                                      [defaults boolForKey:k_key_showInvisibleFullwidthSpace] ||
                                      [defaults boolForKey:k_key_showOtherInvisibleChars]);
    }
    return self;
}


// ------------------------------------------------------
/// Nibファイル読み込み直後
- (void)awakeFromNib
// ------------------------------------------------------
{
    CESubSplitView *subSplitView = [[[self splitViewController] view] subviews][0];
    [subSplitView setEditorView:self];
    [self setTextView:[subSplitView textView]];
    
    [self setupViewParamsInInit:YES];
    // （不可視文字の表示／非表示のセットは全て生成が終ってから、CEWindowController > windowDidLoad で行う）
    [self setShowInvisibles:[self canActivateShowInvisibles]];
    
}


// ------------------------------------------------------
/// 後片付け
- (void)dealloc
// ------------------------------------------------------
{
    [self stopColoringTimer];
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
/// フォントを返す
- (NSFont *)font
// ------------------------------------------------------
{
    return [[self textView] font];
}


// ------------------------------------------------------
/// フォントをセット
- (void)setFont:(NSFont *)inFont
// ------------------------------------------------------
{
    [[self textView] setFont:inFont];
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
/// 現在のエンコードにコンバートできない文字列をマークアップ
- (void)markupRanges:(NSArray *)ranges
// ------------------------------------------------------
{
    NSColor *color = [[[self textView] theme] markupColor];
    
    // ハイライト
    NSArray *layoutManagers = [self allLayoutManagers];
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
    NSArray *managers = [self allLayoutManagers];
    
    for (NSLayoutManager *manager in managers) {
        [manager removeTemporaryAttribute:NSBackgroundColorAttributeName
                        forCharacterRange:NSMakeRange(0, [[self string] length])];
    }
}


// ------------------------------------------------------
/// 行番号の表示をする／しないをセット
- (void)setShowLineNum:(BOOL)showLineNum
// ------------------------------------------------------
{
    _showLineNum = showLineNum;
    
    [[self splitViewController] setShowLineNum:showLineNum];
    [[[self windowController] toolbarController] toggleItemWithIdentifier:k_showLineNumItemID setOn:showLineNum];
}


// ------------------------------------------------------
/// ナビバーを表示する／しないをセット
- (void)setShowNavigationBar:(BOOL)showNavigationBar
// ------------------------------------------------------
{
    _showNavigationBar = showNavigationBar;
    
    [[self splitViewController] setShowNavigationBar:showNavigationBar];
    [[[self windowController] toolbarController] toggleItemWithIdentifier:k_showNavigationBarItemID setOn:showNavigationBar];
}


// ------------------------------------------------------
/// 行をラップする／しないをセット
- (void)setWrapLines:(BOOL)wrapLines
// ------------------------------------------------------
{
    _wrapLines = wrapLines;
    
    [[self splitViewController] setWrapLines:wrapLines];
    [self setNeedsDisplay:YES];
    [[[self windowController] toolbarController] toggleItemWithIdentifier:k_wrapLinesItemID setOn:wrapLines];
}


// ------------------------------------------------------
/// アンチエイリアスでの描画の許可を得る
- (BOOL)shouldUseAntialias
// ------------------------------------------------------
{
    CELayoutManager *manager = (CELayoutManager *)[[self textView] layoutManager];
    
    return [manager useAntialias];
}


// ------------------------------------------------------
/// アンチエイリアス適用をトグルに切り替え
- (void)toggleShouldUseAntialias
// ------------------------------------------------------
{
    CELayoutManager *manager = (CELayoutManager *)[[self textView] layoutManager];

    [[self splitViewController] setUseAntialias:![manager useAntialias]];
}


// ------------------------------------------------------
/// ページガイドを表示する／しないをセット
- (void)setShowPageGuide:(BOOL)showPageGuide
// ------------------------------------------------------
{
    if (_showPageGuide != showPageGuide) {
        _showPageGuide = showPageGuide;
        [[[self windowController] toolbarController] toggleItemWithIdentifier:k_showPageGuideItemID setOn:showPageGuide];
    }
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
        if ([self showNavigationBar]) {
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
- (BOOL)showInvisibles
// ------------------------------------------------------
{
    return [(CELayoutManager *)[[self textView] layoutManager] showInvisibles];
}


// ------------------------------------------------------
/// 不可視文字の表示／非表示を設定
- (void)setShowInvisibles:(BOOL)showInvisibles
// ------------------------------------------------------
{
    [[self splitViewController] setShowInvisibles:showInvisibles];
}


// ------------------------------------------------------
/// カラーリングタイマーのファイヤーデイトを設定時間後にセット
- (void)setupColoringTimer
// ------------------------------------------------------
{
    if ([[self syntaxParser] isNone]) { return; }
    
    BOOL delay = [[NSUserDefaults standardUserDefaults] boolForKey:k_key_delayColoring];
    
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

    if ([menuItem action] == @selector(toggleShowLineNum:)) {
        title = [self showLineNum] ? @"Hide Line Numbers" : @"Show Line Numbers";
        
    } else if ([menuItem action] == @selector(toggleShowNavigationBar:)) {
        title = [self showNavigationBar] ? @"Hide Navigation Bar" : @"Show Navigation Bar";
        
    } else if ([menuItem action] == @selector(toggleWrapLines:)) {
        title = [self wrapLines] ? @"Unwrap Lines" : @"Wrap Lines";
        
    } else if ([menuItem action] == @selector(toggleUseAntialias:)) {
        state = [self shouldUseAntialias] ? NSOnState : NSOffState;
        
    } else if ([menuItem action] == @selector(toggleShowPageGuide:)) {
        title = [self showPageGuide] ? @"Hide Page Guide" : @"Show Page Guide";
        
    } else if ([menuItem action] == @selector(toggleShowInvisibleChars:)) {
        title = [self showInvisibles] ? @"Hide Invisible Characters" : @"Show Invisible Characters";
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
- (IBAction)toggleShowLineNum:(id)sender
// ------------------------------------------------------
{
    [self setShowLineNum:![self showLineNum]];
}


// ------------------------------------------------------
/// ナビゲーションバーの表示をトグルに切り替える
- (IBAction)toggleShowNavigationBar:(id)sender
// ------------------------------------------------------
{
    [self setShowNavigationBar:![self showNavigationBar]];
}


// ------------------------------------------------------
/// ワードラップをトグルに切り替える
- (IBAction)toggleWrapLines:(id)sender
// ------------------------------------------------------
{
    [self setWrapLines:![self wrapLines]];
}


// ------------------------------------------------------
/// 文字にアンチエイリアスを使うかどうかをトグルに切り替える
- (IBAction)toggleUseAntialias:(id)sender
// ------------------------------------------------------
{
    [self toggleShouldUseAntialias];
}


// ------------------------------------------------------
/// 不可視文字表示をトグルに切り替える
- (IBAction)toggleShowInvisibleChars:(id)sender
// ------------------------------------------------------
{
    BOOL showInvisibles = [(CELayoutManager *)[[self textView] layoutManager] showInvisibles];

    [[self splitViewController] setShowInvisibles:!showInvisibles];
    [[[self windowController] toolbarController] toggleItemWithIdentifier:k_showInvisibleCharsItemID setOn:!showInvisibles];
}


// ------------------------------------------------------
/// ソフトタブの有効／無効をトグルに切り替える
- (IBAction)toggleAutoTabExpand:(id)sender
// ------------------------------------------------------
{
    BOOL isEnabled = ![[self textView] isAutoTabExpandEnabled];
    
    [[self splitViewController] setAutoTabExpandEnabled:isEnabled];
    [[[self windowController] toolbarController] toggleItemWithIdentifier:k_autoTabExpandItemID setOn:isEnabled];
}


// ------------------------------------------------------
/// ページガイド表示をトグルに切り替える
- (IBAction)toggleShowPageGuide:(id)sender
// ------------------------------------------------------
{
    [self setShowPageGuide:![self showPageGuide]];
    [[[self splitViewController] view] setNeedsDisplay:YES];
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
    CESubSplitView *masterView = ([sender isMemberOfClass:[NSMenuItem class]]) ? 
            (CESubSplitView *)[(CETextView *)[[self window] firstResponder] delegate] :  // from menu bar
            (CESubSplitView *)[[sender superview] superview];  // from navigation bar
    if (!masterView) { return; }
    NSRect subSplitFrame = [masterView bounds];
    NSRange selectedRange = [[masterView textView] selectedRange];
    CESubSplitView *subSplitView = [[CESubSplitView alloc] initWithFrame:subSplitFrame];

    [subSplitView replaceTextStorage:[[self textView] textStorage]];
    [subSplitView setEditorView:self];
    // あらたなsubViewは、押された追加ボタンが属する（またはフォーカスのある）subSplitViewのすぐ下に挿入する
    [[[self splitViewController] view] addSubview:subSplitView positioned:NSWindowAbove relativeTo:masterView];
    [(NSSplitView *)[[self splitViewController] view] adjustSubviews];
    [self setupViewParamsInInit:NO];
    [[subSplitView textView] setFont:[[self textView] font]];
    [[subSplitView textView] setLineSpacing:[[self textView] lineSpacing]];
    [self setShowInvisibles:[(CELayoutManager *)[[self textView] layoutManager] showInvisibles]];
    [[subSplitView textView] setSelectedRange:selectedRange];
    [(NSSplitView *)[[self splitViewController] view] adjustSubviews];
    [subSplitView setSyntaxWithName:[[self syntaxParser] styleName]];
    [[subSplitView syntaxParser] colorAllString:[self string]];
    [[self textView] centerSelectionInVisibleArea:self];
    [[self window] makeFirstResponder:[subSplitView textView]];
    [[subSplitView textView] setLineEndingString:[[self document] lineEndingString]];
    [[subSplitView textView] centerSelectionInVisibleArea:self];
    [subSplitView setShowNavigationBar:[self showNavigationBar]];  // update navigation bar layout (おそらくAutolayoutならいらない)
    [self updateCloseSubSplitViewButton];
    
}


// ------------------------------------------------------
//// 分割されたテキストビューを閉じる
- (IBAction)closeSplitTextView:(id)sender
// ------------------------------------------------------
{
    BOOL isSenderMenu = [sender isMemberOfClass:[NSMenuItem class]];
    CESubSplitView *firstResponderSubSplitView = (CESubSplitView *)[(CETextView *)[[self window] firstResponder] delegate];
    CESubSplitView *subSplitViewToClose = isSenderMenu ?
            firstResponderSubSplitView : (CESubSplitView *)[[sender superview] superview];
    if (!subSplitViewToClose) { return; }
    NSArray *subViews = [[[self splitViewController] view] subviews];
    NSUInteger count = [subViews count];
    NSUInteger deleteIndex = [subViews indexOfObject:subSplitViewToClose];

    if (isSenderMenu || (deleteIndex == [subViews indexOfObject:firstResponderSubSplitView])) {
        NSUInteger index = deleteIndex + 1;
        if (index >= count) {
            index = count - 2;
        }
        [[self window] makeFirstResponder:[subViews[index] textView]];
    }
    [subSplitViewToClose removeFromSuperview];
    [self updateCloseSubSplitViewButton];
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

        [self setShowLineNum:[defaults boolForKey:k_key_showLineNumbers]];
        [self setShowNavigationBar:[defaults boolForKey:k_key_showNavigationBar]];
        [self setWrapLines:[defaults boolForKey:k_key_wrapLines]];
        [self setShowPageGuide:[defaults boolForKey:k_key_showPageGuide]];
    } else {
        [self setShowLineNum:[self showLineNum]];
        [self setShowNavigationBar:[self showNavigationBar]];
        [self setWrapLines:[self wrapLines]];
        [self setShowPageGuide:[self showPageGuide]];
    }
}


// ------------------------------------------------------
/// navigationBarを返す
- (CENavigationBarController *)navigationBar
// ------------------------------------------------------
{
    return [(CESubSplitView *)[[self textView] delegate] navigationBar];
}


// ------------------------------------------------------
/// syntaxオブジェクトを返す
- (CESyntaxParser *)syntaxParser
// ------------------------------------------------------
{
    return [(CESubSplitView *)[[self textView] delegate] syntaxParser];
}


// ------------------------------------------------------
/// 全layoutManagerを配列で返す
- (NSArray *)allLayoutManagers
// ------------------------------------------------------
{
    NSArray *subSplitViews = [[[self splitViewController] view] subviews];
    NSMutableArray *managers = [NSMutableArray array];
    
    for (NSTextContainer *container in subSplitViews) {
        [managers addObject:[[container textView] layoutManager]];
    }
    return managers;
}


// ------------------------------------------------------
/// テキストビュー分割削除ボタンの有効／無効を更新
- (void)updateCloseSubSplitViewButton
// ------------------------------------------------------
{
    BOOL enabled = ([[[[self splitViewController] view] subviews] count] > 1);
    
    [[self splitViewController] setCloseSubSplitViewButtonEnabled:enabled];
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
