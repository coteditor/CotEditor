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
@property (nonatomic) IBOutlet NSButton *deleteThemeButton;

@property (nonatomic) NSMutableDictionary *themeDict;

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
    [[NSNotificationCenter defaultCenter] removeObserver:[self themeTableView]];
}


// ------------------------------------------------------
/// Nibファイル読み込み直後
- (void)awakeFromNib
// ------------------------------------------------------
{
    [self setFontFamilyNameAndSize];
    
    // デフォルトテーマを選択
    NSArray *themeNames = [[CEThemeManager sharedManager] themeNames];
    NSInteger row = [themeNames indexOfObject:[[NSUserDefaults standardUserDefaults] stringForKey:k_key_defaultTheme]];
    [[self themeTableView] selectRowIndexes:[NSIndexSet indexSetWithIndex:row] byExtendingSelection:NO];
    [[self themeTableView] setAllowsEmptySelection:NO];
    
    // テーマのラインナップが変更されたらテーブルビューを更新
    [[NSNotificationCenter defaultCenter] addObserver:[self themeTableView]
                                             selector:@selector(reloadData)
                                                 name:CEThemeDidUpdateNotification
                                               object:nil];
}


// ------------------------------------------------------
/// テーマが変更された
- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context
// ------------------------------------------------------
{
    if (object == [self themeDict]) {
        [[CEThemeManager sharedManager] saveTheme:[self themeDict] name:[self selectedTheme]];
    }
}


// ------------------------------------------------------
/// メニュー項目の有効化／無効化を制御
- (BOOL)validateMenuItem:(NSMenuItem *)menuItem
// ------------------------------------------------------
{
    if ([menuItem action] == @selector(exportTheme:)) {
        [menuItem setTitle:[NSString stringWithFormat:NSLocalizedString(@"Export “%@”…", nil), [self selectedTheme]]];
        return ![[CEThemeManager sharedManager] isBundledTheme:[self selectedTheme]];
        
    } else if ([menuItem action] == @selector(duplicateTheme:)) {
        [menuItem setTitle:[NSString stringWithFormat:NSLocalizedString(@"Duplicate “%@”…", nil), [self selectedTheme]]];
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
    return [[[CEThemeManager sharedManager] themeNames] count];
}


// ------------------------------------------------------
/// テーブルのセルの内容を返す
- (id)tableView:(NSTableView *)aTableView objectValueForTableColumn:(NSTableColumn *)aTableColumn row:(NSInteger)rowIndex
// ------------------------------------------------------
{
    return [[CEThemeManager sharedManager] themeNames][rowIndex];
}


// ------------------------------------------------------
/// テーブルのセルが編集された
- (void)tableView:(NSTableView *)aTableView setObjectValue:(id)anObject forTableColumn:(NSTableColumn *)aTableColumn row:(NSInteger)rowIndex
// ------------------------------------------------------
{
    [[CEThemeManager sharedManager] renameTheme:[self selectedTheme] toName:anObject];
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
        
        // テーマ辞書の変更を監視
        for (NSString *key in [themeDict allKeys]) {
            [[self themeDict] removeObserver:self forKeyPath:key];
            [themeDict addObserver:self forKeyPath:key options:0 context:NULL];
        }
        
        // デフォルトテーマ設定の更新（初回の選択変更はまだ設定が反映されていない時点で呼び出されるので保存しない）
        if ([self themeDict]) {
            [[NSUserDefaults standardUserDefaults] setObject:[self selectedTheme] forKey:k_key_defaultTheme];
        }
        
        [self setThemeDict:themeDict];
        [[self deleteThemeButton] setEnabled:!isBundled];
    }
}


// ------------------------------------------------------
/// テーブルセルが編集可能かを返す
- (BOOL)tableView:(NSTableView *)tableView shouldEditTableColumn:(NSTableColumn *)tableColumn row:(NSInteger)row
// ------------------------------------------------------
{
    return  ![[CEThemeManager sharedManager] isBundledTheme:[self selectedTheme]];
}



#pragma mark Action Messages

//=======================================================
// Action messages
//
//=======================================================

//------------------------------------------------------
/// 行間値を調整
- (IBAction)setupCustomLineSpacing:(id)sender
//------------------------------------------------------
{
    // IB で Formatter が設定できないのでメソッドで行ってる。
    
    CGFloat value = (CGFloat)[sender doubleValue];
    
    if (value < k_lineSpacingMin) { value = k_lineSpacingMin; }
    if (value > k_lineSpacingMax) { value = k_lineSpacingMax; }
    
    [sender setStringValue:[NSString stringWithFormat:@"%.2f", value]];
}


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
}


//------------------------------------------------------
/// 選択しているテーマを削除
- (IBAction)deleteTheme:(id)sender
//------------------------------------------------------
{
    NSString *message = [NSString stringWithFormat:NSLocalizedString(@"Delete the theme “%@”?", nil), [self selectedTheme]];
    NSAlert *alert = [NSAlert alertWithMessageText:message
                                     defaultButton:NSLocalizedString(@"Cancel", nil)
                                   alternateButton:NSLocalizedString(@"Delete", nil)
                                       otherButton:nil
                         informativeTextWithFormat:NSLocalizedString(@"Deleted theme cannot be restored.", nil)];
    
    [alert beginSheetModalForWindow:[[self view] window]
                      modalDelegate:self
                     didEndSelector:@selector(deleteThemeAlertDidEnd:returnCode:contextInfo:) contextInfo:NULL];
}


//------------------------------------------------------
/// 選択しているテーマを複製
- (IBAction)duplicateTheme:(id)sender
//------------------------------------------------------
{
    [[CEThemeManager sharedManager] duplicateTheme:[self selectedTheme]];
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
    [savePanel setAllowedFileTypes:@[@"plist"]];
    
    [savePanel beginSheetModalForWindow:[[self view] window] completionHandler:^(NSInteger result) {
        if (result == NSFileHandlingPanelCancelButton) { return; }
    
        [[CEThemeManager sharedManager] exportTheme:selectedThemeName toURL:[savePanel URL]];
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
    [openPanel setAllowedFileTypes:@[@"plist"]];
    
    [openPanel beginSheetModalForWindow:[[self view] window] completionHandler:^(NSInteger result) {
        if (result == NSFileHandlingPanelCancelButton) return;
        
        // TODO: duplicate check
        [[CEThemeManager sharedManager] importTheme:[openPanel URL]];
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


//------------------------------------------------------
/// 現在選択されているテーマ名を返す
- (NSString *)selectedTheme
//------------------------------------------------------
{
    return [[CEThemeManager sharedManager] themeNames][[[self themeTableView] selectedRow]];
}


// ------------------------------------------------------
/// テーマ削除確認シートが閉じる直前
- (void)deleteThemeAlertDidEnd:(NSAlert *)alert returnCode:(NSInteger)returnCode contextInfo:(void *)contextInfo
// ------------------------------------------------------
{
    if (returnCode != NSAlertAlternateReturn) {  // != Delete
        return;
    }
    
    NSString *selectedTheme = [self selectedTheme];
    
    if ([[CEThemeManager sharedManager] removeTheme:selectedTheme]) {
        /// TODO: 削除成功時の処理
        
    } else {
        // 削除できなければ、その旨をユーザに通知
        [[alert window] orderOut:self];
        [[[self view] window] makeKeyAndOrderFront:self];
        NSAlert *alert = [NSAlert alertWithMessageText:NSLocalizedString(@"Error occured.", nil)
                                         defaultButton:nil
                                       alternateButton:nil otherButton:nil
                             informativeTextWithFormat:NSLocalizedString(@"Sorry, could not delete “%@”.", nil), selectedTheme];
        NSBeep();
        [alert beginSheetModalForWindow:[[self view] window] modalDelegate:self didEndSelector:NULL contextInfo:NULL];
    }
}

@end
