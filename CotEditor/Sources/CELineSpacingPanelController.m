/*
 =================================================
 CELineSpacingPanelController
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

#import "CELineSpacingPanelController.h"


@interface CELineSpacingPanelController ()

@property (nonatomic) CGFloat lineSpacing;

@end




#pragma mark -

@implementation CELineSpacingPanelController

#pragma mark Superclass Methods

// ------------------------------------------------------
/// initializer of panelController
- (instancetype)init
// ------------------------------------------------------
{
    self = [super initWithWindowNibName:@"LineSpacingPanel"];
    
    return self;
}


// ------------------------------------------------------
/// invoke when frontmost document window changed
- (void)keyDocumentDidChange
// ------------------------------------------------------
{
    [self setLineSpacing:[[[[self documentWindowController] editorView] textView] lineSpacing]];
    
}



#pragma mark Action Messages

// ------------------------------------------------------
/// apply to the frontmost document window
- (IBAction)apply:(id)sender
// ------------------------------------------------------
{
    [[[[self documentWindowController] editorView] textView] setLineSpacing:[self lineSpacing]];
    [[self window] close];
}

@end
