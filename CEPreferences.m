/*
=================================================
CEPreferences
(for CotEditor)

 Copyright (C) 2004-2007 nakamuxu.
 Copyright (C) 2014 CotEditor Project
 http://coteditor.github.io
=================================================

encoding="UTF-8"
Created:2004.12.13

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

#import "CEPreferences.h"
#import "CEAppController.h"

//=======================================================
// Private method
//
//=======================================================

@interface CEPreferences (Private)
- (void)updateUserDefaults;
- (void)setFontFamilyNameAndSize;
- (void)setContentFileDropController;
- (void)setupInvisibleSpacePopup;
- (void)setupInvisibleTabPopup;
- (void)setupInvisibleNewLinePopup;
- (void)setupInvisibleFullwidthSpacePopup;
- (void)setupSyntaxStylesPopup;
- (void)deleteStyleAlertDidEnd:(NSAlert *)inAlert 
        returnCode:(NSInteger)inReturnCode contextInfo:(void *)inContextInfo;
- (void)secondarySheedlDidEnd:(NSAlert *)inSheet 
        returnCode:(NSInteger)inReturnCode contextInfo:(void *)inContextInfo;
- (void)autoDetectAlertDidEnd:(NSAlert *)inSheet 
        returnCode:(NSInteger)inReturnCode contextInfo:(void *)inContextInfo;
- (void)doImport:(NSURL *)fileURL withCurrentSheetWindow:(NSWindow *)inWindow;
- (void)doDeleteFileDropSetting;
- (void)deleteFileDropSettingAlertDidEnd:(NSAlert *)inAlert 
        returnCode:(NSInteger)inReturnCode contextInfo:(void *)inContextInfo;
- (void)editNewAddedRowOfFileDropTableView;
@end


//------------------------------------------------------------------------------------------




@implementation CEPreferences

#pragma mark ===== Public method =====

//=======================================================
// Public method
//
//=======================================================

// ------------------------------------------------------
- (instancetype)initWithAppController:(id)inAppController
// 初期化
// ------------------------------------------------------
{
    self = [super init];
    _appController = [inAppController retain];
    _currentSheetCode = k_syntaxNoSheetTag;
    (void)[NSBundle loadNibNamed:@"Preferences" owner:self];
    _doDeleteFileDrop = NO;

    return self;
}


// ------------------------------------------------------
- (void)dealloc
// あとかたづけ
// ------------------------------------------------------
{
    // NSBundle loadNibNamed: でロードされたオブジェクトを開放
    [_encodingWindow release]; // （コンテントビューは自動解放される）
    [_sizeSampleWindow release];
    [_prefWindow release];
    [_fileDropController release];

    [_appController release];

    [super dealloc];
}


// ------------------------------------------------------
- (void)setupEncodingMenus:(NSArray *)inMenuItems
// エンコーディング設定メニューを生成
// ------------------------------------------------------
{
    id theValues = [[NSUserDefaultsController sharedUserDefaultsController] values];
    NSString *theTitle;
    NSMenuItem *theItem;
    NSUInteger theSelected;

    [_encodingMenuInOpen removeAllItems];
    theItem = [[[NSMenuItem alloc] initWithTitle:NSLocalizedString(@"Auto-Detect",@"") 
                    action:nil keyEquivalent:@""] autorelease];
    [theItem setTag:k_autoDetectEncodingMenuTag];
    [[_encodingMenuInOpen menu] addItem:theItem];
    [[_encodingMenuInOpen menu] addItem:[NSMenuItem separatorItem]];
    [_encodingMenuInNew removeAllItems];

    for (NSMenuItem *menuItem in inMenuItems) {
        [[_encodingMenuInOpen menu] addItem:[[menuItem copy] autorelease]];
        [[_encodingMenuInNew menu] addItem:[[menuItem copy] autorelease]];
    }
    // (エンコーディング設定メニューはバインディングを使っているが、タグの選択がバインディングで行われた後に
    // メニューが追加／削除されるため、結果的に選択がうまく動かない。しかたないので、コードから選択している)
    theSelected = [[theValues valueForKey:k_key_encodingInOpen] unsignedLongValue];
    if (theSelected == k_autoDetectEncodingMenuTag) {
        theTitle = NSLocalizedString(@"Auto-Detect",@"");
    } else {
        theTitle = [NSString localizedNameOfStringEncoding:theSelected];
    }
    [_encodingMenuInOpen selectItemWithTitle:theTitle];
    theTitle = [NSString localizedNameOfStringEncoding:
                [[theValues valueForKey:k_key_encodingInNew] unsignedLongValue]];
    [_encodingMenuInNew selectItemWithTitle:theTitle];
}


// ------------------------------------------------------
- (void)setupSyntaxMenus
// シンタックスカラーリングスタイル選択メニューを生成
// ------------------------------------------------------
{
    [self setupSyntaxStylesPopup];
    [self changedSyntaxStylesPopup:self];
}


// ------------------------------------------------------
- (void)openPrefWindow
// 環境設定パネルを開く
// ------------------------------------------------------
{
    if (![_prefWindow isVisible]) {
        [self setFontFamilyNameAndSize];
        // 拡張子重複エラー表示ボタンの有効化を制御
        [_syntaxStyleXtsnErrButton setEnabled:
                [[CESyntaxManager sharedInstance] existsExtensionError]];

        [_prefWindow center];
    }
    [_prefWindow makeKeyAndOrderFront:self];
}


// ------------------------------------------------------
- (void)closePrefWindow
// 環境設定パネルを閉じる
// ------------------------------------------------------
{
    [_prefWindow close];
}


// ------------------------------------------------------
- (CGFloat)sampleWidth
// サンプルウィンドウの幅を得る
// ------------------------------------------------------
{
    return _sampleWidth;
}


// ------------------------------------------------------
- (void)setSampleWidth:(CGFloat)inWidth
// サンプルウィンドウの幅をセット
// ------------------------------------------------------
{
    if ((inWidth < k_minWindowSize) || (inWidth > k_maxWindowSize)) {return;}
    _sampleWidth = inWidth;
}


// ------------------------------------------------------
- (CGFloat)sampleHeight
// サンプルウィンドウの高さをセット
// ------------------------------------------------------
{
    return _sampleHeight;
}


// ------------------------------------------------------
- (void)setSampleHeight:(CGFloat)inHeight
// サンプルウィンドウの高さを得る
// ------------------------------------------------------
{
    if ((inHeight < k_minWindowSize) || (inHeight > k_maxWindowSize)) {return;}
    _sampleHeight = inHeight;
}


// ------------------------------------------------------
- (void)changeFont:(id)sender
// フォントパネルでフォントが変更された
// ------------------------------------------------------
{
    // (引数"sender"はNSFontManegerのインスタンス)
    NSUserDefaults *theDefaults = [NSUserDefaults standardUserDefaults];
    NSFont *theNewFont = [sender convertFont:[NSFont systemFontOfSize:0]];
    NSString *theName = [theNewFont fontName];
    CGFloat theSize = [theNewFont pointSize];

    if ([[[_prefTabView selectedTabViewItem] identifier] isEqualToString:k_prefFormatItemID]) {
        [theDefaults setObject:theName forKey:k_key_fontName];
        [theDefaults setFloat:theSize forKey:k_key_fontSize];
        [self setFontFamilyNameAndSize];
    } else if ([[[_prefTabView selectedTabViewItem] identifier] isEqualToString:k_prefPrintItemID]) {
        [theDefaults setObject:theName forKey:k_key_printFontName];
        [theDefaults setFloat:theSize forKey:k_key_printFontSize];
        [self setFontFamilyNameAndSize];
    }
    
    for (CEDocument *document in [[NSDocumentController sharedDocumentController] documents]) {
        [document setFontToViewInWindow];
    }
}


// ------------------------------------------------------
- (void)makeFirstResponderToPrefWindow
// _prefWindow を FirstResponder にする
// ------------------------------------------------------
{
    [_prefWindow makeFirstResponder:_prefWindow];
    [self updateUserDefaults];
}


// ------------------------------------------------------
- (void)writeBackFileDropArray
// FileDrop 設定を UserDefaults に書き戻す
// ------------------------------------------------------
{
    NSUserDefaults *theDefaults = [NSUserDefaults standardUserDefaults];
    [theDefaults setObject:[_fileDropController content] forKey:k_key_fileDropArray];
}



#pragma mark ===== Protocol =====

//=======================================================
// NSNibAwaking Protocol
//
//=======================================================

// ------------------------------------------------------
- (void)awakeFromNib
// Nibファイル読み込み直後
// ------------------------------------------------------
{
    [self setupInvisibleSpacePopup];
    [self setupInvisibleTabPopup];
    [self setupInvisibleNewLinePopup];
    [self setupInvisibleFullwidthSpacePopup];
    [self setupSyntaxMenus];
    [self setContentFileDropController];

    [_fileDropTextView setContinuousSpellCheckingEnabled:NO]; // IBでの設定が効かないのでここで、実行
    [_encodingMenuInOpen setAction:@selector(checkSelectedItemOfEncodingMenuInOpen:)];
    // （Nibファイルの用語説明部分は直接NSTextViewに記入していたが、AppleGlot3.4から読み取れなくなり、ローカライズ対象にできなくなってしまった。その回避処理として、Localizable.stringsファイルに書き込むこととしたために、文字列をセットする処理が必要になった。
    // 2008.07.15.
    [_fileDropGlossaryTextView setString:NSLocalizedString(@"<<<ABSOLUTE-PATH>>>\nThe dropped file's absolute path.\n\n<<<RELATIVE-PATH>>>\nThe relative path between the dropped file and the document.\n\n<<<FILENAME>>>\nThe dropped file's name with extension (if exists).\n\n<<<FILENAME-NOSUFFIX>>>\nThe dropped file's name without extension.\n\n<<<FILEEXTENSION>>>\nThe dropped file's extension.\n\n<<<FILEEXTENSION-LOWER>>>\nThe dropped file's extension (converted to lowercase).\n\n<<<FILEEXTENSION-UPPER>>>\nThe dropped file's extension (converted to uppercase).\n\n<<<DIRECTORY>>>\nThe parent directory name of the dropped file.\n\n<<<IMAGEWIDTH>>>\n(if the dropped file is Image) The image width.\n\n<<<IMAGEHEIGHT>>>\n(if the dropped file is Image) The image height.",@"")];

    
    [_prefWindow setShowsToolbarButton:NO];
}



#pragma mark === Delegate and Notification ===

//=======================================================
// Selector for Notification (NSApplication)
//  <== _prefWindow
//=======================================================

// ------------------------------------------------------
- (void)windowDidResignKey:(NSNotification *)inNotification
// prefWindow がキーウィンドウではなくなった
// ------------------------------------------------------
{
    [self makeFirstResponderToPrefWindow]; // 編集中の設定値も保存
}


//=======================================================
// Selector for Notification (NSTableView)
//  <== _fileDropTableView
//=======================================================

// ------------------------------------------------------
- (void)controlTextDidEndEditing:(NSNotification *)inNotification
// FileDrop 拡張子テーブルビューが編集された
// ------------------------------------------------------
{
    if ([inNotification object] == _fileDropTableView) {
        NSString *theXtsnStr = [[_fileDropController selection] valueForKey:k_key_fileDropExtensions];
        NSString *theFormatStr = [[_fileDropController selection] valueForKey:k_key_fileDropFormatString];

        // 入力されていなければ行ごと削除
        if ((theXtsnStr == nil) && (theFormatStr == nil)) {
            // 削除実行フラグを偽に（編集中に削除ボタンが押され、かつ自動削除対象であったときの整合性を取るためのフラグ）
            _doDeleteFileDrop = NO;
            [_fileDropController remove:self];
        } else {
            // フォーマットを整える
            NSCharacterSet *theTrimSet = [NSCharacterSet characterSetWithCharactersInString:@"./ \t\r\n"];
            NSArray *theComponents = [theXtsnStr componentsSeparatedByString:@","];
            NSMutableArray *theNewComps = [NSMutableArray array];
            NSString *thePartStr, *theNewXtsnStr;

            for (NSString *component in theComponents) {
                thePartStr = [component stringByTrimmingCharactersInSet:theTrimSet];
                if ([thePartStr length] > 0) {
                    [theNewComps addObject:thePartStr];
                }
            }
            theNewXtsnStr = [theNewComps componentsJoinedByString:@", "];
            // 有効な文字列が生成できたら、UserDefaults に書き戻し、直ちに反映させる
            if ((theNewXtsnStr != nil) && ([theNewXtsnStr length] > 0)) {
                [[_fileDropController selection] setValue:theNewXtsnStr forKey:k_key_fileDropExtensions];
            } else if (theFormatStr == nil) {
                [_fileDropController remove:self];
            }
        }
        [self writeBackFileDropArray];
    }
}


//=======================================================
// Selector for Notification (NSTextView)
//  <== _fileDropTextView
//=======================================================

// ------------------------------------------------------
- (void)textDidEndEditing:(NSNotification *)inNotification
// FileDrop 挿入文字列フォーマットテキストビューが編集された
// ------------------------------------------------------
{
    if ([inNotification object] == _fileDropTextView) {
        // UserDefaults に書き戻し、直ちに反映させる
        [self writeBackFileDropArray];
    }
}



#pragma mark ===== Action messages =====

//=======================================================
// Action messages
//
//=======================================================

// ------------------------------------------------------
- (IBAction)showFonts:(id)sender
// フォントパネルを表示
//-------------------------------------------------------
{
    id theValues = [[NSUserDefaultsController sharedUserDefaultsController] values];
    NSFontManager *theManager = [NSFontManager sharedFontManager];
    NSFont *theFont;

    if ([[[_prefTabView selectedTabViewItem] identifier] isEqualToString:k_prefPrintItemID]) {
        theFont = [NSFont fontWithName:[theValues valueForKey:k_key_printFontName] 
                    size:(CGFloat)[[theValues valueForKey:k_key_printFontSize] doubleValue]];
    } else {
        theFont = [NSFont fontWithName:[theValues valueForKey:k_key_fontName] 
                    size:(CGFloat)[[theValues valueForKey:k_key_fontSize] doubleValue]];
    }

    [_prefWindow makeFirstResponder:_prefWindow];
    [theManager setSelectedFont:theFont isMultiple:NO];
    [theManager orderFrontFontPanel:sender];
}


// ------------------------------------------------------
- (IBAction)openEncodingEditSheet:(id)sender
// エンコーディングリスト編集シートを開き、閉じる
// ------------------------------------------------------
{
    // データソースをセットアップ、シートを表示してモーダルループに入る(閉じる命令は closeEncodingEditSheet: で)
    [_encodingDataSource setupEncodingsToEdit];
    [NSApp beginSheet:_encodingWindow 
            modalForWindow:_prefWindow 
            modalDelegate:self 
            didEndSelector:NULL 
            contextInfo:NULL];
    [NSApp runModalForWindow:_encodingWindow];

    // シートを閉じる
    [NSApp endSheet:_encodingWindow];
    [_encodingWindow orderOut:self];
    [_prefWindow makeKeyAndOrderFront:self];
}


// ------------------------------------------------------
- (IBAction)closeEncodingEditSheet:(id)sender
// エンコーディングリスト編集シートの OK / Cancel ボタンが押された
// ------------------------------------------------------
{
    if ([sender tag] == k_okButtonTag) { // ok のとき
        [_encodingDataSource writeEncodingsToUserDefaults]; // エンコーディングを保存
        [_appController buildAllEncodingMenus];
    }
    [NSApp stopModal];
}


// ------------------------------------------------------
- (IBAction)openSizeSampleWindow:(id)sender
// サイズ設定のためのサンプルウィンドウを開く
// ------------------------------------------------------
{
    id theValues = [[NSUserDefaultsController sharedUserDefaultsController] values];
    NSSize theSize = NSMakeSize((CGFloat)[[theValues valueForKey:k_key_windowWidth] doubleValue],
                                (CGFloat)[[theValues valueForKey:k_key_windowHeight] doubleValue]);

    [_sizeSampleWindow setContentSize:theSize];
    [_sizeSampleWindow makeKeyAndOrderFront:self];
    // モーダルで表示
    [NSApp runModalForWindow:_sizeSampleWindow];

    // サンプルウィンドウを閉じる
    [_sizeSampleWindow orderOut:self];
    [_prefWindow makeKeyAndOrderFront:self];

}


// ------------------------------------------------------
- (IBAction)setWindowContentSizeToDefault:(id)sender
// サンプルウィンドウの内部サイズをuserDefaultsにセット
// ------------------------------------------------------
{
    if ([sender tag] == k_okButtonTag) { // ok のときサイズを保存
        NSUserDefaults *theDefaults = [NSUserDefaults standardUserDefaults];

        [theDefaults setFloat:_sampleWidth forKey:k_key_windowWidth];
        [theDefaults setFloat:_sampleHeight forKey:k_key_windowHeight];
    }
    [NSApp stopModal];
}


// ------------------------------------------------------
- (IBAction)openSyntaxEditSheet:(id)sender
// カラーシンタックス編集シートを開き、閉じる
// ------------------------------------------------------
{
    NSInteger theSelected = [_syntaxStylesPopup indexOfSelectedItem] - 2; // "None"とセパレータ分のオフセット
    if (([sender tag] != k_syntaxNewTag) && (theSelected < 0)) { return; }

    if (![[CESyntaxManager sharedInstance] setSelectionIndexOfStyle:theSelected mode:[sender tag]]) {
        return;
    }
    NSString *theOldName = [_syntaxStylesPopup titleOfSelectedItem];

    // シートウィンドウを表示してモーダルループに入る
    // (閉じる命令は CESyntaxManagerのcloseSyntaxEditSheet: で)
    NSWindow *theSheet = [[CESyntaxManager sharedInstance] editWindow];

    [NSApp beginSheet:theSheet 
            modalForWindow:_prefWindow 
            modalDelegate:self 
            didEndSelector:NULL 
            contextInfo:NULL];
    [NSApp runModalForWindow:theSheet];


    // === 以下、シートを閉じる処理
    // OKボタンが押されていたとき（キャンセルでも、最初の状態に戻していいかもしれない (1/21)） ********
    if ([[CESyntaxManager sharedInstance] isOkButtonPressed]) {
        // 当該スタイルを適用しているドキュメントに前面に出たときの再カラーリングフラグを立てる
        NSString *theNewName = [[CESyntaxManager sharedInstance] editedNewStyleName];
        NSDictionary *theDict = @{k_key_oldStyleName: theOldName, 
                k_key_newStyleName: theNewName};
        [[CEDocumentController sharedDocumentController] 
                setRecolorFlagToAllDocumentsWithStyleName:theDict];
        [[CESyntaxManager sharedInstance] setEditedNewStyleName:@""];
        // シンタックスカラーリングスタイル指定メニューを再構成、選択をクリアしてボタン類を有効／無効化
        [_appController buildAllSyntaxMenus];
        // 拡張子重複エラー表示ボタンの有効化を制御
        [_syntaxStyleXtsnErrButton setEnabled:
                [[CESyntaxManager sharedInstance] existsExtensionError]];
    }
    // シートを閉じる
    [NSApp endSheet:theSheet];
    [theSheet orderOut:self];
    [_prefWindow makeKeyAndOrderFront:self];
}


// ------------------------------------------------------
- (IBAction)changedSyntaxStylesPopup:(id)sender
// シンタックスカラーリングスタイル指定メニューまたはカラーリング実施チェックボックスが変更された
// ------------------------------------------------------
{
    BOOL theValue = ([_syntaxStylesPopup indexOfSelectedItem] > 1);

    [_syntaxStyleEditButton setEnabled:theValue];
    [_syntaxStyleCopyButton setEnabled:theValue];
    [_syntaxStyleExportButton setEnabled:theValue];

    if (theValue && (![[CESyntaxManager sharedInstance] isDefaultSyntaxStyle:
                [_syntaxStylesPopup title]])) {
        [_syntaxStyleDeleteButton setEnabled:YES];
    } else {
        [_syntaxStyleDeleteButton setEnabled:NO];
    }
}


// ------------------------------------------------------
- (IBAction)deleteSyntaxStyle:(id)sender
// シンタックスカラーリングスタイル削除ボタンが押された
// ------------------------------------------------------
{
    NSInteger theSelected = [_syntaxStylesPopup indexOfSelectedItem] - 2;

    if (![[CESyntaxManager sharedInstance] setSelectionIndexOfStyle:theSelected 
            mode:k_syntaxNoSheetTag]) {
        return;
    }
    NSString *theMessage = [NSString stringWithFormat:
                NSLocalizedString(@"Delete the Syntax coloring style \"%@\" ?",@""), 
                [_syntaxStylesPopup title]];
    NSAlert *theAlert = 
            [NSAlert alertWithMessageText:theMessage 
            defaultButton:NSLocalizedString(@"Cancel",@"") 
            alternateButton:NSLocalizedString(@"Delete",@"") otherButton:nil 
            informativeTextWithFormat:NSLocalizedString(@"Deleted style cannot be restored.",@"")];

    [theAlert beginSheetModalForWindow:_prefWindow 
            modalDelegate:self 
            didEndSelector:@selector(deleteStyleAlertDidEnd:returnCode:contextInfo:) contextInfo:NULL];
}


// ------------------------------------------------------
- (IBAction)importSyntaxStyle:(id)sender
// シンタックスカラーリングスタイルインポートボタンが押された
// ------------------------------------------------------
{
    NSOpenPanel *openPanel = [NSOpenPanel openPanel];

    // OpenPanelをセットアップ(既定値を含む)、シートとして開く
    [openPanel setPrompt:NSLocalizedString(@"Import",@"")];
    [openPanel setResolvesAliases:YES];
    [openPanel setAllowsMultipleSelection:NO];
    [openPanel setCanChooseDirectories:NO];
    [openPanel setAllowedFileTypes:@[@"plist"]];
    
    [openPanel beginSheetModalForWindow:_prefWindow completionHandler:^(NSInteger result) {
        if (result == NSFileHandlingPanelCancelButton) return;
        
        NSURL *URL = [openPanel URLs][0];
        NSString *styleName = [[URL lastPathComponent] stringByDeletingPathExtension];
        
        // 同名styleが既にあるときは、置換してもいいか確認
        if ([[CESyntaxManager sharedInstance] existsStyleFileWithStyleName:styleName]) {
            // オープンパネルを閉じる
            [openPanel orderOut:self];
            [_prefWindow makeKeyAndOrderFront:self];
            
            NSAlert *theAlert;
            NSString *theMessage = [NSString stringWithFormat:
                                    NSLocalizedString(@"the \"%@\" style already exists.", @""), styleName];
            theAlert = [NSAlert alertWithMessageText:theMessage
                                       defaultButton:NSLocalizedString(@"Cancel",@"")
                                     alternateButton:NSLocalizedString(@"Replace",@"") otherButton:nil
                           informativeTextWithFormat:NSLocalizedString(@"Do you want to replace it ?\nReplaced style cannot be restored.",@"")];
            // 現行シート値を設定し、確認のためにセカンダリシートを開く
            _currentSheetCode = k_syntaxImportTag;
            NSBeep();
            [theAlert beginSheetModalForWindow:_prefWindow modalDelegate:self
                                didEndSelector:@selector(secondarySheedlDidEnd:returnCode:contextInfo:)
                                   contextInfo:[URL retain]]; // ===== retain
            
        } else {
            // 重複するファイル名がないとき、インポート実行
            [self doImport:URL withCurrentSheetWindow:openPanel];
        }
    }];
    
}



// ------------------------------------------------------
- (IBAction)exportSyntaxStyle:(id)sender
// シンタックスカラーリングスタイルエクスポートボタンが押された
// ------------------------------------------------------
{
    NSSavePanel *savePanel = [NSSavePanel savePanel];

    // SavePanelをセットアップ(既定値を含む)、シートとして開く
    [savePanel setCanCreateDirectories:YES];
    [savePanel setCanSelectHiddenExtension:YES];
    [savePanel setNameFieldLabel:NSLocalizedString(@"Export As:",@"")];
    [savePanel setNameFieldStringValue:[_syntaxStylesPopup title]];
    [savePanel setAllowedFileTypes:@[@"plist"]];
    
    [savePanel beginSheetModalForWindow:_prefWindow completionHandler:^(NSInteger result) {
        if (result == NSFileHandlingPanelCancelButton) return;
        
        NSFileManager *fileManager = [NSFileManager defaultManager];
        NSURL *sourceURL = [[CESyntaxManager sharedInstance] URLOfStyle:[_syntaxStylesPopup title]];
        NSURL *destURL = [savePanel URL];
        
        // 同名ファイルが既にあるときは、削除(Replace の確認は、SavePanel で自動的に行われている)
        if ([fileManager fileExistsAtPath:[destURL path]]) {
            [fileManager removeItemAtURL:destURL error:nil];
        }
        [fileManager copyItemAtURL:sourceURL toURL:destURL error:nil];
    }];
}


// ------------------------------------------------------
- (IBAction)openSyntaxExtensionErrorSheet:(id)sender
// カラーシンタックス拡張子重複エラー表示シートを開き、閉じる
// ------------------------------------------------------
{
    // シートウィンドウを表示してモーダルループに入る
    // (閉じる命令は CESyntaxManagerのcloseSyntaxEditSheet: で)
    NSWindow *theSheet = [[CESyntaxManager sharedInstance] extensionErrorWindow];

    [NSApp beginSheet:theSheet 
            modalForWindow:_prefWindow 
            modalDelegate:self 
            didEndSelector:NULL 
            contextInfo:NULL];
    [NSApp runModalForWindow:theSheet];

    // シートを閉じる
    [NSApp endSheet:theSheet];
    [theSheet orderOut:self];
    [_prefWindow makeKeyAndOrderFront:self];
}


// ------------------------------------------------------
- (IBAction)insertFormatStringInFileDrop:(id)sender
// ファイルドロップ定型文字列挿入メニューが選択された
// ------------------------------------------------------
{
    NSString *theStr = [(NSMenuItem *)sender title];

    if (theStr) {
        [_prefWindow makeFirstResponder:_fileDropTextView];
        [_fileDropTextView insertText:theStr];
    }
}


// ------------------------------------------------------
- (IBAction)addNewFileDropSetting:(id)sender
// ファイルドロップ編集設定を追加
// ------------------------------------------------------
{
    // フォーカスを移し、値入力を確定
    [[sender window] makeFirstResponder:sender];

    [_prefWindow makeFirstResponder:_fileDropTableView];
    [_fileDropController add:self];

    // ディレイをかけて _fileDropController からのバインディングによる行追加を先に実行させる
    [self performSelector:@selector(editNewAddedRowOfFileDropTableView) withObject:nil afterDelay:0];
}


// ------------------------------------------------------
- (IBAction)deleteFileDropSetting:(id)sender
// ファイルドロップ編集設定の削除ボタンが押された
// ------------------------------------------------------
{
    // (編集中に削除ボタンが押され、かつ自動削除対象であったときの整合性を取るための)削除実施フラグをたてる
    _doDeleteFileDrop = YES;
    // フォーカスを移し、値入力を確定
    [[sender window] makeFirstResponder:sender];
    // ディレイをかけて controlTextDidEndEditing: の自動編集を実行させる
    [self performSelector:@selector(doDeleteFileDropSetting) withObject:nil afterDelay:0];
}


// ------------------------------------------------------
- (IBAction)openKeyBindingEditSheet:(id)sender
// キーバインディング編集シートを開き、閉じる
// ------------------------------------------------------
{
    // シートウィンドウを表示してモーダルループに入る
    // (閉じる命令は CEKeyBindingManager の closeKeyBindingEditSheet: で)
    NSWindow *theSheet = [[CEKeyBindingManager sharedInstance] editSheetWindowOfMode:[sender tag]];

    if ((theSheet != nil) && 
            ([[CEKeyBindingManager sharedInstance] setupOutlineDataOfMode:[sender tag]])) {
        [NSApp beginSheet:theSheet 
                modalForWindow:_prefWindow 
                modalDelegate:self 
                didEndSelector:NULL 
                contextInfo:NULL];
        [NSApp runModalForWindow:theSheet];
    } else {
        return;
    }

    // シートを閉じる
    [NSApp endSheet:theSheet];
    [theSheet orderOut:self];
    [_prefWindow makeKeyAndOrderFront:self];
}


//------------------------------------------------------
- (IBAction)setupCustomLineSpacing:(id)sender
// 行間値を調整
//------------------------------------------------------
{
    // IB で Formatter が設定できないのでメソッドで行ってる。

    CGFloat theValue = (CGFloat)[sender doubleValue];

    if (theValue < k_lineSpacingMin) { theValue = k_lineSpacingMin; }
    if (theValue > k_lineSpacingMax) { theValue = k_lineSpacingMax; }

    [sender setStringValue:[NSString stringWithFormat:@"%.2f", theValue]];
}


//------------------------------------------------------
- (IBAction)checkSelectedItemOfEncodingMenuInOpen:(id)sender
// 既存のファイルを開くエンコーディングが変更されたとき、選択項目をチェック
//------------------------------------------------------
{
    NSString *theNewTitle = [NSString stringWithString:[[_encodingMenuInOpen selectedItem] title]];
    // ファイルを開くエンコーディングをセット
    // （オープンダイアログのエンコーディングポップアップメニューが、デフォルトエンコーディング値の格納場所を兼ねている）
    [[CEDocumentController sharedDocumentController] setSelectAccessoryEncodingMenuToDefault:self];

    if ([theNewTitle isEqualToString:NSLocalizedString(@"Auto-Detect",@"")]) { return; }

    NSString *theMessage = [NSString stringWithFormat:
                NSLocalizedString(@"Are you sure you want to change to \"%@\"?",@""), 
                theNewTitle];
    NSString *altButtonTitle = [NSString stringWithFormat:
                NSLocalizedString(@"Change to \"%@\"",@""), 
                theNewTitle];
    NSAlert *theAlert = 
            [NSAlert alertWithMessageText:theMessage 
            defaultButton:NSLocalizedString(@"Revert to \"Auto-Detect\"",@"") 
            alternateButton:altButtonTitle otherButton:nil 
            informativeTextWithFormat:NSLocalizedString(@"The default \"Auto-Detect\" is recommended for most cases.",@"")];

    NSBeep();
    [theAlert beginSheetModalForWindow:_prefWindow 
            modalDelegate:self 
            didEndSelector:@selector(autoDetectAlertDidEnd:returnCode:contextInfo:) contextInfo:NULL];
}


//------------------------------------------------------
- (IBAction)openPrefHelp:(id)sender
// ヘルプの環境設定説明部分を開く
//------------------------------------------------------
{
    NSString *theBookName = [[NSBundle mainBundle] objectForInfoDictionaryKey: @"CFBundleHelpBookName"];
    NSArray *theAnchorsArray = @[k_helpPrefAnchors];
    NSInteger theTag = [sender tag];

    if ((theTag >= 0) && (theTag < [theAnchorsArray count])) {
        [[NSHelpManager sharedHelpManager] openHelpAnchor:theAnchorsArray[theTag] 
                    inBook:theBookName];
    }
}



@end



@implementation CEPreferences (Private)

//=======================================================
// Private method
//
//=======================================================

//------------------------------------------------------
- (void)updateUserDefaults
// Force update UserDefaults
//------------------------------------------------------
{
// 下記のページの情報を参考にさせていただきました(2004.12.30)
// http://cocoa.mamasam.com/COCOADEV/2004/02/2/85406.php
    NSUserDefaultsController *theUDC = [NSUserDefaultsController sharedUserDefaultsController];

//    [_fileDropController commitEditing];
    [theUDC commitEditing];
    [theUDC save:self];
}


//------------------------------------------------------
- (void)setFontFamilyNameAndSize
// メインウィンドウのフォントファミリー名とサイズをprefFontFamilyNameSizeに表示させる
//------------------------------------------------------
{
    id theValues = [[NSUserDefaultsController sharedUserDefaultsController] values];

    NSString *theName = [theValues valueForKey:k_key_fontName];
    CGFloat theSize = (CGFloat)[[theValues valueForKey:k_key_fontSize] doubleValue];
    NSFont *theFont = [NSFont fontWithName:theName size:theSize];
    NSString *theLocalizedName = [theFont displayName];

    [_prefFontFamilyNameSize setStringValue:[NSString stringWithFormat:@"%@  (%gpt)",theLocalizedName,theSize]];

    theName = [theValues valueForKey:k_key_printFontName];
    theSize = (CGFloat)[[theValues valueForKey:k_key_printFontSize] doubleValue];
    theFont = [NSFont fontWithName:theName size:theSize];
    theLocalizedName = [theFont displayName];

    [_printFontFamilyNameSize setStringValue:[NSString stringWithFormat:@"%@  (%gpt)",theLocalizedName,theSize]];

}


// ------------------------------------------------------
- (void)setContentFileDropController
// ファイルドロップ設定編集用コントローラに値をセット
// ------------------------------------------------------
{
// バインディングで UserDefaults と直結すると「長さゼロの文字列がセットされた」ときなどにいろいろと不具合が発生するので、
// 起動時に読み込み、変更完了／終了時に下記戻す処理を行う。
// http://www.hmdt-web.net/bbs/bbs.cgi?bbsname=mkino&mode=res&no=203&oyano=203&line=0

    id theValues = [[NSUserDefaultsController sharedUserDefaultsController] values];
    NSMutableArray *theArray = [[[theValues valueForKey:k_key_fileDropArray] mutableCopy] autorelease];

    [_fileDropController setContent:theArray];
}


// ------------------------------------------------------
- (void)setupInvisibleSpacePopup
// 不可視文字表示設定ポップアップメニューを生成
// ------------------------------------------------------
{
    id theValues = [[NSUserDefaultsController sharedUserDefaultsController] values];
    NSString *theTitle;
    NSMenuItem *theItem;
    NSUInteger theSelected;
    NSUInteger i;

    [_invisibleSpacePopup removeAllItems];
    for (i = 0; i < (sizeof(k_invisibleSpaceCharList) / sizeof(unichar)); i++) {
        theTitle = [_appController invisibleSpaceCharacter:i];
        theItem = [[[NSMenuItem alloc] initWithTitle:theTitle action:nil keyEquivalent:@""] autorelease];
        [[_invisibleSpacePopup menu] addItem:theItem];
    }
    // (不可視文字表示設定ポップアップメニューはバインディングを使っているが、タグの選択がバインディングで行われた後に
    // メニューが追加／削除されるため、結果的に選択がうまく動かない。しかたないので、コードから選択している)
    theSelected = [[theValues valueForKey:k_key_invisibleSpace] unsignedIntegerValue];
    [_invisibleSpacePopup selectItemAtIndex:theSelected];
}


// ------------------------------------------------------
- (void)setupInvisibleTabPopup
// 不可視文字表示設定ポップアップメニューを生成
// ------------------------------------------------------
{
    id theValues = [[NSUserDefaultsController sharedUserDefaultsController] values];
    NSString *theTitle;
    NSMenuItem *theItem;
    NSUInteger theSelected;
    NSUInteger i;

    [_invisibleTabPopup removeAllItems];
    for (i = 0; i < (sizeof(k_invisibleTabCharList) / sizeof(unichar)); i++) {
        theTitle = [_appController invisibleTabCharacter:i];
        theItem = [[[NSMenuItem alloc] initWithTitle:theTitle action:nil keyEquivalent:@""] autorelease];
        [[_invisibleTabPopup menu] addItem:theItem];
    }
    // (不可視文字表示設定ポップアップメニューはバインディングを使っているが、タグの選択がバインディングで行われた後に
    // メニューが追加／削除されるため、結果的に選択がうまく動かない。しかたないので、コードから選択している)
    theSelected = [[theValues valueForKey:k_key_invisibleTab] unsignedIntegerValue];
    [_invisibleTabPopup selectItemAtIndex:theSelected];
}


// ------------------------------------------------------
- (void)setupInvisibleNewLinePopup
// 不可視文字表示設定ポップアップメニューを生成
// ------------------------------------------------------
{
    id theValues = [[NSUserDefaultsController sharedUserDefaultsController] values];
    NSString *theTitle;
    NSMenuItem *theItem;
    NSUInteger theSelected;
    NSUInteger i;

    [_invisibleNewLinePopup removeAllItems];
    for (i = 0; i < (sizeof(k_invisibleNewLineCharList) / sizeof(unichar)); i++) {
        theTitle = [_appController invisibleNewLineCharacter:i];
        theItem = [[[NSMenuItem alloc] initWithTitle:theTitle action:nil keyEquivalent:@""] autorelease];
        [[_invisibleNewLinePopup menu] addItem:theItem];
    }
    // (不可視文字表示設定ポップアップメニューはバインディングを使っているが、タグの選択がバインディングで行われた後に
    // メニューが追加／削除されるため、結果的に選択がうまく動かない。しかたないので、コードから選択している)
    theSelected = [[theValues valueForKey:k_key_invisibleNewLine] unsignedIntegerValue];
    [_invisibleNewLinePopup selectItemAtIndex:theSelected];
}


// ------------------------------------------------------
- (void)setupInvisibleFullwidthSpacePopup
// 不可視文字表示設定ポップアップメニューを生成
// ------------------------------------------------------
{
    id theValues = [[NSUserDefaultsController sharedUserDefaultsController] values];
    NSString *theTitle;
    NSMenuItem *theItem;
    NSUInteger theSelected;
    NSUInteger i;

    [_invisibleFullwidthSpacePopup removeAllItems];
    for (i = 0; i < (sizeof(k_invisibleFullwidthSpaceCharList) / sizeof(unichar)); i++) {
        theTitle = [_appController invisibleFullwidthSpaceCharacter:i];
        theItem = [[[NSMenuItem alloc] initWithTitle:theTitle action:nil keyEquivalent:@""] autorelease];
        [[_invisibleFullwidthSpacePopup menu] addItem:theItem];
    }
    // (不可視文字表示設定ポップアップメニューはバインディングを使っているが、タグの選択がバインディングで行われた後に
    // メニューが追加／削除されるため、結果的に選択がうまく動かない。しかたないので、コードから選択している)
    theSelected = [[theValues valueForKey:k_key_invisibleFullwidthSpace] unsignedIntegerValue];
    [_invisibleFullwidthSpacePopup selectItemAtIndex:theSelected];
}


// ------------------------------------------------------
- (void)setupSyntaxStylesPopup
// シンタックスカラーリングスタイル指定ポップアップメニューを生成
// ------------------------------------------------------
{
    id theValues = [[NSUserDefaultsController sharedUserDefaultsController] values];
    NSArray *theStyleNames = [[CESyntaxManager sharedInstance] styleNames];
    NSMenuItem *theItem;
    NSString *theSelectedTitle;
    NSUInteger theSelected;

    [_syntaxStylesPopup removeAllItems];
    [_syntaxStylesDefaultPopup removeAllItems];
    theItem = [[[NSMenuItem alloc] initWithTitle:NSLocalizedString(@"Choose style...",@"") 
                    action:nil keyEquivalent:@""] autorelease];
    [[_syntaxStylesPopup menu] addItem:theItem];
    [[_syntaxStylesPopup menu] addItem:[NSMenuItem separatorItem]];
    theItem = [[[NSMenuItem alloc] initWithTitle:NSLocalizedString(@"None",@"") 
                    action:nil keyEquivalent:@""] autorelease];
    [[_syntaxStylesDefaultPopup menu] addItem:theItem];
    [[_syntaxStylesDefaultPopup menu] addItem:[NSMenuItem separatorItem]];
    
    for (NSString *styleName in theStyleNames) {
        theItem = [[[NSMenuItem alloc] initWithTitle:styleName
                    action:nil keyEquivalent:@""] autorelease];
        [[_syntaxStylesPopup menu] addItem:theItem];
        [[_syntaxStylesDefaultPopup menu] addItem:[[theItem copy] autorelease]];
    }
    // (デフォルトシンタックスカラーリングスタイル指定ポップアップメニューはバインディングを使っているが、
    // タグの選択がバインディングで行われた後にメニューが追加／削除されるため、結果的に選択がうまく動かない。
    // しかたないので、コードから選択している)
    theSelectedTitle = [theValues valueForKey:k_key_defaultColoringStyleName];
    theSelected = [_syntaxStylesDefaultPopup indexOfItemWithTitle:theSelectedTitle];
    if (theSelected != -1) { // no selection
        [_syntaxStylesDefaultPopup selectItemAtIndex:theSelected];
    } else {
        [_syntaxStylesDefaultPopup selectItemAtIndex:0]; // == "None"
    }
}


// ------------------------------------------------------
- (void)deleteStyleAlertDidEnd:(NSAlert *)inAlert 
        returnCode:(NSInteger)inReturnCode contextInfo:(void *)inContextInfo
// style削除確認シートが閉じる直前
// ------------------------------------------------------
{
    if (inReturnCode != NSAlertAlternateReturn) { // != Delete
        return;
    }
    NSString *theOldSelectedName = [[CESyntaxManager sharedInstance] selectedStyleName];

    if (![[CESyntaxManager sharedInstance] removeStyleFileWithStyleName:
                [_syntaxStylesPopup title]]) {
        // 削除できなければ、その旨をユーザに通知
        [[inAlert window] orderOut:self];
        [_prefWindow makeKeyAndOrderFront:self];
        NSAlert *theAlert = [NSAlert alertWithMessageText:NSLocalizedString(@"Error occured.",@"") 
            defaultButton:nil 
            alternateButton:nil otherButton:nil 
            informativeTextWithFormat:NSLocalizedString(@"Sorry, could not delete \"%@\".",@""), 
                    [_syntaxStylesPopup title]];
        NSBeep();
        [theAlert beginSheetModalForWindow:_prefWindow modalDelegate:self 
            didEndSelector:NULL 
            contextInfo:NULL];
        return;
    }
    // 当該スタイルを適用しているドキュメントを"None"スタイルにし、前面に出たときの再カラーリングフラグを立てる
    [[CEDocumentController sharedDocumentController] 
            setNoneAndRecolorFlagToAllDocumentsWithStyleName:theOldSelectedName];
    // シンタックスカラーリングスタイル指定メニューを再構成、選択をクリアしてボタン類を有効／無効化
    [_appController buildAllSyntaxMenus];
    // 拡張子重複エラー表示ボタンの有効化を制御
    [_syntaxStyleXtsnErrButton setEnabled:
            [[CESyntaxManager sharedInstance] existsExtensionError]];
}


// ------------------------------------------------------
- (void)secondarySheedlDidEnd:(NSAlert *)inSheet 
        returnCode:(NSInteger)inReturnCode contextInfo:(void *)inContextInfo
// セカンダリシートが閉じる直前
// ------------------------------------------------------
{
    if (_currentSheetCode == k_syntaxImportTag) {
        if (inReturnCode == NSAlertAlternateReturn) { // = Replace
            [self doImport:inContextInfo withCurrentSheetWindow:[inSheet window]];
        }
        [(NSURL *)inContextInfo release]; // ===== release
    }
}


// ------------------------------------------------------
- (void)autoDetectAlertDidEnd:(NSAlert *)inSheet 
        returnCode:(NSInteger)inReturnCode contextInfo:(void *)inContextInfo
// 既存ファイルを開くときのエンコーディングメニューで自動認識以外が
// 選択されたときの警告シートが閉じる直前
// ------------------------------------------------------
{
    if (inReturnCode == NSAlertDefaultReturn) { // = revert to Auto-Detect
        NSUserDefaults *theDefaults = [NSUserDefaults standardUserDefaults];
        [theDefaults setObject:@(k_autoDetectEncodingMenuTag)
                        forKey:k_key_encodingInOpen];
        // ファイルを開くエンコーディングをセット
        // （オープンダイアログのエンコーディングポップアップメニューが、デフォルトエンコーディング値の格納場所を兼ねている）
        [[CEDocumentController sharedDocumentController] setSelectAccessoryEncodingMenuToDefault:self];
    }
}


// ------------------------------------------------------
- (void)doImport:(NSURL *)fileURL withCurrentSheetWindow:(NSWindow *)inWindow
// styleインポート実行
// ------------------------------------------------------
{
    if ([[CESyntaxManager sharedInstance] importStyleFile:[fileURL path]]) {
        // インポートに成功したら、メニューとボタンを更新
        [_appController buildAllSyntaxMenus];
    } else {
        // インポートできなかったときは、セカンダリシートを閉じ、メッセージシートを表示
        [inWindow orderOut:self];
        [_prefWindow makeKeyAndOrderFront:self];
        NSAlert *theAlert = [NSAlert alertWithMessageText:NSLocalizedString(@"Error occured.",@"") 
            defaultButton:nil 
            alternateButton:nil otherButton:nil 
            informativeTextWithFormat:NSLocalizedString(@"Sorry, could not import \"%@\".",@""), 
                    [fileURL lastPathComponent]];
        NSBeep();
        [theAlert beginSheetModalForWindow:_prefWindow modalDelegate:self 
            didEndSelector:NULL 
            contextInfo:NULL];
    }
    _currentSheetCode = k_syntaxNoSheetTag;
}


// ------------------------------------------------------
- (void)doDeleteFileDropSetting
// ファイルドロップ編集設定の削除を確認
// ------------------------------------------------------
{
    // フラグがたっていなければ（既に controlTextDidEndEditing: で自動削除されていれば）何もしない
    if (!_doDeleteFileDrop) { return; }

    NSArray *theSelected = [_fileDropController selectedObjects];
    NSString *theXtsnStr = [theSelected[0] valueForKey:k_key_fileDropExtensions];
    if ([theSelected count] == 0) {
        return;
    } else if (theXtsnStr == nil) {
        theXtsnStr = @"";
    }

    NSString *theMessage = [NSString stringWithFormat:
                NSLocalizedString(@"Delete the File Drop setting ?\n \"%@\"",@""), theXtsnStr];
    NSAlert *theAlert = 
            [NSAlert alertWithMessageText:theMessage 
            defaultButton:NSLocalizedString(@"Cancel",@"") 
            alternateButton:NSLocalizedString(@"Delete",@"") otherButton:nil 
            informativeTextWithFormat:NSLocalizedString(@"Deleted setting cannot be restored.",@"")];

    [theAlert beginSheetModalForWindow:_prefWindow 
            modalDelegate:self 
            didEndSelector:@selector(deleteFileDropSettingAlertDidEnd:returnCode:contextInfo:) 
            contextInfo:@{@"theXtsnStr": theXtsnStr}];
}


// ------------------------------------------------------
- (void)deleteFileDropSettingAlertDidEnd:(NSAlert *)inAlert 
        returnCode:(NSInteger)inReturnCode contextInfo:(void *)inContextInfo
// ファイルドロップ編集設定削除確認シートが閉じる直前
// ------------------------------------------------------
{
    if (inReturnCode != NSAlertAlternateReturn) { return; } // != Delete

    if ([_fileDropController selectionIndex] == NSNotFound) { return; }

    if (_doDeleteFileDrop) {
        [_fileDropController remove:self];
        [self writeBackFileDropArray];
        _doDeleteFileDrop = NO;
    }
}


// ------------------------------------------------------
- (void)editNewAddedRowOfFileDropTableView
// ファイルドロップ編集設定の追加行の編集開始
// ------------------------------------------------------
{
    [_fileDropTableView editColumn:0 row:[_fileDropTableView selectedRow] withEvent:nil select:YES];
}



@end
