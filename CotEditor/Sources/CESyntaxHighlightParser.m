/*
 
 CESyntaxHighlightParser.m
 
 CotEditor
 http://coteditor.com
 
 Created by 1024jp on 2016-01-06.
 
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

#import "CESyntaxHighlightParser.h"
#import "Constants.h"


// parsing constants
static NSUInteger const kMaxEscapesCheckLength = 16;

// key constants (QC might abbr of Quotes/Comment)
static NSString *_Nonnull const QCLocationKey = @"QCLocationKey";
static NSString *_Nonnull const QCPairKindKey = @"QCPairKindKey";
static NSString *_Nonnull const QCStartEndKey = @"QCStartEndKey";
static NSString *_Nonnull const QCLengthKey = @"QCLengthKey";

static NSString *_Nonnull const QCInlineCommentKind = @"QCInlineCommentKind";  // for pairKind
static NSString *_Nonnull const QCBlockCommentKind = @"QCBlockCommentKind";  // for pairKind

typedef NS_ENUM(NSUInteger, QCStartEndType) {
    QCEnd,
    QCStartEnd,
    QCStart,
};


@interface CESyntaxHighlightParser ()

@property (nonatomic, nonnull) NSString *string;

@property (nonatomic, nullable, copy) NSDictionary<NSString *, id> *highlightDictionary;
@property (nonatomic, nullable, copy) NSDictionary<NSString *, NSCharacterSet *> *simpleWordsCharacterSets;
@property (nonatomic, nullable, copy) NSDictionary<NSString *, NSString *> *pairedQuoteTypes;  // dict for quote pair to extract with comment
@property (nonatomic, nullable, copy) NSString *inlineCommentDelimiter;
@property (nonatomic, nullable, copy) NSDictionary<NSString *, NSString *> *blockCommentDelimiters;

@end




#pragma mark -

@implementation CESyntaxHighlightParser

static NSArray<NSString *> *kSyntaxDictKeys;
static CGFloat kPerCompoIncrement;


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
        
        // カラーリングインジケータの上昇幅を決定する（+0.01 はコメント＋引用符抽出用）
        kPerCompoIncrement = 0.98 / (kSizeOfAllSyntaxKeys + 0.01);
    });
}


//------------------------------------------------------
/// disable superclass's designated initializer
- (nullable instancetype)init
//------------------------------------------------------
{
    @throw nil;
}



#pragma mark Public Methods

// ------------------------------------------------------
/// initialize instance
- (nonnull instancetype)initWithString:(nonnull NSString *)string
                            dictionary:(nonnull NSDictionary *)dictionary
              simpleWordsCharacterSets:(nullable NSDictionary<NSString *,NSCharacterSet *> *)simpleWordsCharacterSets
                      pairedQuoteTypes:(nullable NSDictionary<NSString *,NSString *> *)pairedQuoteTypes
                inlineCommentDelimiter:(nullable NSString *)inlineCommentDelimiter
                blockCommentDelimiters:(nullable NSDictionary<NSString *,NSString *> *)blockCommentDelimiters
// ------------------------------------------------------
{
    self = [super init];
    if (self) {
        // make sure the string is immutable
        //   -> [note] NSTextStorage's `string` property retruns mutable string
        _string = [NSString stringWithString:string];
        
        _highlightDictionary = dictionary;
        _simpleWordsCharacterSets = simpleWordsCharacterSets;
        _pairedQuoteTypes = pairedQuoteTypes;
        _inlineCommentDelimiter = inlineCommentDelimiter;
        _blockCommentDelimiters = blockCommentDelimiters;
    }
    return self;
}


// ------------------------------------------------------
/// parse string in background and return extracted highlight ranges per syntax types
- (void)parseRange:(NSRange)range completionHandler:(void (^)(NSDictionary<NSString *,NSArray<NSValue *> *> * _Nonnull))completionHandler
// ------------------------------------------------------
{
    __weak typeof(self) weakSelf = self;
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        typeof(self) self = weakSelf;  // strong self
        if (!self) { return; }
        
        NSDictionary<NSString *,NSArray<NSValue *> *> *highlights = [self extractAllHighlightsFromString:[self string] range:range];
        if (completionHandler) {
            dispatch_sync(dispatch_get_main_queue(), ^{
                completionHandler(highlights);
            });
        }
    });
}



#pragma mark Private Methods

// ------------------------------------------------------
/// 指定された文字列をそのまま検索し、位置を返す
- (nonnull NSArray<NSValue *> *)rangesOfSimpleWords:(nonnull NSDictionary *)wordsDict ignoreCaseWords:(nonnull NSDictionary *)icWordsDict charSet:(nonnull NSCharacterSet *)charSet string:(nonnull NSString *)string range:(NSRange)parseRange
// ------------------------------------------------------
{
    NSMutableArray *ranges = [NSMutableArray array];
    
    NSScanner *scanner = [NSScanner scannerWithString:string];
    [scanner setCaseSensitive:YES];
    [scanner setScanLocation:parseRange.location];
    
    while(![scanner isAtEnd] && ([scanner scanLocation] < NSMaxRange(parseRange))) {
        if ([self isCancelled]) { return @[]; }
        
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
- (nonnull NSArray<NSValue *> *)rangesOfString:(nonnull NSString *)searchString ignoreCase:(BOOL)ignoreCase string:(nonnull NSString *)string range:(NSRange)parseRange
// ------------------------------------------------------
{
    if ([searchString length] == 0) { return @[]; }
    
    NSMutableArray<NSValue *> *ranges = [NSMutableArray array];
    NSUInteger length = [searchString length];
    
    NSScanner *scanner = [NSScanner scannerWithString:string];
    [scanner setCharactersToBeSkipped:nil];
    [scanner setCaseSensitive:!ignoreCase];
    [scanner setScanLocation:parseRange.location];
    
    while(![scanner isAtEnd] && ([scanner scanLocation] < NSMaxRange(parseRange))) {
        if ([self isCancelled]) { return @[]; }
        
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
- (nonnull NSArray<NSValue *> *)rangesOfBeginString:(nonnull NSString *)beginString endString:(nonnull NSString *)endString ignoreCase:(BOOL)ignoreCase string:(nonnull NSString *)string range:(NSRange)parseRange
// ------------------------------------------------------
{
    if ([beginString length] == 0) { return @[]; }
    
    NSMutableArray<NSValue *> *ranges = [NSMutableArray array];
    NSUInteger endLength = [endString length];
    
    NSScanner *scanner = [NSScanner scannerWithString:string];
    [scanner setCharactersToBeSkipped:nil];
    [scanner setCaseSensitive:!ignoreCase];
    [scanner setScanLocation:parseRange.location];
    
    while(![scanner isAtEnd] && ([scanner scanLocation] < NSMaxRange(parseRange))) {
        if ([self isCancelled]) { return @[]; }
        
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
- (nonnull NSArray<NSValue *> *)rangesOfRegularExpressionString:(nonnull NSString *)regexStr ignoreCase:(BOOL)ignoreCase string:(nonnull NSString *)string range:(NSRange)parseRange
// ------------------------------------------------------
{
    if ([regexStr length] == 0) { return @[]; }
    
    NSMutableArray<NSValue *> *ranges = [NSMutableArray array];
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
    
    __weak typeof(self) weakSelf = self;
    [regex enumerateMatchesInString:string
                            options:NSMatchingWithTransparentBounds | NSMatchingWithoutAnchoringBounds
                              range:parseRange
                         usingBlock:^(NSTextCheckingResult *result, NSMatchingFlags flags, BOOL *stop)
     {
         if ([weakSelf isCancelled]) {
             *stop = YES;
             return;
         }
         
         [ranges addObject:[NSValue valueWithRange:[result range]]];
     }];
    
    return ranges;
}


// ------------------------------------------------------
/// 指定された開始／終了文字列を正規表現として検索し、位置を返す
- (nonnull NSArray<NSValue *> *)rangesOfRegularExpressionBeginString:(nonnull NSString *)beginString endString:(nonnull NSString *)endString ignoreCase:(BOOL)ignoreCase string:(nonnull NSString *)string range:(NSRange)parseRange
// ------------------------------------------------------
{
    NSMutableArray<NSValue *> *ranges = [NSMutableArray array];
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
    
    __weak typeof(self) weakSelf = self;
    [beginRegex enumerateMatchesInString:string
                                 options:NSMatchingWithTransparentBounds | NSMatchingWithoutAnchoringBounds
                                   range:parseRange
                              usingBlock:^(NSTextCheckingResult *result, NSMatchingFlags flags, BOOL *stop)
     {
         if ([weakSelf isCancelled]) {
             *stop = YES;
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
/// クオートで囲まれた文字列とともにコメントをカラーリング
- (nonnull NSDictionary<NSString *, NSArray<NSValue *> *> *)extractCommentsWithQuotesFromString:(nonnull NSString *)string range:(NSRange)parseRange
// ------------------------------------------------------
{
    NSDictionary<NSString *, NSString *> *quoteTypes = [self pairedQuoteTypes];
    NSMutableArray<NSDictionary<NSString *, id> *> *positions = [NSMutableArray array];
    
    // コメント定義の位置配列を生成
    if ([self blockCommentDelimiters]) {
        NSString *beginDelimiter = [self blockCommentDelimiters][CEBeginDelimiterKey];
        NSArray<NSValue *> *beginRanges = [self rangesOfString:beginDelimiter ignoreCase:NO string:string range:parseRange];
        for (NSValue *rangeValue in beginRanges) {
            NSRange range = [rangeValue rangeValue];
            
            [positions addObject:@{QCPairKindKey: QCBlockCommentKind,
                                   QCStartEndKey: @(QCStart),
                                   QCLocationKey: @(range.location),
                                   QCLengthKey: @([beginDelimiter length])}];
        }
        
        NSString *endDelimiter = [self blockCommentDelimiters][CEEndDelimiterKey];
        NSArray<NSValue *> *endRanges = [self rangesOfString:endDelimiter ignoreCase:NO string:string range:parseRange];
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
        NSArray<NSValue *> *ranges = [self rangesOfString:delimiter ignoreCase:NO string:string range:parseRange];
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
        NSArray<NSValue *> *ranges = [self rangesOfString:quote ignoreCase:NO string:string range:parseRange];
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
    NSMutableDictionary<NSString *, NSMutableArray<NSValue *> *> *highlights = [NSMutableDictionary dictionary];
    NSUInteger startLocation = 0;
    NSUInteger seekLocalation = parseRange.location;
    NSString *searchingPairKind = nil;
    BOOL isContinued = NO;
    
    for (NSDictionary<NSString *, id> *position in positions) {
        QCStartEndType startEnd = [position[QCStartEndKey] unsignedIntegerValue];
        NSUInteger location = [position[QCLocationKey] unsignedIntegerValue];
        isContinued = NO;
        
        // search next begin delimiter
        if (!searchingPairKind) {
            if (startEnd != QCEnd && location >= seekLocalation) {
                searchingPairKind = position[QCPairKindKey];
                startLocation = location;
            }
            continue;
        }
        
        // search corresponding end delimiter
        if (([position[QCPairKindKey] isEqualToString:searchingPairKind]) &&
            ((startEnd == QCStartEnd) || (startEnd == QCEnd)))
        {
            NSUInteger endLocation = (location + [position[QCLengthKey] unsignedIntegerValue]);
            
            NSString *syntaxType = quoteTypes[searchingPairKind] ? : CESyntaxCommentsKey;
            NSRange range = NSMakeRange(startLocation, endLocation - startLocation);
            
            if (highlights[syntaxType]) {
                [highlights[syntaxType] addObject:[NSValue valueWithRange:range]];
            } else {
                highlights[syntaxType] = [NSMutableArray arrayWithObject:[NSValue valueWithRange:range]];
            }
            
            searchingPairKind = nil;
            seekLocalation = endLocation;
            continue;
        }
        
        if (startLocation < NSMaxRange(parseRange)) {
            isContinued = YES;
        }
    }
    
    // 「終わり」がなければ最後までカラーリングする
    if (isContinued) {
        NSString *syntaxType = quoteTypes[searchingPairKind] ? : CESyntaxCommentsKey;
        NSRange range = NSMakeRange(startLocation, NSMaxRange(parseRange) - startLocation);
        
        if (highlights[syntaxType]) {
            [highlights[syntaxType] addObject:[NSValue valueWithRange:range]];
        } else {
            highlights[syntaxType] = [NSMutableArray arrayWithObject:[NSValue valueWithRange:range]];
        }
    }
    
    return [highlights copy];
}


// ------------------------------------------------------
/// 対象範囲の全てのカラーリング範囲配列を返す
- (nonnull NSDictionary<NSString *, NSArray<NSValue *> *> *)extractAllHighlightsFromString:(nonnull NSString *)string range:(NSRange)parseRange
// ------------------------------------------------------
{
    NSMutableDictionary<NSString *, NSArray<NSValue *> *> *highlights = [NSMutableDictionary dictionary];  // key: highlight type
    
    // Keywords > Commands > Types > Attributes > Variables > Values > Numbers > Strings > Characters > Comments
    for (NSString *syntaxKey in kSyntaxDictKeys) {
        // update indicator sheet message
        if ([self beginParsingBlock]) {
            [self beginParsingBlock](NSLocalizedString(syntaxKey, nil));
        }
        
        NSArray<NSDictionary<NSString *, id> *> *strDicts = [self highlightDictionary][syntaxKey];
        if ([strDicts count] == 0) {
            if ([self didProgress]) {
                [self didProgress](kPerCompoIncrement);
            }
            continue;
        }
        
        CGFloat indicatorDelta = kPerCompoIncrement / [strDicts count];
        
        NSMutableDictionary<NSNumber *, NSMutableArray<NSString *> *> *simpleWordsDict = [NSMutableDictionary dictionaryWithCapacity:40];
        NSMutableDictionary<NSNumber *, NSMutableArray<NSString *> *> *simpleICWordsDict = [NSMutableDictionary dictionaryWithCapacity:40];
        NSMutableArray<NSValue *> *ranges = [NSMutableArray arrayWithCapacity:10];
        
        dispatch_apply([strDicts count], dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^(size_t i) {
            // skip loop if cancelled
            if ([self isCancelled]) { return; }
            
            @autoreleasepool {
                NSDictionary<NSString *, id> *strDict = strDicts[i];
                
                NSString *beginStr = strDict[CESyntaxBeginStringKey];
                NSString *endStr = strDict[CESyntaxEndStringKey];
                BOOL ignoresCase = [strDict[CESyntaxIgnoreCaseKey] boolValue];
                
                if ([beginStr length] == 0) { return; }  // continue
                
                NSArray<NSValue *> *extractedRanges = @[];
                
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
                            NSMutableDictionary<NSNumber *, NSMutableArray<NSString *> *> *dict = ignoresCase ? simpleICWordsDict : simpleWordsDict;
                            NSMutableArray<NSString *> *wordsArray = dict[len];
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
            if ([self didProgress]) {
                [self didProgress](indicatorDelta);
            }
        });
        
        if ([self isCancelled]) { return @{}; }
        
        if ([simpleWordsDict count] > 0 || [simpleICWordsDict count] > 0) {
            [ranges addObjectsFromArray:[self rangesOfSimpleWords:simpleWordsDict
                                                  ignoreCaseWords:simpleICWordsDict
                                                          charSet:[self simpleWordsCharacterSets][syntaxKey]
                                                           string:string
                                                            range:parseRange]];
        }
        // store range array
        highlights[syntaxKey] = ranges;
        
    } // end-for (syntaxKey)
    
    if ([self isCancelled]) { return @{}; }
    
    // コメントと引用符
    if ([self beginParsingBlock]) {
        [self beginParsingBlock](NSLocalizedString(@"comments and quoted texts", nil));
    }
    [highlights addEntriesFromDictionary:[self extractCommentsWithQuotesFromString:string range:parseRange]];
    if ([self didProgress]) {
        [self didProgress](kPerCompoIncrement);
    }
    
    if ([self isCancelled]) { return @{}; }
    
    return [highlights copy];
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
