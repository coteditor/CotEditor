/*
=================================================
CETextSelection
(for CotEditor)

 Copyright (C) 2004-2007 nakamuxu.
 Copyright (C) 2014 CotEditor Project
 http://coteditor.github.io
=================================================

encoding="UTF-8"
Created:2005.03.01

-------------------------------------------------

This program is free software; you can redistribute it and/or
modify it under the terms of the GNU General Public License
as published by the Free Software Foundation; either version 2
of the License, or (at your option) any later version.

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU General Public License for more details.

You should have received a copy of the GNU General Public License
along with this program; if not, write to the Free Software
Foundation, Inc., 59 Temple Place - Suite 330, Boston, MA  02111-1307, USA. 


=================================================
*/

#import <Cocoa/Cocoa.h>

@class CEDocument;

// AppleScript Enum
typedef enum {
    CELowerCase = 'cClw',
    CEUpperCase = 'cCup',
    CECapitalized = 'cCcp'
} CECaseType;

typedef enum {
    CEFullwidth = 'rWfl',
    CEHalfwidth = 'rWhf',
} CEWidthType;

typedef enum {
    CEHiragana = 'cHgn',
    CEKatakana = 'cKkn',
} CEChangeKanaType;

typedef enum {
    CENFC = 'cNfc',
    CENFD = 'cNfd',
    CENFKC = 'cNkc',
    CENFKD = 'cNkd',
} CEUNFType;

@interface CETextSelection : NSObject <NSTextStorageDelegate>
{
    CEDocument *_document;
}

// Public method
- (instancetype)initWithDocument:(CEDocument *)inDocument;
- (void)cleanUpTextStorage:(NSTextStorage *)inTextStorage;

// for AppleScript accessor
- (NSTextStorage *)contents;
- (void)setContents:(id)inObject;
- (NSArray *)range;
- (void)setRange:(NSArray *)inArray;

// for AppleScript handler
- (void)handleShiftRight:(NSScriptCommand *)inCommand;
- (void)handleShiftLeft:(NSScriptCommand *)inCommand;
- (void)handleChangeCase:(NSScriptCommand *)inCommand;
- (void)handleChangeWidthRoman:(NSScriptCommand *)inCommand;
- (void)handleChangeKana:(NSScriptCommand *)inCommand;

@end
