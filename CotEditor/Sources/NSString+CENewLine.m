/*
 
 NSString+CENewLine.m
 
 CotEditor
 http://coteditor.com
 
 Created by 1024jp on 2014-11-30.
 
 ------------------------------------------------------------------------------
 
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

#import "NSString+CENewLine.h"


unichar const kNewLineChars[] = {
    NSNewlineCharacter,
    NSCarriageReturnCharacter,
    NSLineSeparatorCharacter,
    NSParagraphSeparatorCharacter
};


@implementation NSString (CENewLine)

#pragma mark Public Methods

// ------------------------------------------------------
/// NSString form for new line character
+ (nonnull NSString *)newLineStringWithType:(CENewLineType)type
// ------------------------------------------------------
{
    switch (type) {
        case CENewLineLF:  // NSNewlineCharacter
            return @"\n";
        case CENewLineCR:  // NSCarriageReturnCharacter
            return @"\r";
        case CENewLineCRLF:  // CR+LF
            return @"\r\n";
        case CENewLineLineSeparator:
            return [NSString stringWithFormat:@"%C", (unichar)NSLineSeparatorCharacter];
        case CENewLineParagraphSeparator:
            return [NSString stringWithFormat:@"%C", (unichar)NSParagraphSeparatorCharacter];
        case CENewLineNone:  // 改行なし
        default:
            return @"";
    }
}


// ------------------------------------------------------
/// line ending name to display
+ (nonnull NSString *)newLineNameWithType:(CENewLineType)type
// ------------------------------------------------------
{
    switch (type) {
        case CENewLineLF:
            return @"LF";
        case CENewLineCR:
            return @"CR";
        case CENewLineCRLF:
            return @"CR/LF";
        case CENewLineLineSeparator:
            return @"LS";
        case CENewLineParagraphSeparator:
            return @"PS";
        case CENewLineNone:
            return @"";
    }
}


// ------------------------------------------------------
/// return the first new line charater type
- (CENewLineType)detectNewLineType
// ------------------------------------------------------
{
    CENewLineType type = CENewLineNone;
    NSUInteger length = [self length];
    
    if (length == 0) { return type; }
    
    NSScanner *scanner = [NSScanner scannerWithString:self];
    
    // We don't use [NSCharacterSet newlineCharacterSet] because it contains more characters than we need.
    NSString *newLineSetString = [NSString stringWithCharacters:kNewLineChars
                                                         length:sizeof(kNewLineChars) / sizeof(unichar)];
    NSCharacterSet *newLineSet = [NSCharacterSet characterSetWithCharactersInString:newLineSetString];
    
    [scanner scanUpToCharactersFromSet:newLineSet intoString:NULL];
    if (![scanner isAtEnd]) {
        NSUInteger location = [scanner scanLocation];
        
        switch ([self characterAtIndex:location]) {
            case NSNewlineCharacter:
                type = CENewLineLF;
                break;
                
            case NSCarriageReturnCharacter:
                if ((length > location + 1) && ([self characterAtIndex:location + 1] == NSNewlineCharacter)) {
                    type = CENewLineCRLF;
                } else {
                    type = CENewLineCR;
                }
                break;
                
            case NSLineSeparatorCharacter:
                type = CENewLineLineSeparator;
                break;
                
            case NSParagraphSeparatorCharacter:
                type = CENewLineParagraphSeparator;
                break;
        }
    }
    
    return type;
}


// ------------------------------------------------------
/// replace all kind of new line characters in the string with the desired new line type.
- (nonnull NSString *)stringByReplacingNewLineCharacersWith:(CENewLineType)type
// ------------------------------------------------------
{
    NSRegularExpression *regex = [NSRegularExpression regularExpressionWithPattern:@"\\r\\n|[\\n\\r\\u2028\\u2029]"
                                                                           options:0 error:nil];
    
    return [regex stringByReplacingMatchesInString:self
                                           options:0
                                             range:NSMakeRange(0, [self length])
                                      withTemplate:[NSString newLineStringWithType:type]];
}


// ------------------------------------------------------
/// remove all kind of new line characters in string
- (nonnull NSString *)stringByDeletingNewLineCharacters
// ------------------------------------------------------
{
    return [self stringByReplacingNewLineCharacersWith:CENewLineNone];
}

@end
