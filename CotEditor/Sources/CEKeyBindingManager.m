/*
 ==============================================================================
 CEKeyBindingManager
 
 CotEditor
 http://coteditor.github.io
 
 Created on 2005-09-01 by nakamuxu
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

#import "CEKeyBindingManager.h"
#import "CEApplication.h"
#import "CEUtils.h"
#import "constants.h"


@interface CEKeyBindingManager () <NSOutlineViewDataSource, NSOutlineViewDelegate>

@property (nonatomic, strong) IBOutlet NSWindow *menuEditSheet;  // シートが閉じた時自動的に片付けられるようわざとweakにしたいのだが、OS X 10.7 に引っかかるのでstrong
@property (nonatomic, weak) IBOutlet NSOutlineView *menuOutlineView;
@property (nonatomic, weak) IBOutlet NSTextField *menuDuplicateTextField;
@property (nonatomic, weak) IBOutlet NSButton *menuEditKeyButton;
@property (nonatomic, weak) IBOutlet NSButton *menuDeleteKeyButton;
@property (nonatomic, weak) IBOutlet NSButton *menuFactoryDefaultsButton;
@property (nonatomic, weak) IBOutlet NSButton *menuOkButton;

@property (nonatomic, strong) IBOutlet NSWindow *textEditSheet;  // シートが閉じた時自動的に片付けられるようわざとweakにしたいのだが、OS X 10.7 に引っかかるのでstrong
@property (nonatomic, weak) IBOutlet NSOutlineView *textOutlineView;
@property (nonatomic, weak) IBOutlet  NSTextField *textDuplicateTextField;
@property (nonatomic, weak) IBOutlet NSButton *textEditKeyButton;
@property (nonatomic, weak) IBOutlet NSButton *textDeleteKeyButton;
@property (nonatomic, weak) IBOutlet NSButton *textFactoryDefaultsButton;
@property (nonatomic, weak) IBOutlet NSButton *textOkButton;
@property (nonatomic, strong) IBOutlet NSTextView *textInsertStringTextView;  // on 10.8 NSTextView cannot be weak
@property (nonatomic) IBOutlet NSArrayController *textInsertStringArrayController;


@property (nonatomic) NSMutableArray *outlineDataArray;
@property (nonatomic) NSMutableArray *duplicateKeyCheckArray;
@property (nonatomic, copy) NSDictionary *defaultMenuKeyBindingDict;
@property (nonatomic, copy) NSDictionary *menuKeyBindingDict;
@property (nonatomic, copy) NSDictionary *textKeyBindingDict;
@property (nonatomic, copy) NSDictionary *unprintableKeyDict;
@property (nonatomic, copy) NSString *currentKeySpecChars;

@property (nonatomic) CEKeyBindingOutlineMode outlineMode;

@end




#pragma mark -

@implementation CEKeyBindingManager

#pragma mark Class Methods

//=======================================================
// Class method
//
//=======================================================

// ------------------------------------------------------
/// return singleton instance
+ (instancetype)sharedManager
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
// Superclass method
//
//=======================================================

// ------------------------------------------------------
/// 初期化
- (instancetype)init
// ------------------------------------------------------
{
    self = [super init];
    if (self) {
        _unprintableKeyDict = [self unprintableKeyDictionary];
        
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(addCatchedMenuShortcutString:)
                                                     name:CECatchMenuShortcutNotification
                                                   object:NSApp];
    }
    return self;
}


// ------------------------------------------------------
/// あとかたづけ
- (void)dealloc
// ------------------------------------------------------
{
    // ノーティフィケーションセンタから自身を排除
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}


// ------------------------------------------------------
/// Nibファイル読み込み直後
- (void)awakeFromNib
// ------------------------------------------------------
{
    // ダブルクリックでトグルに展開するようアクションを設定する
    [[self menuOutlineView] setDoubleAction:@selector(doubleClickedOutlineViewRow:)];
    [[self menuOutlineView] setTarget:self];
}



#pragma mark Public Methods

//=======================================================
// Public method
//
//=======================================================

// ------------------------------------------------------
/// 起動時の準備
- (void)setupAtLaunching
// ------------------------------------------------------
{
    NSURL *URL = [[NSBundle mainBundle] URLForResource:@"DefaultMenuKeyBindings" withExtension:@"plist"];

    if ([URL checkResourceIsReachableAndReturnError:nil]) {
        [self setDefaultMenuKeyBindingDict:[NSDictionary dictionaryWithContentsOfURL:URL]];
    }
    /// 定義ファイルのセットアップと読み込み
    [self setupMenuKeyBindingDictionary];
    [self setupTextKeyBindingDictionary];
    
    [self resetAllMenuKeyBindingWithDictionary];
}


// ------------------------------------------------------
/// キーバインディング編集シート用ウィンドウを返す
- (NSWindow *)editSheetWindowOfMode:(CEKeyBindingOutlineMode)mode
// ------------------------------------------------------
{
    switch (mode) {
        case CEMenuModeOutline:
            // シートが呼び出されてから初めてnibを読み込む
            // ref. https://github.com/coteditor/CotEditor/issues/53
            if (![self menuEditSheet]) {
                // loadNibNamed:owner:topLevelObjects は10.8から。
                // loadNibNamed:owner:topLevelObjectsはトップレベルobjectを勝手にリテインしない
                if (floor(NSAppKitVersionNumber) <= NSAppKitVersionNumber10_7) {
                    [NSBundle loadNibNamed:@"MenuKeyBindingEditSheet" owner:self];
                    
                } else {
                    NSArray *objects;
                    [[NSBundle mainBundle] loadNibNamed:@"MenuKeyBindingEditSheet" owner:self
                    topLevelObjects:&objects];
                }
            }
            return [self menuEditSheet];
            
        case CETextModeOutline:
            if (![self textEditSheet]) {
                // シートが呼び出されてから初めてnibを読み込む
                // ref. https://github.com/coteditor/CotEditor/issues/53
                if (![self textEditSheet]) {
                    // loadNibNamed:owner:topLevelObjects は10.8から。
                    // loadNibNamed:owner:topLevelObjectsはトップレベルobjectを勝手にリテインしない
                    if (floor(NSAppKitVersionNumber) <= NSAppKitVersionNumber10_7) {
                        [NSBundle loadNibNamed:@"TextKeyBindingEditSheet" owner:self];
                        
                    } else {
                        NSArray *objects;
                        [[NSBundle mainBundle] loadNibNamed:@"TextKeyBindingEditSheet" owner:self
                                            topLevelObjects:&objects];
                    }
                }
            }
            return [self textEditSheet];
    }
    
    return nil;
}


// ------------------------------------------------------
/// 環境設定でシートを表示する準備
- (BOOL)setupOutlineDataOfMode:(CEKeyBindingOutlineMode)mode
// ------------------------------------------------------
{
    if ((mode != CEMenuModeOutline) && (mode != CETextModeOutline)) { return NO; }
    
    // モードの保持、データの準備、タイトルとメッセージの差し替え
    [self setOutlineMode:mode];
    switch (mode) {
        case CEMenuModeOutline:
        {
            [[self menuDuplicateTextField] setStringValue:@""];
            [self setOutlineDataArray:[self mainMenuArrayForOutlineData:[NSApp mainMenu]]];
            [self setDuplicateKeyCheckArray:[self duplicateKeyCheckArrayWithMenu:[NSApp mainMenu]]];
            [[self menuFactoryDefaultsButton] setEnabled:[[self menuKeyBindingSettingFileURL]
                                                          checkResourceIsReachableAndReturnError:nil]];
            [[self menuOutlineView] reloadData];
            [[self menuEditKeyButton] setEnabled:NO];
            // 現在の設定がデフォルト設定ならばデフォルト値を入力する
            if ([[self menuKeyBindingDict] isEqualToDictionary:[self defaultMenuKeyBindingDict]]) {
                [self resetOutlineDataArrayToFactoryDefaults:nil];
            }
        }
        break;
            
        case CETextModeOutline:
        {
            NSArray *insertTextArray = [[NSUserDefaults standardUserDefaults] arrayForKey:k_key_insertCustomTextArray];
            NSArray *factoryDefaultsOfInsertTextArray = [[[NSUserDefaults alloc] init] volatileDomainForName:NSRegistrationDomain][k_key_insertCustomTextArray];
            NSMutableArray *contentArray = [NSMutableArray array];
            
            [[self textDuplicateTextField] setStringValue:@""];
            [self setOutlineDataArray:[self textKeySpecCharArrayForOutlineDataWithFactoryDefaults:NO]];
            // （システム標準のキーバインディングとの重複は、チェックしない）
            [self setDuplicateKeyCheckArray:[[self outlineDataArray] mutableCopy]];
            [[self textFactoryDefaultsButton] setEnabled:
             (![[self outlineDataArray] isEqualToArray:[self duplicateKeyCheckArray]] ||
              ![factoryDefaultsOfInsertTextArray isEqualToArray:insertTextArray])];
            [[self textOutlineView] reloadData];
            for (id object in insertTextArray) {
                [contentArray addObject:[@{k_key_insertCustomText: object} mutableCopy]];
            }
            [[self textInsertStringArrayController] setContent:contentArray];
            [[self textInsertStringArrayController] setSelectionIndex:NSNotFound]; // 選択なし
            [[self textInsertStringTextView] setEditable:NO];
            [[self textInsertStringTextView] setBackgroundColor:[NSColor controlHighlightColor]];
            [[self textEditKeyButton] setEnabled:NO];
        }
        break;
    }

    return YES;
}


// ------------------------------------------------------
/// キー入力に応じたセレクタ文字列を返す
- (NSString *)selectorStringWithKeyEquivalent:(NSString *)string modifierFrags:(NSUInteger)modifierFlags
// ------------------------------------------------------
{
    NSString *keySpecChars = [self keySpecCharsFromKeyEquivalent:string modifierFrags:modifierFlags];

    return [self textKeyBindingDict][keySpecChars];
}



#pragma mark Protocol

//=======================================================
// NSOutlineViewDataSource Protocol(Category)
//
//=======================================================

// ------------------------------------------------------
/// 子アイテムの数を返す
- (NSInteger)outlineView:(NSOutlineView *)outlineView numberOfChildrenOfItem:(id)item
// ------------------------------------------------------
{
    if (item) {
        NSMutableArray *children = item[k_children];
        return (children) ? [children count] : 0;
    } else {
        return [[self outlineDataArray] count];
    }
}


// ------------------------------------------------------
/// アイテムが展開可能かどうかを返す
- (BOOL)outlineView:(NSOutlineView *)outlineView isItemExpandable:(id)item
// ------------------------------------------------------
{
    if (item) {
        return (item[k_children] != nil);
    } else {
        return YES;
    }
}


// ------------------------------------------------------
/// 子アイテムオブジェクトを返す
- (id)outlineView:(NSOutlineView *)outlineView child:(NSInteger)index ofItem:(id)item
// ------------------------------------------------------
{
    if (item) {
        return item[k_children][index];
    } else {
        return [self outlineDataArray][index];
    }
}


// ------------------------------------------------------
/// コラムに応じたオブジェクト(表示文字列)を返す
- (id)outlineView:(NSOutlineView *)outlineView objectValueForTableColumn:(NSTableColumn *)tableColumn byItem:(id)item
// ------------------------------------------------------
{
    id theItem = item ? : [self outlineDataArray];
    NSString *identifier = [tableColumn identifier];

    if ([identifier isEqualToString:k_keyBindingKey]) {
        return [self readableKeyStringsFromKeySpecChars:[theItem valueForKey:identifier]];
    }
    return [theItem valueForKey:identifier];
}


// ------------------------------------------------------
/// コラム編集直前、キー入力を取得するようにしてから許可を出す
- (BOOL)outlineView:(NSOutlineView *)outlineView shouldEditTableColumn:(NSTableColumn *)tableColumn item:(id)item
// ------------------------------------------------------
{
    NSString *identifier = [tableColumn identifier];
    
    if ([identifier isEqualToString:k_keyBindingKey] && !item[k_children]) {
        
        id theItem = item ? : [self outlineDataArray];

        if (![self currentKeySpecChars]) {
            // （値が既にセットされている時は更新しない）
            [self setCurrentKeySpecChars:[theItem valueForKey:identifier]];
        }
        [[NSNotificationCenter defaultCenter] postNotificationName:CESetKeyCatchModeToCatchMenuShortcutNotification
                                                            object:self
                                                          userInfo:@{k_keyCatchMode: @(CECatchMenuShortCutMode)}];
        switch ([self outlineMode]) {
            case CEMenuModeOutline:
                [[self menuDeleteKeyButton] setEnabled:YES];
                break;
            case CETextModeOutline:
                [[self textDeleteKeyButton] setEnabled:YES];
                break;
        }
        return YES;
    }
    return NO;
}


// ------------------------------------------------------
/// データをセット
- (void)outlineView:(NSOutlineView *)outlineView 
        setObjectValue:(id)object forTableColumn:(NSTableColumn *)tableColumn byItem:(id)item
// ------------------------------------------------------
{
    NSString *identifier = [tableColumn identifier];

    // 現在の表示値との比較
    if ([object isEqualToString:[self outlineView:outlineView objectValueForTableColumn:tableColumn byItem:item]]) {
        // データソースの値でなく表示値がそのまま入ってきているのは、選択状態になったあと何の編集もされなかった時
        if (([[NSApp currentEvent] type] == NSLeftMouseDown) &&
            ([self outlineMode] == CEMenuModeOutline) &&
            ([[[self menuDuplicateTextField] stringValue] length] > 0))
        {
            item[identifier] = @"";
            [[self menuDuplicateTextField] setStringValue:@""];
            [self showDuplicateKeySpecCharsMessageWithKeySpecChars:@"" oldChars:[self currentKeySpecChars]];
            
        } else if (([[NSApp currentEvent] type] == NSLeftMouseDown) &&
                   ([self outlineMode] == CETextModeOutline) &&
                   ([[[self textDuplicateTextField] stringValue] length] > 0))
        {
            item[identifier] = @"";
            [[self textDuplicateTextField] setStringValue:@""];
            [self showDuplicateKeySpecCharsMessageWithKeySpecChars:@"" oldChars:[self currentKeySpecChars]];
        }
        
    } else {
        // 現在の表示値と違っていたら、セット
        item[identifier] = object;
        // 他の値とダブっていたら、再び編集状態にする
        if (![self showDuplicateKeySpecCharsMessageWithKeySpecChars:object oldChars:[self currentKeySpecChars]]) {
            __block typeof(self) blockSelf = self;
            dispatch_async(dispatch_get_main_queue(), ^{
                [blockSelf performEditOutlineViewSelectedKeyBindingKeyColumn];
            });
        }
    }
    switch ([self outlineMode]) {
        case CEMenuModeOutline:
            [[self menuDeleteKeyButton] setEnabled:NO];
            break;
        case CETextModeOutline:
            [[self textDeleteKeyButton] setEnabled:NO];
            break;
    }
    [self setCurrentKeySpecChars:nil];
}



#pragma mark Delegate and Notification

//=======================================================
// Delegate method (NSOutlineView)
//  <== menuOutlineView, textOutlineView
//=======================================================

// ------------------------------------------------------
/// 選択行の変更を許可
- (BOOL)outlineView:(NSOutlineView *)outlineView shouldSelectItem:(id)item
// ------------------------------------------------------
{
    NSButton *editButton;
    switch ([self outlineMode]) {
        case CEMenuModeOutline:
            editButton = [self menuEditKeyButton];
            break;
        case CETextModeOutline:
            editButton = [self textEditKeyButton];
            break;
        default:
            return NO;
    }

    // キー取得を停止
    [[NSNotificationCenter defaultCenter] postNotificationName:CESetKeyCatchModeToCatchMenuShortcutNotification
                                                        object:self
                                                      userInfo:@{k_keyCatchMode: @(CEKeyDownNoCatchMode)}];
    // テキストのバインディングを編集している時は挿入文字列配列コントローラの選択オブジェクトを変更
    if ([self outlineMode] == CETextModeOutline) {
        BOOL isEnabled = [[item valueForKey:k_selectorString] hasPrefix:@"insertCustomText"];
        NSUInteger index = [outlineView rowForItem:item];

        [[self textInsertStringArrayController] setSelectionIndex:index];
        [[self textInsertStringTextView] setEditable:isEnabled];
        NSColor *color = isEnabled ? [NSColor controlBackgroundColor] : [NSColor controlHighlightColor];
        [[self textInsertStringTextView] setBackgroundColor:color];
    }
    
    // 編集ボタンを有効化／無効化
    [editButton setEnabled:(!item[k_children])];

    return YES;
}



#pragma mark Action Messages

//=======================================================
// Action messages
//
//=======================================================

// ------------------------------------------------------
/// 選択行のキー編集開始
- (IBAction)editKeyBindingKey:(id)sender
// ------------------------------------------------------
{
    [self performEditOutlineViewSelectedKeyBindingKeyColumn];
}


// ------------------------------------------------------
/// 選択行のキー削除
- (IBAction)deleteKeyBindingKey:(id)sender
// ------------------------------------------------------
{
    NSWindow *sheet;
    NSOutlineView *outlineView;
    
    switch ([self outlineMode]) {
        case CEMenuModeOutline:
            sheet = [self menuEditSheet];
            outlineView = [self menuOutlineView];
            break;
        case CETextModeOutline:
            sheet = [self textEditSheet];
            outlineView = [self textOutlineView];
            break;
        default:
            return;
    }
    
    if (!sheet || !outlineView) { return; }

    NSText *fieldEditor = [sheet fieldEditor:NO forObject:outlineView];

    [fieldEditor setString:@""];

    [sheet endEditingFor:fieldEditor];
    [sheet makeFirstResponder:outlineView];
}


// ------------------------------------------------------
/// キーバインディングを出荷時設定に戻す
- (IBAction)resetOutlineDataArrayToFactoryDefaults:(id)sender
// ------------------------------------------------------
{
    switch ([self outlineMode]) {
        case CEMenuModeOutline:
        {
            NSMutableArray *tmpArray = [[self outlineDataArray] mutableCopy];
            if (tmpArray) {
                [self resetKeySpecCharsToFactoryDefaultsOfOutlineDataArray:tmpArray];
                [self setOutlineDataArray:tmpArray];
                [self setDuplicateKeyCheckArray:[[self duplicateKeyCheckArrayWithArray:[self outlineDataArray]] mutableCopy]];
                [[self menuEditKeyButton] setEnabled:NO];
                [[self menuOutlineView] deselectAll:nil];
                [[self menuOutlineView] reloadData];
            }
            [[self menuFactoryDefaultsButton] setEnabled:NO];
        }
        break;
            
        case CETextModeOutline:
        {
            NSMutableArray *contents = [NSMutableArray array];
            NSArray *defaultInsertTexts = [[[NSUserDefaults alloc] init] volatileDomainForName:NSRegistrationDomain][k_key_insertCustomTextArray];
            
            for (id object in defaultInsertTexts) {
                NSMutableDictionary *dict = [NSMutableDictionary dictionaryWithObject:object forKey:k_key_insertCustomText];
                [contents addObject:dict];
            }
            [[self textOutlineView] deselectAll:nil];
            [self setOutlineDataArray:[self textKeySpecCharArrayForOutlineDataWithFactoryDefaults:YES]];
            [self setDuplicateKeyCheckArray:[[self outlineDataArray] mutableCopy]];
            [[self textInsertStringArrayController] setContent:contents];
            [[self textInsertStringArrayController] setSelectionIndex:NSNotFound]; // 選択なし
            [[self textEditKeyButton] setEnabled:NO];
            [[self textOutlineView] reloadData];
            [[self textInsertStringTextView] setEditable:NO];
            [[self textInsertStringTextView] setBackgroundColor:[NSColor controlHighlightColor]];
            [[self textFactoryDefaultsButton] setEnabled:NO];
        }
        break;
    }
}


// ------------------------------------------------------
/// キーバインディング編集シートの OK / Cancel ボタンが押された
- (IBAction)closeKeyBindingEditSheet:(id)sender
// ------------------------------------------------------
{
    // フォーカスを移して入力中の値を確定
    [[sender window] makeFirstResponder:sender];
    // キー入力取得を停止
    [[NSNotificationCenter defaultCenter] postNotificationName:CESetKeyCatchModeToCatchMenuShortcutNotification
                                                        object:self
                                                      userInfo:@{k_keyCatchMode: @(CEKeyDownNoCatchMode)}];

    if ([sender tag] == k_okButtonTag) { // ok のときデータを保存、反映させる
        [self saveOutlineViewData];
    }
    // シートを閉じる
    [NSApp stopModal];
    // シート内アウトラインビューデータを開放
    [self setOutlineDataArray:nil];
    
    switch ([self outlineMode]) {
        case CEMenuModeOutline:
            [[self menuOutlineView] reloadData]; // （ここでリロードしておかないと、選択行が残ったり展開されたままになる）
            break;
            
        case CETextModeOutline:
            [[self textInsertStringArrayController] setContent:nil];
            [[self textOutlineView] reloadData]; // （ここでリロードしておかないと、選択行が残ったり展開されたままになる）
            break;
    }
    
    // 重複チェック配列を開放
    [self setDuplicateKeyCheckArray:nil];
}


//------------------------------------------------------
/// アウトラインビューの行がダブルクリックされた
- (IBAction)doubleClickedOutlineViewRow:(id)sender
// ------------------------------------------------------
{
    if (![sender isKindOfClass:[NSOutlineView class]]) { return; }

    NSInteger selectedRow = [(NSOutlineView *)sender selectedRow];

    if (selectedRow != -1) {
        id item = [(NSOutlineView *)sender itemAtRow:selectedRow];

        // ダブルクリックでトグルに展開する
        if ([(NSOutlineView *)sender isExpandable:item]) {
            [(NSOutlineView *)sender expandItem:item];
        } else {
            [(NSOutlineView *)sender collapseItem:item];
        }
    }
}




#pragma mark Private Mthods

//=======================================================
// Private method
//
//=======================================================

//------------------------------------------------------
/// キーバインディング設定ファイル保存用ディレクトリのURLを返す
- (NSURL *)userSettingDirecotryURL
//------------------------------------------------------
{
    return [[[NSFileManager defaultManager] URLForDirectory:NSApplicationSupportDirectory
                                                   inDomain:NSUserDomainMask
                                          appropriateForURL:nil
                                                     create:NO
                                                      error:nil]
            URLByAppendingPathComponent:@"CotEditor/KeyBindings"];
    
}

//------------------------------------------------------
/// メニューキーバインディング設定ファイル保存用ファイルのURLを返す
- (NSURL *)menuKeyBindingSettingFileURL
//------------------------------------------------------
{
    return [[[self userSettingDirecotryURL] URLByAppendingPathComponent:@"MenuKeyBindings"]
                                            URLByAppendingPathExtension:@"plist"];
}


//------------------------------------------------------
/// メニューキーバインディング設定ファイル保存用ファイルのURLを返す
- (NSURL *)textKeyBindingSettingFileURL
//------------------------------------------------------
{
    return [[[self userSettingDirecotryURL] URLByAppendingPathComponent:@"TextKeyBindings"]
                                            URLByAppendingPathExtension:@"plist"];
}


//------------------------------------------------------
/// ユーザ設定ディレクトリがない場合は作成する
- (BOOL)prepareUserSettingDicrectory
//------------------------------------------------------
{
    NSURL *URL = [self userSettingDirecotryURL];
    BOOL success;
    
    BOOL isDirectory;
    BOOL exists = [[NSFileManager defaultManager] fileExistsAtPath:[URL path] isDirectory:&isDirectory];
    
    if (exists && isDirectory) {
        return YES;
        
    } else if (!isDirectory) {
        NSLog(@"Error! Key Bindings directory could not be found.");
        return NO;
    }
    
    return [[NSFileManager defaultManager] createDirectoryAtURL:URL
                                    withIntermediateDirectories:YES attributes:nil error:nil];
}


// ------------------------------------------------------
/// メニューキーバインディング定義ファイルのセットアップと読み込み
- (void)setupMenuKeyBindingDictionary
// ------------------------------------------------------
{
    NSDictionary *dict = [NSDictionary dictionaryWithContentsOfURL:[self menuKeyBindingSettingFileURL]] ?
                       : [self defaultMenuKeyBindingDict];
    
    [self setMenuKeyBindingDict:dict];
}


// ------------------------------------------------------
/// テキストキーバインディング定義ファイルのセットアップと読み込み
- (void)setupTextKeyBindingDictionary
// ------------------------------------------------------
{
    NSURL *fileURL = [self textKeyBindingSettingFileURL];
    
    if ([self prepareUserSettingDicrectory]) {
        NSURL *sourceURL = [[NSBundle mainBundle] URLForResource:@"DefaultTextKeyBindings" withExtension:@"plist"];
        
        if ([sourceURL checkResourceIsReachableAndReturnError:nil] &&
            ![fileURL checkResourceIsReachableAndReturnError:nil]) {
            if (![[NSFileManager defaultManager] copyItemAtURL:sourceURL toURL:fileURL error:nil]) {
                NSLog(@"Error! Could not copy \"%@\" to \"%@\"...", sourceURL, fileURL);
                return;
            }
        }
        
        // データ読み込み
        [self setTextKeyBindingDict:[NSDictionary dictionaryWithContentsOfURL:fileURL]];
    }
}


//------------------------------------------------------
/// すべてのメニューのキーボードショートカットをクリアする
- (void)clearAllMenuKeyBindingOf:(NSMenu *)menu
//------------------------------------------------------
{
    for (NSMenuItem *item in [menu itemArray]) {
        // フォントサイズ変更、エンコーディングの各項目、カラーリングの各項目、などは変更しない
        if ([[self selectorStringsToIgnore] containsObject:NSStringFromSelector([item action])] ||
            ([item tag] == k_servicesMenuItemTag) ||
            ([item tag] == k_windowPanelsMenuItemTag) ||
            ([item tag] == k_scriptMenuDirectoryTag))
        {
            continue;
        }
        [item setKeyEquivalent:@""];
        [item setKeyEquivalentModifierMask:0];
        if ([item hasSubmenu]) {
            [self clearAllMenuKeyBindingOf:[item submenu]];
        }
    }
}


//------------------------------------------------------
/// キーボードショートカット設定を反映させる
- (void)updateMenuValidation:(NSMenu *)menu
//------------------------------------------------------
{
    [menu update];
    
    for (NSMenuItem *item in [menu itemArray]) {
        if ([item hasSubmenu]) {
            [self updateMenuValidation:[item submenu]];
        }
    }
}


//------------------------------------------------------
/// すべてのメニューにキーボードショートカットを設定し直す
- (void)resetAllMenuKeyBindingWithDictionary
//------------------------------------------------------
{
    if (![self menuKeyBindingDict]) { return; }

    // まず、全メニューのショートカット定義をクリアする
    [self clearAllMenuKeyBindingOf:[NSApp mainMenu]];

    [self resetKeyBindingWithDictionaryTo:[NSApp mainMenu]];
    // メニュー更新（キーボードショートカット設定反映）
    [self updateMenuValidation:[NSApp mainMenu]];
}


//------------------------------------------------------
/// メニューにキーボードショートカットを設定する
- (void)resetKeyBindingWithDictionaryTo:(NSMenu *)menu
//------------------------------------------------------
{
// NSMenu の indexOfItemWithTarget:andAction: だと取得できないメニューアイテムがあるため、メニューをひとつずつなめる

    for (NSMenuItem *item in [menu itemArray]) {
        if (([item hasSubmenu]) &&
            ([item tag] != k_servicesMenuItemTag) &&
            ([item tag] != k_windowPanelsMenuItemTag) &&
            ([item tag] != k_scriptMenuDirectoryTag))
        {
            [self resetKeyBindingWithDictionaryTo:[item submenu]];
        } else {
            NSString *selectorString = NSStringFromSelector([item action]);
            // フォントサイズ変更、エンコーディングの各項目、カラーリングの各項目、などは変更しない
            if ([[self selectorStringsToIgnore] containsObject:NSStringFromSelector([item action])] ||
                ([item tag] == k_servicesMenuItemTag) ||
                ([item tag] == k_windowPanelsMenuItemTag) ||
                ([item tag] == k_scriptMenuDirectoryTag)) {
                continue;
            }
            NSString *keySpecChars = [self keySpecCharsInDictionaryFromSelectorString:selectorString];
            NSUInteger modifierMask = 0;
            NSString *keyEquivalent = [CEUtils keyEquivalentAndModifierMask:&modifierMask
                                                                 fromString:keySpecChars
                                                        includingCommandKey:YES];

            // keySpecChars があり Cmd が設定されている場合だけ、反映させる
            if (([keySpecChars length] > 0) && (modifierMask & NSCommandKeyMask)) {
                // 日本語リソースが使われたとき、Input BackSlash の keyEquivalent を変更する
                // （半角円マークのままだと半角カナ「エ」に化けるため）
                if ([keyEquivalent isEqualToString:[NSString stringWithCharacters:&k_yenMark length:1]] &&
                    [[[NSBundle mainBundle] preferredLocalizations][0] isEqualToString:@"ja"])
                {
                    [item setKeyEquivalent:@"\\"];
                } else {
                    [item setKeyEquivalent:keyEquivalent];
                }
                [item setKeyEquivalentModifierMask:modifierMask];
            }
        }
    }
}


//------------------------------------------------------
/// 現在のメニューからショートカットキー設定を読み込み編集用アウトラインビューデータ配列を返す
- (NSMutableArray *)mainMenuArrayForOutlineData:(NSMenu *)menu
//------------------------------------------------------
{
    NSMutableArray *outArray = [NSMutableArray array];

    for (NSMenuItem *item in [menu itemArray]) {
        if ([item isSeparatorItem] || ([[item title] length] == 0)) { continue; }
        
        NSMutableDictionary *theDict;
        if (([item hasSubmenu]) &&
                   ([item tag] != k_servicesMenuItemTag) &&
                   ([item tag] != k_windowPanelsMenuItemTag) &&
                   ([item tag] != k_scriptMenuDirectoryTag))
        {
            NSMutableArray *subArray = [self mainMenuArrayForOutlineData:[item submenu]];
            theDict = [@{k_title: [item title],
                         k_children: subArray} mutableCopy];
            
        } else {
            NSString *selectorString = NSStringFromSelector([item action]);
            // フォントサイズ変更、エンコーディングの各項目、カラーリングの各項目、などはリストアップしない
            if ([[self selectorStringsToIgnore] containsObject:selectorString] ||
                ([item tag] == k_servicesMenuItemTag) ||
                ([item tag] == k_windowPanelsMenuItemTag) ||
                ([item tag] == k_scriptMenuDirectoryTag))
            {
                continue;
            }
            
            NSString *keyEquivalent = [item keyEquivalent];
            NSString *keySpecChars;
            if ([keyEquivalent length] > 0) {
                NSUInteger modifierMask = [item keyEquivalentModifierMask];
                keySpecChars = [self keySpecCharsFromKeyEquivalent:keyEquivalent modifierFrags:modifierMask];
            } else {
                keySpecChars = @"";
            }
            theDict = [@{k_title: [item title],
                         k_keyBindingKey: keySpecChars,
                         k_selectorString: selectorString} mutableCopy];
        }
        [outArray addObject:theDict];
    }
    return outArray;
}


//------------------------------------------------------
/// テキストキーバインディングの現在の保持データから設定を読み込み編集用アウトラインビューデータ配列を返す
- (NSMutableArray *)textKeySpecCharArrayForOutlineDataWithFactoryDefaults:(BOOL)usesFactoryDefaults
//------------------------------------------------------
{
    // usesFactoryDefaults == YES で標準設定を返す。NO なら現在の設定を返す。

    NSMutableArray *textKeySpecCharArray = [NSMutableArray array];

    for (id selector in [self textKeyBindingSelectorStrArray]) {
        if (([selector length] == 0) || ![selector isKindOfClass:[NSString class]]) { continue; }
        
        NSArray *keys;
        if (usesFactoryDefaults) {
            NSURL *sourceURL = [[NSBundle mainBundle] URLForResource:@"DefaultTextKeyBindings" withExtension:@"plist"];
            NSDictionary *defaultDict = [NSDictionary dictionaryWithContentsOfURL:sourceURL];
            keys = [defaultDict allKeysForObject:selector];
        } else {
            keys = [[self textKeyBindingDict] allKeysForObject:selector];
        }
        NSString *key = ([keys count] > 0) ? keys[0] : @"";
        
        [textKeySpecCharArray addObject:[@{k_title: selector, //*****
                                           k_keyBindingKey: key,
                                           k_selectorString: selector} mutableCopy]];
    }
    return textKeySpecCharArray;
}


//------------------------------------------------------
/// キーバインディング定義文字列から表示用文字列を生成し、返す
- (NSString *)readableKeyStringsFromKeySpecChars:(NSString *)string
//------------------------------------------------------
{
    NSInteger length = [string length];
    
    if (length < 2) { return @""; }
    
    NSString *keyEquivalent = [string substringFromIndex:(length - 1)];
    NSString *keyStr = [self readableKeyStringsFromKeyEquivalent:keyEquivalent];
    BOOL drawsShift = (isupper([keyEquivalent characterAtIndex:0]) == 1);
    NSString *modKeyStr = [self readableKeyStringsFromModKeySpecChars:[string substringToIndex:(length - 1)]
                                                         withShiftKey:drawsShift];

    return [NSString stringWithFormat:@"%@%@", modKeyStr, keyStr];
}


//------------------------------------------------------
/// メニューのキーボードショートカットから表示用文字列を返す
- (NSString *)readableKeyStringsFromKeyEquivalent:(NSString *)string
//------------------------------------------------------
{
    if ([string length] < 1) { return @""; }

    unichar theChar = [string characterAtIndex:0];
    if ([[NSCharacterSet alphanumericCharacterSet] characterIsMember:theChar]) {
        return [string uppercaseString];
    } else {
        return [self visibleCharFromIgnoringModChar:string];
    }
}


//------------------------------------------------------
/// メニューのキーボードショートカットからキーバインディング定義文字列を返す
- (NSString *)keySpecCharsFromKeyEquivalent:(NSString *)string modifierFrags:(NSUInteger)modifierFlags
//------------------------------------------------------
{
    if ([string length] < 1) { return @""; }

    NSMutableString *keySpecChars = [NSMutableString string];
    unichar theChar = [string characterAtIndex:0];
    BOOL isShiftPressed = NO;

    if (k_size_of_modifierKeysList != k_size_of_keySpecCharList) {
        NSLog(@"internal data error! 'k_modifierKeysList' and 'k_keySpecCharList' size is different.");
        return @"";
    }

    for (NSInteger i = 0; i < k_size_of_modifierKeysList; i++) {
        if ((modifierFlags & k_modifierKeysList[i]) || ((i == 2) && (isupper(theChar) == 1))) {
            // （メニューから定義値を取得した時、アルファベット+シフトの場合にシフトの定義が欠落するための回避処置）
            [keySpecChars appendFormat:@"%C", k_keySpecCharList[i]];
            if ((i == 2) && (isupper(theChar) == 1)) {
                isShiftPressed = YES;
            }
        }
    }
    [keySpecChars appendString:((isShiftPressed) ? [string uppercaseString] : string)];

    return keySpecChars;
}


//------------------------------------------------------
/// キーバインディング定義文字列から表示用モディファイアキー文字列を生成し、返す
- (NSString *)readableKeyStringsFromModKeySpecChars:(NSString *)modString withShiftKey:(BOOL)isShiftPressed
//------------------------------------------------------
{
    if (k_size_of_keySpecCharList != k_size_of_readableKeyStringsList) {
        NSLog(@"internal data error! 'k_keySpecCharList' and 'k_readableKeyStringsList' size is different.");
        return @"";
    }
    
    NSCharacterSet *modStringSet = [NSCharacterSet characterSetWithCharactersInString:modString];
    NSMutableString *keyStrings = [NSMutableString string];

    for (NSUInteger i = 0; i < k_size_of_keySpecCharList; i++) {
        unichar theChar = k_keySpecCharList[i];
        if ([modStringSet characterIsMember:theChar]) {
            [keyStrings appendFormat:@"%C", k_readableKeyStringsList[i]];
        }
    }
    return keyStrings;
}


//------------------------------------------------------
/// キーバインディング定義文字列またはキーボードショートカットキーからキー表示用文字列を生成し、返す
- (NSString *)visibleCharFromIgnoringModChar:(NSString *)igunoresModChar
//------------------------------------------------------
{
    return [self unprintableKeyDict][igunoresModChar] ? : igunoresModChar;
}


//------------------------------------------------------
/// 新しいキーバインディングキーの押下をアウトラインビューに取り込む
- (void)addCatchedMenuShortcutString:(NSNotification *)notification
//------------------------------------------------------
{
    NSWindow *sheet;
    NSOutlineView *outlineView;
    
    switch ([self outlineMode]) {
        case CEMenuModeOutline:
            sheet = [self menuEditSheet];
            outlineView = [self menuOutlineView];
            break;
        case CETextModeOutline:
            sheet = [self textEditSheet];
            outlineView = [self textOutlineView];
            break;
        default:
            return;
    }
    if (sheet && outlineView) {
        NSDictionary *userInfo = [notification userInfo];
        NSUInteger modifierFlags = [[userInfo valueForKey:k_keyBindingModFlags] unsignedIntegerValue];
        NSText *fieldEditor = [sheet fieldEditor:NO forObject:outlineView];
        NSString *charIgnoringMod = [userInfo valueForKey:k_keyBindingChar];
        NSString *fieldString = [self keySpecCharsFromKeyEquivalent:charIgnoringMod modifierFrags:modifierFlags];

        [fieldEditor setString:fieldString];
        [sheet endEditingFor:fieldEditor];
        [sheet makeFirstResponder:outlineView];
    }
}


//------------------------------------------------------
/// 重複などの警告メッセージを表示
- (BOOL)showDuplicateKeySpecCharsMessageWithKeySpecChars:(NSString *)keySpec oldChars:(NSString *)oldSpec
//------------------------------------------------------
{
    BOOL showsMessage = NO;

    if (![self duplicateKeyCheckArray] || !keySpec) { return showsMessage; }

    NSString *readableKeyStr;

    // 他のキーバインディングと重複している時
    if (([keySpec length] > 0) && ![keySpec isEqualToString:oldSpec] &&
        [[self duplicateKeyCheckArray] containsObject:keySpec])
    {
        // メッセージ表示
        readableKeyStr = [self readableKeyStringsFromKeySpecChars:keySpec];
        NSString *message = [NSString stringWithFormat:NSLocalizedString(@"“%@” has already been used. Edit it again.", nil),
                             readableKeyStr];
        switch ([self outlineMode]) {
            case CEMenuModeOutline:
                [[self menuDuplicateTextField] setStringValue:message];
                [[self menuOkButton] setEnabled:NO];
                break;
                
            case CETextModeOutline:
                [[self textDuplicateTextField] setStringValue:message];
                [[self textOkButton] setEnabled:NO];
                break;
        }
        NSBeep();
        showsMessage = NO;

    } else {
        NSRange cmdRange = [keySpec rangeOfString:@"@"];
        BOOL accepts = NO;

        // コマンドキーの存在チェック
        if ([keySpec isEqualToString:@""]) { // 空文字（入力なし = 削除された）の場合はスルー
            accepts = YES;
        } else {
            switch ([self outlineMode]) {
                case CEMenuModeOutline:
                    accepts = ((cmdRange.location != NSNotFound) && (cmdRange.location != ([keySpec length] - 1)));
                    break;
                    
                case CETextModeOutline:
                    accepts = ((cmdRange.location == NSNotFound) || (cmdRange.location == ([keySpec length] - 1)));
                    break;
            }
        }

        // モードとコマンドキーの有無が合致しなければメッセージ表示
        if (!accepts) {
            readableKeyStr = [self readableKeyStringsFromKeySpecChars:keySpec];
            switch ([self outlineMode]) {
                case CEMenuModeOutline:
                    [[self menuDuplicateTextField] setStringValue:[NSString stringWithFormat:
                                                             NSLocalizedString(@"“%@” does NOT include Command key. Edit it again.", nil), readableKeyStr]];
                    [[self menuOkButton] setEnabled:NO];
                    break;
                    
                case CETextModeOutline:
                    [[self textDuplicateTextField] setStringValue:[NSString stringWithFormat:
                                                             NSLocalizedString(@"“%@” includes Command key. Edit it again.", nil), readableKeyStr]];
                    [[self textOkButton] setEnabled:NO];
                    break;
            }
            
            NSBeep();
            showsMessage = NO;

        } else {
            // メッセージ消去
            switch ([self outlineMode]) {
                case CEMenuModeOutline:
                    [[self menuDuplicateTextField] setStringValue:@""];
                    [[self menuOkButton] setEnabled:YES];
                    break;
                    
                case CETextModeOutline:
                    [[self textDuplicateTextField] setStringValue:@""];
                    [[self textOkButton] setEnabled:YES];
                    break;
            }
            showsMessage = YES;
            // 重複チェック配列更新
            if (([oldSpec length] > 0) && ![keySpec isEqualToString:oldSpec]) {
                [[self duplicateKeyCheckArray] removeObject:oldSpec];
            }
            // 重複チェック配列更新
            if (([keySpec length] > 0) && ![keySpec isEqualToString:oldSpec]) {
                [[self duplicateKeyCheckArray] addObject:keySpec];
            }
        }
    }
    return showsMessage;
}


//------------------------------------------------------
/// 重複チェック配列を生成
- (NSMutableArray *)duplicateKeyCheckArrayWithMenu:(NSMenu *)menu
//------------------------------------------------------
{
    NSMutableArray *duplicateKeyCheckArray = [NSMutableArray array];

    for (NSMenuItem *item in [menu itemArray]) {
        if ([item hasSubmenu]) {
            NSArray *theTmpArray = [self duplicateKeyCheckArrayWithMenu:[item submenu]];
            [duplicateKeyCheckArray addObjectsFromArray:theTmpArray];
            continue;
        }
        NSString *keyEquivalent = [item keyEquivalent];
        if ([keyEquivalent length] > 0) {
            NSUInteger modifierFlags = [item keyEquivalentModifierMask];
            NSString *keySpecChars = [self keySpecCharsFromKeyEquivalent:keyEquivalent modifierFrags:modifierFlags];
            if ([keySpecChars length] > 1) {
                [duplicateKeyCheckArray addObject:keySpecChars];
            }
        }
    }
    return duplicateKeyCheckArray;
}


//------------------------------------------------------
/// 重複チェック配列を生成
- (NSArray *)duplicateKeyCheckArrayWithArray:(NSArray *)array
//------------------------------------------------------
{
    if (!array) { return nil; }

    NSMutableArray *duplicateKeyCheckArray = [NSMutableArray array];

    for (id item in array) {
        NSArray *children = item[k_children];
        if (children != nil) {
            NSArray *childrenArray = [self duplicateKeyCheckArrayWithArray:children];
            [duplicateKeyCheckArray addObjectsFromArray:childrenArray];
        }
        NSString *keySpecChars = [item valueForKey:k_keyBindingKey];
        if ([keySpecChars length] > 0) {
            if (![duplicateKeyCheckArray containsObject:keySpecChars]) {
                [duplicateKeyCheckArray addObject:keySpecChars];
            }
        }
    }
    return duplicateKeyCheckArray;
}


//------------------------------------------------------
/// アウトラインビューデータから保存用辞書を生成
- (NSMutableDictionary *)keyBindingDictionaryFromOutlineViewDataArray:(NSArray *)array
//------------------------------------------------------
{
    NSMutableDictionary *keyBindingDict = [NSMutableDictionary dictionary];

    for (id item in array) {
        NSArray *children = item[k_children];
        if (children) {
            NSDictionary *childDict = [self keyBindingDictionaryFromOutlineViewDataArray:children];
            [keyBindingDict addEntriesFromDictionary:childDict];
        }
        NSString *keySpecChars = [item valueForKey:k_keyBindingKey];
        NSString *selectorStr = [item valueForKey:k_selectorString];
        if (([keySpecChars length] > 0) && ([selectorStr length] > 0)) {
            [keyBindingDict setValue:selectorStr forKey:keySpecChars];
        }
    }
    return keyBindingDict;
}


//------------------------------------------------------
/// アウトラインビューデータ保存
- (void)saveOutlineViewData
//------------------------------------------------------
{
    NSDictionary *dictToSave = [self keyBindingDictionaryFromOutlineViewDataArray:[self outlineDataArray]];
    NSURL *fileURL;
    BOOL success = NO;

    switch ([self outlineMode]) {
        case CEMenuModeOutline:
        {
            fileURL = [self menuKeyBindingSettingFileURL];
            
            // デフォルトと同じ場合は現在のユーザ設定ファイルを削除する
            if ([dictToSave isEqualToDictionary:[self defaultMenuKeyBindingDict]]) {
                [[NSFileManager defaultManager] removeItemAtURL:fileURL error:nil];
                success = YES;
                
            } else {
                if ([self prepareUserSettingDicrectory]) {
                    success = [dictToSave writeToURL:fileURL atomically:YES];
                }
            }
            
            // メニューに反映させる
            if (success) {
                [self setMenuKeyBindingDict:dictToSave];
            } else {
                NSLog(@"Error on saving the menu keybindings setting file.");
            }
            [self resetAllMenuKeyBindingWithDictionary];
        }
        break;
        
        case CETextModeOutline:
        {
            fileURL = [self textKeyBindingSettingFileURL];
            
            if ([self prepareUserSettingDicrectory]) {
                [self setTextKeyBindingDict:dictToSave];
                
                if (![dictToSave writeToURL:fileURL atomically:YES]) {
                    NSLog(@"Error! Could not save the Text keyBindings setting file...");
                    return;
                }
            }
            
            NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
            NSArray *contents = [[[self textInsertStringArrayController] content] copy];
            if (![contents isEqualToArray:[defaults arrayForKey:k_key_insertCustomTextArray]]) {
                NSMutableArray *defaultsArray = [NSMutableArray array];
                NSString *insertText;
                
                for (NSDictionary *dict in contents) {
                    insertText = dict[k_key_insertCustomText] ? : @"";
                    [defaultsArray addObject:insertText];
                }
                [defaults setObject:defaultsArray forKey:k_key_insertCustomTextArray];
                [[self textInsertStringArrayController] setContent:nil];
            }
        }
        break;
    }
}


//------------------------------------------------------
/// セレクタ名を定義しているキーバインディング文字列（キー）を得る
- (NSString *)keySpecCharsInDictionaryFromSelectorString:(NSString *)selectorString
//------------------------------------------------------
{
    NSArray *keys = [[self menuKeyBindingDict] allKeysForObject:selectorString];
    
    if ([keys count] > 0) {
        return (NSString *)keys[0];
    }
    return @"";
}


//------------------------------------------------------
/// デフォルト設定の、セレクタ名を定義しているキーバインディング文字列（キー）を得る
- (NSString *)keySpecCharsInDefaultDictionaryFromSelectorString:(NSString *)selectorString
//------------------------------------------------------
{
    NSArray *keys = [[self defaultMenuKeyBindingDict] allKeysForObject:selectorString];

    if ([keys count] > 0) {
        return (NSString *)keys[0];
    }
    return @"";
}


//------------------------------------------------------
/// 配列中のキーバインディング設定文字列をデフォルトに戻す
- (void)resetKeySpecCharsToFactoryDefaultsOfOutlineDataArray:(NSMutableArray *)dataArray
//------------------------------------------------------
{
    for (id item in dataArray) {
        NSMutableArray *children = item[k_children];
        if (children) {
            [self resetKeySpecCharsToFactoryDefaultsOfOutlineDataArray:children];
        }
        NSString *selectorStr = [item valueForKey:k_selectorString];
        NSString *keySpecChars = [self keySpecCharsInDefaultDictionaryFromSelectorString:selectorStr];
        [item setValue:keySpecChars forKey:k_keyBindingKey];
    }
}


//------------------------------------------------------
/// キーを重複入力された時に再び選択状態にする
- (void)performEditOutlineViewSelectedKeyBindingKeyColumn
//------------------------------------------------------
{
    NSOutlineView *outlineView = nil;

    switch ([self outlineMode]) {
        case CEMenuModeOutline:
            outlineView = [self menuOutlineView];
            break;
        
        case CETextModeOutline:
            outlineView = [self textOutlineView];
            break;
        
        default:
            return;
    }

    NSInteger selectedRow = [outlineView selectedRow];

    if (selectedRow != -1) {
        id item = [outlineView itemAtRow:selectedRow];
        NSTableColumn *column = [outlineView tableColumnWithIdentifier:k_keyBindingKey];

        if ([self outlineView:outlineView shouldEditTableColumn:column item:item]) {
            switch ([self outlineMode]) {
                case CEMenuModeOutline:
                    [[self menuDeleteKeyButton] setEnabled:YES];
                    break;
                
                case CETextModeOutline:
                    [[self textDeleteKeyButton] setEnabled:YES];
                    break;
            }
            [outlineView editColumn:[outlineView columnWithIdentifier:k_keyBindingKey]
                                row:selectedRow withEvent:nil select:YES];
        }
    }
}


//------------------------------------------------------
/// そのまま表示できないキーバインディング定義文字列の変換辞書を返す
- (NSDictionary *)unprintableKeyDictionary
//------------------------------------------------------
{
// 下記の情報を参考にさせていただきました (2005.09.05)
// http://www.cocoabuilder.com/archive/message/2004/3/19/102023
    NSArray *visibleChars = @[[NSString stringWithFormat:@"%C", (unichar)0x2191], // "↑" NSUpArrowFunctionKey,
                              [NSString stringWithFormat:@"%C", (unichar)0x2193], // "↓" NSDownArrowFunctionKey,
                              [NSString stringWithFormat:@"%C", (unichar)0x2190], // "←" NSLeftArrowFunctionKey,
                              [NSString stringWithFormat:@"%C", (unichar)0x2192], // "→" NSRightArrowFunctionKey, 
                              @"F1", // NSF1FunctionKey, 
                              @"F2", // NSF2FunctionKey, 
                              @"F3", // NSF3FunctionKey, 
                              @"F4", // NSF4FunctionKey,
                              @"F5", // NSF5FunctionKey, 
                              @"F6", // NSF6FunctionKey, 
                              @"F7", // NSF7FunctionKey, 
                              @"F8", // NSF8FunctionKey, 
                              @"F9", // NSF9FunctionKey, 
                              @"F10", // NSF10FunctionKey, 
                              @"F11", // NSF11FunctionKey, 
                              @"F12", // NSF12FunctionKey, 
                              @"F13", // NSF13FunctionKey, 
                              @"F14", // NSF14FunctionKey, 
                              @"F15", // NSF15FunctionKey, 
                              @"F16", // NSF16FunctionKey, 
                              [NSString stringWithFormat:@"%C", (unichar)0x2326], // NSDeleteCharacter = "Delete forward"
                              [NSString stringWithFormat:@"%C", (unichar)0x2196], // "↖" NSHomeFunctionKey, 
                              [NSString stringWithFormat:@"%C", (unichar)0x2198], // "↘" NSEndFunctionKey, 
                              [NSString stringWithFormat:@"%C", (unichar)0x21DE], // "⇞" NSPageUpFunctionKey, 
                              [NSString stringWithFormat:@"%C", (unichar)0x21DF], // "⇟" NSPageDownFunctionKey, 
                              [NSString stringWithFormat:@"%C", (unichar)0x2327], // "⌧" NSClearLineFunctionKey, 
                              @"Help", // NSHelpFunctionKey, 
                              @"Space", // "Space", 
                              [NSString stringWithFormat:@"%C", (unichar)0x21E5], // "Tab"
                              [NSString stringWithFormat:@"%C", (unichar)0x21A9], // "Return"
                              [NSString stringWithFormat:@"%C", (unichar)0x232B], // "⌫" "Backspace"
                              [NSString stringWithFormat:@"%C", (unichar)0x2305], // "Enter"
                              [NSString stringWithFormat:@"%C", (unichar)0x21E4], // "Backtab"
                              [NSString stringWithFormat:@"%C", (unichar)0x238B]];

    if (k_size_of_noPrintableKeyList != [visibleChars count]) {
        NSLog(@"internal data error! 'k_noPrintableKeyList' and 'visibleChars' size is different.");
        return nil;
    }
    NSMutableArray *keys = [[NSMutableArray alloc] initWithCapacity:k_size_of_noPrintableKeyList];

    for (NSInteger i = 0; i < k_size_of_noPrintableKeyList; i++) {
        [keys addObject:[NSString stringWithFormat:@"%C", k_noPrintableKeyList[i]]];
    }

    return [NSDictionary dictionaryWithObjects:visibleChars forKeys:keys];
}


//------------------------------------------------------
/// 独自定義のセレクタ名配列を返す
- (NSArray *)textKeyBindingSelectorStrArray
//------------------------------------------------------
{
    return @[@"insertCustomText_00:",
             @"insertCustomText_01:",
             @"insertCustomText_02:",
             @"insertCustomText_03:",
             @"insertCustomText_04:",
             @"insertCustomText_05:",
             @"insertCustomText_06:",
             @"insertCustomText_07:",
             @"insertCustomText_08:",
             @"insertCustomText_09:",
             @"insertCustomText_10:",
             @"insertCustomText_11:",
             @"insertCustomText_12:",
             @"insertCustomText_13:",
             @"insertCustomText_14:",
             @"insertCustomText_15:",
             @"insertCustomText_16:",
             @"insertCustomText_17:",
             @"insertCustomText_18:",
             @"insertCustomText_19:",
             @"insertCustomText_20:",
             @"insertCustomText_21:",
             @"insertCustomText_22:",
             @"insertCustomText_23:",
             @"insertCustomText_24:",
             @"insertCustomText_25:",
             @"insertCustomText_26:",
             @"insertCustomText_27:",
             @"insertCustomText_28:",
             @"insertCustomText_29:",
             @"insertCustomText_30:"];
}


//------------------------------------------------------
/// 変更しない項目のセレクタ名配列を返す
- (NSArray *)selectorStringsToIgnore
//------------------------------------------------------
{
    return @[@"modifyFont:",
             @"changeEncoding:",
             @"changeSyntaxStyle:",
             @"makeKeyAndOrderFront:",
             @"launchScript:",
             @"_openRecentDocument:",  // = 10.3 の「最近開いた書類」
             @"orderFrontCharacterPalette:"  // = 10.4「特殊文字…」
             ];
}

@end
