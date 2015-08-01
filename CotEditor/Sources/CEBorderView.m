/*
 
 CEBorderView.m
 
 CotEditor
 http://coteditor.com
 
 Created by 1024jp on 2015-01-09.
 
 ------------------------------------------------------------------------------
 
 © 2015 1024jp
 
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

#import "CEBorderView.h"


@implementation CEBorderView

#pragma mark Superclass Methods

// ------------------------------------------------------
/// setup layer
- (void)awakeFromNib
// ------------------------------------------------------
{
    // setup layer
    CALayer *layer = [CALayer layer];
    [layer setDelegate:self];
    [layer setBackgroundColor:[[self fillColor] CGColor]];
    [layer setNeedsDisplay];
    [self setLayer:layer];
    [self setWantsLayer:YES];
    
    // set layer drawing policies
    [self setLayerContentsRedrawPolicy:NSViewLayerContentsRedrawNever];
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
/// draw borders
- (void)drawLayer:(nonnull CALayer *)layer inContext:(nonnull CGContextRef)ctx
// ------------------------------------------------------
{
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
