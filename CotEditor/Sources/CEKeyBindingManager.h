/*
=================================================
CEKeyBindingManager
(for CotEditor)

 Copyright (C) 2004-2007 nakamuxu.
 Copyright (C) 2014 CotEditor Project
 http://coteditor.github.io
=================================================

encoding="UTF-8"
Created:2005.09.01
 
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
#import "CEAppController.h"
#import "constants.h"


@interface CEKeyBindingManager : NSObject
{
    IBOutlet NSWindow *_menuEditSheet;
    IBOutlet NSOutlineView *_menuOutlineView;
    IBOutlet NSTextField *_menuDuplicateTextField;
    IBOutlet NSButton *_menuEditKeyButton;
    IBOutlet NSButton *_menuDeleteKeyButton;
    IBOutlet NSButton *_menuFactoryDefaultsButton;
    IBOutlet NSButton *_menuOkButton;
    IBOutlet NSWindow *_textEditSheet;
    IBOutlet NSOutlineView *_textOutlineView;
    IBOutlet NSTextField *_textDuplicateTextField;
    IBOutlet NSButton *_textEditKeyButton;
    IBOutlet NSButton *_textDeleteKeyButton;
    IBOutlet NSButton *_textFactoryDefaultsButton;
    IBOutlet NSButton *_textOkButton;
    IBOutlet NSTextView *_textInsertStringTextView;
    IBOutlet NSArrayController *_textInsertStringArrayController;

    NSMutableArray *_outlineDataArray;
    NSMutableArray *_duplicateKeyCheckArray;
    NSDictionary *_defaultMenuKeyBindingDict;
    NSDictionary *_menuKeyBindingDict;
    NSDictionary *_textKeyBindingDict;
    NSDictionary *_noPrintableKeyDict;
    NSString *_currentKeySpecChars;
    NSInteger _outlineMode;
}

// class method
+ (CEKeyBindingManager *)sharedInstance;

// Public method
- (void)setupAtLaunching;
- (NSWindow *)editSheetWindowOfMode:(NSInteger)inMode;
- (void)setupKeyBindingDictionary;
- (BOOL)setupOutlineDataOfMode:(NSInteger)inMode;
- (NSString *)selectorStringWithKeyEquivalent:(NSString *)inString modifierFrags:(NSUInteger)inModFlags;

// Action Message
- (IBAction)editKeyBindingKey:(id)sender;
- (IBAction)deleteKeyBindingKey:(id)sender;
- (IBAction)resetOutlineDataArrayToFactoryDefaults:(id)sender;
- (IBAction)closeKeyBindingEditSheet:(id)sender;
- (IBAction)doubleClickedOutlineViewRow:(id)sender;

@end
