/*
 ==============================================================================
 CESyntaxParser
 
 CotEditor
 http://coteditor.com
 
 Created on 2004-12-22 by nakamuxu
 encoding="UTF-8"
 ------------------------------------------------------------------------------
 
 © 2004-2007 nakamuxu
 © 2014 CotEditor Project
 
 This program is free software; you can redistribute it and/or modify it under
 the terms of the GNU General Public License as published by the Free Software
 Foundation; either version 2 of the License, or (at your option) any later
 version.
 
 This program is distributed in the hope that it will be useful, but WITHOUT
 ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS
 FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.
 
 You should have received a copy of the GNU General Public License along with
 this program; if not, write to the Free Software Foundation, Inc., 59 Temple
 Place - Suite 330, Boston, MA  02111-1307, USA.
 
 ==============================================================================
 */

#import "CESyntaxParser.h"
#import "CETextViewProtocol.h"
#import "CESyntaxManager.h"
#import "CEIndicatorSheetController.h"
#import "RegexKitLite.h"
#import "NSString+MD5.h"
#import "constants.h"


// local constants (QC might abbr of Quotes/Comment)
static NSString *const ColorKey = @"ColorKey";
static NSString *const RangeKey = @"RangeKey";
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

@property (nonatomic) NSLayoutManager *layoutManager;
@property (nonatomic, getter=isPrinting) BOOL printing;  // プリント中かどうかを返す（[NSGraphicsContext currentContextDrawingToScreen] は真を返す時があるため、専用フラグを使う）

@property (nonatomic) BOOL hasSyntaxHighlighting;
@property (atomic, copy) NSDictionary *coloringDictionary;
@property (atomic, copy) NSDictionary *simpleWordsCharacterSets;
@property (atomic, copy) NSDictionary *pairedQuoteTypes;  // dict for quote pair to extract with comment
@property (atomic, copy) NSArray *cacheColorings;  // extracting results cache of the last whole string coloring
@property (atomic, copy) NSString *cacheHash;  // MD5 hash
@property (atomic) dispatch_queue_t coloringQueue;

@property (atomic) CEIndicatorSheetController *indicatorController;


// readonly
@property (readwrite, nonatomic, copy) NSString *styleName;
@property (readwrite, nonatomic, copy) NSArray *completionWords;
@property (readwrite, nonatomic, copy) NSCharacterSet *firstCompletionCharacterSet;
@property (readwrite, nonatomic, copy) NSString *inlineCommentDelimiter;
@property (readwrite, nonatomic, copy) NSDictionary *blockCommentDelimiters;
@property (readwrite, nonatomic, getter=isNone) BOOL none;

@end




#pragma mark -

@implementation CESyntaxParser

static NSArray *kSyntaxDictKeys;
static CGFloat kPerCompoIncrement;


#pragma mark Class Methods

// ------------------------------------------------------
/// クラスの初期化
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
        kPerCompoIncrement = 98.0 / (kSizeOfAllColoringKeys + 1);
    });
}



#pragma mark Public Methods

//=======================================================
// Public method
//
//=======================================================

// ------------------------------------------------------
/// designated initializer
- (instancetype)initWithStyleName:(NSString *)styleName layoutManager:(NSLayoutManager *)layoutManager isPrinting:(BOOL)isPrinting
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
            
            /// カラーリング辞書から補完文字列配列を生成
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
                    [completionWords sortedArrayUsingSelector:@selector(compare:)];
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
                    } // ==== end-autoreleasepool
                }
                _simpleWordsCharacterSets = characterSets;
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
                
                /// シンタックスカラーリングが必要かをキャッシュ
                _hasSyntaxHighlighting = ((count > 0) || _inlineCommentDelimiter || _blockCommentDelimiters);
            }
            
            // queue
            _coloringQueue = dispatch_queue_create("com.coteditor.CotEditor.ColoringQueue", DISPATCH_QUEUE_SERIAL);
            
            // store as properties
            _styleName = styleName;
            _coloringDictionary = [coloringDictionary copy];
            
        } else {
            return nil;
        }
        
        _layoutManager = layoutManager;
        _printing = isPrinting;
    }
    return self;
}


// ------------------------------------------------------
/// 全体をカラーリング
- (void)colorAllString:(NSString *)wholeString
// ------------------------------------------------------
{
    if ([wholeString length] == 0) { return; }
    
    NSRange range = NSMakeRange(0, [wholeString length]);
    
    // 前回の全文カラーリングと内容が全く同じ場合はキャッシュを使う
    if ([[wholeString MD5] isEqualToString:[self cacheHash]]) {
        [self applyColorings:[self cacheColorings] range:range];
    } else {
        [self colorString:wholeString range:range onMainThread:[self isPrinting]];
    }
}

// ------------------------------------------------------
/// 表示されている部分をカラーリング
- (void)colorVisibleRange:(NSRange)range wholeString:(NSString *)wholeString
// ------------------------------------------------------
{
    if ([wholeString length] == 0) { return; }
    
    NSRange wholeRange = NSMakeRange(0, [wholeString length]);
    NSRange effectiveRange;
    NSUInteger start = range.location;
    NSUInteger end = NSMaxRange(range) - 1;

    // 直前／直後が同色ならカラーリング範囲を拡大する
    [[self layoutManager] temporaryAttributesAtCharacterIndex:start
                                        longestEffectiveRange:&effectiveRange
                                                      inRange:wholeRange];
    start = effectiveRange.location;
    
    [[self layoutManager] temporaryAttributesAtCharacterIndex:end
                                        longestEffectiveRange:&effectiveRange
                                                      inRange:wholeRange];
    end = MIN(NSMaxRange(effectiveRange), NSMaxRange(wholeRange));
    
    // 表示領域の前もある程度カラーリングの対象に含める
    start -= MIN(start, [[NSUserDefaults standardUserDefaults] integerForKey:CEDefaultColoringRangeBufferLengthKey]);
    
    NSRange coloringRange = NSMakeRange(start, end - start);
    coloringRange = [wholeString lineRangeForRange:coloringRange];
    
    [self colorString:wholeString range:coloringRange onMainThread:YES];
}


// ------------------------------------------------------
/// アウトラインメニュー用の配列を生成し、返す
- (NSArray *)outlineMenuArrayWithWholeString:(NSString *)wholeString
// ------------------------------------------------------
{
    if (([wholeString length] == 0) || [self isNone]) {
        return @[];
    }
    
    __block NSMutableArray *outlineMenuDicts = [NSMutableArray array];
    
    NSUInteger menuTitleMaxLength = [[NSUserDefaults standardUserDefaults] integerForKey:CEDefaultOutlineMenuMaxLengthKey];
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
             
             // セパレータのとき
             if ([template isEqualToString:CESeparatorString]) {
                 [outlineMenuDicts addObject:@{CEOutlineItemRangeKey: [NSValue valueWithRange:range],
                                               CEOutlineItemTitleKey: CESeparatorString,
                                               CEOutlineItemSortKeyKey: @(range.location)}];
                 return;
             }
             
             // メニュー項目タイトル
             NSString *title;
             
             if ([template length] == 0) {
                 // パターン定義なし
                 title = [wholeString substringWithRange:range];;
                 
             } else {
                 // マッチ文字列をテンプレートで置換
                 title = [regex replacementStringForResult:result
                                                  inString:wholeString
                                                    offset:0
                                                  template:template];
                 
                 
                 // マッチした範囲の開始位置の行を得る
                 NSUInteger lineNum = 0, index = 0;
                 while (index <= range.location) {
                     index = NSMaxRange([wholeString lineRangeForRange:NSMakeRange(index, 0)]);
                     lineNum++;
                 }
                 //行番号（$LN）置換
                 title = [title stringByReplacingOccurrencesOfString:@"(?<!\\\\)\\$LN"
                                                          withString:[NSString stringWithFormat:@"%tu", lineNum]
                                                             options:NSRegularExpressionSearch
                                                               range:NSMakeRange(0, [title length])];
             }
             
             // 改行またはタブをスペースに置換
             title = [title stringByReplacingOccurrencesOfString:@"\n" withString:@" "];
             title = [title stringByReplacingOccurrencesOfString:@"\t" withString:@"    "];
             
             // 長過ぎる場合は末尾を省略
             if ([title length] > menuTitleMaxLength) {
                 title = [NSString stringWithFormat:@"%@ ...", [title substringToIndex:menuTitleMaxLength]];
             }
             
             // ボールド
             BOOL isBold = [definition[CESyntaxBoldKey] boolValue];
             // イタリック
             BOOL isItalic = [definition[CESyntaxItalicKey] boolValue];
             // アンダーライン
             NSUInteger underlineMask = [definition[CESyntaxUnderlineKey] boolValue] ?
             (NSUnderlineByWordMask | NSUnderlinePatternSolid | NSUnderlineStyleThick) : 0;
             
             // 辞書生成
             [outlineMenuDicts addObject:@{CEOutlineItemRangeKey: [NSValue valueWithRange:range],
                                           CEOutlineItemTitleKey: title,
                                           CEOutlineItemSortKeyKey: @(range.location),
                                           CEOutlineItemFontBoldKey: @(isBold),
                                           CEOutlineItemFontItalicKey: @(isItalic),
                                           CEOutlineItemUnderlineMaskKey: @(underlineMask)}];
         }];
    }
    
    if ([outlineMenuDicts count] > 0) {
        // 出現順にソート
        NSSortDescriptor *descriptor = [[NSSortDescriptor alloc] initWithKey:CEOutlineItemSortKeyKey
                                                                   ascending:YES
                                                                    selector:@selector(compare:)];
        [outlineMenuDicts sortUsingDescriptors:@[descriptor]];
        
        // 冒頭のアイテムを追加
        [outlineMenuDicts insertObject:@{CEOutlineItemRangeKey: [NSValue valueWithRange:NSMakeRange(0, 0)],
                                         CEOutlineItemTitleKey: NSLocalizedString(@"<Outline Menu>", nil),
                                         CEOutlineItemSortKeyKey: @0U}
                               atIndex:0];
    }
    
    return outlineMenuDicts;
}



#pragma mark Private Methods

//=======================================================
// Private method
//
//=======================================================

// ------------------------------------------------------
/// 指定された文字列をそのまま検索し、位置を返す
- (NSArray *)rangesOfSimpleWords:(NSDictionary *)wordsDict ignoreCaseWords:(NSDictionary *)icWordsDict charSet:(NSCharacterSet *)charSet string:(NSString *)string
// ------------------------------------------------------
{
    NSMutableArray *ranges = [NSMutableArray array];
    CEIndicatorSheetController *indicator = [self indicatorController];
    
    NSScanner *scanner = [NSScanner scannerWithString:string];
    [scanner setCaseSensitive:YES];
    
    while (![scanner isAtEnd]) {
        if ([indicator isCancelled]) { return nil; }
        
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
- (NSArray *)rangesOfString:(NSString *)searchString ignoreCase:(BOOL)ignoreCase string:(NSString *)string
// ------------------------------------------------------
{
    if ([searchString length] == 0) { return nil; }
    
    NSMutableArray *ranges = [NSMutableArray array];
    CEIndicatorSheetController *indicator = [self indicatorController];
    NSUInteger length = [searchString length];
    
    NSScanner *scanner = [NSScanner scannerWithString:string];
    [scanner setCharactersToBeSkipped:nil];
    [scanner setCaseSensitive:!ignoreCase];
    
    while (![scanner isAtEnd]) {
        if ([indicator isCancelled]) { return nil; }
        
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
- (NSArray *)rangesOfBeginString:(NSString *)beginString endString:(NSString *)endString ignoreCase:(BOOL)ignoreCase string:(NSString *)string
// ------------------------------------------------------
{
    if ([beginString length] == 0) { return nil; }
    
    NSMutableArray *ranges = [NSMutableArray array];
    CEIndicatorSheetController *indicator = [self indicatorController];
    NSUInteger endLength = [endString length];
    
    NSScanner *scanner = [NSScanner scannerWithString:string];
    [scanner setCharactersToBeSkipped:nil];
    [scanner setCaseSensitive:!ignoreCase];
    
    while (![scanner isAtEnd]) {
        if ([indicator isCancelled]) { return nil; }
        
        @autoreleasepool {
            [scanner scanUpToString:beginString intoString:nil];
            NSUInteger startLocation = [scanner scanLocation];
            
            if (![scanner scanString:beginString intoString:nil]) { break; }
            
            if (isCharacterEscaped(string, startLocation)) { continue; }
            
            // find end string
            while (![scanner isAtEnd]) {
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
- (NSArray *)rangesOfRegularExpressionString:(NSString *)regexStr ignoreCase:(BOOL)ignoreCase string:(NSString *)string
// ------------------------------------------------------
{
    if ([regexStr length] == 0) { return nil; }
    
    __block NSMutableArray *ranges = [NSMutableArray array];
    CEIndicatorSheetController *indicator = [self indicatorController];
    uint32_t options = RKLMultiline | (ignoreCase ? RKLCaseless : 0);
    NSError *error = nil;
    
    [string enumerateStringsMatchedByRegex:regexStr
                                   options:options
                                   inRange:NSMakeRange(0, [string length])
                                     error:&error
                        enumerationOptions:RKLRegexEnumerationCapturedStringsNotRequired
                                usingBlock:^(NSInteger captureCount,
                                             NSString *const __unsafe_unretained *capturedStrings,
                                             const NSRange *capturedRanges,
                                             volatile BOOL *const stop)
     {
         if ([indicator isCancelled]) {
             *stop = YES;
             return;
         }
         
         NSRange range = capturedRanges[0];
         [ranges addObject:[NSValue valueWithRange:range]];
     }];
    
    if (error && ![[error userInfo][RKLICURegexErrorNameErrorKey] isEqualToString:@"U_ZERO_ERROR"]) {
        // 何もしない
        NSLog(@"ERROR: %@", [error localizedDescription]);
        return nil;
    }
    
    return ranges;
}


// ------------------------------------------------------
/// 指定された開始／終了文字列を正規表現として検索し、位置を返す
- (NSArray *)rangesOfRegularExpressionBeginString:(NSString *)beginString endString:(NSString *)endString ignoreCase:(BOOL)ignoreCase string:(NSString *)string
// ------------------------------------------------------
{
    __block NSMutableArray *ranges = [NSMutableArray array];
    CEIndicatorSheetController *indicator = [self indicatorController];
    uint32_t options = RKLMultiline | (ignoreCase ? RKLCaseless : 0);
    NSError *error = nil;
    
    [string enumerateStringsMatchedByRegex:beginString
                                   options:options
                                   inRange:NSMakeRange(0, [string length])
                                     error:&error
                        enumerationOptions:RKLRegexEnumerationCapturedStringsNotRequired
                                usingBlock:^(NSInteger captureCount,
                                             NSString *const __unsafe_unretained *capturedStrings,
                                             const NSRange *capturedRanges,
                                             volatile BOOL *const stop)
     {
         if ([indicator isCancelled]) {
             *stop = YES;
             return;
         }
         
         NSRange beginRange = capturedRanges[0];
         NSRange endRange = [string rangeOfRegex:endString
                                         options:options
                                         inRange:NSMakeRange(NSMaxRange(beginRange),
                                                             [string length] - NSMaxRange(beginRange))
                                         capture:0
                                           error:nil];
         
         if (endRange.location != NSNotFound) {
             [ranges addObject:[NSValue valueWithRange:NSUnionRange(beginRange, endRange)]];
         }
     }];
    
    if (error && ![[error userInfo][RKLICURegexErrorNameErrorKey] isEqualToString:@"U_ZERO_ERROR"]) {
        // 何もしない
        NSLog(@"ERROR: %@", [error localizedDescription]);
        return nil;
    }
    
    return ranges;
}


// ------------------------------------------------------
/// クオートで囲まれた文字列とともにコメントをカラーリング
- (NSArray *)extractCommentsWithQuotesFromString:(NSString *)string
// ------------------------------------------------------
{
    NSDictionary *quoteTypes = [self pairedQuoteTypes];
    NSMutableArray *positions = [NSMutableArray array];
    
    // コメント定義の位置配列を生成
    if ([self blockCommentDelimiters]) {
        NSString *beginDelimiter = [self blockCommentDelimiters][CEBeginDelimiterKey];
        NSArray *beginRanges = [self rangesOfString:beginDelimiter ignoreCase:NO string:string];
        for (NSValue *rangeValue in beginRanges) {
            NSRange range = [rangeValue rangeValue];
            
            [positions addObject:@{QCPairKindKey: QCBlockCommentKind,
                                   QCStartEndKey: @(QCStart),
                                   QCLocationKey: @(range.location),
                                   QCLengthKey: @([beginDelimiter length])}];
        }
        
        NSString *endDelimiter = [self blockCommentDelimiters][CEEndDelimiterKey];
        NSArray *endRanges = [self rangesOfString:endDelimiter ignoreCase:NO string:string];
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
        NSArray *ranges = [self rangesOfString:delimiter ignoreCase:NO string:string];
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
        NSArray *ranges = [self rangesOfString:quote ignoreCase:NO string:string];
        for (NSValue *rangeValue in ranges) {
            NSRange range = [rangeValue rangeValue];
            
            [positions addObject:@{QCPairKindKey: quote,
                                   QCStartEndKey: @(QCStartEnd),
                                   QCLocationKey: @(range.location),
                                   QCLengthKey: @([quote length])}];
        }
    }
    
    // コメントもクォートもなければ、もどる
    if ([positions count] == 0) { return nil; }
    
    // 出現順にソート
    NSSortDescriptor *positionSort = [NSSortDescriptor sortDescriptorWithKey:QCLocationKey ascending:YES];
    NSSortDescriptor *prioritySort = [NSSortDescriptor sortDescriptorWithKey:QCStartEndKey ascending:YES];
    [positions sortUsingDescriptors:@[positionSort, prioritySort]];
    
    // カラーリング範囲を走査
    NSMutableArray *colorings = [NSMutableArray array];
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
            
            [colorings addObject:@{ColorKey: colorType,
                                   RangeKey: [NSValue valueWithRange:range]}];
            
            searchPairKind = nil;
            continue;
        }
        
        isContinued = YES;
    }
    
    // 「終わり」がなければ最後までカラーリングする
    if (isContinued) {
        NSString *colorType = quoteTypes[searchPairKind] ? : CESyntaxCommentsKey;
        NSRange range = NSMakeRange(startLocation, [string length] - startLocation);
        
        [colorings addObject:@{ColorKey: colorType,
                               RangeKey: [NSValue valueWithRange:range]}];
    }
    
    return colorings;
}


// ------------------------------------------------------
/// 不可視文字表示時にカラーリング範囲配列を返す
- (NSArray *)extractControlCharsFromString:(NSString *)string
// ------------------------------------------------------
{
    NSMutableArray *colorings = [NSMutableArray array];
    NSCharacterSet *controlCharacterSet = [NSCharacterSet controlCharacterSet];
    NSScanner *scanner = [NSScanner scannerWithString:string];

    while (![scanner isAtEnd]) {
        [scanner scanUpToCharactersFromSet:controlCharacterSet intoString:nil];
        NSUInteger location = [scanner scanLocation];
        NSString *control;
        if ([scanner scanCharactersFromSet:controlCharacterSet intoString:&control]) {
            NSRange range = NSMakeRange(location, [control length]);
            
            [colorings addObject:@{ColorKey: InvisiblesType,
                                   RangeKey: [NSValue valueWithRange:range]}];
        }
    }
    
    return colorings;
}


// ------------------------------------------------------
/// 対象範囲の全てのカラーリング範囲配列を返す
- (NSArray *)extractAllSyntaxFromString:(NSString *)string
// ------------------------------------------------------
{
    NSMutableArray *colorings = [NSMutableArray array];  // ColorKey と RangeKey の dict配列
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
        NSMutableArray *targetRanges = [NSMutableArray arrayWithCapacity:10];
        
        for (NSDictionary *strDict in strDicts) {
            @autoreleasepool {
                NSString *beginStr = strDict[CESyntaxBeginStringKey];
                NSString *endStr = strDict[CESyntaxEndStringKey];
                BOOL ignoresCase = [strDict[CESyntaxIgnoreCaseKey] boolValue];
                
                if ([beginStr length] == 0) { continue; }
                
                if ([strDict[CESyntaxRegularExpressionKey] boolValue]) {
                    if ([endStr length] > 0) {
                        [targetRanges addObjectsFromArray:
                         [self rangesOfRegularExpressionBeginString:beginStr
                                                          endString:endStr
                                                         ignoreCase:ignoresCase
                                                             string:string]];
                    } else {
                        [targetRanges addObjectsFromArray:
                         [self rangesOfRegularExpressionString:beginStr
                                                    ignoreCase:ignoresCase
                                                        string:string]];
                    }
                } else {
                    if ([endStr length] > 0) {
                        [targetRanges addObjectsFromArray:
                         [self rangesOfBeginString:beginStr
                                         endString:endStr
                                        ignoreCase:ignoresCase
                                            string:string]];
                    } else {
                        NSNumber *len = @([beginStr length]);
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
                // キャンセルされたら現在実行中の抽出は破棄して戻る
                [indicator progressIndicator:indicatorDelta];
                
                // インジケータ更新
                if ([indicator isCancelled]) { return nil; }
                
            } // ==== end-autoreleasepool
        } // end-for (strDict)
        
        if ([simpleWordsDict count] > 0 || [simpleICWordsDict count] > 0) {
            [targetRanges addObjectsFromArray:
             [self rangesOfSimpleWords:simpleWordsDict
                       ignoreCaseWords:simpleICWordsDict
                               charSet:[self simpleWordsCharacterSets][syntaxKey]
                                string:string]];
        }
        // カラーとrangeのペアを格納
        for (NSValue *value in targetRanges) {
            [colorings addObject:@{ColorKey: syntaxKey,
                                   RangeKey: value}];
        }
    } // end-for (syntaxKey)
    
    if ([indicator isCancelled]) { return nil; }
    
    // コメントと引用符
    if (indicator) {
        dispatch_async(dispatch_get_main_queue(), ^{
            [indicator setInformativeText:[NSString stringWithFormat:NSLocalizedString(@"Extracting %@…", nil),
                                           NSLocalizedString(@"comments and quoted texts", nil)]];
        });
    }
    [colorings addObjectsFromArray:[self extractCommentsWithQuotesFromString:string]];
    [indicator progressIndicator:kPerCompoIncrement];
    
    if ([indicator isCancelled]) { return nil; }
    
    // 不可視文字の追加
    [colorings addObjectsFromArray:[self extractControlCharsFromString:string]];
    
    return colorings;
}


// ------------------------------------------------------
/// カラーリングを実行
- (void)colorString:(NSString *)wholeString range:(NSRange)coloringRange onMainThread:(BOOL)onMainThread
// ------------------------------------------------------
{
    // カラーリング対象の文字列
    NSString *coloringString = [wholeString substringWithRange:coloringRange];
    if ([coloringString length] == 0) { return; }
    
    // カラーリング不要なら不可視文字のカラーリングだけして戻る
    if (![self hasSyntaxHighlighting]) {
        [self applyColorings:[self extractControlCharsFromString:coloringString] range:coloringRange];
        return;
    }
    
    // 規定の文字数以上の場合にはカラーリングインジケータシートを表示
    // （ただし、CEDefaultShowColoringIndicatorTextLengthKey が「0」の時は表示しない）
    CEIndicatorSheetController *indicator = nil;
    NSUInteger indicatorThreshold = [[NSUserDefaults standardUserDefaults] integerForKey:CEDefaultShowColoringIndicatorTextLengthKey];
    if (![self isPrinting] && (indicatorThreshold > 0) && (coloringRange.length > indicatorThreshold)) {
        NSWindow *documentWindow = [[[self layoutManager] firstTextView] window];
        indicator = [[CEIndicatorSheetController alloc] initWithMessage:NSLocalizedString(@"Coloring text…", nil)];
        [self setIndicatorController:indicator];
        [[self indicatorController] beginSheetForWindow:documentWindow];
    }
    
    // 実行スレッドを決定
    dispatch_queue_t queue = onMainThread ? dispatch_get_main_queue() : [self coloringQueue];
    
    __weak typeof(self) weakSelf = self;
    dispatch_async(queue, ^{
        typeof(self) strongSelf = weakSelf;
        NSArray *colorings = [strongSelf extractAllSyntaxFromString:coloringString];
        
        // 全文を抽出した場合は抽出結果をキャッシュする
        if (([colorings count] > 0) && (coloringRange.length == [wholeString length])) {
            [strongSelf setCacheColorings:colorings];
            [strongSelf setCacheHash:[wholeString MD5]];
        }
        
        // インジケータシートのメッセージを更新
        if (colorings && indicator) {
            [indicator setInformativeText:NSLocalizedString(@"Applying colors to text", nil)];
        }
        
        // 描画をメインスレッドで実行
        dispatch_async(dispatch_get_main_queue(), ^{
            // すでにエディタの文字列が解析した文字列から変化しているときは危険なのでカラーリングを諦める
            BOOL isStringUpdated = ![[[[strongSelf layoutManager] textStorage] string] isEqualToString:wholeString];
            
            if (colorings && !isStringUpdated) {
                // カラーを適用する（ループ中に徐々に適用させると文字がチラ付くので、抽出が終わってから一気に適用する）
                [strongSelf applyColorings:colorings range:coloringRange];
            }
            
            // インジーケータシートを片づける
            if (indicator) {
                [indicator endSheet];
                [strongSelf setIndicatorController:nil];
            }
        });
    });
}


// ------------------------------------------------------
/// 抽出したカラー範囲配列を書類に適用する
- (void)applyColorings:(NSArray *)colorings range:(NSRange)coloringRange
// ------------------------------------------------------
{
    NSLayoutManager *layoutManager = [self layoutManager];
    CETheme *theme = [(NSTextView<CETextViewProtocol> *)[layoutManager firstTextView] theme];
    BOOL isPrinting = [self isPrinting];
    BOOL showsInvisibles = [layoutManager showsControlCharacters];
    
    // 現在あるカラーリングを削除
    if (isPrinting) {
        [[layoutManager firstTextView] setTextColor:[theme textColor] range:coloringRange];
    } else {
        [layoutManager removeTemporaryAttribute:NSForegroundColorAttributeName
                              forCharacterRange:coloringRange];
    }
    
    // カラーリング実行
    for (NSDictionary *coloring in colorings) {
        @autoreleasepool {
            NSColor *color;
            NSString *colorType = coloring[ColorKey];
            if ([colorType isEqualToString:InvisiblesType]) {
                if (!showsInvisibles) { continue; }
                
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
            
            NSRange range = [coloring[RangeKey] rangeValue];
            range.location += coloringRange.location;
            
            if (isPrinting) {
                [[layoutManager firstTextView] setTextColor:color range:range];
            } else {
                [layoutManager addTemporaryAttribute:NSForegroundColorAttributeName
                                               value:color forCharacterRange:range];
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
