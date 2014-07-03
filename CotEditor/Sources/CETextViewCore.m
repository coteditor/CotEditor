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
#import "CEGlyphPopoverController.h"
#import "constants.h"


@interface CETextViewCore ()

@property (nonatomic) NSRect insertionRect;
@property (nonatomic) NSPoint textContainerOriginPoint;
@property (nonatomic) NSMutableParagraphStyle *paragraphStyle;


// readonly
@property (nonatomic, readwrite) NSColor *highlightLineColor;  // カレント行ハイライト色

@end




#pragma mark -

@implementation CETextViewCore

#pragma mark NSTextView Methods

//=======================================================
// NSTextView method
//
//=======================================================

// ------------------------------------------------------
/// 初期化
- (instancetype)initWithFrame:(NSRect)frameRect textContainer:(NSTextContainer *)inTextContainer
// ------------------------------------------------------
{
    self = [super initWithFrame:frameRect textContainer:inTextContainer];
    if (self) {
        // このメソッドはSmultronのSMLTextViewを参考にしています。
        // This method is based on Smultron(SMLTextView) written by Peter Borg. Copyright (C) 2004 Peter Borg.
        // http://smultron.sourceforge.net
        // set the width of every tab by first checking the size of the tab in spaces in the current font and then remove all tabs that sets automatically and then set the default tab stop distance
        NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
        
        [self setTabWidth:[defaults integerForKey:k_key_tabWidth]];
        
        NSFont *font = [NSFont fontWithName:[defaults stringForKey:k_key_fontName]
                                       size:(CGFloat)[defaults doubleForKey:k_key_fontSize]];

        NSMutableParagraphStyle *paragraphStyle = [[NSParagraphStyle defaultParagraphStyle] mutableCopy];
        for (NSTextTab *textTabToBeRemoved in [paragraphStyle tabStops]) {
            [paragraphStyle removeTabStop:textTabToBeRemoved];
        }
        [paragraphStyle setDefaultTabInterval:[self tabIntervalFromFont:font]];
        [self setParagraphStyle:paragraphStyle];
        // （NSParagraphStyle の lineSpacing を設定すればテキスト描画時の行間は制御できるが、
        // 「文書の1文字目に1バイト文字（または2バイト文字）を入力してある状態で先頭に2バイト文字（または1バイト文字）を
        // 挿入すると行間がズレる」問題が生じるため、CELayoutManager および CEATSTypesetter で制御している）

        // テーマの設定
        [self setTheme:[CETheme themeWithName:[defaults stringForKey:k_key_defaultTheme]]];
        
        // set the values
        [self setIsAutoTabExpandEnabled:[defaults boolForKey:k_key_autoExpandTab]];
        [self setSmartInsertDeleteEnabled:[defaults boolForKey:k_key_smartInsertAndDelete]];
        [self setContinuousSpellCheckingEnabled:[defaults boolForKey:k_key_checkSpellingAsType]];
        if ([self respondsToSelector:@selector(setAutomaticQuoteSubstitutionEnabled:)]) {  // only on OS X 10.9 and later
            [self setAutomaticQuoteSubstitutionEnabled:[defaults boolForKey:k_key_enableSmartQuotes]];
            [self setAutomaticDashSubstitutionEnabled:[defaults boolForKey:k_key_enableSmartQuotes]];
        }
        [self setBackgroundAlpha:(CGFloat)[defaults doubleForKey:k_key_windowAlpha]];
        [self setFont:font];
        [self setMinSize:frameRect.size];
        [self setMaxSize:NSMakeSize(FLT_MAX, FLT_MAX)];
        [self setAllowsDocumentBackgroundColorChange:NO];
        [self setAllowsUndo:YES];
        [self setRichText:NO];
        [self setImportsGraphics:NO];
        [self setUsesFindPanel:YES];
        [self setHorizontallyResizable:YES];
        [self setVerticallyResizable:YES];
        [self setAcceptsGlyphInfo:YES];
        [self setLineSpacing:(CGFloat)[defaults doubleForKey:k_key_lineSpacing]];
        [self setInsertionRect:NSZeroRect];
        [self setTextContainerOriginPoint:NSMakePoint((CGFloat)[defaults doubleForKey:k_key_textContainerInsetWidth],
                                                      (CGFloat)[defaults doubleForKey:k_key_textContainerInsetHeightTop])];
        [self setUpdateOutlineMenuItemSelection:YES];
        [self setHighlightLineAdditionalRect:NSZeroRect];
        
        [self applyTypingAttributes];
        
        // 設定の変更を監視
        for (NSString *key in [self observedDefaultKeys]) {
            [[NSUserDefaults standardUserDefaults] addObserver:self
                                                    forKeyPath:key
                                                       options:NSKeyValueObservingOptionNew
                                                       context:NULL];
        }
    }

    return self;
}


// ------------------------------------------------------
/// 後片付け
- (void)dealloc
// ------------------------------------------------------
{
    for (NSString *key in [self observedDefaultKeys]) {
        [[NSUserDefaults standardUserDefaults] removeObserver:self forKeyPath:key];
    }
}


// ------------------------------------------------------
/// ユーザ設定の変更を反映する
-(void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context
// ------------------------------------------------------
{
    id newValue = change[NSKeyValueChangeNewKey];
    
    if ([keyPath isEqualToString:k_key_autoExpandTab]) {
        [self setIsAutoTabExpandEnabled:[newValue boolValue]];
        
    } else if ([keyPath isEqualToString:k_key_smartInsertAndDelete]) {
        [self setSmartInsertDeleteEnabled:[newValue boolValue]];
        
    } else if ([keyPath isEqualToString:k_key_checkSpellingAsType]) {
        [self setContinuousSpellCheckingEnabled:[newValue boolValue]];
        
    } else if ([keyPath isEqualToString:k_key_enableSmartQuotes]) {
        if ([self respondsToSelector:@selector(setAutomaticQuoteSubstitutionEnabled:)]) {  // only on OS X 10.9 and later
            [self setAutomaticQuoteSubstitutionEnabled:[newValue boolValue]];
            [self setAutomaticDashSubstitutionEnabled:[newValue boolValue]];
        }
        
    } else if ([keyPath isEqualToString:k_key_windowAlpha]) {
        [self setBackgroundAlpha:(CGFloat)[newValue doubleValue]];
    }
}


// ------------------------------------------------------
/// first responder になれるかを返す  !!!: Deprecated on 10.4
- (BOOL)becomeFirstResponder
// ------------------------------------------------------
{
    [(CESubSplitView *)[self delegate] setTextViewToEditorView:self];

    return [super becomeFirstResponder];
}


// ------------------------------------------------------
/// キー押下を取得
- (void)keyDown:(NSEvent *)theEvent
// ------------------------------------------------------
{
    NSString *charIgnoringMod = [theEvent charactersIgnoringModifiers];
    // IM で日本語入力変換中でないときのみ追加テキストキーバインディングを実行
    if (![self hasMarkedText] && (charIgnoringMod != nil)) {
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
        
        // 縦書きのときの矢印キー移動を乗っ取る
        if (([self layoutOrientation] == NSTextLayoutOrientationVertical) &&
            ([theEvent modifierFlags] & NSNumericPadKeyMask))  // arrow keys have this mask
        {
            NSString *arrow = [theEvent charactersIgnoringModifiers];
            BOOL isShiftPressed = ([theEvent modifierFlags] & NSShiftKeyMask) > 0;
            BOOL isOptionPressed = ([theEvent modifierFlags] & NSAlternateKeyMask) > 0;
            
            if ([arrow length] == 1) {
                switch([arrow characterAtIndex:0]) {
                    case NSUpArrowFunctionKey:
                        if (isOptionPressed & isShiftPressed) {
                            [self moveWordBackwardAndModifySelection:self];
                        } else if (isOptionPressed) {
                            [self moveWordBackward:self];
                        } else if (isShiftPressed) {
                            [self moveBackwardAndModifySelection:self];
                        } else {
                            [self moveBackward:self];
                        }
                        return;
                        
                    case NSDownArrowFunctionKey:
                        if (isOptionPressed & isShiftPressed) {
                            [self moveWordForwardAndModifySelection:self];
                        } else if (isOptionPressed) {
                            [self moveWordForward:self];
                        } else if (isShiftPressed) {
                            [self moveForwardAndModifySelection:self];
                        } else {
                            [self moveForward:self];
                        }
                        return;
                        
                    case NSRightArrowFunctionKey:
                        if (isShiftPressed) {
                            [self moveUpAndModifySelection:self];
                        } else {
                            [self moveUp:self];
                        }
                        return;
                        
                    case NSLeftArrowFunctionKey:
                        if (isShiftPressed) {
                            [self moveDownAndModifySelection:self];
                        } else {
                            [self moveDown:self];
                        }
                        return;
                }
            }
        }
    }
    
    [super keyDown:theEvent];
}


// ------------------------------------------------------
/// 文字列入力、'¥' と '\' を入れ替える
- (void)insertText:(id)aString
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
/// タブ入力、タブを展開
- (void)insertTab:(id)sender
// ------------------------------------------------------
{
    if ([self isAutoTabExpandEnabled]) {
        NSInteger tabWidth = [self tabWidth];
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
/// 改行コード入力、オートインデント実行
- (void)insertNewline:(id)sender
// ------------------------------------------------------
{
    NSString *indent = @"";
    BOOL shouldIncreaseIndentLevel = NO;
    BOOL shouldExpandBlock = NO;
    
    if ([[NSUserDefaults standardUserDefaults] boolForKey:k_key_autoIndent]) {
        NSRange selectedRange = [self selectedRange];
        NSRange lineRange = [[self string] lineRangeForRange:selectedRange];
        NSString *lineStr = [[self string] substringWithRange:
                             NSMakeRange(lineRange.location,
                                         lineRange.length - (NSMaxRange(lineRange) - NSMaxRange(selectedRange)))];
        NSRange indentRange = [lineStr rangeOfString:@"^[ \\t　]+" options:NSRegularExpressionSearch];
        
        // インデントを選択状態で改行入力した時は置換とみなしてオートインデントしない 2008.12.13
        if ((indentRange.location != NSNotFound) &&
            (NSMaxRange(selectedRange) < (selectedRange.location + NSMaxRange(indentRange))))
        {
            indent = [lineStr substringWithRange:indentRange];
        }
        
        // スマートインデント
        if ([[NSUserDefaults standardUserDefaults] boolForKey:k_key_enableSmartIndent]) {
            unichar lastChar = NULL;
            unichar nextChar = NULL;
            if (selectedRange.location > 0) {
                lastChar = [[self string] characterAtIndex:selectedRange.location - 1];
            }
            if (NSMaxRange(selectedRange) < [[self string] length]) {
                nextChar = [[self string] characterAtIndex:NSMaxRange(selectedRange)];
            }
            // `{}` の中で改行した場合はインデントを展開する
            shouldExpandBlock = ((lastChar == '{') && (nextChar == '}'));
            // 改行直前の文字が `:` の場合はインデントレベルを1つ下げる
            shouldIncreaseIndentLevel = (lastChar == ':');
        }
    }
    
    [super insertNewline:sender];
    
    if ([indent length] > 0) {
        [super insertText:indent];
    }
    
    if (shouldExpandBlock) {
        [self insertTab:sender];
        NSRange selection = [self selectedRange];
        [super insertNewline:sender];
        [super insertText:indent];
        [self setSelectedRange:selection];
        
    } else if (shouldIncreaseIndentLevel) {
        [self insertTab:sender];
    }
}


// ------------------------------------------------------
/// デリート、タブを展開しているときのスペースを調整削除
- (void)deleteBackward:(id)sender
// ------------------------------------------------------
{
    NSRange selectedRange = [self selectedRange];
    if (selectedRange.length == 0) {
        if ([self isAutoTabExpandEnabled]) {
            NSUInteger tabWidth = [self tabWidth];
            NSRange lineRange = [[self string] lineRangeForRange:selectedRange];
            NSInteger location = selectedRange.location - lineRange.location;
            NSInteger length = (location + tabWidth) % tabWidth;
            NSInteger targetWidth = (length == 0) ? tabWidth : length;
            if (selectedRange.location >= targetWidth) {
                NSRange targetRange = NSMakeRange(selectedRange.location - targetWidth, targetWidth);
                NSString *target = [[self string] substringWithRange:targetRange];
                BOOL shouldDelete = NO;
                for (NSUInteger i = 0; i < targetWidth; i++) {
                    shouldDelete = ([target characterAtIndex:i] == ' ');
                    if (!shouldDelete) {
                        break;
                    }
                }
                if (shouldDelete) {
                    [self setSelectedRange:targetRange];
                }
            }
        }
    }
    [super deleteBackward:sender];
}


// ------------------------------------------------------
/// 補完リストの表示、選択候補の入力
- (void)insertCompletion:(NSString *)word forPartialWordRange:(NSRange)charRange 
        movement:(NSInteger)movement isFinal:(BOOL)isFinal
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
            if (([inputChar isEqualToString:@"_"]) && (movement == NSRightTextMovement) && isFinal) {
                movement = NSIllegalTextMovement;
                isFinal = NO;
            }
            if ((movement == NSIllegalTextMovement) &&
                (theUnichar < 0xF700) && (theUnichar != NSDeleteCharacter)) { // 通常のキー入力の判断
                [self setIsReCompletion:YES];
            } else {
                // 補完文字列に括弧が含まれていたら、括弧内だけを選択する準備をする
                range = [word rangeOfString:@"\\(.*\\)" options:NSRegularExpressionSearch];
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
/// コンテキストメニューを返す
- (NSMenu *)menuForEvent:(NSEvent *)theEvent
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
    if ((utilityMenu || ASSubMenu) &&
        ([outMenu indexOfItemWithTag:k_utilityMenuTag] == k_noMenuItem) &&
        ([outMenu indexOfItemWithTag:k_scriptMenuTag] == k_noMenuItem)) {
        [outMenu addItem:[NSMenuItem separatorItem]];
    }
    if (utilityMenu && ([outMenu indexOfItemWithTag:k_utilityMenuTag] == k_noMenuItem)) {
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
            for (NSUInteger i = 0; i < 2; i++) { // セパレータをふたつ追加
                [outMenu addItem:[NSMenuItem separatorItem]];
                [[outMenu itemAtIndex:([outMenu numberOfItems] - 1)] setTag:k_scriptMenuTag];
            }
            NSMenuItem *addItem = nil;
            for (NSMenuItem *item in [ASSubMenu itemArray]) {
                addItem = [item copy];
                [addItem setTag:k_scriptMenuTag];
                [outMenu addItem:addItem];
            }
        } else{
            [ASMenuItem setImage:[NSImage imageNamed:@"scriptMenuTemplate"]];
            [ASMenuItem setTag:k_scriptMenuTag];
            [ASMenuItem setSubmenu:ASSubMenu];
            [outMenu addItem:ASMenuItem];
        }
    }
    
    if ([CEGlyphPopoverController isSingleCharacter:[[self string] substringWithRange:[self selectedRange]]]) {
        [outMenu insertItemWithTitle:NSLocalizedString(@"Inspect Character", nil)
                              action:@selector(showSelectionInfo:)
                       keyEquivalent:@""
                             atIndex:1];
    }
    
    return outMenu;
}


// ------------------------------------------------------
/// コピー実行。改行コードを書類に設定されたものに置換する。
- (void)copy:(id)sender
// ------------------------------------------------------
{
    // （このメソッドは cut: からも呼び出される）
    [super copy:sender];
    [self replaceLineEndingToDocCharInPboard:[NSPasteboard generalPasteboard]];
}


// ------------------------------------------------------
/// フォント変更
- (void)changeFont:(id)sender
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
/// フォントを設定
- (void)setFont:(NSFont *)font
// ------------------------------------------------------
{
// 複合フォントで行間が等間隔でなくなる問題を回避するため、CELayoutManager にもフォントを持たせておく。
// （CELayoutManager で [[self firstTextView] font] を使うと、「1バイトフォントを指定して日本語が入力されている」場合に
// 日本語フォント名を返してくることがあるため、CELayoutManager からは [textView font] を使わない）
    
    [(CELayoutManager *)[self layoutManager] setTextFont:font];
    [super setFont:font];
    
    [[self paragraphStyle] setDefaultTabInterval:[self tabIntervalFromFont:font]];
    
    [self applyTypingAttributes];
}


// ------------------------------------------------------
/// 補完時の範囲を返す
- (NSRange)rangeForUserCompletion
// ------------------------------------------------------
{
    NSString *string = [self string];
    NSRange range = [super rangeForUserCompletion];
    NSCharacterSet *charSet = [(CESubSplitView *)[self delegate] firstCompletionCharacterSet];
    NSInteger begin = range.location;

    if (!charSet || [string length] == 0) { return range; }

    // 入力補完文字列の先頭となりえない文字が出てくるまで補完文字列対象を広げる
    for (NSInteger i = range.location; i >= 0; i--) {
        if ([charSet characterIsMember:[string characterAtIndex:i]]) {
            begin = i;
        } else {
            break;
        }
    }
    return NSMakeRange(begin, NSMaxRange(range) - begin);
}


// ------------------------------------------------------
/// テキストコンテナの原点（左上）座標を返す
- (NSPoint)textContainerOrigin
// ------------------------------------------------------
{
    return [self textContainerOriginPoint];
}


// ------------------------------------------------------
/// ビュー内を描画
- (void)drawRect:(NSRect)inRect
// ------------------------------------------------------
{
    [super drawRect:inRect];

    [self drawHighlightLineAdditionalRect];

    // ページガイド描画
    if ([(CESubSplitView *)[self delegate] showPageGuide]) {
        CGFloat column = (CGFloat)[[NSUserDefaults standardUserDefaults] doubleForKey:k_key_pageGuideColumn];
        CGFloat length = [self frame].size.height;
        if ((column < k_pageGuideColumnMin) || (column > k_pageGuideColumnMax)) {
            return;
        }
        CGFloat linePadding = [[self textContainer] lineFragmentPadding];
        CGFloat insetWidth = (CGFloat)[[NSUserDefaults standardUserDefaults] doubleForKey:k_key_textContainerInsetWidth];
        column *= [@"M" sizeWithAttributes:@{NSFontAttributeName:[self font]}].width;

        if ([self layoutOrientation] == NSTextLayoutOrientationVertical) {
            length = [self frame].size.width;
        }
        
        // （2ピクセル右に描画してるのは、調整）
        CGFloat x = column + insetWidth + linePadding + 2.5;
        [[NSGraphicsContext currentContext] setShouldAntialias:NO];
        [[[self textColor] colorWithAlphaComponent:0.16] set];
        [NSBezierPath strokeLineFromPoint:NSMakePoint(x, 0)
                                  toPoint:NSMakePoint(x, length)];
    }
    // テキストビューを透過させている時に影を更新描画する
    if ([[self backgroundColor] alphaComponent] < 1.0) {
        [[self window] invalidateShadow];
    }
}


// ------------------------------------------------------
/// 特定の範囲が見えるようにスクロール
- (void)scrollRangeToVisible:(NSRange)range
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


// ------------------------------------------------------
/// 表示方向を変更
- (void)setLayoutOrientation:(NSTextLayoutOrientation)theOrientation
// ------------------------------------------------------
{
    // 縦書きのときは強制的に行番号ビューを非表示
    BOOL shouldShowLineNum = NO;
    if (theOrientation != NSTextLayoutOrientationVertical) {
        shouldShowLineNum = [[NSUserDefaults standardUserDefaults] boolForKey:k_key_showLineNumbers];
    }
    [(CELineNumView *)[self slaveView] setShowLineNum:shouldShowLineNum];
    
    [super setLayoutOrientation:theOrientation];
}


// ------------------------------------------------------
/// フォントパネルを更新
- (void)updateFontPanel
// ------------------------------------------------------
{
    // フォントのみをフォントパネルに渡す
    // -> super にやらせると、テキストカラーもフォントパネルに送り、フォントパネルがさらにカラーパネル（= カラーコードパネル）にそのテキストカラーを渡すので、
    // それを断つために自分で渡す
    [[NSFontPanel sharedFontPanel] setPanelFont:[self font] isMultiple:NO];
}



#pragma mark Public Methods

//=======================================================
// Public method
//
//=======================================================


// ------------------------------------------------------
/// ハイライト行追加表示
- (void)drawHighlightLineAdditionalRect
// ------------------------------------------------------
{
    if (NSWidth([self highlightLineAdditionalRect]) == 0) { return; }

    [[self highlightLineColor] set];
    [NSBezierPath fillRect:[self highlightLineAdditionalRect]];
}


// ------------------------------------------------------
/// キー入力時の文字修飾辞書をセット
- (void)applyTypingAttributes
// ------------------------------------------------------
{
    NSDictionary *attrs = @{NSParagraphStyleAttributeName: [self paragraphStyle],
                            NSFontAttributeName: [self font],
                            NSForegroundColorAttributeName: [self textColor]};
    
    [self setTypingAttributes:attrs];
}


// ------------------------------------------------------
/// ビューの不透明度をセット
- (void)setBackgroundAlpha:(CGFloat)alpha
// ------------------------------------------------------
{
    [self setBackgroundColor:[[self backgroundColor] colorWithAlphaComponent:alpha]];
    [self setHighlightLineColor:[[self highlightLineColor] colorWithAlphaComponent:alpha]];
    
    _backgroundAlpha = alpha;
}


// ------------------------------------------------------
/// 選択文字列を置換
- (void)replaceSelectedStringTo:(NSString *)string scroll:(BOOL)doScroll
// ------------------------------------------------------
{
    if (string == nil) { return; }
    NSRange selectedRange = [self selectedRange];
    NSString *actionName = (selectedRange.length > 0) ? @"Replace Text" : @"Insert Text";
    NSRange newRange = NSMakeRange(selectedRange.location, [string length]);

    [self doInsertString:string withRange:selectedRange 
            withSelected:newRange withActionName:NSLocalizedString(actionName, nil) scroll:doScroll];
}


// ------------------------------------------------------
/// 全文字列を置換
- (void)replaceAllStringTo:(NSString *)string
// ------------------------------------------------------
{
    NSRange newRange = NSMakeRange(0, [string length]);

    if (string) {
        [self doReplaceString:string withRange:NSMakeRange(0, [[self string] length])
                 withSelected:newRange withActionName:NSLocalizedString(@"Replace Text", nil)];
    }
}


// ------------------------------------------------------
/// 選択文字列の後ろへ新規文字列を挿入
- (void)insertAfterSelection:(NSString *)string
// ------------------------------------------------------
{
    if (string == nil) { return; }
    NSRange selectedRange = [self selectedRange];
    NSRange newRange = NSMakeRange(NSMaxRange(selectedRange), [string length]);

    [self doInsertString:string withRange:NSMakeRange(NSMaxRange(selectedRange), 0)
            withSelected:newRange withActionName:NSLocalizedString(@"Insert Text", nil) scroll:NO];
}


// ------------------------------------------------------
/// 末尾に新規文字列を追加
- (void)appendAllString:(NSString *)string
// ------------------------------------------------------
{
    if (string == nil) { return; }
    NSRange newRange = NSMakeRange([[self string] length], [string length]);

    [self doInsertString:string withRange:NSMakeRange([[self string] length], 0)
            withSelected:newRange withActionName:NSLocalizedString(@"Insert Text", nil) scroll:NO];
}


// ------------------------------------------------------
/// カスタムキーバインドで文字列入力
- (void)insertCustomTextWithPatternNum:(NSInteger)patternNum
// ------------------------------------------------------
{
    if (patternNum < 0) { return; }
    
    NSArray *texts = [[NSUserDefaults standardUserDefaults] arrayForKey:k_key_insertCustomTextArray];

    if (patternNum < (NSInteger)[texts count]) {
        NSString *string = texts[patternNum];
        NSRange selectedRange = [self selectedRange];
        NSRange newRange = NSMakeRange(selectedRange.location + [string length], 0);

        [self doInsertString:string withRange:selectedRange
                withSelected:newRange withActionName:NSLocalizedString(@"Insert Custom Text", nil) scroll:YES];
    }
}


// ------------------------------------------------------
/// フォントをリセット
- (void)resetFont:(id)sender
// ------------------------------------------------------
{
    NSString *name = [[NSUserDefaults standardUserDefaults] stringForKey:k_key_fontName];
    CGFloat size = (CGFloat)[[NSUserDefaults standardUserDefaults] doubleForKey:k_key_fontSize];

    [self setFont:[NSFont fontWithName:name size:size]];
    [[self slaveView] setNeedsDisplay:YES];
    [self updateLineNumberAndAdjustScroll];
}


// ------------------------------------------------------
/// 読み取り可能なPasteboardタイプを返す
- (NSArray *)readablePasteboardTypes
// ------------------------------------------------------
{
    NSMutableArray *types = [NSMutableArray arrayWithArray:[super readablePasteboardTypes]];

    [types addObject:NSFilenamesPboardType];
    return types;
}


// ------------------------------------------------------
/// 改行コード置換のためのPasteboardタイプ配列を返す
- (NSArray *)pasteboardTypesForString
// ------------------------------------------------------
{
    return @[NSStringPboardType, @"public.utf8-plain-text"];
}


// ------------------------------------------------------
/// ドラッグする文字列の改行コードを書類に設定されたものに置換する
- (void)dragImage:(NSImage *)anImage at:(NSPoint)imageLoc offset:(NSSize)mouseOffset
            event:(NSEvent *)theEvent pasteboard:(NSPasteboard *)pboard
           source:(id)sourceObject slideBack:(BOOL)slideBack
// ------------------------------------------------------
{
    [self replaceLineEndingToDocCharInPboard:pboard];
    [super dragImage:anImage at:imageLoc offset:mouseOffset
               event:theEvent pasteboard:pboard source:sourceObject slideBack:slideBack];
}


// ------------------------------------------------------
/// 領域内でオブジェクトがドラッグされている
- (NSUInteger)dragOperationForDraggingInfo:(id <NSDraggingInfo>)dragInfo type:(NSString *)type
// ------------------------------------------------------
{
    if ([type isEqualToString:NSFilenamesPboardType]) {
        NSArray *fileDropArray = [[NSUserDefaults standardUserDefaults] arrayForKey:k_key_fileDropArray];
        for (NSDictionary *item in fileDropArray) {
            NSArray *array = [[dragInfo draggingPasteboard] propertyListForType:NSFilenamesPboardType];
            NSArray *extensions = [item[k_key_fileDropExtensions] componentsSeparatedByString:@", "];
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
                    if ((partialFraction > 0.5) && ([string characterAtIndex:glyphIndex] != '\n')) {
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
                    [[self insertionPointColor] set];
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
/// ドロップ実行（同じ書類からドロップされた文字列の改行コードをLFへ置換するためにオーバーライド）
- (BOOL)performDragOperation:(id < NSDraggingInfo >)sender
// ------------------------------------------------------
{
    // ドロップによる編集で改行コードをLFに統一する
    // （その他の編集は、下記の通りの別の場所で置換している）
    // # テキスト編集時の改行コードの置換場所
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
        // （自己内ドラッグの場合には、改行コード置換を readSelectionFromPasteboard:type: 内で実行すると
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
/// ペーストまたはドロップされたアイテムに応じて挿入する文字列をNSPasteboardから読み込む
- (BOOL)readSelectionFromPasteboard:(NSPasteboard *)pboard type:(NSString *)type
// ------------------------------------------------------
{
    // （このメソッドは、performDragOperation: 内で呼ばれる）

    BOOL success = NO;
    NSRange selectedRange, newRange;

    // 実行中フラグを立てる
    [self setIsReadingFromPboard:YES];

    // ペーストされたか、他からテキストがドロップされた
    if (![self isSelfDrop] && [type isEqualToString:NSStringPboardType]) {
        // ペースト、他からのドロップによる編集で改行コードをLFに統一する
        // （その他の編集は、下記の通りの別の場所で置換している）
        // # テキスト編集時の改行コードの置換場所
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
        NSArray *fileDropDefs = [[NSUserDefaults standardUserDefaults] arrayForKey:k_key_fileDropArray];
        NSArray *files = [pboard propertyListForType:NSFilenamesPboardType];
        NSURL *documentURL = [[[[self window] windowController] document] fileURL];
        NSString *relativePath, *fileName, *fileNoSuffix, *dirName;
        NSString *pathExtension = nil, *pathExtensionLower = nil, *pathExtensionUpper = nil;
        NSString *stringToDrop;

        for (NSString *path in files) {
            NSURL *absoluteURL = [NSURL fileURLWithPath:path];
            stringToDrop = nil;
            
            selectedRange = [self selectedRange];
            for (NSDictionary *definition in fileDropDefs) {
                NSArray *extensions = [definition[k_key_fileDropExtensions] componentsSeparatedByString:@", "];
                pathExtension = [absoluteURL pathExtension];
                pathExtensionLower = [pathExtension lowercaseString];
                pathExtensionUpper = [pathExtension uppercaseString];
                
                if ([extensions containsObject:pathExtensionLower] ||
                    [extensions containsObject:pathExtensionUpper])
                {
                    stringToDrop = definition[k_key_fileDropFormatString];
                }
            }
            if ([stringToDrop length] > 0) {
                if (documentURL && ![documentURL isEqual:absoluteURL]) {
                    NSArray *docPathComponents = [documentURL pathComponents];
                    NSArray *droppedPathComponents = [absoluteURL pathComponents];
                    NSMutableArray *relativeComponents = [NSMutableArray array];
                    NSUInteger sameCount = 0, count = 0;
                    NSUInteger docCompnentsCount = [docPathComponents count];
                    NSUInteger droppedCompnentsCount = [droppedPathComponents count];

                    for (NSUInteger i = 0; i < docCompnentsCount; i++) {
                        if (![docPathComponents[i] isEqualToString:droppedPathComponents[i]]) {
                            sameCount = i;
                            count = docCompnentsCount - sameCount - 1;
                            break;
                        }
                    }
                    for (NSUInteger i = count; i > 0; i--) {
                        [relativeComponents addObject:@".."];
                    }
                    for (NSUInteger i = sameCount; i < droppedCompnentsCount; i++) {
                        [relativeComponents addObject:droppedPathComponents[i]];
                    }
                    relativePath = [[NSURL fileURLWithPathComponents:relativeComponents] relativePath];
                } else {
                    relativePath = [absoluteURL path];
                }
                
                fileName = [absoluteURL lastPathComponent];
                fileNoSuffix = [fileName stringByDeletingPathExtension];
                dirName = [[absoluteURL URLByDeletingLastPathComponent] lastPathComponent];
                
                stringToDrop = [stringToDrop stringByReplacingOccurrencesOfString:@"<<<ABSOLUTE-PATH>>>"
                                                                       withString:[absoluteURL path]];
                stringToDrop = [stringToDrop stringByReplacingOccurrencesOfString:@"<<<RELATIVE-PATH>>>"
                                                                       withString:relativePath];
                stringToDrop = [stringToDrop stringByReplacingOccurrencesOfString:@"<<<FILENAME>>>"
                                                                       withString:fileName];
                stringToDrop = [stringToDrop stringByReplacingOccurrencesOfString:@"<<<FILENAME-NOSUFFIX>>>"
                                                                       withString:fileNoSuffix];
                stringToDrop = [stringToDrop stringByReplacingOccurrencesOfString:@"<<<FILEEXTENSION>>>"
                                                                       withString:pathExtension];
                stringToDrop = [stringToDrop stringByReplacingOccurrencesOfString:@"<<<FILEEXTENSION-LOWER>>>"
                                                                       withString:pathExtensionLower];
                stringToDrop = [stringToDrop stringByReplacingOccurrencesOfString:@"<<<FILEEXTENSION-UPPER>>>"
                                                                       withString:pathExtensionUpper];
                stringToDrop = [stringToDrop stringByReplacingOccurrencesOfString:@"<<<DIRECTORY>>>"
                                                                       withString:dirName];
                
                NSImageRep *imageRep = [NSImageRep imageRepWithContentsOfURL:absoluteURL];
                if (imageRep) {
                    // NSImage の size では dpi をも考慮されたサイズが返ってきてしまうので NSImageRep を使う
                    stringToDrop = [stringToDrop stringByReplacingOccurrencesOfString:@"<<<IMAGEWIDTH>>>"
                                                                           withString:[NSString stringWithFormat:@"%zd",
                                                                                       [imageRep pixelsWide]]];
                    stringToDrop = [stringToDrop stringByReplacingOccurrencesOfString:@"<<<IMAGEHEIGHT>>>"
                                                                           withString:[NSString stringWithFormat:@"%zd",
                                                                                       [imageRep pixelsHigh]]];
                }
                // （ファイルをドロップしたときは、挿入文字列全体を選択状態にする）
                newRange = NSMakeRange(selectedRange.location, [stringToDrop length]);
                // （Action名は自動で付けられる？ので、指定しない）
                [self doReplaceString:stringToDrop withRange:selectedRange withSelected:newRange withActionName:@""];
                // 挿入後、選択範囲を移動させておかないと複数オブジェクトをドロップされた時に重ね書きしてしまう
                [self setSelectedRange:NSMakeRange(NSMaxRange(newRange), 0)];
                success = YES;
            }
        }
    }
    if (!success) {
        success = [super readSelectionFromPasteboard:pboard type:type];
    }
    [self setIsReadingFromPboard:NO];

    return success;
}


// ------------------------------------------------------
/// マウスでのテキスト選択時の挙動を制御、ダブルクリックでの括弧内選択機能を追加
- (NSRange)selectionRangeForProposedRange:(NSRange)proposedSelRange granularity:(NSSelectionGranularity)granularity
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
/// 行間値をセットし、テキストと行番号を再描画
- (void)setNewLineSpacingAndUpdate:(CGFloat)lineSpacing
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
/// 置換を実行
- (void)doReplaceString:(NSString *)string withRange:(NSRange)range
           withSelected:(NSRange)selection withActionName:(NSString *)actionName
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
    if (shouldSetAttrs) { // 文字列がない場合に AppleScript から文字列を追加されたときに Attributes が適用されないことへの対応
        [[self textStorage] setAttributes:[self typingAttributes]
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
/// 文字列を選択
- (void)selectTextRangeValue:(NSValue *)rangeValue
// ------------------------------------------------------
{
    [self setSelectedRange:[rangeValue rangeValue]];
}


// ------------------------------------------------------
/// カラーリング設定を更新する
- (void)setTheme:(CETheme *)theme;
// ------------------------------------------------------
{
    NSColor *backgroundColor = [theme backgroundColor];
    NSColor *highlightLineColor = [theme lineHighLightColor];
    
    [self setTextColor:[theme textColor]];
    [self setBackgroundColor:[backgroundColor colorWithAlphaComponent:[self backgroundAlpha]]];
    [self setHighlightLineColor:[highlightLineColor colorWithAlphaComponent:[self backgroundAlpha]]];
    [self setInsertionPointColor:[theme insertionPointColor]];
    [self setSelectedTextAttributes:@{NSBackgroundColorAttributeName: [theme selectionColor]}];
    
    // 背景色に合わせたスクローラのスタイルをセット
    CGFloat brightness = [[backgroundColor colorUsingColorSpaceName:NSDeviceRGBColorSpace] brightnessComponent];
    NSInteger knobStyle = (brightness < 0.5) ? NSScrollerKnobStyleLight : NSScrollerKnobStyleDefault;
    [[self enclosingScrollView] setScrollerKnobStyle:knobStyle];
    
    _theme = theme;
}



#pragma mark Protocol

//=======================================================
// NSNibAwaking Protocol
//
//=======================================================

// ------------------------------------------------------
/// メニューの有効／無効を制御
- (BOOL)validateMenuItem:(NSMenuItem *)menuItem
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
    } else if ([menuItem action] == @selector(changeTabWidth:)) {
        [menuItem setState:(([self tabWidth] == [menuItem tag]) ? NSOnState : NSOffState)];
    } else if ([menuItem action] == @selector(toggleLayoutOrientation:)) {
        NSString *title = ([self layoutOrientation] == NSTextLayoutOrientationHorizontal) ? @"Use Vertical Orientation" : @"Use Horizontal Orientation";
        [menuItem setTitle:NSLocalizedString(title, nil)];
    } else if ([menuItem action] == @selector(showSelectionInfo:)) {
        NSString *selection = [[self string] substringWithRange:[self selectedRange]];
        return [CEGlyphPopoverController isSingleCharacter:selection];
    }

    return [super validateMenuItem:menuItem];
}



#pragma mark Action Messages

//=======================================================
// Action messages
//
//=======================================================

// ------------------------------------------------------
/// 右へシフト
- (IBAction)shiftRight:(id)sender
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
    if ([self isAutoTabExpandEnabled]) {
        NSUInteger tabWidth = [self tabWidth];
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
/// 左へシフト
- (IBAction)shiftLeft:(id)sender
// ------------------------------------------------------
{
    // 現在の選択区域とシフトする行範囲を得る
    NSRange selectedRange = [self selectedRange];
    NSRange lineRange = [[self string] lineRangeForRange:selectedRange];
    if (NSMaxRange(lineRange) == 0) { // 空行で実行された場合は何もしない
        return;
    }
    if ((lineRange.length > 1) &&  ([[self string] characterAtIndex:NSMaxRange(lineRange) - 1] == '\n')) {
        lineRange.length--; // 末尾の改行分を減ずる
    }
    // シフトするために削除するスペースの長さを得る
    NSInteger shiftLength = [self tabWidth];
    if (shiftLength < 1) { return; }

    // 置換する行を生成する
    NSArray *lines = [[[self string] substringWithRange:lineRange] componentsSeparatedByString:@"\n"];
    NSMutableString *newLine = [NSMutableString string];
    NSMutableString *tmpLine = [NSMutableString string];
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
            unichar theChar = [lines[i] characterAtIndex:j];
            if (theChar == '\t') {
                if (!spaceDeleted) {
                    [tmpLine deleteCharactersInRange:NSMakeRange(0, 1)];
                    numberOfDeleted++;
                }
                break;
            } else if (theChar == ' ') {
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
/// 縦書き／横書きを切り替え
- (IBAction)toggleLayoutOrientation:(id)sender
// ------------------------------------------------------
{
    if ([self layoutOrientation] == NSTextLayoutOrientationVertical) {
        [self setLayoutOrientation:NSTextLayoutOrientationHorizontal];
    } else {
        [self setLayoutOrientation:NSTextLayoutOrientationVertical];
    }
}


// ------------------------------------------------------
/// タブ幅を変更する
- (IBAction)changeTabWidth:(id)sender
// ------------------------------------------------------
{
    [self setTabWidth:[sender tag]];
    [self setFont:[self font]];  // 新しい幅でレイアウトし直す
}


// ------------------------------------------------------
/// 小文字へ変更
- (IBAction)exchangeLowercase:(id)sender
// ------------------------------------------------------
{
    NSRange selectedRange = [self selectedRange];

    if (selectedRange.length > 0) {
        NSString *newStr = [[[self string] substringWithRange:selectedRange] lowercaseString];
        if (newStr) {
            NSRange newRange = NSMakeRange(selectedRange.location, [newStr length]);
            [self doInsertString:newStr withRange:selectedRange 
                    withSelected:newRange withActionName:NSLocalizedString(@"To Lowercase", nil) scroll:YES];
        }
    }
}


// ------------------------------------------------------
/// 大文字へ変更
- (IBAction)exchangeUppercase:(id)sender
// ------------------------------------------------------
{
    NSRange selectedRange = [self selectedRange];

    if (selectedRange.length > 0) {
        NSString *newStr = [[[self string] substringWithRange:selectedRange] uppercaseString];
        if (newStr) {
            NSRange newRange = NSMakeRange(selectedRange.location, [newStr length]);
            [self doInsertString:newStr withRange:selectedRange 
                    withSelected:newRange withActionName:NSLocalizedString(@"To Uppercase", nil) scroll:YES];
        }
    }
}


// ------------------------------------------------------
/// 単語の頭を大文字へ変更
- (IBAction)exchangeCapitalized:(id)sender
// ------------------------------------------------------
{
    NSRange selectedRange = [self selectedRange];

    if (selectedRange.length > 0) {
        NSString *newStr = [[[self string] substringWithRange:selectedRange] capitalizedString];
        if (newStr) {
            NSRange newRange = NSMakeRange(selectedRange.location, [newStr length]);
            [self doInsertString:newStr withRange:selectedRange
                    withSelected:newRange withActionName:NSLocalizedString(@"To Capitalized", nil) scroll:YES];
        }
    }
}


// ------------------------------------------------------
/// 全角Roman文字へ変更
- (IBAction)exchangeFullwidthRoman:(id)sender
// ------------------------------------------------------
{
    NSRange selectedRange = [self selectedRange];

    if (selectedRange.length > 0) {
        NSString *newStr = [self halfToFullwidthRomanStringFrom:[[self string] substringWithRange:selectedRange]];
        if (newStr) {
            NSRange newRange = NSMakeRange(selectedRange.location, [newStr length]);
            [self doInsertString:newStr withRange:selectedRange 
                    withSelected:newRange withActionName:NSLocalizedString(@"To Fullwidth (ja_JP/Roman)", nil) scroll:YES];
        }
    }
}


// ------------------------------------------------------
/// 半角Roman文字へ変更
- (IBAction)exchangeHalfwidthRoman:(id)sender
// ------------------------------------------------------
{
    NSRange selectedRange = [self selectedRange];

    if (selectedRange.length > 0) {
        NSString *newStr = 
                [self fullToHalfwidthRomanStringFrom:[[self string] substringWithRange:selectedRange]];
        if (newStr) {
            NSRange newRange = NSMakeRange(selectedRange.location, [newStr length]);
            [self doInsertString:newStr withRange:selectedRange 
                    withSelected:newRange withActionName:NSLocalizedString(@"To Halfwidth (ja_JP/Roman)", nil) scroll:YES];
        }
    }
}


// ------------------------------------------------------
/// ひらがなをカタカナへ変更
- (IBAction)exchangeKatakana:(id)sender
// ------------------------------------------------------
{
    NSRange selectedRange = [self selectedRange];

    if (selectedRange.length > 0) {
        NSString *newStr = [self hiraganaToKatakanaStringFrom:[[self string] substringWithRange:selectedRange]];
        if (newStr) {
            NSRange newRange = NSMakeRange(selectedRange.location, [newStr length]);
            [self doInsertString:newStr withRange:selectedRange 
                    withSelected:newRange withActionName:NSLocalizedString(@"Hiragana to Katakana (ja_JP)",@"") scroll:YES];
        }
    }
}


// ------------------------------------------------------
/// カタカナをひらがなへ変更
- (IBAction)exchangeHiragana:(id)sender
// ------------------------------------------------------
{
    NSRange selectedRange = [self selectedRange];

    if (selectedRange.length > 0) {
        NSString *newStr = 
                [self katakanaToHiraganaStringFrom:[[self string] substringWithRange:selectedRange]];
        if (newStr) {
            NSRange newRange = NSMakeRange(selectedRange.location, [newStr length]);
            [self doInsertString:newStr withRange:selectedRange
                    withSelected:newRange withActionName:NSLocalizedString(@"Katakana to Hiragana (ja_JP)",@"") scroll:YES];
        }
    }
}


// ------------------------------------------------------
/// Unicode正規化
- (IBAction)unicodeNormalizationNFD:(id)sender
// ------------------------------------------------------
{
    [self unicodeNormalization:sender];
}


// ------------------------------------------------------
/// Unicode正規化
- (IBAction)unicodeNormalizationNFC:(id)sender
// ------------------------------------------------------
{
    [self unicodeNormalization:sender];
}


// ------------------------------------------------------
/// Unicode正規化
- (IBAction)unicodeNormalizationNFKD:(id)sender
// ------------------------------------------------------
{
    [self unicodeNormalization:sender];
}


// ------------------------------------------------------
/// Unicode正規化
- (IBAction)unicodeNormalizationNFKC:(id)sender
// ------------------------------------------------------
{
    [self unicodeNormalization:sender];
}


// ------------------------------------------------------
/// Unicode正規化
- (IBAction)unicodeNormalization:(id)sender
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
/// 半角円マークを入力
- (IBAction)inputYenMark:(id)sender
// ------------------------------------------------------
{
    [super insertText:[NSString stringWithCharacters:&k_yenMark length:1]];
}


// ------------------------------------------------------
/// バックスラッシュを入力
- (IBAction)inputBackSlash:(id)sender
// ------------------------------------------------------
{
    [super insertText:@"\\"];
}


// ------------------------------------------------------
/// 選択範囲をカラーコードパネルに渡す
- (IBAction)editColorCode:(id)sender
// ------------------------------------------------------
{
    NSString *curStr = [[self string] substringWithRange:[self selectedRange]];
    
    [[CEColorCodePanelController sharedController] showWindow:sender];
    [[CEColorCodePanelController sharedController] setColorWithCode:curStr];
}


// ------------------------------------------------------
/// カラーパネルからのアクションで色を変更しない
- (IBAction)changeColor:(id)sender
// ------------------------------------------------------
{
    // do nothing.
}


// ------------------------------------------------------
/// アウトラインメニュー選択によるテキスト選択を実行
- (IBAction)setSelectedRangeWithNSValue:(id)sender
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
/// 行間設定を変更
- (IBAction)setLineSpacingFromMenu:(id)sender
// ------------------------------------------------------
{
    [self setNewLineSpacingAndUpdate:(CGFloat)[[sender title] doubleValue]];
}


// ------------------------------------------------------
/// グリフ情報をポップオーバーで表示
- (IBAction)showSelectionInfo:(id)sender
// ------------------------------------------------------
{
    NSRange selectedRange = [self selectedRange];
    NSString *selectedString = [[self string] substringWithRange:selectedRange];
    
    if (![CEGlyphPopoverController isSingleCharacter:selectedString]) {
        return;
    }
    
    CEGlyphPopoverController *popoverController = [[CEGlyphPopoverController alloc] initWithCharacter:selectedString];
    
    NSRange glyphRange = [[self layoutManager] glyphRangeForCharacterRange:selectedRange actualCharacterRange:NULL];
    NSRect selectedRect = [[self layoutManager] boundingRectForGlyphRange:glyphRange inTextContainer:[self textContainer]];
    NSPoint containerOrigin = [self textContainerOrigin];
    selectedRect.origin.x += containerOrigin.x;
    selectedRect.origin.y += containerOrigin.y - 6.0;
    selectedRect = [self convertRectToLayer:selectedRect];
    
    [popoverController showPopoverRelativeToRect:selectedRect ofView:self];
    [self showFindIndicatorForRange:NSMakeRange(selectedRange.location, 1)];
}


#pragma mark Private Mthods

// ------------------------------------------------------
/// 変更を監視するデフォルトキー
- (NSArray *)observedDefaultKeys
// ------------------------------------------------------
{
    return @[k_key_windowAlpha,
             k_key_autoExpandTab,
             k_key_smartInsertAndDelete,
             k_key_checkSpellingAsType,
             k_key_enableSmartQuotes];
}


// ------------------------------------------------------
/// 文字列置換のリドゥーを登録
- (void)redoReplaceString:(NSString *)string withRange:(NSRange)range 
            withSelected:(NSRange)selection withActionName:(NSString *)actionName
// ------------------------------------------------------
{
    [[[self undoManager] prepareWithInvocationTarget:self]
        doReplaceString:string withRange:range withSelected:selection withActionName:actionName];
}


// ------------------------------------------------------
/// 置換実行
- (void)doInsertString:(NSString *)string withRange:(NSRange)range 
            withSelected:(NSRange)selection withActionName:(NSString *)actionName scroll:(BOOL)doScroll
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
/// 半角Romanを全角Romanへ変換
- (NSString *)halfToFullwidthRomanStringFrom:(NSString *)halfRoman
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
/// 全角Romanを半角Romanへ変換
- (NSString *)fullToHalfwidthRomanStringFrom:(NSString *)fullRoman
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
/// ひらがなをカタカナへ変換
- (NSString *)hiraganaToKatakanaStringFrom:(NSString *)hiragana
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
/// カタカナをひらがなへ変換
- (NSString *)katakanaToHiraganaStringFrom:(NSString *)katakana
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
/// ドラッグされているアイテムのNSFilenamesPboardTypeに指定された拡張子のものが含まれているかどうかを返す
- (BOOL)draggedItemsArray:(NSArray *)items containsExtensionInExtensions:(NSArray *)extensions
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
/// 行番号更新、キャレット／選択範囲が見えるようスクロール位置を調整
- (void)updateLineNumberAndAdjustScroll
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
/// Pasetboard内文字列の改行コードを書類に設定されたものに置換する
- (void)replaceLineEndingToDocCharInPboard:(NSPasteboard *)pboard
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
/// フォントからタブ幅を計算して返す
- (CGFloat)tabIntervalFromFont:(NSFont *)font
// ------------------------------------------------------
{
    NSMutableString *widthStr = [[NSMutableString alloc] init];
    NSUInteger numberOfSpaces = [self tabWidth];
    while (numberOfSpaces--) {
        [widthStr appendString:@" "];
    }
    return [widthStr sizeWithAttributes:@{NSFontAttributeName:font}].width;
}

@end
