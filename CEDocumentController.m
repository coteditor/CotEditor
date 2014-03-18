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
 
 ___ARC_enabled___

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


@interface CEDocumentController ()

@property (nonatomic, weak) CEDocument *latestDocument;
@property (nonatomic) NSRect latestDocumentWindowFrame;
@property (nonatomic) BOOL isOpenHidden;

@property (nonatomic, weak) IBOutlet NSView *openPanelAccessoryView;

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
- (id)openUntitledDocumentAndDisplay:(BOOL)displayDocument error:(NSError **)outError
// 名称未設定ドキュメントを開き、位置を保存
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
- (id)makeDocumentWithContentsOfURL:(NSURL *)url ofType:(NSString *)typeName error:(NSError **)outError
// ファイルからドキュメントを作成
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
- (NSInteger)runModalOpenPanel:(NSOpenPanel *)openPanel forTypes:(NSArray *)extensions
// オープンパネルを開くときにエンコーディング指定メニューを付加する
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
- (void)removeDocument:(NSDocument *)document
// ドキュメントが閉じた
// ------------------------------------------------------
{
    [self setLatestDocument:nil];

    [super removeDocument:document];
}



#pragma mark Public Methods

//=======================================================
// Public method
//
//=======================================================

// ------------------------------------------------------
- (NSStringEncoding)accessorySelectedEncoding
// ファイルオープンダイアログで指定されたエンコーディングを取得
// ------------------------------------------------------
{
    return [[[self accessoryEncodingMenu] selectedItem] tag];
}


// ------------------------------------------------------
- (void)setAccessorySelectedEncoding:(NSStringEncoding)encoding
// ファイルオープンダイアログのエンコーディングの選択項目を設定
// ------------------------------------------------------
{
    NSString *title = (encoding == k_autoDetectEncodingMenuTag) ?
                      NSLocalizedString(@"Auto-Detect", nil) :
                      [NSString localizedNameOfStringEncoding:encoding];

    if (![title isEqualToString:@""]) {
        [[self accessoryEncodingMenu] selectItemWithTitle:title];
    }
}


// ------------------------------------------------------
- (void)rebuildAllToolbarsEncodingItem
// すべてのツールバーのエンコーディングメニューを再生成する
// ------------------------------------------------------
{
    [[self documents] makeObjectsPerformSelector:@selector(rebuildToolbarEncodingItem)];
}


// ------------------------------------------------------
- (void)rebuildAllToolbarsSyntaxItem
// すべてのツールバーのシンタックスカラーリングスタイルメニューを再生成する
// ------------------------------------------------------
{
    [[self documents] makeObjectsPerformSelector:@selector(rebuildToolbarSyntaxItem)];
}


// ------------------------------------------------------
- (void)setRecolorFlagToAllDocumentsWithStyleName:(NSDictionary *)inDict
// 指定されたスタイルを適用しているドキュメントのリカラーフラグを立てる
// ------------------------------------------------------
{
    if (inDict != nil) {
        [[self documents] makeObjectsPerformSelector:@selector(setRecolorFlagToWindowControllerWithStyleName:) 
                withObject:inDict];
    }
}


// ------------------------------------------------------
- (void)setNoneAndRecolorFlagToAllDocumentsWithStyleName:(NSString *)styleName
// 指定されたスタイルを適用しているドキュメントの適用スタイルを"None"にし、リカラーフラグを立てる
// ------------------------------------------------------
{
    if (styleName != nil) {
        [[self documents] makeObjectsPerformSelector:@selector(setStyleToNoneAndRecolorFlagWithStyleName:) 
                withObject:styleName];
    }
}



#pragma mark Action messages

//=======================================================
// Action messages
//
//=======================================================

// ------------------------------------------------------
- (IBAction)newDocument:(id)sender
// 新規ドキュメント作成 (override)
// ------------------------------------------------------
{
    [super newDocument:sender];

    [self setLatestDocument:nil];
}


// ------------------------------------------------------
- (IBAction)openDocument:(id)sender
// ドキュメントを開く (override)
// ------------------------------------------------------
{
    [self setIsOpenHidden:([sender tag] == k_openHiddenMenuItemTag)];

    [super openDocument:sender];
    // エンコーディングメニューの選択をリセット
    [self setSelectAccessoryEncodingMenuToDefault:self];
}


// ------------------------------------------------------
- (IBAction)openHiddenDocument:(id)sender
// ドキュメントを開く
// ------------------------------------------------------
{
    [self setIsOpenHidden:([sender tag] == k_openHiddenMenuItemTag)];

    [super openDocument:sender];
}


// ------------------------------------------------------
- (IBAction)setSmartInsertAndDeleteToAllTextView:(id)sender
// すべてのテキストビューのスマートインサート／デリート実行を設定
// ------------------------------------------------------
{
    [[self documents] makeObjectsPerformSelector:@selector(setSmartInsertAndDeleteToTextView)];
}


// ------------------------------------------------------
- (IBAction)setSelectAccessoryEncodingMenuToDefault:(id)sender
// エンコーディングメニューの選択を初期化
// ------------------------------------------------------
{
    NSStringEncoding defaultEncoding = (NSStringEncoding)[[NSUserDefaults standardUserDefaults] integerForKey:k_key_encodingInOpen];

    [self setAccessorySelectedEncoding:defaultEncoding];
}

@end
