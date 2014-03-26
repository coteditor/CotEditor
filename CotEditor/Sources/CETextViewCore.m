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
#import "CEColorCodePanelController.h"
#import "CEKeyBindingManager.h"
#import "constants.h"


@interface CETextViewCore ()

@property (nonatomic) NSRect insertionRect;
@property (nonatomic) NSPoint textContainerOriginPoint;

@end



#pragma mark -

@implementation CETextViewCore



#pragma mark NSTextView Methods

//=======================================================
// NSTextView method
//
//=======================================================

// ------------------------------------------------------
- (instancetype)initWithFrame:(NSRect)frameRect textContainer:(NSTextContainer *)inTextContainer
// 初期化
// ------------------------------------------------------
{
    self = [super initWithFrame:frameRect textContainer:inTextContainer];
    if (self) {
        // このメソッドはSmultronのSMLTextViewを参考にしています。
        // This method is based on Smultron(SMLTextView) written by Peter Borg. Copyright (C) 2004 Peter Borg.
        // http://smultron.sourceforge.net
        // set the width of every tab by first checking the size of the tab in spaces in the current font and then remove all tabs that sets automatically and then set the default tab stop distance
        NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
        
        NSFont *font = [NSFont fontWithName:[defaults stringForKey:k_key_fontName]
                                       size:(CGFloat)[defaults doubleForKey:k_key_fontSize]];

        NSDictionary *attrs;
        NSColor *backgroundColor, *highlightLineColor;

        NSMutableParagraphStyle *paragraphStyle = [[NSParagraphStyle defaultParagraphStyle] mutableCopy];
        for (NSTextTab *textTabToBeRemoved in [paragraphStyle tabStops]) {
            [paragraphStyle removeTabStop:textTabToBeRemoved];
        }
        [paragraphStyle setDefaultTabInterval:[self tabIntervalFromFont:font]];

        attrs = @{NSParagraphStyleAttributeName: paragraphStyle,
                  NSFontAttributeName: font,
                  NSForegroundColorAttributeName: [NSUnarchiver unarchiveObjectWithData:
                                                   [defaults valueForKey:k_key_textColor]]};
        [self setTypingAttrs:attrs];
        [self setEffectTypingAttrs];
        // （NSParagraphStyle の lineSpacing を設定すればテキスト描画時の行間は制御できるが、
        // 「文書の1文字目に1バイト文字（または2バイト文字）を入力してある状態で先頭に2バイト文字（または1バイト文字）を
        // 挿入すると行間がズレる」問題が生じるため、CELayoutManager および CEATSTypesetter で制御している）

        // set the values
        [self setFont:font];
        [self setMinSize:frameRect.size];
        [self setMaxSize:NSMakeSize(FLT_MAX, FLT_MAX)];
        [self setAllowsDocumentBackgroundColorChange:NO];
        [self setAllowsUndo:YES];
        [self setRichText:NO];
        [self setImportsGraphics:NO];
        [self setSmartInsertDeleteEnabled:[defaults boolForKey:k_key_smartInsertAndDelete]];
        [self setContinuousSpellCheckingEnabled:[defaults boolForKey:k_key_checkSpellingAsType]];
        [self setUsesFindPanel:YES];
        [self setHorizontallyResizable:YES];
        [self setVerticallyResizable:YES];
        [self setAcceptsGlyphInfo:YES];
        [self setAutomaticQuoteSubstitutionEnabled:[defaults boolForKey:k_key_enableSmartQuotes]];
        [self setAutomaticDashSubstitutionEnabled:[defaults boolForKey:k_key_enableSmartQuotes]];
        [self setLineSpacing:(CGFloat)[defaults doubleForKey:k_key_lineSpacing]];
        [self setTextColor:[NSUnarchiver unarchiveObjectWithData:[defaults valueForKey:k_key_textColor]]];
        backgroundColor = [NSUnarchiver unarchiveObjectWithData:[defaults valueForKey:k_key_backgroundColor]];
        highlightLineColor =  [NSUnarchiver unarchiveObjectWithData:[defaults valueForKey:k_key_highlightLineColor]];
        [self setBackgroundColor:[backgroundColor colorWithAlphaComponent:(CGFloat)[defaults doubleForKey:k_key_windowAlpha]]];
        [self setHighlightLineColor:[highlightLineColor colorWithAlphaComponent:(CGFloat)[defaults doubleForKey:k_key_windowAlpha]]];
        [self setInsertionPointColor:
                [NSUnarchiver unarchiveObjectWithData:[defaults valueForKey:k_key_insertionPointColor]]];
        [self setSelectedTextAttributes:
                @{NSBackgroundColorAttributeName: [NSUnarchiver unarchiveObjectWithData:[defaults valueForKey:k_key_selectionColor]]}];
        [self setInsertionRect:NSZeroRect];
        [self setTextContainerOriginPoint:NSMakePoint((CGFloat)[defaults doubleForKey:k_key_textContainerInsetWidth],
                                                      (CGFloat)[defaults doubleForKey:k_key_textContainerInsetHeightTop])];
        [self setIsReCompletion:NO];
        [self setUpdateOutlineMenuItemSelection:YES];
        [self setIsSelfDrop:NO];
        [self setIsReadingFromPboard:NO];
        [self setHighlightLineAdditionalRect:NSZeroRect];
    }

    return self;
}


// ------------------------------------------------------
- (BOOL)becomeFirstResponder
// first responder になれるかを返す  !!!: Deprecated on 10.4
// ------------------------------------------------------
{
    [(CESubSplitView *)[self delegate] setTextViewToEditorView:self];

    return [super becomeFirstResponder];
}


// ------------------------------------------------------
- (void)keyDown:(NSEvent *)theEvent
// キー押下を取得
// ------------------------------------------------------
{
    NSString *charIgnoringMod = [theEvent charactersIgnoringModifiers];
    // IM で日本語入力変換中でないときのみ追加テキストキーバインディングを実行
    if ((![self hasMarkedText]) && (charIgnoringMod != nil)) {
        NSUInteger modFlags = [theEvent modifierFlags];
        NSString *selectorStr = [[CEKeyBindingManager sharedManager] selectorStringWithKeyEquivalent:charIgnoringMod
                                                                                        modifierFrags:modFlags];
        NSInteger length = [selectorStr length];
        if ((selectorStr != nil) && (length > 0)) {
            if (([selectorStr hasPrefix:@"insertCustomText"]) && (length == 20)) {
                NSInteger theNum = [[selectorStr substringFromIndex:17] integerValue];
                [self insertCustomTextWithPatternNum:theNum];
            } else {
                [self doCommandBySelector:NSSelectorFromString(selectorStr)];
            }
            return;
        }
    }
    [super keyDown:theEvent];
}


// ------------------------------------------------------
- (void)insertText:(id)aString
// 文字列入力、'¥' と '\' を入れ替える。
// ------------------------------------------------------
{
    if ([[NSUserDefaults standardUserDefaults] boolForKey:k_key_swapYenAndBackSlashKey] && ([aString length] == 1)) {
        NSEvent *event = [NSApp currentEvent];
        NSUInteger flags = [NSEvent modifierFlags];

        if (([event type] == NSKeyDown) && (flags == 0)) {
            if ([aString isEqualToString:@"\\"]) {
                [self inputYenMark:nil];
                return;
            } else if ([aString isEqualToString:[NSString stringWithCharacters:&k_yenMark length:1]]) {
                [self inputBackSlash:nil];
                return;
            }
        }
    }
    [super insertText:aString];
}


// ------------------------------------------------------
- (void)insertTab:(id)sender
// タブ入力、タブを展開。
// ------------------------------------------------------
{
    if ([[NSUserDefaults standardUserDefaults] boolForKey:k_key_autoExpandTab]) {
        NSInteger tabWidth = [[NSUserDefaults standardUserDefaults] integerForKey:k_key_tabWidth];
        NSRange selected = [self selectedRange];
        NSRange lineRange = [[self string] lineRangeForRange:selected];
        NSInteger location = selected.location - lineRange.location;
        NSInteger length = tabWidth - ((location + tabWidth) % tabWidth);
        NSMutableString *spaces = [NSMutableString string];

        while (length--) {
            [spaces appendString:@" "];
        }
        [super insertText:spaces];
    } else {
        [super insertTab:sender];
    }
}


// ------------------------------------------------------
- (void)insertNewline:(id)sender
// 行末コード入力、オートインデント実行。
// ------------------------------------------------------
{
    NSMutableString *input = [NSMutableString string];
    
    if ([[NSUserDefaults standardUserDefaults] boolForKey:k_key_autoIndent]) {
        NSRange selectedRange = [self selectedRange];
        NSRange lineRange = [[self string] lineRangeForRange:selectedRange];
        NSString *lineStr = [[self string] substringWithRange:
                    NSMakeRange(lineRange.location,
                                lineRange.length - (NSMaxRange(lineRange) - NSMaxRange(selectedRange)))];
        NSRange indentRange = [lineStr rangeOfRegularExpressionString:@"^[[:blank:]\t]+"];

        // インデントを選択状態で改行入力した時は置換とみなしてオートインデントしない 2008.12.13
        if ((indentRange.location != NSNotFound) &&
            NSMaxRange(selectedRange) < (selectedRange.location + NSMaxRange(indentRange))) {
            [input setString:[lineStr substringWithRange:indentRange]];
        }
    }
    [super insertNewline:sender];
    if ([input length] > 0) {
        [super insertText:input];
    }
}


// ------------------------------------------------------
- (void)deleteBackward:(id)sender
// デリート。タブを展開しているときのスペースを調整削除。
// ------------------------------------------------------
{
    NSRange selectedRange = [self selectedRange];
    if (selectedRange.length == 0) {
        if ([[NSUserDefaults standardUserDefaults] boolForKey:k_key_autoExpandTab]) {
            NSInteger tabWidth = [[NSUserDefaults standardUserDefaults] integerForKey:k_key_tabWidth];
            NSRange lineRange = [[self string] lineRangeForRange:selectedRange];
            NSInteger location = selectedRange.location - lineRange.location;
            NSInteger length = (location + tabWidth) % tabWidth;
            NSInteger targetWidth = (length == 0) ? tabWidth : length;
            if ((NSInteger)selectedRange.location >= targetWidth) {
                NSRange targetRange = NSMakeRange(selectedRange.location - targetWidth, targetWidth);
                NSString *target = [[self string] substringWithRange:targetRange];
                BOOL valueToDelete = NO;
                NSUInteger i;
                for (i = 0; i < targetWidth; i++) {
                    valueToDelete = [[target substringWithRange:NSMakeRange(i, 1)] isEqualToString:@" "];
                    if (!valueToDelete) {
                        break;
                    }
                }
                if (valueToDelete) {
                    [self setSelectedRange:targetRange];
                }
            }
        }
    }
    [super deleteBackward:sender];
}


// ------------------------------------------------------
- (void)insertCompletion:(NSString *)word forPartialWordRange:(NSRange)charRange 
        movement:(NSInteger)movement isFinal:(BOOL)isFinal
// 補完リストの表示、選択候補の入力
// ------------------------------------------------------
{
    NSEvent *event = [[self window] currentEvent];
    NSRange range;
    BOOL shouldReselect = NO;

    // complete リストを表示中に通常のキー入力があったら、直後にもう一度入力補完を行うためのフラグを立てる
    // （フラグは CEEditorView > textDidChange: で評価される）
    if (isFinal && ([event type] == NSKeyDown)) {
        NSString *inputChar = [event charactersIgnoringModifiers];
        unichar theUnichar = [inputChar characterAtIndex:0];

        if ([inputChar isEqualToString:[event characters]]) { //キーバインディングの入力などを除外
            // アンダースコアが右矢印キーと判断されることの是正
            if (([inputChar isEqualToString:@"_"]) && (movement == NSRightTextMovement) && (isFinal)) {
                movement = NSIllegalTextMovement;
                isFinal = NO;
            }
            if ((movement == NSIllegalTextMovement) &&
                (theUnichar < 0xF700) && (theUnichar != NSDeleteCharacter)) { // 通常のキー入力の判断
                [self setIsReCompletion:YES];
            } else {
                // 補完文字列に括弧が含まれていたら、括弧内だけを選択する準備をする
                range = [word rangeOfRegularExpressionString:@"\\(.*\\)"];
                shouldReselect = (range.location != NSNotFound);
            }
        }
    }
    [super insertCompletion:word forPartialWordRange:charRange movement:movement isFinal:isFinal];
    if (shouldReselect) {
        // 括弧内だけを選択
        [self setSelectedRange:NSMakeRange(charRange.location + range.location + 1, range.length - 2)];
    }
}


// ------------------------------------------------------
- (NSMenu *)menuForEvent:(NSEvent *)theEvent
// コンテキストメニューを返す
// ------------------------------------------------------
{
    NSMenu *outMenu = [super menuForEvent:theEvent];
    NSMenuItem *selectAllMenuItem = [[NSMenuItem alloc] initWithTitle:NSLocalizedString(@"Select All", nil)
                                                               action:@selector(selectAll:) keyEquivalent:@""];
    NSMenuItem *utilityMenuItem = [[NSMenuItem alloc] initWithTitle:NSLocalizedString(@"Utility", nil)
                                                             action:nil keyEquivalent:@""];
    NSMenu *utilityMenu = [[[[NSApp mainMenu] itemAtIndex:k_utilityMenuIndex] submenu] copy];
    NSMenuItem *ASMenuItem = [[NSMenuItem alloc] initWithTitle:@"" action:nil keyEquivalent:@""];
    NSMenu *ASSubMenu = [[CEScriptManager sharedManager] contexualMenu];

    // 「フォント」メニューおよびサブメニューを削除
    [outMenu removeItem:[outMenu itemWithTitle:NSLocalizedString(@"Font",@"")]];

    // 連続してコンテキストメニューを表示させるとどんどんメニューアイテムが追加されてしまうので、
    // 既に追加されているかどうかをチェックしている
    if (selectAllMenuItem &&
        ([outMenu indexOfItemWithTarget:nil andAction:@selector(selectAll:)] == k_noMenuItem)) {
        NSInteger pasteIndex = [outMenu indexOfItemWithTarget:nil andAction:@selector(paste:)];
        if (pasteIndex != k_noMenuItem) {
            [outMenu insertItem:selectAllMenuItem atIndex:(pasteIndex + 1)];
        }
    }
    if (((utilityMenu) || (ASSubMenu)) &&
        ([outMenu indexOfItemWithTag:k_utilityMenuTag] == k_noMenuItem) &&
        ([outMenu indexOfItemWithTag:k_scriptMenuTag] == k_noMenuItem)) {
        [outMenu addItem:[NSMenuItem separatorItem]];
    }
    if ((utilityMenu) && ([outMenu indexOfItemWithTag:k_utilityMenuTag] == k_noMenuItem)) {
        [utilityMenuItem setTag:k_utilityMenuTag];
        [utilityMenuItem setSubmenu:utilityMenu];
        [outMenu addItem:utilityMenuItem];
    }
    if (ASSubMenu) {
        NSMenuItem *delItem = nil;
        while ((delItem = [outMenu itemWithTag:k_scriptMenuTag])) {
            [outMenu removeItem:delItem];
        }
        
        if ([[NSUserDefaults standardUserDefaults] boolForKey:k_key_inlineContextualScriptMenu]) {
            NSUInteger i, count = [ASSubMenu numberOfItems];
            NSMenuItem *addItem = nil;

            for (i = 0; i < 2; i++) { // セパレータをふたつ追加
                [outMenu addItem:[NSMenuItem separatorItem]];
                [[outMenu itemAtIndex:([outMenu numberOfItems] - 1)] setTag:k_scriptMenuTag];
            }
            for (i = 0; i < count; i++) {
                addItem = [(NSMenuItem *)[ASSubMenu itemAtIndex:i] copy];
                [addItem setTag:k_scriptMenuTag];
                [outMenu addItem:addItem];
            }
        } else{
            [ASMenuItem setImage:[NSImage imageNamed:@"scriptMenuIcon"]];
            [ASMenuItem setTag:k_scriptMenuTag];
            [ASMenuItem setSubmenu:ASSubMenu];
            [outMenu addItem:ASMenuItem];
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
    NSFont *newFont = [sender convertFont:[self font]];

    [self setFont:newFont];
    [self setNeedsDisplay:YES]; // 本来なくても再描画されるが、最下行以下のページガイドの描画が残るための措置(2009.02.14)
    [[self slaveView] setNeedsDisplay:YES];
    [self updateLineNumberAndAdjustScroll];
}


// ------------------------------------------------------
- (void)setFont:(NSFont *)font
// フォントを設定
// ------------------------------------------------------
{
    NSMutableDictionary *attrs = [[self typingAttrs] mutableCopy];

// 複合フォントで行間が等間隔でなくなる問題を回避するため、CELayoutManager にもフォントを持たせておく。
// （CELayoutManager で [[self firstTextView] font] を使うと、「1バイトフォントを指定して日本語が入力されている」場合に
// 日本語フォント名を返してくることがあるため、CELayoutManager からは [textView font] を使わない）
    [(CELayoutManager *)[self layoutManager] setTextFont:font];
    [super setFont:font];
    attrs[NSFontAttributeName] = font;
    [attrs[NSParagraphStyleAttributeName] setDefaultTabInterval:[self tabIntervalFromFont:font]];
    
    [self setTypingAttrs:attrs];
    [self setEffectTypingAttrs];
}


// ------------------------------------------------------
- (NSRange)rangeForUserCompletion
// 補完時の範囲を返す
// ------------------------------------------------------
{
    NSString *string = [self string];
    NSRange range = [super rangeForUserCompletion];
    NSCharacterSet *charSet = [(CESubSplitView *)[self delegate] completionsFirstLetterSet];
    NSInteger i, begin = range.location;

    if (charSet == nil) { return range; }

    // 入力補完文字列の先頭となりえない文字が出てくるまで補完文字列対象を広げる
    for (i = range.location; i >= 0; i--) {
        unichar theChar = [[string substringWithRange:NSMakeRange(i, 1)] characterAtIndex:0];
        if ([charSet characterIsMember:theChar]) {
            begin = i;
        } else {
            break;
        }
    }
    return NSMakeRange(begin, NSMaxRange(range) - begin);
}


// ------------------------------------------------------
- (NSPoint)textContainerOrigin
// テキストコンテナの原点（左上）座標を返す
// ------------------------------------------------------
{
    return [self textContainerOriginPoint];
}


// ------------------------------------------------------
- (void)drawRect:(NSRect)inRect
// ビュー内を描画
// ------------------------------------------------------
{
    [super drawRect:inRect];

    [self drawHighlightLineAdditionalRect];

    // ページガイド描画
    if ([(CESubSplitView *)[self delegate] showPageGuide]) {
        CGFloat column = (CGFloat)[[NSUserDefaults standardUserDefaults] doubleForKey:k_key_pageGuideColumn];
        NSImage *lineImg = [NSImage imageNamed:@"pageGuide"];
        if ((column < k_pageGuideColumnMin) || (column > k_pageGuideColumnMax) || (lineImg == nil)) {
            return;
        }
        CGFloat linePadding = [[self textContainer] lineFragmentPadding];
        CGFloat insetWidth = (CGFloat)[[NSUserDefaults standardUserDefaults] doubleForKey:k_key_textContainerInsetWidth];
        NSString *tmpStr = @"M";
        column *= [tmpStr sizeWithAttributes:@{NSFontAttributeName:[self font]}].width;

        // （2ピクセル右に描画してるのは、調整）
        [lineImg drawInRect:NSMakeRect(column + insetWidth + linePadding + 2.0, 0, 1, [self frame].size.height)
                   fromRect:NSMakeRect(0, 0, 2, 1) operation:NSCompositeSourceOver fraction:0.5];
    }
    // テキストビューを透過させている時に影を更新描画する
    if ([[self backgroundColor] alphaComponent] < 1.0) {
        [[self window] invalidateShadow];
    }
}


// ------------------------------------------------------
- (void)scrollRangeToVisible:(NSRange)range
// 特定の範囲が見えるようにスクロール
// ------------------------------------------------------
{
    [super scrollRangeToVisible:range];
    
    // 完全にスクロールさせる
    // （setTextContainerInset で上下に空白領域を挿入している関係で、ちゃんとスクロールしない場合があることへの対策）
    NSUInteger length = [[self string] length];
    NSRect rect = NSZeroRect, convertedRect;
    
    if (length == range.location) {
        rect = [[self layoutManager] extraLineFragmentRect];
    } else if (length > range.location) {
        NSString *tailStr = [[self string] substringFromIndex:range.location];
        if ([tailStr newlineCharacter] != OgreNonbreakingNewlineCharacter) {
            return;
        }
    }
    
    if (NSEqualRects(rect, NSZeroRect)) {
        NSRange targetRange = [[self string] lineRangeForRange:range];
        NSRange glyphRange = [[self layoutManager] glyphRangeForCharacterRange:targetRange actualCharacterRange:nil];
        rect = [[self layoutManager] lineFragmentRectForGlyphAtIndex:(NSMaxRange(glyphRange) - 1)
                                                      effectiveRange:nil];
    }
    if (NSEqualRects(rect, NSZeroRect)) { return; }
    
    convertedRect = [self convertRect:rect toView:[[self enclosingScrollView] superview]]; //subsplitview
    if ((convertedRect.origin.y >= 0) &&
        (convertedRect.origin.y < (CGFloat)[[NSUserDefaults standardUserDefaults] doubleForKey:k_key_textContainerInsetHeightBottom]))
    {
        [self scrollPoint:NSMakePoint(NSMinX(rect), NSMaxY(rect))];
    }
}



#pragma mark Public Methods

//=======================================================
// Public method
//
//=======================================================


// ------------------------------------------------------
- (void)drawHighlightLineAdditionalRect
// ハイライト行追加表示
// ------------------------------------------------------
{
    if (NSWidth([self highlightLineAdditionalRect]) == 0) { return; }

    [[[self highlightLineColor] colorWithAlphaComponent:[[self backgroundColor] alphaComponent]] set];
    [NSBezierPath fillRect:[self highlightLineAdditionalRect]];
}


// ------------------------------------------------------
- (void)setEffectTypingAttrs
// キー入力時の文字修飾辞書をセット
// ------------------------------------------------------
{
    [self setTypingAttributes:[self typingAttrs]];
}


// ------------------------------------------------------
- (void)setBackgroundColorWithAlpha:(CGFloat)alpha
// 背景色をセット
// ------------------------------------------------------
{
    NSColor *theBackgroundColor = 
            [NSUnarchiver unarchiveObjectWithData:[[NSUserDefaults standardUserDefaults] valueForKey:k_key_backgroundColor]];

    [self setBackgroundColor:[theBackgroundColor colorWithAlphaComponent:alpha]];
}


// ------------------------------------------------------
- (void)replaceSelectedStringTo:(NSString *)string scroll:(BOOL)doScroll
// 選択文字列を置換
// ------------------------------------------------------
{
    if (string == nil) { return; }
    NSRange selectedRange = [self selectedRange];
    NSString *actionName = (selectedRange.length > 0) ? @"Replace text" : @"Insert text";
    NSRange newRange = NSMakeRange(selectedRange.location, [string length]);

    [self doInsertString:string withRange:selectedRange 
            withSelected:newRange withActionName:NSLocalizedString(actionName, nil) scroll:doScroll];
}


// ------------------------------------------------------
- (void)replaceAllStringTo:(NSString *)string
// 全文字列を置換
// ------------------------------------------------------
{
    NSRange newRange = NSMakeRange(0, [string length]);

    if (string) {
        [self doReplaceString:string withRange:NSMakeRange(0, [[self string] length])
                 withSelected:newRange withActionName:NSLocalizedString(@"Replace text", nil)];
    }
}


// ------------------------------------------------------
- (void)insertAfterSelection:(NSString *)string
// 選択文字列の後ろへ新規文字列を挿入
// ------------------------------------------------------
{
    if (string == nil) { return; }
    NSRange selectedRange = [self selectedRange];
    NSRange newRange = NSMakeRange(NSMaxRange(selectedRange), [string length]);

    [self doInsertString:string withRange:NSMakeRange(NSMaxRange(selectedRange), 0)
            withSelected:newRange withActionName:NSLocalizedString(@"Insert text", nil) scroll:NO];
}


// ------------------------------------------------------
- (void)appendAllString:(NSString *)string
// 末尾に新規文字列を追加
// ------------------------------------------------------
{
    if (string == nil) { return; }
    NSRange newRange = NSMakeRange([[self string] length], [string length]);

    [self doInsertString:string withRange:NSMakeRange([[self string] length], 0)
            withSelected:newRange withActionName:NSLocalizedString(@"Insert text", nil) scroll:NO];
}


// ------------------------------------------------------
- (void)insertCustomTextWithPatternNum:(NSInteger)patternNum
// カスタムキーバインドで文字列入力
// ------------------------------------------------------
{
    if (patternNum < 0) { return; }
    
    NSArray *texts = [[NSUserDefaults standardUserDefaults] arrayForKey:k_key_insertCustomTextArray];

    if (patternNum < (NSInteger)[texts count]) {
        NSString *string = texts[patternNum];
        NSRange selectedRange = [self selectedRange];
        NSRange newRange = NSMakeRange(selectedRange.location + [string length], 0);

        [self doInsertString:string withRange:selectedRange
                withSelected:newRange withActionName:NSLocalizedString(@"Insert custom text", nil) scroll:YES];
    }
}


// ------------------------------------------------------
- (void)resetFont:(id)sender
// フォントをリセット
// ------------------------------------------------------
{
    NSString *name = [[NSUserDefaults standardUserDefaults] stringForKey:k_key_fontName];
    CGFloat size = (CGFloat)[[NSUserDefaults standardUserDefaults] doubleForKey:k_key_fontSize];

    [self setFont:[NSFont fontWithName:name size:size]];
    [[self slaveView] setNeedsDisplay:YES];
    [self updateLineNumberAndAdjustScroll];
}


// ------------------------------------------------------
- (NSArray *)readablePasteboardTypes
// 読み取り可能なPasteboardタイプを返す
// ------------------------------------------------------
{
    NSMutableArray *types = [NSMutableArray arrayWithArray:[super readablePasteboardTypes]];

    [types addObject:NSFilenamesPboardType];
    return types;
}


// ------------------------------------------------------
- (NSArray *)pasteboardTypesForString
// 行末コード置換のためのPasteboardタイプ配列を返す
// ------------------------------------------------------
{
    return @[NSStringPboardType, @"public.utf8-plain-text"];
}


// ------------------------------------------------------
- (void)dragImage:(NSImage *)anImage at:(NSPoint)imageLoc offset:(NSSize)mouseOffset
            event:(NSEvent *)theEvent pasteboard:(NSPasteboard *)pboard
           source:(id)sourceObject slideBack:(BOOL)slideBack
// ドラッグする文字列の行末コードを書類に設定されたものに置換する
// ------------------------------------------------------
{
    [self replaceLineEndingToDocCharInPboard:pboard];
    [super dragImage:anImage at:imageLoc offset:mouseOffset
               event:theEvent pasteboard:pboard source:sourceObject slideBack:slideBack];
}


// ------------------------------------------------------
- (NSUInteger)dragOperationForDraggingInfo:(id <NSDraggingInfo>)dragInfo type:(NSString *)type
// 領域内でオブジェクトがドラッグされている
// ------------------------------------------------------
{
    if ([type isEqualToString:NSFilenamesPboardType]) {
        NSArray *fileDropArray = [[NSUserDefaults standardUserDefaults] arrayForKey:k_key_fileDropArray];
        NSColor *insertionPointColor = [NSUnarchiver unarchiveObjectWithData:[[NSUserDefaults standardUserDefaults] valueForKey:k_key_insertionPointColor]];
        for (id item in fileDropArray) {
            NSArray *array = [[dragInfo draggingPasteboard] propertyListForType:NSFilenamesPboardType];
            NSArray *extensions = [[item valueForKey:k_key_fileDropExtensions] componentsSeparatedByString:@", "];
            if ([self draggedItemsArray:array containsExtensionInExtensions:extensions]) {
                NSString *string = [self string];
                NSUInteger length = [string length];
                if (length > 0) {
                    // 挿入ポイントを自前で描画する
                    CGFloat partialFraction;
                    NSLayoutManager *layoutManager = [self layoutManager];
                    NSUInteger glyphIndex = [layoutManager glyphIndexForPoint:[self convertPoint:[dragInfo draggingLocation] fromView: nil]
                                                              inTextContainer:[self textContainer]
                                               fractionOfDistanceThroughGlyph:&partialFraction];
                    NSPoint glypthIndexPoint;
                    NSRect lineRect, insertionRect;
                    if ((partialFraction > 0.5) && 
                            (![[string substringWithRange:NSMakeRange(glyphIndex, 1)] isEqualToString:@"\n"])) {
                            NSRect glyphRect = [layoutManager boundingRectForGlyphRange:NSMakeRange(glyphIndex, 1)
                                                                        inTextContainer:[self textContainer]];
                            glypthIndexPoint = [layoutManager locationForGlyphAtIndex:glyphIndex];
                            glypthIndexPoint.x += NSWidth(glyphRect);
                    } else {
                        glypthIndexPoint = [layoutManager locationForGlyphAtIndex:glyphIndex];
                    }
                    lineRect = [layoutManager lineFragmentRectForGlyphAtIndex:glyphIndex effectiveRange:NULL];
                    insertionRect = NSMakeRect(glypthIndexPoint.x, lineRect.origin.y, 1, NSHeight(lineRect));
                    if (!NSEqualRects([self insertionRect], insertionRect)) {
                        // 古い自前挿入ポイントが描かれたままになることへの対応
                        [self setNeedsDisplayInRect:[self insertionRect] avoidAdditionalLayout:NO];
                    }
                    [insertionPointColor set];
                    [self lockFocus];
                    NSFrameRectWithWidth(insertionRect, 1.0);
                    [self unlockFocus];
                    [self setInsertionRect:insertionRect];
                }
                return NSDragOperationCopy;
            }
        }
        return NSDragOperationNone;
    }
    return [super dragOperationForDraggingInfo:dragInfo type:type];
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
        NSPasteboard *pboard = [sender draggingPasteboard];
        NSString *pboardType = [pboard availableTypeFromArray:[self pasteboardTypesForString]];
        if (pboardType != nil) {
            NSString *string = [pboard stringForType:pboardType];
            if (string != nil) {
                OgreNewlineCharacter newlineChar = [OGRegularExpression newlineCharacterInString:string];
                if ((newlineChar != OgreNonbreakingNewlineCharacter) &&
                    (newlineChar != OgreLfNewlineCharacter)) {
                    [pboard setString:[OGRegularExpression replaceNewlineCharactersInString:string
                                                                              withCharacter:OgreLfNewlineCharacter]
                              forType:pboardType];
                }
            }
        }
    }

    BOOL success = [super performDragOperation:sender];
    [self setIsSelfDrop:NO];

    return success;
}


// ------------------------------------------------------
- (BOOL)readSelectionFromPasteboard:(NSPasteboard *)pboard type:(NSString *)type
// ペーストまたはドロップされたアイテムに応じて挿入する文字列をNSPasteboardから読み込む
// ------------------------------------------------------
{
    // （このメソッドは、performDragOperation: 内で呼ばれる）

    BOOL success = NO;
    NSRange selectedRange, newRange;

    // 実行中フラグを立てる
    [self setIsReadingFromPboard:YES];

    // ペーストされたか、他からテキストがドロップされた
    if ((![self isSelfDrop]) && ([type isEqualToString:NSStringPboardType])) {
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

        NSString *pboardStr = [pboard stringForType:NSStringPboardType];
        if (pboardStr) {
            OgreNewlineCharacter newlineChar = [OGRegularExpression newlineCharacterInString:pboardStr];
            if ((newlineChar != OgreNonbreakingNewlineCharacter) &&
                (newlineChar != OgreLfNewlineCharacter)) {
                NSString *replacedStr = [OGRegularExpression replaceNewlineCharactersInString:pboardStr
                                                                                withCharacter:OgreLfNewlineCharacter];
                selectedRange = [self selectedRange];
                newRange = NSMakeRange(selectedRange.location + [replacedStr length], 0);
                // （Action名は自動で付けられる？ので、指定しない）
                [self doReplaceString:replacedStr withRange:selectedRange withSelected:newRange withActionName:@""];
                success = YES;
            }
        }

    // ファイルがドロップされた
    } else if ([type isEqualToString:NSFilenamesPboardType]) {
        NSArray *fileDropArray = [[NSUserDefaults standardUserDefaults] arrayForKey:k_key_fileDropArray];
        NSArray *files = [pboard propertyListForType:NSURLPboardType];
        NSURL *documentURL = [[[[self window] windowController] document] fileURL];
        NSString *fileName, *fileNoSuffix, *dirName;
        NSString *pathExtension = nil, *pathExtensionLower = nil, *pathExtensionUpper = nil;
        NSMutableString *relativePath = [NSMutableString string];
        NSMutableString *newStr = [NSMutableString string];
        NSInteger i, xtsnCount;
        NSInteger fileArrayCount = (NSInteger)[fileDropArray count];

        for (NSURL *absoluteURL in files) {
            selectedRange = [self selectedRange];
            for (xtsnCount = 0; xtsnCount < fileArrayCount; xtsnCount++) {
                NSArray *extensions = [[fileDropArray[xtsnCount] valueForKey:k_key_fileDropExtensions]
                                       componentsSeparatedByString:@", "];
                pathExtension = [absoluteURL pathExtension];
                pathExtensionLower = [pathExtension lowercaseString];
                pathExtensionUpper = [pathExtension uppercaseString];

                if (([extensions containsObject:pathExtensionLower]) 
                        || ([extensions containsObject:pathExtensionUpper])) {

                    [newStr setString:[fileDropArray[xtsnCount] 
                                valueForKey:k_key_fileDropFormatString]];
                } else {
                    continue;
                }
            }
            if ([newStr length] > 0) {
                if ((documentURL != nil) && (![[documentURL path] isEqualToString:[absoluteURL path]])) {
                    NSArray *docPathArray = [documentURL pathComponents];
                    NSArray *pathArray = [absoluteURL pathComponents];
                    NSMutableString *tmpStr = [NSMutableString string];
                    NSInteger j, theSame = 0, count = 0;
                    NSInteger docArrayCount = (NSInteger)[docPathArray count];
                    NSInteger pathArrayCount = (NSInteger)[pathArray count];

                    for (j = 0; j < docArrayCount; j++) {
                        if (![docPathArray[j] isEqualToString:pathArray[j]]) {
                            theSame = j;
                            count = [docPathArray count] - theSame - 1;
                            break;
                        }
                    }
                    for (j = count; j > 0; j--) {
                        [tmpStr appendString:@"../"];
                    }
                    for (j = theSame; j < pathArrayCount; j++) {
                        if ([tmpStr length] > 0) {
                            [tmpStr appendString:@"/"];
                        }
                        [tmpStr appendString:pathArray[j]];
                    }
                    [relativePath setString:[tmpStr stringByStandardizingPath]];
                } else {
                    [relativePath setString:[absoluteURL path]];
                }
                fileName = [absoluteURL lastPathComponent];
                fileNoSuffix = [fileName stringByDeletingPathExtension];
                dirName = [[absoluteURL URLByDeletingLastPathComponent] lastPathComponent];
                (void)[newStr replaceOccurrencesOfString:@"<<<ABSOLUTE-PATH>>>"
                                              withString:[absoluteURL path] options:0 range:NSMakeRange(0, [newStr length])];
                (void)[newStr replaceOccurrencesOfString:@"<<<RELATIVE-PATH>>>"
                                              withString:relativePath options:0 range:NSMakeRange(0, [newStr length])];
                (void)[newStr replaceOccurrencesOfString:@"<<<FILENAME>>>"
                                              withString:fileName options:0 range:NSMakeRange(0, [newStr length])];
                (void)[newStr replaceOccurrencesOfString:@"<<<FILENAME-NOSUFFIX>>>"
                                              withString:fileNoSuffix options:0 range:NSMakeRange(0, [newStr length])];
                (void)[newStr replaceOccurrencesOfString:@"<<<FILEEXTENSION>>>"
                                              withString:pathExtension options:0 range:NSMakeRange(0, [newStr length])];
                (void)[newStr replaceOccurrencesOfString:@"<<<FILEEXTENSION-LOWER>>>"
                                              withString:pathExtensionLower options:0 range:NSMakeRange(0, [newStr length])];
                (void)[newStr replaceOccurrencesOfString:@"<<<FILEEXTENSION-UPPER>>>"
                                              withString:pathExtensionUpper options:0 range:NSMakeRange(0, [newStr length])];
                (void)[newStr replaceOccurrencesOfString:@"<<<DIRECTORY>>>"
                                              withString:dirName options:0 range:NSMakeRange(0, [newStr length])];
                NSImageRep *imageRep = [NSImageRep imageRepWithContentsOfURL:absoluteURL];
                if (imageRep) {
                    // NSImage の size では dpi をも考慮されたサイズが返ってきてしまうので NSImageRep を使う
                    (void)[newStr replaceOccurrencesOfString:@"<<<IMAGEWIDTH>>>"
                                                  withString:[NSString stringWithFormat:@"%li", (long)[imageRep pixelsWide]]
                                                     options:0 range:NSMakeRange(0, [newStr length])];
                    (void)[newStr replaceOccurrencesOfString:@"<<<IMAGEHEIGHT>>>"
                                                  withString:[NSString stringWithFormat:@"%li", (long)[imageRep pixelsHigh]]
                                                     options:0 range:NSMakeRange(0, [newStr length])];
                }
                // （ファイルをドロップしたときは、挿入文字列全体を選択状態にする）
                newRange = NSMakeRange(selectedRange.location, [newStr length]);
                // （Action名は自動で付けられる？ので、指定しない）
                [self doReplaceString:newStr withRange:selectedRange withSelected:newRange withActionName:@""];
                // 挿入後、選択範囲を移動させておかないと複数オブジェクトをドロップされた時に重ね書きしてしまう
                [self setSelectedRange:NSMakeRange(NSMaxRange(newRange), 0)];
                success = YES;
            }
        }
    }
    if (success == NO) {
        success = [super readSelectionFromPasteboard:pboard type:type];
    }
    [self setIsReadingFromPboard:NO];

    return success;
}


// ------------------------------------------------------
- (NSRange)selectionRangeForProposedRange:(NSRange)proposedSelRange granularity:(NSSelectionGranularity)granularity
// マウスでのテキスト選択時の挙動を制御、ダブルクリックでの括弧内選択機能を追加
// ------------------------------------------------------
{
// このメソッドは、Smultron のものを使用させていただきました。(2006.09.09)
// This method is based on Smultron.(written by Peter Borg – http://smultron.sourceforge.net)
// Smultron  Copyright (c) 2004-2005 Peter Borg, All rights reserved.
// Smultron is released under GNU General Public License, http://www.gnu.org/copyleft/gpl.html

	if (granularity != NSSelectByWord || [[self string] length] == proposedSelRange.location) {// If it's not a double-click return unchanged
		return [super selectionRangeForProposedRange:proposedSelRange granularity:granularity];
	}
	
	NSInteger location = [super selectionRangeForProposedRange:proposedSelRange granularity:NSSelectByCharacter].location;
	NSInteger originalLocation = location;

	NSString *completeString = [self string];
	unichar characterToCheck = [completeString characterAtIndex:location];
	NSUInteger skipMatchingBrace = 0;
	NSInteger lengthOfString = [completeString length];
	if (lengthOfString == (NSInteger)proposedSelRange.location) { // To avoid crash if a double-click occurs after any text
		return [super selectionRangeForProposedRange:proposedSelRange granularity:granularity];
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
		return [super selectionRangeForProposedRange:NSMakeRange(proposedSelRange.location, 1) granularity:NSSelectByCharacter];
	} else {
		return [super selectionRangeForProposedRange:proposedSelRange granularity:granularity];
	}
}


// ------------------------------------------------------
- (void)setNewLineSpacingAndUpdate:(CGFloat)lineSpacing
// 行間値をセットし、テキストと行番号を再描画
// ------------------------------------------------------
{
    if (lineSpacing != [self lineSpacing]) {
        NSRange range = NSMakeRange(0, [[self string] length]);

        [self setLineSpacing:lineSpacing];
        // テキストを再描画
        [[self layoutManager] invalidateLayoutForCharacterRange:range isSoft:NO actualCharacterRange:nil];
        [self updateLineNumberAndAdjustScroll];
    }
}


// ------------------------------------------------------
- (void)doReplaceString:(NSString *)string withRange:(NSRange)range
           withSelected:(NSRange)selection withActionName:(NSString *)actionName
// 置換を実行
// ------------------------------------------------------
{
    NSString *newStr = [string copy];
    NSString *curStr = [[self string] substringWithRange:range];

    // regist Undo
    id document = [[[self window] windowController] document];
    NSUndoManager *undoManager = [self undoManager];
    NSRange newRange = NSMakeRange(range.location, [string length]); // replaced range after method.

    [[undoManager prepareWithInvocationTarget:self] redoReplaceString:newStr withRange:range
                                                         withSelected:selection withActionName:actionName]; // redo in undo
    [[undoManager prepareWithInvocationTarget:self] setSelectedRange:[self selectedRange]]; // select current selection.
    [[undoManager prepareWithInvocationTarget:self] didChangeText]; // post notification.
    [[undoManager prepareWithInvocationTarget:[self textStorage]] replaceCharactersInRange:newRange withString:curStr];
    [[undoManager prepareWithInvocationTarget:document] updateChangeCount:NSChangeUndone]; // to decrement changeCount.
    if ([actionName length] > 0) {
        [undoManager setActionName:actionName];
    }
    BOOL shouldSetAttrs = ([[self string] length] == 0);
    [[self textStorage] beginEditing];
    [[self textStorage] replaceCharactersInRange:range withString:newStr];
    if (shouldSetAttrs) { // 文字列がない場合に AppleScript から文字列を追加されたときに Attrs が適用されないことへの対応
        [[self textStorage] setAttributes:[self typingAttrs]
                                    range:NSMakeRange(0, [[[self textStorage] string] length])];
    }
    [[self textStorage] endEditing];
    // テキストの編集ノーティフィケーションをポスト（ここでは NSTextStorage を編集しているため自動ではポストされない）
    [self didChangeText];
    // 選択範囲を変更、アンドゥカウントを増やす
    [self setSelectedRange:selection];
    [document updateChangeCount:NSChangeDone];
}


// ------------------------------------------------------
- (void)selectTextRangeValue:(NSValue *)rangeValue
// 文字列を選択
// ------------------------------------------------------
{
    [self setSelectedRange:[rangeValue rangeValue]];
}



#pragma mark Protocol

//=======================================================
// NSNibAwaking Protocol
//
//=======================================================

// ------------------------------------------------------
- (BOOL)validateMenuItem:(NSMenuItem *)menuItem
// メニューの有効／無効を制御
// ------------------------------------------------------
{
    NSUInteger length = [self selectedRange].length;

    if (([menuItem action] == @selector(exchangeLowercase:)) || 
            ([menuItem action] == @selector(exchangeUppercase:)) || 
            ([menuItem action] == @selector(exchangeCapitalized:)) || 
            ([menuItem action] == @selector(exchangeFullwidthRoman:)) || 
            ([menuItem action] == @selector(exchangeHalfwidthRoman:)) || 
            ([menuItem action] == @selector(exchangeKatakana:)) || 
            ([menuItem action] == @selector(exchangeHiragana:)) || 
            ([menuItem action] == @selector(unicodeNormalizationNFD:)) || 
            ([menuItem action] == @selector(unicodeNormalizationNFC:)) || 
            ([menuItem action] == @selector(unicodeNormalizationNFKD:)) || 
            ([menuItem action] == @selector(unicodeNormalizationNFKC:)) || 
            ([menuItem action] == @selector(unicodeNormalization:))) {
        return (length > 0);
        // （カラーコード編集メニューは常に有効）

    } else if ([menuItem action] == @selector(setLineSpacingFromMenu:)) {
        [menuItem setState:(([self lineSpacing] == (CGFloat)[[menuItem title] doubleValue]) ? NSOnState : NSOffState)];
    }

    return [super validateMenuItem:menuItem];
}



#pragma mark Action Messages

//=======================================================
// Action messages
//
//=======================================================

// ------------------------------------------------------
- (IBAction)shiftRight:(id)sender
// 右へシフト
// ------------------------------------------------------
{
    // 現在の選択区域とシフトする行範囲を得る
    NSRange selectedRange = [self selectedRange];
    NSRange lineRange = [[self string] lineRangeForRange:selectedRange];

    if (lineRange.length > 1) {
        lineRange.length--; // 最末尾の改行分を減ずる
    }
    // シフトするために挿入する文字列と長さを得る
    NSMutableString *shiftStr = [NSMutableString string];
    NSUInteger shiftLength = 0;
    if ([[NSUserDefaults standardUserDefaults] boolForKey:k_key_autoExpandTab]) {
        NSUInteger tabWidth = [[NSUserDefaults standardUserDefaults] integerForKey:k_key_tabWidth];
        shiftLength = tabWidth;
        while (tabWidth--) {
            [shiftStr appendString:@" "];
        }
    } else {
        shiftLength = 1;
        [shiftStr setString:@"\t"];
    }
    if (shiftLength < 1) { return; }

    // 置換する行を生成する
    NSMutableString *newLine = [NSMutableString stringWithString:[[self string] substringWithRange:lineRange]];
    NSString *newStr = [NSString stringWithFormat:@"%@%@", @"\n", shiftStr];
    NSUInteger lines = [newLine replaceOccurrencesOfString:@"\n"
                                                withString:newStr
                                                   options:0
                                                     range:NSMakeRange(0, [newLine length])];
    [newLine insertString:shiftStr atIndex:0];
    // 置換後の選択位置の調整
    NSUInteger newLocation;
    if ((lineRange.location == selectedRange.location) && (selectedRange.length > 0) &&
        ([[[self string] substringWithRange:selectedRange] hasSuffix:@"\n"]))
    {
        // 行頭から行末まで選択されていたときは、処理後も同様に選択する
        newLocation = selectedRange.location;
        lines++;
    } else {
        newLocation = selectedRange.location + shiftLength;
    }
    // 置換実行
    [self doReplaceString:newLine withRange:lineRange
             withSelected:NSMakeRange(newLocation, selectedRange.length + shiftLength * lines)
           withActionName:NSLocalizedString(@"Shift Right", nil)];
}


// ------------------------------------------------------
- (IBAction)shiftLeft:(id)sender
// 左へシフト
// ------------------------------------------------------
{
    // 現在の選択区域とシフトする行範囲を得る
    NSRange selectedRange = [self selectedRange];
    NSRange lineRange = [[self string] lineRangeForRange:selectedRange];
    if (NSMaxRange(lineRange) == 0) { // 空行で実行された場合は何もしない
        return;
    }
    if ((lineRange.length > 1) &&
        ([[[self string] substringWithRange:NSMakeRange(NSMaxRange(lineRange) - 1, 1)] isEqualToString:@"\n"]))
    {
        lineRange.length--; // 末尾の改行分を減ずる
    }
    // シフトするために削除するスペースの長さを得る
    NSInteger shiftLength = [[NSUserDefaults standardUserDefaults] integerForKey:k_key_tabWidth];
    if (shiftLength < 1) { return; }

    // 置換する行を生成する
    NSArray *lines = [[[self string] substringWithRange:lineRange] componentsSeparatedByString:@"\n"];
    NSMutableString *newLine = [NSMutableString string];
    NSMutableString *tmpLine = [NSMutableString string];
    NSString *string;
    BOOL spaceDeleted;
    NSUInteger numberOfDeleted = 0, totalDeleted = 0;
    NSInteger newLocation = selectedRange.location, newLength = selectedRange.length;
    NSUInteger i, j, count = [lines count];

    // 選択区域を含む行をスキャンし、冒頭のスペース／タブを削除
    for (i = 0; i < count; i++) {
        [tmpLine setString:lines[i]];
        spaceDeleted = NO;
        for (j = 0; j < shiftLength; j++) {
            if ([tmpLine length] == 0) {
                break;
            }
            string = [lines[i] substringWithRange:NSMakeRange(j, 1)];
            if ([string isEqualToString:@"\t"]) {
                if (!spaceDeleted) {
                    [tmpLine deleteCharactersInRange:NSMakeRange(0, 1)];
                    numberOfDeleted++;
                }
                break;
            } else if ([string isEqualToString:@" "]) {
                [tmpLine deleteCharactersInRange:NSMakeRange(0, 1)];
                numberOfDeleted++;
                spaceDeleted = YES;
            } else {
                break;
            }
        }
        // 処理後の選択区域用の値を算出
        if (i == 0) {
            newLocation -= numberOfDeleted;
            if (newLocation < (NSInteger)lineRange.location) {
                newLength -= (lineRange.location - newLocation);
                newLocation = lineRange.location;
            }
        } else {
            newLength -= numberOfDeleted;
            if (newLength < (NSInteger)lineRange.location - newLocation + (NSInteger)[newLine length]) {
                newLength = lineRange.location - newLocation + [newLine length];
            }
        }
        // 冒頭のスペース／タブを削除した行を合成
        [newLine appendString:tmpLine];
        if (i != ((NSInteger)[lines count] - 1)) {
            [newLine appendString:@"\n"];
        }
        totalDeleted += numberOfDeleted;
        numberOfDeleted = 0;
    }
    // シフトされなかったら中止
    if (totalDeleted == 0) { return; }
    if (newLocation < 0) {
        newLocation = 0;
    }
    if (newLength < 0) {
        newLength = 0;
    }
    // 置換実行
    [self doReplaceString:newLine withRange:lineRange
             withSelected:NSMakeRange(newLocation, newLength) withActionName:NSLocalizedString(@"Shift Left", nil)];
}


// ------------------------------------------------------
- (IBAction)exchangeLowercase:(id)sender
// 小文字へ変更
// ------------------------------------------------------
{
    NSRange selectedRange = [self selectedRange];

    if (selectedRange.length > 0) {
        NSString *newStr = [[[self string] substringWithRange:selectedRange] lowercaseString];
        if (newStr) {
            NSRange newRange = NSMakeRange(selectedRange.location, [newStr length]);
            [self doInsertString:newStr withRange:selectedRange 
                    withSelected:newRange withActionName:NSLocalizedString(@"to Lowercase", nil) scroll:YES];
        }
    }
}


// ------------------------------------------------------
- (IBAction)exchangeUppercase:(id)sender
// 大文字へ変更
// ------------------------------------------------------
{
    NSRange selectedRange = [self selectedRange];

    if (selectedRange.length > 0) {
        NSString *newStr = [[[self string] substringWithRange:selectedRange] uppercaseString];
        if (newStr) {
            NSRange newRange = NSMakeRange(selectedRange.location, [newStr length]);
            [self doInsertString:newStr withRange:selectedRange 
                    withSelected:newRange withActionName:NSLocalizedString(@"to Uppercase", nil) scroll:YES];
        }
    }
}


// ------------------------------------------------------
- (IBAction)exchangeCapitalized:(id)sender
// 単語の頭を大文字へ変更
// ------------------------------------------------------
{
    NSRange selectedRange = [self selectedRange];

    if (selectedRange.length > 0) {
        NSString *newStr = [[[self string] substringWithRange:selectedRange] capitalizedString];
        if (newStr) {
            NSRange newRange = NSMakeRange(selectedRange.location, [newStr length]);
            [self doInsertString:newStr withRange:selectedRange
                    withSelected:newRange withActionName:NSLocalizedString(@"to Capitalized", nil) scroll:YES];
        }
    }
}


// ------------------------------------------------------
- (IBAction)exchangeFullwidthRoman:(id)sender
// 全角Roman文字へ変更
// ------------------------------------------------------
{
    NSRange selectedRange = [self selectedRange];

    if (selectedRange.length > 0) {
        NSString *newStr = [self halfToFullwidthRomanStringFrom:[[self string] substringWithRange:selectedRange]];
        if (newStr) {
            NSRange newRange = NSMakeRange(selectedRange.location, [newStr length]);
            [self doInsertString:newStr withRange:selectedRange 
                    withSelected:newRange withActionName:NSLocalizedString(@"to Fullwidth (jp/Roman)", nil) scroll:YES];
        }
    }
}


// ------------------------------------------------------
- (IBAction)exchangeHalfwidthRoman:(id)sender
// 半角Roman文字へ変更
// ------------------------------------------------------
{
    NSRange selectedRange = [self selectedRange];

    if (selectedRange.length > 0) {
        NSString *newStr = 
                [self fullToHalfwidthRomanStringFrom:[[self string] substringWithRange:selectedRange]];
        if (newStr) {
            NSRange newRange = NSMakeRange(selectedRange.location, [newStr length]);
            [self doInsertString:newStr withRange:selectedRange 
                    withSelected:newRange withActionName:NSLocalizedString(@"to Halfwidth (jp/Roman)", nil) scroll:YES];
        }
    }
}


// ------------------------------------------------------
- (IBAction)exchangeKatakana:(id)sender
// ひらがなをカタカナへ変更
// ------------------------------------------------------
{
    NSRange selectedRange = [self selectedRange];

    if (selectedRange.length > 0) {
        NSString *newStr = [self hiraganaToKatakanaStringFrom:[[self string] substringWithRange:selectedRange]];
        if (newStr) {
            NSRange newRange = NSMakeRange(selectedRange.location, [newStr length]);
            [self doInsertString:newStr withRange:selectedRange 
                    withSelected:newRange withActionName:NSLocalizedString(@"Hiragana to Katakana (jp)",@"") scroll:YES];
        }
    }
}


// ------------------------------------------------------
- (IBAction)exchangeHiragana:(id)sender
// カタカナをひらがなへ変更
// ------------------------------------------------------
{
    NSRange selectedRange = [self selectedRange];

    if (selectedRange.length > 0) {
        NSString *newStr = 
                [self katakanaToHiraganaStringFrom:[[self string] substringWithRange:selectedRange]];
        if (newStr) {
            NSRange newRange = NSMakeRange(selectedRange.location, [newStr length]);
            [self doInsertString:newStr withRange:selectedRange
                    withSelected:newRange withActionName:NSLocalizedString(@"Katakana to Hiragana (jp)",@"") scroll:YES];
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
    NSRange selectedRange = [self selectedRange];
    NSInteger switchType;

    if ([sender isKindOfClass:[NSMenuItem class]]) {
        switchType = [sender tag];
    } else if ([sender isKindOfClass:[NSNumber class]]) {
        switchType = [sender integerValue];
    } else {
        return;
    }
    if (selectedRange.length > 0) {
        NSString *actionName = nil, *newStr = nil, *originalStr = [[self string] substringWithRange:selectedRange];

        switch (switchType) {
        case 0: // from D
            newStr = [originalStr decomposedStringWithCanonicalMapping];
            actionName = [NSString stringWithString:NSLocalizedString(@"NFD", nil)];
            break;
        case 1: // from C
            newStr = [originalStr precomposedStringWithCanonicalMapping];
            actionName = [NSString stringWithString:NSLocalizedString(@"NFC", nil)];
            break;
        case 2: // from KD
            newStr = [originalStr decomposedStringWithCompatibilityMapping];
            actionName = [NSString stringWithString:NSLocalizedString(@"NFKD", nil)];
            break;
        case 3: // from KC
            newStr = [originalStr precomposedStringWithCompatibilityMapping];
            actionName = [NSString stringWithString:NSLocalizedString(@"NFKC", nil)];
            break;
        default:
            break;
            return;
        }
        if (newStr) {
            NSRange newRange = NSMakeRange(selectedRange.location, [newStr length]);
            [self doInsertString:newStr withRange:selectedRange 
                    withSelected:newRange withActionName:actionName scroll:YES];
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
    NSString *curStr = [[self string] substringWithRange:[self selectedRange]];

    [[CEColorCodePanelController sharedController] showWindow:sender];
    [[CEColorCodePanelController sharedController] importHexColorCodeAsForeColor:curStr];
}


// ------------------------------------------------------
- (IBAction)editHexColorCodeAsBGColor:(id)sender
// Hex Color Code を文字色として編集ウィンドウへ取り込む
// ------------------------------------------------------
{
    NSString *curStr = [[self string] substringWithRange:[self selectedRange]];
    
    [[CEColorCodePanelController sharedController] showWindow:sender];
    [[CEColorCodePanelController sharedController] importHexColorCodeAsBackColor:curStr];
}


// ------------------------------------------------------
- (IBAction)setSelectedRangeWithNSValue:(id)sender
// アウトラインメニュー選択によるテキスト選択を実行
// ------------------------------------------------------
{
    NSValue *value = [sender representedObject];
    if (value) {
        NSRange range = [value rangeValue];

        [self setUpdateOutlineMenuItemSelection:NO]; // 選択範囲変更後にメニュー選択項目が再選択されるオーバーヘッドを省く
        [self setSelectedRange:range];
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




#pragma mark Private Mthods

// ------------------------------------------------------
- (void)redoReplaceString:(NSString *)string withRange:(NSRange)range 
            withSelected:(NSRange)selection withActionName:(NSString *)actionName
// 文字列置換のリドゥーを登録
// ------------------------------------------------------
{
    [[[self undoManager] prepareWithInvocationTarget:self]
        doReplaceString:string withRange:range withSelected:selection withActionName:actionName];
}


// ------------------------------------------------------
- (void)doInsertString:(NSString *)string withRange:(NSRange)range 
            withSelected:(NSRange)selection withActionName:(NSString *)actionName scroll:(BOOL)doScroll
// 置換実行
// ------------------------------------------------------
{
    NSUndoManager *undoManager = [self undoManager];

    // 一時的にイベントごとのグループを作らないようにする
    // （でないと、グルーピングするとchangeCountが余分にカウントされる）
    [undoManager setGroupsByEvent:NO];

    // それ以前のキー入力と分離するため、グルーピング
    // CEDocument > writeWithBackupToFile:ofType:saveOperation:でも同様の処理を行っている (2008.06.01)
    [undoManager beginUndoGrouping];
    [self setSelectedRange:range];
    [super insertText:[string copy]];
    [self setSelectedRange:selection];
    if (doScroll) {
        [self scrollRangeToVisible:selection];
    }
    if ([actionName length] > 0) {
        [undoManager setActionName:actionName];
    }
    [undoManager endUndoGrouping];
    [undoManager setGroupsByEvent:YES]; // イベントごとのグループ作成設定を元に戻す
}


// ------------------------------------------------------
- (NSString *)halfToFullwidthRomanStringFrom:(NSString *)halfRoman
// 半角Romanを全角Romanへ変換
// ------------------------------------------------------
{
    NSMutableString *fullRoman = [NSMutableString string];
    NSCharacterSet *latinCharSet = [NSCharacterSet characterSetWithRange:NSMakeRange((NSUInteger)'!', 94)];
    unichar theChar;
    NSUInteger i, count = [halfRoman length];

    for (i = 0; i < count; i++) {
        theChar = [halfRoman characterAtIndex:i];
        if ([latinCharSet characterIsMember:theChar]) {
            [fullRoman appendString:[NSString stringWithFormat:@"%C", (unichar)(theChar + 65248)]];
// 半角カナには未対応（2/21） *********************
//        } else if ([theHankakuKanaCharSet characterIsMember:theChar]) {
//            [fullString appendString:[NSString stringWithFormat:@"%C", (unichar)(theChar + 65248)]];
        } else {
            [fullRoman appendString:[halfRoman substringWithRange:NSMakeRange(i, 1)]];
        }
    }
    return fullRoman;
}


// ------------------------------------------------------
- (NSString *)fullToHalfwidthRomanStringFrom:(NSString *)fullRoman
// 全角Romanを半角Romanへ変換
// ------------------------------------------------------
{
    NSMutableString *halfRoman = [NSMutableString string];
    NSCharacterSet *fullwidthCharSet = [NSCharacterSet characterSetWithRange:NSMakeRange(65281, 94)];
    unichar theChar;
    NSUInteger i, count = [fullRoman length];

    for (i = 0; i < count; i++) {
        theChar = [fullRoman characterAtIndex:i];
        if ([fullwidthCharSet characterIsMember:theChar]) {
            [halfRoman appendString:[NSString stringWithFormat:@"%C", (unichar)(theChar - 65248)]];
        } else {
            [halfRoman appendString:[fullRoman substringWithRange:NSMakeRange(i, 1)]];
        }
    }
    return halfRoman;
}


// ------------------------------------------------------
- (NSString *)hiraganaToKatakanaStringFrom:(NSString *)hiragana
// ひらがなをカタカナへ変換
// ------------------------------------------------------
{
    NSMutableString *katakana = [NSMutableString string];
    NSCharacterSet *hiraganaCharSet = [NSCharacterSet characterSetWithRange:NSMakeRange(12353, 86)];
    unichar theChar;
    NSUInteger i, count = [hiragana length];

    for (i = 0; i < count; i++) {
        theChar = [hiragana characterAtIndex:i];
        if ([hiraganaCharSet characterIsMember:theChar]) {
            [katakana appendString:[NSString stringWithFormat:@"%C", (unichar)(theChar + 96)]];
        } else {
            [katakana appendString:[hiragana substringWithRange:NSMakeRange(i, 1)]];
        }
    }
    return katakana;
}


// ------------------------------------------------------
- (NSString *)katakanaToHiraganaStringFrom:(NSString *)katakana
// カタカナをひらがなへ変換
// ------------------------------------------------------
{
    NSMutableString *hiragana = [NSMutableString string];
    NSCharacterSet *katakanaCharSet = [NSCharacterSet characterSetWithRange:NSMakeRange(12449, 86)];
    unichar theChar;
    NSUInteger i, count = [katakana length];

    for (i = 0; i < count; i++) {
        theChar = [katakana characterAtIndex:i];
        if ([katakanaCharSet characterIsMember:theChar]) {
            [hiragana appendString:[NSString stringWithFormat:@"%C", (unichar)(theChar - 96)]];
        } else {
            [hiragana appendString:[katakana substringWithRange:NSMakeRange(i, 1)]];
        }
    }
    return hiragana;
}


// ------------------------------------------------------
- (BOOL)draggedItemsArray:(NSArray *)items containsExtensionInExtensions:(NSArray *)extensions
// ドラッグされているアイテムのNSFilenamesPboardTypeに指定された拡張子のものが含まれているかどうかを返す
// ------------------------------------------------------
{
    if ([items count] > 0) {
        for (NSString *extension in extensions) {
            for (id item in items) {
                if ([[item pathExtension] isEqualToString:extension]) {
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
- (void)replaceLineEndingToDocCharInPboard:(NSPasteboard *)pboard
// Pasetboard内文字列の行末コードを書類に設定されたものに置換する
// ------------------------------------------------------
{
    if (pboard == nil) { return; }

    OgreNewlineCharacter newlineChar = [[(CESubSplitView *)[self delegate] editorView] lineEndingCharacter];

    if (newlineChar != OgreLfNewlineCharacter) {
        NSString *pboardType = [pboard availableTypeFromArray:[self pasteboardTypesForString]];
        if (pboardType) {
            NSString *string = [pboard stringForType:pboardType];

            if (string) {
                [pboard setString:[OGRegularExpression replaceNewlineCharactersInString:string withCharacter:newlineChar]
                          forType:pboardType];
            }
        }
    }
}


// ------------------------------------------------------
- (CGFloat)tabIntervalFromFont:(NSFont *)font
// フォントからタブ幅を計算して返す
// ------------------------------------------------------
{
    NSMutableString *widthStr = [[NSMutableString alloc] init];
    NSUInteger numberOfSpaces = [[NSUserDefaults standardUserDefaults] integerForKey:k_key_tabWidth];
    while (numberOfSpaces--) {
        [widthStr appendString:@" "];
    }
    return [widthStr sizeWithAttributes:@{NSFontAttributeName:font}].width;
}

@end
