/*
 
 CEControlCharacerNames.m
 
 CotEditor
 http://coteditor.com
 
 Created by 1024jp on 2015-12-29.
 
 ------------------------------------------------------------------------------
 
 © 2015 1024jp
 
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

#import "CEControlCharacerNames.h"


BOOL CEIsC0ControlPoint(unichar character) {
    return 0x0000 <= character && character <= 0x0020;  // U+0020 is actually not in range of C0 control character. But they are often included in actual fact.
}


BOOL CEIsC1ControlPoint(unichar character) {
    return 0x0080 <= character && character <= 0x009F;
}


unichar const CEDeleteCharacter = 0x007F;


// c.f. http://unicode.org/Public/UNIDATA/UnicodeData.txt
static NSString *_Nonnull const CEC0ControlCharacterNames[] = {
    @"NULL",
    @"START OF HEADING",
    @"START OF TEXT",
    @"END OF TEXT",
    @"END OF TRANSMISSION",
    @"ENQUIRY",
    @"ACKNOWLEDGE",
    @"BELL",
    @"BACKSPACE",
    @"HORIZONTAL TABULATION",
    @"LINE FEED",
    @"VERTICAL TABULATION",
    @"FORM FEED",
    @"CARRIAGE RETURN",
    @"SHIFT OUT",
    @"SHIFT IN",
    @"DATA LINK ESCAPE",
    @"DEVICE CONTROL ONE",
    @"DEVICE CONTROL TWO",
    @"DEVICE CONTROL THREE",
    @"DEVICE CONTROL FOUR",
    @"NEGATIVE ACKNOWLEDGE",
    @"SYNCHRONOUS IDLE",
    @"END OF TRANSMISSION BLOCK",
    @"CANCEL",
    @"END OF MEDIUM",
    @"SUBSTITUTE",
    @"ESCAPE",
    @"FILE SEPARATOR",
    @"GROUP SEPARATOR",
    @"RECORD SEPARATOR",
    @"UNIT SEPARATOR",
    @"SPACE",
};


static NSString *_Nonnull const CEDeleteCharacterName = @"DELETE";


static NSString *_Nonnull const CEC1ControlCharacterNames[] = {
    @"PADDING CHARACTER",
    @"HIGH OCTET PRESET",
    @"BREAK PERMITTED HERE",
    @"NO BREAK HERE",
    @"INDEX",
    @"NEXT LINE",
    @"START OF SELECTED AREA",
    @"END OF SELECTED AREA",
    @"CHARACTER TABULATION SET",
    @"CHARACTER TABULATION WITH JUSTIFICATION",
    @"LINE TABULATION SET",
    @"PARTIAL LINE FORWARD",
    @"PARTIAL LINE BACKWARD",
    @"REVERSE LINE FEED",
    @"SINGLE SHIFT TWO",
    @"SINGLE SHIFT THREE",
    @"DEVICE CONTROL STRING",
    @"PRIVATE USE ONE",
    @"PRIVATE USE TWO",
    @"SET TRANSMIT STATE",
    @"CANCEL CHARACTER",
    @"MESSAGE WAITING",
    @"START OF PROTECTED AREA",
    @"END OF PROTECTED AREA",
    @"START OF STRING",
    @"SINGLE GRAPHIC CHARACTER INTRODUCER",
    @"SINGLE CHARACTER INTRODUCER",
    @"CONTROL SEQUENCE INTRODUCER",
    @"STRING TERMINATOR",
    @"OPERATING SYSTEM COMMAND",
    @"PRIVACY MESSAGE",
    @"APPLICATION PROGRAM COMMAND",
};


NSString * _Nullable CEControlCharacterName(unichar character)
{
    if (CEIsC0ControlPoint(character)) {
        NSUInteger index = character;
        return CEC0ControlCharacterNames[index];
        
    } else if (character == CEDeleteCharacter) {
        return CEDeleteCharacterName;
    
    } else if (CEIsC1ControlPoint(character)) {
        NSUInteger index = character - 0x0080;  // shift to 0-based array index
        return CEC1ControlCharacterNames[index];
    }
    
    return nil;
}
