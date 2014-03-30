/*
=================================================
CEDocumentController
(for CotEditor)

 Copyright (C) 2004-2007 nakamuxu.
 Copyright (C) 2014 CotEditor Project
 http://coteditor.github.io
=================================================

encoding="UTF-8"
Created:2004.12.14

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

#import "CEDocumentController.h"
#import "constants.h"


@interface CEDocumentController ()

@property (nonatomic) BOOL isOpenHidden;

@property (nonatomic) IBOutlet NSView *openPanelAccessoryView;


// readonly
@property (nonatomic, readwrite) IBOutlet NSPopUpButton *accessoryEncodingMenu;

@end


#pragma mark -

@implementation CEDocumentController

#pragma mark NSDocumentController Methods

//=======================================================
// NSDocumentController Methods
//
//=======================================================

// ------------------------------------------------------
/// inizialize instance
- (instancetype)init
// ------------------------------------------------------
{
    self = [super init];
    if (self) {
        [NSBundle loadNibNamed:@"OpenDocumentAccessory" owner:self];
    }
    return self;
}


// ------------------------------------------------------
/// オープンパネルを開くときにエンコーディング指定メニューを付加する
- (NSInteger)runModalOpenPanel:(NSOpenPanel *)openPanel forTypes:(NSArray *)extensions
// ------------------------------------------------------
{
    // エンコーディングメニューの選択を初期化し、ビューをセット
    [self setSelectAccessoryEncodingMenuToDefault:self];
    [openPanel setAccessoryView:[self openPanelAccessoryView]];

    // 非表示ファイルも表示するとき
    if ([self isOpenHidden]) {
        [openPanel setTreatsFilePackagesAsDirectories:YES];
        [openPanel setShowsHiddenFiles:YES];
    } else {
        [openPanel setTreatsFilePackagesAsDirectories:NO];
    }

    return [super runModalOpenPanel:openPanel forTypes:extensions];
}



#pragma mark Action Messages

//=======================================================
// Action messages
//
//=======================================================

// ------------------------------------------------------
/// ドキュメントを開く (override)
- (IBAction)openDocument:(id)sender
// ------------------------------------------------------
{
    [self setIsOpenHidden:([sender tag] == k_openHiddenMenuItemTag)];

    [super openDocument:sender];
    // エンコーディングメニューの選択をリセット
    [self setSelectAccessoryEncodingMenuToDefault:self];
}


// ------------------------------------------------------
/// ドキュメントを開く
- (IBAction)openHiddenDocument:(id)sender
// ------------------------------------------------------
{
    [self setIsOpenHidden:([sender tag] == k_openHiddenMenuItemTag)];

    [super openDocument:sender];
}


// ------------------------------------------------------
/// エンコーディングメニューの選択を初期化
- (IBAction)setSelectAccessoryEncodingMenuToDefault:(id)sender
// ------------------------------------------------------
{
    NSStringEncoding defaultEncoding = (NSStringEncoding)[[NSUserDefaults standardUserDefaults] integerForKey:k_key_encodingInOpen];

    [self setAccessorySelectedEncoding:defaultEncoding];
}

@end
