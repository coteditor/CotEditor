/*
 =================================================
 CEEncodingListSheetController
 (for CotEditor)
 
 Copyright (C) 2014 CotEditor Project
 http://coteditor.github.io
 =================================================
 
 encoding="UTF-8"
 Created:2014-03-26 by 1024jp
 
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

#import "CEEncodingListSheetController.h"
#import "CEPrefEncodingDataSource.h"
#import "CEAppController.h"


@interface CEEncodingListSheetController ()

@property (nonatomic, weak) IBOutlet CEPrefEncodingDataSource *dataSource;

@end



#pragma mark -

@implementation CEEncodingListSheetController

#pragma mark NSWindowController Methods

// ------------------------------------------------------
- (instancetype)init
// 初期化
// ------------------------------------------------------
{
    self = [super initWithWindowNibName:@"EncodingListSheet"];
    if (self) {
    }
    return self;
}


// ------------------------------------------------------
- (void)awakeFromNib
// Nibファイル読み込み直後
// ------------------------------------------------------
{
    [[self dataSource] setupEncodingsToEdit];
}



#pragma mark Action Messages

// ------------------------------------------------------
- (IBAction)save:(id)sender
// OK ボタンが押された
// ------------------------------------------------------
{
    [[self dataSource] writeEncodingsToUserDefaults]; // エンコーディングを保存
    [(CEAppController *)[[NSApplication sharedApplication] delegate] buildAllEncodingMenus];
    
    [NSApp stopModal];
}


// ------------------------------------------------------
- (IBAction)cancel:(id)sender
// Cancel ボタンが押された
// ------------------------------------------------------
{
    [NSApp stopModal];
}

@end
