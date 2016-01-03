/*
 
 CEOpacityPanelController.m
 
 CotEditor
 http://coteditor.com
 
 Created by 1024jp on 2014-03-12.

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

#import "CEOpacityPanelController.h"
#import "CEWindow.h"
#import "CEWindowController.h"
#import "Defaults.h"


@interface CEOpacityPanelController ()

@property (nonatomic) CGFloat opacity;

@end




#pragma mark -

@implementation CEOpacityPanelController

#pragma mark Superclass Methods

// ------------------------------------------------------
/// nib name
- (nullable NSString *)windowNibName
// ------------------------------------------------------
{
    return @"OpacityPanel";
}


// ------------------------------------------------------
/// invoke when frontmost document window changed
- (void)keyDocumentDidChange
// ------------------------------------------------------
{
    [self setOpacity:[(CEWindow *)[[self documentWindowController] window] backgroundAlpha]];
}


// ------------------------------------------------------
/// auto close window if all document windows were closed
- (BOOL)autoCloses
// ------------------------------------------------------
{
    return YES;
}



#pragma mark Action Messages

// ------------------------------------------------------
/// set current value as default and apply it to all document windows
- (IBAction)applyAsDefault:(nullable id)sender
// ------------------------------------------------------
{
    // set as default
    //   -> The new value will automatically be applied to all windows as they observe userDefault value.
    [[NSUserDefaults standardUserDefaults] setValue:@([self opacity]) forKey:CEDefaultWindowAlphaKey];
}



#pragma mark Private Methods

// ------------------------------------------------------
/// setter for opacity property
- (void)setOpacity:(CGFloat)opacity
// ------------------------------------------------------
{
    _opacity = opacity;
    
    // apply to the frontmost document window
    [(CEWindow *)[[self documentWindowController] window] setBackgroundAlpha:opacity];
}

@end
