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

@property (nonatomic, weak) CEDocument *latestDocument;
@property (nonatomic) NSRect latestDocumentWindowFrame;
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
/// 名称未設定ドキュメントを開き、位置を保存
- (id)openUntitledDocumentAndDisplay:(BOOL)displayDocument error:(NSError **)outError
// ------------------------------------------------------
{
    id document = [super openUntitledDocumentAndDisplay:displayDocument error:outError];

    if (document) {
        [self setLatestDocument:(CEDocument *)document];
        [self setLatestDocumentWindowFrame:[[[(CEDocument *)document windowController] window] frame]];
    }
    return document;
}


// ------------------------------------------------------
/// ファイルからドキュメントを作成
- (id)makeDocumentWithContentsOfURL:(NSURL *)url ofType:(NSString *)typeName error:(NSError **)outError
// ------------------------------------------------------
{
    id document = [super makeDocumentWithContentsOfURL:url ofType:typeName error:outError];

    // 自動的に開かれた名称未設定ドキュメントが未変更のままあるときはそれを上書きする（ように見せる）
    // 実際の位置の変更は CEWindowController で行う
    if (document && [self latestDocument] && ![[self latestDocument] isDocumentEdited] &&
        NSEqualRects([self latestDocumentWindowFrame], [[[[self latestDocument] windowController] window] frame])) {
        // ウィンドウ位置は、この時点ではまだ新しいドキュメントの windowController がないため、設定できない
        [document setDoCascadeWindow:NO];
        [document setInitTopLeftPoint:NSMakePoint(NSMinX([self latestDocumentWindowFrame]),
                                                  NSMaxY([self latestDocumentWindowFrame]))];
        [[[[self latestDocument] windowController] window] close];
    }

    return document;
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


// ------------------------------------------------------
/// ドキュメントが閉じた
- (void)removeDocument:(NSDocument *)document
// ------------------------------------------------------
{
    [self setLatestDocument:nil];

    [super removeDocument:document];
}



#pragma mark Action Messages

//=======================================================
// Action messages
//
//=======================================================

// ------------------------------------------------------
/// 新規ドキュメント作成 (override)
- (IBAction)newDocument:(id)sender
// ------------------------------------------------------
{
    [super newDocument:sender];

    [self setLatestDocument:nil];
}


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
