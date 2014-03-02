/*
=================================================
CESyntaxManager
(for CotEditor)

Copyright (C) 2004-2007 nakamuxu.
http://www.aynimac.com/
=================================================

encoding="UTF-8"
Created:2004.12.24

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
#import "RegexKitLite.h"
#import "constants.h"


@interface CESyntaxManager : NSObject
{
    IBOutlet id _styleController;
    IBOutlet id _editWindow;
    IBOutlet id _styleNameField;
    IBOutlet id _messageField;
    IBOutlet id _elementPopUpButton;
    IBOutlet id _factoryDefaultsButton;
    IBOutlet id _extensionErrorTextView;
    IBOutlet id _syntaxElementCheckTextView;

    NSString *_selectedStyleName;
    NSString *_editedNewStyleName;
    NSArray *_coloringStyleArray;
    NSDictionary *_xtsnAndStyleTable;
    NSDictionary *_xtsnErrors;
    NSArray *_extensions;

    BOOL _okButtonPressed;
    BOOL _addedItemInLeopard;
    NSInteger _sheetOpeningMode;
    NSUInteger _selectedDetailTag; // Elementsタブでのポップアップメニュー選択用バインディング変数(#削除不可)
}

// class method
+ (CESyntaxManager *)sharedInstance;

// Public method
- (NSDictionary *)xtsnAndStyleTable;
- (NSDictionary *)xtsnErrors;
- (NSArray *)extensions;
- (NSString *)selectedStyleName;
- (NSString *)editedNewStyleName;
- (void)setEditedNewStyleName:(NSString *)inString;
- (BOOL)setSelectionIndexOfStyle:(NSInteger)inStyleIndex mode:(NSInteger)inMode;
- (NSString *)syntaxNameFromExtension:(NSString *)inExtension;
- (NSDictionary *)syntaxWithStyleName:(NSString *)inStyleName;
- (NSArray *)defaultSyntaxFileNames;
- (NSArray *)defaultSyntaxFileNamesWithoutPrefix;
- (BOOL)isDefaultSyntaxStyle:(NSString *)inStyleName;
- (BOOL)isEqualToDefaultSyntaxStyle:(NSString *)inStyleName;
- (NSArray *)styleNames;
- (NSWindow *)editWindow;
- (BOOL)isOkButtonPressed;
- (void)setIsOkButtonPressed:(BOOL)inValue;
- (BOOL)existsStyleFileWithStyleName:(NSString *)inStyleName;
- (BOOL)importStyleFile:(NSString *)inStyleFileName;
- (BOOL)removeStyleFileWithStyleName:(NSString *)inStyleName;
- (NSURL *)URLOfStyle:(NSString *)styleName;
- (BOOL)existsExtensionError;
- (NSWindow *)extensionErrorWindow;

// Action Message
- (IBAction)setToFactoryDefaults:(id)sender;
- (IBAction)closeSyntaxEditSheet:(id)sender;
- (IBAction)closeSyntaxExtensionErrorSheet:(id)sender;
- (IBAction)startSyntaxElementCheck:(id)sender;

@end
