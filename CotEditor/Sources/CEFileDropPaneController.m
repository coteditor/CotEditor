/*
 ==============================================================================
 CEFileDropPaneController
 
 CotEditor
 http://coteditor.com
 
 Created on 2014-04-18 by 1024jp
 encoding="UTF-8"
 ------------------------------------------------------------------------------
 
 © 2004-2007 nakamuxu
 © 2014 CotEditor Project
 
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

#import "CEFileDropPaneController.h"
#import "constants.h"


@interface CEFileDropPaneController () <NSTableViewDelegate, NSTextFieldDelegate, NSTextViewDelegate>

@property (nonatomic) IBOutlet NSArrayController *fileDropController;
@property (nonatomic, weak) IBOutlet NSTableView *extensionTableView;
@property (nonatomic, strong) IBOutlet NSTextView *formatTextView;  // on 10.8 NSTextView cannot be weak
@property (nonatomic, strong) IBOutlet NSTextView *glossaryTextView;  // on 10.8 NSTextView cannot be weak

@property (nonatomic, getter=isDeletingFileDrop) BOOL deletingFileDrop;

@end




#pragma mark -

@implementation CEFileDropPaneController

#pragma mark Superclass Methods

// ------------------------------------------------------
/// setup UI
- (void)loadView
// ------------------------------------------------------
{
    [super loadView];
    
    // 設定を読み込む
    [self loadSetting];
    
    // 用語集をセット
    NSURL *glossaryURL = [[NSBundle mainBundle] URLForResource:@"FileDropGlossary" withExtension:@"txt"];
    NSString *glossary = [NSString stringWithContentsOfURL:glossaryURL encoding:NSUTF8StringEncoding error:nil];
    [[self glossaryTextView] setString:glossary];
    
    // FileDrop 配列コントローラの値を確実に書き戻すためにウインドウクローズを監視
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(storeSetting)
                                                 name:NSWindowWillCloseNotification
                                               object:[[self view] window]];
}


// ------------------------------------------------------
/// clean up
- (void)dealloc
// ------------------------------------------------------
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}



#pragma mark Delegate and Notification

//=======================================================
// Delegate method (NSTableView)
//  <== extensionTableView
//=======================================================

// ------------------------------------------------------
/// 拡張子テーブルが編集された
- (void)controlTextDidEndEditing:(NSNotification *)notification
// ------------------------------------------------------
{
    if (![[notification object] isKindOfClass:[NSTextField class]]) { return; }
    
    NSString *extensions = [[[self fileDropController] selection] valueForKeyPath:CEFileDropExtensionsKey];
    NSString *format = [[[self fileDropController] selection] valueForKeyPath:CEFileDropFormatStringKey];
    
    // 入力されていなければ行ごと削除
    if (!extensions && !format) {
        // 削除実行フラグを偽に（編集中に削除ボタンが押され、かつ自動削除対象であったときの整合性を取るためのフラグ）
        [self setDeletingFileDrop:NO];
        [[self fileDropController] remove:self];
        
    } else {
        // フォーマットを整える
        NSString *newExtensions = [self sanitizeExtensionsString:extensions];
        
        // 有効な文字列が生成できたら、UserDefaults に書き戻し、直ちに反映させる
        if ([newExtensions length] > 0) {
            [[[self fileDropController] selection] setValue:newExtensions forKey:CEFileDropExtensionsKey];
        } else if (!format) {
            [[self fileDropController] remove:self];
        }
    }
    
    
    [self storeSetting];
}


// ------------------------------------------------------
/// 拡張子テーブルの追加行の編集開始
- (void)tableView:(NSTableView *)tableView didAddRowView:(NSTableRowView *)rowView forRow:(NSInteger)row
// ------------------------------------------------------
{
    BOOL isLastRow = ([tableView numberOfRows] - 1 == row);
    NSTextField *textField = [[rowView viewAtColumn:0] textField];
    
    if (isLastRow && [[textField stringValue] length] == 0) {
        [tableView editColumn:0 row:row withEvent:nil select:YES];
    }
}



//=======================================================
// Delegate method (NSTextView)
//  <== formatTextView
//=======================================================

// ------------------------------------------------------
/// FileDrop 挿入文字列フォーマットテキストビューが編集された
- (void)textDidEndEditing:(NSNotification *)notification
// ------------------------------------------------------
{
    if ([notification object] == [self formatTextView]) {
        // UserDefaults に書き戻し、直ちに反映させる
        [self storeSetting];
    }
}



#pragma mark Action Messages

// ------------------------------------------------------
/// 定型文字列挿入メニューが選択された
- (IBAction)insertToken:(id)sender
// ------------------------------------------------------
{
    NSString *title = [(NSMenuItem *)sender title];
    
    [[[self view] window] makeFirstResponder:[self formatTextView]];
    [[self formatTextView] insertText:title];
}


// ------------------------------------------------------
/// ファイルドロップ編集設定を追加
- (IBAction)addSetting:(id)sender
// ------------------------------------------------------
{
    // フォーカスを移し、値入力を確定
    [[sender window] makeFirstResponder:sender];
    
    [[self fileDropController] add:self];
}


// ------------------------------------------------------
/// ファイルドロップ編集設定の削除ボタンが押された
- (IBAction)removeSetting:(id)sender
// ------------------------------------------------------
{
    // (編集中に削除ボタンが押され、かつ自動削除対象であったときの整合性を取るための)削除実施フラグをたてる
    [self setDeletingFileDrop:YES];
    
    // フォーカスを移し、値入力を確定
    [[sender window] makeFirstResponder:sender];
    
    // 確認ダイアログを出す
    [self confirmDeletion];
}



#pragma mark Private Mthods

// ------------------------------------------------------
//// FileDrop 設定を UserDefaults に書き戻す
- (void)storeSetting
// ------------------------------------------------------
{
    [[NSUserDefaults standardUserDefaults] setObject:[[self fileDropController] content] forKey:CEDefaultFileDropArrayKey];
}


// ------------------------------------------------------
/// FileDrop 設定をコントローラにセット
- (void)loadSetting
// ------------------------------------------------------
{
    // バインディングで UserDefaults と直結すると「長さゼロの文字列がセットされた」ときなどにいろいろと不具合が発生するので、
    // 起動時に読み込み、変更完了／終了時に下記戻す処理を行う。
    // http://www.hmdt-web.net/bbs/bbs.cgi?bbsname=mkino&mode=res&no=203&oyano=203&line=0
    
    NSArray *settings = [[NSUserDefaults standardUserDefaults] arrayForKey:CEDefaultFileDropArrayKey];
    
    NSMutableArray *content = [NSMutableArray array];
    for (NSDictionary *dict in settings) {
        [content addObject:[dict mutableCopy]];
    }
    
    [[self fileDropController] setContent:content];
}


// ------------------------------------------------------
/// 拡張子文字列のフォーマットを整える（全て無効なときは nil を返す）
- (NSString *)sanitizeExtensionsString:(NSString *)extensionsString
// ------------------------------------------------------
{
    if (![extensionsString isKindOfClass:[NSString class]]) { return nil; }
    
    NSCharacterSet *trimSet = [NSCharacterSet characterSetWithCharactersInString:@"./ \t\r\n"];
    NSArray *extensions = [extensionsString componentsSeparatedByString:@","];
    NSMutableArray *sanitizedExtensions = [NSMutableArray array];
    
    for (NSString *extension in extensions) {
        NSString *sanitizedExtension = [extension stringByTrimmingCharactersInSet:trimSet];
        if ([sanitizedExtension length] > 0) {
            [sanitizedExtensions addObject:sanitizedExtension];
        }
    }
    if ([sanitizedExtensions count] > 0) {
        return [sanitizedExtensions componentsJoinedByString:@", "];
    } else {
        return nil;
    }
}


// ------------------------------------------------------
/// 削除して良いかを確認
- (void)confirmDeletion
// ------------------------------------------------------
{
    // フラグがたっていなければ（既に controlTextDidEndEditing: で自動削除されていれば）何もしない
    if (![self isDeletingFileDrop]) { return; }
    
    NSArray *selected = [[self fileDropController] selectedObjects];
    NSString *extension = [selected firstObject][CEFileDropExtensionsKey];
    if ([selected count] == 0) {
        return;
    } else if (!extension) {
        extension = @"";
    }
    
    NSAlert *alert = [[NSAlert alloc] init];
    [alert setMessageText:[NSString stringWithFormat:NSLocalizedString(@"Delete the File Drop setting for “%@”?", nil), extension]];
    [alert setInformativeText:NSLocalizedString(@"Deleted setting cannot be restored.", nil)];
    [alert addButtonWithTitle:NSLocalizedString(@"Cancel", nil)];
    [alert addButtonWithTitle:NSLocalizedString(@"Delete", nil)];
    
    [alert beginSheetModalForWindow:[[self view] window]
                      modalDelegate:self
                     didEndSelector:@selector(deleteSettingAlertDidEnd:returnCode:contextInfo:)
                        contextInfo:NULL];
}


// ------------------------------------------------------
/// ファイルドロップ編集設定削除確認シートが閉じる直前
- (void)deleteSettingAlertDidEnd:(NSAlert *)alert returnCode:(NSInteger)returnCode contextInfo:(void *)contextInfo
// ------------------------------------------------------
{
    if (returnCode != NSAlertSecondButtonReturn) { return; } // != Delete
    
    if ([[self fileDropController] selectionIndex] == NSNotFound) { return; }
    
    if ([self isDeletingFileDrop]) {
        [[self fileDropController] remove:self];
        [self storeSetting];
        [self setDeletingFileDrop:NO];
    }
}

@end
