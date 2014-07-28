/*
=================================================
CELineNumberView
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

@import CoreText;
#import "CELineNumberView.h"
#import "constants.h"


@interface CELineNumberView ()

@property (nonatomic) NSTimer *draggingTimer;
@property (nonatomic) NSLayoutConstraint *thicknessConstraint;

@property (nonatomic) NSString *fontName;
@property (nonatomic) NSColor *numberColor;

@end




#pragma mark -

@implementation CELineNumberView

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
        [self setAutoresizingMask:NSViewHeightSizable];
        [[self enclosingScrollView] setHasHorizontalScroller:NO];
        [[self enclosingScrollView] setHasVerticalScroller:NO];
        
        NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
        NSFont *font = [NSFont fontWithName:[defaults stringForKey:k_key_lineNumFontName] size:0] ? : [NSFont paletteFontOfSize:0];
        _fontName = [font fontName];
        _numberColor = [NSUnarchiver unarchiveObjectWithData:[defaults dataForKey:k_key_lineNumFontColor]];
        _backgroundAlpha = 1.0;
        
        // set thickness constraint
        _thicknessConstraint = [NSLayoutConstraint constraintWithItem:self
                                                            attribute:NSLayoutAttributeWidth
                                                            relatedBy:NSLayoutRelationEqual
                                                               toItem:nil
                                                            attribute:NSLayoutAttributeNotAnAttribute
                                                           multiplier:1
                                                             constant:0];
        [self addConstraint:_thicknessConstraint];
        
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
    
    // setup the variables we need for the loop
    NSString *string = [[self textView] string];
    
    if ([string length] == 0) { return; }
    
    NSLayoutManager *layoutManager = [[self textView] layoutManager]; // get owner's layout manager.
    
    // setup drawing attributes for the font size
    CGFloat masterFontSize = [[[self textView] font] pointSize];
    CGFloat fontSize = round(0.9 * masterFontSize);
    CTFontRef font = CTFontCreateWithName((CFStringRef)[self fontName], fontSize, nil);
    CFAutorelease(font);
    
    //ループの中で convertRect:fromView: を呼ぶと重いみたいなので一回だけ呼んで差分を調べておく(hetima)
    CGFloat crDistance;
    {
        NSRect numRect = [layoutManager lineFragmentRectForGlyphAtIndex:0 effectiveRange:NULL withoutAdditionalLayout:YES];
        crDistance = numRect.origin.y - NSHeight(numRect);
        numRect = [self convertRect:numRect fromView:[self textView]];
        crDistance = numRect.origin.y - crDistance;
    }
    
    // set graphics context
    CGContextRef context = (CGContextRef)[[NSGraphicsContext currentContext] graphicsPort];
    CGContextSaveGState(context);
    
    CGFontRef cgFont = CTFontCopyGraphicsFont(font, NULL);
    CGContextSetFont(context, cgFont);
    CGContextSetFontSize(context, fontSize);
    CGContextSetFillColorWithColor(context, [[self numberColor] CGColor]);
    CFRelease(cgFont);
    
    // prepare '-' glyph (wrapped mark)
    CGGlyph dashGlyph;
    unichar dash = '-';
    CTFontGetGlyphsForCharacters(font, &dash, &dashGlyph, 1);
    // prepare number glyphs
    CGGlyph digitGlyphs[10];
    unichar numbers[10];
    [@"0123456789" getCharacters:numbers range:NSMakeRange(0, 10)];
    CTFontGetGlyphsForCharacters(font, numbers, digitGlyphs, 10);
    
    //文字幅を計算しておく 等幅扱い
    //いずれにしても等幅じゃないと奇麗に揃わないので等幅だということにしておく(hetima)
    CGSize advances[10];
    CTFontGetAdvancesForGlyphs(font, kCTFontHorizontalOrientation, digitGlyphs, advances, 10);
    CGFloat charWidth = advances[8].width;  // use '8' to get width
    
    // adjust drawing origin
    CGFloat inset = (CGFloat)[[NSUserDefaults standardUserDefaults] doubleForKey:k_key_textContainerInsetHeightTop];
    CGFloat diff = (masterFontSize - fontSize) / 2;
    CGFloat ascent = CTFontGetAscent(font);
    CGContextSetTextMatrix(context, CGAffineTransformMakeTranslation(-k_lineNumPadding, - inset - diff - ascent));
    
    // get glyph range which line number should be drawn
    NSRange visibleGlyphRange = [layoutManager glyphRangeForBoundingRect:[[self textView] visibleRect]
                                                         inTextContainer:[[self textView] textContainer]];
    // count line endings to find first line number to draw
    NSRegularExpression *regex = [NSRegularExpression regularExpressionWithPattern:@"\n" options:0 error:nil];
    NSUInteger startLineNum = [regex numberOfMatchesInString:string options:0
                                                       range:NSMakeRange(0, [layoutManager characterIndexForGlyphAtIndex:
                                                                             visibleGlyphRange.location])] + 1;
    
    // counters
    NSUInteger glyphCount = visibleGlyphRange.location;
    NSUInteger endGlyphIndex = NSMaxRange(visibleGlyphRange);
    NSUInteger lineNum = startLineNum;
    NSUInteger lastLineNum = 0;
    
    for (NSUInteger glyphIndex = visibleGlyphRange.location; glyphIndex < endGlyphIndex; lineNum++) { // count "REAL" lines
        NSUInteger charIndex = [layoutManager characterIndexForGlyphAtIndex:glyphIndex];
        glyphIndex = NSMaxRange([layoutManager glyphRangeForCharacterRange:[string lineRangeForRange:NSMakeRange(charIndex, 0)]
                                                      actualCharacterRange:NULL]);
        
        while (glyphCount < glyphIndex) { // handle "DRAWN" (wrapped) lines
            NSRange range;
            NSRect numRect = [layoutManager lineFragmentRectForGlyphAtIndex:glyphCount effectiveRange:&range withoutAdditionalLayout:YES];
            numRect.origin.x = dirtyRect.origin.x;  // don't care about x -- just force it into the rect
            numRect.origin.y = crDistance - NSMaxY(numRect);
            
            if (lastLineNum == lineNum) {  // wrapped line
                CGPoint position = CGPointMake(NSWidth([self frame]) - charWidth, NSMaxY(numRect));
                CGContextShowGlyphsAtPositions(context, &dashGlyph, &position, 1);  // draw wrapped mark
                
            } else {  // new line
                int digit = (int)log10(lineNum) + 1;
                
                // adjust frame width
                CGFloat currentWidth = NSWidth([self frame]);
                CGFloat requiredWidth = charWidth * digit;
                if ((currentWidth - k_lineNumPadding) < requiredWidth) {
                    while ((currentWidth - k_lineNumPadding) < requiredWidth) {
                        currentWidth += charWidth;
                    }
                    [self setWidth:currentWidth]; // set a wider width if needed.
                }
                
                // get glyphs and positions
                CGGlyph glyphs[digit];
                CGPoint positions[digit];
                for (int i = 0; i < digit; i++) {
                    int index = (lineNum % (int)pow(10, i + 1)) / pow(10, i);  // get number of desired digit
                    
                    glyphs[i] = digitGlyphs[index];
                    positions[i] = CGPointMake(currentWidth - (i + 1) * charWidth, NSMaxY(numRect));
                }
                
                CGContextShowGlyphsAtPositions(context, glyphs, positions, digit);  // draw line number
            }
            
            lastLineNum = lineNum;
            glyphCount = NSMaxRange(range);
        }
    }
    
    // Draw the last "extra" line number.
    NSRect numRect = [layoutManager extraLineFragmentUsedRect];
    if (!NSEqualSizes(numRect.size, NSZeroSize)) {
        numRect.origin.x = dirtyRect.origin.x;  // don't care about x -- just force it into the rect
        numRect.origin.y = crDistance - NSMaxY(numRect);
        
        int digit = (int)log10(lineNum) + 1;
        
        // adjust frame width
        CGFloat currentWidth = NSWidth([self frame]);
        CGFloat requiredWidth = charWidth * digit;
        if ((currentWidth - k_lineNumPadding) < requiredWidth) {
            while ((currentWidth - k_lineNumPadding) < requiredWidth) {
                currentWidth += charWidth;
            }
            [self setWidth:currentWidth]; // set a wider width if needed.
        }
        
        // get glyphs and positions
        CGGlyph glyphs[digit];
        CGPoint positions[digit];
        for (int i = 0; i < digit; i++) {
            int index = (lineNum % (int)pow(10, i + 1)) / pow(10, i);  // get number of desired digit
            
            glyphs[i] = digitGlyphs[index];
            positions[i] = CGPointMake(currentWidth - (i + 1) * charWidth, NSMaxY(numRect));
        }
        
        CGContextShowGlyphsAtPositions(context, glyphs, positions, digit);  // draw line number
    }
    
    CGContextRestoreGState(context);
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
    [[self thicknessConstraint] setConstant:width];
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
