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
 
 -fno-objc-arc
 
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
#import "CEToolbarController.h"

//=======================================================
// Private method
//
//=======================================================

@interface CEEditorView ()

@property (nonatomic, retain) NSNumberFormatter *decimalFormatter;

@end

@interface CEEditorView (Private)
- (void)setupViews;
- (void)setupViewParamsInInit:(BOOL)inBool;
- (void)doColoringNow;
- (void)doColoringWithTimer:(NSTimer *)inTimer;
- (void)doUpdateInfoWithTimer:(NSTimer *)inTimer;
- (void)doUpdateIncompatibleCharListWithTimer:(NSTimer *)inTimer;
- (void)focusOtherSplitTextViewOnNext:(BOOL)inBool;
- (void)stopColoringTimer;
- (void)stopInfoUpdateTimer;
- (void)stopIncompatibleCharTimer;
@end


//------------------------------------------------------------------------------------------




@implementation CEEditorView

#pragma mark ===== Public method =====

//=======================================================
// Public method
//
//=======================================================

// ------------------------------------------------------
- (instancetype)initWithFrame:(NSRect)inFrame
// 初期化
// ------------------------------------------------------
{
    self = [super initWithFrame:inFrame];
    if (self) {
        // set number formatter for status bar
        [self setDecimalFormatter:[[NSNumberFormatter alloc] init]];
        [[self decimalFormatter] setNumberStyle:NSNumberFormatterDecimalStyle];
        if (![[NSUserDefaults standardUserDefaults] boolForKey:k_key_showStatusBarThousSeparator]) {
            [[self decimalFormatter] setThousandSeparator:@""];
        }
        
        [self setupViews];
    }
    return self;
}


// ------------------------------------------------------
- (void)dealloc
// 後片付け
// ------------------------------------------------------
{
    [self stopAllTimer];

    [_textViewCore release];
    [_splitView release];
    [_statusBar release];
    [_decimalFormatter release];

    [super dealloc];
}


// ------------------------------------------------------
- (NSUndoManager *)undoManagerForTextView:(NSTextView *)inTextView
// _textViewCoreのundoManager を返す
// ------------------------------------------------------
{
    return [[self document] undoManager];
}


// ------------------------------------------------------
- (CEDocument *)document
// documentを返す
// ------------------------------------------------------
{
    return [[self windowController] document];
}


// ------------------------------------------------------
- (id)windowController
// windowControllerを返す
// ------------------------------------------------------
{
    return [[self window] windowController];
}


// ------------------------------------------------------
- (NSTextStorage *)textStorage
// textStorageを返す
// ------------------------------------------------------
{
    return [[self textView] textStorage];
}


// ------------------------------------------------------
- (CESplitView *)splitView
// splitViewを返す
// ------------------------------------------------------
{
    return _splitView;
}


// ------------------------------------------------------
- (CETextViewCore *)textView
// メインtextViewを返す
// ------------------------------------------------------
{
    return _textViewCore;
}


// ------------------------------------------------------
- (void)setTextView:(CETextViewCore *)inTextView
// textViewを保持
// ------------------------------------------------------
{
    [inTextView retain];
    [_textViewCore release];
    _textViewCore = inTextView;
}


// ------------------------------------------------------
- (CENavigationBarView *)navigationBar
// navigationBarを返す
// ------------------------------------------------------
{
    return [(CESubSplitView *)[[self textView] delegate] navigationBar];
}


// ------------------------------------------------------
- (CESyntax *)syntax
// syntaxオブジェクトを返す
// ------------------------------------------------------
{
    return [(CESubSplitView *)[[self textView] delegate] syntax];
}


// ------------------------------------------------------
- (BOOL)isColoring
// カラーリングしているかどうかを返す
// ------------------------------------------------------
{
    return _coloring;
}


// ------------------------------------------------------
- (void)setIsColoring:(BOOL)inBool
// カラーリングする／しないをセット
// ------------------------------------------------------
{
    _coloring = inBool;
}


// ------------------------------------------------------
- (NSString *)string
// メインtextViewの文字列を返す（行末コードはLF固定）
// ------------------------------------------------------
{
    return ([[self textView] string]);
}


// ------------------------------------------------------
- (NSString *)stringForSave
// 行末コードを指定のものに置換したメインtextViewの文字列を返す
// ------------------------------------------------------
{
    NSString *outString = [OGRegularExpression replaceNewlineCharactersInString:[self string] 
                    withCharacter:[self lineEndingCharacter]];
    return outString;
}


// ------------------------------------------------------
- (NSString *)substringWithRange:(NSRange)inRange
// メインtextViewの指定された範囲の文字列を返す
// ------------------------------------------------------
{
    return ([[self string] substringWithRange:inRange]);
}


// ------------------------------------------------------
- (NSString *)substringWithSelection
// メインtextViewの選択された文字列を返す
// ------------------------------------------------------
{
    return ([[self string] substringWithRange:[[self textView] selectedRange]]);
}


// ------------------------------------------------------
- (NSString *)substringWithSelectionForSave
// メインtextViewの選択された文字列を、行末コードを指定のものに置換して返す
// ------------------------------------------------------
{
    NSString *theTmpStr = [self substringWithSelection];
    NSString *outString = [OGRegularExpression replaceNewlineCharactersInString:theTmpStr 
                    withCharacter:[self lineEndingCharacter]];

    return outString;
}


// ------------------------------------------------------
- (void)setString:(NSString *)inString
// メインtextViewに文字列をセット。行末コードはLFに置換される
// ------------------------------------------------------
{
    // 表示する文字列内の行末コードをLFに統一する
    // （その他の編集は、下記の通りの別の場所で置換している）
    // # テキスト編集時の行末コードの置換場所
    //  * ファイルオープン = CEEditorView > setString:
    //  * キー入力 = CESubSplitView > textView:shouldChangeTextInRange:replacementString:
    //  * ペースト = CETextViewCore > readSelectionFromPasteboard:type:
    //  * ドロップ（同一書類内） = CETextViewCore > performDragOperation:
    //  * ドロップ（別書類または別アプリから） = CETextViewCore > readSelectionFromPasteboard:type:
    //  * スクリプト = CESubSplitView > textView:shouldChangeTextInRange:replacementString:
    //  * 検索パネルでの置換 = (OgreKit) OgreTextViewPlainAdapter > replaceCharactersInRange:withOGString:

    NSString *theNewLineString = [OGRegularExpression replaceNewlineCharactersInString:inString 
                    withCharacter:OgreLfNewlineCharacter];

    // UTF-16 でないものを UTF-16 で表示した時など当該フォントで表示できない文字が表示されてしまった後だと、
    // 設定されたフォントでないもので表示されることがあるため、リセットする
    [[self textView] setString:@""];
    [[self textView] setEffectTypingAttrs];
    [[self textView] setString:theNewLineString];
    // キャレットを先頭に移動
    if ([theNewLineString length] > 0) {
        [[self splitView] setAllCaretToBeginning];
    }
}


// ------------------------------------------------------
- (void)replaceTextViewSelectedStringTo:(NSString *)inString scroll:(BOOL)inBoolScroll
// 選択文字列を置換する
// ------------------------------------------------------
{
    [[self textView] replaceSelectedStringTo:inString scroll:inBoolScroll];
}


// ------------------------------------------------------
- (void)replaceTextViewAllStringTo:(NSString *)inString
// 全文字列を置換
// ------------------------------------------------------
{
    [[self textView] replaceAllStringTo:inString];
}


// ------------------------------------------------------
- (void)insertTextViewAfterSelectionStringTo:(NSString *)inString
// 選択範囲の直後に文字列を挿入
// ------------------------------------------------------
{
    [[self textView] insertAfterSelection:inString];
}


// ------------------------------------------------------
- (void)appendTextViewAfterAllStringTo:(NSString *)inString
// 文字列の最後に新たな文字列を追加
// ------------------------------------------------------
{
    [[self textView] appendAllString:inString];
}


// ------------------------------------------------------
- (BOOL)setSyntaxExtension:(NSString *)inExtension
// 文書の拡張子をCESyntaxへセット
// ------------------------------------------------------
{
    BOOL outBool = [[self syntax] setSyntaxStyleNameFromExtension:inExtension];
    NSString *theName = [[self syntax] syntaxStyleName];

    [self setIsColoring:(![theName isEqualToString:NSLocalizedString(@"None",@"")])];
    return outBool;
}


// ------------------------------------------------------
- (NSFont *)font
// フォントを返す
// ------------------------------------------------------
{
    return [[self textView] font];
}


// ------------------------------------------------------
- (void)setFont:(NSFont *)inFont
// フォントをセット
// ------------------------------------------------------
{
    [[self textView] setFont:inFont];
}


// ------------------------------------------------------
- (NSRange)selectedRange
// 選択範囲を返す
// ------------------------------------------------------
{
    if ([[[self textView] newLineString] length] > 1) {
        NSRange theRange = [[self textView] selectedRange];
        NSString *theTmpLocStr = [[self string] substringWithRange:NSMakeRange(0, theRange.location)];
        NSString *theLocStr = [OGRegularExpression replaceNewlineCharactersInString:theTmpLocStr 
                        withCharacter:[self lineEndingCharacter]];
        NSString *theLenStr = [self substringWithSelectionForSave];

        return (NSMakeRange([theLocStr length], [theLenStr length]));
    }
    return ([[self textView] selectedRange]);
}


// ------------------------------------------------------
- (void)setSelectedRange:(NSRange)inCharRange
// 選択範囲を変更
// ------------------------------------------------------
{
    if ([[[self textView] newLineString] length] > 1) {
        NSString *theTmpLocStr = [[self stringForSave] substringWithRange:NSMakeRange(0, inCharRange.location)];
        NSString *theLocStr = [OGRegularExpression replaceNewlineCharactersInString:theTmpLocStr 
                        withCharacter:OgreLfNewlineCharacter];
        NSString *theTmpLenStr = [[self stringForSave] substringWithRange:inCharRange];
        NSString *theLenStr = [OGRegularExpression replaceNewlineCharactersInString:theTmpLenStr 
                        withCharacter:OgreLfNewlineCharacter];
        [[self textView] setSelectedRange:NSMakeRange([theLocStr length], [theLenStr length])];
    } else {
        [[self textView] setSelectedRange:inCharRange];
    }
}


// ------------------------------------------------------
- (NSArray *)allLayoutManagers
// 全layoutManagerを配列で返す
// ------------------------------------------------------
{
    NSArray *theSubSplitViews = [[self splitView] subviews];
    NSMutableArray *outArray = [NSMutableArray array];

    for (NSTextContainer *container in theSubSplitViews) {
        [outArray addObject:[[container textView] layoutManager]];
    }
    return outArray;
}


// ------------------------------------------------------
- (BOOL)showLineNum
// 行版を表示するかどうかを返す
// ------------------------------------------------------
{
    return _showLineNum;
}


// ------------------------------------------------------
- (void)setShowLineNum:(BOOL)inBool
// 行番号の表示をする／しないをセット
// ------------------------------------------------------
{
    _showLineNum = inBool;
    [[self splitView] setShowLineNum:inBool];
    [[[self windowController] toolbarController] updateToggleItem:k_showLineNumItemID setOn:inBool];
}


// ------------------------------------------------------
- (BOOL)showStatusBar
// ステータスバーを表示するかどうかを返す
// ------------------------------------------------------
{
    if (_statusBar) {
        return ([_statusBar showStatusBar]);
    } else {
        return NO;
    }
}


// ------------------------------------------------------
- (void)setShowStatusBar:(BOOL)inBool
// ステータスバーを表示する／しないをセット
// ------------------------------------------------------
{
    if (_statusBar) {
        [_statusBar setShowStatusBar:inBool];
        [[[self windowController] toolbarController] updateToggleItem:k_showStatusBarItemID setOn:inBool];
        [self updateLineEndingsInStatusAndInfo:NO];
        if (!_infoUpdateTimer) {
            [self updateDocumentInfoStringWithDrawerForceUpdate:NO];
        }
    }
}


// ------------------------------------------------------
- (BOOL)showNavigationBar
// ナビバーを表示するかどうかを返す
// ------------------------------------------------------
{
    return _showNavigationBar;
}


// ------------------------------------------------------
- (void)setShowNavigationBar:(BOOL)inBool
// ナビバーを表示する／しないをセット
// ------------------------------------------------------
{
    _showNavigationBar = inBool;
    [[self splitView] setShowNavigationBar:inBool];
    [[[self windowController] toolbarController] updateToggleItem:k_showNavigationBarItemID setOn:inBool];
}


// ------------------------------------------------------
- (BOOL)wrapLines
// 行をラップするかどうかを返す
// ------------------------------------------------------
{
    return _wrapLines;
}


// ------------------------------------------------------
- (void)setWrapLines:(BOOL)inBool
// 行をラップする／しないをセット
// ------------------------------------------------------
{
    _wrapLines = inBool;
    [[self splitView] setWrapLines:inBool];
    [self setNeedsDisplay:YES];
    [[[self windowController] toolbarController] updateToggleItem:k_wrapLinesItemID setOn:inBool];
}


// ------------------------------------------------------
- (BOOL)isWritable
// 文書への書き込み（ファイル上書き保存）が可能かどうかを返す
// ------------------------------------------------------
{
    return _isWritable;
}


// ------------------------------------------------------
- (void)setIsWritable:(BOOL)isWritable
// 文書への書き込み（ファイル上書き保存）が可能かどうかをセット
// ------------------------------------------------------
{
    _isWritable = isWritable;
    
    if (_statusBar) {
        [_statusBar setShowsReadOnlyIcon:!_isWritable];
    }
}


// ------------------------------------------------------
- (BOOL)isAlertedNotWritable
// 文書が読み込み専用のときにその警告を表示したかどうかを返す
// ------------------------------------------------------
{
    return _alertedNotWritable;
}


// ------------------------------------------------------
- (void)setIsAlertedNotWritable:(BOOL)inBool
// 文書が読み込み専用のときにその警告を表示したかどうかをセット
// ------------------------------------------------------
{
    _alertedNotWritable = inBool;
}


// ------------------------------------------------------
- (BOOL)shouldUseAntialias
// アンチエイリアスでの描画の許可を得る
// ------------------------------------------------------
{
    CELayoutManager *theManager = (CELayoutManager *)[[self textView] layoutManager];
    return [theManager useAntialias];
}


// ------------------------------------------------------
- (void)toggleShouldUseAntialias
// アンチエイリアス適用をトグルに切り替え
// ------------------------------------------------------
{
    CELayoutManager *theManager = (CELayoutManager *)[[self textView] layoutManager];
    BOOL theBool = [theManager useAntialias];

    [[self splitView] setUseAntialias:(!theBool)];
}


// ------------------------------------------------------
- (BOOL)showPageGuide
// ページガイドを表示するかどうかを返す
// ------------------------------------------------------
{
    return _showPageGuide;
}


// ------------------------------------------------------
- (void)setShowPageGuide:(BOOL)inBool
// ページガイドを表示する／しないをセット
// ------------------------------------------------------
{
    if (_showPageGuide != inBool) {
        _showPageGuide = inBool;
        [[[self windowController] toolbarController] updateToggleItem:k_showPageGuideItemID setOn:inBool];
    }
}


// ------------------------------------------------------
- (NSInteger)lineEndingCharacter
// 行末コードを返す（OgreNewlineCharacter型）
// ------------------------------------------------------
{
    return _lineEndingCharacter;
}


// ------------------------------------------------------
- (void)setLineEndingCharacter:(NSInteger)inNewLineEnding
// 行末コードをセット（OgreNewlineCharacter型）
// ------------------------------------------------------
{
    NSArray *theSubSplitViews = [[self splitView] subviews];
    NSString *theNewLineString;
    BOOL theBoolUpdate = ([self lineEndingCharacter] != inNewLineEnding);
    unichar theChar[2];

    if ((inNewLineEnding > OgreNonbreakingNewlineCharacter) && 
            (inNewLineEnding <= OgreWindowsNewlineCharacter)) {
        _lineEndingCharacter = inNewLineEnding;
    } else {
        id theValues = [[NSUserDefaultsController sharedUserDefaultsController] values];
        NSInteger theDefaultLineEnd = [[theValues valueForKey:k_key_defaultLineEndCharCode] integerValue];
        _lineEndingCharacter = theDefaultLineEnd;
    }
    // set to textViewCore.
    switch (_lineEndingCharacter) {
        case OgreLfNewlineCharacter:
            theNewLineString = @"\n";  // LF
            break;
        case OgreCrNewlineCharacter:  // CR
            theNewLineString = @"\r";
            break;
        case OgreCrLfNewlineCharacter:  // CR+LF
            theNewLineString = @"\r\n";
            break;
        case OgreUnicodeLineSeparatorNewlineCharacter:  // Unicode line separator
            theChar[0] = 0x2028; theChar[1] = 0;
            theNewLineString = [[[NSString alloc] initWithCharacters:theChar length:1] autorelease];
            break;
        case OgreUnicodeParagraphSeparatorNewlineCharacter:  // Unicode paragraph separator
            theChar[0] = 0x2029; theChar[1] = 0;
            theNewLineString = [[[NSString alloc] initWithCharacters:theChar length:1] autorelease];
            break;
        case OgreNonbreakingNewlineCharacter:  // 改行なしの場合
            theNewLineString = @"";
            break;
            
        default:
            return;
    }
    for (NSTextContainer *container in theSubSplitViews) {
        [(CETextViewCore *)[container textView] setNewLineString:theNewLineString];
    }
    if (theBoolUpdate) {
        [self updateLineEndingsInStatusAndInfo:NO];
        if (!_infoUpdateTimer) {
            [self updateDocumentInfoStringWithDrawerForceUpdate:NO];
        }
    }
}


// ------------------------------------------------------
- (NSString *)syntaxStyleNameToColoring
// シンタックススタイル名を返す
// ------------------------------------------------------
{
    if ([self syntax]) {
        return [[self syntax] syntaxStyleName]; 
    }
    return nil;
}


// ------------------------------------------------------
- (void)setSyntaxStyleNameToColoring:(NSString *)inName recolorNow:(BOOL)inValue
// シンタックススタイル名をセット
// ------------------------------------------------------
{
    if ([self syntax]) {
        [[self splitView] setSyntaxStyleNameToSyntax:inName];
        [self setIsColoring:(![inName isEqualToString:NSLocalizedString(@"None",@"")])];
        if (inValue) {
            [self recoloringAllString];
            if ([self showNavigationBar]) {
                [[self splitView] updateAllOutlineMenu];
            }
        }
    }
}


// ------------------------------------------------------
- (void)recoloringAllString
// 全テキストを再カラーリング
// ------------------------------------------------------
{
    [self stopColoringTimer];
    [[self splitView] recoloringAllTextView];
}


// ------------------------------------------------------
- (void)updateColoringAndOutlineMenuWithDelay
// ディレイをかけて、全テキストを再カラーリング、アウトラインメニューを更新
// ------------------------------------------------------
{
    [self stopColoringTimer];
    // （下記のメソッドの実行順序を変更すると、Tigerで大きめの書類を開いたときに異常に遅くなるので注意。 2008.05.03.）
    [[self splitView] performSelector:@selector(recoloringAllTextView) withObject:nil afterDelay:0.03];
    [[self splitView] performSelector:@selector(updateAllOutlineMenu) withObject:nil afterDelay:0];
}


// ------------------------------------------------------
- (void)alertForNotWritable
// 書き込み禁止アラートを表示
// ------------------------------------------------------
{
    if (([self isWritable]) || ([self isAlertedNotWritable])) { return; }

    id theValues = [[NSUserDefaultsController sharedUserDefaultsController] values];

    if ([[theValues valueForKey:k_key_showAlertForNotWritable] boolValue]) {

        NSAlert *theAlert = [NSAlert alertWithMessageText:NSLocalizedString(@"The file is not writable.", nil)
                                            defaultButton:nil
                                          alternateButton:nil
                                              otherButton:nil
                                informativeTextWithFormat:NSLocalizedString(@"You may not be able to save your changes, but you will be able to save a copy somewhere else.", nil)
                    ];

        [theAlert beginSheetModalForWindow:[self window] 
                    modalDelegate:self 
                    didEndSelector:NULL 
                    contextInfo:NULL];
    }
    [self setIsAlertedNotWritable:YES];
}


// ------------------------------------------------------
- (void)updateDocumentInfoStringWithDrawerForceUpdate:(BOOL)doUpdate
// ドローワの文書情報を更新
// ------------------------------------------------------
{
    BOOL shouldUpdateStatusBar = [_statusBar showStatusBar];
    BOOL shouldUpdateDrawer = (doUpdate) ? YES : [[self windowController] needsInfoDrawerUpdate];
    
    if (!shouldUpdateStatusBar && !shouldUpdateDrawer) { return; }
    
    NSString *theString = ([self lineEndingCharacter] == OgreCrLfNewlineCharacter) ? [self stringForSave] : [self string];
    NSString *singleCharInfo = nil;
    NSRange selectedRange = [self selectedRange];
    NSUInteger numberOfLines = 0, currentLine = 0, length = [theString length];
    NSUInteger lineStart = 0, countInLine = 0;

    // IM で変換途中の文字列は選択範囲としてカウントしない (2007.05.20)
    if ([[self textView] hasMarkedText]) {
        selectedRange.length = 0;
    }
    if (length > 0) {
        lineStart = [theString lineRangeForRange:selectedRange].location;
        countInLine = selectedRange.location - lineStart;

        for (NSUInteger index = 0, numberOfLines = 0; index < length; numberOfLines++) {
            if (index <= selectedRange.location) {
                currentLine = numberOfLines + 1;
            }
            index = NSMaxRange([theString lineRangeForRange:NSMakeRange(index, 0)]);
        }
        // 行末コードをカウントしない場合は再計算
        if (![[NSUserDefaults standardUserDefaults] boolForKey:k_key_countLineEndingAsChar]) {
            NSString *locStr = [theString substringToIndex:selectedRange.location];

            selectedRange.location = [[OGRegularExpression chomp:locStr] length];
            selectedRange.length = [[OGRegularExpression chomp:[self substringWithSelection]] length];
            length = [[OGRegularExpression chomp:theString] length];
        }
    }
    NSUInteger numberOfWords = [[NSSpellChecker sharedSpellChecker] countWordsInString:theString language:nil];

    if (shouldUpdateStatusBar) {
        NSString *statusString;
        
        if (selectedRange.length > 0) {
            if (selectedRange.length == 1) {
                unichar theCharacter = [theString characterAtIndex:selectedRange.location];
                singleCharInfo = [NSString stringWithFormat:@"0x%.4X",theCharacter];
                statusString = [NSString stringWithFormat:NSLocalizedString(@"Line: %@ / %@   Char: %@ / %@ (>%@) [:%@]   Unicode: %@", nil),
                    [[self decimalFormatter] stringFromNumber:@(currentLine)],
                    [[self decimalFormatter] stringFromNumber:@(numberOfLines)],
                    [[self decimalFormatter] stringFromNumber:@(selectedRange.location)],
                    [[self decimalFormatter] stringFromNumber:@(length)],
                    [[self decimalFormatter] stringFromNumber:@(countInLine)],
                    [[self decimalFormatter] stringFromNumber:@(selectedRange.length)],
                    singleCharInfo];
            } else {
                statusString = [NSString stringWithFormat:NSLocalizedString(@"Line: %@ / %@   Char: %@ / %@ (>%@) [:%@]", nil),
                    [[self decimalFormatter] stringFromNumber:@(currentLine)],
                    [[self decimalFormatter] stringFromNumber:@(numberOfLines)],
                    [[self decimalFormatter] stringFromNumber:@(selectedRange.location)],
                    [[self decimalFormatter] stringFromNumber:@(length)],
                    [[self decimalFormatter] stringFromNumber:@(countInLine)],
                    [[self decimalFormatter] stringFromNumber:@(selectedRange.length)]];
            }
        } else {
            statusString = [NSString stringWithFormat:NSLocalizedString(@"Line: %@ / %@   Char: %@ / %@ (>%@)", nil),
                    [[self decimalFormatter] stringFromNumber:@(currentLine)],
                    [[self decimalFormatter] stringFromNumber:@(numberOfLines)],
                    [[self decimalFormatter] stringFromNumber:@(selectedRange.location)],
                    [[self decimalFormatter] stringFromNumber:@(length)],
                    [[self decimalFormatter] stringFromNumber:@(countInLine)]];
        }
        [[_statusBar leftTextField] setStringValue:statusString];
    }
    if (shouldUpdateDrawer) {
        NSString *linesInfo, *charsInfo, *selectInfo;
        
        linesInfo = [NSString stringWithFormat:@"%ld / %ld", (long)currentLine, (long)numberOfLines];
        [[self windowController] setLinesInfo:linesInfo];
        charsInfo = [NSString stringWithFormat:@"%ld / %ld", (long)selectedRange.location, (long)length];
        [[self windowController] setCharsInfo:charsInfo];
        [[self windowController] setInLineInfo:[NSString stringWithFormat:@"%ld", (long)countInLine]];
        selectInfo = (selectedRange.length > 0) ? [NSString stringWithFormat:@"%ld", (long)selectedRange.length] : @" - ";
        [[self windowController] setSelectInfo:selectInfo];
        [[self windowController] setSingleCharInfo:singleCharInfo];
    }
}


// ------------------------------------------------------
- (void)updateLineEndingsInStatusAndInfo:(BOOL)inBool
// ステータスバーと情報ドローワの行末コード表記を更新
// ------------------------------------------------------
{
    BOOL shouldUpdateStatusBar = [_statusBar showStatusBar];
    BOOL shouldUpdateDrawer = (inBool) ? YES : [[self windowController] needsInfoDrawerUpdate];
    if (!shouldUpdateStatusBar && !shouldUpdateDrawer) { return; }
    
    NSString *encodingInfo, *lineEndingsInfo;
    
    switch (_lineEndingCharacter) {
        case OgreLfNewlineCharacter:
            lineEndingsInfo = @"LF";
            break;
        case OgreCrNewlineCharacter:
            lineEndingsInfo = @"CR";
            break;
        case OgreCrLfNewlineCharacter:
            lineEndingsInfo = @"CRLF";
            break;
        case OgreUnicodeLineSeparatorNewlineCharacter:
            lineEndingsInfo = @"U-lineSep"; // Unicode line separator
            break;
        case OgreUnicodeParagraphSeparatorNewlineCharacter:
            lineEndingsInfo = @"U-paraSep"; // Unicode paragraph separator
            break;
        case OgreNonbreakingNewlineCharacter:
            lineEndingsInfo = @""; // 改行なしの場合
            break;
        default:
            return;
    }
    
    encodingInfo = [[self document] currentIANACharSetName];
    if (shouldUpdateStatusBar) {
        [[_statusBar rightTextField] setStringValue:[NSString stringWithFormat:@"%@ %@", encodingInfo, lineEndingsInfo]];
    }
    if (shouldUpdateDrawer) {
        [[self windowController] setEncodingInfo:encodingInfo];
        [[self windowController] setLineEndingsInfo:lineEndingsInfo];
    }
}


// ------------------------------------------------------
- (void)setShowInvisibleChars:(BOOL)inBool
// 不可視文字の表示／非表示を設定
// ------------------------------------------------------
{
    [[self splitView] setShowInvisibles:inBool];
}


// ------------------------------------------------------
- (void)updateShowInvisibleCharsMenuToolTip
// 不可視文字表示メニューのツールチップを更新
// ------------------------------------------------------
{
    NSMenuItem *theShowMenuItem = 
            [[[[NSApp mainMenu] itemAtIndex:k_viewMenuIndex] submenu] itemWithTag:k_showInvisibleCharMenuItemTag];

    if ([[self document] canActivateShowInvisibleCharsItem]) {
        [theShowMenuItem setToolTip:NSLocalizedString(@"",@"")];
    } else {
        [theShowMenuItem setToolTip:NSLocalizedString(@"To display invisible characters, set in Preferences and re-open the document.",@"")];
    }
}


// ------------------------------------------------------
- (void)setColoringTimer
// カラーリングタイマーのファイヤーデイトを設定時間後にセット
// ------------------------------------------------------
{
    if ([self isColoring]) {
        id theValues = [[NSUserDefaultsController sharedUserDefaultsController] values];

        // 遅延カラーリング
        if ([[theValues valueForKey:k_key_delayColoring] boolValue]) {
            if (_coloringTimer) {
                [_coloringTimer setFireDate:[NSDate dateWithTimeIntervalSinceNow:_secondColoringDelay]];
            } else {
                _coloringTimer = [[NSTimer scheduledTimerWithTimeInterval:_firstColoringDelay 
                        target:self 
                        selector:@selector(doColoringWithTimer:) 
                        userInfo:nil repeats:NO] retain]; // ===== retain
            }
        } else {
            if (_coloringTimer) {
                [_coloringTimer setFireDate:[NSDate dateWithTimeIntervalSinceNow:_basicColoringDelay]];
            } else {
                _coloringTimer = [[NSTimer scheduledTimerWithTimeInterval:_basicColoringDelay 
                        target:self 
                        selector:@selector(doColoringWithTimer:) 
                        userInfo:nil repeats:NO] retain]; // ===== retain
            }
        }
    }
}


// ------------------------------------------------------
- (void)setIncompatibleCharTimer
// 非互換文字更新タイマーのファイヤーデイトを設定時間後にセット
// ------------------------------------------------------
{
    if ([[self windowController] needsIncompatibleCharDrawerUpdate]) {
        if (_incompatibleCharTimer) {
            [_incompatibleCharTimer setFireDate:[NSDate dateWithTimeIntervalSinceNow:_incompatibleCharInterval]];
        } else {
            _incompatibleCharTimer = [[NSTimer scheduledTimerWithTimeInterval:_incompatibleCharInterval 
                        target:self 
                        selector:@selector(doUpdateIncompatibleCharListWithTimer:) 
                        userInfo:nil repeats:NO] retain]; // ===== retain
        }
    }
}


// ------------------------------------------------------
- (void)setInfoUpdateTimer
// 文書情報更新タイマーのファイヤーデイトを設定時間後にセット
// ------------------------------------------------------
{
    if (_infoUpdateTimer) {
        [_infoUpdateTimer setFireDate:[NSDate dateWithTimeIntervalSinceNow:_infoUpdateInterval]];
    } else {
        _infoUpdateTimer = [[NSTimer scheduledTimerWithTimeInterval:_infoUpdateInterval 
                    target:self 
                    selector:@selector(doUpdateInfoWithTimer:) userInfo:nil 
                    repeats:NO] retain]; // ===== retain
    }
}


// ------------------------------------------------------
- (void)updateCloseSubSplitViewButton
// テキストビュー分割削除ボタンの有効／無効を更新
// ------------------------------------------------------
{
    BOOL theBoolEnabeld = [[[self splitView] subviews] count] > 1;

    [[self splitView] setCloseSubSplitViewButtonEnabled:theBoolEnabeld];
}


// ------------------------------------------------------
- (void)stopAllTimer
// 全タイマーを停止
// ------------------------------------------------------
{
    [self stopColoringTimer];
    [self stopInfoUpdateTimer];
    [self stopIncompatibleCharTimer];
}



#pragma mark ===== Protocol =====

//=======================================================
// NSMenuValidation Protocol
//
//=======================================================

// ------------------------------------------------------
- (BOOL)validateMenuItem:(NSMenuItem *)inMenuItem
// メニュー項目の有効・無効を制御
// ------------------------------------------------------
{
    NSInteger theState = NSOffState;

    if ([inMenuItem action] == @selector(toggleShowLineNum:)) {
        if ([self showLineNum]) {theState = NSOnState;}
    } else if ([inMenuItem action] == @selector(toggleShowStatusBar:)) {
        if ([self showStatusBar]) {theState = NSOnState;}
    } else if ([inMenuItem action] == @selector(toggleShowNavigationBar:)) {
        if ([self showNavigationBar]) {theState = NSOnState;}
    } else if ([inMenuItem action] == @selector(toggleWrapLines:)) {
        if ([self wrapLines]) {theState = NSOnState;}
    } else if ([inMenuItem action] == @selector(toggleUseAntialias:)) {
        if ([self shouldUseAntialias]) {theState = NSOnState;}
    } else if ([inMenuItem action] == @selector(toggleShowInvisibleChars:)) {
        if ([(CELayoutManager *)[[self textView] layoutManager] showInvisibles]) {theState = NSOnState;}
        [inMenuItem setState:theState];
        return ([[self document] canActivateShowInvisibleCharsItem]);
    } else if ([inMenuItem action] == @selector(toggleShowPageGuide:)) {
        if ([self showPageGuide]) {theState = NSOnState;}
    } else if (([inMenuItem action] == @selector(focusNextSplitTextView:)) || 
            ([inMenuItem action] == @selector(focusPrevSplitTextView:)) || 
            ([inMenuItem action] == @selector(closeSplitTextView:))) {
        return ([[[self splitView] subviews] count] > 1);
    }
    [inMenuItem setState:theState];

    return YES;
}



#pragma mark ===== Action messages =====

//=======================================================
// Action messages
//
//=======================================================

// ------------------------------------------------------
- (IBAction)toggleShowLineNum:(id)sender
// 行番号表示をトグルに切り替える
// ------------------------------------------------------
{
    BOOL theBool = [self showLineNum];
    [self setShowLineNum:(!theBool)];
}


// ------------------------------------------------------
- (IBAction)toggleShowStatusBar:(id)sender
// ステータスバーの表示をトグルに切り替える
// ------------------------------------------------------
{
    BOOL theBool = [self showStatusBar];
    [self setShowStatusBar:(!theBool)];
}


// ------------------------------------------------------
- (IBAction)toggleShowNavigationBar:(id)sender
// ナビゲーションバーの表示をトグルに切り替える
// ------------------------------------------------------
{
    BOOL theBool = [self showNavigationBar];
    [self setShowNavigationBar:(!theBool)];
}


// ------------------------------------------------------
- (IBAction)toggleWrapLines:(id)sender
// ワードラップをトグルに切り替える
// ------------------------------------------------------
{
    BOOL theBool = [self wrapLines];
    [self setWrapLines:(!theBool)];
}


// ------------------------------------------------------
- (IBAction)toggleUseAntialias:(id)sender
// 文字にアンチエイリアスを使うかどうかをトグルに切り替える
// ------------------------------------------------------
{
    [self toggleShouldUseAntialias];
}


// ------------------------------------------------------
- (IBAction)toggleShowInvisibleChars:(id)sender
// 不可視文字表示をトグルに切り替える
// ------------------------------------------------------
{
    CELayoutManager *theLayoutManager = (CELayoutManager *)[[self textView] layoutManager];
    BOOL theBool = [theLayoutManager showInvisibles];

    [[self splitView] setShowInvisibles:(!theBool)];
    [[[self windowController] toolbarController] updateToggleItem:k_showInvisibleCharsItemID setOn:(!theBool)];
}


// ------------------------------------------------------
- (IBAction)toggleShowPageGuide:(id)sender
// ページガイド表示をトグルに切り替える
// ------------------------------------------------------
{
    BOOL theBool = [self showPageGuide];

    [self setShowPageGuide:(!theBool)];
    [[self splitView] setNeedsDisplay:YES];
}


// ------------------------------------------------------
- (IBAction)openSplitTextView:(id)sender
// テキストビュー分割を行う
// ------------------------------------------------------
{
    CESubSplitView *theMasterView = ([sender isMemberOfClass:[NSMenuItem class]]) ? 
            (CESubSplitView *)[(CETextViewCore *)[[self window] firstResponder] delegate] :
            [(CENavigationBarView *)[sender superview] masterView];
    if (theMasterView == nil) { return; }
    NSRect theSubSplitFrame = [theMasterView bounds];
    NSRange theSelectedRange = [[theMasterView textView] selectedRange];
    CESubSplitView *theSubSplitView = 
            [[[CESubSplitView allocWithZone:[self zone]] initWithFrame:theSubSplitFrame] autorelease];

    [theSubSplitView replaceTextStorage:[[self textView] textStorage]];
    [theSubSplitView setEditorView:self];
    // あらたなsubViewは、押された追加ボタンが属する（またはフォーカスのある）subSplitViewのすぐ下に挿入する
    [[self splitView] addSubview:theSubSplitView positioned:NSWindowAbove relativeTo:theMasterView];
    [[self splitView] adjustSubviews];
    [self setupViewParamsInInit:NO];
    [[theSubSplitView textView] setFont:[[self textView] font]];
    [[theSubSplitView textView] setLineSpacing:[[self textView] lineSpacing]];
    [self setShowInvisibleChars:[(CELayoutManager *)[[self textView] layoutManager] showInvisibles]];
    [[theSubSplitView textView] setSelectedRange:theSelectedRange];
    [[self splitView] adjustSubviews];
    [theSubSplitView setSyntaxStyleNameToSyntax:[[self syntax] syntaxStyleName]];
    [[theSubSplitView syntax] colorAllString:[self string]];
    [[self textView] centerSelectionInVisibleArea:self];
    [[self window] makeFirstResponder:[theSubSplitView textView]];
    [self setLineEndingCharacter:[self lineEndingCharacter]];
    [[theSubSplitView textView] centerSelectionInVisibleArea:self];
    [self updateCloseSubSplitViewButton];
}


// ------------------------------------------------------
- (IBAction)closeSplitTextView:(id)sender
// 分割されたテキストビューを閉じる
// ------------------------------------------------------
{
    BOOL theBoolIsSenderMenu = [sender isMemberOfClass:[NSMenuItem class]];
    CESubSplitView *theFirstResponderSubSplitView = (CESubSplitView *)[(CETextViewCore *)[[self window] firstResponder] delegate];
    CESubSplitView *theCloseSubSplitView = (theBoolIsSenderMenu) ? 
            theFirstResponderSubSplitView : [(CENavigationBarView *)[sender superview] masterView];
    if (theCloseSubSplitView == nil) { return; }
    NSArray *theSubViews = [[self splitView] subviews];
    NSUInteger theCount = [theSubViews count];
    NSUInteger theDelIndex = [theSubViews indexOfObject:theCloseSubSplitView];
    NSUInteger theIndex = 0;

    if ((theBoolIsSenderMenu) || (theDelIndex == [theSubViews indexOfObject:theFirstResponderSubSplitView])) {
        theIndex = theDelIndex + 1;
        if (theIndex >= theCount) {
            theIndex = theCount - 2;
        }
        [[self window] makeFirstResponder:[theSubViews[theIndex] textView]];
    }
    [theCloseSubSplitView removeFromSuperview];
    [self updateCloseSubSplitViewButton];
}


// ------------------------------------------------------
- (IBAction)focusNextSplitTextView:(id)sender
// 次の分割されたテキストビューへフォーカス移動
// ------------------------------------------------------
{
    [self focusOtherSplitTextViewOnNext:YES];
}


// ------------------------------------------------------
- (IBAction)focusPrevSplitTextView:(id)sender
// 前の分割されたテキストビューへフォーカス移動
// ------------------------------------------------------
{
    [self focusOtherSplitTextViewOnNext:NO];
}



@end



@implementation CEEditorView (Private)

//=======================================================
// Private method
//
//=======================================================

// ------------------------------------------------------
- (void)setupViews
// サブビューの初期化
// ------------------------------------------------------
{
    id theValues = [[NSUserDefaultsController sharedUserDefaultsController] values];

    // Create and configure the statusBar
    NSRect theStatusFrame = [self bounds];
    theStatusFrame.size.height = 0.0;
    _statusBar = [[CEStatusBarView allocWithZone:[self zone]] initWithFrame:theStatusFrame];
    [_statusBar setMasterView:self];
    [self addSubview:_statusBar];

    // Create CESplitView -- this will enclose everything else.
    NSRect theSplitFrame = [self bounds];
    _splitView = [[CESplitView allocWithZone:[self zone]] initWithFrame:theSplitFrame]; // ===== alloc
    [_splitView setVertical:NO];
    [_splitView setAutoresizingMask:(NSViewWidthSizable | NSViewHeightSizable)];
    [self addSubview:_splitView];

    NSRect theSubSplitFrame = [self bounds];
    CESubSplitView *theSubSplitView = 
            [[[CESubSplitView allocWithZone:[self zone]] initWithFrame:theSubSplitFrame] autorelease];
    [theSubSplitView setEditorView:self];
    [self setTextView:[theSubSplitView textView]];
    [_splitView addSubview:theSubSplitView];

    [self setupViewParamsInInit:YES];
    // （不可視文字の表示／非表示のセットは全て生成が終ってから、CEWindowController > windowDidLoad で行う）
    _coloringTimer = nil;
    _infoUpdateTimer = nil;
    _incompatibleCharTimer = nil;
    _basicColoringDelay = [[theValues valueForKey:k_key_basicColoringDelay] doubleValue];
    _firstColoringDelay = [[theValues valueForKey:k_key_firstColoringDelay] doubleValue];
    _secondColoringDelay = [[theValues valueForKey:k_key_secondColoringDelay] doubleValue];
    _infoUpdateInterval = [[theValues valueForKey:k_key_infoUpdateInterval] doubleValue];
    _incompatibleCharInterval = [[theValues valueForKey:k_key_incompatibleCharInterval] doubleValue];
}


// ------------------------------------------------------
- (void)setupViewParamsInInit:(BOOL)inBool
// サブビューに初期値を設定
// ------------------------------------------------------
{
    if (inBool) { // == initial
        id theValues = [[NSUserDefaultsController sharedUserDefaultsController] values];

        [self setShowLineNum:[[theValues valueForKey:k_key_showLineNumbers] boolValue]];
        [self setShowNavigationBar:[[theValues valueForKey:k_key_showNavigationBar] boolValue]];
        [_statusBar setShowStatusBar:[[theValues valueForKey:k_key_showStatusBar] boolValue]];
        [self setWrapLines:[[theValues valueForKey:k_key_wrapLines] boolValue]];
        [self setShowPageGuide:[[theValues valueForKey:k_key_showPageGuide] boolValue]];
        [self setIsWritable:YES];
        [self setIsAlertedNotWritable:NO];
    } else {
        [self setShowLineNum:[self showLineNum]];
        [self setShowNavigationBar:[self showNavigationBar]];
        [self setWrapLines:[self wrapLines]];
        [self setShowPageGuide:[self showPageGuide]];
    }
}


// ------------------------------------------------------
- (void)doColoringNow
// カラーリング実行
// ------------------------------------------------------
{
    if (_coloringTimer) { return; }

    NSRect theVisibleRect = [[[[self textView] enclosingScrollView] contentView] documentVisibleRect];
    NSRange theGlyphRange = [[[self textView] layoutManager] glyphRangeForBoundingRect:theVisibleRect 
                inTextContainer:[[self textView] textContainer]];
    NSRange theCharRange = [[[self textView] layoutManager] characterRangeForGlyphRange:theGlyphRange 
                actualGlyphRange:NULL];
    NSRange theSelectedRange = [[self textView] selectedRange];

    // = 選択領域（編集場所）が見えないときは編集場所周辺を更新
    if (!NSLocationInRange(theSelectedRange.location, theCharRange)) {
        NSInteger theLocation = theSelectedRange.location - theCharRange.length;
        if (theLocation < 0) { theLocation = 0; }
        NSInteger theLength = theSelectedRange.length + theCharRange.length;
        NSInteger theMax = [[self string] length] - theLocation;
        if (theLength > theMax) { theLength = theMax; }

        [[self syntax] colorVisibleRange:NSMakeRange(theLocation, theLength) withWholeString:[self string]];
    } else {
        [[self syntax] colorVisibleRange:theCharRange withWholeString:[self string]];
    }
}


// ------------------------------------------------------
- (void)doColoringWithTimer:(NSTimer *)inTimer
// タイマーの設定時刻に到達、カラーリング実行
// ------------------------------------------------------
{
    [self stopColoringTimer];
    [self doColoringNow];
}


// ------------------------------------------------------
- (void)doUpdateInfoWithTimer:(NSTimer *)inTimer
// タイマーの設定時刻に到達、情報更新
// ------------------------------------------------------
{
    [self stopInfoUpdateTimer];
    [self updateDocumentInfoStringWithDrawerForceUpdate:NO];
}


// ------------------------------------------------------
- (void)doUpdateIncompatibleCharListWithTimer:(NSTimer *)inTimer
// タイマーの設定時刻に到達、非互換文字情報更新
// ------------------------------------------------------
{
    [self stopIncompatibleCharTimer];
    [[self windowController] updateIncompatibleCharList];
}


// ------------------------------------------------------
- (void)focusOtherSplitTextViewOnNext:(BOOL)inBool
// 分割された前／後のテキストビューにフォーカス移動
// ------------------------------------------------------
{
    NSArray *theSubSplitViews = [[self splitView] subviews];
    NSInteger theCount = [theSubSplitViews count];
    if (theCount < 2) { return; }
    CESubSplitView *theCurView = (CESubSplitView *)[(CETextViewCore *)[[self window] firstResponder] delegate];
    NSInteger theIndex = [theSubSplitViews indexOfObject:theCurView];

    if (inBool) { // == Next
        theIndex++;
    } else { // == Prev
        theIndex--;
    }
    if (theIndex < 0) {
        [[self window] makeFirstResponder:[[theSubSplitViews lastObject] textView]];
    } else if (theIndex < theCount) {
        [[self window] makeFirstResponder:[theSubSplitViews[theIndex] textView]];
    } else if (theIndex >= theCount) {
        [[self window] makeFirstResponder:[theSubSplitViews[0] textView]];
    }
}




// ------------------------------------------------------
- (void)stopColoringTimer
// カラーリング更新タイマーを停止
// ------------------------------------------------------
{
    if (_coloringTimer) {
        [_coloringTimer invalidate];
        [_coloringTimer release]; // ===== release
        _coloringTimer = nil;
    }
}


// ------------------------------------------------------
- (void)stopInfoUpdateTimer
// 文書情報更新タイマーを停止
// ------------------------------------------------------
{
    if (_infoUpdateTimer) {
        [_infoUpdateTimer invalidate];
        [_infoUpdateTimer release]; // ===== release
        _infoUpdateTimer = nil;
    }
}


// ------------------------------------------------------
- (void)stopIncompatibleCharTimer
// 非互換文字情報更新タイマーを停止
// ------------------------------------------------------
{
    if (_incompatibleCharTimer) {
        [_incompatibleCharTimer invalidate];
        [_incompatibleCharTimer release]; // ===== release
        _incompatibleCharTimer = nil;
    }
}

@end
