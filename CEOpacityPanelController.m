/*
 =================================================
 CEOpacityPanelController
 (for CotEditor)
 
 Copyright (C) 2014 CotEditor Project
 http://coteditor.github.io
 =================================================
 
 encoding="UTF-8"
 Created:2014-03-12 by 1024jp
 
 ___ARC_enabled___
 
 -------------------------------------------------
 
 This program is free software; you can redistribute it and/or
 modify it under the terms of the GNU General Public License
 as published by the Free Software Foundation; either version 2
 of the License, or (at your option) any later version.
 
 This program is distributed in the hope that it will be useful,
 but WITHOUT ANY WARRANTY; without even the implied warranty of
 MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 GNU General Public License for more details.
 
 You should have received a copy of the GNU General Public License
 along with this program; if not, write to the Free Software
 Foundation, Inc., 59 Temple Place - Suite 330, Boston, MA  02111-1307, USA.
 
 
 =================================================
 */

#import "CEOpacityPanelController.h"
#import "CEWindowController.h"
#import "constants.h"


@implementation CEOpacityPanelController

@synthesize opacity = _opacity;


#pragma mark Class Methods

// ------------------------------------------------------
+ (CEOpacityPanelController *)sharedController
// return singleton instance
// ------------------------------------------------------
{
    static dispatch_once_t predicate;
    static CEOpacityPanelController *shared = nil;
    
    dispatch_once(&predicate, ^{
        shared = [[CEOpacityPanelController alloc] initWithWindowNibName:@"OpacityPanel"];
    });
    
    return shared;
}



#pragma mark Public Methods

// ------------------------------------------------------
- (instancetype)initWithWindow:(NSWindow *)window
// default initializer
// ------------------------------------------------------
{
    self = [super initWithWindow:window];
    if (self) {
        id defaults = [[NSUserDefaultsController sharedUserDefaultsController] values];
        [self setOpacity:(CGFloat)[[defaults valueForKey:k_key_windowAlpha] doubleValue]];
    }
    return self;
}


// ------------------------------------------------------
- (void)setOpacity:(CGFloat)opacity
// setter for opacity property
// ------------------------------------------------------
{
    _opacity = opacity;
    
    // apply to the frontmost document window
    [[self subjectWindowController] setAlpha:[self opacity]];
}



#pragma mark Action Messages

// ------------------------------------------------------
- (IBAction)applyAsDefault:(id)sender
// set current value as default and apply it to all document windows
// ------------------------------------------------------
{
    // apply to all windows
    NSArray *documents = [[NSDocumentController sharedDocumentController] documents];
    for (id document in documents) {
        [(CEWindowController *)[document windowController] setAlpha:[self opacity]];
    }
    
    // set as default
    [[NSUserDefaults standardUserDefaults] setValue:@([self opacity]) forKey:k_key_windowAlpha];
}



#pragma mark Private Methods

// ------------------------------------------------------
- (CEWindowController *)subjectWindowController
// return the frontmost document's window controller (or nil if not exists)
// ------------------------------------------------------
{
    id windowController = [[[NSDocumentController sharedDocumentController] currentDocument] windowControllers][0];
    
    if ([windowController isKindOfClass:[CEWindowController class]]) {
        return windowController;
    }
    
    return nil;
}

@end
