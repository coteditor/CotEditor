/*
 =================================================
 CELineSpacingPanelController
 (for CotEditor)
 
 Copyright (C) 2014 CotEditor Project
 http://coteditor.github.io
 =================================================
 
 encoding="UTF-8"
 Created:2014-03-16 by 1024jp
 
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

#import "CELineSpacingPanelController.h"
#import "CEWindowController.h"
#import "constants.h"


@implementation CELineSpacingPanelController

#pragma mark Class Methods

// ------------------------------------------------------
+ (CELineSpacingPanelController *)sharedController
// return singleton instance
// ------------------------------------------------------
{
    static dispatch_once_t predicate;
    static CELineSpacingPanelController *shared = nil;
    
    dispatch_once(&predicate, ^{
        shared = [[CELineSpacingPanelController alloc] initWithWindowNibName:@"LineSpacingPanel"];
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
        [self setLineSpacing:(CGFloat)[[NSUserDefaults standardUserDefaults] doubleForKey:k_key_lineSpacing]];
    }
    return self;
}


// ------------------------------------------------------
- (IBAction)showWindow:(id)sender
// show window
// ------------------------------------------------------
{
    [self setLineSpacing:[[self documentWindowController] lineSpacingInTextView]];
    
    [super showWindow:sender];
}



#pragma mark Private Methods

// ------------------------------------------------------
- (IBAction)apply:(id)sender
// apply to the frontmost document window
// ------------------------------------------------------
{
    [[self documentWindowController] setLineSpacingInTextView:[self lineSpacing]];
    [[self window] close];
}


// ------------------------------------------------------
- (CEWindowController *)documentWindowController
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
