/*
 
 CETextView.m
 
 CotEditor
 http://coteditor.com
 
 Created by nakamuxu on 2005-03-30.
 
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
#import "CEEditorScrollView.h"

#import "CEColorCodePanelController.h"
#import "CECharacterPopoverController.h"
#import "CEDocument.h"
#import "CEAlphaWindow.h"

#import "CEThemeManager.h"
#import "CEKeyBindingManager.h"
#import "CEScriptManager.h"

#import "CEDefaults.h"
#import "Constants.h"

#import "NSTextView+CELayout.h"
#import "NSString+CECounting.h"
#import "NSString+CEEncoding.h"
#import "NSFont+CESize.h"


// notifications
NSString *_Nonnull const CETextViewDidBecomeFirstResponderNotification = @"CETextViewDidBecomeFirstResponderNotification";


// constant
static NSString *_Nonnull const CESelectedRangesKey = @"selectedRange";
static NSString *_Nonnull const CEVisibleRectKey = @"visibleRect";
static NSString *_Nonnull const CEAutoBalancedClosingBracketAttributeName = @"autoBalancedClosingBracket";

static const NSInteger kNoMenuItem = -1;


@interface CETextView ()

@property (nonatomic, weak) NSTimer *completionTimer;
@property (nonatomic, copy) NSString *particalCompletionWord;  // ユーザが実際に入力した補完の元になる文字列

@property (nonatomic) CGFloat lineHeight;
@property (nonatomic) NSColor *highlightLineColor;  // カレント行ハイライト色

@property (nonatomic) CGFloat initialMagnificationScale;
@property (nonatomic) CGFloat deferredMagnification;

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
- (nullable instancetype)initWithCoder:(nonnull NSCoder *)coder
// ------------------------------------------------------
{
    self = [super initWithCoder:(NSCoder *)coder];
    if (self) {
        // set class identifier for window restoration
        [self setIdentifier:@"coreTextView"];
        
        NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
        
        // setup layoutManager and textContainer
        CELayoutManager *layoutManager = [[CELayoutManager alloc] init];
        [layoutManager setUsesScreenFonts:YES];
        [layoutManager setUsesAntialias:[defaults boolForKey:CEDefaultShouldAntialiasKey]];
        [[self textContainer] replaceLayoutManager:layoutManager];
        
        // set layer drawing policies
        [self setLayerContentsRedrawPolicy:NSViewLayerContentsRedrawDuringViewResize];
        [self setLayerContentsPlacement:NSViewLayerContentsPlacementScaleAxesIndependently];
        
        // set layout values
        [self setMinSize:[self frame].size];
        [self setMaxSize:NSMakeSize(CGFLOAT_MAX, CGFLOAT_MAX)];
        [self setHorizontallyResizable:YES];
        [self setVerticallyResizable:YES];
        [self setTextContainerInset:NSMakeSize((CGFloat)[defaults doubleForKey:CEDefaultTextContainerInsetWidthKey],
                                               (CGFloat)([defaults doubleForKey:CEDefaultTextContainerInsetHeightTopKey] +
                                                         [defaults doubleForKey:CEDefaultTextContainerInsetHeightBottomKey]) / 2)];
        
        // setup behaviors
        [self setSmartInsertDeleteEnabled:[defaults boolForKey:CEDefaultSmartInsertAndDeleteKey]];
        [self setContinuousSpellCheckingEnabled:[defaults boolForKey:CEDefaultCheckSpellingAsTypeKey]];
        [self setAutomaticQuoteSubstitutionEnabled:[defaults boolForKey:CEDefaultEnableSmartQuotesKey]];
        [self setAutomaticDashSubstitutionEnabled:[defaults boolForKey:CEDefaultEnableSmartDashesKey]];
        [self setAllowsDocumentBackgroundColorChange:NO];
        [self setAllowsUndo:YES];
        [self setRichText:NO];
        [self setImportsGraphics:NO];
        [self setUsesFindPanel:YES];
        [self setAcceptsGlyphInfo:YES];
        _autoTabExpandEnabled = [defaults boolForKey:CEDefaultAutoExpandTabKey];
        
        // set link detection
        [self setAutomaticLinkDetectionEnabled:[defaults boolForKey:CEDefaultAutoLinkDetectionKey]];
        [self setLinkTextAttributes:@{NSCursorAttributeName: [NSCursor pointingHandCursor],
                                      NSUnderlineStyleAttributeName: @(NSUnderlineStyleSingle)}];
        
        // setup theme
        [self setTheme:[[CEThemeManager sharedManager] themeWithName:[defaults stringForKey:CEDefaultThemeKey]]];
        
        // set font
        CGFloat fontSize = (CGFloat)[defaults doubleForKey:CEDefaultFontSizeKey];
        NSString *fontName = [defaults stringForKey:CEDefaultFontNameKey];
        NSFont *font = [NSFont fontWithName:fontName size:fontSize] ?: [NSFont userFontOfSize:fontSize];
        [super setFont:font];
        [layoutManager setTextFont:font];
        
        // set paragraph style values
        _lineHeight = (CGFloat)[defaults doubleForKey:CEDefaultLineHeightKey];
        _tabWidth = [defaults integerForKey:CEDefaultTabWidthKey];
        
        [self invalidateDefaultParagraphStyle];
        
        // observe change of defaults
        for (NSString *key in [[self class] observedDefaultKeys]) {
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
    for (NSString *key in [[self class] observedDefaultKeys]) {
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
    [[NSNotificationCenter defaultCenter] postNotificationName:CETextViewDidBecomeFirstResponderNotification
                                                        object:self];
    
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
                                                                                        modifierMask:[theEvent modifierFlags]];
        
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
        NSString *yen = [NSString stringWithCharacters:&kYenCharacter length:1];
        
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
            
            if (wrappingFormat) {
                NSString *selectedString = [[self string] substringWithRange:[self selectedRange]];
                string = [NSString stringWithFormat:wrappingFormat, selectedString];
            }
            if ([self shouldChangeTextInRange:[self selectedRange] replacementString:string]) {
                [[self textStorage] replaceCharactersInRange:[self selectedRange] withString:string];
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
    
    // add "Copy as Rich Text" menu item
    NSUInteger copyIndex = [menu indexOfItemWithTarget:nil andAction:@selector(copy:)];
    [menu insertItemWithTitle:NSLocalizedString(@"Copy as Rich Text", nil)
                       action:@selector(copyWithStyle:)
                keyEquivalent:@""
                      atIndex:(copyIndex + 1)];
    
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
    if (![sender isKindOfClass:[NSFontManager class]]) { return; }
    
    NSFont *newFont = [sender convertFont:[self font]];
    
    // apply to all text views sharing textStorage
    for (NSLayoutManager *layoutManager in [[self textStorage] layoutManagers]) {
        [[layoutManager firstTextView] setFont:newFont];
    }
}


// ------------------------------------------------------
/// make sure to return by user defined font
- (nullable NSFont *)font
// ------------------------------------------------------
{
    return [(CELayoutManager *)[self layoutManager] textFont] ?: [super font];
}


// ------------------------------------------------------
/// フォントを設定
- (void)setFont:(nullable NSFont *)font
// ------------------------------------------------------
{
    if (!font) { return; }
    
    // 複合フォントで行間が等間隔でなくなる問題を回避するため、CELayoutManager にもフォントを持たせておく
    // -> [NSTextView font] を使うと、「1バイトフォントを指定して日本語が入力されている」場合に
    //    日本語フォントを返してくることがあるため、CELayoutManager からは [textView font] を使わない
    [(CELayoutManager *)[self layoutManager] setTextFont:font];
    [super setFont:font];
    
    [self invalidateDefaultParagraphStyle];
    
    // update current text
    [self invalidateStyle];
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
        CGFloat charWidth = [(CELayoutManager *)[self layoutManager] spaceWidth];
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
}


// ------------------------------------------------------
/// 表示方向を変更
- (void)setLayoutOrientation:(NSTextLayoutOrientation)theOrientation
// ------------------------------------------------------
{
    // reset text wrapping
    if (theOrientation != [self layoutOrientation] && [self wrapsLines]) {
        [[self textContainer] setContainerSize:NSMakeSize(0, CGFLOAT_MAX)];
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
        NSURL *documentURL = [[self document] fileURL];
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
/// apply change of user setting
- (void)observeValueForKeyPath:(nullable NSString *)keyPath ofObject:(nullable id)object change:(nullable NSDictionary<NSString *, id> *)change context:(nullable void *)context
// ------------------------------------------------------
{
    id newValue = change[NSKeyValueChangeNewKey];
    NSRange wholeRange = NSMakeRange(0, [[self textStorage] length]);
    
    if ([keyPath isEqualToString:CEDefaultAutoExpandTabKey]) {
        [self setAutoTabExpandEnabled:[newValue boolValue]];
        
    } else if ([keyPath isEqualToString:CEDefaultSmartInsertAndDeleteKey]) {
        [self setSmartInsertDeleteEnabled:[newValue boolValue]];
        
    } else if ([keyPath isEqualToString:CEDefaultCheckSpellingAsTypeKey]) {
        [self setContinuousSpellCheckingEnabled:[newValue boolValue]];
        
    } else if ([keyPath isEqualToString:CEDefaultPageGuideColumnKey]) {
        [self setNeedsDisplayInRect:[self visibleRect] avoidAdditionalLayout:YES];
        
    } else if ([keyPath isEqualToString:CEDefaultTabWidthKey]) {
        [self setTabWidth:[newValue unsignedIntegerValue]];
        
    } else if ([keyPath isEqualToString:CEDefaultEnablesHangingIndentKey] ||
               [keyPath isEqualToString:CEDefaultHangingIndentWidthKey])
    {
        if ([keyPath isEqualToString:CEDefaultEnablesHangingIndentKey] && ![newValue boolValue]) {
            [[self textStorage] addAttribute:NSParagraphStyleAttributeName value:[self defaultParagraphStyle] range:wholeRange];
        } else {
            [(CELayoutManager *)[self layoutManager] invalidateIndentInRange:wholeRange];
        }
        
    } else if ([keyPath isEqualToString:CEDefaultEnableSmartQuotesKey]) {
        [self setAutomaticQuoteSubstitutionEnabled:[newValue boolValue]];
        
    } else if ([keyPath isEqualToString:CEDefaultEnableSmartDashesKey]) {
        [self setAutomaticDashSubstitutionEnabled:[newValue boolValue]];
        
    } else if ([keyPath isEqualToString:CEDefaultAutoLinkDetectionKey]) {
        [self setAutomaticLinkDetectionEnabled:[newValue boolValue]];
        if ([self isAutomaticLinkDetectionEnabled]) {
            [self detectLinkIfNeeded];
        } else {
            // remove current links
            [[self textStorage] removeAttribute:NSLinkAttributeName range:wholeRange];
        }
    
    } else if ([keyPath isEqualToString:CEDefaultFontNameKey] || [keyPath isEqualToString:CEDefaultFontSizeKey]) {
        NSFont *font = [NSFont fontWithName:[[NSUserDefaults standardUserDefaults] stringForKey:CEDefaultFontNameKey]
                                       size:(CGFloat)[[NSUserDefaults standardUserDefaults] doubleForKey:CEDefaultFontSizeKey]];
        [self setFont:font];
        
    } else if ([keyPath isEqualToString:CEDefaultShouldAntialiasKey]) {
        [self setUsesAntialias:[newValue boolValue]];
        
    } else if ([keyPath isEqualToString:CEDefaultLineHeightKey]) {
        [self setLineHeight:(CGFloat)[newValue doubleValue]];
        
        // reset visible area
        [self scrollRangeToVisible:[self selectedRange]];
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
    if (([menuItem action] == @selector(copyWithStyle:)) ||
        ([menuItem action] == @selector(exchangeFullwidthRoman:)) ||
        ([menuItem action] == @selector(exchangeHalfwidthRoman:)) ||
        ([menuItem action] == @selector(exchangeKatakana:)) ||
        ([menuItem action] == @selector(exchangeHiragana:)) ||
        ([menuItem action] == @selector(normalizeUnicodeWithNFD:)) ||
        ([menuItem action] == @selector(normalizeUnicodeWithNFC:)) ||
        ([menuItem action] == @selector(normalizeUnicodeWithNFKD:)) ||
        ([menuItem action] == @selector(normalizeUnicodeWithNFKC:)) ||
        ([menuItem action] == @selector(normalizeUnicodeWithNFKCCF:)) ||
        ([menuItem action] == @selector(normalizeUnicodeWithModifiedNFC:)) ||
        ([menuItem action] == @selector(normalizeUnicodeWithModifiedNFD:)))
    {
        return ([self selectedRange].length > 0);
        // （カラーコード編集メニューは常に有効）
        
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



#pragma mark Public Accessors

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
    
    [(CELayoutManager *)[self layoutManager] setInvisiblesColor:[theme invisiblesColor]];
    
    // 背景色に合わせたスクローラのスタイルをセット
    NSInteger knobStyle = [theme isDarkTheme] ? NSScrollerKnobStyleLight : NSScrollerKnobStyleDefault;
    [[self enclosingScrollView] setScrollerKnobStyle:knobStyle];
    
    _theme = theme;
    
    // redraw selection
    [self setNeedsDisplayInRect:[self visibleRect] avoidAdditionalLayout:YES];
}


// ------------------------------------------------------
/// タブ幅を変更
- (void)setTabWidth:(NSUInteger)tabWidth
// ------------------------------------------------------
{
    if (tabWidth == [self tabWidth]) { return; }
    
    _tabWidth = tabWidth;
    
    [self invalidateDefaultParagraphStyle];
    
    // update current text
    [self invalidateStyle];
}


// ------------------------------------------------------
/// 行間値をセットし、テキストと行番号を再描画
- (void)setLineHeight:(CGFloat)lineHeight
// ------------------------------------------------------
{
    if (lineHeight == [self lineHeight]) { return; }
    
    _lineHeight = lineHeight;
    
    [self invalidateDefaultParagraphStyle];
    
    // update current text
    [self invalidateStyle];
}


// ------------------------------------------------------
/// アンチエイリアス適用を切り替える
- (void)setUsesAntialias:(BOOL)usesAntialias
// ------------------------------------------------------
{
    [(CELayoutManager *)[self layoutManager] setUsesAntialias:usesAntialias];
    [self setNeedsDisplayInRect:[self visibleRect] avoidAdditionalLayout:YES];
}


// ------------------------------------------------------
/// アンチエイリアスを適用しているか
- (BOOL)usesAntialias
// ------------------------------------------------------
{
    return [(CELayoutManager *)[self layoutManager] usesAntialias];
}


// ------------------------------------------------------
/// 不可視文字の表示／非表示を切り替える
- (void)setShowsInvisibles:(BOOL)showsInvisibles
// ------------------------------------------------------
{
    [(CELayoutManager *)[self layoutManager] setShowsInvisibles:showsInvisibles];
}


// ------------------------------------------------------
/// 不可視文字を表示しているか
- (BOOL)showsInvisibles
// ------------------------------------------------------
{
    return [(CELayoutManager *)[self layoutManager] showsInvisibles];
}



#pragma mark Public Methods

// ------------------------------------------------------
/// invalidate string attributes
- (void)invalidateStyle
// ------------------------------------------------------
{
    NSRange range = NSMakeRange(0, [[self textStorage] length]);
    
    if (range.length == 0) { return; }
    
    // UTF-16 でないものを UTF-16 で表示した時など当該フォントで表示できない文字が表示されてしまった後だと、
    // 設定されたフォントでないもので表示されることがあるため、リセットする
    [[self textStorage] setAttributes:[self typingAttributes] range:range];
    
    [(CELayoutManager *)[self layoutManager] invalidateIndentInRange:range];
    [self detectLinkIfNeeded];
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
        NSMutableAttributedString *styledText = [[NSMutableAttributedString alloc] initWithString:plainText attributes:[self typingAttributes]];
        
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
/// 半角円マークを入力
- (IBAction)inputYenMark:(nullable id)sender
// ------------------------------------------------------
{
    [super insertText:[NSString stringWithCharacters:&kYenCharacter length:1]
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
/// default keys to observe update
+ (nonnull NSArray<NSString *> *)observedDefaultKeys
// ------------------------------------------------------
{
    return @[CEDefaultAutoExpandTabKey,
             CEDefaultSmartInsertAndDeleteKey,
             CEDefaultCheckSpellingAsTypeKey,
             CEDefaultPageGuideColumnKey,
             CEDefaultEnableSmartQuotesKey,
             CEDefaultEnableSmartDashesKey,
             CEDefaultTabWidthKey,
             CEDefaultHangingIndentWidthKey,
             CEDefaultEnablesHangingIndentKey,
             CEDefaultAutoLinkDetectionKey,
             CEDefaultFontNameKey,
             CEDefaultFontSizeKey,
             CEDefaultShouldAntialiasKey,
             CEDefaultLineHeightKey,
             ];
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
    return [[self document] lineEnding];
}


// ------------------------------------------------------
/// document object representing the text view contents
- (nullable __kindof NSDocument *)document
// ------------------------------------------------------
{
    return [[[self window] windowController] document];
}


// ------------------------------------------------------
/// set defaultParagraphStyle based on font, tabWidth, and line height
- (void)invalidateDefaultParagraphStyle
// ------------------------------------------------------
{
    NSMutableParagraphStyle *paragraphStyle = [[NSParagraphStyle defaultParagraphStyle] mutableCopy];
    
    // set line height
    //   -> The actual line height will be calculated in CELayoutManager and CEATSTypesetter based on this line height multiple.
    //      Because the default Cocoa Text System calculate line height differently
    //      if the first character of the document is drawn with another font (typically by a composite font).
    [paragraphStyle setLineHeightMultiple:[self lineHeight]];
    
    // calculate tab interval
    NSFont *font = [[self font] screenFont] ?: [self font];
    CGFloat tabInterval = [self tabWidth] * [font advancementForCharacter:' '];
    [paragraphStyle setTabStops:@[]];  // clear default tab stops
    [paragraphStyle setDefaultTabInterval:tabInterval];
    
    [self setDefaultParagraphStyle:paragraphStyle];
    
    // add paragraph style also to the typing attributes
    //   -> textColor and font are added automatically.
    NSMutableDictionary *typingAttributes = [[self typingAttributes] mutableCopy];
    typingAttributes[NSParagraphStyleAttributeName] = paragraphStyle;
    [self setTypingAttributes:typingAttributes];
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
    
    // redraw visible area
    [self setNeedsDisplayInRect:[self visibleRect] avoidAdditionalLayout:YES];
}


// ------------------------------------------------------
/// カスタムキーバインドで文字列入力
- (void)insertCustomTextWithPatternNumber:(NSInteger)patternNumber
// ------------------------------------------------------
{
    NSArray<NSString *> *texts = [[NSUserDefaults standardUserDefaults] stringArrayForKey:CEDefaultInsertCustomTextArrayKey];
    
    if (patternNumber < 0 || patternNumber >= [texts count]) { return; }
    
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
- (NSUInteger)indentLevelOfString:(nonnull NSString *)string
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
    NSCharacterSet *charSet = [self firstSyntaxCompletionCharacterSet];
    
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

@implementation CETextView (Scaling)

#pragma mark Superclass Methods

// ------------------------------------------------------
/// change font size by pinch gesture
- (void)magnifyWithEvent:(nonnull NSEvent *)event
// ------------------------------------------------------
{
    if ([event phase] & NSEventPhaseBegan) {
        [self setInitialMagnificationScale:[self scale]];
    }
    
    CGFloat scale = [self scale] + [event magnification];
    CGPoint center = [self convertPoint:[event locationInWindow] fromView:nil];
    
    // hold a bit at scale 1.0
    if (([self initialMagnificationScale] > 1.0 && scale < 1.0) ||  // zoom-out
        ([self initialMagnificationScale] <= 1.0 && scale >= 1.0))  // zoom-in
    {
        self.deferredMagnification += [event magnification];
        if (fabs([self deferredMagnification]) > 0.4) {
            scale = [self scale] + [self deferredMagnification] / 2;
            self.deferredMagnification = 0;
            [self setInitialMagnificationScale:scale];
        } else {
            scale = 1.0;
        }
    }
    
    // sanitize final scale
    if ([event phase] & NSEventPhaseEnded) {
        if (fabs(scale - 1.0) < 0.05) {
            scale = 1.0;
        }
    }
    
    [self setScale:scale centeredAtPoint:center];
}


// ------------------------------------------------------
/// reset font size by two-finger double tap
- (void)smartMagnifyWithEvent:(nonnull NSEvent *)event
// ------------------------------------------------------
{
    CGFloat scale = ([self scale] == 1.0) ? 1.5 : 1.0;
    CGPoint center = [self convertPoint:[event locationInWindow] fromView:nil];
    
    [self setScale:scale centeredAtPoint:center];
}



#pragma mark Action Messages

// ------------------------------------------------------
/// scale up
- (IBAction)biggerFont:(nullable id)sender
// ------------------------------------------------------
{
    [self setScaleKeepingVisibleArea:[self scale] * 1.1];
}


// ------------------------------------------------------
/// scale down
- (IBAction)smallerFont:(nullable id)sender
// ------------------------------------------------------
{
    [self setScaleKeepingVisibleArea:[self scale] / 1.1];
}


// ------------------------------------------------------
/// reset scale and font to default
- (IBAction)resetFont:(nullable id)sender
// ------------------------------------------------------
{
    NSString *name = [[NSUserDefaults standardUserDefaults] stringForKey:CEDefaultFontNameKey];
    CGFloat size = (CGFloat)[[NSUserDefaults standardUserDefaults] doubleForKey:CEDefaultFontSizeKey];
    [self setFont:[NSFont fontWithName:name size:size] ? : [NSFont userFontOfSize:size]];
    
    [self setScaleKeepingVisibleArea:1.0];
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
