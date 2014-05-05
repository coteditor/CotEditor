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


// readonly
@property (nonatomic, readwrite) CESplitView *splitView;

@end




#pragma -

@implementation CEEditorView

#pragma mark NSView methods

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
        [self setupViews];
    }
    return self;
}


// ------------------------------------------------------
/// 後片付け
- (void)dealloc
// ------------------------------------------------------
{
    [self stopAllTimer];
}



#pragma mark Public methods

//=======================================================
// Public method
//
//=======================================================

// ------------------------------------------------------
/// textViewCoreのundoManager を返す
- (NSUndoManager *)undoManagerForTextView:(NSTextView *)textView
// ------------------------------------------------------
{
    return [[self document] undoManager];
}


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
/// navigationBarを返す
- (CENavigationBarView *)navigationBar
// ------------------------------------------------------
{
    return [(CESubSplitView *)[[self textView] delegate] navigationBar];
}


// ------------------------------------------------------
/// syntaxオブジェクトを返す
- (CESyntax *)syntax
// ------------------------------------------------------
{
    return [(CESubSplitView *)[[self textView] delegate] syntax];
}


// ------------------------------------------------------
/// メインtextViewの文字列を返す（改行コードはLF固定）
- (NSString *)string
// ------------------------------------------------------
{
    return ([[self textView] string]);
}


// ------------------------------------------------------
/// 改行コードを指定のものに置換したメインtextViewの文字列を返す
- (NSString *)stringForSave
// ------------------------------------------------------
{
    return [OGRegularExpression replaceNewlineCharactersInString:[self string]
                                                   withCharacter:[self lineEndingCharacter]];
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
                                                   withCharacter:[self lineEndingCharacter]];
}


// ------------------------------------------------------
/// メインtextViewに文字列をセット。改行コードはLFに置換される
- (void)setString:(NSString *)string
// ------------------------------------------------------
{
    // 表示する文字列内の改行コードをLFに統一する
    // （その他の編集は、下記の通りの別の場所で置換している）
    // # テキスト編集時の改行コードの置換場所
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
    [[self textView] applyTypingAttributes];
    [[self textView] setString:newLineString];
    // キャレットを先頭に移動
    if ([newLineString length] > 0) {
        [[self splitView] setAllCaretToBeginning];
    }
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
/// 文書の拡張子をCESyntaxへセット
- (BOOL)setSyntaxExtension:(NSString *)extension
// ------------------------------------------------------
{
    BOOL success = [[self syntax] setSyntaxStyleNameFromExtension:extension];
    NSString *name = [[self syntax] syntaxStyleName];

    [self setIsColoring:(![name isEqualToString:NSLocalizedString(@"None", nil)])];
    
    return success;
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
                                                                   withCharacter:[self lineEndingCharacter]];
        NSString *lenStr = [self substringWithSelectionForSave];

        return (NSMakeRange([locStr length], [lenStr length]));
    }
    return ([[self textView] selectedRange]);
}


// ------------------------------------------------------
/// 選択範囲を変更
- (void)setSelectedRange:(NSRange)charRange
// ------------------------------------------------------
{
    if ([[[self textView] lineEndingString] length] > 1) {
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
/// 全layoutManagerを配列で返す
- (NSArray *)allLayoutManagers
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
/// 行番号の表示をする／しないをセット
- (void)setShowLineNum:(BOOL)showLineNum
// ------------------------------------------------------
{
    _showLineNum = showLineNum;
    [[self splitView] setShowLineNum:showLineNum];
    [[[self windowController] toolbarController] updateToggleItem:k_showLineNumItemID setOn:showLineNum];
}


// ------------------------------------------------------
/// ステータスバーを表示するかどうかを返す
- (BOOL)showStatusBar
// ------------------------------------------------------
{
    if ([self statusBar]) {
        return [[self statusBar] showStatusBar];
    } else {
        return NO;
    }
}


// ------------------------------------------------------
/// ステータスバーを表示する／しないをセット
- (void)setShowStatusBar:(BOOL)showStatusBar
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
/// ナビバーを表示する／しないをセット
- (void)setShowNavigationBar:(BOOL)showNavigationBar
// ------------------------------------------------------
{
    _showNavigationBar = showNavigationBar;
    [[self splitView] setShowNavigationBar:showNavigationBar];
    [[[self windowController] toolbarController] updateToggleItem:k_showNavigationBarItemID setOn:showNavigationBar];
}


// ------------------------------------------------------
/// 行をラップする／しないをセット
- (void)setWrapLines:(BOOL)wrapLines
// ------------------------------------------------------
{
    _wrapLines = wrapLines;
    [[self splitView] setWrapLines:wrapLines];
    [self setNeedsDisplay:YES];
    [[[self windowController] toolbarController] updateToggleItem:k_wrapLinesItemID setOn:wrapLines];
}


// ------------------------------------------------------
/// 文書への書き込み（ファイル上書き保存）が可能かどうかをセット
- (void)setIsWritable:(BOOL)isWritable
// ------------------------------------------------------
{
    _isWritable = isWritable;
    
    if ([self statusBar]) {
        [[self statusBar] setShowsReadOnlyIcon:!isWritable];
    }
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

    [[self splitView] setUseAntialias:![manager useAntialias]];
}


// ------------------------------------------------------
/// ページガイドを表示する／しないをセット
- (void)setShowPageGuide:(BOOL)showPageGuide
// ------------------------------------------------------
{
    if (_showPageGuide != showPageGuide) {
        _showPageGuide = showPageGuide;
        [[[self windowController] toolbarController] updateToggleItem:k_showPageGuideItemID setOn:showPageGuide];
    }
}


// ------------------------------------------------------
/// 改行コードをセット（OgreNewlineCharacter型）
- (void)setLineEndingCharacter:(OgreNewlineCharacter)lineEndingCharacter
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
        [(CETextViewCore *)[container textView] setLineEndingString:newLineString];
    }
    if (shouldUpdate) {
        [self updateLineEndingsInStatusAndInfo:NO];
        if (![self infoUpdateTimer]) {
            [self updateDocumentInfoStringWithDrawerForceUpdate:NO];
        }
    }
}


// ------------------------------------------------------
/// シンタックススタイル名を返す
- (NSString *)syntaxStyleNameToColoring
// ------------------------------------------------------
{
    return ([self syntax]) ? [[self syntax] syntaxStyleName] : nil;
}


// ------------------------------------------------------
/// シンタックススタイル名をセット
- (void)setSyntaxStyleNameToColoring:(NSString *)name recolorNow:(BOOL)recolorNow
// ------------------------------------------------------
{
    if ([self syntax]) {
        [[self splitView] setSyntaxStyleNameToSyntax:name];
        [self setIsColoring:(![name isEqualToString:NSLocalizedString(@"None", nil)])];
        if (recolorNow) {
            [self recolorAllString];
            if ([self showNavigationBar]) {
                [[self splitView] updateAllOutlineMenu];
            }
        }
    }
}


// ------------------------------------------------------
/// 全テキストを再カラーリング
- (void)recolorAllString
// ------------------------------------------------------
{
    [self stopColoringTimer];
    [[self splitView] recoloringAllTextView];
}


// ------------------------------------------------------
/// ディレイをかけて、全テキストを再カラーリング、アウトラインメニューを更新
- (void)updateColoringAndOutlineMenuWithDelay
// ------------------------------------------------------
{
    [self stopColoringTimer];
    // （下記のメソッドの実行順序を変更すると、Tigerで大きめの書類を開いたときに異常に遅くなるので注意。 2008.05.03.）
    [[self splitView] performSelector:@selector(recoloringAllTextView) withObject:nil afterDelay:0.03];
    [[self splitView] performSelector:@selector(updateAllOutlineMenu) withObject:nil afterDelay:0];
}


// ------------------------------------------------------
/// 書き込み禁止アラートを表示
- (void)alertForNotWritable
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
/// ドローワの文書情報を更新
- (void)updateDocumentInfoStringWithDrawerForceUpdate:(BOOL)doUpdate
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
    NSUInteger numberOfSelectedLines = 0;
    NSUInteger lineStart = 0, column = 0, index = 0;
    NSUInteger numberOfSelectedWords = 0, numberOfWords = 0;
    BOOL isSelected = (selectedRange.length > 0);

    // IM で変換途中の文字列は選択範囲としてカウントしない (2007.05.20)
    if ([[self textView] hasMarkedText]) {
        selectedRange.length = 0;
    }
    if (length > 0) {
        lineStart = [theString lineRangeForRange:selectedRange].location;
        column = selectedRange.location - lineStart;

        for (index = 0, numberOfLines = 0; index < length; numberOfLines++) {
            if (index <= selectedRange.location) {
                currentLine = numberOfLines + 1;
            }
            index = NSMaxRange([theString lineRangeForRange:NSMakeRange(index, 0)]);
        }
        
        numberOfWords = [spellChecker countWordsInString:theString language:nil];
        if (isSelected) {
            NSString *selectedString = [theString substringWithRange:selectedRange];
            numberOfSelectedLines = [[selectedString componentsSeparatedByString:@"\n"] count];
            numberOfSelectedWords = [spellChecker countWordsInString:selectedString language:nil];
        }
        
        // 改行コードをカウントしない場合は再計算
        if (![[NSUserDefaults standardUserDefaults] boolForKey:k_key_countLineEndingAsChar]) {
            NSString *locStr = [theString substringToIndex:selectedRange.location];

            selectedRange.location = [[OGRegularExpression chomp:locStr] length];
            selectedRange.length = [[OGRegularExpression chomp:[self substringWithSelection]] length];
            length = [[OGRegularExpression chomp:theString] length];
        }
    }

    if (shouldUpdateStatusBar) {
        [[self statusBar] setLinesInfo:numberOfLines];
        [[self statusBar] setSelectedLinesInfo:numberOfSelectedLines];
        [[self statusBar] setCharsInfo:length];
        [[self statusBar] setSelectedCharsInfo:selectedRange.length];
        [[self statusBar] setWordsInfo:numberOfWords];
        [[self statusBar] setSelectedWordsInfo:numberOfSelectedWords];
        [[self statusBar] setLocationInfo:selectedRange.location];
        [[self statusBar] setLineInfo:currentLine];
        [[self statusBar] setColumnInfo:column];
        [[self statusBar] updateLeftField];
    }
    if (shouldUpdateDrawer) {
        NSString *linesInfo, *charsInfo, *selectInfo, *wordsInfo, *byteLengthInfo;
        
        if (selectedRange.length == 2) {
            unichar firstChar = [theString characterAtIndex:selectedRange.location];
            unichar secondChar = [theString characterAtIndex:selectedRange.location + 1];
            if (CFStringIsSurrogateHighCharacter(firstChar) && CFStringIsSurrogateLowCharacter(secondChar)) {
                UTF32Char pair = CFStringGetLongCharacterForSurrogatePair(firstChar, secondChar);
                singleCharInfo = [NSString stringWithFormat:@"U+%04lX", (unsigned long)pair];
            }
        }
        if (selectedRange.length == 1) {
            unichar character = [theString characterAtIndex:selectedRange.location];
            singleCharInfo = [NSString stringWithFormat:@"U+%.4X", character];
        }
        NSUInteger byteLength = [theString lengthOfBytesUsingEncoding:[[self document] encodingCode]];
        NSUInteger selectedByteLength = [[theString substringWithRange:selectedRange]
                                         lengthOfBytesUsingEncoding:[[self document] encodingCode]];
        
        linesInfo = [NSString stringWithFormat:@"%ld", (long)numberOfLines];
        if (isSelected) {
            linesInfo = [linesInfo stringByAppendingFormat:@" (%ld)", (long)numberOfSelectedLines];
        }
        [[self windowController] setLinesInfo:linesInfo];
        
        charsInfo = [NSString stringWithFormat:@"%ld", (long)length];
        if (isSelected) {
            charsInfo = [charsInfo stringByAppendingFormat:@" (%ld)", (long)selectedRange.length];
        }
        [[self windowController] setCharsInfo:charsInfo];
        
        byteLengthInfo = [NSString stringWithFormat:@"%ld", (long)byteLength];
        if (isSelected) {
            byteLengthInfo = [byteLengthInfo stringByAppendingFormat:@" (%ld)", (long)selectedByteLength];
        }
        [[self windowController] setByteLengthInfo:byteLengthInfo];
        
        wordsInfo = [NSString stringWithFormat:@"%ld", (long)numberOfWords];
        if (isSelected) {
            wordsInfo = [wordsInfo stringByAppendingFormat:@" (%ld)", (long)numberOfSelectedWords];
        }
        [[self windowController] setWordsInfo:wordsInfo];
        
        [[self windowController] setLocationInfo:[NSString stringWithFormat:@"%ld", (long)selectedRange.location]];
        [[self windowController] setColumnInfo:[NSString stringWithFormat:@"%ld", (long)column]];
        [[self windowController] setLineInfo:[NSString stringWithFormat:@"%ld", (long)currentLine]];
        [[self windowController] setSingleCharInfo:singleCharInfo];
    }
}


// ------------------------------------------------------
/// ステータスバーと情報ドローワの改行コード表記を更新
- (void)updateLineEndingsInStatusAndInfo:(BOOL)inBool
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
        [[self statusBar] setEncodingInfo:encodingInfo];
        [[self statusBar] setLineEndingsInfo:lineEndingsInfo];
        [[self statusBar] setFileSizeInfo:[[[self document] fileAttributes] fileSize]];
        [[self statusBar] updateRightField];
    }
    if (shouldUpdateDrawer) {
        [[self windowController] setEncodingInfo:encodingInfo];
        [[self windowController] setLineEndingsInfo:lineEndingsInfo];
    }
}


// ------------------------------------------------------
/// 不可視文字の表示／非表示を設定
- (void)setShowInvisibleChars:(BOOL)showInvisibleChars
// ------------------------------------------------------
{
    [[self splitView] setShowInvisibles:showInvisibleChars];
}


// ------------------------------------------------------
/// 不可視文字表示メニューのツールチップを更新
- (void)updateShowInvisibleCharsMenuToolTip
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
/// カラーリングタイマーのファイヤーデイトを設定時間後にセット
- (void)setupColoringTimer
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
/// 非互換文字更新タイマーのファイヤーデイトを設定時間後にセット
- (void)setupIncompatibleCharTimer
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
/// 文書情報更新タイマーのファイヤーデイトを設定時間後にセット
- (void)setupInfoUpdateTimer
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
/// テキストビュー分割削除ボタンの有効／無効を更新
- (void)updateCloseSubSplitViewButton
// ------------------------------------------------------
{
    BOOL enabled = ([[[self splitView] subviews] count] > 1);

    [[self splitView] setCloseSubSplitViewButtonEnabled:enabled];
}


// ------------------------------------------------------
/// 全タイマーを停止
- (void)stopAllTimer
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
/// メニュー項目の有効・無効を制御
- (BOOL)validateMenuItem:(NSMenuItem *)menuItem
// ------------------------------------------------------
{
    NSInteger theState = NSOffState;
    NSString *title;

    if ([menuItem action] == @selector(toggleShowLineNum:)) {
        title = [self showLineNum] ? @"Hide Line Numbers" : @"Show Line Numbers";
        
    } else if ([menuItem action] == @selector(toggleShowStatusBar:)) {
        title = [self showStatusBar] ? @"Hide Status Bar" : @"Show Status Bar";
        
    } else if ([menuItem action] == @selector(toggleShowNavigationBar:)) {
        title = [self showNavigationBar] ? @"Hide Navigation Bar" : @"Show Navigation Bar";
        
    } else if ([menuItem action] == @selector(toggleWrapLines:)) {
        title = [self wrapLines] ? @"Unwrap Lines" : @"Wrap Lines";
        
    } else if ([menuItem action] == @selector(toggleUseAntialias:)) {
        if ([self shouldUseAntialias]) {theState = NSOnState;}
        
    } else if ([menuItem action] == @selector(toggleShowPageGuide:)) {
        title = [self showPageGuide] ? @"Hide Page Guide" : @"Show Page Guide";
        
    } else if ([menuItem action] == @selector(toggleShowInvisibleChars:)) {
        title = [(CELayoutManager *)[[self textView] layoutManager] showInvisibles] ? @"Hide Invisible Characters" : @"Show Invisible Characters";
        [menuItem setTitle:NSLocalizedString(title, nil)];
        return ([[self document] canActivateShowInvisibleCharsItem]);
    
    } else if ([menuItem action] == @selector(toggleAutoTabExpand:)) {
        theState = [[self textView] isAutoTabExpandEnabled] ? NSOnState : NSOffState;
        
    } else if (([menuItem action] == @selector(focusNextSplitTextView:)) || 
            ([menuItem action] == @selector(focusPrevSplitTextView:)) || 
            ([menuItem action] == @selector(closeSplitTextView:))) {
        return ([[[self splitView] subviews] count] > 1);
    }
    
    if (title) {
        [menuItem setTitle:NSLocalizedString(title, nil)];
    } else {
        [menuItem setState:theState];
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
/// ステータスバーの表示をトグルに切り替える
- (IBAction)toggleShowStatusBar:(id)sender
// ------------------------------------------------------
{
    [self setShowStatusBar:![self showStatusBar]];
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
    CELayoutManager *layoutManager = (CELayoutManager *)[[self textView] layoutManager];
    BOOL showInvisibles = [layoutManager showInvisibles];

    [[self splitView] setShowInvisibles:!showInvisibles];
    [[[self windowController] toolbarController] updateToggleItem:k_showInvisibleCharsItemID setOn:!showInvisibles];
}


// ------------------------------------------------------
/// ソフトタブの有効／無効をトグルに切り替える
- (IBAction)toggleAutoTabExpand:(id)sender
// ------------------------------------------------------
{
    BOOL isEnabled = ![[self textView] isAutoTabExpandEnabled];
    
    [[self splitView] setAutoTabExpandEnabled:isEnabled];
    [[[self windowController] toolbarController] updateToggleItem:k_autoTabExpandItemID setOn:isEnabled];
}


// ------------------------------------------------------
/// ページガイド表示をトグルに切り替える
- (IBAction)toggleShowPageGuide:(id)sender
// ------------------------------------------------------
{
    [self setShowPageGuide:![self showPageGuide]];
    [[self splitView] setNeedsDisplay:YES];
}


// ------------------------------------------------------
/// テキストビュー分割を行う
- (IBAction)openSplitTextView:(id)sender
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
//// 分割されたテキストビューを閉じる
- (IBAction)closeSplitTextView:(id)sender
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
/// 次の分割されたテキストビューへフォーカス移動
- (IBAction)focusNextSplitTextView:(id)sender
// ------------------------------------------------------
{
    [self focusOtherSplitTextViewOnNext:YES];
}


// ------------------------------------------------------
/// 前の分割されたテキストビューへフォーカス移動
- (IBAction)focusPrevSplitTextView:(id)sender
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
/// サブビューの初期化
- (void)setupViews
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
/// サブビューに初期値を設定
- (void)setupViewParamsInInit:(BOOL)isInitial
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
    } else {
        // 表示領域の前もある程度カラーリングの対象に含める
        NSUInteger buffer = MIN(charRange.location, k_coloringRangeBufferLength);
        coloringRange.location -= buffer;
        coloringRange.length += buffer;
    }
    
    [[self syntax]  colorVisibleRange:coloringRange withWholeString:[self string]];
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
/// タイマーの設定時刻に到達、情報更新
- (void)doUpdateInfoWithTimer:(NSTimer *)timer
// ------------------------------------------------------
{
    [self stopInfoUpdateTimer];
    [self updateDocumentInfoStringWithDrawerForceUpdate:NO];
}


// ------------------------------------------------------
/// タイマーの設定時刻に到達、非互換文字情報更新
- (void)doUpdateIncompatibleCharListWithTimer:(NSTimer *)timer
// ------------------------------------------------------
{
    [self stopIncompatibleCharTimer];
    [[self windowController] updateIncompatibleCharList];
}


// ------------------------------------------------------
/// 分割された前／後のテキストビューにフォーカス移動
- (void)focusOtherSplitTextViewOnNext:(BOOL)isOnNext
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
/// 文書情報更新タイマーを停止
- (void)stopInfoUpdateTimer
// ------------------------------------------------------
{
    if ([self infoUpdateTimer]) {
        [[self infoUpdateTimer] invalidate];
        [self setInfoUpdateTimer:nil];
    }
}


// ------------------------------------------------------
/// 非互換文字情報更新タイマーを停止
- (void)stopIncompatibleCharTimer
// ------------------------------------------------------
{
    if ([self incompatibleCharTimer]) {
        [[self incompatibleCharTimer] invalidate];
        [self setIncompatibleCharTimer:nil];
    }
}

@end
