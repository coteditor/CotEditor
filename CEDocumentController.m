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
#import "ODBEditorSuite.h"

static CEDocument *theLatestDocument = nil;
static NSRect theLatestDocumentWindowFrame;

@implementation CEDocumentController

#pragma mark -
#pragma mark Public method

//=======================================================
// Public method
//
//=======================================================

// ------------------------------------------------------
- (void)dealloc
// あとかたづけ
// ------------------------------------------------------
{
    theLatestDocument = nil;

    [super dealloc];
}


// ------------------------------------------------------
- (id)openUntitledDocumentAndDisplay:(BOOL)displayDocument error:(NSError **)outError
// 名称未設定ドキュメントを開き、位置を保存
// ------------------------------------------------------
{
    id outDocument = [super openUntitledDocumentAndDisplay:displayDocument error:outError];

    if (outDocument) {
        theLatestDocument = outDocument;
        theLatestDocumentWindowFrame = [[[(CEDocument *)outDocument windowController] window] frame];
    }
    return outDocument;
}


// ------------------------------------------------------
- (id)makeDocumentWithContentsOfURL:(NSURL *)url ofType:(NSString *)typeName error:(NSError **)outError
// ファイルからドキュメントを作成
// ------------------------------------------------------
{
    id outDocument = [super makeDocumentWithContentsOfURL:url ofType:typeName error:outError];

    // 自動的に開かれた名称未設定ドキュメントが未変更のままあるときはそれを上書きする（ように見せる）ための設定を行う
    // 実際の位置の変更は CEWindowController で行う
    if (outDocument && theLatestDocument && (![(CEDocument *)theLatestDocument isDocumentEdited]) && 
            NSEqualRects(theLatestDocumentWindowFrame, 
            [[[(CEDocument *)theLatestDocument windowController] window] frame])) {
        // ウィンドウ位置は、この時点ではまだ新しいドキュメントの windowController がないため、設定できない
        [outDocument setDoCascadeWindow:NO];
        [outDocument setInitTopLeftPoint:
                NSMakePoint(theLatestDocumentWindowFrame.origin.x, NSMaxY(theLatestDocumentWindowFrame))];
    }

    return outDocument;
}


// ------------------------------------------------------
- (id)openDocumentWithContentsOfURL:(NSURL *)url display:(BOOL)displayDocument error:(NSError **)outError
// ファイルを開き、ドキュメントを作成
// ------------------------------------------------------
{
    id outDocument = [super openDocumentWithContentsOfURL:url display:displayDocument error:outError];

    if (outDocument) {
        // 外部エディタプロトコル(ODB Editor Suite)用の値をセット
        // この部分は、Smultron を参考にさせていただきました。(2005.04.20)
        // This part is based on Smultron.(written by Peter Borg – http://smultron.sourceforge.net)
        // Smultron  Copyright (c) 2004-2005 Peter Borg, All rights reserved.
        // Smultron is released under GNU General Public License, http://www.gnu.org/copyleft/gpl.html

        NSAppleEventDescriptor *theDescriptor, *theAEPropDescriptor, *theFileSender, *theFileToken;

        theDescriptor = [[NSAppleEventManager sharedAppleEventManager] currentAppleEvent];
        theFileSender = [theDescriptor paramDescriptorForKeyword:keyFileSender];
        if (theFileSender != nil) {
            theFileToken = [theDescriptor paramDescriptorForKeyword:keyFileSenderToken];
        } else {
            theAEPropDescriptor = [theDescriptor paramDescriptorForKeyword:keyAEPropData];
            theFileSender = [theAEPropDescriptor paramDescriptorForKeyword:keyFileSender];
            theFileToken = [theAEPropDescriptor paramDescriptorForKeyword:keyFileSenderToken];
        }
        if (theFileSender != nil) {
            [outDocument setFileSender:theFileSender];
            if (theFileToken != nil) {
                [outDocument setFileToken:theFileToken];
            }
        }
    }
    // 自動的に開かれた名称未設定ドキュメントが未変更のままであるときは、それを上書きする（ように見せる）
    if (outDocument && theLatestDocument && (![(CEDocument *)theLatestDocument isDocumentEdited]) && 
            NSEqualRects(theLatestDocumentWindowFrame, 
            [[[(CEDocument *)theLatestDocument windowController] window] frame])) {
        // 新しく開かれたウィンドウの真下にある名称未設定ドキュメントを閉じる
        [[[(CEDocument *)theLatestDocument windowController] window] close];
    }

    return outDocument;
}


// ------------------------------------------------------
- (NSInteger)runModalOpenPanel:(NSOpenPanel *)inOpenPanel forTypes:(NSArray *)inExtensions
// オープンパネルを開くときにエンコーディング指定メニューを付加する
// ------------------------------------------------------
{
    // エンコーディングメニューの選択を初期化し、ビューをセット
    [self setSelectAccessoryEncodingMenuToDefault:self];
    [inOpenPanel setAccessoryView:_openPanelAccessoryView];

    // 非表示ファイルも表示するとき
    if (_isOpenHidden) {
        [inOpenPanel setTreatsFilePackagesAsDirectories:YES];
        [inOpenPanel setShowsHiddenFiles:YES];
    } else {
        [inOpenPanel setTreatsFilePackagesAsDirectories:NO];
    }

    return [super runModalOpenPanel:inOpenPanel forTypes:inExtensions];
}


// ------------------------------------------------------
- (void)removeDocument:(NSDocument *)inDocument
// ドキュメントが閉じた
// ------------------------------------------------------
{
    theLatestDocument = nil;

    [super removeDocument:inDocument];
}


// ------------------------------------------------------
- (id)accessoryEncodingMenu
// ファイルオープンダイアログで表示されるエンコーディングメニューを返す
// ------------------------------------------------------
{
    return _accessoryEncodingMenu;
}


// ------------------------------------------------------
- (NSStringEncoding)accessorySelectedEncoding
// ファイルオープンダイアログで指定されたエンコーディングを取得
// ------------------------------------------------------
{
    return ([[_accessoryEncodingMenu selectedItem] tag]);
}


// ------------------------------------------------------
- (void)setSelectAccessoryEncoding:(NSStringEncoding)inEncoding
// ファイルオープンダイアログのエンコーディングの選択項目を設定
// ------------------------------------------------------
{
    NSString *theTitle = (inEncoding == k_autoDetectEncodingMenuTag) ? 
                NSLocalizedString(@"Auto-Detect",@"") : 
                [NSString localizedNameOfStringEncoding:inEncoding];

    if (theTitle && (![theTitle isEqualToString:@""])) {
        [_accessoryEncodingMenu selectItemWithTitle:theTitle];
    }
}


// ------------------------------------------------------
- (void)setFontToAllDocuments
// 全ドキュメントにフォント変更通知を送る
// ------------------------------------------------------
{
    [[self documents] makeObjectsPerformSelector:@selector(setFontToViewInWindow)];
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
- (void)setNoneAndRecolorFlagToAllDocumentsWithStyleName:(NSString *)inStyleName
// 指定されたスタイルを適用しているドキュメントの適用スタイルを"None"にし、リカラーフラグを立てる
// ------------------------------------------------------
{
    if (inStyleName != nil) {
        [[self documents] makeObjectsPerformSelector:@selector(setStyleToNoneAndRecolorFlagWithStyleName:) 
                withObject:inStyleName];
    }
}



#pragma mark -
#pragma mark Action messages

//=======================================================
// Action messages
//
//=======================================================

// ------------------------------------------------------
- (IBAction)newDocument:(id)sender
// 新規ドキュメント作成(override)
// ------------------------------------------------------
{
    [super newDocument:sender];

    theLatestDocument = nil;
}


// ------------------------------------------------------
- (IBAction)openDocument:(id)sender
// ドキュメントを開く
// ------------------------------------------------------
{
    _isOpenHidden = ([sender tag] == k_openHiddenMenuItemTag);

    [super openDocument:sender];
    // エンコーディングメニューの選択をリセット
    [self setSelectAccessoryEncodingMenuToDefault:self];
}


// ------------------------------------------------------
- (IBAction)openHiddenDocument:(id)sender
// ドキュメントを開く
// ------------------------------------------------------
{
    _isOpenHidden = ([sender tag] == k_openHiddenMenuItemTag);

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
    id theValues = [[NSUserDefaultsController sharedUserDefaultsController] values];

    [self setSelectAccessoryEncoding:[[theValues valueForKey:k_key_encodingInOpen] unsignedLongValue]];
}

@end
