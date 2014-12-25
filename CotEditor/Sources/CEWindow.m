/*
 ==============================================================================
 CEWindow
 
 CotEditor
 http://coteditor.com
 
 Created on 2004-10-31 by 1024jp
 encoding="UTF-8"
 ------------------------------------------------------------------------------
 
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

#import "CEWindow.h"


// notifications
NSString *const CEWindowOpacityDidChangeNotification = @"CEWindowOpacityDidChangeNotification";


@interface CEWindow ()

@property (nonatomic) NSColor *storedBackgroundColor;

@end




#pragma mark -

@implementation CEWindow

#pragma mark Superclass Methods

// ------------------------------------------------------
/// initialize
- (instancetype)initWithContentRect:(NSRect)contentRect styleMask:(NSUInteger)aStyle backing:(NSBackingStoreType)bufferingType defer:(BOOL)flag
// ------------------------------------------------------
{
    self = [super initWithContentRect:contentRect styleMask:aStyle backing:bufferingType defer:flag];
    if (self) {
        _backgroundAlpha = 1.0;
        
        // observe toggling fullscreen
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(willEnterFullscreen:)
                                                     name:NSWindowWillEnterFullScreenNotification
                                                   object:self];
        
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(willExitFullscreen:)
                                                     name:NSWindowWillExitFullScreenNotification
                                                   object:self];
    }
    return self;
}


// ------------------------------------------------------
/// clean-up
- (void)dealloc
// ------------------------------------------------------
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}


// ------------------------------------------------------
/// set background color
- (void)setBackgroundColor:(NSColor *)backgroundColor
// ------------------------------------------------------
{
    // apply alpha value to input background color
    [super setBackgroundColor:[backgroundColor colorWithAlphaComponent:[self backgroundAlpha]]];
}



#pragma mark Accessors

// ------------------------------------------------------
/// set opaque
- (void)setOpaque:(BOOL)opaque
// ------------------------------------------------------
{
    [super setOpaque:opaque];
    
    [[NSNotificationCenter defaultCenter] postNotificationName:CEWindowOpacityDidChangeNotification
                                                        object:self];
}


// ------------------------------------------------------
/// set background alpha
- (void)setBackgroundAlpha:(CGFloat)backgroundAlpha
// ------------------------------------------------------
{
    CGFloat sanitizedAlpha = backgroundAlpha;
    
    sanitizedAlpha = MAX(sanitizedAlpha, 0.2);
    sanitizedAlpha = MIN(sanitizedAlpha, 1.0);
    
    _backgroundAlpha = sanitizedAlpha;
    
    [self setBackgroundColor:[self backgroundColor]];
    [self setOpaque:(sanitizedAlpha == 1.0)];
    [self invalidateShadow];
}



#pragma mark Notifications

// ------------------------------------------------------
/// notify entering fullscreen
- (void)willEnterFullscreen:(NSNotification *)notification
// ------------------------------------------------------
{
    [self setStoredBackgroundColor:[self backgroundColor]];
    [self setBackgroundColor:nil];  // restore window background to default (affect to the toolbar's background)
    [self setOpaque:YES];  // set opaque flag　expressly in order to let textView which observes opaque update its background color
}


// ------------------------------------------------------
/// notify exit fullscreen
- (void)willExitFullscreen:(NSNotification *)notification
// ------------------------------------------------------
{
    [self setBackgroundColor:[self storedBackgroundColor]];
    [self setBackgroundAlpha:[self backgroundAlpha]];
}

@end
