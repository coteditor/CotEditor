/*
 ==============================================================================
 CEWindowController
 
 CotEditor
 http://coteditor.com
 
 Created on 2004-12-13 by nakamuxu
 encoding="UTF-8"
 ------------------------------------------------------------------------------
 
 © 2004-2007 nakamuxu
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

@import Cocoa;
#import <OgreKit/OgreTextFinder.h>
#import "CEDocument.h"
#import "CEEditorWrapper.h"
#import "CEToolbarController.h"


// document information keys
extern NSString *const CEDocumentEncodingKey;
extern NSString *const CEDocumentLineEndingsKey;
extern NSString *const CEDocumentCreationDateKey;     // NSDate
extern NSString *const CEDocumentModificationDateKey; // NSDate
extern NSString *const CEDocumentOwnerKey;
extern NSString *const CEDocumentHFSTypeKey;
extern NSString *const CEDocumentHFSCreatorKey;
extern NSString *const CEDocumentFinderLockKey;
extern NSString *const CEDocumentPermissionKey;
extern NSString *const CEDocumentFileSizeKey;
// editor information keys
extern NSString *const CEDocumentLinesKey;
extern NSString *const CEDocumentCharsKey;
extern NSString *const CEDocumentWordsKey;
extern NSString *const CEDocumentLengthKey;
extern NSString *const CEDocumentSelectedLinesKey;
extern NSString *const CEDocumentSelectedCharsKey;
extern NSString *const CEDocumentSelectedWordsKey;
extern NSString *const CEDocumentSelectedLengthKey;
extern NSString *const CEDocumentFormattedLinesKey;
extern NSString *const CEDocumentFormattedCharsKey;
extern NSString *const CEDocumentFormattedWordsKey;
extern NSString *const CEDocumentFormattedLengthKey;
extern NSString *const CEDocumentByteLengthKey;
extern NSString *const CEDocumentColumnKey;    // caret location from line head
extern NSString *const CEDocumentLocationKey;  // caret location from begining of document
extern NSString *const CEDocumentLineKey;      // current line
extern NSString *const CEDocumentUnicodeKey;   // Unicode of selected single character (or surrogate-pair)


@interface CEWindowController : NSWindowController <NSWindowDelegate, OgreTextFindDataSource>

@property (readonly, nonatomic, weak) CEEditorWrapper *editor;
@property (readonly, nonatomic, weak) CEToolbarController *toolbarController;
@property (readonly, nonatomic) BOOL showsStatusBar;

// Public method
- (void)setWritable:(BOOL)isWritable;
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
- (IBAction)toggleStatusBar:(id)sender;

@end
