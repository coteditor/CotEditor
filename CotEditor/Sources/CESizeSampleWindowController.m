/*
 =================================================
 CESizeSampleWindowController
 (for CotEditor)
 
 Copyright (C) 2014 CotEditor Project
 http://coteditor.github.io
 =================================================
 
 encoding="UTF-8"
 Created:2014-03-26 by 1024jp
 
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

#import "CESizeSampleWindowController.h"


@interface CESizeSampleWindowController ()

@property (nonatomic) IBOutlet NSUserDefaultsController *userDefaultsController;

@end



#pragma mark -

@implementation CESizeSampleWindowController

#pragma mark Super Class Methods

- (void)windowDidLoad
{
    [super windowDidLoad];
    [[self window] center];
}



#pragma mark Action Messages

// ------------------------------------------------------
- (IBAction)cancel:(id)sender
// サンプルウィンドウの内部サイズをuserDefaultsにセット
// ------------------------------------------------------
{
    [[self userDefaultsController] revert:sender];
    [NSApp stopModal];
}


// ------------------------------------------------------
- (IBAction)save:(id)sender
// サンプルウィンドウの内部サイズをuserDefaultsにセット
// ------------------------------------------------------
{
    [[self userDefaultsController] save:sender];
    [NSApp stopModal];
}

@end
