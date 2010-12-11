/*
=================================================
CESyntax
(for CotEditor)

Copyright (C) 2004-2007 nakamuxu.
http://www.aynimac.com/
=================================================

encoding="UTF-8"
Created:2004.12.22

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
#import <OgreKit/OgreKit.h>
#import "CESyntaxManager.h"
#import "CELayoutManager.h"
#import "RKLMatchEnumerator.h"
#import "DEBUG_macro.h"

@class CETextViewCore;

@interface CESyntax : NSObject
{
    IBOutlet id _coloringIndicator;
    IBOutlet id _coloringCaption;

    CELayoutManager *_layoutManager;
    NSString *_wholeString;
    NSString *_localString;
    NSString *_syntaxStyleName;
    NSDictionary *_coloringDictionary;
    NSDictionary *_currentAttrs;
    NSDictionary *_singleQuotesAttrs;
    NSDictionary *_doubleQuotesAttrs;
    NSColor *_textColor;
    NSArray *_completeWordsArray;
    NSCharacterSet *_completeFirstLetterSet;
    NSRange _updateRange;
    NSModalSession _modalSession;

    BOOL _isIndicatorShown;
    BOOL _isPrinting;
    BOOL _isPanther;
    unsigned int _showColoringIndicatorTextLength;
}

// Public method
- (void)setWholeString:(NSString *)inString;
- (unsigned int)wholeStringLength;
- (void)setLocalString:(NSString *)inString;
- (void)setLayoutManager:(CELayoutManager *)inLayoutManager;
- (NSString *)syntaxStyleName;
- (void)setSyntaxStyleName:(NSString *)inStyleName;
- (BOOL)setSyntaxStyleNameFromExtension:(NSString *)inExtension;
- (NSArray *)completeWordsArray;
- (NSCharacterSet *)completeFirstLetterSet;
- (void)setCompleteWordsArrayFromColoringDictionary;
- (void)colorAllString:(NSString *)inWholeString;
- (void)colorVisibleRange:(NSRange)inRange withWholeString:(NSString *)inWholeString;
- (NSArray *)outlineMenuArrayWithWholeString:(NSString *)inWholeString;
- (BOOL)isPrinting;
- (void)setIsPrinting:(BOOL)inValue;

// Action Message
- (IBAction)cancelColoring:(id)sender;

@end
