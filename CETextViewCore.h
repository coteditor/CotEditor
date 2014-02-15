/*
=================================================
CETextViewCore
(for CotEditor)

Copyright (C) 2004-2007 nakamuxu.
http://www.aynimac.com/
=================================================

encoding="UTF-8"
Created:2005.03.30

------------
This class is based on JSDTextView (written by James S. Derry – http://www.balthisar.com)
JSDTextView is released as public domain.
arranged by nakamuxu, Dec 2004.
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
#import "NSEventAdditions.h"
#import "constants.h"

@class CEEditorView;

@interface CETextViewCore : NSTextView
{
    NSView *_slaveView;
    NSString *_newLineString;
    NSDictionary *_typingAttrs;
    NSColor *_highlightLineColor;

    NSRect _insertionRect;
    NSPoint _textContainerOriginPoint;
    NSRect _highlightLineAdditionalRect;

    CGFloat _lineSpacing;
    BOOL _isReCompletion;
    BOOL _updateOutlineMenuItemSelection;
    BOOL _isSelfDrop;
    BOOL _isReadingFromPboard;
}

// Public method
- (NSColor *)highlightLineColor;
- (void)setHighlightLineColor:(NSColor *)inColor;
- (void)drawHighlightLineAdditionalRect;
- (NSRect)highlightLineAdditionalRect;
- (void)setHighlightLineAdditionalRect:(NSRect)inRect;
- (NSString *)newLineString;
- (void)setNewLineString:(NSString *)inString;
- (NSView *)slaveView;
- (void)setSlaveView:(NSView *)inView;
- (NSDictionary *)typingAttrs;
- (void)setTypingAttrs:(NSDictionary *)inAttrs;
- (void)setEffectTypingAttrs;
- (void)setBackgroundColorWithAlpha:(CGFloat)inAlpha;
- (void)replaceSelectedStringTo:(NSString *)inString scroll:(BOOL)inBoolScroll;
- (void)replaceAllStringTo:(NSString *)inString;
- (void)insertAfterSelection:(NSString *)inString;
- (void)appendAllString:(NSString *)inString;
- (void)insertCustomTextWithPatternNum:(NSInteger)inPatternNum;
- (void)resetFont:(id)sender;
- (NSArray *)readablePasteboardTypes;
- (NSArray *)pasteboardTypesForString;
- (NSUInteger)dragOperationForDraggingInfo:(id <NSDraggingInfo>)inDragInfo type:(NSString *)inType;
- (BOOL)readSelectionFromPasteboard:(NSPasteboard *)inPboard type:(NSString *)inType;
- (NSRange)selectionRangeForProposedRange:(NSRange)inProposedSelRange
            granularity:(NSSelectionGranularity)inGranularity;
- (BOOL)isSelfDrop;
- (void)setIsSelfDrop:(BOOL)inValue;
- (BOOL)isReadingFromPboard;
- (void)setIsReadingFromPboard:(BOOL)inValue;
- (BOOL)isReCompletion;
- (void)setIsReCompletion:(BOOL)inValue;
- (BOOL)updateOutlineMenuItemSelection;
- (void)setUpdateOutlineMenuItemSelection:(BOOL)inValue;
- (CGFloat)lineSpacing;
- (void)setLineSpacing:(CGFloat)inLineSpacing;
- (void)setNewLineSpacingAndUpdate:(CGFloat)inLineSpacing;
- (void)doReplaceString:(NSString *)inString withRange:(NSRange)inRange 
            withSelected:(NSRange)inSelection withActionName:(NSString *)inActionName;
- (void)selectTextRangeValue:(NSValue *)inRangeValue;

// Action Message
- (IBAction)shiftRight:(id)sender;
- (IBAction)shiftLeft:(id)sender;
- (IBAction)exchangeLowercase:(id)sender;
- (IBAction)exchangeUppercase:(id)sender;
- (IBAction)exchangeCapitalized:(id)sender;
- (IBAction)exchangeFullwidthRoman:(id)sender;
- (IBAction)exchangeHalfwidthRoman:(id)sender;
- (IBAction)exchangeKatakana:(id)sender;
- (IBAction)exchangeHiragana:(id)sender;
- (IBAction)unicodeNormalizationNFD:(id)sender;
- (IBAction)unicodeNormalizationNFC:(id)sender;
- (IBAction)unicodeNormalizationNFKD:(id)sender;
- (IBAction)unicodeNormalizationNFKC:(id)sender;
- (IBAction)unicodeNormalization:(id)sender;
- (IBAction)inputYenMark:(id)sender;
- (IBAction)inputBackSlash:(id)sender;
- (IBAction)editHexColorCodeAsForeColor:(id)sender;
- (IBAction)editHexColorCodeAsBGColor:(id)sender;
- (IBAction)setSelectedRangeWithNSValue:(id)sender;
- (IBAction)setLineSpacingFromMenu:(id)sender;

@end
