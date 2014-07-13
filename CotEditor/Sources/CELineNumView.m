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
#import "constants.h"


@interface CELineNumView ()

@property (nonatomic) NSTimer *draggingTimer;

@end




#pragma mark -

@implementation CELineNumView

#pragma mark Superclass Methods

//=======================================================
// Superclass method
//
//=======================================================

// ------------------------------------------------------
/// initialize
- (instancetype)initWithFrame:(NSRect)frameRect
// ------------------------------------------------------
{
    self = [super initWithFrame:frameRect];
    if (self) {
        [self setBackgroundAlpha:1.0];
        [self setAutoresizingMask:NSViewHeightSizable];
        [[self enclosingScrollView] setHasHorizontalScroller:NO];
        [[self enclosingScrollView] setHasVerticalScroller:NO];
        
        // observe window resize
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(updateLineNumber:)
                                                     name:NSWindowDidResizeNotification
                                                   object:[self window]];
    }
    return self;
}


// ------------------------------------------------------
/// clean up
- (void)dealloc
// ------------------------------------------------------
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}


// ------------------------------------------------------
/// draw line numbers.
- (void)drawRect:(NSRect)dirtyRect
// ------------------------------------------------------
{
    if (![self showLineNum] || ![self textView]) { return; }
    
    // fill in the background
    NSColor *backgroundColor = [[NSColor controlHighlightColor] colorWithAlphaComponent:[self backgroundAlpha]];
    [backgroundColor set];
    [NSBezierPath fillRect:dirtyRect];
    
    // draw frame border (0.5px)
    [[NSColor controlShadowColor] set];
    [NSBezierPath strokeLineFromPoint:NSMakePoint(NSMaxX(dirtyRect), NSMaxY(dirtyRect))
                              toPoint:NSMakePoint(NSMaxX(dirtyRect), NSMinY(dirtyRect))];
    
    // adjust rect so we won't later draw into the scrollbar area
    if ([[self scrollView] hasHorizontalScroller]) {
        CGFloat horizontalScrollAdj = NSHeight([[[self scrollView] horizontalScroller] frame]) / 2;
        dirtyRect.origin.y += horizontalScrollAdj; // (shift the drawing frame reference up.)
        dirtyRect.size.height -= horizontalScrollAdj; // (and shrink it the same distance.)
    }
    
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    
    // setup drawing attributes for the font size and color.
    CGFloat masterFontSize = [[[self textView] font] pointSize];
    CGFloat fontSize = round(0.9 * masterFontSize);
    NSFont *font = [NSFont fontWithName:[defaults stringForKey:k_key_lineNumFontName] size:fontSize] ? : [NSFont paletteFontOfSize:fontSize];
    NSDictionary *attrs = @{NSFontAttributeName: font,
                            NSForegroundColorAttributeName: [NSUnarchiver unarchiveObjectWithData:
                                                             [defaults dataForKey:k_key_lineNumFontColor]]};
    
    //文字幅を計算しておく 等幅扱い
    //いずれにしても等幅じゃないと奇麗に揃わないので等幅だということにしておく(hetima)
    CGFloat charWidth = [@"8" sizeWithAttributes:attrs].width;
    
    // setup the variables we need for the loop
    NSString *string = [[self textView] string];
    NSLayoutManager *layoutManager = [[self textView] layoutManager]; // get owner's layout manager.
    
    NSUInteger numberOfGlyphs = [layoutManager numberOfGlyphs];
    
    if (numberOfGlyphs == 0) { return; }
    
    //ループの中で convertRect:fromView: を呼ぶと重いみたいなので一回だけ呼んで差分を調べておく(hetima)
    CGFloat crDistance;
    {
        NSRect numRect = [layoutManager lineFragmentRectForGlyphAtIndex:0 effectiveRange:NULL];
        crDistance = numRect.origin.y - NSHeight(numRect);
        numRect = [self convertRect:numRect fromView:[self textView]];
        crDistance = numRect.origin.y - crDistance;
    }
    
    // adjust values for line number drawing
    CGFloat insetAdj = (CGFloat)[defaults doubleForKey:k_key_textContainerInsetHeightTop];
    CGFloat adj = k_lineNumFontDescender - (masterFontSize + fontSize) / 2 - insetAdj;
    
    // counters
    NSUInteger lastLineNum = 0;
    NSUInteger lineNum = 1;
    NSUInteger glyphCount = 0;
    
    for (NSUInteger glyphIndex = 0; glyphIndex < numberOfGlyphs; lineNum++) { // count "REAL" lines
        NSUInteger charIndex = [layoutManager characterIndexForGlyphAtIndex:glyphIndex];
        glyphIndex = NSMaxRange([layoutManager glyphRangeForCharacterRange:[string lineRangeForRange:NSMakeRange(charIndex, 0)]
                                                      actualCharacterRange:NULL]);
        while (glyphCount < glyphIndex) { // handle "DRAWN" (wrapped) lines
            NSRange range;
            NSRect numRect = [layoutManager lineFragmentRectForGlyphAtIndex:glyphCount effectiveRange:&range];
            numRect.origin.x = dirtyRect.origin.x;  // don't care about x -- just force it into the rect
            numRect.origin.y = crDistance - NSHeight(numRect) - numRect.origin.y;
            if ([self needsToDrawRect:numRect]) {
                NSString *numStr = (lastLineNum != lineNum) ? [NSString stringWithFormat:@"%tu", lineNum] : @"-";
                CGFloat requiredWidth = charWidth * [numStr length];
                CGFloat currentWidth = NSWidth([self frame]);
                if ((currentWidth - k_lineNumPadding) < requiredWidth) {
                    while ((currentWidth - k_lineNumPadding) < requiredWidth) {
                        currentWidth += charWidth;
                    }
                    [self setWidth:currentWidth]; // set a wider width if needed.
                }
                NSPoint point = NSMakePoint(currentWidth - requiredWidth - k_lineNumPadding,
                                            numRect.origin.y + adj + NSHeight(numRect));
                [numStr drawAtPoint:point withAttributes:attrs]; // draw the line number.
                lastLineNum = lineNum;
            } else if (NSMaxY(numRect) < 0) { // no need to draw
                return;
            }
            glyphCount = NSMaxRange(range);
        }
    }
    // Draw the last "extra" line number.
    NSRect numRect = [layoutManager extraLineFragmentRect];
    if (!NSEqualSizes(numRect.size, NSZeroSize)) {
        NSString *numStr = (lastLineNum != lineNum) ? [NSString stringWithFormat:@"%tu", lineNum] : @" ";
        CGFloat requiredWidth = charWidth * [numStr length];
        CGFloat currentWidth = NSWidth([self frame]);
        if ((currentWidth - k_lineNumPadding) < requiredWidth) {
            while ((currentWidth - k_lineNumPadding) < requiredWidth) {
                currentWidth += charWidth;
            }
            [self setWidth:currentWidth]; // set a wider width if needed.
        }
        NSPoint point = NSMakePoint(currentWidth - requiredWidth - k_lineNumPadding,
                               crDistance - numRect.origin.y + adj);
        [numStr drawAtPoint:point withAttributes:attrs]; // draw the last line number.
    }
}


// ------------------------------------------------------
/// start selecting correspondent lines in text view with drag / click event
- (void)mouseDown:(NSEvent *)theEvent
// ------------------------------------------------------
{
    // get start point
    NSPoint point = [[self window] convertRectToScreen:NSMakeRect([theEvent locationInWindow].x,
                                                                  [theEvent locationInWindow].y, 0, 0)].origin;
    NSUInteger index = [[self textView] characterIndexForPoint:point];
    
    [self selectLines:nil];  // for single click event
    
    // repeat while dragging
    [self setDraggingTimer:[NSTimer scheduledTimerWithTimeInterval:0.05
                                                            target:self
                                                          selector:@selector(selectLines:)
                                                          userInfo:@(index)
                                                           repeats:YES]];
}


// ------------------------------------------------------
/// end selecting correspondent lines in text view with drag event
- (void)mouseUp:(NSEvent *)theEvent
// ------------------------------------------------------
{
    [[self draggingTimer] invalidate];
    [self setDraggingTimer:nil];
}



#pragma mark Public Methods

//=======================================================
// Public method
//
//=======================================================

// ------------------------------------------------------
/// set to show line numbers.
- (void)setShowLineNum:(BOOL)showLineNum
// ------------------------------------------------------
{
    if (showLineNum != [self showLineNum]) {
        _showLineNum = showLineNum;
        
        CGFloat width = showLineNum ? k_defaultLineNumWidth : 0.0;
        [self setWidth:width];
    }
}


// ------------------------------------------------------
/// redraw line numbers
- (void)updateLineNumber:(id)sender
// ------------------------------------------------------
{
    [self setNeedsDisplay:YES];
}



#pragma mark Private Methods

//=======================================================
// Private method
//
//=======================================================

// ------------------------------------------------------
/// return scroll view of the textView (not enclosing scroll view of self)
- (NSScrollView *)scrollView
// ------------------------------------------------------
{
    return [[self textView] enclosingScrollView];
}


// ------------------------------------------------------
/// set view width.
- (void)setWidth:(CGFloat)width
// ------------------------------------------------------
{
    CGFloat adjWidth = width - NSWidth([self frame]);
    NSRect newFrame;

    // set masterView width
    newFrame = [[self scrollView] frame];
    newFrame.origin.x += adjWidth;
    newFrame.size.width -= adjWidth;
    [[self scrollView] setFrame:newFrame];
    
    // set LineNumView width
    newFrame = [self frame];
    newFrame.size.width += adjWidth;
    [self setFrame:newFrame];

    [self setNeedsDisplay:YES];
}


// ------------------------------------------------------
/// select lines while dragging event
- (void)selectLines:(NSTimer *)timer
// ------------------------------------------------------
{
    NSTextView *textView = [self textView];
    NSPoint point = [NSEvent mouseLocation];  // screen based point
    
    // scroll text view if needed
    CGFloat y = [self convertPoint:[[self window] convertRectFromScreen:NSMakeRect(point.x, point.y, 0, 0)].origin
                          fromView:nil].y;
    if (y < 0) {
        [textView scrollLineDown:nil];
    } else if (y > NSHeight([self bounds])) {
        [textView scrollLineUp:nil];
    }
    
    // select lines
    NSUInteger currentIndex = [textView characterIndexForPoint:point];
    NSUInteger clickedIndex = timer ? [[timer userInfo] unsignedIntegerValue] : currentIndex;
    NSRange range = [[textView string] lineRangeForRange:NSMakeRange(MIN(currentIndex, clickedIndex),
                                                                     abs(currentIndex - clickedIndex))];
    [textView setSelectedRange:range];
}

@end
