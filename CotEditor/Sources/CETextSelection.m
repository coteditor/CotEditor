/*
 ==============================================================================
 CETextSelection
 
 CotEditor
 http://coteditor.com
 
 Created on 2005-03-01 by nakamuxu
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

#import "CETextSelection.h"
#import "CEDocument+ScriptingSupport.h"


@interface CETextSelection ()

@property (nonatomic, weak) CEDocument *document;

@end





#pragma mark -

@implementation CETextSelection

#pragma mark Public Methods

//=======================================================
// Public method
//
//=======================================================

// ------------------------------------------------------
/// 初期化
- (instancetype)initWithDocument:(CEDocument *)document
// ------------------------------------------------------
{
    self = [super init];
    if (self) {
        _document = document;
    }
    return self;
}

// ------------------------------------------------------
/// 生成した textStorage のデリゲートであることをやめる
- (void)cleanUpTextStorage:(NSTextStorage *)textStorage
// ------------------------------------------------------
{
    [textStorage setDelegate:nil];
}



#pragma mark Delegate and Notifications

//=======================================================
// Delegate method (NSTextStorage)
//  <== NSTextStorage
//=======================================================

// ------------------------------------------------------
/// AppleScriptの返り値としてのtextStorageが更新された
- (void)textStorageDidProcessEditing:(NSNotification *)aNotification
// ------------------------------------------------------
{
    NSTextStorage *storage = (NSTextStorage *)[aNotification object];

    [[[[self document] editor] textView] replaceSelectedStringTo:[storage string] scroll:NO];
    [self cleanUpTextStorage:storage];
}

@end




#pragma mark -

@implementation CETextSelection (ScriptingSupport)

#pragma mark Superclass Methods

//=======================================================
// Superclass methods
//
//=======================================================

// ------------------------------------------------------
/// sdef 内で定義されている名前を返す
- (NSScriptObjectSpecifier *)objectSpecifier
// ------------------------------------------------------
{
    return [[NSNameSpecifier alloc] initWithContainerSpecifier:[[self document] objectSpecifier]
                                                           key:@"text selection"];
}



#pragma mark AppleScript Accessors

//=======================================================
// AppleScript accessor
//
//=======================================================

// ------------------------------------------------------
/// 選択範囲内の文字列を返す(Unicode text型)
- (NSTextStorage *)contents
// ------------------------------------------------------
{
    NSString *string = [[[self document] editor] substringWithSelectionForSave];
    NSTextStorage *storage = [[NSTextStorage alloc] initWithString:string];

    [storage setDelegate:self];
    // 0.5秒後にデリゲートをやめる（放置するとクラッシュの原因になる）
    __weak typeof(self) weakSelf = self;
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.5 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        typeof(self) strongSelf = weakSelf;
        [strongSelf cleanUpTextStorage:storage];
    });

    return storage;
}


// ------------------------------------------------------
/// 選択範囲に文字列をセット
- (void)setContents:(id)ContentsObject
// ------------------------------------------------------
{
    NSString *string;
    
    if ([ContentsObject isKindOfClass:[NSTextStorage class]]) {
        string = [ContentsObject string];
    } else if ([ContentsObject isKindOfClass:[NSString class]]) {
        string = ContentsObject;
    } else {
        return;
    }
    
    [[[self document] editor] replaceTextViewSelectedStringTo:string scroll:NO];
}


// ------------------------------------------------------
/// 選択範囲の文字の位置と長さを返す(list型)
- (NSArray *)range
// ------------------------------------------------------
{
    NSRange range = [[[self document] editor] selectedRange];

    return @[@(range.location),
             @(range.length)];
}


// ------------------------------------------------------
/// 選択範囲の文字の位置と長さをセット
- (void)setRange:(NSArray *)rangeArray
// ------------------------------------------------------
{
    if ([rangeArray count] != 2) { return; }
    NSInteger location = [rangeArray[0] integerValue];
    NSInteger length = [rangeArray[1] integerValue];

    [[self document] setSelectedCharacterRangeInTextViewWithLocation:location length:length];
}


// ------------------------------------------------------
/// 選択範囲の行の位置と長さを返す(list型)
- (NSArray *)lineRange
// ------------------------------------------------------
{
    NSRange selectedRange = [[[self document] editor] selectedRange];
    NSString *string = [[self document] stringForSave];
    NSUInteger currentLine = 0, lastLine = 0, length = [string length];

    if (length > 0) {
        for (NSUInteger index = 0, lines = 0; index < length; lines++) {
            if (index <= selectedRange.location) {
                currentLine = lines + 1;
            }
            if (index < NSMaxRange(selectedRange)) {
                lastLine = lines + 1;
            }
            index = NSMaxRange([string lineRangeForRange:NSMakeRange(index, 0)]);
        }
    }
    
    return @[@(currentLine),
             @(lastLine - currentLine + 1)];;
}


// ------------------------------------------------------
/// 選択範囲の行の位置と長さをセット
- (void)setLineRange:(NSArray *)rangeArray
// ------------------------------------------------------
{
    NSInteger location;
    NSInteger length;

    if ([rangeArray isKindOfClass:[NSNumber class]]) {
        location = [(NSNumber *)rangeArray integerValue];
        length = 1;
    } else if([rangeArray count] == 2) {
        location = [rangeArray[0] integerValue];
        length = [rangeArray[1] integerValue];
    } else {
        return;
    }

    [[self document] setSelectedLineRangeInTextViewWithLocation:location length:length];
}



#pragma mark AppleScript Handlers

//=======================================================
// AppleScript handler
//
//=======================================================

// ------------------------------------------------------
/// 選択範囲を右にシフト
- (void)handleShiftRightScriptCommand:(NSScriptCommand *)command
// ------------------------------------------------------
{
    [[[[self document] editor] textView] shiftRight:self];
}


// ------------------------------------------------------
/// 選択範囲を左にシフト
- (void)handleShiftLeftScriptCommand:(NSScriptCommand *)command
// ------------------------------------------------------
{
    [[[[self document] editor] textView] shiftLeft:self];
}


// ------------------------------------------------------
/// 文字列を大文字／小文字／キャピタライズにコンバートする
- (void)handleChangeCaseScriptCommand:(NSScriptCommand *)command
// ------------------------------------------------------
{
    NSDictionary *arguments = [command evaluatedArguments];
    CECaseType caseType = [arguments[@"caseType"] unsignedIntegerValue];
    NSTextView *textView = [[[self document] editor] textView];

    switch (caseType) {
        case CELowerCase:
            [textView lowercaseWord:self];
            break;
        case CEUpperCase:
            [textView uppercaseWord:self];
            break;
        case CECapitalized:
            [textView capitalizeWord:self];
            break;
    }
}


// ------------------------------------------------------
/// 半角／全角Romanを切り替える
- (void)handleChangeWidthRomanScriptCommand:(NSScriptCommand *)command
// ------------------------------------------------------
{
    NSDictionary *arguments = [command evaluatedArguments];
    CEWidthType widthType = [arguments[@"widthType"] unsignedIntegerValue];
    CETextView *textView = [[[self document] editor] textView];

    switch (widthType) {
        case CEFullwidth:
            [textView exchangeFullwidthRoman:self];
            break;
        case CEHalfwidth:
            [textView exchangeHalfwidthRoman:self];
            break;
    }
}


// ------------------------------------------------------
/// ひらがな／カタカナを切り替える
- (void)handleChangeKanaScriptCommand:(NSScriptCommand *)command
// ------------------------------------------------------
{
    NSDictionary *arguments = [command evaluatedArguments];
    CEChangeKanaType changeKanaType = [arguments[@"kanaType"] unsignedIntegerValue];
    CETextView *textView = [[[self document] editor] textView];
    
    switch (changeKanaType) {
        case CEHiragana:
            [textView exchangeHiragana:self];
            break;
        case CEKatakana:
            [textView exchangeKatakana:self];
            break;
    }
}


// ------------------------------------------------------
/// Unicode 正規化
- (void)handleNormalizeUnicodeScriptCommand:(NSScriptCommand *)command
// ------------------------------------------------------
{
    NSDictionary *arguments = [command evaluatedArguments];
    CEUNFType UNFType = [arguments[@"unfType"] unsignedIntegerValue];
    CETextView *textView = [[[self document] editor] textView];
    
    CEUnicodeNormalizationType typeCode;
    switch (UNFType) {
        case CENFC:  typeCode = CEUnicodeNormalizationNFC; break;
        case CENFD:  typeCode = CEUnicodeNormalizationNFD; break;
        case CENFKC: typeCode = CEUnicodeNormalizationNFKC; break;
        case CENFKD: typeCode = CEUnicodeNormalizationNFKD; break;
    }
    [textView unicodeNormalization:@(typeCode)];
}

@end
