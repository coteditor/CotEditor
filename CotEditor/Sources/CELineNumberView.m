/*
 ==============================================================================
 CELineNumberView
 
 CotEditor
 http://coteditor.com
 
 Created on 2005-03-30 by nakamuxu
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

@import CoreText;
#import "CELineNumberView.h"
#import "constants.h"


@interface CELineNumberView ()

@property (nonatomic) CGFloat thickness;
@property (nonatomic) NSTimer *draggingTimer;

@end




#pragma mark -

@implementation CELineNumberView

static const NSString *LineNumberFontName;


#pragma mark Superclass Methods

// ------------------------------------------------------
/// initialize class
+ (void)initialize
// ------------------------------------------------------
{
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        NSString *defaultFontName = [[NSUserDefaults standardUserDefaults] stringForKey:CEDefaultLineNumFontNameKey];
        NSFont *font = [NSFont fontWithName:defaultFontName size:0] ? : [NSFont paletteFontOfSize:0];
        LineNumberFontName = [font fontName];
    });
}


// ------------------------------------------------------
/// clean up
- (void)dealloc
// ------------------------------------------------------
{
    _textView = nil;
}


// ------------------------------------------------------
/// draw line numbers.
- (void)drawRect:(NSRect)dirtyRect
// ------------------------------------------------------
{
    NSColor *counterColor = [[[self textView] theme] isDarkTheme] ? [NSColor whiteColor] : [NSColor blackColor];
    NSColor *textColor = [[[self textView] theme] weakTextColor];
    
    // fill in the background
    [[counterColor colorWithAlphaComponent:0.08] set];
    [NSBezierPath fillRect:dirtyRect];
    
    // draw frame border (1px)
    [[textColor colorWithAlphaComponent:0.3] set];
    [NSBezierPath strokeLineFromPoint:NSMakePoint(NSMaxX(dirtyRect) - 0.5, NSMaxY(dirtyRect))
                              toPoint:NSMakePoint(NSMaxX(dirtyRect) - 0.5, NSMinY(dirtyRect))];
    
    // get document data
    NSString *string = [[self textView] string];
    NSLayoutManager *layoutManager = [[self textView] layoutManager];
    
    if ([string length] == 0) { return; }
    
    // set graphics context
    CGContextRef context = (CGContextRef)[[NSGraphicsContext currentContext] graphicsPort];
    CGContextSaveGState(context);
    
    // setup font
    CGFloat masterFontSize = [[[self textView] font] pointSize];
    CGFloat fontSize = round(0.9 * masterFontSize);
    CTFontRef font = CTFontCreateWithName((CFStringRef)LineNumberFontName, fontSize, nil);
    
    CGFontRef cgFont = CTFontCopyGraphicsFont(font, NULL);
    CGContextSetFont(context, cgFont);
    CGContextSetFontSize(context, fontSize);
    CGContextSetFillColorWithColor(context, [textColor CGColor]);
    CFRelease(cgFont);
    
    // prepare glyphs
    CGGlyph wrappedMarkGlyph;
    unichar dash = '-';
    CTFontGetGlyphsForCharacters(font, &dash, &wrappedMarkGlyph, 1);
    
    CGGlyph digitGlyphs[10];
    unichar numbers[10] = {'0', '1', '2', '3', '4', '5', '6', '7', '8', '9'};
    CTFontGetGlyphsForCharacters(font, numbers, digitGlyphs, 10);
    
    // calc character width as monospaced font
    CGSize advance;
    CTFontGetAdvancesForGlyphs(font, kCTFontHorizontalOrientation, &digitGlyphs[8], &advance, 1);  // use '8' to get width
    CGFloat charWidth = advance.width;
    
    // prepare frame width
    CGFloat width = NSWidth([self frame]);
    
    // adjust drawing coordinate
    NSPoint relativePoint = [self convertPoint:NSZeroPoint fromView:[self textView]];
    NSPoint inset = [[self textView] textContainerOrigin];
    CGFloat diff = masterFontSize - fontSize;
    CGFloat ascent = CTFontGetAscent(font);
    CGAffineTransform transform = CGAffineTransformIdentity;
    transform = CGAffineTransformScale(transform, 1.0, -1.0);  // flip
    transform = CGAffineTransformTranslate(transform, -kLineNumPadding, -relativePoint.y - inset.y - diff - ascent);
    CGContextSetTextMatrix(context, transform);
    CFRelease(font);
    
    // get glyph range which line number should be drawn
    NSRange visibleGlyphRange = [layoutManager glyphRangeForBoundingRect:[[self textView] visibleRect]
                                                         inTextContainer:[[self textView] textContainer]];
    
    // counters
    NSUInteger glyphCount = visibleGlyphRange.location;
    NSUInteger lineNum = 1;
    NSUInteger lastLineNum = 0;
    
    // count lines until visible
    NSRegularExpression *regex = [NSRegularExpression regularExpressionWithPattern:@"\n" options:0 error:nil];
    lineNum += [regex numberOfMatchesInString:string options:0
                                        range:NSMakeRange(0, [layoutManager characterIndexForGlyphAtIndex:visibleGlyphRange.location])];
    
    // draw visible line numbers
    for (NSUInteger glyphIndex = visibleGlyphRange.location; glyphIndex < NSMaxRange(visibleGlyphRange); lineNum++) { // count "real" lines
        NSUInteger charIndex = [layoutManager characterIndexForGlyphAtIndex:glyphIndex];
        glyphIndex = NSMaxRange([layoutManager glyphRangeForCharacterRange:[string lineRangeForRange:NSMakeRange(charIndex, 0)]
                                                      actualCharacterRange:NULL]);
        
        while (glyphCount < glyphIndex) { // handle wrapped lines
            NSRange range;
            NSRect lineRect = [layoutManager lineFragmentRectForGlyphAtIndex:glyphCount effectiveRange:&range withoutAdditionalLayout:YES];
            CGFloat y = -NSMinY(lineRect);
            
            if (lastLineNum == lineNum) {  // wrapped line
                CGPoint position = CGPointMake(width - charWidth, y);
                CGContextShowGlyphsAtPositions(context, &wrappedMarkGlyph, &position, 1);  // draw wrapped mark
                
            } else {  // new line
                NSUInteger digit = numberOfDigits(lineNum);
                
                // get glyphs and positions
                CGGlyph glyphs[digit];
                CGPoint positions[digit];
                for (NSUInteger i = 0; i < digit; i++) {
                    glyphs[i] = digitGlyphs[numberAt(i, lineNum)];
                    positions[i] = CGPointMake(width - (i + 1) * charWidth, y);
                }
                
                CGContextShowGlyphsAtPositions(context, glyphs, positions, digit);  // draw line number
            }
            
            lastLineNum = lineNum;
            glyphCount = NSMaxRange(range);
        }
    }
    
    // draw the last "extra" line number
    if ([layoutManager extraLineFragmentTextContainer]) {
        NSRect lineRect = [layoutManager extraLineFragmentUsedRect];
        CGFloat y = -NSMinY(lineRect);
        
        NSUInteger digit = numberOfDigits(lineNum);
        
        // get glyphs and positions
        CGGlyph glyphs[digit];
        CGPoint positions[digit];
        for (NSUInteger i = 0; i < digit; i++) {
            glyphs[i] = digitGlyphs[numberAt(i, lineNum)];
            positions[i] = CGPointMake(width - (i + 1) * charWidth, y);
        }
        
        CGContextShowGlyphsAtPositions(context, glyphs, positions, digit);  // draw line number
    }
    
    // adjust thickness
    CGFloat requiredWidth = MAX(numberOfDigits(lineNum) * charWidth + 3 * kLineNumPadding, kDefaultLineNumWidth);
    [self setThickness:ceil(requiredWidth)];
    
    CGContextRestoreGState(context);
}


// ------------------------------------------------------
/// flip vertical coordinate
- (BOOL)isFlipped
// ------------------------------------------------------
{
    return YES;
}


// ------------------------------------------------------
/// return self size
- (NSSize)intrinsicContentSize
// ------------------------------------------------------
{
    return NSMakeSize([self thickness], NSViewNoInstrinsicMetric);
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

// ------------------------------------------------------
/// set line numbers visibility
- (void)setShown:(BOOL)shown
// ------------------------------------------------------
{
    if (shown == [self isShown]) { return; }
    
    _shown = shown;
    
    CGFloat width = shown ? kDefaultLineNumWidth : 0.0;
    [self setThickness:width];
}


// ------------------------------------------------------
/// redraw line numbers
- (void)updateLineNumber
// ------------------------------------------------------
{
    [self setNeedsDisplay:YES];
}



#pragma mark Private Methods

// ------------------------------------------------------
/// set view thickness
- (void)setThickness:(CGFloat)thickness
// ------------------------------------------------------
{
    _thickness = thickness;
    
    [self invalidateIntrinsicContentSize];
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
        [textView scrollLineUp:nil];
    } else if (y > NSHeight([self bounds])) {
        [textView scrollLineDown:nil];
    }
    
    // select lines
    NSUInteger currentIndex = [textView characterIndexForPoint:point];
    NSUInteger clickedIndex = timer ? [[timer userInfo] unsignedIntegerValue] : currentIndex;
    NSRange range = [[textView string] lineRangeForRange:NSMakeRange(MIN(currentIndex, clickedIndex),
                                                                     abs(currentIndex - clickedIndex))];
    [textView setSelectedRange:range];
}



#pragma mark Private C Functions

/// digits of input number
unsigned int numberOfDigits(int number) { return (unsigned int)log10(number) + 1; }

/// number at the desired place of input number
unsigned int numberAt(int place, int number) { return (number % (int)pow(10, place + 1)) / pow(10, place); }

@end
