/*
=================================================
CEDocument+ScriptingSupport
(for CotEditor)

 Copyright (C) 2004-2007 nakamuxu.
 Copyright (C) 2014 CotEditor Project
 http://coteditor.github.io
=================================================

encoding="UTF-8"
Created:2005.03.12
 
 -fno-objc-arc
 
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

#import "CEDocument+ScriptingSupport.h"

//=======================================================
// Private method
//
//=======================================================

@interface CEDocument (ScriptingSupportPrivate)
- (BOOL)doFind:(NSString *)inSearchString range:(NSRange)inRange 
            option:(unsigned)inMask withRegularExpression:(BOOL)inRE;
@end


//------------------------------------------------------------------------------------------




@implementation CEDocument (ScriptingSupport)

#pragma mark ===== Public method =====

//=======================================================
// Public method
//
//=======================================================

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

    [[[self editorView] textView] replaceAllStringTo:theNewString];
    [self cleanUpTextStorage:(NSTextStorage *)[inNotification object]];
}




#pragma mark ===== AppleScript accessor =====

//=======================================================
// AppleScript accessor
//
//=======================================================

// ------------------------------------------------------
- (NSTextStorage *)textStorage
// ドキュメントの文字列を返す(text型)
// ------------------------------------------------------
{
    NSTextStorage *outStorage = [[[NSTextStorage alloc] initWithString:[[self editorView] stringForSave]] autorelease];

    [outStorage setDelegate:self];
    // 0.5秒後にデリゲートをやめる（放置するとクラッシュの原因になる）
    [self performSelector:@selector(cleanUpTextStorage:) withObject:outStorage afterDelay:0.5];

    return outStorage;
}


// ------------------------------------------------------
- (void)setTextStorage:(id)inObject;
// ドキュメントの文字列をセット（全置換）
// ------------------------------------------------------
{
    if ([inObject isKindOfClass:[NSTextStorage class]]) {
        [[[self editorView] textView] replaceAllStringTo:[inObject string]];
    }
}


// ------------------------------------------------------
- (NSTextStorage *)contents
// ドキュメントの文字列を返す(text型)
// ------------------------------------------------------
{
    return [self textStorage];
}


// ------------------------------------------------------
- (void)setContents:(id)inObject
// ドキュメントの文字列をセット（全置換）
// ------------------------------------------------------
{
    [self setTextStorage:inObject];
}


// ------------------------------------------------------
- (NSNumber *)length
// ドキュメントの文字数を返す(integer型)
// ------------------------------------------------------
{
    int theLength = [[[self editorView] stringForSave] length];

    return @(theLength);
}


// ------------------------------------------------------
- (CELineEnding)lineEnding
// 行末コードを返す(enum型)
// ------------------------------------------------------
{
    NSInteger theCode = [[self editorView] lineEndingCharacter];
    CELineEnding outLineEnding;

    switch (theCode) {
    case 1:
        outLineEnding = CELineEndingCR;
        break;
    case 2:
        outLineEnding = CELineEndingCRLF;
        break;
    default:
        outLineEnding = CELineEndingLF;
        break;
    }
    return outLineEnding;
}


// ------------------------------------------------------
- (void)setLineEnding:(CELineEnding)inEnding
// 行末コードをセット
// ------------------------------------------------------
{
    NSInteger theCode;

    switch (inEnding) {
    case CELineEndingCR:
        theCode = 1;
        break;
    case CELineEndingCRLF:
        theCode = 2;
        break;
    default:
        theCode = 0;
        break;
    }
    [self doSetNewLineEndingCharacterCode:theCode];
}


// ------------------------------------------------------
- (NSString *)encoding
// エンコーディング名を返す(Unicode text型)
// ------------------------------------------------------
{
    return [NSString localizedNameOfStringEncoding:[self encodingCode]];
}


// ------------------------------------------------------
- (NSString *)IANACharSetName
// エンコーディング名の IANA Charset 名を返す(Unicode text型)
// ------------------------------------------------------
{
    NSString *outName = [self currentIANACharSetName];

    // 得られなければ空文字を返す
    if (outName == nil) {
        return @"";
    }
    return outName;
}


// ------------------------------------------------------
- (NSString *)coloringStyle
// カラーリングスタイル名を返す(Unicode text型)
// ------------------------------------------------------
{
    return [[self editorView] syntaxStyleNameToColoring];
}


// ------------------------------------------------------
- (void)setColoringStyle:(NSString *)inStyleName
// カラーリングスタイル名をセット
// ------------------------------------------------------
{
    [self doSetSyntaxStyle:inStyleName];
}


// ------------------------------------------------------
- (CETextSelection *)selection
// selection-object を返す
// ------------------------------------------------------
{
    return _selection;
}


// ------------------------------------------------------
- (void)setSelection:(id)inObject
// 選択範囲へテキストを設定
// ------------------------------------------------------
{
    if ([inObject isKindOfClass:[NSString class]]) {
        [_selection setContents:inObject];
    }
}


// ------------------------------------------------------
- (NSNumber *)wrapLines
// ワードラップの状態を返す
// ------------------------------------------------------
{
    BOOL theBOOL = [[self editorView] wrapLines];

    return @(theBOOL);
}


// ------------------------------------------------------
- (void)setWrapLines:(NSNumber *)inValue
// ワードラップを切り替える
// ------------------------------------------------------
{
    [[self editorView] setWrapLines:[inValue boolValue]];
}


// ------------------------------------------------------
- (NSNumber *)lineSpacing
// 行間値を返す
// ------------------------------------------------------
{
    return @([[[self editorView] textView] lineSpacing]);
}


// ------------------------------------------------------
- (void)setLineSpacing:(NSNumber *)lineSpacing
// 行間値をセット
// ------------------------------------------------------
{
    [[[self editorView] textView] setLineSpacing:(CGFloat)[lineSpacing doubleValue]];
}


#pragma mark ===== AppleScript handler =====

//=======================================================
// AppleScript handler
//
//=======================================================

// ------------------------------------------------------
- (NSNumber *)handleConvert:(NSScriptCommand *)inCommand
// エンコーディングを変更し、テキストをコンバートする
// ------------------------------------------------------
{
    NSDictionary *theArg = [inCommand evaluatedArguments];
    NSString *theEncodingName = [theArg valueForKey:@"newEncoding"];
    NSStringEncoding theEncoding = [[NSApp delegate] encodingFromName:theEncodingName];
    BOOL theResult = NO;

    if (theEncoding == NSNotFound) {
        theResult = NO;
    } else if (theEncoding == [self encodingCode]) {
        theResult = YES;
    } else {
        NSString *theActionName = @"TEST";
        BOOL theLossy = NO;

        theLossy = [[theArg valueForKey:@"Lossy"] boolValue];
        theResult = [self doSetEncoding:theEncoding updateDocument:YES 
                askLossy:NO lossy:theLossy asActionName:theActionName];
    }

    return @(theResult);
}


// ------------------------------------------------------
- (NSNumber *)handleReinterpret:(NSScriptCommand *)inCommand
// エンコーディングを変更し、テキストを再解釈する
// ------------------------------------------------------
{
    NSDictionary *theArg = [inCommand evaluatedArguments];
    NSString *theEncodingName = [theArg valueForKey:@"newEncoding"];
    NSStringEncoding theEncoding = [[NSApp delegate] encodingFromName:theEncodingName];
    BOOL theResult = NO;

    if ((theEncoding == NSNotFound) || ([self fileURL] == nil)) {
        theResult = NO;
    } else if (theEncoding == [self encodingCode]) {
        theResult = YES;
    } else if ([self stringFromData:[NSData dataWithContentsOfURL:[self fileURL]]
                encoding:theEncoding xattr:NO]) {
        [self setStringToEditorView];
        // ダーティーフラグをクリア
        [self updateChangeCount:NSChangeCleared];
        // ツールバーアイテムの選択状態をセット
        [[[self windowController] toolbarController] setSelectEncoding:[self encodingCode]];
        theResult = YES;
    }

    return @(theResult);
}


// ------------------------------------------------------
- (NSNumber *)handleFind:(NSScriptCommand *)inCommand
// 検索
// ------------------------------------------------------
{
    NSDictionary *theArg = [inCommand evaluatedArguments];
    NSString *theSearch = [theArg valueForKey:@"targetString"];
    if ((theSearch == nil) || ([theSearch length] < 1)) { return @NO; }
    BOOL theBoolIsRE = ([theArg valueForKey:@"regularExpression"] != nil) ? 
               [[theArg valueForKey:@"regularExpression"] boolValue] : NO;
    BOOL theBoolIgnoreCase = ([theArg valueForKey:@"ignoreCase"] != nil) ? 
               [[theArg valueForKey:@"ignoreCase"] boolValue] : NO;
    BOOL theBoolBackwards = ([theArg valueForKey:@"backwardsSearch"] != nil) ? 
               [[theArg valueForKey:@"backwardsSearch"] boolValue] : NO;
    BOOL theBoolWrapSearch = ([theArg valueForKey:@"wrapSearch"] != nil) ? 
               [[theArg valueForKey:@"wrapSearch"] boolValue] : NO;
    NSString *theWholeStr = [[self editorView] stringForSave];
    NSInteger theWholeLength = [theWholeStr length];
    if (theWholeLength < 1) { return @NO; }
    NSRange theSelectionRange = [[self editorView] selectedRange];
    NSRange theTargetRange;

    if (theBoolBackwards) {
        theTargetRange = NSMakeRange(0, theSelectionRange.location);
    } else {
        theTargetRange = NSMakeRange(NSMaxRange(theSelectionRange), 
                            theWholeLength - NSMaxRange(theSelectionRange));
    }
    NSUInteger theMask = 0;
    if (theBoolIgnoreCase) {
        theMask |= (theBoolIsRE) ? OgreIgnoreCaseOption : NSCaseInsensitiveSearch;
    }
    if (theBoolBackwards) {
        theMask |= NSBackwardsSearch;
    }

    BOOL theBoolResult = [self doFind:theSearch range:theTargetRange 
                option:theMask withRegularExpression:theBoolIsRE];
    if ((theBoolResult == NO) && theBoolWrapSearch) {
        theTargetRange = NSMakeRange(0, theWholeLength);
        theBoolResult = [self doFind:theSearch range:theTargetRange 
                option:theMask withRegularExpression:theBoolIsRE];
    }
    
    return @(theBoolResult);
}


// ------------------------------------------------------
- (NSNumber *)handleReplace:(NSScriptCommand *)inCommand
// 置換
// ------------------------------------------------------
{
    NSDictionary *theArg = [inCommand evaluatedArguments];
    NSString *theSearch = [theArg valueForKey:@"targetString"];
    if ((theSearch == nil) || ([theSearch length] < 1)) { return @NO; }
    BOOL theBoolIsRE = ([theArg valueForKey:@"regularExpression"] != nil) ? 
               [[theArg valueForKey:@"regularExpression"] boolValue] : NO;
    BOOL theBoolIgnoreCase = ([theArg valueForKey:@"ignoreCase"] != nil) ? 
               [[theArg valueForKey:@"ignoreCase"] boolValue] : NO;
    BOOL theBoolAll = ([theArg valueForKey:@"all"] != nil) ? 
               [[theArg valueForKey:@"all"] boolValue] : NO;
    BOOL theBoolBackwards = ([theArg valueForKey:@"backwardsSearch"] != nil) ? 
               [[theArg valueForKey:@"backwardsSearch"] boolValue] : NO;
    BOOL theBoolWrapSearch = ([theArg valueForKey:@"wrapSearch"] != nil) ? 
               [[theArg valueForKey:@"wrapSearch"] boolValue] : NO;
    NSString *theWholeStr = [[self editorView] stringForSave];
    NSInteger theWholeLength = [theWholeStr length];
    if (theWholeLength < 1) { return @0; }
    NSString *theNewString = [theArg valueForKey:@"newString"];
    if ([theSearch isEqualToString:theNewString]) { return @NO; }
    if (theNewString == nil) { theNewString = @""; }
    NSRange theSelectionRange, theTargetRange;

    if (theBoolAll) {
        theTargetRange = NSMakeRange(0, theWholeLength);
    } else {
        theSelectionRange = [[self editorView] selectedRange];
        if (theBoolBackwards) {
            theTargetRange = NSMakeRange(0, theSelectionRange.location);
        } else {
            theTargetRange = NSMakeRange(NSMaxRange(theSelectionRange), 
                                theWholeLength - NSMaxRange(theSelectionRange));
        }
    }
    NSUInteger theMask = 0;
    if (theBoolIgnoreCase) {
        theMask |= (theBoolIsRE) ? OgreIgnoreCaseOption : NSCaseInsensitiveSearch;
    }
    if (theBoolBackwards) {
        theMask |= NSBackwardsSearch;
    }

    BOOL theBoolResult = NO;
    NSInteger theResult = 0;
    if (theBoolAll) {
        NSMutableString *theTmpStr = [theWholeStr mutableCopy]; // ===== copy
        if (theBoolIsRE) {
            theResult = [theTmpStr replaceOccurrencesOfRegularExpressionString:theSearch 
                            withString:theNewString options:theMask range:theTargetRange];
        } else {
            theResult = [theTmpStr replaceOccurrencesOfString:theSearch 
                            withString:theNewString options:theMask range:theTargetRange];
        }
        if (theResult > 0) {
            [[[self editorView] textView] replaceAllStringTo:theTmpStr];
            [[[self editorView] textView] setSelectedRange:NSMakeRange(0,0)];
        }
        [theTmpStr release]; // ===== release

    } else {
        theBoolResult = [self doFind:theSearch range:theTargetRange 
                    option:theMask withRegularExpression:theBoolIsRE];
        if ((theBoolResult == NO) && theBoolWrapSearch) {
            theTargetRange = NSMakeRange(0, theWholeLength);
            theBoolResult = [self doFind:theSearch range:theTargetRange 
                    option:theMask withRegularExpression:theBoolIsRE];
        }
        if (theBoolResult) {
            [_selection setContents:theNewString]; // （CETextSelection の setContents: の引数は NSString も可）
            theResult = 1;
        }
    }

    return @(theResult);
}


// ------------------------------------------------------
- (void)handleScroll:(NSScriptCommand *)inCommand
// スクロール実行
// ------------------------------------------------------
{
    [self scrollToCenteringSelection];
}


// ------------------------------------------------------
- (NSString *)handleString:(NSScriptCommand *)inCommand
// 指定された範囲の文字列を返す
// ------------------------------------------------------
{
    NSDictionary *theArg = [inCommand evaluatedArguments];
    NSArray *theArray = [theArg valueForKey:@"range"];
    NSInteger theLocation, theLength;
    NSRange theRange;

    if ((theArray == nil) || ([theArray count] < 1)) { return [NSString string]; }
    theLocation = [theArray[0] integerValue];
    theLength = ([theArray count] > 1) ? 
            [theArray[1] integerValue] : 1;
    theRange = [self rangeInTextViewWithLocation:theLocation withLength:theLength];

    if (NSEqualRanges(NSMakeRange(0, 0), theRange)) {
        return @"";
    }
    return [[[[self editorView] textView] string] substringWithRange:theRange];
}



@end




@implementation CEDocument (ScriptingSupportPrivate)

//=======================================================
// Private method
//
//=======================================================

// ------------------------------------------------------
- (BOOL)doFind:(NSString *)inSearchString range:(NSRange)inRange 
            option:(unsigned)inMask withRegularExpression:(BOOL)inRE
// 文字列を検索し、見つかったら選択して結果を返す
// ------------------------------------------------------
{
    NSString *theWholeStr = [[self editorView] stringForSave];
    NSRange theSearchedRange;

    if (inRE) {
        theSearchedRange = 
                [theWholeStr rangeOfRegularExpressionString:inSearchString options:inMask range:inRange];
    } else {
        theSearchedRange = [theWholeStr rangeOfString:inSearchString options:inMask range:inRange];
    }
    if (theSearchedRange.location != NSNotFound) {
        [[self editorView] setSelectedRange:theSearchedRange];
        return YES;
    }
    return NO;
}
@end