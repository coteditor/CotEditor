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
/// 初期化
- (instancetype)init
// ------------------------------------------------------
{
    self = [super initWithWindowNibName:@"EncodingListSheet"];
    if (self) {
    }
    return self;
}


// ------------------------------------------------------
/// Nibファイル読み込み直後
- (void)awakeFromNib
// ------------------------------------------------------
{
    [[self dataSource] setupEncodingsToEdit];
}



#pragma mark Action Messages

// ------------------------------------------------------
/// OK ボタンが押された
- (IBAction)save:(id)sender
// ------------------------------------------------------
{
    [[self dataSource] writeEncodingsToUserDefaults]; // エンコーディングを保存
    [(CEAppController *)[NSApp delegate] buildAllEncodingMenus];
    
    [NSApp stopModal];
}


// ------------------------------------------------------
/// Cancel ボタンが押された
- (IBAction)cancel:(id)sender
// ------------------------------------------------------
{
    [NSApp stopModal];
}

@end
