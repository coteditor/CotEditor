/*
 =================================================
 CEGoToPanelController
 (for CotEditor)
 
 Copyright (C) 2014 CotEditor Project
 http://coteditor.github.io
 =================================================
 
 encoding="UTF-8"
 Created:2014-03-16 by 1024jp
 
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

#import "CEGoToPanelController.h"
#import "constants.h"


@interface CEGoToPanelController ()

@property (nonatomic) NSString  *locationString;
@property (nonatomic) NSUInteger gotoType;

@end


#pragma mark -

@implementation CEGoToPanelController

#pragma mark Class Methods

// ------------------------------------------------------
+ (CEGoToPanelController *)sharedController
// return singleton instance
// ------------------------------------------------------
{
    static dispatch_once_t predicate;
    static CEGoToPanelController *shared = nil;
    
    dispatch_once(&predicate, ^{
        shared = [[CEGoToPanelController alloc] initWithWindowNibName:@"GoToPanel"];
    });
    
    return shared;
}


#pragma mark CEPanelController Methods

// ------------------------------------------------------
- (void)keyDocumentDidChange
// invoke when frontmost document window changed
// ------------------------------------------------------
{
    [self setLocationString:@""];
}



#pragma mark Action Messages

// ------------------------------------------------------
- (IBAction)apply:(id)sender
// apply to the frontmost document window
// ------------------------------------------------------
{
    NSArray *theArray = [[self locationString] componentsSeparatedByString:@":"];
    
    if ([theArray count] > 0) {
        NSInteger location = [theArray[0] integerValue];
        NSInteger length = ([theArray count] > 1) ? [theArray[1] integerValue] : 0;
        
        [[[self documentWindowController] document] gotoLocation:location withLength:length type:[self gotoType]];
        [[self window] close];
    }
}

@end
