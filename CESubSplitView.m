/*
=================================================
CESubSplitView
(for CotEditor)

Copyright (C) 2004-2007 nakamuxu.
http://www.aynimac.com/
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

#import "CESubSplitView.h"

//=======================================================
// Private method
//
//=======================================================

@interface CESubSplitView (Private)
- (void)adjustTextFrameSize;
- (void)doUpdateLineNumberWithTimer:(NSTimer *)inTimer;
- (void)doUpdateOutlineMenuWithTimer:(NSTimer *)inTimer;
- (void)resetBackgroundColor:(id)sender;
- (void)updateInfo;
- (void)showHighlightCurrentLine;
@end


//------------------------------------------------------------------------------------------




@implementation CESubSplitView

#pragma mark ===== Public method =====

//=======================================================
// Public method
//
//=======================================================

// ------------------------------------------------------
- (id)initWithFrame:(NSRect)inFrame
// 初期化
// ------------------------------------------------------
{
    self = [super initWithFrame:inFrame];

    if (self) {

        id theValues = [[NSUserDefaultsController sharedUserDefaultsController] values];

        _lastCursorLocation = 0;

        // LineNumView 生成
        NSRect theLineMumFrame = inFrame;
        theLineMumFrame.size.width = 0.0; // default width (about invisible).
        _lineNumView = [[CELineNumView allocWithZone:[self zone]] initWithFrame:theLineMumFrame];
        [_lineNumView setMasterView:self];
        [self addSubview:_lineNumView];

        // navigationBar 生成
        NSRect theNavigationFrame = inFrame;
        theNavigationFrame.origin.y = NSHeight(theNavigationFrame);
        theNavigationFrame.size.height = 0.0;
        _navigationBar = [[CENavigationBarView allocWithZone:[self zone]] initWithFrame:theNavigationFrame];
        [_navigationBar setMasterView:self];
        [self addSubview:_navigationBar];

        _scrollView = [[NSScrollView allocWithZone:[self zone]] initWithFrame:inFrame]; // ===== alloc
        [_scrollView setBorderType:NSNoBorder];
        [_scrollView setHasVerticalScroller:YES];
        [_scrollView setHasHorizontalScroller:YES];
        [_scrollView setAutoresizingMask:(NSViewWidthSizable | NSViewHeightSizable)];
        [_scrollView setAutohidesScrollers:NO];
        [_scrollView setDrawsBackground:NO];
        [[_scrollView contentView] setAutoresizesSubviews:YES];
        // （splitViewをリサイズした時に最後までナビバーを表示させるため、その下に配置する）
        [self addSubview:_scrollView positioned:NSWindowBelow relativeTo:_navigationBar];

        // TextStorage と LayoutManager を生成
        _textStorage = [[NSTextStorage allocWithZone:[self zone]] init]; // ===== alloc
        CELayoutManager *theLayoutManager = [[CELayoutManager allocWithZone:[self zone]] init]; // ===== alloc
        [_textStorage addLayoutManager:theLayoutManager];
        [theLayoutManager setBackgroundLayoutEnabled:YES];
        [theLayoutManager setUseAntialias:[[theValues valueForKey:k_key_shouldAntialias] boolValue]];
        [theLayoutManager setFixLineHeight:[[theValues valueForKey:k_key_fixLineHeight] boolValue]];

        // NSTextContainer と CESyntax を生成
        NSTextContainer *theTextContainer = [[NSTextContainer allocWithZone:[self zone]] 
                    initWithContainerSize:NSMakeSize(FLT_MAX, FLT_MAX)]; // ===== alloc
        [theLayoutManager addTextContainer:theTextContainer];

        _syntax = [[CESyntax allocWithZone:[self zone]] init]; // ===== alloc
        [_syntax setSyntaxStyleName:NSLocalizedString(@"None",@"")];
        [_syntax setLayoutManager:theLayoutManager];
        [_syntax setIsPrinting:NO];

        // TextView 生成
        NSRect theTextFrame;
        theTextFrame.origin = NSZeroPoint;
        theTextFrame.size = [_scrollView contentSize]; // (frame will start at upper left.)
        _textViewCore = [[CETextViewCore allocWithZone:[self zone]] 
                    initWithFrame:theTextFrame textContainer:theTextContainer]; // ===== alloc
        [_textViewCore setDelegate:self];
        // OgreKit 改造でポストするようにしたノーティフィケーションをキャッチ
        [[NSNotificationCenter defaultCenter] addObserver:self 
                    selector:@selector(textDidReplaceAll:) 
                    name:@"textDidReplaceAllNotification" 
                    object:_textViewCore];
        [_scrollView setDocumentView:_textViewCore];

        // slave view をセット
        [_textViewCore setSlaveView:_lineNumView]; // (the textview will also update slaveView.)
        [_textViewCore setPostsBoundsChangedNotifications:YES]; // observer = _lineNumView
        [[NSNotificationCenter defaultCenter] addObserver:_lineNumView 
                    selector:@selector(updateLineNumber:) 
                    name:NSViewBoundsDidChangeNotification 
                    object:[_scrollView contentView]];

        // ビューのパラメータをセット
        [_textViewCore setTextContainerInset:
                NSMakeSize((CGFloat)[[theValues valueForKey:k_key_textContainerInsetWidth] doubleValue],
                           ((CGFloat)[[theValues valueForKey:k_key_textContainerInsetHeightTop] doubleValue] +
                            (CGFloat)[[theValues valueForKey:k_key_textContainerInsetHeightBottom] doubleValue]) / 2
                           )];
        _lineNumUpdateTimer = nil;
        _outlineMenuTimer = nil;
        _lineNumUpdateInterval = [[theValues valueForKey:k_key_lineNumUpdateInterval] doubleValue];
        _outlineMenuInterval = [[theValues valueForKey:k_key_outlineMenuInterval] doubleValue];
        _highlightBracesColorDict = [[NSDictionary alloc] initWithObjectsAndKeys:
                    [NSUnarchiver unarchiveObjectWithData:[theValues valueForKey:k_key_selectionColor]], 
                    NSBackgroundColorAttributeName, nil]; // ===== alloc
        _highlightCurrentLine = [[theValues valueForKey:k_key_highlightCurrentLine] boolValue];
        _setHiliteLineColorToIMChars = [[theValues valueForKey:k_key_setHiliteLineColorToIMChars] boolValue];
        _hadMarkedText = NO;

        // システム側で保持されるオブジェクトを解放
        [theLayoutManager release]; // ===== release
        [theTextContainer release]; // ===== release

    }
    return self;
}


// ------------------------------------------------------
- (void)dealloc
// 後片づけ
// ------------------------------------------------------
{
    [self stopUpdateLineNumberTimer];
    [self stopUpdateOutlineMenuTimer];
    [self setEditorView:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:_lineNumView];
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    [_syntax release];

    [[self textView] setDelegate:nil];
    [[self textView] release]; // release from myself

    // release "Text System" == NSTextStorage, CELayoutManager, NSTextContainer, CETextViewCore.
    [_textStorage release];

    [_scrollView release];
    [_lineNumView release];
    [_navigationBar release];

    [_highlightBracesColorDict release];

    [super dealloc];
}


// ------------------------------------------------------
- (void)releaseEditorView
// _editorView 開放
// ------------------------------------------------------
{
    // （dealloc は親階層から行われるため、あらかじめ「子」が持っている「親」を開放しておく）
    [self setEditorView:nil];
}


// ------------------------------------------------------
- (CEEditorView *)editorView
// エディタビューを返す
// ------------------------------------------------------
{
    return _editorView;
}


// ------------------------------------------------------
- (void)setEditorView:(CEEditorView *)inEditorView
// エディタビューをセット
// ------------------------------------------------------
{
    [inEditorView retain];
    [_editorView release];
    _editorView = inEditorView;
}


// ------------------------------------------------------
- (NSScrollView *)scrollView
// スクロールビューを返す
// ------------------------------------------------------
{
    return _scrollView;
}


// ------------------------------------------------------
- (CETextViewCore *)textView
// テキストビューを返す
// ------------------------------------------------------
{
    return _textViewCore;
}


// ------------------------------------------------------
- (CELineNumView *)lineNumView
// 行番号ビューを返す
// ------------------------------------------------------
{
    return _lineNumView;
}


// ------------------------------------------------------
- (CENavigationBarView *)navigationBar
// ナビゲーションバービューを返す
// ------------------------------------------------------
{
    return _navigationBar;
}


// ------------------------------------------------------
- (CESyntax *)syntax
// syntax を返す
// ------------------------------------------------------
{
    return _syntax;
}


// ------------------------------------------------------
- (NSString *)string
// テキストビューの文字列を返す
// ------------------------------------------------------
{
    return ([[self textView] string]);
}


// ------------------------------------------------------
- (void)viewDidEndLiveResize
// ライブリサイズが終了した
// ------------------------------------------------------
{
    // ナビゲーションバーを表示させているときにスプリットビューを最小までリサイズしてから広げると、テキストが
    // ナビバーを上書きしてしまうことへの対応措置。
    if ([[self editorView] showNavigationBar]) {
        [[self scrollView] setFrameSize:
                NSMakeSize([[self scrollView] frame].size.width, 
                    [self frame].size.height - k_navigationBarHeight)];
    }
}


// ------------------------------------------------------
- (void)replaceTextStorage:(NSTextStorage *)inTextStorage
// TextStorage を置換
// ------------------------------------------------------
{
    [inTextStorage retain];
    [_textStorage release];
    _textStorage = inTextStorage;
    [[[self textView] layoutManager] replaceTextStorage:inTextStorage];
}


// ------------------------------------------------------
- (BOOL)isWritable
// ドキュメントが書き込みできるかどうかを返す
// ------------------------------------------------------
{
    return [[self editorView] isWritable];
}


// ------------------------------------------------------
- (BOOL)isAlertedNotWritable
// 「書き込み禁止」アラートを表示したかどうかを返す
// ------------------------------------------------------
{
    return [[self editorView] isAlertedNotWritable];
}


// ------------------------------------------------------
- (void)setTextViewToEditorView:(CETextViewCore *)inTextView
// テキストビューをエディタビューにセット
// ------------------------------------------------------
{
    [[self editorView] setTextView:inTextView];
}


// ------------------------------------------------------
- (void)setShowLineNumWithNumber:(NSNumber *)inNumber
// 行番号表示設定をセット
// ------------------------------------------------------
{
    [[self lineNumView] setShowLineNum:[inNumber boolValue]];
}


// ------------------------------------------------------
- (void)setShowNavigationBarWithNumber:(NSNumber *)inNumber
// ナビゲーションバーを表示／非表示
// ------------------------------------------------------
{
    [[self navigationBar] setShowNavigationBar:[inNumber boolValue]];
    if (!_outlineMenuTimer) {
        [self updateOutlineMenu];
    }
}


// ------------------------------------------------------
- (void)setWrapLinesWithNumber:(NSNumber *)inNumber
// ラップする／しないを切り替える
// ------------------------------------------------------
{
    if ([inNumber boolValue]) {
        [[[self textView] enclosingScrollView] setHasHorizontalScroller:NO];
        [[self textView] setAutoresizingMask:NSViewWidthSizable];
        [self adjustTextFrameSize];
        [[[self textView] textContainer] setWidthTracksTextView:YES]; // (will follow the width of the textview.)
        [[self textView] sizeToFit];
        [[self textView] setHorizontallyResizable:NO];
    } else {
        [[[self textView] enclosingScrollView] setHasHorizontalScroller:YES];
        [[[self textView] textContainer] setWidthTracksTextView:NO];
        [[[self textView] textContainer] setContainerSize:NSMakeSize(FLT_MAX, FLT_MAX)]; // set the frame size
        [[self textView] setAutoresizingMask:NSViewNotSizable]; // (don't let it autosize, though.)
        [[self textView] setHorizontallyResizable:YES];
    }

}


// ------------------------------------------------------
- (void)setShowInvisiblesWithNumber:(NSNumber *)inNumber
// 不可視文字の表示／非表示を切り替える
// ------------------------------------------------------
{
    NSRange theSelectedRange;
    BOOL theBoolReSelect = NO;

    if ([inNumber boolValue]) {
        theBoolReSelect = YES;
        theSelectedRange = [[self textView] selectedRange];
        [[self textView] setSelectedRange:NSMakeRange(0, 0)]; // （選択範囲をリセットしておき、あとで再選択）
    }
    [(CELayoutManager *)[[self textView] layoutManager] setShowInvisibles:[inNumber boolValue]];
    [[self textView] setNeedsDisplay:YES];
    if (theBoolReSelect) {
        // （不可視文字が選択状態で表示／非表示を切り替えられた時、不可視文字の背景選択色を描画するための時間差での選択処理）
        // （もっとスマートな解決方法はないものか...？ 2006.09.25）
        [[self textView] performSelector:@selector(selectTextRangeValue:) 
                withObject:[NSValue valueWithRange:theSelectedRange] afterDelay:0];
    }
}


// ------------------------------------------------------
- (void)setUseAntialiasWithNumber:(NSNumber *)inNumber
// アンチエイリアス適用を切り替える
// ------------------------------------------------------
{
    CELayoutManager *theManager = (CELayoutManager *)[[self textView] layoutManager];

    [theManager setUseAntialias:[inNumber boolValue]];
    [[self textView] setNeedsDisplay:YES];
}


// ------------------------------------------------------
- (BOOL)showPageGuide
// ページガイドの表示／非表示を返す
// ------------------------------------------------------
{
    return [[self editorView] showPageGuide];
}


// ------------------------------------------------------
- (void)setCaretToBeginning
// キャレットを先頭に移動
// ------------------------------------------------------
{
    [[self textView] setSelectedRange:NSMakeRange(0, 0)];
}


// ------------------------------------------------------
- (void)setSyntaxStyleNameToSyntax:(NSString *)inName
// シンタックススタイルを設定
// ------------------------------------------------------
{
    [[self syntax] setSyntaxStyleName:inName];
}


// ------------------------------------------------------
- (void)recoloringAllTextViewString
// 全てを再カラーリング
// ------------------------------------------------------
{
    [[self syntax] colorAllString:[[self textView] string]];
}


// ------------------------------------------------------
- (void)updateOutlineMenu
// アウトラインメニューを更新
// ------------------------------------------------------
{
    [self stopUpdateOutlineMenuTimer];
    [[self navigationBar] setOutlineMenuArray:
            [[[self editorView] syntax] outlineMenuArrayWithWholeString:[self string]]];
    // （選択項目の更新も上記メソッド内で行われるので、updateOutlineMenuSelection は呼ぶ必要なし。 2008.05.16.）
}


// ------------------------------------------------------
- (void)updateOutlineMenuSelection
// アウトラインメニューの選択項目を更新
// ------------------------------------------------------
{
    if (!_outlineMenuTimer) {
        if ([[self textView] updateOutlineMenuItemSelection]) {
            [[self navigationBar] performSelector:@selector(selectOutlineMenuItemWithRangeValue:) 
                        withObject:[NSValue valueWithRange:[[self textView] selectedRange]] 
                        afterDelay:0.01];
        } else {
            [[self textView] setUpdateOutlineMenuItemSelection:YES];
            [[self navigationBar] performSelector:@selector(updatePrevNextButtonEnabled) withObject:nil 
                        afterDelay:0.01];
        }
    }
}


// ------------------------------------------------------
- (void)updateCloseSubSplitViewButtonWithNumber:(NSNumber *)inNumber
// テキストビュー分割削除ボタンの有効化／無効化を制御
// ------------------------------------------------------
{
    [[self navigationBar] setCloseSplitButtonEnabled:[inNumber boolValue]];
}


// ------------------------------------------------------
- (void)stopUpdateLineNumberTimer
// 行番号更新タイマーを停止
// ------------------------------------------------------
{
    if (_lineNumUpdateTimer) {
        [_lineNumUpdateTimer invalidate];
        [_lineNumUpdateTimer release]; // ===== release
        _lineNumUpdateTimer = nil;
    }
}


// ------------------------------------------------------
- (void)stopUpdateOutlineMenuTimer
// アウトラインメニュー更新タイマーを停止
// ------------------------------------------------------
{
    if (_outlineMenuTimer) {
        [_outlineMenuTimer invalidate];
        [_outlineMenuTimer release]; // ===== release
        _outlineMenuTimer = nil;
    }
}


// ------------------------------------------------------
- (NSCharacterSet *)completionsFirstLetterSet
// 入力補完文字列に設定された最初の1文字のセットを返す
// ------------------------------------------------------
{
    return [[self syntax] completeFirstLetterSet];
}


// ------------------------------------------------------
- (NSDictionary *)highlightBracesColorDict
// ハイライトカラー辞書を返す
// ------------------------------------------------------
{
    return _highlightBracesColorDict;
}


// ------------------------------------------------------
- (void)setBackgroundColorAlphaWithNumber:(NSNumber *)inNumber
// テキストビューに背景色をセット
// ------------------------------------------------------
{
    [[self textView] setBackgroundColorWithAlpha:(CGFloat)[inNumber doubleValue]];
}



#pragma mark === Delegate and Notification ===

//=======================================================
// Delegate method (CETextViewCore)
//  <== _textViewCore
//=======================================================

// ------------------------------------------------------
- (BOOL)textView:(NSTextView *)inTextView shouldChangeTextInRange:(NSRange)inAffectedCharRange 
        replacementString:(NSString *)inReplacementString
//  テキストが編集される
// ------------------------------------------------------
{
    // キー入力、スクリプトによる編集で行末コードをLFに統一する
    // （その他の編集は、下記の通りの別の場所で置換している）
    // # テキスト編集時の行末コードの置換場所
    //  * ファイルオープン = CEEditorView > setString:
    //  * キー入力 = CESubSplitView > textView:shouldChangeTextInRange:replacementString:
    //  * ペースト = CETextViewCore > readSelectionFromPasteboard:type:
    //  * ドロップ（同一書類内） = CETextViewCore > performDragOperation:
    //  * ドロップ（別書類または別アプリから） = CETextViewCore > readSelectionFromPasteboard:type:
    //  * スクリプト = CESubSplitView > textView:shouldChangeTextInRange:replacementString:
    //  * 検索パネルでの置換 = (OgreKit) OgreTextViewPlainAdapter > replaceCharactersInRange:withOGString:

    if ((inReplacementString == nil) || // = attributesのみの変更
            ([inReplacementString length] == 0) || // = 文章の削除
            ([(CETextViewCore *)inTextView isSelfDrop]) || // = 自己内ドラッグ&ドロップ
            ([(CETextViewCore *)inTextView isReadingFromPboard]) || // = ペーストまたはドロップ
            ([[inTextView undoManager] isUndoing])) { return YES; } // = アンドゥ中

    NSString *theNewStr = nil;

    if (![inReplacementString isEqualToString:@"\n"]) {
        OgreNewlineCharacter theReplacementLineEndingChar = 
                    [OGRegularExpression newlineCharacterInString:inReplacementString];
        // 挿入／置換する文字列に行末コードが含まれていたら、LF に置換する
        if ((theReplacementLineEndingChar != OgreNonbreakingNewlineCharacter) && 
                (theReplacementLineEndingChar != OgreLfNewlineCharacter)) {
            // （theNewStrが使用されるのはスクリプトからの入力時。キー入力は条件式を通過しない）
            theNewStr = [OGRegularExpression replaceNewlineCharactersInString:inReplacementString 
                    withCharacter:OgreLfNewlineCharacter];
        }
    }
    if (theNewStr != nil) {
        // （Action名は自動で付けられる？ので、指定しない）
        [(CETextViewCore *)inTextView doReplaceString:theNewStr withRange:inAffectedCharRange 
                withSelected:NSMakeRange(inAffectedCharRange.location + [theNewStr length], 0) 
                withActionName:@""];

        return NO;
    }
    return YES;
}


// ------------------------------------------------------
- (NSArray *)textView:(NSTextView *)inTextView completions:(NSArray *)inWordsArray 
        forPartialWordRange:(NSRange)inCharRange indexOfSelectedItem:(NSInteger *)inIndex
// 補完候補リストをセット
// ------------------------------------------------------
{
    // This method is based on Smultron(SMLSyntaxColouring.m)
    //  written by Peter Borg. Copyright (C) 2004 Peter Borg.
    // http://smultron.sourceforge.net

    id theValues = [[NSUserDefaultsController sharedUserDefaultsController] values];
    NSUInteger theAddingStandard = [[theValues valueForKey:k_key_completeAddStandardWords] unsignedIntegerValue];
    NSMutableArray *outArray = [NSMutableArray arrayWithCapacity:[inWordsArray count]];
    NSEnumerator *theEnumerator;
    NSString *theCurStr = [[inTextView string] substringWithRange:inCharRange];
    NSString *theArrayStr;

    //"ファイル中の語彙" を検索して outArray に入れる
    {
        OGRegularExpression *regex = [OGRegularExpression regularExpressionWithString: 
            [NSString stringWithFormat:@"(?:^|\\b|(?<=\\W))%@\\w+?(?:$|\\b)", 
                [OGRegularExpression regularizeString:theCurStr]]];
        theEnumerator = [regex matchEnumeratorInString:[inTextView string]];
        OGRegularExpressionMatch *match;
        while (match = [theEnumerator nextObject]) {
            if (![outArray containsObject:[match matchedString]]) {
                [outArray addObject:[match matchedString]];
            }
        }
    }
    
    //"カラーシンタックス辞書の語彙" をコピーする
    if (theAddingStandard >= 1) {
        NSArray *syntaxWordsArray = [_syntax completeWordsArray];
        theEnumerator = [syntaxWordsArray objectEnumerator];
        while (theArrayStr = [theEnumerator nextObject]) 
            if ([theArrayStr rangeOfString:theCurStr options:NSCaseInsensitiveSearch 
                                     range:NSMakeRange(0, [theArrayStr length])].location == 0 && 
                ![outArray containsObject:theArrayStr]) 
                [outArray addObject:theArrayStr];
    }
    
    //デフォルトの候補から "一般英単語" をコピーする
    if (theAddingStandard >= 2) {
        theEnumerator = [inWordsArray objectEnumerator];
        while (theArrayStr = [theEnumerator nextObject]) {
            //デフォルトの候補は "ファイル中の語彙" "一般英単語" の順に並んでいる
            //そのうち "ファイル中の語彙" 部分をスキップする
            if (![outArray containsObject:theArrayStr]) {
                [outArray addObject:theArrayStr];
                [outArray addObjectsFromArray:[theEnumerator allObjects]];
                break;
            }
        }
    }

    return outArray;
}



//=======================================================
// Notification method (NSTextView)
//  <== CETextViewCore
//=======================================================

// ------------------------------------------------------
- (void)textDidChange:(NSNotification *)inNotification
// text did edit.
// ------------------------------------------------------
{
    // カラーリング実行
    [[self editorView] setColoringTimer];

    // 行番号、アウトラインメニュー項目、非互換文字リスト更新
    [self updateInfo];

    // フラグが立っていたら、入力補完を再度実行する
    // （フラグは CETextViewCore > insertCompletion:forPartialWordRange:movement:isFinal: で立てている）
    if ([[self textView] isReCompletion]) {
        [[self textView] setIsReCompletion:NO];
        [[self textView] performSelector:@selector(complete:) withObject:nil afterDelay:0.05];
    }
}


// ------------------------------------------------------
- (void)textViewDidChangeSelection:(NSNotification *)inNotification
// the selection of main textView was changed.
// ------------------------------------------------------
{
    id theValues = [[NSUserDefaultsController sharedUserDefaultsController] values];

    // カレント行をハイライト
    [self showHighlightCurrentLine];

    // 文書情報更新
    [[self editorView] setInfoUpdateTimer];

    // アウトラインメニュー選択項目更新
    [self updateOutlineMenuSelection];

    // 対応するカッコをハイライト表示
// 以下の部分は、Smultron を参考にさせていただきました。(2006.09.09)
// This method is based on Smultron.(written by Peter Borg – http://smultron.sourceforge.net)
// Smultron  Copyright (c) 2004-2005 Peter Borg, All rights reserved.
// Smultron is released under GNU General Public License, http://www.gnu.org/copyleft/gpl.html

    if ([[theValues valueForKey:k_key_highlightBraces] boolValue] == NO) {
        return;
    }
    NSString *theString = [self string];
    NSInteger theStringLength = [theString length];
    if (theStringLength == 0) { return; }
    NSRange theSelectedRange = [[self textView] selectedRange];
    NSInteger theLocation = theSelectedRange.location;
    NSInteger theDifference = theLocation - _lastCursorLocation;
    _lastCursorLocation = theLocation;

    // Smultron では「if (theDifference != 1 && theDifference != -1)」の条件を使ってキャレットを前方に動かした時も強調表示させているが、CotEditor では Xcode 同様、入力時またはキャレットを後方に動かした時だけに限定した（2006.09.10）
    if (theDifference != 1) {
        return; // If the difference is more than one, they've moved the cursor with the mouse or it has been moved by resetSelectedRange below and we shouldn't check for matching braces then
    }
    
    if (theDifference == 1) { // Check if the cursor has moved forward
        theLocation--;
    }

    if (theLocation == theStringLength) {
        return;
    }

    unichar theUnichar = [theString characterAtIndex:theLocation];
    unichar theCurChar, theBraceChar;
    if (theUnichar == ')') {
        theBraceChar = k_braceCharList[0];
    } else if (theUnichar == ']') {
        theBraceChar = k_braceCharList[1];
    } else if (theUnichar == '}') {
        theBraceChar = k_braceCharList[2];
    } else if ((theUnichar == '>') && ([[theValues valueForKey:k_key_highlightLtGt] boolValue])) {
        theBraceChar = k_braceCharList[3];
    } else {
        return;
    }
    NSUInteger theSkipMatchingBrace = 0;
    theCurChar = theUnichar;

    while (theLocation--) {
        theUnichar = [theString characterAtIndex:theLocation];
        if (theUnichar == theBraceChar) {
            if (!theSkipMatchingBrace) {
                [[[self textView] layoutManager] addTemporaryAttributes:[self highlightBracesColorDict] 
                        forCharacterRange:NSMakeRange(theLocation, 1)];
                [self performSelector:@selector(resetBackgroundColor:) 
                        withObject:NSStringFromRange(NSMakeRange(theLocation, 1)) afterDelay:0.12];
                return;
            } else {
                theSkipMatchingBrace--;
            }
        } else if (theUnichar == theCurChar) {
            theSkipMatchingBrace++;
        }
    }
    NSBeep();
}


//=======================================================
// Notification method (OgreKit 改)
//  <== OgreReplaceAllThread
//=======================================================

// ------------------------------------------------------
- (void)textDidReplaceAll:(NSNotification *)inNotification
// did Replace All
// ------------------------------------------------------
{
    // 文書情報更新（選択範囲・キャレット位置が変更されないまま全置換が実行された場合への対応）
    [[self editorView] setInfoUpdateTimer];
    // 全テキストを再カラーリング
    [self performSelector:@selector(recoloringAllTextViewString) withObject:nil afterDelay:0];
    // 行番号、アウトラインメニュー項目、非互換文字リスト更新
    [self updateInfo];
}



@end



@implementation CESubSplitView (Private)

//=======================================================
// Private method
//
//=======================================================

// ------------------------------------------------------
- (void)adjustTextFrameSize
// ラップする時にサイズを適正化する
// ------------------------------------------------------
{
    NSInteger theNewWidth = [[self scrollView] contentSize].width;

    theNewWidth -= (NSWidth([[self lineNumView] frame]) + k_lineNumPadding * 2 );
    [[[self textView] textContainer] setContainerSize:NSMakeSize(theNewWidth, FLT_MAX)];
}


// ------------------------------------------------------
- (void)doUpdateLineNumberWithTimer:(NSTimer *)inTimer
// 行番号更新
// ------------------------------------------------------
{
    [self stopUpdateLineNumberTimer];
    [[self lineNumView] updateLineNumber:self];
}


// ------------------------------------------------------
- (void)doUpdateOutlineMenuWithTimer:(NSTimer *)inTimer
// アウトラインメニュー更新
// ------------------------------------------------------
{
    [self updateOutlineMenu]; // （updateOutlineMenu 内で stopUpdateOutlineMenuTimer を実行している）
}


// ------------------------------------------------------
- (void)resetBackgroundColor:(id)sender
// 対応カッコハイライト表示をリセット
// ------------------------------------------------------
{
    [[[self textView] layoutManager] removeTemporaryAttribute:NSBackgroundColorAttributeName 
            forCharacterRange:NSRangeFromString(sender)];
}


// ------------------------------------------------------
- (void)updateInfo
// 行番号表示、アウトラインメニューなどを更新
// ------------------------------------------------------
{
    // 行番号更新
    if (_lineNumUpdateTimer) {
        [_lineNumUpdateTimer setFireDate:[NSDate dateWithTimeIntervalSinceNow:_lineNumUpdateInterval]];
    } else {
        _lineNumUpdateTimer = [[NSTimer scheduledTimerWithTimeInterval:_lineNumUpdateInterval 
                    target:self 
                    selector:@selector(doUpdateLineNumberWithTimer:) 
                    userInfo:nil repeats:NO] retain]; // ===== retain
    }

    // アウトラインメニュー項目更新
    if (_outlineMenuTimer) {
        [_outlineMenuTimer setFireDate:[NSDate dateWithTimeIntervalSinceNow:_outlineMenuInterval]];
    } else {
        _outlineMenuTimer = [[NSTimer scheduledTimerWithTimeInterval:_outlineMenuInterval 
                    target:self 
                    selector:@selector(doUpdateOutlineMenuWithTimer:) 
                    userInfo:nil repeats:NO] retain]; // ===== retain
    }

    // 非互換文字リスト更新
    [[self editorView] setIncompatibleCharTimer];
}


// ------------------------------------------------------
- (void)showHighlightCurrentLine
// カレント行をハイライト表示
// ------------------------------------------------------
{
    if (!_highlightCurrentLine) { return; }

// IMでの仮名漢字変換中に背景色がカレント行ハイライト色でなくテキスト背景色になることがあるため、行の文字数の変化や追加描画矩形の
// 比較では、描画をパスできない。
// hasMarkedText を使っても、変換確定の直前直後の区別がつかないことがあるので、愚直に全工程を実行している。 2008.05.31.

    CELayoutManager *theLayoutManager = (CELayoutManager *)[[self textView] layoutManager];

// グリフがないときはそのまま戻ると、全くハイライトされないことと、アンドゥで描画が乱れるため、実行する。2008.06.21.
//    NSUInteger theNumOfGlyphs = [theLayoutManager numberOfGlyphs];
//    if (theNumOfGlyphs == 0) { return; }
    NSRange theSelectedRange = [[self textView] selectedRange];
    NSRange theLineRange = [[self string] lineRangeForRange:theSelectedRange];

    // 文字背景色でハイライトされる矩形を取得
    NSRange theGlyphRange = 
                [theLayoutManager glyphRangeForCharacterRange:theLineRange actualCharacterRange:NULL];
    NSRect theAttrsRect = [theLayoutManager boundingRectForGlyphRange:theGlyphRange 
                            inTextContainer:[[self textView] textContainer]];
    // 10.5.5でdeleteキーで最終行の文字をすべて削除すると、ハイライトが文頭に移動してしまう。これはboundingRectForGlyphRange:inTextContainer:でZeroRectが返ってきてしまうために起こる。extraLineFragmentRectも試したが、やはりZeroRectしか返ってこなかった。この不具合を迂回するための条件式を設定したが、最後に削除した文字列の背景部分のみハイライトしないままになる問題が残ってる。2008.11.15
    if (([[self string] length] == 0) || 
            ((!NSEqualRects(theAttrsRect, NSZeroRect)) && ([[self string] length] > 0))) {
        // 文字背景色を塗っても右側に生じる「空白」の矩形を得る
        CGFloat theAdditionalWidth = [[[self textView] textContainer] containerSize].width
                        - theAttrsRect.size.width - theAttrsRect.origin.x
                        - [[self textView] textContainerInset].width
                        - [[[self textView] textContainer] lineFragmentPadding];
        NSRect theAdditionalRect = NSMakeRect(NSMaxX(theAttrsRect), 
                    NSMinY(theAttrsRect) + [[self textView] textContainerOrigin].y, theAdditionalWidth, 
                    [theLayoutManager lineHeight]);
    //NSLog(NSStringFromRange(theGlyphRange));
    //NSLog(NSStringFromRect(theAttrsRect));
    //NSLog(NSStringFromRange(theLineRange));

        // 追加描画矩形を描画する
        if (!NSEqualRects([[self textView] highlightLineAdditionalRect], theAdditionalRect)) {
            [[self textView] setNeedsDisplayInRect:[[self textView] highlightLineAdditionalRect]];
            [[self textView] setHighlightLineAdditionalRect:theAdditionalRect];
            [[self textView] setNeedsDisplayInRect:theAdditionalRect];
        }
    }

    // 古い範囲の文字背景色を削除し、新しい範囲にセット
    BOOL theBoolSetBackgroundColor = _setHiliteLineColorToIMChars ? YES : 
                    ((_hadMarkedText == [[self textView] hasMarkedText]) && 
                                    (!NSEqualRanges(_hilightedLineRange, theLineRange)));
    if (theBoolSetBackgroundColor) {

        NSColor *theHighlightColor = [[[self textView] highlightLineColor] colorWithAlphaComponent:
                    [[[self textView] backgroundColor] alphaComponent]];
        NSDictionary *theDict = @{NSBackgroundColorAttributeName: theHighlightColor};
        // （文字列が削除されたときも実行されるので、範囲を検証しておかないと例外が発生する）
        NSRange theRemoveAttrsRange = NSMakeRange(0, [_textStorage length]);

        // 検索パネルのハイライトや非互換文字表示で使っているlayoutManのaddTemporaryAttributesと衝突しないように、
        // NSTextStorageの背景色を使っている。addTemporaryAttributesよりも後ろに描画されるので、
        // これら検索パネルのハイライト／非互換文字表示／カレント行のハイライトが全て表示できる。
        // ただし、テキストビュー分割時にアクティブでないものも含めて全てのテキストビューがハイライトされてしまう。
        // これは、全テキストビューのtextStorageが共通であることに起因するので、構造を変更しない限り解決できない。2008.06.07.
        [_textStorage beginEditing];
        if (theRemoveAttrsRange.length > 0) {
            [_textStorage removeAttribute:NSBackgroundColorAttributeName range:theRemoveAttrsRange];
        }
        [_textStorage addAttributes:theDict range:theLineRange];
        [_textStorage endEditing];
        _hilightedLineRange = theLineRange;
        _hadMarkedText = [[self textView] hasMarkedText];
    }
}


@end
