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

#import "CEPreferencesController.h"
#import "CEAppController.h"
#import "CESyntaxExtensionErrorSheetController.h"
#import "constants.h"


@interface CEPreferencesController ()

@property (nonatomic, weak) IBOutlet NSTabView *prefTabView;
@property (nonatomic, weak) IBOutlet NSTextField *prefFontFamilyNameSize;
@property (nonatomic, weak) IBOutlet NSTextField *printFontFamilyNameSize;

@property (nonatomic) IBOutlet NSWindow *encodingWindow;
@property (nonatomic, weak) IBOutlet CEPrefEncodingDataSource *encodingDataSource;
@property (nonatomic, weak) IBOutlet NSPopUpButton *encodingMenuInOpen;
@property (nonatomic, weak) IBOutlet NSPopUpButton *encodingMenuInNew;

@property (nonatomic) IBOutlet NSWindow *sizeSampleWindow;
@property (nonatomic) IBOutlet NSArrayController *fileDropController;
@property (nonatomic, weak) IBOutlet NSTableView *fileDropTableView;
@property (nonatomic, strong) IBOutlet NSTextView *fileDropTextView;  // on 10.8 NSTextView cannot be weak
@property (nonatomic, strong) IBOutlet NSTextView *fileDropGlossaryTextView;  // on 10.8 NSTextView cannot be weak
@property (nonatomic, weak) IBOutlet NSPopUpButton *invisibleSpacePopup;
@property (nonatomic, weak) IBOutlet NSPopUpButton *invisibleTabPopup;
@property (nonatomic, weak) IBOutlet NSPopUpButton *invisibleNewLinePopup;
@property (nonatomic, weak) IBOutlet NSPopUpButton *invisibleFullwidthSpacePopup;
@property (nonatomic, weak) IBOutlet NSPopUpButton *syntaxStylesPopup;
@property (nonatomic, weak) IBOutlet NSPopUpButton *syntaxStylesDefaultPopup;
@property (nonatomic, weak) IBOutlet NSButton *syntaxStyleEditButton;
@property (nonatomic, weak) IBOutlet NSButton *syntaxStyleCopyButton;
@property (nonatomic, weak) IBOutlet NSButton *syntaxStyleExportButton;
@property (nonatomic, weak) IBOutlet NSButton *syntaxStyleDeleteButton;
@property (nonatomic, weak) IBOutlet NSButton *syntaxStyleXtsnErrButton;

@property (nonatomic) BOOL doDeleteFileDrop;

@property (nonatomic) CGFloat sampleWidth;
@property (nonatomic) CGFloat sampleHeight;

@end





#pragma mark -

@implementation CEPreferencesController

#pragma mark Class Methods

//=======================================================
// Class method
//
//=======================================================

// ------------------------------------------------------
+ (instancetype)sharedController
// return singleton instance
// ------------------------------------------------------
{
    static dispatch_once_t predicate;
    static CEPreferencesController *shared = nil;
    
    dispatch_once(&predicate, ^{
        shared = [[CEPreferencesController alloc] initWithWindowNibName:@"Preferences"];
    });
    
    return shared;
}



#pragma mark NSWindowController Methods

//=======================================================
// Public method
//
//=======================================================

// ------------------------------------------------------
- (IBAction)showWindow:(id)sender
// 環境設定パネルを開く
// ------------------------------------------------------
{
    if (![[self window] isVisible]) {
        [self setFontFamilyNameAndSize];
        // 拡張子重複エラー表示ボタンの有効化を制御
        [[self syntaxStyleXtsnErrButton] setEnabled:[[CESyntaxManager sharedInstance] existsExtensionError]];
        
        [[self window] center];
    }
    [super showWindow:sender];
}



#pragma mark Public Methods

//=======================================================
// Public method
//
//=======================================================

// ------------------------------------------------------
- (void)setupEncodingMenus:(NSArray *)menuItems
// エンコーディング設定メニューを生成
// ------------------------------------------------------
{
    NSString *title;
    NSMenuItem *item;
    NSUInteger selected;

    [[self encodingMenuInOpen] removeAllItems];
    item = [[NSMenuItem alloc] initWithTitle:NSLocalizedString(@"Auto-Detect", nil)
                                      action:nil keyEquivalent:@""];
    [item setTag:k_autoDetectEncodingMenuTag];
    [[[self encodingMenuInOpen] menu] addItem:item];
    [[[self encodingMenuInOpen] menu] addItem:[NSMenuItem separatorItem]];
    [[self encodingMenuInNew] removeAllItems];

    for (NSMenuItem *menuItem in menuItems) {
        [[[self encodingMenuInOpen] menu] addItem:[menuItem copy]];
        [[[self encodingMenuInNew] menu] addItem:[menuItem copy]];
    }
    // (エンコーディング設定メニューはバインディングを使っているが、タグの選択がバインディングで行われた後に
    // メニューが追加／削除されるため、結果的に選択がうまく動かない。しかたないので、コードから選択している)
    selected = [[NSUserDefaults standardUserDefaults] integerForKey:k_key_encodingInOpen];
    if (selected == k_autoDetectEncodingMenuTag) {
        title = NSLocalizedString(@"Auto-Detect", nil);
    } else {
        title = [NSString localizedNameOfStringEncoding:selected];
    }
    [[self encodingMenuInOpen] selectItemWithTitle:title];
    title = [NSString localizedNameOfStringEncoding:[[NSUserDefaults standardUserDefaults]
                                                     integerForKey:k_key_encodingInNew]];
    [[self encodingMenuInNew] selectItemWithTitle:title];
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
- (void)setSampleWidth:(CGFloat)width
// サンプルウィンドウの幅をセット
// ------------------------------------------------------
{
    if ((width < k_minWindowSize) || (width > k_maxWindowSize)) {return;}
    _sampleWidth = width;
}


// ------------------------------------------------------
- (void)setSampleHeight:(CGFloat)height
// サンプルウィンドウの高さを得る
// ------------------------------------------------------
{
    if ((height < k_minWindowSize) || (height > k_maxWindowSize)) {return;}
    _sampleHeight = height;
}


// ------------------------------------------------------
- (void)changeFont:(id)sender
// フォントパネルでフォントが変更された
// ------------------------------------------------------
{
    // (引数"sender"はNSFontManegerのインスタンス)
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    NSFont *newFont = [sender convertFont:[NSFont systemFontOfSize:0]];
    NSString *name = [newFont fontName];
    CGFloat size = [newFont pointSize];

    if ([[[[self prefTabView] selectedTabViewItem] identifier] isEqualToString:k_prefFormatItemID]) {
        [defaults setObject:name forKey:k_key_fontName];
        [defaults setFloat:size forKey:k_key_fontSize];
        [self setFontFamilyNameAndSize];
    } else if ([[[[self prefTabView] selectedTabViewItem] identifier] isEqualToString:k_prefPrintItemID]) {
        [defaults setObject:name forKey:k_key_printFontName];
        [defaults setFloat:size forKey:k_key_printFontSize];
        [self setFontFamilyNameAndSize];
    }
}



#pragma mark Protocol

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

    [[self fileDropTextView] setContinuousSpellCheckingEnabled:NO]; // IBでの設定が効かないのでここで、実行
    [[self encodingMenuInOpen] setAction:@selector(checkSelectedItemOfEncodingMenuInOpen:)];
    // （Nibファイルの用語説明部分は直接NSTextViewに記入していたが、AppleGlot3.4から読み取れなくなり、ローカライズ対象にできなくなってしまった。その回避処理として、Localizable.stringsファイルに書き込むこととしたために、文字列をセットする処理が必要になった。
    // 2008.07.15.
    [[self fileDropGlossaryTextView] setString:NSLocalizedString(@"<<<ABSOLUTE-PATH>>>\nThe dropped file's absolute path.\n\n<<<RELATIVE-PATH>>>\nThe relative path between the dropped file and the document.\n\n<<<FILENAME>>>\nThe dropped file's name with extension (if exists).\n\n<<<FILENAME-NOSUFFIX>>>\nThe dropped file's name without extension.\n\n<<<FILEEXTENSION>>>\nThe dropped file's extension.\n\n<<<FILEEXTENSION-LOWER>>>\nThe dropped file's extension (converted to lowercase).\n\n<<<FILEEXTENSION-UPPER>>>\nThe dropped file's extension (converted to uppercase).\n\n<<<DIRECTORY>>>\nThe parent directory name of the dropped file.\n\n<<<IMAGEWIDTH>>>\n(if the dropped file is Image) The image width.\n\n<<<IMAGEHEIGHT>>>\n(if the dropped file is Image) The image height.", nil)];

    
    [[self window] setShowsToolbarButton:NO];
}



#pragma mark Delegate and Notification

//=======================================================
// Selector for Notification (NSApplication)
//  <== prefWindow
//=======================================================

// ------------------------------------------------------
- (void)windowWillClose:(NSNotification *)notification
// ウインドウが閉じる
// ------------------------------------------------------
{
    // 編集中の設定値も保存
    [[self window] makeFirstResponder:[self window]];
    [self updateUserDefaults];  // !!!: いまでも必要かあとで調べる [synclonize] 2014jp 2014-03
    // FileDrop 配列コントローラの値を書き戻す
    [self writeBackFileDropArray];
}


//=======================================================
// Selector for Notification (NSTableView)
//  <== fileDropTableView
//=======================================================

// ------------------------------------------------------
- (void)controlTextDidEndEditing:(NSNotification *)notification
// FileDrop 拡張子テーブルビューが編集された
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
// Selector for Notification (NSTextView)
//  <== fileDropTextView
//=======================================================

// ------------------------------------------------------
- (void)textDidEndEditing:(NSNotification *)notification
// FileDrop 挿入文字列フォーマットテキストビューが編集された
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
- (IBAction)showFonts:(id)sender
// フォントパネルを表示
//-------------------------------------------------------
{
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    NSFontManager *manager = [NSFontManager sharedFontManager];
    NSFont *font;

    if ([[[[self prefTabView] selectedTabViewItem] identifier] isEqualToString:k_prefPrintItemID]) {
        font = [NSFont fontWithName:[defaults stringForKey:k_key_printFontName]
                               size:(CGFloat)[defaults doubleForKey:k_key_printFontSize]];
    } else {
        font = [NSFont fontWithName:[defaults stringForKey:k_key_fontName]
                               size:(CGFloat)[defaults doubleForKey:k_key_fontSize]];
    }

    [[self window] makeFirstResponder:[self window]];
    [manager setSelectedFont:font isMultiple:NO];
    [manager orderFrontFontPanel:sender];
}


// ------------------------------------------------------
- (IBAction)openEncodingEditSheet:(id)sender
// エンコーディングリスト編集シートを開き、閉じる
// ------------------------------------------------------
{
    // データソースをセットアップ、シートを表示してモーダルループに入る(閉じる命令は closeEncodingEditSheet: で)
    [[self encodingDataSource] setupEncodingsToEdit];
    [NSApp beginSheet:[self encodingWindow]
       modalForWindow:[self window]
        modalDelegate:self
       didEndSelector:NULL
          contextInfo:NULL];
    [NSApp runModalForWindow:[self encodingWindow]];

    // シートを閉じる
    [NSApp endSheet:[self encodingWindow]];
    [[self encodingWindow] orderOut:self];
    [[self window] makeKeyAndOrderFront:self];
}


// ------------------------------------------------------
- (IBAction)closeEncodingEditSheet:(id)sender
// エンコーディングリスト編集シートの OK / Cancel ボタンが押された
// ------------------------------------------------------
{
    if ([sender tag] == k_okButtonTag) { // ok のとき
        [[self encodingDataSource] writeEncodingsToUserDefaults]; // エンコーディングを保存
        [(CEAppController *)[[NSApplication sharedApplication] delegate] buildAllEncodingMenus];
    }
    [NSApp stopModal];
}


// ------------------------------------------------------
- (IBAction)openSizeSampleWindow:(id)sender
// サイズ設定のためのサンプルウィンドウを開く
// ------------------------------------------------------
{
    NSSize size = NSMakeSize((CGFloat)[[NSUserDefaults standardUserDefaults] doubleForKey:k_key_windowWidth],
                             (CGFloat)[[NSUserDefaults standardUserDefaults] doubleForKey:k_key_windowHeight]);

    [[self sizeSampleWindow] setContentSize:size];
    [[self sizeSampleWindow] makeKeyAndOrderFront:self];
    // モーダルで表示
    [NSApp runModalForWindow:[self sizeSampleWindow]];

    // サンプルウィンドウを閉じる
    [[self sizeSampleWindow] orderOut:self];
    [[self window] makeKeyAndOrderFront:self];

}


// ------------------------------------------------------
- (IBAction)setWindowContentSizeToDefault:(id)sender
// サンプルウィンドウの内部サイズをuserDefaultsにセット
// ------------------------------------------------------
{
    if ([sender tag] == k_okButtonTag) { // ok のときサイズを保存
        NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];

        [defaults setDouble:[self sampleWidth] forKey:k_key_windowWidth];
        [defaults setDouble:[self sampleHeight] forKey:k_key_windowHeight];
    }
    [NSApp stopModal];
}


// ------------------------------------------------------
- (IBAction)openSyntaxEditSheet:(id)sender
// カラーシンタックス編集シートを開き、閉じる
// ------------------------------------------------------
{
    NSInteger selected = [[self syntaxStylesPopup] indexOfSelectedItem] - 2; // "None"とセパレータ分のオフセット
    if (([sender tag] != k_syntaxNewTag) && (selected < 0)) { return; }

    if (![[CESyntaxManager sharedInstance] setSelectionIndexOfStyle:selected mode:[sender tag]]) {
        return;
    }
    NSString *oldName = [[self syntaxStylesPopup] titleOfSelectedItem];

    // シートウィンドウを表示してモーダルループに入る
    // (閉じる命令は CESyntaxManagerのcloseSyntaxEditSheet: で)
    NSWindow *sheet = [[CESyntaxManager sharedInstance] editWindow];

    [NSApp beginSheet:sheet
       modalForWindow:[self window]
        modalDelegate:self
       didEndSelector:NULL
          contextInfo:NULL];
    [NSApp runModalForWindow:sheet];


    // === 以下、シートを閉じる処理
    // OKボタンが押されていたとき（キャンセルでも、最初の状態に戻していいかもしれない (1/21)） ********
    if ([[CESyntaxManager sharedInstance] isOkButtonPressed]) {
        // 当該スタイルを適用しているドキュメントに前面に出たときの再カラーリングフラグを立てる
        NSString *newName = [[CESyntaxManager sharedInstance] editedNewStyleName];
        NSDictionary *styleNameDict = @{k_key_oldStyleName: oldName,
                                        k_key_newStyleName: newName};
        [[NSApp orderedDocuments] makeObjectsPerformSelector:@selector(setRecolorFlagToWindowControllerWithStyleName:)
                                                  withObject:styleNameDict];
        
        [[CESyntaxManager sharedInstance] setEditedNewStyleName:@""];
        // シンタックスカラーリングスタイル指定メニューを再構成、選択をクリアしてボタン類を有効／無効化
        [(CEAppController *)[[NSApplication sharedApplication] delegate] buildAllSyntaxMenus];
        // 拡張子重複エラー表示ボタンの有効化を制御
        [[self syntaxStyleXtsnErrButton] setEnabled:
                [[CESyntaxManager sharedInstance] existsExtensionError]];
    }
    // シートを閉じる
    [NSApp endSheet:sheet];
    [sheet orderOut:self];
    [[self window] makeKeyAndOrderFront:self];
}


// ------------------------------------------------------
- (IBAction)changedSyntaxStylesPopup:(id)sender
// シンタックスカラーリングスタイル指定メニューまたはカラーリング実施チェックボックスが変更された
// ------------------------------------------------------
{
    BOOL isEnabled = ([[self syntaxStylesPopup] indexOfSelectedItem] > 1);

    [[self syntaxStyleEditButton] setEnabled:isEnabled];
    [[self syntaxStyleCopyButton] setEnabled:isEnabled];
    [[self syntaxStyleExportButton] setEnabled:isEnabled];

    if (isEnabled &&
        ![[CESyntaxManager sharedInstance] isDefaultSyntaxStyle:[[self syntaxStylesPopup] title]])
    {
        [[self syntaxStyleDeleteButton] setEnabled:YES];
    } else {
        [[self syntaxStyleDeleteButton] setEnabled:NO];
    }
}


// ------------------------------------------------------
- (IBAction)deleteSyntaxStyle:(id)sender
// シンタックスカラーリングスタイル削除ボタンが押された
// ------------------------------------------------------
{
    NSInteger selected = [[self syntaxStylesPopup] indexOfSelectedItem] - 2;

    if (![[CESyntaxManager sharedInstance] setSelectionIndexOfStyle:selected mode:k_syntaxNoSheetTag]) {
        return;
    }
    NSString *message = [NSString stringWithFormat:NSLocalizedString(@"Delete the Syntax coloring style \"%@\" ?", nil),
                         [[self syntaxStylesPopup] title]];
    NSAlert *alert = [NSAlert alertWithMessageText:message
                                     defaultButton:NSLocalizedString(@"Cancel", nil)
                                   alternateButton:NSLocalizedString(@"Delete", nil)
                                       otherButton:nil
                         informativeTextWithFormat:NSLocalizedString(@"Deleted style cannot be restored.", nil)];

    __block typeof(self) blockSelf = self;
    [alert beginSheetModalForWindow:[self window] completionHandler:^(NSModalResponse returnCode) {
        if (returnCode != NSAlertAlternateReturn) { return; } // != Delete
        
        NSString *oldSelectedName = [[CESyntaxManager sharedInstance] selectedStyleName];
        
        if (![[CESyntaxManager sharedInstance] removeStyleFileWithStyleName:[[blockSelf syntaxStylesPopup] title]]) {
            // 削除できなければ、その旨をユーザに通知
            [[alert window] orderOut:blockSelf];
            [[blockSelf window] makeKeyAndOrderFront:blockSelf];
            NSAlert *newAlert = [NSAlert alertWithMessageText:NSLocalizedString(@"Error occured.", nil)
                                                defaultButton:nil alternateButton:nil otherButton:nil
                                    informativeTextWithFormat:NSLocalizedString(@"Sorry, could not delete \"%@\".", nil),
                                 [[blockSelf syntaxStylesPopup] title]];
            NSBeep();
            [newAlert beginSheetModalForWindow:[blockSelf window] completionHandler:nil];
            return;
        }
        // 当該スタイルを適用しているドキュメントを"None"スタイルにし、前面に出たときの再カラーリングフラグを立てる
        [[NSApp orderedDocuments] makeObjectsPerformSelector:@selector(setStyleToNoneAndRecolorFlagWithStyleName:)
                                                  withObject:oldSelectedName];
        
        // シンタックスカラーリングスタイル指定メニューを再構成、選択をクリアしてボタン類を有効／無効化
        [(CEAppController *)[[NSApplication sharedApplication] delegate] buildAllSyntaxMenus];
        // 拡張子重複エラー表示ボタンの有効化を制御
        [[blockSelf syntaxStyleXtsnErrButton] setEnabled:[[CESyntaxManager sharedInstance] existsExtensionError]];
    }];
}


// ------------------------------------------------------
- (IBAction)importSyntaxStyle:(id)sender
// シンタックスカラーリングスタイルインポートボタンが押された
// ------------------------------------------------------
{
    NSOpenPanel *openPanel = [NSOpenPanel openPanel];

    // OpenPanelをセットアップ(既定値を含む)、シートとして開く
    [openPanel setPrompt:NSLocalizedString(@"Import", nil)];
    [openPanel setResolvesAliases:YES];
    [openPanel setAllowsMultipleSelection:NO];
    [openPanel setCanChooseDirectories:NO];
    [openPanel setAllowedFileTypes:@[@"plist"]];
    
    __block typeof(self) blockSelf = self;
    [openPanel beginSheetModalForWindow:[self window] completionHandler:^(NSInteger result) {
        if (result == NSFileHandlingPanelCancelButton) return;
        
        NSURL *URL = [openPanel URLs][0];
        NSString *styleName = [[URL lastPathComponent] stringByDeletingPathExtension];
        
        // 同名styleが既にあるときは、置換してもいいか確認
        if ([[CESyntaxManager sharedInstance] existsStyleFileWithStyleName:styleName]) {
            // オープンパネルを閉じる
            [openPanel orderOut:blockSelf];
            [[blockSelf window] makeKeyAndOrderFront:blockSelf];
            
            NSAlert *alert;
            NSString *message = [NSString stringWithFormat:NSLocalizedString(@"the \"%@\" style already exists.", nil), styleName];
            alert = [NSAlert alertWithMessageText:message
                                    defaultButton:NSLocalizedString(@"Cancel", nil)
                                  alternateButton:NSLocalizedString(@"Replace", nil) otherButton:nil
                        informativeTextWithFormat:NSLocalizedString(@"Do you want to replace it ?\nReplaced style cannot be restored.", nil)];
            // 現行シート値を設定し、確認のためにセカンダリシートを開く
            NSBeep();
            
            [alert beginSheetModalForWindow:[self window] completionHandler:^(NSModalResponse returnCode) {
                if (returnCode == NSAlertAlternateReturn) { // = Replace
                    [blockSelf doImport:URL withCurrentSheetWindow:[alert window]];
                }
            }];
            
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
    [savePanel setNameFieldLabel:NSLocalizedString(@"Export As:", nil)];
    [savePanel setNameFieldStringValue:[[self syntaxStylesPopup] title]];
    [savePanel setAllowedFileTypes:@[@"plist"]];
    
    [savePanel beginSheetModalForWindow:[self window] completionHandler:^(NSInteger result) {
        if (result == NSFileHandlingPanelCancelButton) return;
        
        NSFileManager *fileManager = [NSFileManager defaultManager];
        NSURL *sourceURL = [[CESyntaxManager sharedInstance] URLOfStyle:[[self syntaxStylesPopup] title]];
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
    CESyntaxExtensionErrorSheetController *sheetController = [[CESyntaxExtensionErrorSheetController alloc] init];
    NSWindow *sheet = [sheetController window];
    
    // シートウィンドウを表示してモーダルループに入る
    // (閉じる命令は CESyntaxExtensionsSheetControllerのcloseSheet: で)
    [NSApp beginSheet:sheet modalForWindow:[self window] modalDelegate:self didEndSelector:NULL contextInfo:NULL];
    [NSApp runModalForWindow:sheet];

    // シートを閉じる
    [NSApp endSheet:sheet];
    [sheetController close];
    [[self window] makeKeyAndOrderFront:self];
}


// ------------------------------------------------------
- (IBAction)insertFormatStringInFileDrop:(id)sender
// ファイルドロップ定型文字列挿入メニューが選択された
// ------------------------------------------------------
{
    NSString *title = [(NSMenuItem *)sender title];

    if (title) {
        [[self window] makeFirstResponder:[self fileDropTextView]];
        [[self fileDropTextView] insertText:title];
    }
}


// ------------------------------------------------------
- (IBAction)addNewFileDropSetting:(id)sender
// ファイルドロップ編集設定を追加
// ------------------------------------------------------
{
    // フォーカスを移し、値入力を確定
    [[sender window] makeFirstResponder:sender];

    [[self window] makeFirstResponder:[self fileDropTableView]];
    [[self fileDropController] add:self];

    // ディレイをかけて fileDropController からのバインディングによる行追加を先に実行させる
    [self performSelector:@selector(editNewAddedRowOfFileDropTableView) withObject:nil afterDelay:0];
}


// ------------------------------------------------------
- (IBAction)deleteFileDropSetting:(id)sender
// ファイルドロップ編集設定の削除ボタンが押された
// ------------------------------------------------------
{
    // (編集中に削除ボタンが押され、かつ自動削除対象であったときの整合性を取るための)削除実施フラグをたてる
    [self setDoDeleteFileDrop:YES];
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
    NSWindow *sheet = [[CEKeyBindingManager sharedInstance] editSheetWindowOfMode:[sender tag]];

    if ((sheet != nil) &&
        [[CEKeyBindingManager sharedInstance] setupOutlineDataOfMode:[sender tag]])
    {
        [NSApp beginSheet:sheet
           modalForWindow:[self window]
            modalDelegate:self
           didEndSelector:NULL
              contextInfo:NULL];
        [NSApp runModalForWindow:sheet];
    } else {
        return;
    }

    // シートを閉じる
    [NSApp endSheet:sheet];
    [sheet orderOut:self];
    [[self window] makeKeyAndOrderFront:self];
}


//------------------------------------------------------
- (IBAction)setupCustomLineSpacing:(id)sender
// 行間値を調整
//------------------------------------------------------
{
    // IB で Formatter が設定できないのでメソッドで行ってる。

    CGFloat value = (CGFloat)[sender doubleValue];

    if (value < k_lineSpacingMin) { value = k_lineSpacingMin; }
    if (value > k_lineSpacingMax) { value = k_lineSpacingMax; }

    [sender setStringValue:[NSString stringWithFormat:@"%.2f", value]];
}


//------------------------------------------------------
- (IBAction)checkSelectedItemOfEncodingMenuInOpen:(id)sender
// 既存のファイルを開くエンコーディングが変更されたとき、選択項目をチェック
//------------------------------------------------------
{
    NSString *newTitle = [NSString stringWithString:[[[self encodingMenuInOpen] selectedItem] title]];
    // ファイルを開くエンコーディングをセット
    // （オープンダイアログのエンコーディングポップアップメニューが、デフォルトエンコーディング値の格納場所を兼ねている）
    [[CEDocumentController sharedDocumentController] setSelectAccessoryEncodingMenuToDefault:self];

    if ([newTitle isEqualToString:NSLocalizedString(@"Auto-Detect", nil)]) { return; }

    NSString *message = [NSString stringWithFormat:
                         NSLocalizedString(@"Are you sure you want to change to \"%@\"?", nil),
                         newTitle];
    NSString *altButtonTitle = [NSString stringWithFormat:
                                NSLocalizedString(@"Change to \"%@\"", nil),
                                newTitle];
    NSAlert *alert = [NSAlert alertWithMessageText:message
                                     defaultButton:NSLocalizedString(@"Revert to \"Auto-Detect\"", nil)
                                   alternateButton:altButtonTitle
                                       otherButton:nil
                         informativeTextWithFormat:NSLocalizedString(@"The default \"Auto-Detect\" is recommended for most cases.",nil)];

    NSBeep();
    [alert beginSheetModalForWindow:[self window]
                      modalDelegate:self
                     didEndSelector:@selector(autoDetectAlertDidEnd:returnCode:contextInfo:)
                        contextInfo:NULL];
}


//------------------------------------------------------
- (IBAction)openPrefHelp:(id)sender
// ヘルプの環境設定説明部分を開く
//------------------------------------------------------
{
    NSString *bookName = [[NSBundle mainBundle] objectForInfoDictionaryKey: @"CFBundleHelpBookName"];
    NSArray *anchorsArray = @[k_helpPrefAnchors];
    NSInteger tag = [sender tag];

    if ((tag >= 0) && (tag < [anchorsArray count])) {
        [[NSHelpManager sharedHelpManager] openHelpAnchor:anchorsArray[tag]
                                                   inBook:bookName];
    }
}


// ------------------------------------------------------
- (IBAction)setSmartInsertAndDeleteToAllTextView:(id)sender
// すべてのテキストビューのスマートインサート／デリート実行を設定
// ------------------------------------------------------
{
    [[NSApp orderedDocuments] makeObjectsPerformSelector:@selector(setSmartInsertAndDeleteToTextView)];
}



// ------------------------------------------------------
- (IBAction)setSmartQuotesToAllTextView:(id)sender
// すべてのテキストビューのスマート引用符／ダッシュ実行を設定
// ------------------------------------------------------
{
    [[NSApp orderedDocuments] makeObjectsPerformSelector:@selector(setSmartQuotesToTextView)];
}



#pragma mark Private Mthods

//=======================================================
// Private method
//
//=======================================================

// ------------------------------------------------------
- (void)writeBackFileDropArray
// FileDrop 設定を UserDefaults に書き戻す
// ------------------------------------------------------
{
    [[NSUserDefaults standardUserDefaults] setObject:[[self fileDropController] content] forKey:k_key_fileDropArray];
}


//------------------------------------------------------
- (void)updateUserDefaults
// Force update UserDefaults
//------------------------------------------------------
{
// 下記のページの情報を参考にさせていただきました(2004.12.30)
// http://cocoa.mamasam.com/COCOADEV/2004/02/2/85406.php
    NSUserDefaultsController *UDC = [NSUserDefaultsController sharedUserDefaultsController];

//    [[self fileDropController] commitEditing];
    [UDC commitEditing];
    [UDC save:self];
}


//------------------------------------------------------
- (void)setFontFamilyNameAndSize
// メインウィンドウのフォントファミリー名とサイズをprefFontFamilyNameSizeに表示させる
//------------------------------------------------------
{
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];

    NSString *name = [defaults stringForKey:k_key_fontName];
    CGFloat size = (CGFloat)[defaults doubleForKey:k_key_fontSize];
    NSFont *font = [NSFont fontWithName:name size:size];
    NSString *localizedName = [font displayName];

    [[self prefFontFamilyNameSize] setStringValue:[NSString stringWithFormat:@"%@  (%gpt)", localizedName, size]];

    name = [defaults stringForKey:k_key_printFontName];
    size = (CGFloat)[defaults doubleForKey:k_key_printFontSize];
    font = [NSFont fontWithName:name size:size];
    localizedName = [font displayName];

    [[self printFontFamilyNameSize] setStringValue:[NSString stringWithFormat:@"%@  (%gpt)", localizedName, size]];

}


// ------------------------------------------------------
- (void)setContentFileDropController
// ファイルドロップ設定編集用コントローラに値をセット
// ------------------------------------------------------
{
// バインディングで UserDefaults と直結すると「長さゼロの文字列がセットされた」ときなどにいろいろと不具合が発生するので、
// 起動時に読み込み、変更完了／終了時に下記戻す処理を行う。
// http://www.hmdt-web.net/bbs/bbs.cgi?bbsname=mkino&mode=res&no=203&oyano=203&line=0

    NSMutableArray *fileDropArray = [[[NSUserDefaults standardUserDefaults] arrayForKey:k_key_fileDropArray] mutableCopy];

    [[self fileDropController] setContent:fileDropArray];
}


// ------------------------------------------------------
- (void)setupInvisibleSpacePopup
// 不可視文字表示設定ポップアップメニューを生成
// ------------------------------------------------------
{
    CEAppController *appDelegate = (CEAppController *)[[NSApplication sharedApplication] delegate];
    NSString *title;
    NSMenuItem *item;
    NSUInteger selected;
    NSUInteger i;

    [[self invisibleSpacePopup] removeAllItems];
    for (i = 0; i < (sizeof(k_invisibleSpaceCharList) / sizeof(unichar)); i++) {
        title = [appDelegate invisibleSpaceCharacter:i];
        item = [[NSMenuItem alloc] initWithTitle:title action:nil keyEquivalent:@""];
        [[[self invisibleSpacePopup] menu] addItem:item];
    }
    // (不可視文字表示設定ポップアップメニューはバインディングを使っているが、タグの選択がバインディングで行われた後に
    // メニューが追加／削除されるため、結果的に選択がうまく動かない。しかたないので、コードから選択している)
    selected = [[NSUserDefaults standardUserDefaults] integerForKey:k_key_invisibleSpace];
    [[self invisibleSpacePopup] selectItemAtIndex:selected];
}


// ------------------------------------------------------
- (void)setupInvisibleTabPopup
// 不可視文字表示設定ポップアップメニューを生成
// ------------------------------------------------------
{
    CEAppController *appDelegate = (CEAppController *)[[NSApplication sharedApplication] delegate];
    NSString *title;
    NSMenuItem *item;
    NSUInteger selected;
    NSUInteger i;

    [[self invisibleTabPopup] removeAllItems];
    for (i = 0; i < (sizeof(k_invisibleTabCharList) / sizeof(unichar)); i++) {
        title = [appDelegate invisibleTabCharacter:i];
        item = [[NSMenuItem alloc] initWithTitle:title action:nil keyEquivalent:@""];
        [[[self invisibleTabPopup] menu] addItem:item];
    }
    // (不可視文字表示設定ポップアップメニューはバインディングを使っているが、タグの選択がバインディングで行われた後に
    // メニューが追加／削除されるため、結果的に選択がうまく動かない。しかたないので、コードから選択している)
    selected = [[NSUserDefaults standardUserDefaults] integerForKey:k_key_invisibleTab];
    [[self invisibleTabPopup] selectItemAtIndex:selected];
}


// ------------------------------------------------------
- (void)setupInvisibleNewLinePopup
// 不可視文字表示設定ポップアップメニューを生成
// ------------------------------------------------------
{
    CEAppController *appDelegate = (CEAppController *)[[NSApplication sharedApplication] delegate];
    NSString *vitle;
    NSMenuItem *item;
    NSUInteger selected;
    NSUInteger i;

    [[self invisibleNewLinePopup] removeAllItems];
    for (i = 0; i < (sizeof(k_invisibleNewLineCharList) / sizeof(unichar)); i++) {
        vitle = [appDelegate invisibleNewLineCharacter:i];
        item = [[NSMenuItem alloc] initWithTitle:vitle action:nil keyEquivalent:@""];
        [[[self invisibleNewLinePopup] menu] addItem:item];
    }
    // (不可視文字表示設定ポップアップメニューはバインディングを使っているが、タグの選択がバインディングで行われた後に
    // メニューが追加／削除されるため、結果的に選択がうまく動かない。しかたないので、コードから選択している)
    selected = [[NSUserDefaults standardUserDefaults] integerForKey:k_key_invisibleNewLine];
    [[self invisibleNewLinePopup] selectItemAtIndex:selected];
}


// ------------------------------------------------------
- (void)setupInvisibleFullwidthSpacePopup
// 不可視文字表示設定ポップアップメニューを生成
// ------------------------------------------------------
{
    CEAppController *appDelegate = (CEAppController *)[[NSApplication sharedApplication] delegate];
    NSString *title;
    NSMenuItem *item;
    NSUInteger selected;
    NSUInteger i;

    [[self invisibleFullwidthSpacePopup] removeAllItems];
    for (i = 0; i < (sizeof(k_invisibleFullwidthSpaceCharList) / sizeof(unichar)); i++) {
        title = [appDelegate invisibleFullwidthSpaceCharacter:i];
        item = [[NSMenuItem alloc] initWithTitle:title action:nil keyEquivalent:@""];
        [[[self invisibleFullwidthSpacePopup] menu] addItem:item];
    }
    // (不可視文字表示設定ポップアップメニューはバインディングを使っているが、タグの選択がバインディングで行われた後に
    // メニューが追加／削除されるため、結果的に選択がうまく動かない。しかたないので、コードから選択している)
    selected = [[NSUserDefaults standardUserDefaults] integerForKey:k_key_invisibleFullwidthSpace];
    [[self invisibleFullwidthSpacePopup] selectItemAtIndex:selected];
}


// ------------------------------------------------------
- (void)setupSyntaxStylesPopup
// シンタックスカラーリングスタイル指定ポップアップメニューを生成
// ------------------------------------------------------
{
    NSArray *styleNames = [[CESyntaxManager sharedInstance] styleNames];
    NSMenuItem *item;
    NSString *selectedTitle;
    NSUInteger selected;

    [[self syntaxStylesPopup] removeAllItems];
    [[self syntaxStylesDefaultPopup] removeAllItems];
    item = [[NSMenuItem alloc] initWithTitle:NSLocalizedString(@"Choose style...", nil)
                                      action:nil keyEquivalent:@""];
    [[[self syntaxStylesPopup] menu] addItem:item];
    [[[self syntaxStylesPopup] menu] addItem:[NSMenuItem separatorItem]];
    item = [[NSMenuItem alloc] initWithTitle:NSLocalizedString(@"None", nil)
                                      action:nil keyEquivalent:@""];
    [[[self syntaxStylesDefaultPopup] menu] addItem:item];
    [[[self syntaxStylesDefaultPopup] menu] addItem:[NSMenuItem separatorItem]];
    
    for (NSString *styleName in styleNames) {
        item = [[NSMenuItem alloc] initWithTitle:styleName
                   action:nil keyEquivalent:@""];
        [[[self syntaxStylesPopup] menu] addItem:item];
        [[[self syntaxStylesDefaultPopup] menu] addItem:[item copy]];
    }
    // (デフォルトシンタックスカラーリングスタイル指定ポップアップメニューはバインディングを使っているが、
    // タグの選択がバインディングで行われた後にメニューが追加／削除されるため、結果的に選択がうまく動かない。
    // しかたないので、コードから選択している)
    selectedTitle = [[NSUserDefaults standardUserDefaults] stringForKey:k_key_defaultColoringStyleName];
    selected = [[self syntaxStylesDefaultPopup] indexOfItemWithTitle:selectedTitle];
    if (selected != -1) { // no selection
        [[self syntaxStylesDefaultPopup] selectItemAtIndex:selected];
    } else {
        [[self syntaxStylesDefaultPopup] selectItemAtIndex:0]; // == "None"
    }
}


// ------------------------------------------------------
- (void)autoDetectAlertDidEnd:(NSAlert *)sheet
        returnCode:(NSInteger)returnCode contextInfo:(void *)contextInfo
// 既存ファイルを開くときのエンコーディングメニューで自動認識以外が
// 選択されたときの警告シートが閉じる直前
// ------------------------------------------------------
{
    if (returnCode == NSAlertDefaultReturn) { // = revert to Auto-Detect
        [[NSUserDefaults standardUserDefaults] setObject:@(k_autoDetectEncodingMenuTag)
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
        [(CEAppController *)[[NSApplication sharedApplication] delegate] buildAllSyntaxMenus];
    } else {
        // インポートできなかったときは、セカンダリシートを閉じ、メッセージシートを表示
        [inWindow orderOut:self];
        [[self window] makeKeyAndOrderFront:self];
        NSAlert *alert = [NSAlert alertWithMessageText:NSLocalizedString(@"Error occured.", nil)
                                         defaultButton:nil
                                       alternateButton:nil otherButton:nil
                             informativeTextWithFormat:NSLocalizedString(@"Sorry, could not import \"%@\".", nil), [fileURL lastPathComponent]];
        NSBeep();
        [alert beginSheetModalForWindow:[self window] modalDelegate:self didEndSelector:NULL contextInfo:NULL];
    }
}


// ------------------------------------------------------
- (void)doDeleteFileDropSetting
// ファイルドロップ編集設定の削除を確認
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

    NSString *message = [NSString stringWithFormat:NSLocalizedString(@"Delete the File Drop setting ?\n \"%@\"", nil), extension];
    NSAlert *alert = [NSAlert alertWithMessageText:message
                                     defaultButton:NSLocalizedString(@"Cancel", nil)
                                   alternateButton:NSLocalizedString(@"Delete", nil) otherButton:nil
                         informativeTextWithFormat:NSLocalizedString(@"Deleted setting cannot be restored.", nil)];
    
    __block typeof(self) blockSelf = self;
    [alert beginSheetModalForWindow:[self window] completionHandler:^(NSModalResponse returnCode) {
        if (returnCode != NSAlertAlternateReturn) { return; } // != Delete
        
        if ([[blockSelf fileDropController] selectionIndex] == NSNotFound) { return; }
        
        if ([blockSelf doDeleteFileDrop]) {
            [[blockSelf fileDropController] remove:self];
            [blockSelf writeBackFileDropArray];
            [blockSelf setDoDeleteFileDrop:NO];
        }
     }];
}


// ------------------------------------------------------
- (void)editNewAddedRowOfFileDropTableView
// ファイルドロップ編集設定の追加行の編集開始
// ------------------------------------------------------
{
    [[self fileDropTableView] editColumn:0 row:[[self fileDropTableView] selectedRow] withEvent:nil select:YES];
}

@end
