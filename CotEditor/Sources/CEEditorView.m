/*
=================================================
CEEditorView
(for CotEditor)

 Copyright (C) 2004-2007 nakamuxu.
 Copyright (C) 2014 CotEditor Project
 http://coteditor.github.io
=================================================

encoding="UTF-8"
Created:2006.03.18
 
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
#import "CELineNumberView.h"
#import "CEThemeManager.h"
#import "constants.h"


@interface CEEditorView ()

@property (nonatomic) NSScrollView *scrollView;
@property (nonatomic) CELineNumberView *lineNumberView;
@property (nonatomic) NSTextStorage *textStorage;

@property (nonatomic) NSTimer *lineNumUpdateTimer;
@property (nonatomic) NSTimer *outlineMenuTimer;

@property (nonatomic) BOOL highlightsCurrentLine;
@property (nonatomic) NSInteger lastCursorLocation;


// readonly
@property (nonatomic, readwrite) CETextView *textView;
@property (nonatomic, readwrite) CENavigationBarController *navigationBar;
@property (nonatomic, readwrite) CESyntaxParser *syntaxParser;

@end





#pragma mark -

@implementation CEEditorView

#pragma mark NSView Methods

//=======================================================
// NSView method
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
        
        _highlightsCurrentLine = [defaults boolForKey:k_key_highlightCurrentLine];

        // LineNumberView 生成
        [self setLineNumberView:[[CELineNumberView alloc] initWithFrame:NSZeroRect]];
        [[self lineNumberView] setTranslatesAutoresizingMaskIntoConstraints:NO];
        [self addSubview:[self lineNumberView]];

        // navigationBar 生成
        [self setNavigationBar:[[CENavigationBarController alloc] init]];
        [self addSubview:[[self navigationBar] view]];

        // scrollView 生成
        [self setScrollView:[[NSScrollView alloc] initWithFrame:NSZeroRect]];
        [[self scrollView] setBorderType:NSNoBorder];
        [[self scrollView] setHasVerticalScroller:YES];
        [[self scrollView] setHasHorizontalScroller:YES];
        [[self scrollView] setTranslatesAutoresizingMaskIntoConstraints:NO];
        [[self scrollView] setAutohidesScrollers:NO];
        [[self scrollView] setDrawsBackground:NO];
        [[[self scrollView] contentView] setAutoresizesSubviews:YES];
        [self addSubview:[self scrollView]];
        
        // setup autolayout
        NSDictionary *views = @{@"navBar": [[self navigationBar] view],
                                @"lineNumView": [self lineNumberView],
                                @"scrollView": [self scrollView]};
        [[[self navigationBar] view] setTranslatesAutoresizingMaskIntoConstraints:NO];
        [self addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:|[navBar]|"
                                                                     options:0 metrics:nil views:views]];
        [self addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:|[lineNumView][scrollView]|"
                                                                     options:0 metrics:nil views:views]];
        [self addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|[navBar][scrollView]|"
                                                                     options:0 metrics:nil views:views]];
        [self addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:[navBar][lineNumView]|"
                                                                     options:0 metrics:nil views:views]];

        // TextStorage と LayoutManager を生成
        [self setTextStorage:[[NSTextStorage alloc] initWithString:@" "]];
        CELayoutManager *layoutManager = [[CELayoutManager alloc] init];
        [[self textStorage] addLayoutManager:layoutManager];
        [layoutManager setBackgroundLayoutEnabled:YES];
        [layoutManager setUseAntialias:[defaults boolForKey:k_key_shouldAntialias]];
        [layoutManager setFixLineHeight:[defaults boolForKey:k_key_fixLineHeight]];

        // NSTextContainer と CESyntaxParser を生成
        NSTextContainer *container = [[NSTextContainer alloc] initWithContainerSize:NSMakeSize(FLT_MAX, FLT_MAX)];
        [layoutManager addTextContainer:container];

        [self setSyntaxParser:[[CESyntaxParser alloc] initWithStyleName:NSLocalizedString(@"None", @"")
                                                          layoutManager:layoutManager
                                                             isPrinting:NO]];

        // TextView 生成
        [self setTextView:[[CETextView alloc] initWithFrame:NSZeroRect textContainer:container]];
        [[self textView] setDelegate:self];
        
        [[self lineNumberView] setTextView:[self textView]];
        [[self navigationBar] setTextView:[self textView]];
        [[self scrollView] setDocumentView:[self textView]];
        
        // OgreKit 改造でポストするようにしたノーティフィケーションをキャッチ
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(textDidReplaceAll:)
                                                     name:@"textDidReplaceAllNotification"
                                                   object:[self textView]];
        
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

        // slave view をセット
        [[self textView] setSlaveView:[self lineNumberView]]; // (the textview will also update slaveView.)
        [[self textView] setPostsBoundsChangedNotifications:YES]; // observer = lineNumberView
        [[NSNotificationCenter defaultCenter] addObserver:[self lineNumberView]
                                                 selector:@selector(updateLineNumber:)
                                                     name:NSViewBoundsDidChangeNotification
                                                   object:[[self scrollView] contentView]];
        
        // リサイズに現在行ハイライトを追従
        if (_highlightsCurrentLine) {
            [[NSNotificationCenter defaultCenter] addObserver:self
                                                     selector:@selector(highlightCurrentLine)
                                                         name:NSViewFrameDidChangeNotification
                                                       object:[[self scrollView] contentView]];
        }
    }
    return self;
}


// ------------------------------------------------------
/// 後片づけ
- (void)dealloc
// ------------------------------------------------------
{
    [self stopUpdateLineNumberTimer];
    [self stopUpdateOutlineMenuTimer];
    [[NSNotificationCenter defaultCenter] removeObserver:[self lineNumberView]];
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    [self setTextView:nil];
}



#pragma mark Public Methods

//=======================================================
// Public method
//
//=======================================================

// ------------------------------------------------------
/// テキストビューの文字列を返す
- (NSString *)string
// ------------------------------------------------------
{
    return ([[self textView] string]);
}


// ------------------------------------------------------
/// TextStorage を置換
- (void)replaceTextStorage:(NSTextStorage *)textStorage
// ------------------------------------------------------
{
    _textStorage = textStorage;
    [[[self textView] layoutManager] replaceTextStorage:textStorage];
}


// ------------------------------------------------------
/// テキストビューをエディタビューにセット
- (void)setTextViewToEditorWrapper:(CETextView *)textView
// ------------------------------------------------------
{
    [[self editorWrapper] setTextView:textView];
}


// ------------------------------------------------------
/// 行番号表示設定をセット
- (void)setShowLineNum:(BOOL)showLineNum
// ------------------------------------------------------
{
    [[self lineNumberView] setShowLineNum:showLineNum];
}


// ------------------------------------------------------
/// ナビゲーションバーを表示／非表示
- (void)setShowNavigationBar:(BOOL)showNavigationBar
// ------------------------------------------------------
{
    [[self navigationBar] setShowNavigationBar:showNavigationBar];
    if (![self outlineMenuTimer]) {
        [self updateOutlineMenu];
    }
}


// ------------------------------------------------------
/// ラップする／しないを切り替える
- (void)setWrapLines:(BOOL)wrapLines
// ------------------------------------------------------
{
    NSTextView *textView = [self textView];
    BOOL isVertical = ([textView layoutOrientation] == NSTextLayoutOrientationVertical);
    
    // 条件を揃えるためにいったん横書きに戻す (各項目の縦横の入れ替えは setLayoutOrientation: が良きに計らってくれる)
    [textView setLayoutOrientation:NSTextLayoutOrientationHorizontal];
    
    if (wrapLines) {
        [[textView enclosingScrollView] setHasHorizontalScroller:NO];
        [textView setAutoresizingMask:NSViewWidthSizable];
        [self adjustTextFrameSize];
        [[textView textContainer] setWidthTracksTextView:YES]; // (will follow the width of the textview.)
        [textView sizeToFit];
        [textView setHorizontallyResizable:NO];
    } else {
        [[textView enclosingScrollView] setHasHorizontalScroller:YES];
        [[textView textContainer] setWidthTracksTextView:NO];
        [[textView textContainer] setContainerSize:NSMakeSize(FLT_MAX, FLT_MAX)]; // set the frame size
        [textView setAutoresizingMask:NSViewNotSizable]; // (don't let it autosize, though.)
        [textView setHorizontallyResizable:YES];
    }
    
    // 縦書きモードの際は改めて縦書きにする
    if (isVertical) {
        [textView setLayoutOrientation:NSTextLayoutOrientationVertical];
    }

}


// ------------------------------------------------------
/// 不可視文字の表示／非表示を切り替える
- (void)setShowInvisibles:(BOOL)showInvisibles
// ------------------------------------------------------
{
    NSRange selectedRange;
    BOOL shouldReselect = NO;

    if (showInvisibles) {
        shouldReselect = YES;
        selectedRange = [[self textView] selectedRange];
        [[self textView] setSelectedRange:NSMakeRange(0, 0)]; // （選択範囲をリセットしておき、あとで再選択）
    }
    [(CELayoutManager *)[[self textView] layoutManager] setShowInvisibles:showInvisibles];
    [[self textView] setNeedsDisplay:YES];
    if (shouldReselect) {
        // （不可視文字が選択状態で表示／非表示を切り替えられた時、不可視文字の背景選択色を描画するための時間差での選択処理）
        // （もっとスマートな解決方法はないものか...？ 2006.09.25）
        __block CETextView *textView = [self textView];
        dispatch_async(dispatch_get_main_queue(), ^{
            [textView setSelectedRange:selectedRange];
        });
    }
}


// ------------------------------------------------------
/// ソフトタブの有効／無効を切り替える
- (void)setAutoTabExpandEnabled:(BOOL)isEnabled
// ------------------------------------------------------
{
    [[self textView] setIsAutoTabExpandEnabled:isEnabled];
}


// ------------------------------------------------------
/// アンチエイリアス適用を切り替える
- (void)setUseAntialias:(BOOL)useAntialias
// ------------------------------------------------------
{
    CELayoutManager *manager = (CELayoutManager *)[[self textView] layoutManager];

    [manager setUseAntialias:useAntialias];
    [[self textView] setNeedsDisplay:YES];
}


// ------------------------------------------------------
/// ページガイドの表示／非表示を返す
- (BOOL)showPageGuide
// ------------------------------------------------------
{
    return [[self editorWrapper] showPageGuide];
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
                                                      layoutManager:(CELayoutManager *)[[self textView] layoutManager]
                                                         isPrinting:NO]];
    
    [[self textView] setInlineCommentDelimiter:[[self syntaxParser] inlineCommentDelimiter]];
    [[self textView] setBlockCommentDelimiters:[[self syntaxParser] blockCommentDelimiters]];
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
    // 置換の Undo を判別するために OgreKit 側で登録された actionName を使用しているが、
    // ローカライズ後の名前なので、名前を決め打ちしている。あまり良い方法ではない。 (2014-04 by 1024jp)
    NSString *actionName = [undoManager isUndoing] ? [undoManager redoActionName] : [undoManager undoActionName];
    if ([@[@"一括置換", @"Replace All"] containsObject:actionName]) {
        [self textDidReplaceAll:aNotification];
    }
}


// ------------------------------------------------------
/// アウトラインメニューを更新
- (void)updateOutlineMenu
// ------------------------------------------------------
{
    [self stopUpdateOutlineMenuTimer];
    
    // 規定の文字数以上の場合にはインジケータを表示
    // （ただし、k_key_showColoringIndicatorTextLength が「0」の時は表示しない）
    NSUInteger indicatorThreshold = [[NSUserDefaults standardUserDefaults] integerForKey:k_key_showColoringIndicatorTextLength];
    if (indicatorThreshold > 0 && indicatorThreshold < [[self string] length]) {
        [[self navigationBar] showOutlineIndicator];
    }
    
    // 別スレッドでアウトラインを抽出して、メインスレッドで navigationBar に渡す
    NSString *wholeString = [[self string] copy];  // 解析中に参照元が変更されると困るのでコピーする
    __block typeof(self) blockSelf = self;
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        NSArray *outlineMenuArray = [[blockSelf syntaxParser] outlineMenuArrayWithWholeString:wholeString];
        
        dispatch_async(dispatch_get_main_queue(), ^{
            [[blockSelf navigationBar] setOutlineMenuArray:outlineMenuArray];
            // （選択項目の更新も上記メソッド内で行われるので、updateOutlineMenuSelection は呼ぶ必要なし。 2008.05.16.）
        });
    });
}


// ------------------------------------------------------
/// アウトラインメニューの選択項目を更新
- (void)updateOutlineMenuSelection
// ------------------------------------------------------
{
    if ([self outlineMenuTimer]) { return; }
    
    if ([[self textView] updateOutlineMenuItemSelection]) {
        [[self navigationBar] selectOutlineMenuItemWithRange:[[self textView] selectedRange]];
    } else {
        [[self textView] setUpdateOutlineMenuItemSelection:YES];
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
/// 入力補完文字列に設定された最初の1文字のセットを返す
- (NSCharacterSet *)firstCompletionCharacterSet
// ------------------------------------------------------
{
    return [[self syntaxParser] firstCompletionCharacterSet];
}


// ------------------------------------------------------
/// テキストビューに背景色をセット
- (void)setBackgroundColorAlpha:(CGFloat)alpha
// ------------------------------------------------------
{
    [[self textView] setBackgroundAlpha:alpha];
    [[self lineNumberView] setBackgroundAlpha:alpha];
}



#pragma mark Delegate and Notification

//=======================================================
// Delegate method (CETextView)
//  <== textView
//=======================================================

// ------------------------------------------------------
///  テキストが編集される
- (BOOL)textView:(NSTextView *)aTextView shouldChangeTextInRange:(NSRange)affectedCharRange 
        replacementString:(NSString *)replacementString
// ------------------------------------------------------
{
    // キー入力、スクリプトによる編集で改行コードをLFに統一する
    // （その他の編集は、下記の通りの別の場所で置換している）
    // # テキスト編集時の改行コードの置換場所
    //  * ファイルオープン = CEDocument > setStringToEditor
    //  * スクリプト = CEEditorView > textView:shouldChangeTextInRange:replacementString:
    //  * キー入力 = CEEditorView > textView:shouldChangeTextInRange:replacementString:
    //  * ペースト = CETextView > readSelectionFromPasteboard:type:
    //  * ドロップ（別書類または別アプリから） = CETextView > readSelectionFromPasteboard:type:
    //  * ドロップ（同一書類内） = CETextView > performDragOperation:
    //  * 検索パネルでの置換 = (OgreKit) OgreTextViewPlainAdapter > replaceCharactersInRange:withOGString:
    if (!replacementString ||  // = attributesのみの変更
        ([replacementString length] == 0) ||  // = 文章の削除
        [(CETextView *)aTextView isSelfDrop] ||  // = 自己内ドラッグ&ドロップ
        [(CETextView *)aTextView isReadingFromPboard] ||  // = ペーストまたはドロップ
        [[aTextView undoManager] isUndoing] ||  // = アンドゥ中
        [replacementString isEqualToString:@"\n"])
    {
        return YES;
    }
    
    OgreNewlineCharacter replacementLineEndingChar = [OGRegularExpression newlineCharacterInString:replacementString];
    // 挿入／置換する文字列に改行コードが含まれていたら、LF に置換する
    if ((replacementLineEndingChar != OgreNonbreakingNewlineCharacter) &&
        (replacementLineEndingChar != OgreLfNewlineCharacter)) {
        // （newStrが使用されるのはスクリプトからの入力時。キー入力は条件式を通過しない）
        NSString *newStr = [OGRegularExpression replaceNewlineCharactersInString:replacementString
                                                                   withCharacter:OgreLfNewlineCharacter];
        
        if (newStr) {
            // （Action名は自動で付けられる？ので、指定しない）
            [(CETextView *)aTextView doReplaceString:newStr
                                           withRange:affectedCharRange
                                        withSelected:NSMakeRange(affectedCharRange.location + [newStr length], 0)
                                      withActionName:@""];
            
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
    NSMutableOrderedSet *outWords = [NSMutableOrderedSet orderedSet];
    NSUInteger addingMode = [[NSUserDefaults standardUserDefaults] integerForKey:k_key_completeAddStandardWords];
    NSString *partialWord = [[textView string] substringWithRange:charRange];

    //"ファイル中の語彙" を検索して outArray に入れる
    if (addingMode != 3) {
        NSString *documentString = [textView string];
        NSString *pattern = [NSString stringWithFormat:@"(?:^|\\b|(?<=\\W))%@\\w+?(?:$|\\b)",
                             [NSRegularExpression escapedPatternForString:partialWord]];
        NSRegularExpression *regex = [NSRegularExpression regularExpressionWithPattern:pattern options:0 error:nil];
        [regex enumerateMatchesInString:documentString options:0
                                  range:NSMakeRange(0, [documentString length])
                             usingBlock:^(NSTextCheckingResult *result, NSMatchingFlags flags, BOOL *stop)
         {
             [outWords addObject:[documentString substringWithRange:[result range]]];
         }];
    }
    
    //"カラーシンタックス辞書の語彙" をコピーする
    if (addingMode >= 1) {
        NSArray *syntaxWords = [[self syntaxParser] completionWords];
        for (NSString *word in syntaxWords) {
            if ([word rangeOfString:partialWord options:NSCaseInsensitiveSearch|NSAnchoredSearch].location != NSNotFound) {
                [outWords addObject:word];
            }
        }
    }
    
    //デフォルトの候補から "一般英単語" をコピーする
    if (addingMode == 2) {
        [outWords addObjectsFromArray:words];
    }
    
    // 入力済みの単語と同じ候補しかないときは表示しない
    if ([outWords count] == 1 && [outWords[0] isEqualToString:partialWord]) {
        return nil;
    }

    return [outWords array];
}



//=======================================================
// Notification method (NSTextView)
//  <== CETextView
//=======================================================

// ------------------------------------------------------
/// text did edit.
- (void)textDidChange:(NSNotification *)aNotification
// ------------------------------------------------------
{
    // カラーリング実行
    [[self editorWrapper] setupColoringTimer];

    // 行番号、アウトラインメニュー項目、非互換文字リスト更新
    [self updateInfo];

    // フラグが立っていたら、入力補完を再度実行する
    // （フラグは CETextView > insertCompletion:forPartialWordRange:movement:isFinal: で立てている）
    if ([[self textView] isReCompletion]) {
        [[self textView] setIsReCompletion:NO];
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
    [[[self window] windowController] setupInfoUpdateTimer];

    // アウトラインメニュー選択項目更新
    [self updateOutlineMenuSelection];

    // 対応するカッコをハイライト表示
// 以下の部分は、Smultron を参考にさせていただきました。(2006.09.09)
// This method is based on Smultron.(written by Peter Borg – http://smultron.sourceforge.net)
// Smultron  Copyright (c) 2004-2005 Peter Borg, All rights reserved.
// Smultron is released under GNU General Public License, http://www.gnu.org/copyleft/gpl.html

    if (![[NSUserDefaults standardUserDefaults] boolForKey:k_key_highlightBraces]) { return; }
    
    NSString *string = [self string];
    NSInteger stringLength = [string length];
    if (stringLength == 0) { return; }
    NSRange selectedRange = [[self textView] selectedRange];
    NSInteger location = selectedRange.location;
    NSInteger difference = location - [self lastCursorLocation];
    [self setLastCursorLocation:location];

    // Smultron では「if (difference != 1 && difference != -1)」の条件を使ってキャレットを前方に動かした時も強調表示させているが、CotEditor では Xcode 同様、入力時またはキャレットを後方に動かした時だけに限定した（2006.09.10）
    if (difference != 1) {
        return; // If the difference is more than one, they've moved the cursor with the mouse or it has been moved by resetSelectedRange below and we shouldn't check for matching braces then
    }
    
    if (difference == 1) { // Check if the cursor has moved forward
        location--;
    }

    if (location == stringLength) {
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
    } else if ((theUnichar == '>') && [[NSUserDefaults standardUserDefaults] boolForKey:k_key_highlightLtGt]) {
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


//=======================================================
// Notification method (OgreKit 改)
//  <== OgreReplaceAllThread
//=======================================================

// ------------------------------------------------------
/// did Replace All
- (void)textDidReplaceAll:(NSNotification *)aNotification
// ------------------------------------------------------
{
    // 文書情報更新（選択範囲・キャレット位置が変更されないまま全置換が実行された場合への対応）
    [[[self window] windowController] setupInfoUpdateTimer];
    
    // 行番号、アウトラインメニュー項目、非互換文字リスト更新
    [self updateInfo];
    
    // 全テキストを再カラーリング
    [self recolorAllTextViewString];
}



#pragma mark Private Mthods

//=======================================================
// Private method
//
//=======================================================

// ------------------------------------------------------
/// ラップする時にサイズを適正化する
- (void)adjustTextFrameSize
// ------------------------------------------------------
{
    NSInteger newWidth = [[self scrollView] contentSize].width;

    newWidth -= (NSWidth([[self lineNumberView] frame]) + k_lineNumPadding * 2 );
    [[[self textView] textContainer] setContainerSize:NSMakeSize(newWidth, FLT_MAX)];
}


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


// ------------------------------------------------------
/// 行番号更新
- (void)updateLineNumberWithTimer:(NSTimer *)timer
// ------------------------------------------------------
{
    [self stopUpdateLineNumberTimer];
    [[self lineNumberView] updateLineNumber:self];
}


// ------------------------------------------------------
/// アウトラインメニュー更新
- (void)updateOutlineMenuWithTimer:(NSTimer *)timer
// ------------------------------------------------------
{
    [self updateOutlineMenu]; // （updateOutlineMenu 内で stopUpdateOutlineMenuTimer を実行している）
}


// ------------------------------------------------------
/// 行番号表示、アウトラインメニューなどを更新
- (void)updateInfo
// ------------------------------------------------------
{
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    
    // 行番号更新
    NSTimeInterval lineNumUpdateInterval = [defaults doubleForKey:k_key_lineNumUpdateInterval];
    if ([self lineNumUpdateTimer]) {
        [[self lineNumUpdateTimer] setFireDate:[NSDate dateWithTimeIntervalSinceNow:lineNumUpdateInterval]];
    } else {
        [self setLineNumUpdateTimer:[NSTimer scheduledTimerWithTimeInterval:lineNumUpdateInterval
                                                                     target:self
                                                                   selector:@selector(updateLineNumberWithTimer:)
                                                                   userInfo:nil
                                                                    repeats:NO]];
    }

    // アウトラインメニュー項目更新
    NSTimeInterval outlineMenuInterval = [defaults doubleForKey:k_key_outlineMenuInterval];
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
    [[[self window] windowController] setupIncompatibleCharTimer];
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
    if ([textView selectedRange].location == [[self string] length] && [layoutManager extraLineFragmentTextContainer]) {  // 最終行
        rect = [layoutManager extraLineFragmentRect];
        
    } else {
        NSRange lineRange = [[self string] lineRangeForRange:[textView selectedRange]];
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
