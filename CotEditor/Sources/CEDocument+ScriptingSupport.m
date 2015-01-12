/*
 ==============================================================================
 CEDocument+ScriptingSupport
 
 CotEditor
 http://coteditor.com
 
 Created on 2005-03-12 by nakamuxu
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

#import "CEDocument+ScriptingSupport.h"
#import <OgreKit/OgreKit.h>
#import "CEUtils.h"


@implementation CEDocument (ScriptingSupport)

#pragma mark Delegate

//=======================================================
// NSTextStorageDelegate  <- selection
//=======================================================

// ------------------------------------------------------
/// text strage as AppleScript's return value did update
- (void)textStorageDidProcessEditing:(NSNotification *)notification
// ------------------------------------------------------
{
    NSTextStorage *storage = (NSTextStorage *)[notification object];

    [[self editor] replaceTextViewAllStringWithString:[storage string]];
    [storage setDelegate:nil];
}



#pragma mark AppleScript Accessores

// ------------------------------------------------------
/// return whole document string (text type)
- (NSTextStorage *)textStorage
// ------------------------------------------------------
{
    NSTextStorage *storage = [[NSTextStorage alloc] initWithString:[self stringForSave]];

    [storage setDelegate:self];
    
    // disconnect the delegate after 0.5 sec. (otherwise app may crash)
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.5 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        [storage setDelegate:nil];
    });

    return storage;
}


// ------------------------------------------------------
/// replase whole document string
- (void)setTextStorage:(id)object;
// ------------------------------------------------------
{
    if ([object isKindOfClass:[NSTextStorage class]]) {
        [[self editor] replaceTextViewAllStringWithString:[object string]];
    } else if ([object isKindOfClass:[NSString class]]) {
        [[self editor] replaceTextViewAllStringWithString:object];
    }
}


// ------------------------------------------------------
/// return document string (text type)
- (NSTextStorage *)contents
// ------------------------------------------------------
{
    return [self textStorage];
}


// ------------------------------------------------------
/// replase whole document string
- (void)setContents:(id)object
// ------------------------------------------------------
{
    [self setTextStorage:object];
}


// ------------------------------------------------------
/// return length of document (integer type)
- (NSNumber *)length
// ------------------------------------------------------
{
    return @([[self stringForSave] length]);
}


// ------------------------------------------------------
/// return new line code (enum type)
- (CEOSALineEnding)lineEndingChar
// ------------------------------------------------------
{
    switch ([self lineEnding]) {
        case CENewLineCR:
            return CEOSALineEndingCR;
            break;
        case CENewLineCRLF:
            return CEOSALineEndingCRLF;
            break;
        default:
            return CEOSALineEndingLF;
            break;
    }
}


// ------------------------------------------------------
/// set new line
- (void)setLineEndingChar:(CEOSALineEnding)lineEndingChar
// ------------------------------------------------------
{
    CENewLineType type;

    switch (lineEndingChar) {
        case CEOSALineEndingCR:
            type = CENewLineCR;
            break;
        case CEOSALineEndingCRLF:
            type = CENewLineCRLF;
            break;
        case CEOSALineEndingLF:
            type = CENewLineLF;
            break;
    }
    [self doSetLineEnding:type];
}


// ------------------------------------------------------
/// return encoding name (Unicode text type)
- (NSString *)encodingName
// ------------------------------------------------------
{
    return [NSString localizedNameOfStringEncoding:[self encoding]];
}


// ------------------------------------------------------
/// return IANA Charset name of encoding (Unicode text type)
- (NSString *)IANACharSetName
// ------------------------------------------------------
{
    return [self currentIANACharSetName] ? : @"";  // retuns blank string if cannot get
}


// ------------------------------------------------------
/// return syntax style name (Unicode text type)
- (NSString *)coloringStyle
// ------------------------------------------------------
{
    return [[self editor] syntaxStyleName];
}


// ------------------------------------------------------
/// set syntax style
- (void)setColoringStyle:(NSString *)styleName
// ------------------------------------------------------
{
    [self doSetSyntaxStyle:styleName];
}


// ------------------------------------------------------
/// return selection-object
- (CETextSelection *)selectionObject
// ------------------------------------------------------
{
    return [self selection];
}


// ------------------------------------------------------
/// set text to the selection
- (void)setSelectionObject:(id)object
// ------------------------------------------------------
{
    if ([object isKindOfClass:[NSString class]]) {
        [[self selection] setContents:object];
    }
}


// ------------------------------------------------------
/// return state of text wrapping
- (NSNumber *)wrapsLines
// ------------------------------------------------------
{
    return @([[self editor] wrapsLines]);
}


// ------------------------------------------------------
/// toggle warapping state
- (void)setWrapsLines:(NSNumber *)wrapsLines
// ------------------------------------------------------
{
    [[self editor] setWrapsLines:[wrapsLines boolValue]];
}


// ------------------------------------------------------
/// return line spacing
- (NSNumber *)lineSpacing
// ------------------------------------------------------
{
    return @([[[self editor] textView] lineSpacing]);
}


// ------------------------------------------------------
/// set line spacing
- (void)setLineSpacing:(NSNumber *)lineSpacing
// ------------------------------------------------------
{
    [[[self editor] textView] setLineSpacing:(CGFloat)[lineSpacing doubleValue]];
}


// ------------------------------------------------------
/// returns tab width (integer type)
- (NSNumber *)tabWidth
// ------------------------------------------------------
{
    return @([[[self editor] textView] tabWidth]);
}


// ------------------------------------------------------
/// set tab width
- (void)setTabWidth:(NSNumber *)tabWidth
// ------------------------------------------------------
{
    [[[self editor] textView] setTabWidth:[tabWidth unsignedIntegerValue]];
}



#pragma mark AppleScript Handlers

// ------------------------------------------------------
/// change encoding and convert text
- (NSNumber *)handleConvertScriptCommand:(NSScriptCommand *)command
// ------------------------------------------------------
{
    NSDictionary *arguments = [command evaluatedArguments];
    NSString *encodingName = arguments[@"newEncoding"];
    NSStringEncoding encoding = [CEUtils encodingFromName:encodingName];
    BOOL success = NO;

    if (encoding == NSNotFound) {
        success = NO;
    } else if (encoding == [self encoding]) {
        success = YES;
    } else {
        NSString *actionName = @"TEST";
        BOOL lossy = NO;

        lossy = [arguments[@"Lossy"] boolValue];
        success = [self doSetEncoding:encoding updateDocument:YES askLossy:NO lossy:lossy asActionName:actionName];
    }

    return @(success);
}


// ------------------------------------------------------
/// change encoding and reinterpret text
- (NSNumber *)handleReinterpretScriptCommand:(NSScriptCommand *)command
// ------------------------------------------------------
{
    NSDictionary *arguments = [command evaluatedArguments];
    NSString *encodingName = arguments[@"newEncoding"];
    NSStringEncoding encoding = [CEUtils encodingFromName:encodingName];
    BOOL success = NO;

    if ((encoding == NSNotFound) || ![self fileURL]) {
        success = NO;
    } else if (encoding == [self encoding]) {
        success = YES;
    } else if ([self readStringFromData:[NSData dataWithContentsOfURL:[self fileURL]] encoding:encoding xattr:NO]) {
        [self setStringToEditor];
        // clear dirty flag
        [self updateChangeCount:NSChangeCleared];
        // update popup menu in the toolbar
        [[[self windowController] toolbarController] setSelectedEncoding:[self encoding]];
        success = YES;
    }

    return @(success);
}


// ------------------------------------------------------
/// find
- (NSNumber *)handleFindScriptCommand:(NSScriptCommand *)command
// ------------------------------------------------------
{
    NSDictionary *arguments = [command evaluatedArguments];
    NSString *searchStr = arguments[@"targetString"];
    if ([searchStr length] == 0) { return @NO; }
    BOOL isRegex = [arguments[@"regularExpression"] boolValue];
    BOOL ignoresCase = [arguments[@"ignoreCase"] boolValue];
    BOOL isBackwards = [arguments[@"backwardsSearch"] boolValue];
    BOOL isWrapSearch = [arguments[@"wrapSearch"] boolValue];
    NSString *wholeStr = [self stringForSave];
    NSInteger wholeLength = [wholeStr length];
    if (wholeLength == 0) { return @NO; }
    NSRange selectionRange = [[self editor] selectedRange];
    NSRange targetRange;

    if (isBackwards) {
        targetRange = NSMakeRange(0, selectionRange.location);
    } else {
        targetRange = NSMakeRange(NSMaxRange(selectionRange),
                                  wholeLength - NSMaxRange(selectionRange));
    }
    NSUInteger mask = 0;
    if (ignoresCase) {
        mask |= isRegex ? OgreIgnoreCaseOption : NSCaseInsensitiveSearch;
    }
    if (isBackwards) {
        mask |= NSBackwardsSearch;
    }

    BOOL success = [self doFind:searchStr range:targetRange option:mask withRegularExpression:isRegex];
    if (!success && isWrapSearch) {
        targetRange = NSMakeRange(0, wholeLength);
        success = [self doFind:searchStr range:targetRange option:mask withRegularExpression:isRegex];
    }
    
    return @(success);
}


// ------------------------------------------------------
/// replace
- (NSNumber *)handleReplaceScriptCommand:(NSScriptCommand *)command
// ------------------------------------------------------
{
    NSDictionary *arguments = [command evaluatedArguments];
    NSString *searchStr = arguments[@"targetString"];
    if ([searchStr length] == 0) { return @NO; }
    BOOL isRegex = [arguments[@"regularExpression"] boolValue];
    BOOL ignoresCase = [arguments[@"ignoreCase"] boolValue];
    BOOL isAll = [arguments[@"all"] boolValue];
    BOOL isBackwards = [arguments[@"backwardsSearch"] boolValue];
    BOOL isWrapSearch = [arguments[@"wrapSearch"] boolValue];
    NSString *wholeStr = [self stringForSave];
    NSInteger wholeLength = [wholeStr length];
    if (wholeLength == 0) { return @NO; }
    NSString *newString = arguments[@"newString"];
    if ([searchStr isEqualToString:newString]) { return @NO; }
    if (!newString) { newString = @""; }
    NSRange selectionRange, targetRange;

    if (isAll) {
        targetRange = NSMakeRange(0, wholeLength);
    } else {
        selectionRange = [[self editor] selectedRange];
        if (isBackwards) {
            targetRange = NSMakeRange(0, selectionRange.location);
        } else {
            targetRange = NSMakeRange(NSMaxRange(selectionRange),
                                      wholeLength - NSMaxRange(selectionRange));
        }
    }
    NSUInteger mask = 0;
    if (ignoresCase) {
        mask |= (isRegex) ? OgreIgnoreCaseOption : NSCaseInsensitiveSearch;
    }
    if (isBackwards) {
        mask |= NSBackwardsSearch;
    }

    BOOL success = NO;
    NSInteger result = 0;
    if (isAll) {
        NSMutableString *tmpStr = [wholeStr mutableCopy];
        if (isRegex) {
            result = [tmpStr replaceOccurrencesOfRegularExpressionString:searchStr
                                                              withString:newString options:mask range:targetRange];
        } else {
            result = [tmpStr replaceOccurrencesOfString:searchStr
                                             withString:newString options:mask range:targetRange];
        }
        if (result > 0) {
            [[self editor] replaceTextViewAllStringWithString:tmpStr];
            [[[self editor] textView] setSelectedRange:NSMakeRange(0,0)];
        }

    } else {
        success = [self doFind:searchStr range:targetRange option:mask withRegularExpression:isRegex];
        if (!success && isWrapSearch) {
            targetRange = NSMakeRange(0, wholeLength);
            success = [self doFind:searchStr range:targetRange option:mask withRegularExpression:isRegex];
        }
        if (success) {
            [[self selection] setContents:newString];  // CETextSelection's `setContents:` accepts also NSString for its argument
            result = 1;
        }
    }

    return @(result);
}


// ------------------------------------------------------
/// scroll to make selection visible
- (void)handleScrollScriptCommand:(NSScriptCommand *)command
// ------------------------------------------------------
{
    NSTextView *textView = [[self editor] textView];
    [textView scrollRangeToVisible:[textView selectedRange]];
}


// ------------------------------------------------------
/// return sting in the specified range
- (NSString *)handleStringScriptCommand:(NSScriptCommand *)command
// ------------------------------------------------------
{
    NSDictionary *arguments = [command evaluatedArguments];
    NSArray *rangeArray = arguments[@"range"];

    if ([rangeArray count] == 0) { return [NSString string]; }
    NSInteger location = [rangeArray[0] integerValue];
    NSInteger length = ([rangeArray count] > 1) ? [rangeArray[1] integerValue] : 1;
    NSRange range = [self rangeInTextViewWithLocation:location length:length];

    if (NSEqualRanges(NSMakeRange(0, 0), range)) {
        return @"";
    }
    return [[[[self editor] textView] string] substringWithRange:range];
}



#pragma mark Private Methods

// ------------------------------------------------------
/// find string, select if found and return whether succeed
- (BOOL)doFind:(NSString *)searchString range:(NSRange)range option:(unsigned)option withRegularExpression:(BOOL)isRegex
// ------------------------------------------------------
{
    NSString *wholeStr = [[self editor] string];
    NSRange searchedRange;

    if (isRegex) {
        searchedRange = [wholeStr rangeOfRegularExpressionString:searchString options:option range:range];
    } else {
        searchedRange = [wholeStr rangeOfString:searchString options:option range:range];
    }
    if (searchedRange.location != NSNotFound) {
        [[self editor] setSelectedRange:searchedRange];
        return YES;
    }
    return NO;
}

@end
