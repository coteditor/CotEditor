/*
=================================================
CESyntaxParser
(for CotEditor)

 Copyright (C) 2004-2007 nakamuxu.
 Copyright (C) 2014 CotEditor Project
 http://coteditor.github.io
=================================================

encoding="UTF-8"
Created:2004.12.22
 
-------------------------------------------------

This program is free software; you can redistribute it and/or
modify it under the terms of the GNU General Public License
as published by the Free Software Foundation; either version 2
of the License, or (at your option) any later version.

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU General Public License for more details.

You should have received a copy of the GNU General Public License
along with this program; if not, write to the Free Software
Foundation, Inc., 59 Temple Place - Suite 330, Boston, MA  02111-1307, USA. 


=================================================
*/

#import "CESyntaxParser.h"
#import "CELayoutManager.h"
#import "CEEditorView.h"
#import "CESyntaxManager.h"
#import "CEIndicatorSheetController.h"
#import "RegexKitLite.h"
#import "DEBUG_macro.h"
#import "constants.h"


// local constants (QC might abbr of Quotes/Comment)
static NSString *const QCPositionKey = @"QCPositionKey";
static NSString *const QCPairKindKey = @"QCPairKindKey";
static NSString *const QCStartEndKey = @"QCStartEndKey";
static NSString *const QCLengthKey = @"QCLengthKey";

static NSString *const ColorKey = @"ColorKey";
static NSString *const RangeKey = @"RangeKey";

static NSString *const QCInlineCommentKind = @"QCInlineCommentKind";  // for pairKind
static NSString *const QCBlockCommentKind = @"QCBlockCommentKind";  // for pairKind
static NSString *const InvisiblesType = @"invisibles";

typedef NS_ENUM(NSUInteger, QCStartEndType) {
    QCNotUseStartEnd,
    QCStart,
    QCEnd
};

typedef NS_ENUM(NSUInteger, QCArrayFormat) {
    QCRangeFormat,
    QCDictFormat
};




@interface CESyntaxParser ()

@property (nonatomic) CELayoutManager *layoutManager;
@property (atomic) BOOL isPrinting;  // プリント中かどうかを返す（[NSGraphicsContext currentContextDrawingToScreen] は真を返す時があるため、専用フラグを使う）

@property (atomic, copy) NSDictionary *coloringDictionary;
@property (atomic, copy) NSDictionary *simpleWordsCharacterSets;
@property (atomic, copy) NSArray *cacheColorings;  // extracting results cache of the last whole string coloring
@property (atomic) NSUInteger cacheHash;
@property (atomic) dispatch_queue_t coloringQueue;

@property (atomic, copy) NSString *coloringString;  // カラーリング対象文字列　coloringsForAllSyntaxWithString: 冒頭でセットされる
@property (atomic) CEIndicatorSheetController *indicatorController;


// readonly
@property (nonatomic, copy, readwrite) NSString *syntaxStyleName;
@property (nonatomic, copy, readwrite) NSArray *completionWords;
@property (nonatomic, copy, readwrite) NSCharacterSet *firstCompletionCharacterSet;
@property (nonatomic, copy, readwrite) NSString *inlineCommentDelimiter;
@property (nonatomic, copy, readwrite) NSDictionary *blockCommentDelimiters;
@property (nonatomic, readwrite) BOOL isNone;

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
        NSMutableArray *syntaxDictKeys = [[NSMutableArray alloc] initWithCapacity:k_size_of_allColoringArrays];
        for (NSUInteger i = 0; i < k_size_of_allColoringArrays; i++) {
            [syntaxDictKeys addObject:k_SCKey_allColoringArrays[i]];
        }
        kSyntaxDictKeys = [syntaxDictKeys copy];
        
        // カラーリングインジケータの上昇幅を決定する（+1 はコメント＋引用符抽出用）
        kPerCompoIncrement = 98.0 / (k_size_of_allColoringArrays + 1);
    });
}


// ------------------------------------------------------
/// 与えられた文字列の末尾にエスケープシーケンス（バックスラッシュ）がいくつあるかを返す
+ (NSUInteger)numberOfEscapeSequencesInString:(NSString *)string
// ------------------------------------------------------
{
    NSUInteger count = 0;
    
    for (NSInteger i = [string length] - 1; i >= 0; i--) {
        if ([string characterAtIndex:i] == '\\') {
            count++;
        } else {
            break;
        }
    }
    return count;
}



#pragma mark Public Methods

//=======================================================
// Public method
//
//=======================================================

// ------------------------------------------------------
/// designated initializer
- (instancetype)initWithStyleName:(NSString *)styleName layoutManager:(CELayoutManager *)layoutManager isPrinting:(BOOL)isPrinting
// ------------------------------------------------------
{
    self = [super init];
    if (self) {
        if (!styleName || [styleName isEqualToString:NSLocalizedString(@"None", nil)]) {
            _isNone = YES;
            _syntaxStyleName = NSLocalizedString(@"None", nil);
            
        } else if ([[[CESyntaxManager sharedManager] styleNames] containsObject:styleName]) {
            _syntaxStyleName = styleName;
            _coloringDictionary = [[CESyntaxManager sharedManager] styleWithStyleName:styleName];
            
            /// カラーリング辞書から補完文字列配列を生成
            {
                NSMutableArray *completionWords = [NSMutableArray array];
                NSMutableString *firstCharsString = [NSMutableString string];
                NSArray *completionDicts = _coloringDictionary[k_SCKey_completionsArray];
                
                if (completionDicts) {
                    for (NSDictionary *dict in completionDicts) {
                        NSString *word = dict[k_SCKey_arrayKeyString];
                        [completionWords addObject:word];
                        [firstCharsString appendString:[word substringToIndex:1]];
                    }
                } else {
                    NSCharacterSet *trimCharSet = [NSCharacterSet whitespaceAndNewlineCharacterSet];
                    for (NSString *key in kSyntaxDictKeys) {
                        @autoreleasepool {
                            for (NSDictionary *wordDict in _coloringDictionary[key]) {
                                NSString *begin = [wordDict[k_SCKey_beginString] stringByTrimmingCharactersInSet:trimCharSet];
                                NSString *end = [wordDict[k_SCKey_endString] stringByTrimmingCharactersInSet:trimCharSet];
                                if (([begin length] > 0) && ([end length] == 0) && ![wordDict[k_SCKey_regularExpression] boolValue]) {
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
                    NSCharacterSet *charSet = [NSCharacterSet characterSetWithCharactersInString:firstCharsString];
                    _firstCompletionCharacterSet = charSet;
                }
            }
            
            // カラーリング辞書から単純文字列検索のときに使う characterSet の辞書を生成
            {
                NSMutableDictionary *characterSets = [NSMutableDictionary dictionary];
                NSCharacterSet *trimCharSet = [NSCharacterSet whitespaceAndNewlineCharacterSet];
                
                for (NSString *key in kSyntaxDictKeys) {
                    @autoreleasepool {
                        NSMutableCharacterSet *charSet = [NSMutableCharacterSet characterSetWithCharactersInString:k_allAlphabetChars];
                        
                        for (NSDictionary *wordDict in _coloringDictionary[key]) {
                            NSString *begin = [wordDict[k_SCKey_beginString] stringByTrimmingCharactersInSet:trimCharSet];
                            NSString *end = [wordDict[k_SCKey_endString] stringByTrimmingCharactersInSet:trimCharSet];
                            BOOL isRegex = [wordDict[k_SCKey_regularExpression] boolValue];
                            
                            if ([begin length] > 0 && [end length] == 0 && !isRegex) {
                                if ([wordDict[k_SCKey_ignoreCase] boolValue]) {
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
            
            // コメントデリミッタを設定
            NSDictionary *delimiters = _coloringDictionary[k_SCKey_commentDelimitersDict];
            if ([delimiters[k_SCKey_inlineComment] length] > 0) {
                _inlineCommentDelimiter = delimiters[k_SCKey_inlineComment];
            }
            if ([delimiters[k_SCKey_beginComment] length] > 0 && [delimiters[k_SCKey_endComment] length] > 0) {
                _blockCommentDelimiters = @{@"begin": delimiters[k_SCKey_beginComment],
                                            @"end": delimiters[k_SCKey_endComment]};
            }
            
            // queue
            _coloringQueue = dispatch_queue_create("com.aynimac.CotEditor.ColoringQueue", DISPATCH_QUEUE_CONCURRENT);

            
        } else {
            return nil;
        }
        
        _layoutManager = layoutManager;
        _isPrinting = isPrinting;
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
    if ([wholeString hash] == [self cacheHash]) {
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
    start -= MIN(start, [[NSUserDefaults standardUserDefaults] integerForKey:k_key_coloringRangeBufferLength]);
    
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
    
    NSUInteger menuTitleMaxLength = [[NSUserDefaults standardUserDefaults] integerForKey:k_key_outlineMenuMaxLength];
    NSArray *definitions = [self coloringDictionary][k_SCKey_outlineMenuArray];
    
    for (NSDictionary *definition in definitions) {
        NSRegularExpressionOptions options = NSRegularExpressionAnchorsMatchLines;
        if ([definition[k_SCKey_ignoreCase] boolValue]) {
            options |= NSRegularExpressionCaseInsensitive;
        }

        NSError *error = nil;
        NSRegularExpression *regex = [NSRegularExpression regularExpressionWithPattern:definition[k_SCKey_beginString]
                                                                               options:options
                                                                                 error:&error];
        if (error) {
            NSLog(@"ERROR in \"%s\" with regex pattern \"%@\"", __PRETTY_FUNCTION__, definition[k_SCKey_beginString]);
            continue;  // do nothing
        }
        
        NSString *template = definition[k_SCKey_arrayKeyString];
        
        [regex enumerateMatchesInString:wholeString
                                options:0
                                  range:NSMakeRange(0, [wholeString length])
                             usingBlock:^(NSTextCheckingResult *result, NSMatchingFlags flags, BOOL *stop)
         {
             NSRange range = [result range];
             
             // セパレータのとき
             if ([template isEqualToString:CESeparatorString]) {
                 [outlineMenuDicts addObject:@{k_outlineMenuItemRange: [NSValue valueWithRange:range],
                                               k_outlineMenuItemTitle: CESeparatorString,
                                               k_outlineMenuItemSortKey: @(range.location)}];
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
             BOOL isBold = [definition[k_SCKey_bold] boolValue];
             // イタリック
             BOOL isItalic = [definition[k_SCKey_italic] boolValue];
             // アンダーライン
             NSUInteger underlineMask = [definition[k_SCKey_underline] boolValue] ?
             (NSUnderlineByWordMask | NSUnderlinePatternSolid | NSUnderlineStyleThick) : 0;
             
             // 辞書生成
             [outlineMenuDicts addObject:@{k_outlineMenuItemRange: [NSValue valueWithRange:range],
                                           k_outlineMenuItemTitle: title,
                                           k_outlineMenuItemSortKey: @(range.location),
                                           k_outlineMenuItemFontBold: @(isBold),
                                           k_outlineMenuItemFontItalic: @(isItalic),
                                           k_outlineMenuItemUnderlineMask: @(underlineMask)}];
         }];
    }
    
    if ([outlineMenuDicts count] > 0) {
        // 出現順にソート
        NSSortDescriptor *descriptor = [[NSSortDescriptor alloc] initWithKey:k_outlineMenuItemSortKey
                                                                   ascending:YES
                                                                    selector:@selector(compare:)];
        [outlineMenuDicts sortUsingDescriptors:@[descriptor]];
        
        // 冒頭のアイテムを追加
        [outlineMenuDicts insertObject:@{k_outlineMenuItemRange: [NSValue valueWithRange:NSMakeRange(0, 0)],
                                         k_outlineMenuItemTitle: NSLocalizedString(@"<Outline Menu>", nil),
                                         k_outlineMenuItemSortKey: @0U}
                               atIndex:0];
    }
    
    return outlineMenuDicts;
}



#pragma mark Private Mthods

//=======================================================
// Private method
//
//=======================================================

// ------------------------------------------------------
/// 指定された文字列をそのまま検索し、位置を返す
- (NSArray *)rangesSimpleWords:(NSDictionary *)wordsDict ignoreCaseWords:(NSDictionary *)icWordsDict charSet:(NSCharacterSet *)charSet
// ------------------------------------------------------
{
    NSMutableArray *ranges = [NSMutableArray array];
    
    NSScanner *scanner = [NSScanner scannerWithString:[self coloringString]];
    [scanner setCharactersToBeSkipped:[NSCharacterSet characterSetWithCharactersInString:@"\n\t "]];
    [scanner setCaseSensitive:YES];
    
    @try {
        while (![scanner isAtEnd]) {
            NSString *scannedString = nil;
            [scanner scanUpToCharactersFromSet:charSet intoString:NULL];
            if ([scanner scanCharactersFromSet:charSet intoString:&scannedString]) {
                NSUInteger length = [scannedString length];
                
                if (length == 0) { continue; }
                
                NSUInteger location = [scanner scanLocation];
                NSArray *words = wordsDict[@(length)];
                
                BOOL isFound = [words containsObject:scannedString];
                
                if (!isFound) {
                    words = icWordsDict[@(length)];
                    for (NSString *word in words) {
                        if ([word caseInsensitiveCompare:scannedString] == NSOrderedSame) {
                            isFound = YES;
                            break;
                        }
                    }
                }
                
                if (isFound) {
                    NSRange range = NSMakeRange(location - length, length);
                    [ranges addObject:[NSValue valueWithRange:range]];
                }
            }
        }
    } @catch (NSException *exception) {
        // 何もしない
        NSLog(@"ERROR in \"%s\", reason: %@", __PRETTY_FUNCTION__, [exception reason]);
        return nil;
    }

    return ranges;
}


// ------------------------------------------------------
/// 指定された開始／終了ペアの文字列を検索し、位置を返す
- (NSArray *)rangesBeginString:(NSString *)beginString endString:(NSString *)endString ignoreCase:(BOOL)ignoreCase
                  returnFormat:(QCArrayFormat)returnFormat pairKind:(NSString *)pairKind
// ------------------------------------------------------
{
    if ([beginString length] < 1) { return nil; }
    
    NSMutableArray *ranges = [[NSMutableArray alloc] initWithCapacity:10];
    NSString *string = [self coloringString];
    NSString *escapesCheckStr = nil;
    NSUInteger localLength = [string length];
    NSUInteger start = 0, numberOfEscapes = 0, end = 0;
    NSUInteger escapesCheckLength;
    NSUInteger beginLength = [beginString length];
    NSUInteger endLength = [endString length];
    QCStartEndType startEnd = QCNotUseStartEnd;
    NSRange attrRange, escapesCheckRange;
    
    BOOL isComment = ([pairKind isEqualToString:QCInlineCommentKind] || [pairKind isEqualToString:QCBlockCommentKind]);
    QCStartEndType startType = isComment ? QCStart : QCNotUseStartEnd;
    QCStartEndType endType   = isComment ? QCEnd : QCNotUseStartEnd;
    
    NSScanner *scanner = [NSScanner scannerWithString:string];
    [scanner setCharactersToBeSkipped:nil];
    [scanner setCaseSensitive:!ignoreCase];

    while (![scanner isAtEnd]) {
        if ([[self indicatorController] isCancelled]) {
            return nil;
        }
        
        [scanner scanUpToString:beginString intoString:nil];
        start = [scanner scanLocation];
        if (start + beginLength < localLength) {
            [scanner setScanLocation:(start + beginLength)];
            escapesCheckLength = (start < k_ESCheckLength) ? start : k_ESCheckLength;
            escapesCheckRange = NSMakeRange(start - escapesCheckLength, escapesCheckLength);
            escapesCheckStr = [string substringWithRange:escapesCheckRange];
            numberOfEscapes = [CESyntaxParser numberOfEscapeSequencesInString:escapesCheckStr];
            if (numberOfEscapes % 2 == 1) {
                continue;
            }
            if (returnFormat == QCDictFormat) {
                [ranges addObject:@{QCPositionKey: @(start),
                                    QCPairKindKey: pairKind,
                                    QCStartEndKey: @(startType),
                                    QCLengthKey: @(beginLength)}];
            }
        } else {
            break;
        }
        while (1) {
            [scanner scanUpToString:endString intoString:nil];
            end = [scanner scanLocation] + endLength;
            if (end <= localLength) {
                [scanner setScanLocation:end];
                escapesCheckLength = ((end - endLength) < k_ESCheckLength) ? (end - endLength) : k_ESCheckLength;
                escapesCheckRange = NSMakeRange(end - endLength - escapesCheckLength, escapesCheckLength);
                escapesCheckStr = [string substringWithRange:escapesCheckRange];
                numberOfEscapes = [CESyntaxParser numberOfEscapeSequencesInString:escapesCheckStr];
                if (numberOfEscapes % 2 == 1) {
                    continue;
                } else {
                    if (start < end) {
                        if (returnFormat == QCRangeFormat) {
                            attrRange = NSMakeRange(start, end - start);
                            [ranges addObject:[NSValue valueWithRange:attrRange]];
                        } else {
                            [ranges addObject:@{QCPositionKey: @(end - endLength),
                                                QCPairKindKey: pairKind,
                                                QCStartEndKey: @(endType),
                                                QCLengthKey: @(endLength)}];
                        }
                        break;
                    }
                }
            } else {
                break;
            }
        } // end-while (1)
    } // end-while (![scanner isAtEnd])
    
    return ranges;
}


// ------------------------------------------------------
/// 指定された文字列を正規表現として検索し、位置を返す
- (NSArray *)rangesRegularExpressionString:(NSString *)regexStr ignoreCase:(BOOL)ignoreCase
                              returnFormat:(QCArrayFormat)returnFormat pairKind:(NSString *)pairKind
// ------------------------------------------------------
{
    __block NSMutableArray *ranges = [NSMutableArray array];
    NSString *string = [self coloringString];
    uint32_t options = RKLMultiline | (ignoreCase ? RKLCaseless : 0);
    NSError *error = nil;
    
    BOOL isComment = ([pairKind isEqualToString:QCInlineCommentKind] || [pairKind isEqualToString:QCBlockCommentKind]);
    QCStartEndType startType = isComment ? QCStart : QCNotUseStartEnd;
    QCStartEndType endType   = isComment ? QCEnd : QCNotUseStartEnd;
    
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
         if ([[self indicatorController] isCancelled]) {
             *stop = YES;
             return;
         }
         
         NSRange range = capturedRanges[0];
         
         if (returnFormat == QCRangeFormat) {
             [ranges addObject:[NSValue valueWithRange:range]];
             
         } else {
             [ranges addObject:@{QCPositionKey: @(range.location),
                                 QCPairKindKey: pairKind,
                                 QCStartEndKey: @(startType),
                                 QCLengthKey: @0U}];
             [ranges addObject:@{QCPositionKey: @(NSMaxRange(range)),
                                 QCPairKindKey: pairKind,
                                 QCStartEndKey: @(endType),
                                 QCLengthKey: @0U}];
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
/// 指定された開始／終了文字列を正規表現として検索し、位置を返す
- (NSArray *)rangesRegularExpressionBeginString:(NSString *)beginString endString:(NSString *)endString ignoreCase:(BOOL)ignoreCase
// ------------------------------------------------------
{
    __block NSMutableArray *ranges = [NSMutableArray array];
    NSString *string = [self coloringString];
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
         if ([[self indicatorController] isCancelled]) {
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
- (NSArray *)extractCommentsWithQuotes:(NSDictionary *)quoteColorTypes
// ------------------------------------------------------
{
    NSMutableArray *colorings = [NSMutableArray array];
    NSMutableArray *positions = [NSMutableArray array];
    
    // コメント定義の位置配列を生成
    if ([self inlineCommentDelimiter]) {
        NSString *beginString = [NSString stringWithFormat:@"%@.*",
                                 [NSRegularExpression escapedPatternForString:[self inlineCommentDelimiter]]];
        [positions addObjectsFromArray:[self rangesRegularExpressionString:beginString
                                                                ignoreCase:NO
                                                              returnFormat:QCDictFormat
                                                                  pairKind:QCInlineCommentKind]];
    }
    if ([self blockCommentDelimiters]) {
        [positions addObjectsFromArray:[self rangesBeginString:[self blockCommentDelimiters][@"begin"]
                                                     endString:[self blockCommentDelimiters][@"end"]
                                                    ignoreCase:NO
                                                  returnFormat:QCDictFormat
                                                      pairKind:QCBlockCommentKind]];
    }
    
    // クォート定義があれば位置配列を生成、マージ
    for (NSString *quote in quoteColorTypes) {
        [positions addObjectsFromArray:[self rangesBeginString:quote endString:quote ignoreCase:NO
                                                  returnFormat:QCDictFormat pairKind:quote]];
    }
    
    // コメントもクォートもなければ、もどる
    if ([positions count] < 1) { return nil; }
    
    NSUInteger maxLength = [[self coloringString] length];
    
    NSSortDescriptor *descriptor = [[NSSortDescriptor alloc] initWithKey:QCPositionKey ascending:YES];
    [positions sortUsingDescriptors:@[descriptor]];
    
    NSUInteger coloringCount = [positions count];
    NSString *colorType;
    NSUInteger i, index = 0;
    NSUInteger start, end;
    NSString *searchPairKind = nil;
    
    while (index < coloringCount) {
        NSDictionary *position = positions[index];
        if (!searchPairKind) {
            if ([position[QCStartEndKey] unsignedIntegerValue] == QCEnd) {
                index++;
                continue;
            }
            searchPairKind = position[QCPairKindKey];
            start = [position[QCPositionKey] unsignedIntegerValue];
            index++;
            continue;
        }
        
        if (searchPairKind == position[QCPairKindKey]) {
            colorType = quoteColorTypes[searchPairKind] ? : k_SCKey_commentsArray;
            
            end = [position[QCPositionKey] unsignedIntegerValue] + [position[QCLengthKey] unsignedIntegerValue];
            
            [colorings addObject:@{ColorKey: colorType,
                                   RangeKey: [NSValue valueWithRange:NSMakeRange(start, end - start)]}];
            
            searchPairKind = nil;
            index++;
        } else {
            // 「終わり」があるか調べる
            BOOL hasEnd = NO;
            for (i = (index + 1); i < coloringCount; i++) {
                NSDictionary *checkPosition = positions[i];
                if (searchPairKind == checkPosition[QCPairKindKey]) {
                    QCStartEndType checkStartEnd = [checkPosition[QCStartEndKey] unsignedIntegerValue];
                    if ((checkStartEnd == QCNotUseStartEnd) || (checkStartEnd == QCEnd)) {
                        hasEnd = YES;
                        break;
                    }
                }
            }
            // 「終わり」があればそこへジャンプ、なければ最後までカラーリングして、抜ける
            if (hasEnd) {
                index = i;
            } else {
                colorType = quoteColorTypes[searchPairKind] ? : k_SCKey_commentsArray;
                
                [colorings addObject:@{ColorKey: colorType,
                                       RangeKey: [NSValue valueWithRange:NSMakeRange(start, maxLength - start)]}];
                break;
            }
        }
    }
    return colorings;
}


// ------------------------------------------------------
/// 不可視文字表示時にカラーリング範囲配列を返す
- (NSArray *)extractOtherInvisibleCharsFromString:(NSString *)string
// ------------------------------------------------------
{
    NSMutableArray *colorings = [NSMutableArray array];
    
    NSScanner *scanner = [NSScanner scannerWithString:string];
    NSString *controlStr;

    while (![scanner isAtEnd]) {
        [scanner scanUpToCharactersFromSet:[NSCharacterSet controlCharacterSet] intoString:nil];
        NSUInteger start = [scanner scanLocation];
        if ([scanner scanCharactersFromSet:[NSCharacterSet controlCharacterSet] intoString:&controlStr]) {
            NSRange range = NSMakeRange(start, [controlStr length]);
            
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
    
    // カラーリング対象文字列を保持
    [self setColoringString:string];
    
    NSMutableDictionary *simpleWordsDict = [NSMutableDictionary dictionaryWithCapacity:40];
    NSMutableDictionary *simpleICWordsDict = [NSMutableDictionary dictionaryWithCapacity:40];
    NSMutableDictionary *quoteTypes = [NSMutableDictionary dictionaryWithCapacity:2];
    
    @try {
        // Keywords > Commands > Types > Variables > Values > Numbers > Strings > Characters > Comments
        for (NSString *syntaxKey in kSyntaxDictKeys) {
            // インジケータシートのメッセージを更新
            if ([self indicatorController]) {
                [[self indicatorController] setInformativeText:
                 [NSString stringWithFormat:NSLocalizedString(@"Extracting %@", nil),
                  NSLocalizedString([syntaxKey stringByReplacingOccurrencesOfString:@"Array" withString:@""], nil)]];
            }
            
            NSArray *strDicts = [self coloringDictionary][syntaxKey];
            if ([strDicts count] == 0) {
                if ([self indicatorController]) {
                    [[self indicatorController] progressIndicator:kPerCompoIncrement];
                }
                continue;
            }
            
            CGFloat indicatorDelta = kPerCompoIncrement / [strDicts count];
            
            NSMutableArray *targetRanges = [[NSMutableArray alloc] initWithCapacity:10];
            for (NSDictionary *strDict in strDicts) {
                // キャンセルされたら現在実行中の抽出は破棄して戻る
                if ([[self indicatorController] isCancelled]) { return nil; }
                
                @autoreleasepool {
                    NSString *beginStr = strDict[k_SCKey_beginString];
                    NSString *endStr = strDict[k_SCKey_endString];
                    BOOL ignoresCase = [strDict[k_SCKey_ignoreCase] boolValue];
                    
                    if ([beginStr length] == 0) { continue; }
                    
                    if ([strDict[k_SCKey_regularExpression] boolValue]) {
                        if ([endStr length] > 0) {
                            [targetRanges addObjectsFromArray:
                             [self rangesRegularExpressionBeginString:beginStr
                                                            endString:endStr
                                                           ignoreCase:ignoresCase]];
                        } else {
                            [targetRanges addObjectsFromArray:
                             [self rangesRegularExpressionString:beginStr
                                                      ignoreCase:ignoresCase
                                                    returnFormat:QCRangeFormat
                                                        pairKind:nil]];
                        }
                    } else {
                        if ([endStr length] > 0) {
                            // 開始／終了ともに入力されていたらクォートかどうかをチェック、最初に出てきたクォートのみを把握
                            BOOL isQuoteFound = NO;
                            for (NSString *quote in @[@"'", @"\"", @"`"]) {
                                if ([beginStr isEqualToString:quote] && [endStr isEqualToString:quote]) {
                                    if (!quoteTypes[quote]) {
                                        quoteTypes[quote] = syntaxKey;
                                    }
                                    isQuoteFound = YES;
                                }
                            }
                            if (isQuoteFound) { continue; }
                            
                            [targetRanges addObjectsFromArray:
                             [self rangesBeginString:beginStr
                                           endString:endStr
                                          ignoreCase:ignoresCase
                                        returnFormat:QCRangeFormat
                                            pairKind:nil]];
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
                    // インジケータ更新
                    if ([self indicatorController]) {
                        [[self indicatorController] progressIndicator:indicatorDelta];
                    }
                } // ==== end-autoreleasepool
            } // end-for (strDict)
            
            if ([simpleWordsDict count] > 0 || [simpleICWordsDict count] > 0) {
                [targetRanges addObjectsFromArray:
                 [self rangesSimpleWords:simpleWordsDict
                         ignoreCaseWords:simpleICWordsDict
                                 charSet:[self simpleWordsCharacterSets][syntaxKey]]];
                
                [simpleWordsDict removeAllObjects];
            }
            // カラーとrangeのペアを格納
            for (NSValue *value in targetRanges) {
                [colorings addObject:@{ColorKey: syntaxKey,
                                       RangeKey: value}];
            }
        } // end-for (syntaxKey)
        
        [colorings addObjectsFromArray:[self extractCommentsWithQuotes:quoteTypes]];
        if ([self indicatorController]) {
            [[self indicatorController] progressIndicator:kPerCompoIncrement];
        }

        
        // 不可視文字の追加
        [colorings addObjectsFromArray:[self extractOtherInvisibleCharsFromString:string]];
        
    } @catch (NSException *exception) {
        // 何もしない
        NSLog(@"ERROR in \"%s\" reason: %@", __PRETTY_FUNCTION__, [exception reason]);
        
    } @finally {
        // カラーリング対象文字列を片づける
        [self setColoringString:nil];
    }
    
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
    if (([[self coloringDictionary][k_SCKey_numOfObjInArray] integerValue] == 0) || [self isNone]) {
        [self applyColorings:[self extractOtherInvisibleCharsFromString:coloringString] range:coloringRange];
        return;
    }
    
    // 規定の文字数以上の場合にはカラーリングインジケータシートを表示
    // （ただし、k_key_showColoringIndicatorTextLength が「0」の時は表示しない）
    NSUInteger indicatorThreshold = [[NSUserDefaults standardUserDefaults] integerForKey:k_key_showColoringIndicatorTextLength];
    if (![self isPrinting] && (indicatorThreshold > 0) && (coloringRange.length > indicatorThreshold)) {
        NSWindow *documentWindow = [[[self layoutManager] firstTextView] window];
        [self setIndicatorController:[[CEIndicatorSheetController alloc] initWithMessage:NSLocalizedString(@"Coloring text...", nil)]];
        [[self indicatorController] beginSheetForWindow:documentWindow];
    }
    
    __block typeof(self) blockSelf = self;
    dispatch_block_t colorBlock = ^{
        NSArray *colorings = [blockSelf extractAllSyntaxFromString:coloringString];
        
        dispatch_block_t mainThreadBlock = ^{
            if (colorings) {
                // インジケータシートのメッセージを更新
                [[blockSelf indicatorController] setInformativeText:NSLocalizedString(@"Applying colors to text", nil)];
                
                // カラーを適応する（ループ中に徐々に適応させると文字がチラ付くので、抽出が終わってから一気に適応する）
                [blockSelf applyColorings:colorings range:coloringRange];
            }
            
            // インジーケータシートを片づける
            if ([blockSelf indicatorController]) {
                [[blockSelf indicatorController] endSheet];
                [blockSelf setIndicatorController:nil];
            }
        };
        
        // メインスレッドで実行
        if ([NSThread isMainThread]) {
            mainThreadBlock();
        } else {
            dispatch_sync(dispatch_get_main_queue(), mainThreadBlock);
        }
        
        // 全文を抽出した場合は抽出結果をキャッシュする
        if (([colorings count] > 0) && (coloringRange.length == [wholeString length])) {
            [blockSelf setCacheColorings:colorings];
            [blockSelf setCacheHash:[wholeString hash]];
        }
    };
    
    // 任意のスレッドで実行
    if (onMainThread) {
        colorBlock();
    } else {
        dispatch_async([self coloringQueue], colorBlock);
    }
}


// ------------------------------------------------------
/// 抽出したカラー範囲配列を書類に適応する
- (void)applyColorings:(NSArray *)colorings range:(NSRange)coloringRange
// ------------------------------------------------------
{
    CETheme *theme = [(NSTextView<CETextViewProtocol> *)[[self layoutManager] firstTextView] theme];
    
    // 現在あるカラーリングを削除
    if ([self isPrinting]) {
        [[[self layoutManager] firstTextView] setTextColor:[theme textColor] range:coloringRange];
    } else {
        [[self layoutManager] removeTemporaryAttribute:NSForegroundColorAttributeName
                                     forCharacterRange:coloringRange];
    }
    
    // カラーリング実行
    for (NSDictionary *coloring in colorings) {
        @autoreleasepool {
            NSColor *color;
            NSString *colorType = coloring[ColorKey];
            if ([colorType isEqualToString:InvisiblesType]) {
                if (![[self layoutManager] showOtherInvisibles]) { continue; }
                
                color = [theme invisiblesColor];
            } else if ([colorType isEqualToString:k_SCKey_keywordsArray]) {
                color = [theme keywordsColor];
            } else if ([colorType isEqualToString:k_SCKey_commandsArray]) {
                color = [theme commandsColor];
            } else if ([colorType isEqualToString:k_SCKey_typesArray]) {
                color = [theme typesColor];
            } else if ([colorType isEqualToString:k_SCKey_variablesArray]) {
                color = [theme variablesColor];
            } else if ([colorType isEqualToString:k_SCKey_valuesArray]) {
                color = [theme valuesColor];
            } else if ([colorType isEqualToString:k_SCKey_numbersArray]) {
                color = [theme numbersColor];
            } else if ([colorType isEqualToString:k_SCKey_stringsArray]) {
                color = [theme stringsColor];
            } else if ([colorType isEqualToString:k_SCKey_charactersArray]) {
                color = [theme charactersColor];
            } else if ([colorType isEqualToString:k_SCKey_commentsArray]) {
                color = [theme commentsColor];
            } else {
                color = [theme textColor];
            }
            
            NSRange range = [coloring[RangeKey] rangeValue];
            range.location += coloringRange.location;
            
            if ([self isPrinting]) {
                [[[self layoutManager] firstTextView] setTextColor:color range:range];
            } else {
                [[self layoutManager] addTemporaryAttribute:NSForegroundColorAttributeName
                                                      value:color forCharacterRange:range];
            }
        }
    }
}

@end
