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
};


@interface CETextSelection : NSObject <NSTextStorageDelegate>

// Public method
- (instancetype)initWithDocument:(CEDocument *)document NS_DESIGNATED_INITIALIZER;

@end


@interface CETextSelection (ScriptingSupport)

// AppleScript accessor
- (NSTextStorage *)contents;
- (void)setContents:(id)contentsObject;
- (NSArray *)range;
- (void)setRange:(NSArray *)rangeArray;
- (NSArray *)lineRange;
- (void)setLineRange:(NSArray *)RangeArray;

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
