/*
 
 CEFileDropPaneController.m
 
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

#import "CEFileDropPaneController.h"
#import "Constants.h"


@interface CEFileDropPaneController () <NSTableViewDelegate, NSTextFieldDelegate, NSTextViewDelegate>

@property (nonatomic, nullable) IBOutlet NSArrayController *fileDropController;
@property (nonatomic, nullable, weak) IBOutlet NSTableView *extensionTableView;
@property (nonatomic, nullable, strong) IBOutlet NSTextView *formatTextView;  // on 10.8 NSTextView cannot be weak
@property (nonatomic, nullable, strong) IBOutlet NSTextView *glossaryTextView;  // on 10.8 NSTextView cannot be weak

@property (nonatomic, getter=isDeletingFileDrop) BOOL deletingFileDrop;

@end




#pragma mark -

@implementation CEFileDropPaneController

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



#pragma mark Delegate

//=======================================================
// NSTableViewDelegate  < extensionTableView
//=======================================================

// ------------------------------------------------------
/// 拡張子テーブルが編集された
- (void)controlTextDidEndEditing:(nonnull NSNotification *)notification
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
- (void)tableView:(nonnull NSTableView *)tableView didAddRowView:(nonnull NSTableRowView *)rowView forRow:(NSInteger)row
// ------------------------------------------------------
{
    BOOL isLastRow = ([tableView numberOfRows] - 1 == row);
    NSTextField *textField = [[rowView viewAtColumn:0] textField];
    
    if (isLastRow && [[textField stringValue] length] == 0) {
        [tableView editColumn:0 row:row withEvent:nil select:YES];
    }
}


#if MAC_OS_X_VERSION_MAX_ALLOWED >= 101100
// ------------------------------------------------------
/// set action on swiping theme name (on El Capitan and leter)
- (nonnull NSArray<NSTableViewRowAction *> *)tableView:(nonnull NSTableView *)tableView rowActionsForRow:(NSInteger)row edge:(NSTableRowActionEdge)edge
// ------------------------------------------------------
{
    if (edge == NSTableRowActionEdgeLeading) { return @[]; }
    
    // Delete
    return @[[NSTableViewRowAction rowActionWithStyle:NSTableViewRowActionStyleDestructive
                                                title:NSLocalizedString(@"Delete", nil)
                                              handler:^(NSTableViewRowAction *action, NSInteger row)
              {
                  [self setDeletingFileDrop:YES];
                  [self deleteSettingAtIndex:row];
              }]];
}
#endif  // MAC_OS_X_VERSION_10_11


//=======================================================
// NSTextViewDelegate  < formatTextView
//=======================================================

// ------------------------------------------------------
/// FileDrop 挿入文字列フォーマットテキストビューが編集された
- (void)textDidEndEditing:(nonnull NSNotification *)notification
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
- (IBAction)insertToken:(nullable id)sender
// ------------------------------------------------------
{
    NSString *title = [(NSMenuItem *)sender title];
    NSTextView *textView = [self formatTextView];
    
    [[[self view] window] makeFirstResponder:textView];
    if ([textView shouldChangeTextInRange:[textView selectedRange] replacementString:title]) {
        [[textView textStorage] replaceCharactersInRange:[textView selectedRange] withString:title];
        [textView didChangeText];
    }
}


// ------------------------------------------------------
/// ファイルドロップ編集設定を追加
- (IBAction)addSetting:(nullable id)sender
// ------------------------------------------------------
{
    // フォーカスを移し、値入力を確定
    [[sender window] makeFirstResponder:sender];
    
    [[self fileDropController] add:self];
}


// ------------------------------------------------------
/// ファイルドロップ編集設定の削除ボタンが押された
- (IBAction)removeSetting:(nullable id)sender
// ------------------------------------------------------
{
    NSInteger selectedRow = [[self extensionTableView] selectedRow];
    
    if (selectedRow == -1) { return; }
    
    // (編集中に削除ボタンが押され、かつ自動削除対象であったときの整合性を取るための)削除実施フラグをたてる
    [self setDeletingFileDrop:YES];
    
    // フォーカスを移し、値入力を確定
    [[sender window] makeFirstResponder:sender];
    
    // 確認ダイアログを出す
    [self deleteSettingAtIndex:selectedRow];
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
- (nullable NSString *)sanitizeExtensionsString:(nullable NSString *)extensionsString
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
- (void)deleteSettingAtIndex:(NSUInteger)rowIndex
// ------------------------------------------------------
{
    // フラグがたっていなければ（既に controlTextDidEndEditing: で自動削除されていれば）何もしない
    if (![self isDeletingFileDrop]) { return; }
    
    NSDictionary *item = [[self fileDropController] arrangedObjects][rowIndex];
    NSString *extension = item ? item[CEFileDropExtensionsKey] : @"";
    
    NSAlert *alert = [[NSAlert alloc] init];
    [alert setMessageText:[NSString stringWithFormat:NSLocalizedString(@"Delete the File Drop setting for “%@”?", nil), extension]];
    [alert setInformativeText:NSLocalizedString(@"Deleted setting cannot be restored.", nil)];
    [alert addButtonWithTitle:NSLocalizedString(@"Cancel", nil)];
    [alert addButtonWithTitle:NSLocalizedString(@"Delete", nil)];
    
    [alert beginSheetModalForWindow:[[self view] window]
                      modalDelegate:self
                     didEndSelector:@selector(deleteSettingAlertDidEnd:returnCode:contextInfo:)
                        contextInfo:rowIndex];
}


// ------------------------------------------------------
/// ファイルドロップ編集設定削除確認シートが閉じる直前
- (void)deleteSettingAlertDidEnd:(nonnull NSAlert *)alert returnCode:(NSInteger)returnCode contextInfo:(nullable void *)contextInfo
// ------------------------------------------------------
{
    if (returnCode != NSAlertSecondButtonReturn) { return; } // != Delete
    
    if (![self isDeletingFileDrop]) { return; }
    
    NSUInteger index = contextInfo;
    
    [[self fileDropController] removeObjectAtArrangedObjectIndex:index];
    [self storeSetting];
    [self setDeletingFileDrop:NO];
}

@end
