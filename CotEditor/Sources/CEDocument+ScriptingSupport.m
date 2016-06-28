/*
 
 CEDocument+ScriptingSupport.m
 
 CotEditor
 http://coteditor.com
 
 Created by nakamuxu on 2005-03-12.

 ------------------------------------------------------------------------------
 
 © 2004-2007 nakamuxu
 © 2014-2016 1024jp
 
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

#import "CEDocument+ScriptingSupport.h"

#import "CotEditor-Swift.h"

#import "CETextSelection.h"
#import "CEEditorWrapper+Editor.h"
#import "CESyntaxStyle.h"


@implementation CEDocument (ScriptingSupport)

#pragma mark Notification

// ------------------------------------------------------
/// text strage as AppleScript's return value did update
- (void)scriptTextStorageDidProcessEditing:(nonnull NSNotification *)notification
// ------------------------------------------------------
{
    NSTextStorage *textStorage = (NSTextStorage *)[notification object];

    [[self editor] replaceTextViewAllStringWithString:[textStorage string]];
    
    [[NSNotificationCenter defaultCenter] removeObserver:self
                                                    name:NSTextStorageDidProcessEditingNotification
                                                  object:textStorage];
}



#pragma mark AppleScript Accessores

// ------------------------------------------------------
/// return whole document string (text type)
- (NSTextStorage *)scriptTextStorage
// ------------------------------------------------------
{
    NSTextStorage *textStorage = [[NSTextStorage alloc] initWithString:[self string]];

    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(scriptTextStorageDidProcessEditing:)
                                                 name:NSTextStorageDidProcessEditingNotification
                                               object:textStorage];
    
    // disconnect the delegate after 0.5 sec. (otherwise app may crash)
    __weak typeof(self) weakSelf = self;
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.5 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        [[NSNotificationCenter defaultCenter] removeObserver:weakSelf
                                                        name:NSTextStorageDidProcessEditingNotification
                                                      object:textStorage];
    });
    
    return textStorage;
}


// ------------------------------------------------------
/// replase whole document string
- (void)setScriptTextStorage:(id)object;
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
    return [self scriptTextStorage];
}


// ------------------------------------------------------
/// replase whole document string
- (void)setContents:(id)object
// ------------------------------------------------------
{
    [self setScriptTextStorage:object];
}


// ------------------------------------------------------
/// return length of document (integer type)
- (NSNumber *)length
// ------------------------------------------------------
{
    return @([[self string] length]);
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
    [self changeLineEndingTo:type];
}


// ------------------------------------------------------
/// return encoding name (Unicode text type)
- (NSString *)encodingName
// ------------------------------------------------------
{
    return [NSString localizedNameOfStringEncoding:[self encoding]];
}


// ------------------------------------------------------
/// return syntax style name (Unicode text type)
- (NSString *)coloringStyle
// ------------------------------------------------------
{
    return [[self syntaxStyle] styleName];
}


// ------------------------------------------------------
/// set syntax style
- (void)setColoringStyle:(NSString *)styleName
// ------------------------------------------------------
{
    [self setSyntaxStyleWithName:styleName];
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
/// returns tab width (integer type)
- (NSNumber *)tabWidth
// ------------------------------------------------------
{
    return @([[self editor] tabWidth]);
}


// ------------------------------------------------------
/// set tab width
- (void)setTabWidth:(NSNumber *)tabWidth
// ------------------------------------------------------
{
    [[self editor] setTabWidth:[tabWidth unsignedIntegerValue]];
}



#pragma mark AppleScript Handlers

// ------------------------------------------------------
/// change encoding and convert text
- (NSNumber *)handleConvertScriptCommand:(NSScriptCommand *)command
// ------------------------------------------------------
{
    NSDictionary<NSString *, id> *arguments = [command evaluatedArguments];
    NSString *encodingName = arguments[@"newEncoding"];
    NSStringEncoding encoding = [EncodingManager encodingFromName:encodingName];
    
    if (encoding == NSNotFound) {
        return @NO;
    } else if (encoding == [self encoding]) {
        return @YES;
    }
    
    BOOL lossy = [arguments[@"Lossy"] boolValue];
    
    BOOL success = [self changeEncoding:encoding withUTF8BOM:NO askLossy:NO lossy:lossy];
    
    return @(success);
}


// ------------------------------------------------------
/// change encoding and reinterpret text
- (NSNumber *)handleReinterpretScriptCommand:(NSScriptCommand *)command
// ------------------------------------------------------
{
    NSDictionary<NSString *, id> *arguments = [command evaluatedArguments];
    NSString *encodingName = arguments[@"newEncoding"];
    NSStringEncoding encoding = [EncodingManager encodingFromName:encodingName];
    
    BOOL success = [self reinterpretWithEncoding:encoding error:nil];

    return @(success);
}


// ------------------------------------------------------
/// find
- (NSNumber *)handleFindScriptCommand:(NSScriptCommand *)command
// ------------------------------------------------------
{
    NSDictionary<NSString *, id> *arguments = [command evaluatedArguments];
    NSString *searchString = arguments[@"targetString"];
    
    if ([searchString length] == 0) { return @NO; }
    
    BOOL isRegex = [arguments[@"regularExpression"] boolValue];
    BOOL ignoresCase = [arguments[@"ignoreCase"] boolValue];
    BOOL isBackwards = [arguments[@"backwardsSearch"] boolValue];
    BOOL isWrapSearch = [arguments[@"wrapSearch"] boolValue];
    
    NSString *wholeString = [self string];
    NSInteger wholeLength = [wholeString length];
    
    if (wholeLength == 0) { return @NO; }
    
    // set target range
    NSRange targetRange;
    NSRange selectedRange = [[self editor] selectedRange];
    if (isBackwards) {
        targetRange = NSMakeRange(0, selectedRange.location);
    } else {
        targetRange = NSMakeRange(NSMaxRange(selectedRange),
                                  wholeLength - NSMaxRange(selectedRange));
    }
    
    // perform find
    BOOL success = [self find:searchString withRegularExpression:isRegex ignoresCase:ignoresCase backwards:isBackwards range:targetRange];
    if (!success && isWrapSearch) {
        targetRange = NSMakeRange(0, wholeLength);
        success = [self find:searchString withRegularExpression:isRegex ignoresCase:ignoresCase backwards:isBackwards range:targetRange];
    }
    
    return @(success);
}


// ------------------------------------------------------
/// replace
- (NSNumber *)handleReplaceScriptCommand:(NSScriptCommand *)command
// ------------------------------------------------------
{
    NSDictionary<NSString *, id> *arguments = [command evaluatedArguments];
    NSString *searchString = arguments[@"targetString"];
    
    if ([searchString length] == 0) { return @NO; }
    
    BOOL isRegex = [arguments[@"regularExpression"] boolValue];
    BOOL ignoresCase = [arguments[@"ignoreCase"] boolValue];
    BOOL isAll = [arguments[@"all"] boolValue];
    BOOL isBackwards = [arguments[@"backwardsSearch"] boolValue];
    BOOL isWrapSearch = [arguments[@"wrapSearch"] boolValue];
    
    NSString *wholeString = [self string];
    NSInteger wholeLength = [wholeString length];
    
    if (wholeLength == 0) { return @NO; }
    
    NSString *replacementString = arguments[@"newString"] ?: @"";
    
    if (!isRegex && [searchString isEqualToString:replacementString]) { return @NO; }
    
    // set target range
    NSRange targetRange;
    if (isAll) {
        targetRange = NSMakeRange(0, wholeLength);
    } else {
        NSRange selectedRange = [[self editor] selectedRange];
        if (isBackwards) {
            targetRange = NSMakeRange(0, selectedRange.location);
        } else {
            targetRange = NSMakeRange(NSMaxRange(selectedRange),
                                      wholeLength - NSMaxRange(selectedRange));
        }
    }
    
    // perform replacement
    NSInteger numberOfReplacements = 0;
    if (isAll) {
        NSMutableString *newWholeString = [wholeString mutableCopy];
        if (isRegex) {
            NSRegularExpressionOptions options = (ignoresCase ? NSRegularExpressionCaseInsensitive : 0);
            NSRegularExpression *regex = [NSRegularExpression regularExpressionWithPattern:searchString options:options error:nil];
            numberOfReplacements = [regex replaceMatchesInString:newWholeString options:0 range:targetRange withTemplate:replacementString];
            
        } else {
            NSStringCompareOptions options = ((ignoresCase ? NSCaseInsensitiveSearch : 0) |
                                              (isBackwards ? NSBackwardsSearch : 0));
            numberOfReplacements = [newWholeString replaceOccurrencesOfString:searchString withString:replacementString
                                                                      options:options
                                                                        range:targetRange];
        }
        if (numberOfReplacements > 0) {
            [[self editor] replaceTextViewAllStringWithString:newWholeString];
            [[self editor] setSelectedRange:NSMakeRange(0, 0)];
        }
        
    } else {
        BOOL success = [self find:searchString withRegularExpression:isRegex ignoresCase:ignoresCase backwards:isBackwards range:targetRange];
        if (!success && isWrapSearch) {
            targetRange = NSMakeRange(0, wholeLength);
            success = [self find:searchString withRegularExpression:isRegex ignoresCase:ignoresCase backwards:isBackwards range:targetRange];
        }
        if (success) {
            [[self selection] setContents:replacementString];  // CETextSelection's `setContents:` accepts also NSString for its argument
            numberOfReplacements = 1;
        }
    }
    
    return @(numberOfReplacements);
}


// ------------------------------------------------------
/// scroll to make selection visible
- (void)handleScrollScriptCommand:(NSScriptCommand *)command
// ------------------------------------------------------
{
    NSTextView *textView = [[self editor] focusedTextView];
    [textView scrollRangeToVisible:[textView selectedRange]];
}


// ------------------------------------------------------
/// return sting in the specified range
- (NSString *)handleStringScriptCommand:(NSScriptCommand *)command
// ------------------------------------------------------
{
    NSDictionary<NSString *, id> *arguments = [command evaluatedArguments];
    NSArray<NSNumber *> *rangeArray = arguments[@"range"];
    
    if ([rangeArray count] == 0) { return @""; }
    
    NSInteger location = [rangeArray[0] integerValue];
    NSInteger length = ([rangeArray count] > 1) ? [rangeArray[1] integerValue] : 1;
    NSRange range = [[self editor] rangeWithLocation:location length:length];
    
    if (NSEqualRanges(NSMakeRange(0, 0), range)) { return @""; }
    
    return [[[self editor] string] substringWithRange:range];
}



#pragma mark Private Methods

// ------------------------------------------------------
/// find string, select if found and return whether succeed
- (BOOL)find:(NSString *)searchString withRegularExpression:(BOOL)isRegex ignoresCase:(BOOL)ignoresCase backwards:(BOOL)isBackwards range:(NSRange)range
// ------------------------------------------------------
{
    NSRange foundRange = [[self string] rangeOfString:searchString
                                              options:((isRegex ? NSRegularExpressionSearch : 0) |
                                                       (ignoresCase ? NSCaseInsensitiveSearch : 0) |
                                                       (isBackwards ? NSBackwardsSearch : 0))
                                                range:range];
    
    if (foundRange.location == NSNotFound) { return NO; }
    
    [[self editor] setSelectedRange:foundRange];
    return YES;
}

@end
