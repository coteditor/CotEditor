/*
 ==============================================================================
 CETextView
 
 CotEditor
 http://coteditor.com
 
 Created on 2005-03-30 by nakamuxu
 encoding="UTF-8"
 
 ------------
 This class is based on JSDTextView (written by James S. Derry – http://www.balthisar.com)
 JSDTextView is released as public domain.
 arranged by nakamuxu, Dec 2004.
 ------------------------------------------------------------------------------
 
 © 2004-2007 nakamuxu
 © 2014 CotEditor Project
 
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

#import "CETextView.h"
#import "CELineNumberView.h"
#import "CEColorCodePanelController.h"
#import "CEGlyphPopoverController.h"
#import "CEKeyBindingManager.h"
#import "CEScriptManager.h"
#import "NSString+JapaneseTransform.h"
#import "constants.h"


// enum
typedef NS_ENUM(NSUInteger, CEUnicodeNormalizationForm) {
    CEUnicodeNormalizationNFD,
    CEUnicodeNormalizationNFC,
    CEUnicodeNormalizationNFKD,
    CEUnicodeNormalizationNFKC
};


// constant
const NSInteger kNoMenuItem = -1;


@interface CETextView ()

@property (nonatomic) NSRect insertionRect;
@property (nonatomic) NSPoint textContainerOriginPoint;
@property (nonatomic) NSMutableParagraphStyle *paragraphStyle;
@property (nonatomic) NSTimer *completionTimer;
@property (nonatomic) NSString *particalCompletionWord;  // ユーザが実際に入力した補完の元になる文字列

@property (nonatomic) NSColor *highlightLineColor;  // カレント行ハイライト色
@property (nonatomic) NSUInteger tabWidth;  // タブ幅


// readonly
@property (readwrite, nonatomic, getter=isSelfDrop) BOOL selfDrop;  // 自己内ドラッグ&ドロップなのか
@property (readwrite, nonatomic, getter=isReadingFromPboard) BOOL readingFromPboard;  // ペーストまたはドロップ実行中なのか

@end




#pragma mark -

@implementation CETextView

#pragma mark NSTextView Methods

//=======================================================
// NSTextView method
//
//=======================================================

// ------------------------------------------------------
/// 初期化
- (instancetype)initWithFrame:(NSRect)frameRect textContainer:(NSTextContainer *)aTextContainer
// ------------------------------------------------------
{
    self = [super initWithFrame:frameRect textContainer:aTextContainer];
    if (self) {
        // このメソッドはSmultronのSMLTextViewを参考にしています。
        // This method is based on Smultron(SMLTextView) written by Peter Borg. Copyright (C) 2004 Peter Borg.
        // http://smultron.sourceforge.net
        // set the width of every tab by first checking the size of the tab in spaces in the current font and then remove all tabs that sets automatically and then set the default tab stop distance
        NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
        
        _tabWidth = [defaults integerForKey:CEDefaultTabWidthKey];
        
        NSFont *font = [NSFont fontWithName:[defaults stringForKey:CEDefaultFontNameKey]
                                       size:(CGFloat)[defaults doubleForKey:CEDefaultFontSizeKey]];

        NSMutableParagraphStyle *paragraphStyle = [[NSParagraphStyle defaultParagraphStyle] mutableCopy];
        for (NSTextTab *textTabToBeRemoved in [paragraphStyle tabStops]) {
            [paragraphStyle removeTabStop:textTabToBeRemoved];
        }
        [paragraphStyle setDefaultTabInterval:[self tabIntervalFromFont:font]];
        _paragraphStyle = paragraphStyle;
        // （NSParagraphStyle の lineSpacing を設定すればテキスト描画時の行間は制御できるが、
        // 「文書の1文字目に1バイト文字（または2バイト文字）を入力してある状態で先頭に2バイト文字（または1バイト文字）を
        // 挿入すると行間がズレる」問題が生じるため、CELayoutManager および CEATSTypesetter で制御している）

        // テーマの設定
        [self setTheme:[CETheme themeWithName:[defaults stringForKey:CEDefaultThemeKey]]];
        
        // set the values
        _autoTabExpandEnabled = [defaults boolForKey:CEDefaultAutoExpandTabKey];
        [self setSmartInsertDeleteEnabled:[defaults boolForKey:CEDefaultSmartInsertAndDeleteKey]];
        [self setContinuousSpellCheckingEnabled:[defaults boolForKey:CEDefaultCheckSpellingAsTypeKey]];
        if ([self respondsToSelector:@selector(setAutomaticQuoteSubstitutionEnabled:)]) {  // only on OS X 10.9 and later
            [self setAutomaticQuoteSubstitutionEnabled:[defaults boolForKey:CEDefaultEnableSmartQuotesKey]];
            [self setAutomaticDashSubstitutionEnabled:[defaults boolForKey:CEDefaultEnableSmartQuotesKey]];
        }
        [self setFont:font];
        [self setMinSize:frameRect.size];
        [self setMaxSize:NSMakeSize(CGFLOAT_MAX, CGFLOAT_MAX)];
        [self setAllowsDocumentBackgroundColorChange:NO];
        [self setAllowsUndo:YES];
        [self setRichText:NO];
        [self setImportsGraphics:NO];
        [self setUsesFindPanel:YES];
        [self setHorizontallyResizable:YES];
        [self setVerticallyResizable:YES];
        [self setAcceptsGlyphInfo:YES];
        [self setTextContainerInset:NSMakeSize((CGFloat)[defaults doubleForKey:CEDefaultTextContainerInsetWidthKey],
                                               (CGFloat)([defaults doubleForKey:CEDefaultTextContainerInsetHeightTopKey] +
                                                         [defaults doubleForKey:CEDefaultTextContainerInsetHeightBottomKey]) / 2)];
        [self setLineSpacing:(CGFloat)[defaults doubleForKey:CEDefaultLineSpacingKey]];
        _insertionRect = NSZeroRect;
        _textContainerOriginPoint = NSMakePoint((CGFloat)[defaults doubleForKey:CEDefaultTextContainerInsetWidthKey],
                                                (CGFloat)[defaults doubleForKey:CEDefaultTextContainerInsetHeightTopKey]);
        _needsUpdateOutlineMenuItemSelection = YES;
        
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
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    [self stopCompletionTimer];
}


// ------------------------------------------------------
/// ユーザ設定の変更を反映する
-(void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context
// ------------------------------------------------------
{
    id newValue = change[NSKeyValueChangeNewKey];
    
    if ([keyPath isEqualToString:CEDefaultAutoExpandTabKey]) {
        [self setAutoTabExpandEnabled:[newValue boolValue]];
        
    } else if ([keyPath isEqualToString:CEDefaultSmartInsertAndDeleteKey]) {
        [self setSmartInsertDeleteEnabled:[newValue boolValue]];
        
    } else if ([keyPath isEqualToString:CEDefaultCheckSpellingAsTypeKey]) {
        [self setContinuousSpellCheckingEnabled:[newValue boolValue]];
        
    } else if ([keyPath isEqualToString:CEDefaultEnableSmartQuotesKey]) {
        if ([self respondsToSelector:@selector(setAutomaticQuoteSubstitutionEnabled:)]) {  // only on OS X 10.9 and later
            [self setAutomaticQuoteSubstitutionEnabled:[newValue boolValue]];
            [self setAutomaticDashSubstitutionEnabled:[newValue boolValue]];
        }
    }
}


// ------------------------------------------------------
/// first responder になれるかを返す  !!!: Deprecated on 10.4
- (BOOL)becomeFirstResponder
// ------------------------------------------------------
{
    [[(CEWindowController *)[[self window] windowController] editor] setTextView:self];
    
    return [super becomeFirstResponder];
}


// ------------------------------------------------------
/// 自身がウインドウに組み込まれた
-(void)viewDidMoveToWindow
// ------------------------------------------------------
{
    [super viewDidMoveToWindow];
    
    // テーマ背景色を反映させる
    [[self window] setBackgroundColor:[[self theme] backgroundColor]];
    
    // レイヤーバックドビューにする
    if (NSAppKitVersionNumber >= NSAppKitVersionNumber10_8) { // on Mountain Lion and later
        [[self enclosingScrollView] setWantsLayer:YES];
        [[[self enclosingScrollView] contentView] setCopiesOnScroll:YES];
        [self setLayerContentsRedrawPolicy:NSViewLayerContentsRedrawOnSetNeedsDisplay];
    }
    
    // ウインドウの透明フラグを監視する
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(didWindowOpacityChange:)
                                                 name:CEWindowOpacityDidChangeNotification
                                               object:[self window]];
}


// ------------------------------------------------------
/// キー押下を取得
- (void)keyDown:(NSEvent *)theEvent
// ------------------------------------------------------
{
    NSString *charIgnoringMod = [theEvent charactersIgnoringModifiers];
    // IM で日本語入力変換中でないときのみ追加テキストキーバインディングを実行
    if (![self hasMarkedText] && charIgnoringMod) {
        NSUInteger modFlags = [theEvent modifierFlags];
        NSString *selectorStr = [[CEKeyBindingManager sharedManager] selectorStringWithKeyEquivalent:charIgnoringMod
                                                                                       modifierFrags:modFlags];
        NSInteger length = [selectorStr length];
        if (selectorStr && (length > 0)) {
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
/// 文字列入力、'¥' と '\' を入れ替える (NSTextInputClient)
- (void)insertText:(id)aString replacementRange:(NSRange)replacementRange
// ------------------------------------------------------
{
    if ([[NSUserDefaults standardUserDefaults] boolForKey:CEDefaultSwapYenAndBackSlashKey] && ([aString length] == 1)) {
        NSEvent *event = [NSApp currentEvent];
        NSUInteger flags = [NSEvent modifierFlags];
        
        if (([event type] == NSKeyDown) && (flags == 0)) {
            NSString *yen = [NSString stringWithCharacters:&kYenMark length:1];
            if ([aString isEqualToString:@"\\"]) {
                [super insertText:yen replacementRange:replacementRange];
                return;
            } else if ([aString isEqualToString:yen]) {
                [super insertText:@"\\" replacementRange:replacementRange];
                return;
            }
        }
    }
    
    [super insertText:aString replacementRange:replacementRange];
    
    // auto completion
    if ([[NSUserDefaults standardUserDefaults] boolForKey:CEDefaultAutoCompleteKey]) {
        [self completeAfterDelay:[[NSUserDefaults standardUserDefaults] doubleForKey:CEDefaultAutoCompletionDelayKey]];
    }
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
    BOOL shouldDecreaseIndentLevel = NO;
    BOOL shouldExpandBlock = NO;
    
    if ([[NSUserDefaults standardUserDefaults] boolForKey:CEDefaultAutoIndentKey]) {
        NSRange selectedRange = [self selectedRange];
        NSRange lineRange = [[self string] lineRangeForRange:selectedRange];
        NSString *lineStr = [[self string] substringWithRange:
                             NSMakeRange(lineRange.location,
                                         lineRange.length - (NSMaxRange(lineRange) - NSMaxRange(selectedRange)))];
        NSRange indentRange = [lineStr rangeOfString:@"^[ \\t　]+" options:NSRegularExpressionSearch];
        
        // インデントを選択状態で改行入力した時は置換とみなしてオートインデントしない 2008.12.13
        if (NSMaxRange(selectedRange) >= (selectedRange.location + NSMaxRange(indentRange))) {
            [super insertNewline:sender];
            return;
        }
            
        if (indentRange.location != NSNotFound) {
            indent = [lineStr substringWithRange:indentRange];
        }
        
        // スマートインデント
        if ([[NSUserDefaults standardUserDefaults] boolForKey:CEDefaultEnableSmartIndentKey]) {
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
            // 改行直前の文字が `:` か `{` の場合はインデントレベルを1つ上げる
            shouldIncreaseIndentLevel = ((lastChar == ':') || (lastChar == '{'));
            // 改行直前の文字が `}` でそれ以外が空白の行の場合はインデントレベルを1つ下げる
            shouldDecreaseIndentLevel = ((lastChar == '}') &&
                                         ([lineStr rangeOfString:@"^[ \\t　]+$"
                                                         options:NSRegularExpressionSearch
                                                           range:NSMakeRange(0, [lineStr length] - 1)].location != NSNotFound));
        }
    }
    
    // インデントレベルを下げる必要があるかを改めて判定して必要であれば下げる
    if (shouldDecreaseIndentLevel) {
        NSString *completeString = [self string];
        NSUInteger currentIndentLevel = [self indentLevelOfString:indent];
        NSInteger precedingLocation = [self selectedRange].location - 1;
        NSUInteger skipMatchingBrace = 0;
        BOOL isSearching = YES;
        
        while (isSearching && precedingLocation--) {
            unichar characterToCheck = [completeString characterAtIndex:precedingLocation];
            if (characterToCheck == '{') {
                if (!skipMatchingBrace) {
                    isSearching = NO;
                    #pragma unused(isSearching)  // `isSearching` is in fact used in condition for while
                    break;
                } else {
                    skipMatchingBrace--;
                }
            } else if (characterToCheck == '}') {
                skipMatchingBrace++;
            }
        }
        
        if (precedingLocation >= 0) {
            NSRange precedingRange = NSMakeRange(precedingLocation, 0);
            NSRange precedingLineRange = [completeString lineRangeForRange:precedingRange];
            NSString *lineStr = [completeString substringWithRange:
                                 NSMakeRange(precedingLineRange.location, precedingLineRange.length)];
            NSInteger desiredIndentLevel = [self indentLevelOfString:lineStr];
            
            while (desiredIndentLevel < currentIndentLevel) {
                [self moveLeft:sender];
                [self deleteBackward:sender];
                [self moveRight:sender];
                
                NSUInteger inentWidth = ([indent characterAtIndex:[indent length] - 1] == ' ') ? [self tabWidth] : 1;
                indent = [indent substringToIndex:[indent length] - inentWidth];
                currentIndentLevel--;
            }
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
- (void)insertCompletion:(NSString *)word forPartialWordRange:(NSRange)charRange movement:(NSInteger)movement isFinal:(BOOL)flag
// ------------------------------------------------------
{
    NSEvent *event = [[self window] currentEvent];
    BOOL didComplete = NO;
    
    [self stopCompletionTimer];
    
    // 補完の元になる文字列を保存する
    if (![self particalCompletionWord]) {
        [self setParticalCompletionWord:[[self string] substringWithRange:charRange]];
    }

    // 補完リストを表示中に通常のキー入力があったら、直後にもう一度入力補完を行うためのフラグを立てる
    // （フラグは CEEditorView > textDidChange: で評価される）
    if (flag && ([event type] == NSKeyDown) && !([event modifierFlags] & NSCommandKeyMask)) {
        NSString *inputChar = [event charactersIgnoringModifiers];
        unichar theUnichar = [inputChar characterAtIndex:0];

        if ([inputChar isEqualToString:[event characters]]) { //キーバインディングの入力などを除外
            // アンダースコアが右矢印キーと判断されることの是正
            if (([inputChar isEqualToString:@"_"]) && (movement == NSRightTextMovement)) {
                movement = NSIllegalTextMovement;
                flag = NO;
            }
            if ((movement == NSIllegalTextMovement) &&
                (theUnichar < 0xF700) && (theUnichar != NSDeleteCharacter)) { // 通常のキー入力の判断
                [self setNeedsRecompletion:YES];
            }
        }
    }
    
    if (flag) {
        if ((movement == NSIllegalTextMovement) || (movement == NSRightTextMovement)) {  // キャンセル扱い
            // 保存していた入力を復帰する（大文字／小文字が変更されている可能性があるため）
            word = [self particalCompletionWord];
        } else {
            didComplete = YES;
        }
        
        // 補完の元になる文字列をクリア
        [self setParticalCompletionWord:nil];
    }
    
    [super insertCompletion:word forPartialWordRange:charRange movement:movement isFinal:flag];
    
    if (didComplete) {
        // 補完文字列に括弧が含まれていたら、括弧内だけを選択
        NSRange rangeToSelect = [word rangeOfString:@"(?<=\\().*(?=\\))" options:NSRegularExpressionSearch];
        if (rangeToSelect.location != NSNotFound) {
            rangeToSelect.location += charRange.location;
            [self setSelectedRange:rangeToSelect];
        }
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
    NSMenu *utilityMenu = [[[[NSApp mainMenu] itemAtIndex:CEUtilityMenuIndex] submenu] copy];
    NSMenuItem *ASMenuItem = [[NSMenuItem alloc] initWithTitle:@"" action:nil keyEquivalent:@""];
    NSMenu *ASSubMenu = [[CEScriptManager sharedManager] contexualMenu];

    // 「フォント」メニューおよびサブメニューを削除
    [outMenu removeItem:[outMenu itemWithTitle:NSLocalizedString(@"Font",@"")]];

    // 連続してコンテキストメニューを表示させるとどんどんメニューアイテムが追加されてしまうので、
    // 既に追加されているかどうかをチェックしている
    if (selectAllMenuItem &&
        ([outMenu indexOfItemWithTarget:nil andAction:@selector(selectAll:)] == kNoMenuItem)) {
        NSInteger pasteIndex = [outMenu indexOfItemWithTarget:nil andAction:@selector(paste:)];
        if (pasteIndex != kNoMenuItem) {
            [outMenu insertItem:selectAllMenuItem atIndex:(pasteIndex + 1)];
        }
    }
    if ((utilityMenu || ASSubMenu) &&
        ([outMenu indexOfItemWithTag:CEUtilityMenuItemTag] == kNoMenuItem) &&
        ([outMenu indexOfItemWithTag:CEScriptMenuItemTag] == kNoMenuItem)) {
        [outMenu addItem:[NSMenuItem separatorItem]];
    }
    if (utilityMenu && ([outMenu indexOfItemWithTag:CEUtilityMenuItemTag] == kNoMenuItem)) {
        [utilityMenuItem setTag:CEUtilityMenuItemTag];
        [utilityMenuItem setSubmenu:utilityMenu];
        [outMenu addItem:utilityMenuItem];
    }
    if (ASSubMenu) {
        NSMenuItem *delItem = nil;
        while ((delItem = [outMenu itemWithTag:CEScriptMenuItemTag])) {
            [outMenu removeItem:delItem];
        }
        
        if ([[NSUserDefaults standardUserDefaults] boolForKey:CEDefaultInlineContextualScriptMenuKey]) {
            for (NSUInteger i = 0; i < 2; i++) { // セパレータをふたつ追加
                [outMenu addItem:[NSMenuItem separatorItem]];
                [[outMenu itemAtIndex:([outMenu numberOfItems] - 1)] setTag:CEScriptMenuItemTag];
            }
            NSMenuItem *addItem = nil;
            for (NSMenuItem *item in [ASSubMenu itemArray]) {
                addItem = [item copy];
                [addItem setTag:CEScriptMenuItemTag];
                [outMenu addItem:addItem];
            }
            [outMenu addItem:[NSMenuItem separatorItem]];
        } else{
            [ASMenuItem setImage:[NSImage imageNamed:@"ScriptTemplate"]];
            [[ASMenuItem image] setTemplate:NO];
            [ASMenuItem setTag:CEScriptMenuItemTag];
            [ASMenuItem setSubmenu:ASSubMenu];
            [outMenu addItem:ASMenuItem];
        }
    }
    
    if ([[[self string] substringWithRange:[self selectedRange]] numberOfComposedCharacters] == 1) {
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
    NSCharacterSet *charSet = [self firstCompletionCharacterSet];

    if (!charSet || [string length] == 0) { return range; }

    // 入力補完文字列の先頭となりえない文字が出てくるまで補完文字列対象を広げる
    NSInteger begin = MIN(range.location, [string length] - 1);
    for (NSInteger i = begin; i >= 0; i--) {
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
/// ビュー内の背景を描画
- (void)drawViewBackgroundInRect:(NSRect)rect
// ------------------------------------------------------
{
    [super drawViewBackgroundInRect:rect];
    
    // 現在行ハイライト描画
    if (NSWidth([self highlightLineRect]) > 0) {
        [[self highlightLineColor] set];
        [NSBezierPath fillRect:[self highlightLineRect]];
    }
}


// ------------------------------------------------------
/// ビュー内を描画
- (void)drawRect:(NSRect)dirtyRect
// ------------------------------------------------------
{
    [super drawRect:dirtyRect];
    
    // ページガイド描画
    if ([self showsPageGuide]) {
        CGFloat column = (CGFloat)[[NSUserDefaults standardUserDefaults] doubleForKey:CEDefaultPageGuideColumnKey];
        
        if ((column < kMinPageGuideColumn) || (column > kMaxPageGuideColumn)) {
            return;
        }
        
        CGFloat length = ([self layoutOrientation] == NSTextLayoutOrientationVertical) ? NSWidth([self frame]) : NSHeight([self frame]);
        CGFloat linePadding = [[self textContainer] lineFragmentPadding];
        CGFloat inset = [self textContainerOrigin].x;
        column *= [@"M" sizeWithAttributes:@{NSFontAttributeName:[(CELayoutManager *)[self layoutManager] textFont]}].width;
        
        // （2ピクセル右に描画してるのは、調整）
        CGFloat x = floor(column + inset + linePadding) + 2.5;
        [[[[self theme] textColor] colorWithAlphaComponent:0.2] set];
        [NSBezierPath strokeLineFromPoint:NSMakePoint(x, 0)
                                  toPoint:NSMakePoint(x, length)];
    }
    
    // テキストビューを透過させている時に影を更新描画する (on Lion)
    // Lion 上では Layer-backed になっていないのでビュー越しにテキストのドロップシャドウが描画される。Lion サポート落としたら多分不要。(2014-10 1024jp)
    if ((NSAppKitVersionNumber < NSAppKitVersionNumber10_8) && ![[self window] isOpaque]) {
        [[self window] invalidateShadow];
    }
}


// ------------------------------------------------------
/// 特定の範囲が見えるようにスクロール
- (void)scrollRangeToVisible:(NSRange)range
// ------------------------------------------------------
{
    // 矢印キーが押されているときは1行ずつのスクロールにする
    if ([NSEvent modifierFlags] & NSNumericPadKeyMask) {
        NSRange glyphRange = [[self layoutManager] glyphRangeForCharacterRange:range actualCharacterRange:nil];
        NSRect glyphRect = [[self layoutManager] boundingRectForGlyphRange:glyphRange inTextContainer:[self textContainer]];
        CGFloat buffer = [[self font] pointSize] / 2;
        
        glyphRect = NSInsetRect(glyphRect, -buffer, -buffer);
        glyphRect = NSOffsetRect(glyphRect, [self textContainerOrigin].x, [self textContainerOrigin].y);
        
        [super scrollRectToVisible:glyphRect];  // move minimum distance
        
        return;
    }
    
    [super scrollRangeToVisible:range];
    
    // 完全にスクロールさせる
    // （setTextContainerInset で上下に空白領域を挿入している関係で、ちゃんとスクロールしない場合があることへの対策）
    NSUInteger length = [[self string] length];
    NSRect rect = NSZeroRect;
    
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
    
    NSRect convertedRect = [self convertRect:rect toView:[[self enclosingScrollView] superview]]; //editorView
    if ((convertedRect.origin.y >= 0) &&
        (convertedRect.origin.y < [[NSUserDefaults standardUserDefaults] doubleForKey:CEDefaultTextContainerInsetHeightBottomKey]))
    {
        [self scrollPoint:NSMakePoint(NSMinX(rect), NSMaxY(rect))];
    }
}


// ------------------------------------------------------
/// 表示方向を変更
- (void)setLayoutOrientation:(NSTextLayoutOrientation)theOrientation
// ------------------------------------------------------
{
    if (theOrientation != [self layoutOrientation]) {
        BOOL isVertical = (theOrientation == NSTextLayoutOrientationVertical);
        
        // 折り返しを再セット
        if ([[self textContainer] containerSize].width != CGFLOAT_MAX) {
            [[self textContainer] setContainerSize:NSMakeSize(0, CGFLOAT_MAX)];
        }
        
        // 縦書きのときは強制的に行番号ビューを非表示
        BOOL showsLineNum = isVertical ? NO : [[NSUserDefaults standardUserDefaults] boolForKey:CEDefaultShowLineNumbersKey];
        [(CELineNumberView *)[self lineNumberView] setShown:showsLineNum];
    }
    
    [super setLayoutOrientation:theOrientation];
}


// ------------------------------------------------------
/// 読み取り可能なPasteboardタイプを返す
- (NSArray *)readablePasteboardTypes
// ------------------------------------------------------
{
    return [[super readablePasteboardTypes] arrayByAddingObject:NSFilenamesPboardType];
}


// ------------------------------------------------------
/// ドラッグする文字列の改行コードを書類に設定されたものに置換する
- (NSDraggingSession *)beginDraggingSessionWithItems:(NSArray *)items event:(NSEvent *)event source:(id<NSDraggingSource>)source
// ------------------------------------------------------
{
    NSDraggingSession *session = [super beginDraggingSessionWithItems:items event:event source:source];
    
    [self replaceLineEndingToDocCharInPboard:[session draggingPasteboard]];
    
    return session;
}


// ------------------------------------------------------
/// 領域内でオブジェクトがドラッグされている
- (NSDragOperation)dragOperationForDraggingInfo:(id <NSDraggingInfo>)dragInfo type:(NSString *)type
// ------------------------------------------------------
{
    if ([type isEqualToString:NSFilenamesPboardType]) {
        NSArray *fileDropArray = [[NSUserDefaults standardUserDefaults] arrayForKey:CEDefaultFileDropArrayKey];
        
        for (NSDictionary *item in fileDropArray) {
            NSArray *array = [[dragInfo draggingPasteboard] propertyListForType:NSFilenamesPboardType];
            NSArray *extensions = [item[CEFileDropExtensionsKey] componentsSeparatedByString:@", "];
            
            if ([self draggedItemsArray:array containsExtensionInExtensions:extensions]) {
                NSString *string = [self string];
                if ([string length] > 0) {
                    // 挿入ポイントを自前で描画する
                    CGFloat partialFraction;
                    NSLayoutManager *layoutManager = [self layoutManager];
                    NSUInteger glyphIndex = [layoutManager glyphIndexForPoint:[self convertPoint:[dragInfo draggingLocation] fromView:nil]
                                                              inTextContainer:[self textContainer]
                                               fractionOfDistanceThroughGlyph:&partialFraction];
                    NSPoint glypthIndexPoint;
                    if ((partialFraction > 0.5) && ([string characterAtIndex:glyphIndex] != '\n')) {
                        NSRect glyphRect = [layoutManager boundingRectForGlyphRange:NSMakeRange(glyphIndex, 1)
                                                                    inTextContainer:[self textContainer]];
                        glypthIndexPoint = [layoutManager locationForGlyphAtIndex:glyphIndex];
                        glypthIndexPoint.x += NSWidth(glyphRect);
                    } else {
                        glypthIndexPoint = [layoutManager locationForGlyphAtIndex:glyphIndex];
                    }
                    NSRect lineRect = [layoutManager lineFragmentRectForGlyphAtIndex:glyphIndex effectiveRange:NULL];
                    NSRect insertionRect = NSMakeRect(glypthIndexPoint.x, lineRect.origin.y, 1, NSHeight(lineRect));
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
- (BOOL)performDragOperation:(id<NSDraggingInfo>)sender
// ------------------------------------------------------
{
    // ドロップによる編集で改行コードをLFに統一する
    // （その他の編集は、下記の通りの別の場所で置換している）
    // # テキスト編集時の改行コードの置換場所
    //  * ファイルオープン = CEDocument > setStringToEditor
    //  * スクリプト = CEEditorView > textView:shouldChangeTextInRange:replacementString:
    //  * キー入力 = CEEditorView > textView:shouldChangeTextInRange:replacementString:
    //  * ペースト = CETextView > readSelectionFromPasteboard:type:
    //  * ドロップ（別書類または別アプリから） = CETextView > readSelectionFromPasteboard:type:
    //  * ドロップ（同一書類内） = CETextView > performDragOperation:
    //  * 検索パネルでの置換 = (OgreKit) OgreTextViewPlainAdapter > replaceCharactersInRange:withOGString:
    
    // まず、自己内ドラッグかどうかのフラグを立てる
    [self setSelfDrop:([sender draggingSource] == self)];
    
    if ([self isSelfDrop]) {
        // （自己内ドラッグの場合には、改行コード置換を readSelectionFromPasteboard:type: 内で実行すると
        // アンドゥの登録で文字列範囲の計算が面倒なので、ここでPasteboardを書き換えてしまう）
        NSPasteboard *pboard = [sender draggingPasteboard];
        NSString *pboardType = [pboard availableTypeFromArray:[self pasteboardTypesForString]];
        if (pboardType) {
            NSString *string = [pboard stringForType:pboardType];
            if (string) {
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
    [self setSelfDrop:NO];
    
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
    [self setReadingFromPboard:YES];
    
    // ペーストされたか、他からテキストがドロップされた
    if (![self isSelfDrop] && [type isEqualToString:NSStringPboardType]) {
        // ペースト、他からのドロップによる編集で改行コードをLFに統一する
        // （その他の編集は、下記の通りの別の場所で置換している）
        // # テキスト編集時の改行コードの置換場所
        //  * ファイルオープン = CEDocument > setStringToEditor
        //  * スクリプト = CEEditorView > textView:shouldChangeTextInRange:replacementString:
        //  * キー入力 = CEEditorView > textView:shouldChangeTextInRange:replacementString:
        //  * ペースト = CETextView > readSelectionFromPasteboard:type:
        //  * ドロップ（別書類または別アプリから） = CETextView > readSelectionFromPasteboard:type:
        //  * ドロップ（同一書類内） = CETextView > performDragOperation:
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
        NSArray *fileDropDefs = [[NSUserDefaults standardUserDefaults] arrayForKey:CEDefaultFileDropArrayKey];
        NSArray *files = [pboard propertyListForType:NSFilenamesPboardType];
        NSURL *documentURL = [[[[self window] windowController] document] fileURL];
        
        for (NSString *path in files) {
            NSURL *absoluteURL = [NSURL fileURLWithPath:path];
            NSString *pathExtension = nil, *pathExtensionLower = nil, *pathExtensionUpper = nil;
            NSString *stringToDrop = nil;
            
            selectedRange = [self selectedRange];
            for (NSDictionary *definition in fileDropDefs) {
                NSArray *extensions = [definition[CEFileDropExtensionsKey] componentsSeparatedByString:@", "];
                pathExtension = [absoluteURL pathExtension];
                pathExtensionLower = [pathExtension lowercaseString];
                pathExtensionUpper = [pathExtension uppercaseString];
                
                if ([extensions containsObject:pathExtensionLower] ||
                    [extensions containsObject:pathExtensionUpper])
                {
                    stringToDrop = definition[CEFileDropFormatStringKey];
                }
            }
            if ([stringToDrop length] > 0) {
                NSString *relativePath;
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
                
                NSString *fileName = [absoluteURL lastPathComponent];
                NSString *fileNoSuffix = [fileName stringByDeletingPathExtension];
                NSString *dirName = [[absoluteURL URLByDeletingLastPathComponent] lastPathComponent];
                
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
    [self setReadingFromPboard:NO];
    
    return success;
}


// ------------------------------------------------------
/// マウスでのテキスト選択時の挙動を制御
- (NSRange)selectionRangeForProposedRange:(NSRange)proposedSelRange granularity:(NSSelectionGranularity)granularity
// ------------------------------------------------------
{
    // このメソッドは、Smultron のものを使用させていただきました。(2006.09.09)
    // This method is based on Smultron.(written by Peter Borg – http://smultron.sourceforge.net)
    // Smultron  Copyright (c) 2004-2005 Peter Borg, All rights reserved.
    // Smultron is released under GNU General Public License, http://www.gnu.org/copyleft/gpl.html
    
    if (granularity != NSSelectByWord || [[self string] length] == proposedSelRange.location) {  // If it's not a double-click return unchanged
        return [super selectionRangeForProposedRange:proposedSelRange granularity:granularity];
    }
    
    // do not continue custom process if selection contains multiple lines (for dragging event with double-click)
    if ([[[[self string] substringWithRange:proposedSelRange] componentsSeparatedByString:@"\n"] count] > 1) {
        return [super selectionRangeForProposedRange:proposedSelRange granularity:granularity];
    }
    
    NSString *completeString = [self string];
    NSInteger lengthOfString = [completeString length];
    if (lengthOfString == (NSInteger)proposedSelRange.location) { // To avoid crash if a double-click occurs after any text
        return [super selectionRangeForProposedRange:proposedSelRange granularity:granularity];
    }
    
    NSInteger location = [super selectionRangeForProposedRange:proposedSelRange granularity:NSSelectByCharacter].location;
    NSRange wordRange = [super selectionRangeForProposedRange:proposedSelRange granularity:NSSelectByWord];
    
    // 特定の文字を単語区切りとして扱う
    if (wordRange.length > 1) {
        NSString *word = [completeString substringWithRange:wordRange];
        NSScanner *scanner = [NSScanner scannerWithString:word];
        NSCharacterSet *breakCharacterSet = [NSCharacterSet characterSetWithCharactersInString:@".:"];
        
        NSRange newWrodRange = wordRange;
        while ([scanner scanUpToCharactersFromSet:breakCharacterSet intoString:nil]) {
            NSUInteger breakLocation = [scanner scanLocation];
            if (wordRange.location + breakLocation < location) {
                newWrodRange.location = wordRange.location + breakLocation + 1;
                newWrodRange.length = wordRange.length - (breakLocation + 1);
            } else {
                newWrodRange.length -= wordRange.length - breakLocation;
                break;
            }
            [scanner scanCharactersFromSet:breakCharacterSet intoString:nil];
        }
        return newWrodRange;
    }
    
    // ダブルクリックでの括弧内選択
    unichar beginBrace, endBrace;
    BOOL isEndBrace = NO;
    switch ([completeString characterAtIndex:location]) {
        case ')':
            isEndBrace = YES;
        case '(':
            beginBrace = '(';
            endBrace = ')';
            break;
            
        case '}':
            isEndBrace = YES;
        case '{':
            beginBrace = '{';
            endBrace = '}';
            break;
            
        case ']':
            isEndBrace = YES;
        case '[':
            beginBrace = '[';
            endBrace = ']';
            break;
            
        case '>':
            isEndBrace = YES;
        case '<':
            beginBrace = '<';
            endBrace = '>';
            break;
            
        default: {
            return wordRange;
        }
    }
    
    NSInteger originalLocation = location;
    NSUInteger skipMatchingBrace = 0;
    
    if (isEndBrace) {
        while (location--) {
            unichar characterToCheck = [completeString characterAtIndex:location];
            if (characterToCheck == beginBrace) {
                if (!skipMatchingBrace) {
                    return NSMakeRange(location, originalLocation - location + 1);
                } else {
                    skipMatchingBrace--;
                }
            } else if (characterToCheck == endBrace) {
                skipMatchingBrace++;
            }
        }
    } else {
        while (++location < lengthOfString) {
            unichar characterToCheck = [completeString characterAtIndex:location];
            if (characterToCheck == endBrace) {
                if (!skipMatchingBrace) {
                    return NSMakeRange(originalLocation, location - originalLocation + 1);
                } else {
                    skipMatchingBrace--;
                }
            } else if (characterToCheck == beginBrace) {
                skipMatchingBrace++;
            }
        }
    }
    NSBeep();
    
    // If it has a found a "starting" brace but not found a match, a double-click should only select the "starting" brace and not what it usually would select at a double-click
    return [super selectionRangeForProposedRange:NSMakeRange(proposedSelRange.location, 1) granularity:NSSelectByCharacter];
}


// ------------------------------------------------------
/// フォントパネルを更新
- (void)updateFontPanel
// ------------------------------------------------------
{
    // フォントのみをフォントパネルに渡す
    // -> super にやらせると、テキストカラーもフォントパネルに送り、フォントパネルがさらにカラーパネル（= カラーコードパネル）にそのテキストカラーを渡すので、
    // それを断つために自分で渡す
    [[NSFontManager sharedFontManager] setSelectedFont:[self font] isMultiple:NO];
}



#pragma mark Public Methods

//=======================================================
// Public method
//
//=======================================================

// ------------------------------------------------------
/// ディレイをかけて入力補完リストを表示
- (void)completeAfterDelay:(NSTimeInterval)delay
// ------------------------------------------------------
{
    if ([self completionTimer]) {
        [[self completionTimer] setFireDate:[NSDate dateWithTimeIntervalSinceNow:delay]];
    } else {
        [self setCompletionTimer:[NSTimer scheduledTimerWithTimeInterval:delay
                                                                  target:self
                                                                selector:@selector(completionWithTimer:)
                                                                userInfo:nil
                                                                 repeats:NO]];
    }
}


// ------------------------------------------------------
/// キー入力時の文字修飾辞書をセット
- (void)applyTypingAttributes
// ------------------------------------------------------
{
    [self setTypingAttributes:@{NSParagraphStyleAttributeName: [self paragraphStyle],
                                NSFontAttributeName: [self font],
                                NSForegroundColorAttributeName: [[self theme] textColor]}];
}


// ------------------------------------------------------
/// 選択文字列を置換
- (void)replaceSelectedStringTo:(NSString *)string scroll:(BOOL)needsScroll
// ------------------------------------------------------
{
    if (!string) { return; }
    
    NSRange selectedRange = [self selectedRange];
    NSString *actionName = (selectedRange.length > 0) ? @"Replace Text" : @"Insert Text";

    [self doInsertString:string
               withRange:selectedRange
            withSelected:NSMakeRange(selectedRange.location, [string length])
          withActionName:NSLocalizedString(actionName, nil)
                  scroll:needsScroll];
}


// ------------------------------------------------------
/// 全文字列を置換
- (void)replaceAllStringTo:(NSString *)string
// ------------------------------------------------------
{
    if (!string) { return; }
    
    [self doReplaceString:string
                withRange:NSMakeRange(0, [[self string] length])
             withSelected:NSMakeRange(0, [string length])
           withActionName:NSLocalizedString(@"Replace Text", nil)];
}


// ------------------------------------------------------
/// 選択文字列の後ろへ新規文字列を挿入
- (void)insertAfterSelection:(NSString *)string
// ------------------------------------------------------
{
    if (!string) { return; }

    [self doInsertString:string
               withRange:NSMakeRange(NSMaxRange([self selectedRange]), 0)
            withSelected:NSMakeRange(NSMaxRange([self selectedRange]), [string length])
          withActionName:NSLocalizedString(@"Insert Text", nil)
                  scroll:NO];
}


// ------------------------------------------------------
/// 末尾に新規文字列を追加
- (void)appendAllString:(NSString *)string
// ------------------------------------------------------
{
    if (!string) { return; }

    [self doInsertString:string
               withRange:NSMakeRange([[self string] length], 0)
            withSelected:NSMakeRange([[self string] length], [string length])
          withActionName:NSLocalizedString(@"Insert Text", nil)
                  scroll:NO];
}


// ------------------------------------------------------
/// カスタムキーバインドで文字列入力
- (void)insertCustomTextWithPatternNum:(NSInteger)patternNum
// ------------------------------------------------------
{
    if (patternNum < 0) { return; }
    
    NSArray *texts = [[NSUserDefaults standardUserDefaults] arrayForKey:CEDefaultInsertCustomTextArrayKey];

    if (patternNum < [texts count]) {
        NSString *string = texts[patternNum];

        [self doInsertString:string
                   withRange:[self selectedRange]
                withSelected:NSMakeRange([self selectedRange].location + [string length], 0)
              withActionName:NSLocalizedString(@"Insert Custom Text", nil)
                      scroll:YES];
    }
}


// ------------------------------------------------------
/// フォントをリセット
- (void)resetFont:(id)sender
// ------------------------------------------------------
{
    NSString *name = [[NSUserDefaults standardUserDefaults] stringForKey:CEDefaultFontNameKey];
    CGFloat size = (CGFloat)[[NSUserDefaults standardUserDefaults] doubleForKey:CEDefaultFontSizeKey];

    [self setFont:[NSFont fontWithName:name size:size]];
    [self updateLineNumberAndAdjustScroll];
}


// ------------------------------------------------------
/// 行間値をセットし、テキストと行番号を再描画
- (void)setNewLineSpacingAndUpdate:(CGFloat)lineSpacing
// ------------------------------------------------------
{
    if (lineSpacing == [self lineSpacing]) { return; }
    
    NSRange range = NSMakeRange(0, [[self string] length]);
    
    [self setLineSpacing:lineSpacing];
    // テキストを再描画
    [[self layoutManager] invalidateLayoutForCharacterRange:range isSoft:NO actualCharacterRange:nil];
    [self updateLineNumberAndAdjustScroll];
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
    NSDocument *document = [[[self window] windowController] document];
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
/// カラーリング設定を更新する
- (void)setTheme:(CETheme *)theme;
// ------------------------------------------------------
{
    [[self window] setBackgroundColor:[theme backgroundColor]];
    
    [self setBackgroundColor:[theme backgroundColor]];
    [self setTextColor:[theme textColor]];
    [self setHighlightLineColor:[theme lineHighLightColor]];
    [self setInsertionPointColor:[theme insertionPointColor]];
    [self setSelectedTextAttributes:@{NSBackgroundColorAttributeName: [theme selectionColor]}];
    
    // 背景色に合わせたスクローラのスタイルをセット
    NSInteger knobStyle = [theme isDarkTheme] ? NSScrollerKnobStyleLight : NSScrollerKnobStyleDefault;
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
    if (([menuItem action] == @selector(exchangeFullwidthRoman:)) ||
        ([menuItem action] == @selector(exchangeHalfwidthRoman:)) ||
        ([menuItem action] == @selector(exchangeKatakana:)) ||
        ([menuItem action] == @selector(exchangeHiragana:)) ||
        ([menuItem action] == @selector(normalizeUnicodeWithNFD:)) ||
        ([menuItem action] == @selector(normalizeUnicodeWithNFC:)) ||
        ([menuItem action] == @selector(normalizeUnicodeWithNFKD:)) ||
        ([menuItem action] == @selector(normalizeUnicodeWithNFKC:)))
    {
        return ([self selectedRange].length > 0);
        // （カラーコード編集メニューは常に有効）

    } else if ([menuItem action] == @selector(setLineSpacingFromMenu:)) {
        [menuItem setState:(([self lineSpacing] == (CGFloat)[[menuItem title] doubleValue] - 1.0) ? NSOnState : NSOffState)];
    } else if ([menuItem action] == @selector(changeTabWidth:)) {
        [menuItem setState:(([self tabWidth] == [menuItem tag]) ? NSOnState : NSOffState)];
    } else if ([menuItem action] == @selector(showSelectionInfo:)) {
        NSString *selection = [[self string] substringWithRange:[self selectedRange]];
        return ([selection numberOfComposedCharacters] == 1);
    } else if ([menuItem action] == @selector(toggleComment:)) {
        NSString *title = [self canUncomment] ? @"Uncomment Selection" : @"Comment Selection";
        [menuItem setTitle:NSLocalizedString(title, nil)];
        return ([self inlineCommentDelimiter] || [self blockCommentDelimiters]);
    }

    return [super validateMenuItem:menuItem];
}


// ------------------------------------------------------
/// ツールバーアイコンの有効／無効を制御
- (BOOL)validateToolbarItem:(NSToolbarItem *)theItem
// ------------------------------------------------------
{
    if ([theItem action] == @selector(toggleComment:)) {
        return ([self inlineCommentDelimiter] || [self blockCommentDelimiters]);
    }
    
    return YES;
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
    NSUInteger totalDeleted = 0;
    NSInteger newLocation = selectedRange.location, newLength = selectedRange.length;
    NSUInteger count = [lines count];

    // 選択区域を含む行をスキャンし、冒頭のスペース／タブを削除
    for (NSUInteger i = 0; i < count; i++) {
        NSUInteger numberOfDeleted = 0;
        NSMutableString *tmpLine = [lines[i] mutableCopy];
        BOOL spaceDeleted = NO;
        for (NSUInteger j = 0; j < shiftLength; j++) {
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
/// 選択範囲のコメントを切り替える
- (IBAction)toggleComment:(id)sender
// ------------------------------------------------------
{
    if ([self canUncomment]) {
        [self uncomment:self];
    } else {
        [self commentOut:self];
    }
}


// ------------------------------------------------------
/// 選択範囲をコメントアウトする
- (IBAction)commentOut:(id)sender
// ------------------------------------------------------
{
    if (![self blockCommentDelimiters] && ![self inlineCommentDelimiter]) { return; }
    
    // determine comment out target
    NSRange targetRange;
    if ([[NSUserDefaults standardUserDefaults] boolForKey:CEDefaultCommentsAtLineHeadKey]) {
        targetRange = [[self string] lineRangeForRange:[self selectedRange]];
    } else {
        targetRange = [self selectedRange];
    }
    // remove last return
    if (targetRange.length > 0 && [[self string] characterAtIndex:NSMaxRange(targetRange) - 1] == '\n') {
        targetRange.length--;
    }
    
    NSString *target = [[self string] substringWithRange:targetRange];
    NSString *beginDelimiter, *endDelimiter;
    NSString *spacer = [[NSUserDefaults standardUserDefaults] boolForKey:CEDefaultAppendsCommentSpacerKey] ? @" " : @"";
    NSString *newString;
    NSRange selected;
    NSUInteger addedChars = 0;
    
    // insert delimiters
    if ([self inlineCommentDelimiter]) {
        beginDelimiter = [self inlineCommentDelimiter];
        
        newString = [target stringByReplacingOccurrencesOfString:@"\n"
                                                      withString:[NSString stringWithFormat:@"\n%@%@", beginDelimiter, spacer]
                                                         options:0
                                                           range:NSMakeRange(0, [target length])];
        newString = [@[beginDelimiter, newString] componentsJoinedByString:spacer];
        addedChars = [newString length] - targetRange.length;
        
    } else if ([self blockCommentDelimiters]) {
        beginDelimiter = [self blockCommentDelimiters][CEBeginDelimiterKey];
        endDelimiter = [self blockCommentDelimiters][CEEndDelimiterKey];
        
        newString = [@[beginDelimiter, target, endDelimiter] componentsJoinedByString:spacer];
        addedChars = [beginDelimiter length] + [spacer length];
    }
    
    // selection
    if ([self selectedRange].length > 0) {
        selected = NSMakeRange(targetRange.location, [newString length]);
    } else {
        selected = NSMakeRange([self selectedRange].location + addedChars, 0);
    }
    
    // replace
    [self doReplaceString:newString
                withRange:targetRange
             withSelected:selected
           withActionName:NSLocalizedString(@"Comment Out", nil)];
}


// ------------------------------------------------------
/// 選択範囲のコメントをはずす
- (IBAction)uncomment:(id)sender
// ------------------------------------------------------
{
    if (![self blockCommentDelimiters] && ![self inlineCommentDelimiter]) { return; }
    
    BOOL hasUncommented = NO;
    
    // determine uncomment target
    NSRange targetRange;
    if ([[NSUserDefaults standardUserDefaults] boolForKey:CEDefaultCommentsAtLineHeadKey]) {
        targetRange = [[self string] lineRangeForRange:[self selectedRange]];
    } else {
        targetRange = [self selectedRange];
    }
    // remove last return
    if (targetRange.length > 0 && [[self string] characterAtIndex:NSMaxRange(targetRange) - 1] == '\n') {
        targetRange.length--;
    }
    
    NSString *target = [[self string] substringWithRange:targetRange];
    NSString *beginDelimiter, *endDelimiter;
    NSString *spacer = [[NSUserDefaults standardUserDefaults] boolForKey:CEDefaultAppendsCommentSpacerKey] ? @" " : @"";
    NSString *newString;
    NSUInteger removedChars = 0;
    
    // block comment
    if ([self blockCommentDelimiters]) {
        if ([target length] > 0) {
            beginDelimiter = [self blockCommentDelimiters][CEBeginDelimiterKey];
            endDelimiter = [self blockCommentDelimiters][CEEndDelimiterKey];
            
            // remove comment delimiters
            if ([target hasPrefix:beginDelimiter] && [target hasSuffix:endDelimiter]) {
                removedChars = [beginDelimiter length];
                newString = [target substringWithRange:NSMakeRange([beginDelimiter length],
                                                                   [target length] - [beginDelimiter length] - [endDelimiter length])];
                
                if ([spacer length] > 0 && [newString hasPrefix:spacer] && [newString hasSuffix:spacer]) {
                    newString = [newString substringWithRange:NSMakeRange(1, [newString length] - 2)];
                    removedChars++;
                }
                
                hasUncommented = YES;
            }
        }
    }
    
    // inline comment
    if (!hasUncommented) {
        beginDelimiter = [self inlineCommentDelimiter];
        
        // remove comment delimiters
        NSArray *lines = [target componentsSeparatedByString:@"\n"];
        NSMutableArray *newLines = [NSMutableArray array];
        for (NSString *line in lines) {
            NSString *newLine = [line copy];
            if ([line hasPrefix:beginDelimiter]) {
                newLine = [line substringFromIndex:[beginDelimiter length]];
                
                if ([spacer length] > 0 && [newLine hasPrefix:spacer]) {
                    newLine = [newLine substringFromIndex:[spacer length]];
                }
            }
            
            [newLines addObject:newLine];
            removedChars += [line length] - [newLine length];
        }
        
        newString = [newLines componentsJoinedByString:@"\n"];
    }
    
    // set selection
    NSRange selection;
    if ([self selectedRange].length > 0) {
        selection = NSMakeRange(targetRange.location, [newString length]);
    } else {
        selection = NSMakeRange([self selectedRange].location, 0);
        selection.location -= MIN(MIN(selection.location, selection.location - targetRange.location), removedChars);
    }
    
    [self doReplaceString:newString withRange:targetRange withSelected:selection
           withActionName:NSLocalizedString(@"Uncomment", nil)];
}


// ------------------------------------------------------
/// 選択範囲を含む行全体を選択する
- (IBAction)selectLines:(id)sender
// ------------------------------------------------------
{
    [self setSelectedRange:[[self string] lineRangeForRange:[self selectedRange]]];
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
/// 全角Roman文字へ変更
- (IBAction)exchangeFullwidthRoman:(id)sender
// ------------------------------------------------------
{
    NSRange selectedRange = [self selectedRange];
    
    if (selectedRange.length == 0) { return; }
    
    NSString *newStr =  [[[self string] substringWithRange:selectedRange] fullWidthRomanString];
    if (newStr) {
        [self doInsertString:newStr withRange:selectedRange
                withSelected:NSMakeRange(selectedRange.location, [newStr length])
              withActionName:NSLocalizedString(@"To Fullwidth (ja_JP/Roman)", nil) scroll:YES];
    }
}


// ------------------------------------------------------
/// 半角Roman文字へ変更
- (IBAction)exchangeHalfwidthRoman:(id)sender
// ------------------------------------------------------
{
    NSRange selectedRange = [self selectedRange];
    
    if (selectedRange.length == 0) { return; }
    
    NSString *newStr =  [[[self string] substringWithRange:selectedRange] halfWidthRomanString];
    if (newStr) {
        [self doInsertString:newStr withRange:selectedRange
                withSelected:NSMakeRange(selectedRange.location, [newStr length])
              withActionName:NSLocalizedString(@"To Halfwidth (ja_JP/Roman)", nil) scroll:YES];
    }
}


// ------------------------------------------------------
/// ひらがなをカタカナへ変更
- (IBAction)exchangeKatakana:(id)sender
// ------------------------------------------------------
{
    NSRange selectedRange = [self selectedRange];
    
    if (selectedRange.length == 0) { return; }
    
    NSString *newStr =  [[[self string] substringWithRange:selectedRange] katakanaString];
    if (newStr) {
        [self doInsertString:newStr withRange:selectedRange
                withSelected:NSMakeRange(selectedRange.location, [newStr length])
              withActionName:NSLocalizedString(@"Hiragana to Katakana (ja_JP)",@"") scroll:YES];
    }
}


// ------------------------------------------------------
/// カタカナをひらがなへ変更
- (IBAction)exchangeHiragana:(id)sender
// ------------------------------------------------------
{
    NSRange selectedRange = [self selectedRange];
    
    if (selectedRange.length == 0) { return; }
    
    NSString *newStr = [[[self string] substringWithRange:selectedRange] hiraganaString];
    if (newStr) {
        [self doInsertString:newStr withRange:selectedRange
                withSelected:NSMakeRange(selectedRange.location, [newStr length])
              withActionName:NSLocalizedString(@"Katakana to Hiragana (ja_JP)",@"") scroll:YES];
    }
}


// ------------------------------------------------------
/// Unicode正規化
- (IBAction)normalizeUnicodeWithNFD:(id)sender
// ------------------------------------------------------
{
    [self normalizeUnicodeWithForm:CEUnicodeNormalizationNFD];
}


// ------------------------------------------------------
/// Unicode正規化
- (IBAction)normalizeUnicodeWithNFC:(id)sender
// ------------------------------------------------------
{
    [self normalizeUnicodeWithForm:CEUnicodeNormalizationNFC];
}


// ------------------------------------------------------
/// Unicode正規化
- (IBAction)normalizeUnicodeWithNFKD:(id)sender
// ------------------------------------------------------
{
    [self normalizeUnicodeWithForm:CEUnicodeNormalizationNFKD];
}


// ------------------------------------------------------
/// Unicode正規化
- (IBAction)normalizeUnicodeWithNFKC:(id)sender
// ------------------------------------------------------
{
    [self normalizeUnicodeWithForm:CEUnicodeNormalizationNFKC];
}


// ------------------------------------------------------
/// 半角円マークを入力
- (IBAction)inputYenMark:(id)sender
// ------------------------------------------------------
{
    [super insertText:[NSString stringWithCharacters:&kYenMark length:1]];
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

        [self setNeedsUpdateOutlineMenuItemSelection:NO]; // 選択範囲変更後にメニュー選択項目が再選択されるオーバーヘッドを省く
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
    [self setNewLineSpacingAndUpdate:(CGFloat)[[sender title] doubleValue] - 1.0];  // title is line height
}


// ------------------------------------------------------
/// グリフ情報をポップオーバーで表示
- (IBAction)showSelectionInfo:(id)sender
// ------------------------------------------------------
{
    NSRange selectedRange = [self selectedRange];
    NSString *selectedString = [[self string] substringWithRange:selectedRange];
    CEGlyphPopoverController *popoverController = [[CEGlyphPopoverController alloc] initWithCharacter:selectedString];
    
    if (!popoverController) { return; }
    
    NSRange glyphRange = [[self layoutManager] glyphRangeForCharacterRange:selectedRange actualCharacterRange:NULL];
    NSRect selectedRect = [[self layoutManager] boundingRectForGlyphRange:glyphRange inTextContainer:[self textContainer]];
    NSPoint containerOrigin = [self textContainerOrigin];
    selectedRect.origin.x += containerOrigin.x;
    selectedRect.origin.y += containerOrigin.y - 6.0;
    selectedRect = [self convertRectToLayer:selectedRect];
    
    [popoverController showPopoverRelativeToRect:selectedRect ofView:self];
    [self showFindIndicatorForRange:NSMakeRange(selectedRange.location, 1)];
}



#pragma mark Private Methods

//=======================================================
// Private method
//
//=======================================================

// ------------------------------------------------------
/// 変更を監視するデフォルトキー
- (NSArray *)observedDefaultKeys
// ------------------------------------------------------
{
    return @[CEDefaultAutoExpandTabKey,
             CEDefaultSmartInsertAndDeleteKey,
             CEDefaultCheckSpellingAsTypeKey,
             CEDefaultEnableSmartQuotesKey];
}


// ------------------------------------------------------
/// ウインドウの透明設定が変更された
- (void)didWindowOpacityChange:(NSNotification *)notification
// ------------------------------------------------------
{
    // ウインドウが不透明な時は自前で背景を描画する（サブピクセルレンダリングを有効にするためには layer-backed で不透明なビューが必要）
    [self setDrawsBackground:[[self window] isOpaque]];
    
    if (NSAppKitVersionNumber >= NSAppKitVersionNumber10_8) { // on Mountain Lion and later
        // 半透明時にこれを有効にすると、ファイルサイズが大きいときにハングに近い状態になるため、
        // 暫定処置として不透明時にだけ有効にする。
        // 逆に不透明時に無効だと、ウインドウリサイズ時にビューが伸び縮みする (2014-10 by 1024jp)
        [[self layer] setNeedsDisplayOnBoundsChange:[[self window] isOpaque]];
    }
    
    [self setNeedsDisplay:YES];
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
/// 改行コード置換のためのPasteboardタイプ配列を返す
- (NSArray *)pasteboardTypesForString
// ------------------------------------------------------
{
    return @[NSPasteboardTypeString, (NSString *)kUTTypeUTF8PlainText];
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
    [[self lineNumberView] setNeedsDisplay:YES];
    
    // キャレット／選択範囲が見えるようにスクロール位置を調整
    [self scrollRangeToVisible:[self selectedRange]];
}


// ------------------------------------------------------
/// Pasetboard内文字列の改行コードを書類に設定されたものに置換する
- (void)replaceLineEndingToDocCharInPboard:(NSPasteboard *)pboard
// ------------------------------------------------------
{
    if (!pboard) { return; }

    OgreNewlineCharacter newlineChar = [[[[self window] windowController] document] lineEnding];

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


// ------------------------------------------------------
/// 選択範囲をコメント解除できるかを返す
- (BOOL)canUncomment
// ------------------------------------------------------
{
    if (![self blockCommentDelimiters] && ![self inlineCommentDelimiter]) { return NO; }
    
    // determine comment out target
    NSRange targetRange;
    if ([[NSUserDefaults standardUserDefaults] boolForKey:CEDefaultCommentsAtLineHeadKey]) {
        targetRange = [[self string] lineRangeForRange:[self selectedRange]];
    } else {
        targetRange = [self selectedRange];
    }
    // remove last return
    if (targetRange.length > 0 && [[self string] characterAtIndex:NSMaxRange(targetRange) - 1] == '\n') {
        targetRange.length--;
    }
    
    NSString *target = [[self string] substringWithRange:targetRange];
    
    if ([target length] == 0) { return NO; }
    
    if ([self blockCommentDelimiters]) {
        if ([target hasPrefix:[self blockCommentDelimiters][CEBeginDelimiterKey]] &&
            [target hasSuffix:[self blockCommentDelimiters][CEEndDelimiterKey]]) {
            return YES;
        }
    }
    
    if ([self inlineCommentDelimiter]) {
        NSArray *lines = [target componentsSeparatedByString:@"\n"];
        NSUInteger commentLineCount = 0;
        for (NSString *line in lines) {
            if ([line hasPrefix:[self inlineCommentDelimiter]]) {
                commentLineCount++;
            }
        }
        
        return commentLineCount == [lines count];
    }
    
    return NO;
}


// ------------------------------------------------------
/// 入力補完リストの表示
- (void)completionWithTimer:(NSTimer *)timer
// ------------------------------------------------------
{
    [self stopCompletionTimer];
    
    // abord if input is not specified (for Japanese input)
    if ([self hasMarkedText]) { return; }
    
    // abord if selected
    if ([self selectedRange].length > 0) { return; }
    
    // abord if caret is (probably) at the middle of a word
    NSUInteger nextCharIndex = NSMaxRange([self selectedRange]);
    if (nextCharIndex < [[self string] length]) {
        unichar nextChar = [[self string] characterAtIndex:nextCharIndex];
        if ([[NSCharacterSet alphanumericCharacterSet] characterIsMember:nextChar]) {
            return;
        }
    }
    
    // abord if previous character is blank
    NSUInteger location = [self selectedRange].location;
    if (location > 0) {
        unichar prevChar = [[self string] characterAtIndex:location - 1];
        if ([[NSCharacterSet whitespaceAndNewlineCharacterSet] characterIsMember:prevChar]) {
            return;
        }
    }
    
    [self complete:self];
}


// ------------------------------------------------------
/// Unicode正規化
- (void)normalizeUnicodeWithForm:(CEUnicodeNormalizationForm)form
// ------------------------------------------------------
{
    NSRange selectedRange = [self selectedRange];
    
    if (selectedRange.length == 0) { return; }
    
    NSString *originalStr = [[self string] substringWithRange:selectedRange];
    NSString *actionName = nil, *newStr = nil;
    
    switch (form) {
        case CEUnicodeNormalizationNFD:
            newStr = [originalStr decomposedStringWithCanonicalMapping];
            actionName = @"NFD";
            break;
        case CEUnicodeNormalizationNFC:
            newStr = [originalStr precomposedStringWithCanonicalMapping];
            actionName = @"NFC";
            break;
        case CEUnicodeNormalizationNFKD:
            newStr = [originalStr decomposedStringWithCompatibilityMapping];
            actionName = @"NFKD";
            break;
        case CEUnicodeNormalizationNFKC:
            newStr = [originalStr precomposedStringWithCompatibilityMapping];
            actionName = @"NFKC";
            break;
    }
    
    if (newStr) {
        [self doInsertString:newStr
                   withRange:selectedRange
                withSelected:NSMakeRange(selectedRange.location, [newStr length])
              withActionName:NSLocalizedString(actionName, nil)
                      scroll:YES];
    }
}


// ------------------------------------------------------
/// 入力補完タイマーを停止
- (void)stopCompletionTimer
// ------------------------------------------------------
{
    [[self completionTimer] invalidate];
    [self setCompletionTimer:nil];
}


// ------------------------------------------------------
/// インデントレベルを算出
- (NSUInteger)indentLevelOfString:(NSString *)string
// ------------------------------------------------------
{
    NSRange indentRange = [string rangeOfString:@"^[ \\t　]+" options:NSRegularExpressionSearch];
    
    if (indentRange.location == NSNotFound) { return 0; }
    
    NSString *indent = [string substringWithRange:indentRange];
    NSUInteger numberOfTabChars = [[indent componentsSeparatedByString:@"\t"] count] - 1;
    
    return numberOfTabChars + (([indent length] - numberOfTabChars) / [self tabWidth]);
}

@end
