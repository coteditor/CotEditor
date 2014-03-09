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

#import <Cocoa/Cocoa.h>
#import <OgreKit/OgreKit.h>
#import "CEDocument.h"
#import "CEEditorView.h"
#import "CEToolbarController.h"
#import "constants.h"


@interface CEWindowController : NSWindowController <NSWindowDelegate, OgreTextFindDataSource>
{
    IBOutlet id _editorView;
    IBOutlet id _drawer;
    IBOutlet id _tabViewSelectionPopUpButton;
    IBOutlet id _tabView;
    IBOutlet id _infoCreatorField;
    IBOutlet id _infoTypeField;
    IBOutlet id _infoCreatedField;
    IBOutlet id _infoModifiedField;
    IBOutlet id _infoOwnerField;
    IBOutlet id _infoPermissionField;
    IBOutlet id _infoFinderLockField;
    IBOutlet id _infoEncodingField;
    IBOutlet id _infoLineEndingsField;
    IBOutlet id _infoLinesField;
    IBOutlet id _infoCharsField;
    IBOutlet id _infoSelectField;
    IBOutlet id _infoInLineField;
    IBOutlet id _infoSingleCharField;
    IBOutlet id _listTableView;
    IBOutlet id _listErrorTextField;
    IBOutlet id _listController;
    IBOutlet id _toolbarController;
    IBOutlet id _printSettingController;
    IBOutlet id _printAccessoryView;

    NSUInteger _tabViewSelectedIndex; // ドローワのタブビューでのポップアップメニュー選択用バインディング変数(#削除不可)

    BOOL _recolorWithBecomeKey;
}

// Public method
- (id)toolbarController;
- (BOOL)needsInfoDrawerUpdate;
- (BOOL)needsIncompatibleCharDrawerUpdate;
- (void)setInfoEncoding:(NSString *)inString;
- (void)setInfoLineEndings:(NSString *)inString;
- (void)setInfoLine:(NSString *)inString;
- (void)setInfoChar:(NSString *)inString;
- (void)setInfoSelect:(NSString *)inString;
- (void)setInfoInLine:(NSString *)inString;
- (void)setInfoSingleChar:(NSString *)inString;
- (void)updateFileAttrsInformation;
- (void)updateIncompatibleCharList;
- (void)setRecolorWithBecomeKey:(BOOL)inValue;
- (void)showIncompatibleCharList;
- (void)setupPrintValues;
- (id)printValues;
- (NSView *)printAccessoryView;

// Action Message
- (IBAction)getInfo:(id)sender;
- (IBAction)toggleIncompatibleCharList:(id)sender;
- (IBAction)selectIncompatibleRange:(id)sender;

@end
