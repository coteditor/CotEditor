/*
=================================================
CEPreferences
(for CotEditor)

 Copyright (C) 2004-2007 nakamuxu.
 Copyright (C) 2014 CotEditor Project
 http://coteditor.github.io
=================================================

encoding="UTF-8"
Created:2004.12.13
 
 -fno-objc-arc
 
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
#import "CEPrefEncodingDataSource.h"
#import "CESyntax.h"
#import "constants.h"

@interface CEPreferences : NSObject
{
    IBOutlet NSWindow *_prefWindow;
    IBOutlet NSTabView *_prefTabView;
    IBOutlet NSTextField *_prefFontFamilyNameSize;
    IBOutlet NSTextField *_printFontFamilyNameSize;
    IBOutlet NSWindow *_encodingWindow;
    IBOutlet CEPrefEncodingDataSource *_encodingDataSource;
    IBOutlet NSPopUpButton *_encodingMenuInOpen;
    IBOutlet NSPopUpButton *_encodingMenuInNew;
    IBOutlet NSWindow *_sizeSampleWindow;
    IBOutlet NSArrayController *_fileDropController;
    IBOutlet NSTableView *_fileDropTableView;
    IBOutlet NSTextView *_fileDropTextView;
    IBOutlet NSTextView *_fileDropGlossaryTextView;
    IBOutlet NSPopUpButton *_invisibleSpacePopup;
    IBOutlet NSPopUpButton *_invisibleTabPopup;
    IBOutlet NSPopUpButton *_invisibleNewLinePopup;
    IBOutlet NSPopUpButton *_invisibleFullwidthSpacePopup;
    IBOutlet NSPopUpButton *_syntaxStylesPopup;
    IBOutlet NSPopUpButton *_syntaxStylesDefaultPopup;
    IBOutlet NSButton *_syntaxStyleEditButton;
    IBOutlet NSButton *_syntaxStyleCopyButton;
    IBOutlet NSButton *_syntaxStyleExportButton;
    IBOutlet NSButton *_syntaxStyleDeleteButton;
    IBOutlet NSButton *_syntaxStyleXtsnErrButton;

    CGFloat _sampleWidth;
    CGFloat _sampleHeight;

    id _appController;
    NSInteger _currentSheetCode;
    BOOL _doDeleteFileDrop;
}

// Public method
- (void)setupEncodingMenus:(NSArray *)inMenuItems;
- (instancetype)initWithAppController:(id)inAppontroller;
- (void)setupSyntaxMenus;
- (void)openPrefWindow;
- (void)closePrefWindow;
- (CGFloat)sampleWidth;
- (void)setSampleWidth:(CGFloat)inWidth;
- (CGFloat)sampleHeight;
- (void)setSampleHeight:(CGFloat)inHeight;
- (void)changeFont:(id)sender;
- (void)makeFirstResponderToPrefWindow;
- (void)writeBackFileDropArray;

// Action Message
- (IBAction)showFonts:(id)sender;
- (IBAction)openEncodingEditSheet:(id)sender;
- (IBAction)closeEncodingEditSheet:(id)sender;
- (IBAction)openSizeSampleWindow:(id)sender;
- (IBAction)setWindowContentSizeToDefault:(id)sender;
- (IBAction)openSyntaxEditSheet:(id)sender;
- (IBAction)changedSyntaxStylesPopup:(id)sender;
- (IBAction)deleteSyntaxStyle:(id)sender;
- (IBAction)importSyntaxStyle:(id)sender;
- (IBAction)exportSyntaxStyle:(id)sender;
- (IBAction)openSyntaxExtensionErrorSheet:(id)sender;
- (IBAction)insertFormatStringInFileDrop:(id)sender;
- (IBAction)addNewFileDropSetting:(id)sender;
- (IBAction)deleteFileDropSetting:(id)sender;
- (IBAction)openKeyBindingEditSheet:(id)sender;
- (IBAction)setupCustomLineSpacing:(id)sender;
- (IBAction)openPrefHelp:(id)sender;

@end
