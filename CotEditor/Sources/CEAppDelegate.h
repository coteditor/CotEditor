/*
=================================================
CEAppDelegate
(for CotEditor)

 Copyright (C) 2004-2007 nakamuxu.
 Copyright (C) 2014 CotEditor Project
 http://coteditor.github.io
=================================================

encoding="UTF-8"
Created:2004.12.13
 
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

#import <Cocoa/Cocoa.h>
#import "CEDocumentController.h"
#import "CESyntaxManager.h"
#import "CEKeyBindingManager.h"
#import "CEScriptManager.h"


@interface CEAppDelegate : NSObject <NSApplicationDelegate>

@property (nonatomic, copy, readonly) NSArray *encodingMenuItems;


// Public method
- (void)buildAllEncodingMenus;

// Action Message
- (IBAction)openPrefWindow:(id)sender;
- (IBAction)openAppleScriptDictionary:(id)sender;
- (IBAction)openScriptErrorWindow:(id)sender;
- (IBAction)openHexColorCodeEditor:(id)sender;
- (IBAction)openOpacityPanel:(id)sender;
- (IBAction)openLineSpacingPanel:(id)sender;
- (IBAction)openGoToPanel:(id)sender;
- (IBAction)openUnicodeInputPanel:(id)sender;
- (IBAction)newInDockMenu:(id)sender;
- (IBAction)openInDockMenu:(id)sender;
- (IBAction)openBundledDocument:(id)sender;
- (IBAction)openWebSite:(id)sender;

@end
