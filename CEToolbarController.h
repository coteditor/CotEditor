/*
=================================================
CEToolbarController
(for CotEditor)

Copyright (C) 2004-2007 nakamuxu.
http://www.aynimac.com/
=================================================

encoding="UTF-8"
Created:2005.01.07

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
#import "constants.h"

@class CEDocument;

@interface CEToolbarController : NSObject <NSToolbarDelegate>
{
    IBOutlet id _mainWindow;
    IBOutlet id _lineEndingPopupButton;
    IBOutlet id _encodingPopupButton;
    IBOutlet id _syntaxPopupButton;
    IBOutlet id _searchMenu;

    NSToolbar *_toolbar;
}

// Public method
- (void)setupToolbar;
- (void)updateToggleItem:(NSString *)inIdentifer setOn:(BOOL)inBool;
- (void)buildEncodingPopupButton;
- (void)setSelectEncoding:(NSInteger)inEncoding;
- (void)setSelectEndingItemIndex:(NSInteger)inIndex;
- (void)buildSyntaxPopupButton;
- (NSString *)selectedTitleOfSyntaxItem;
- (void)setSelectSyntaxItemWithTitle:(NSString *)inTitle;

@end
