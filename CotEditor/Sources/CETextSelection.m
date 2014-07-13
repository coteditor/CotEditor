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
    NSTextStorage *storage = (NSTextStorage *)[aNotification object];

    [[[[self document] editorView] textView] replaceSelectedStringTo:[storage string] scroll:NO];
    [self cleanUpTextStorage:storage];
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
    __block typeof(self) blockSelf = self;
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.5 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        [blockSelf cleanUpTextStorage:storage];
    });

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
    NSRange range = [[[self document] editorView] selectedRange];

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
    NSRange selectedRange = [[[self document] editorView] selectedRange];
    NSString *string = [[[self document] editorView] stringForSave];
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
    CECaseType caseType = [arguments[@"caseType"] unsignedLongValue];
    CETextView *textView = [[[self document] editorView] textView];

    switch (caseType) {
        case CELowerCase:
            [textView exchangeLowercase:self];
            break;
        case CEUpperCase:
            [textView exchangeUppercase:self];
            break;
        case CECapitalized:
            [textView exchangeCapitalized:self];
            break;
    }
}


// ------------------------------------------------------
/// 半角／全角Romanを切り替える
- (void)handleChangeWidthRoman:(NSScriptCommand *)command
// ------------------------------------------------------
{
    NSDictionary *arguments = [command evaluatedArguments];
    CEWidthType widthType = [arguments[@"widthType"] unsignedLongValue];
    CETextView *textView = [[[self document] editorView] textView];

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
- (void)handleChangeKana:(NSScriptCommand *)command
// ------------------------------------------------------
{
    NSDictionary *arguments = [command evaluatedArguments];
    CEChangeKanaType changeKanaType = [arguments[@"kanaType"] unsignedLongValue];
    CETextView *textView = [[[self document] editorView] textView];
    
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
- (void)handleUnicodeNomalization:(NSScriptCommand *)command
// ------------------------------------------------------
{
    NSDictionary *arguments = [command evaluatedArguments];
    CEUNFType UNFType = [arguments[@"unfType"] unsignedLongValue];
    CETextView *textView = [[[self document] editorView] textView];
    
    NSInteger typeCode;
    switch (UNFType) {
        case CENFC:  typeCode = 0; break;
        case CENFD:  typeCode = 1; break;
        case CENFKC: typeCode = 2; break;
        case CENFKD: typeCode = 3; break;
    }
    [textView unicodeNormalization:@(typeCode)];
}

@end
