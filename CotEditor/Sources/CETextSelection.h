/*
 
 CETextSelection.h
 
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

@import Cocoa;


@class CEDocument;

// AppleScript Enum
typedef NS_ENUM(NSUInteger, CECaseType) {
    CELowerCase = 'cClw',
    CEUpperCase = 'cCup',
    CECapitalized = 'cCcp'
};

typedef NS_ENUM(NSUInteger, CEWidthType) {
    CEFullwidth = 'rWfl',
    CEHalfwidth = 'rWhf',
};

typedef NS_ENUM(NSUInteger, CEChangeKanaType) {
    CEHiragana = 'cHgn',
    CEKatakana = 'cKkn',
};

typedef NS_ENUM(NSUInteger, CEUNFType) {
    CENFC = 'cNfc',
    CENFD = 'cNfd',
    CENFKC = 'cNkc',
    CENFKD = 'cNkd',
    CENFKCCF = 'cNcf',
    CEModifiedNFD = 'cNfm',
};


@interface CETextSelection : NSObject

// Public method
- (instancetype)initWithDocument:(CEDocument *)document NS_DESIGNATED_INITIALIZER;

// unavailable initializer
- (instancetype)init __attribute__((unavailable("use -initWithDocument: instead")));

@end


@interface CETextSelection (ScriptingSupport)

// AppleScript accessor
- (NSTextStorage *)contents;
- (void)setContents:(id)contentsObject;
- (NSArray<NSNumber *> *)range;
- (void)setRange:(NSArray<NSNumber *> *)rangeArray;
- (NSArray<NSNumber *> *)lineRange;
- (void)setLineRange:(NSArray<NSNumber *> *)RangeArray;

// AppleScript handler
- (void)handleShiftRightScriptCommand:(NSScriptCommand *)command;
- (void)handleShiftLeftScriptCommand:(NSScriptCommand *)command;
- (void)handleCommentOutScriptCommand:(NSScriptCommand *)command;
- (void)handleUncommentScriptCommand:(NSScriptCommand *)command;
- (void)handleChangeCaseScriptCommand:(NSScriptCommand *)command;
- (void)handleChangeWidthRomanScriptCommand:(NSScriptCommand *)command;
- (void)handleChangeKanaScriptCommand:(NSScriptCommand *)command;
- (void)handleNormalizeUnicodeScriptCommand:(NSScriptCommand *)command;

@end
