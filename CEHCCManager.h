/*
=================================================
CEHCCManager
(for CotEditor)

Copyright (C) 2004-2007 nakamuxu.
Copyright (C) 2014 CotEditor Project
http://coteditor.github.io
=================================================

encoding="UTF-8"
Created:2005.07.14

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


@interface CEHCCManager : NSWindowController <NSWindowDelegate, NSComboBoxDelegate>

// class method
+ (CEHCCManager *)sharedInstance;

// Public method
- (void)setupHCCValues;
- (void)importHexColorCodeAsForeColor:(NSString *)codeString;
- (void)importHexColorCodeAsBackGroundColor:(NSString *)codeString;

// Action Message
- (IBAction)exportHexColorCode:(id)sender;
- (IBAction)swapColor:(id)sender;
- (IBAction)toggleDisclosureButton:(id)sender;

@end
