/*
 
 CETextViewController.m
 
 CotEditor
 http://coteditor.com
 
 Created by 1024jp on 2016-06-18.
 
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

#import "CETextViewController.h"
#import "CETextView.h"

#import "CESyntaxStyle.h"
#import "CEScriptManager.h"
#import "CEGoToLineViewController.h"

#import "CEDefaults.h"
#import "Constants.h"

#import "NSString+CENewLine.h"


static const NSTimeInterval kCurrentLineUpdateInterval = 0.01;


@interface CETextViewController () <NSTextViewDelegate>

@property (nonatomic, nullable, weak) NSTimer *currentLineUpdateTimer;
@property (nonatomic) NSUInteger lastCursorLocation;

@property (readwrite, nonatomic, nullable) IBOutlet CETextView *textView;

@end




#pragma mark -

@implementation CETextViewController

#pragma mark Public Methods

// ------------------------------------------------------
/// clean up
- (void)dealloc
// ------------------------------------------------------
{
    [_currentLineUpdateTimer invalidate];
    
    [[NSUserDefaults standardUserDefaults] removeObserver:self forKeyPath:CEDefaultHighlightCurrentLineKey];
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    
    // detatch textStorage safely
    [[[self textView] textStorage] removeLayoutManager:[[self textView] layoutManager]];
}


// ------------------------------------------------------
/// initialize instance
- (void)viewDidLoad
// ------------------------------------------------------
{
    [super viewDidLoad];
    
    // observe change of defaults
    [[NSUserDefaults standardUserDefaults] addObserver:self
                                            forKeyPath:CEDefaultHighlightCurrentLineKey
                                               options:NSKeyValueObservingOptionNew
                                               context:NULL];
    
    // update current line highlight on changing frame size with a delay
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(setupCurrentLineUpdateTimer)
                                                 name:NSViewFrameDidChangeNotification
                                               object:[self textView]];
}


// ------------------------------------------------------
/// apply change of user setting
- (void)observeValueForKeyPath:(nullable NSString *)keyPath ofObject:(nullable id)object change:(nullable NSDictionary<NSString *, id> *)change context:(nullable void *)context
// ------------------------------------------------------
{
    id newValue = change[NSKeyValueChangeNewKey];
    
    if ([keyPath isEqualToString:CEDefaultHighlightCurrentLineKey]) {
        if ([newValue boolValue]) {
            [self setupCurrentLineUpdateTimer];
        } else {
            NSRect rect = [[self textView] highlightLineRect];
            [[self textView] setHighlightLineRect:NSZeroRect];
            [[self textView] setNeedsDisplayInRect:rect avoidAdditionalLayout:YES];
        }
    }
}



#pragma mark Public Methods

// ------------------------------------------------------
/// change line number visibility
- (void)setShowsLineNumber:(BOOL)showsLineNumber
// ------------------------------------------------------
{
    [[self scrollView] setRulersVisible:showsLineNumber];
}


// ------------------------------------------------------
/// シンタックススタイルを設定
- (void)setSyntaxStyle:(nullable CESyntaxStyle *)syntaxStyle
// ------------------------------------------------------
{
    _syntaxStyle = syntaxStyle;
    
    [[self textView] setInlineCommentDelimiter:[syntaxStyle inlineCommentDelimiter]];
    [[self textView] setBlockCommentDelimiters:[syntaxStyle blockCommentDelimiters]];
    [[self textView] setFirstSyntaxCompletionCharacterSet:[syntaxStyle firstCompletionCharacterSet]];
}



#pragma mark Delegate

//=======================================================
// NSTextViewDelegate  < textView
//=======================================================

// ------------------------------------------------------
/// text will be edited
- (BOOL)textView:(nonnull NSTextView *)textView shouldChangeTextInRange:(NSRange)affectedCharRange replacementString:(nullable NSString *)replacementString
// ------------------------------------------------------
{
    // standardize line endings to LF (Key Typing, Script, Paste, Drop or Replace via Find Panel)
    // (Line endings replacemement by other text modifications are processed in the following methods.)
    //
    // # Methods Standardizing Line Endings on Text Editing
    //   - File Open:
    //       - CEDocument > readFromURL:ofType:error:
    //   - Key Typing, Script, Paste, Drop or Replace via Find Panel:
    //       - CETextViewController > textView:shouldChangeTextInRange:replacementString:
    
    if (!replacementString ||  // = only attributes changed
        ([replacementString length] == 0) ||  // = text deleted
        [[textView undoManager] isUndoing] ||  // = undo
        [replacementString isEqualToString:@"\n"])
    {
        return YES;
    }
    
    // replace all line endings with LF
    CENewLineType replacementLineEndingType = [replacementString detectNewLineType];
    if ((replacementLineEndingType != CENewLineNone) && (replacementLineEndingType != CENewLineLF)) {
        NSString *newString = [replacementString stringByReplacingNewLineCharacersWith:CENewLineLF];
        
        [textView replaceWithString:newString
                              range:affectedCharRange
                      selectedRange:NSMakeRange(affectedCharRange.location + [newString length], 0)
                         actionName:nil];  // Action name will be set automatically.
        
        return NO;
    }
    
    return YES;
}


// ------------------------------------------------------
/// build completion list
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
        for (NSString *word in [[self syntaxStyle] completionWords]) {
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
/// add script menu to context menu
- (nullable NSMenu *)textView:(nonnull NSTextView *)view menu:(nonnull NSMenu *)menu forEvent:(nonnull NSEvent *)event atIndex:(NSUInteger)charIndex
// ------------------------------------------------------
{
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
/// text did edit.
- (void)textDidChange:(nonnull NSNotification *)notification
// ------------------------------------------------------
{
    CETextView *textView = [notification object];
    
    // retry completion if needed
    //   -> Flag is set in CETextView > `insertCompletion:forPartialWordRange:movement:isFinal:`
    if ([textView needsRecompletion]) {
        [textView setNeedsRecompletion:NO];
        [textView completeAfterDelay:0.05];
    }
}


// ------------------------------------------------------
/// the selection of main textView was changed.
- (void)textViewDidChangeSelection:(nonnull NSNotification *)notification
// ------------------------------------------------------
{
    NSTextView *textView = [notification object];
    if (![textView isKindOfClass:[NSTextView class]]) { return; }
    
    // highlight the current line
    // -> For the selection change, call `updateCurrentLineRect` directly rather than setting currentLineUpdateTimer
    //    in order to provide a quick feedback of change to users.
    [self updateCurrentLineRect];
    
    // highlight matching brace
    [self highlightMatchingBraceInTextView:textView];
}


// ------------------------------------------------------
/// font is changed
- (void)textViewDidChangeTypingAttributes:(nonnull NSNotification *)notification
// ------------------------------------------------------
{
    [self setupCurrentLineUpdateTimer];
}



#pragma mark Action Messages

// ------------------------------------------------------
/// show Go To sheet
- (IBAction)gotoLocation:(nullable id)sender
// ------------------------------------------------------
{
    CEGoToLineViewController *viewController = [[CEGoToLineViewController alloc] initWithTextView:[self textView]];
    
    [self presentViewControllerAsSheet:viewController];
}



#pragma mark Private Methods

// ------------------------------------------------------
/// cast view to NSScrollView
- (nullable NSScrollView *)scrollView
// ------------------------------------------------------
{
    return (NSScrollView *)[self view];
}


// ------------------------------------------------------
/// find the matching open brace and highlight it
- (void)highlightMatchingBraceInTextView:(nonnull NSTextView *)textView
// ------------------------------------------------------
{
    if (![[NSUserDefaults standardUserDefaults] boolForKey:CEDefaultHighlightBracesKey]) { return; }
    
    // The following part is based on Smultron's SMLTextView.m by Peter Borg. (2006-09-09)
    // Smultron 2 was distributed on <http://smultron.sourceforge.net> under the terms of the BSD license.
    // Copyright (c) 2004-2006 Peter Borg
    
    NSString *completeString = [textView string];
    if ([completeString length] == 0) { return; }
    
    NSInteger location = [textView selectedRange].location;
    NSInteger difference = location - [self lastCursorLocation];
    [self setLastCursorLocation:location];
    
    // The brace will be highlighted only when the cursor moves forward, just like on Xcode. (2006-09-10)
    // If the difference is more than one, they've moved the cursor with the mouse or it has been moved by resetSelectedRange below and we shouldn't check for matching braces then.
    if (difference != 1) { return; }
    
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
            if (skippedBraceCount == 0) {
                // highlight the matching brace
                [textView showFindIndicatorForRange:NSMakeRange(location, 1)];
                return;
            }
            skippedBraceCount--;
            
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
/// set update timer for current line highlight calculation
- (void)setupCurrentLineUpdateTimer
// ------------------------------------------------------
{
    if (![[NSUserDefaults standardUserDefaults] boolForKey:CEDefaultHighlightCurrentLineKey]) { return; }
    
    if ([[self currentLineUpdateTimer] isValid]) {
        [[self currentLineUpdateTimer] setFireDate:[NSDate dateWithTimeIntervalSinceNow:kCurrentLineUpdateInterval]];
    } else {
        [self setCurrentLineUpdateTimer:[NSTimer scheduledTimerWithTimeInterval:kCurrentLineUpdateInterval
                                                                         target:self
                                                                       selector:@selector(updateCurrentLineRect)
                                                                       userInfo:nil
                                                                        repeats:NO]];
    }
}


// ------------------------------------------------------
/// update current line highlight area
- (void)updateCurrentLineRect
// ------------------------------------------------------
{
    // [note] Don't invoke this method too often but with a currentLineUpdateTimer because this is a heavy task.
    
    if (![[NSUserDefaults standardUserDefaults] boolForKey:CEDefaultHighlightCurrentLineKey]) { return; }
    
    [[self currentLineUpdateTimer] invalidate];
    
    CETextView *textView = [self textView];
    
    // calcurate current line rect
    NSRange lineRange = [[textView string] lineRangeForRange:[textView selectedRange]];
    NSRange glyphRange = [[textView layoutManager] glyphRangeForCharacterRange:lineRange actualCharacterRange:NULL];
    NSRect rect = [[textView layoutManager] boundingRectForGlyphRange:glyphRange inTextContainer:[textView textContainer]];
    rect.origin.x = [[textView textContainer] lineFragmentPadding];
    rect.size.width = [[textView textContainer] containerSize].width - 2 * rect.origin.x;
    rect = NSOffsetRect(rect, [textView textContainerOrigin].x, [textView textContainerOrigin].y);
    
    // let textView draw the rect to highlight
    if (!NSEqualRects([textView highlightLineRect], rect)) {
        // clear previous highlihght
        [textView setNeedsDisplayInRect:[textView highlightLineRect] avoidAdditionalLayout:YES];
        
        // draw highlight
        [textView setHighlightLineRect:rect];
        [textView setNeedsDisplayInRect:rect avoidAdditionalLayout:YES];
    }
}

@end
