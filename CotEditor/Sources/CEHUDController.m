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

@import QuartzCore;
#import "CEHUDController.h"


NSString * _Nonnull const CEWrapSymbolName = @"WrapSymbol";

static NSString * _Nonnull const FadeInKey = @"fadeIn";
static NSString * _Nonnull const FadeOutKey = @"fadeOut";
static NSString * _Nonnull const HUDIdentifier = @"HUD";
static CGFloat const kCornerRadius = 14.0;
static NSTimeInterval const kDefaultDisplayingInterval = 0.1;
static NSTimeInterval const kFadeDuration = 0.5;


@interface CEHUDController ()

@property (nonatomic, nonnull) NSImage *symbolImage;

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
    
    [[self view] setIdentifier:HUDIdentifier];
    [[[self view] layer] setCornerRadius:kCornerRadius];
    [[[self view] layer] setOpacity:0.0];
    
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
            fadeOut(subview, kFadeDuration / 2, 0);  // fade quickly
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
    fadeIn([self view], kFadeDuration * 0.8);
    
    // set fade-out with delay
    fadeOut([self view], kFadeDuration, kFadeDuration + kDefaultDisplayingInterval);
}



#pragma mark Private Methods

// ------------------------------------------------------
/// fade-in view
void fadeIn(NSView * _Nonnull view, NSTimeInterval duration)
// ------------------------------------------------------
{
    CABasicAnimation *animation = [CABasicAnimation animationWithKeyPath:@"opacity"];
    [animation setToValue:@1.0];
    [animation setDuration:duration];
    [animation setFillMode:kCAFillModeForwards];
    [animation setRemovedOnCompletion:NO];
    [[view layer] addAnimation:animation forKey:FadeInKey];
}


// ------------------------------------------------------
/// fade-out view
void fadeOut(NSView * _Nonnull view, NSTimeInterval duration, NSTimeInterval delay)
// ------------------------------------------------------
{
    [CATransaction begin]; {
        [CATransaction setCompletionBlock:^{
            [view removeFromSuperview];
        }];
        CABasicAnimation *animation = [CABasicAnimation animationWithKeyPath:@"opacity"];
        [animation setToValue:@0.0];
        [animation setDuration:duration];
        [animation setBeginTime:CACurrentMediaTime() + delay];
        [animation setFillMode:kCAFillModeForwards];
        [animation setRemovedOnCompletion:NO];
        [[view layer] addAnimation:animation forKey:FadeOutKey];
    } [CATransaction commit];
}

@end
