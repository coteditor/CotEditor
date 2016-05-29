/*
 
 CEFormatPaneController.m
 
 CotEditor
 http://coteditor.com
 
 Created by 1024jp on 2014-04-18.

 ------------------------------------------------------------------------------
 
 © 2004-2007 nakamuxu
 © 2014-2016 1024jp
 
 Licensed under the Apache License, Version 2.0 (the "License");
 you may not use this file except in compliance with the License.
 You may obtain a copy of the License at
 
 http://www.apache.org/licenses/LICENSE-2.0
 
 Unless required by applicable law or agreed to in writing, software
 distributed under the License is distributed on an "AS IS" BASIS,
 WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 See the License for the specific language governing permissions and
 limitations under the License.
 
 */

@import AudioToolbox;
#import "CEFormatPaneController.h"
#import "CEEncodingManager.h"
#import "CESyntaxManager.h"
#import "CESyntaxMappingConflictsSheetController.h"
#import "CESyntaxEditSheetController.h"
#import "CEEncodingListSheetController.h"
#import "CEDefaults.h"
#import "CEEncodings.h"
#import "Constants.h"

#import "NSString+CEEncoding.h"


// constants
NSString *_Nonnull const StyleNameKey = @"name";
NSString *_Nonnull const StyleStateKey = @"state";
NSString *_Nonnull const IsUTF8WithBOM = @"UTF-8 with BOM";


@interface CEFormatPaneController () <NSTableViewDelegate>

@property (nonatomic, nullable, weak) IBOutlet NSPopUpButton *encodingMenuInOpen;
@property (nonatomic, nullable, weak) IBOutlet NSPopUpButton *encodingMenuInNew;

@property (nonatomic, nullable) IBOutlet NSArrayController *stylesController;
@property (nonatomic, nullable, weak) IBOutlet NSTableView *syntaxTableView;
@property (nonatomic, nullable) IBOutlet NSMenu *syntaxTableMenu;
@property (nonatomic, nullable, weak) IBOutlet NSPopUpButton *syntaxStylesDefaultPopup;
@property (nonatomic, nullable, weak) IBOutlet NSButton *syntaxStyleDeleteButton;

@end




#pragma mark -

@implementation CEFormatPaneController

#pragma mark Superclass Methods

// ------------------------------------------------------
/// nib name
- (nullable NSString *)nibName
// ------------------------------------------------------
{
    return @"FormatPane";
}


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
    }
    
    BOOL isContextualMenu = ([menuItem menu] == [self syntaxTableMenu]);
    
    NSString *representedStyleName = [self selectedStyleName];
    if (isContextualMenu) {
        NSInteger clickedrow = [[self syntaxTableView] clickedRow];
        
        if (clickedrow == -1) {  // clicked blank area
            representedStyleName = nil;
        } else {
            representedStyleName = [[self stylesController] arrangedObjects][clickedrow][StyleNameKey];
        }
    }
    // set style name as representedObject to menu items whose action is related to syntax style
    if ([NSStringFromSelector([menuItem action]) containsString:@"Syntax"]) {
        [menuItem setRepresentedObject:representedStyleName];
    }
    
    BOOL isCustomized = NO;
    BOOL isBundled = NO;
    if (representedStyleName) {
        isBundled = [[CESyntaxManager sharedManager] isBundledStyle:representedStyleName cutomized:nil];
    }
    
    // 書き出し/複製メニュー項目に現在選択されているスタイル名を追加
    if ([menuItem action] == @selector(exportSyntaxStyle:)) {
        if (!isContextualMenu) {
            [menuItem setTitle:[NSString stringWithFormat:NSLocalizedString(@"Export “%@”…", nil), representedStyleName]];
        }
        
    } else if ([menuItem action] == @selector(openSyntaxEditSheet:) && [menuItem tag] == CECopySyntaxEdit) {
        if (!isContextualMenu) {
            [menuItem setTitle:[NSString stringWithFormat:NSLocalizedString(@"Duplicate “%@”…", nil), representedStyleName]];
        }
        
    } else if ([menuItem action] == @selector(revealSyntaxStyleInFinder:)) {
        if (!isContextualMenu) {
            [menuItem setTitle:[NSString stringWithFormat:NSLocalizedString(@"Reveal “%@” in Finder", nil), representedStyleName]];
        }
        return representedStyleName ? ([[CESyntaxManager sharedManager] URLForUserStyle:representedStyleName] != nil) : NO;
        
    } else if ([menuItem action] == @selector(deleteSyntaxStyle:)) {
        [menuItem setHidden:(isBundled || !representedStyleName)];
        
    } else if ([menuItem action] == @selector(restoreSyntaxStyle:)) {
        if (!isContextualMenu) {
            [menuItem setTitle:[NSString stringWithFormat:NSLocalizedString(@"Restore “%@”", nil), representedStyleName]];
        }
        [menuItem setHidden:(!isBundled || !representedStyleName)];
        return isCustomized;
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


// ------------------------------------------------------
/// set action on swiping theme name (on El Capitan and leter)
- (nonnull NSArray<NSTableViewRowAction *> *)tableView:(nonnull NSTableView *)tableView rowActionsForRow:(NSInteger)row edge:(NSTableRowActionEdge)edge
// ------------------------------------------------------
{
    if (edge == NSTableRowActionEdgeLeading) { return @[]; }
    
    NSString *swipedSyntaxName = [[self stylesController] arrangedObjects][row][StyleNameKey];
    BOOL isCustomized;
    BOOL isBundled = [[CESyntaxManager sharedManager] isBundledStyle:swipedSyntaxName cutomized:&isCustomized];
    
    // do nothing on undeletable style
    if (isBundled && !isCustomized) { return @[]; }
    
    if (isCustomized) {
        // Restore
        return @[[NSTableViewRowAction rowActionWithStyle:NSTableViewRowActionStyleRegular
                                                    title:NSLocalizedString(@"Restore", nil)
                                                  handler:^(NSTableViewRowAction *action, NSInteger row)
                  {
                      [self restoreSyntaxStyleWithName:swipedSyntaxName];
                      
                      // finish swiped mode anyway
                      [[self syntaxTableView] setRowActionsVisible:NO];
                  }]];
    } else {
        // Delete
        return @[[NSTableViewRowAction rowActionWithStyle:NSTableViewRowActionStyleDestructive
                                                    title:NSLocalizedString(@"Delete", nil)
                                                  handler:^(NSTableViewRowAction *action, NSInteger row)
                  {
                      [self deleteSyntaxStyleWithName:swipedSyntaxName];
                  }]];
    }
}



#pragma mark Action Messages

// ------------------------------------------------------
/// save also availability of UTF-8 BOM
- (IBAction)changeEncodingInNewDocument:(nullable id)sender
// ------------------------------------------------------
{
    BOOL withUTF8BOM = [[[[self encodingMenuInNew] selectedItem] representedObject] isEqualToString:IsUTF8WithBOM];
    
    [[NSUserDefaults standardUserDefaults] setBool:withUTF8BOM forKey:CEDefaultSaveUTF8BOMKey];
}


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
    NSString *styleName = ([sender isKindOfClass:[NSMenuItem class]]) ? [sender representedObject] : [self selectedStyleName];
    
    CESyntaxEditSheetController *sheetController = [[CESyntaxEditSheetController alloc] initWithStyle:styleName
                                                                                                 mode:[sender tag]];
    if (!sheetController) { return; }
    
    // show editor as sheet
    [[[self view] window] beginSheet:[sheetController window] completionHandler:^(NSModalResponse returnCode) {
        [sheetController close];
    }];
}


// ------------------------------------------------------
/// シンタックススタイル削除ボタンが押された
- (IBAction)deleteSyntaxStyle:(nullable id)sender
// ------------------------------------------------------
{
    NSString *styleName = ([sender isKindOfClass:[NSMenuItem class]]) ? [sender representedObject] : [self selectedStyleName];
    
    [self deleteSyntaxStyleWithName:styleName];
}


// ------------------------------------------------------
/// シンタックススタイルリストアボタンが押された
- (IBAction)restoreSyntaxStyle:(nullable id)sender
// ------------------------------------------------------
{
    NSString *styleName = ([sender isKindOfClass:[NSMenuItem class]]) ? [sender representedObject] : [self selectedStyleName];
    
    [self restoreSyntaxStyleWithName:styleName];
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
        typeof(self) self = weakSelf;  // strong self
        if (!self) { return; }
        
        if (result == NSFileHandlingPanelCancelButton) { return; }
        
        NSURL *URL = [openPanel URL];
        NSString *styleName = [[URL lastPathComponent] stringByDeletingPathExtension];
        
        // 同名styleが既にあるときは、置換してもいいか確認
        if ([[[CESyntaxManager sharedManager] styleNames] containsObject:styleName]) {
            // オープンパネルを閉じる
            [openPanel orderOut:self];
            [[[self view] window] makeKeyAndOrderFront:self];
            
            NSAlert *alert = [[NSAlert alloc] init];
            [alert setMessageText:[NSString stringWithFormat:NSLocalizedString(@"The “%@” style already exists.", nil), styleName]];
            [alert setInformativeText:NSLocalizedString(@"Do you want to replace it?\nReplaced style can’t be restored.", nil)];
            [alert addButtonWithTitle:NSLocalizedString(@"Cancel", nil)];
            [alert addButtonWithTitle:NSLocalizedString(@"Replace", nil)];
            // 現行シート値を設定し、確認のためにセカンダリシートを開く
            NSBeep();
            
            __weak typeof(self) weakSelf = self;
            [alert beginSheetModalForWindow:[[self view] window] completionHandler:^(NSInteger returnCode)
             {
                 typeof(self) self = weakSelf;  // strong self
                 
                 if (returnCode == NSAlertSecondButtonReturn) { // = Replace
                     [self doImport:URL withCurrentSheetWindow:[alert window]];
                 }
             }];
            
        } else {
            // 重複するファイル名がないとき、インポート実行
            [self doImport:URL withCurrentSheetWindow:openPanel];
        }
    }];
}


// ------------------------------------------------------
/// シンタックスカラーリングスタイルエクスポートボタンが押された
- (IBAction)exportSyntaxStyle:(nullable id)sender
// ------------------------------------------------------
{
    NSString *styleName = ([sender isKindOfClass:[NSMenuItem class]]) ? [sender representedObject] : [self selectedStyleName];
    
    NSSavePanel *savePanel = [NSSavePanel savePanel];
    
    // SavePanelをセットアップ(既定値を含む)、シートとして開く
    [savePanel setCanCreateDirectories:YES];
    [savePanel setCanSelectHiddenExtension:YES];
    [savePanel setNameFieldLabel:NSLocalizedString(@"Export As:", nil)];
    [savePanel setNameFieldStringValue:styleName];
    [savePanel setAllowedFileTypes:@[@"yaml"]];
    
    [savePanel beginSheetModalForWindow:[[self view] window] completionHandler:^(NSInteger result) {
        if (result == NSFileHandlingPanelOKButton) {
            [[CESyntaxManager sharedManager] exportStyle:styleName toURL:[savePanel URL]];
        }
    }];
}


// ------------------------------------------------------
/// シンタックスカラーリングファイルをFinderで開く
- (IBAction)revealSyntaxStyleInFinder:(nullable id)sender
// ------------------------------------------------------
{
    NSString *styleName = ([sender isKindOfClass:[NSMenuItem class]]) ? [sender representedObject] : [self selectedStyleName];
    
    NSURL *URL = [[CESyntaxManager sharedManager] URLForUserStyle:styleName];
    
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
    
    // シートウィンドウを表示してモーダルループに入る
    // (閉じる命令は CESyntaxMappingConflictsSheetController の closeSheet: で)
    [NSApp beginSheet:[sheetController window] modalForWindow:[[self view] window] modalDelegate:self didEndSelector:NULL contextInfo:NULL];
    [NSApp runModalForWindow:[sheetController window]];
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
    [alert beginSheetModalForWindow:[[self view] window] completionHandler:^(NSInteger returnCode)
     {
         if (returnCode == NSAlertFirstButtonReturn) { // = revert to Auto-Detect
             [[NSUserDefaults standardUserDefaults] setObject:@(CEAutoDetectEncoding)
                                                       forKey:CEDefaultEncodingInOpenKey];
         }
     }];
}



#pragma mark Private Methods

// ------------------------------------------------------
/// エンコーディング設定メニューを生成
- (void)setupEncodingMenus
// ------------------------------------------------------
{
    NSArray<NSMenuItem *> *menuItems = [[CEEncodingManager sharedManager] encodingMenuItems];
    
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
        
        // add "UTF-8 with BOM" item only to "In New" menu
        if ([item tag] == NSUTF8StringEncoding) {
            NSMenuItem *bomItem = [[NSMenuItem alloc] initWithTitle:[NSString localizedNameOfUTF8EncodingWithBOM]
                                                             action:NULL
                                                      keyEquivalent:@""];
            [bomItem setTag:NSUTF8StringEncoding];
            [bomItem setRepresentedObject:IsUTF8WithBOM];
            [[[self encodingMenuInNew] menu] addItem:bomItem];
        }
    }
    
    // (エンコーディング設定メニューはバインディングを使っているが、タグの選択がバインディングで行われた後に
    // メニューが追加／削除されるため、結果的に選択がうまく動かない。しかたないので、コードから選択している)
    [[self encodingMenuInOpen] selectItemWithTag:[[NSUserDefaults standardUserDefaults] integerForKey:CEDefaultEncodingInOpenKey]];
    
    NSStringEncoding encodingInNew = [[NSUserDefaults standardUserDefaults] integerForKey:CEDefaultEncodingInNewKey];
    if (encodingInNew == NSUTF8StringEncoding) {
        NSUInteger index = [[self encodingMenuInNew] indexOfItemWithRepresentedObject:IsUTF8WithBOM];
        
        // -> The normal "UTF-8" is just above "UTF-8 with BOM".
        if (![[NSUserDefaults standardUserDefaults] boolForKey:CEDefaultSaveUTF8BOMKey]) {
            index--;
        }
        [[self encodingMenuInNew] selectItemAtIndex:index];
        
    } else {
        [[self encodingMenuInNew] selectItemWithTag:encodingInNew];
    }
}


// ------------------------------------------------------
/// シンタックスカラーリングスタイルメニューを生成
- (void)setupSyntaxStyleMenus
// ------------------------------------------------------
{
    NSArray<NSString *> *styleNames = [[CESyntaxManager sharedManager] styleNames];
    NSString *noneStyle = NSLocalizedString(@"None", nil);
    
    NSMutableArray<NSDictionary *> *hoge = [NSMutableArray array];
    for (NSString *styleName in styleNames) {
        BOOL isCutomized;
        BOOL isBundled = [[CESyntaxManager sharedManager] isBundledStyle:styleName cutomized:&isCutomized];
        
        [hoge addObject:@{StyleNameKey: styleName,
                          StyleStateKey: @(!isBundled || isCutomized)}];
    }
    
    // インストール済みスタイルリストの更新
    [[self stylesController] setContent:hoge];
    [self validateRemoveSyntaxStyleButton];
    [[self syntaxTableView] reloadData];
    
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
    return [[[self stylesController] selectedObjects] firstObject][StyleNameKey];
}


// ------------------------------------------------------
/// シンタックススタイル削除ボタンを制御する
- (void)validateRemoveSyntaxStyleButton
// ------------------------------------------------------
{
    BOOL isDeletable = [self selectedStyleName] ? ![[CESyntaxManager sharedManager] isBundledStyle:[self selectedStyleName] cutomized:nil] : NO;
    
    [[self syntaxStyleDeleteButton] setEnabled:isDeletable];
}


// ------------------------------------------------------
/// try to delete given syntax style
- (void)deleteSyntaxStyleWithName:(nonnull NSString *)styleName
// ------------------------------------------------------
{
    NSAlert *alert = [[NSAlert alloc] init];
    [alert setMessageText:[NSString stringWithFormat:NSLocalizedString(@"Are you sure you want to delete “%@” syntax style?", nil), styleName]];
    [alert setInformativeText:NSLocalizedString(@"This action cannot be undone.", nil)];
    [alert addButtonWithTitle:NSLocalizedString(@"Cancel", nil)];
    [alert addButtonWithTitle:NSLocalizedString(@"Delete", nil)];
    
    NSWindow *window = [[self view] window];
    [alert beginSheetModalForWindow:window completionHandler:^(NSInteger returnCode)
     {
         if (returnCode != NSAlertSecondButtonReturn) { return; }  // != Delete
         
         if ([[CESyntaxManager sharedManager] removeStyleFileWithStyleName:styleName]) {
             AudioServicesPlaySystemSound(CESystemSoundID_MoveToTrash);
             
         } else {
             // 削除できなければ、その旨をユーザに通知
             [[alert window] orderOut:nil];
             [window makeKeyAndOrderFront:nil];
             NSAlert *alert = [[NSAlert alloc] init];
             [alert setMessageText:NSLocalizedString(@"An error occurred.", nil)];
             [alert setInformativeText:[NSString stringWithFormat:NSLocalizedString(@"The style “%@” couldn’t be deleted.", nil), styleName]];
             NSBeep();
             [alert beginSheetModalForWindow:window completionHandler:nil];
         }
     }];
}


// ------------------------------------------------------
/// try to delete given syntax style
- (void)restoreSyntaxStyleWithName:(nonnull NSString *)styleName
// ------------------------------------------------------
{
    if (![[CESyntaxManager sharedManager] URLForUserStyle:styleName]) { return; }
    
    [[CESyntaxManager sharedManager] restoreStyleFileWithStyleName:styleName];
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
        [alert setMessageText:NSLocalizedString(@"An error occurred.", nil)];
        [alert setInformativeText:[NSString stringWithFormat:NSLocalizedString(@"The style “%@” couldn’t be imported.", nil), [fileURL lastPathComponent]]];
        
        NSBeep();
        [alert beginSheetModalForWindow:[[self view] window] completionHandler:nil];
    }
}

@end
