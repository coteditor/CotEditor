/*
 
 CEWindowController.h
 
 CotEditor
 http://coteditor.com
 
 Created by nakamuxu on 2004-12-13.

 ------------------------------------------------------------------------------
 
 © 2004-2007 nakamuxu
 © 2014-2015 1024jp
 
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

@import Cocoa;
#import "CEToolbarController.h"


@class CEEditorWrapper;


@interface CEWindowController : NSWindowController <NSWindowDelegate>

@property (readonly, nonatomic, nullable, weak) CEEditorWrapper *editor;
@property (readonly, nonatomic, nullable, weak) CEToolbarController *toolbarController;
@property (readonly, nonatomic) BOOL showsStatusBar;


// Public Methods
- (void)showIncompatibleCharList;
- (void)updateIncompatibleCharsIfNeeded;
- (void)updateEditorInfoIfNeeded;
- (void)updateModeInfoIfNeeded;
- (void)updateFileInfo;
- (void)setupEditorInfoUpdateTimer;

// Action Messages
- (IBAction)getInfo:(nullable id)sender;
- (IBAction)toggleIncompatibleCharList:(nullable id)sender;
- (IBAction)toggleStatusBar:(nullable id)sender;

@end
