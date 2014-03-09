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
- (CGFloat)windowAlphaControllerValue
// ウィンドウの透明度設定コントローラの値を返す
// ------------------------------------------------------
{
    return (CGFloat)[[[_transparencyController content] valueForKey:k_key_curWindowAlpha] doubleValue];
}


// ------------------------------------------------------
- (void)setWindowAlphaControllerDictionary:(NSMutableDictionary *)inDict
// ウィンドウの透明度設定コントローラに値をセット
// ------------------------------------------------------
{
    [_transparencyController setContent:inDict];
}


// ------------------------------------------------------
- (void)setWindowAlphaControllerValueDefault
// ウィンドウの透明度設定コントローラにデフォルト値をセット
// ------------------------------------------------------
{
    id theValues = [[NSUserDefaultsController sharedUserDefaultsController] values];

    [_transparencyController setContent:[NSMutableDictionary dictionaryWithObjectsAndKeys:
            [theValues valueForKey:k_key_windowAlpha], k_key_curWindowAlpha, 
            [theValues valueForKey:k_key_alphaOnlyTextView], k_key_curAlphaOnlyTextView, 
            nil]];
}


// ------------------------------------------------------
- (void)setTransparencyPanelControlsEnabledWithDecrement:(BOOL)inValue
// 透明度設定パネルのコントロール類の有効／無効を制御
// ------------------------------------------------------
{
    NSUInteger theNum = [[self documents] count];

    if (inValue) {
        theNum--;
    }
    if (theNum ==  0) {
        [self setWindowAlphaControllerValueDefault];
        [_windowAlphaSlider setEnabled:NO];
        [_windowAlphaField setTextColor:[NSColor disabledControlTextColor]];
        [_windowAlphaTextViewOnlyButton setEnabled:NO];
    } else if (theNum > 0) {
        [_windowAlphaSlider setEnabled:YES];
        [_windowAlphaField setTextColor:[NSColor controlTextColor]];
        [_windowAlphaTextViewOnlyButton setEnabled:YES];
        if (theNum > 1) {
            [_windowAlphaSetButton setEnabled:YES];
        } else {
            [_windowAlphaSetButton setEnabled:NO];
        }
    }
}


// ------------------------------------------------------
- (void)setGotoPanelControlsEnabledWithDecrement:(BOOL)inValue
// 文字／行移動パネルのコントロール類の有効／無効を制御
// ------------------------------------------------------
{
    NSUInteger theNum = [[self documents] count];

    if (inValue) {
        theNum--;
    }
    [_gotoSelectButton setEnabled:(theNum >  0)];
    [_gotoIndexField setEnabled:(theNum >  0)];
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
#pragma mark Protocol

//=======================================================
// NSNibAwaking Protocol
//
//=======================================================

// ------------------------------------------------------
- (BOOL)validateMenuItem:(NSMenuItem *)inMenuItem
// メニューの有効化／無効化を制御
// ------------------------------------------------------
{
    if ([inMenuItem action] == @selector(openLineSpacingPanel:)) {
        CEDocument *theCurDoc = [self currentDocument];
        if (theCurDoc == nil) {
            return NO;
        } else {
            CGFloat theLineSpacing = [theCurDoc lineSpacingInTextView];
            BOOL theState = ((theLineSpacing != 0.0) && (theLineSpacing != 0.25) && 
                    (theLineSpacing != 0.5) && (theLineSpacing != 0.75) && 
                    (theLineSpacing != 1.0) && (theLineSpacing != 1.25) && 
                    (theLineSpacing != 1.5) && (theLineSpacing != 1.75) && 
                    (theLineSpacing != 2.0));
            if (theState) {
                [inMenuItem setTitle:
                        [NSString stringWithFormat:NSLocalizedString(@"Custom [%.2f] ...",@""), theLineSpacing]];
            } else {
                [inMenuItem setTitle:NSLocalizedString(@"Custom...",@"")];
            }
            [inMenuItem setState:theState];
            return YES;
        }
        return ([self currentDocument] != nil);
    }

    return [super validateMenuItem:inMenuItem];
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
- (IBAction)openTransparencyPanel:(id)sender
// 透明度設定パネルを開く
// ------------------------------------------------------
{
    [self setTransparencyPanelControlsEnabledWithDecrement:NO];
    [[_windowAlphaSlider window] makeKeyAndOrderFront:nil];
}


// ------------------------------------------------------
- (IBAction)setAllWindowAlpha:(id)sender
// すべてのウィンドウの透明度を設定
// ------------------------------------------------------
{
    [[self documents] makeObjectsPerformSelector:@selector(setAlphaToWindowAndTextView)];
}


// ------------------------------------------------------
- (IBAction)openGotoPanel:(id)sender
// 文字／行移動パネルを開く
// ------------------------------------------------------
{
    NSWindow *thePanel = [_gotoIndexField window];

    if ([thePanel isKeyWindow]) {
        // 既に開いてキーになっているときは、文字／行移動をトグルに切り替える
        NSUserDefaults *theDefaults = [NSUserDefaults standardUserDefaults];
        NSInteger theNewSelect = ([_gotoCharLineMatrix selectedRow] == 0) ? 1 : 0;
        [theDefaults setInteger:theNewSelect forKey:k_key_gotoObjectMenuIndex];
    } else {
        [self setGotoPanelControlsEnabledWithDecrement:NO];
        [thePanel makeKeyAndOrderFront:sender];
        [thePanel makeFirstResponder:_gotoIndexField];
    }
}


// ------------------------------------------------------
- (IBAction)gotoCharacterOrLine:(id)sender
// 文字／行移動を実行
// ------------------------------------------------------
{
    NSArray *theArray = [[_gotoIndexField stringValue] componentsSeparatedByString:@":"];
    CEDocument *theCurDoc = [self currentDocument];

    if (([theArray count] > 0) && (theCurDoc)) {
        NSInteger theLocation = [theArray[0] integerValue];
        NSInteger theLength = ([theArray count] > 1) ? [theArray[1] integerValue] : 0;

        [theCurDoc gotoLocation:theLocation withLength:theLength];
    }
    [[_gotoIndexField window] orderOut:nil];
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


// ------------------------------------------------------
- (IBAction)openLineSpacingPanel:(id)sender
// カスタム行間設定パネルを開く
// ------------------------------------------------------
{
    CEDocument *theCurDoc = [self currentDocument];
    CGFloat theLineSpacing = [theCurDoc lineSpacingInTextView];

    if (theCurDoc) {
        [_lineSpacingField setStringValue:[NSString stringWithFormat:@"%.2f", theLineSpacing]];
        [[_lineSpacingField window] makeKeyAndOrderFront:nil];
    }
}


// ------------------------------------------------------
- (IBAction)closeLineSpacingPanel:(id)sender
// カスタム行間設定パネルを閉じる
// ------------------------------------------------------
{
    [[_lineSpacingField window] orderOut:nil];
}


// ------------------------------------------------------
- (IBAction)setCustomLineSpacing:(id)sender
// カスタム行間設定を実行
// ------------------------------------------------------
{
    CEDocument *theCurDoc = [self currentDocument];

    if (theCurDoc) {
        [theCurDoc setCustomLineSpacingToTextView:(CGFloat)[_lineSpacingField doubleValue]];
    }
    [self closeLineSpacingPanel:nil];
}



@end
