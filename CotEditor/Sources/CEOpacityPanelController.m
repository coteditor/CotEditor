/*
 ==============================================================================
 CEOpacityPanelController
 
 CotEditor
 http://coteditor.github.io
 
 Created by 2014-03-12 by 1024jp
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

#import "CEOpacityPanelController.h"
#import "constants.h"


@interface CEOpacityPanelController ()

@property (nonatomic) CGFloat opacity;

@end




#pragma mark -

@implementation CEOpacityPanelController

#pragma mark Superclass Methods

// ------------------------------------------------------
/// initializer of panelController
- (instancetype)init
// ------------------------------------------------------
{
    self = [super initWithWindowNibName:@"OpacityPanel"];
    
    return self;
}


// ------------------------------------------------------
/// invoke when frontmost document window changed
- (void)keyDocumentDidChange
// ------------------------------------------------------
{
    [self setOpacity:[[self documentWindowController] alpha]];
}



#pragma mark Action Messages

// ------------------------------------------------------
/// set current value as default and apply it to all document windows
- (IBAction)applyAsDefault:(id)sender
// ------------------------------------------------------
{
    // apply to all windows
    for (id document in [NSApp orderedDocuments]) {
        [(CEWindowController *)[document windowController] setAlpha:[self opacity]];
    }
    
    // set as default
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
    [[self documentWindowController] setAlpha:opacity];
}

@end
