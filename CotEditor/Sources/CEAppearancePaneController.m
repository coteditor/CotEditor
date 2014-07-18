/*
 =================================================
 CEAppearancePaneController
 (for CotEditor)
 
 Copyright (C) 2004-2007 nakamuxu.
 Copyright (C) 2014 CotEditor Project
 http://coteditor.github.io
 =================================================
 
 encoding="UTF-8"
 Created:2014-04-18
 
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

#import "CEAppearancePaneController.h"
#import "CEThemeManager.h"
#import "constants.h"


@interface CEAppearancePaneController () <NSTableViewDelegate, NSTableViewDataSource>

@property (nonatomic, weak) IBOutlet NSTextField *fontField;

@property (nonatomic) IBOutlet NSTableView *themeTableView;

@property (nonatomic) NSArray *themeNames;
@property (nonatomic) NSMutableDictionary *themeDict;
@property (nonatomic) BOOL isBundled;

@end




#pragma mark -

@implementation CEAppearancePaneController

#pragma mark Superclass Methods

//=======================================================
// Superclass method
//
//=======================================================

// ------------------------------------------------------
/// あとかたづけ
- (void)dealloc
// ------------------------------------------------------
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    
    for (NSString *key in [[self themeDict] allKeys]) {
        [[self themeDict] removeObserver:self forKeyPath:key];
    }
}


// ------------------------------------------------------
/// Nibファイル読み込み直後
- (void)awakeFromNib
// ------------------------------------------------------
{
    [self setFontFamilyNameAndSize];
    
    [self setupThemeList];
    
    // デフォルトテーマを選択
    NSArray *themeNames = [[self themeNames] copy];
    NSInteger row = [themeNames indexOfObject:[[NSUserDefaults standardUserDefaults] stringForKey:k_key_defaultTheme]];
    [[self themeTableView] selectRowIndexes:[NSIndexSet indexSetWithIndex:row] byExtendingSelection:NO];
    [[self themeTableView] setAllowsEmptySelection:NO];
    
    // テーマのラインナップが変更されたらテーブルビューを更新
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(setupThemeList)
                                                 name:CEThemeListDidUpdateNotification
                                               object:nil];
}


// ------------------------------------------------------
/// テーマが変更された
- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context
// ------------------------------------------------------
{
    if (object == [self themeDict]) {
        [[CEThemeManager sharedManager] saveTheme:[self themeDict] name:[self selectedTheme] completionHandler:nil];
    }
}


// ------------------------------------------------------
/// メニュー項目の有効化／無効化を制御
- (BOOL)validateMenuItem:(NSMenuItem *)menuItem
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



#pragma mark Delegate and Notification

//=======================================================
// NSTableDataSource Protocol
//  <== themeTableView
//=======================================================

// ------------------------------------------------------
/// テーブルの行数を返す
- (NSInteger)numberOfRowsInTableView:(NSTableView *)aTableView
// ------------------------------------------------------
{
    return [[self themeNames] count];
}


// ------------------------------------------------------
/// テーブルのセルの内容を返す
- (id)tableView:(NSTableView *)aTableView objectValueForTableColumn:(NSTableColumn *)aTableColumn row:(NSInteger)rowIndex
// ------------------------------------------------------
{
    return [self themeNames][rowIndex];
}


//=======================================================
// Delegate method (NSTableView)
//  <== themeTableView
//=======================================================

// ------------------------------------------------------
/// テーブルの選択が変更された
- (void)tableViewSelectionDidChange:(NSNotification *)notification
// ------------------------------------------------------
{
    if ([notification object] == [self themeTableView]) {
        BOOL isBundled;
        NSMutableDictionary *themeDict = [[CEThemeManager sharedManager] archivedTheme:[self selectedTheme] isBundled:&isBundled];
        
        // デフォルトテーマ設定の更新（初回の選択変更はまだ設定が反映されていない時点で呼び出されるので保存しない）
        if ([self themeDict]) {
            NSString *oldThemeName = [[NSUserDefaults standardUserDefaults] stringForKey:k_key_defaultTheme];
            
            [[NSUserDefaults standardUserDefaults] setObject:[self selectedTheme] forKey:k_key_defaultTheme];
            
            // 現在開いているウインドウのテーマも変更
            [[NSNotificationCenter defaultCenter] postNotificationName:CEThemeDidUpdateNotification
                                                                object:self
                                                              userInfo:@{CEOldNameKey: oldThemeName,
                                                                         CENewNameKey: [self selectedTheme]}];
        }
        
        [self setThemeDict:themeDict];
        [self setIsBundled:isBundled];
    }
}


// ------------------------------------------------------
/// テーブルセルが編集可能かを返す
- (BOOL)tableView:(NSTableView *)tableView shouldEditTableColumn:(NSTableColumn *)tableColumn row:(NSInteger)row
// ------------------------------------------------------
{
    return ![[CEThemeManager sharedManager] isBundledTheme:[self selectedTheme] cutomized:nil];
}


// ------------------------------------------------------
/// テーマ名が編集された
- (BOOL)control:(NSControl *)control textShouldEndEditing:(NSText *)fieldEditor
// ------------------------------------------------------
{
    NSString *newName = [fieldEditor string];
    NSError *error = nil;
    
    // 空の場合は終わる（自動的に元の名前がセットされる）
    if ([newName isEqualToString:@""]) {
        return YES;
    }
    
    BOOL success = [[CEThemeManager sharedManager] renameTheme:[self selectedTheme] toName:newName error:&error];
    
    if (error) {
        NSAlert *alert = [NSAlert alertWithError:error];
        NSBeep();
        [alert beginSheetModalForWindow:[[self view] window] modalDelegate:nil didEndSelector:NULL contextInfo:NULL];
    }
    
    return success;
}



#pragma mark Action Messages

//=======================================================
// Action messages
//
//=======================================================

// ------------------------------------------------------
/// フォントパネルを表示
- (IBAction)showFonts:(id)sender
//-------------------------------------------------------
{
    NSFont *font = [NSFont fontWithName:[[NSUserDefaults standardUserDefaults] stringForKey:k_key_fontName]
                                   size:(CGFloat)[[NSUserDefaults standardUserDefaults] doubleForKey:k_key_fontSize]];
    
    [[[self view] window] makeFirstResponder:self];
    [[NSFontManager sharedFontManager] setSelectedFont:font isMultiple:NO];
    [[NSFontManager sharedFontManager] orderFrontFontPanel:sender];
}


// ------------------------------------------------------
/// フォントパネルでフォントが変更された
- (void)changeFont:(id)sender
// ------------------------------------------------------
{
    // (引数"sender"はNSFontManegerのインスタンス)
    NSFont *newFont = [sender convertFont:[NSFont systemFontOfSize:0]];
    NSString *name = [newFont fontName];
    CGFloat size = [newFont pointSize];
    
    [[NSUserDefaults standardUserDefaults] setObject:name forKey:k_key_fontName];
    [[NSUserDefaults standardUserDefaults] setFloat:size forKey:k_key_fontSize];
    [self setFontFamilyNameAndSize];
}


//------------------------------------------------------
/// テーマを追加
- (IBAction)addTheme:(id)sender
//------------------------------------------------------
{
    __block typeof(self) blockSelf = self;
    [[CEThemeManager sharedManager] createUntitledThemeWithCompletionHandler:^(NSString *themeName, NSError *error) {
        NSArray *themeNames = [[CEThemeManager sharedManager] themeNames];
        NSInteger row = [themeNames indexOfObject:themeName];
        [[blockSelf themeTableView] selectRowIndexes:[NSIndexSet indexSetWithIndex:row] byExtendingSelection:NO];
    }];
}


//------------------------------------------------------
/// 選択しているテーマを削除
- (IBAction)deleteTheme:(id)sender
//------------------------------------------------------
{
    NSAlert *alert = [[NSAlert alloc] init];
    [alert setMessageText:[NSString stringWithFormat:NSLocalizedString(@"Delete the theme “%@”?", nil),
                           [self selectedTheme]]];
    [alert setInformativeText:NSLocalizedString(@"Deleted theme cannot be restored.", nil)];
    [alert addButtonWithTitle:NSLocalizedString(@"Cancel", nil)];
    [alert addButtonWithTitle:NSLocalizedString(@"Delete", nil)];
    
    [alert beginSheetModalForWindow:[[self view] window]
                      modalDelegate:self
                     didEndSelector:@selector(deleteThemeAlertDidEnd:returnCode:contextInfo:) contextInfo:NULL];
}


//------------------------------------------------------
/// 選択しているテーマを複製
- (IBAction)duplicateTheme:(id)sender
//------------------------------------------------------
{
    [[CEThemeManager sharedManager] duplicateTheme:[self selectedTheme] error:nil];
}


//------------------------------------------------------
/// 選択しているテーマを書き出し
- (IBAction)exportTheme:(id)sender
//------------------------------------------------------
{
    NSString *selectedThemeName = [self selectedTheme];
    
    NSSavePanel *savePanel = [NSSavePanel savePanel];
    [savePanel setCanCreateDirectories:YES];
    [savePanel setCanSelectHiddenExtension:YES];
    [savePanel setNameFieldLabel:NSLocalizedString(@"Export As:", nil)];
    [savePanel setNameFieldStringValue:selectedThemeName];
    [savePanel setAllowedFileTypes:@[@"cottheme"]];
    
    [savePanel beginSheetModalForWindow:[[self view] window] completionHandler:^(NSInteger result) {
        if (result == NSFileHandlingPanelCancelButton) { return; }
        
        [[CEThemeManager sharedManager] exportTheme:selectedThemeName toURL:[savePanel URL] error:nil];
    }];
}


//------------------------------------------------------
/// テーマを読み込み
- (IBAction)importTheme:(id)sender
//------------------------------------------------------
{
    NSOpenPanel *openPanel = [NSOpenPanel openPanel];
    [openPanel setPrompt:NSLocalizedString(@"Import", nil)];
    [openPanel setResolvesAliases:YES];
    [openPanel setAllowsMultipleSelection:NO];
    [openPanel setCanChooseDirectories:NO];
    [openPanel setAllowedFileTypes:@[@"cottheme"]];
    
    [openPanel beginSheetModalForWindow:[[self view] window] completionHandler:^(NSInteger result) {
        if (result == NSFileHandlingPanelCancelButton) { return; }
        
        NSURL *URL = [openPanel URL];
        NSError *error = nil;
        
        // インポートを試みる
        [[CEThemeManager sharedManager] importTheme:URL replace:NO error:&error];
        
        if (error) {
            NSAlert *alert = [NSAlert alertWithError:error];
            
            [openPanel orderOut:nil];
            [[openPanel sheetParent] makeKeyAndOrderFront:nil];
            
            // 同名のファイルがある場合は上書きするかを訊く
            if ([error code] == CEThemeFileDuplicationError) {
                [alert beginSheetModalForWindow:[[self view] window]
                                  modalDelegate:self
                                 didEndSelector:@selector(importDuplicateThemeAlertDidEnd:returnCode:contextInfo:)
                                    contextInfo:(__bridge_retained void *)(URL)];
            } else {
                [alert beginSheetModalForWindow:[[self view] window]
                                  modalDelegate:nil
                                 didEndSelector:NULL
                                    contextInfo:NULL];
            }
        }
    }];
}


// ------------------------------------------------------
/// カスタマイズされたバンドル版テーマをオリジナルに戻す
- (IBAction)restoreTheme:(id)sender
// ------------------------------------------------------
{
    [[CEThemeManager sharedManager] restoreTheme:[self selectedTheme] completionHandler:^(NSError *error) {
        if (!error) {
            // 辞書をセットし直す
            [self setThemeDict:[[CEThemeManager sharedManager] archivedTheme:[self selectedTheme] isBundled:nil]];
        }
    }];
}


// ------------------------------------------------------
/// システムのハイライトカラーを適応する
- (IBAction)applySystemSelectionColor:(id)sender
// ------------------------------------------------------
{
    if ([sender state] == NSOnState) {
        [self themeDict][CEThemeSelectionColorKey] = [NSArchiver archivedDataWithRootObject:[NSColor selectedTextBackgroundColor]];
    }
}



#pragma mark Private Methods

//=======================================================
// Private method
//
//=======================================================

//------------------------------------------------------
/// メインウィンドウのフォントファミリー名とサイズをprefFontFamilyNameSizeに表示させる
- (void)setFontFamilyNameAndSize
//------------------------------------------------------
{
    NSString *name = [[NSUserDefaults standardUserDefaults] stringForKey:k_key_fontName];
    CGFloat size = (CGFloat)[[NSUserDefaults standardUserDefaults] doubleForKey:k_key_fontSize];
    NSFont *font = [NSFont fontWithName:name size:size];
    NSString *localizedName = [font displayName];
    
    [[self fontField] setStringValue:[NSString stringWithFormat:@"%@ %g", localizedName, size]];
}


// ------------------------------------------------------
/// テーマ辞書をセット
- (void)setThemeDict:(NSMutableDictionary *)themeDict
// ------------------------------------------------------
{
    // テーマ辞書の変更を監視
    for (NSString *key in [themeDict allKeys]) {
        [[self themeDict] removeObserver:self forKeyPath:key];
        [themeDict addObserver:self forKeyPath:key options:0 context:NULL];
    }
    
    _themeDict = themeDict;
}


//------------------------------------------------------
/// 現在選択されているテーマ名を返す
- (NSString *)selectedTheme
//------------------------------------------------------
{
    return [self themeNames][[[self themeTableView] selectedRow]];
}


// ------------------------------------------------------
/// テーマ削除確認シートが閉じる直前
- (void)deleteThemeAlertDidEnd:(NSAlert *)alert returnCode:(NSInteger)returnCode contextInfo:(void *)contextInfo
// ------------------------------------------------------
{
    if (returnCode != NSAlertSecondButtonReturn) {  // != Delete
        return;
    }
    
    NSError *error = nil;
    [[CEThemeManager sharedManager] removeTheme:[self selectedTheme] error:&error];
    
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
- (void)importDuplicateThemeAlertDidEnd:(NSAlert *)alert returnCode:(NSInteger)returnCode contextInfo:(void *)contextInfo
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


- (void)setupThemeList
{
    [self setThemeNames:[[CEThemeManager sharedManager] themeNames]];
    [[self themeTableView] reloadData];
}

@end
