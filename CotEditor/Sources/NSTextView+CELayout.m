/*
 
 NSTextView+CELayout.m
 
 CotEditor
 http://coteditor.com
 
 Created by 1024jp on 2016-05-31.
 
 ------------------------------------------------------------------------------
 
 © 2016 1024jp
 
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

#import "NSTextView+CELayout.h"

#import "CEGeometry.h"


@implementation NSTextView (CERange)

// ------------------------------------------------------
/// calculate visible range
- (NSRange)visibleRange
// ------------------------------------------------------
{
    NSPoint containerOrigin = [self textContainerOrigin];
    NSRect visibleRect = NSOffsetRect([[self enclosingScrollView] documentVisibleRect],
                                      -containerOrigin.x,  -containerOrigin.y);
    NSRange glyphRange = [[self layoutManager] glyphRangeForBoundingRectWithoutAdditionalLayout:visibleRect
                                                                                inTextContainer:[self textContainer]];
    
    return [[self layoutManager] characterRangeForGlyphRange:glyphRange actualGlyphRange:NULL];
}

@end




#pragma mark -

@implementation NSTextView (CETextWrapping)

// ------------------------------------------------------
/// if soft wrap lines
- (BOOL)wrapsLines
// ------------------------------------------------------
{
    return [[self textContainer] containerSize].width != CGFLOAT_MAX;
}


// ------------------------------------------------------
/// set if soft wrap lines
- (void)setWrapsLines:(BOOL)wrapsLines
// ------------------------------------------------------
{
    NSRange visibleRange = [self visibleRange];
    BOOL isVertical = ([self layoutOrientation] == NSTextLayoutOrientationVertical);
    
    // 条件を揃えるためにいったん横書きに戻す (各項目の縦横の入れ替えは setLayoutOrientation: が良きに計らってくれる)
    if (isVertical) {
        [self setLayoutOrientation:NSTextLayoutOrientationHorizontal];
    }
    
    [[self enclosingScrollView] setHasHorizontalScroller:!wrapsLines];
    [[self textContainer] setWidthTracksTextView:wrapsLines];
    if (wrapsLines) {
        NSSize contentSize = [[self enclosingScrollView] contentSize];
        [[self textContainer] setContainerSize:NSMakeSize(round(contentSize.width / [self scale]), CGFLOAT_MAX)];
        [self setConstrainedFrameSize:contentSize];
    } else {
        [[self textContainer] setContainerSize:NSMakeSize(CGFLOAT_MAX, CGFLOAT_MAX)];
    }
    [self setAutoresizingMask:(wrapsLines ? NSViewWidthSizable : NSViewNotSizable)];
    [self setHorizontallyResizable:!wrapsLines];
    
    // 縦書きモードの際は改めて縦書きにする
    if (isVertical) {
        [self setLayoutOrientation:NSTextLayoutOrientationVertical];
    }
    
    [self scrollRangeToVisible:visibleRange];
}

@end




#pragma mark -

@implementation NSTextView (CEScaling)

// cf. https://developer.apple.com/library/mac/qa/qa1346/_index.html

// ------------------------------------------------------
/// get current zooming scale
- (CGFloat)scale
// ------------------------------------------------------
{
    return [self convertSize:NSMakeSize(1.0, 1.0) toView:nil].width;
}


// ------------------------------------------------------
/// zoom to the passed-in scale
- (void)setScale:(CGFloat)scale
// ------------------------------------------------------
{
    // sanitize scale
    scale = MAX([[self enclosingScrollView] minMagnification], MIN(scale, [[self enclosingScrollView] maxMagnification]));
    
    // scale
    [self scaleUnitSquareToSize:[self convertSize:NSMakeSize(1.0, 1.0) fromView:nil]];  // reset
    [self scaleUnitSquareToSize:NSMakeSize(scale, scale)];
    
    // ensure bounds origin is {0, 0} for vertical text orientation
    [self setNeedsDisplay:YES];
    [self translateOriginToPoint:[self bounds].origin];
    
    // reset minimum size for unwrap mode
    [self setMinSize:CEScaleSize([[self enclosingScrollView] contentSize], 1.0 / scale)];
    
    // ensure text layout
    [[self layoutManager] ensureLayoutForCharacterRange:NSMakeRange(0, [[self string] length])];
    [[self layoutManager] ensureLayoutForTextContainer:[self textContainer]];
    [self sizeToFit];
    
    // dummy reselection to force redrawing current line highlight
    [self setSelectedRanges:[self selectedRanges]];
}


// ------------------------------------------------------
/// zoom to the scale keeping passed-in point position in scroll view
- (void)setScale:(CGFloat)scale centeredAtPoint:(NSPoint)point
// ------------------------------------------------------
{
    if (scale == [self scale]) { return; }
    
    // store current coordinate
    NSUInteger centerGlyphIndex = [[self layoutManager] glyphIndexForPoint:point inTextContainer:[self textContainer]];
    CGFloat currentScale = [self scale];
    BOOL isVertical = [self layoutOrientation] == NSTextLayoutOrientationVertical;
    NSRect visibleRect = [[self enclosingScrollView] documentVisibleRect];
    NSPoint visibleOrigin = NSMakePoint(NSMinX(visibleRect),
                                        isVertical ? NSMaxY(visibleRect) : NSMinY(visibleRect));
    NSPoint centerFromClipOrigin = CEScalePoint(NSMakePoint(point.x - visibleOrigin.x,
                                                            point.y - visibleOrigin.y), currentScale);  // from top-left
    
    [self setScale:scale];
    
    // adjust scroller to keep position of the glyph at the passed-in center point
    if ([self scale] != currentScale) {
        centerFromClipOrigin = CEScalePoint(centerFromClipOrigin, 1.0 / scale);
        NSRect newCenter = [[self layoutManager] boundingRectForGlyphRange:NSMakeRange(centerGlyphIndex, 1)
                                                           inTextContainer:[self textContainer]];
        NSPoint scrollPoint = NSMakePoint(round(point.x - centerFromClipOrigin.x),
                                          round(NSMidY(newCenter) - centerFromClipOrigin.y));
        [self scrollPoint:scrollPoint];
    }
}


// ------------------------------------------------------
/// zoom to the scale keeping current visible rect position in scroll view
- (void)setScaleKeepingVisibleArea:(CGFloat)scale
// ------------------------------------------------------
{
    [self setScale:scale centeredAtPoint:CEMidInRect([self visibleRect])];
}

@end
