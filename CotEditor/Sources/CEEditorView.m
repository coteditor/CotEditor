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
#import "CEToolbarController.h"
#import "constants.h"


@interface CEEditorView ()

@property (nonatomic) CEStatusBarView *statusBar;

@property (nonatomic) NSTimer *coloringTimer;
@property (nonatomic) NSTimer *infoUpdateTimer;
@property (nonatomic) NSTimer *incompatibleCharTimer;

@property (nonatomic) NSTimeInterval basicColoringDelay;
@property (nonatomic) NSTimeInterval firstColoringDelay;
@property (nonatomic) NSTimeInterval secondColoringDelay;
@property (nonatomic) NSTimeInterval infoUpdateInterval;
@property (nonatomic) NSTimeInterval incompatibleCharInterval;

@property (nonatomic) NSNumberFormatter *decimalFormatter;


// readonly
@property (nonatomic, readwrite) CESplitView *splitView;

@end




#pragma -

@implementation CEEditorView

#pragma mark Public methods

//=======================================================
// Public method
//
//=======================================================

// ------------------------------------------------------
- (instancetype)initWithFrame:(NSRect)frameRect
// 初期化
// ------------------------------------------------------
{
    self = [super initWithFrame:frameRect];
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
}


// ------------------------------------------------------
- (NSUndoManager *)undoManagerForTextView:(NSTextView *)textView
// textViewCoreのundoManager を返す
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
    return [OGRegularExpression replaceNewlineCharactersInString:[self string]
                                                   withCharacter:[self lineEndingCharacter]];
}


// ------------------------------------------------------
- (NSString *)substringWithRange:(NSRange)range
// メインtextViewの指定された範囲の文字列を返す
// ------------------------------------------------------
{
    return [[self string] substringWithRange:range];
}


// ------------------------------------------------------
- (NSString *)substringWithSelection
// メインtextViewの選択された文字列を返す
// ------------------------------------------------------
{
    return [[self string] substringWithRange:[[self textView] selectedRange]];
}


// ------------------------------------------------------
- (NSString *)substringWithSelectionForSave
// メインtextViewの選択された文字列を、行末コードを指定のものに置換して返す
// ------------------------------------------------------
{
    return [OGRegularExpression replaceNewlineCharactersInString:[self substringWithSelection]
                                                   withCharacter:[self lineEndingCharacter]];
}


// ------------------------------------------------------
- (void)setString:(NSString *)string
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

    NSString *newLineString = [OGRegularExpression replaceNewlineCharactersInString:string
                                                                      withCharacter:OgreLfNewlineCharacter];

    // UTF-16 でないものを UTF-16 で表示した時など当該フォントで表示できない文字が表示されてしまった後だと、
    // 設定されたフォントでないもので表示されることがあるため、リセットする
    [[self textView] setString:@""];
    [[self textView] setEffectTypingAttrs];
    [[self textView] setString:newLineString];
    // キャレットを先頭に移動
    if ([newLineString length] > 0) {
        [[self splitView] setAllCaretToBeginning];
    }
}


// ------------------------------------------------------
- (void)replaceTextViewSelectedStringTo:(NSString *)string scroll:(BOOL)doScroll
// 選択文字列を置換する
// ------------------------------------------------------
{
    [[self textView] replaceSelectedStringTo:string scroll:doScroll];
}


// ------------------------------------------------------
- (void)replaceTextViewAllStringTo:(NSString *)string
// 全文字列を置換
// ------------------------------------------------------
{
    [[self textView] replaceAllStringTo:string];
}


// ------------------------------------------------------
- (void)insertTextViewAfterSelectionStringTo:(NSString *)string
// 選択範囲の直後に文字列を挿入
// ------------------------------------------------------
{
    [[self textView] insertAfterSelection:string];
}


// ------------------------------------------------------
- (void)appendTextViewAfterAllStringTo:(NSString *)string
// 文字列の最後に新たな文字列を追加
// ------------------------------------------------------
{
    [[self textView] appendAllString:string];
}


// ------------------------------------------------------
- (BOOL)setSyntaxExtension:(NSString *)extension
// 文書の拡張子をCESyntaxへセット
// ------------------------------------------------------
{
    BOOL success = [[self syntax] setSyntaxStyleNameFromExtension:extension];
    NSString *name = [[self syntax] syntaxStyleName];

    [self setIsColoring:(![name isEqualToString:NSLocalizedString(@"None", nil)])];
    
    return success;
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
        NSRange range = [[self textView] selectedRange];
        NSString *tmpLocStr = [[self string] substringWithRange:NSMakeRange(0, range.location)];
        NSString *locStr = [OGRegularExpression replaceNewlineCharactersInString:tmpLocStr
                                                                   withCharacter:[self lineEndingCharacter]];
        NSString *lenStr = [self substringWithSelectionForSave];

        return (NSMakeRange([locStr length], [lenStr length]));
    }
    return ([[self textView] selectedRange]);
}


// ------------------------------------------------------
- (void)setSelectedRange:(NSRange)charRange
// 選択範囲を変更
// ------------------------------------------------------
{
    if ([[[self textView] newLineString] length] > 1) {
        NSString *tmpLocStr = [[self stringForSave] substringWithRange:NSMakeRange(0, charRange.location)];
        NSString *locStr = [OGRegularExpression replaceNewlineCharactersInString:tmpLocStr
                                                                   withCharacter:OgreLfNewlineCharacter];
        NSString *tmpLenStr = [[self stringForSave] substringWithRange:charRange];
        NSString *lenStr = [OGRegularExpression replaceNewlineCharactersInString:tmpLenStr
                                                                   withCharacter:OgreLfNewlineCharacter];
        [[self textView] setSelectedRange:NSMakeRange([locStr length], [lenStr length])];
    } else {
        [[self textView] setSelectedRange:charRange];
    }
}


// ------------------------------------------------------
- (NSArray *)allLayoutManagers
// 全layoutManagerを配列で返す
// ------------------------------------------------------
{
    NSArray *subSplitViews = [[self splitView] subviews];
    NSMutableArray *managers = [NSMutableArray array];

    for (NSTextContainer *container in subSplitViews) {
        [managers addObject:[[container textView] layoutManager]];
    }
    return managers;
}


// ------------------------------------------------------
- (void)setShowLineNum:(BOOL)showLineNum
// 行番号の表示をする／しないをセット
// ------------------------------------------------------
{
    _showLineNum = showLineNum;
    [[self splitView] setShowLineNum:showLineNum];
    [[[self windowController] toolbarController] updateToggleItem:k_showLineNumItemID setOn:showLineNum];
}


// ------------------------------------------------------
- (BOOL)showStatusBar
// ステータスバーを表示するかどうかを返す
// ------------------------------------------------------
{
    if ([self statusBar]) {
        return [[self statusBar] showStatusBar];
    } else {
        return NO;
    }
}


// ------------------------------------------------------
- (void)setShowStatusBar:(BOOL)showStatusBar
// ステータスバーを表示する／しないをセット
// ------------------------------------------------------
{
    if ([self statusBar]) {
        [[self statusBar] setShowStatusBar:showStatusBar];
        [[[self windowController] toolbarController] updateToggleItem:k_showStatusBarItemID setOn:showStatusBar];
        [self updateLineEndingsInStatusAndInfo:NO];
        if (![self infoUpdateTimer]) {
            [self updateDocumentInfoStringWithDrawerForceUpdate:NO];
        }
    }
}


// ------------------------------------------------------
- (void)setShowNavigationBar:(BOOL)showNavigationBar
// ナビバーを表示する／しないをセット
// ------------------------------------------------------
{
    _showNavigationBar = showNavigationBar;
    [[self splitView] setShowNavigationBar:showNavigationBar];
    [[[self windowController] toolbarController] updateToggleItem:k_showNavigationBarItemID setOn:showNavigationBar];
}


// ------------------------------------------------------
- (void)setWrapLines:(BOOL)wrapLines
// 行をラップする／しないをセット
// ------------------------------------------------------
{
    _wrapLines = wrapLines;
    [[self splitView] setWrapLines:wrapLines];
    [self setNeedsDisplay:YES];
    [[[self windowController] toolbarController] updateToggleItem:k_wrapLinesItemID setOn:wrapLines];
}


// ------------------------------------------------------
- (void)setIsWritable:(BOOL)isWritable
// 文書への書き込み（ファイル上書き保存）が可能かどうかをセット
// ------------------------------------------------------
{
    _isWritable = isWritable;
    
    if ([self statusBar]) {
        [[self statusBar] setShowsReadOnlyIcon:!isWritable];
    }
}


// ------------------------------------------------------
- (BOOL)shouldUseAntialias
// アンチエイリアスでの描画の許可を得る
// ------------------------------------------------------
{
    CELayoutManager *manager = (CELayoutManager *)[[self textView] layoutManager];
    
    return [manager useAntialias];
}


// ------------------------------------------------------
- (void)toggleShouldUseAntialias
// アンチエイリアス適用をトグルに切り替え
// ------------------------------------------------------
{
    CELayoutManager *manager = (CELayoutManager *)[[self textView] layoutManager];

    [[self splitView] setUseAntialias:![manager useAntialias]];
}


// ------------------------------------------------------
- (void)setShowPageGuide:(BOOL)showPageGuide
// ページガイドを表示する／しないをセット
// ------------------------------------------------------
{
    if (_showPageGuide != showPageGuide) {
        _showPageGuide = showPageGuide;
        [[[self windowController] toolbarController] updateToggleItem:k_showPageGuideItemID setOn:showPageGuide];
    }
}


// ------------------------------------------------------
- (void)setLineEndingCharacter:(OgreNewlineCharacter)lineEndingCharacter
// 行末コードをセット（OgreNewlineCharacter型）
// ------------------------------------------------------
{
    NSArray *subSplitViews = [[self splitView] subviews];
    NSString *newLineString;
    BOOL shouldUpdate = (_lineEndingCharacter != lineEndingCharacter);
    unichar theChar[2];

    if ((lineEndingCharacter > OgreNonbreakingNewlineCharacter) && 
            (lineEndingCharacter <= OgreWindowsNewlineCharacter)) {
        _lineEndingCharacter = lineEndingCharacter;
    } else {
        NSInteger defaultLineEnding = [[NSUserDefaults standardUserDefaults] integerForKey:k_key_defaultLineEndCharCode];        _lineEndingCharacter = defaultLineEnding;
    }
    // set to textViewCore.
    switch (_lineEndingCharacter) {
        case OgreLfNewlineCharacter:
            newLineString = @"\n";  // LF
            break;
        case OgreCrNewlineCharacter:  // CR
            newLineString = @"\r";
            break;
        case OgreCrLfNewlineCharacter:  // CR+LF
            newLineString = @"\r\n";
            break;
        case OgreUnicodeLineSeparatorNewlineCharacter:  // Unicode line separator
            theChar[0] = 0x2028; theChar[1] = 0;
            newLineString = [[NSString alloc] initWithCharacters:theChar length:1];
            break;
        case OgreUnicodeParagraphSeparatorNewlineCharacter:  // Unicode paragraph separator
            theChar[0] = 0x2029; theChar[1] = 0;
            newLineString = [[NSString alloc] initWithCharacters:theChar length:1];
            break;
        case OgreNonbreakingNewlineCharacter:  // 改行なしの場合
            newLineString = @"";
            break;
            
        default:
            return;
    }
    for (NSTextContainer *container in subSplitViews) {
        [(CETextViewCore *)[container textView] setNewLineString:newLineString];
    }
    if (shouldUpdate) {
        [self updateLineEndingsInStatusAndInfo:NO];
        if (![self infoUpdateTimer]) {
            [self updateDocumentInfoStringWithDrawerForceUpdate:NO];
        }
    }
}


// ------------------------------------------------------
- (NSString *)syntaxStyleNameToColoring
// シンタックススタイル名を返す
// ------------------------------------------------------
{
    return ([self syntax]) ? [[self syntax] syntaxStyleName] : nil;
}


// ------------------------------------------------------
- (void)setSyntaxStyleNameToColoring:(NSString *)name recolorNow:(BOOL)recolorNow
// シンタックススタイル名をセット
// ------------------------------------------------------
{
    if ([self syntax]) {
        [[self splitView] setSyntaxStyleNameToSyntax:name];
        [self setIsColoring:(![name isEqualToString:NSLocalizedString(@"None", nil)])];
        if (recolorNow) {
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
    if ([self isWritable] || [self isAlertedNotWritable]) { return; }
    
    if ([[NSUserDefaults standardUserDefaults] boolForKey:k_key_showAlertForNotWritable]) {

        NSAlert *alert = [NSAlert alertWithMessageText:NSLocalizedString(@"The file is not writable.", nil)
                                         defaultButton:nil
                                       alternateButton:nil
                                           otherButton:nil
                             informativeTextWithFormat:NSLocalizedString(@"You may not be able to save your changes, but you will be able to save a copy somewhere else.", nil)];

        [alert beginSheetModalForWindow:[self window]
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
    BOOL shouldUpdateStatusBar = [[self statusBar] showStatusBar];
    BOOL shouldUpdateDrawer = (doUpdate) ? YES : [[self windowController] needsInfoDrawerUpdate];
    
    if (!shouldUpdateStatusBar && !shouldUpdateDrawer) { return; }
    
    NSSpellChecker *spellChecker = [NSSpellChecker sharedSpellChecker];
    NSString *theString = ([self lineEndingCharacter] == OgreCrLfNewlineCharacter) ? [self stringForSave] : [self string];
    NSString *singleCharInfo = nil;
    NSRange selectedRange = [self selectedRange];
    NSUInteger numberOfLines = 0, currentLine = 0, length = [theString length];
    NSUInteger lineStart = 0, countInLine = 0, index = 0;
    NSUInteger numberOfSelectedWords = 0, numberOfWords = [spellChecker countWordsInString:theString language:nil];

    // IM で変換途中の文字列は選択範囲としてカウントしない (2007.05.20)
    if ([[self textView] hasMarkedText]) {
        selectedRange.length = 0;
    }
    if (length > 0) {
        lineStart = [theString lineRangeForRange:selectedRange].location;
        countInLine = selectedRange.location - lineStart;

        for (index = 0, numberOfLines = 0; index < length; numberOfLines++) {
            if (index <= selectedRange.location) {
                currentLine = numberOfLines + 1;
            }
            index = NSMaxRange([theString lineRangeForRange:NSMakeRange(index, 0)]);
        }
        
        if (selectedRange.length > 0) {
            numberOfSelectedWords = [spellChecker countWordsInString:[theString substringWithRange:selectedRange]
                                                                                          language:nil];
        }
        
        // 行末コードをカウントしない場合は再計算
        if (![[NSUserDefaults standardUserDefaults] boolForKey:k_key_countLineEndingAsChar]) {
            NSString *locStr = [theString substringToIndex:selectedRange.location];

            selectedRange.location = [[OGRegularExpression chomp:locStr] length];
            selectedRange.length = [[OGRegularExpression chomp:[self substringWithSelection]] length];
            length = [[OGRegularExpression chomp:theString] length];
        }
    }

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
        [[[self statusBar] leftTextField] setStringValue:statusString];
    }
    if (shouldUpdateDrawer) {
        NSString *linesInfo, *charsInfo, *selectInfo, *wordsInfo;
        
        linesInfo = [NSString stringWithFormat:@"%ld / %ld", (long)currentLine, (long)numberOfLines];
        [[self windowController] setLinesInfo:linesInfo];
        charsInfo = [NSString stringWithFormat:@"%ld / %ld", (long)selectedRange.location, (long)length];
        [[self windowController] setCharsInfo:charsInfo];
        [[self windowController] setInLineInfo:[NSString stringWithFormat:@"%ld", (long)countInLine]];
        selectInfo = (selectedRange.length > 0) ? [NSString stringWithFormat:@"%ld", (long)selectedRange.length] : @" - ";
        [[self windowController] setSelectInfo:selectInfo];
        [[self windowController] setSingleCharInfo:singleCharInfo];
        wordsInfo = [NSString stringWithFormat:@"%ld / %ld", (long)numberOfSelectedWords, (long)numberOfWords];
        [[self windowController] setWordsInfo:wordsInfo];
    }
}


// ------------------------------------------------------
- (void)updateLineEndingsInStatusAndInfo:(BOOL)inBool
// ステータスバーと情報ドローワの行末コード表記を更新
// ------------------------------------------------------
{
    BOOL shouldUpdateStatusBar = [[self statusBar] showStatusBar];
    BOOL shouldUpdateDrawer = (inBool) ? YES : [[self windowController] needsInfoDrawerUpdate];
    if (!shouldUpdateStatusBar && !shouldUpdateDrawer) { return; }
    
    NSString *encodingInfo, *lineEndingsInfo;
    
    switch ([self lineEndingCharacter]) {
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
        [[[self statusBar] rightTextField] setStringValue:[NSString stringWithFormat:@"%@ %@", encodingInfo, lineEndingsInfo]];
    }
    if (shouldUpdateDrawer) {
        [[self windowController] setEncodingInfo:encodingInfo];
        [[self windowController] setLineEndingsInfo:lineEndingsInfo];
    }
}


// ------------------------------------------------------
- (void)setShowInvisibleChars:(BOOL)showInvisibleChars
// 不可視文字の表示／非表示を設定
// ------------------------------------------------------
{
    [[self splitView] setShowInvisibles:showInvisibleChars];
}


// ------------------------------------------------------
- (void)updateShowInvisibleCharsMenuToolTip
// 不可視文字表示メニューのツールチップを更新
// ------------------------------------------------------
{
    NSMenuItem *menuItem = [[[[NSApp mainMenu] itemAtIndex:k_viewMenuIndex] submenu] itemWithTag:k_showInvisibleCharMenuItemTag];

    NSString *toolTip = @"";
    if (![[self document] canActivateShowInvisibleCharsItem]) {
        toolTip = @"To display invisible characters, set in Preferences and re-open the document.";
    }
    [menuItem setToolTip:NSLocalizedString(toolTip, @"")];
}


// ------------------------------------------------------
- (void)setupColoringTimer
// カラーリングタイマーのファイヤーデイトを設定時間後にセット
// ------------------------------------------------------
{
    if ([self isColoring]) {
        // 遅延カラーリング
        if ([[NSUserDefaults standardUserDefaults] boolForKey:k_key_delayColoring]) {
            if ([self coloringTimer]) {
                [[self coloringTimer] setFireDate:[NSDate dateWithTimeIntervalSinceNow:[self secondColoringDelay]]];
            } else {
                [self setColoringTimer:[NSTimer scheduledTimerWithTimeInterval:[self firstColoringDelay]
                                                                        target:self
                                                                      selector:@selector(doColoringWithTimer:)
                                                                      userInfo:nil repeats:NO]];
            }
        } else {
            if ([self coloringTimer]) {
                [[self coloringTimer] setFireDate:[NSDate dateWithTimeIntervalSinceNow:[self basicColoringDelay]]];
            } else {
                [self setColoringTimer:[NSTimer scheduledTimerWithTimeInterval:[self basicColoringDelay]
                                                                        target:self
                                                                      selector:@selector(doColoringWithTimer:)
                                                                      userInfo:nil repeats:NO]];
            }
        }
    }
}


// ------------------------------------------------------
- (void)setupIncompatibleCharTimer
// 非互換文字更新タイマーのファイヤーデイトを設定時間後にセット
// ------------------------------------------------------
{
    if ([[self windowController] needsIncompatibleCharDrawerUpdate]) {
        if ([self incompatibleCharTimer]) {
            [[self incompatibleCharTimer] setFireDate:[NSDate dateWithTimeIntervalSinceNow:[self incompatibleCharInterval]]];
        } else {
            [self setIncompatibleCharTimer:[NSTimer scheduledTimerWithTimeInterval:[self incompatibleCharInterval]
                                                                            target:self
                                                                          selector:@selector(doUpdateIncompatibleCharListWithTimer:)
                                                                          userInfo:nil
                                                                           repeats:NO]];
        }
    }
}


// ------------------------------------------------------
- (void)setupInfoUpdateTimer
// 文書情報更新タイマーのファイヤーデイトを設定時間後にセット
// ------------------------------------------------------
{
    if ([self infoUpdateTimer]) {
        [[self infoUpdateTimer] setFireDate:[NSDate dateWithTimeIntervalSinceNow:[self infoUpdateInterval]]];
    } else {
        [self setInfoUpdateTimer:[NSTimer scheduledTimerWithTimeInterval:[self infoUpdateInterval]
                                                                  target:self
                                                                selector:@selector(doUpdateInfoWithTimer:)
                                                                userInfo:nil
                                                                 repeats:NO]];
    }
}


// ------------------------------------------------------
- (void)updateCloseSubSplitViewButton
// テキストビュー分割削除ボタンの有効／無効を更新
// ------------------------------------------------------
{
    BOOL enabled = ([[[self splitView] subviews] count] > 1);

    [[self splitView] setCloseSubSplitViewButtonEnabled:enabled];
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



#pragma mark Protocol

//=======================================================
// NSMenuValidation Protocol
//
//=======================================================

// ------------------------------------------------------
- (BOOL)validateMenuItem:(NSMenuItem *)menuItem
// メニュー項目の有効・無効を制御
// ------------------------------------------------------
{
    NSInteger theState = NSOffState;

    if ([menuItem action] == @selector(toggleShowLineNum:)) {
        if ([self showLineNum]) {theState = NSOnState;}
    } else if ([menuItem action] == @selector(toggleShowStatusBar:)) {
        if ([self showStatusBar]) {theState = NSOnState;}
    } else if ([menuItem action] == @selector(toggleShowNavigationBar:)) {
        if ([self showNavigationBar]) {theState = NSOnState;}
    } else if ([menuItem action] == @selector(toggleWrapLines:)) {
        if ([self wrapLines]) {theState = NSOnState;}
    } else if ([menuItem action] == @selector(toggleUseAntialias:)) {
        if ([self shouldUseAntialias]) {theState = NSOnState;}
    } else if ([menuItem action] == @selector(toggleShowInvisibleChars:)) {
        if ([(CELayoutManager *)[[self textView] layoutManager] showInvisibles]) {theState = NSOnState;}
        [menuItem setState:theState];
        return ([[self document] canActivateShowInvisibleCharsItem]);
    } else if ([menuItem action] == @selector(toggleShowPageGuide:)) {
        if ([self showPageGuide]) {theState = NSOnState;}
    } else if (([menuItem action] == @selector(focusNextSplitTextView:)) || 
            ([menuItem action] == @selector(focusPrevSplitTextView:)) || 
            ([menuItem action] == @selector(closeSplitTextView:))) {
        return ([[[self splitView] subviews] count] > 1);
    }
    [menuItem setState:theState];

    return YES;
}



#pragma mark Action Messages

//=======================================================
// Action messages
//
//=======================================================

// ------------------------------------------------------
- (IBAction)toggleShowLineNum:(id)sender
// 行番号表示をトグルに切り替える
// ------------------------------------------------------
{
    [self setShowLineNum:![self showLineNum]];
}


// ------------------------------------------------------
- (IBAction)toggleShowStatusBar:(id)sender
// ステータスバーの表示をトグルに切り替える
// ------------------------------------------------------
{
    [self setShowStatusBar:![self showStatusBar]];
}


// ------------------------------------------------------
- (IBAction)toggleShowNavigationBar:(id)sender
// ナビゲーションバーの表示をトグルに切り替える
// ------------------------------------------------------
{
    [self setShowNavigationBar:![self showNavigationBar]];
}


// ------------------------------------------------------
- (IBAction)toggleWrapLines:(id)sender
// ワードラップをトグルに切り替える
// ------------------------------------------------------
{
    [self setWrapLines:![self wrapLines]];
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
    CELayoutManager *layoutManager = (CELayoutManager *)[[self textView] layoutManager];
    BOOL showInvisibles = [layoutManager showInvisibles];

    [[self splitView] setShowInvisibles:!showInvisibles];
    [[[self windowController] toolbarController] updateToggleItem:k_showInvisibleCharsItemID setOn:!showInvisibles];
}


// ------------------------------------------------------
- (IBAction)toggleShowPageGuide:(id)sender
// ページガイド表示をトグルに切り替える
// ------------------------------------------------------
{
    [self setShowPageGuide:![self showPageGuide]];
    [[self splitView] setNeedsDisplay:YES];
}


// ------------------------------------------------------
- (IBAction)openSplitTextView:(id)sender
// テキストビュー分割を行う
// ------------------------------------------------------
{
    CESubSplitView *masterView = ([sender isMemberOfClass:[NSMenuItem class]]) ? 
            (CESubSplitView *)[(CETextViewCore *)[[self window] firstResponder] delegate] :
            [(CENavigationBarView *)[sender superview] masterView];
    if (masterView == nil) { return; }
    NSRect subSplitFrame = [masterView bounds];
    NSRange selectedRange = [[masterView textView] selectedRange];
    CESubSplitView *subSplitView = [[CESubSplitView alloc] initWithFrame:subSplitFrame];

    [subSplitView replaceTextStorage:[[self textView] textStorage]];
    [subSplitView setEditorView:self];
    // あらたなsubViewは、押された追加ボタンが属する（またはフォーカスのある）subSplitViewのすぐ下に挿入する
    [[self splitView] addSubview:subSplitView positioned:NSWindowAbove relativeTo:masterView];
    [[self splitView] adjustSubviews];
    [self setupViewParamsInInit:NO];
    [[subSplitView textView] setFont:[[self textView] font]];
    [[subSplitView textView] setLineSpacing:[[self textView] lineSpacing]];
    [self setShowInvisibleChars:[(CELayoutManager *)[[self textView] layoutManager] showInvisibles]];
    [[subSplitView textView] setSelectedRange:selectedRange];
    [[self splitView] adjustSubviews];
    [subSplitView setSyntaxStyleNameToSyntax:[[self syntax] syntaxStyleName]];
    [[subSplitView syntax] colorAllString:[self string]];
    [[self textView] centerSelectionInVisibleArea:self];
    [[self window] makeFirstResponder:[subSplitView textView]];
    [self setLineEndingCharacter:[self lineEndingCharacter]];
    [[subSplitView textView] centerSelectionInVisibleArea:self];
    [self updateCloseSubSplitViewButton];
}


// ------------------------------------------------------
- (IBAction)closeSplitTextView:(id)sender
// 分割されたテキストビューを閉じる
// ------------------------------------------------------
{
    BOOL isSenderMenu = [sender isMemberOfClass:[NSMenuItem class]];
    CESubSplitView *firstResponderSubSplitView = (CESubSplitView *)[(CETextViewCore *)[[self window] firstResponder] delegate];
    CESubSplitView *subSplitViewToClose = (isSenderMenu) ?
            firstResponderSubSplitView : [(CENavigationBarView *)[sender superview] masterView];
    if (subSplitViewToClose == nil) { return; }
    NSArray *subViews = [[self splitView] subviews];
    NSUInteger count = [subViews count];
    NSUInteger deleteIndex = [subViews indexOfObject:subSplitViewToClose];
    NSUInteger index = 0;

    if (isSenderMenu || (deleteIndex == [subViews indexOfObject:firstResponderSubSplitView])) {
        index = deleteIndex + 1;
        if (index >= count) {
            index = count - 2;
        }
        [[self window] makeFirstResponder:[subViews[index] textView]];
    }
    [subSplitViewToClose removeFromSuperview];
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



#pragma mark Private Methods

//=======================================================
// Private method
//
//=======================================================

// ------------------------------------------------------
- (void)setupViews
// サブビューの初期化
// ------------------------------------------------------
{
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];

    // Create and configure the statusBar
    NSRect statusFrame = [self bounds];
    statusFrame.size.height = 0.0;
    [self setStatusBar:[[CEStatusBarView alloc] initWithFrame:statusFrame]];
    [[self statusBar] setMasterView:self];
    [self addSubview:[self statusBar]];

    // Create CESplitView -- this will enclose everything else.
    NSRect splitFrame = [self bounds];
    [self setSplitView:[[CESplitView alloc] initWithFrame:splitFrame]];
    [[self splitView] setVertical:NO];
    [[self splitView] setAutoresizingMask:(NSViewWidthSizable | NSViewHeightSizable)];
    [self addSubview:[self splitView]];

    NSRect subSplitFrame = [self bounds];
    CESubSplitView *subSplitView = [[CESubSplitView alloc] initWithFrame:subSplitFrame];
    [subSplitView setEditorView:self];
    [self setTextView:[subSplitView textView]];
    [[self splitView] addSubview:subSplitView];

    [self setupViewParamsInInit:YES];
    // （不可視文字の表示／非表示のセットは全て生成が終ってから、CEWindowController > windowDidLoad で行う）
    [self setColoringTimer:nil];
    [self setInfoUpdateTimer:nil];
    [self setInfoUpdateTimer:nil];
    [self setBasicColoringDelay:[defaults doubleForKey:k_key_basicColoringDelay]];
    [self setFirstColoringDelay:[defaults doubleForKey:k_key_firstColoringDelay]];
    [self setSecondColoringDelay:[defaults doubleForKey:k_key_secondColoringDelay]];
    [self setInfoUpdateInterval:[defaults doubleForKey:k_key_infoUpdateInterval]];
    [self setIncompatibleCharInterval:[defaults doubleForKey:k_key_incompatibleCharInterval]];
}


// ------------------------------------------------------
- (void)setupViewParamsInInit:(BOOL)isInitial
// サブビューに初期値を設定
// ------------------------------------------------------
{
    if (isInitial) {
        NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];

        [self setShowLineNum:[defaults boolForKey:k_key_showLineNumbers]];
        [self setShowNavigationBar:[defaults boolForKey:k_key_showNavigationBar]];
        [[self statusBar] setShowStatusBar:[defaults boolForKey:k_key_showStatusBar]];
        [self setWrapLines:[defaults boolForKey:k_key_wrapLines]];
        [self setShowPageGuide:[defaults boolForKey:k_key_showPageGuide]];
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
    if ([self coloringTimer]) { return; }

    NSRect visibleRect = [[[[self textView] enclosingScrollView] contentView] documentVisibleRect];
    NSRange glyphRange = [[[self textView] layoutManager] glyphRangeForBoundingRect:visibleRect
                                                                    inTextContainer:[[self textView] textContainer]];
    NSRange charRange = [[[self textView] layoutManager] characterRangeForGlyphRange:glyphRange
                                                                    actualGlyphRange:NULL];
    NSRange selectedRange = [[self textView] selectedRange];

    // = 選択領域（編集場所）が見えないときは編集場所周辺を更新
    if (!NSLocationInRange(selectedRange.location, charRange)) {
        NSInteger location = selectedRange.location - charRange.length;
        if (location < 0) { location = 0; }
        NSInteger length = selectedRange.length + charRange.length;
        NSInteger max = [[self string] length] - location;
        length = MIN(length, max);

        [[self syntax] colorVisibleRange:NSMakeRange(location, length) withWholeString:[self string]];
    } else {
        [[self syntax] colorVisibleRange:charRange withWholeString:[self string]];
    }
}


// ------------------------------------------------------
- (void)doColoringWithTimer:(NSTimer *)timer
// タイマーの設定時刻に到達、カラーリング実行
// ------------------------------------------------------
{
    [self stopColoringTimer];
    [self doColoringNow];
}


// ------------------------------------------------------
- (void)doUpdateInfoWithTimer:(NSTimer *)timer
// タイマーの設定時刻に到達、情報更新
// ------------------------------------------------------
{
    [self stopInfoUpdateTimer];
    [self updateDocumentInfoStringWithDrawerForceUpdate:NO];
}


// ------------------------------------------------------
- (void)doUpdateIncompatibleCharListWithTimer:(NSTimer *)timer
// タイマーの設定時刻に到達、非互換文字情報更新
// ------------------------------------------------------
{
    [self stopIncompatibleCharTimer];
    [[self windowController] updateIncompatibleCharList];
}


// ------------------------------------------------------
- (void)focusOtherSplitTextViewOnNext:(BOOL)isOnNext
// 分割された前／後のテキストビューにフォーカス移動
// ------------------------------------------------------
{
    NSArray *subSplitViews = [[self splitView] subviews];
    NSInteger count = [subSplitViews count];
    if (count < 2) { return; }
    CESubSplitView *currentView = (CESubSplitView *)[(CETextViewCore *)[[self window] firstResponder] delegate];
    NSInteger index = [subSplitViews indexOfObject:currentView];

    if (isOnNext) { // == Next
        index++;
    } else { // == Prev
        index--;
    }
    if (index < 0) {
        [[self window] makeFirstResponder:[[subSplitViews lastObject] textView]];
    } else if (index < count) {
        [[self window] makeFirstResponder:[subSplitViews[index] textView]];
    } else if (index >= count) {
        [[self window] makeFirstResponder:[subSplitViews[0] textView]];
    }
}




// ------------------------------------------------------
- (void)stopColoringTimer
// カラーリング更新タイマーを停止
// ------------------------------------------------------
{
    if ([self coloringTimer]) {
        [[self coloringTimer] invalidate];
        [self setColoringTimer:nil];
    }
}


// ------------------------------------------------------
- (void)stopInfoUpdateTimer
// 文書情報更新タイマーを停止
// ------------------------------------------------------
{
    if ([self infoUpdateTimer]) {
        [[self infoUpdateTimer] invalidate];
        [self setInfoUpdateTimer:nil];
    }
}


// ------------------------------------------------------
- (void)stopIncompatibleCharTimer
// 非互換文字情報更新タイマーを停止
// ------------------------------------------------------
{
    if ([self incompatibleCharTimer]) {
        [[self incompatibleCharTimer] invalidate];
        [self setIncompatibleCharTimer:nil];
    }
}

@end
