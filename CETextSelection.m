/*
=================================================
CETextSelection
(for CotEditor)

Copyright (C) 2004-2007 nakamuxu.
http://www.aynimac.com/
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
#import "CEDocumentAppleScript.h"


@implementation CETextSelection

#pragma mark ===== Public method =====

//=======================================================
// Public method
//
//=======================================================

// ------------------------------------------------------
- (id)initWithDocument:(CEDocument *)inDocument
// 初期化
// ------------------------------------------------------
{
    self = [super init];
    if (self) {
        _document = [inDocument retain];
    }
    return self;
}


// ------------------------------------------------------
- (void)dealloc
// 後片付け
// ------------------------------------------------------
{
    [_document release];
    [super dealloc];
}


// ------------------------------------------------------
- (void)cleanUpTextStorage:(NSTextStorage *)inTextStorage
// 生成した textStorage のデリゲートであることをやめる
// ------------------------------------------------------
{
    [inTextStorage setDelegate:nil];
}



#pragma mark === Delegate and Notification ===

//=======================================================
// Delegate method (NSTextStorage)
//  <== NSTextStorage
//=======================================================

// ------------------------------------------------------
- (void)textStorageDidProcessEditing:(NSNotification *)inNotification
// AppleScriptの返り値としてのtextStorageが更新された
// ------------------------------------------------------
{
    NSString *theNewString = [(NSTextStorage *)[inNotification object] string];

    [[[_document editorView] textView] replaceSelectedStringTo:theNewString scroll:NO];
    [self cleanUpTextStorage:(NSTextStorage *)[inNotification object]];
}


#pragma mark ===== AppleScript accessor =====

//=======================================================
// AppleScript accessor
//
//=======================================================

// ------------------------------------------------------
- (NSTextStorage *)contents
// 選択範囲内の文字列を返す(Unicode text型)
// ------------------------------------------------------
{
    NSString *theString = [[_document editorView] substringWithSelectionForSave];
    NSTextStorage *outStorage = [[[NSTextStorage alloc] initWithString:theString] autorelease];

    [outStorage setDelegate:self];
    // 0.5秒後にデリゲートをやめる（放置するとクラッシュの原因になる）
    [self performSelector:@selector(cleanUpTextStorage:) withObject:outStorage afterDelay:0.5];

    return outStorage;
}


// ------------------------------------------------------
- (void)setContents:(id)inObject
// 選択範囲に文字列をセット
// ------------------------------------------------------
{
    if ([inObject isKindOfClass:[NSTextStorage class]]) {
        [[_document editorView] replaceTextViewSelectedStringTo:[inObject string] scroll:NO];
    } else if ([inObject isKindOfClass:[NSString class]]) {
        [[_document editorView] replaceTextViewSelectedStringTo:inObject scroll:NO];
    }
}


// ------------------------------------------------------
- (NSArray *)range
// 選択範囲の文字の位置と長さを返す(list型)
// ------------------------------------------------------
{
    NSRange theSelectedRange = [[_document editorView] selectedRange];
    NSArray *outArray = @[[NSNumber numberWithInt:theSelectedRange.location], 
                [NSNumber numberWithInt:theSelectedRange.length]];

    return outArray;
}


// ------------------------------------------------------
- (void)setRange:(NSArray *)inArray
// 選択範囲の文字の位置と長さをセット
// ------------------------------------------------------
{
    if ([inArray count] != 2) { return; }
    NSInteger theLocation = [inArray[0] integerValue];
    NSInteger theLength = [inArray[1] integerValue];

    [_document setSelectedCharacterRangeInTextViewWithLocation:theLocation withLength:theLength];
}


// ------------------------------------------------------
- (NSArray *)lineRange
// 選択範囲の行の位置と長さを返す(list型)
// ------------------------------------------------------
{
    NSRange theSelectedRange = [[_document editorView] selectedRange];
    NSString *theString = [[_document editorView] stringForSave];
    NSUInteger theLines = 0, theCurLine = 0, theIndex = 0, theLastLine = 0, theLength = [theString length];
    NSArray *outArray;

    if (theLength > 0) {
        for (theIndex = 0, theLines = 0; theIndex < theLength; theLines++) {
            if (theIndex <= theSelectedRange.location) {
                theCurLine = theLines + 1;
            }
            if (theIndex < NSMaxRange(theSelectedRange)) {
                theLastLine = theLines + 1;
            }
            theIndex = NSMaxRange([theString lineRangeForRange:NSMakeRange(theIndex, 0)]);
        }
    }
    outArray = @[[NSNumber numberWithInt:theCurLine], 
                [NSNumber numberWithInt:(theLastLine - theCurLine + 1)]];

    return outArray;
}


// ------------------------------------------------------
- (void)setLineRange:(NSArray *)inArray
// 選択範囲の行の位置と長さをセット
// ------------------------------------------------------
{
    NSInteger theLocation;
    NSInteger theLength;

    if ([inArray isKindOfClass:[NSNumber class]]) {
        theLocation = [(NSNumber *)inArray integerValue];
        theLength = 1;
    } else if([inArray count] == 2) {
        theLocation = [inArray[0] integerValue];
        theLength = [inArray[1] integerValue];
    } else {
        return;
    }

    [_document setSelectedLineRangeInTextViewWithLocation:theLocation withLength:theLength];
}



#pragma mark ===== AppleScript handler =====

//=======================================================
// AppleScript handler
//
//=======================================================

// ------------------------------------------------------
- (void)handleShiftRight:(NSScriptCommand *)inCommand
// 選択範囲を右にシフト
// ------------------------------------------------------
{
    [[[_document editorView] textView] shiftRight:self];
}


// ------------------------------------------------------
- (void)handleShiftLeft:(NSScriptCommand *)inCommand
// 選択範囲を左にシフト
// ------------------------------------------------------
{
    [[[_document editorView] textView] shiftLeft:self];
}


// ------------------------------------------------------
- (void)handleChangeCase:(NSScriptCommand *)inCommand
// 文字列を大文字／小文字／キャピタライズにコンバートし、結果を返す
// ------------------------------------------------------
{
    NSDictionary *theArg = [inCommand evaluatedArguments];
    CECaseType theType = [[theArg valueForKey:@"caseType"] unsignedLongValue];

    switch (theType) {
    case CELowerCase:
        [[[_document editorView] textView] exchangeLowercase:self];
        break;
    case CEUpperCase:
        [[[_document editorView] textView] exchangeUppercase:self];
        break;
    case CECapitalized:
        [[[_document editorView] textView] exchangeCapitalized:self];
        break;
    default:
        break;
    }
}


// ------------------------------------------------------
- (void)handleChangeWidthRoman:(NSScriptCommand *)inCommand
// 半角／全角Romanを切り替える
// ------------------------------------------------------
{
    NSDictionary *theArg = [inCommand evaluatedArguments];
    CEWidthType theType = [[theArg valueForKey:@"widthType"] unsignedLongValue];

    switch (theType) {
    case CEFullwidth:
        [[[_document editorView] textView] exchangeFullwidthRoman:self];
        break;
    case CEHalfwidth:
        [[[_document editorView] textView] exchangeHalfwidthRoman:self];
        break;
    default:
        break;
    }
}


// ------------------------------------------------------
- (void)handleChangeKana:(NSScriptCommand *)inCommand
// ひらがな／カタカナを切り替える
// ------------------------------------------------------
{
    NSDictionary *theArg = [inCommand evaluatedArguments];
    CEChangeKanaType theType = [[theArg valueForKey:@"kanaType"] unsignedLongValue];

    if (theType == CEHiragana) {
        [[[_document editorView] textView] exchangeHiragana:self];
    } else if (theType == CEKatakana) {
        [[[_document editorView] textView] exchangeKatakana:self];
    }
}


// ------------------------------------------------------
- (void)handleUnicodeNomalization:(NSScriptCommand *)inCommand
// Unicode 正規化
// ------------------------------------------------------
{
    NSDictionary *theArg = [inCommand evaluatedArguments];
    CEUNFType theType = [theArg[@"unfType"] unsignedLongValue];
    NSInteger theTypeCode = 0;

    switch (theType) {
    case CENFD: theTypeCode = 1; break;
    case CENFKC: theTypeCode = 2; break;
    case CENFKD: theTypeCode = 3; break;
    default:
        break;
    }
    [[[_document editorView] textView] unicodeNormalization:@(theTypeCode)];
}


@end
