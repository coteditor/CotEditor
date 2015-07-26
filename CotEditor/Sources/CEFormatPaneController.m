/*
 ==============================================================================
 CEFormatPaneController
 
 CotEditor
 http://coteditor.com
 
 Created on 2014-04-18 by 1024jp
 encoding="UTF-8"
 ------------------------------------------------------------------------------
 
 © 2004-2007 nakamuxu
 © 2014-2015 1024jp
 
 This program is free software; you can redistribute it and/or modify it under
 the terms of the GNU General Public License as published by the Free Software
 Foundation; either version 2 of the License, or (at your option) any later
 version.
 
 This program is distributed in the hope that it will be useful, but WITHOUT
 ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS
 FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.
 
 You should have received a copy of the GNU General Public License along with
 this program; if not, write to the Free Software Foundation, Inc., 59 Temple
 Place - Suite 330, Boston, MA  02111-1307, USA.
 
 ==============================================================================
 */

@import AudioToolbox;
#import "CEFormatPaneController.h"
#import "CEEncodingManager.h"
#import "CESyntaxManager.h"
#import "CESyntaxMappingConflictsSheetController.h"
#import "CESyntaxEditSheetController.h"
#import "CEEncodingListSheetController.h"
#import "Constants.h"


@interface CEFormatPaneController () <NSTableViewDelegate>

@property (nonatomic, nullable, weak) IBOutlet NSPopUpButton *encodingMenuInOpen;
@property (nonatomic, nullable, weak) IBOutlet NSPopUpButton *encodingMenuInNew;

@property (nonatomic, nullable) IBOutlet NSArrayController *stylesController;
@property (nonatomic, nullable, weak) IBOutlet NSTableView *syntaxTableView;
@property (nonatomic, nullable, weak) IBOutlet NSPopUpButton *syntaxStylesDefaultPopup;
@property (nonatomic, nullable, weak) IBOutlet NSButton *syntaxStyleDeleteButton;

@end




#pragma mark -

@implementation CEFormatPaneController

#pragma mark Superclass Methods

// ------------------------------------------------------
/// clean up
- (void)dealloc
// ------------------------------------------------------
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}


// ------------------------------------------------------
/// setup UI
- (void)loadView
// ------------------------------------------------------
{
    [super loadView];
    
    [self setupSyntaxStyleMenus];
    
    // インストール済みシンタックス定義をダブルクリックしたら編集シートが出るようにセット
    [[self syntaxTableView] setDoubleAction:@selector(openSyntaxEditSheet:)];
    [[self syntaxTableView] setTarget:self];
    
    [self setupEncodingMenus];
    [[self encodingMenuInOpen] setAction:@selector(checkSelectedItemOfEncodingMenuInOpen:)];
    [[self encodingMenuInOpen] setTarget:self];
    
    
    // シンタックススタイルリスト更新の通知依頼
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(setupSyntaxStyleMenus)
                                                 name:CESyntaxListDidUpdateNotification
                                               object:nil];
    
    // エンコーディングリスト更新の通知依頼
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(setupEncodingMenus)
                                                 name:CEEncodingListDidUpdateNotification
                                               object:nil];
}



#pragma mark Protocol

//=======================================================
// NSMenuValidation Protocol
//=======================================================

// ------------------------------------------------------
/// メニューの有効化／無効化を制御
- (BOOL)validateMenuItem:(nonnull NSMenuItem *)menuItem
// ------------------------------------------------------
{
    // 拡張子重複エラー表示メニューの有効化を制御
    if ([menuItem action] == @selector(openSyntaxMappingConflictSheet:)) {
        return [[CESyntaxManager sharedManager] existsMappingConflict];
        
    // 書き出し/複製メニュー項目に現在選択されているスタイル名を追加
    } if ([menuItem action] == @selector(exportSyntaxStyle:)) {
        [menuItem setTitle:[NSString stringWithFormat:NSLocalizedString(@"Export “%@”…", nil), [self selectedStyleName]]];
        
    } if ([menuItem action] == @selector(openSyntaxEditSheet:) && [menuItem tag] == CECopySyntaxEdit) {
        [menuItem setTitle:[NSString stringWithFormat:NSLocalizedString(@"Duplicate “%@”…", nil), [self selectedStyleName]]];
        
    } if ([menuItem action] == @selector(revealSyntaxStyleInFinder:)) {
        [menuItem setTitle:[NSString stringWithFormat:NSLocalizedString(@"Reveal “%@” in Finder", nil), [self selectedStyleName]]];
        if (![[CESyntaxManager sharedManager] URLForUserStyle:[self selectedStyleName]]) {
            return NO;
        }
    }
    
    return YES;
}



#pragma mark Delegate

//=======================================================
// NSTableViewDelegate  < syntaxTableView
//=======================================================

// ------------------------------------------------------
/// テーブルの選択が変更された
- (void)tableViewSelectionDidChange:(nonnull NSNotification *)notification
// ------------------------------------------------------
{
    if ([notification object] == [self syntaxTableView]) {
        [self validateRemoveSyntaxStyleButton];
    }
}


#if MAC_OS_X_VERSION_MAX_ALLOWED >= 101100
// ------------------------------------------------------
/// set action on swiping theme name (on El Capitan and leter)
- (nonnull NSArray<NSTableViewRowAction *> *)tableView:(nonnull NSTableView *)tableView rowActionsForRow:(NSInteger)row edge:(NSTableRowActionEdge)edge
// ------------------------------------------------------
{
    if (edge == NSTableRowActionEdgeLeading) { return @[]; }
    
    NSString *swipedSyntaxName = [[self stylesController] arrangedObjects][row];
    BOOL isDeletable = ![[CESyntaxManager sharedManager] isBundledStyle:swipedSyntaxName];
    
    if (!isDeletable) { return @[]; }
    
    __weak typeof(self) weakSelf = self;
    return @[[NSTableViewRowAction rowActionWithStyle:NSTableViewRowActionStyleDestructive
                                                title:NSLocalizedString(@"Delete", nil)
                                              handler:^(NSTableViewRowAction *action, NSInteger row)
              {
                  typeof(weakSelf) strongSelf = weakSelf;
                  [strongSelf deleteSyntaxStyleWithName:swipedSyntaxName];
              }]];
}
#endif  // MAC_OS_X_VERSION_10_11



#pragma mark Action Messages

// ------------------------------------------------------
/// エンコーディングリスト編集シートを開き、閉じる
- (IBAction)openEncodingEditSheet:(nullable id)sender
// ------------------------------------------------------
{
    CEEncodingListSheetController *sheetController = [[CEEncodingListSheetController alloc] init];
    NSWindow *sheet = [sheetController window];
    
    // シートを表示してモーダルループに入る(閉じる命令は CEEncodingListSheetController内 で)
    [NSApp beginSheet:sheet modalForWindow:[[self view] window] modalDelegate:self didEndSelector:NULL contextInfo:NULL];
    [NSApp runModalForWindow:sheet];
}


// ------------------------------------------------------
/// カラーシンタックス編集シートを開き、閉じる
- (IBAction)openSyntaxEditSheet:(nullable id)sender
// ------------------------------------------------------
{
    CESyntaxEditSheetController *sheetController = [[CESyntaxEditSheetController alloc] initWithStyle:[self selectedStyleName]
                                                                                                 mode:[sender tag]];
    if (!sheetController) {
        return;
    }
    
    // シートウィンドウを表示
    // (閉じる命令は CESyntaxEditSheetController の endSheetWithReturnCode: で)
    NSWindow *sheet = [sheetController window];
    
    if (floor(NSAppKitVersionNumber) > NSAppKitVersionNumber10_8) { // on Mavericks or later
        [[[self view] window] beginSheet:sheet completionHandler:^(NSModalResponse returnCode) {
            [sheetController close];
        }];
        
    } else {
        // Mountain Lion 以下ではモーダルループに入る
        [NSApp beginSheet:sheet modalForWindow:[[self view] window] modalDelegate:self didEndSelector:NULL contextInfo:NULL];
        [NSApp runModalForWindow:sheet];
    }
}


// ------------------------------------------------------
/// シンタックススタイル削除ボタンが押された
- (IBAction)deleteSyntaxStyle:(nullable id)sender
// ------------------------------------------------------
{
    [self deleteSyntaxStyleWithName:[self selectedStyleName]];
}


// ------------------------------------------------------
/// シンタックスカラーリングスタイルインポートボタンが押された
- (IBAction)importSyntaxStyle:(nullable id)sender
// ------------------------------------------------------
{
    NSOpenPanel *openPanel = [NSOpenPanel openPanel];
    
    // OpenPanelをセットアップ(既定値を含む)、シートとして開く
    [openPanel setPrompt:NSLocalizedString(@"Import", nil)];
    [openPanel setResolvesAliases:YES];
    [openPanel setAllowsMultipleSelection:NO];
    [openPanel setCanChooseDirectories:NO];
    [openPanel setAllowedFileTypes:@[@"yaml", @"plist"]];
    
    __weak typeof(self) weakSelf = self;
    [openPanel beginSheetModalForWindow:[[self view] window] completionHandler:^(NSInteger result) {
        typeof(weakSelf) strongSelf = weakSelf;
        
        if (result == NSFileHandlingPanelCancelButton) return;
        
        NSURL *URL = [openPanel URL];
        NSString *styleName = [[URL lastPathComponent] stringByDeletingPathExtension];
        
        // 同名styleが既にあるときは、置換してもいいか確認
        if ([[[CESyntaxManager sharedManager] styleNames] containsObject:styleName]) {
            // オープンパネルを閉じる
            [openPanel orderOut:strongSelf];
            [[[strongSelf view] window] makeKeyAndOrderFront:strongSelf];
            
            NSAlert *alert = [[NSAlert alloc] init];
            [alert setMessageText:[NSString stringWithFormat:NSLocalizedString(@"The “%@” style already exists.", nil), styleName]];
            [alert setInformativeText:NSLocalizedString(@"Do you want to replace it?\nReplaced style cannot be restored.", nil)];
            [alert addButtonWithTitle:NSLocalizedString(@"Cancel", nil)];
            [alert addButtonWithTitle:NSLocalizedString(@"Replace", nil)];
            // 現行シート値を設定し、確認のためにセカンダリシートを開く
            NSBeep();
            [alert beginSheetModalForWindow:[[strongSelf view] window] modalDelegate:strongSelf
                             didEndSelector:@selector(secondarySheetDidEnd:returnCode:contextInfo:)
                                contextInfo:(__bridge_retained void *)(URL)];
        } else {
            // 重複するファイル名がないとき、インポート実行
            [strongSelf doImport:URL withCurrentSheetWindow:openPanel];
        }
    }];
}



// ------------------------------------------------------
/// シンタックスカラーリングスタイルエクスポートボタンが押された
- (IBAction)exportSyntaxStyle:(nullable id)sender
// ------------------------------------------------------
{
    NSString *selectedStyle = [self selectedStyleName];
    NSSavePanel *savePanel = [NSSavePanel savePanel];
    
    // SavePanelをセットアップ(既定値を含む)、シートとして開く
    [savePanel setCanCreateDirectories:YES];
    [savePanel setCanSelectHiddenExtension:YES];
    [savePanel setNameFieldLabel:NSLocalizedString(@"Export As:", nil)];
    [savePanel setNameFieldStringValue:selectedStyle];
    [savePanel setAllowedFileTypes:@[@"yaml"]];
    
    [savePanel beginSheetModalForWindow:[[self view] window] completionHandler:^(NSInteger result) {
        if (result == NSFileHandlingPanelOKButton) {
            [[CESyntaxManager sharedManager] exportStyle:selectedStyle toURL:[savePanel URL]];
        }
    }];
}


// ------------------------------------------------------
/// シンタックスカラーリングファイルをFinderで開く
- (IBAction)revealSyntaxStyleInFinder:(nullable id)sender
// ------------------------------------------------------
{
    NSURL *URL = [[CESyntaxManager sharedManager] URLForUserStyle:[self selectedStyleName]];
    
    if (URL) {
        [[NSWorkspace sharedWorkspace] activateFileViewerSelectingURLs:@[URL]];
    }
}


// ------------------------------------------------------
/// シンタックスマッピング重複エラー表示シートを開き、閉じる
- (IBAction)openSyntaxMappingConflictSheet:(nullable id)sender
// ------------------------------------------------------
{
    CESyntaxMappingConflictsSheetController *sheetController = [[CESyntaxMappingConflictsSheetController alloc] init];
    NSWindow *sheet = [sheetController window];
    
    // シートウィンドウを表示してモーダルループに入る
    // (閉じる命令は CESyntaxMappingConflictsSheetController の closeSheet: で)
    [NSApp beginSheet:sheet modalForWindow:[[self view] window] modalDelegate:self didEndSelector:NULL contextInfo:NULL];
    [NSApp runModalForWindow:sheet];
}


//------------------------------------------------------
/// 既存のファイルを開くエンコーディングが変更されたとき、選択項目をチェック
- (IBAction)checkSelectedItemOfEncodingMenuInOpen:(nullable id)sender
//------------------------------------------------------
{
    NSString *newTitle = [[[self encodingMenuInOpen] selectedItem] title];
    
    if ([newTitle isEqualToString:NSLocalizedString(@"Auto-Detect", nil)]) { return; }
    
    NSAlert *alert = [[NSAlert alloc] init];
    [alert setMessageText:[NSString stringWithFormat:NSLocalizedString(@"Are you sure you want to change to “%@”?", nil),
                           newTitle]];
    [alert setInformativeText:NSLocalizedString(@"The default “Auto-Detect” is recommended for most cases.", nil)];
    [alert addButtonWithTitle:NSLocalizedString(@"Revert to “Auto-Detect”", nil)];
    [alert addButtonWithTitle:[NSString stringWithFormat:NSLocalizedString(@"Change to “%@”", nil), newTitle]];
    
    NSBeep();
    [alert beginSheetModalForWindow:[[self view] window]
                      modalDelegate:self
                     didEndSelector:@selector(autoDetectAlertDidEnd:returnCode:contextInfo:)
                        contextInfo:NULL];
}



#pragma mark Private Methods

// ------------------------------------------------------
/// エンコーディング設定メニューを生成
- (void)setupEncodingMenus
// ------------------------------------------------------
{
    NSArray *menuItems = [[CEEncodingManager sharedManager] encodingMenuItems];
    
    [[self encodingMenuInOpen] removeAllItems];
    [[self encodingMenuInNew] removeAllItems];
    
    NSMenuItem *autoDetectItem = [[NSMenuItem alloc] initWithTitle:NSLocalizedString(@"Auto-Detect", nil)
                                                            action:nil keyEquivalent:@""];
    [autoDetectItem setTag:CEAutoDetectEncoding];
    [[[self encodingMenuInOpen] menu] addItem:autoDetectItem];
    [[[self encodingMenuInOpen] menu] addItem:[NSMenuItem separatorItem]];
    
    for (NSMenuItem *item in menuItems) {
        [[[self encodingMenuInOpen] menu] addItem:[item copy]];
        [[[self encodingMenuInNew] menu] addItem:[item copy]];
    }
    
    // (エンコーディング設定メニューはバインディングを使っているが、タグの選択がバインディングで行われた後に
    // メニューが追加／削除されるため、結果的に選択がうまく動かない。しかたないので、コードから選択している)
    [[self encodingMenuInOpen] selectItemWithTag:[[NSUserDefaults standardUserDefaults] integerForKey:CEDefaultEncodingInOpenKey]];
    [[self encodingMenuInNew] selectItemWithTag:[[NSUserDefaults standardUserDefaults] integerForKey:CEDefaultEncodingInNewKey]];
}


// ------------------------------------------------------
/// シンタックスカラーリングスタイルメニューを生成
- (void)setupSyntaxStyleMenus
// ------------------------------------------------------
{
    NSArray *styleNames = [[CESyntaxManager sharedManager] styleNames];
    NSString *noneStyle = NSLocalizedString(@"None", nil);
    
    // インストール済みスタイルリストの更新
    [[self stylesController] setContent:styleNames];
    [self validateRemoveSyntaxStyleButton];
    
    // デフォルトスタイルメニューの更新
    [[self syntaxStylesDefaultPopup] removeAllItems];
    [[self syntaxStylesDefaultPopup] addItemWithTitle:noneStyle];
    [[[self syntaxStylesDefaultPopup] menu] addItem:[NSMenuItem separatorItem]];
    [[self syntaxStylesDefaultPopup] addItemsWithTitles:styleNames];
    
    // (デフォルトシンタックスカラーリングスタイル指定ポップアップメニューはバインディングを使っているが、
    // タグの選択がバインディングで行われた後にメニューが追加／削除されるため、結果的に選択がうまく動かない。
    // しかたないので、コードから選択している)
    NSString *selectedStyle = [[NSUserDefaults standardUserDefaults] stringForKey:CEDefaultSyntaxStyleKey];
    selectedStyle = [styleNames containsObject:selectedStyle] ? selectedStyle : noneStyle;
    [[self syntaxStylesDefaultPopup] selectItemWithTitle:selectedStyle];
}


// ------------------------------------------------------
/// 現在選択されているスタイル名を返す
- (nullable NSString *)selectedStyleName
// ------------------------------------------------------
{
    return [[[self stylesController] selectedObjects] firstObject];
}


// ------------------------------------------------------
/// シンタックススタイル削除ボタンを制御する
- (void)validateRemoveSyntaxStyleButton
// ------------------------------------------------------
{
    BOOL isDeletable = ![[CESyntaxManager sharedManager] isBundledStyle:[self selectedStyleName]];
    
    [[self syntaxStyleDeleteButton] setEnabled:isDeletable];
}


// ------------------------------------------------------
/// try to delete given syntax style
- (void)deleteSyntaxStyleWithName:(nonnull NSString *)styleName
// ------------------------------------------------------
{
    if (![[CESyntaxManager sharedManager] URLForUserStyle:styleName]) { return; }
    
    NSAlert *alert = [[NSAlert alloc] init];
    [alert setMessageText:[NSString stringWithFormat:NSLocalizedString(@"Delete the syntax style “%@”?", nil), styleName]];
    [alert setInformativeText:NSLocalizedString(@"Deleted style cannot be restored.", nil)];
    [alert addButtonWithTitle:NSLocalizedString(@"Cancel", nil)];
    [alert addButtonWithTitle:NSLocalizedString(@"Delete", nil)];
    
    [alert beginSheetModalForWindow:[[self view] window]
                      modalDelegate:self
                     didEndSelector:@selector(deleteStyleAlertDidEnd:returnCode:contextInfo:)
                        contextInfo:(__bridge_retained void *)styleName];
}


// ------------------------------------------------------
/// 既存ファイルを開くときのエンコーディングメニューで自動認識以外が選択されたときの警告シートが閉じる直前
- (void)autoDetectAlertDidEnd:(nonnull NSAlert *)sheet returnCode:(NSInteger)returnCode contextInfo:(nullable void *)contextInfo
// ------------------------------------------------------
{
    if (returnCode == NSAlertFirstButtonReturn) { // = revert to Auto-Detect
        [[NSUserDefaults standardUserDefaults] setObject:@(CEAutoDetectEncoding)
                                                  forKey:CEDefaultEncodingInOpenKey];
    }
}


// ------------------------------------------------------
/// styleインポート実行
- (void)doImport:(nonnull NSURL *)fileURL withCurrentSheetWindow:(nullable NSWindow *)window
// ------------------------------------------------------
{
    if (![[CESyntaxManager sharedManager] importStyleFromURL:fileURL]) {
        // インポートできなかったときは、セカンダリシートを閉じ、メッセージシートを表示
        [window orderOut:self];
        [[[self view] window] makeKeyAndOrderFront:self];
        NSAlert *alert = [[NSAlert alloc] init];
        [alert setMessageText:NSLocalizedString(@"Error occured.", nil)];
        [alert setInformativeText:[NSString stringWithFormat:NSLocalizedString(@"Sorry, could not import “%@”.", nil), [fileURL lastPathComponent]]];
        
        NSBeep();
        [alert beginSheetModalForWindow:[[self view] window] modalDelegate:self didEndSelector:NULL contextInfo:NULL];
    }
}


// ------------------------------------------------------
/// style削除確認シートが閉じる直前
- (void)deleteStyleAlertDidEnd:(nonnull NSAlert *)alert returnCode:(NSInteger)returnCode contextInfo:(nullable void *)contextInfo
// ------------------------------------------------------
{
    if (returnCode != NSAlertSecondButtonReturn) {  // != Delete
        return;
    }
    
    NSString *styleName = (__bridge_transfer NSString *)contextInfo;
    
    if ([[CESyntaxManager sharedManager] removeStyleFileWithStyleName:styleName]) {
        AudioServicesPlaySystemSound(CESystemSoundID_MoveToTrash);
    } else {
        // 削除できなければ、その旨をユーザに通知
        [[alert window] orderOut:self];
        [[[self view] window] makeKeyAndOrderFront:self];
        NSAlert *alert = [[NSAlert alloc] init];
        [alert setMessageText:NSLocalizedString(@"Error occured.", nil)];
        [alert setInformativeText:[NSString stringWithFormat:NSLocalizedString(@"Sorry, could not delete “%@”.", nil), styleName]];
        NSBeep();
        [alert beginSheetModalForWindow:[[self view] window] modalDelegate:self didEndSelector:NULL contextInfo:NULL];
    }
}


// ------------------------------------------------------
/// セカンダリシートが閉じる直前
- (void)secondarySheetDidEnd:(nonnull NSAlert *)alert returnCode:(NSInteger)returnCode contextInfo:(nullable void *)contextInfo
// ------------------------------------------------------
{
    if (returnCode == NSAlertSecondButtonReturn) { // = Replace
        [self doImport:CFBridgingRelease(contextInfo) withCurrentSheetWindow:[alert window]];
    }
}

@end
