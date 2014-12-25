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



#pragma mark Delegate and Notifications

//=======================================================
// Delegate method (NSTextStorage)
//  <== NSTextStorage
//=======================================================

// ------------------------------------------------------
/// text strage as AppleScript's return value did update
- (void)textStorageDidProcessEditing:(NSNotification *)aNotification
// ------------------------------------------------------
{
    NSTextStorage *storage = (NSTextStorage *)[aNotification object];

    [[[[self document] editor] textView] replaceSelectedStringTo:[storage string] scroll:NO];
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
    NSString *string = [[[self document] editor] substringWithSelectionForSave];
    NSTextStorage *storage = [[NSTextStorage alloc] initWithString:string];

    [storage setDelegate:self];
    
    // disconnect the delegate after 0.5 sec. (otherwise app may crash)
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.5 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        [storage setDelegate:nil];
    });

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
    
    [[[self document] editor] replaceTextViewSelectedStringTo:string scroll:NO];
}


// ------------------------------------------------------
/// return character range (location and length) of the selection (list type)
- (NSArray *)range
// ------------------------------------------------------
{
    NSRange range = [[[self document] editor] selectedRange];

    return @[@(range.location),
             @(range.length)];
}


// ------------------------------------------------------
/// set character range (location and length) of the selection
- (void)setRange:(NSArray *)rangeArray
// ------------------------------------------------------
{
    if ([rangeArray count] != 2) { return; }
    NSInteger location = [rangeArray[0] integerValue];
    NSInteger length = [rangeArray[1] integerValue];

    [[self document] setSelectedCharacterRangeInTextViewWithLocation:location length:length];
}


// ------------------------------------------------------
/// return line range (location and length) of the selection (list type)
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
/// set line range (location and length) of the selection
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

// ------------------------------------------------------
/// shift the selection to right
- (void)handleShiftRightScriptCommand:(NSScriptCommand *)command
// ------------------------------------------------------
{
    [[[[self document] editor] textView] shiftRight:command];
}


// ------------------------------------------------------
/// shift the selection to left
- (void)handleShiftLeftScriptCommand:(NSScriptCommand *)command
// ------------------------------------------------------
{
    [[[[self document] editor] textView] shiftLeft:command];
}


// ------------------------------------------------------
/// comment-out the selection
- (void)handleCommentOutScriptCommand:(NSScriptCommand *)command
// ------------------------------------------------------
{
    [[[[self document] editor] textView] commentOut:command];
}


// ------------------------------------------------------
/// uncomment the selection
- (void)handleUncommentScriptCommand:(NSScriptCommand *)command
// ------------------------------------------------------
{
    [[[[self document] editor] textView] uncomment:command];
}


// ------------------------------------------------------
/// convert letters in the selection to lowercase, uppercase or capitalized
- (void)handleChangeCaseScriptCommand:(NSScriptCommand *)command
// ------------------------------------------------------
{
    NSDictionary *arguments = [command evaluatedArguments];
    CECaseType caseType = [arguments[@"caseType"] unsignedIntegerValue];
    NSTextView *textView = [[[self document] editor] textView];

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
    NSDictionary *arguments = [command evaluatedArguments];
    CEWidthType widthType = [arguments[@"widthType"] unsignedIntegerValue];
    CETextView *textView = [[[self document] editor] textView];

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
    NSDictionary *arguments = [command evaluatedArguments];
    CEChangeKanaType changeKanaType = [arguments[@"kanaType"] unsignedIntegerValue];
    CETextView *textView = [[[self document] editor] textView];
    
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
    NSDictionary *arguments = [command evaluatedArguments];
    CEUNFType UNFType = [arguments[@"unfType"] unsignedIntegerValue];
    CETextView *textView = [[[self document] editor] textView];
    
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
    }
}

@end
