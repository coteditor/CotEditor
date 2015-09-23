/*
 
 CETextSelection.m
 
 CotEditor
 http://coteditor.com
 
 Created by nakamuxu on 2005-03-01.

 ------------------------------------------------------------------------------
 
 © 2004-2007 nakamuxu
 © 2014-2015 1024jp
 
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

#import "CETextSelection.h"
#import "CEDocument+ScriptingSupport.h"


@interface CETextSelection ()

@property (nonatomic, weak) CEDocument *document;

@end




#pragma mark -

@implementation CETextSelection


#pragma mark Superclass Methods

//------------------------------------------------------
/// override designated initializer
- (nullable instancetype)init
//------------------------------------------------------
{
    [NSException raise:NSGenericException
                format:@"Disabled. Use +[[%@ alloc] %@] instead.",
     NSStringFromClass([self class]),
     NSStringFromSelector(@selector(initWithDocument:))];
    
    return nil;
}



#pragma mark Public Methods

// ------------------------------------------------------
/// initialize
- (instancetype)initWithDocument:(CEDocument *)document
// ------------------------------------------------------
{
    self = [super init];
    if (self) {
        _document = document;
    }
    return self;
}



#pragma mark Delegate

//=======================================================
// NSTextStorageDelegate
//=======================================================

// ------------------------------------------------------
/// text strage as AppleScript's return value did update
- (void)textStorageDidProcessEditing:(nonnull NSNotification *)aNotification
// ------------------------------------------------------
{
    NSTextStorage *storage = (NSTextStorage *)[aNotification object];

    [[[self document] editor] insertTextViewString:[storage string]];
    [storage setDelegate:nil];
}

@end




#pragma mark -

@implementation CETextSelection (ScriptingSupport)

#pragma mark Superclass Methods

// ------------------------------------------------------
/// return object name which is determined in the sdef file
- (NSScriptObjectSpecifier *)objectSpecifier
// ------------------------------------------------------
{
    return [[NSNameSpecifier alloc] initWithContainerSpecifier:[[self document] objectSpecifier]
                                                           key:@"text selection"];
}



#pragma mark AppleScript Accessors

// ------------------------------------------------------
/// return string of the selection (Unicode text type)
- (NSTextStorage *)contents
// ------------------------------------------------------
{
    NSString *string = [[[self document] editor] substringWithSelection];
    
    // apply line endings
    string = [string stringByReplacingNewLineCharacersWith:[[self document] lineEnding]];
    
    NSTextStorage *storage = [[NSTextStorage alloc] initWithString:string];

    return storage;
}


// ------------------------------------------------------
/// replace the string in the selection
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
    
    [[[self document] editor] insertTextViewString:string];
}


// ------------------------------------------------------
/// return character range (location and length) of the selection (list type)
- (NSArray<NSNumber *> *)range
// ------------------------------------------------------
{
    NSRange range = [[[self document] editor] selectedRange];

    return @[@(range.location),
             @(range.length)];
}


// ------------------------------------------------------
/// set character range (location and length) of the selection
- (void)setRange:(NSArray<NSNumber *> *)rangeArray
// ------------------------------------------------------
{
    if ([rangeArray count] != 2) { return; }
    NSInteger location = [rangeArray[0] integerValue];
    NSInteger length = [rangeArray[1] integerValue];

    [[[self document] editor] setSelectedCharacterRangeWithLocation:location length:length];
}


// ------------------------------------------------------
/// return line range (location and length) of the selection (list type)
- (NSArray<NSNumber *> *)lineRange
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
/// set line range (location and length) of the selection
- (void)setLineRange:(NSArray<NSNumber *> *)rangeArray
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

    [[[self document] editor] setSelectedLineRangeWithLocation:location length:length];
}



#pragma mark AppleScript Handlers

// ------------------------------------------------------
/// shift the selection to right
- (void)handleShiftRightScriptCommand:(NSScriptCommand *)command
// ------------------------------------------------------
{
    [[[[self document] editor] focusedTextView] shiftRight:command];
}


// ------------------------------------------------------
/// shift the selection to left
- (void)handleShiftLeftScriptCommand:(NSScriptCommand *)command
// ------------------------------------------------------
{
    [[[[self document] editor] focusedTextView] shiftLeft:command];
}


// ------------------------------------------------------
/// swap selected lines with the line just above
- (void)handleMoveLineUpScriptCommand:(NSScriptCommand *)command
// ------------------------------------------------------
{
    [[[[self document] editor] focusedTextView] moveLineUp:command];
}


// ------------------------------------------------------
/// swap selected lines with the line just below
- (void)handleMoveLineDownScriptCommand:(NSScriptCommand *)command
// ------------------------------------------------------
{
    [[[[self document] editor] focusedTextView] moveLineDown:command];
}


// ------------------------------------------------------
/// swap selected lines with the line just below
- (void)handleSortLinesAscendingScriptCommand:(NSScriptCommand *)command
// ------------------------------------------------------
{
    [[[[self document] editor] focusedTextView] sortLinesAscending:command];
}


// ------------------------------------------------------
/// swap selected lines with the line just below
- (void)handleReverseLinesScriptCommand:(NSScriptCommand *)command
// ------------------------------------------------------
{
    [[[[self document] editor] focusedTextView] reverseLines:command];
}


// ------------------------------------------------------
/// comment-out the selection
- (void)handleCommentOutScriptCommand:(NSScriptCommand *)command
// ------------------------------------------------------
{
    [[[[self document] editor] focusedTextView] commentOut:command];
}


// ------------------------------------------------------
/// uncomment the selection
- (void)handleUncommentScriptCommand:(NSScriptCommand *)command
// ------------------------------------------------------
{
    [[[[self document] editor] focusedTextView] uncomment:command];
}


// ------------------------------------------------------
/// convert letters in the selection to lowercase, uppercase or capitalized
- (void)handleChangeCaseScriptCommand:(NSScriptCommand *)command
// ------------------------------------------------------
{
    NSDictionary<NSString *, id> *arguments = [command evaluatedArguments];
    CECaseType caseType = [arguments[@"caseType"] unsignedIntegerValue];
    NSTextView *textView = [[[self document] editor] focusedTextView];

    switch (caseType) {
        case CELowerCase:
            [textView lowercaseWord:command];
            break;
        case CEUpperCase:
            [textView uppercaseWord:command];
            break;
        case CECapitalized:
            [textView capitalizeWord:command];
            break;
    }
}


// ------------------------------------------------------
/// convert half-width roman in the selection to full-width roman or vice versa
- (void)handleChangeWidthRomanScriptCommand:(NSScriptCommand *)command
// ------------------------------------------------------
{
    NSDictionary<NSString *, id> *arguments = [command evaluatedArguments];
    CEWidthType widthType = [arguments[@"widthType"] unsignedIntegerValue];
    CETextView *textView = [[[self document] editor] focusedTextView];

    switch (widthType) {
        case CEFullwidth:
            [textView exchangeFullwidthRoman:command];
            break;
        case CEHalfwidth:
            [textView exchangeHalfwidthRoman:command];
            break;
    }
}


// ------------------------------------------------------
/// convert Japanese Hiragana in the selection to Katakana or vice versa
- (void)handleChangeKanaScriptCommand:(NSScriptCommand *)command
// ------------------------------------------------------
{
    NSDictionary<NSString *, id> *arguments = [command evaluatedArguments];
    CEChangeKanaType changeKanaType = [arguments[@"kanaType"] unsignedIntegerValue];
    CETextView *textView = [[[self document] editor] focusedTextView];
    
    switch (changeKanaType) {
        case CEHiragana:
            [textView exchangeHiragana:command];
            break;
        case CEKatakana:
            [textView exchangeKatakana:command];
            break;
    }
}


// ------------------------------------------------------
/// Unicode normalization
- (void)handleNormalizeUnicodeScriptCommand:(NSScriptCommand *)command
// ------------------------------------------------------
{
    NSDictionary<NSString *, id> *arguments = [command evaluatedArguments];
    CEUNFType UNFType = [arguments[@"unfType"] unsignedIntegerValue];
    CETextView *textView = [[[self document] editor] focusedTextView];
    
    switch (UNFType) {
        case CENFC:
            [textView normalizeUnicodeWithNFC:command];
            break;
        case CENFD:
            [textView normalizeUnicodeWithNFD:command];
            break;
        case CENFKC:
            [textView normalizeUnicodeWithNFKC:command];
            break;
        case CENFKD:
            [textView normalizeUnicodeWithNFKD:command];
            break;
        case CENFKCCF:
            [textView normalizeUnicodeWithNFKCCF:command];
            break;
        case CEModifiedNFD:
            [textView normalizeUnicodeWithModifiedNFD:command];
            break;
    }
}

@end
