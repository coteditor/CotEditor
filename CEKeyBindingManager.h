/*
=================================================
CEKeyBindingManager
(for CotEditor)

Copyright (C) 2004-2007 nakamuxu.
http://www.aynimac.com/
=================================================

encoding="UTF-8"
Created:2005.09.01

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
    IBOutlet id _menuEditSheet;
    IBOutlet id _menuOutlineView;
    IBOutlet id _menuDuplicateTextField;
    IBOutlet id _menuEditKeyButton;
    IBOutlet id _menuDeleteKeyButton;
    IBOutlet id _menuFactoryDefaultsButton;
    IBOutlet id _menuOkButton;
    IBOutlet id _textEditSheet;
    IBOutlet id _textOutlineView;
    IBOutlet id _textDuplicateTextField;
    IBOutlet id _textEditKeyButton;
    IBOutlet id _textDeleteKeyButton;
    IBOutlet id _textFactoryDefaultsButton;
    IBOutlet id _textOkButton;
    IBOutlet id _textInsertStringTextView;
    IBOutlet id _textInsertStringArrayController;

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
