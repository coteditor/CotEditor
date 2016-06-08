/*
 
 CEAlphaWindow.m
 
 CotEditor
 http://coteditor.com
 
 Created by 1024jp on 2004-10-31.

 ------------------------------------------------------------------------------
 
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

#import "CEAlphaWindow.h"


// notifications
NSString *_Nonnull const CEWindowOpacityDidChangeNotification = @"CEWindowOpacityDidChangeNotification";


@interface CEAlphaWindow ()

@property (nonatomic, nullable) NSColor *storedBackgroundColor;

@end




#pragma mark -

@implementation CEAlphaWindow

#pragma mark Superclass Methods

// ------------------------------------------------------
/// initialize
- (nonnull instancetype)initWithContentRect:(NSRect)contentRect styleMask:(NSUInteger)aStyle backing:(NSBackingStoreType)bufferingType defer:(BOOL)flag
// ------------------------------------------------------
{
    self = [super initWithContentRect:contentRect styleMask:aStyle backing:bufferingType defer:flag];
    if (self) {
        _backgroundAlpha = 1.0;
        
        // make sure window title bar (incl. toolbar) is opaque
        //   -> It's actucally a bit dirty way but practically works well.
        //      Without this tweak, the title bar will be dyed in the background color on El Capitan. (2016-01 by 1024p)
        NSView *windowTitleView = [[self standardWindowButton:NSWindowCloseButton] superview];
        [[windowTitleView layer] setBackgroundColor:[[NSColor windowBackgroundColor] CGColor]];
        
        // observe toggling fullscreen
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(willEnterOpaqueMode:)
                                                     name:NSWindowWillEnterFullScreenNotification
                                                   object:self];
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(willExitOpaqueMode:)
                                                     name:NSWindowWillExitFullScreenNotification
                                                   object:self];
        
        // observe toggling Versions browsing
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(willEnterOpaqueMode:)
                                                     name:NSWindowWillEnterVersionBrowserNotification
                                                   object:self];
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(willExitOpaqueMode:)
                                                     name:NSWindowWillExitVersionBrowserNotification
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
    CGFloat sanitizedAlpha = MAX(0.2, MIN(backgroundAlpha, 1.0));
    
    // window must be opaque on version browsing
    if ([[[self windowController] document] isInViewingMode]) {
        sanitizedAlpha = 1.0;
    }
    
    _backgroundAlpha = sanitizedAlpha;
    
    [self setBackgroundColor:[self backgroundColor]];
    [self setOpaque:(sanitizedAlpha == 1.0)];
    [self invalidateShadow];
}



#pragma mark Notifications

// ------------------------------------------------------
/// notify entering fullscreen or Versions
- (void)willEnterOpaqueMode:(nonnull NSNotification *)notification
// ------------------------------------------------------
{
    [self setStoredBackgroundColor:[self backgroundColor]];
    [self setBackgroundColor:nil];  // restore window background to default (affect to the toolbar's background)
    [self setOpaque:YES];  // set opaque flag expressly in order to let textView which observes opaque update its background color
}


// ------------------------------------------------------
/// notify exit fullscreen or Versions
- (void)willExitOpaqueMode:(nonnull NSNotification *)notification
// ------------------------------------------------------
{
    [self setBackgroundColor:[self storedBackgroundColor]];
    [self setBackgroundAlpha:[self backgroundAlpha]];
}

@end
