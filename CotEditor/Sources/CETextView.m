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
 © 2014-2016 1024jp
 
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
#import "CELayoutManager.h"
#import "CEWindowController.h"
#import "CEEditorWrapper.h"
#import "CEColorCodePanelController.h"
#import "CECharacterPopoverController.h"
#import "CEEditorScrollView.h"
#import "CEDocument.h"
#import "CEKeyBindingManager.h"
#import "CEScriptManager.h"
#import "CEWindow.h"
#import "NSString+CECounting.h"
#import "CEDefaults.h"
#import "CEEncodings.h"
#import "Constants.h"


// constant
static NSString *_Nonnull const CESelectedRangesKey = @"selectedRange";
static NSString *_Nonnull const CEVisibleRectKey = @"visibleRect";
static NSString *_Nonnull const CEAutoBalancedClosingBracketAttributeName = @"autoBalancedClosingBracket";

static const NSInteger kNoMenuItem = -1;

// Page guide column
static const NSUInteger kMinPageGuideColumn = 1;
static const NSUInteger kMaxPageGuideColumn = 1000;


@interface CETextView ()

@property (nonatomic, weak) NSTimer *completionTimer;
@property (nonatomic, copy) NSString *particalCompletionWord;  // ユーザが実際に入力した補完の元になる文字列

@property (nonatomic) NSColor *highlightLineColor;  // カレント行ハイライト色

@end




#pragma mark -

@implementation CETextView

static NSPoint kTextContainerOrigin;
static NSCharacterSet *kMatchingOpeningBracketsSet;
static NSCharacterSet *kMatchingClosingBracketsSet;


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
        
        kMatchingOpeningBracketsSet = [NSCharacterSet characterSetWithCharactersInString:@"[{(\""];
        kMatchingClosingBracketsSet = [NSCharacterSet characterSetWithCharactersInString:@"]})"];  // ignore "
    });
    
}


// ------------------------------------------------------
/// initialize instance
- (nullable instancetype)initWithCoder:(NSCoder *)coder
// ------------------------------------------------------
{
    self = [super initWithCoder:(NSCoder *)coder];
    if (self) {
        // set class identifier for window restoration
        [self setIdentifier:@"coreTextView"];
        
        NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
        
        // setup layoutManager and textContainer
        CELayoutManager *layoutManager = [[CELayoutManager alloc] init];
        [layoutManager setUsesAntialias:[defaults boolForKey:CEDefaultShouldAntialiasKey]];
        [layoutManager setFixesLineHeight:[defaults boolForKey:CEDefaultFixLineHeightKey]];
        [[self textContainer] replaceLayoutManager:layoutManager];
        
        // This method is partly based on Smultron's SMLTextView by Peter Borg. (2006-09-09)
        // Smultron 2 was distributed on <http://smultron.sourceforge.net> under the terms of the BSD license.
        // Copyright (c) 2004-2006 Peter Borg
        
        // set the width of every tab by first checking the size of the tab in spaces in the current font and then remove all tabs that sets automatically and then set the default tab stop distance
        _tabWidth = [defaults integerForKey:CEDefaultTabWidthKey];
        
        CGFloat fontSize = (CGFloat)[defaults doubleForKey:CEDefaultFontSizeKey];
        NSFont *font = [NSFont fontWithName:[defaults stringForKey:CEDefaultFontNameKey] size:fontSize];
        if (!font) {
            font = [NSFont userFontOfSize:fontSize];
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
        [self setLayerContentsRedrawPolicy:NSViewLayerContentsRedrawBeforeViewResize];
        [self setLayerContentsPlacement:NSViewLayerContentsPlacementScaleAxesIndependently];
        
        // set link detection
        [self setAutomaticLinkDetectionEnabled:[defaults boolForKey:CEDefaultAutoLinkDetectionKey]];
        [self setLinkTextAttributes:@{NSCursorAttributeName: [NSCursor pointingHandCursor],
                                      NSUnderlineStyleAttributeName: @(NSUnderlineStyleSingle)}];
        
        // set values
        _autoTabExpandEnabled = [defaults boolForKey:CEDefaultAutoExpandTabKey];
        [self setSmartInsertDeleteEnabled:[defaults boolForKey:CEDefaultSmartInsertAndDeleteKey]];
        [self setContinuousSpellCheckingEnabled:[defaults boolForKey:CEDefaultCheckSpellingAsTypeKey]];
        if ([self respondsToSelector:@selector(setAutomaticQuoteSubstitutionEnabled:)]) {  // only on OS X 10.9 and later
            [self setAutomaticQuoteSubstitutionEnabled:[defaults boolForKey:CEDefaultEnableSmartQuotesKey]];
            [self setAutomaticDashSubstitutionEnabled:[defaults boolForKey:CEDefaultEnableSmartQuotesKey]];
        }
        [self setFont:font];
        [self setMinSize:[self frame].size];
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
    
    [_completionTimer invalidate];
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
    
    // 背景色に合わせたスクローラのスタイルをセット
    NSInteger knobStyle = [[self theme] isDarkTheme] ? NSScrollerKnobStyleLight : NSScrollerKnobStyleDefault;
    [[self enclosingScrollView] setScrollerKnobStyle:knobStyle];
    
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
    BOOL isModifierKeyPressed = ([theEvent modifierFlags] & NSDeviceIndependentModifierFlagsMask) != 0;  // check just in case
    if (![self hasMarkedText] && charIgnoringMod && isModifierKeyPressed) {
        NSString *selectorStr = [[CEKeyBindingManager sharedManager] selectorStringWithKeyEquivalent:charIgnoringMod
                                                                                       modifierFrags:[theEvent modifierFlags]];
        
        if ([selectorStr length] > 0) {
            if (([selectorStr hasPrefix:@"insertCustomText"]) && ([selectorStr length] == 20)) {
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
    
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    
    // cast NSAttributedString to NSString in order to make sure input string is plain-text
    NSString *string = [aString isKindOfClass:[NSAttributedString class]] ? [aString string] : aString;
    
    // swap '¥' with '\' if needed
    if ([defaults boolForKey:CEDefaultSwapYenAndBackSlashKey] && ([string length] == 1)) {
        NSString *yen = [NSString stringWithCharacters:&kYenMark length:1];
        
        if ([string isEqualToString:@"\\"]) {
            [super insertText:yen replacementRange:replacementRange];
            return;
        } else if ([string isEqualToString:yen]) {
            [super insertText:@"\\" replacementRange:replacementRange];
            return;
        }
    }
    
    // balance brackets and quotes
    if ([defaults boolForKey:CEDefaultBalancesBracketsKey] && (replacementRange.length == 0) &&
        [string length] == 1 && [kMatchingOpeningBracketsSet characterIsMember:[string characterAtIndex:0]])
    {
        // wrap selection with brackets if some text is selected
        if ([self selectedRange].length > 0) {
            NSString *wrappingFormat = nil;
            switch ([string characterAtIndex:0]) {
                case '[':
                    wrappingFormat = @"[%@]";
                    break;
                case '{':
                    wrappingFormat = @"{%@}";
                    break;
                case '(':
                    wrappingFormat = @"(%@)";
                    break;
                case '"':
                    wrappingFormat = @"\"%@\"";
                    break;
            }
            
            NSString *selectedString = [[self string] substringWithRange:[self selectedRange]];
            NSString *replacementString = [NSString stringWithFormat:wrappingFormat, selectedString];
            if ([self shouldChangeTextInRange:[self selectedRange] replacementString:replacementString]) {
                [[self textStorage] replaceCharactersInRange:[self selectedRange] withString:replacementString];
                [self didChangeText];
                return;
            }
        
        // check if insertion point is in a word
        } else if (![[NSCharacterSet alphanumericCharacterSet] characterIsMember:[self characterAfterInsertion]]) {
            switch ([string characterAtIndex:0]) {
                case '[':
                    string = @"[]";
                    break;
                case '{':
                    string = @"{}";
                    break;
                case '(':
                    string = @"()";
                    break;
                case '"':
                    string = @"\"\"";
                    break;
            }
            
            [super insertText:string replacementRange:replacementRange];
            [self setSelectedRange:NSMakeRange([self selectedRange].location - 1, 0)];
            
            // set flag
            [[self textStorage] addAttribute:CEAutoBalancedClosingBracketAttributeName value:@YES
                                       range:NSMakeRange([self selectedRange].location, 1)];
            return;
        }
    }
    
    // just move cursor if closed bracket is already typed
    if ([defaults boolForKey:CEDefaultBalancesBracketsKey] && (replacementRange.length == 0) &&
        [kMatchingClosingBracketsSet characterIsMember:[string characterAtIndex:0]] &&
        ([string characterAtIndex:0] == [self characterAfterInsertion]))
    {
        if ([[[self textStorage] attribute:CEAutoBalancedClosingBracketAttributeName
                                   atIndex:[self selectedRange].location effectiveRange:NULL] boolValue])
        {
            [self setSelectedRange:NSMakeRange([self selectedRange].location + 1, 0)];
            return;
        }
    }
    
    // smart outdent with '}' charcter
    if ([defaults boolForKey:CEDefaultAutoIndentKey] &&
        [defaults boolForKey:CEDefaultEnableSmartIndentKey] &&
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
    if ([defaults boolForKey:CEDefaultAutoCompleteKey]) {
        [self completeAfterDelay:[defaults doubleForKey:CEDefaultAutoCompletionDelayKey]];
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
        unichar lastChar = [self characterBeforeInsertion];
        unichar nextChar = [self characterAfterInsertion];
        
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
    
    // delete tab
    if ((selectedRange.length == 0) && [self isAutoTabExpandEnabled]) {
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
    
    // balance brackets
    if ((selectedRange.length == 0) && [[NSUserDefaults standardUserDefaults] boolForKey:CEDefaultBalancesBracketsKey] &&
        (selectedRange.location > 0) && (selectedRange.location < [[self string] length]) &&
        [kMatchingOpeningBracketsSet characterIsMember:[self characterBeforeInsertion]])
    {
        NSString *surroundingCharacters = [[self string] substringWithRange:NSMakeRange(selectedRange.location - 1, 2)];
        if ([surroundingCharacters isEqualToString:@"{}"] ||
            [surroundingCharacters isEqualToString:@"[]"] ||
            [surroundingCharacters isEqualToString:@"()"] ||
            [surroundingCharacters isEqualToString:@"\"\""])
        {
            [self setSelectedRange:NSMakeRange(selectedRange.location - 1, 2)];
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
    
    CENewLineType newLineType = [self documentNewLineType];
    
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
    // apply link to pasted string
    __unsafe_unretained typeof(self) weakSelf = self;  // NSTextView cannot be weak
    dispatch_async(dispatch_get_main_queue(), ^{
        [weakSelf detectLinkIfNeeded];
    });
    
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
            
            // jsut insert the absolute path if no specific setting for the file type was found
            // -> This is the default behavior of NSTextView by file dropping.
            if ([stringToDrop length] == 0) {
                if ([replacementString length] > 0) {
                    [replacementString appendString:@"\n"];
                }
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
        
    } else if ([keyPath isEqualToString:CEDefaultPageGuideColumnKey]) {
        [self setNeedsDisplayInRect:[self visibleRect] avoidAdditionalLayout:YES];
        
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
        
    } else if ([keyPath isEqualToString:CEDefaultAutoLinkDetectionKey]) {
        [self setAutomaticLinkDetectionEnabled:[newValue boolValue]];
        if ([self isAutomaticLinkDetectionEnabled]) {
            [self detectLinkIfNeeded];
        } else {
            // remove current links
            [[self textStorage] removeAttribute:NSLinkAttributeName range:NSMakeRange(0, [[self string] length])];
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


// ------------------------------------------------------
/// make link-like text clickable
- (void)detectLinkIfNeeded
// ------------------------------------------------------
{
    if (![self isAutomaticLinkDetectionEnabled]) { return; }
    
    // The following code looks suitable, but actually doesn't work. (2015-12)
//    NSRange range = NSMakeRange(0, [[self string] length]);
//    [self checkTextInRange:range types:NSTextCheckingTypeLink options:@{}];
    
    [[self undoManager] disableUndoRegistration];
    NSTextCheckingTypes currentCheckingType = [self enabledTextCheckingTypes];
    [self setEnabledTextCheckingTypes:NSTextCheckingTypeLink];
    [self checkTextInDocument:nil];
    [self setEnabledTextCheckingTypes:currentCheckingType];
    [[self undoManager] enableUndoRegistration];
}



#pragma mark Action Messages

// ------------------------------------------------------
/// copy selection with syntax highlight and font style
- (void)copyWithStyle:(nullable id)sender
// ------------------------------------------------------
{
    if ([self selectedRange].length == 0) { return; }
    
    NSMutableArray<NSAttributedString *> *selections = [NSMutableArray arrayWithCapacity:[[self selectedRanges] count]];
    NSMutableArray<NSNumber *> *propertyList = [NSMutableArray arrayWithCapacity:[[self selectedRanges] count]];
    NSString *newLine = [NSString newLineStringWithType:[self documentNewLineType]];

    // substring all selected attributed strings
    for (NSValue *rangeValue in [self selectedRanges]) {
        NSRange selectedRange = [rangeValue rangeValue];
        NSString *plainText = [[self string] substringWithRange:selectedRange];
        NSMutableAttributedString *styledText = [[NSMutableAttributedString alloc] initWithString:plainText
                                                                                       attributes:[self typingAttributes]];
        
        // apply syntax highlight that is set as temporary attributes in layout manager to attributed string
        for (NSUInteger charIndex = selectedRange.location; charIndex < NSMaxRange(selectedRange); charIndex++) {
            NSRange effectiveRange;
            NSColor *color = [[self layoutManager] temporaryAttribute:NSForegroundColorAttributeName atCharacterIndex:charIndex
                                                longestEffectiveRange:&effectiveRange inRange:selectedRange];
            
            if (!color) { continue; }
            
            NSRange localRange = NSMakeRange(effectiveRange.location - selectedRange.location, effectiveRange.length);
            [styledText addAttribute:NSForegroundColorAttributeName value:color range:localRange];
            
            charIndex = NSMaxRange(effectiveRange);
        }
        
        // apply document's line ending
        if ([self documentNewLineType] != CENewLineLF) {
            for (NSInteger charIndex = [plainText length] - 1; charIndex >= 0; charIndex--) {  // process backwards
                if ([plainText characterAtIndex:charIndex] == '\n') {
                    [styledText replaceCharactersInRange:NSMakeRange(charIndex, 1) withString:newLine];
                }
            }
        }
        
        [selections addObject:styledText];
        [propertyList addObject:@([[plainText componentsSeparatedByString:@"\n"] count])];
    }
    
    NSMutableAttributedString *pasteboardString = [[NSMutableAttributedString alloc] init];
    
    // join attributed strings
    NSAttributedString *attrNewLine = [[NSMutableAttributedString alloc] initWithString:newLine];
    for (NSAttributedString *selection in selections) {
        // join with newline string
        if ([pasteboardString length] > 0) {
            [pasteboardString appendAttributedString:attrNewLine];
        }
        [pasteboardString appendAttributedString:selection];
    }
    
    // set to paste board
    NSPasteboard *pboard = [NSPasteboard generalPasteboard];
    [pboard clearContents];
    [pboard declareTypes:[self writablePasteboardTypes] owner:nil];
    if ([pboard canReadItemWithDataConformingToTypes:@[NSPasteboardTypeMultipleTextSelection]]) {
        [pboard setPropertyList:propertyList forType:NSPasteboardTypeMultipleTextSelection];
    }
    [pboard writeObjects:@[pasteboardString]];
}


// ------------------------------------------------------
/// フォントをリセット
- (void)resetFont:(nullable id)sender
// ------------------------------------------------------
{
    NSString *name = [[NSUserDefaults standardUserDefaults] stringForKey:CEDefaultFontNameKey];
    CGFloat size = (CGFloat)[[NSUserDefaults standardUserDefaults] doubleForKey:CEDefaultFontSizeKey];
    
    [self setFont:[NSFont fontWithName:name size:size] ? : [NSFont userFontOfSize:size]];
    
    // キャレット／選択範囲が見えるようにスクロール位置を調整
    [self scrollRangeToVisible:[self selectedRange]];
}


// ------------------------------------------------------
/// 選択範囲を含む行全体を選択する
- (IBAction)selectLines:(nullable id)sender
// ------------------------------------------------------
{
    NSMutableArray<NSValue *> *selectedLineRanges = [NSMutableArray arrayWithCapacity:[[self selectedRanges] count]];
    for (NSValue *rangeValue in [self selectedRanges]) {
        NSRange lineRange = [[self string] lineRangeForRange:[rangeValue rangeValue]];
        [selectedLineRanges addObject:[NSValue valueWithRange:lineRange]];
    }
    
    [self setSelectedRanges:selectedLineRanges];
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
/// trim all trailing whitespace
- (IBAction)trimTrailingWhitespace:(nullable id)sender
// ------------------------------------------------------
{
    NSMutableArray<NSString *> *replaceStrings = [NSMutableArray array];
    NSMutableArray<NSValue *> *replaceRanges = [NSMutableArray array];
    
    NSRegularExpression *regex = [NSRegularExpression regularExpressionWithPattern:@"[ \\t]+$" options:NSRegularExpressionAnchorsMatchLines error:nil];
    [regex enumerateMatchesInString:[self string] options:0
                              range:NSMakeRange(0, [[self string] length])
                         usingBlock:^(NSTextCheckingResult * _Nullable result, NSMatchingFlags flags, BOOL * _Nonnull stop)
     {
         [replaceRanges addObject:[NSValue valueWithRange:[result range]]];
         [replaceStrings addObject:@""];
    }];
    
    [self replaceWithStrings:replaceStrings ranges:replaceRanges selectedRanges:nil
                  actionName:NSLocalizedString(@"Trim Trailing Whitespace", nil)];
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
    
    // apply document's line ending
    if ([self documentNewLineType] != CENewLineLF && [selectedString detectNewLineType] == CENewLineLF) {
        selectedString = [selectedString stringByReplacingNewLineCharacersWith:[self documentNewLineType]];
    }
    
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
             CEDefaultPageGuideColumnKey,
             CEDefaultEnableSmartQuotesKey,
             CEDefaultHangingIndentWidthKey,
             CEDefaultEnablesHangingIndentKey,
             CEDefaultAutoLinkDetectionKey];
}


// ------------------------------------------------------
/// character just before the insertion or 0
- (unichar)characterBeforeInsertion
// ------------------------------------------------------
{
    NSUInteger location = [self selectedRange].location;
    if (location > 0) {
        return [[self string] characterAtIndex:location - 1];
    }
    return NULL;
}


// ------------------------------------------------------
/// character just after the insertion or 0
- (unichar)characterAfterInsertion
// ------------------------------------------------------
{
    NSUInteger location = NSMaxRange([self selectedRange]);
    if (location < [[self string] length]) {
        return [[self string] characterAtIndex:location];
    }
    return NULL;
}


// ------------------------------------------------------
/// true new line type of document
- (CENewLineType)documentNewLineType
// ------------------------------------------------------
{
    return [[[[self window] windowController] document] lineEnding];
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
    
    [[self completionTimer] invalidate];
    
    // 補完の元になる文字列を保存する
    if (![self particalCompletionWord]) {
        [self setParticalCompletionWord:[[self string] substringWithRange:charRange]];
    }
    
    // 補完リストを表示中に通常のキー入力があったら、直後にもう一度入力補完を行うためのフラグを立てる
    // （フラグは CEEditorViewController > textDidChange: で評価される）
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
    if ([[self completionTimer] isValid]) {
        [[self completionTimer] setFireDate:[NSDate dateWithTimeIntervalSinceNow:delay]];
    } else {
        [self setCompletionTimer:[NSTimer scheduledTimerWithTimeInterval:delay
                                                                  target:self
                                                                selector:@selector(completionWithTimer:)
                                                                userInfo:nil
                                                                 repeats:NO]];
    }
}



#pragma mark Private Methods

// ------------------------------------------------------
/// 入力補完リストの表示
- (void)completionWithTimer:(nonnull NSTimer *)timer
// ------------------------------------------------------
{
    [[self completionTimer] invalidate];
    
    // abord if input is not specified (for Japanese input)
    if ([self hasMarkedText]) { return; }
    
    // abord if selected
    if ([self selectedRange].length > 0) { return; }
    
    // abord if caret is (probably) at the middle of a word
    if ([[NSCharacterSet alphanumericCharacterSet] characterIsMember:[self characterAfterInsertion]]) { return; }
    
    // abord if previous character is blank
    if ([[NSCharacterSet whitespaceAndNewlineCharacterSet] characterIsMember:[self characterBeforeInsertion]]) { return; }
    
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
    
    NSInteger location = wordRange.location;
    unichar clickedCharacter = [completeString characterAtIndex:location];
    
    // select (syntax-highlighted) quoted text by double-clicking
    if (clickedCharacter == '"' || clickedCharacter == '\'' || clickedCharacter == '`') {
        NSRange highlightRange;
        [[self layoutManager] temporaryAttribute:NSForegroundColorAttributeName atCharacterIndex:location
                           longestEffectiveRange:&highlightRange inRange:NSMakeRange(0, [completeString length])];
        
        BOOL isStartQuote = (highlightRange.location == location);
        BOOL isEndQuote = (NSMaxRange(highlightRange) - 1 == location);
        
        if (isStartQuote || isEndQuote) {
            if ((isStartQuote && [completeString characterAtIndex:NSMaxRange(highlightRange) - 1] == clickedCharacter) ||
                (isEndQuote && [completeString characterAtIndex:highlightRange.location] == clickedCharacter))
            {
                return highlightRange;
            }
        }
    }
    
    // select inside of brackets by double-clicking
    unichar beginBrace, endBrace;
    BOOL isEndBrace = NO;
    switch (clickedCharacter) {
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
