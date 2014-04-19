/*
=================================================
CESyntax
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

#import "CESyntax.h"
#import <OgreKit/OgreKit.h>
#import "CEEditorView.h"
#import "CESyntaxManager.h"
#import "CEPrivateMutableArray.h"
#import "constants.h"
#import "DEBUG_macro.h"


@interface CESyntax ()

@property (nonatomic, weak) IBOutlet NSProgressIndicator *coloringIndicator;
@property (nonatomic, weak) IBOutlet NSTextField *coloringCaption;

@property (nonatomic) NSDictionary *coloringDictionary;
@property (nonatomic) NSDictionary *currentAttrs;
@property (nonatomic) NSDictionary *singleQuotesAttrs;
@property (nonatomic) NSDictionary *doubleQuotesAttrs;
@property (nonatomic) NSColor *textColor;

@property (nonatomic) NSRange updateRange;
@property (nonatomic) NSModalSession modalSession;

@property (nonatomic) BOOL isIndicatorShown;
@property (nonatomic) NSUInteger showColoringIndicatorTextLength;


// readonly
@property (nonatomic, readwrite) NSArray *completeWordsArray;
@property (nonatomic, readwrite) NSCharacterSet *completeFirstLetterSet;

@end





#pragma mark -

@implementation CESyntax

#pragma mark Public Methods

//=======================================================
// Public method
//
//=======================================================

// ------------------------------------------------------
/// 初期化
- (instancetype)init
// ------------------------------------------------------
{
    self = [super init];
    if (self) {
        (void)[NSBundle loadNibNamed:@"Indicator" owner:self];
        [self setShowColoringIndicatorTextLength:[[NSUserDefaults standardUserDefaults] integerForKey:k_key_showColoringIndicatorTextLength]];
        [[self coloringIndicator] setIndeterminate:NO];
    }
    return self;
}


// ------------------------------------------------------
/// 全文字列の長さを返す
- (NSUInteger)wholeStringLength
// ------------------------------------------------------
{
    return [[self wholeString] length];
}


// ------------------------------------------------------
/// 保持するstyle名をセット
- (void)setSyntaxStyleName:(NSString *)styleName
// ------------------------------------------------------
{
    CESyntaxManager *manager = [CESyntaxManager sharedManager];
    NSArray *names = [manager styleNames];

    if ([names containsObject:styleName] || [styleName isEqualToString:NSLocalizedString(@"None",@"")]) {
        [self setColoringDictionary:[manager styleWithStyleName:styleName]];

        [self setCompleteWordsArrayFromColoringDictionary];

        _syntaxStyleName = styleName;
    }
}


// ------------------------------------------------------
/// 拡張子からstyle名をセット
- (BOOL)setSyntaxStyleNameFromExtension:(NSString *)extension
// ------------------------------------------------------
{
    NSString *name = [[CESyntaxManager sharedManager] syntaxNameFromExtension:extension];

    if (name && ![[self syntaxStyleName] isEqualToString:name]) {
        [self setSyntaxStyleName:name];
        return YES;
    }
    return NO;
}


// ------------------------------------------------------
/// 保持しているカラーリング辞書から補完文字列配列を生成
- (void)setCompleteWordsArrayFromColoringDictionary
// ------------------------------------------------------
{
    if ([self coloringDictionary] == nil) { return; }

    NSMutableArray *tmpArray = [NSMutableArray array];
    NSArray *completeArray = [self coloringDictionary][k_SCKey_completionsArray];
    NSMutableString *tmpString = [NSMutableString string];
    NSString *string = nil;
    NSCharacterSet *charSet;

    if (completeArray) {
        for (NSDictionary *dict in completeArray) {
            string = dict[k_SCKey_arrayKeyString];
            [tmpArray addObject:string];
            [tmpString appendString:[string substringToIndex:1]];
        }

    } else {
        NSArray *syntaxArray = @[k_SCKey_allColoringArrays];
        NSArray *array;
        NSString *endStr = nil;
        NSDictionary *strDict;


        for (NSString *syntaxName in syntaxArray) {
            @autoreleasepool {
                array = [self coloringDictionary][syntaxName];
                for (strDict in array) {
                    string = [strDict[k_SCKey_beginString] stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
                    endStr = [strDict[k_SCKey_endString] stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
                    if (([string length] > 0) &&
                        ((endStr == nil) || ([endStr length] < 1)) &&
                        (![strDict[k_SCKey_regularExpression] boolValue]))
                    {
                        [tmpArray addObject:string];
                        [tmpString appendString:[string substringToIndex:1]];
                    }
                }
            } // ==== end-autoreleasepool
        }
        // ソート
        [tmpArray sortedArrayUsingSelector:@selector(compare:)];
    }
    // completeWordsArray を保持する
    [self setCompleteWordsArray:tmpArray];

    // completeFirstLetterSet を保持する
    if ([tmpString length] > 0) {
        charSet = [NSCharacterSet characterSetWithCharactersInString:tmpString];
        [self setCompleteFirstLetterSet:charSet];
    } else {
        [self setCompleteFirstLetterSet:nil];
    }
}


// ------------------------------------------------------
/// 全体をカラーリング
- (void)colorAllString:(NSString *)wholeString
// ------------------------------------------------------
{
    if ((wholeString == nil) || ([wholeString length] < 1) || 
            ([[self syntaxStyleName] length] < 1)) { return; }

    [self setWholeString:wholeString];
    [self setUpdateRange:NSMakeRange(0, [self wholeStringLength])];

    if ([self coloringDictionary] == nil) {
        [self setColoringDictionary:[[CESyntaxManager sharedManager] styleWithStyleName:[self syntaxStyleName]]];
        [self setCompleteWordsArrayFromColoringDictionary];
    }
    if ([self coloringDictionary] == nil) { return; }

    [self doColoring];
    [self setWholeString:nil];
}


// ------------------------------------------------------
/// 表示されている部分をカラーリング
- (void)colorVisibleRange:(NSRange)range withWholeString:(NSString *)wholeString
// ------------------------------------------------------
{
    if ((wholeString == nil) || ([wholeString length] < 1) || 
            ([[self syntaxStyleName] length] < 1)) { return; }
    [self setWholeString:wholeString];

    NSRange effectiveRange;
    NSUInteger start = range.location;
    NSUInteger end = NSMaxRange(range) - 1;
    NSUInteger wholeLength = [self wholeStringLength];

    // 直前／直後が同色ならカラーリング範囲を拡大する
    (void)[[self layoutManager] temporaryAttributesAtCharacterIndex:start
                                              longestEffectiveRange:&effectiveRange
                                                            inRange:NSMakeRange(0, [self wholeStringLength])];

    start = effectiveRange.location;
    (void)[[self layoutManager] temporaryAttributesAtCharacterIndex:end
                                              longestEffectiveRange:&effectiveRange
                                                            inRange:NSMakeRange(0, [self wholeStringLength])];

    end = (NSMaxRange(effectiveRange) < wholeLength) ? NSMaxRange(effectiveRange) : wholeLength;

    [self setUpdateRange:NSMakeRange(start, end - start)];
    if ([self coloringDictionary] == nil) {
        [self setColoringDictionary:[[CESyntaxManager sharedManager] styleWithStyleName:[self syntaxStyleName]]];
        [self setCompleteWordsArrayFromColoringDictionary];
    }
    if ([self coloringDictionary] == nil) { return; }

    [self doColoring];
    [self setWholeString:nil];
}


// ------------------------------------------------------
/// アウトラインメニュー用の配列を生成し、返す
- (NSArray *)outlineMenuArrayWithWholeString:(NSString *)wholeString
// ------------------------------------------------------
{
// （outlineMenuは、過去の定義との互換性保持のためもあってOgreKitを使っている 2008.05.16）
    NSMutableArray *outlineMenuDicts = [NSMutableArray array];
    if ((wholeString == nil) || ([wholeString length] < 1) || ([[self syntaxStyleName] length] < 1)) {
        return outlineMenuDicts;
    }
    [self setWholeString:wholeString];

    NSArray *REStringArray = [self coloringDictionary][k_SCKey_outlineMenuArray];
    NSMutableString *pattern; 
    NSString *title, *matchedIndexString;
    NSRange matchRange;
    NSUInteger index, lines, curLine, wholeLength = [wholeString length];
    NSUInteger menuTitleMaxLength = [[NSUserDefaults standardUserDefaults] integerForKey:k_key_outlineMenuMaxLength];

    for (NSDictionary *dict in REStringArray) {
        NSUInteger options = ([dict[k_SCKey_ignoreCase] boolValue]) ?  OgreIgnoreCaseOption : OgreNoneOption;
        NSDictionary *matchDict;
        OGRegularExpression *regex;
        NSEnumerator *enumerator;
        OGRegularExpressionMatch *match;

        NS_DURING
            regex = [OGRegularExpression regularExpressionWithString:dict[k_SCKey_beginString] options:options];
        NS_HANDLER
            // 何もしない
            NSLog(@"ERROR in \"%s\"", __PRETTY_FUNCTION__);
            continue;
        NS_ENDHANDLER

        enumerator = [regex matchEnumeratorInString:[self wholeString]];
        while (match = [enumerator nextObject]) {
            // マッチした範囲
            matchRange = [match rangeOfMatchedString];
            // メニュー項目タイトル
            pattern = [dict[k_SCKey_arrayKeyString] mutableCopy];
            if ([pattern isEqualToString:k_outlineMenuSeparatorSymbol]) {
                // セパレータのとき
                matchDict = @{k_outlineMenuItemRange: [NSValue valueWithRange:matchRange],
                              k_outlineMenuItemTitle: k_outlineMenuSeparatorSymbol,
                              k_outlineMenuItemSortKey: @(matchRange.location)};
                [outlineMenuDicts addObject:matchDict];
                continue;
            } else if ((pattern == nil) || ([pattern length] < 1)) {
                // パターン定義なし
                pattern = [[match matchedString] mutableCopy];
            } else {
                // マッチ文字列（$0, $&）置換
                (void)[pattern replaceOccurrencesOfRegularExpressionString:@"(?<!\\\\)\\$0"
                                                                withString:[match matchedString]
                                                                   options:0
                                                                     range:NSMakeRange(0, [pattern length])];
                (void)[pattern replaceOccurrencesOfRegularExpressionString:@"(?<!\\\\)\\$&"
                                                                withString:[match matchedString]
                                                                   options:0
                                                                     range:NSMakeRange(0, [pattern length])];
                // マッチ部分文字列（$1-9）置換
                for (NSInteger i = 1; i < 10; i++) {
                    matchedIndexString = [match substringAtIndex:i];
                    if (matchedIndexString != nil) {
                        (void)[pattern replaceOccurrencesOfRegularExpressionString:[NSString stringWithFormat:@"(?<!\\\\)\\$%li", (long)i]
                                                                        withString:matchedIndexString
                                                                           options:0
                                                                             range:NSMakeRange(0, [pattern length])];
                    }
                }
                // マッチした範囲の開始位置の行
                curLine = 1;
                for (index = 0, lines = 0; index < wholeLength; lines++) {
                    if (index <= matchRange.location) {
                        curLine = lines + 1;
                    } else {
                        break;
                    }
                    index = NSMaxRange([wholeString lineRangeForRange:NSMakeRange(index, 0)]);
                }
                //行番号（$LN）置換
                (void)[pattern replaceOccurrencesOfRegularExpressionString:@"(?<!\\\\)\\$LN"
                                                                withString:[NSString stringWithFormat:@"%lu", (unsigned long)curLine]
                                                                   options:0
                                                                     range:NSMakeRange(0, [pattern length])];
            }
            // 改行またはタブをスペースに置換
            (void)[pattern replaceOccurrencesOfRegularExpressionString:@"[\n\t]"
                                                            withString:@" "
                                                               options:0
                                                                 range:NSMakeRange(0, [pattern length])];
            // エスケープされた「$」を置換
            (void)[pattern replaceOccurrencesOfRegularExpressionString:@"\\\\\\$(?=([0-9&]|LN))"
                                                            withString:@"$"
                                                               options:0
                                                                 range:NSMakeRange(0, [pattern length])];
            // タイトル確定
            if ([pattern length] > menuTitleMaxLength) {
                title = [NSString stringWithFormat:@"%@ ...", [pattern substringToIndex:menuTitleMaxLength]];
            } else {
                title = [NSString stringWithString:pattern];
            }
            // ボールド
            BOOL isBold = [[dict valueForKey:k_SCKey_bold] boolValue];
            // イタリック
            BOOL isItalic = [[dict valueForKey:k_SCKey_italic] boolValue];
            // アンダーライン
            NSUInteger theUnderlineMask = ([[dict valueForKey:k_SCKey_underline] boolValue]) ?
                    (NSUnderlineByWordMask | NSUnderlinePatternSolid | NSUnderlineStyleThick) : 0;
            // 辞書生成
            matchDict = @{k_outlineMenuItemRange: [NSValue valueWithRange:matchRange],
                          k_outlineMenuItemTitle: title,
                          k_outlineMenuItemSortKey: @(matchRange.location),
                          k_outlineMenuItemFontBold: @(isBold),
                          k_outlineMenuItemFontItalic: @(isItalic),
                          k_outlineMenuItemUnderlineMask: @(theUnderlineMask)};
            [outlineMenuDicts addObject:matchDict];
        }
    }
    if ([outlineMenuDicts count] > 0) {
        NSSortDescriptor *theDescriptor = [[NSSortDescriptor alloc] initWithKey:k_outlineMenuItemSortKey
                                                                      ascending:YES
                                                                       selector:@selector(compare:)];
        [outlineMenuDicts sortUsingDescriptors:@[theDescriptor]];
        // ソート後に、冒頭のアイテムを追加
        [outlineMenuDicts insertObject:@{k_outlineMenuItemRange: [NSValue valueWithRange:NSMakeRange(0, 0)],
                                         k_outlineMenuItemTitle: NSLocalizedString(@"<Outline Menu>",@""),
                                         k_outlineMenuItemSortKey: @0U}
                               atIndex:0];
    }
    return outlineMenuDicts;
}



#pragma mark Action Messages

//=======================================================
// Action messages
//
//=======================================================

// ------------------------------------------------------
/// カラーリング中止、インジケータシートのモーダルを停止
- (IBAction)cancelColoring:(id)sender
// ------------------------------------------------------
{
    [NSApp abortModal];
}



#pragma mark Private Mthods

//=======================================================
// Private method
//
//=======================================================

// ------------------------------------------------------
/// 指定された文字列をそのまま検索し、カラーリング
- (void)setAttrToSimpleWordsArrayDict:(NSMutableDictionary*)wordsDict withCharString:(NSMutableString *)charString
// ------------------------------------------------------
{
    NSArray *array = [self rangesSimpleWordsArrayDict:wordsDict withCharString:charString];
    NSRange range;

    for (NSValue *value in array) {
        range = [value rangeValue];
        range.location += [self updateRange].location;

        if ([self isPrinting]) {
            [[[self layoutManager] firstTextView] setTextColor:[self textColor] range:range];
        } else {
            [[self layoutManager] addTemporaryAttributes:[self currentAttrs] forCharacterRange:range];
        }
    }
}


// ------------------------------------------------------
/// 指定された文字列をそのまま検索し、位置を返す
- (NSArray *)rangesSimpleWordsArrayDict:(NSMutableDictionary*)wordsDict withCharString:(NSMutableString *)charString
// ------------------------------------------------------
{
    NSScanner *scanner = [NSScanner scannerWithString:[self localString]];
    NSString *scanStr = nil;
    CEPrivateMutableArray *outArray = [[CEPrivateMutableArray alloc] initWithCapacity:10];
    NSCharacterSet *charSet;
    NSRange attrRange;
    id wordsArray;
    NSUInteger location = 0, length = 0;

    // 改行、タブ、スペースは無視
    [charString chomp];
    (void)[charString replaceOccurrencesOfString:@"\t" withString:@"" options:0 range:NSMakeRange(0, [charString length])];
    (void)[charString replaceOccurrencesOfString:@" " withString:@"" options:0 range:NSMakeRange(0, [charString length])];

    charSet = [NSCharacterSet characterSetWithCharactersInString:charString];
    [scanner setCharactersToBeSkipped:[NSCharacterSet characterSetWithCharactersInString:@"\n\t "]];
    [scanner setCaseSensitive:YES];

    NS_DURING
        while (![scanner isAtEnd]) {
            (void)[scanner scanUpToCharactersFromSet:charSet intoString:NULL];
            if ([scanner scanCharactersFromSet:charSet intoString:&scanStr]) {
                length = [scanStr length];
                if (length > 0) {
                    location = [scanner scanLocation];
                    wordsArray = wordsDict[@(length)];
                    if ([wordsArray containsObject:scanStr]) {
                        attrRange = NSMakeRange(location - length, length);
                        [outArray addObject:[NSValue valueWithRange:attrRange]];
                    }
                }
            }
        }
    NS_HANDLER
        // 何もしない
        NSLog(@"ERROR in \"%s\"", __PRETTY_FUNCTION__);
        return nil;
    NS_ENDHANDLER

    return outArray;
}


// ------------------------------------------------------
/// 指定された開始／終了ペアの文字列を検索し、位置を返す
- (NSArray *)rangesBeginString:(NSString *)beginString withEndString:(NSString *)endString
                    doColoring:(BOOL)doColoring pairStringKind:(NSUInteger)pairKind
// ------------------------------------------------------
{
    NSString *ESCheckStr = nil;
    NSScanner *scanner = [NSScanner scannerWithString:[self localString]];
    NSUInteger localLength = [[self localString] length];
    NSUInteger start = 0, ESNum = 0, end = 0;
    NSUInteger beginLength = 0, endLength = 0, ESCheckLength;
    NSUInteger startEnd = 0;
    NSRange attrRange, tmpRange;

    beginLength = [beginString length];
    if (beginLength < 1) { return nil; }
    endLength = [endString length];
    [scanner setCharactersToBeSkipped:nil];
    [scanner setCaseSensitive:YES];
    CEPrivateMutableArray *outArray = [[CEPrivateMutableArray alloc] initWithCapacity:10];
    NSInteger i = 0;

    while (![scanner isAtEnd]) {
        (void)[scanner scanUpToString:beginString intoString:nil];
        start = [scanner scanLocation];
        if (start + beginLength < localLength) {
            [scanner setScanLocation:(start + beginLength)];
            ESCheckLength = (start < k_ESCheckLength) ? start : k_ESCheckLength;
            tmpRange = NSMakeRange(start - ESCheckLength, ESCheckLength);
            ESCheckStr = [[self localString] substringWithRange:tmpRange];
            ESNum = [self numberOfEscapeSequenceInString:ESCheckStr];
            if (ESNum % 2 == 1) {
                continue;
            }
            if (!doColoring) {
                startEnd = (pairKind >= k_QC_CommentBaseNum) ? k_QC_Start : k_notUseStartEnd;
                [outArray addObject:@{k_QCPosition: @(start),
                                      k_QCPairKind: @(pairKind),
                                      k_QCStartEnd: @(startEnd),
                                      k_QCStrLength: @(beginLength)}];
            }
        } else {
            break;
        }
        while (1) {
            i++;
            if ([self isIndicatorShown] && ((i % 10) == 0) &&
                ([NSApp runModalSession:[self modalSession]] != NSRunContinuesResponse))
            {
                return nil;
            }
            (void)[scanner scanUpToString:endString intoString:nil];
            end = [scanner scanLocation] + endLength;
            if (end <= localLength) {
                [scanner setScanLocation:end];
                ESCheckLength = ((end - endLength) < k_ESCheckLength) ? (end - endLength) : k_ESCheckLength;
                tmpRange = NSMakeRange(end - endLength - ESCheckLength, ESCheckLength);
                ESCheckStr = [[self localString] substringWithRange:tmpRange];
                ESNum = [self numberOfEscapeSequenceInString:ESCheckStr];
                if (ESNum % 2 == 1) {
                    continue;
                } else {
                    if (start < end) {
                        if (doColoring) {
                            attrRange = NSMakeRange(start, end - start);
                            [outArray addObject:[NSValue valueWithRange:attrRange]];
                        } else {
                            startEnd = (pairKind >= k_QC_CommentBaseNum) ? k_QC_End : k_notUseStartEnd;
                            [outArray addObject:@{k_QCPosition: @(end - endLength),
                                                  k_QCPairKind: @(pairKind),
                                                  k_QCStartEnd: @(startEnd),
                                                  k_QCStrLength: @(endLength)}];
                        }
                        break;
                    }
                }
            } else {
                break;
            }
        } // end-while (1)
    } // end-while (![scanner isAtEnd])
    return outArray;
}


// ------------------------------------------------------
/// 指定された文字列を正規表現として検索し、位置を返す
- (NSArray *)rangesRegularExpressionString:(NSString *)regexStr withIgnoreCase:(BOOL)ignoreCase
                                doColoring:(BOOL)doColoring pairStringKind:(NSUInteger)pairKind
// ------------------------------------------------------
{
    NSRegularExpressionOptions regexOptions = NSRegularExpressionAnchorsMatchLines;
    if (ignoreCase) {
        regexOptions |= NSRegularExpressionCaseInsensitive;
    }
    
    NSError *error = nil;
    NSRegularExpression *regex = [NSRegularExpression regularExpressionWithPattern:regexStr options:regexOptions error:&error];
    if (error) {
        NSLog(@"ERROR in \"%s\"", __PRETTY_FUNCTION__);
        return nil;  // 何もしない
    }
    
    __block NSMutableArray *outArray = [[NSMutableArray alloc] initWithCapacity:10];
    [regex enumerateMatchesInString:[self localString]
                            options:0
                              range:NSMakeRange(0, [[self localString] length])
                         usingBlock:^(NSTextCheckingResult *result, NSMatchingFlags flags, BOOL *stop)
     {
         if ([self isIndicatorShown] && ([NSApp runModalSession:[self modalSession]] != NSModalResponseContinue)) {
             *stop = YES;
         };
         
         if (doColoring) {
             [outArray addObject:[NSValue valueWithRange:[result range]]];
             
         } else {
             NSUInteger QCStart = 0, QCEnd = 0;
             NSRange attrRange = [result range];
             
             if (pairKind >= k_QC_CommentBaseNum) {
                 QCStart = k_QC_Start;
                 QCEnd = k_QC_End;
             } else {
                 QCStart = QCEnd = k_notUseStartEnd;
             }
             [outArray addObject:@{k_QCPosition: @(attrRange.location),
                                   k_QCPairKind: @(pairKind),
                                   k_QCStartEnd: @(QCStart),
                                   k_QCStrLength: @0U}];
             [outArray addObject:@{k_QCPosition: @(NSMaxRange(attrRange)),
                                   k_QCPairKind: @(pairKind),
                                   k_QCStartEnd: @(QCEnd),
                                   k_QCStrLength: @0U}];
         }
    }];
    
    return outArray;
}


// ------------------------------------------------------
/// 指定された文字列を正規表現として検索し、位置を返す
- (NSArray *)checkRegularExpressionString:(NSString *)regexStr withIgnoreCase:(BOOL)ignoreCase
                               doColoring:(BOOL)doColoring pairStringKind:(NSUInteger)pairKind
// ------------------------------------------------------
{
    NSUInteger options = (ignoreCase) ? OgreIgnoreCaseOption : OgreNoneOption;
    OGRegularExpression *regex;
    NSEnumerator *enumerator;
    OGRegularExpressionMatch *match;
    NSMutableArray *outArray = [NSMutableArray array];
    NSRange attrRange;
    NSUInteger QCStart = 0, QCEnd = 0;

    NS_DURING
        regex = [OGRegularExpression regularExpressionWithString:regexStr options:options];
    NS_HANDLER
        // 例外処理 (OgreKit付属のRegularExpressionTestのコードを参考にしています)
        // 何もしない
        return nil;
    NS_ENDHANDLER

    enumerator = [regex matchEnumeratorInString:[self localString]];

    while (match = [enumerator nextObject]) {
        if ([self isIndicatorShown] && ([NSApp runModalSession:[self modalSession]] != NSRunContinuesResponse)) {
            return nil;
        }
        
        @autoreleasepool {
            attrRange = [match rangeOfMatchedString];
            attrRange.location += [self updateRange].location;
            if (doColoring) {
                [outArray addObject:[NSValue valueWithRange:attrRange]];
            } else {
                if (pairKind >= k_QC_CommentBaseNum) {
                    QCStart = k_QC_Start;
                    QCEnd = k_QC_End;
                } else {
                    QCStart = QCEnd = k_notUseStartEnd;
                }
                [outArray addObject:@{k_QCPosition: @(attrRange.location),
                                      k_QCPairKind: @(pairKind),
                                      k_QCStartEnd: @(QCStart),
                                      k_QCStrLength: @0U}];
                [outArray addObject:@{k_QCPosition: @(NSMaxRange(attrRange)),
                                      k_QCPairKind: @(pairKind),
                                      k_QCStartEnd: @(QCEnd),
                                      k_QCStrLength: @0U}];
            }
        } // ==== end-autoreleasepool
    }
    return outArray;
}


// ------------------------------------------------------
/// 指定された開始／終了文字列を正規表現として検索し、位置を返す
- (NSArray *)rangesRegularExpressionBeginString:(NSString *)beginString withEndString:(NSString *)endString withIgnoreCase:(BOOL)ignoreCase
                                     doColoring:(BOOL)doColoring pairStringKind:(NSUInteger)pairKind
// ------------------------------------------------------
{
    NSRegularExpressionOptions regexOptions = NSRegularExpressionAnchorsMatchLines;
    if (ignoreCase) {
        regexOptions |= NSRegularExpressionCaseInsensitive;
    }
    
    NSError *error = nil;
    NSRegularExpression *beginRegex = [NSRegularExpression regularExpressionWithPattern:beginString options:regexOptions error:&error];
    NSRegularExpression *endRegex = [NSRegularExpression regularExpressionWithPattern:endString options:regexOptions error:&error];
    if (error) {
        NSLog(@"ERROR in \"%s\"", __PRETTY_FUNCTION__);
        return nil;  // 何もしない
    }
    
    __block NSMutableArray *outArray = [[NSMutableArray alloc] initWithCapacity:10];
    [beginRegex enumerateMatchesInString:[self localString]
                                 options:0
                                   range:NSMakeRange(0, [[self localString] length])
                              usingBlock:^(NSTextCheckingResult *result, NSMatchingFlags flags, BOOL *stop)
     {
         if ([self isIndicatorShown] && ([NSApp runModalSession:[self modalSession]] != NSModalResponseContinue)) {
             *stop = YES;
         };
         
         NSRange beginRange = [result range];
         NSRange endRange = [endRegex rangeOfFirstMatchInString:[self localString] options:0
                                                          range:NSMakeRange(NSMaxRange(beginRange),
                                                                            [[self localString] length] - NSMaxRange(beginRange))];
         
         if (endRange.location != NSNotFound) {
             NSRange attrRange = NSUnionRange(beginRange, endRange);
             
             if (doColoring) {
                 [outArray addObject:[NSValue valueWithRange:attrRange]];
                 
             } else {
                 NSUInteger QCStart = 0, QCEnd = 0;
                 
                 if (pairKind >= k_QC_CommentBaseNum) {
                     QCStart = k_QC_Start;
                     QCEnd = k_QC_End;
                 } else {
                     QCStart = QCEnd = k_notUseStartEnd;
                 }
                 [outArray addObject:@{k_QCPosition: @(attrRange.location),
                                       k_QCPairKind: @(pairKind),
                                       k_QCStartEnd: @(QCStart),
                                       k_QCStrLength: @0U}];
                 [outArray addObject:@{k_QCPosition: @(NSMaxRange(attrRange)),
                                       k_QCPairKind: @(pairKind),
                                       k_QCStartEnd: @(QCEnd),
                                       k_QCStrLength: @0U}];
             }
         }
     }];
    
    return outArray;
}


// ------------------------------------------------------
/// 指定された開始／終了文字列を正規表現として検索し、位置を返す
- (NSArray *)checkRegularExpressionBeginString:(NSString *)beginString withEndString:(NSString *)endString withIgnoreCase:(BOOL)ignoreCase
                                    doColoring:(BOOL)doColoring pairStringKind:(NSUInteger)pairKind
// ------------------------------------------------------
{
    NSUInteger options = (ignoreCase) ? OgreIgnoreCaseOption : OgreNoneOption;
    OGRegularExpression *regex;
    NSEnumerator *enumerator;
    OGRegularExpressionMatch *match;
    NSRange beginRange, endRange, attrRange;
    NSMutableArray *outArray = [NSMutableArray array];
    NSUInteger QCStart = 0, QCEnd = 0;

    NS_DURING
        regex = [OGRegularExpression regularExpressionWithString:beginString options:options];
    NS_HANDLER
        // 構文エラーなど例外は無視 (OgreKit付属のRegularExpressionTestのコードを参考にしています)
        // 何もしない
        return nil;
    NS_ENDHANDLER

    enumerator = [regex matchEnumeratorInString:[self localString]];

    while (match = [enumerator nextObject]) {
        if ([self isIndicatorShown] && ([NSApp runModalSession:[self modalSession]] != NSRunContinuesResponse)) {
            return nil;
        }
        @autoreleasepool {
            beginRange = [match rangeOfMatchedString];
            NS_DURING
                endRange = [[self localString] rangeOfRegularExpressionString:endString
                                                                      options:options
                                                                        range:NSMakeRange(NSMaxRange(beginRange),
                                                                                          [[self localString] length] - NSMaxRange(beginRange))];
            NS_HANDLER
                return nil;
            NS_ENDHANDLER
            if (endRange.location != NSNotFound) {
                attrRange = NSUnionRange(beginRange, endRange);
                attrRange.location += [self updateRange].location;
            } else {
                continue;
            }
            if (doColoring) {
                [outArray addObject:[NSValue valueWithRange:attrRange]];
            } else {
                if (pairKind >= k_QC_CommentBaseNum) {
                    QCStart = k_QC_Start;
                    QCEnd = k_QC_End;
                } else {
                    QCStart = QCEnd = k_notUseStartEnd;
                }
                [outArray addObject:@{k_QCPosition:@(attrRange.location),
                                      k_QCPairKind: @(pairKind),
                                      k_QCStartEnd: @(QCStart),
                                      k_QCStrLength: @0U}];
                [outArray addObject:@{k_QCPosition: @(NSMaxRange(attrRange)),
                                      k_QCPairKind: @(pairKind),
                                      k_QCStartEnd: @(QCEnd),
                                      k_QCStrLength: @0U}];
            }
        } // ==== end-autoreleasepool
    }
    return outArray;
}


// ------------------------------------------------------
/// コメントをカラーリング
- (void)setAttrToCommentsWithSyntaxArray:(NSArray *)syntaxArray
                        withSingleQuotes:(BOOL)withSingleQuotes withDoubleQuotes:(BOOL)withDoubleQuotes
                         updateIndicator:(BOOL)updateIndicator
// ------------------------------------------------------
{
    NSMutableArray *posArray = [NSMutableArray array];
    NSMutableDictionary *simpleWordsDict = [NSMutableDictionary dictionaryWithCapacity:40];
    NSArray *tmpArray = nil;
    NSDictionary *strDict, *curRecord, *checkRecord, *attrs;
    NSString *beginStr = nil, *endStr = nil;
    NSMutableString *simpleWordsChar = [NSMutableString string];
    NSRange coloringRange;
    NSInteger i, j, index = 0, syntaxCount = [syntaxArray count], coloringCount;
    NSUInteger QCKind, start, end, checkStartEnd;
    double indicatorValue, beginDouble = [self doubleValueOfIndicator];
    BOOL hasEnd = NO;

    // コメント定義の位置配列を生成
    for (i = 0; i < syntaxCount; i++) {
        if ([self isIndicatorShown] && ((i % 10) == 0) &&
            ([NSApp runModalSession:[self modalSession]] != NSRunContinuesResponse)) { return; }
        strDict = syntaxArray[i];
        beginStr = strDict[k_SCKey_beginString];

        if ([beginStr length] < 1) { continue; }

        endStr = strDict[k_SCKey_endString];

        if ([strDict[k_SCKey_regularExpression] boolValue]) {
            if ((endStr != nil) && ([endStr length] > 0)) {
                tmpArray = [self rangesRegularExpressionBeginString:beginStr
                                                      withEndString:endStr
                                                     withIgnoreCase:[strDict[k_SCKey_ignoreCase] boolValue]
                                                         doColoring:NO
                                                     pairStringKind:(k_QC_CommentBaseNum + i)];
                [posArray addObjectsFromArray:tmpArray];
            } else {
                tmpArray = [self rangesRegularExpressionString:beginStr
                                                withIgnoreCase:[strDict[k_SCKey_ignoreCase] boolValue]
                                                    doColoring:NO
                                                pairStringKind:(k_QC_CommentBaseNum + i)];
                [posArray addObjectsFromArray:tmpArray];
            }
        } else {
            if ((endStr != nil) && ([endStr length] > 0)) {
                tmpArray = [self rangesBeginString:beginStr withEndString:endStr
                                        doColoring:NO pairStringKind:(k_QC_CommentBaseNum + i)];
                [posArray addObjectsFromArray:tmpArray];
            } else {
                NSNumber *len = @([beginStr length]);
                id wordsArray = simpleWordsDict[len];
                if (wordsArray) {
                    [wordsArray addObject:beginStr];
                } else {
                    wordsArray = [NSMutableArray arrayWithObject:beginStr];
                    simpleWordsDict[len] = wordsArray;
                }
                [simpleWordsChar appendString:beginStr];
            }
        }
    } // end-for
    // シングルクォート定義があれば位置配列を生成、マージ
    if (withSingleQuotes) {
        [posArray addObjectsFromArray:[self rangesBeginString:@"\'" withEndString:@"\'"
                                                   doColoring:NO pairStringKind:k_QC_SingleQ]];
    }
    // ダブルクォート定義があれば位置配列を生成、マージ
    if (withDoubleQuotes) {
        [posArray addObjectsFromArray:[self rangesBeginString:@"\"" withEndString:@"\""
                                                   doColoring:NO pairStringKind:k_QC_DoubleQ]];
    }
    // コメントもクォートもなければ、もどる
    if (([posArray count] < 1) && ([simpleWordsDict count] < 1)) { return; }

    // まず、開始文字列だけのコメント定義があればカラーリング
    if (([simpleWordsDict count]) > 0) {
        [self setAttrToSimpleWordsArrayDict:simpleWordsDict withCharString:simpleWordsChar];
    }

    // カラーリング対象がなければ、もどる
    if ([posArray count] < 1) { return; }
    NSSortDescriptor *theDescriptor = [[NSSortDescriptor alloc] initWithKey:k_QCPosition ascending:YES];
    [posArray sortUsingDescriptors:@[theDescriptor]];
    coloringCount = [posArray count];

    QCKind = k_notUseKind;
    while (index < coloringCount) {
        // インジケータ更新
        if ((updateIndicator) && ((index % 10) == 0)) {
            indicatorValue = beginDouble + (double)(index / (double)coloringCount * 200);
            [self setDoubleIndicator:(double)indicatorValue];
        }
        curRecord = posArray[index];
        if (QCKind == k_notUseKind) {
            if ([curRecord[k_QCStartEnd] unsignedIntegerValue] == k_QC_End) {
                index++;
                continue;
            }
            QCKind = [curRecord[k_QCPairKind] unsignedIntegerValue];
            start = [curRecord[k_QCPosition] unsignedIntegerValue];
            index++;
            continue;
        }
        if (QCKind == [curRecord[k_QCPairKind] unsignedIntegerValue]) {
            if (QCKind == k_QC_SingleQ) {
                attrs = [self singleQuotesAttrs];
            } else if (QCKind == k_QC_DoubleQ) {
                attrs = [self doubleQuotesAttrs];
            } else if (QCKind >= k_QC_CommentBaseNum) {
                attrs = [self currentAttrs];
            } else {
                NSLog(@"setAttrToCommentsWithSyntaxArray:withSyngleQuotes::... \n Can not set Attrs.");
                break;
            }
            end = [curRecord[k_QCPosition] unsignedIntegerValue] +
                  [curRecord[k_QCStrLength] unsignedIntegerValue];
            coloringRange = NSMakeRange(start + [self updateRange].location, end - start);
            if ([self isPrinting]) {
                [[[self layoutManager] firstTextView] setTextColor:attrs[NSForegroundColorAttributeName] range:coloringRange];
            } else {
                [[self layoutManager] addTemporaryAttributes:attrs forCharacterRange:coloringRange];
            }
            QCKind = k_notUseKind;
            index++;
        } else {
            // 「終わり」があるか調べる
            for (j = (index + 1); j < coloringCount; j++) {
                checkRecord = posArray[j];
                if (QCKind == [checkRecord[k_QCPairKind] unsignedIntegerValue]) {
                    checkStartEnd = [checkRecord[k_QCStartEnd] unsignedIntegerValue];
                    if ((checkStartEnd == k_notUseStartEnd) || (checkStartEnd == k_QC_End)) {
                        hasEnd = YES;
                        break;
                    }
                }
                hasEnd = NO;
            }
            // 「終わり」があればそこへジャンプ、なければ最後までカラーリングして、抜ける
            if (hasEnd) {
                index = j;
            } else {
                if (QCKind == k_QC_SingleQ) {
                    attrs = [self singleQuotesAttrs];
                } else if (QCKind == k_QC_DoubleQ) {
                    attrs = [self doubleQuotesAttrs];
                } else if (QCKind >= k_QC_CommentBaseNum) {
                    attrs = [self currentAttrs];
                } else {
                    NSLog(@"setAttrToCommentsWithSyntaxArray:withSyngleQuotes::... \n Can not set Attrs.");
                    break;
                }
                coloringRange = NSMakeRange(start + [self updateRange].location, NSMaxRange([self updateRange]) - start);
                if ([self isPrinting]) {
                    [[[self layoutManager] firstTextView] setTextColor:
                     attrs[NSForegroundColorAttributeName] range:coloringRange];
                } else {
                    [[self layoutManager] addTemporaryAttributes:attrs forCharacterRange:coloringRange];
                }
                break;
            }
        }
    }
}


// ------------------------------------------------------
/// 与えられた文字列の末尾にエスケープシーケンス（バックスラッシュ）がいくつあるかを返す
- (NSUInteger)numberOfEscapeSequenceInString:(NSString *)string
// ------------------------------------------------------
{
    NSUInteger numberOfEscapeSequence = 0, length = [string length];
    NSInteger i;

    for (i = (length - 1); i >= 0; i--) {
        if ([string characterAtIndex:i] == '\\') {
            numberOfEscapeSequence++;
        } else {
            break;
        }
    }
    return numberOfEscapeSequence;
}


// ------------------------------------------------------
/// 不可視文字表示時に文字色を変更する
- (void)setOtherInvisibleCharsAttrs
// ------------------------------------------------------
{
    if (![[self layoutManager] showOtherInvisibles]) { return; }
    NSColor *color = [NSUnarchiver unarchiveObjectWithData:[[NSUserDefaults standardUserDefaults]
                                                            valueForKey:k_key_invisibleCharactersColor]];
    if ([[[self layoutManager] firstTextView] textColor] == color) { return; }
    NSDictionary *attrs = @{};
    NSMutableArray *targetArray = [NSMutableArray array];
    NSScanner *scanner = [NSScanner scannerWithString:[self localString]];
    NSString *controlStr;
    NSRange coloringRange;
    NSInteger start;

    if (![self isPrinting]) {
        attrs = @{NSForegroundColorAttributeName: color};
    }

    while (![scanner isAtEnd]) {
        (void)[scanner scanUpToCharactersFromSet:[NSCharacterSet controlCharacterSet] intoString:nil];
        start = [scanner scanLocation];
        if ([scanner scanCharactersFromSet:[NSCharacterSet controlCharacterSet]
                                intoString:&controlStr]) {
            [targetArray addObject:[NSValue valueWithRange:NSMakeRange(start, [controlStr length])]];
        }
    }
    if ([self isPrinting]) {
        for (NSValue *value in targetArray) {
            coloringRange = [value rangeValue];
            coloringRange.location += [self updateRange].location;
            [[[self layoutManager] firstTextView] setTextColor:color range:coloringRange];
        }
    } else {
        for (NSValue *value in targetArray) {
            coloringRange = [value rangeValue];
            coloringRange.location += [self updateRange].location;
            [[self layoutManager] addTemporaryAttributes:attrs forCharacterRange:coloringRange];
        }
    }
}


// ------------------------------------------------------
/// カラーリングを実行
- (void)doColoring
// ------------------------------------------------------
{
    NSUInteger length = [self wholeStringLength];
    if (length < 1) { return; }
    [self setLocalString:[[self wholeString] substringWithRange:[self updateRange]]]; // カラーリング対象文字列を保持
    if ([[self localString] length] < 1) { return; }

    // 現在あるカラーリングを削除、カラーリング不要なら不可視文字のカラーリングだけして戻る
    [[self layoutManager] removeTemporaryAttribute:NSForegroundColorAttributeName forCharacterRange:[self updateRange]];
    if (([[self coloringDictionary][k_SCKey_numOfObjInArray] integerValue] == 0) ||
        ([[self syntaxStyleName] isEqualToString:NSLocalizedString(@"None",@"")]))
    {
        [self setOtherInvisibleCharsAttrs];
        return;
    }

    // 規定の文字数以上の場合にはカラーリングインジケータシートを表示
    // （ただし、k_key_showColoringIndicatorTextLength が「0」の時は表示しない）
    NSWindow *documentWindow = nil;
    NSWindow *sheet = nil;
    if (([self showColoringIndicatorTextLength] > 0) && ([self updateRange].length > [self showColoringIndicatorTextLength])) {
        [self setIsIndicatorShown:YES];
        [self setDoubleIndicator:0];
        if ([self isPrinting]) {
            documentWindow = [NSApp mainWindow];
            [[self coloringCaption] setStringValue:NSLocalizedString(@"Coloring print text...", nil)];
        } else {
            documentWindow = [[[self layoutManager] firstTextView] window];
            [[self coloringCaption] setStringValue:NSLocalizedString(@"Coloring text...", nil)];
        }
        sheet = [[self coloringIndicator] window];
        [NSApp beginSheet:sheet
           modalForWindow:documentWindow
            modalDelegate:self
           didEndSelector:NULL
              contextInfo:NULL];
        [self setModalSession:[NSApp beginModalSessionForWindow:sheet]];
    }

    NSArray *colorArray = @[k_key_allSyntaxColors];
    NSArray *syntaxArray = @[k_SCKey_allColoringArrays];
    NSArray *array, *inArray;
    NSMutableDictionary *simpleWordsDict = [NSMutableDictionary dictionaryWithCapacity:40];
    NSMutableString *simpleWordsChar = [NSMutableString stringWithString:k_allAlphabetChars];
    NSString *beginStr = nil, *endStr = nil;
    NSDictionary *strDict;
    NSRange coloringRange;
    NSInteger i, j, count, syntaxArrayCount = [syntaxArray count];
    BOOL isSingleQuotes = NO, isDoubleQuotes = NO;
    double indicatorValue, beginDouble = 0.0;

    NS_DURING
        // Keywords > Commands > Values > Numbers > Strings > Characters > Comments
        for (i = 0; i < syntaxArrayCount; i++) {

            if ([self isIndicatorShown] && ([NSApp runModalSession:[self modalSession]] != NSRunContinuesResponse)) {
                // キャンセルされたら、現在あるカラーリング（途中まで色づけられたもの）を削除して戻る
                if ([self isPrinting]) {
                    [[[self layoutManager] firstTextView] setTextColor:[[[self layoutManager] firstTextView] textColor]
                                                                 range:[self updateRange]];
                } else {
                    [[self layoutManager] removeTemporaryAttribute:NSForegroundColorAttributeName
                                                 forCharacterRange:[self updateRange]];
                    [[[CEDocumentController sharedDocumentController] documentForWindow:documentWindow]
                     doSetSyntaxStyle:NSLocalizedString(@"None",@"") delay:YES];
                }
                break;
            }

            array = [self coloringDictionary][syntaxArray[i]];
            count = [array count];
            [self setTextColor:[NSUnarchiver unarchiveObjectWithData:
                                [[NSUserDefaults standardUserDefaults] valueForKey:colorArray[i]]]]; // ===== retain
            [self setCurrentAttrs:@{NSForegroundColorAttributeName: [self textColor]}]; // ===== retain

            // シングル／ダブルクォートのカラーリングがあったら、コメントとともに別メソッドでカラーリングする
            if ([syntaxArray[i] isEqualToString:k_SCKey_commentsArray]) {
                [self setAttrToCommentsWithSyntaxArray:array withSingleQuotes:isSingleQuotes
                                      withDoubleQuotes:isDoubleQuotes updateIndicator:[self isIndicatorShown]];
                [self setTextColor:nil]; // ===== release
                [self setCurrentAttrs:nil]; // ===== release
                break;
            }
            if (count < 1) {
                if ([self isIndicatorShown]) {
                    [self setDoubleIndicator:((i + 1) * 100.0)];
                }
                continue;
            }

            if ([self isIndicatorShown]) {
                beginDouble = [self doubleValueOfIndicator];
            }
            CEPrivateMutableArray *targetArray = [[CEPrivateMutableArray alloc] initWithCapacity:10];
            NSArray *tmpArray = nil;
            for (j = 0; j < count; j++) {
                @autoreleasepool {
                    strDict = array[j];
                    beginStr = strDict[k_SCKey_beginString];

                    if ([beginStr length] < 1) { continue; }

                    endStr = strDict[k_SCKey_endString];

                    if ([strDict[k_SCKey_regularExpression] boolValue]) {
                        if ((endStr != nil) && ([endStr length] > 0)) {
                            tmpArray = [self rangesRegularExpressionBeginString:beginStr
                                                                  withEndString:endStr
                                                                 withIgnoreCase:[strDict[k_SCKey_ignoreCase] boolValue]
                                                                     doColoring:YES
                                                                 pairStringKind:k_notUseKind];
                            if (tmpArray != nil) {
                                [targetArray addObject:tmpArray];
                            }
                        } else {
                            tmpArray = [self rangesRegularExpressionString:beginStr
                                                            withIgnoreCase:[strDict[k_SCKey_ignoreCase] boolValue]
                                                                doColoring:YES
                                                            pairStringKind:k_notUseKind];
                            if (tmpArray != nil) {
                                [targetArray addObject:tmpArray];
                            }
                        }
                    } else {
                        if ((endStr != nil) && ([endStr length] > 0)) {
                            // 開始／終了ともに入力されていたらクォートかどうかをチェック、最初に出てきたクォートのみを把握
                            if ([beginStr isEqualToString:@"\'"] && [endStr isEqualToString:@"\'"]) {
                                if (!isSingleQuotes) {
                                    isSingleQuotes = YES;
                                    [self setSingleQuotesAttrs:[self currentAttrs]]; // ===== retain
                                }
                                continue;
                            }
                            if ([beginStr isEqualToString:@"\""] && [endStr isEqualToString:@"\""]) {
                                if (!isDoubleQuotes) {
                                    isDoubleQuotes = YES;
                                    [self setDoubleQuotesAttrs:[self currentAttrs]]; // ===== retain
                                }
                                continue;
                            }
                            tmpArray = [self rangesBeginString:beginStr withEndString:endStr
                                                    doColoring:YES pairStringKind:k_notUseKind];
                            if (tmpArray != nil) {
                                [targetArray addObject:tmpArray];
                            }
                        } else {
                            NSNumber *len = @([beginStr length]);
                            id wordsArray = simpleWordsDict[len];
                            if (wordsArray) {
                                [wordsArray addObject:beginStr];
                            } else {
                                wordsArray = [NSMutableArray arrayWithObject:beginStr];
                                simpleWordsDict[len] = wordsArray;
                            }
                            [simpleWordsChar appendString:beginStr];
                        }
                    }
                    // インジケータ更新
                    if ([self isIndicatorShown] && ((j % 10) == 0)) {
                        indicatorValue = beginDouble + (double)(j / (double)count * k_perCompoIncrement);
                        [self setDoubleIndicator:(double)indicatorValue];
                        [[self coloringIndicator] displayIfNeeded];
                    }
                } // ==== end-autoreleasepool
            } // end-for (j)
            if (([simpleWordsDict count]) > 0) {
                tmpArray = [self rangesSimpleWordsArrayDict:simpleWordsDict withCharString:simpleWordsChar];
                if (tmpArray != nil) {
                    [targetArray addObject:tmpArray];
                }
                [simpleWordsDict removeAllObjects];
                [simpleWordsChar setString:k_allAlphabetChars];
            }
            // カラーリング実行
            for (inArray in targetArray) {
                // IMP を使ってメソッド呼び出しを高速化
                // http://www.mulle-kybernetik.com/artikel/Optimization/opti-3.html
                // http://homepage.mac.com/mkino2/spec/optimize/methodCall.html
                if ([self isPrinting]) {
                    IMP impSetTextColor = [[[self layoutManager] firstTextView] methodForSelector:@selector(setTextColor:range:)];
                    void (*funcSetTextColor)(id, SEL, id, NSRange) = (void(*)(id, SEL, id, NSRange))impSetTextColor;  // cast for ARC
                    for (NSValue *value in inArray) {
                        coloringRange = [value rangeValue];
                        coloringRange.location += [self updateRange].location;
                        funcSetTextColor([[self layoutManager] firstTextView],
                                         @selector(setTextColor:range:),
                                         [self textColor], coloringRange);
                    }
                } else {
                    IMP impAddTempAttrs = [[self layoutManager] methodForSelector:@selector(addTemporaryAttributes:forCharacterRange:)];
                    void (*funcAddTempAttrs)(id, SEL, id, NSRange) = (void(*)(id, SEL, id, NSRange))impAddTempAttrs;  // cast for ARC
                    for (NSValue *value in inArray) {
                        coloringRange = [value rangeValue];
                        coloringRange.location += [self updateRange].location;
                        funcAddTempAttrs([self layoutManager],
                                         @selector(addTemporaryAttributes:forCharacterRange:),
                                         [self currentAttrs], coloringRange);
                    }
                }
            }
            if ([self isIndicatorShown]) {
                [self setDoubleIndicator:((i + 1) * 100.0)];
            }
            [self setTextColor:nil];  // ===== release
            [self setCurrentAttrs:nil];
        } // end-for (i)
        [self setOtherInvisibleCharsAttrs];
    NS_HANDLER
        // 何もしない
        NSLog(@"ERROR in \"%s\"", __PRETTY_FUNCTION__);
    NS_ENDHANDLER

    // インジーケータシートを片づける
    if ([self isIndicatorShown]) {
        [NSApp endModalSession:[self modalSession]];
        [NSApp endSheet:sheet];
        [sheet orderOut:self];
        [self setIsIndicatorShown:NO];
        [self setModalSession:nil];
    }
    // 不要な変数を片づける
    [self setSingleQuotesAttrs:nil];
    [self setDoubleQuotesAttrs:nil];
    [self setLocalString:nil];
}


// ------------------------------------------------------
/// カラーリングインジケータの値を返す
- (double)doubleValueOfIndicator
// ------------------------------------------------------
{
    return [[self coloringIndicator] doubleValue];
}


// ------------------------------------------------------
/// カラーリングインジケータの値を設定
- (void)setDoubleIndicator:(double)doubleIndicator
// ------------------------------------------------------
{
    [[self coloringIndicator] setDoubleValue:doubleIndicator];
}

@end
