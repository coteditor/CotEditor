/*
 ==============================================================================
 CEFileDropPaneController
 
 CotEditor
 http://coteditor.github.io
 
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
@property (nonatomic, weak) IBOutlet NSTableView *fileDropTableView;
@property (nonatomic, strong) IBOutlet NSTextView *fileDropTextView;  // on 10.8 NSTextView cannot be weak
@property (nonatomic, strong) IBOutlet NSTextView *glossaryTextView;  // on 10.8 NSTextView cannot be weak

@property (nonatomic, getter=isDeletingFileDrop) BOOL deletingFileDrop;

@end




#pragma mark -

@implementation CEFileDropPaneController

#pragma mark Superclass Methods

//=======================================================
// Superclass method
//
//=======================================================

// ------------------------------------------------------
/// ビューの読み込み
- (void)loadView
// ------------------------------------------------------
{
    [super loadView];
    
    // 各種セットアップ
    [self setContentFileDropController];
    
    // 用語集をセット
    NSURL *glossaryURL = [[NSBundle mainBundle] URLForResource:@"FileDropGlossary" withExtension:@"txt"];
    NSString *glossary = [NSString stringWithContentsOfURL:glossaryURL encoding:NSUTF8StringEncoding error:nil];
    [[self glossaryTextView] setString:glossary];
    
    // FileDrop 配列コントローラの値を確実に書き戻すためにウインドウクローズを監視
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(writeBackFileDropArray)
                                                 name:NSWindowWillCloseNotification
                                               object:[[self view] window]];
}


// ------------------------------------------------------
/// 後片付け
- (void)dealloc
// ------------------------------------------------------
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
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
    if (![[notification object] isKindOfClass:[NSTextField class]]) { return; }
    
    NSString *extension = [[[self fileDropController] selection] valueForKeyPath:CEFileDropExtensionsKey];
    NSString *format = [[[self fileDropController] selection] valueForKeyPath:CEFileDropFormatStringKey];
    
    // 入力されていなければ行ごと削除
    if (!extension && !format) {
        // 削除実行フラグを偽に（編集中に削除ボタンが押され、かつ自動削除対象であったときの整合性を取るためのフラグ）
        [self setDeletingFileDrop:NO];
        [[self fileDropController] remove:self];
        
    } else {
        // フォーマットを整える
        NSCharacterSet *trimSet = [NSCharacterSet characterSetWithCharactersInString:@"./ \t\r\n"];
        NSArray *components = [extension componentsSeparatedByString:@","];
        NSMutableArray *newComponents = [NSMutableArray array];
        
        for (NSString *component in components) {
            NSString *partStr = [component stringByTrimmingCharactersInSet:trimSet];
            if ([partStr length] > 0) {
                [newComponents addObject:partStr];
            }
        }
        NSString *newExtension = [newComponents componentsJoinedByString:@", "];
        // 有効な文字列が生成できたら、UserDefaults に書き戻し、直ちに反映させる
        if ([newExtension length] > 0) {
            [[[self fileDropController] selection] setValue:newExtension forKey:CEFileDropExtensionsKey];
        } else if (!format) {
            [[self fileDropController] remove:self];
        }
    }
    [self writeBackFileDropArray];
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
    __unsafe_unretained typeof(self) weakSelf = self;  // cannot be weak on Lion
    dispatch_async(dispatch_get_main_queue(), ^{
        typeof(self) strongSelf = weakSelf;
        [strongSelf editNewAddedRowOfFileDropTableView];
    });
}


// ------------------------------------------------------
/// ファイルドロップ編集設定の削除ボタンが押された
- (IBAction)deleteFileDropSetting:(id)sender
// ------------------------------------------------------
{
    // (編集中に削除ボタンが押され、かつ自動削除対象であったときの整合性を取るための)削除実施フラグをたてる
    [self setDeletingFileDrop:YES];
    // フォーカスを移し、値入力を確定
    [[sender window] makeFirstResponder:sender];
    // ディレイをかけて controlTextDidEndEditing: の自動編集を実行させる
    __unsafe_unretained typeof(self) weakSelf = self;  // cannot be weak on Lion
    dispatch_async(dispatch_get_main_queue(), ^{
        typeof(self) strongSelf = weakSelf;
        [strongSelf doDeleteFileDropSetting];
    });
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
    [[NSUserDefaults standardUserDefaults] setObject:[[self fileDropController] content] forKey:CEDefaultFileDropArrayKey];
}


// ------------------------------------------------------
/// ファイルドロップ設定編集用コントローラに値をセット
- (void)setContentFileDropController
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
/// ファイルドロップ編集設定の削除を確認
- (void)doDeleteFileDropSetting
// ------------------------------------------------------
{
    // フラグがたっていなければ（既に controlTextDidEndEditing: で自動削除されていれば）何もしない
    if (![self isDeletingFileDrop]) { return; }
    
    NSArray *selected = [[self fileDropController] selectedObjects];
    NSString *extension = selected[0][CEFileDropExtensionsKey];
    if ([selected count] == 0) {
        return;
    } else if (!extension) {
        extension = @"";
    }
    
    NSString *message = [NSString stringWithFormat:NSLocalizedString(@"Delete the File Drop setting for “%@”?", nil), extension];
    NSAlert *alert = [[NSAlert alloc] init];
    [alert setMessageText:message];
    [alert setInformativeText:NSLocalizedString(@"Deleted setting cannot be restored.", nil)];
    [alert addButtonWithTitle:NSLocalizedString(@"Cancel", nil)];
    [alert addButtonWithTitle:NSLocalizedString(@"Delete", nil)];
    
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
    if (returnCode != NSAlertSecondButtonReturn) { return; } // != Delete
    
    if ([[self fileDropController] selectionIndex] == NSNotFound) { return; }
    
    if ([self isDeletingFileDrop]) {
        [[self fileDropController] remove:self];
        [self writeBackFileDropArray];
        [self setDeletingFileDrop:NO];
    }
}

@end
