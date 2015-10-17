/*
 
 CETextView.m
 
 CotEditor
 http://coteditor.com
 
 Created by nakamuxu on 2005-03-30.
 
 ------------
 This class is based on JSDTextView (written by James S. Derry – http://www.balthisar.com)
 JSDTextView is released as public domain.
 arranged by nakamuxu, Dec 2004.
 
 ------------------------------------------------------------------------------
 
 © 2004-2007 nakamuxu
 © 2014-2015 1024jp
 
 Licensed under the Apache License, Version 2.0 (the "License");
 you may not use this file except in compliance with the License.
 You may obtain a copy of the License at
 
 http://www.apache.org/licenses/LICENSE-2.0
 
 Unless required by applicable law or agreed to in writing, software
 distributed under the License is distributed on an "AS IS" BASIS,
 WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 See the License for the specific language governing permissions and
 limitations under the License.
 
 */

#import "CETextView.h"
#import "CEColorCodePanelController.h"
#import "CECharacterPopoverController.h"
#import "CEEditorScrollView.h"
#import "CEDocument.h"
#import "CEKeyBindingManager.h"
#import "CEScriptManager.h"
#import "CEWindow.h"
#import "NSString+JapaneseTransform.h"
#import "NSString+Normalization.h"
#import "Constants.h"


// constant
const NSInteger kNoMenuItem = -1;

NSString *_Nonnull const CESelectedRangesKey = @"selectedRange";
NSString *_Nonnull const CEVisibleRectKey = @"visibleRect";


@interface CETextView ()

@property (nonatomic) NSTimer *completionTimer;
@property (nonatomic, copy) NSString *particalCompletionWord;  // ユーザが実際に入力した補完の元になる文字列

@property (nonatomic) NSColor *highlightLineColor;  // カレント行ハイライト色

@end




#pragma mark -

@implementation CETextView

static NSPoint kTextContainerOrigin;


#pragma mark Superclass Methods

// ------------------------------------------------------
/// initialize class
+ (void)initialize
// ------------------------------------------------------
{
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
        
        kTextContainerOrigin = NSMakePoint((CGFloat)[defaults doubleForKey:CEDefaultTextContainerInsetWidthKey],
                                           (CGFloat)[defaults doubleForKey:CEDefaultTextContainerInsetHeightTopKey]);
    });
    
}


// ------------------------------------------------------
/// initialize instance
- (nonnull instancetype)initWithFrame:(NSRect)frameRect textContainer:(nullable NSTextContainer *)container
// ------------------------------------------------------
{
    self = [super initWithFrame:frameRect textContainer:container];
    if (self) {
        // set class identifier for window restoration
        [self setIdentifier:@"coreTextView"];
        
        NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
        
        // This method is partly based on Smultron's SMLTextView by Peter Borg. (2006-09-09)
        // Smultron 2 was distributed on <http://smultron.sourceforge.net> under the terms of the BSD license.
        // Copyright (c) 2004-2006 Peter Borg
        
        // set the width of every tab by first checking the size of the tab in spaces in the current font and then remove all tabs that sets automatically and then set the default tab stop distance
        _tabWidth = [defaults integerForKey:CEDefaultTabWidthKey];
        
        CGFloat fontSize = (CGFloat)[defaults doubleForKey:CEDefaultFontSizeKey];
        NSFont *font = [NSFont fontWithName:[defaults stringForKey:CEDefaultFontNameKey] size:fontSize];
        if (!font) {
            font = [NSFont systemFontOfSize:fontSize];
        }

        NSMutableParagraphStyle *paragraphStyle = [[NSParagraphStyle defaultParagraphStyle] mutableCopy];
        [paragraphStyle setTabStops:@[]];  // clear default tab stops
        [paragraphStyle setDefaultTabInterval:[self tabIntervalFromFont:font]];
        [self setDefaultParagraphStyle:paragraphStyle];
        // （NSParagraphStyle の lineSpacing を設定すればテキスト描画時の行間は制御できるが、
        // 「文書の1文字目に1バイト文字（または2バイト文字）を入力してある状態で先頭に2バイト文字（または1バイト文字）を
        // 挿入すると行間がズレる」問題が生じるため、CELayoutManager および CEATSTypesetter で制御している）

        // setup theme
        [self setTheme:[CETheme themeWithName:[defaults stringForKey:CEDefaultThemeKey]]];
        
        // set layer drawing policies
        [self setLayerContentsRedrawPolicy:NSViewLayerContentsRedrawOnSetNeedsDisplay];
        [self setLayerContentsPlacement:NSViewLayerContentsPlacementScaleAxesIndependently];
        
        // set values
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
        _needsUpdateOutlineMenuItemSelection = YES;
        
        [self applyTypingAttributes];
        
        // observe change of defaults
        for (NSString *key in [CETextView observedDefaultKeys]) {
            [[NSUserDefaults standardUserDefaults] addObserver:self
                                                    forKeyPath:key
                                                       options:NSKeyValueObservingOptionNew
                                                       context:NULL];
        }
    }

    return self;
}


// ------------------------------------------------------
/// clean up
- (void)dealloc
// ------------------------------------------------------
{
    for (NSString *key in [CETextView observedDefaultKeys]) {
        [[NSUserDefaults standardUserDefaults] removeObserver:self forKeyPath:key];
    }
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    [self stopCompletionTimer];
}


// ------------------------------------------------------
/// store UI state for the window restoration
- (void)encodeRestorableStateWithCoder:(nonnull NSCoder *)coder
// ------------------------------------------------------
{
    [super encodeRestorableStateWithCoder:coder];
    
    [coder encodeObject:[self selectedRanges] forKey:CESelectedRangesKey];
    [coder encodeRect:[self visibleRect] forKey:CEVisibleRectKey];
}


// ------------------------------------------------------
/// restore UI state on the window restoration
- (void)restoreStateWithCoder:(nonnull NSCoder *)coder
// ------------------------------------------------------
{
    [super restoreStateWithCoder:coder];
    
    if ([coder containsValueForKey:CEVisibleRectKey]) {
        NSRect visibleRect = [coder decodeRectForKey:CEVisibleRectKey];
        NSArray<NSValue *> *selectedRanges = [coder decodeObjectForKey:CESelectedRangesKey];
        
        // filter to avoid crash if the stored selected range is an invalid range
        if ([selectedRanges count] > 0) {
            NSUInteger length = [[self textStorage] length];
            selectedRanges = [selectedRanges filteredArrayUsingPredicate:[NSPredicate predicateWithBlock:^BOOL(id  _Nonnull evaluatedObject, NSDictionary<NSString *,id> * _Nullable bindings) {
                NSRange range = [evaluatedObject rangeValue];
                
                return NSMaxRange(range) <= length;
            }]];
            
            if ([selectedRanges count] > 0) {
                [self setSelectedRanges:selectedRanges];
            }
        }
        
        // perform scroll on the next run-loop
        __unsafe_unretained typeof(self) weakSelf = self;  // NSTextView cannot be weak
        dispatch_async(dispatch_get_main_queue(), ^{
            typeof(self) self = weakSelf;  // strong self
            if (!self) { return; }
            
            [self scrollRectToVisible:visibleRect];
        });
    }
}


// ------------------------------------------------------
/// first responder になれるかを返す
- (BOOL)becomeFirstResponder
// ------------------------------------------------------
{
    [[(CEWindowController *)[[self window] windowController] editor] setFocusedTextView:self];
    
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
    
    // ウインドウの透明フラグを監視する
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(didWindowOpacityChange:)
                                                 name:CEWindowOpacityDidChangeNotification
                                               object:[self window]];
}


// ------------------------------------------------------
/// キー押下を取得
- (void)keyDown:(nonnull NSEvent *)theEvent
// ------------------------------------------------------
{
    NSString *charIgnoringMod = [theEvent charactersIgnoringModifiers];
    // IM で日本語入力変換中でないときのみ追加テキストキーバインディングを実行
    if (![self hasMarkedText] && charIgnoringMod) {
        NSString *selectorStr = [[CEKeyBindingManager sharedManager] selectorStringWithKeyEquivalent:charIgnoringMod
                                                                                       modifierFrags:[theEvent modifierFlags]];
        NSInteger length = [selectorStr length];
        if (selectorStr && (length > 0)) {
            if (([selectorStr hasPrefix:@"insertCustomText"]) && (length == 20)) {
                NSInteger patternNumber = [[selectorStr substringFromIndex:17] integerValue];
                [self insertCustomTextWithPatternNumber:patternNumber];
            } else {
                [self doCommandBySelector:NSSelectorFromString(selectorStr)];
            }
            return;
        }
    }
    
    [super keyDown:theEvent];
}


// ------------------------------------------------------
/// on inputting text (NSTextInputClient Protocol)
- (void)insertText:(nonnull id)aString replacementRange:(NSRange)replacementRange
// ------------------------------------------------------
{
    // do not use this method for programmatical insertion.
    
    // cast NSAttributedString to NSString in order to make sure input string is plain-text
    NSString *string = [aString isKindOfClass:[NSAttributedString class]] ? [aString string] : aString;
    
    // swap '¥' with '\' if needed
    if ([[NSUserDefaults standardUserDefaults] boolForKey:CEDefaultSwapYenAndBackSlashKey] && ([string length] == 1)) {
        NSString *yen = [NSString stringWithCharacters:&kYenMark length:1];
        
        if ([string isEqualToString:@"\\"]) {
            [super insertText:yen replacementRange:replacementRange];
            return;
        } else if ([string isEqualToString:yen]) {
            [super insertText:@"\\" replacementRange:replacementRange];
            return;
        }
    }
    
    // smart outdent with '}' charcter
    if ([[NSUserDefaults standardUserDefaults] boolForKey:CEDefaultAutoIndentKey] &&
        [[NSUserDefaults standardUserDefaults] boolForKey:CEDefaultEnableSmartIndentKey] &&
        (replacementRange.length == 0) && [string isEqualToString:@"}"])
    {
        NSString *wholeString = [self string];
        NSUInteger insretionLocation = NSMaxRange([self selectedRange]);
        NSRange lineRange = [wholeString lineRangeForRange:NSMakeRange(insretionLocation, 0)];
        NSString *lineStr = [wholeString substringWithRange:lineRange];
        
        // decrease indent level if the line is consists of only whitespaces
        if ([lineStr rangeOfString:@"^[ \\t　]+\\n?$"
                           options:NSRegularExpressionSearch
                             range:NSMakeRange(0, [lineStr length])].location != NSNotFound)
        {
            // find correspondent opening-brace
            NSInteger precedingLocation = insretionLocation - 1;
            NSUInteger skipMatchingBrace = 0;
            
            while (precedingLocation--) {
                unichar characterToCheck = [wholeString characterAtIndex:precedingLocation];
                if (characterToCheck == '{') {
                    if (skipMatchingBrace) {
                        skipMatchingBrace--;
                    } else {
                        break;  // found
                    }
                } else if (characterToCheck == '}') {
                    skipMatchingBrace++;
                }
            }
            
            // outdent
            if (precedingLocation >= 0) {
                NSRange precedingLineRange = [wholeString lineRangeForRange:NSMakeRange(precedingLocation, 0)];
                NSString *precedingLineStr = [wholeString substringWithRange:precedingLineRange];
                NSUInteger desiredLevel = [self indentLevelOfString:precedingLineStr];
                NSUInteger currentLevel = [self indentLevelOfString:lineStr];
                NSUInteger levelToReduce = currentLevel - desiredLevel;
                
                while (levelToReduce--) {
                    [self deleteBackward:self];
                }
            }
        }
    }
    
    [super insertText:string replacementRange:replacementRange];
    
    // auto completion
    if ([[NSUserDefaults standardUserDefaults] boolForKey:CEDefaultAutoCompleteKey]) {
        [self completeAfterDelay:[[NSUserDefaults standardUserDefaults] doubleForKey:CEDefaultAutoCompletionDelayKey]];
    }
}


// ------------------------------------------------------
/// タブ入力、タブを展開
- (void)insertTab:(nullable id)sender
// ------------------------------------------------------
{
    if ([self isAutoTabExpandEnabled]) {
        NSInteger tabWidth = [self tabWidth];
        NSInteger column = [self columnOfLocation:[self selectedRange].location expandsTab:YES];
        NSInteger length = tabWidth - ((column + tabWidth) % tabWidth);
        NSMutableString *spaces = [NSMutableString string];

        while (length--) {
            [spaces appendString:@" "];
        }
        [super insertText:spaces replacementRange:[self selectedRange]];
        
    } else {
        [super insertTab:sender];
    }
}


// ------------------------------------------------------
/// 改行コード入力、オートインデント実行
- (void)insertNewline:(nullable id)sender
// ------------------------------------------------------
{
    if (![[NSUserDefaults standardUserDefaults] boolForKey:CEDefaultAutoIndentKey]) {
        return [super insertNewline:sender];
    }
    
    NSRange selectedRange = [self selectedRange];
    NSRange lineRange = [[self string] lineRangeForRange:selectedRange];
    NSString *lineStr = [[self string] substringWithRange:NSMakeRange(lineRange.location,
                                                                      NSMaxRange(selectedRange) - lineRange.location)];
    NSRange indentRange = [lineStr rangeOfString:@"^[ \\t　]+" options:NSRegularExpressionSearch];
    
    // インデントを選択状態で改行入力した時は置換とみなしてオートインデントしない 2008-12-13
    if (NSMaxRange(selectedRange) >= (selectedRange.location + NSMaxRange(indentRange))) {
        return [super insertNewline:sender];
    }
    
    NSString *indent = @"";
    BOOL shouldIncreaseIndentLevel = NO;
    BOOL shouldExpandBlock = NO;
    
    if (indentRange.location != NSNotFound) {
        indent = [lineStr substringWithRange:indentRange];
    }
    
    // calculation for smart indent
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
    }
    
    [super insertNewline:sender];
    
    // auto indent
    if ([indent length] > 0) {
        [super insertText:indent replacementRange:[self selectedRange]];
    }
    
    // smart indent
    if (shouldExpandBlock) {
        [self insertTab:sender];
        NSRange selection = [self selectedRange];
        [super insertNewline:sender];
        [super insertText:indent replacementRange:[self selectedRange]];
        [self setSelectedRange:selection];
        
    } else if (shouldIncreaseIndentLevel) {
        [self insertTab:sender];
    }
}


// ------------------------------------------------------
/// デリート、タブを展開しているときのスペースを調整削除
- (void)deleteBackward:(nullable id)sender
// ------------------------------------------------------
{
    NSRange selectedRange = [self selectedRange];
    if (selectedRange.length == 0 && [self isAutoTabExpandEnabled]) {
        NSUInteger tabWidth = [self tabWidth];
        NSInteger column = [self columnOfLocation:selectedRange.location expandsTab:YES];
        NSInteger length = tabWidth - ((column + tabWidth) % tabWidth);
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
    [super deleteBackward:sender];
}


// ------------------------------------------------------
/// コンテキストメニューを返す
- (nullable NSMenu *)menuForEvent:(nonnull NSEvent *)theEvent
// ------------------------------------------------------
{
    NSMenu *menu = [super menuForEvent:theEvent];

    // remove unwanted "Font" menu and its submenus
    [menu removeItem:[menu itemWithTitle:NSLocalizedString(@"Font", nil)]];
    
    // add "Inspect Character" menu item if single character is selected
    if ([[[self string] substringWithRange:[self selectedRange]] numberOfComposedCharacters] == 1) {
        [menu insertItemWithTitle:NSLocalizedString(@"Inspect Character", nil)
                              action:@selector(showSelectionInfo:)
                       keyEquivalent:@""
                             atIndex:1];
    }
    
    // add "Select All" menu item
    NSInteger pasteIndex = [menu indexOfItemWithTarget:nil andAction:@selector(paste:)];
    if (pasteIndex != kNoMenuItem) {
        [menu insertItemWithTitle:NSLocalizedString(@"Select All", nil)
                           action:@selector(selectAll:) keyEquivalent:@""
                          atIndex:(pasteIndex + 1)];
    }
    
    // append a separator
    [menu addItem:[NSMenuItem separatorItem]];
    
    // append Script menu
    NSMenu *scriptMenu = [[CEScriptManager sharedManager] contexualMenu];
    if (scriptMenu) {
        if ([[NSUserDefaults standardUserDefaults] boolForKey:CEDefaultInlineContextualScriptMenuKey]) {
            [menu addItem:[NSMenuItem separatorItem]];
            [[[menu itemArray] lastObject] setTag:CEScriptMenuItemTag];
            
            for (NSMenuItem *item in [scriptMenu itemArray]) {
                NSMenuItem *addItem = [item copy];
                [addItem setTag:CEScriptMenuItemTag];
                [menu addItem:addItem];
            }
            [menu addItem:[NSMenuItem separatorItem]];
            
        } else {
            NSMenuItem *item = [[NSMenuItem alloc] initWithTitle:@"" action:nil keyEquivalent:@""];
            [item setImage:[NSImage imageNamed:@"ScriptTemplate"]];
            [item setTag:CEScriptMenuItemTag];
            [item setSubmenu:scriptMenu];
            [menu addItem:item];
        }
    }
    
    return menu;
}


// ------------------------------------------------------
/// フォント変更
- (void)changeFont:(nullable id)sender
// ------------------------------------------------------
{
    // (引数"sender"はNSFontManegerのインスタンス)
    NSFont *newFont = [sender convertFont:[self font]];

    [self setFont:newFont];
    [self setNeedsDisplayInRect:[self visibleRect] avoidAdditionalLayout:YES];  // 最下行以下のページガイドの描画が残るための措置 (2009-02-14)
}


// ------------------------------------------------------
/// フォントを設定
- (void)setFont:(nullable NSFont *)font
// ------------------------------------------------------
{
// 複合フォントで行間が等間隔でなくなる問題を回避するため、CELayoutManager にもフォントを持たせておく。
// （CELayoutManager で [[self firstTextView] font] を使うと、「1バイトフォントを指定して日本語が入力されている」場合に
// 日本語フォント名を返してくることがあるため、CELayoutManager からは [textView font] を使わない）
    
    [(CELayoutManager *)[self layoutManager] setTextFont:font];
    [super setFont:font];
    
    NSMutableParagraphStyle *paragraphStyle = [[self defaultParagraphStyle] mutableCopy];
    [paragraphStyle setDefaultTabInterval:[self tabIntervalFromFont:font]];
    [self setDefaultParagraphStyle:paragraphStyle];
    
    [self applyTypingAttributes];
}


// ------------------------------------------------------
/// タブ幅を変更
- (void)setTabWidth:(NSUInteger)tabWidth
// ------------------------------------------------------
{
    _tabWidth = tabWidth;
    [self setFont:[self font]];  // force re-layout with new width
}


// ------------------------------------------------------
/// テキストコンテナの原点（左上）座標を返す
- (NSPoint)textContainerOrigin
// ------------------------------------------------------
{
    return kTextContainerOrigin;
}


// ------------------------------------------------------
/// ビュー内の背景を描画
- (void)drawViewBackgroundInRect:(NSRect)rect
// ------------------------------------------------------
{
    [super drawViewBackgroundInRect:rect];
    
    // draw current line highlight
    if (NSIntersectsRect(rect, [self highlightLineRect])) {
        [[self highlightLineColor] set];
        [NSBezierPath fillRect:[self highlightLineRect]];
    }
    
    // avoid rimaining dropshadow from letters on Mountain Lion (2015-02 by 1024jp)
    if (NSAppKitVersionNumber < NSAppKitVersionNumber10_9 && ![[self window] isOpaque]) {
        [[self window] invalidateShadow];
    }
}


// ------------------------------------------------------
/// ビュー内を描画
- (void)drawRect:(NSRect)dirtyRect
// ------------------------------------------------------
{
    [super drawRect:dirtyRect];
    
    // draw page guide
    if ([self showsPageGuide]) {
        CGFloat column = (CGFloat)[[NSUserDefaults standardUserDefaults] doubleForKey:CEDefaultPageGuideColumnKey];
        
        if ((column < kMinPageGuideColumn) || (column > kMaxPageGuideColumn)) {
            return;
        }
        
        NSFont *font = [(CELayoutManager *)[self layoutManager] textFont];
        font = [font screenFont] ? : font;
        CGFloat charWidth = [font advancementForGlyph:(NSGlyph)' '].width;
        
        CGFloat inset = [self textContainerOrigin].x;
        CGFloat linePadding = [[self textContainer] lineFragmentPadding];
        CGFloat x = floor(charWidth * column + inset + linePadding) + 2.5;  // +2px for adjustment
        
        [[[self textColor] colorWithAlphaComponent:0.2] set];
        [NSBezierPath strokeLineFromPoint:NSMakePoint(x, NSMinY(dirtyRect))
                                  toPoint:NSMakePoint(x, NSMaxY(dirtyRect))];
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
    
    if (NSAppKitVersionNumber >= NSAppKitVersionNumber10_10) { return; }
    // The following additional scroll adjustment might be no more required thanks to the changing on Yosemite.
    // cf.: NSScrollView section in AppKit Release Notes for OS X v10.10
    
    // 完全にスクロールさせる
    // （setTextContainerInset で上下に空白領域を挿入している関係で、ちゃんとスクロールしない場合があることへの対策）
    NSUInteger length = [[self string] length];
    NSRect rect = NSZeroRect;
    
    if (length == range.location) {
        rect = [[self layoutManager] extraLineFragmentRect];
    } else if (length > range.location) {
        NSString *tailStr = [[self string] substringFromIndex:range.location];
        if ([tailStr detectNewLineType] != CENewLineNone) {
            return;
        }
    }
    
    if (NSEqualRects(rect, NSZeroRect)) {
        NSRange targetRange = [[self string] lineRangeForRange:range];
        NSRange glyphRange = [[self layoutManager] glyphRangeForCharacterRange:targetRange actualCharacterRange:nil];
        rect = [[self layoutManager] lineFragmentRectForGlyphAtIndex:(NSMaxRange(glyphRange) - 1)
                                                      effectiveRange:nil
                                             withoutAdditionalLayout:YES];
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
        // 折り返しを再セット
        if ([[self textContainer] containerSize].width != CGFLOAT_MAX) {
            [[self textContainer] setContainerSize:NSMakeSize(0, CGFLOAT_MAX)];
        }
    }
    
    [super setLayoutOrientation:theOrientation];
}


// ------------------------------------------------------
/// Pasetboard内文字列の改行コードを書類に設定されたものに置換する
- (BOOL)writeSelectionToPasteboard:(NSPasteboard *)pboard types:(NSArray<NSString *> *)types
// ------------------------------------------------------
{
    BOOL success = [super writeSelectionToPasteboard:pboard types:types];
    
    CENewLineType newLineType = [[[[self window] windowController] document] lineEnding];
    
    if (newLineType == CENewLineLF || newLineType == CENewLineNone) { return success; }
    
    for (NSString *type in types) {
        NSString *string = [pboard stringForType:type];
        if (string) {
            [pboard setString:[string stringByReplacingNewLineCharacersWith:newLineType]
                      forType:type];
        }
    }
    
    return success;
}


// ------------------------------------------------------
/// ペーストまたはドロップされたアイテムに応じて挿入する文字列をNSPasteboardから読み込む (involed in `performDragOperation:`)
- (BOOL)readSelectionFromPasteboard:(nonnull NSPasteboard *)pboard type:(nonnull NSString *)type
// ------------------------------------------------------
{
    // on file drop
    if ([type isEqualToString:NSFilenamesPboardType]) {
        NSArray<NSDictionary<NSString *, NSString *> *> *fileDropDefs = [[NSUserDefaults standardUserDefaults] arrayForKey:CEDefaultFileDropArrayKey];
        NSArray<NSString *> *files = [pboard propertyListForType:NSFilenamesPboardType];
        NSURL *documentURL = [[[[self window] windowController] document] fileURL];
        NSMutableString *replacementString = [NSMutableString string];
        
        for (NSString *path in files) {
            NSURL *absoluteURL = [NSURL fileURLWithPath:path];
            NSString *pathExtension = [absoluteURL pathExtension];
            NSString *stringToDrop = nil;
            
            // find matched template for path extension
            for (NSDictionary<NSString *, NSString *> *definition in fileDropDefs) {
                NSArray<NSString *> *extensions = [definition[CEFileDropExtensionsKey] componentsSeparatedByString:@", "];
                
                if ([extensions containsObject:[pathExtension lowercaseString]] ||
                    [extensions containsObject:[pathExtension uppercaseString]])
                {
                    stringToDrop = definition[CEFileDropFormatStringKey];
                }
            }
            
            // add jsut absolute path if no specific setting for the file type found
            if ([stringToDrop length] == 0) {
                [replacementString appendString:[absoluteURL path]];
                
                continue;
            }
            
            // build relative path
            NSString *relativePath;
            if (documentURL && ![documentURL isEqual:absoluteURL]) {
                NSArray<NSString *> *docPathComponents = [documentURL pathComponents];
                NSArray<NSString *> *droppedPathComponents = [absoluteURL pathComponents];
                NSMutableArray<NSString *> *relativeComponents = [NSMutableArray array];
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
            
            // replace template
            stringToDrop = [stringToDrop stringByReplacingOccurrencesOfString:CEFileDropAbsolutePathToken
                                                                   withString:[absoluteURL path]];
            stringToDrop = [stringToDrop stringByReplacingOccurrencesOfString:CEFileDropRelativePathToken
                                                                   withString:relativePath];
            stringToDrop = [stringToDrop stringByReplacingOccurrencesOfString:CEFileDropFilenameToken
                                                                   withString:[absoluteURL lastPathComponent]];
            stringToDrop = [stringToDrop stringByReplacingOccurrencesOfString:CEFileDropFilenameNosuffixToken
                                                                   withString:[[absoluteURL lastPathComponent] stringByDeletingPathExtension]];
            stringToDrop = [stringToDrop stringByReplacingOccurrencesOfString:CEFileDropFileextensionToken
                                                                   withString:pathExtension];
            stringToDrop = [stringToDrop stringByReplacingOccurrencesOfString:CEFileDropFileextensionLowerToken
                                                                   withString:[pathExtension lowercaseString]];
            stringToDrop = [stringToDrop stringByReplacingOccurrencesOfString:CEFileDropFileextensionUpperToken
                                                                   withString:[pathExtension uppercaseString]];
            stringToDrop = [stringToDrop stringByReplacingOccurrencesOfString:CEFileDropDirectoryToken
                                                                   withString:[[absoluteURL URLByDeletingLastPathComponent] lastPathComponent]];
            
            // get image dimension if needed
            NSImageRep *imageRep = [NSImageRep imageRepWithContentsOfURL:absoluteURL];
            if (imageRep) {
                // NSImage の size では dpi をも考慮されたサイズが返ってきてしまうので NSImageRep を使う
                stringToDrop = [stringToDrop stringByReplacingOccurrencesOfString:CEFileDropImagewidthToken
                                                                       withString:[NSString stringWithFormat:@"%zd", [imageRep pixelsWide]]];
                stringToDrop = [stringToDrop stringByReplacingOccurrencesOfString:CEFileDropImagehightToken
                                                                       withString:[NSString stringWithFormat:@"%zd", [imageRep pixelsHigh]]];
            }
            
            [replacementString appendString:stringToDrop];
        }
        
        // insert drop text to view
        if ([self shouldChangeTextInRange:[self selectedRange] replacementString:replacementString]) {
            [self replaceCharactersInRange:[self selectedRange] withString:replacementString];
            [self didChangeText];
            return YES;
        }
    }
    
    return [super readSelectionFromPasteboard:pboard type:type];
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


// ------------------------------------------------------
/// let line number view update
- (void)updateRuler
// ------------------------------------------------------
{
    [(CEEditorScrollView *)[self enclosingScrollView] invalidateLineNumber];
}



#pragma mark Protocol

//=======================================================
// NSKeyValueObserving Protocol
//=======================================================

// ------------------------------------------------------
/// ユーザ設定の変更を反映する
- (void)observeValueForKeyPath:(nullable NSString *)keyPath ofObject:(nullable id)object change:(nullable NSDictionary<NSString *, id> *)change context:(nullable void *)context
// ------------------------------------------------------
{
    id newValue = change[NSKeyValueChangeNewKey];
    
    if ([keyPath isEqualToString:CEDefaultAutoExpandTabKey]) {
        [self setAutoTabExpandEnabled:[newValue boolValue]];
        
    } else if ([keyPath isEqualToString:CEDefaultSmartInsertAndDeleteKey]) {
        [self setSmartInsertDeleteEnabled:[newValue boolValue]];
        
    } else if ([keyPath isEqualToString:CEDefaultCheckSpellingAsTypeKey]) {
        [self setContinuousSpellCheckingEnabled:[newValue boolValue]];
        
    } else if ([keyPath isEqualToString:CEDefaultEnablesHangingIndentKey] ||
               [keyPath isEqualToString:CEDefaultHangingIndentWidthKey])
    {
        NSRange wholeRange = NSMakeRange(0, [[self string] length]);
        if ([keyPath isEqualToString:CEDefaultEnablesHangingIndentKey] && ![newValue boolValue]) {
            // reset all headIndent
            NSMutableParagraphStyle *paragraphStyle = [[self typingAttributes][NSParagraphStyleAttributeName] mutableCopy];
            [paragraphStyle setHeadIndent:0];
            [[self textStorage] addAttribute:NSParagraphStyleAttributeName value:paragraphStyle range:wholeRange];
        } else {
            [(CELayoutManager *)[self layoutManager] invalidateIndentInRange:wholeRange];
        }
    
    } else if ([keyPath isEqualToString:CEDefaultEnableSmartQuotesKey]) {
        if ([self respondsToSelector:@selector(setAutomaticQuoteSubstitutionEnabled:)]) {  // only on OS X 10.9 and later
            [self setAutomaticQuoteSubstitutionEnabled:[newValue boolValue]];
            [self setAutomaticDashSubstitutionEnabled:[newValue boolValue]];
        }
    }
}


//=======================================================
// NSMenuValidation Protocol
//=======================================================

// ------------------------------------------------------
/// メニューの有効／無効を制御
- (BOOL)validateMenuItem:(nonnull NSMenuItem *)menuItem
// ------------------------------------------------------
{
    if (([menuItem action] == @selector(exchangeFullwidthRoman:)) ||
        ([menuItem action] == @selector(exchangeHalfwidthRoman:)) ||
        ([menuItem action] == @selector(exchangeKatakana:)) ||
        ([menuItem action] == @selector(exchangeHiragana:)) ||
        ([menuItem action] == @selector(normalizeUnicodeWithNFD:)) ||
        ([menuItem action] == @selector(normalizeUnicodeWithNFC:)) ||
        ([menuItem action] == @selector(normalizeUnicodeWithNFKD:)) ||
        ([menuItem action] == @selector(normalizeUnicodeWithNFKC:)) ||
        ([menuItem action] == @selector(normalizeUnicodeWithNFKCCF:)) ||
        ([menuItem action] == @selector(normalizeUnicodeWithModifiedNFD:)))
    {
        return ([self selectedRange].length > 0);
        // （カラーコード編集メニューは常に有効）
        
    } else if ([menuItem action] == @selector(changeLineHeight:)) {
        CGFloat lineSpacing = [[menuItem title] doubleValue] - 1.0;
        [menuItem setState:(CEIsAlmostEqualCGFloats([self lineSpacing], lineSpacing) ? NSOnState : NSOffState)];
    } else if ([menuItem action] == @selector(changeTabWidth:)) {
        [menuItem setState:(([self tabWidth] == [menuItem tag]) ? NSOnState : NSOffState)];
    } else if ([menuItem action] == @selector(showSelectionInfo:)) {
        NSString *selection = [[self string] substringWithRange:[self selectedRange]];
        return ([selection numberOfComposedCharacters] == 1);
    } else if ([menuItem action] == @selector(toggleComment:)) {
        NSString *title = [self canUncommentRange:[self selectedRange]] ? @"Uncomment Selection" : @"Comment Selection";
        [menuItem setTitle:NSLocalizedString(title, nil)];
        return ([self inlineCommentDelimiter] || [self blockCommentDelimiters]);
    }
    
    return [super validateMenuItem:menuItem];
}


//=======================================================
// NSToolbarItemValidation Protocol
//=======================================================

// ------------------------------------------------------
/// ツールバーアイコンの有効／無効を制御
- (BOOL)validateToolbarItem:(nonnull NSToolbarItem *)theItem
// ------------------------------------------------------
{
    if ([theItem action] == @selector(toggleComment:)) {
        return ([self inlineCommentDelimiter] || [self blockCommentDelimiters]);
    }
    
    return YES;
}



#pragma mark Public Methods

// ------------------------------------------------------
/// treat programmatic text insertion
- (void)insertString:(nonnull NSString *)string
// ------------------------------------------------------
{
    NSRange replacementRange = [self selectedRange];
    
    if ([self shouldChangeTextInRange:replacementRange replacementString:string]) {
        [self replaceCharactersInRange:replacementRange withString:string];
        [self setSelectedRange:NSMakeRange(replacementRange.location, [string length])];
        
        NSString *actionName = (replacementRange.length > 0) ? @"Replace Text" : @"Insert Text";
        [[self undoManager] setActionName:NSLocalizedString(actionName, nil)];
        
        [self didChangeText];
    }
}


// ------------------------------------------------------
/// insert given string just after current selection and select inserted range
- (void)insertStringAfterSelection:(nonnull NSString *)string
// ------------------------------------------------------
{
    NSRange replacementRange = NSMakeRange(NSMaxRange([self selectedRange]), 0);
    
    if ([self shouldChangeTextInRange:replacementRange replacementString:string]) {
        [self replaceCharactersInRange:replacementRange withString:string];
        [self setSelectedRange:NSMakeRange(replacementRange.location, [string length])];
        
        [[self undoManager] setActionName:NSLocalizedString(@"Insert Text", nil)];
        
        [self didChangeText];
    }
}


// ------------------------------------------------------
/// swap whole current string with given string and select inserted range
- (void)replaceAllStringWithString:(nonnull NSString *)string
// ------------------------------------------------------
{
    NSRange replacementRange = NSMakeRange(0, [[self string] length]);
    
    if ([self shouldChangeTextInRange:replacementRange replacementString:string]) {
        [self replaceCharactersInRange:replacementRange withString:string];
        [self setSelectedRange:NSMakeRange(replacementRange.location, [string length])];
        
        [[self undoManager] setActionName:NSLocalizedString(@"Replace Text", nil)];
        
        [self didChangeText];
    }
}


// ------------------------------------------------------
/// append string at the end of the whole string and select inserted range
- (void)appendString:(nonnull NSString *)string
// ------------------------------------------------------
{
    NSRange replacementRange = NSMakeRange([[self string] length], 0);
    
    if ([self shouldChangeTextInRange:replacementRange replacementString:string]) {
        [self replaceCharactersInRange:replacementRange withString:string];
        [self setSelectedRange:NSMakeRange(replacementRange.location, [string length])];
        
        [[self undoManager] setActionName:NSLocalizedString(@"Insert Text", nil)];
        
        [self didChangeText];
    }
}


// ------------------------------------------------------
/// 行間値をセットし、テキストと行番号を再描画
- (void)setLineSpacingAndUpdate:(CGFloat)lineSpacing
// ------------------------------------------------------
{
    if (lineSpacing == [self lineSpacing]) { return; }
    
    [self setLineSpacing:lineSpacing];
    
    // redraw
    NSRange range = NSMakeRange(0, [[self string] length]);
    [[self layoutManager] invalidateLayoutForCharacterRange:range actualCharacterRange:nil];
    
    // 行番号を強制的に更新（スクロール位置が調整されない時は再描画が行われないため）
    [self updateRuler];
    
    // キャレット／選択範囲が見えるようにスクロール位置を調整
    [self scrollRangeToVisible:[self selectedRange]];
}


// ------------------------------------------------------
/// 置換を実行
- (void)replaceWithString:(nullable NSString *)string range:(NSRange)range selectedRange:(NSRange)selectedRange actionName:(nullable NSString *)actionName
// ------------------------------------------------------
{
    if (!string) { return; }
    
    [self replaceWithStrings:@[string]
                      ranges:@[[NSValue valueWithRange:range]]
              selectedRanges:@[[NSValue valueWithRange:selectedRange]]
                  actionName:actionName];
}


// ------------------------------------------------------
/// カラーリング設定を更新する
- (void)setTheme:(nullable CETheme *)theme;
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
    
    // redraw selection
    [self setNeedsDisplayInRect:[self visibleRect] avoidAdditionalLayout:YES];
}



#pragma mark Action Messages

// ------------------------------------------------------
/// フォントをリセット
- (void)resetFont:(nullable id)sender
// ------------------------------------------------------
{
    NSString *name = [[NSUserDefaults standardUserDefaults] stringForKey:CEDefaultFontNameKey];
    CGFloat size = (CGFloat)[[NSUserDefaults standardUserDefaults] doubleForKey:CEDefaultFontSizeKey];
    
    [self setFont:[NSFont fontWithName:name size:size] ? : [NSFont systemFontOfSize:size]];
    
    // キャレット／選択範囲が見えるようにスクロール位置を調整
    [self scrollRangeToVisible:[self selectedRange]];
}


// ------------------------------------------------------
/// increase indent level
- (IBAction)shiftRight:(nullable id)sender
// ------------------------------------------------------
{
    if ([self tabWidth] < 1) { return; }
    
    // get range to process
    NSRange selectedRange = [self selectedRange];
    NSRange lineRange = [[self string] lineRangeForRange:selectedRange];
    
    // remove the last line ending
    if (lineRange.length > 0) {
        lineRange.length--;
    }
    
    // create indent string to prepend
    NSMutableString *indent = [NSMutableString string];
    if ([self isAutoTabExpandEnabled]) {
        NSUInteger tabWidth = [self tabWidth];
        while (tabWidth--) {
            [indent appendString:@" "];
        }
    } else {
        [indent setString:@"\t"];
    }
    
    // create shifted string
    NSMutableString *newString = [NSMutableString stringWithString:[[self string] substringWithRange:lineRange]];
    NSUInteger numberOfLines = [newString replaceOccurrencesOfString:@"\n"
                                                          withString:[NSString stringWithFormat:@"\n%@", indent]
                                                             options:0
                                                               range:NSMakeRange(0, [newString length])];
    [newString insertString:indent atIndex:0];
    
    // calculate new selection range
    NSRange newSelectedRange = NSMakeRange(selectedRange.location,
                                           selectedRange.length + [indent length] * numberOfLines);
    if ((lineRange.location == selectedRange.location) && (selectedRange.length > 0) &&
        ([[[self string] substringWithRange:selectedRange] hasSuffix:@"\n"]))
    {
        // 行頭から行末まで選択されていたときは、処理後も同様に選択する
        newSelectedRange.length += [indent length];
    } else {
        newSelectedRange.location += [indent length];
    }
    
    // perform replace and register to undo manager
    [self replaceWithString:newString range:lineRange selectedRange:newSelectedRange
                 actionName:NSLocalizedString(@"Shift Right", nil)];
}


// ------------------------------------------------------
/// decrease indent level
- (IBAction)shiftLeft:(nullable id)sender
// ------------------------------------------------------
{
    if ([self tabWidth] < 1) { return; }
    
    // get range to process
    NSRange selectedRange = [self selectedRange];
    NSRange lineRange = [[self string] lineRangeForRange:selectedRange];
    
    if (lineRange.length == 0) { return; } // do nothing with blank line
    
    // remove the last line ending
    if ((lineRange.length > 1) && ([[self string] characterAtIndex:NSMaxRange(lineRange) - 1] == '\n')) {
        lineRange.length--;
    }

    // create shifted string
    NSMutableArray<NSString *> *newLines = [NSMutableArray array];
    NSInteger tabWidth = [self tabWidth];
    __block NSRange newSelectedRange = selectedRange;
    __block BOOL didShift = NO;
    __block NSUInteger scanningLineLocation = lineRange.location;
    __block BOOL isFirstLine = YES;

    // scan selected lines and remove tab/spaces at the beginning of lines
    [[[self string] substringWithRange:lineRange] enumerateLinesUsingBlock:^(NSString *line, BOOL *stop) {
        NSUInteger numberOfDeleted = 0;
        
        // count tab/spaces to delete
        BOOL isDeletingSpace = NO;
        for (NSUInteger i = 0; i < MIN(tabWidth, [line length]); i++) {
            unichar theChar = [line characterAtIndex:i];
            if (theChar == '\t' && !isDeletingSpace) {
                numberOfDeleted = 1;
                break;
            } else if (theChar == ' ') {
                numberOfDeleted++;
                isDeletingSpace = YES;
            } else {
                break;
            }
        }
        
        NSString *newLine = [line substringFromIndex:numberOfDeleted];
        
        // calculate new selection range
        NSRange deletedRange = NSMakeRange(scanningLineLocation, numberOfDeleted);
        newSelectedRange.length -= NSIntersectionRange(deletedRange, newSelectedRange).length;
        if (isFirstLine) {
            newSelectedRange.location = MAX((NSInteger)(selectedRange.location - numberOfDeleted),
                                            (NSInteger)lineRange.location);
            isFirstLine = NO;
        }
        
        // append new line
        [newLines addObject:newLine];
        
        didShift = didShift ? : (numberOfDeleted > 0);
        scanningLineLocation += [newLine length] + 1;  // +1 for line ending
    }];
    
    // cancel if not shifted
    if (!didShift) { return; }
    
    NSString *newString = [newLines componentsJoinedByString:@"\n"];
    
    // perform replace and register to undo manager
    [self replaceWithString:newString range:lineRange selectedRange:newSelectedRange
                 actionName:NSLocalizedString(@"Shift Left", nil)];
}


// ------------------------------------------------------
/// 選択範囲を含む行全体を選択する
- (IBAction)selectLines:(nullable id)sender
// ------------------------------------------------------
{
    [self setSelectedRange:[[self string] lineRangeForRange:[self selectedRange]]];
}


// ------------------------------------------------------
/// タブ幅を変更する
- (IBAction)changeTabWidth:(nullable id)sender
// ------------------------------------------------------
{
    [self setTabWidth:[sender tag]];
}


// ------------------------------------------------------
/// 半角円マークを入力
- (IBAction)inputYenMark:(nullable id)sender
// ------------------------------------------------------
{
    [super insertText:[NSString stringWithCharacters:&kYenMark length:1]
     replacementRange:[self selectedRange]];
}


// ------------------------------------------------------
/// バックスラッシュを入力
- (IBAction)inputBackSlash:(nullable id)sender
// ------------------------------------------------------
{
    [super insertText:@"\\" replacementRange:[self selectedRange]];
}


// ------------------------------------------------------
/// アウトラインメニュー選択によるテキスト選択を実行
- (IBAction)setSelectedRangeWithNSValue:(nullable id)sender
// ------------------------------------------------------
{
    NSValue *value = [sender representedObject];
    
    if (!value) { return; }
    
    NSRange range = [value rangeValue];
    
    [self setNeedsUpdateOutlineMenuItemSelection:NO]; // 選択範囲変更後にメニュー選択項目が再選択されるオーバーヘッドを省く
    [self setSelectedRange:range];
    [self centerSelectionInVisibleArea:self];
    [[self window] makeFirstResponder:self];
}


// ------------------------------------------------------
/// 行間設定を変更
- (IBAction)changeLineHeight:(nullable id)sender
// ------------------------------------------------------
{
    [self setLineSpacingAndUpdate:(CGFloat)[[sender title] doubleValue] - 1.0];  // title is line height
}


// ------------------------------------------------------
/// グリフ情報をポップオーバーで表示
- (IBAction)showSelectionInfo:(nullable id)sender
// ------------------------------------------------------
{
    NSRange selectedRange = [self selectedRange];
    NSString *selectedString = [[self string] substringWithRange:selectedRange];
    CECharacterPopoverController *popoverController = [[CECharacterPopoverController alloc] initWithCharacter:selectedString];
    
    if (!popoverController) { return; }
    
    NSRect selectedRect = [self overlayRectForRange:selectedRange];
    selectedRect.origin.y -= 4;
    
    [popoverController showPopoverRelativeToRect:selectedRect ofView:self];
    [self showFindIndicatorForRange:NSMakeRange(selectedRange.location, 1)];
}


#pragma mark Private Methods

// ------------------------------------------------------
/// 変更を監視するデフォルトキー
+ (nonnull NSArray<NSString *> *)observedDefaultKeys
// ------------------------------------------------------
{
    return @[CEDefaultAutoExpandTabKey,
             CEDefaultSmartInsertAndDeleteKey,
             CEDefaultCheckSpellingAsTypeKey,
             CEDefaultEnableSmartQuotesKey,
             CEDefaultHangingIndentWidthKey,
             CEDefaultEnablesHangingIndentKey];
}


// ------------------------------------------------------
/// キー入力時の文字修飾辞書をセット
- (void)applyTypingAttributes
// ------------------------------------------------------
{
    [self setTypingAttributes:@{NSParagraphStyleAttributeName: [self defaultParagraphStyle],
                                NSFontAttributeName: [self font],
                                NSForegroundColorAttributeName: [[self theme] textColor]}];
    
    // update current text
    [[self textStorage] setAttributes:[self typingAttributes]
                                range:NSMakeRange(0, [[self textStorage] length])];
}


// ------------------------------------------------------
/// window's opacity did change
- (void)didWindowOpacityChange:(nonnull NSNotification *)notification
// ------------------------------------------------------
{
    BOOL isOpaque = [[self window] isOpaque];
    
    // let text view have own background if possible
    [self setDrawsBackground:isOpaque];
    
    // By opaque window, turn `copiesOnScroll` on to enable Responsive Scrolling with traditional drawing.
    // -> Better not using layer-backed view to avoid ugly text rendering and performance issue (1024jp on 2015-01)
    //    cf. Responsive Scrolling section in the Release Notes for OS X 10.9
    [[[self enclosingScrollView] contentView] setCopiesOnScroll:isOpaque];
    
    // Make view layer-backed in order to disable dropshadow from letters on Mavericks (1024jp on 2015-02)
    // -> This makes scrolling laggy on huge file.
    if (floor(NSAppKitVersionNumber) == NSAppKitVersionNumber10_9) {
        [[self enclosingScrollView] setWantsLayer:!isOpaque];
    }
    
    // redraw visible area
    [self setNeedsDisplayInRect:[self visibleRect] avoidAdditionalLayout:YES];
}


// ------------------------------------------------------
/// perform multiple replacements
- (void)replaceWithStrings:(nonnull NSArray<NSString *> *)strings ranges:(nonnull NSArray<NSValue *> *)ranges selectedRanges:(nonnull NSArray<NSValue *> *)selectedRanges actionName:(nullable NSString *)actionName
// ------------------------------------------------------
{
    // register redo for text selection
    [[[self undoManager] prepareWithInvocationTarget:self] setSelectedRangesWithUndo:[self selectedRanges]];
    
    // tell textEditor about beginning of the text processing
    if (![self shouldChangeTextInRanges:ranges replacementStrings:strings]) { return; }
    
    // set action name
    if (actionName) {
        [[self undoManager] setActionName:actionName];
    }
    
    // process text
    NSTextStorage *textStorage = [self textStorage];
    NSDictionary<NSString *, id> *attributes = [self typingAttributes];
    
    [textStorage beginEditing];
    // use backwards enumeration to skip adjustment of applying location
    [ranges enumerateObjectsWithOptions:NSEnumerationReverse
                             usingBlock:^(id obj, NSUInteger idx, BOOL *stop)
     {
         NSRange range = [obj rangeValue];
         NSString *string = strings[idx];
         NSAttributedString *attrString = [[NSAttributedString alloc] initWithString:string attributes:attributes];
         
         [textStorage replaceCharactersInRange:range withAttributedString:attrString];
     }];
    [textStorage endEditing];
    
    // post didEdit notification (It's not posted automatically, since here NSTextStorage is directly edited.)
    [self didChangeText];
    
    // apply new selection ranges
    [self setSelectedRangesWithUndo:selectedRanges];
}


// ------------------------------------------------------
/// undoable selection change
- (void)setSelectedRangesWithUndo:(nonnull NSArray<NSValue *> *)ranges;
// ------------------------------------------------------
{
    [self setSelectedRanges:ranges];
    [[[self undoManager] prepareWithInvocationTarget:self] setSelectedRangesWithUndo:ranges];
}


// ------------------------------------------------------
/// カスタムキーバインドで文字列入力
- (void)insertCustomTextWithPatternNumber:(NSInteger)patternNumber
// ------------------------------------------------------
{
    if (patternNumber < 0) { return; }
    
    NSArray<NSString *> *texts = [[NSUserDefaults standardUserDefaults] stringArrayForKey:CEDefaultInsertCustomTextArrayKey];
    
    if (patternNumber < [texts count]) {
        NSString *string = texts[patternNumber];
        
        if ([self shouldChangeTextInRange:[self selectedRange] replacementString:string]) {
            [self replaceCharactersInRange:[self selectedRange] withString:string];
            [[self undoManager] setActionName:NSLocalizedString(@"Insert Custom Text", nil)];
            [self didChangeText];
            [self scrollRangeToVisible:[self selectedRange]];
            
        } else {
            NSBeep();
        }
    }
}


// ------------------------------------------------------
/// フォントからタブ幅を計算して返す
- (CGFloat)tabIntervalFromFont:(NSFont *)font
// ------------------------------------------------------
{
    NSFont *screenFont = [font screenFont] ? : font;
    CGFloat spaceWidth = [screenFont advancementForGlyph:(NSGlyph)' '].width;
    
    return [self tabWidth] * spaceWidth;
}


// ------------------------------------------------------
/// calculate column number at location in the line
- (NSUInteger)columnOfLocation:(NSUInteger)location expandsTab:(BOOL)expandsTab
// ------------------------------------------------------
{
    NSRange lineRange = [[self string] lineRangeForRange:NSMakeRange(location, 0)];
    NSInteger column = location - lineRange.location;
    
    // count tab width
    if (expandsTab) {
        NSString *beforeInsertion = [[self string] substringWithRange:NSMakeRange(lineRange.location, column)];
        NSUInteger numberOfTabChars = [[beforeInsertion componentsSeparatedByString:@"\t"] count] - 1;
        column += numberOfTabChars * ([self tabWidth] - 1);
    }
    
    return column;
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


// ------------------------------------------------------
/// rect for given character range
- (NSRect)overlayRectForRange:(NSRange)range
// ------------------------------------------------------
{
    NSRange glyphRange = [[self layoutManager] glyphRangeForCharacterRange:range actualCharacterRange:NULL];
    NSRect rect = [[self layoutManager] boundingRectForGlyphRange:glyphRange inTextContainer:[self textContainer]];
    NSPoint containerOrigin = [self textContainerOrigin];
    
    rect.origin.x += containerOrigin.x;
    rect.origin.y += containerOrigin.y;
    
    return [self convertRectToLayer:rect];
}

@end




#pragma mark -

@implementation CETextView (WordCompletion)

#pragma mark Superclass Methods

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
/// 補完リストの表示、選択候補の入力
- (void)insertCompletion:(nonnull NSString *)word forPartialWordRange:(NSRange)charRange movement:(NSInteger)movement isFinal:(BOOL)flag
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



#pragma mark Public Methods

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



#pragma mark Semi-Private Methods

// ------------------------------------------------------
/// 入力補完タイマーを停止
- (void)stopCompletionTimer
// ------------------------------------------------------
{
    [[self completionTimer] invalidate];
    [self setCompletionTimer:nil];
}



#pragma mark Private Methods

// ------------------------------------------------------
/// 入力補完リストの表示
- (void)completionWithTimer:(nonnull NSTimer *)timer
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

@end




#pragma mark -

@implementation CETextView (WordSelection)

#pragma mark Superclass Methods

// ------------------------------------------------------
/// adjust word selection range
- (NSRange)selectionRangeForProposedRange:(NSRange)proposedSelRange granularity:(NSSelectionGranularity)granularity
// ------------------------------------------------------
{
    // This method is partly based on Smultron's SMLTextView by Peter Borg (2006-09-09)
    // Smultron 2 was distributed on <http://smultron.sourceforge.net> under the terms of the BSD license.
    // Copyright (c) 2004-2006 Peter Borg
    
    NSString *completeString = [self string];
    
    if (granularity != NSSelectByWord || [completeString length] == proposedSelRange.location) {
        return [super selectionRangeForProposedRange:proposedSelRange granularity:granularity];
    }
    
    NSRange wordRange = [super selectionRangeForProposedRange:proposedSelRange granularity:NSSelectByWord];
    
    // treat additional specific chars as separator (see wordRangeAt: for details)
    if (wordRange.length > 0) {
        wordRange = [self wordRangeAt:proposedSelRange.location];
        if (proposedSelRange.length > 1) {
            wordRange = NSUnionRange(wordRange, [self wordRangeAt:NSMaxRange(proposedSelRange) - 1]);
        }
    }
    
    // settle result on expanding selection or if there is no possibility for clicking brackets
    if (proposedSelRange.length > 0 || wordRange.length != 1) { return wordRange; }
    
    // select inside of brackets by double-clicking
    NSInteger location = wordRange.location;
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
            
        default:
            return wordRange;
    }
    
    NSUInteger lengthOfString = [completeString length];
    NSInteger originalLocation = location;
    NSUInteger skippedBraceCount = 0;
    
    if (isEndBrace) {
        while (location--) {
            unichar character = [completeString characterAtIndex:location];
            if (character == beginBrace) {
                if (!skippedBraceCount) {
                    return NSMakeRange(location, originalLocation - location + 1);
                } else {
                    skippedBraceCount--;
                }
            } else if (character == endBrace) {
                skippedBraceCount++;
            }
        }
    } else {
        while (++location < lengthOfString) {
            unichar character = [completeString characterAtIndex:location];
            if (character == endBrace) {
                if (!skippedBraceCount) {
                    return NSMakeRange(originalLocation, location - originalLocation + 1);
                } else {
                    skippedBraceCount--;
                }
            } else if (character == beginBrace) {
                skippedBraceCount++;
            }
        }
    }
    NSBeep();
    
    // If it has a found a "starting" brace but not found a match, a double-click should only select the "starting" brace and not what it usually would select at a double-click
    return [super selectionRangeForProposedRange:NSMakeRange(proposedSelRange.location, 1) granularity:NSSelectByCharacter];
}



#pragma mark Private Methods

// ------------------------------------------------------
/// word range includes location
- (NSRange)wordRangeAt:(NSUInteger)location
// ------------------------------------------------------
{
    NSRange proposedWordRange = [super selectionRangeForProposedRange:NSMakeRange(location, 0) granularity:NSSelectByWord];
    
    if (proposedWordRange.length <= 1) { return proposedWordRange; }
    
    NSRange wordRange = proposedWordRange;
    NSString *word = [[self string] substringWithRange:proposedWordRange];
    NSScanner *scanner = [NSScanner scannerWithString:word];
    NSCharacterSet *breakCharacterSet = [NSCharacterSet characterSetWithCharactersInString:@".:"];
    
    while ([scanner scanUpToCharactersFromSet:breakCharacterSet intoString:nil]) {
        NSUInteger breakLocation = [scanner scanLocation];
        
        if (proposedWordRange.location + breakLocation < location) {
            wordRange.location = proposedWordRange.location + breakLocation + 1;
            wordRange.length = proposedWordRange.length - (breakLocation + 1);
            
        } else if (proposedWordRange.location + breakLocation == location) {
            wordRange = NSMakeRange(location, 1);
            break;
            
        } else {
            wordRange.length -= proposedWordRange.length - breakLocation;
            break;
        }
        [scanner scanCharactersFromSet:breakCharacterSet intoString:nil];
    }
    
    return wordRange;
}

@end




#pragma mark -

@implementation CETextView (PinchZoomSupport)

#pragma mark Superclass Methods

// ------------------------------------------------------
/// change font size by pinch gesture
- (void)magnifyWithEvent:(nonnull NSEvent *)event
// ------------------------------------------------------
{
    BOOL isScalingDown = ([event magnification] < 0);
    CGFloat defaultSize = (CGFloat)[[NSUserDefaults standardUserDefaults] floatForKey:CEDefaultFontSizeKey];
    CGFloat size = [[self font] pointSize];
    
    // avoid scaling down to smaller than default size
    if (isScalingDown && size == defaultSize) { return; }
    
    // calc new font size
    size = MAX(defaultSize, size + ([event magnification] * 10));
    
    [self changeFontSize:size];
}


// ------------------------------------------------------
/// reset font size by two-finger double tap
- (void)smartMagnifyWithEvent:(nonnull NSEvent *)event
// ------------------------------------------------------
{
    CGFloat defaultSize = (CGFloat)[[NSUserDefaults standardUserDefaults] floatForKey:CEDefaultFontSizeKey];
    CGFloat size = [[self font] pointSize];
    
    if (size == defaultSize) {
        // pseudo-animation
        __unsafe_unretained typeof(self) weakSelf = self;  // NSTextView cannot be weak
        for (CGFloat factor = 1, interval = 0; factor <= 1.5; factor += 0.05, interval += 0.01) {
            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(interval * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                typeof(self) self = weakSelf;  // strong self
                if (!self) { return; }
                
                [self changeFontSize:size * factor];
            });
        }
    } else {
        [self changeFontSize:defaultSize];
    }
}



#pragma mark Private Methods

// ------------------------------------------------------
/// change font size keeping visible area as possible
- (void)changeFontSize:(CGFloat)size
// ------------------------------------------------------
{
    // store current visible area
    NSRange glyphRange = [[self layoutManager] glyphRangeForBoundingRect:[self visibleRect]
                                                         inTextContainer:[self textContainer]];
    NSRange visibleRange = [[self layoutManager] characterRangeForGlyphRange:glyphRange actualGlyphRange:NULL];
    NSRange selectedRange = [self selectedRange];
    selectedRange.length = MAX(selectedRange.length, 1);  // sanitize for NSIntersectionRange()
    BOOL isSelectionVisible = (NSIntersectionRange(visibleRange, selectedRange).length > 0);
    
    // change font size
    [self setFont:[[NSFontManager sharedFontManager] convertFont:[self font] toSize:size]];
    
    // adjust visible area
    [self scrollRangeToVisible:visibleRange];
    if (isSelectionVisible) {
        [self scrollRangeToVisible:selectedRange];
    }
}

@end




#pragma mark -

@implementation CETextView (Commenting)

#pragma mark Action Messages

// ------------------------------------------------------
/// toggle comment state in selection
- (IBAction)toggleComment:(nullable id)sender
// ------------------------------------------------------
{
    if ([self canUncommentRange:[self selectedRange]]) {
        [self uncomment:sender];
    } else {
        [self commentOut:sender];
    }
}


// ------------------------------------------------------
/// comment out selection appending comment delimiters
- (IBAction)commentOut:(nullable id)sender
// ------------------------------------------------------
{
    if (![self blockCommentDelimiters] && ![self inlineCommentDelimiter]) { return; }
    
    // determine comment out target
    NSRange targetRange;
    if (![sender isKindOfClass:[NSScriptCommand class]] &&
        [[NSUserDefaults standardUserDefaults] boolForKey:CEDefaultCommentsAtLineHeadKey])
    {
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
    [self replaceWithString:newString range:targetRange selectedRange:selected
                 actionName:NSLocalizedString(@"Comment Out", nil)];
}


// ------------------------------------------------------
/// uncomment selection removing comment delimiters
- (IBAction)uncomment:(nullable id)sender
// ------------------------------------------------------
{
    if (![self blockCommentDelimiters] && ![self inlineCommentDelimiter]) { return; }
    
    BOOL hasUncommented = NO;
    
    // determine uncomment target
    NSRange targetRange;
    if (![sender isKindOfClass:[NSScriptCommand class]] &&
        [[NSUserDefaults standardUserDefaults] boolForKey:CEDefaultCommentsAtLineHeadKey])
    {
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
    beginDelimiter = [self inlineCommentDelimiter];
    if (!hasUncommented && beginDelimiter) {
        
        // remove comment delimiters
        NSArray<NSString *> *lines = [target componentsSeparatedByString:@"\n"];
        NSMutableArray<NSString *> *newLines = [NSMutableArray array];
        for (NSString *line in lines) {
            NSString *newLine = [line copy];
            if ([line hasPrefix:beginDelimiter]) {
                newLine = [line substringFromIndex:[beginDelimiter length]];
                
                if ([spacer length] > 0 && [newLine hasPrefix:spacer]) {
                    newLine = [newLine substringFromIndex:[spacer length]];
                }
                
                hasUncommented = YES;
            }
            
            [newLines addObject:newLine];
            removedChars += [line length] - [newLine length];
        }
        
        newString = [newLines componentsJoinedByString:@"\n"];
    }
    
    if (!hasUncommented) { return; }
    
    // set selection
    NSRange selection;
    if ([self selectedRange].length > 0) {
        selection = NSMakeRange(targetRange.location, [newString length]);
    } else {
        selection = NSMakeRange([self selectedRange].location, 0);
        selection.location -= MIN(MIN(selection.location, selection.location - targetRange.location), removedChars);
    }
    
    [self replaceWithString:newString range:targetRange selectedRange:selection
                 actionName:NSLocalizedString(@"Uncomment", nil)];
}



#pragma mark Semi-Private Methods

// ------------------------------------------------------
/// whether given range can be uncommented
- (BOOL)canUncommentRange:(NSRange)range
// ------------------------------------------------------
{
    if (![self blockCommentDelimiters] && ![self inlineCommentDelimiter]) { return NO; }
    
    // determine comment out target
    if ([[NSUserDefaults standardUserDefaults] boolForKey:CEDefaultCommentsAtLineHeadKey]) {
        range = [[self string] lineRangeForRange:range];
    }
    // remove last return
    if (range.length > 0 && [[self string] characterAtIndex:NSMaxRange(range) - 1] == '\n') {
        range.length--;
    }
    
    NSString *target = [[self string] substringWithRange:range];
    
    if ([target length] == 0) { return NO; }
    
    if ([self blockCommentDelimiters]) {
        if ([target hasPrefix:[self blockCommentDelimiters][CEBeginDelimiterKey]] &&
            [target hasSuffix:[self blockCommentDelimiters][CEEndDelimiterKey]]) {
            return YES;
        }
    }
    
    if ([self inlineCommentDelimiter]) {
        NSArray<NSString *> *lines = [target componentsSeparatedByString:@"\n"];
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

@end




#pragma mark -

@implementation CETextView (Transformation)

#pragma mark Action Messages

// ------------------------------------------------------
/// transform half-width roman characters in selection to full-width
- (IBAction)exchangeFullwidthRoman:(nullable id)sender
// ------------------------------------------------------
{
    [self transformSelectionWithActionName:NSLocalizedString(@"To Fullwidth Roman", nil)
                          operationHandler:^NSString *(NSString *substring)
     {
         return [substring fullWidthRomanString];
     }];
}


// ------------------------------------------------------
/// transform full-width roman characters in selection to half-width
- (IBAction)exchangeHalfwidthRoman:(nullable id)sender
// ------------------------------------------------------
{
    [self transformSelectionWithActionName:NSLocalizedString(@"To Halfwidth Roman", nil)
                          operationHandler:^NSString *(NSString *substring)
     {
         return [substring halfWidthRomanString];
     }];
}


// ------------------------------------------------------
/// transform Hiragana in selection to Katakana
- (IBAction)exchangeKatakana:(nullable id)sender
// ------------------------------------------------------
{
    [self transformSelectionWithActionName:NSLocalizedString(@"Hiragana to Katakana", nil)
                          operationHandler:^NSString *(NSString *substring)
     {
         return [substring katakanaString];
     }];
}


// ------------------------------------------------------
/// transform Katakana in selection to Hiragana
- (IBAction)exchangeHiragana:(nullable id)sender
// ------------------------------------------------------
{
    [self transformSelectionWithActionName:NSLocalizedString(@"Katakana to Hiragana", nil)
                          operationHandler:^NSString *(NSString *substring)
     {
         return [substring hiraganaString];
     }];
}


// ------------------------------------------------------
/// Unicode normalization (NDF)
- (IBAction)normalizeUnicodeWithNFD:(nullable id)sender
// ------------------------------------------------------
{
    [self transformSelectionWithActionName:@"NFD"
                          operationHandler:^NSString *(NSString *substring)
     {
         return [substring decomposedStringWithCanonicalMapping];
     }];
}


// ------------------------------------------------------
/// Unicode normalization (NFC)
- (IBAction)normalizeUnicodeWithNFC:(nullable id)sender
// ------------------------------------------------------
{
    [self transformSelectionWithActionName:@"NFC"
                          operationHandler:^NSString *(NSString *substring)
     {
         return [substring precomposedStringWithCanonicalMapping];
     }];
}


// ------------------------------------------------------
/// Unicode normalization (NFKD)
- (IBAction)normalizeUnicodeWithNFKD:(nullable id)sender
// ------------------------------------------------------
{
    [self transformSelectionWithActionName:@"NFKD"
                          operationHandler:^NSString *(NSString *substring)
     {
         return [substring decomposedStringWithCompatibilityMapping];
     }];
}


// ------------------------------------------------------
/// Unicode normalization (NFKC)
- (IBAction)normalizeUnicodeWithNFKC:(nullable id)sender
// ------------------------------------------------------
{
    [self transformSelectionWithActionName:@"NFKC"
                          operationHandler:^NSString *(NSString *substring)
     {
         return [substring precomposedStringWithCompatibilityMapping];
     }];
}

// ------------------------------------------------------
/// Unicode normalization (NFKC_Casefold)
- (IBAction)normalizeUnicodeWithNFKCCF:(nullable id)sender
// ------------------------------------------------------
{
    [self transformSelectionWithActionName:@"NFKC Casefold"
                          operationHandler:^NSString *(NSString *substring)
     {
         return [substring precomposedStringWithCompatibilityMappingWithCasefold];
     }];
}

// ------------------------------------------------------
/// Unicode normalization (Modified NFD)
- (IBAction)normalizeUnicodeWithModifiedNFD:(nullable id)sender
// ------------------------------------------------------
{
    [self transformSelectionWithActionName:NSLocalizedString(@"Modified NFD", @"name of an Uniocode normalization type")
                          operationHandler:^NSString *(NSString *substring)
     {
         return [substring decomposedStringWithHFSPlusMapping];
     }];
}



#pragma mark Private Methods

// ------------------------------------------------------
/// transform all selected strings and register to undo manager
- (void)transformSelectionWithActionName:(NSString *)actionName operationHandler:(NSString *(^)(NSString *substring))operationHandler
// ------------------------------------------------------
{
    NSArray<NSValue *> *selectedRanges = [self selectedRanges];
    NSMutableArray<NSValue *> *appliedRanges = [NSMutableArray array];
    NSMutableArray<NSString *> *strings = [NSMutableArray array];
    NSMutableArray<NSValue *> *newSelectedRanges = [NSMutableArray array];
    BOOL success = NO;
    NSInteger deltaLocation = 0;
    
    for (NSValue *rangeValue in selectedRanges) {
        NSRange range = [rangeValue rangeValue];
        
        if (range.length == 0) { continue; }
        
        NSString *substring = [[self string] substringWithRange:range];
        NSString *string = operationHandler(substring);
        
        if (string) {
            NSRange newRange = NSMakeRange(range.location - deltaLocation, [string length]);
            
            [strings addObject:string];
            [appliedRanges addObject:rangeValue];
            [newSelectedRanges addObject:[NSValue valueWithRange:newRange]];
            deltaLocation += [substring length] - [string length];
            success = YES;
        }
    }
    
    if (!success) { return; }
    
    [self replaceWithStrings:strings ranges:appliedRanges selectedRanges:newSelectedRanges actionName:actionName];
    
    [self scrollRangeToVisible:[self selectedRange]];
}

@end




#pragma mark -

@implementation CETextView (ColorCode)

#pragma mark Action Messages

// ------------------------------------------------------
/// tell selected string to color code panel
- (IBAction)editColorCode:(nullable id)sender
// ------------------------------------------------------
{
    NSString *selectedString = [[self string] substringWithRange:[self selectedRange]];
    
    [[CEColorCodePanelController sharedController] showWindow:sender];
    [[CEColorCodePanelController sharedController] setColorWithCode:selectedString];
}


// ------------------------------------------------------
/// avoid changeing text color by color panel
- (IBAction)changeColor:(nullable id)sender
// ------------------------------------------------------
{
    // do nothing.
}

@end




#pragma mark -

@implementation CETextView (LineProcessing)

#pragma mark Private Methods

// ------------------------------------------------------
/// move selected line up
- (IBAction)moveLineUp:(nullable id)sender
// ------------------------------------------------------
{
    // get line ranges to process
    NSArray<NSValue *> *lineRanges = [self selectedLineRanges];
    
    // cannot perform Move Line Up if one of the selections is already in the first line
    if ([[lineRanges firstObject] rangeValue].location == 0) {
        NSBeep();
        return;
    }
    
    NSArray<NSValue *> *selectedRanges = [self selectedRanges];
    NSTextStorage *textStorage = [self textStorage];
    
    // register redo for text selection
    [[[self undoManager] prepareWithInvocationTarget:self] setSelectedRangesWithUndo:[self selectedRanges]];
    
    NSMutableArray<NSValue *> *newSelectedRanges = [NSMutableArray arrayWithCapacity:[selectedRanges count]];
    
    // swap lines
    [textStorage beginEditing];
    for (NSValue *lineRangeValue in lineRanges) {
        NSRange lineRange = [lineRangeValue rangeValue];
        NSRange upperLineRange = [[textStorage string] lineRangeForRange:NSMakeRange(lineRange.location - 1, 0)];
        NSString *lineString = [[textStorage string] substringWithRange:lineRange];
        NSString *upperLineString = [[textStorage string] substringWithRange:upperLineRange];
        
        // last line
        if (![lineString hasSuffix:@"\n"]) {
            lineString = [lineString stringByAppendingString:@"\n"];
            upperLineString = [upperLineString substringToIndex:upperLineRange.length - 1];
        }
        
        NSString *replacementString = [NSString stringWithFormat:@"%@%@", lineString, upperLineString];
        NSRange editRange = NSMakeRange(upperLineRange.location, [replacementString length]);
        
        // swap
        if ([self shouldChangeTextInRange:editRange replacementString:replacementString]) {
            [[textStorage mutableString] replaceCharactersInRange:editRange withString:replacementString];
            [self didChangeText];
        
            // move selected ranges in the line to move
            for (NSValue *selectedRangeValue in selectedRanges) {
                NSRange selectedRange = [selectedRangeValue rangeValue];
                
                if ((selectedRange.location > lineRange.location) ||
                    (selectedRange.location <= NSMaxRange(lineRange)))
                {
                    selectedRange.location -= upperLineRange.length;
                    [newSelectedRanges addObject:[NSValue valueWithRange:selectedRange]];
                }
            }
        }
    }
    [textStorage endEditing];
    
    [self setSelectedRangesWithUndo:newSelectedRanges];
    
    [[self undoManager] setActionName:NSLocalizedString(@"Move Line", @"action name")];
}


// ------------------------------------------------------
/// move selected line down
- (IBAction)moveLineDown:(nullable id)sender
// ------------------------------------------------------
{
    // get line ranges to process
    NSArray<NSValue *> *lineRanges = [self selectedLineRanges];
    
    // cannot perform Move Line Down if one of the selections is already in the last line
    if (NSMaxRange([[lineRanges lastObject] rangeValue]) == [[self string] length]) {
        NSBeep();
        return;
    }
    
    NSArray<NSValue *> *selectedRanges = [self selectedRanges];
    NSTextStorage *textStorage = [self textStorage];
    
    // register redo for text selection
    [[[self undoManager] prepareWithInvocationTarget:self] setSelectedRangesWithUndo:[self selectedRanges]];
    
    NSMutableArray<NSValue *> *newSelectedRanges = [NSMutableArray arrayWithCapacity:[selectedRanges count]];
    
    // swap lines
    [textStorage beginEditing];
    for (NSValue *lineRangeValue in [lineRanges reverseObjectEnumerator]) {  // reverse order
        NSRange lineRange = [lineRangeValue rangeValue];
        NSRange lowerLineRange = [[textStorage string] lineRangeForRange:NSMakeRange(NSMaxRange(lineRange), 0)];
        NSString *lineString = [[textStorage string] substringWithRange:lineRange];
        NSString *lowerLineString = [[textStorage string] substringWithRange:lowerLineRange];
        
        // last line
        if (![lowerLineString hasSuffix:@"\n"]) {
            lineString = [lineString substringToIndex:lineRange.length - 1];
            lowerLineString = [lowerLineString stringByAppendingString:@"\n"];
            lowerLineRange.length += 1;
        }
        
        NSString *replacementString = [NSString stringWithFormat:@"%@%@", lowerLineString, lineString];
        NSRange editRange = NSMakeRange(lineRange.location, [replacementString length]);
        
        // swap
        if ([self shouldChangeTextInRange:editRange replacementString:replacementString]) {
            [[textStorage mutableString] replaceCharactersInRange:editRange withString:replacementString];
            [self didChangeText];
            
            // move selected ranges in the line to move
            for (NSValue *selectedRangeValue in selectedRanges) {
                NSRange selectedRange = [selectedRangeValue rangeValue];
                
                if ((selectedRange.location > lineRange.location) ||
                    (selectedRange.location <= NSMaxRange(lineRange)))
                {
                    selectedRange.location += lowerLineRange.length;
                    [newSelectedRanges addObject:[NSValue valueWithRange:selectedRange]];
                }
            }
        }
    }
    [textStorage endEditing];
    
    [self setSelectedRangesWithUndo:newSelectedRanges];
    
    [[self undoManager] setActionName:NSLocalizedString(@"Move Line", @"action name")];
}


// ------------------------------------------------------
/// sort selected lines (only in the first selection) ascending
- (IBAction)sortLinesAscending:(nullable id)sender
// ------------------------------------------------------
{
    NSRange lineRange = [[self string] lineRangeForRange:[self selectedRange]];
    
    if (lineRange.length == 0) { return; }
    
    BOOL endsWithNewline = ([[self string] characterAtIndex:NSMaxRange(lineRange) - 1] == '\n');
    NSMutableArray<NSString *> *lines = [NSMutableArray array];
    
    [[self string] enumerateSubstringsInRange:lineRange
                                      options:NSStringEnumerationByLines
                                   usingBlock:^(NSString * _Nullable substring,
                                                NSRange substringRange,
                                                NSRange enclosingRange,
                                                BOOL * _Nonnull stop)
     {
         [lines addObject:substring];
     }];
    
    // do nothing with single line
    if ([lines count] < 2) { return; }
    
    // sort alphabetically ignoring case
    [lines sortUsingSelector:@selector(localizedCaseInsensitiveCompare:)];
    
    NSString *newString = [lines componentsJoinedByString:@"\n"];
    if (endsWithNewline) {
        newString = [newString stringByAppendingString:@"\n"];
    }
    
    if (![self shouldChangeTextInRange:lineRange replacementString:newString]) { return; }
    
    [[self textStorage] replaceCharactersInRange:lineRange withString:newString];
    
    [self didChangeText];
    
    [[self undoManager] setActionName:NSLocalizedString(@"Sort Lines", @"action name")];
}


// ------------------------------------------------------
/// reverse selected lines (only in the first selection)
- (IBAction)reverseLines:(nullable id)sender
// ------------------------------------------------------
{
    NSRange lineRange = [[self string] lineRangeForRange:[self selectedRange]];
    
    if (lineRange.length == 0) { return; }
    
    BOOL endsWithNewline = ([[self string] characterAtIndex:NSMaxRange(lineRange) - 1] == '\n');
    NSMutableArray<NSString *> *lines = [NSMutableArray array];
    
    [[self string] enumerateSubstringsInRange:lineRange
                                      options:NSStringEnumerationByLines | NSStringEnumerationReverse
                                   usingBlock:^(NSString * _Nullable substring,
                                                NSRange substringRange,
                                                NSRange enclosingRange,
                                                BOOL * _Nonnull stop)
     {
         [lines addObject:substring];
     }];
    
    // do nothing with single line
    if ([lines count] < 2) { return; }
    
    // make new string
    NSString *newString = [lines componentsJoinedByString:@"\n"];
    if (endsWithNewline) {
        newString = [newString stringByAppendingString:@"\n"];
    }
    
    if (![self shouldChangeTextInRange:lineRange replacementString:newString]) { return; }
    
    [[self textStorage] replaceCharactersInRange:lineRange withString:newString];
    
    [self didChangeText];
    
    [[self undoManager] setActionName:NSLocalizedString(@"Reverse Lines", @"action name")];
}


// ------------------------------------------------------
/// remove duplicate lines in selection
- (IBAction)deleteDuplicateLine:(nullable id)sender
// ------------------------------------------------------
{
    if ([self selectedRange].length == 0) { return; }
    
    NSMutableArray<NSValue *> *replacementRanges = [NSMutableArray array];
    NSMutableArray<NSString *> *replacementStrings = [NSMutableArray array];
    NSMutableOrderedSet<NSString *> *uniqueLines = [NSMutableOrderedSet orderedSet];
    NSUInteger processedCount = 0;
    
    // collect duplicate lines
    for (NSValue *rangeValue in [self selectedRanges]) {
        NSRange range = [rangeValue rangeValue];
        NSRange lineRange = [[self string] lineRangeForRange:range];
        NSString *targetString = [[self string] substringWithRange:lineRange];
        NSArray<NSString *> *lines = [targetString componentsSeparatedByString:@"\n"];
        
        // filter duplicate lines
        [uniqueLines addObjectsFromArray:lines];
        
        NSRange targetLinesRange = NSMakeRange(processedCount, [uniqueLines count] - processedCount);
        processedCount += targetLinesRange.length;
        
        // do nothing if no duplicate line exists
        if (targetLinesRange.length == [lines count]) { continue; }
        
        NSIndexSet *indexSet = [NSIndexSet indexSetWithIndexesInRange:targetLinesRange];
        NSString *replacementString = [[uniqueLines objectsAtIndexes:indexSet] componentsJoinedByString:@"\n"];
        
        // append last new line only if the original selected lineRange has a new line at the end
        if ([targetString hasSuffix:@"\n"]) {
            replacementString = [replacementString stringByAppendingString:@"\n"];
        }
        
        [replacementStrings addObject:replacementString];
        [replacementRanges addObject:[NSValue valueWithRange:lineRange]];
    }
    
    // return if no line to be removed
    if ([replacementRanges count] == 0) { return; }
    if (![self shouldChangeTextInRanges:replacementRanges replacementStrings:replacementStrings]) { return; }
    
    // delete duplicate lines
    NSTextStorage *textStorage = [self textStorage];
    [replacementStrings enumerateObjectsWithOptions:NSEnumerationReverse
                                         usingBlock:^(NSString *_Nonnull replacementString, NSUInteger idx, BOOL * _Nonnull stop)
     {
         NSRange replacementRange = [replacementRanges[idx] rangeValue];
         [textStorage replaceCharactersInRange:replacementRange withString:replacementString];
     }];
    [self didChangeText];
    
    [[self undoManager] setActionName:NSLocalizedString(@"Delete Duplicate Lines", @"action name")];
}



// ------------------------------------------------------
/// remove selected lines
- (IBAction)deleteLine:(nullable id)sender
// ------------------------------------------------------
{
    NSArray<NSValue *> *replacementRanges = [self selectedLineRanges];
    
    // on empty last line
    if ([replacementRanges count] == 0) { return; }
    
    NSMutableArray<NSString *> *replacementStrings = [NSMutableArray arrayWithCapacity:[replacementRanges count]];
    
    for (NSValue *_ in replacementRanges) {
        [replacementStrings addObject:@""];
    }
    
    if (![self shouldChangeTextInRanges:replacementRanges replacementStrings:replacementStrings]) { return; }
    
    // delete lines
    [[self textStorage] beginEditing];
    for (NSValue *rangeValue in [replacementRanges reverseObjectEnumerator]) {
        NSRange lineRange = [rangeValue rangeValue];
        
        [[self textStorage] replaceCharactersInRange:lineRange withString:@""];
    }
    [[self textStorage] endEditing];
    
    [self didChangeText];
    
    [[self undoManager] setActionName:NSLocalizedString(@"Delete Line", @"action name")];
}



#pragma mark Private Methods

// ------------------------------------------------------
/// extract line by line line ranges which selected ranges include
- (nonnull NSArray<NSValue *> *)selectedLineRanges
// ------------------------------------------------------
{
    NSMutableOrderedSet<NSValue *> *lineRanges = [NSMutableOrderedSet orderedSet];
    NSString *string = [self string];
    
    // get line ranges to process
    for (NSValue *rangeValue in [self selectedRanges]) {
        NSRange selectedRange = [rangeValue rangeValue];
        
        NSRange linesRange = [string lineRangeForRange:selectedRange];
        
        // store each line to process
        [string enumerateSubstringsInRange:linesRange
                                   options:NSStringEnumerationByLines | NSStringEnumerationSubstringNotRequired
                                usingBlock:^(NSString * _Nullable substring,
                                             NSRange substringRange,
                                             NSRange enclosingRange,
                                             BOOL * _Nonnull stop)
         {
             [lineRanges addObject:[NSValue valueWithRange:enclosingRange]];
         }];
    }
    
    return [lineRanges array];
}

@end
