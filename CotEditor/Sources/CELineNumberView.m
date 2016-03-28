/*
 
 CELineNumberView.m
 
 CotEditor
 http://coteditor.com
 
 Created by nakamuxu on 2005-03-30.
 
 ------------------------------------------------------------------------------
 
 © 2004-2007 nakamuxu
 © 2014-2016 1024jp
 
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

@import CoreText;
#import "CELineNumberView.h"
#import "CETextViewProtocol.h"
#import "CEDefaults.h"

#import "NSString+CECounting.h"


static const NSUInteger kMinNumberOfDigits = 3;
static const CGFloat kMinVerticalThickness = 32.0;
static const CGFloat kMinHorizontalThickness = 20.0;
static const CGFloat kLineNumberPadding = 4.0;
static const CGFloat kFontSizeFactor = 0.9;

// dragging info keys
static NSString * _Nonnull const DraggingSelectedRangesKey = @"selectedRanges";
static NSString * _Nonnull const DraggingIndexKey = @"index";


@interface CELineNumberView ()

@property (nonatomic) NSUInteger totalNumberOfLines;
@property (nonatomic) BOOL needsRecountTotalNumberOfLines;
@property (nonatomic, nullable, weak) NSTimer *draggingTimer;

@end




#pragma mark -

@implementation CELineNumberView

static CGFontRef LineNumberFont;
static CGFontRef BoldLineNumberFont;


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
        NSFont *boldFont = [[NSFontManager sharedFontManager] convertFont:font toHaveTrait:NSBoldFontMask];
        
        LineNumberFont = CGFontCreateWithFontName((CFStringRef)[font fontName]);
        BoldLineNumberFont = CGFontCreateWithFontName((CFStringRef)[boldFont fontName]);
    });
}


// ------------------------------------------------------
/// initialize instance
- (nonnull instancetype)initWithScrollView:(nullable NSScrollView *)scrollView orientation:(NSRulerOrientation)orientation
// ------------------------------------------------------
{
    self = [super initWithScrollView:scrollView orientation:orientation];
    if (self) {
        [self setClientView:[scrollView documentView]];
    }
    return self;
}


// ------------------------------------------------------
/// cleanup
- (void)dealloc
// ------------------------------------------------------
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}


// ------------------------------------------------------
/// setup initial size
- (void)viewDidMoveToSuperview
// ------------------------------------------------------
{
    [super viewDidMoveToSuperview];
    
    CGFloat thickness = [self orientation] == NSHorizontalRuler ? kMinHorizontalThickness : kMinVerticalThickness;
    [self setRuleThickness:thickness];
}


// ------------------------------------------------------
/// draw background
- (void)drawRect:(NSRect)dirtyRect
// ------------------------------------------------------
{
    NSColor *counterColor = [[self theme] isDarkTheme] ? [NSColor whiteColor] : [NSColor blackColor];
    NSColor *textColor = [[self theme] weakTextColor];
    
    // fill background
    [[counterColor colorWithAlphaComponent:0.08] set];
    [NSBezierPath fillRect:dirtyRect];
    
    // draw frame border (1px)
    [[textColor colorWithAlphaComponent:0.3] set];
    switch ([self orientation]) {
        case NSVerticalRuler:
            [NSBezierPath strokeLineFromPoint:NSMakePoint(NSMaxX(dirtyRect) - 0.5, NSMaxY(dirtyRect))
                                      toPoint:NSMakePoint(NSMaxX(dirtyRect) - 0.5, NSMinY(dirtyRect))];
            break;
            
        case NSHorizontalRuler:
            [NSBezierPath strokeLineFromPoint:NSMakePoint(NSMinX(dirtyRect), NSMaxY(dirtyRect) - 0.5)
                                      toPoint:NSMakePoint(NSMaxX(dirtyRect), NSMaxY(dirtyRect) - 0.5)];
            break;
    }
    
    [self drawHashMarksAndLabelsInRect:dirtyRect];
}


// ------------------------------------------------------
/// draw line numbers
- (void)drawHashMarksAndLabelsInRect:(NSRect)rect
// ------------------------------------------------------
{
    NSString *string = [[self textView] string];
    NSUInteger length = [string length];
    
    if (length == 0) { return; }
    
    NSTextView *textView = [self textView];
    NSLayoutManager *layoutManager = [textView layoutManager];
    NSColor *textColor = [[self theme] weakTextColor];
    CGFloat scale = [textView convertSize:NSMakeSize(1.0, 1.0) toView:nil].width;
    
    // set graphics context
    CGContextRef context = (CGContextRef)[[NSGraphicsContext currentContext] graphicsPort];
    CGContextSaveGState(context);

    // setup font
    CGFloat masterFontSize = scale * [[[self textView] font] pointSize];
    CGFloat fontSize = MIN(round(kFontSizeFactor * masterFontSize), masterFontSize);
    CTFontRef font = CTFontCreateWithGraphicsFont(LineNumberFont, fontSize, nil, nil);
    
    CGContextSetFont(context, LineNumberFont);
    CGContextSetFontSize(context, fontSize);
    CGContextSetFillColorWithColor(context, [textColor CGColor]);
    
    // prepare glyphs
    CGGlyph wrappedMarkGlyph;
    const unichar dash = '-';
    CTFontGetGlyphsForCharacters(font, &dash, &wrappedMarkGlyph, 1);
    
    CGGlyph digitGlyphs[10];
    const unichar numbers[10] = {'0', '1', '2', '3', '4', '5', '6', '7', '8', '9'};
    CTFontGetGlyphsForCharacters(font, numbers, digitGlyphs, 10);
    
    // calc character width as monospaced font
    CGSize advance;
    CTFontGetAdvancesForGlyphs(font, kCTFontOrientationHorizontal, &digitGlyphs[8], &advance, 1);  // use '8' to get width
    CGFloat charWidth = advance.width;
    CFRelease(font);
    
    // prepare frame width
    CGFloat ruleThickness = [self ruleThickness];
    
    BOOL isVerticalText = [self orientation] == NSHorizontalRuler;
    CGFloat tickLength = ceil(fontSize / 3);
    
    // adjust text drawing coordinate
    NSPoint relativePoint = [self convertPoint:NSZeroPoint fromView:textView];
    NSPoint inset = [textView textContainerOrigin];
    CGFloat ascent = scale * [[textView font] ascender];
    CGAffineTransform transform = CGAffineTransformMakeScale(1.0, -1.0);  // flip
    if (isVerticalText) {
        transform = CGAffineTransformTranslate(transform, round(relativePoint.x - inset.y - ascent / 2), -ruleThickness);
    } else {
        transform = CGAffineTransformTranslate(transform, -kLineNumberPadding, -relativePoint.y - inset.y - ascent);
    }
    CGContextSetTextMatrix(context, transform);
    
    // add enough buffer to avoid broken drawing on Mountain Lion (10.8) with scroller (2015-07)
    NSRect visibleRect = [[self scrollView] documentVisibleRect];
    visibleRect.size.height += fontSize;
    
    // get multiple selections
    NSMutableArray<NSValue *> *selectedLineRanges = [NSMutableArray arrayWithCapacity:[[textView selectedRanges] count]];
    for (NSValue *rangeValue in [textView selectedRanges]) {
        NSRange selectedLineRange = [string lineRangeForRange:[rangeValue rangeValue]];
        [selectedLineRanges addObject:[NSValue valueWithRange:selectedLineRange]];
    }
    
    // draw line number block
    CGGlyph *digitGlyphsPtr = digitGlyphs;
    void (^draw_number)(NSUInteger, CGFloat, BOOL) = ^(NSUInteger lineNumber, CGFloat y, BOOL isBold)
    {
        NSUInteger digit = numberOfDigits(lineNumber);
        
        // calculate base position
        CGPoint position;
        if (isVerticalText) {
            position = CGPointMake(ceil(y + charWidth * digit / 2), 2 * tickLength);
        } else {
            position = CGPointMake(ruleThickness, y);
        }
        
        // get glyphs and positions
        CGGlyph glyphs[digit];
        CGPoint positions[digit];
        for (NSUInteger i = 0; i < digit; i++) {
            position.x -= charWidth;
            
            positions[i] = position;
            glyphs[i] = digitGlyphsPtr[numberAt(i, lineNumber)];
        }
        
        if (isBold) {
            CGContextSetFont(context, BoldLineNumberFont);
        }
        
        // draw
        CGContextShowGlyphsAtPositions(context, glyphs, positions, digit);
        
        if (isBold) {
            // back to the regular font
            CGContextSetFont(context, LineNumberFont);
        }
    };
    
    // draw ticks block for vertical text
    void (^draw_tick)(CGFloat) = ^(CGFloat y)
    {
        CGFloat x = round(y) + 0.5;
        
        CGMutablePathRef tick = CGPathCreateMutable();
        CGPathMoveToPoint(tick, &transform, x, 0);
        CGPathAddLineToPoint(tick, &transform, x, tickLength);
        CGContextAddPath(context, tick);
        CFRelease(tick);
    };
    
    // get glyph range of which line number should be drawn
    NSRange glyphRangeToDraw = [layoutManager glyphRangeForBoundingRectWithoutAdditionalLayout:visibleRect
                                                                               inTextContainer:[textView textContainer]];
    
    // counters
    NSUInteger glyphCount = glyphRangeToDraw.location;
    NSUInteger lineNumber = 1;
    NSUInteger lastLineNumber = 0;
    
    // count lines until visible
    lineNumber = [string numberOfLinesInRange:NSMakeRange(0, [layoutManager characterIndexForGlyphAtIndex:glyphRangeToDraw.location])
                         includingLastNewLine:YES] ?: 1;  // start with 1
    
    // draw visible line numbers
    for (NSUInteger glyphIndex = glyphRangeToDraw.location; glyphIndex < NSMaxRange(glyphRangeToDraw); lineNumber++) { // count "real" lines
        NSUInteger charIndex = [layoutManager characterIndexForGlyphAtIndex:glyphIndex];
        NSRange lineRange = [string lineRangeForRange:NSMakeRange(charIndex, 0)];
        glyphIndex = NSMaxRange([layoutManager glyphRangeForCharacterRange:lineRange actualCharacterRange:NULL]);
        
        // check if line is selected
        BOOL isSelected = NO;
        for (NSValue *selectedLineValue in selectedLineRanges) {
            NSRange selectedRange = [selectedLineValue rangeValue];
            
            if (NSLocationInRange(lineRange.location, selectedRange) &&
                (isVerticalText && ((lineRange.location == selectedRange.location) ||
                                    (NSMaxRange(lineRange) == NSMaxRange(selectedRange)))))
            {
                isSelected = YES;
                break;
            }
        }
        
        while (glyphCount < glyphIndex) { // handle wrapped lines
            NSRange range;
            NSRect lineRect = [layoutManager lineFragmentRectForGlyphAtIndex:glyphCount effectiveRange:&range withoutAdditionalLayout:YES];
            BOOL isWrappedLine = (lastLineNumber == lineNumber);
            lastLineNumber = lineNumber;
            glyphCount = NSMaxRange(range);
            
            if (isVerticalText && isWrappedLine) { continue; }
            
            CGFloat y = scale * -NSMinY(lineRect);
            
            if (isWrappedLine) {
                CGPoint position = CGPointMake(ruleThickness - charWidth, y);
                CGContextShowGlyphsAtPositions(context, &wrappedMarkGlyph, &position, 1);  // draw wrapped mark
                
            } else {  // new line
                if (isVerticalText) {
                    draw_tick(y);
                }
                if (!isVerticalText || lineNumber % 5 == 0 || lineNumber == 1 || isSelected ||
                    (NSMaxRange(lineRange) == length && ![layoutManager extraLineFragmentTextContainer]))  // last line for vertical text
                {
                    draw_number(lineNumber, y, isSelected);
                }
            }
        }
    }
    
    // draw the last "extra" line number
    if ([layoutManager extraLineFragmentTextContainer]) {
        NSRect lineRect = [layoutManager extraLineFragmentUsedRect];
        NSRange lastSelectedRange = [[selectedLineRanges lastObject] rangeValue];
        BOOL isSelected = (lastSelectedRange.length == 0) && (length == NSMaxRange(lastSelectedRange));
        CGFloat y = scale * -NSMinY(lineRect);
        
        if (isVerticalText) {
            draw_tick(y);
        }
        draw_number(lineNumber, y, isSelected);
    }
    
    // draw vertical text tics
    if (isVerticalText) {
        CGContextSetStrokeColorWithColor(context, [[textColor colorWithAlphaComponent:0.6] CGColor]);
        CGContextStrokePath(context);
    }
    
    CGContextRestoreGState(context);
    
    // adjust thickness
    CGFloat requiredThickness;
    if (isVerticalText) {
        requiredThickness = MAX(fontSize + 2.5 * tickLength, kMinHorizontalThickness);
        
    } else {
        if ([self needsRecountTotalNumberOfLines]) {
            // -> count only if really needed since the line counting is high workload, especially by large document
            [self setTotalNumberOfLines:[string numberOfLinesInRange:NSMakeRange(0, length) includingLastNewLine:YES]];
            [self setNeedsRecountTotalNumberOfLines:NO];
        }
        
        // use the line number of whole string, namely the possible largest line number
        // -> The view width depends on the number of digits of the total line numbers.
        //    It's quite dengerous to change width of line number view on scrolling dynamically.
        NSUInteger digits = MAX(numberOfDigits([self totalNumberOfLines]), kMinNumberOfDigits);
        requiredThickness = MAX(digits * charWidth + 3 * kLineNumberPadding, kMinVerticalThickness);
    }
    [self setRuleThickness:ceil(requiredThickness)];
}


// ------------------------------------------------------
/// make background transparent
- (BOOL)isOpaque
// ------------------------------------------------------
{
    return NO;
}


// ------------------------------------------------------
/// remove extra thickness
- (CGFloat)requiredThickness
// ------------------------------------------------------
{
    if ([self orientation] == NSHorizontalRuler) {
        return [self ruleThickness];
    }
    return MAX(kMinVerticalThickness, [self ruleThickness]);
}


// ------------------------------------------------------
/// setter of client view
- (void)setClientView:(NSView *)clientView
// ------------------------------------------------------
{
    // stop observing current textStorage
    if ([[self clientView] isKindOfClass:[NSTextView class]]) {
        [[NSNotificationCenter defaultCenter] removeObserver:self
                                                        name:NSTextDidChangeNotification
                                                      object:(NSTextView *)[self clientView]];
    }
    
    // observe new textStorage change
    if ([clientView isKindOfClass:[NSTextView class]]) {
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(textDidChange:)
                                                     name:NSTextDidChangeNotification
                                                   object:(NSTextView *)clientView];
        [self setNeedsRecountTotalNumberOfLines:YES];
    }
    
    [super setClientView:clientView];
}



#pragma mark Private Methods

// ------------------------------------------------------
/// return client view casting to textView
- (nullable NSTextView *)textView
// ------------------------------------------------------
{
    return (NSTextView *)[self clientView];
}


// ------------------------------------------------------
/// return coloring theme
- (nullable CETheme *)theme
// ------------------------------------------------------
{
    return [(NSTextView<CETextViewProtocol> *)[self clientView] theme];
}


// ------------------------------------------------------
/// update total number of lines determining view thickness on holizontal text layout
- (void)textDidChange:(nonnull NSNotification *)notification
// ------------------------------------------------------
{
    [self setNeedsRecountTotalNumberOfLines:YES];
}



#pragma mark Private C Functions

/// digits of input number
unsigned int numberOfDigits(int number) { return (unsigned int)log10(number) + 1; }

/// number at the desired place of input number
unsigned int numberAt(int place, int number) { return (number % (int)pow(10, place + 1)) / pow(10, place); }

@end




#pragma mark -

@implementation CELineNumberView (LineSelecting)

#pragma mark Superclass Methods

// ------------------------------------------------------
/// start selecting correspondent lines in text view with drag / click event
- (void)mouseDown:(nonnull NSEvent *)theEvent
// ------------------------------------------------------
{
    // get start point
    NSPoint point = [[self window] convertRectToScreen:NSMakeRect([theEvent locationInWindow].x,
                                                                  [theEvent locationInWindow].y, 0, 0)].origin;
    NSUInteger index = [[self textView] characterIndexForPoint:point];
    
    // repeat while dragging
    [self setDraggingTimer:[NSTimer scheduledTimerWithTimeInterval:0.05
                                                            target:self
                                                          selector:@selector(selectLines:)
                                                          userInfo:@{DraggingIndexKey: @(index),
                                                                     DraggingSelectedRangesKey: [[self textView] selectedRanges]}
                                                           repeats:YES]];
    
    [self selectLines:nil];  // for single click event
}


// ------------------------------------------------------
/// end selecting correspondent lines in text view with drag event
- (void)mouseUp:(nonnull NSEvent *)theEvent
// ------------------------------------------------------
{
    [[self draggingTimer] invalidate];
    [self setDraggingTimer:nil];
    
    // settle selection
    //   -> in `selectLines:`, `stillSelecting` flag is always YES
    [[self textView] setSelectedRanges:[[self textView] selectedRanges]];
}



#pragma mark Private Methods

// ------------------------------------------------------
/// select lines while dragging event
- (void)selectLines:(nullable NSTimer *)timer
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
    NSUInteger clickedIndex = timer ? [[timer userInfo][DraggingIndexKey] unsignedIntegerValue] : currentIndex;
    NSRange currentLineRange = [[textView string] lineRangeForRange:NSMakeRange(currentIndex, 0)];
    NSRange clickedLineRange = [[textView string] lineRangeForRange:NSMakeRange(clickedIndex, 0)];
    NSRange range = NSUnionRange(currentLineRange, clickedLineRange);
    
    NSSelectionAffinity affinity = (currentIndex < clickedIndex) ? NSSelectionAffinityUpstream : NSSelectionAffinityDownstream;
    
    // with Command key (add selection)
    if ([NSEvent modifierFlags] & NSCommandKeyMask) {
        NSArray<NSValue *> *originalSelectedRanges = [timer userInfo][DraggingSelectedRangesKey] ?: [textView selectedRanges];
        NSMutableArray<NSValue *> *selectedRanges = [NSMutableArray array];
        BOOL intersects = NO;
        
        for (NSValue *selectedRangeValue in originalSelectedRanges) {
            NSRange selectedRange = [selectedRangeValue rangeValue];

            if (selectedRange.location <= range.location && NSMaxRange(range) <= NSMaxRange(selectedRange)) {  // exclude
                NSRange range1 = NSMakeRange(selectedRange.location, range.location - selectedRange.location);
                NSRange range2 = NSMakeRange(NSMaxRange(range), NSMaxRange(selectedRange) - NSMaxRange(range));
                
                if (range1.length > 0) {
                    [selectedRanges addObject:[NSValue valueWithRange:range1]];
                }
                if (range2.length > 0) {
                    [selectedRanges addObject:[NSValue valueWithRange:range2]];
                }
                
                intersects = YES;
                continue;
            }
            
            // add
            [selectedRanges addObject:selectedRangeValue];
        }
        
        if (!intersects) {  // add current dragging selection
            [selectedRanges addObject:[NSValue valueWithRange:range]];
        }
        
        [textView setSelectedRanges:selectedRanges affinity:affinity stillSelecting:YES];
        
        // redraw line number
        [self setNeedsDisplay:YES];
        
        return;
    }
    
    // with Shift key (expand selection)
    if ([NSEvent modifierFlags] & NSShiftKeyMask) {
        NSRange selectedRange = [textView selectedRange];
        if (NSLocationInRange(currentIndex, selectedRange)) {  // reduce
            BOOL inUpperSection = (currentIndex - selectedRange.location) < selectedRange.length / 2;
            if (inUpperSection) {  // clicked upper half section of selected range
                range = NSMakeRange(currentIndex, NSMaxRange(selectedRange) - currentIndex);
                
            } else {
                range = selectedRange;
                range.length -= NSMaxRange(selectedRange) - NSMaxRange(currentLineRange);
            }
            
        } else {  // expand
            range = NSUnionRange(range, selectedRange);
        }
    }
    
    [textView setSelectedRange:range affinity:affinity stillSelecting:YES];
    
    // redraw line number
    [self setNeedsDisplay:YES];
}

@end
