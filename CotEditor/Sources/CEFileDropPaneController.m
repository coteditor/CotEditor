/*
 =================================================
 CEFileDropPaneController
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

#import "CEFileDropPaneController.h"
#import "constants.h"


@interface CEFileDropPaneController ()

@property (nonatomic) IBOutlet NSArrayController *fileDropController;
@property (nonatomic, weak) IBOutlet NSTableView *fileDropTableView;
@property (nonatomic, strong) IBOutlet NSTextView *fileDropTextView;  // on 10.8 NSTextView cannot be weak
@property (nonatomic, strong) IBOutlet NSTextView *fileDropGlossaryTextView;  // on 10.8 NSTextView cannot be weak

@property (nonatomic) BOOL doDeleteFileDrop;

@end




#pragma mark -

@implementation CEFileDropPaneController

#pragma mark Protocol

//=======================================================
// NSNibAwaking Protocol
//
//=======================================================

// ------------------------------------------------------
/// Nibファイル読み込み直後
- (void)awakeFromNib
// ------------------------------------------------------
{
    // 各種セットアップ
    [self setContentFileDropController];
    // （Nibファイルの用語説明部分は直接NSTextViewに記入していたが、AppleGlot3.4から読み取れなくなり、ローカライズ対象にできなくなってしまった。その回避処理として、Localizable.stringsファイルに書き込むこととしたために、文字列をセットする処理が必要になった。
    // 2008.07.15.
    [[self fileDropGlossaryTextView] setString:NSLocalizedString(@"<<<ABSOLUTE-PATH>>>\nThe dropped file's absolute path.\n\n<<<RELATIVE-PATH>>>\nThe relative path between the dropped file and the document.\n\n<<<FILENAME>>>\nThe dropped file's name with extension (if exists).\n\n<<<FILENAME-NOSUFFIX>>>\nThe dropped file's name without extension.\n\n<<<FILEEXTENSION>>>\nThe dropped file's extension.\n\n<<<FILEEXTENSION-LOWER>>>\nThe dropped file's extension (converted to lowercase).\n\n<<<FILEEXTENSION-UPPER>>>\nThe dropped file's extension (converted to uppercase).\n\n<<<DIRECTORY>>>\nThe parent directory name of the dropped file.\n\n<<<IMAGEWIDTH>>>\n(if the dropped file is Image) The image width.\n\n<<<IMAGEHEIGHT>>>\n(if the dropped file is Image) The image height.", nil)];
}



#pragma mark Delegate and Notification

//=======================================================
// Delegate method (NSTableView)
//  <== fileDropTableView
//=======================================================

// ------------------------------------------------------
/// FileDrop 拡張子テーブルビューが編集された
- (void)controlTextDidEndEditing:(NSNotification *)notification
// ------------------------------------------------------
{
    if ([notification object] == [self fileDropTableView]) {
        NSString *extension = [[[self fileDropController] selection] valueForKey:k_key_fileDropExtensions];
        NSString *format = [[[self fileDropController] selection] valueForKey:k_key_fileDropFormatString];
        
        // 入力されていなければ行ごと削除
        if ((extension == nil) && (format == nil)) {
            // 削除実行フラグを偽に（編集中に削除ボタンが押され、かつ自動削除対象であったときの整合性を取るためのフラグ）
            [self setDoDeleteFileDrop:NO];
            [[self fileDropController] remove:self];
        } else {
            // フォーマットを整える
            NSCharacterSet *trimSet = [NSCharacterSet characterSetWithCharactersInString:@"./ \t\r\n"];
            NSArray *components = [extension componentsSeparatedByString:@","];
            NSMutableArray *newComps = [NSMutableArray array];
            NSString *partStr, *newXtsnStr;
            
            for (NSString *component in components) {
                partStr = [component stringByTrimmingCharactersInSet:trimSet];
                if ([partStr length] > 0) {
                    [newComps addObject:partStr];
                }
            }
            newXtsnStr = [newComps componentsJoinedByString:@", "];
            // 有効な文字列が生成できたら、UserDefaults に書き戻し、直ちに反映させる
            if ((newXtsnStr != nil) && ([newXtsnStr length] > 0)) {
                [[[self fileDropController] selection] setValue:newXtsnStr forKey:k_key_fileDropExtensions];
            } else if (format == nil) {
                [[self fileDropController] remove:self];
            }
        }
        [self writeBackFileDropArray];
    }
}


//=======================================================
// Delegate method (NSTextView)
//  <== fileDropTextView
//=======================================================

// ------------------------------------------------------
/// FileDrop 挿入文字列フォーマットテキストビューが編集された
- (void)textDidEndEditing:(NSNotification *)notification
// ------------------------------------------------------
{
    if ([notification object] == [self fileDropTextView]) {
        // UserDefaults に書き戻し、直ちに反映させる
        [self writeBackFileDropArray];
    }
}



#pragma mark Action Messages

//=======================================================
// Action messages
//
//=======================================================

// ------------------------------------------------------
/// ファイルドロップ定型文字列挿入メニューが選択された
- (IBAction)insertFormatStringInFileDrop:(id)sender
// ------------------------------------------------------
{
    NSString *title = [(NSMenuItem *)sender title];
    
    if (title) {
        [[[self view] window] makeFirstResponder:[self fileDropTextView]];
        [[self fileDropTextView] insertText:title];
    }
}


// ------------------------------------------------------
/// ファイルドロップ編集設定を追加
- (IBAction)addNewFileDropSetting:(id)sender
// ------------------------------------------------------
{
    // フォーカスを移し、値入力を確定
    [[sender window] makeFirstResponder:sender];
    
    [[[self view] window] makeFirstResponder:[self fileDropTableView]];
    [[self fileDropController] add:self];
    
    // ディレイをかけて fileDropController からのバインディングによる行追加を先に実行させる
    [self performSelector:@selector(editNewAddedRowOfFileDropTableView) withObject:nil afterDelay:0];
}


// ------------------------------------------------------
/// ファイルドロップ編集設定の削除ボタンが押された
- (IBAction)deleteFileDropSetting:(id)sender
// ------------------------------------------------------
{
    // (編集中に削除ボタンが押され、かつ自動削除対象であったときの整合性を取るための)削除実施フラグをたてる
    [self setDoDeleteFileDrop:YES];
    // フォーカスを移し、値入力を確定
    [[sender window] makeFirstResponder:sender];
    // ディレイをかけて controlTextDidEndEditing: の自動編集を実行させる
    [self performSelector:@selector(doDeleteFileDropSetting) withObject:nil afterDelay:0];
}



#pragma mark Private Mthods

//=======================================================
// Private method
//
//=======================================================

// ------------------------------------------------------
//// FileDrop 設定を UserDefaults に書き戻す
- (void)writeBackFileDropArray
// ------------------------------------------------------
{
    [[NSUserDefaults standardUserDefaults] setObject:[[self fileDropController] content] forKey:k_key_fileDropArray];
}


// ------------------------------------------------------
/// ファイルドロップ設定編集用コントローラに値をセット
- (void)setContentFileDropController
// ------------------------------------------------------
{
    // バインディングで UserDefaults と直結すると「長さゼロの文字列がセットされた」ときなどにいろいろと不具合が発生するので、
    // 起動時に読み込み、変更完了／終了時に下記戻す処理を行う。
    // http://www.hmdt-web.net/bbs/bbs.cgi?bbsname=mkino&mode=res&no=203&oyano=203&line=0
    
    NSMutableArray *fileDropArray = [[[NSUserDefaults standardUserDefaults] arrayForKey:k_key_fileDropArray] mutableCopy];
    
    [[self fileDropController] setContent:fileDropArray];
}


// ------------------------------------------------------
/// ファイルドロップ編集設定の削除を確認
- (void)doDeleteFileDropSetting
// ------------------------------------------------------
{
    // フラグがたっていなければ（既に controlTextDidEndEditing: で自動削除されていれば）何もしない
    if (![self doDeleteFileDrop]) { return; }
    
    NSArray *selected = [[self fileDropController] selectedObjects];
    NSString *extension = [selected[0] valueForKey:k_key_fileDropExtensions];
    if ([selected count] == 0) {
        return;
    } else if (extension == nil) {
        extension = @"";
    }
    
    NSString *message = [NSString stringWithFormat:NSLocalizedString(@"Delete the File Drop setting for “%@”?", nil), extension];
    NSAlert *alert = [NSAlert alertWithMessageText:message
                                     defaultButton:NSLocalizedString(@"Cancel", nil)
                                   alternateButton:NSLocalizedString(@"Delete", nil) otherButton:nil
                         informativeTextWithFormat:NSLocalizedString(@"Deleted setting cannot be restored.", nil)];
    
    [alert beginSheetModalForWindow:[[self view] window]
                      modalDelegate:self
                     didEndSelector:@selector(deleteFileDropSettingAlertDidEnd:returnCode:contextInfo:)
                        contextInfo:NULL];
}


// ------------------------------------------------------
/// ファイルドロップ編集設定の追加行の編集開始
- (void)editNewAddedRowOfFileDropTableView
// ------------------------------------------------------
{
    [[self fileDropTableView] editColumn:0 row:[[self fileDropTableView] selectedRow] withEvent:nil select:YES];
}


// ------------------------------------------------------
/// ファイルドロップ編集設定削除確認シートが閉じる直前
- (void)deleteFileDropSettingAlertDidEnd:(NSAlert *)alert returnCode:(NSInteger)returnCode contextInfo:(void *)contextInfo
// ------------------------------------------------------
{
    if (returnCode != NSAlertAlternateReturn) { return; } // != Delete
    
    if ([[self fileDropController] selectionIndex] == NSNotFound) { return; }
    
    if ([self doDeleteFileDrop]) {
        [[self fileDropController] remove:self];
        [self writeBackFileDropArray];
        [self setDoDeleteFileDrop:NO];
    }
}

@end
