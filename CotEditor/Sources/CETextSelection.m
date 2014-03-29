/*
=================================================
CETextSelection
(for CotEditor)

 Copyright (C) 2004-2007 nakamuxu.
 Copyright (C) 2014 CotEditor Project
 http://coteditor.github.io
=================================================

encoding="UTF-8"
Created:2005.03.01
 
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
        [self setDocument:document];
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
    NSString *newString = [(NSTextStorage *)[aNotification object] string];

    [[[[self document] editorView] textView] replaceSelectedStringTo:newString scroll:NO];
    [self cleanUpTextStorage:(NSTextStorage *)[aNotification object]];
}


@end



#pragma mark -

@implementation CETextSelection (ScriptingSupport)

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
    NSString *string = [[[self document] editorView] substringWithSelectionForSave];
    NSTextStorage *storage = [[NSTextStorage alloc] initWithString:string];

    [storage setDelegate:self];
    // 0.5秒後にデリゲートをやめる（放置するとクラッシュの原因になる）
    [self performSelector:@selector(cleanUpTextStorage:) withObject:storage afterDelay:0.5];

    return storage;
}


// ------------------------------------------------------
/// 選択範囲に文字列をセット
- (void)setContents:(id)ContentsObject
// ------------------------------------------------------
{
    if ([ContentsObject isKindOfClass:[NSTextStorage class]]) {
        [[[self document] editorView] replaceTextViewSelectedStringTo:[ContentsObject string] scroll:NO];
    } else if ([ContentsObject isKindOfClass:[NSString class]]) {
        [[[self document] editorView] replaceTextViewSelectedStringTo:ContentsObject scroll:NO];
    }
}


// ------------------------------------------------------
/// 選択範囲の文字の位置と長さを返す(list型)
- (NSArray *)range
// ------------------------------------------------------
{
    NSRange selectedRange = [[[self document] editorView] selectedRange];
    NSArray *rangeArray = @[@(selectedRange.location),
                            @(selectedRange.length)];

    return rangeArray;
}


// ------------------------------------------------------
/// 選択範囲の文字の位置と長さをセット
- (void)setRange:(NSArray *)rangeArray
// ------------------------------------------------------
{
    if ([rangeArray count] != 2) { return; }
    NSInteger location = [rangeArray[0] integerValue];
    NSInteger length = [rangeArray[1] integerValue];

    [[self document] setSelectedCharacterRangeInTextViewWithLocation:location withLength:length];
}


// ------------------------------------------------------
/// 選択範囲の行の位置と長さを返す(list型)
- (NSArray *)lineRange
// ------------------------------------------------------
{
    NSRange selectedRange = [[[self document] editorView] selectedRange];
    NSString *string = [[[self document] editorView] stringForSave];
    NSUInteger lines = 0, currentLine = 0, index = 0, lastLine = 0, length = [string length];
    NSArray *rangeArray;

    if (length > 0) {
        for (index = 0, lines = 0; index < length; lines++) {
            if (index <= selectedRange.location) {
                currentLine = lines + 1;
            }
            if (index < NSMaxRange(selectedRange)) {
                lastLine = lines + 1;
            }
            index = NSMaxRange([string lineRangeForRange:NSMakeRange(index, 0)]);
        }
    }
    rangeArray = @[@(currentLine),
                 @(lastLine - currentLine + 1)];

    return rangeArray;
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

    [[self document] setSelectedLineRangeInTextViewWithLocation:location withLength:length];
}



#pragma mark AppleScript Handlers

//=======================================================
// AppleScript handler
//
//=======================================================

// ------------------------------------------------------
/// 選択範囲を右にシフト
- (void)handleShiftRight:(NSScriptCommand *)command
// ------------------------------------------------------
{
    [[[[self document] editorView] textView] shiftRight:self];
}


// ------------------------------------------------------
/// 選択範囲を左にシフト
- (void)handleShiftLeft:(NSScriptCommand *)command
// ------------------------------------------------------
{
    [[[[self document] editorView] textView] shiftLeft:self];
}


// ------------------------------------------------------
/// 文字列を大文字／小文字／キャピタライズにコンバートし、結果を返す
- (void)handleChangeCase:(NSScriptCommand *)command
// ------------------------------------------------------
{
    NSDictionary *arguments = [command evaluatedArguments];
    CECaseType caseType = [[arguments valueForKey:@"caseType"] unsignedLongValue];

    switch (caseType) {
    case CELowerCase:
        [[[[self document] editorView] textView] exchangeLowercase:self];
        break;
    case CEUpperCase:
        [[[[self document] editorView] textView] exchangeUppercase:self];
        break;
    case CECapitalized:
        [[[[self document] editorView] textView] exchangeCapitalized:self];
        break;
    default:
        break;
    }
}


// ------------------------------------------------------
/// 半角／全角Romanを切り替える
- (void)handleChangeWidthRoman:(NSScriptCommand *)command
// ------------------------------------------------------
{
    NSDictionary *arguments = [command evaluatedArguments];
    CEWidthType widthType = [[arguments valueForKey:@"widthType"] unsignedLongValue];

    switch (widthType) {
    case CEFullwidth:
        [[[[self document] editorView] textView] exchangeFullwidthRoman:self];
        break;
    case CEHalfwidth:
        [[[[self document] editorView] textView] exchangeHalfwidthRoman:self];
        break;
    default:
        break;
    }
}


// ------------------------------------------------------
/// ひらがな／カタカナを切り替える
- (void)handleChangeKana:(NSScriptCommand *)command
// ------------------------------------------------------
{
    NSDictionary *arguments = [command evaluatedArguments];
    CEChangeKanaType changeKanaType = [[arguments valueForKey:@"kanaType"] unsignedLongValue];

    if (changeKanaType == CEHiragana) {
        [[[[self document] editorView] textView] exchangeHiragana:self];
    } else if (changeKanaType == CEKatakana) {
        [[[[self document] editorView] textView] exchangeKatakana:self];
    }
}


// ------------------------------------------------------
/// Unicode 正規化
- (void)handleUnicodeNomalization:(NSScriptCommand *)command
// ------------------------------------------------------
{
    NSDictionary *arguments = [command evaluatedArguments];
    CEUNFType UNFType = [arguments[@"unfType"] unsignedLongValue];
    NSInteger typeCode = 0;

    switch (UNFType) {
    case CENFD: typeCode = 1; break;
    case CENFKC: typeCode = 2; break;
    case CENFKD: typeCode = 3; break;
    default:
        break;
    }
    [[[[self document] editorView] textView] unicodeNormalization:@(typeCode)];
}

@end
