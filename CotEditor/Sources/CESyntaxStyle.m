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
#import "CESyntaxOutlineParser.h"
#import "CESyntaxHighlightParser.h"
#import "CETextViewProtocol.h"
#import "CESyntaxManager.h"
#import "CEIndicatorSheetController.h"
#import "CEDefaults.h"
#import "Constants.h"


// parsing constants
static NSString *_Nonnull const kAllAlphabetChars = @"abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789_";


@interface CESyntaxStyle ()

@property (nonatomic) BOOL hasSyntaxHighlighting;
@property (nonatomic, nullable, copy) NSDictionary<NSString *, id> *highlightDictionary;
@property (nonatomic, nullable, copy) NSDictionary<NSString *, NSCharacterSet *> *simpleWordsCharacterSets;
@property (nonatomic, nullable, copy) NSDictionary<NSString *, NSString *> *pairedQuoteTypes;  // dict for quote pair to extract with comment

@property (nonatomic, nullable, copy) NSDictionary *cachedHighlights;  // extracted results cache of the last whole string highlighs
@property (nonatomic, nullable, copy) NSString *cachedHash;  // MD5 hash


// readonly
@property (readwrite, nonatomic, nonnull, copy) NSString *styleName;
@property (readwrite, nonatomic, nullable, copy) NSArray<NSString *> *completionWords;
@property (readwrite, nonatomic, nullable, copy) NSCharacterSet *firstCompletionCharacterSet;
@property (readwrite, nonatomic, nullable, copy) NSString *inlineCommentDelimiter;
@property (readwrite, nonatomic, nullable, copy) NSDictionary<NSString *, NSString *> *blockCommentDelimiters;
@property (readwrite, nonatomic, getter=isNone) BOOL none;

@property (readwrite, nonatomic, nullable) NSArray<NSDictionary *> *outlineDefinitions;

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
- (nullable instancetype)init
//------------------------------------------------------
{
    return [self initWithStyleName:nil];
}



#pragma mark Public Methods

// ------------------------------------------------------
/// designated initializer
- (nullable instancetype)initWithStyleName:(nullable NSString *)styleName
// ------------------------------------------------------
{
    self = [super init];
    if (self) {
        if (!styleName || [styleName isEqualToString:NSLocalizedString(@"None", nil)]) {
            _none = YES;
            _styleName = NSLocalizedString(@"None", nil);
            
        } else if ([[[CESyntaxManager sharedManager] styleNames] containsObject:styleName]) {
            NSMutableDictionary<NSString *, id> *highlightDictionary = [[[CESyntaxManager sharedManager] styleWithStyleName:styleName] mutableCopy];
            
            // コメントデリミッタを設定
            NSDictionary<NSString *, NSString *> *delimiters = highlightDictionary[CESyntaxCommentDelimitersKey];
            if ([delimiters[CESyntaxInlineCommentKey] length] > 0) {
                _inlineCommentDelimiter = delimiters[CESyntaxInlineCommentKey];
            }
            if ([delimiters[CESyntaxBeginCommentKey] length] > 0 && [delimiters[CESyntaxEndCommentKey] length] > 0) {
                _blockCommentDelimiters = @{CEBeginDelimiterKey: delimiters[CESyntaxBeginCommentKey],
                                            CEEndDelimiterKey: delimiters[CESyntaxEndCommentKey]};
            }
            
            // カラーリング辞書から補完文字列配列を生成
            {
                NSMutableArray<NSString *> *completionWords = [NSMutableArray array];
                NSMutableString *firstCharsString = [NSMutableString string];
                NSArray<NSString *> *completionDicts = highlightDictionary[CESyntaxCompletionsKey];
                
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
                            for (NSDictionary<NSString *, id> *wordDict in highlightDictionary[key]) {
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
                    // ソート
                    [completionWords sortUsingSelector:@selector(compare:)];
                }
                // completionWords を保持する
                _completionWords = completionWords;
                
                // firstCompletionCharacterSet を保持する
                if ([firstCharsString length] > 0) {
                    _firstCompletionCharacterSet = [NSCharacterSet characterSetWithCharactersInString:firstCharsString];
                }
            }
            
            // カラーリング辞書から単純文字列検索のときに使う characterSet の辞書を生成
            {
                NSMutableDictionary<NSString *, NSCharacterSet *> *characterSets = [NSMutableDictionary dictionary];
                NSCharacterSet *trimCharSet = [NSCharacterSet whitespaceAndNewlineCharacterSet];
                
                for (NSString *key in kSyntaxDictKeys) {
                    @autoreleasepool {
                        NSMutableCharacterSet *charSet = [NSMutableCharacterSet characterSetWithCharactersInString:kAllAlphabetChars];
                        
                        for (NSDictionary<NSString *, id> *wordDict in highlightDictionary[key]) {
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
                        [charSet removeCharactersInString:@"\n\t "];  // 改行、タブ、スペースは無視
                        
                        characterSets[key] = [charSet copy];
                    }
                }
                _simpleWordsCharacterSets = [characterSets copy];
            }
            
            // 引用符のカラーリングはコメントと一緒に別途 extractCommentsWithQuotesFromString: で行なうので選り分けておく
            // そもそもカラーリング用の定義があるのかもここでチェック
            {
                NSUInteger count = 0;
                NSMutableDictionary<NSString *, NSString *> *quoteTypes = [NSMutableDictionary dictionary];
                
                for (NSString *key in kSyntaxDictKeys) {
                    NSMutableArray<NSDictionary<NSString *, id> *> *wordDicts = [highlightDictionary[key] mutableCopy];
                    count += [wordDicts count];
                    
                    for (NSDictionary<NSString *, id> *wordDict in highlightDictionary[key]) {
                        NSString *begin = wordDict[CESyntaxBeginStringKey];
                        NSString *end = wordDict[CESyntaxEndStringKey];
                        
                        // 最初に出てきたクォートのみを把握
                        for (NSString *quote in @[@"'", @"\"", @"`"]) {
                            if (([begin isEqualToString:quote] && [end isEqualToString:quote]) &&
                                !quoteTypes[quote])
                            {
                                quoteTypes[quote] = key;
                                [wordDicts removeObject:wordDict];  // 引用符としてカラーリングするのでリストからははずす
                            }
                        }
                    }
                    if (wordDicts) {
                        highlightDictionary[key] = wordDicts;
                    }
                }
                _pairedQuoteTypes = quoteTypes;
                
                // シンタックスカラーリングが必要かをキャッシュ
                _hasSyntaxHighlighting = ((count > 0) || _inlineCommentDelimiter || _blockCommentDelimiters);
            }
            
            // store as properties
            _styleName = styleName;
            _highlightDictionary = [highlightDictionary copy];
            
            _outlineDefinitions = highlightDictionary[CESyntaxOutlineMenuKey];
            
        } else {
            return nil;
        }
    }
    return self;
}


// ------------------------------------------------------
/// check equality
- (BOOL)isEqualToSyntaxStyle:(CESyntaxStyle *)syntaxStyle
// ------------------------------------------------------
{
    if (![[syntaxStyle styleName] isEqualToString:[self styleName]]) { return NO; }
    if (![[syntaxStyle highlightDictionary] isEqualToDictionary:[self highlightDictionary]]) { return NO; }
    
    return YES;
}

@end




#pragma mark -

@implementation CESyntaxStyle (Highlighting)

#pragma mark Public Methods

// ------------------------------------------------------
/// 全体をカラーリング
- (void)highlightWholeStringInTextStorage:(nonnull NSTextStorage *)textStorage completionHandler:(nullable void (^)())completionHandler
// ------------------------------------------------------
{
    if ([textStorage length] == 0) { return; }
    
    NSRange wholeRange = NSMakeRange(0, [textStorage length]);
    
    // 前回の全文カラーリングと内容が全く同じ場合はキャッシュを使う
    if ([[[textStorage string] MD5] isEqualToString:[self cachedHash]]) {
        for (NSLayoutManager *layoutManager in [textStorage layoutManagers]) {
            [self applyHighlights:[self cachedHighlights] range:wholeRange layoutManager:layoutManager];
        }
        if (completionHandler) {
            completionHandler();
        }
        
    } else {
        // make sure that string is immutable
        // [Caution] DO NOT use [wholeString copy] here instead of `stringWithString:`.
        //           It still returns a mutable object, NSBigMutableString,
        //           and it can cause crash when the mutable string is given to NSRegularExpression instance.
        //           (2015-08, with OS X 10.10 SDK)
        NSString *safeImmutableString = [NSString stringWithString:[textStorage string]];
        
        [self highlightString:safeImmutableString
                        range:wholeRange textStorage:textStorage completionHandler:completionHandler];
    }
}


// ------------------------------------------------------
/// 表示されている部分をカラーリング
- (void)highlightRange:(NSRange)range textStorage:(nonnull NSTextStorage *)textStorage
// ------------------------------------------------------
{
    if ([textStorage length] == 0) { return; }
    
    // make sure that string is immutable (see `highlightWholeStringInTextStorage:completionHandler:` for details)
    NSString *string = [NSString stringWithString:[textStorage string]];
    
    NSUInteger bufferLength = [[NSUserDefaults standardUserDefaults] integerForKey:CEDefaultColoringRangeBufferLengthKey];
    NSRange wholeRange = NSMakeRange(0, [string length]);
    NSRange highlightRange;
    
    // 文字列が十分小さい時は全文カラーリングをする
    if (wholeRange.length <= bufferLength) {
        highlightRange = wholeRange;
        
    } else {
        NSUInteger start = range.location;
        NSUInteger end = NSMaxRange(range) - 1;
        
        // 直前／直後が同色ならカラーリング範囲を拡大する
        NSLayoutManager *layoutManager = [[textStorage layoutManagers] firstObject];
        NSRange effectiveRange;
        
        // 表示領域の前があまり多くないときはファイル頭からカラーリングする
        if (start <= bufferLength) {
            start = 0;
        } else {
            [layoutManager temporaryAttribute:NSForegroundColorAttributeName
                             atCharacterIndex:start
                        longestEffectiveRange:&effectiveRange
                                      inRange:wholeRange];
            start = effectiveRange.location;
        }
        
        [layoutManager temporaryAttribute:NSForegroundColorAttributeName
                         atCharacterIndex:end
                    longestEffectiveRange:&effectiveRange
                                  inRange:wholeRange];
        end = NSMaxRange(effectiveRange);
        
        highlightRange = NSMakeRange(start, end - start);
        highlightRange = [string lineRangeForRange:highlightRange];
    }
    
    [self highlightString:string range:highlightRange
              textStorage:textStorage completionHandler:nil];
}



#pragma mark Private Methods

// ------------------------------------------------------
/// カラーリングを実行
- (void)highlightString:(nonnull NSString *)wholeString range:(NSRange)highlightRange textStorage:(nonnull NSTextStorage *)textStorage completionHandler:(nullable void (^)())completionHandler
// ------------------------------------------------------
{
    if (highlightRange.length == 0) { return; }
    
    // カラーリング不要なら現在のカラーリングをクリアして戻る
    if (![self hasSyntaxHighlighting]) {
        for (NSLayoutManager *layoutManager in [textStorage layoutManagers]) {
            [self applyHighlights:@{} range:highlightRange layoutManager:layoutManager];
        }
        if (completionHandler) {
            completionHandler();
        }
        return;
    }
    
    __block BOOL isCompleted = NO;
    
    __block CESyntaxHighlightParser *parser = [[CESyntaxHighlightParser alloc] initWithString:wholeString
                                                                                   dictionary:[self highlightDictionary]
                                                                     simpleWordsCharacterSets:[self simpleWordsCharacterSets]
                                                                             pairedQuoteTypes:[self pairedQuoteTypes]
                                                                       inlineCommentDelimiter:[self inlineCommentDelimiter]
                                                                       blockCommentDelimiters:[self blockCommentDelimiters]];
    
    // show highlighting indicator for large string
    CEIndicatorSheetController *indicator = nil;
    if ([self shouldShowIndicatorForHighlightLength:highlightRange.length]) {
        NSWindow *documentWindow = [[[[textStorage layoutManagers] firstObject] firstTextView] window];
        indicator = [[CEIndicatorSheetController alloc] initWithMessage:NSLocalizedString(@"Coloring text…", nil)];
        // set handlers
        [parser setDidProgress:^(CGFloat delta) {
            [indicator progressIndicator:delta];
        }];
        [parser setBeginParsingBlock:^(NSString * _Nonnull blockName) {
            if (indicator) {
                [indicator setInformativeText:[NSString stringWithFormat:NSLocalizedString(@"Extracting %@…", nil), blockName]];
            }
        }];
        
        // wait for window becomes visible
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_LOW, 0), ^{
            while (![documentWindow isVisible]) {
                [[NSRunLoop currentRunLoop] limitDateForMode:NSDefaultRunLoopMode];
            }
            
            // progress the main thread run-loop in order to give a chance to show more important sheet
            dispatch_sync(dispatch_get_main_queue(), ^{});
            
            // wait until attached window closes
            while ([documentWindow attachedSheet]) {
                [[NSRunLoop currentRunLoop] limitDateForMode:NSDefaultRunLoopMode];
            }
            
            // otherwise, attach the indicator as a sheet
            dispatch_async(dispatch_get_main_queue(), ^{
                // do nothing if highlighting is already finished
                if (isCompleted) { return; }
                
                [indicator beginSheetForWindow:documentWindow completionHandler:^(NSModalResponse returnCode) {
                    if (returnCode == NSCancelButton) {
                        [parser setCancelled:YES];
                    }
                }];
            });
        });
    }
    
    __weak typeof(self) weakSelf = self;
    [parser parseRange:highlightRange completionHandler:^(NSDictionary<NSString *,NSArray<NSValue *> *> * _Nonnull highlights)
     {
         typeof(self) self = weakSelf;  // strong self
         if (!self) {
             isCompleted = YES;
             return;
         }
         
         if ([highlights count] > 0) {
             // cache result if whole text was parsed
             if (highlightRange.length == [wholeString length]) {
                 [self setCachedHighlights:highlights];
                 [self setCachedHash:[wholeString MD5]];
             }
             
             // update indicator message
             if (indicator) {
                 [indicator setInformativeText:NSLocalizedString(@"Applying colors to text", nil)];
             }
             
             // apply color (or give up if the editor's string is changed from the analized string)
             if ([[textStorage string] isEqualToString:wholeString]) {
                 for (NSLayoutManager *layoutManager in [textStorage layoutManagers]) {
                     [self applyHighlights:highlights range:highlightRange layoutManager:layoutManager];
                 }
             }
         }
         
         isCompleted = YES;
         
         // clean up indicator sheet
         if (indicator) {
             [indicator close:self];
         }
         
         // do the rest things
         if (completionHandler) {
             completionHandler();
         }
         
         parser = nil;  // keep parser until end
     }];
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
/// 抽出したカラー範囲配列を書類に適用する
- (void)applyHighlights:(NSDictionary<NSString *, NSArray<NSValue *> *> *)highlights range:(NSRange)highlightRange layoutManager:(nonnull NSLayoutManager *)layoutManager
// ------------------------------------------------------
{
    // 現在あるカラーリングを削除
    [layoutManager removeTemporaryAttribute:NSForegroundColorAttributeName
                          forCharacterRange:highlightRange];
    
    // カラーリング実行
    CETheme *theme = [(NSTextView<CETextViewProtocol> *)[layoutManager firstTextView] theme];
    for (NSString *syntaxType in kSyntaxDictKeys) {
        NSArray<NSValue *> *ranges = highlights[syntaxType];
        
        if ([ranges count] == 0) { continue; }
        
        // get color from theme
        NSColor *color;
        if ([syntaxType isEqualToString:CESyntaxKeywordsKey]) {
            color = [theme keywordsColor];
        } else if ([syntaxType isEqualToString:CESyntaxCommandsKey]) {
            color = [theme commandsColor];
        } else if ([syntaxType isEqualToString:CESyntaxTypesKey]) {
            color = [theme typesColor];
        } else if ([syntaxType isEqualToString:CESyntaxAttributesKey]) {
            color = [theme attributesColor];
        } else if ([syntaxType isEqualToString:CESyntaxVariablesKey]) {
            color = [theme variablesColor];
        } else if ([syntaxType isEqualToString:CESyntaxValuesKey]) {
            color = [theme valuesColor];
        } else if ([syntaxType isEqualToString:CESyntaxNumbersKey]) {
            color = [theme numbersColor];
        } else if ([syntaxType isEqualToString:CESyntaxStringsKey]) {
            color = [theme stringsColor];
        } else if ([syntaxType isEqualToString:CESyntaxCharactersKey]) {
            color = [theme charactersColor];
        } else if ([syntaxType isEqualToString:CESyntaxCommentsKey]) {
            color = [theme commentsColor];
        } else {
            color = [theme textColor];
        }
        
        for (NSValue *rangeValue in ranges) {
            [layoutManager addTemporaryAttribute:NSForegroundColorAttributeName
                                           value:color forCharacterRange:[rangeValue rangeValue]];
        }
    }
}

@end
