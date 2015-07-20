/*
 ==============================================================================
 CEBorderView
 
 CotEditor
 http://coteditor.com
 
 Created on 2015-01-09 by 1024jp
 encoding="UTF-8"
 ------------------------------------------------------------------------------
 
 © 2015 1024jp
 
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

#import "CEBorderView.h"


@implementation CEBorderView

#pragma mark Superclass Methods

// ------------------------------------------------------
/// setup layer
- (void)awakeFromNib
// ------------------------------------------------------
{
    // set layer
    CALayer *layer = [CALayer layer];
    [layer setDelegate:self];
    [self setLayer:layer];
    [self setWantsLayer:YES];
    
    // set layer drawing policies
    [self setLayerContentsRedrawPolicy:NSViewLayerContentsRedrawBeforeViewResize];
    [self setLayerContentsPlacement:NSViewLayerContentsPlacementScaleAxesIndependently];
}


// ------------------------------------------------------
/// whether it's opaque view
- (BOOL)isOpaque
// ------------------------------------------------------
{
    return YES;
}



#pragma mark CALayer Methods

// ------------------------------------------------------
/// draw
- (void)drawLayer:(nonnull CALayer *)layer inContext:(nonnull CGContextRef)ctx
// ------------------------------------------------------
{
    CGRect bounds = [self bounds];
    
    // fill background
    CGContextSetFillColorWithColor(ctx, [[self fillColor] CGColor]);
    CGContextFillRect(ctx, bounds);
    
    // draw borders
    CGRect frame = [self frame];
    const CGFloat strokeWidth = 1.0;
    CGContextSetStrokeColorWithColor(ctx, [[self borderColor] CGColor]);
    if ([self drawsTopBorder]) {
        CGContextMoveToPoint(ctx, NSMinX(frame), NSMaxY(frame) - strokeWidth / 2);
        CGContextAddLineToPoint(ctx, NSMaxX(frame), NSMaxY(frame) - strokeWidth / 2);
    }
    if ([self drawsBottomBorder]) {
        CGContextMoveToPoint(ctx ,NSMinX(frame), strokeWidth / 2);
        CGContextAddLineToPoint(ctx, NSMaxX(frame), strokeWidth / 2);
    }
    CGContextStrokePath(ctx);
}

@end
