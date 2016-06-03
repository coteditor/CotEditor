/*
 
 CESyntaxHighlightParseOperation.m
 
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

#import "CESyntaxHighlightParseOperation.h"
#import "Constants.h"

#import "NSString+CEAdditions.h"


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


@interface CESyntaxHighlightParseOperation ()

@property (nonatomic, nullable, copy) NSDictionary<NSString *, id> *highlightDictionary;
@property (nonatomic, nullable, copy) NSDictionary<NSString *, NSCharacterSet *> *simpleWordsCharacterSets;
@property (nonatomic, nullable, copy) NSDictionary<NSString *, NSString *> *pairedQuoteTypes;  // dict for quote pair to extract with comment
@property (nonatomic, nullable, copy) NSString *inlineCommentDelimiter;
@property (nonatomic, nullable, copy) NSDictionary<NSString *, NSString *> *blockCommentDelimiters;

// readonly
@property (readwrite, nonatomic, nullable, copy) NSDictionary<NSString *, NSArray<NSValue *> *> *results;

@end




#pragma mark -

@implementation CESyntaxHighlightParseOperation

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
/// disable superclass's designated initializer
- (nullable instancetype)init
//------------------------------------------------------
{
    @throw nil;
}


//------------------------------------------------------
/// runs asynchronous
- (BOOL)isAsynchronous
//------------------------------------------------------
{
    return YES;
}


//------------------------------------------------------
/// priority of operation
- (NSOperationQueuePriority)queuePriority
//------------------------------------------------------
{
    return NSOperationQueuePriorityHigh;
}



#pragma mark Public Methods

// ------------------------------------------------------
/// initialize instance
- (nonnull instancetype)initWithDictionary:(nonnull NSDictionary *)dictionary
                  simpleWordsCharacterSets:(nullable NSDictionary<NSString *, NSCharacterSet *> *)simpleWordsCharacterSets
                          pairedQuoteTypes:(nullable NSDictionary<NSString *, NSString *> *)pairedQuoteTypes
                    inlineCommentDelimiter:(nullable NSString *)inlineCommentDelimiter
                    blockCommentDelimiters:(nullable NSDictionary<NSString *, NSString *> *)blockCommentDelimiters
// ------------------------------------------------------
{
    self = [super init];
    if (self) {
        _highlightDictionary = dictionary;
        _simpleWordsCharacterSets = simpleWordsCharacterSets;
        _pairedQuoteTypes = pairedQuoteTypes;
        _inlineCommentDelimiter = inlineCommentDelimiter;
        _blockCommentDelimiters = blockCommentDelimiters;
        
        _progress = [NSProgress progressWithTotalUnitCount:[kSyntaxDictKeys count] + 2];
        __weak typeof(self) weakSelf = self;
        [_progress setCancellationHandler:^{
            [weakSelf cancel];
        }];
    }
    return self;
}


// ------------------------------------------------------
/// parse string in background and return extracted highlight ranges per syntax types
- (void)main
// ------------------------------------------------------
{
    [self setResults:[self extractAllHighlightsFromString:[self string] range:[self parseRange]]];
}



#pragma mark Private Methods

// ------------------------------------------------------
/// 指定された文字列をそのまま検索し、位置を返す
- (nullable NSArray<NSValue *> *)rangesOfSimpleWords:(nonnull NSDictionary<NSNumber *, NSArray *> *)wordsDict ignoreCaseWords:(nonnull NSDictionary<NSNumber *, NSArray *> *)icWordsDict charSet:(nonnull NSCharacterSet *)charSet string:(nonnull NSString *)string range:(NSRange)parseRange
// ------------------------------------------------------
{
    NSMutableArray<NSValue *> *ranges = [NSMutableArray array];
    
    NSScanner *scanner = [NSScanner scannerWithString:string];
    [scanner setCaseSensitive:YES];
    [scanner setScanLocation:parseRange.location];
    
    while(![scanner isAtEnd] && ([scanner scanLocation] < NSMaxRange(parseRange))) {
        if ([self isCancelled]) { return nil; }
        
        @autoreleasepool {
            NSString *scannedString = nil;
            [scanner scanUpToCharactersFromSet:charSet intoString:NULL];
            if (![scanner scanCharactersFromSet:charSet intoString:&scannedString]) { break; }
            
            NSUInteger length = [scannedString length];
            
            NSArray<NSString *> *words = wordsDict[@(length)];
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
- (nullable NSArray<NSValue *> *)rangesOfString:(nonnull NSString *)searchString string:(nonnull NSString *)string range:(NSRange)parseRange
// ------------------------------------------------------
{
    if ([searchString length] == 0) { return nil; }
    
    NSMutableArray<NSValue *> *ranges = [NSMutableArray array];
    
    NSUInteger location = parseRange.location;
    while (location != NSNotFound) {
        NSRange range = [string rangeOfString:searchString options:NSLiteralSearch
                                        range:NSMakeRange(location, NSMaxRange(parseRange) - location)];
        location = NSMaxRange(range);
        
        if (range.location == NSNotFound) { break; }
        if ([string isCharacterEscapedAt:range.location]) { continue; }
        
        [ranges addObject:[NSValue valueWithRange:range]];
    }
    
    return ranges;
}


// ------------------------------------------------------
/// 指定された開始／終了ペアの文字列を検索し、位置を返す
- (nullable NSArray<NSValue *> *)rangesOfBeginString:(nonnull NSString *)beginString endString:(nonnull NSString *)endString ignoreCase:(BOOL)ignoreCase string:(nonnull NSString *)string range:(NSRange)parseRange
// ------------------------------------------------------
{
    if ([beginString length] == 0) { return nil; }
    
    NSMutableArray<NSValue *> *ranges = [NSMutableArray array];
    NSUInteger endLength = [endString length];
    
    NSScanner *scanner = [NSScanner scannerWithString:string];
    [scanner setCharactersToBeSkipped:nil];
    [scanner setCaseSensitive:!ignoreCase];
    [scanner setScanLocation:parseRange.location];
    
    while(![scanner isAtEnd] && ([scanner scanLocation] < NSMaxRange(parseRange))) {
        if ([self isCancelled]) { return nil; }
        
        @autoreleasepool {
            [scanner scanUpToString:beginString intoString:nil];
            NSUInteger startLocation = [scanner scanLocation];
            
            if (![scanner scanString:beginString intoString:nil]) { break; }
            
            if ([string isCharacterEscapedAt:startLocation]) { continue; }
            
            // find end string
            while(![scanner isAtEnd] && ([scanner scanLocation] < NSMaxRange(parseRange))) {
                
                [scanner scanUpToString:endString intoString:nil];
                if (![scanner scanString:endString intoString:nil]) { break; }
                
                NSUInteger endLocation = [scanner scanLocation];
                
                if ([string isCharacterEscapedAt:endLocation - endLength]) { continue; }
                
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
- (nullable NSArray<NSValue *> *)rangesOfRegularExpressionString:(nonnull NSString *)regexStr ignoreCase:(BOOL)ignoreCase string:(nonnull NSString *)string range:(NSRange)parseRange
// ------------------------------------------------------
{
    if ([regexStr length] == 0) { return nil; }
    
    NSMutableArray<NSValue *> *ranges = [NSMutableArray array];
    NSRegularExpressionOptions options = NSRegularExpressionAnchorsMatchLines;
    if (ignoreCase) {
        options |= NSRegularExpressionCaseInsensitive;
    }
    
    NSError *error = nil;
    NSRegularExpression *regex = [NSRegularExpression regularExpressionWithPattern:regexStr options:options error:&error];
    if (error) {
        NSLog(@"ERROR in \"%s\"", __PRETTY_FUNCTION__);
        return nil;
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
- (nullable NSArray<NSValue *> *)rangesOfRegularExpressionBeginString:(nonnull NSString *)beginString endString:(nonnull NSString *)endString ignoreCase:(BOOL)ignoreCase string:(nonnull NSString *)string range:(NSRange)parseRange
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
        return nil;
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
        NSArray<NSValue *> *beginRanges = [self rangesOfString:beginDelimiter string:string range:parseRange];
        for (NSValue *rangeValue in beginRanges) {
            NSRange range = [rangeValue rangeValue];
            
            [positions addObject:@{QCPairKindKey: QCBlockCommentKind,
                                   QCStartEndKey: @(QCStart),
                                   QCLocationKey: @(range.location),
                                   QCLengthKey: @([beginDelimiter length])}];
        }
        
        NSString *endDelimiter = [self blockCommentDelimiters][CEEndDelimiterKey];
        NSArray<NSValue *> *endRanges = [self rangesOfString:endDelimiter string:string range:parseRange];
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
        NSArray<NSValue *> *ranges = [self rangesOfString:delimiter string:string range:parseRange];
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
        NSArray<NSValue *> *ranges = [self rangesOfString:quote string:string range:parseRange];
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
    NSUInteger seekLocation = parseRange.location;
    NSString *searchingPairKind = nil;
    BOOL isContinued = NO;
    
    for (NSDictionary<NSString *, id> *position in positions) {
        QCStartEndType startEnd = [position[QCStartEndKey] unsignedIntegerValue];
        NSUInteger location = [position[QCLocationKey] unsignedIntegerValue];
        isContinued = NO;
        
        // search next begin delimiter
        if (!searchingPairKind) {
            if (startEnd != QCEnd && location >= seekLocation) {
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
            seekLocation = endLocation;
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
    NSProgress *totalProgress = [self progress];
    
    // Keywords > Commands > Types > Attributes > Variables > Values > Numbers > Strings > Characters > Comments
    for (NSString *syntaxKey in kSyntaxDictKeys) {
        // update indicator sheet message
        [totalProgress becomeCurrentWithPendingUnitCount:1];
        dispatch_async(dispatch_get_main_queue(), ^{
            [totalProgress setLocalizedDescription:[NSString stringWithFormat:NSLocalizedString(@"Extracting %@…", nil), NSLocalizedString(syntaxKey, nil)]];
        });
        
        NSArray<NSDictionary<NSString *, id> *> *strDicts = [self highlightDictionary][syntaxKey];
        if ([strDicts count] == 0) {
            [totalProgress resignCurrent];
            continue;
        }
        
        NSProgress *childProgress = [NSProgress progressWithTotalUnitCount:[strDicts count] + 10];  // + 10 for simple words
        
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
                
                NSArray<NSValue *> *extractedRanges = nil;
                
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
                            NSString *word = ignoresCase ? [beginStr lowercaseString] : beginStr;
                            NSMutableArray<NSString *> *words = dict[len];
                            if (words) {
                                [words addObject:word];
                                
                            } else {
                                words = [NSMutableArray arrayWithObject:word];
                                dict[len] = words;
                            }
                        }
                    }
                }
                
                if (!extractedRanges) { return; }  // continue
                
                @synchronized(ranges) {
                    [ranges addObjectsFromArray:extractedRanges];
                }
            }
            
            // progress indicator
            dispatch_async(dispatch_get_main_queue(), ^{
                childProgress.completedUnitCount++;
            });
        });
        
        if ([self isCancelled]) { return @{}; }
        
        // extract simple words
        if ([simpleWordsDict count] > 0 || [simpleICWordsDict count] > 0) {
            NSArray<NSValue *> *extractedRanges = [self rangesOfSimpleWords:simpleWordsDict
                                                            ignoreCaseWords:simpleICWordsDict
                                                                    charSet:[self simpleWordsCharacterSets][syntaxKey]
                                                                     string:string
                                                                      range:parseRange];
            if (extractedRanges) {
                [ranges addObjectsFromArray:extractedRanges];
            }
        }
        // store range array
        highlights[syntaxKey] = ranges;
        
        // progress indicator
        childProgress.completedUnitCount = childProgress.totalUnitCount;
        [totalProgress resignCurrent];
        
    } // end-for (syntaxKey)
    
    if ([self isCancelled]) { return @{}; }
    
    // comments and quoted text
    dispatch_async(dispatch_get_main_queue(), ^{
        [totalProgress setLocalizedDescription:[NSString stringWithFormat:NSLocalizedString(@"Extracting %@…", nil),
                                                NSLocalizedString(@"comments and quoted texts", nil)]];
    });
    NSDictionary<NSString *, NSArray *> *commentAndQuoteRanges = [self extractCommentsWithQuotesFromString:string range:parseRange];
    for (NSString *key in commentAndQuoteRanges) {
        if (highlights[key]) {
            highlights[key] = [highlights[key] arrayByAddingObjectsFromArray:commentAndQuoteRanges[key]];
        } else {
            highlights[key] = commentAndQuoteRanges[key];
        }
    }
    
    if ([self isCancelled]) { return @{}; }
    
    NSDictionary<NSString *, NSArray<NSValue *> *> *sanitized = sanitizeHighlights(highlights);
    
    totalProgress.completedUnitCount++;  // = total - 1
    
    return sanitized;
}



#pragma mark Private Functions

// ------------------------------------------------------
/// remove duplicated coloring ranges
NSDictionary<NSString *, NSArray<NSValue *> *> *sanitizeHighlights(NSDictionary<NSString *, NSArray<NSValue *> *> *highlights)
// ------------------------------------------------------
{
    // This sanitization will reduce performance time of `applyHighlights:highlights:layoutManager:` significantly.
    // Adding temporary attribute to a layoutManager is quite sluggish,
    // so we want to remove useless highlighting ranges as many as possible beforehand.
    
    NSMutableDictionary *sanitizedHighlights = [NSMutableDictionary dictionaryWithCapacity:[highlights count]];
    NSMutableIndexSet *highlightedIndexes = [NSMutableIndexSet indexSet];
    
    for (NSString *syntaxType in [kSyntaxDictKeys reverseObjectEnumerator]) {
        NSArray<NSValue *> *ranges = highlights[syntaxType];
        NSMutableArray<NSValue *> *sanitizedRanges = [NSMutableArray array];
        
        for (NSValue *rangeValue in ranges) {
            NSRange range = [rangeValue rangeValue];
            
            if (![highlightedIndexes containsIndexesInRange:range]) {
                [sanitizedRanges addObject:rangeValue];
                [highlightedIndexes addIndexesInRange:range];
            }
        }
        
        if ([sanitizedRanges count] > 0) {
            sanitizedHighlights[syntaxType] = [sanitizedRanges copy];
        }
    }
    
    return [sanitizedHighlights copy];
}

@end
