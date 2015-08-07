/*
 
 CESyntaxParser.m
 
 CotEditor
 http://coteditor.com
 
 Created by nakamuxu on 2004-12-22.

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

#import "CESyntaxParser.h"
#import "CETextViewProtocol.h"
#import "CESyntaxManager.h"
#import "CEIndicatorSheetController.h"
#import "NSString+MD5.h"
#import "Constants.h"


// local constants (QC might abbr of Quotes/Comment)
static NSString *const InvisiblesType = @"invisibles";

static NSString *const QCLocationKey = @"QCLocationKey";
static NSString *const QCPairKindKey = @"QCPairKindKey";
static NSString *const QCStartEndKey = @"QCStartEndKey";
static NSString *const QCLengthKey = @"QCLengthKey";

static NSString *const QCInlineCommentKind = @"QCInlineCommentKind";  // for pairKind
static NSString *const QCBlockCommentKind = @"QCBlockCommentKind";  // for pairKind

typedef NS_ENUM(NSUInteger, QCStartEndType) {
    QCEnd,
    QCStartEnd,
    QCStart,
};




@interface CESyntaxParser ()

@property (nonatomic) BOOL hasSyntaxHighlighting;
@property (nonatomic, nullable, copy) NSDictionary *coloringDictionary;
@property (nonatomic, nullable, copy) NSDictionary *simpleWordsCharacterSets;
@property (nonatomic, nullable, copy) NSDictionary *pairedQuoteTypes;  // dict for quote pair to extract with comment

@property (nonatomic, nullable, copy) NSDictionary *cacheColorings;  // extracted results cache of the last whole string coloring
@property (nonatomic, nullable, copy) NSString *cacheHash;  // MD5 hash

@property (nonatomic, nullable) CEIndicatorSheetController *indicatorController;


// readonly
@property (readwrite, nonatomic, nonnull, copy) NSString *styleName;
@property (readwrite, nonatomic, nullable, copy) NSArray *completionWords;
@property (readwrite, nonatomic, nullable, copy) NSCharacterSet *firstCompletionCharacterSet;
@property (readwrite, nonatomic, nullable, copy) NSString *inlineCommentDelimiter;
@property (readwrite, nonatomic, nullable, copy) NSDictionary *blockCommentDelimiters;
@property (readwrite, nonatomic, getter=isNone) BOOL none;

@end




#pragma mark -

@implementation CESyntaxParser

static NSArray *kSyntaxDictKeys;
static CGFloat kPerCompoIncrement;


#pragma mark Superclass Methods

// ------------------------------------------------------
/// initialize class
+ (void)initialize
// ------------------------------------------------------
{
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        NSMutableArray *syntaxDictKeys = [NSMutableArray arrayWithCapacity:kSizeOfAllColoringKeys];
        for (NSUInteger i = 0; i < kSizeOfAllColoringKeys; i++) {
            [syntaxDictKeys addObject:kAllColoringKeys[i]];
        }
        kSyntaxDictKeys = [syntaxDictKeys copy];
        
        // カラーリングインジケータの上昇幅を決定する（+1 はコメント＋引用符抽出用）
        kPerCompoIncrement = 0.98 / (kSizeOfAllColoringKeys + 0.01);
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
            NSMutableDictionary *coloringDictionary = [[[CESyntaxManager sharedManager] styleWithStyleName:styleName] mutableCopy];
            
            // コメントデリミッタを設定
            NSDictionary *delimiters = coloringDictionary[CESyntaxCommentDelimitersKey];
            if ([delimiters[CESyntaxInlineCommentKey] length] > 0) {
                _inlineCommentDelimiter = delimiters[CESyntaxInlineCommentKey];
            }
            if ([delimiters[CESyntaxBeginCommentKey] length] > 0 && [delimiters[CESyntaxEndCommentKey] length] > 0) {
                _blockCommentDelimiters = @{CEBeginDelimiterKey: delimiters[CESyntaxBeginCommentKey],
                                            CEEndDelimiterKey: delimiters[CESyntaxEndCommentKey]};
            }
            
            // カラーリング辞書から補完文字列配列を生成
            {
                NSMutableArray *completionWords = [NSMutableArray array];
                NSMutableString *firstCharsString = [NSMutableString string];
                NSArray *completionDicts = coloringDictionary[CESyntaxCompletionsKey];
                
                if ([completionDicts count] > 0) {
                    for (NSDictionary *dict in completionDicts) {
                        NSString *word = dict[CESyntaxKeyStringKey];
                        [completionWords addObject:word];
                        [firstCharsString appendString:[word substringToIndex:1]];
                    }
                } else {
                    NSCharacterSet *trimCharSet = [NSCharacterSet whitespaceAndNewlineCharacterSet];
                    for (NSString *key in kSyntaxDictKeys) {
                        @autoreleasepool {
                            for (NSDictionary *wordDict in coloringDictionary[key]) {
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
                NSMutableDictionary *characterSets = [NSMutableDictionary dictionary];
                NSCharacterSet *trimCharSet = [NSCharacterSet whitespaceAndNewlineCharacterSet];
                
                for (NSString *key in kSyntaxDictKeys) {
                    @autoreleasepool {
                        NSMutableCharacterSet *charSet = [NSMutableCharacterSet characterSetWithCharactersInString:kAllAlphabetChars];
                        
                        for (NSDictionary *wordDict in coloringDictionary[key]) {
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
                        
                        characterSets[key] = charSet;
                    }
                }
                _simpleWordsCharacterSets = [characterSets copy];
            }
            
            // 引用符のカラーリングはコメントと一緒に別途 extractCommentsWithQuotesFromString: で行なうので選り分けておく
            // そもそもカラーリング用の定義があるのかもここでチェック
            {
                NSUInteger count = 0;
                NSMutableDictionary *quoteTypes = [NSMutableDictionary dictionary];
                
                for (NSString *key in kSyntaxDictKeys) {
                    NSMutableArray *wordDicts = [coloringDictionary[key] mutableCopy];
                    count += [wordDicts count];
                    
                    for (NSDictionary *wordDict in coloringDictionary[key]) {
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
                        coloringDictionary[key] = wordDicts;
                    }
                }
                _pairedQuoteTypes = quoteTypes;
                
                // シンタックスカラーリングが必要かをキャッシュ
                _hasSyntaxHighlighting = ((count > 0) || _inlineCommentDelimiter || _blockCommentDelimiters);
            }
            
            // store as properties
            _styleName = styleName;
            _coloringDictionary = [coloringDictionary copy];
            
        } else {
            return nil;
        }
    }
    return self;
}

@end




#pragma mark -

@implementation CESyntaxParser (Outline)

#pragma mark Public Methods

// ------------------------------------------------------
/// アウトラインメニュー用の配列を生成し、返す
- (nonnull NSArray *)outlineItemsWithWholeString:(nullable NSString *)wholeString
// ------------------------------------------------------
{
    if (([wholeString length] == 0) || [self isNone]) { return @[]; }
    
    NSMutableArray *outlineItems = [NSMutableArray array];
    NSArray *definitions = [self coloringDictionary][CESyntaxOutlineMenuKey];
    
    for (NSDictionary *definition in definitions) {
        NSRegularExpressionOptions options = NSRegularExpressionAnchorsMatchLines;
        if ([definition[CESyntaxIgnoreCaseKey] boolValue]) {
            options |= NSRegularExpressionCaseInsensitive;
        }
        
        NSError *error = nil;
        NSRegularExpression *regex = [NSRegularExpression regularExpressionWithPattern:definition[CESyntaxBeginStringKey]
                                                                               options:options
                                                                                 error:&error];
        if (error) {
            NSLog(@"ERROR in \"%s\" with regex pattern \"%@\"", __PRETTY_FUNCTION__, definition[CESyntaxBeginStringKey]);
            continue;  // do nothing
        }
        
        NSString *template = definition[CESyntaxKeyStringKey];
        
        [regex enumerateMatchesInString:wholeString
                                options:0
                                  range:NSMakeRange(0, [wholeString length])
                             usingBlock:^(NSTextCheckingResult *result, NSMatchingFlags flags, BOOL *stop)
         {
             NSRange range = [result range];
             
             // separator item
             if ([template isEqualToString:CESeparatorString]) {
                 [outlineItems addObject:@{CEOutlineItemRangeKey: [NSValue valueWithRange:range],
                                           CEOutlineItemTitleKey: CESeparatorString}];
                 return;
             }
             
             // menu item title
             NSString *title;
             
             if ([template length] == 0) {
                 // no pattern definition
                 title = [wholeString substringWithRange:range];;
                 
             } else {
                 // replace matched string with template
                 title = [regex replacementStringForResult:result
                                                  inString:wholeString
                                                    offset:0
                                                  template:template];
                 
                 
                 // replace line number ($LN)
                 if ([title rangeOfString:@"$LN"].location != NSNotFound) {
                     // count line number of the beginning of the matched range
                     NSUInteger lineCount = 0, index = 0;
                     while (index <= range.location) {
                         index = NSMaxRange([wholeString lineRangeForRange:NSMakeRange(index, 0)]);
                         lineCount++;
                     }
                     
                     // replace
                     title = [title stringByReplacingOccurrencesOfString:@"(?<!\\\\)\\$LN"
                                                              withString:[NSString stringWithFormat:@"%tu", lineCount]
                                                                 options:NSRegularExpressionSearch
                                                                   range:NSMakeRange(0, [title length])];
                 }
             }
             
             // replace whitespaces
             title = [title stringByReplacingOccurrencesOfString:@"\n" withString:@" "];
             title = [title stringByReplacingOccurrencesOfString:@"\t" withString:@"    "];
             
             // font styles (unwrap once to avoid setting nil to dict)
             BOOL isBold = [definition[CESyntaxBoldKey] boolValue];
             BOOL isItalic = [definition[CESyntaxItalicKey] boolValue];
             BOOL isUnderline = [definition[CESyntaxUnderlineKey] boolValue];
             
             // append outline item
             [outlineItems addObject:@{CEOutlineItemRangeKey: [NSValue valueWithRange:range],
                                       CEOutlineItemTitleKey: title,
                                       CEOutlineItemStyleBoldKey: @(isBold),
                                       CEOutlineItemStyleItalicKey: @(isItalic),
                                       CEOutlineItemStyleUnderlineKey: @(isUnderline)}];
         }];
    }
    
    if ([outlineItems count] > 0) {
        // sort by location
        [outlineItems sortUsingComparator:^NSComparisonResult(id obj1, id obj2) {
            NSRange range1 = [obj1[CEOutlineItemRangeKey] rangeValue];
            NSRange range2 = [obj2[CEOutlineItemRangeKey] rangeValue];
            
            if (range1.location > range2.location) {
                return NSOrderedDescending;
            } else if (range1.location < range2.location) {
                return NSOrderedAscending;
            } else {
                return NSOrderedSame;
            }
        }];
    }
    
    return outlineItems;
}

@end




#pragma mark -

@implementation CESyntaxParser (Highlighting)

#pragma mark Public Methods

// ------------------------------------------------------
/// 全体をカラーリング
- (void)colorAllString:(nullable NSString *)wholeString layoutManager:(nonnull NSLayoutManager *)layoutManager temporal:(BOOL)isTemporal
// ------------------------------------------------------
{
    if ([wholeString length] == 0) { return; }
    
    NSRange range = NSMakeRange(0, [wholeString length]);
    
    // 前回の全文カラーリングと内容が全く同じ場合はキャッシュを使う
    if ([[wholeString MD5] isEqualToString:[self cacheHash]]) {
        [self applyColorings:[self cacheColorings] range:range layoutManager:layoutManager temporal:isTemporal];
    } else {
        // make sure that string is immutable
        NSString *safeImmutableString = [NSString stringWithString:wholeString];
        // [Caution] DO NOT use [wholeString copy] here instead of `stringWithString:`.
        //           It still returns a mutable object, NSBigMutableString,
        //           and it can cause crash when the mutable string is given to NSRegularExpression instance.
        //           (2015-08, with OS X 10.10 SDK)
        
        [self colorString:safeImmutableString
                    range:range layoutManager:layoutManager temporal:isTemporal];
    }
}


// ------------------------------------------------------
/// 表示されている部分をカラーリング
- (void)colorRange:(NSRange)range wholeString:(nullable NSString *)wholeString layoutManager:(nonnull NSLayoutManager *)layoutManager temporal:(BOOL)isTemporal
// ------------------------------------------------------
{
    if ([wholeString length] == 0) { return; }
    
    // make sure that string is immutable (see `colorAllString:layoutManager:temporal:` for details)
    NSString *safeImmutableString = [NSString stringWithString:wholeString];
    
    NSUInteger bufferLength = [[NSUserDefaults standardUserDefaults] integerForKey:CEDefaultColoringRangeBufferLengthKey];
    NSRange wholeRange = NSMakeRange(0, [safeImmutableString length]);
    NSRange coloringRange;
    
    // 文字列が十分小さい時は全文カラーリングをする
    if (wholeRange.length <= bufferLength) {
        coloringRange = wholeRange;
        
    } else {
        NSUInteger start = range.location;
        NSUInteger end = NSMaxRange(range) - 1;
        
        // 表示領域の前もある程度カラーリングの対象に含める
        start -= MIN(start, bufferLength);
        
        // 直前／直後が同色ならカラーリング範囲を拡大する
        NSRange effectiveRange;
        [layoutManager temporaryAttributesAtCharacterIndex:start
                                     longestEffectiveRange:&effectiveRange
                                                   inRange:wholeRange];
        start = effectiveRange.location;
        
        [layoutManager temporaryAttributesAtCharacterIndex:end
                                     longestEffectiveRange:&effectiveRange
                                                   inRange:wholeRange];
        end = NSMaxRange(effectiveRange);
        
        coloringRange = NSMakeRange(start, end - start);
    }
    
    coloringRange = [safeImmutableString lineRangeForRange:coloringRange];
    
    [self colorString:safeImmutableString range:coloringRange layoutManager:layoutManager temporal:isTemporal];
}



#pragma mark Private Methods

// ------------------------------------------------------
/// 指定された文字列をそのまま検索し、位置を返す
- (nonnull NSArray *)rangesOfSimpleWords:(nonnull NSDictionary *)wordsDict ignoreCaseWords:(nonnull NSDictionary *)icWordsDict charSet:(nonnull NSCharacterSet *)charSet string:(nonnull NSString *)string range:(NSRange)parseRange
// ------------------------------------------------------
{
    NSMutableArray *ranges = [NSMutableArray array];
    CEIndicatorSheetController *indicator = [self indicatorController];
    
    NSScanner *scanner = [NSScanner scannerWithString:string];
    [scanner setCaseSensitive:YES];
    [scanner setScanLocation:parseRange.location];
    
    while(![scanner isAtEnd] && ([scanner scanLocation] < NSMaxRange(parseRange))) {
        if ([indicator isCancelled]) { return @[]; }
        
        @autoreleasepool {
            NSString *scannedString = nil;
            [scanner scanUpToCharactersFromSet:charSet intoString:NULL];
            if (![scanner scanCharactersFromSet:charSet intoString:&scannedString]) { break; }
            
            NSUInteger length = [scannedString length];
            
            NSArray *words = wordsDict[@(length)];
            BOOL isFound = [words containsObject:scannedString];
            
            if (!isFound) {
                words = icWordsDict[@(length)];
                isFound = [words containsObject:[scannedString lowercaseString]];  // The words are already transformed in lowercase.
            }
            
            if (isFound) {
                NSUInteger location = [scanner scanLocation];
                NSRange range = NSMakeRange(location - length, length);
                [ranges addObject:[NSValue valueWithRange:range]];
            }
        }
    }
    
    return ranges;
}


// ------------------------------------------------------
/// 指定された文字列を検索し、位置を返す
- (nonnull NSArray *)rangesOfString:(nonnull NSString *)searchString ignoreCase:(BOOL)ignoreCase string:(nonnull NSString *)string range:(NSRange)parseRange
// ------------------------------------------------------
{
    if ([searchString length] == 0) { return @[]; }
    
    NSMutableArray *ranges = [NSMutableArray array];
    CEIndicatorSheetController *indicator = [self indicatorController];
    NSUInteger length = [searchString length];
    
    NSScanner *scanner = [NSScanner scannerWithString:string];
    [scanner setCharactersToBeSkipped:nil];
    [scanner setCaseSensitive:!ignoreCase];
    [scanner setScanLocation:parseRange.location];
    
    while(![scanner isAtEnd] && ([scanner scanLocation] < NSMaxRange(parseRange))) {
        if ([indicator isCancelled]) { return @[]; }
        
        @autoreleasepool {
            [scanner scanUpToString:searchString intoString:nil];
            NSUInteger startLocation = [scanner scanLocation];
            
            if (![scanner scanString:searchString intoString:nil]) { break; }
            
            if (isCharacterEscaped(string, startLocation)) { continue; }
            
            NSRange range = NSMakeRange(startLocation, length);
            [ranges addObject:[NSValue valueWithRange:range]];
        }
    }
    
    return ranges;
}


// ------------------------------------------------------
/// 指定された開始／終了ペアの文字列を検索し、位置を返す
- (nonnull NSArray *)rangesOfBeginString:(nonnull NSString *)beginString endString:(nonnull NSString *)endString ignoreCase:(BOOL)ignoreCase string:(nonnull NSString *)string range:(NSRange)parseRange
// ------------------------------------------------------
{
    if ([beginString length] == 0) { return @[]; }
    
    NSMutableArray *ranges = [NSMutableArray array];
    CEIndicatorSheetController *indicator = [self indicatorController];
    NSUInteger endLength = [endString length];
    
    NSScanner *scanner = [NSScanner scannerWithString:string];
    [scanner setCharactersToBeSkipped:nil];
    [scanner setCaseSensitive:!ignoreCase];
    [scanner setScanLocation:parseRange.location];
    
    while(![scanner isAtEnd] && ([scanner scanLocation] < NSMaxRange(parseRange))) {
        if ([indicator isCancelled]) { return @[]; }
        
        @autoreleasepool {
            [scanner scanUpToString:beginString intoString:nil];
            NSUInteger startLocation = [scanner scanLocation];
            
            if (![scanner scanString:beginString intoString:nil]) { break; }
            
            if (isCharacterEscaped(string, startLocation)) { continue; }
            
            // find end string
            while(![scanner isAtEnd] && ([scanner scanLocation] < NSMaxRange(parseRange))) {
                
                [scanner scanUpToString:endString intoString:nil];
                if (![scanner scanString:endString intoString:nil]) { break; }
                
                NSUInteger endLocation = [scanner scanLocation];
                
                if (isCharacterEscaped(string, (endLocation - endLength))) { continue; }
                
                NSRange range = NSMakeRange(startLocation, endLocation - startLocation);
                [ranges addObject:[NSValue valueWithRange:range]];
                
                break;
            }
        }
    }
    
    return ranges;
}


// ------------------------------------------------------
/// 指定された文字列を正規表現として検索し、位置を返す
- (nonnull NSArray *)rangesOfRegularExpressionString:(nonnull NSString *)regexStr ignoreCase:(BOOL)ignoreCase string:(nonnull NSString *)string range:(NSRange)parseRange
// ------------------------------------------------------
{
    if ([regexStr length] == 0) { return @[]; }
    
    NSMutableArray *ranges = [NSMutableArray array];
    CEIndicatorSheetController *indicator = [self indicatorController];
    NSRegularExpressionOptions options = NSRegularExpressionAnchorsMatchLines;
    if (ignoreCase) {
        options |= NSRegularExpressionCaseInsensitive;
    }
    
    NSError *error = nil;
    NSRegularExpression *regex = [NSRegularExpression regularExpressionWithPattern:regexStr options:options error:&error];
    if (error) {
        NSLog(@"ERROR in \"%s\"", __PRETTY_FUNCTION__);
        return @[];
    }
    
    [regex enumerateMatchesInString:string
                            options:NSMatchingReportProgress | NSMatchingWithTransparentBounds | NSMatchingWithoutAnchoringBounds
                              range:parseRange
                         usingBlock:^(NSTextCheckingResult *result, NSMatchingFlags flags, BOOL *stop)
     {
         if (flags & NSMatchingProgress) {
             if ([indicator isCancelled]) {
                 *stop = YES;
             }
             return;
         }
         
         [ranges addObject:[NSValue valueWithRange:[result range]]];
     }];
    
    return ranges;
}


// ------------------------------------------------------
/// 指定された開始／終了文字列を正規表現として検索し、位置を返す
- (nonnull NSArray *)rangesOfRegularExpressionBeginString:(nonnull NSString *)beginString endString:(nonnull NSString *)endString ignoreCase:(BOOL)ignoreCase string:(nonnull NSString *)string range:(NSRange)parseRange
// ------------------------------------------------------
{
    NSMutableArray *ranges = [NSMutableArray array];
    CEIndicatorSheetController *indicator = [self indicatorController];
    NSRegularExpressionOptions options = NSRegularExpressionAnchorsMatchLines;
    if (ignoreCase) {
        options |= NSRegularExpressionCaseInsensitive;
    }
    
    NSError *error = nil;
    NSRegularExpression *beginRegex = [NSRegularExpression regularExpressionWithPattern:beginString options:options error:&error];
    NSRegularExpression *endRegex = [NSRegularExpression regularExpressionWithPattern:endString options:options error:&error];
    
    if (error) {
        NSLog(@"ERROR in \"%s\"", __PRETTY_FUNCTION__);
        return @[];
    }
    
    [beginRegex enumerateMatchesInString:string
                                 options:NSMatchingReportProgress | NSMatchingWithTransparentBounds | NSMatchingWithoutAnchoringBounds
                                   range:parseRange
                              usingBlock:^(NSTextCheckingResult *result, NSMatchingFlags flags, BOOL *stop)
     {
         if (flags & NSMatchingProgress) {
             if ([indicator isCancelled]) {
                 *stop = YES;
             }
             return;
         }
         
         NSRange beginRange = [result range];
         NSRange endRange = [endRegex rangeOfFirstMatchInString:string
                                                        options:NSMatchingWithTransparentBounds | NSMatchingWithoutAnchoringBounds
                                                          range:NSMakeRange(NSMaxRange(beginRange),
                                                                            [string length] - NSMaxRange(beginRange))];
         
         if (endRange.location != NSNotFound) {
             [ranges addObject:[NSValue valueWithRange:NSUnionRange(beginRange, endRange)]];
         }
     }];
    
    return ranges;
}


// ------------------------------------------------------
/// 不可視文字のカラーリング範囲配列を返す
- (nonnull NSArray *)rangesOfControlCharsInString:(nonnull NSString *)string range:(NSRange)parseRange
// ------------------------------------------------------
{
    NSMutableArray *ranges = [NSMutableArray array];
    NSCharacterSet *controlCharacterSet = [NSCharacterSet controlCharacterSet];
    NSScanner *scanner = [NSScanner scannerWithString:string];
    
    [scanner setScanLocation:parseRange.location];
    
    while(![scanner isAtEnd] && ([scanner scanLocation] < NSMaxRange(parseRange))) {
        [scanner scanUpToCharactersFromSet:controlCharacterSet intoString:nil];
        NSUInteger location = [scanner scanLocation];
        NSString *control;
        if ([scanner scanCharactersFromSet:controlCharacterSet intoString:&control]) {
            NSRange range = NSMakeRange(location, [control length]);
            
            [ranges addObject:[NSValue valueWithRange:range]];
        }
    }
    
    return ranges;
}


// ------------------------------------------------------
/// クオートで囲まれた文字列とともにコメントをカラーリング
- (nonnull NSDictionary *)extractCommentsWithQuotesFromString:(nonnull NSString *)string range:(NSRange)parseRange
// ------------------------------------------------------
{
    NSDictionary *quoteTypes = [self pairedQuoteTypes];
    NSMutableArray *positions = [NSMutableArray array];
    
    // コメント定義の位置配列を生成
    if ([self blockCommentDelimiters]) {
        NSString *beginDelimiter = [self blockCommentDelimiters][CEBeginDelimiterKey];
        NSArray *beginRanges = [self rangesOfString:beginDelimiter ignoreCase:NO string:string range:parseRange];
        for (NSValue *rangeValue in beginRanges) {
            NSRange range = [rangeValue rangeValue];
            
            [positions addObject:@{QCPairKindKey: QCBlockCommentKind,
                                   QCStartEndKey: @(QCStart),
                                   QCLocationKey: @(range.location),
                                   QCLengthKey: @([beginDelimiter length])}];
        }
        
        NSString *endDelimiter = [self blockCommentDelimiters][CEEndDelimiterKey];
        NSArray *endRanges = [self rangesOfString:endDelimiter ignoreCase:NO string:string range:parseRange];
        for (NSValue *rangeValue in endRanges) {
            NSRange range = [rangeValue rangeValue];
            
            [positions addObject:@{QCPairKindKey: QCBlockCommentKind,
                                   QCStartEndKey: @(QCEnd),
                                   QCLocationKey: @(range.location),
                                   QCLengthKey: @([endDelimiter length])}];
        }
        
    }
    if ([self inlineCommentDelimiter]) {
        NSString *delimiter = [self inlineCommentDelimiter];
        NSArray *ranges = [self rangesOfString:delimiter ignoreCase:NO string:string range:parseRange];
        for (NSValue *rangeValue in ranges) {
            NSRange range = [rangeValue rangeValue];
            NSRange lineRange = [string lineRangeForRange:range];
            
            [positions addObject:@{QCPairKindKey: QCInlineCommentKind,
                                   QCStartEndKey: @(QCStart),
                                   QCLocationKey: @(range.location),
                                   QCLengthKey: @([delimiter length])}];
            [positions addObject:@{QCPairKindKey: QCInlineCommentKind,
                                   QCStartEndKey: @(QCEnd),
                                   QCLocationKey: @(NSMaxRange(lineRange)),
                                   QCLengthKey: @0U}];
            
        }
        
    }
    
    // クォート定義があれば位置配列を生成、マージ
    for (NSString *quote in quoteTypes) {
        NSArray *ranges = [self rangesOfString:quote ignoreCase:NO string:string range:parseRange];
        for (NSValue *rangeValue in ranges) {
            NSRange range = [rangeValue rangeValue];
            
            [positions addObject:@{QCPairKindKey: quote,
                                   QCStartEndKey: @(QCStartEnd),
                                   QCLocationKey: @(range.location),
                                   QCLengthKey: @([quote length])}];
        }
    }
    
    // コメントもクォートもなければ、もどる
    if ([positions count] == 0) { return @{}; }
    
    // 出現順にソート
    NSSortDescriptor *positionSort = [NSSortDescriptor sortDescriptorWithKey:QCLocationKey ascending:YES];
    NSSortDescriptor *prioritySort = [NSSortDescriptor sortDescriptorWithKey:QCStartEndKey ascending:YES];
    [positions sortUsingDescriptors:@[positionSort, prioritySort]];
    
    // カラーリング範囲を走査
    NSMutableDictionary *colorings = [NSMutableDictionary dictionary];
    NSUInteger startLocation = 0;
    NSString *searchPairKind = nil;
    BOOL isContinued = NO;
    
    for (NSDictionary *position in positions) {
        QCStartEndType startEnd = [position[QCStartEndKey] unsignedIntegerValue];
        isContinued = NO;
        
        if (!searchPairKind) {
            if (startEnd != QCEnd) {
                searchPairKind = position[QCPairKindKey];
                startLocation = [position[QCLocationKey] unsignedIntegerValue];
            }
            continue;
        }
        
        if (([position[QCPairKindKey] isEqualToString:searchPairKind]) &&
            ((startEnd == QCStartEnd) || (startEnd == QCEnd)))
        {
            NSUInteger endLocation = ([position[QCLocationKey] unsignedIntegerValue] +
                                      [position[QCLengthKey] unsignedIntegerValue]);
            
            NSString *colorType = quoteTypes[searchPairKind] ? : CESyntaxCommentsKey;
            NSRange range = NSMakeRange(startLocation, endLocation - startLocation);
            
            if (colorings[colorType]) {
                [colorings[colorType] addObject:[NSValue valueWithRange:range]];
            } else {
                colorings[colorType] = [NSMutableArray arrayWithObject:[NSValue valueWithRange:range]];
            }
            
            searchPairKind = nil;
            continue;
        }
        
        isContinued = YES;
    }
    
    // 「終わり」がなければ最後までカラーリングする
    if (isContinued) {
        NSString *colorType = quoteTypes[searchPairKind] ? : CESyntaxCommentsKey;
        NSRange range = NSMakeRange(startLocation, [string length] - startLocation);
        
        if (colorings[colorType]) {
            [colorings[colorType] addObject:[NSValue valueWithRange:range]];
        } else {
            colorings[colorType] = [NSMutableArray arrayWithObject:[NSValue valueWithRange:range]];
        }
    }
    
    return [colorings copy];
}


// ------------------------------------------------------
/// 対象範囲の全てのカラーリング範囲配列を返す
- (nonnull NSDictionary *)extractAllSyntaxFromString:(nonnull NSString *)string range:(NSRange)parseRange
// ------------------------------------------------------
{
    NSMutableDictionary *colorings = [NSMutableDictionary dictionary];  // key: coloring type value: range array
    CEIndicatorSheetController *indicator = [self indicatorController];
    
    // Keywords > Commands > Types > Attributes > Variables > Values > Numbers > Strings > Characters > Comments
    for (NSString *syntaxKey in kSyntaxDictKeys) {
        // インジケータシートのメッセージを更新
        if (indicator) {
            dispatch_async(dispatch_get_main_queue(), ^{
                [indicator setInformativeText:[NSString stringWithFormat:NSLocalizedString(@"Extracting %@…", nil),
                                               NSLocalizedString(syntaxKey, nil)]];
            });
        }
        
        NSArray *strDicts = [self coloringDictionary][syntaxKey];
        if ([strDicts count] == 0) {
            [indicator progressIndicator:kPerCompoIncrement];
            continue;
        }
        
        CGFloat indicatorDelta = kPerCompoIncrement / [strDicts count];
        
        NSMutableDictionary *simpleWordsDict = [NSMutableDictionary dictionaryWithCapacity:40];
        NSMutableDictionary *simpleICWordsDict = [NSMutableDictionary dictionaryWithCapacity:40];
        NSMutableArray *ranges = [NSMutableArray arrayWithCapacity:10];
        
        dispatch_apply([strDicts count], dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^(size_t i) {
            // skip loop if cancelled
            if ([indicator isCancelled]) { return; }
            
            @autoreleasepool {
                NSDictionary *strDict = strDicts[i];
                
                NSString *beginStr = strDict[CESyntaxBeginStringKey];
                NSString *endStr = strDict[CESyntaxEndStringKey];
                BOOL ignoresCase = [strDict[CESyntaxIgnoreCaseKey] boolValue];
                
                if ([beginStr length] == 0) { return; }  // continue
                
                NSArray *extractedRanges = @[];
                
                if ([strDict[CESyntaxRegularExpressionKey] boolValue]) {
                    if ([endStr length] > 0) {
                        extractedRanges = [self rangesOfRegularExpressionBeginString:beginStr
                                                                           endString:endStr
                                                                          ignoreCase:ignoresCase
                                                                              string:string
                                                                               range:parseRange];
                    } else {
                        extractedRanges = [self rangesOfRegularExpressionString:beginStr
                                                                     ignoreCase:ignoresCase
                                                                         string:string
                                                                          range:parseRange];
                    }
                } else {
                    if ([endStr length] > 0) {
                        extractedRanges = [self rangesOfBeginString:beginStr
                                                          endString:endStr
                                                         ignoreCase:ignoresCase
                                                             string:string
                                                              range:parseRange];
                    } else {
                        NSNumber *len = @([beginStr length]);
                        @synchronized(simpleWordsDict) {
                            NSMutableDictionary *dict = ignoresCase ? simpleICWordsDict : simpleWordsDict;
                            NSMutableArray *wordsArray = dict[len];
                            if (wordsArray) {
                                [wordsArray addObject:beginStr];
                                
                            } else {
                                wordsArray = [NSMutableArray arrayWithObject:beginStr];
                                dict[len] = wordsArray;
                            }
                        }
                    }
                }
                
                @synchronized(ranges) {
                    [ranges addObjectsFromArray:extractedRanges];
                }
            }
            
            // progress indicator
            [indicator progressIndicator:indicatorDelta];
        });
        
        // キャンセルされたら現在実行中の抽出は破棄して戻る
        if ([indicator isCancelled]) { return @{}; }
        
        if ([simpleWordsDict count] > 0 || [simpleICWordsDict count] > 0) {
            [ranges addObjectsFromArray:[self rangesOfSimpleWords:simpleWordsDict
                                                  ignoreCaseWords:simpleICWordsDict
                                                          charSet:[self simpleWordsCharacterSets][syntaxKey]
                                                           string:string
                                                            range:parseRange]];
        }
        // store range array
        colorings[syntaxKey] = ranges;
        
    } // end-for (syntaxKey)
    
    if ([indicator isCancelled]) { return @{}; }
    
    // コメントと引用符
    if (indicator) {
        dispatch_async(dispatch_get_main_queue(), ^{
            [indicator setInformativeText:[NSString stringWithFormat:NSLocalizedString(@"Extracting %@…", nil),
                                           NSLocalizedString(@"comments and quoted texts", nil)]];
        });
    }
    [colorings addEntriesFromDictionary:[self extractCommentsWithQuotesFromString:string range:parseRange]];
    [indicator progressIndicator:kPerCompoIncrement];
    
    if ([indicator isCancelled]) { return @{}; }
    
    // 不可視文字の追加
    colorings[InvisiblesType] = [self rangesOfControlCharsInString:string range:parseRange];
    
    return [colorings copy];
}


// ------------------------------------------------------
/// カラーリングを実行
- (void)colorString:(nonnull NSString *)wholeString range:(NSRange)coloringRange layoutManager:(nonnull NSLayoutManager *)layoutManager temporal:(BOOL)isTemporal
// ------------------------------------------------------
{
    if (coloringRange.length == 0) { return; }
    
    // カラーリング不要なら現在のカラーリングをクリアして戻る
    if (![self hasSyntaxHighlighting]) {
        [self applyColorings:@{} range:coloringRange layoutManager:layoutManager temporal:isTemporal];
        return;
    }
    
    // 規定の文字数以上の場合にはカラーリングインジケータシートを表示
    // （ただし、CEDefaultShowColoringIndicatorTextLengthKey が「0」の時は表示しない）
    CEIndicatorSheetController *indicator = nil;
    NSUInteger indicatorThreshold = [[NSUserDefaults standardUserDefaults] integerForKey:CEDefaultShowColoringIndicatorTextLengthKey];
    if ((indicatorThreshold > 0) && (coloringRange.length > indicatorThreshold)) {
        NSWindow *documentWindow = [[layoutManager firstTextView] window];
        indicator = [[CEIndicatorSheetController alloc] initWithMessage:NSLocalizedString(@"Coloring text…", nil)];
        [self setIndicatorController:indicator];
        
        // wait for window becomes visible
        __weak typeof(self) weakSelf = self;
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0), ^{
            typeof(self) self = weakSelf;  // strong self
            if (!self) { return; }
            
            while (![documentWindow isVisible]) {
                [[NSRunLoop currentRunLoop] limitDateForMode:NSDefaultRunLoopMode];
            }
            
            // progress the main thread run-loop in order to give a chance to show more important sheet
            dispatch_sync(dispatch_get_main_queue(), ^{});
            
            // weit until attached window closes
            while ([documentWindow attachedSheet]) {
                [[NSRunLoop currentRunLoop] limitDateForMode:NSDefaultRunLoopMode];
            }
            
            // do nothing if the indicator has already been put away (= coloring was finished)
            if (![self indicatorController]) { return; }
            
            // otherwise, attach the indicator as a sheet
            dispatch_async(dispatch_get_main_queue(), ^{
                [[self indicatorController] beginSheetForWindow:documentWindow];
            });
        });
    }
    
    __weak typeof(self) weakSelf = self;
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        typeof(self) self = weakSelf;  // strong self
        if (!self) { return; }
        // カラー範囲を抽出する
        NSDictionary *colorings = [self extractAllSyntaxFromString:wholeString range:coloringRange];
        
        if ([colorings count] > 0) {
            // 全文を抽出した場合は抽出結果をキャッシュする
            if (coloringRange.length == [wholeString length]) {
                [self setCacheColorings:colorings];
                [self setCacheHash:[wholeString MD5]];
            }
            
            // update indicator message
            if (indicator) {
                dispatch_sync(dispatch_get_main_queue(), ^{
                    [indicator setInformativeText:NSLocalizedString(@"Applying colors to text", nil)];
                });
            }
            
            // apply color (or give up if the editor's string is changed from the analized string)
            if ([[[layoutManager textStorage] string] isEqualToString:wholeString]) {
                dispatch_sync(dispatch_get_main_queue(), ^{
                    [self applyColorings:colorings range:coloringRange layoutManager:layoutManager temporal:isTemporal];
                });
            }
        }
        
        // clean up indicator sheet
        if (indicator) {
            dispatch_sync(dispatch_get_main_queue(), ^{
                [indicator endSheet];
                [self setIndicatorController:nil];
            });
        }
    });
}


// ------------------------------------------------------
/// 抽出したカラー範囲配列を書類に適用する
- (void)applyColorings:(NSDictionary *)colorings range:(NSRange)coloringRange layoutManager:(nonnull NSLayoutManager *)layoutManager temporal:(BOOL)isTemporal
// ------------------------------------------------------
{
    CETheme *theme = [(NSTextView<CETextViewProtocol> *)[layoutManager firstTextView] theme];
    
    // 現在あるカラーリングを削除
    if (isTemporal) {
        [layoutManager removeTemporaryAttribute:NSForegroundColorAttributeName
                              forCharacterRange:coloringRange];
    } else {
        [[layoutManager firstTextView] setTextColor:[theme textColor] range:coloringRange];
    }
    
    // add invisible coloring if needed
    NSArray *colorTypes = kSyntaxDictKeys;
    if ([layoutManager showsControlCharacters]) {
        colorTypes = [colorTypes arrayByAddingObject:InvisiblesType];
    }
    
    // カラーリング実行
    for (NSString *colorType in colorTypes) {
        NSArray *ranges = colorings[colorType];
        
        if ([ranges count] == 0) { continue; }
        
        // get color from theme
        NSColor *color;
        if ([colorType isEqualToString:InvisiblesType]) {
            color = [theme invisiblesColor];
        } else if ([colorType isEqualToString:CESyntaxKeywordsKey]) {
            color = [theme keywordsColor];
        } else if ([colorType isEqualToString:CESyntaxCommandsKey]) {
            color = [theme commandsColor];
        } else if ([colorType isEqualToString:CESyntaxTypesKey]) {
            color = [theme typesColor];
        } else if ([colorType isEqualToString:CESyntaxAttributesKey]) {
            color = [theme attributesColor];
        } else if ([colorType isEqualToString:CESyntaxVariablesKey]) {
            color = [theme variablesColor];
        } else if ([colorType isEqualToString:CESyntaxValuesKey]) {
            color = [theme valuesColor];
        } else if ([colorType isEqualToString:CESyntaxNumbersKey]) {
            color = [theme numbersColor];
        } else if ([colorType isEqualToString:CESyntaxStringsKey]) {
            color = [theme stringsColor];
        } else if ([colorType isEqualToString:CESyntaxCharactersKey]) {
            color = [theme charactersColor];
        } else if ([colorType isEqualToString:CESyntaxCommentsKey]) {
            color = [theme commentsColor];
        } else {
            color = [theme textColor];
        }
        
        for (NSValue *rangeValue in ranges) {
            NSRange range = [rangeValue rangeValue];
            
            if (isTemporal) {
                [layoutManager addTemporaryAttribute:NSForegroundColorAttributeName
                                               value:color forCharacterRange:range];
            } else {
                [[layoutManager firstTextView] setTextColor:color range:range];
            }
        }
    }
}



#pragma mark Private Functions

// ------------------------------------------------------
/// 与えられた位置の文字がバックスラッシュでエスケープされているかを返す
BOOL isCharacterEscaped(NSString *string, NSUInteger location)
// ------------------------------------------------------
{
    NSUInteger numberOfEscapes = 0;
    NSUInteger escapesCheckLength = MIN(location, kMaxEscapesCheckLength);
    
    location--;
    for (NSUInteger i = 0; i < escapesCheckLength; i++) {
        if ([string characterAtIndex:location - i] == '\\') {
            numberOfEscapes++;
        } else {
            break;
        }
    }
    
    return (numberOfEscapes % 2 == 1);
}

@end
