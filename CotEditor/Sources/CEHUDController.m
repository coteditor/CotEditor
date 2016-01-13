/*
 
 CEHUDController.h
 
 CotEditor
 http://coteditor.com
 
 Created by 1024jp on 2016-01-13.
 
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

#import "CEHUDController.h"


NSString * _Nonnull const CEWrapSymbolName = @"WrapSymbol";

static NSString * _Nonnull const HUDIdentifier = @"HUD";
static CGFloat const kCornerRadius = 14.0;
static NSTimeInterval const kDefaultDisplayingInterval = 0.1;
static NSTimeInterval const kFadeDuration = 0.5;


@interface CEHUDController ()

@property (nonatomic, nonnull) NSImage *symbolImage;
@property (nonatomic, nullable, weak) NSTimer *fadeoutTimer;

@property (nonatomic, nullable, weak) IBOutlet NSImageView *symbol;

@end




#pragma mark -

@implementation CEHUDController

#pragma mark Superclass Methods

// ------------------------------------------------------
/// initialize instance
- (nonnull instancetype)initWithSymbolName:(nonnull NSString *)symbolName
// ------------------------------------------------------
{
    self = [super init];
    if (self) {
        _symbolImage = [NSImage imageNamed:symbolName];
        
        NSAssert(_symbolImage, @"Failed loading symbol image for HUD view.");
    }
    return self;
}


// ------------------------------------------------------
/// clean up
- (void)dealloc
// ------------------------------------------------------
{
    [_fadeoutTimer invalidate];
}


// ------------------------------------------------------
/// nib name
- (nullable NSString *)nibName
// ------------------------------------------------------
{
    return @"HUDView";
}


// ------------------------------------------------------
/// setup UI
- (void)loadView
// ------------------------------------------------------
{
    [super loadView];
    
    [[self view] setAlphaValue:0.0];
    [[self view] setIdentifier:HUDIdentifier];
    [[[self view] layer] setCornerRadius:kCornerRadius];
    
    NSVisualEffectView *effectView = (NSVisualEffectView *)[self view];
    [effectView setMaterial:NSVisualEffectMaterialDark];
}



#pragma mark Public Methods

// ------------------------------------------------------
/// show HUD for view
- (void)showInView:(nonnull __kindof NSView *)clientView
// ------------------------------------------------------
{
    // remove previous HUD
    for (__kindof NSView *subview in [clientView subviews]) {
        if ([[subview identifier] isEqualToString:HUDIdentifier]) {
            fadeOut(subview, kFadeDuration / 2);  // fade quickly
        }
    }
    
    [clientView addSubview:[self view]];
    
    // set symbol image
    if ([self isReversed]) {
        [[self symbol] rotateByAngle:180];
    }
    
    // center
    [clientView addConstraints:@[[NSLayoutConstraint constraintWithItem:[self view]
                                                              attribute:NSLayoutAttributeCenterX
                                                              relatedBy:NSLayoutRelationEqual
                                                                 toItem:clientView
                                                              attribute:NSLayoutAttributeCenterX
                                                             multiplier:1
                                                               constant:0],
                                 [NSLayoutConstraint constraintWithItem:[self view]
                                                              attribute:NSLayoutAttributeCenterY
                                                              relatedBy:NSLayoutRelationEqual
                                                                 toItem:clientView
                                                              attribute:NSLayoutAttributeCenterY
                                                             multiplier:0.8  // shift a bit upper
                                                               constant:0]]];
    // fade-in
    fadeIn([self view], kFadeDuration);
    
    // set fade-out timer
    [self setFadeoutTimer:[NSTimer scheduledTimerWithTimeInterval:kFadeDuration + kDefaultDisplayingInterval
                                                           target:self
                                                         selector:@selector(fadeOutWithTimer:)
                                                         userInfo:nil
                                                          repeats:NO]];
}



#pragma mark Private Methods

// ------------------------------------------------------
/// fade out timer
- (void)fadeOutWithTimer:(nonnull NSTimer *)timer
// ------------------------------------------------------
{
    fadeOut([self view], kFadeDuration);
}


// ------------------------------------------------------
/// fade-in view
void fadeIn(NSView * _Nonnull view, NSTimeInterval duration)
// ------------------------------------------------------
{
    [NSAnimationContext runAnimationGroup:^(NSAnimationContext * _Nonnull context) {
        [context setDuration:duration];
        [[view animator] setAlphaValue:1.0];
    } completionHandler:nil];
}


// ------------------------------------------------------
/// fade-out view
void fadeOut(NSView * _Nonnull view, NSTimeInterval duration)
// ------------------------------------------------------
{
    [NSAnimationContext runAnimationGroup:^(NSAnimationContext * _Nonnull context) {
        [context setDuration:duration];
        [[view animator] setAlphaValue:0.0];
    } completionHandler:^{
        [view removeFromSuperview];
    }];
}

@end
