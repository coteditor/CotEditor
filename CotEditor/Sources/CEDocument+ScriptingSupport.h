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

@import Cocoa;
#import "CEDocument.h"


@interface CEDocument (ScriptingSupport) <NSTextStorageDelegate>

// AppleScript enum
typedef NS_ENUM(NSUInteger, CEOSALineEnding) {
    CEOSALineEndingLF = 'leLF',
    CEOSALineEndingCR = 'leCR',
    CEOSALineEndingCRLF = 'leCL'
};

// Public method
- (void)cleanUpTextStorage:(NSTextStorage *)inTextStorage;

// AppleScript accessor
- (NSTextStorage *)textStorage;
- (void)setTextStorage:(id)object;
- (NSTextStorage *)contents;
- (void)setContents:(id)object;
- (NSNumber *)length;
- (CEOSALineEnding)lineEndingChar;
- (void)setLineEndingChar:(CEOSALineEnding)lineEndingChar;
- (NSString *)encodingName;
- (NSString *)IANACharSetName;
- (NSString *)coloringStyle;
- (void)setColoringStyle:(NSString *)styleName;
- (CETextSelection *)selectionObject;
- (void)setSelectionObject:(id)object;
- (NSNumber *)wrapsLines;
- (void)setWrapsLines:(NSNumber *)wrapsLines;
- (NSNumber *)lineSpacing;
- (void)setLineSpacing:(NSNumber *)lineSpacing;
- (NSNumber *)tabWidth;
- (void)setTabWidth:(NSNumber *)tabWidth;

// AppleScript handler
- (NSNumber *)handleConvertScriptCommand:(NSScriptCommand *)command;
- (NSNumber *)handleReinterpretScriptCommand:(NSScriptCommand *)command;
- (NSNumber *)handleFindScriptCommand:(NSScriptCommand *)command;
- (NSNumber *)handleReplaceScriptCommand:(NSScriptCommand *)command;
- (void)handleScrollScriptCommand:(NSScriptCommand *)command;
- (NSString *)handleStringScriptCommand:(NSScriptCommand *)command;

@end
