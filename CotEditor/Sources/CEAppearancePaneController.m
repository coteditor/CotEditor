/*
 
 CEAppearancePaneController.m
 
 CotEditor
 http://coteditor.com
 
 Created by 1024jp on 2014-04-18.

 ------------------------------------------------------------------------------
 
 © 2004-2007 nakamuxu
 © 2014-2015 1024jp
 
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
#import "CEAppearancePaneController.h"
#import "CEThemeViewController.h"
#import "CEThemeManager.h"
#import "Constants.h"


@interface CEAppearancePaneController () <NSTableViewDelegate, NSTableViewDataSource, CEThemeViewControllerDelegate>

@property (nonatomic, nullable, weak) IBOutlet NSTextField *fontField;
@property (nonatomic, nullable, weak) IBOutlet NSTableView *themeTableView;
@property (nonatomic, nullable, weak) IBOutlet NSBox *box;

@property (nonatomic, nullable) CEThemeViewController *themeViewController;
@property (nonatomic, nullable, copy) NSArray<NSString *> *themeNames;
@property (nonatomic, getter=isBundled) BOOL bundled;

@end




#pragma mark -

@implementation CEAppearancePaneController

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
    
    [self setFontFamilyNameAndSize];
    
    [self setupThemeList];
    
    // register droppable types
    [[self themeTableView] registerForDraggedTypes:@[(NSString *)kUTTypeFileURL]];
    
    // デフォルトテーマを選択
    NSArray<NSString *> *themeNames = [[self themeNames] copy];
    NSInteger row = [themeNames indexOfObject:[[NSUserDefaults standardUserDefaults] stringForKey:CEDefaultThemeKey]];
    [[self themeTableView] selectRowIndexes:[NSIndexSet indexSetWithIndex:row] byExtendingSelection:NO];
    [[self themeTableView] setAllowsEmptySelection:NO];
    
    // テーマのラインナップが変更されたらテーブルビューを更新
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(setupThemeList)
                                                 name:CEThemeListDidUpdateNotification
                                               object:nil];
}



#pragma mark Protocol

//=======================================================
// NSMenuValidation Protocol
//=======================================================

// ------------------------------------------------------
/// メニュー項目の有効化／無効化を制御
- (BOOL)validateMenuItem:(nonnull NSMenuItem *)menuItem
// ------------------------------------------------------
{
    BOOL isCustomized;
    BOOL isBundled = [[CEThemeManager sharedManager] isBundledTheme:[self selectedTheme] cutomized:&isCustomized];
    
    if ([menuItem action] == @selector(exportTheme:)) {
        [menuItem setTitle:[NSString stringWithFormat:NSLocalizedString(@"Export “%@”…", nil), [self selectedTheme]]];
        return (!isBundled || isCustomized);
        
    } else if ([menuItem action] == @selector(duplicateTheme:)) {
        [menuItem setTitle:[NSString stringWithFormat:NSLocalizedString(@"Duplicate “%@”", nil), [self selectedTheme]]];
    } else if ([menuItem action] == @selector(restoreTheme:)) {
        [menuItem setTitle:[NSString stringWithFormat:NSLocalizedString(@"Restore “%@”", nil), [self selectedTheme]]];
        [menuItem setHidden:!isBundled];
        return isCustomized;
    }
    
    return YES;
}



#pragma mark Data Source

//=======================================================
// NSTableDataSource Protocol  < themeTableView
//=======================================================

// ------------------------------------------------------
/// テーブルの行数を返す
- (NSInteger)numberOfRowsInTableView:(nonnull NSTableView *)aTableView
// ------------------------------------------------------
{
    return [[self themeNames] count];
}


// ------------------------------------------------------
/// テーブルのセルの内容を返す
- (nullable id)tableView:(nonnull NSTableView *)aTableView objectValueForTableColumn:(nullable NSTableColumn *)aTableColumn row:(NSInteger)rowIndex
// ------------------------------------------------------
{
    return [self themeNames][rowIndex];
}


// ------------------------------------------------------
/// validate when dragged items come to tableView
- (NSDragOperation)tableView:(nonnull NSTableView *)tableView validateDrop:(nonnull id<NSDraggingInfo>)info proposedRow:(NSInteger)row proposedDropOperation:(NSTableViewDropOperation)dropOperation
// ------------------------------------------------------
{
    // get file URLs from pasteboard
    NSPasteboard *pboard = [info draggingPasteboard];
    NSArray<NSURL *> *URLs = [pboard readObjectsForClasses:@[[NSURL class]]
                                                   options:@{NSPasteboardURLReadingFileURLsOnlyKey: @YES,
                                                             NSPasteboardURLReadingContentsConformToTypesKey: @[CEUTTypeTheme]}];
    
    if ([URLs count] == 0) { return NSDragOperationNone; }
    
    // highlight text view itself
    [tableView setDropRow:-1 dropOperation:NSTableViewDropOn];
    
    // show number of theme files
    [info setNumberOfValidItemsForDrop:[URLs count]];
    
    return NSDragOperationCopy;
}


// ------------------------------------------------------
/// check acceptability of dragged items and insert them to table
- (BOOL)tableView:(nonnull NSTableView *)tableView acceptDrop:(nonnull id<NSDraggingInfo>)info row:(NSInteger)row dropOperation:(NSTableViewDropOperation)dropOperation
// ------------------------------------------------------
{
    [info enumerateDraggingItemsWithOptions:0 forView:tableView classes:@[[NSURL class]]
                              searchOptions:@{NSPasteboardURLReadingFileURLsOnlyKey: @YES,
                                              NSPasteboardURLReadingContentsConformToTypesKey: @[CEUTTypeTheme]}
                                 usingBlock:^(NSDraggingItem *draggingItem, NSInteger idx, BOOL *stop)
     {
         NSURL *fileURL = [draggingItem item];
         
         [self importThemeWithURL:fileURL];
     }];
    
    return YES;
}



#pragma mark Delegate

//=======================================================
// CEThemeViewControllerDelegate
//=======================================================

// ------------------------------------------------------
/// テーマが編集された
- (void)didUpdateTheme:(NSMutableDictionary<NSString *, NSMutableDictionary<NSString *, id> *> *)theme
// ------------------------------------------------------
{
    // save
    [[CEThemeManager sharedManager] saveTheme:theme name:[self selectedTheme] completionHandler:nil];
}


//=======================================================
// NSTableViewDelegate  < themeTableView
//=======================================================

// ------------------------------------------------------
/// テーブルの選択が変更された
- (void)tableViewSelectionDidChange:(nonnull NSNotification *)notification
// ------------------------------------------------------
{
    if ([notification object] == [self themeTableView]) {
        BOOL isBundled;
        NSMutableDictionary<NSString *, NSMutableDictionary<NSString *, id> *> *themeDict = [[CEThemeManager sharedManager] archivedTheme:[self selectedTheme] isBundled:&isBundled];
        
        // デフォルトテーマ設定の更新（初回の選択変更はまだ設定が反映されていない時点で呼び出されるので保存しない）
        if ([self themeViewController]) {
            NSString *oldThemeName = [[NSUserDefaults standardUserDefaults] stringForKey:CEDefaultThemeKey];
            
            [[NSUserDefaults standardUserDefaults] setObject:[self selectedTheme] forKey:CEDefaultThemeKey];
            
            // 現在開いているウインドウのテーマも変更
            [[NSNotificationCenter defaultCenter] postNotificationName:CEThemeDidUpdateNotification
                                                                object:self
                                                              userInfo:@{CEOldNameKey: oldThemeName,
                                                                         CENewNameKey: [self selectedTheme]}];
        }
        
        [self setThemeViewController:[[CEThemeViewController alloc] init]];
        [[self themeViewController] setDelegate:self];
        [[self themeViewController] setRepresentedObject:themeDict];
        [[self themeViewController] setBundled:isBundled];
        [[self box] setContentView:[[self themeViewController] view]];
        
        [self setBundled:isBundled];
    }
}


// ------------------------------------------------------
/// テーブルセルが編集可能かを設定する
- (void)tableView:(nonnull NSTableView *)tableView didAddRowView:(nonnull NSTableRowView *)rowView forRow:(NSInteger)row
// ------------------------------------------------------
{
    NSTableCellView *view = [tableView viewAtColumn:0 row:row makeIfNecessary:NO];
    NSString *themeName = [self themeNames][row];
    BOOL editable = ![[CEThemeManager sharedManager] isBundledTheme:themeName cutomized:nil];
    
    [[view textField] setEditable:editable];
}


// ------------------------------------------------------
/// テーマ名が編集された
- (BOOL)control:(nonnull NSControl *)control textShouldEndEditing:(nonnull NSText *)fieldEditor
// ------------------------------------------------------
{
    NSString *oldName = [self selectedTheme];
    NSString *newName = [fieldEditor string];
    NSError *error = nil;
    
    // 空の場合は終わる（自動的に元の名前がセットされる）
    if ([newName isEqualToString:@""]) {
        return YES;
    }
    
    BOOL success = [[CEThemeManager sharedManager] renameTheme:oldName toName:newName error:&error];
    
    if (error) {
        // revert name
        [fieldEditor setString:oldName];
        // show alert
        NSAlert *alert = [NSAlert alertWithError:error];
        [alert beginSheetModalForWindow:[[self view] window] modalDelegate:nil didEndSelector:NULL contextInfo:NULL];
    }
    
    return success;
}


#if MAC_OS_X_VERSION_MAX_ALLOWED >= 101100
// ------------------------------------------------------
/// set action on swiping theme name (on El Capitan and leter)
- (nonnull NSArray<NSTableViewRowAction *> *)tableView:(nonnull NSTableView *)tableView rowActionsForRow:(NSInteger)row edge:(NSTableRowActionEdge)edge
// ------------------------------------------------------
{
    if (edge == NSTableRowActionEdgeLeading) { return @[]; }
    
    NSString *swipedThemeName = [self themeNames][row];
    
    // check whether theme can be deleted
    BOOL isCustomized;
    BOOL isBundled = [[CEThemeManager sharedManager] isBundledTheme:swipedThemeName cutomized:&isCustomized];
    
    // do nothing on undeletable theme
    if (isBundled && !isCustomized) { return @[]; }
    
    if (isCustomized) {
        // Restore
        return @[[NSTableViewRowAction rowActionWithStyle:NSTableViewRowActionStyleRegular
                                                    title:NSLocalizedString(@"Restore", nil)
                                                  handler:^(NSTableViewRowAction *action, NSInteger row)
                  {
                      [self restoreThemeWithName:swipedThemeName];
                      
                      // finish swiped mode anyway
                      [[self themeTableView] setRowActionsVisible:NO];
                  }]];
    } else {
        // Delete
        return @[[NSTableViewRowAction rowActionWithStyle:NSTableViewRowActionStyleDestructive
                                                    title:NSLocalizedString(@"Delete", nil)
                                                  handler:^(NSTableViewRowAction *action, NSInteger row)
                  {
                      [self deleteThemeWithName:swipedThemeName];
                  }]];
    }
}
#endif  // MAC_OS_X_VERSION_10_11



#pragma mark Action Messages

// ------------------------------------------------------
/// show font panel
- (IBAction)showFonts:(nullable id)sender
//-------------------------------------------------------
{
    NSFont *font = [NSFont fontWithName:[[NSUserDefaults standardUserDefaults] stringForKey:CEDefaultFontNameKey]
                                   size:(CGFloat)[[NSUserDefaults standardUserDefaults] doubleForKey:CEDefaultFontSizeKey]];
    
    [[[self view] window] makeFirstResponder:self];
    [[NSFontManager sharedFontManager] setSelectedFont:font isMultiple:NO];
    [[NSFontManager sharedFontManager] orderFrontFontPanel:sender];
}


// ------------------------------------------------------
/// font in font panel did update
- (void)changeFont:(nullable id)sender
// ------------------------------------------------------
{
    NSFontManager *fontManager = (NSFontManager *)sender;
    NSFont *newFont = [fontManager convertFont:[NSFont systemFontOfSize:0]];
    
    [[NSUserDefaults standardUserDefaults] setObject:[newFont fontName] forKey:CEDefaultFontNameKey];
    [[NSUserDefaults standardUserDefaults] setDouble:[newFont pointSize] forKey:CEDefaultFontSizeKey];
    [self setFontFamilyNameAndSize];
}


//------------------------------------------------------
/// テーマを追加
- (IBAction)addTheme:(nullable id)sender
//------------------------------------------------------
{
    NSTableView *tableView = [self themeTableView];
    [[CEThemeManager sharedManager] createUntitledThemeWithCompletionHandler:^(NSString *themeName, NSError *error) {
        NSArray<NSString *> *themeNames = [[CEThemeManager sharedManager] themeNames];
        NSInteger row = [themeNames indexOfObject:themeName];
        [tableView selectRowIndexes:[NSIndexSet indexSetWithIndex:row] byExtendingSelection:NO];
    }];
}


//------------------------------------------------------
/// 選択しているテーマを削除
- (IBAction)deleteTheme:(nullable id)sender
//------------------------------------------------------
{
    [self deleteThemeWithName:[self selectedTheme]];
}


//------------------------------------------------------
/// 選択しているテーマを複製
- (IBAction)duplicateTheme:(nullable id)sender
//------------------------------------------------------
{
    [[CEThemeManager sharedManager] duplicateTheme:[self selectedTheme] error:nil];
}


//------------------------------------------------------
/// 選択しているテーマを書き出し
- (IBAction)exportTheme:(nullable id)sender
//------------------------------------------------------
{
    NSString *selectedThemeName = [self selectedTheme];
    
    NSSavePanel *savePanel = [NSSavePanel savePanel];
    [savePanel setCanCreateDirectories:YES];
    [savePanel setCanSelectHiddenExtension:YES];
    [savePanel setNameFieldLabel:NSLocalizedString(@"Export As:", nil)];
    [savePanel setNameFieldStringValue:selectedThemeName];
    [savePanel setAllowedFileTypes:@[CEThemeExtension]];
    
    [savePanel beginSheetModalForWindow:[[self view] window] completionHandler:^(NSInteger result) {
        if (result == NSFileHandlingPanelCancelButton) { return; }
        
        [[CEThemeManager sharedManager] exportTheme:selectedThemeName toURL:[savePanel URL] error:nil];
    }];
}


//------------------------------------------------------
/// テーマを読み込み
- (IBAction)importTheme:(nullable id)sender
//------------------------------------------------------
{
    NSOpenPanel *openPanel = [NSOpenPanel openPanel];
    [openPanel setPrompt:NSLocalizedString(@"Import", nil)];
    [openPanel setResolvesAliases:YES];
    [openPanel setAllowsMultipleSelection:NO];
    [openPanel setCanChooseDirectories:NO];
    [openPanel setAllowedFileTypes:@[CEThemeExtension]];
    
    [openPanel beginSheetModalForWindow:[[self view] window] completionHandler:^(NSInteger result) {
        if (result == NSFileHandlingPanelCancelButton) { return; }
        
        [openPanel orderOut:nil];
        [[openPanel sheetParent] makeKeyAndOrderFront:nil];
        
        [self importThemeWithURL:[openPanel URL]];
    }];
}


// ------------------------------------------------------
/// カスタマイズされたバンドル版テーマをオリジナルに戻す
- (IBAction)restoreTheme:(nullable id)sender
// ------------------------------------------------------
{
    [self restoreThemeWithName:[self selectedTheme]];
}



#pragma mark Private Methods

//------------------------------------------------------
/// display font name and size in the font field
- (void)setFontFamilyNameAndSize
//------------------------------------------------------
{
    NSString *name = [[NSUserDefaults standardUserDefaults] stringForKey:CEDefaultFontNameKey];
    CGFloat size = (CGFloat)[[NSUserDefaults standardUserDefaults] doubleForKey:CEDefaultFontSizeKey];
    NSFont *font = [NSFont fontWithName:name size:size];
    NSString *localizedName = [font displayName];
    
    [[self fontField] setStringValue:[NSString stringWithFormat:@"%@ %g", localizedName, size]];
}


//------------------------------------------------------
/// 現在選択されているテーマ名を返す
- (nonnull NSString *)selectedTheme
//------------------------------------------------------
{
    return [self themeNames][[[self themeTableView] selectedRow]];
}


//------------------------------------------------------
/// try to delete given theme
- (void)deleteThemeWithName:(nonnull NSString *)themeName
//------------------------------------------------------
{
    NSAlert *alert = [[NSAlert alloc] init];
    [alert setMessageText:[NSString stringWithFormat:NSLocalizedString(@"Are you sure you want to delete “%@” theme?", nil), themeName]];
    [alert setInformativeText:NSLocalizedString(@"Deleted theme can’t be restored.", nil)];
    [alert addButtonWithTitle:NSLocalizedString(@"Cancel", nil)];
    [alert addButtonWithTitle:NSLocalizedString(@"Delete", nil)];
    
    [alert beginSheetModalForWindow:[[self view] window]
                      modalDelegate:self
                     didEndSelector:@selector(deleteThemeAlertDidEnd:returnCode:contextInfo:)
                        contextInfo:(__bridge_retained void *)themeName];
    
}


//------------------------------------------------------
/// try to restore given theme
- (void)restoreThemeWithName:(nonnull NSString *)themeName
//------------------------------------------------------
{
    [[CEThemeManager sharedManager] restoreTheme:themeName completionHandler:^(NSError *error) {
        // refresh theme view if current displayed theme was restored
        if (!error && [themeName isEqualToString:[self selectedTheme]]) {
            NSMutableDictionary<NSString *, NSMutableDictionary<NSString *, id> *>  *bundledTheme = [[CEThemeManager sharedManager] archivedTheme:themeName isBundled:nil];
            
            [[self themeViewController] setRepresentedObject:bundledTheme];
        }
    }];
}


//------------------------------------------------------
/// try to import theme file at given URL
- (void)importThemeWithURL:(nonnull NSURL *)URL
//------------------------------------------------------
{
    NSError *error = nil;
    [[CEThemeManager sharedManager] importTheme:URL replace:NO error:&error];
    
    if (error) {
        NSAlert *alert = [NSAlert alertWithError:error];
        NSWindow *window = [[self view] window];
        
        // display as an independent window if any sheet is already attached
        if ([window attachedSheet]) {
            window = nil;
        }
        
        // ask for overwriting if a theme with the same name already exists
        if ([error code] == CEThemeFileDuplicationError) {
                [alert beginSheetModalForWindow:window
                                  modalDelegate:self
                                 didEndSelector:@selector(importDuplicateThemeAlertDidEnd:returnCode:contextInfo:)
                                    contextInfo:(__bridge_retained void *)URL];
            
        } else {
            [alert beginSheetModalForWindow:window
                              modalDelegate:nil
                             didEndSelector:NULL
                                contextInfo:NULL];
        }
    }
}


// ------------------------------------------------------
/// テーマ削除確認シートが閉じる直前
- (void)deleteThemeAlertDidEnd:(nonnull NSAlert *)alert returnCode:(NSInteger)returnCode contextInfo:(nullable void *)contextInfo
// ------------------------------------------------------
{
    if (returnCode != NSAlertSecondButtonReturn) {  // != Delete
        return;
    }
    NSString *themeName = (__bridge_transfer NSString *)contextInfo;
    
    NSError *error = nil;
    if ([[CEThemeManager sharedManager] removeTheme:themeName error:&error]) {
        AudioServicesPlaySystemSound(CESystemSoundID_MoveToTrash);
    }
    
    if (error) {
        // 削除できなければ、その旨をユーザに通知
        [[alert window] orderOut:self];
        [[[self view] window] makeKeyAndOrderFront:self];
        NSAlert *errorAlert = [NSAlert alertWithError:error];
        NSBeep();
        [errorAlert beginSheetModalForWindow:[[self view] window] modalDelegate:self didEndSelector:NULL contextInfo:NULL];
    }
}


// ------------------------------------------------------
/// テーマ読み込みでの重複するテーマの上書き確認シートが閉じる直前
- (void)importDuplicateThemeAlertDidEnd:(nonnull NSAlert *)alert returnCode:(NSInteger)returnCode contextInfo:(nullable void *)contextInfo
// ------------------------------------------------------
{
    if (returnCode != NSAlertSecondButtonReturn) {  // Cancel
        return;
    }
    
    NSURL *URL = CFBridgingRelease(contextInfo);
    NSError *error = nil;
    [[CEThemeManager sharedManager] importTheme:URL replace:YES error:&error];
    
    if (error) {
        NSAlert *alert = [NSAlert alertWithError:error];
        [alert beginSheetModalForWindow:[[self view] window] modalDelegate:nil didEndSelector:NULL contextInfo:NULL];
    }
}


// ------------------------------------------------------
/// テーマのリストを更新
- (void)setupThemeList
// ------------------------------------------------------
{
    [self setThemeNames:[[CEThemeManager sharedManager] themeNames]];
    [[self themeTableView] reloadData];
}

@end
