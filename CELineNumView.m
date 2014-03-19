/*
=================================================
CELineNumView
(for CotEditor)

 Copyright (C) 2004-2007 nakamuxu.
 Copyright (C) 2014 CotEditor Project
 http://coteditor.github.io
=================================================

encoding="UTF-8"
Created:2005.03.30
 
------------
This class is based on JSDTextView (written by James S. Derry – http://www.balthisar.com)
JSDTextView is released as public domain.
arranged by nakamuxu, Dec 2004.
arranged by Hetima, Aug 2005.
arranged by 1024jp, Mar 2014.
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
#import "constants.h"


@implementation CELineNumView

#pragma mark Public Methods

//=======================================================
// Public method
//
//=======================================================

// ------------------------------------------------------
- (instancetype)initWithFrame:(NSRect)frameRect
// initialize
// ------------------------------------------------------
{
    self = [super initWithFrame:frameRect];
    if (self) {
        [self setBackgroundAlpha:1.0];
        [self setAutoresizingMask:NSViewHeightSizable];
        [[self enclosingScrollView] setHasHorizontalScroller:NO];
        [[self enclosingScrollView] setHasVerticalScroller:NO];
    }
    return self;
}


// ------------------------------------------------------
- (void)setShowLineNum:(BOOL)showLineNum
// set to show line numbers.
// ------------------------------------------------------
{
    if (showLineNum != [self showLineNum]) {
        _showLineNum = showLineNum;
        
        CGFloat width = showLineNum ? k_defaultLineNumWidth : 0.0;
        [self setWidth:width];
    }
}


// ------------------------------------------------------
- (void)drawRect:(NSRect)dirtyRect
// draw line numbers.
// ------------------------------------------------------
{
    if (![self masterView] || ![self showLineNum]) {
        return;
    }

    id values = [[NSUserDefaultsController sharedUserDefaultsController] values];

    // fill in the background
    NSColor *backgroundColor = [[NSColor controlHighlightColor] colorWithAlphaComponent:[self backgroundAlpha]];
    [backgroundColor set];
    [NSBezierPath fillRect:dirtyRect];
    // draw frame border (0.5px)
    [[NSColor controlShadowColor] set];
    [NSBezierPath strokeLineFromPoint:NSMakePoint(NSMaxX(dirtyRect), NSMaxY(dirtyRect))
                              toPoint:NSMakePoint(NSMaxX(dirtyRect), NSMinY(dirtyRect))];
    
    // adjust rect so we won't later draw into the scrollbar area
    if ([[[self masterView] scrollView] hasHorizontalScroller]) {
        CGFloat horizontalScrollAdj = NSHeight([[[[self masterView] scrollView] horizontalScroller] frame]) / 2;
        dirtyRect.origin.y += horizontalScrollAdj; // (shift the drawing frame reference up.)
        dirtyRect.size.height -= horizontalScrollAdj; // (and shrink it the same distance.)
    }
    // setup drawing attributes for the font size and color. 
    NSMutableDictionary *attrs = [[NSMutableDictionary alloc] init]; // ===== init
    CGFloat fontSize = (CGFloat)[[values valueForKey:k_key_lineNumFontSize] doubleValue];
    NSFont *font = [NSFont fontWithName:[values valueForKey:k_key_lineNumFontName] size:fontSize];
    if (font == nil) {
        font = [NSFont paletteFontOfSize:9];
    }
    attrs[NSFontAttributeName] = font;
    attrs[NSForegroundColorAttributeName] = [NSUnarchiver unarchiveObjectWithData:[values valueForKey:k_key_lineNumFontColor]];

    //文字幅を計算しておく 等幅扱い
    //いずれにしても等幅じゃないと奇麗に揃わないので等幅だということにしておく(hetima)
    CGFloat charWidth = [@"8" sizeWithAttributes:attrs].width;

    // setup the variables we need for the loop
    NSRange range;       // a range for counting lines
    NSString *str = [[self masterView] string];
    NSString *numStr;    // a temporary string for Line Number
    NSString *wrappedLineMark = [[values valueForKey:k_key_showWrappedLineMark] boolValue] ? @"-" : @" ";
    NSUInteger glyphIndex, theBefore, glyphCount; // glyph counter
    NSUInteger charIndex;
    NSUInteger lineNum;     // line counter
    CGFloat reqWidth;      // width calculator holder -- width needed to show string
    CGFloat curWidth;      // width calculator holder -- my current width
    CGFloat adj = 0;       // adjust vertical value for line number drawing
    CGFloat insetAdj = (CGFloat)[[values valueForKey:k_key_textContainerInsetHeightTop] doubleValue];
    NSRect numRect;      // rectange holder
    NSPoint numPoint;    // point holder
    CELayoutManager *layoutManager = (CELayoutManager *)[[[self masterView] textView] layoutManager]; // get _owner's layout manager.

    theBefore = 0;
    lineNum = 1;
    glyphCount = 0;

    CGFloat crDistance;
    NSUInteger numberOfGlyphs = [layoutManager numberOfGlyphs];

    if(numberOfGlyphs > 0) {
        //ループの中で convertRect:fromView: を呼ぶと重いみたいなので一回だけ呼んで差分を調べておく(hetima)
        numRect = [layoutManager lineFragmentRectForGlyphAtIndex:glyphCount effectiveRange:NULL];
        crDistance = numRect.origin.y - NSHeight(numRect);
        numRect = [self convertRect:numRect fromView:[[self masterView] textView]];
        crDistance = numRect.origin.y - crDistance;
    } else {
        return;
    }
    adj = k_lineNumFontDescender - ([[[[self masterView] textView] font] pointSize] + fontSize) / 2 - insetAdj;

    for (glyphIndex = 0; glyphIndex < numberOfGlyphs; lineNum++) { // count "REAL" lines
        charIndex = [layoutManager characterIndexForGlyphAtIndex:glyphIndex];
        glyphIndex = NSMaxRange([layoutManager glyphRangeForCharacterRange:[str lineRangeForRange:NSMakeRange(charIndex, 0)]
                                                      actualCharacterRange:NULL]);
        while (glyphCount < glyphIndex) { // handle "DRAWN" (wrapped) lines
            numRect = [layoutManager lineFragmentRectForGlyphAtIndex:glyphCount effectiveRange:&range];
            numRect.origin.x = dirtyRect.origin.x;  // don't care about x -- just force it into the rect
            numRect.origin.y = crDistance - NSHeight(numRect) - numRect.origin.y;
            if (NSIntersectsRect(numRect, dirtyRect)) {
                numStr = (theBefore != lineNum) ? [NSString stringWithFormat:@"%ld", (long)lineNum] : wrappedLineMark;
                reqWidth = charWidth * [numStr length];
                curWidth = NSWidth([self frame]);
                if ((curWidth - k_lineNumPadding) < reqWidth) {
                    while ((curWidth - k_lineNumPadding) < reqWidth) {
                        curWidth += charWidth;
                    }
                    [self setWidth:curWidth]; // set a wider width if needed.
                }
                numPoint = NSMakePoint(curWidth - reqWidth - k_lineNumPadding,
                                       numRect.origin.y + adj + NSHeight(numRect));
                [numStr drawAtPoint:numPoint withAttributes:attrs]; // draw the line number.
                theBefore = lineNum;
            } else if (NSMaxY(numRect) < 0) { // no need to draw
                return;
            }
            glyphCount = NSMaxRange(range);
        }
    }
    // Draw the last "extra" line number.
    numRect = [layoutManager extraLineFragmentRect];
    // 10.5.1では、1行目が改行だけのときnumRect.origin.yに行の高さがセットされてしまうことへ対処（2007.12.01）
    if ((numRect.size.width > 0) && (numRect.size.height > 0)) {
//    if (!NSEqualRects(numRect, NSZeroRect)) {
        numStr = (theBefore != lineNum) ? [NSString stringWithFormat:@"%ld", (long)lineNum] : @" ";
        reqWidth = charWidth * [numStr length];
        curWidth = NSWidth([self frame]);
        if ((curWidth - k_lineNumPadding) < reqWidth) {
            while ((curWidth - k_lineNumPadding) < reqWidth) {
                curWidth += charWidth;
            }
            [self setWidth:curWidth]; // set a wider width if needed.
        }
        numPoint = NSMakePoint((curWidth - reqWidth - k_lineNumPadding),
                               crDistance - numRect.origin.y + adj);
        [numStr drawAtPoint:numPoint withAttributes:attrs]; // draw the last line number.
    }
}


// ------------------------------------------------------
- (void)updateLineNumber:(id)sender
// redraw line numbers
// ------------------------------------------------------
{
    [self setNeedsDisplay:YES];
}



#pragma mark - Private Methods

//=======================================================
// Private method
//
//=======================================================

// ------------------------------------------------------
- (void)setWidth:(CGFloat)width
// set view width.
// ------------------------------------------------------
{
    CGFloat adjWidth = width - NSWidth([self frame]);
    NSRect newFrame;

    // set masterView width
    newFrame = [[[self masterView] scrollView] frame];
    newFrame.origin.x += adjWidth;
    newFrame.size.width -= adjWidth;
    [[[self masterView] scrollView] setFrame:newFrame];
    
    // set LineNumView width
    newFrame = [self frame];
    newFrame.size.width += adjWidth;
    [self setFrame:newFrame];

    [self setNeedsDisplay:YES];
}

@end
