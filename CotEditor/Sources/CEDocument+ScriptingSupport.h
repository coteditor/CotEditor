/*
 
 CEDocument+ScriptingSupport.h
 
 CotEditor
 http://coteditor.com
 
 Created by nakamuxu on 2005-03-12.

 ------------------------------------------------------------------------------
 
 © 2004-2007 nakamuxu
 © 2014 1024jp
 
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

@import Cocoa;
#import "CEDocument.h"


@interface CEDocument (ScriptingSupport) <NSTextStorageDelegate>

// AppleScript enum
typedef NS_ENUM(NSUInteger, CEOSALineEnding) {
    CEOSALineEndingLF = 'leLF',
    CEOSALineEndingCR = 'leCR',
    CEOSALineEndingCRLF = 'leCL'
};

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
