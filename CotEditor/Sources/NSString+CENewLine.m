/*
 ==============================================================================
 NSString+CENewLine
 
 CotEditor
 http://coteditor.com
 
 Created on 2014-11-30 by 1024jp
 encoding="UTF-8"
 ------------------------------------------------------------------------------
 
 © 2014 1024jp
 
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
+ (NSString *)newLineStringWithType:(CENewLineType)type
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
+ (NSString *)newLineNameWithType:(CENewLineType)type
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
- (NSString *)stringByReplacingNewLineCharacersWith:(CENewLineType)type
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
- (NSString *)stringByDeletingNewLineCharacters
// ------------------------------------------------------
{
    return [self stringByReplacingNewLineCharacersWith:CENewLineNone];
}

@end
