/*
=================================================
CETextViewCore
(for CotEditor)

 Copyright (C) 2004-2007 nakamuxu.
 Copyright (C) 2014 CotEditor Project
 http://coteditor.github.io
=================================================

encoding="UTF-8"
Created:2005.03.30

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

#import "CETextViewCore.h"
#import "CEEditorView.h"
#import "CESyntaxManager.h"

//=======================================================
// Private method
//
//=======================================================

@interface CETextViewCore (Private)
- (void)redoReplaceString:(NSString *)inString withRange:(NSRange)inRange 
            withSelected:(NSRange)inSelection withActionName:(NSString *)inActionName;
- (void)doInsertString:(NSString *)inString withRange:(NSRange)inRange 
            withSelected:(NSRange)inSelection withActionName:(NSString *)inActionName scroll:(BOOL)inBoolToScroll;
- (NSString *)halfToFullwidthRomanStringFrom:(NSString *)inString;
- (NSString *)fullToHalfwidthRomanStringFrom:(NSString *)inString;
- (NSString *)hiraganaToKatakanaStringFrom:(NSString *)inString;
- (NSString *)katakanaToHiraganaStringFrom:(NSString *)inString;
- (BOOL)draggedItemsArray:(NSArray *)inArray containsExtensionInExtensions:(NSArray *)inExtensions;
- (void)updateLineNumberAndAdjustScroll;
- (void)replaceLineEndingToDocCharInPboard:(NSPasteboard *)inPboard;
@end


//------------------------------------------------------------------------------------------




@implementation CETextViewCore



#pragma mark ===== Public method =====

//=======================================================
// Public method
//
//=======================================================

// ------------------------------------------------------
- (instancetype)initWithFrame:(NSRect)inFrame textContainer:(NSTextContainer *)inTextContainer
// 初期化
// ------------------------------------------------------
{
    self = [super initWithFrame:inFrame textContainer:inTextContainer];
    if (self) {

    // このメソッドはSmultronのSMLTextViewを参考にしています。
    // This method is based on Smultron(SMLTextView) written by Peter Borg. Copyright (C) 2004 Peter Borg.
    // http://smultron.sourceforge.net
    // set the width of every tab by first checking the size of the tab in spaces in the current font and then remove all tabs that sets automatically and then set the default tab stop distance
        id theValues = [[NSUserDefaultsController sharedUserDefaultsController] values];
        NSMutableString *theWidthStr = [[NSMutableString alloc] init]; // ===== alloc
        NSUInteger theNumOfSpaces = [[theValues valueForKey:k_key_tabWidth] integerValue];
        while (theNumOfSpaces--) {
            [theWidthStr appendString:@" "];
        }
        NSString *theName = [theValues valueForKey:k_key_fontName];
        CGFloat theSize = (CGFloat)[[theValues valueForKey:k_key_fontSize] doubleValue];
        NSFont *theFont = [NSFont fontWithName:theName size:theSize];
        CGFloat sizeOfTab = [theWidthStr sizeWithAttributes:@{NSFontAttributeName:theFont}].width;

        // [追記] widthOfString:メソッドのdeprecatedに従い、Smultronでのコードに書き改めた (2014.02)
        // "widthOfString:" について (2005.02.06)
        // Apple の Xcode ヘルプの widthOfString: の項には、下記のように書かれている。
        // "This method is for backward compatibility only. In new code, use the Application Kit’s 
        // string-drawing methods, as described in NSString Additions."
        // しかし、sizeWithAttributes: を使用すると不具合が起こる。条件は、
        // 1. アプリケーションを起動して最初のドキュメントウィンドウ
        // 2. 指定フォントが Lucida Grande（システムフォント）
        // 3. 不可視文字の表示で「タブ」を表示するように設定されている
        // 4. タブをスペースに展開しないように設定されている
        // 5. タブ幅が「4」で設定されている
        // 上記がそろったときに、最初の新規ウィンドウでタブを入力していると5〜6でキャレットが移動できない状態になる。
        // また、これは設定されたタブ幅によってどこで移動できなくなるかが変化していく。PowerMac G5 2.0GHzx2 で確認した。
        // 調べてみると、最初のウィンドウで sizeWithAttributes: で返ってくる幅が、やや狭くなっている。
        // 通常ならば「15.187500」であるはずなのに、最初のウィンドウでだけは「15.187000」である。これが何らかの原因となって、
        // キャレットの移動を阻害しているのだと思われる。
        // ちなみに、参考にさせていただいた Smultron(SMLTextView) では以下の通り sizeWithAttributes: をつかっていて、
        // やはり問題が起きている。真の原因はどこにあるのか、よくわからない。
//      (Smultron でのコード)
//        NSDictionary *theSizeAttribute = 
//                [[NSDictionary alloc] initWithObjectsAndKeys:theFont, NSFontAttributeName, nil]; // ===== alloc
//        float sizeOfTab = [theWidthStr sizeWithAttributes:theSizeAttribute].width;
//        [theSizeAttribute release]; // ===== release

        [theWidthStr release]; // ===== release

        NSDictionary *theAttrs;
        NSColor *backgroundColor, *highlightLineColor;
        NSMutableParagraphStyle *theParagraphStyle;
        NSTextTab *theTextTabToBeRemoved;
        NSEnumerator *enumerator;

        theParagraphStyle = [[NSParagraphStyle defaultParagraphStyle] mutableCopy]; // ===== copy
        enumerator = [[theParagraphStyle tabStops] objectEnumerator];
        while (theTextTabToBeRemoved = [enumerator nextObject]) {
            [theParagraphStyle removeTabStop:theTextTabToBeRemoved];
        }

        [theParagraphStyle setDefaultTabInterval:sizeOfTab];

        theAttrs = @{NSParagraphStyleAttributeName: theParagraphStyle, 
                    NSFontAttributeName: theFont, 
                    NSForegroundColorAttributeName: [NSUnarchiver unarchiveObjectWithData:[theValues valueForKey:k_key_textColor]]};
        [theParagraphStyle release]; // ===== release
        [self setTypingAttrs:theAttrs];
        [self setEffectTypingAttrs];
        // （NSParagraphStyle の lineSpacing を設定すればテキスト描画時の行間は制御できるが、
        // 「文書の1文字目に1バイト文字（または2バイト文字）を入力してある状態で先頭に2バイト文字（または1バイト文字）を
        // 挿入すると行間がズレる」問題が生じるため、CELayoutManager および CEATSTypesetter で制御している）

        // set the values
        [self setFont:theFont];
        [self setMinSize:inFrame.size];
        [self setMaxSize:NSMakeSize(FLT_MAX, FLT_MAX)];
        [self setAllowsDocumentBackgroundColorChange:NO];
        [self setAllowsUndo:YES];
        [self setRichText:NO];
        [self setImportsGraphics:NO];
        [self setSmartInsertDeleteEnabled:[[theValues valueForKey:k_key_smartInsertAndDelete] boolValue]];
        [self setContinuousSpellCheckingEnabled:[[theValues valueForKey:k_key_checkSpellingAsType] boolValue]];
        [self setUsesFindPanel:YES];
        [self setHorizontallyResizable:YES];
        [self setVerticallyResizable:YES];
        [self setAcceptsGlyphInfo:YES];
        [self setLineSpacing:(CGFloat)[[theValues valueForKey:k_key_lineSpacing] doubleValue]];
        [self setTextColor:[NSUnarchiver unarchiveObjectWithData:[theValues valueForKey:k_key_textColor]]];
        backgroundColor = [NSUnarchiver unarchiveObjectWithData:[theValues valueForKey:k_key_backgroundColor]];
        highlightLineColor =  [NSUnarchiver unarchiveObjectWithData:[theValues valueForKey:k_key_highlightLineColor]];
        [self setBackgroundColor:
            [backgroundColor colorWithAlphaComponent:(CGFloat)[[theValues valueForKey:k_key_windowAlpha] doubleValue]]];
        [self setHighlightLineColor:
            [highlightLineColor colorWithAlphaComponent:(CGFloat)[[theValues valueForKey:k_key_windowAlpha] doubleValue]]];
        [self setInsertionPointColor:
                [NSUnarchiver unarchiveObjectWithData:[theValues valueForKey:k_key_insertionPointColor]]];
        [self setSelectedTextAttributes:
                @{NSBackgroundColorAttributeName: [NSUnarchiver unarchiveObjectWithData:[theValues valueForKey:k_key_selectionColor]]}];
        _insertionRect = NSZeroRect;
        _textContainerOriginPoint = NSMakePoint((CGFloat)[[theValues valueForKey:k_key_textContainerInsetWidth] doubleValue],
                                                (CGFloat)[[theValues valueForKey:k_key_textContainerInsetHeightTop] doubleValue]);
        [self setIsReCompletion:NO];
        [self setUpdateOutlineMenuItemSelection:YES];
        [self setIsSelfDrop:NO];
        [self setIsReadingFromPboard:NO];
        [self setHighlightLineAdditionalRect:NSZeroRect];
    }

    return self;
}


// ------------------------------------------------------
- (void)dealloc
// 後片付け
// ------------------------------------------------------
{
//    _slaveViewは保持されていない
    [_newLineString release];
    [_typingAttrs release];
    [_highlightLineColor release];

    [super dealloc];
}


// ------------------------------------------------------
- (BOOL)becomeFirstResponder
// first responder になれるかを返す
// ------------------------------------------------------
{
    [(CESubSplitView *)[self delegate] setTextViewToEditorView:self];

    return [super becomeFirstResponder];
}


// ------------------------------------------------------
- (void)keyDown:(NSEvent *)inEvent
// キー押下を取得
// ------------------------------------------------------
{
    NSString *theCharIgnoringMod = [inEvent charactersIgnoringModifiers];
    // IM で日本語入力変換中でないときのみ追加テキストキーバインディングを実行
    if ((![self hasMarkedText]) && (theCharIgnoringMod != nil)) {
        NSUInteger theModFlags = [inEvent modifierFlags];
        NSString *theSelectorStr = 
                [[CEKeyBindingManager sharedInstance] selectorStringWithKeyEquivalent:theCharIgnoringMod 
                        modifierFrags:theModFlags];
        NSInteger theLength = [theSelectorStr length];
        if ((theSelectorStr != nil) && (theLength > 0)) {
            if (([theSelectorStr hasPrefix:@"insertCustomText"]) && (theLength == 20)) {
                NSInteger theNum = [[theSelectorStr substringFromIndex:17] integerValue];
                [self insertCustomTextWithPatternNum:theNum];
            } else {
                [self doCommandBySelector:NSSelectorFromString(theSelectorStr)];
            }
            return;
        }
    }
    [super keyDown:inEvent];
}


// ------------------------------------------------------
- (void)insertText:(id)inString
// 文字列入力、'¥' と '\' を入れ替える。
// ------------------------------------------------------
{
    id theValues = [[NSUserDefaultsController sharedUserDefaultsController] values];

    if (([[theValues valueForKey:k_key_swapYenAndBackSlashKey] boolValue]) && ([inString length] == 1)) {
        NSEvent *theEvent = [NSApp currentEvent];
        NSUInteger theFlags = [NSEvent currentCarbonModifierFlags];

        if (([theEvent type] == NSKeyDown) && (theFlags == 0)) {
            if ([inString isEqualToString:@"\\"]) {
                [self inputYenMark:nil];
                return;
            } else if ([inString isEqualToString:[NSString stringWithCharacters:&k_yenMark length:1]]) {
                [self inputBackSlash:nil];
                return;
            }
        }
    }
    [super insertText:inString];
}


// ------------------------------------------------------
- (void)insertTab:(id)sender
// タブ入力、タブを展開。
// ------------------------------------------------------
{
    id theValues = [[NSUserDefaultsController sharedUserDefaultsController] values];

    if ([[theValues valueForKey:k_key_autoExpandTab] boolValue]) {
        NSInteger theTabWidth = [[theValues valueForKey:k_key_tabWidth] integerValue];
        NSRange theSelected = [self selectedRange];
        NSRange theLineRange = [[self string] lineRangeForRange:theSelected];
        NSInteger theLocation = theSelected.location - theLineRange.location;
        NSInteger theLength = theTabWidth - ((theLocation + theTabWidth) % theTabWidth);
        NSMutableString *theSpaces = [NSMutableString string];

        while (theLength--) {
            [theSpaces appendString:@" "];
        }
        [super insertText:theSpaces];
    } else {
        [super insertTab:sender];
    }
}


// ------------------------------------------------------
- (void)insertNewline:(id)sender
// 行末コード入力、オートインデント実行。
// ------------------------------------------------------
{
    id theValues = [[NSUserDefaultsController sharedUserDefaultsController] values];
    NSMutableString *theInput = [NSMutableString string];

    if ([[theValues valueForKey:k_key_autoIndent] boolValue]) {
        NSRange theSelected = [self selectedRange];
        NSRange theLineRange = [[self string] lineRangeForRange:theSelected];
        NSString *theLineStr = [[self string] substringWithRange:
                    NSMakeRange(theLineRange.location, 
                    theLineRange.length - (NSMaxRange(theLineRange) - NSMaxRange(theSelected)))];
        NSRange theIndentRange = [theLineStr rangeOfRegularExpressionString:@"^[[:blank:]\t]+"];

        // インデントを選択状態で改行入力した時は置換とみなしてオートインデントしない 2008.12.13
        if ((theIndentRange.location != NSNotFound) && 
                NSMaxRange(theSelected) < (theSelected.location + NSMaxRange(theIndentRange))) {
            [theInput setString:[theLineStr substringWithRange:theIndentRange]];
        }
    }
    [super insertNewline:sender];
    if ([theInput length] > 0) {
        [super insertText:theInput];
    }
}


// ------------------------------------------------------
- (void)deleteBackward:(id)sender
// デリート。タブを展開しているときのスペースを調整削除。
// ------------------------------------------------------
{
    NSRange theSelected = [self selectedRange];
    if (theSelected.length == 0) {
        id theValues = [[NSUserDefaultsController sharedUserDefaultsController] values];
        if ([[theValues valueForKey:k_key_autoExpandTab] boolValue]) {
            NSInteger theTabWidth = [[theValues valueForKey:k_key_tabWidth] integerValue];
            NSRange theLineRange = [[self string] lineRangeForRange:theSelected];
            NSInteger theLocation = theSelected.location - theLineRange.location;
            NSInteger theLength = (theLocation + theTabWidth) % theTabWidth;
            NSInteger theTargetWidth = (theLength == 0) ? theTabWidth : theLength;
            if ((NSInteger)theSelected.location >= theTargetWidth) {
                NSRange theTargetRange = NSMakeRange(theSelected.location - theTargetWidth, theTargetWidth);
                NSString *theTarget = [[self string] substringWithRange:theTargetRange];
                BOOL theValueToDelete = NO;
                NSUInteger i;
                for (i = 0; i < theTargetWidth; i++) {
                    theValueToDelete = [[theTarget substringWithRange:NSMakeRange(i, 1)] isEqualToString:@" "];
                    if (!theValueToDelete) {
                        break;
                    }
                }
                if (theValueToDelete) {
                    [self setSelectedRange:theTargetRange];
                }
            }
        }
    }
    [super deleteBackward:sender];
}


// ------------------------------------------------------
- (void)insertCompletion:(NSString *)inWord forPartialWordRange:(NSRange)inCharRange 
        movement:(NSInteger)inMovement isFinal:(BOOL)inFlag
// 補完リストの表示、選択候補の入力
// ------------------------------------------------------
{
    NSEvent *theEvent = [[self window] currentEvent];
    NSRange theRange;
    BOOL theBoolToReselect = NO;

    // complete リストを表示中に通常のキー入力があったら、直後にもう一度入力補完を行うためのフラグを立てる
    // （フラグは CEEditorView > textDidChange: で評価される）
    if (inFlag && ([theEvent type] == NSKeyDown)) {
        NSString *theInputChar = [theEvent charactersIgnoringModifiers];
        unichar theUnichar = [theInputChar characterAtIndex:0];

        if ([theInputChar isEqualToString:[theEvent characters]]) { //キーバインディングの入力などを除外
            // アンダースコアが右矢印キーと判断されることの是正
            if (([theInputChar isEqualToString:@"_"]) && (inMovement == NSRightTextMovement) && (inFlag)) {
                inMovement = NSIllegalTextMovement;
                inFlag = NO;
            }
            if ((inMovement == NSIllegalTextMovement) && 
                    (theUnichar < 0xF700) && (theUnichar != NSDeleteCharacter)) { // 通常のキー入力の判断
                [self setIsReCompletion:YES];
            } else {
                // 補完文字列に括弧が含まれていたら、括弧内だけを選択する準備をする
                theRange = [inWord rangeOfRegularExpressionString:@"\\(.*\\)"];
                theBoolToReselect = (theRange.location != NSNotFound);
            }
        }
    }
    [super insertCompletion:inWord forPartialWordRange:inCharRange movement:inMovement isFinal:inFlag];
    if (theBoolToReselect) {
        // 括弧内だけを選択
        [self setSelectedRange:NSMakeRange(inCharRange.location + theRange.location + 1, theRange.length - 2)];
    }
}


// ------------------------------------------------------
- (NSMenu *)menuForEvent:(NSEvent *)inEvent
// コンテキストメニューを返す
// ------------------------------------------------------
{
    id theValues = [[NSUserDefaultsController sharedUserDefaultsController] values];

    NSMenu *outMenu = [super menuForEvent:inEvent];
    NSMenuItem *theSelectAllMenuItem = [[[NSMenuItem alloc] initWithTitle:NSLocalizedString(@"Select All",@"") 
                action:@selector(selectAll:) keyEquivalent:@""] autorelease];
    NSMenuItem *theUtilityMenuItem = [[[NSMenuItem alloc] initWithTitle:NSLocalizedString(@"Utility",@"") 
                action:nil keyEquivalent:@""] autorelease];
    NSMenu *theUtilityMenu = [[[[[NSApp mainMenu] itemAtIndex:k_utilityMenuIndex] submenu] copy] autorelease];
    NSMenuItem *theASMenuItem = 
                [[[NSMenuItem alloc] initWithTitle:@"" action:nil keyEquivalent:@""] autorelease];
    NSMenu *theASSubMenu = [[CEScriptManager sharedInstance] contexualMenu];

    // 「フォント」メニューおよびサブメニューを削除
    [outMenu removeItem:[outMenu itemWithTitle:NSLocalizedString(@"Font",@"")]];

    // 連続してコンテキストメニューを表示させるとどんどんメニューアイテムが追加されてしまうので、
    // 既に追加されているかどうかをチェックしている
    if (theSelectAllMenuItem && 
            ([outMenu indexOfItemWithTarget:nil andAction:@selector(selectAll:)] == k_noMenuItem)) {
        NSInteger thePasteIndex = [outMenu indexOfItemWithTarget:nil andAction:@selector(paste:)];
        if (thePasteIndex != k_noMenuItem) {
            [outMenu insertItem:theSelectAllMenuItem atIndex:(thePasteIndex + 1)];
        }
    }
    if (((theUtilityMenu) || (theASSubMenu)) && 
            ([outMenu indexOfItemWithTag:k_utilityMenuTag] == k_noMenuItem) && 
            ([outMenu indexOfItemWithTag:k_scriptMenuTag] == k_noMenuItem)) {
        [outMenu addItem:[NSMenuItem separatorItem]];
    }
    if ((theUtilityMenu) && ([outMenu indexOfItemWithTag:k_utilityMenuTag] == k_noMenuItem)) {
        [theUtilityMenuItem setTag:k_utilityMenuTag];
        [theUtilityMenuItem setSubmenu:theUtilityMenu];
        [outMenu addItem:theUtilityMenuItem];
    }
    if (theASSubMenu) {
        NSMenuItem *theDelItem = nil;
        while ((theDelItem = [outMenu itemWithTag:k_scriptMenuTag])) {
            [outMenu removeItem:theDelItem];
        }
        if ([[theValues valueForKey:k_key_inlineContextualScriptMenu] boolValue]) {
            NSUInteger i, theCount = [theASSubMenu numberOfItems];
            NSMenuItem *theAddItem = nil;

            for (i = 0; i < 2; i++) { // セパレータをふたつ追加
                [outMenu addItem:[NSMenuItem separatorItem]];
                [[outMenu itemAtIndex:([outMenu numberOfItems] - 1)] setTag:k_scriptMenuTag];
            }
            for (i = 0; i < theCount; i++) {
                theAddItem = [(NSMenuItem *)[theASSubMenu itemAtIndex:i] copy]; // ===== copy
                [theAddItem setTag:k_scriptMenuTag];
                [outMenu addItem:theAddItem];
                [theAddItem release]; // ===== release
            }
        } else{
            [theASMenuItem setImage:[NSImage imageNamed:@"scriptMenuIcon"]];
            [theASMenuItem setTag:k_scriptMenuTag];
            [theASMenuItem setSubmenu:theASSubMenu];
            [outMenu addItem:theASMenuItem];
        }
    }
    return outMenu;
}


// ------------------------------------------------------
- (void)copy:(id)sender
// コピー実行。行末コードを書類に設定されたものに置換する。
// ------------------------------------------------------
{
    // （このメソッドは cut: からも呼び出される）
    [super copy:sender];
    [self replaceLineEndingToDocCharInPboard:[NSPasteboard generalPasteboard]];
}


// ------------------------------------------------------
- (void)changeFont:(id)sender
// フォント変更
// ------------------------------------------------------
{
    // (引数"sender"はNSFontManegerのインスタンス)
    NSFont *theNewFont = [sender convertFont:[self font]];

    [self setFont:theNewFont];
    [self setNeedsDisplay:YES]; // 本来なくても再描画されるが、最下行以下のページガイドの描画が残るための措置(2009.02.14)
    [[self slaveView] setNeedsDisplay:YES];
    [self updateLineNumberAndAdjustScroll];
}


// ------------------------------------------------------
- (void)setFont:(NSFont *)inFont
// フォントを設定
// ------------------------------------------------------
{
    NSMutableDictionary *theAttrs = [[[self typingAttrs] mutableCopy] autorelease];

// 複合フォントで行間が等間隔でなくなる問題を回避するため、CELayoutManager にもフォントを持たせておく。
// （CELayoutManager で [[self firstTextView] font] を使うと、「1バイトフォントを指定して日本語が入力されている」場合に
// 日本語フォント名を返してくることがあるため、CELayoutManager からは [textView font] を使わない）
    [(CELayoutManager *)[self layoutManager] setTextFont:inFont];
    [super setFont:inFont];
    theAttrs[NSFontAttributeName] = inFont;
    [self setTypingAttrs:theAttrs];
    [self setEffectTypingAttrs];
}


// ------------------------------------------------------
- (NSRange)rangeForUserCompletion
// 補完時の範囲を返す
// ------------------------------------------------------
{
    NSString *theString = [self string];
    NSRange theRange = [super rangeForUserCompletion];
    NSCharacterSet *theCharSet = [(CESubSplitView *)[self delegate] completionsFirstLetterSet];
    NSInteger i, theBegin = theRange.location;

    if (theCharSet == nil) { return theRange; }

    // 入力補完文字列の先頭となりえない文字が出てくるまで補完文字列対象を広げる
    for (i = theRange.location; i >= 0; i--) {
        unichar theChar = [[theString substringWithRange:NSMakeRange(i, 1)] characterAtIndex:0];
        if ([theCharSet characterIsMember:theChar]) {
            theBegin = i;
        } else {
            break;
        }
    }
    return NSMakeRange(theBegin, NSMaxRange(theRange) - theBegin);
}


// ------------------------------------------------------
- (NSPoint)textContainerOrigin
// テキストコンテナの原点（左上）座標を返す
// ------------------------------------------------------
{
    return _textContainerOriginPoint;
}


// ------------------------------------------------------
- (void)drawRect:(NSRect)inRect
// ビュー内を描画
// ------------------------------------------------------
{

    id theValues = [[NSUserDefaultsController sharedUserDefaultsController] values];

    [super drawRect:inRect];

    [self drawHighlightLineAdditionalRect];

    // ページガイド描画
    if ([(CESubSplitView *)[self delegate] showPageGuide]) {
        CGFloat theColumn = (CGFloat)[[theValues valueForKey:k_key_pageGuideColumn] doubleValue];
        NSImage *theLineImg = [NSImage imageNamed:@"pageGuide"];
        if ((theColumn < k_pageGuideColumnMin) || (theColumn > k_pageGuideColumnMax) || (theLineImg == nil)) {
            return;
        }
        CGFloat theLinePadding = [[self textContainer] lineFragmentPadding];
        CGFloat theInsetWidth = (CGFloat)[[theValues valueForKey:k_key_textContainerInsetWidth] doubleValue];
        NSString *theTmpStr = @"M";
        theColumn *= [theTmpStr sizeWithAttributes:@{NSFontAttributeName:[self font]}].width;

        // （2ピクセル右に描画してるのは、調整）
        [theLineImg drawInRect:
                NSMakeRect(theColumn + theInsetWidth + theLinePadding + 2.0, 0, 1, [self frame].size.height) 
                fromRect:NSMakeRect(0, 0, 2, 1) operation:NSCompositeSourceOver fraction:0.5];
    }
    // テキストビューを透過させている時に影を更新描画する
    if ([[self backgroundColor] alphaComponent] < 1.0) {
        [[self window] invalidateShadow];
    }
}


// ------------------------------------------------------
- (NSColor *)highlightLineColor
// カレント行ハイライト色を返す
// ------------------------------------------------------
{
    return _highlightLineColor;
}


// ------------------------------------------------------
- (void)setHighlightLineColor:(NSColor *)inColor
// カレント行ハイライト色をセット
// ------------------------------------------------------
{
    [inColor retain];
    [_highlightLineColor release];
    _highlightLineColor = inColor;
}


// ------------------------------------------------------
- (void)drawHighlightLineAdditionalRect
// ハイライト行追加表示
// ------------------------------------------------------
{
    if (NSWidth([self highlightLineAdditionalRect]) == 0) { return; }

    [[[self highlightLineColor] colorWithAlphaComponent:[[self backgroundColor] alphaComponent]] set];
    [NSBezierPath fillRect:_highlightLineAdditionalRect];
}


// ------------------------------------------------------
- (NSRect)highlightLineAdditionalRect
// ハイライト行で追加表示する矩形を返す
// ------------------------------------------------------
{
    return _highlightLineAdditionalRect;
}


// ------------------------------------------------------
- (void)setHighlightLineAdditionalRect:(NSRect)inRect
// ハイライト行で追加表示する矩形をセット
// ------------------------------------------------------
{
    _highlightLineAdditionalRect = inRect;
}


// ------------------------------------------------------
- (void)scrollRangeToVisible:(NSRange)inRange
// 特定の範囲が見えるようにスクロール
// ------------------------------------------------------
{
    id theValues = [[NSUserDefaultsController sharedUserDefaultsController] values];

    [super scrollRangeToVisible:inRange];

    // 完全にスクロールさせる
    // （setTextContainerInset で上下に空白領域を挿入している関係で、ちゃんとスクロールしない場合があることへの対策）
    NSUInteger theLength = [[self string] length];
    NSRect theRect = NSZeroRect, theConvertedRect;

    if (theLength == inRange.location) {
        theRect = [[self layoutManager] extraLineFragmentRect];
    } else if (theLength > inRange.location) {
        NSString *theTailStr = [[self string] substringFromIndex:inRange.location];
        if ([theTailStr newlineCharacter] != OgreNonbreakingNewlineCharacter) {
            return;
        }
    }

    if (NSEqualRects(theRect, NSZeroRect)) {
        NSRange theTargetRange = [[self string] lineRangeForRange:inRange];
        NSRange theGlyphRange = 
                [[self layoutManager] glyphRangeForCharacterRange:theTargetRange actualCharacterRange:nil];
        theRect = [[self layoutManager] lineFragmentRectForGlyphAtIndex:(NSMaxRange(theGlyphRange) - 1) 
                    effectiveRange:nil];
    }
    if (NSEqualRects(theRect, NSZeroRect)) { return; }

    theConvertedRect = [self convertRect:theRect toView:[[self enclosingScrollView] superview]]; //subsplitview
    if ((theConvertedRect.origin.y >= 0) &&
        (theConvertedRect.origin.y < (CGFloat)[[theValues valueForKey:k_key_textContainerInsetHeightBottom] doubleValue])
        ) {
        [self scrollPoint:NSMakePoint(NSMinX(theRect), NSMaxY(theRect))];
    }
}


// ------------------------------------------------------
- (NSString *)newLineString
// 行末文字を返す
// ------------------------------------------------------
{
    return _newLineString;
}


// ------------------------------------------------------
- (void)setNewLineString:(NSString *)inString
// 行末文字をセット
// ------------------------------------------------------
{
    [inString retain];
    [_newLineString release];
    _newLineString = inString;
}


// ------------------------------------------------------
- (NSView *)slaveView
// LineNumViewを返す
// ------------------------------------------------------
{
    return _slaveView;
}


// ------------------------------------------------------
- (void)setSlaveView:(NSView *)inView
// LineNumViewをセット
// ------------------------------------------------------
{
    _slaveView = inView;
}


// ------------------------------------------------------
- (NSDictionary *)typingAttrs
// キー入力時の文字修飾辞書を返す。
// ------------------------------------------------------
{
    return _typingAttrs;
}


// ------------------------------------------------------
- (void)setTypingAttrs:(NSDictionary *)inAttrs
// キー入力時の文字修飾辞書を保持
// ------------------------------------------------------
{
    [inAttrs retain];
    [_typingAttrs release];
    _typingAttrs = inAttrs;
}


// ------------------------------------------------------
- (void)setEffectTypingAttrs
// キー入力時の文字修飾辞書をセット
// ------------------------------------------------------
{
    [self setTypingAttributes:[self typingAttrs]];
}


// ------------------------------------------------------
- (void)setBackgroundColorWithAlpha:(CGFloat)inAlpha
// 背景色をセット
// ------------------------------------------------------
{
    id theValues = [[NSUserDefaultsController sharedUserDefaultsController] values];
    NSColor *theBackgroundColor = 
            [NSUnarchiver unarchiveObjectWithData:[theValues valueForKey:k_key_backgroundColor]];

    [self setBackgroundColor:[theBackgroundColor colorWithAlphaComponent:inAlpha]];
}


// ------------------------------------------------------
- (void)replaceSelectedStringTo:(NSString *)inString scroll:(BOOL)inBoolScroll
// 選択文字列を置換
// ------------------------------------------------------
{
    if (inString == nil) { return; }
    NSRange theSelected = [self selectedRange];
    NSString *theActionName = (theSelected.length > 0) ?
            NSLocalizedString(@"Replace text",@"") : 
            NSLocalizedString(@"Insert text",@"");
    NSRange theNewRange = NSMakeRange(theSelected.location, [inString length]);

    [self doInsertString:inString withRange:theSelected 
            withSelected:theNewRange withActionName:theActionName scroll:inBoolScroll];
}


// ------------------------------------------------------
- (void)replaceAllStringTo:(NSString *)inString
// 全文字列を置換
// ------------------------------------------------------
{
    NSRange theNewRange = NSMakeRange(0, [inString length]);

    if (inString != nil) {
        [self doReplaceString:inString withRange:NSMakeRange(0, [[self string] length]) 
                withSelected:theNewRange withActionName:NSLocalizedString(@"Replace text",@"")];
    }
}


// ------------------------------------------------------
- (void)insertAfterSelection:(NSString *)inString
// 選択文字列の後ろへ新規文字列を挿入
// ------------------------------------------------------
{
    if (inString == nil) { return; }
    NSRange theSelected = [self selectedRange];
    NSRange theNewRange = NSMakeRange(NSMaxRange(theSelected), [inString length]);

    [self doInsertString:inString withRange:NSMakeRange(NSMaxRange(theSelected), 0) 
            withSelected:theNewRange withActionName:NSLocalizedString(@"Insert text",@"") scroll:NO];
}


// ------------------------------------------------------
- (void)appendAllString:(NSString *)inString
// 末尾に新規文字列を追加
// ------------------------------------------------------
{
    if (inString == nil) { return; }
    NSRange theNewRange = NSMakeRange([[self string] length], [inString length]);

    [self doInsertString:inString withRange:NSMakeRange([[self string] length], 0) 
            withSelected:theNewRange withActionName:NSLocalizedString(@"Insert text",@"") scroll:NO];
}


// ------------------------------------------------------
- (void)insertCustomTextWithPatternNum:(NSInteger)inPatternNum
// カスタムキーバインドで文字列入力
// ------------------------------------------------------
{
    if (inPatternNum < 0) { return; }
    id theValues = [[NSUserDefaultsController sharedUserDefaultsController] values];
    NSArray *theArray = [theValues valueForKey:k_key_insertCustomTextArray];

    if (inPatternNum < (NSInteger)[theArray count]) {
        NSString *theString = theArray[inPatternNum];
        NSRange theSelected = [self selectedRange];
        NSRange theNewRange = NSMakeRange(theSelected.location + [theString length], 0);

        [self doInsertString:theString withRange:theSelected 
                withSelected:theNewRange withActionName:NSLocalizedString(@"Insert custom text",@"") scroll:YES];
    }
}


// ------------------------------------------------------
- (void)resetFont:(id)sender
// フォントをリセット
// ------------------------------------------------------
{
    id theValues = [[NSUserDefaultsController sharedUserDefaultsController] values];
    NSString *theName = [theValues valueForKey:k_key_fontName];
    CGFloat theSize = (CGFloat)[[theValues valueForKey:k_key_fontSize] doubleValue];
    NSFont *theFont = [NSFont fontWithName:theName size:theSize];

    [self setFont:theFont];
    [[self slaveView] setNeedsDisplay:YES];
    [self updateLineNumberAndAdjustScroll];
}


// ------------------------------------------------------
- (NSArray *)readablePasteboardTypes
// 読み取り可能なPasteboardタイプを返す
// ------------------------------------------------------
{
    NSMutableArray *outArray = [NSMutableArray arrayWithArray:[super readablePasteboardTypes]];

    [outArray addObject:NSFilenamesPboardType];
    return outArray;
}


// ------------------------------------------------------
- (NSArray *)pasteboardTypesForString
// 行末コード置換のためのPasteboardタイプ配列を返す
// ------------------------------------------------------
{
    NSArray *outArray = @[NSStringPboardType, 
                            @"public.utf8-plain-text"];
    return outArray;
}


// ------------------------------------------------------
- (void)dragImage:(NSImage *)inImage at:(NSPoint)inImageLoc offset:(NSSize)inMouseOffset 
        event:(NSEvent *)inEvent pasteboard:(NSPasteboard *)inPboard 
        source:(id)inSourceObject slideBack:(BOOL)inSlideBack
// ドラッグする文字列の行末コードを書類に設定されたものに置換する
// ------------------------------------------------------
{
    [self replaceLineEndingToDocCharInPboard:inPboard];
    [super dragImage:inImage at:inImageLoc offset:inMouseOffset 
            event:inEvent pasteboard:inPboard source:inSourceObject slideBack:inSlideBack];
}


// ------------------------------------------------------
- (NSUInteger)dragOperationForDraggingInfo:(id <NSDraggingInfo>)inDragInfo type:(NSString *)inType
// 領域内でオブジェクトがドラッグされている
// ------------------------------------------------------
{
    if ([inType isEqualToString:NSFilenamesPboardType]) {
        id theValues = [[NSUserDefaultsController sharedUserDefaultsController] values];
        NSArray *theFileDropArray = [theValues valueForKey:k_key_fileDropArray];
        NSColor *theInsertionPointColor = 
                [NSUnarchiver unarchiveObjectWithData:[theValues valueForKey:k_key_insertionPointColor]];
        for (id item in theFileDropArray) {
            NSArray *theArray = [[inDragInfo draggingPasteboard] propertyListForType:NSFilenamesPboardType];
            NSArray *theExtensions = 
                        [[item
                            valueForKey:k_key_fileDropExtensions] componentsSeparatedByString:@", "];
            if ([self draggedItemsArray:theArray containsExtensionInExtensions:theExtensions]) {
                NSString *theString = [self string];
                NSUInteger theLength = [theString length];
                if (theLength > 0) {
                    // 挿入ポイントを自前で描画する
                    CGFloat thePartialFraction;
                    NSLayoutManager *theLayoutManager = [self layoutManager];
                    NSUInteger theGlyphIndex = [theLayoutManager
                            glyphIndexForPoint:[self convertPoint:[inDragInfo draggingLocation] fromView: nil]
                            inTextContainer:[self textContainer] 
                            fractionOfDistanceThroughGlyph:&thePartialFraction];
                    NSPoint theGlypthIndexPoint;
                    NSRect theLineRect, theInsertionRect;
                    if ((thePartialFraction > 0.5) && 
                            (![[theString substringWithRange:
                                NSMakeRange(theGlyphIndex,1)] isEqualToString:@"\n"])) {
                            NSRect theGlyphRect = [theLayoutManager 
                                    boundingRectForGlyphRange:NSMakeRange(theGlyphIndex,1) 
                                    inTextContainer:[self textContainer]];
                            theGlypthIndexPoint = [theLayoutManager locationForGlyphAtIndex:theGlyphIndex];
                            theGlypthIndexPoint.x += NSWidth(theGlyphRect);
                    } else {
                        theGlypthIndexPoint = [theLayoutManager locationForGlyphAtIndex:theGlyphIndex];
                    }
                    theLineRect = [theLayoutManager 
                                lineFragmentRectForGlyphAtIndex:theGlyphIndex effectiveRange:NULL];
                    theInsertionRect = NSMakeRect(theGlypthIndexPoint.x, theLineRect.origin.y, 
                                    1, NSHeight(theLineRect));
                    if (!NSEqualRects(_insertionRect, theInsertionRect)) {
                        // 古い自前挿入ポイントが描かれたままになることへの対応
                        [self setNeedsDisplayInRect:_insertionRect avoidAdditionalLayout:NO];
                    }
                    [theInsertionPointColor set];
                    [self lockFocus];
                    NSFrameRectWithWidth(theInsertionRect, 1.0);
                    [self unlockFocus];
                    _insertionRect = theInsertionRect;
                }
                return NSDragOperationCopy;
            }
        }
        return NSDragOperationNone;
    }
    return [super dragOperationForDraggingInfo:inDragInfo type:inType];
}


// ------------------------------------------------------
- (BOOL)performDragOperation:(id < NSDraggingInfo >)sender
// ドロップ実行（同じ書類からドロップされた文字列の行末コードをLFへ置換するためにオーバーライド）
// ------------------------------------------------------
{
    // ドロップによる編集で行末コードをLFに統一する
    // （その他の編集は、下記の通りの別の場所で置換している）
    // # テキスト編集時の行末コードの置換場所
    //  * ファイルオープン = CEEditorView > setString:
    //  * キー入力 = CESubSplitView > textView:shouldChangeTextInRange:replacementString:
    //  * ペースト = CETextViewCore > readSelectionFromPasteboard:type:
    //  * ドロップ（同一書類内） = CETextViewCore > performDragOperation:
    //  * ドロップ（別書類または別アプリから） = CETextViewCore > readSelectionFromPasteboard:type:
    //  * スクリプト = CESubSplitView > textView:shouldChangeTextInRange:replacementString:
    //  * 検索パネルでの置換 = (OgreKit) OgreTextViewPlainAdapter > replaceCharactersInRange:withOGString:

    // まず、自己内ドラッグかどうかのフラグを立てる
    [self setIsSelfDrop:([sender draggingSource] == self)];

    if ([self isSelfDrop]) {
        // （自己内ドラッグの場合には、行末コード置換を readSelectionFromPasteboard:type: 内で実行すると
        // アンドゥの登録で文字列範囲の計算が面倒なので、ここでPasteboardを書き換えてしまう）
        NSPasteboard *thePboard = [sender draggingPasteboard];
        NSString *thePboardType = [thePboard availableTypeFromArray:[self pasteboardTypesForString]];
        if (thePboardType != nil) {
            NSString *theStr = [thePboard stringForType:thePboardType];
            if (theStr != nil) {
                OgreNewlineCharacter theNewlineChar = [OGRegularExpression newlineCharacterInString:theStr];
                if ((theNewlineChar != OgreNonbreakingNewlineCharacter) && 
                                (theNewlineChar != OgreLfNewlineCharacter)) {
                    [thePboard setString:[OGRegularExpression replaceNewlineCharactersInString:theStr 
                                        withCharacter:OgreLfNewlineCharacter] forType:thePboardType];
                }
            }
        }
    }

    BOOL outBoolResult = [super performDragOperation:sender];
    [self setIsSelfDrop:NO];

    return outBoolResult;
}


// ------------------------------------------------------
- (BOOL)readSelectionFromPasteboard:(NSPasteboard *)inPboard type:(NSString *)inType
// ペーストまたはドロップされたアイテムに応じて挿入する文字列をNSPasteboardから読み込む
// ------------------------------------------------------
{
    // （このメソッドは、performDragOperation: 内で呼ばれる）

    BOOL outBoolResult = NO;
    NSRange theSelected, theNewRange;

    // 実行中フラグを立てる
    [self setIsReadingFromPboard:YES];

    // ペーストされたか、他からテキストがドロップされた
    if ((![self isSelfDrop]) && ([inType isEqualToString:NSStringPboardType])) {
        // ペースト、他からのドロップによる編集で行末コードをLFに統一する
        // （その他の編集は、下記の通りの別の場所で置換している）
        // # テキスト編集時の行末コードの置換場所
        //  * ファイルオープン = CEEditorView > setString:
        //  * キー入力 = CESubSplitView > textView:shouldChangeTextInRange:replacementString:
        //  * ペースト = CETextViewCore > readSelectionFromPasteboard:type:
        //  * ドロップ（同一書類内） = CETextViewCore > performDragOperation:
        //  * ドロップ（別書類または別アプリから） = CETextViewCore > readSelectionFromPasteboard:type:
        //  * スクリプト = CESubSplitView > textView:shouldChangeTextInRange:replacementString:
        //  * 検索パネルでの置換 = (OgreKit) OgreTextViewPlainAdapter > replaceCharactersInRange:withOGString:

        NSString *thePboardStr = [inPboard stringForType:NSStringPboardType];
        if (thePboardStr != nil) {
            OgreNewlineCharacter theNewlineChar = [OGRegularExpression newlineCharacterInString:thePboardStr];
            if ((theNewlineChar != OgreNonbreakingNewlineCharacter) && 
                            (theNewlineChar != OgreLfNewlineCharacter)) {
                NSString *theReplacedStr = [OGRegularExpression replaceNewlineCharactersInString:thePboardStr 
                                    withCharacter:OgreLfNewlineCharacter];
                theSelected = [self selectedRange];
                theNewRange = NSMakeRange(theSelected.location + [theReplacedStr length], 0);
                // （Action名は自動で付けられる？ので、指定しない）
                [self doReplaceString:theReplacedStr withRange:theSelected 
                        withSelected:theNewRange withActionName:@""];
                outBoolResult = YES;
            }
        }

    // ファイルがドロップされた
    } else if ([inType isEqualToString:NSFilenamesPboardType]) {

        id theValues = [[NSUserDefaultsController sharedUserDefaultsController] values];
        NSArray *theFileDropArray = [theValues valueForKey:k_key_fileDropArray];
        NSArray *theFiles = [inPboard propertyListForType:NSFilenamesPboardType];
        NSString *theDocPath = [[[[self window] windowController] document] fileName];
        NSString *theFileName, *theFileNoSuffix, *theDirName;
        NSString *thePathExtension = nil, *thePathExtensionLower = nil, *thePathExtensionUpper = nil;
        NSMutableString *theRelativePath = [NSMutableString string];
        NSMutableString *theNewStr = [NSMutableString string];
        NSInteger i, theXtsnCount;
        NSInteger theFileArrayCount = (NSInteger)[theFileDropArray count];

        for (NSString *theAbsolutePath in theFiles) {
            theSelected = [self selectedRange];
            for (theXtsnCount = 0; theXtsnCount < theFileArrayCount; theXtsnCount++) {
                NSArray *theExtensions = 
                            [[theFileDropArray[theXtsnCount] 
                                valueForKey:k_key_fileDropExtensions] componentsSeparatedByString:@", "];
                thePathExtension = [theAbsolutePath pathExtension];
                thePathExtensionLower = [thePathExtension lowercaseString];
                thePathExtensionUpper = [thePathExtension uppercaseString];

                if (([theExtensions containsObject:thePathExtensionLower]) 
                        || ([theExtensions containsObject:thePathExtensionUpper])) {

                    [theNewStr setString:[theFileDropArray[theXtsnCount] 
                                valueForKey:k_key_fileDropFormatString]];
                } else {
                    continue;
                }
            }
            if ([theNewStr length] > 0) {
                if ((theDocPath != nil) && (![theDocPath isEqualToString:theAbsolutePath])) {
                    NSArray *theDocPathArray = [theDocPath pathComponents];
                    NSArray *thePathArray = [theAbsolutePath pathComponents];
                    NSMutableString *theTmpStr = [NSMutableString string];
                    NSInteger j, theSame = 0, theCount = 0;
                    NSInteger theDocArrayCount = (NSInteger)[theDocPathArray count];
                    NSInteger thePathArrayCount = (NSInteger)[thePathArray count];

                    for (j = 0; j < theDocArrayCount; j++) {
                        if (![theDocPathArray[j] isEqualToString:
                                    thePathArray[j]]) {
                            theSame = j;
                            theCount = [theDocPathArray count] - theSame - 1;
                            break;
                        }
                    }
                    for (j = theCount; j > 0; j--) {
                        [theTmpStr appendString:@"../"];
                    }
                    for (j = theSame; j < thePathArrayCount; j++) {
                        if ([theTmpStr length] > 0) {
                            [theTmpStr appendString:@"/"];
                        }
                        [theTmpStr appendString:thePathArray[j]];
                    }
                    [theRelativePath setString:[theTmpStr stringByStandardizingPath]];
                } else {
                    [theRelativePath setString:theAbsolutePath];
                }
                theFileName = [theAbsolutePath lastPathComponent];
                theFileNoSuffix = [theFileName stringByDeletingPathExtension];
                theDirName = [[theAbsolutePath stringByDeletingLastPathComponent] lastPathComponent];
                (void)[theNewStr replaceOccurrencesOfString:@"<<<ABSOLUTE-PATH>>>" 
                            withString:theAbsolutePath options:0 range:NSMakeRange(0, [theNewStr length])];
                (void)[theNewStr replaceOccurrencesOfString:@"<<<RELATIVE-PATH>>>" 
                            withString:theRelativePath options:0 range:NSMakeRange(0, [theNewStr length])];
                (void)[theNewStr replaceOccurrencesOfString:@"<<<FILENAME>>>" 
                            withString:theFileName options:0 range:NSMakeRange(0, [theNewStr length])];
                (void)[theNewStr replaceOccurrencesOfString:@"<<<FILENAME-NOSUFFIX>>>" 
                            withString:theFileNoSuffix options:0 range:NSMakeRange(0, [theNewStr length])];
                (void)[theNewStr replaceOccurrencesOfString:@"<<<FILEEXTENSION>>>" 
                            withString:thePathExtension options:0 range:NSMakeRange(0, [theNewStr length])];
                (void)[theNewStr replaceOccurrencesOfString:@"<<<FILEEXTENSION-LOWER>>>" 
                            withString:thePathExtensionLower options:0 range:NSMakeRange(0, [theNewStr length])];
                (void)[theNewStr replaceOccurrencesOfString:@"<<<FILEEXTENSION-UPPER>>>" 
                            withString:thePathExtensionUpper options:0 range:NSMakeRange(0, [theNewStr length])];
                (void)[theNewStr replaceOccurrencesOfString:@"<<<DIRECTORY>>>" 
                            withString:theDirName options:0 range:NSMakeRange(0, [theNewStr length])];
                NSImageRep *theImageRep = [NSImageRep imageRepWithContentsOfFile:theAbsolutePath];
                if (theImageRep != nil) {
                    // NSImage の size では dpi をも考慮されたサイズが返ってきてしまうので NSImageRep を使う
                    (void)[theNewStr replaceOccurrencesOfString:@"<<<IMAGEWIDTH>>>" 
                                withString:[NSString stringWithFormat:@"%li", (long)[theImageRep pixelsWide]] 
                                options:0 range:NSMakeRange(0, [theNewStr length])];
                    (void)[theNewStr replaceOccurrencesOfString:@"<<<IMAGEHEIGHT>>>" 
                                withString:[NSString stringWithFormat:@"%li", (long)[theImageRep pixelsHigh]] 
                                options:0 range:NSMakeRange(0, [theNewStr length])];
                }
                // （ファイルをドロップしたときは、挿入文字列全体を選択状態にする）
                theNewRange = NSMakeRange(theSelected.location, [theNewStr length]);
                // （Action名は自動で付けられる？ので、指定しない）
                [self doReplaceString:theNewStr withRange:theSelected 
                        withSelected:theNewRange withActionName:@""];
                // 挿入後、選択範囲を移動させておかないと複数オブジェクトをドロップされた時に重ね書きしてしまう
                [self setSelectedRange:NSMakeRange(NSMaxRange(theNewRange), 0)];
                outBoolResult = YES;
            }
        }
    }
    if (outBoolResult == NO) {
        outBoolResult = [super readSelectionFromPasteboard:inPboard type:inType];
    }
    [self setIsReadingFromPboard:NO];

    return outBoolResult;
}


// ------------------------------------------------------
- (NSRange)selectionRangeForProposedRange:(NSRange)inProposedSelRange
            granularity:(NSSelectionGranularity)inGranularity
// マウスでのテキスト選択時の挙動を制御、ダブルクリックでの括弧内選択機能を追加
// ------------------------------------------------------
{
// このメソッドは、Smultron のものを使用させていただきました。(2006.09.09)
// This method is based on Smultron.(written by Peter Borg – http://smultron.sourceforge.net)
// Smultron  Copyright (c) 2004-2005 Peter Borg, All rights reserved.
// Smultron is released under GNU General Public License, http://www.gnu.org/copyleft/gpl.html

	if (inGranularity != NSSelectByWord || [[self string] length] == inProposedSelRange.location) {// If it's not a double-click return unchanged
		return [super selectionRangeForProposedRange:inProposedSelRange granularity:inGranularity];
	}
	
	NSInteger location = [super selectionRangeForProposedRange:inProposedSelRange granularity:NSSelectByCharacter].location;
	NSInteger originalLocation = location;

	NSString *completeString = [self string];
	unichar characterToCheck = [completeString characterAtIndex:location];
	NSUInteger skipMatchingBrace = 0;
	NSInteger lengthOfString = [completeString length];
	if (lengthOfString == (NSInteger)inProposedSelRange.location) { // To avoid crash if a double-click occurs after any text
		return [super selectionRangeForProposedRange:inProposedSelRange granularity:inGranularity];
	}
	
	BOOL triedToMatchBrace = NO;
	
	if (characterToCheck == ')') {
		triedToMatchBrace = YES;
		while (location--) {
			characterToCheck = [completeString characterAtIndex:location];
			if (characterToCheck == '(') {
				if (!skipMatchingBrace) {
					return NSMakeRange(location, originalLocation - location + 1);
				} else {
					skipMatchingBrace--;
				}
			} else if (characterToCheck == ')') {
				skipMatchingBrace++;
			}
		}
		NSBeep();
	} else if (characterToCheck == '}') {
		triedToMatchBrace = YES;
		while (location--) {
			characterToCheck = [completeString characterAtIndex:location];
			if (characterToCheck == '{') {
				if (!skipMatchingBrace) {
					return NSMakeRange(location, originalLocation - location + 1);
				} else {
					skipMatchingBrace--;
				}
			} else if (characterToCheck == '}') {
				skipMatchingBrace++;
			}
		}
		NSBeep();
	} else if (characterToCheck == ']') {
		triedToMatchBrace = YES;
		while (location--) {
			characterToCheck = [completeString characterAtIndex:location];
			if (characterToCheck == '[') {
				if (!skipMatchingBrace) {
					return NSMakeRange(location, originalLocation - location + 1);
				} else {
					skipMatchingBrace--;
				}
			} else if (characterToCheck == ']') {
				skipMatchingBrace++;
			}
		}
		NSBeep();
	} else if (characterToCheck == '>') {
		triedToMatchBrace = YES;
		while (location--) {
			characterToCheck = [completeString characterAtIndex:location];
			if (characterToCheck == '<') {
				if (!skipMatchingBrace) {
					return NSMakeRange(location, originalLocation - location + 1);
				} else {
					skipMatchingBrace--;
				}
			} else if (characterToCheck == '>') {
				skipMatchingBrace++;
			}
		}
		NSBeep();
	} else if (characterToCheck == '(') {
		triedToMatchBrace = YES;
		while (++location < lengthOfString) {
			characterToCheck = [completeString characterAtIndex:location];
			if (characterToCheck == ')') {
				if (!skipMatchingBrace) {
					return NSMakeRange(originalLocation, location - originalLocation + 1);
				} else {
					skipMatchingBrace--;
				}
			} else if (characterToCheck == '(') {
				skipMatchingBrace++;
			}
		}
		NSBeep();
	} else if (characterToCheck == '{') {
		triedToMatchBrace = YES;
		while (++location < lengthOfString) {
			characterToCheck = [completeString characterAtIndex:location];
			if (characterToCheck == '}') {
				if (!skipMatchingBrace) {
					return NSMakeRange(originalLocation, location - originalLocation + 1);
				} else {
					skipMatchingBrace--;
				}
			} else if (characterToCheck == '{') {
				skipMatchingBrace++;
			}
		}
		NSBeep();
	} else if (characterToCheck == '[') {
		triedToMatchBrace = YES;
		while (++location < lengthOfString) {
			characterToCheck = [completeString characterAtIndex:location];
			if (characterToCheck == ']') {
				if (!skipMatchingBrace) {
					return NSMakeRange(originalLocation, location - originalLocation + 1);
				} else {
					skipMatchingBrace--;
				}
			} else if (characterToCheck == '[') {
				skipMatchingBrace++;
			}
		}
		NSBeep();
	} else if (characterToCheck == '<') {
		triedToMatchBrace = YES;
		while (++location < lengthOfString) {
			characterToCheck = [completeString characterAtIndex:location];
			if (characterToCheck == '>') {
				if (!skipMatchingBrace) {
					return NSMakeRange(originalLocation, location - originalLocation + 1);
				} else {
					skipMatchingBrace--;
				}
			} else if (characterToCheck == '<') {
				skipMatchingBrace++;
			}
		}
		NSBeep();
    }

	// If it has a found a "starting" brace but not found a match, a double-click should only select the "starting" brace and not what it usually would select at a double-click
	if (triedToMatchBrace) {
		return [super selectionRangeForProposedRange:NSMakeRange(inProposedSelRange.location, 1) granularity:NSSelectByCharacter];
	} else {
		return [super selectionRangeForProposedRange:inProposedSelRange granularity:inGranularity];
	}
}


// ------------------------------------------------------
- (BOOL)isSelfDrop
// 自己内ドラッグ&ドロップなのかを返す
// ------------------------------------------------------
{
    return _isSelfDrop;
}


// ------------------------------------------------------
- (void)setIsSelfDrop:(BOOL)inValue
// 自己内ドラッグ&ドロップなのかをセット
// ------------------------------------------------------
{
    _isSelfDrop = inValue;
}


// ------------------------------------------------------
- (BOOL)isReadingFromPboard
// ペーストまたはドロップ実行中なのかを返す
// ------------------------------------------------------
{
    return _isReadingFromPboard;
}


// ------------------------------------------------------
- (void)setIsReadingFromPboard:(BOOL)inValue
// ペーストまたはドロップ実行中なのかをセット
// ------------------------------------------------------
{
    _isReadingFromPboard = inValue;
}


// ------------------------------------------------------
- (BOOL)isReCompletion
// 再度入力補完をするかどうかを返す
// ------------------------------------------------------
{
    return _isReCompletion;
}


// ------------------------------------------------------
- (void)setIsReCompletion:(BOOL)inValue
// 再度入力補完をするかをセット
// ------------------------------------------------------
{
    _isReCompletion = inValue;
}


// ------------------------------------------------------
- (BOOL)updateOutlineMenuItemSelection
// アウトラインメニュー項目の更新をすべきかどうかを返す
// ------------------------------------------------------
{
    return _updateOutlineMenuItemSelection;
}


// ------------------------------------------------------
- (void)setUpdateOutlineMenuItemSelection:(BOOL)inValue
// アウトラインメニュー項目の更新をすべきかどうかをセット
// ------------------------------------------------------
{
    _updateOutlineMenuItemSelection = inValue;
}


// ------------------------------------------------------
- (CGFloat)lineSpacing
// 行間値を返す
// ------------------------------------------------------
{
    return _lineSpacing;
}


// ------------------------------------------------------
- (void)setLineSpacing:(CGFloat)inLineSpacing
// 行間値をセット
// ------------------------------------------------------
{
    _lineSpacing = inLineSpacing;
}


// ------------------------------------------------------
- (void)setNewLineSpacingAndUpdate:(CGFloat)inLineSpacing
// 行間値をセットし、テキストと行番号を再描画
// ------------------------------------------------------
{
    if (inLineSpacing != [self lineSpacing]) {
        NSRange theRange = NSMakeRange(0, [[self string] length]);

        [self setLineSpacing:inLineSpacing];
        // テキストを再描画
        [[self layoutManager] invalidateLayoutForCharacterRange:theRange isSoft:NO actualCharacterRange:nil];
        [self updateLineNumberAndAdjustScroll];
    }
}


// ------------------------------------------------------
- (void)doReplaceString:(NSString *)inString withRange:(NSRange)inRange 
            withSelected:(NSRange)inSelection withActionName:(NSString *)inActionName
// 置換を実行
// ------------------------------------------------------
{
    NSString *theNewStr = [[inString copy] autorelease];
    NSString *theCurStr = [[self string] substringWithRange:inRange];

    // regist Undo
    id theDocument = [[[self window] windowController] document];
    NSUndoManager *theUndoManager = [self undoManager];
    NSRange theNewRange = NSMakeRange(inRange.location, [inString length]); // replaced range after method.

    [[theUndoManager prepareWithInvocationTarget:self] 
            redoReplaceString:theNewStr withRange:inRange 
            withSelected:inSelection withActionName:inActionName]; // redo in undo
    [[theUndoManager prepareWithInvocationTarget:self] 
            setSelectedRange:[self selectedRange]]; // select current selection.
    [[theUndoManager prepareWithInvocationTarget:self] didChangeText]; // post notification.
    [[theUndoManager prepareWithInvocationTarget:[self textStorage]] 
            replaceCharactersInRange:theNewRange withString:theCurStr];
    [[theUndoManager prepareWithInvocationTarget:theDocument] 
            updateChangeCount:NSChangeUndone]; // to decrement changeCount.
    if ([inActionName length] > 0) {
        [theUndoManager setActionName:inActionName];
    }
    BOOL theBoolToSetAttrs = ([[self string] length] == 0);
    [[self textStorage] beginEditing];
    [[self textStorage] replaceCharactersInRange:inRange withString:theNewStr];
    if (theBoolToSetAttrs) { // 文字列がない場合に AppleScript から文字列を追加されたときに Attrs が適用されないことへの対応
        [[self textStorage] setAttributes:[self typingAttrs] 
                range:NSMakeRange(0, [[[self textStorage] string] length])];
    }
    [[self textStorage] endEditing];
    // テキストの編集ノーティフィケーションをポスト（ここでは NSTextStorage を編集しているため自動ではポストされない）
    [self didChangeText];
    // 選択範囲を変更、アンドゥカウントを増やす
    [self setSelectedRange:inSelection];
    [theDocument updateChangeCount:NSChangeDone];
}


// ------------------------------------------------------
- (void)selectTextRangeValue:(NSValue *)inRangeValue
// 文字列を選択
// ------------------------------------------------------
{
    [self setSelectedRange:[inRangeValue rangeValue]];
}



#pragma mark ===== Protocol =====

//=======================================================
// NSNibAwaking Protocol
//
//=======================================================

// ------------------------------------------------------
- (BOOL)validateMenuItem:(NSMenuItem *)inMenuItem
// メニューの有効／無効を制御
// ------------------------------------------------------
{
    NSRange theSelected = [self selectedRange];
    NSUInteger theLength = theSelected.length;

    if (([inMenuItem action] == @selector(exchangeLowercase:)) || 
            ([inMenuItem action] == @selector(exchangeUppercase:)) || 
            ([inMenuItem action] == @selector(exchangeCapitalized:)) || 
            ([inMenuItem action] == @selector(exchangeFullwidthRoman:)) || 
            ([inMenuItem action] == @selector(exchangeHalfwidthRoman:)) || 
            ([inMenuItem action] == @selector(exchangeKatakana:)) || 
            ([inMenuItem action] == @selector(exchangeHiragana:)) || 
            ([inMenuItem action] == @selector(unicodeNormalizationNFD:)) || 
            ([inMenuItem action] == @selector(unicodeNormalizationNFC:)) || 
            ([inMenuItem action] == @selector(unicodeNormalizationNFKD:)) || 
            ([inMenuItem action] == @selector(unicodeNormalizationNFKC:)) || 
            ([inMenuItem action] == @selector(unicodeNormalization:))) {
        return (theLength > 0);
        // （カラーコード編集メニューは常に有効）

    } else if ([inMenuItem action] == @selector(setLineSpacingFromMenu:)) {
        [inMenuItem setState:(([self lineSpacing] == (CGFloat)[[inMenuItem title] doubleValue]) ?
                NSOnState : NSOffState)];
    }

    return [super validateMenuItem:inMenuItem];
}



#pragma mark ===== Action messages =====

//=======================================================
// Action messages
//
//=======================================================

// ------------------------------------------------------
- (IBAction)shiftRight:(id)sender
// 右へシフト
// ------------------------------------------------------
{
    id theValues = [[NSUserDefaultsController sharedUserDefaultsController] values];

    // 現在の選択区域とシフトする行範囲を得る
    NSRange theSelected = [self selectedRange];
    NSRange theLineRange = [[self string] lineRangeForRange:theSelected];

    if (theLineRange.length > 1) {
        theLineRange.length--; // 最末尾の改行分を減ずる
    }
    // シフトするために挿入する文字列と長さを得る
    NSMutableString *theShiftStr = [NSMutableString string];
    NSUInteger theShiftLength = 0;
    if ([[theValues valueForKey:k_key_autoExpandTab] boolValue]) {
        NSUInteger theTabWidth = [[theValues valueForKey:k_key_tabWidth] integerValue];
        theShiftLength = theTabWidth;
        while (theTabWidth--) {
            [theShiftStr appendString:@" "];
        }
    } else {
        theShiftLength = 1;
        [theShiftStr setString:@"\t"];
    }
    if (theShiftLength < 1) { return; }

    // 置換する行を生成する
    NSMutableString *theNewLine = 
            [NSMutableString stringWithString:[[self string] substringWithRange:theLineRange]];
    NSString *theNewStr = [NSString stringWithFormat:@"%@%@", @"\n", theShiftStr];
    NSUInteger theLines = [theNewLine replaceOccurrencesOfString:@"\n"
                    withString:theNewStr options:0 range:NSMakeRange(0, [theNewLine length])];
    [theNewLine insertString:theShiftStr atIndex:0];
    // 置換後の選択位置の調整
    NSUInteger theNewLocation;
    if ((theLineRange.location == theSelected.location) && (theSelected.length > 0) && 
            ([[[self string] substringWithRange:theSelected] hasSuffix:@"\n"])) {

             // 行頭から行末まで選択されていたときは、処理後も同様に選択する
            theNewLocation = theSelected.location;
            theLines++;
    } else {
        theNewLocation = theSelected.location + theShiftLength;
    }
    // 置換実行
    [self doReplaceString:theNewLine withRange:theLineRange 
            withSelected:NSMakeRange(theNewLocation, theSelected.length + theShiftLength * theLines) 
            withActionName:NSLocalizedString(@"Shift Right",@"")];
}


// ------------------------------------------------------
- (IBAction)shiftLeft:(id)sender
// 左へシフト
// ------------------------------------------------------
{
    id theValues = [[NSUserDefaultsController sharedUserDefaultsController] values];

    // 現在の選択区域とシフトする行範囲を得る
    NSRange theSelected = [self selectedRange];
    NSRange theLineRange = [[self string] lineRangeForRange:theSelected];
    if (NSMaxRange(theLineRange) == 0) { // 空行で実行された場合は何もしない
        return;
    }
    if ((theLineRange.length > 1) && 
            ([[[self string] substringWithRange:NSMakeRange(NSMaxRange(theLineRange) - 1, 1)] 
                isEqualToString:@"\n"])) {
        theLineRange.length--; // 末尾の改行分を減ずる
    }
    // シフトするために削除するスペースの長さを得る
    NSInteger theShiftLength = [[theValues valueForKey:k_key_tabWidth] integerValue];
    if (theShiftLength < 1) { return; }

    // 置換する行を生成する
    NSArray *theLines = 
            [[[self string] substringWithRange:theLineRange] componentsSeparatedByString:@"\n"];
    NSMutableString *theNewLine = [NSMutableString string];
    NSMutableString *theTmpLine = [NSMutableString string];
    NSString *theStr;
    BOOL theSpaceDeleted;
    NSUInteger theNumOfDeleted = 0, theTotalDeleted = 0;
    NSInteger theNewLocation = theSelected.location, theNewLength = theSelected.length;
    NSInteger i, j, theCount = (NSInteger)[theLines count];

    // 選択区域を含む行をスキャンし、冒頭のスペース／タブを削除
    for (i = 0; i < theCount; i++) {
        [theTmpLine setString:theLines[i]];
        theSpaceDeleted = NO;
        for (j = 0; j < theShiftLength; j++) {
            if ([theTmpLine length] == 0) {
                break;
            }
            theStr = [theLines[i] substringWithRange:NSMakeRange(j, 1)];
            if ([theStr isEqualToString:@"\t"]) {
                if (!theSpaceDeleted) {
                    [theTmpLine deleteCharactersInRange:NSMakeRange(0, 1)];
                    theNumOfDeleted++;
                }
                break;
            } else if ([theStr isEqualToString:@" "]) {
                [theTmpLine deleteCharactersInRange:NSMakeRange(0, 1)];
                theNumOfDeleted++;
                theSpaceDeleted = YES;
            } else {
                break;
            }
        }
        // 処理後の選択区域用の値を算出
        if (i == 0) {
            theNewLocation -= theNumOfDeleted;
            if (theNewLocation < (NSInteger)theLineRange.location) {
                theNewLength -= (theLineRange.location - theNewLocation);
                theNewLocation = theLineRange.location;
            }
        } else {
            theNewLength -= theNumOfDeleted;
            if (theNewLength < (NSInteger)theLineRange.location - theNewLocation + (NSInteger)[theNewLine length]) {
                theNewLength = theLineRange.location - theNewLocation + [theNewLine length];
            }
        }
        // 冒頭のスペース／タブを削除した行を合成
        [theNewLine appendString:theTmpLine];
        if (i != ((NSInteger)[theLines count] - 1)) {
            [theNewLine appendString:@"\n"];
        }
        theTotalDeleted += theNumOfDeleted;
        theNumOfDeleted = 0;
    }
    // シフトされなかったら中止
    if (theTotalDeleted == 0) { return; }
    if (theNewLocation < 0) {
        theNewLocation = 0;
    }
    if (theNewLength < 0) {
        theNewLength = 0;
    }
    // 置換実行
    [self doReplaceString:theNewLine withRange:theLineRange 
                withSelected:NSMakeRange(theNewLocation, theNewLength) 
                withActionName:NSLocalizedString(@"Shift Left",@"")];
}


// ------------------------------------------------------
- (IBAction)exchangeLowercase:(id)sender
// 小文字へ変更
// ------------------------------------------------------
{
    NSRange theSelected = [self selectedRange];

    if (theSelected.length > 0) {
        NSString *theNewStr = [[[self string] substringWithRange:theSelected] lowercaseString];
        if (theNewStr != nil) {
            NSRange theNewRange = NSMakeRange(theSelected.location, [theNewStr length]);
            [self doInsertString:theNewStr withRange:theSelected 
                    withSelected:theNewRange withActionName:NSLocalizedString(@"to Lowercase",@"") scroll:YES];
        }
    }
}


// ------------------------------------------------------
- (IBAction)exchangeUppercase:(id)sender
// 大文字へ変更
// ------------------------------------------------------
{
    NSRange theSelected = [self selectedRange];

    if (theSelected.length > 0) {
        NSString *theNewStr = [[[self string] substringWithRange:theSelected] uppercaseString];
        if (theNewStr != nil) {
            NSRange theNewRange = NSMakeRange(theSelected.location, [theNewStr length]);
            [self doInsertString:theNewStr withRange:theSelected 
                    withSelected:theNewRange withActionName:NSLocalizedString(@"to Uppercase",@"") scroll:YES];
        }
    }
}


// ------------------------------------------------------
- (IBAction)exchangeCapitalized:(id)sender
// 単語の頭を大文字へ変更
// ------------------------------------------------------
{
    NSRange theSelected = [self selectedRange];

    if (theSelected.length > 0) {
        NSString *theNewStr = [[[self string] substringWithRange:theSelected] capitalizedString];
        if (theNewStr != nil) {
            NSRange theNewRange = NSMakeRange(theSelected.location, [theNewStr length]);
            [self doInsertString:theNewStr withRange:theSelected 
                    withSelected:theNewRange withActionName:NSLocalizedString(@"to Capitalized",@"") scroll:YES];
        }
    }
}


// ------------------------------------------------------
- (IBAction)exchangeFullwidthRoman:(id)sender
// 全角Roman文字へ変更
// ------------------------------------------------------
{
    NSRange theSelected = [self selectedRange];

    if (theSelected.length > 0) {
        NSString *theNewStr = 
                [self halfToFullwidthRomanStringFrom:[[self string] substringWithRange:theSelected]];
        if (theNewStr != nil) {
            NSRange theNewRange = NSMakeRange(theSelected.location, [theNewStr length]);
            [self doInsertString:theNewStr withRange:theSelected 
                    withSelected:theNewRange 
                    withActionName:NSLocalizedString(@"to Fullwidth (jp/Roman)",@"") scroll:YES];
        }
    }
}


// ------------------------------------------------------
- (IBAction)exchangeHalfwidthRoman:(id)sender
// 半角Roman文字へ変更
// ------------------------------------------------------
{
    NSRange theSelected = [self selectedRange];

    if (theSelected.length > 0) {
        NSString *theNewStr = 
                [self fullToHalfwidthRomanStringFrom:[[self string] substringWithRange:theSelected]];
        if (theNewStr != nil) {
            NSRange theNewRange = NSMakeRange(theSelected.location, [theNewStr length]);
            [self doInsertString:theNewStr withRange:theSelected 
                    withSelected:theNewRange 
                    withActionName:NSLocalizedString(@"to Halfwidth (jp/Roman)",@"") scroll:YES];
        }
    }
}


// ------------------------------------------------------
- (IBAction)exchangeKatakana:(id)sender
// ひらがなをカタカナへ変更
// ------------------------------------------------------
{
    NSRange theSelected = [self selectedRange];

    if (theSelected.length > 0) {
        NSString *theNewStr = 
                [self hiraganaToKatakanaStringFrom:[[self string] substringWithRange:theSelected]];
        if (theNewStr != nil) {
            NSRange theNewRange = NSMakeRange(theSelected.location, [theNewStr length]);
            [self doInsertString:theNewStr withRange:theSelected 
                    withSelected:theNewRange 
                    withActionName:NSLocalizedString(@"Hiragana to Katakana (jp)",@"") scroll:YES];
        }
    }
}


// ------------------------------------------------------
- (IBAction)exchangeHiragana:(id)sender
// カタカナをひらがなへ変更
// ------------------------------------------------------
{
    NSRange theSelected = [self selectedRange];

    if (theSelected.length > 0) {
        NSString *theNewStr = 
                [self katakanaToHiraganaStringFrom:[[self string] substringWithRange:theSelected]];
        if (theNewStr != nil) {
            NSRange theNewRange = NSMakeRange(theSelected.location, [theNewStr length]);
            [self doInsertString:theNewStr withRange:theSelected 
                    withSelected:theNewRange 
                    withActionName:NSLocalizedString(@"Katakana to Hiragana (jp)",@"") scroll:YES];
        }
    }
}


// ------------------------------------------------------
- (IBAction)unicodeNormalizationNFD:(id)sender
// Unicode正規化
// ------------------------------------------------------
{
    [self unicodeNormalization:sender];
}


// ------------------------------------------------------
- (IBAction)unicodeNormalizationNFC:(id)sender
// Unicode正規化
// ------------------------------------------------------
{
    [self unicodeNormalization:sender];
}


// ------------------------------------------------------
- (IBAction)unicodeNormalizationNFKD:(id)sender
// Unicode正規化
// ------------------------------------------------------
{
    [self unicodeNormalization:sender];
}


// ------------------------------------------------------
- (IBAction)unicodeNormalizationNFKC:(id)sender
// Unicode正規化
// ------------------------------------------------------
{
    [self unicodeNormalization:sender];
}


// ------------------------------------------------------
- (IBAction)unicodeNormalization:(id)sender
// Unicode正規化
// ------------------------------------------------------
{
    NSRange theSelected = [self selectedRange];
    NSInteger theSwitchType;

    if ([sender isKindOfClass:[NSMenuItem class]]) {
        theSwitchType = [sender tag];
    } else if ([sender isKindOfClass:[NSNumber class]]) {
        theSwitchType = [sender integerValue];
    } else {
        return;
    }
    if (theSelected.length > 0) {
        NSString *theActionName = nil, *theNewStr = nil, *theOrgStr = [[self string] substringWithRange:theSelected];

        switch (theSwitchType) {
        case 0: // from D
            theNewStr = [theOrgStr decomposedStringWithCanonicalMapping];
            theActionName = [NSString stringWithString:NSLocalizedString(@"NFD",@"")];
            break;
        case 1: // from C
            theNewStr = [theOrgStr precomposedStringWithCanonicalMapping];
            theActionName = [NSString stringWithString:NSLocalizedString(@"NFC",@"")];
            break;
        case 2: // from KD
            theNewStr = [theOrgStr decomposedStringWithCompatibilityMapping];
            theActionName = [NSString stringWithString:NSLocalizedString(@"NFKD",@"")];
            break;
        case 3: // from KC
            theNewStr = [theOrgStr precomposedStringWithCompatibilityMapping];
            theActionName = [NSString stringWithString:NSLocalizedString(@"NFKC",@"")];
            break;
        default:
            break;
            return;
        }
        if (theNewStr != nil) {
            NSRange theNewRange = NSMakeRange(theSelected.location, [theNewStr length]);
            [self doInsertString:theNewStr withRange:theSelected 
                    withSelected:theNewRange withActionName:theActionName scroll:YES];
        }
    }
}


// ------------------------------------------------------
- (IBAction)inputYenMark:(id)sender
// 半角円マークを入力
// ------------------------------------------------------
{
    [super insertText:[NSString stringWithCharacters:&k_yenMark length:1]];
}


// ------------------------------------------------------
- (IBAction)inputBackSlash:(id)sender
// バックスラッシュを入力
// ------------------------------------------------------
{
    [super insertText:@"\\"];
}


// ------------------------------------------------------
- (IBAction)editHexColorCodeAsForeColor:(id)sender
// Hex Color Code を文字色として編集ウィンドウへ取り込む
// ------------------------------------------------------
{
    NSString *theCurStr = [[self string] substringWithRange:[self selectedRange]];

    [[CEHCCManager sharedInstance] importHexColorCodeAsForeColor:theCurStr];
}


// ------------------------------------------------------
- (IBAction)editHexColorCodeAsBGColor:(id)sender
// Hex Color Code を文字色として編集ウィンドウへ取り込む
// ------------------------------------------------------
{
    NSString *theCurStr = [[self string] substringWithRange:[self selectedRange]];

    [[CEHCCManager sharedInstance] importHexColorCodeAsBackGroundColor:theCurStr];
}


// ------------------------------------------------------
- (IBAction)setSelectedRangeWithNSValue:(id)sender
// アウトラインメニュー選択によるテキスト選択を実行
// ------------------------------------------------------
{
    NSValue *theValue = [sender representedObject];
    if (theValue != nil) {
        NSRange theRange = [theValue rangeValue];

        [self setUpdateOutlineMenuItemSelection:NO]; // 選択範囲変更後にメニュー選択項目が再選択されるオーバーヘッドを省く
        [self setSelectedRange:theRange];
        [self centerSelectionInVisibleArea:self];
        [[self window] makeFirstResponder:self];
    }
}


// ------------------------------------------------------
- (IBAction)setLineSpacingFromMenu:(id)sender
// 行間設定を変更
// ------------------------------------------------------
{
    [self setNewLineSpacingAndUpdate:(CGFloat)[[sender title] doubleValue]];
}



@end



@implementation CETextViewCore (Private)

// ------------------------------------------------------
- (void)redoReplaceString:(NSString *)inString withRange:(NSRange)inRange 
            withSelected:(NSRange)inSelection withActionName:(NSString *)inActionName
// 文字列置換のリドゥーを登録
// ------------------------------------------------------
{
    NSUndoManager *theUndoManager = [self undoManager];

    [[theUndoManager prepareWithInvocationTarget:self] 
        doReplaceString:inString withRange:inRange withSelected:inSelection withActionName:inActionName];
}


// ------------------------------------------------------
- (void)doInsertString:(NSString *)inString withRange:(NSRange)inRange 
            withSelected:(NSRange)inSelection withActionName:(NSString *)inActionName scroll:(BOOL)inBoolToScroll
// 置換実行
// ------------------------------------------------------
{
    NSUndoManager *theUndoManager = [self undoManager];

    // 一時的にイベントごとのグループを作らないようにする
    // （でないと、グルーピングするとchangeCountが余分にカウントされる）
    [theUndoManager setGroupsByEvent:NO];

    // それ以前のキー入力と分離するため、グルーピング
    // CEDocument > writeWithBackupToFile:ofType:saveOperation:でも同様の処理を行っている (2008.06.01)
    [theUndoManager beginUndoGrouping];
    [self setSelectedRange:inRange];
    [super insertText:[[inString copy] autorelease]];
    [self setSelectedRange:inSelection];
    if (inBoolToScroll) {
        [self scrollRangeToVisible:inSelection];
    }
    if ([inActionName length] > 0) {
        [theUndoManager setActionName:inActionName];
    }
    [theUndoManager endUndoGrouping];
    [theUndoManager setGroupsByEvent:YES]; // イベントごとのグループ作成設定を元に戻す
}


// ------------------------------------------------------
- (NSString *)halfToFullwidthRomanStringFrom:(NSString *)inString
// 半角Romanを全角Romanへ変換
// ------------------------------------------------------
{
    NSMutableString *outString = [NSMutableString string];
    NSCharacterSet *theLatinCharSet = [NSCharacterSet characterSetWithRange:NSMakeRange((NSUInteger)'!', 94)];
    unichar theChar;
    NSUInteger i, theCount = [inString length];

    for (i = 0; i < theCount; i++) {
        theChar = [inString characterAtIndex:i];
        if ([theLatinCharSet characterIsMember:theChar]) {
            [outString appendString:[NSString stringWithFormat:@"%C", (unichar)(theChar + 65248)]];
// 半角カナには未対応（2/21） *********************
//        } else if ([theHankakuKanaCharSet characterIsMember:theChar]) {
//            [outString appendString:[NSString stringWithFormat:@"%C", (unichar)(theChar + 65248)]];
        } else {
            [outString appendString:[inString substringWithRange:NSMakeRange(i, 1)]];
        }
    }
    return outString;
}


// ------------------------------------------------------
- (NSString *)fullToHalfwidthRomanStringFrom:(NSString *)inString
// 全角Romanを半角Romanへ変換
// ------------------------------------------------------
{
    NSMutableString *outString = [NSMutableString string];
    NSCharacterSet *theFullwidthCharSet = [NSCharacterSet characterSetWithRange:NSMakeRange(65281, 94)];
    unichar theChar;
    NSUInteger i, theCount = [inString length];

    for (i = 0; i < theCount; i++) {
        theChar = [inString characterAtIndex:i];
        if ([theFullwidthCharSet characterIsMember:theChar]) {
            [outString appendString:[NSString stringWithFormat:@"%C", (unichar)(theChar - 65248)]];
        } else {
            [outString appendString:[inString substringWithRange:NSMakeRange(i, 1)]];
        }
    }
    return outString;
}


// ------------------------------------------------------
- (NSString *)hiraganaToKatakanaStringFrom:(NSString *)inString
// ひらがなをカタカナへ変換
// ------------------------------------------------------
{
    NSMutableString *outString = [NSMutableString string];
    NSCharacterSet *theHiraganaCharSet = [NSCharacterSet characterSetWithRange:NSMakeRange(12353, 86)];
    unichar theChar;
    NSUInteger i, theCount = [inString length];

    for (i = 0; i < theCount; i++) {
        theChar = [inString characterAtIndex:i];
        if ([theHiraganaCharSet characterIsMember:theChar]) {
            [outString appendString:[NSString stringWithFormat:@"%C", (unichar)(theChar + 96)]];
        } else {
            [outString appendString:[inString substringWithRange:NSMakeRange(i, 1)]];
        }
    }
    return outString;
}


// ------------------------------------------------------
- (NSString *)katakanaToHiraganaStringFrom:(NSString *)inString
// カタカナをひらがなへ変換
// ------------------------------------------------------
{
    NSMutableString *outString = [NSMutableString string];
    NSCharacterSet *theKatakanaCharSet = [NSCharacterSet characterSetWithRange:NSMakeRange(12449, 86)];
    unichar theChar;
    NSUInteger i, theCount = [inString length];

    for (i = 0; i < theCount; i++) {
        theChar = [inString characterAtIndex:i];
        if ([theKatakanaCharSet characterIsMember:theChar]) {
            [outString appendString:[NSString stringWithFormat:@"%C", (unichar)(theChar - 96)]];
        } else {
            [outString appendString:[inString substringWithRange:NSMakeRange(i, 1)]];
        }
    }
    return outString;
}


// ------------------------------------------------------
- (BOOL)draggedItemsArray:(NSArray *)inArray containsExtensionInExtensions:(NSArray *)inExtensions
// ドラッグされているアイテムのNSFilenamesPboardTypeに指定された拡張子のものが含まれているかどうかを返す
// ------------------------------------------------------
{
    if ([inArray count] > 0) {
        NSEnumerator *theEnumerator = [inExtensions objectEnumerator];
        NSString *theXtsn;

        while (theXtsn = [theEnumerator nextObject]) {
            for (id item in inArray) {
                if ([[item pathExtension] isEqualToString:theXtsn]) {
                    return YES;
                }
            }
        }
    }
    return NO;
}


// ------------------------------------------------------
- (void)updateLineNumberAndAdjustScroll
// 行番号更新、キャレット／選択範囲が見えるようスクロール位置を調整
// ------------------------------------------------------
{
    // 行番号を強制的に更新（スクロール位置が調整されない時は再描画が行われないため）
    if ([(CELineNumView *)[self slaveView] showLineNum]) {
        [[self slaveView] setNeedsDisplay:YES];
    }
    // キャレット／選択範囲が見えるようにスクロール位置を調整
    [self scrollRangeToVisible:[self selectedRange]];
}


// ------------------------------------------------------
- (void)replaceLineEndingToDocCharInPboard:(NSPasteboard *)inPboard
// Pasetboard内文字列の行末コードを書類に設定されたものに置換する
// ------------------------------------------------------
{
    if (inPboard == nil) { return; }

    OgreNewlineCharacter theNewlineChar = [[(CESubSplitView *)[self delegate] editorView] lineEndingCharacter];

    if (theNewlineChar != OgreLfNewlineCharacter) {
        NSString *thePboardType = [inPboard availableTypeFromArray:[self pasteboardTypesForString]];
        if (thePboardType != nil) {
            NSString *theStr = [inPboard stringForType:thePboardType];

            if (theStr != nil) {
                [inPboard setString:[OGRegularExpression replaceNewlineCharactersInString:theStr 
                                    withCharacter:theNewlineChar] forType:thePboardType];
            }
        }
    }
}



@end
