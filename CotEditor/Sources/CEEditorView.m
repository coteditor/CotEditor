/*
 ==============================================================================
 CEEditorView
 
 CotEditor
 http://coteditor.com
 
 Created on 2006-03-18 by nakamuxu
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

#import "CEEditorView.h"
#import <OgreKit/OgreTextFinder.h>
#import "CEWindowController.h"
#import "CEEditorWrapper.h"
#import "CEEditorScrollView.h"
#import "CESyntaxParser.h"
#import "CEThemeManager.h"
#import "CETextFinder.h"
#import "NSString+CENewLine.h"
#import "Constants.h"


@interface CEEditorView ()

@property (nonatomic) CEEditorScrollView *scrollView;
@property (nonatomic) NSTextStorage *textStorage;

@property (nonatomic) NSTimer *lineNumUpdateTimer;
@property (nonatomic) NSTimer *outlineMenuTimer;

@property (nonatomic) BOOL highlightsCurrentLine;
@property (nonatomic) NSInteger lastCursorLocation;


// readonly
@property (readwrite, nonatomic) CETextView *textView;
@property (readwrite, nonatomic) CENavigationBarController *navigationBar;
@property (readwrite, nonatomic) CESyntaxParser *syntaxParser;

@end




#pragma mark -

@implementation CEEditorView

#pragma mark Superclass Methods

// ------------------------------------------------------
/// initialize instance
- (instancetype)initWithFrame:(NSRect)frameRect
// ------------------------------------------------------
{
    self = [super initWithFrame:frameRect];
    if (self) {
        NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
        
        _highlightsCurrentLine = [defaults boolForKey:CEDefaultHighlightCurrentLineKey];

        // navigationBar 生成
        _navigationBar = [[CENavigationBarController alloc] init];
        [self addSubview:[_navigationBar view]];

        // create scroller with line number view
        _scrollView = [[CEEditorScrollView alloc] initWithFrame:NSZeroRect];
        [_scrollView setBorderType:NSNoBorder];
        [_scrollView setHasVerticalScroller:YES];
        [_scrollView setHasHorizontalScroller:YES];
        [_scrollView setTranslatesAutoresizingMaskIntoConstraints:NO];
        [_scrollView setAutohidesScrollers:NO];
        [_scrollView setDrawsBackground:NO];
        [self addSubview:_scrollView];
        
        // setup autolayout
        NSDictionary *views = @{@"navBar": [_navigationBar view],
                                @"scrollView": _scrollView};
        [[_navigationBar view] setTranslatesAutoresizingMaskIntoConstraints:NO];
        [self addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:|[navBar]|"
                                                                     options:0 metrics:nil views:views]];
        [self addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:|[scrollView]|"
                                                                     options:0 metrics:nil views:views]];
        [self addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|[navBar][scrollView]|"
                                                                     options:0 metrics:nil views:views]];

        // TextStorage と LayoutManager を生成
        [self setTextStorage:[[NSTextStorage alloc] init]];
        CELayoutManager *layoutManager = [[CELayoutManager alloc] init];
        [_textStorage addLayoutManager:layoutManager];
        [layoutManager setBackgroundLayoutEnabled:YES];
        [layoutManager setUsesAntialias:[defaults boolForKey:CEDefaultShouldAntialiasKey]];
        [layoutManager setFixesLineHeight:[defaults boolForKey:CEDefaultFixLineHeightKey]];

        // NSTextContainer と CESyntaxParser を生成
        NSTextContainer *container = [[NSTextContainer alloc] initWithContainerSize:NSMakeSize(CGFLOAT_MAX, CGFLOAT_MAX)];
        [layoutManager addTextContainer:container];

        _syntaxParser = [[CESyntaxParser alloc] initWithStyleName:NSLocalizedString(@"None", @"")
                                                    layoutManager:layoutManager];

        // TextView 生成
        _textView = [[CETextView alloc] initWithFrame:NSZeroRect textContainer:container];
        [_textView setDelegate:self];
        
        [_navigationBar setTextView:_textView];
        [_scrollView setDocumentView:_textView];
        
        // すべて置換アクションをキャッチ
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(textDidReplaceAll:)
                                                     name:CETextFinderDidReplaceAllNotification
                                                   object:_textView];
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(recolorAllTextViewString)
                                                     name:CETextFinderDidUnhighlightNotification
                                                   object:_textView];
        
        // 置換の Undo/Redo 後に再カラーリングできるように Undo/Redo アクションをキャッチ
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(recolorAfterUndoAndRedo:)
                                                     name:NSUndoManagerDidRedoChangeNotification
                                                   object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(recolorAfterUndoAndRedo:)
                                                     name:NSUndoManagerDidUndoChangeNotification
                                                   object:nil];
        
        // テーマの変更をキャッチ
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(themeDidUpdate:)
                                                     name:CEThemeDidUpdateNotification
                                                   object:nil];
        
        // リサイズに現在行ハイライトを追従
        if (_highlightsCurrentLine) {
            [[NSNotificationCenter defaultCenter] addObserver:self
                                                     selector:@selector(highlightCurrentLine)
                                                         name:NSViewFrameDidChangeNotification
                                                       object:[_scrollView contentView]];
        }
    }
    return self;
}


// ------------------------------------------------------
/// clean up
- (void)dealloc
// ------------------------------------------------------
{
    [self stopUpdateLineNumberTimer];
    [self stopUpdateOutlineMenuTimer];
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    
    [_textStorage removeLayoutManager:[_textView layoutManager]];
    _textView = nil;
}



#pragma mark Public Methods

// ------------------------------------------------------
/// TextStorage を置換
- (void)replaceTextStorage:(NSTextStorage *)textStorage
// ------------------------------------------------------
{
    [self setTextStorage:textStorage];
    [[[self textView] layoutManager] replaceTextStorage:textStorage];
}


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
    [[self navigationBar] setShown:showsNavigationBar animate:performAnimation];
    if (![self outlineMenuTimer]) {
        [self updateOutlineMenu];
    }
}


// ------------------------------------------------------
/// ラップする／しないを切り替える
- (void)setWrapsLines:(BOOL)wrapsLines
// ------------------------------------------------------
{
    NSTextView *textView = [self textView];
    BOOL isVertical = ([textView layoutOrientation] == NSTextLayoutOrientationVertical);
    
    // 条件を揃えるためにいったん横書きに戻す (各項目の縦横の入れ替えは setLayoutOrientation: が良きに計らってくれる)
    [textView setLayoutOrientation:NSTextLayoutOrientationHorizontal];
    
    [[textView enclosingScrollView] setHasHorizontalScroller:!wrapsLines];
    [[textView textContainer] setWidthTracksTextView:wrapsLines];
    if (wrapsLines) {
        NSSize contentSize = [[textView enclosingScrollView] contentSize];
        [[textView textContainer] setContainerSize:NSMakeSize(contentSize.width, CGFLOAT_MAX)];
        [textView sizeToFit];
    } else {
        [[textView textContainer] setContainerSize:NSMakeSize(CGFLOAT_MAX, CGFLOAT_MAX)];
    }
    [textView setAutoresizingMask:(wrapsLines ? NSViewWidthSizable : NSViewNotSizable)];
    [textView setHorizontallyResizable:!wrapsLines];
    
    // 縦書きモードの際は改めて縦書きにする
    if (isVertical) {
        [textView setLayoutOrientation:NSTextLayoutOrientationVertical];
    }
    
    [[self scrollView] invalidateLineNumber];
}


// ------------------------------------------------------
/// 不可視文字の表示／非表示を切り替える
- (void)setShowsInvisibles:(BOOL)showsInvisibles
// ------------------------------------------------------
{
    [(CELayoutManager *)[[self textView] layoutManager] setShowsInvisibles:showsInvisibles];
    
    // （不可視文字が選択状態で表示／非表示を切り替えられた時、不可視文字の背景選択色を描画するための時間差での選択処理）
    // （もっとスマートな解決方法はないものか...？ 2006-09-25）
    if (showsInvisibles) {
        __block NSTextView *textView = [self textView];
        dispatch_async(dispatch_get_main_queue(), ^{
            NSRange selectedRange = [textView selectedRange];
            [textView setSelectedRange:NSMakeRange(0, 0)];
            [textView setSelectedRange:selectedRange];
        });
    }
}


// ------------------------------------------------------
/// アンチエイリアス適用を切り替える
- (void)setUsesAntialias:(BOOL)usesAntialias
// ------------------------------------------------------
{
    CELayoutManager *manager = (CELayoutManager *)[[self textView] layoutManager];

    [manager setUsesAntialias:usesAntialias];
    [[self textView] setNeedsDisplayInRect:[[self textView] visibleRect]];
}


// ------------------------------------------------------
/// キャレットを先頭に移動
- (void)setCaretToBeginning
// ------------------------------------------------------
{
    [[self textView] setSelectedRange:NSMakeRange(0, 0)];
}


// ------------------------------------------------------
/// シンタックススタイルを設定
- (void)setSyntaxWithName:(NSString *)styleName
// ------------------------------------------------------
{
    [self setSyntaxParser:[[CESyntaxParser alloc] initWithStyleName:styleName
                                                      layoutManager:(CELayoutManager *)[[self textView] layoutManager]]];
    
    [[self textView] setInlineCommentDelimiter:[[self syntaxParser] inlineCommentDelimiter]];
    [[self textView] setBlockCommentDelimiters:[[self syntaxParser] blockCommentDelimiters]];
    [[self textView] setFirstCompletionCharacterSet:[[self syntaxParser] firstCompletionCharacterSet]];
}


// ------------------------------------------------------
/// 全てを再カラーリング
- (void)recolorAllTextViewString
// ------------------------------------------------------
{
    [[self syntaxParser] colorAllString:[[self textView] string]];
}


// ------------------------------------------------------
/// Undo/Redo の後に全てを再カラーリング
- (void)recolorAfterUndoAndRedo:(NSNotification *)aNotification
// ------------------------------------------------------
{
    NSUndoManager *undoManager = [aNotification object];
    
    if (undoManager != [[self textView] undoManager]) { return; }
    
    // OgreKit からの置換の Undo/Redo の後のみ再カラーリングを実行
    // 置換の Undo を判別するために OgreKit 側で登録された actionName を使用 (2014-04 by 1024jp)
    // [Note] OgreKit側の問題として、すべてのUndoに対して "Replace All" という名前を付けているようだ。なので現在「すべて」以外の置換も対象となっている (2014-12 by 1024jp)
    NSString *actionName = [undoManager isUndoing] ? [undoManager redoActionName] : [undoManager undoActionName];
    if ([actionName isEqualToString:OgreTextFinderLocalizedString(@"Replace All")]) {
        [self textDidReplaceAll:aNotification];
    }
}


// ------------------------------------------------------
/// アウトラインメニューを更新
- (void)updateOutlineMenu
// ------------------------------------------------------
{
    [self stopUpdateOutlineMenuTimer];
    
    NSString *wholeString = [[[self textView] string] copy];  // 解析中に参照元が変更されると困るのでコピーする
    
    // 規定の文字数以上の場合にはインジケータを表示
    // （ただし、CEDefaultShowColoringIndicatorTextLengthKey が「0」の時は表示しない）
    NSUInteger indicatorThreshold = [[NSUserDefaults standardUserDefaults] integerForKey:CEDefaultShowColoringIndicatorTextLengthKey];
    if (indicatorThreshold > 0 && indicatorThreshold < [wholeString length]) {
        [[self navigationBar] showOutlineIndicator];
    }
    
    // 別スレッドでアウトラインを抽出して、メインスレッドで navigationBar に渡す
    __weak typeof(self) weakSelf = self;
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        typeof(weakSelf) strongSelf = weakSelf;
        NSArray *outlineMenuArray = [[strongSelf syntaxParser] outlineMenuArrayWithWholeString:wholeString];
        
        dispatch_sync(dispatch_get_main_queue(), ^{
            [[strongSelf navigationBar] setOutlineMenuArray:outlineMenuArray];
            // （選択項目の更新も上記メソッド内で行われるので、updateOutlineMenuSelection は呼ぶ必要なし。 2008.05.16.）
        });
    });
}



#pragma mark Delegate

//=======================================================
// NSTextViewDelegate  < textView
//=======================================================

// ------------------------------------------------------
///  テキストが編集される
- (BOOL)textView:(NSTextView *)aTextView shouldChangeTextInRange:(NSRange)affectedCharRange 
        replacementString:(NSString *)replacementString
// ------------------------------------------------------
{
    // standardize line endings to LF (Script, Key Typing)
    // (Line endings replacemement by other text modifications are processed in the following methods.)
    //
    // # Methods Standardizing Line Endings on Text Editing
    //   - File Open: CEDocument > setStringToEditor
    //   - Script: CEEditorView > textView:shouldChangeTextInRange:replacementString:
    //   - Key Typing: CEEditorView > textView:shouldChangeTextInRange:replacementString:
    //   - Paste: CETextView > readSelectionFromPasteboard:type:
    //   - Drop (from other documents/apps): CETextView > readSelectionFromPasteboard:type:
    //   - Drop (from the same document): CETextView > performDragOperation:
    //   - Replace on Find Penel: (OgreKit) OgreTextViewPlainAdapter > replaceCharactersInRange:withOGString:
    
    if (!replacementString ||  // = attributesのみの変更
        ([replacementString length] == 0) ||  // = 文章の削除
        [(CETextView *)aTextView isSelfDrop] ||  // = 自己内ドラッグ&ドロップ
        [(CETextView *)aTextView isReadingFromPboard] ||  // = ペーストまたはドロップ
        [[aTextView undoManager] isUndoing] ||  // = アンドゥ中
        [replacementString isEqualToString:@"\n"])
    {
        return YES;
    }
    
    CENewLineType replacementLineEndingType = [replacementString detectNewLineType];
    // 挿入／置換する文字列に改行コードが含まれていたら、LF に置換する
    if ((replacementLineEndingType != CENewLineNone) && (replacementLineEndingType != CENewLineLF)) {
        // （newStrが使用されるのはスクリプトからの入力時。キー入力は条件式を通過しない）
        NSString *newString = [replacementString stringByReplacingNewLineCharacersWith:CENewLineLF];
        
        if (newString) {
            [(CETextView *)aTextView replaceWithString:newString
                                                 range:affectedCharRange
                                         selectedRange:NSMakeRange(affectedCharRange.location + [newString length], 0)
                                            actionName:nil];  // Action名は自動で付けられる？ので、指定しない
            
            return NO;
        }
    }
    
    return YES;
}


// ------------------------------------------------------
/// 補完候補リストをセット
- (NSArray *)textView:(NSTextView *)textView completions:(NSArray *)words 
        forPartialWordRange:(NSRange)charRange indexOfSelectedItem:(NSInteger *)index
// ------------------------------------------------------
{
    NSMutableOrderedSet *candidateWords = [NSMutableOrderedSet orderedSet];
    NSUInteger addingMode = [[NSUserDefaults standardUserDefaults] integerForKey:CEDefaultCompletionWordsKey];
    NSString *partialWord = [[textView string] substringWithRange:charRange];

    
    //"ファイル中の語彙" を検索して candidateWords に入れる
    if (addingMode != 3) {
        if (charRange.length == 1 && ![[NSCharacterSet alphanumericCharacterSet] characterIsMember:[partialWord characterAtIndex:0]]) {
            // do nothing if the particle word is an symbol
            
        } else {
            NSString *documentString = [textView string];
            NSString *pattern = [NSString stringWithFormat:@"(?:^|\\b|(?<=\\W))%@\\w+?(?:$|\\b)",
                                 [NSRegularExpression escapedPatternForString:partialWord]];
            NSRegularExpression *regex = [NSRegularExpression regularExpressionWithPattern:pattern options:0 error:nil];
            [regex enumerateMatchesInString:documentString options:0
                                      range:NSMakeRange(0, [documentString length])
                                 usingBlock:^(NSTextCheckingResult *result, NSMatchingFlags flags, BOOL *stop)
             {
                 [candidateWords addObject:[documentString substringWithRange:[result range]]];
             }];
        }
    }
    
    //"カラーシンタックス辞書の語彙" をコピーする
    if (addingMode >= 1) {
        NSArray *syntaxWords = [[self syntaxParser] completionWords];
        for (NSString *word in syntaxWords) {
            if ([word rangeOfString:partialWord options:NSCaseInsensitiveSearch|NSAnchoredSearch].location != NSNotFound) {
                [candidateWords addObject:word];
            }
        }
    }
    
    //デフォルトの候補から "一般英単語" をコピーする
    if (addingMode == 2) {
        [candidateWords addObjectsFromArray:words];
    }
    
    // 入力済みの単語と同じ候補しかないときは表示しない
    if ([candidateWords count] == 1 && [[candidateWords firstObject] caseInsensitiveCompare:partialWord] == NSOrderedSame) {
        return nil;
    }

    return [candidateWords array];
}


// ------------------------------------------------------
/// text did edit.
- (void)textDidChange:(NSNotification *)aNotification
// ------------------------------------------------------
{
    // カラーリング実行
    [[self editorWrapper] setupColoringTimer];

    // アウトラインメニュー項目、非互換文字リスト更新
    [self updateInfo];

    // フラグが立っていたら、入力補完を再度実行する
    // （フラグは CETextView > insertCompletion:forPartialWordRange:movement:isFinal: で立てている）
    if ([[self textView] needsRecompletion]) {
        [[self textView] setNeedsRecompletion:NO];
        [[self textView] completeAfterDelay:0.05];
    }
}


// ------------------------------------------------------
/// the selection of main textView was changed.
- (void)textViewDidChangeSelection:(NSNotification *)aNotification
// ------------------------------------------------------
{
    // カレント行をハイライト
    [self highlightCurrentLine];

    // 文書情報更新
    [[[self window] windowController] setupEditorInfoUpdateTimer];

    // アウトラインメニュー選択項目更新
    [self updateOutlineMenuSelection];

    // 対応するカッコをハイライト表示
    
    // The following part is based on Smultron's SMLTextView.m by Peter Borg. (2006-09-09)
    // Smultron 2 was distributed on <http://smultron.sourceforge.net> under the terms of the BSD license.
    // Copyright (c) 2004-2006 Peter Borg

    if (![[NSUserDefaults standardUserDefaults] boolForKey:CEDefaultHighlightBracesKey]) { return; }
    
    NSString *string = [[self textView] string];
    if ([string length] == 0) { return; }
    NSRange selectedRange = [[self textView] selectedRange];
    NSInteger location = selectedRange.location;
    NSInteger difference = location - [self lastCursorLocation];
    [self setLastCursorLocation:location];

    // Smultron では「if (difference != 1 && difference != -1)」の条件を使ってキャレットを前方に動かした時も強調表示させているが、CotEditor では Xcode 同様、入力時またはキャレットを後方に動かした時だけに限定した（2006-09-10）
    if (difference != 1) {
        return; // If the difference is more than one, they've moved the cursor with the mouse or it has been moved by resetSelectedRange below and we shouldn't check for matching braces then
    }
    
    if (difference == 1) { // Check if the cursor has moved forward
        location--;
    }

    if (location == [string length]) {
        return;
    }
    
    unichar theUnichar = [string characterAtIndex:location];
    unichar curChar, braceChar;
    if (theUnichar == ')') {
        braceChar = '(';
    } else if (theUnichar == ']') {
        braceChar = '[';
    } else if (theUnichar == '}') {
        braceChar = '{';
    } else if ((theUnichar == '>') && [[NSUserDefaults standardUserDefaults] boolForKey:CEDefaultHighlightLtGtKey]) {
        braceChar = '<';
    } else {
        return;
    }
    NSUInteger skipMatchingBrace = 0;
    curChar = theUnichar;

    while (location--) {
        theUnichar = [string characterAtIndex:location];
        if (theUnichar == braceChar) {
            if (!skipMatchingBrace) {
                [[self textView] showFindIndicatorForRange:NSMakeRange(location, 1)];
                return;
            } else {
                skipMatchingBrace--;
            }
        } else if (theUnichar == curChar) {
            skipMatchingBrace++;
        }
    }
    NSBeep();
}


// ------------------------------------------------------
/// font is changed
- (void)textViewDidChangeTypingAttributes:(NSNotification *)notification
// ------------------------------------------------------
{
    [self highlightCurrentLine];
}



#pragma mark Notifications

//=======================================================
// Notification  < CETextFinder
//=======================================================

// ------------------------------------------------------
/// did Replace All
- (void)textDidReplaceAll:(NSNotification *)aNotification
// ------------------------------------------------------
{
    // 文書情報更新（選択範囲・キャレット位置が変更されないまま全置換が実行された場合への対応）
    [[[self window] windowController] setupEditorInfoUpdateTimer];
    
    // アウトラインメニュー項目、非互換文字リスト更新
    [self updateInfo];
    
    // 全テキストを再カラーリング
    [self recolorAllTextViewString];
}


//=======================================================
// Notification  < CEThemeManager
//=======================================================

// ------------------------------------------------------
/// テーマが更新された
- (void)themeDidUpdate:(NSNotification *)notification
// ------------------------------------------------------
{
    if ([[notification userInfo][CEOldNameKey] isEqualToString:[[[self textView] theme] name]]) {
        [[self textView] setTheme:[CETheme themeWithName:[notification userInfo][CENewNameKey]]];
        [[self textView] setSelectedRanges:[[self textView] selectedRanges]];  // 現在行のハイライトカラーの更新するために選択し直す
        [[self editorWrapper] recolorAllString];
    }
}



#pragma mark Private Mthods

// ------------------------------------------------------
// textStorage をセット
- (void)setTextStorage:(NSTextStorage *)textStorage
// ------------------------------------------------------
{
    // 行番号ビューのためにテキストの変更を監視する
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(updateLineNumber)
                                                 name:NSTextStorageDidProcessEditingNotification
                                               object:textStorage];
    
    _textStorage = textStorage;
}


// ------------------------------------------------------
/// 行番号更新
- (void)updateLineNumberWithTimer:(NSTimer *)timer
// ------------------------------------------------------
{
    [self stopUpdateLineNumberTimer];
    [[self scrollView] invalidateLineNumber];
}


// ------------------------------------------------------
/// アウトラインメニュー更新
- (void)updateOutlineMenuWithTimer:(NSTimer *)timer
// ------------------------------------------------------
{
    [self updateOutlineMenu]; // （updateOutlineMenu 内で stopUpdateOutlineMenuTimer を実行している）
}


// ------------------------------------------------------
/// 行番号表示を更新
- (void)updateLineNumber
// ------------------------------------------------------
{
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    
    // 行番号更新
    NSTimeInterval lineNumUpdateInterval = [defaults doubleForKey:CEDefaultLineNumUpdateIntervalKey];
    if ([self lineNumUpdateTimer]) {
        [[self lineNumUpdateTimer] setFireDate:[NSDate dateWithTimeIntervalSinceNow:lineNumUpdateInterval]];
    } else {
        [self setLineNumUpdateTimer:[NSTimer scheduledTimerWithTimeInterval:lineNumUpdateInterval
                                                                     target:self
                                                                   selector:@selector(updateLineNumberWithTimer:)
                                                                   userInfo:nil
                                                                    repeats:NO]];
    }
}


// ------------------------------------------------------
/// アウトラインメニューの選択項目を更新
- (void)updateOutlineMenuSelection
// ------------------------------------------------------
{
    if ([self outlineMenuTimer]) { return; }
    
    if ([[self textView] needsUpdateOutlineMenuItemSelection]) {
        [[self navigationBar] selectOutlineMenuItemWithRange:[[self textView] selectedRange]];
    } else {
        [[self textView] setNeedsUpdateOutlineMenuItemSelection:YES];
        [[self navigationBar] updatePrevNextButtonEnabled];
    }
}


// ------------------------------------------------------
/// テキストビュー分割削除ボタンの有効化／無効化を制御
- (void)updateCloseSplitViewButton:(BOOL)isEnabled
// ------------------------------------------------------
{
    [[self navigationBar] setCloseSplitButtonEnabled:isEnabled];
}


// ------------------------------------------------------
/// 行番号更新タイマーを停止
- (void)stopUpdateLineNumberTimer
// ------------------------------------------------------
{
    if ([self lineNumUpdateTimer]) {
        [[self lineNumUpdateTimer] invalidate];
        [self setLineNumUpdateTimer:nil];
    }
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


// ------------------------------------------------------
/// アウトラインメニューなどを更新
- (void)updateInfo
// ------------------------------------------------------
{
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];

    // アウトラインメニュー項目更新
    NSTimeInterval outlineMenuInterval = [defaults doubleForKey:CEDefaultOutlineMenuIntervalKey];
    if ([self outlineMenuTimer]) {
        [[self outlineMenuTimer] setFireDate:[NSDate dateWithTimeIntervalSinceNow:outlineMenuInterval]];
    } else {
        [self setOutlineMenuTimer:[NSTimer scheduledTimerWithTimeInterval:outlineMenuInterval
                                                                   target:self
                                                                 selector:@selector(updateOutlineMenuWithTimer:)
                                                                 userInfo:nil
                                                                  repeats:NO]];
    }

    // 非互換文字リスト更新
    [[[self window] windowController] updateIncompatibleCharsIfNeeded];
}


// ------------------------------------------------------
/// カレント行をハイライト表示
- (void)highlightCurrentLine
// ------------------------------------------------------
{
    if (![self highlightsCurrentLine]) { return; }
    
    // 最初に（表示前に） TextView にテキストをセットした際にムダに演算が実行されるのを避ける (2014-07 by 1024jp)
    if (![[self window] isVisible]) { return; }
    
    NSLayoutManager *layoutManager = [[self textView] layoutManager];
    CETextView *textView = [self textView];
    NSRect rect;
    
    // 選択行の矩形を得る
    if ([textView selectedRange].location == [[textView string] length] && [layoutManager extraLineFragmentTextContainer]) {  // 最終行
        rect = [layoutManager extraLineFragmentRect];
        
    } else {
        NSRange lineRange = [[textView string] lineRangeForRange:[textView selectedRange]];
        lineRange.length -= (lineRange.length > 0) ? 1 : 0;  // remove line ending
        NSRange glyphRange = [layoutManager glyphRangeForCharacterRange:lineRange actualCharacterRange:NULL];
        
        rect = [layoutManager boundingRectForGlyphRange:glyphRange inTextContainer:[textView textContainer]];
        rect.size.width = [[textView textContainer] containerSize].width;
    }
    
    // 周囲の空白の調整
    CGFloat padding = [[textView textContainer] lineFragmentPadding];
    rect.origin.x = padding;
    rect.size.width -= 2 * padding;
    rect = NSOffsetRect(rect, [textView textContainerOrigin].x, [textView textContainerOrigin].y);
    
    // ハイライト矩形を描画
    if (!NSEqualRects([textView highlightLineRect], rect)) {
        // clear previous highlihght
        [textView setNeedsDisplayInRect:[textView highlightLineRect] avoidAdditionalLayout:YES];
        
        // draw highlight
        [textView setHighlightLineRect:rect];
        [textView setNeedsDisplayInRect:rect avoidAdditionalLayout:YES];
    }
}

@end
