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
#import "CESizeSampleWindowController.h"
#import "CESyntaxExtensionErrorSheetController.h"
#import "CEEncodingListSheetController.h"
#import "constants.h"


typedef NS_ENUM(NSUInteger, CEPreferencesToolbarTag) {
    CEGeneralPreferences,
    CEWindowPreferences,
    CEViewPreferences,
    CEFormatPreferences,
    CESyntaxPreferences,
    CEFileDropPreferences,
    CEKeyBindingsPreferences,
    CEPrintPreferences
};


@interface CEPreferencesController ()

@property (nonatomic) IBOutlet NSView *generalView;
@property (nonatomic) IBOutlet NSView *windowView;
@property (nonatomic) IBOutlet NSView *viewView;
@property (nonatomic) IBOutlet NSView *formatView;
@property (nonatomic) IBOutlet NSView *syntaxView;
@property (nonatomic) IBOutlet NSView *fileDropView;
@property (nonatomic) IBOutlet NSView *keyBindingsView;
@property (nonatomic) IBOutlet NSView *printView;

@property (nonatomic, weak) IBOutlet NSTextField *prefFontFamilyNameSize;
@property (nonatomic, weak) IBOutlet NSTextField *printFontFamilyNameSize;

@property (nonatomic, weak) IBOutlet NSPopUpButton *encodingMenuInOpen;
@property (nonatomic, weak) IBOutlet NSPopUpButton *encodingMenuInNew;

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

@end




#pragma mark -

@implementation CEPreferencesController

#pragma mark Class Methods

//=======================================================
// Class method
//
//=======================================================

// ------------------------------------------------------
/// return singleton instance
+ (instancetype)sharedController
// ------------------------------------------------------
{
    static dispatch_once_t predicate;
    static id shared = nil;
    
    dispatch_once(&predicate, ^{
        shared = [[self alloc] init];
    });
    
    return shared;
}



#pragma mark Superclass Methods

//=======================================================
// Public method
//
//=======================================================

// ------------------------------------------------------
/// 初期化
- (instancetype)init
// ------------------------------------------------------
{
    self = [super initWithWindowNibName:@"Preferences"];
    
    return self;
}


// ------------------------------------------------------
/// 環境設定パネルを開く
- (IBAction)showWindow:(id)sender
// ------------------------------------------------------
{
    if (![[self window] isVisible]) {
        [self setFontFamilyNameAndSize];
        // 拡張子重複エラー表示ボタンの有効化を制御
        [[self syntaxStyleXtsnErrButton] setEnabled:[[CESyntaxManager sharedManager] existsExtensionError]];
    }
    [super showWindow:sender];
}



#pragma mark Public Methods

//=======================================================
// Public method
//
//=======================================================

// ------------------------------------------------------
/// エンコーディング設定メニューを生成
- (void)setupEncodingMenus:(NSArray *)menuItems
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
/// シンタックスカラーリングスタイル選択メニューを生成
- (void)setupSyntaxMenus
// ------------------------------------------------------
{
    [self setupSyntaxStylesPopup];
    [self changedSyntaxStylesPopup:self];
}


// ------------------------------------------------------
/// フォントパネルでフォントが変更された
- (void)changeFont:(id)sender
// ------------------------------------------------------
{
    // (引数"sender"はNSFontManegerのインスタンス)
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    NSFont *newFont = [sender convertFont:[NSFont systemFontOfSize:0]];
    NSString *name = [newFont fontName];
    CGFloat size = [newFont pointSize];

    if ([[[self window] contentView] subviews][0] == [self formatView]) {
        [defaults setObject:name forKey:k_key_fontName];
        [defaults setFloat:size forKey:k_key_fontSize];
        [self setFontFamilyNameAndSize];
        
    } else if ([[[self window] contentView] subviews][0] == [self printView]) {
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
/// Nibファイル読み込み直後
- (void)awakeFromNib
// ------------------------------------------------------
{
    // 最初のビューを選ぶ
    NSToolbarItem *leftmostItem = [[[self window] toolbar] items][0];
    [[[self window] toolbar] setSelectedItemIdentifier:[leftmostItem itemIdentifier]];
    [self switchView:leftmostItem];
    [[self window] center];
    
    // 各種セットアップ
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
/// ウインドウが閉じる
- (void)windowWillClose:(NSNotification *)notification
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
// Selector for Notification (NSTextView)
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
/// ツールバーからビューをスイッチする
- (IBAction)switchView:(id)sender
// ------------------------------------------------------
{
    // detect clicked icon and select a view to switch
    NSView   *newView;
    switch ([sender tag]) {
        case CEGeneralPreferences:     newView = [self generalView];     break;
        case CEViewPreferences:        newView = [self viewView];        break;
        case CEWindowPreferences:      newView = [self windowView];      break;
        case CEFormatPreferences:      newView = [self formatView];      break;
        case CESyntaxPreferences:      newView = [self syntaxView];      break;
        case CEFileDropPreferences:    newView = [self fileDropView];    break;
        case CEKeyBindingsPreferences: newView = [self keyBindingsView]; break;
        case CEPrintPreferences:       newView = [self printView];       break;
    }
    
    // remove current view from the main view
    for (NSView *view in [[[self window] contentView] subviews]) {
        [view removeFromSuperview];
    }
    
    // set window title
    [[self window] setTitle:[sender label]];
    
    // resize window to fit to new view
    NSRect frame    = [[self window] frame];
    NSRect newFrame = [[self window] frameRectForContentRect:[newView frame]];
    newFrame.origin    = frame.origin;
    newFrame.origin.y += NSHeight(frame) - NSHeight(newFrame);
    [[self window] setFrame:newFrame display:YES animate:YES];
    
    // add new view to the main view
    [[[self window] contentView] addSubview:newView];
}


// ------------------------------------------------------
/// フォントパネルを表示
- (IBAction)showFonts:(id)sender
//-------------------------------------------------------
{
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    NSFontManager *manager = [NSFontManager sharedFontManager];
    NSFont *font;

    
    if ([[[self window] contentView] subviews][0] == [self formatView]) {
        font = [NSFont fontWithName:[defaults stringForKey:k_key_fontName]
                               size:(CGFloat)[defaults doubleForKey:k_key_fontSize]];
        
    } else if ([[[self window] contentView] subviews][0] == [self printView]) {
        font = [NSFont fontWithName:[defaults stringForKey:k_key_printFontName]
                               size:(CGFloat)[defaults doubleForKey:k_key_printFontSize]];
    }

    [[self window] makeFirstResponder:[self window]];
    [manager setSelectedFont:font isMultiple:NO];
    [manager orderFrontFontPanel:sender];
}


// ------------------------------------------------------
/// エンコーディングリスト編集シートを開き、閉じる
- (IBAction)openEncodingEditSheet:(id)sender
// ------------------------------------------------------
{
    CEEncodingListSheetController *sheetController = [[CEEncodingListSheetController alloc] init];
    NSWindow *sheet = [sheetController window];
    
    // シートを表示してモーダルループに入る(閉じる命令は CEEncodingListSheetController内 で)
    [NSApp beginSheet:sheet modalForWindow:[self window] modalDelegate:self didEndSelector:NULL contextInfo:NULL];
    [NSApp runModalForWindow:sheet];

    // シートを閉じる
    [NSApp endSheet:sheet];
    [[sheetController window] orderOut:self];
    [[self window] makeKeyAndOrderFront:self];
}


// ------------------------------------------------------
/// サイズ設定のためのサンプルウィンドウを開く
- (IBAction)openSizeSampleWindow:(id)sender
// ------------------------------------------------------
{
    // モーダルで表示
    CESizeSampleWindowController *sampleWindowController = [[CESizeSampleWindowController alloc] initWithWindowNibName:@"SizeSampleWindow"];
    [sampleWindowController showWindow:sender];
    [NSApp runModalForWindow:[sampleWindowController window]];
    
    [[self window] makeKeyAndOrderFront:self];
}


// ------------------------------------------------------
/// カラーシンタックス編集シートを開き、閉じる
- (IBAction)openSyntaxEditSheet:(id)sender
// ------------------------------------------------------
{
    NSInteger selected = [[self syntaxStylesPopup] indexOfSelectedItem] - 2; // "None"とセパレータ分のオフセット
    if (([sender tag] != k_syntaxNewTag) && (selected < 0)) { return; }

    if (![[CESyntaxManager sharedManager] setSelectionIndexOfStyle:selected mode:[sender tag]]) {
        return;
    }
    NSString *oldName = [[self syntaxStylesPopup] titleOfSelectedItem];

    // シートウィンドウを表示してモーダルループに入る
    // (閉じる命令は CESyntaxManagerのcloseSyntaxEditSheet: で)
    NSWindow *sheet = [[CESyntaxManager sharedManager] editWindow];

    [NSApp beginSheet:sheet
       modalForWindow:[self window]
        modalDelegate:self
       didEndSelector:NULL
          contextInfo:NULL];
    [NSApp runModalForWindow:sheet];


    // === 以下、シートを閉じる処理
    // OKボタンが押されていたとき（キャンセルでも、最初の状態に戻していいかもしれない (1/21)） ********
    if ([[CESyntaxManager sharedManager] isOkButtonPressed]) {
        // 当該スタイルを適用しているドキュメントに前面に出たときの再カラーリングフラグを立てる
        NSString *newName = [[CESyntaxManager sharedManager] editedNewStyleName];
        NSDictionary *styleNameDict = @{k_key_oldStyleName: oldName,
                                        k_key_newStyleName: newName};
        [[NSApp orderedDocuments] makeObjectsPerformSelector:@selector(setRecolorFlagToWindowControllerWithStyleName:)
                                                  withObject:styleNameDict];
        
        [[CESyntaxManager sharedManager] setEditedNewStyleName:@""];
        // シンタックスカラーリングスタイル指定メニューを再構成、選択をクリアしてボタン類を有効／無効化
        [(CEAppController *)[[NSApplication sharedApplication] delegate] buildAllSyntaxMenus];
        // 拡張子重複エラー表示ボタンの有効化を制御
        [[self syntaxStyleXtsnErrButton] setEnabled:
                [[CESyntaxManager sharedManager] existsExtensionError]];
    }
    // シートを閉じる
    [NSApp endSheet:sheet];
    [sheet orderOut:self];
    [[self window] makeKeyAndOrderFront:self];
}


// ------------------------------------------------------
/// シンタックスカラーリングスタイル指定メニューまたはカラーリング実施チェックボックスが変更された
- (IBAction)changedSyntaxStylesPopup:(id)sender
// ------------------------------------------------------
{
    BOOL isEnabled = ([[self syntaxStylesPopup] indexOfSelectedItem] > 1);

    [[self syntaxStyleEditButton] setEnabled:isEnabled];
    [[self syntaxStyleCopyButton] setEnabled:isEnabled];
    [[self syntaxStyleExportButton] setEnabled:isEnabled];

    if (isEnabled &&
        ![[CESyntaxManager sharedManager] isDefaultSyntaxStyle:[[self syntaxStylesPopup] title]])
    {
        [[self syntaxStyleDeleteButton] setEnabled:YES];
    } else {
        [[self syntaxStyleDeleteButton] setEnabled:NO];
    }
}


// ------------------------------------------------------
/// シンタックスカラーリングスタイル削除ボタンが押された
- (IBAction)deleteSyntaxStyle:(id)sender
// ------------------------------------------------------
{
    NSInteger selected = [[self syntaxStylesPopup] indexOfSelectedItem] - 2;

    if (![[CESyntaxManager sharedManager] setSelectionIndexOfStyle:selected mode:k_syntaxNoSheetTag]) {
        return;
    }
    NSString *message = [NSString stringWithFormat:NSLocalizedString(@"Delete the Syntax coloring style \"%@\" ?", nil),
                         [[self syntaxStylesPopup] title]];
    NSAlert *alert = [NSAlert alertWithMessageText:message
                                     defaultButton:NSLocalizedString(@"Cancel", nil)
                                   alternateButton:NSLocalizedString(@"Delete", nil)
                                       otherButton:nil
                         informativeTextWithFormat:NSLocalizedString(@"Deleted style cannot be restored.", nil)];

    [alert beginSheetModalForWindow:[self window]
                      modalDelegate:self
                     didEndSelector:@selector(deleteStyleAlertDidEnd:returnCode:contextInfo:) contextInfo:NULL];
}


// ------------------------------------------------------
/// シンタックスカラーリングスタイルインポートボタンが押された
- (IBAction)importSyntaxStyle:(id)sender
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
        if ([[CESyntaxManager sharedManager] existsStyleFileWithStyleName:styleName]) {
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
            [alert beginSheetModalForWindow:[self window] modalDelegate:self
                             didEndSelector:@selector(secondarySheedlDidEnd:returnCode:contextInfo:)
                                contextInfo:(__bridge_retained void *)(URL)];
        } else {
            // 重複するファイル名がないとき、インポート実行
            [self doImport:URL withCurrentSheetWindow:openPanel];
        }
    }];
}



// ------------------------------------------------------
/// シンタックスカラーリングスタイルエクスポートボタンが押された
- (IBAction)exportSyntaxStyle:(id)sender
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
        NSURL *sourceURL = [[CESyntaxManager sharedManager] URLOfStyle:[[self syntaxStylesPopup] title]];
        NSURL *destURL = [savePanel URL];
        
        // 同名ファイルが既にあるときは、削除(Replace の確認は、SavePanel で自動的に行われている)
        if ([fileManager fileExistsAtPath:[destURL path]]) {
            [fileManager removeItemAtURL:destURL error:nil];
        }
        [fileManager copyItemAtURL:sourceURL toURL:destURL error:nil];
    }];
}


// ------------------------------------------------------
/// カラーシンタックス拡張子重複エラー表示シートを開き、閉じる
- (IBAction)openSyntaxExtensionErrorSheet:(id)sender
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
/// ファイルドロップ定型文字列挿入メニューが選択された
- (IBAction)insertFormatStringInFileDrop:(id)sender
// ------------------------------------------------------
{
    NSString *title = [(NSMenuItem *)sender title];

    if (title) {
        [[self window] makeFirstResponder:[self fileDropTextView]];
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

    [[self window] makeFirstResponder:[self fileDropTableView]];
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


// ------------------------------------------------------
/// キーバインディング編集シートを開き、閉じる
- (IBAction)openKeyBindingEditSheet:(id)sender
// ------------------------------------------------------
{
    // シートウィンドウを表示してモーダルループに入る
    // (閉じる命令は CEKeyBindingManager の closeKeyBindingEditSheet: で)
    NSWindow *sheet = [[CEKeyBindingManager sharedManager] editSheetWindowOfMode:[sender tag]];

    if ((sheet != nil) &&
        [[CEKeyBindingManager sharedManager] setupOutlineDataOfMode:[sender tag]])
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


//------------------------------------------------------
/// 既存のファイルを開くエンコーディングが変更されたとき、選択項目をチェック
- (IBAction)checkSelectedItemOfEncodingMenuInOpen:(id)sender
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
/// ヘルプの環境設定説明部分を開く
- (IBAction)openPrefHelp:(id)sender
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
/// すべてのテキストビューのスマートインサート／デリート実行を設定
- (IBAction)setSmartInsertAndDeleteToAllTextView:(id)sender
// ------------------------------------------------------
{
    [[NSApp orderedDocuments] makeObjectsPerformSelector:@selector(setSmartInsertAndDeleteToTextView)];
}



// ------------------------------------------------------
/// すべてのテキストビューのスマート引用符／ダッシュ実行を設定
- (IBAction)setSmartQuotesToAllTextView:(id)sender
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
//// FileDrop 設定を UserDefaults に書き戻す
- (void)writeBackFileDropArray
// ------------------------------------------------------
{
    [[NSUserDefaults standardUserDefaults] setObject:[[self fileDropController] content] forKey:k_key_fileDropArray];
}


//------------------------------------------------------
/// Force update UserDefaults
- (void)updateUserDefaults
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
/// メインウィンドウのフォントファミリー名とサイズをprefFontFamilyNameSizeに表示させる
- (void)setFontFamilyNameAndSize
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
/// 不可視文字表示設定ポップアップメニューを生成
- (void)setupInvisibleSpacePopup
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
/// 不可視文字表示設定ポップアップメニューを生成
- (void)setupInvisibleTabPopup
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
/// 不可視文字表示設定ポップアップメニューを生成
- (void)setupInvisibleNewLinePopup
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
/// 不可視文字表示設定ポップアップメニューを生成
- (void)setupInvisibleFullwidthSpacePopup
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
/// シンタックスカラーリングスタイル指定ポップアップメニューを生成
- (void)setupSyntaxStylesPopup
// ------------------------------------------------------
{
    NSArray *styleNames = [[CESyntaxManager sharedManager] styleNames];
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
/// 既存ファイルを開くときのエンコーディングメニューで自動認識以外が選択されたときの警告シートが閉じる直前
- (void)autoDetectAlertDidEnd:(NSAlert *)sheet
        returnCode:(NSInteger)returnCode contextInfo:(void *)contextInfo
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
/// styleインポート実行
- (void)doImport:(NSURL *)fileURL withCurrentSheetWindow:(NSWindow *)inWindow
// ------------------------------------------------------
{
    if ([[CESyntaxManager sharedManager] importStyleFile:[fileURL path]]) {
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

    NSString *message = [NSString stringWithFormat:NSLocalizedString(@"Delete the File Drop setting ?\n \"%@\"", nil), extension];
    NSAlert *alert = [NSAlert alertWithMessageText:message
                                     defaultButton:NSLocalizedString(@"Cancel", nil)
                                   alternateButton:NSLocalizedString(@"Delete", nil) otherButton:nil
                         informativeTextWithFormat:NSLocalizedString(@"Deleted setting cannot be restored.", nil)];
    
    [alert beginSheetModalForWindow:[self window]
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


// ------------------------------------------------------
/// style削除確認シートが閉じる直前
- (void)deleteStyleAlertDidEnd:(NSAlert *)alert returnCode:(NSInteger)returnCode contextInfo:(void *)contextInfo
// ------------------------------------------------------
{
    if (returnCode != NSAlertAlternateReturn) { // != Delete
        return;
    }
    
    if (![[CESyntaxManager sharedManager] removeStyleFileWithStyleName:
          [_syntaxStylesPopup title]]) {
        // 削除できなければ、その旨をユーザに通知
        [[alert window] orderOut:self];
        [[self window] makeKeyAndOrderFront:self];
        NSAlert *alert = [NSAlert alertWithMessageText:NSLocalizedString(@"Error occured.", nil)
                                         defaultButton:nil
                                       alternateButton:nil otherButton:nil
                             informativeTextWithFormat:NSLocalizedString(@"Sorry, could not delete \"%@\".", nil),
                          [[self syntaxStylesPopup] title]];
        NSBeep();
        [alert beginSheetModalForWindow:[self window] modalDelegate:self didEndSelector:NULL contextInfo:NULL];
        return;
    }
    // 当該スタイルを適用しているドキュメントを"None"スタイルにし、前面に出たときの再カラーリングフラグを立てる
    [(CEAppController *)[[NSApplication sharedApplication] delegate] buildAllSyntaxMenus];
    // シンタックスカラーリングスタイル指定メニューを再構成、選択をクリアしてボタン類を有効／無効化
    [(CEAppController *)[[NSApplication sharedApplication] delegate] buildAllSyntaxMenus];
    // 拡張子重複エラー表示ボタンの有効化を制御
    [[self syntaxStyleXtsnErrButton] setEnabled:[[CESyntaxManager sharedManager] existsExtensionError]];
}


// ------------------------------------------------------
/// セカンダリシートが閉じる直前
- (void)secondarySheedlDidEnd:(NSAlert *)alert returnCode:(NSInteger)returnCode contextInfo:(void *)contextInfo
// ------------------------------------------------------
{
    if (returnCode == NSAlertAlternateReturn) { // = Replace
        [self doImport:CFBridgingRelease(contextInfo) withCurrentSheetWindow:[alert window]];
    }
}

@end
