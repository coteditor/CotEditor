/*
=================================================
CEWindowController
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

@import Cocoa;
#import <OgreKit/OgreKit.h>
#import "CEDocument.h"
#import "CEEditorWrapper.h"
#import "CEToolbarController.h"


@interface CEWindowController : NSWindowController <NSWindowDelegate, NSDrawerDelegate, NSTabViewDelegate, OgreTextFindDataSource>

@property (nonatomic) CGFloat alpha;

@property (nonatomic, readonly, weak) CEEditorWrapper *editor;
@property (nonatomic, readonly, weak) CEToolbarController *toolbarController;
@property (nonatomic, readonly) BOOL showStatusBar;

// Public method
- (void)setIsWritable:(BOOL)isWritable;
- (BOOL)needsInfoDrawerUpdate;
- (BOOL)needsIncompatibleCharDrawerUpdate;
- (void)showIncompatibleCharList;
- (void)updateEditorStatusInfo:(BOOL)needsUpdateDrawer;
- (void)updateEncodingAndLineEndingsInfo:(BOOL)needsUpdateDrawer;
- (void)updateFileAttributesInfo;
- (void)setupIncompatibleCharTimer;
- (void)setupInfoUpdateTimer;

// Action Message
- (IBAction)getInfo:(id)sender;
- (IBAction)toggleIncompatibleCharList:(id)sender;
- (IBAction)selectIncompatibleRange:(id)sender;
- (IBAction)toggleShowStatusBar:(id)sender;

@end
