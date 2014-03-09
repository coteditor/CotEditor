/*
=================================================
CELineNumView
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
arranged by Hetima, Aug 2005.
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

#import "CELineNumView.h"
#import "CEEditorView.h"

//=======================================================
// Private method
//
//=======================================================

@interface CELineNumView (Private)
- (void)setWidth:(CGFloat)inValue;
@end


//------------------------------------------------------------------------------------------




@implementation CELineNumView

#pragma mark ===== Public method =====

//=======================================================
// Public method
//
//=======================================================

// ------------------------------------------------------
- (id)initWithFrame:(NSRect)inFrame
// initialize
// ------------------------------------------------------
{
    self = [super initWithFrame:inFrame];
    if (self) {
        [self setAutoresizingMask:NSViewHeightSizable];
        [[self enclosingScrollView] setHasHorizontalScroller:NO];
        [[self enclosingScrollView] setHasVerticalScroller:NO];
    }
    return self;
}


// ------------------------------------------------------
- (void)dealloc
// clean up
// ------------------------------------------------------
{
//    _masterView was not retained

    [super dealloc];
}


// ------------------------------------------------------
- (CESubSplitView *)masterView
// return main textView
// ------------------------------------------------------
{
    return _masterView; // not retain
}


// ------------------------------------------------------
- (void)setMasterView:(CESubSplitView *)inView
// set main textView in myself. *NOT* retain.
// ------------------------------------------------------
{
    _masterView = inView;
}


// ------------------------------------------------------
- (BOOL)showLineNum
// is set to show line numbers?
// ------------------------------------------------------
{
    return _showLineNum;
}


// ------------------------------------------------------
- (void)setShowLineNum:(BOOL)inBool
// set to show line numbers.
// ------------------------------------------------------
{
    if (inBool != _showLineNum) {
        _showLineNum = !_showLineNum;
        if (!_showLineNum) {
            [self setWidth:0];
        } else {
            [self setWidth:k_defaultLineNumWidth];
        }
    }
}


// ------------------------------------------------------
- (void)drawRect:(NSRect)inRect
// draw line numbers.
// ------------------------------------------------------
{
    if ((!_masterView) || (!_showLineNum)) {
        return;
    }

    id theValues = [[NSUserDefaultsController sharedUserDefaultsController] values];

    // fill in the background
    [[NSColor controlHighlightColor] set];
    [NSBezierPath fillRect:inRect];
    // draw frame border
    [[NSColor controlShadowColor] set];
    [NSBezierPath strokeLineFromPoint:NSMakePoint(NSMaxX(inRect), NSMaxY(inRect)) 
        toPoint:NSMakePoint(NSMaxX(inRect), NSMinY(inRect))];
    // adjust rect so we won't later draw into the scrollbar area
    if ([[_masterView scrollView] hasHorizontalScroller]) {
        CGFloat theHScrollAdj = NSHeight([[[_masterView scrollView] horizontalScroller] frame]) / 2;
        inRect.origin.y += theHScrollAdj; // (shift the drawing frame reference up.)
        inRect.size.height -= theHScrollAdj; // (and shrink it the same distance.)
    }
    // setup drawing attributes for the font size and color. 
    NSMutableDictionary *theAttrs = [[NSMutableDictionary alloc] init]; // ===== init
    CGFloat theLineNumFontSize = (CGFloat)[[theValues valueForKey:k_key_lineNumFontSize] doubleValue];
    NSFont *theFont = [NSFont fontWithName:[theValues valueForKey:k_key_lineNumFontName] size:theLineNumFontSize];
    if (theFont == nil) {
        theFont = [NSFont paletteFontOfSize:9];
    }
    theAttrs[NSFontAttributeName] = theFont;
    theAttrs[NSForegroundColorAttributeName] = [NSUnarchiver unarchiveObjectWithData:[theValues valueForKey:k_key_lineNumFontColor]];

    //文字幅を計算しておく 等幅扱い
    //いずれにしても等幅じゃないと奇麗に揃わないので等幅だということにしておく(hetima)
    CGFloat charWidth = [@"8" sizeWithAttributes:theAttrs].width;

    // setup the variables we need for the loop
    NSRange theRange;       // a range for counting lines
    NSString *theStr = [_masterView string];
    NSString *theNumStr;    // a temporary string for Line Number
    NSString *theWrapedLineMark = ([[theValues valueForKey:k_key_showWrappedLineMark] boolValue]) ? 
            @"-" : @" ";
    NSInteger theGlyphIndex, theBefore, theGlyphCount; // glyph counter
    NSInteger theCharIndex;
    NSInteger theLineNum;     // line counter
    CGFloat theReqWidth;      // width calculator holder -- width needed to show string
    CGFloat theCurWidth;      // width calculator holder -- my current width
    CGFloat theAdj = 0;       // adjust vertical value for line number drawing
    CGFloat theInsetAdj = (CGFloat)[[theValues valueForKey:k_key_textContainerInsetHeightTop] doubleValue];
    NSRect theNumRect;      // rectange holder
    NSPoint theNumPoint;    // point holder
    CELayoutManager *theManager = (CELayoutManager *)[[_masterView textView] layoutManager]; // get _owner's layout manager.

    theBefore = 0;
    theLineNum = 1;
    theGlyphCount = 0;

    CGFloat crDistance;
    NSUInteger numberOfGlyphs = [theManager numberOfGlyphs];

    if(numberOfGlyphs > 0) {
        //ループの中で convertRect:fromView: を呼ぶと重いみたいなので一回だけ呼んで差分を調べておく(hetima)
        theNumRect = [theManager lineFragmentRectForGlyphAtIndex:theGlyphCount effectiveRange:NULL];
        crDistance = theNumRect.origin.y - NSHeight(theNumRect);
        theNumRect = [self convertRect:theNumRect fromView:[_masterView textView]];
        crDistance = theNumRect.origin.y - crDistance;
    } else {
        [theAttrs release]; // ===== release
        return;
    }
    theAdj = k_lineNumFontDescender - ([[[_masterView textView] font] pointSize] + theLineNumFontSize) / 2 - theInsetAdj;

    for (theGlyphIndex = 0; theGlyphIndex < numberOfGlyphs; theLineNum++) { // count "REAL" lines
        theCharIndex = [theManager characterIndexForGlyphAtIndex:theGlyphIndex];
        theGlyphIndex = NSMaxRange([theManager glyphRangeForCharacterRange:
                            [theStr lineRangeForRange:NSMakeRange(theCharIndex, 0)] 
                            actualCharacterRange:NULL]);
        while (theGlyphCount < theGlyphIndex) { // handle "DRAWN" (wrapped) lines
            theNumRect = [theManager lineFragmentRectForGlyphAtIndex:theGlyphCount effectiveRange:&theRange];
            theNumRect.origin.x = inRect.origin.x;  // don't care about x -- just force it into the rect
            theNumRect.origin.y = crDistance - NSHeight(theNumRect) - theNumRect.origin.y;
            if (NSIntersectsRect(theNumRect, inRect)) {
                theNumStr = (theBefore != theLineNum) ? 
                    [NSString stringWithFormat:@"%ld", (long)theLineNum] : theWrapedLineMark;
                theReqWidth = charWidth * [theNumStr length];
                theCurWidth = NSWidth([self frame]);
                if ((theCurWidth - k_lineNumPadding) < theReqWidth) {
                    while ((theCurWidth - k_lineNumPadding) < theReqWidth) { theCurWidth += charWidth;}
                    [self setWidth:theCurWidth]; // set a wider width if needed.
                }
                theNumPoint = NSMakePoint((theCurWidth - theReqWidth - k_lineNumPadding), 
                                theNumRect.origin.y + theAdj + NSHeight(theNumRect));
                [theNumStr drawAtPoint:theNumPoint withAttributes:theAttrs]; // draw the line number.
                theBefore = theLineNum;
            } else if (NSMaxY(theNumRect) < 0) { // no need to draw
                [theAttrs release]; // ===== release
                return;
            }
            theGlyphCount = NSMaxRange(theRange);
        }
    }
    // Draw the last "extra" line number.
    theNumRect = [theManager extraLineFragmentRect];
    // 10.5.1では、1行目が改行だけのときtheNumRect.origin.yに行の高さがセットされてしまうことへ対処（2007.12.01）
    if ((theNumRect.size.width > 0) && (theNumRect.size.height > 0)) {
//    if (!NSEqualRects(theNumRect, NSZeroRect)) {
        theNumStr = (theBefore != theLineNum) ? 
            [NSString stringWithFormat:@"%ld", (long)theLineNum] : 
            @" ";
        theReqWidth = charWidth * [theNumStr length];
        theCurWidth = NSWidth([self frame]);
        if ((theCurWidth - k_lineNumPadding) < theReqWidth) {
            while ((theCurWidth - k_lineNumPadding) < theReqWidth) { theCurWidth += charWidth;}
            [self setWidth:theCurWidth]; // set a wider width if needed.
        }
        theNumPoint = NSMakePoint((theCurWidth - theReqWidth - k_lineNumPadding), 
                        crDistance - theNumRect.origin.y + theAdj);
        [theNumStr drawAtPoint:theNumPoint withAttributes:theAttrs]; // draw the last line number.
    }
    [theAttrs release]; // ===== release
}


// ------------------------------------------------------
- (void)updateLineNumber:(id)sender
// redraw line numbers
// ------------------------------------------------------
{
    [self setNeedsDisplay:YES];
}



@end



@implementation CELineNumView (Private)

//=======================================================
// Private method
//
//=======================================================

// ------------------------------------------------------
- (void)setWidth:(CGFloat)inValue
// set view width.
// ------------------------------------------------------
{
    CGFloat theAdjWidth = (inValue - NSWidth([self frame]));
    NSRect theNewFrame;

    // set masterView width
    theNewFrame = [[[self masterView] scrollView] frame];
    theNewFrame.origin.x += theAdjWidth;
    theNewFrame.size.width -= theAdjWidth;
    [[[self masterView] scrollView] setFrame:theNewFrame];
    
    // set LineNumView width
    theNewFrame = [self frame];
    theNewFrame.size.width += theAdjWidth;
    [self setFrame:theNewFrame];

    [self setNeedsDisplay:YES];
}


@end