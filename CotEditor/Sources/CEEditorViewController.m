/*
 
 CEEditorViewController.m
 
 CotEditor
 http://coteditor.com
 
 Created by nakamuxu on 2006-03-18.
 
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

#import "CEEditorViewController.h"
#import "CEWindowController.h"
#import "CENavigationBarController.h"
#import "CEEditorWrapper.h"
#import "CEEditorScrollView.h"
#import "CETextView.h"
#import "CESyntaxStyle.h"
#import "CEThemeManager.h"
#import "CELayoutManager.h"
#import "NSString+CENewLine.h"
#import "CEDefaults.h"
#import "Constants.h"


@interface CEEditorViewController ()

@property (nonatomic, nullable, weak) IBOutlet CEEditorScrollView *scrollView;
@property (nonatomic, nonnull) NSTextStorage *textStorage;

@property (nonatomic) BOOL highlightsCurrentLine;
@property (nonatomic) NSUInteger lastCursorLocation;


// readonly
@property (readwrite, nullable, nonatomic) IBOutlet CETextView *textView;
@property (readwrite, nullable, nonatomic) IBOutlet CENavigationBarController *navigationBarController;

@end




#pragma mark -

@implementation CEEditorViewController

#pragma mark Superclass Methods

// ------------------------------------------------------
/// initialize instance
- (nonnull instancetype)initWithTextStorage:(nonnull NSTextStorage *)textStorage
// ------------------------------------------------------
{
    self = [super init];
    if (self) {
        _textStorage = textStorage;
        _highlightsCurrentLine = [[NSUserDefaults standardUserDefaults] boolForKey:CEDefaultHighlightCurrentLineKey];
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
    
    [_textStorage removeLayoutManager:[_textView layoutManager]];
    _textView = nil;
}


// ------------------------------------------------------
/// nib name
- (nullable NSString *)nibName
// ------------------------------------------------------
{
    return @"EditorView";
}


// ------------------------------------------------------
/// setup UI
- (void)loadView
// ------------------------------------------------------
{
    [super loadView];
    
    // set textStorage to textView
    [[[self textView] layoutManager] replaceTextStorage:[self textStorage]];
    
    // 置換の Undo/Redo 後に再カラーリングできるように Undo/Redo アクションをキャッチ
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(recolorAfterUndoAndRedo:)
                                                 name:NSUndoManagerDidRedoChangeNotification
                                               object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(recolorAfterUndoAndRedo:)
                                                 name:NSUndoManagerDidUndoChangeNotification
                                               object:nil];
    
    // テーマの変更をキャッチ
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(themeDidUpdate:)
                                                 name:CEThemeDidUpdateNotification
                                               object:nil];
    
    // observe change of defaults
    for (NSString *key in [[self class] observedDefaultKeys]) {
        [[NSUserDefaults standardUserDefaults] addObserver:self
                                                forKeyPath:key
                                                   options:NSKeyValueObservingOptionNew
                                                   context:NULL];
    }
    
    // リサイズに現在行ハイライトを追従
    if (_highlightsCurrentLine) {
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(highlightCurrentLine)
                                                     name:NSViewFrameDidChangeNotification
                                                   object:[[self scrollView] contentView]];
    }
    
    // initial highlight (What a dirty workaround...)
    __weak typeof(self) weakSelf = self;
    dispatch_async(dispatch_get_main_queue(), ^{
        [weakSelf highlightCurrentLine];
    });
}


// ------------------------------------------------------
/// apply change of user setting
- (void)observeValueForKeyPath:(nullable NSString *)keyPath ofObject:(nullable id)object change:(nullable NSDictionary<NSString *, id> *)change context:(nullable void *)context
// ------------------------------------------------------
{
    id newValue = change[NSKeyValueChangeNewKey];
    
    if ([keyPath isEqualToString:CEDefaultHighlightCurrentLineKey]) {
        [self setHighlightsCurrentLine:[newValue boolValue]];
        if ([self highlightsCurrentLine]) {
            [self highlightCurrentLine];
        } else {
            NSRect rect = [[self textView] highlightLineRect];
            [[self textView] setHighlightLineRect:NSZeroRect];
            [[self textView] setNeedsDisplayInRect:rect avoidAdditionalLayout:YES];
        }
    }
}



#pragma mark Public Methods

// ------------------------------------------------------
/// 行番号表示設定をセット
- (void)setShowsLineNum:(BOOL)showsLineNum
// ------------------------------------------------------
{
    [[self scrollView] setRulersVisible:showsLineNum];
}


// ------------------------------------------------------
/// ナビゲーションバーを表示／非表示
- (void)setShowsNavigationBar:(BOOL)showsNavigationBar animate:(BOOL)performAnimation;
// ------------------------------------------------------
{
    [[self navigationBarController] setShown:showsNavigationBar animate:performAnimation];
}


// ------------------------------------------------------
/// ラップする／しないを切り替える
- (void)setWrapsLines:(BOOL)wrapsLines
// ------------------------------------------------------
{
    NSTextView *textView = [self textView];
    BOOL isVertical = ([textView layoutOrientation] == NSTextLayoutOrientationVertical);
    
    // 条件を揃えるためにいったん横書きに戻す (各項目の縦横の入れ替えは setLayoutOrientation: が良きに計らってくれる)
    [textView setLayoutOrientation:NSTextLayoutOrientationHorizontal];
    
    [[textView enclosingScrollView] setHasHorizontalScroller:!wrapsLines];
    [[textView textContainer] setWidthTracksTextView:wrapsLines];
    if (wrapsLines) {
        NSSize contentSize = [[textView enclosingScrollView] contentSize];
        CGFloat scale = [textView convertSize:NSMakeSize(1.0, 1.0) toView:nil].width;
        [[textView textContainer] setContainerSize:NSMakeSize(contentSize.width / scale, CGFLOAT_MAX)];
        [textView sizeToFit];
    } else {
        [[textView textContainer] setContainerSize:NSMakeSize(CGFLOAT_MAX, CGFLOAT_MAX)];
    }
    [textView setAutoresizingMask:(wrapsLines ? NSViewWidthSizable : NSViewNotSizable)];
    [textView setHorizontallyResizable:!wrapsLines];
    
    // 縦書きモードの際は改めて縦書きにする
    if (isVertical) {
        [textView setLayoutOrientation:NSTextLayoutOrientationVertical];
    }
}


// ------------------------------------------------------
/// 不可視文字の表示／非表示を切り替える
- (void)setShowsInvisibles:(BOOL)showsInvisibles
// ------------------------------------------------------
{
    [(CELayoutManager *)[[self textView] layoutManager] setShowsInvisibles:showsInvisibles];
}


// ------------------------------------------------------
/// アンチエイリアス適用を切り替える
- (void)setUsesAntialias:(BOOL)usesAntialias
// ------------------------------------------------------
{
    CELayoutManager *manager = (CELayoutManager *)[[self textView] layoutManager];

    [manager setUsesAntialias:usesAntialias];
    [[self textView] setNeedsDisplayInRect:[[self textView] visibleRect]];
}


// ------------------------------------------------------
/// キャレットを先頭に移動
- (void)setCaretToBeginning
// ------------------------------------------------------
{
    [[self textView] setSelectedRange:NSMakeRange(0, 0)];
}


// ------------------------------------------------------
/// シンタックススタイルを設定
- (void)applySyntax:(nonnull CESyntaxStyle *)syntaxStyle
// ------------------------------------------------------
{
    [[self textView] setInlineCommentDelimiter:[syntaxStyle inlineCommentDelimiter]];
    [[self textView] setBlockCommentDelimiters:[syntaxStyle blockCommentDelimiters]];
    [[self textView] setFirstCompletionCharacterSet:[syntaxStyle firstCompletionCharacterSet]];
}


// ------------------------------------------------------
/// Undo/Redo の後に全てを再カラーリング
- (void)recolorAfterUndoAndRedo:(nonnull NSNotification *)aNotification
// ------------------------------------------------------
{
    NSUndoManager *undoManager = [aNotification object];
    
    if (undoManager != [[self textView] undoManager]) { return; }
    
    // invalidate syntax highlighting only after Undo/Redo of "Replace All" action
    // To determine Undo/Redo type, use actionName that was set in CETextFinder (2014-04 by 1024jp)
    NSString *actionName = [undoManager isUndoing] ? [undoManager redoActionName] : [undoManager undoActionName];
    if (![actionName isEqualToString:NSLocalizedString(@"Replace All", nil)]) { return; }
    
    // 全テキストを再カラーリング
    [[self editorWrapper] setupColoringTimer];
}



#pragma mark Delegate

//=======================================================
// NSTextViewDelegate  < textView
//=======================================================

// ------------------------------------------------------
/// テキストが編集される
- (BOOL)textView:(nonnull NSTextView *)textView shouldChangeTextInRange:(NSRange)affectedCharRange replacementString:(nullable NSString *)replacementString
// ------------------------------------------------------
{
    // standardize line endings to LF (Key Typing, Script, Paste, Drop or Replace via Find Panel)
    // (Line endings replacemement by other text modifications are processed in the following methods.)
    //
    // # Methods Standardizing Line Endings on Text Editing
    //   - File Open:
    //       - CEDocument > applyContentToWindow
    //   - Key Typing, Script, Paste, Drop or Replace via Find Panel:
    //       - CEEditorViewController > textView:shouldChangeTextInRange:replacementString:
    
    if (!replacementString ||  // = attributesのみの変更
        ([replacementString length] == 0) ||  // = 文章の削除
        [[textView undoManager] isUndoing] ||  // = アンドゥ中
        [replacementString isEqualToString:@"\n"])
    {
        return YES;
    }
    
    // 挿入／置換する文字列に改行コードが含まれていたら、LF に置換する
    // （newStrが使用されるのはスクリプトからの入力時。キー入力は条件式を通過しない）
    CENewLineType replacementLineEndingType = [replacementString detectNewLineType];
    if ((replacementLineEndingType != CENewLineNone) && (replacementLineEndingType != CENewLineLF)) {
        NSString *newString = [replacementString stringByReplacingNewLineCharacersWith:CENewLineLF];
        
        [(CETextView *)textView replaceWithString:newString
                                            range:affectedCharRange
                                    selectedRange:NSMakeRange(affectedCharRange.location + [newString length], 0)
                                       actionName:nil];  // Action名は自動で付けられる？ので、指定しない
        
        return NO;
    }
    
    return YES;
}


// ------------------------------------------------------
/// 補完候補リストをセット
- (nonnull NSArray<NSString *> *)textView:(nonnull NSTextView *)textView completions:(nonnull NSArray<NSString *> *)words forPartialWordRange:(NSRange)charRange indexOfSelectedItem:(nullable NSInteger *)index
// ------------------------------------------------------
{
    // do nothing if completion is not suggested from the typed characters
    if (charRange.length == 0) { return @[]; }
    
    NSMutableOrderedSet<NSString *> *candidateWords = [NSMutableOrderedSet orderedSet];
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    NSString *partialWord = [[textView string] substringWithRange:charRange];

    // extract words in document and set to candidateWords
    if ([defaults boolForKey:CEDefaultCompletesDocumentWordsKey]) {
        if (charRange.length == 1 && ![[NSCharacterSet alphanumericCharacterSet] characterIsMember:[partialWord characterAtIndex:0]]) {
            // do nothing if the particle word is an symbol
            
        } else {
            NSString *documentString = [textView string];
            NSString *pattern = [NSString stringWithFormat:@"(?:^|\\b|(?<=\\W))%@\\w+?(?:$|\\b)",
                                 [NSRegularExpression escapedPatternForString:partialWord]];
            NSRegularExpression *regex = [NSRegularExpression regularExpressionWithPattern:pattern options:0 error:nil];
            [regex enumerateMatchesInString:documentString options:0
                                      range:NSMakeRange(0, [documentString length])
                                 usingBlock:^(NSTextCheckingResult *result, NSMatchingFlags flags, BOOL *stop)
             {
                 [candidateWords addObject:[documentString substringWithRange:[result range]]];
             }];
        }
    }
    
    // copy words defined in syntax style
    if ([defaults boolForKey:CEDefaultCompletesSyntaxWordsKey]) {
        NSArray<NSString *> *syntaxWords = [[self syntaxStyle] completionWords];
        for (NSString *word in syntaxWords) {
            if ([word rangeOfString:partialWord options:NSCaseInsensitiveSearch|NSAnchoredSearch].location != NSNotFound) {
                [candidateWords addObject:word];
            }
        }
    }
    
    // copy the standard words from default completion words
    if ([defaults boolForKey:CEDefaultCompletesStandartWordsKey]) {
        [candidateWords addObjectsFromArray:words];
    }
    
    // provide nothing if there is only a candidate which is same as input word
    if ([candidateWords count] == 1 && [[candidateWords firstObject] caseInsensitiveCompare:partialWord] == NSOrderedSame) {
        return @[];
    }

    return [candidateWords array];
}


// ------------------------------------------------------
/// text did edit.
- (void)textDidChange:(nonnull NSNotification *)aNotification
// ------------------------------------------------------
{
    // 文書情報更新（選択範囲・キャレット位置が変更されないまま全置換が実行された場合への対応）
    [[[[self view] window] windowController] setupEditorInfoUpdateTimer];
    
    // 全テキストを再カラーリング
    [[self editorWrapper] setupColoringTimer];

    // アウトラインメニュー項目更新
    [[self editorWrapper] setupOutlineMenuUpdateTimer];
    
    // 非互換文字リスト更新
    [[[[self view] window] windowController] updateIncompatibleCharsIfNeeded];

    // フラグが立っていたら、入力補完を再度実行する
    // （フラグは CETextView > insertCompletion:forPartialWordRange:movement:isFinal: で立てている）
    if ([[self textView] needsRecompletion]) {
        [[self textView] setNeedsRecompletion:NO];
        [[self textView] completeAfterDelay:0.05];
    }
}


// ------------------------------------------------------
/// the selection of main textView was changed.
- (void)textViewDidChangeSelection:(nonnull NSNotification *)aNotification
// ------------------------------------------------------
{
    // highlight the current line
    [self highlightCurrentLine];

    // update document information
    [[[[self view] window] windowController] setupEditorInfoUpdateTimer];

    // update selected item of the outline menu
    [self updateOutlineMenuSelection];

    // highlight matching brace
    
    // The following part is based on Smultron's SMLTextView.m by Peter Borg. (2006-09-09)
    // Smultron 2 was distributed on <http://smultron.sourceforge.net> under the terms of the BSD license.
    // Copyright (c) 2004-2006 Peter Borg

    if (![[NSUserDefaults standardUserDefaults] boolForKey:CEDefaultHighlightBracesKey]) { return; }
    
    NSString *completeString = [[self textView] string];
    if ([completeString length] == 0) { return; }
    
    NSInteger location = [[self textView] selectedRange].location;
    NSInteger difference = location - [self lastCursorLocation];
    [self setLastCursorLocation:location];

    // The brace will be highlighted only when the cursor moves forward, just like on Xcode. (2006-09-10)
    if (difference != 1) {
        return; // If the difference is more than one, they've moved the cursor with the mouse or it has been moved by resetSelectedRange below and we shouldn't check for matching braces then.
    }
    
    // check the caracter just before the cursor
    location--;
    
    unichar beginBrace, endBrace;
    switch ([completeString characterAtIndex:location]) {
        case ')':
            beginBrace = '(';
            endBrace = ')';
            break;
            
        case '}':
            beginBrace = '{';
            endBrace = '}';
            break;
            
        case ']':
            beginBrace = '[';
            endBrace = ']';
            break;
            
        case '>':
            if (![[NSUserDefaults standardUserDefaults] boolForKey:CEDefaultHighlightLtGtKey]) { return; }
            beginBrace = '<';
            endBrace = '>';
            break;
            
        default:
            return;
    }
    
    NSUInteger skippedBraceCount = 0;

    while (location--) {
        unichar character = [completeString characterAtIndex:location];
        if (character == beginBrace) {
            if (!skippedBraceCount) {
                // highlight the matching brace
                [[self textView] showFindIndicatorForRange:NSMakeRange(location, 1)];
                return;
            } else {
                skippedBraceCount--;
            }
        } else if (character == endBrace) {
            skippedBraceCount++;
        }
    }
    
    // do not beep when the typed brace is `>`
    //  -> Since `>` (and `<`) can often be used alone unlike other braces.
    if (endBrace != '>') {
        NSBeep();
    }
}


// ------------------------------------------------------
/// font is changed
- (void)textViewDidChangeTypingAttributes:(nonnull NSNotification *)notification
// ------------------------------------------------------
{
    [self highlightCurrentLine];
}



#pragma mark Notifications

//=======================================================
// Notification  < CEThemeManager
//=======================================================

// ------------------------------------------------------
/// テーマが更新された
- (void)themeDidUpdate:(nonnull NSNotification *)notification
// ------------------------------------------------------
{
    if ([[notification userInfo][CEOldNameKey] isEqualToString:[[[self textView] theme] name]]) {
        CETheme *theme = [[CEThemeManager sharedManager] themeWithName:[notification userInfo][CENewNameKey]];
        
        if (!theme) { return; }
        
        [[self textView] setTheme:theme];
        [[self textView] setSelectedRanges:[[self textView] selectedRanges]];  // 現在行のハイライトカラーの更新するために選択し直す
        [[self editorWrapper] invalidateSyntaxColoring];
    }
}



#pragma mark Private Methods

// ------------------------------------------------------
/// default keys to observe update
+ (nonnull NSArray<NSString *> *)observedDefaultKeys
// ------------------------------------------------------
{
    return @[CEDefaultHighlightCurrentLineKey,
             ];
}

// ------------------------------------------------------
/// return shared sytnax style
- (nullable CESyntaxStyle *)syntaxStyle
// ------------------------------------------------------
{
    return [[self editorWrapper] syntaxStyle];
}


// ------------------------------------------------------
/// アウトラインメニューの選択項目を更新
- (void)updateOutlineMenuSelection
// ------------------------------------------------------
{
    if ([[self textView] needsUpdateOutlineMenuItemSelection]) {
        [[self navigationBarController] selectOutlineMenuItemWithRange:[[self textView] selectedRange]];
    } else {
        [[self textView] setNeedsUpdateOutlineMenuItemSelection:YES];
        [[self navigationBarController] updatePrevNextButtonEnabled];
    }
}


// ------------------------------------------------------
/// テキストビュー分割削除ボタンの有効化／無効化を制御
- (void)updateCloseSplitViewButton:(BOOL)isEnabled
// ------------------------------------------------------
{
    [[self navigationBarController] setCloseSplitButtonEnabled:isEnabled];
}


// ------------------------------------------------------
/// カレント行をハイライト表示
- (void)highlightCurrentLine
// ------------------------------------------------------
{
    if (![self highlightsCurrentLine]) { return; }
    
    // 最初に（表示前に） TextView にテキストをセットした際にムダに演算が実行されるのを避ける (2014-07 by 1024jp)
    if (![[[self view] window] isVisible]) { return; }
    
    NSLayoutManager *layoutManager = [[self textView] layoutManager];
    CETextView *textView = [self textView];
    NSRect rect;
    
    // 選択行の矩形を得る
    if ([textView selectedRange].location == [[textView string] length] && [layoutManager extraLineFragmentTextContainer]) {  // 最終行
        rect = [layoutManager extraLineFragmentRect];
        
    } else {
        NSRange lineRange = [[textView string] lineRangeForRange:[textView selectedRange]];
        lineRange.length -= (lineRange.length > 0) ? 1 : 0;  // remove line ending
        NSRange glyphRange = [layoutManager glyphRangeForCharacterRange:lineRange actualCharacterRange:NULL];
        
        rect = [layoutManager boundingRectForGlyphRange:glyphRange inTextContainer:[textView textContainer]];
        rect.size.width = [[textView textContainer] containerSize].width;
    }
    
    // 周囲の空白の調整
    CGFloat padding = [[textView textContainer] lineFragmentPadding];
    rect.origin.x = padding;
    rect.size.width -= 2 * padding;
    rect = NSOffsetRect(rect, [textView textContainerOrigin].x, [textView textContainerOrigin].y);
    
    // ハイライト矩形を描画
    if (!NSEqualRects([textView highlightLineRect], rect)) {
        // clear previous highlihght
        [textView setNeedsDisplayInRect:[textView highlightLineRect] avoidAdditionalLayout:YES];
        
        // draw highlight
        [textView setHighlightLineRect:rect];
        [textView setNeedsDisplayInRect:rect avoidAdditionalLayout:YES];
    }
}

@end
