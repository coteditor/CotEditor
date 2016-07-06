/*
 
 CESyntaxStyle.m
 
 CotEditor
 http://coteditor.com
 
 Created by nakamuxu on 2004-12-22.

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

#import <NSHash/NSString+NSHash.h>

#import "CESyntaxStyle.h"

#import "CotEditor-Swift.h"

#import "CESyntaxDictionaryKeys.h"
#import "CEThemableProtocol.h"
#import "CEDefaults.h"

#import "NSTextView+CELayout.h"


// parsing constants
static NSString *_Nonnull const kAllAlphabetChars = @"abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789_";


@interface CESyntaxStyle ()

@property (nonatomic) BOOL hasSyntaxHighlighting;
@property (nonatomic, nullable, copy) NSDictionary<NSString *, id> *highlightDictionary;
@property (nonatomic, nullable, copy) NSDictionary<NSString *, NSCharacterSet *> *simpleWordsCharacterSets;
@property (nonatomic, nullable, copy) NSDictionary<NSString *, NSString *> *pairedQuoteTypes;  // dict for quote pair to extract with comment
@property (nonatomic, nullable, copy) NSArray<OutlineDefinition *> *outlineDefinitions;

@property (nonatomic, nullable, copy) NSDictionary<NSString *, NSArray *> *cachedHighlights;  // extracted results cache of the last whole string highlighs
@property (nonatomic, nullable, copy) NSString *highlightCacheHash;  // MD5 hash
@property (nonatomic, nullable, weak) NSTimer *outlineMenuTimer;

@property (nonatomic, nonnull) NSOperationQueue *outlineParseOperationQueue;
@property (nonatomic, nonnull) NSOperationQueue *syntaxHighlightParseOperationQueue;


// readonly
@property (readwrite, nonatomic, nonnull, copy) NSString *styleName;
@property (readwrite, nonatomic, getter=isNone) BOOL none;
@property (readwrite, nonatomic, nullable, copy) NSString *inlineCommentDelimiter;
@property (readwrite, nonatomic, nullable, copy) NSDictionary<NSString *, NSString *> *blockCommentDelimiters;
@property (readwrite, nonatomic, nullable, copy) NSArray<NSString *> *completionWords;
@property (readwrite, nonatomic, nullable, copy) NSCharacterSet *firstCompletionCharacterSet;

@property (readwrite, nonatomic, nullable, copy) NSArray<OutlineItem *> *outlineItems;

@end




#pragma mark -

@implementation CESyntaxStyle

static NSArray<NSString *> *kSyntaxDictKeys;


#pragma mark Superclass Methods

// ------------------------------------------------------
/// initialize class
+ (void)initialize
// ------------------------------------------------------
{
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        NSMutableArray<NSString *> *syntaxDictKeys = [NSMutableArray arrayWithCapacity:kSizeOfAllSyntaxKeys];
        for (NSUInteger i = 0; i < kSizeOfAllSyntaxKeys; i++) {
            [syntaxDictKeys addObject:kAllSyntaxKeys[i]];
        }
        kSyntaxDictKeys = [syntaxDictKeys copy];
    });
}


//------------------------------------------------------
/// override designated initializer
- (nonnull instancetype)init
//------------------------------------------------------
{
    return [self initWithDictionary:nil name:NSLocalizedString(@"None", nil)];
}


//------------------------------------------------------
/// clean up
- (void)dealloc
//------------------------------------------------------
{
    [_outlineParseOperationQueue cancelAllOperations];
    [_syntaxHighlightParseOperationQueue cancelAllOperations];
    
    [_outlineMenuTimer invalidate];
}



#pragma mark Public Methods

// ------------------------------------------------------
/// designated initializer
- (nonnull instancetype)initWithDictionary:(nullable NSDictionary<NSString *, id> *)dictionary name:(nonnull NSString *)styleName
// ------------------------------------------------------
{
    self = [super init];
    if (self) {
        _styleName = styleName;
        
        _outlineParseOperationQueue = [[NSOperationQueue alloc] init];
        [_outlineParseOperationQueue setName:@"com.coteditor.CotEditor.outlineParseOperationQueue"];
        _syntaxHighlightParseOperationQueue = [[NSOperationQueue alloc] init];
        [_syntaxHighlightParseOperationQueue setName:@"com.coteditor.CotEditor.syntaxHighlightParseOperationQueue"];
        
        if (!dictionary) {
            _none = YES;
            
        } else {
            NSMutableDictionary<NSString *, id> *mutableDictionary = [dictionary mutableCopy];
            
            // set comment delimiters
            NSDictionary<NSString *, NSString *> *delimiters = mutableDictionary[CESyntaxCommentDelimitersKey];
            if ([delimiters[CESyntaxInlineCommentKey] length] > 0) {
                _inlineCommentDelimiter = delimiters[CESyntaxInlineCommentKey];
            }
            if ([delimiters[CESyntaxBeginCommentKey] length] > 0 && [delimiters[CESyntaxEndCommentKey] length] > 0) {
                _blockCommentDelimiters = @{CEBeginDelimiterKey: delimiters[CESyntaxBeginCommentKey],
                                            CEEndDelimiterKey: delimiters[CESyntaxEndCommentKey]};
            }
            
            // create word-completion data set
            {
                NSMutableArray<NSString *> *completionWords = [NSMutableArray array];
                NSMutableString *firstCharsString = [NSMutableString string];
                NSArray<NSString *> *completionDicts = mutableDictionary[CESyntaxCompletionsKey];
                
                if ([completionDicts count] > 0) {
                    for (NSDictionary<NSString *, id> *dict in completionDicts) {
                        NSString *word = dict[CESyntaxKeyStringKey];
                        [completionWords addObject:word];
                        [firstCharsString appendString:[word substringToIndex:1]];
                    }
                } else {
                    NSCharacterSet *trimCharSet = [NSCharacterSet whitespaceAndNewlineCharacterSet];
                    for (NSString *key in kSyntaxDictKeys) {
                        @autoreleasepool {
                            for (NSDictionary<NSString *, id> *wordDict in mutableDictionary[key]) {
                                NSString *begin = [wordDict[CESyntaxBeginStringKey] stringByTrimmingCharactersInSet:trimCharSet];
                                NSString *end = [wordDict[CESyntaxEndStringKey] stringByTrimmingCharactersInSet:trimCharSet];
                                BOOL isRegEx = [wordDict[CESyntaxRegularExpressionKey] boolValue];
                                
                                if (([begin length] > 0) && ([end length] == 0) && !isRegEx) {
                                    [completionWords addObject:begin];
                                    [firstCharsString appendString:[begin substringToIndex:1]];
                                }
                            }
                        } // ==== end-autoreleasepool
                    }
                    // sort
                    [completionWords sortUsingSelector:@selector(compare:)];
                }
                
                // keep results
                _completionWords = completionWords;
                if ([firstCharsString length] > 0) {
                    _firstCompletionCharacterSet = [NSCharacterSet characterSetWithCharactersInString:firstCharsString];
                }
            }
            
            // create characerSet dict for simple word highlights
            {
                NSMutableDictionary<NSString *, NSCharacterSet *> *characterSets = [NSMutableDictionary dictionary];
                NSCharacterSet *trimCharSet = [NSCharacterSet whitespaceAndNewlineCharacterSet];
                
                for (NSString *key in kSyntaxDictKeys) {
                    @autoreleasepool {
                        NSMutableCharacterSet *charSet = [NSMutableCharacterSet characterSetWithCharactersInString:kAllAlphabetChars];
                        
                        for (NSDictionary<NSString *, id> *wordDict in mutableDictionary[key]) {
                            NSString *begin = [wordDict[CESyntaxBeginStringKey] stringByTrimmingCharactersInSet:trimCharSet];
                            NSString *end = [wordDict[CESyntaxEndStringKey] stringByTrimmingCharactersInSet:trimCharSet];
                            BOOL isRegex = [wordDict[CESyntaxRegularExpressionKey] boolValue];
                            
                            if ([begin length] > 0 && [end length] == 0 && !isRegex) {
                                if ([wordDict[CESyntaxIgnoreCaseKey] boolValue]) {
                                    [charSet addCharactersInString:[begin uppercaseString]];
                                    [charSet addCharactersInString:[begin lowercaseString]];
                                } else {
                                    [charSet addCharactersInString:begin];
                                }
                            }
                        }
                        [charSet removeCharactersInString:@"\n\t "];   // ignore line breaks, tabs and spaces
                        
                        characterSets[key] = [charSet copy];
                    }
                }
                _simpleWordsCharacterSets = [characterSets copy];
            }
            
            // pick quote definitions up to parse quoted text separately with comments in `extractCommentsWithQuotes`
            // also check if highlighting definition exists
            {
                NSUInteger count = 0;
                NSMutableDictionary<NSString *, NSString *> *quoteTypes = [NSMutableDictionary dictionary];
                
                for (NSString *key in kSyntaxDictKeys) {
                    NSMutableArray<NSDictionary<NSString *, id> *> *wordDicts = [mutableDictionary[key] mutableCopy];
                    count += [wordDicts count];
                    
                    for (NSDictionary<NSString *, id> *wordDict in mutableDictionary[key]) {
                        NSString *begin = wordDict[CESyntaxBeginStringKey];
                        NSString *end = wordDict[CESyntaxEndStringKey];
                        
                        // check just firstly appeared quotes
                        for (NSString *quote in @[@"\"\"\"", @"'''", @"'", @"\"", @"`"]) {
                            if (([begin isEqualToString:quote] && [end isEqualToString:quote]) &&
                                !quoteTypes[quote])
                            {
                                // remove from the normal highlight definition list
                                [wordDicts removeObject:wordDict];
                                quoteTypes[quote] = key;
                            }
                        }
                    }
                    if (wordDicts) {
                        mutableDictionary[key] = wordDicts;
                    }
                }
                _pairedQuoteTypes = quoteTypes;
                
                // cache if syntax highlight exists
                _hasSyntaxHighlighting = ((count > 0) || _inlineCommentDelimiter || _blockCommentDelimiters);
            }
            
            // store as properties
            _highlightDictionary = [mutableDictionary copy];
            
            // parse outline definitions
            NSMutableArray<OutlineDefinition *> *outlineDefinitions = [NSMutableArray arrayWithCapacity:[mutableDictionary[CESyntaxOutlineMenuKey] count]];
            for (NSDictionary *definition in mutableDictionary[CESyntaxOutlineMenuKey]) {
                OutlineDefinition *item = [[OutlineDefinition alloc] initWithDefinition:definition];
                if (item) {
                    [outlineDefinitions addObject:item];
                }
            }
            _outlineDefinitions = [outlineDefinitions copy];
            
            
        }
    }
    return self;
}


// ------------------------------------------------------
/// check equality
- (BOOL)isEqualToSyntaxStyle:(CESyntaxStyle *)syntaxStyle
// ------------------------------------------------------
{
    if ([[syntaxStyle styleName] isEqualToString:[self styleName]] &&
        [[syntaxStyle highlightDictionary] isEqualToDictionary:[self highlightDictionary]] &&
        ((![syntaxStyle inlineCommentDelimiter] && ![self inlineCommentDelimiter]) ||
         [[syntaxStyle inlineCommentDelimiter] isEqualToString:[self inlineCommentDelimiter]]) &&
        ((![syntaxStyle blockCommentDelimiters] && ![self blockCommentDelimiters]) ||
         [[syntaxStyle blockCommentDelimiters] isEqualToDictionary:[self blockCommentDelimiters]]))
    {
        return YES;
    }
    
    return NO;
}


// ------------------------------------------------------
/// cancel all syntax parse
- (void)cancelAllParses
// ------------------------------------------------------
{
    [[self outlineParseOperationQueue] cancelAllOperations];
    [[self syntaxHighlightParseOperationQueue] cancelAllOperations];
}


// ------------------------------------------------------
/// whether enable parsing syntax
- (BOOL)canParse
// ------------------------------------------------------
{
    BOOL isHighlightEnabled = [[NSUserDefaults standardUserDefaults] boolForKey:CEDefaultEnableSyntaxHighlightKey];
    
    return isHighlightEnabled && ![self isNone];
}



#pragma mark Private Accessors

// ------------------------------------------------------
/// inform delegate about outline items update
- (void)setOutlineItems:(NSArray<OutlineItem *> *)outlineItems
// ------------------------------------------------------
{
    _outlineItems = [outlineItems copy];
    
    __weak typeof(self) weakSelf = self;
    dispatch_async(dispatch_get_main_queue(), ^{
        typeof(self) self = weakSelf;
        
        if ([[self delegate] respondsToSelector:@selector(syntaxStyle:didParseOutline:)]) {
            [[self delegate] syntaxStyle:self didParseOutline:outlineItems];
        }
    });
}

@end




#pragma mark -

@implementation CESyntaxStyle (Outline)

#pragma mark Public Methods

// ------------------------------------------------------
/// parse outline with delay
- (void)invalidateOutline
// ------------------------------------------------------
{
    if (![self canParse]) {
        if (![self outlineItems]) {
            [self setOutlineItems:@[]];
        }
        return;
    }
    
    [self setupOutlineMenuUpdateTimer];
}



#pragma mark Private Methods

// ------------------------------------------------------
/// parse outline
- (void)parseOutline
// ------------------------------------------------------
{
    [[self outlineMenuTimer] invalidate];
    
    if ([[self textStorage] length] == 0) {
        [self setOutlineItems:@[]];
        return;
    }
    
    // make sure the string is immutable
    //   -> NSTextStorage's `string` property retruns a mutable string.
    NSString *string = [NSString stringWithString:[[self textStorage] string]];
    NSRange range = NSMakeRange(0, [string length]);
    
    OutlineParseOperation *operation = [[OutlineParseOperation alloc] initWithDefinitions:[self outlineDefinitions]];
    [operation setString:string];
    [operation setParseRange:range];
    
    __weak typeof(operation) weakOperation = operation;
    __weak typeof(self) weakSelf = self;
    [operation setCompletionBlock:^{
        if ([weakOperation isCancelled]) { return; }
        
        [weakSelf setOutlineItems:[weakOperation results]];
    }];
    
    [[self outlineParseOperationQueue] addOperation:operation];
}


// ------------------------------------------------------
/// let parse outline after a delay
- (void)setupOutlineMenuUpdateTimer
// ------------------------------------------------------
{
    NSTimeInterval interval = [[NSUserDefaults standardUserDefaults] doubleForKey:CEDefaultOutlineMenuIntervalKey];
    
    if ([[self outlineMenuTimer] isValid]) {
        [[self outlineMenuTimer] setFireDate:[NSDate dateWithTimeIntervalSinceNow:interval]];
    } else {
        [self setOutlineMenuTimer:[NSTimer scheduledTimerWithTimeInterval:interval
                                                                   target:self
                                                                 selector:@selector(parseOutline)
                                                                 userInfo:nil
                                                                  repeats:NO]];
    }
}

@end




#pragma mark -

@implementation CESyntaxStyle (Highlighting)

#pragma mark Public Methods

// ------------------------------------------------------
/// update whole document highlights
- (void)highlightWholeStringWithCompletionHandler:(nullable void (^)())completionHandler
// ------------------------------------------------------
{
    if (![[NSUserDefaults standardUserDefaults] boolForKey:CEDefaultEnableSyntaxHighlightKey]) { return; }
    if ([[self textStorage] length] == 0) { return; }
    
    NSTextStorage *textStorage = [self textStorage];
    NSRange wholeRange = NSMakeRange(0, [textStorage length]);
    
    // use cache if the content of the whole document is the same as the last
    if ([self highlightCacheHash] && [[self highlightCacheHash] isEqualToString:[[textStorage string] MD5]]) {
        [self applyHighlights:[self cachedHighlights] range:wholeRange];
        if (completionHandler) {
            completionHandler();
        }
        return;
    }
    
    // make sure that string is immutable
    // [Caution] DO NOT use [string copy] here instead of `stringWithString:`.
    //           It still returns a mutable object, NSBigMutableString,
    //           and it can cause crash when the mutable string is given to NSRegularExpression instance.
    //           (2015-08, with OS X 10.10 SDK)
    NSString *string = [NSString stringWithString:[textStorage string]];
    
    [self highlightString:string range:wholeRange completionHandler:completionHandler];
}


// ------------------------------------------------------
/// update highlights around passed-in range
- (void)highlightAroundEditedRange:(NSRange)editedRange
// ------------------------------------------------------
{
    if (![[NSUserDefaults standardUserDefaults] boolForKey:CEDefaultEnableSyntaxHighlightKey]) { return; }
    if ([[self textStorage] length] == 0) { return; }
    
    NSTextStorage *textStorage = [self textStorage];
    
    // make sure that string is immutable (see `highlightWholeStringInTextStorage:completionHandler:` for details)
    NSString *string = [NSString stringWithString:[textStorage string]];
    
    NSUInteger bufferLength = [[NSUserDefaults standardUserDefaults] integerForKey:CEDefaultColoringRangeBufferLengthKey];
    NSRange wholeRange = NSMakeRange(0, [string length]);
    NSRange highlightRange = editedRange;
    
    // highlight whole if string is enough short
    if (wholeRange.length <= bufferLength) {
        highlightRange = wholeRange;
        
    } else {
        // highlight whole visible area if edited point is visible
        for (NSLayoutManager *layoutManager in [textStorage layoutManagers]) {
            NSRange visibleRange = [[layoutManager firstTextView] visibleRange];
            
            if (NSIntersectionRange(editedRange, visibleRange).length > 0) {
                highlightRange = NSUnionRange(highlightRange, visibleRange);
            }
        }
        highlightRange = [string lineRangeForRange:highlightRange];
        
        NSUInteger start = highlightRange.location;
        NSUInteger end = NSMaxRange(highlightRange) - 1;
        
        // expand highlight area if the character just before/after the highlighting area is the same color
        NSLayoutManager *layoutManager = [[textStorage layoutManagers] firstObject];
        NSRange effectiveRange;
        
        // highlight from the beginning of the document if it's not so large
        if (start <= bufferLength) {
            start = 0;
        } else {
            if ([layoutManager temporaryAttribute:NSForegroundColorAttributeName
                                 atCharacterIndex:start
                            longestEffectiveRange:&effectiveRange
                                          inRange:wholeRange])
            {
                start = effectiveRange.location;
            }
        }
        
        if ([layoutManager temporaryAttribute:NSForegroundColorAttributeName
                             atCharacterIndex:end
                        longestEffectiveRange:&effectiveRange
                                      inRange:wholeRange])
        {
            end = NSMaxRange(effectiveRange) - 1;
        }
        
        highlightRange = NSMakeRange(start, end - start);
    }
    
    [self highlightString:string range:highlightRange completionHandler:nil];
}



#pragma mark Private Methods

// ------------------------------------------------------
/// perform highlighting
- (void)highlightString:(nonnull NSString *)wholeString range:(NSRange)highlightRange completionHandler:(nullable void (^)())completionHandler
// ------------------------------------------------------
{
    if (highlightRange.length == 0) { return; }
    
    // just clear current highlight and return if no coloring needs
    if (![self hasSyntaxHighlighting]) {
        [self applyHighlights:@{} range:highlightRange];
        if (completionHandler) {
            completionHandler();
        }
        return;
    }
    
    SyntaxHighlightParseOperation *operation = [[SyntaxHighlightParseOperation alloc] initWithDictionary:[self highlightDictionary]
                                                                                simpleWordsCharacterSets:[self simpleWordsCharacterSets]
                                                                                        pairedQuoteTypes:[self pairedQuoteTypes]
                                                                                  inlineCommentDelimiter:[self inlineCommentDelimiter]
                                                                                  blockCommentDelimiters:[self blockCommentDelimiters]];
    [operation setString:wholeString];
    [operation setParseRange:highlightRange];
    
    // show highlighting indicator for large string
    __block ProgressViewController *indicator = nil;
    if ([self shouldShowIndicatorForHighlightLength:highlightRange.length]) {
        NSTextStorage *textStorage = [self textStorage];
        
        // wait for window becomes visible and sheet-attachable
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_LOW, 0), ^{
            while (![[[[[textStorage layoutManagers] firstObject] firstTextView] window] isVisible]) {
                [[NSRunLoop currentRunLoop] limitDateForMode:NSDefaultRunLoopMode];
            }
            
            // attach the indicator as a sheet
            dispatch_sync(dispatch_get_main_queue(), ^{
                // do nothing if highlighting is already finished
                if ([operation isFinished]) { return; }
                
                NSWindow *documentWindow = [[[[textStorage layoutManagers] firstObject] firstTextView] window];
                indicator = [[ProgressViewController alloc] initWithProgress:[operation progress] message:NSLocalizedString(@"Coloring text…", nil)];
                [[[documentWindow windowController] contentViewController] presentViewControllerAsSheet:indicator];
            });
        });
    }
    
    __weak typeof(self) weakSelf = self;
    __weak typeof(operation) weakOperation = operation;
    [operation setCompletionBlock:^{
        NSDictionary<NSString *, NSArray<NSValue *> *> *highlights = [weakOperation results];
        dispatch_async(dispatch_get_main_queue(), ^{
            typeof(self) self = weakSelf;
            
            if (![weakOperation isCancelled]) {
                // cache result if whole text was parsed
                if (highlightRange.length == [wholeString length]) {
                    [self setCachedHighlights:highlights];
                    [self setHighlightCacheHash:[wholeString MD5]];
                }
                
                // apply color (or give up if the editor's string is changed from the analized string)
                if ([[[self textStorage] string] length] == [wholeString length]) {
                    // update indicator message
                    [[weakOperation progress] setLocalizedDescription:NSLocalizedString(@"Applying colors to text", nil)];
                    [self applyHighlights:highlights range:highlightRange];
                }
            }
            
            // clean up indicator sheet
            if (indicator) {
                [indicator dismissController:self];
            }
            
            // do the rest things
            if (completionHandler) {
                completionHandler();
            }
        });
    }];
    
    [[self syntaxHighlightParseOperationQueue] addOperation:operation];
}


// ------------------------------------------------------
/// whether need to display highlighting indicator
- (BOOL)shouldShowIndicatorForHighlightLength:(NSUInteger)length
// ------------------------------------------------------
{
    NSUInteger indicatorThreshold = [[NSUserDefaults standardUserDefaults] integerForKey:CEDefaultShowColoringIndicatorTextLengthKey];
    
    // do not show indicator CEDefaultShowColoringIndicatorTextLengthKey is 0
    return (indicatorThreshold > 0) && (length > indicatorThreshold);
}


// ------------------------------------------------------
/// apply highlights to the document
- (void)applyHighlights:(NSDictionary<NSString *, NSArray<NSValue *> *> *)highlights range:(NSRange)highlightRange
// ------------------------------------------------------
{
    for (NSLayoutManager *layoutManager in [[self textStorage] layoutManagers]) {
        // remove current highlights
        [layoutManager removeTemporaryAttribute:NSForegroundColorAttributeName
                              forCharacterRange:highlightRange];
        
        // apply color to layoutManager
        CETheme *theme = [(NSTextView<CEThemable> *)[layoutManager firstTextView] theme];
        for (NSString *syntaxType in kSyntaxDictKeys) {
            NSArray<NSValue *> *ranges = highlights[syntaxType];
            NSColor *color = [theme syntaxColorForType:syntaxType] ?: [theme textColor];
            
            for (NSValue *rangeValue in ranges) {
                [layoutManager addTemporaryAttribute:NSForegroundColorAttributeName
                                               value:color forCharacterRange:[rangeValue rangeValue]];
            }
        }
    }
}

@end
