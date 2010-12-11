/*
=================================================
CEKeyBindingManager
(for CotEditor)

Copyright (C) 2004-2006 nakamuxu.
http://www.aynimac.com/
=================================================

encoding="UTF-8"
Created:2005.09.01

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

#import "CEKeyBindingManager.h"

//=======================================================
// Private method
//
//=======================================================

@interface CEKeyBindingManager (Private)
- (NSString *)pathOfMenuKeyBindingSettingFile;
- (NSString *)pathOfTextKeyBindingSettingFile;
- (void)setupMenuKeyBindingDictionary;
- (void)setupTextKeyBindingDictionary;
- (void)clearAllMenuKeyBindingOf:(NSMenu *)inMenu;
- (void)updateMenuValidation:(NSMenu *)inMenu;
- (void)resetAllMenuKeyBindingWithDictionary;
- (void)resetKeyBindingWithDictionaryTo:(NSMenu *)inMenu;
- (NSMutableArray *)mainMenuArrayForOutlineData:(NSMenu *)inMenu;
- (NSMutableArray *)textKeySpecCharArrayForOutlineDataWithFactoryDefaults:(BOOL)inBool;
- (NSString *)readableKeyStringsFromKeySpecChars:(NSString *)inString;
- (NSString *)readableKeyStringsFromKeyEquivalent:(NSString *)inString;
- (NSString *)keySpecCharsFromKeyEquivalent:(NSString *)inString modifierFrags:(unsigned int)inModFlags;
- (NSString *)readableKeyStringsFromModKeySpecChars:(NSString *)inModString withShiftKey:(BOOL)inBool;
- (NSString *)visibleCharFromIgnoringModChar:(NSString *)inIgModChar;
- (BOOL)showDuplicateKeySpecCharsMessageWithKeySpecChars:(NSString *)inKeySpec oldChars:(NSString *)inOldSpec;
- (NSMutableArray *)duplicateKeyCheckArrayWithMenu:(NSMenu *)inMenu;
- (NSArray *)duplicateKeyCheckArrayWithArray:(NSArray *)inArray;
- (NSMutableDictionary *)keyBindingDictionaryFromOutlineViewDataArray:(NSArray *)inArray;
- (void)saveOutlineViewData;
- (NSString *)keySpecCharsInDictionaryFromSelectorString:(NSString *)inSelectorStr;
- (void)performEditOutlineViewSelectedKeyBindingKeyColumn;
- (void)resetKeySpecCharsToFactoryDefaultsOfOutlineDataArray:(NSMutableArray *)inArray;
- (NSDictionary *)noPrintableKeyDictionary;
- (NSArray *)textKeyBindingSelectorStrArray;
@end


//------------------------------------------------------------------------------------------




@implementation CEKeyBindingManager

static CEKeyBindingManager *sharedInstance = nil;

#pragma mark ===== Class method =====

//=======================================================
// Class method
//
//=======================================================

// ------------------------------------------------------
+ (CEKeyBindingManager *)sharedInstance
// 共有インスタンスを返す
// ------------------------------------------------------
{
    return sharedInstance ? sharedInstance : [[self alloc] init];
}



#pragma mark ===== Public method =====

//=======================================================
// Public method
//
//=======================================================

// ------------------------------------------------------
- (id)init
// 初期化
// ------------------------------------------------------
{
    if (sharedInstance == nil) {
        self = [super init];
        (void)[NSBundle loadNibNamed:@"KeyBindingManager" owner:self];
        _outlineDataArray = nil;
        _duplicateKeyCheckArray = nil;
        _defaultMenuKeyBindingDict = nil;
        _menuKeyBindingDict = nil;
        _textKeyBindingDict = nil;
        _noPrintableKeyDict = [[self noPrintableKeyDictionary] retain]; // ===== retain
        [[NSNotificationCenter defaultCenter] addObserver:self 
                selector:@selector(addCatchedMenuShortcutString:) 
                name:k_catchMenuShortcutNotification object:NSApp];
        _currentKeySpecChars = nil;
        _outlineMode = nil;
        sharedInstance = self;
    }
    return sharedInstance;
}


// ------------------------------------------------------
- (void)dealloc
// あとかたづけ
// ------------------------------------------------------
{
    // ノーティフィケーションセンタから自身を排除
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    // NSBundle loadNibNamed: でロードされたオブジェクトを開放
    // 参考にさせていただきました > http://homepage.mac.com/mkino2/backnumber/2004_10.html#October%2012_1
    [_menuEditSheet release]; // （コンテントビューは自動解放される）
    [_textEditSheet release]; // （コンテントビューは自動解放される）

    [_outlineDataArray release];
    [_duplicateKeyCheckArray release];
    [_defaultMenuKeyBindingDict release];
    [_menuKeyBindingDict release];
    [_textKeyBindingDict release];
    [_noPrintableKeyDict release];
    [_currentKeySpecChars release];

    [super dealloc];
}


// ------------------------------------------------------
- (void)setupAtLaunching
// 起動時の準備
// ------------------------------------------------------
{
    NSString *theSource = [[[NSBundle mainBundle] bundlePath] 
            stringByAppendingPathComponent:@"/Contents/Resources/DefaultMenuKeyBindings.plist"];

    if ([[NSFileManager defaultManager] fileExistsAtPath:theSource]) {
        _defaultMenuKeyBindingDict = 
            [[NSDictionary allocWithZone:[self zone]] initWithContentsOfFile:theSource]; // ===== alloc
    }

    // ダブルクリックでトグルに展開するようアクションを設定する
    [_menuOutlineView setDoubleAction:@selector(doubleClickedOutlineViewRow:)];
    [_menuOutlineView setTarget:self];
    [self setupKeyBindingDictionary];
    [self resetAllMenuKeyBindingWithDictionary];
}


// ------------------------------------------------------
- (NSWindow *)editSheetWindowOfMode:(int)inMode
// キーバインディング編集シート用ウィンドウを返す
// ------------------------------------------------------
{
    if (inMode == k_outlineViewModeMenu) { // === Menu
        return _menuEditSheet;
    } else if (inMode == k_outlineViewModeText) { // === Text
        return _textEditSheet;
    }
    return nil;
}


// ------------------------------------------------------
- (void)setupKeyBindingDictionary
// 定義ファイルのセットアップと読み込み
// ------------------------------------------------------
{
    [self setupMenuKeyBindingDictionary];
    [self setupTextKeyBindingDictionary];
}


// ------------------------------------------------------
- (BOOL)setupOutlineDataOfMode:(int)inMode
// 環境設定でシートを表示する準備
// ------------------------------------------------------
{
    if ((inMode != k_outlineViewModeMenu) && (inMode != k_outlineViewModeText)) { return NO; }

    if (_outlineDataArray) {
        [_outlineDataArray release];
    }
    if (_duplicateKeyCheckArray) {
        [_duplicateKeyCheckArray release];
    }
    // モードの保持、データの準備、タイトルとメッセージの差し替え
    _outlineMode = inMode;
    if (_outlineMode == k_outlineViewModeMenu) { // === Menu
        [_menuDuplicateTextField setStringValue:@""];
        _outlineDataArray = [[self mainMenuArrayForOutlineData:[NSApp mainMenu]] retain]; // ===== retain
        _duplicateKeyCheckArray = 
                [[self duplicateKeyCheckArrayWithMenu:[NSApp mainMenu]] retain]; // ===== retain
        [_menuFactoryDefaultsButton setEnabled:
                (![_menuKeyBindingDict isEqualToDictionary:_defaultMenuKeyBindingDict])];
        [_menuOutlineView reloadData];
        [_menuEditKeyButton setEnabled:NO];

    } else if (_outlineMode == k_outlineViewModeText) { // === Text
        id theValues = [[NSUserDefaultsController sharedUserDefaultsController] values];
        NSArray *theInsertTextArray = [theValues valueForKey:k_key_insertCustomTextArray];
        NSMutableArray *theContentArray = [NSMutableArray array];
        NSMutableDictionary *theDict;
        int i, theMax = [theInsertTextArray count];

        [_textDuplicateTextField setStringValue:@""];
        _outlineDataArray = 
                [[self textKeySpecCharArrayForOutlineDataWithFactoryDefaults:NO] retain]; // ===== retain
        // （システム標準のキーバインディングとの重複は、チェックしない）
        _duplicateKeyCheckArray = [_outlineDataArray mutableCopy]; // ===== copy
        [_textFactoryDefaultsButton setEnabled:
                ((![_outlineDataArray isEqualToArray:_duplicateKeyCheckArray]) || 
                (![[[[NSApp delegate] class] factoryDefaultOfTextInsertStringArray] 
                    isEqualToArray:theInsertTextArray]))];
        [_textOutlineView reloadData];
        for (i = 0; i < theMax; i++) {
            theDict = [NSMutableDictionary dictionaryWithObject:[theInsertTextArray objectAtIndex:i] 
                        forKey:k_key_insertCustomText];
            [theContentArray addObject:theDict];
        }
        [_textInsertStringArrayController setContent:theContentArray];
        [_textInsertStringArrayController setSelectionIndex:NSNotFound]; // 選択なし
        [_textInsertStringTextView setEditable:NO];
        [_textInsertStringTextView setBackgroundColor:[NSColor controlHighlightColor]];
        [_textEditKeyButton setEnabled:NO];
    }

    return YES;
}


// ------------------------------------------------------
- (NSString *)selectorStringWithKeyEquivalent:(NSString *)inString modifierFrags:(unsigned int)inModFlags
// キー入力に応じたセレクタ文字列を返す
// ------------------------------------------------------
{
    NSString *theKeySpecChars = [self keySpecCharsFromKeyEquivalent:inString modifierFrags:inModFlags];

    return [_textKeyBindingDict objectForKey:theKeySpecChars];
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
    // アプリケーションメニューにタイトルを設定（Nibで設定できないため）
    NSString *theAppName = [[NSBundle mainBundle] objectForInfoDictionaryKey:@"CFBundleExecutable"];
    if ((theAppName != nil) && ([theAppName length] > 0)) {
        [[[NSApp mainMenu] itemAtIndex:k_applicationMenuIndex] setTitle:theAppName];
    }
}



//=======================================================
// NSOutlineViewDataSource Protocol(Category)
//
//=======================================================

// ------------------------------------------------------
- (int)outlineView:(NSOutlineView *)inOutlineView numberOfChildrenOfItem:(id)inItem
// 子アイテムの数を返す
// ------------------------------------------------------
{
    if (inItem == nil) {
        return [_outlineDataArray count];
    } else {
        id theItem = [inItem valueForKey:k_children];
        return (theItem != nil) ? [theItem count] : 0;
    }
}


// ------------------------------------------------------
- (BOOL)outlineView:(NSOutlineView *)inOutlineView isItemExpandable:(id)inItem
// アイテムが展開可能かどうかを返す
// ------------------------------------------------------
{
    if (inItem == nil) {
        return YES;
    } else {
        return ([inItem valueForKey:k_children] != nil);
    }
}


// ------------------------------------------------------
- (id)outlineView:(NSOutlineView *)inOutlineView child:(int)inIndex ofItem:(id)inItem
// 子アイテムオブジェクトを返す
// ------------------------------------------------------
{
    if (inItem == nil) {
        return [_outlineDataArray objectAtIndex:inIndex];
    } else {
        return [[inItem valueForKey:k_children] objectAtIndex:inIndex];
    }
}


// ------------------------------------------------------
- (id)outlineView:(NSOutlineView *)inOutlineView 
        objectValueForTableColumn:(NSTableColumn *)inTableColumn byItem:(id)inItem
// コラムに応じたオブジェクト(表示文字列)を返す
// ------------------------------------------------------
{
    id theItem = (inItem == nil) ? _outlineDataArray : inItem;
    id theID = [inTableColumn identifier];

    if ([theID isEqualToString:k_keyBindingKey]) {
        return [self readableKeyStringsFromKeySpecChars:[theItem valueForKey:theID]];
    }
    return [theItem valueForKey:theID];
}


// ------------------------------------------------------
- (BOOL)outlineView:(NSOutlineView *)inOutlineView 
        shouldEditTableColumn:(NSTableColumn *)inTableColumn item:(id)inItem
// コラム編集直前、キー入力を取得するようにしてから許可を出す
// ------------------------------------------------------
{
    id theID = [inTableColumn identifier];
    if (([theID isEqualToString:k_keyBindingKey]) && ([inItem valueForKey:k_children] == nil)) {

        id theItem = (inItem == nil) ? _outlineDataArray : inItem;

        if (_currentKeySpecChars == nil) {
            // （値が既にセットされている時は更新しない）
            _currentKeySpecChars = [[theItem valueForKey:theID] retain]; // ===== retain
        }
        [[NSNotificationCenter defaultCenter] postNotificationName:k_setKeyCatchModeToCatchMenuShortcut 
                object:self 
                userInfo:[NSDictionary dictionaryWithObjectsAndKeys:
                    [NSNumber numberWithInt:k_catchMenuShortcut], k_keyCatchMode, 
                    nil]
                ];
        if (_outlineMode == k_outlineViewModeMenu) {
            [_menuDeleteKeyButton setEnabled:YES];
        } else if (_outlineMode == k_outlineViewModeText) {
            [_textDeleteKeyButton setEnabled:YES];
        }
        return YES;
    }
    return NO;
}


// ------------------------------------------------------
- (void)outlineView:(NSOutlineView *)inOutlineView 
        setObjectValue:(id)inObject forTableColumn:(NSTableColumn *)inTableColumn byItem:(id)inItem
// データをセット
// ------------------------------------------------------
{
    id theID = [inTableColumn identifier];
    BOOL theBoolReleaseOldChars = YES;

    // 現在の表示値との比較
    if ([inObject isEqualToString:
            [self outlineView:inOutlineView objectValueForTableColumn:inTableColumn byItem:inItem]]) {
        // データソースの値でなく表示値がそのまま入ってきているのは、選択状態になったあと何の編集もされなかった時
        if (([[NSApp currentEvent] type] == NSLeftMouseDown) && 
                (_outlineMode == k_outlineViewModeMenu) && 
                ([[_menuDuplicateTextField stringValue] length] > 0)) {
            [inItem setObject:@"" forKey:theID];
            [_menuDuplicateTextField setStringValue:@""];
            (void)[self showDuplicateKeySpecCharsMessageWithKeySpecChars:@"" oldChars:_currentKeySpecChars];
        } else if (([[NSApp currentEvent] type] == NSLeftMouseDown) && 
                (_outlineMode == k_outlineViewModeText) && 
                ([[_textDuplicateTextField stringValue] length] > 0)) {
            [inItem setObject:@"" forKey:theID];
            [_textDuplicateTextField setStringValue:@""];
            (void)[self showDuplicateKeySpecCharsMessageWithKeySpecChars:@"" oldChars:_currentKeySpecChars];
        }
    } else {
        // 現在の表示値と違っていたら、セット
        [inItem setObject:inObject forKey:theID];
        // 他の値とダブっていたら、再び編集状態にする
        if (![self showDuplicateKeySpecCharsMessageWithKeySpecChars:inObject oldChars:_currentKeySpecChars]) {
            [self performSelector:@selector(performEditOutlineViewSelectedKeyBindingKeyColumn) 
                    withObject:nil afterDelay:0 
                    inModes:[NSArray arrayWithObject:NSModalPanelRunLoopMode]];
            theBoolReleaseOldChars = NO;
        }
    }
    if (_outlineMode == k_outlineViewModeMenu) {
        [_menuDeleteKeyButton setEnabled:NO];
    } else if (_outlineMode == k_outlineViewModeText) {
        [_textDeleteKeyButton setEnabled:NO];
    }
    if (theBoolReleaseOldChars) {
        [_currentKeySpecChars release];
        _currentKeySpecChars = nil;
    }
}



#pragma mark === Delegate and Notification ===

//=======================================================
// Delegate method (NSOutlineView)
//  <== _menuOutlineView, _textOutlineView
//=======================================================

// ------------------------------------------------------
- (BOOL)outlineView:(NSOutlineView *)inOutlineView shouldSelectItem:(id)inItem
// 選択行の変更を許可
// ------------------------------------------------------
{
    id theEditButton = nil;

    if (_outlineMode == k_outlineViewModeMenu) {
        theEditButton = _menuEditKeyButton;
    } else if (_outlineMode == k_outlineViewModeText) {
        theEditButton = _textEditKeyButton;
    }
    if (theEditButton == nil) { return NO; }

    // キー取得を停止
    [[NSNotificationCenter defaultCenter] postNotificationName:k_setKeyCatchModeToCatchMenuShortcut 
            object:self 
            userInfo:[NSDictionary dictionaryWithObjectsAndKeys:
                [NSNumber numberWithInt:k_keyDownNoCatch], k_keyCatchMode, 
                nil]
            ];
    // テキストのバインディングを編集している時は挿入文字列配列コントローラの選択オブジェクトを変更
    if (_outlineMode == k_outlineViewModeText) {
        BOOL theBoolIsEnabled = [[inItem valueForKey:k_selectorString] hasPrefix:@"insertCustomText"];
        unsigned int theIndex = [inOutlineView rowForItem:inItem];

        (void)[_textInsertStringArrayController setSelectionIndex:theIndex];
        [_textInsertStringTextView setEditable:theBoolIsEnabled];
        if (theBoolIsEnabled) {
            [_textInsertStringTextView setBackgroundColor:[NSColor controlBackgroundColor]];
        } else {
            [_textInsertStringTextView setBackgroundColor:[NSColor controlHighlightColor]];
        }
    }
    // 編集ボタンを有効化／無効化
    [theEditButton setEnabled:([inItem valueForKey:k_children] == nil)];

    return YES;
}



#pragma mark ===== Action messages =====

//=======================================================
// Action messages
//
//=======================================================

// ------------------------------------------------------
- (IBAction)editKeyBindingKey:(id)sender
// 選択行のキー編集開始
// ------------------------------------------------------
{
    [self performEditOutlineViewSelectedKeyBindingKeyColumn];
}


// ------------------------------------------------------
- (IBAction)deleteKeyBindingKey:(id)sender
// 選択行のキー削除
// ------------------------------------------------------
{
    id theSheet, theOutlineView;
    if (_outlineMode == k_outlineViewModeMenu) {
        theSheet = _menuEditSheet;
        theOutlineView = _menuOutlineView;
    } else if (_outlineMode == k_outlineViewModeText) {
        theSheet = _textEditSheet;
        theOutlineView = _textOutlineView;
    } else {
        return;
    }
    if ((theSheet == nil) || (theOutlineView == nil)) { return; }

    id theFieldEditor = [theSheet fieldEditor:NO forObject:theOutlineView];

    [theFieldEditor setString:@""];

    [theSheet endEditingFor:theFieldEditor];
    [theSheet makeFirstResponder:theOutlineView];
}


// ------------------------------------------------------
- (IBAction)resetOutlineDataArrayToFactoryDefaults:(id)sender
// キーバインディングを出荷時設定に戻す
// ------------------------------------------------------
{
    if (_outlineMode == k_outlineViewModeMenu) {
        NSMutableArray *theTmpArray = [_outlineDataArray mutableCopy]; // ===== copy
        if (theTmpArray != nil) {
            [self resetKeySpecCharsToFactoryDefaultsOfOutlineDataArray:theTmpArray];
            [_outlineDataArray release];
            _outlineDataArray = theTmpArray;
            [_duplicateKeyCheckArray release];
            _duplicateKeyCheckArray = 
                    [[self duplicateKeyCheckArrayWithArray:_outlineDataArray] retain]; // ===== retain
            [_menuEditKeyButton setEnabled:NO];
            [_menuOutlineView deselectAll:nil];
            [_menuOutlineView reloadData];
        }
        [_menuFactoryDefaultsButton setEnabled:NO];

    } else if (_outlineMode == k_outlineViewModeText) {
        NSMutableArray *theContentArray = [NSMutableArray array];
        NSArray *theInsertTextArray = [[[NSApp delegate] class] factoryDefaultOfTextInsertStringArray];
        NSMutableDictionary *theDict;
        int i, theMax = [theInsertTextArray count];

        for (i = 0; i < theMax; i++) {
            theDict = [NSMutableDictionary dictionaryWithObject:[theInsertTextArray objectAtIndex:i] 
                        forKey:k_key_insertCustomText];
            [theContentArray addObject:theDict];
        }
        [_textOutlineView deselectAll:nil];
        [_outlineDataArray release];
        _outlineDataArray = 
                [[self textKeySpecCharArrayForOutlineDataWithFactoryDefaults:YES] retain]; // ===== retain
        [_duplicateKeyCheckArray release];
        _duplicateKeyCheckArray = [_outlineDataArray mutableCopy]; // ===== copy
        [_textInsertStringArrayController setContent:theContentArray];
        [_textInsertStringArrayController setSelectionIndex:NSNotFound]; // 選択なし
        [_textEditKeyButton setEnabled:NO];
        [_textOutlineView reloadData];
        [_textInsertStringTextView setEditable:NO];
        [_textInsertStringTextView setBackgroundColor:[NSColor controlHighlightColor]];
        [_textFactoryDefaultsButton setEnabled:NO];
    }
}


// ------------------------------------------------------
- (IBAction)closeKeyBindingEditSheet:(id)sender
// キーバインディング編集シートの OK / Cancel ボタンが押された
// ------------------------------------------------------
{
    // フォーカスを移して入力中の値を確定
    [[sender window] makeFirstResponder:sender];
    // キー入力取得を停止
    [[NSNotificationCenter defaultCenter] postNotificationName:k_setKeyCatchModeToCatchMenuShortcut 
            object:self 
            userInfo:[NSDictionary dictionaryWithObjectsAndKeys:
                [NSNumber numberWithInt:k_keyDownNoCatch], k_keyCatchMode, 
                nil]
            ];

    if ([sender tag] == k_okButtonTag) { // ok のときデータを保存、反映させる
        if ((_outlineMode == k_outlineViewModeMenu) || (_outlineMode == k_outlineViewModeText)) {
            [self saveOutlineViewData];
        }
    }
    // シートを閉じる
    [NSApp stopModal];
    // シート内アウトラインビューデータを開放
    if (_outlineDataArray) {
        [_outlineDataArray release];
        _outlineDataArray = nil;
    }
    if (_outlineMode == k_outlineViewModeMenu) {
        [_menuOutlineView reloadData]; // （ここでリロードしておかないと、選択行が残ったり展開されたままになる）
    } else if (_outlineMode == k_outlineViewModeText) {
        [_textInsertStringArrayController setContent:nil];
        [_textOutlineView reloadData]; // （ここでリロードしておかないと、選択行が残ったり展開されたままになる）
    }
    // 重複チェック配列を開放
    if (_duplicateKeyCheckArray) {
        [_duplicateKeyCheckArray release];
        _duplicateKeyCheckArray = nil;
    }
}


//------------------------------------------------------
- (IBAction)doubleClickedOutlineViewRow:(id)sender
// アウトラインビューの行がダブルクリックされた
// ------------------------------------------------------
{
    if (![sender isKindOfClass:[NSOutlineView class]]) { return; }

    int theSelectedRow = [(NSOutlineView *)sender selectedRow];

    if (theSelectedRow != -1) {
        id theItem = [(NSOutlineView *)sender itemAtRow:theSelectedRow];

        // ダブルクリックでトグルに展開する
        if ([(NSOutlineView *)sender isExpandable:theItem]) {
            [(NSOutlineView *)sender expandItem:theItem];
        } else {
            [(NSOutlineView *)sender collapseItem:theItem];
        }
    }
}



@end


@implementation CEKeyBindingManager (Private)

//=======================================================
// Private method
//
//=======================================================

//------------------------------------------------------
- (NSString *)pathOfMenuKeyBindingSettingFile
// メニューキーバインディング設定ファイル保存用ファイルのパスを返す
//------------------------------------------------------
{
    NSString *outPath = [NSHomeDirectory( ) 
            stringByAppendingPathComponent:
                @"Library/Application Support/CotEditor/KeyBindings/MenuKeyBindings.plist"];

    return outPath;
}


//------------------------------------------------------
- (NSString *)pathOfTextKeyBindingSettingFile
// メニューキーバインディング設定ファイル保存用ファイルのパスを返す
//------------------------------------------------------
{
    NSString *outPath = [NSHomeDirectory( ) 
            stringByAppendingPathComponent:
                @"Library/Application Support/CotEditor/KeyBindings/TextKeyBindings.plist"];

    return outPath;
}


// ------------------------------------------------------
- (void)setupMenuKeyBindingDictionary
// メニューキーバインディング定義ファイルのセットアップと読み込み
// ------------------------------------------------------
{
    NSString *theFilePath = [self pathOfMenuKeyBindingSettingFile];
    NSString *theDirPath = [theFilePath stringByDeletingLastPathComponent];

    // ディレクトリの存在チェック
    NSFileManager *theFileManager = [NSFileManager defaultManager];
    BOOL theValueIsDir = NO, theValueCreated = NO;
    BOOL theExists = [theFileManager fileExistsAtPath:theDirPath isDirectory:&theValueIsDir];
    if (!theExists) {
        theValueCreated = [theFileManager createDirectoryAtPath:theDirPath attributes:nil];
    }
    if ((theExists && theValueIsDir) || (theValueCreated)) {
        NSString *theSource = [[[NSBundle mainBundle] bundlePath] 
                stringByAppendingPathComponent:@"/Contents/Resources/DefaultMenuKeyBindings.plist"];

        if (([theFileManager fileExistsAtPath:theSource]) && 
                    (![theFileManager fileExistsAtPath:theFilePath])) {
            if (![theFileManager copyPath:theSource toPath:theFilePath handler:nil]) {
                NSLog(@"Error! Could not copy \"%@\" to \"%@\"...", theSource, theFilePath);
                return;
            }
        }
    } else {
        NSLog(@"Error! Key Bindings directory could not be found.");
        return;
    }

    // データ読み込み
    if (_menuKeyBindingDict != nil) {
        [_menuKeyBindingDict release];
    }
    _menuKeyBindingDict = 
            [[NSDictionary allocWithZone:[self zone]] initWithContentsOfFile:theFilePath]; // ===== alloc
}


// ------------------------------------------------------
- (void)setupTextKeyBindingDictionary
// テキストキーバインディング定義ファイルのセットアップと読み込み
// ------------------------------------------------------
{
    NSString *theFilePath = [self pathOfTextKeyBindingSettingFile];
    NSString *theDirPath = [theFilePath stringByDeletingLastPathComponent];

    // ディレクトリの存在チェック
    NSFileManager *theFileManager = [NSFileManager defaultManager];
    BOOL theValueIsDir = NO, theValueCreated = NO;
    BOOL theExists = [theFileManager fileExistsAtPath:theDirPath isDirectory:&theValueIsDir];
    if (!theExists) {
        theValueCreated = [theFileManager createDirectoryAtPath:theDirPath attributes:nil];
    }
    if ((theExists && theValueIsDir) || (theValueCreated)) {
        NSString *theSource = [[[NSBundle mainBundle] bundlePath] 
                stringByAppendingPathComponent:@"/Contents/Resources/DefaultTextKeyBindings.plist"];

        if (([theFileManager fileExistsAtPath:theSource]) && 
                    (![theFileManager fileExistsAtPath:theFilePath])) {
            if (![theFileManager copyPath:theSource toPath:theFilePath handler:nil]) {
                NSLog(@"Error! Could not copy \"%@\" to \"%@\"...", theSource, theFilePath);
                return;
            }
        }
    } else {
        NSLog(@"Error! Key Bindings directory could not be found.");
        return;
    }

    // データ読み込み
    if (_textKeyBindingDict != nil) {
        [_textKeyBindingDict release];
    }
    _textKeyBindingDict = 
            [[NSDictionary allocWithZone:[self zone]] initWithContentsOfFile:theFilePath]; // ===== alloc
}


//------------------------------------------------------
- (void)clearAllMenuKeyBindingOf:(NSMenu *)inMenu
// すべてのメニューのキーボードショートカットをクリアする
//------------------------------------------------------
{
    NSEnumerator *theMenuEnum = [[inMenu itemArray] objectEnumerator];
    NSString *theSelectorString;
    id theMenuItem;

    while (theMenuItem = [theMenuEnum nextObject]) {
        theSelectorString = NSStringFromSelector([theMenuItem action]);
        // フォントサイズ変更、エンコーディングの各項目、カラーリングの各項目、などは変更しない
        if (([theSelectorString isEqualToString:@"modifyFont:"]) || 
                ([theSelectorString isEqualToString:@"setEncoding:"]) || 
                ([theSelectorString isEqualToString:@"setSyntaxStyle:"]) || 
                ([theSelectorString isEqualToString:@"makeKeyAndOrderFront:"]) || 
                ([theSelectorString isEqualToString:@"launchScript:"]) || 
                ([theSelectorString isEqualToString:@"_openRecentDocument:"]) || // = 10.3 の「最近開いた書類」
                ([theSelectorString isEqualToString:@"orderFrontCharacterPalette:"]) || // = 10.4「特殊文字…」
                ([theMenuItem tag] == k_servicesMenuItemTag) || 
                ([theMenuItem tag] == k_windowPanelsMenuItemTag) || 
                ([theMenuItem tag] == k_scriptMenuDirectoryTag)) { // スクリプトメニュー内ユーザ定義サブメニュー
            continue;
        }
        [theMenuItem setKeyEquivalent:@""];
        [theMenuItem setKeyEquivalentModifierMask:0];
        if ([theMenuItem hasSubmenu]) {
            [self clearAllMenuKeyBindingOf:[theMenuItem submenu]];
        }
    }
}


//------------------------------------------------------
- (void)updateMenuValidation:(NSMenu *)inMenu
// キーボードショートカット設定を反映させる
//------------------------------------------------------
{
    NSEnumerator *theMenuEnum = [[inMenu itemArray] objectEnumerator];
    id theMenuItem;

    [inMenu update];
    while (theMenuItem = [theMenuEnum nextObject]) {
        if ([theMenuItem hasSubmenu]) {
            [self updateMenuValidation:[theMenuItem submenu]];
        }
    }

}


//------------------------------------------------------
- (void)resetAllMenuKeyBindingWithDictionary
// すべてのメニューにキーボードショートカットを設定し直す
//------------------------------------------------------
{
    if (_menuKeyBindingDict == nil) { return; }

//    NSString *theSelectorStr;
//    SEL theSelector;
//    id theKey;

    // まず、全メニューのショートカット定義をクリアする
    [self clearAllMenuKeyBindingOf:[NSApp mainMenu]];

    [self resetKeyBindingWithDictionaryTo:[NSApp mainMenu]];
    // メニュー更新（キーボードショートカット設定反映）
    [self updateMenuValidation:[NSApp mainMenu]];
}


//------------------------------------------------------
- (void)resetKeyBindingWithDictionaryTo:(NSMenu *)inMenu
// メニューにキーボードショートカットを設定する
//------------------------------------------------------
{
// NSMenu の indexOfItemWithTarget:andAction: だと取得できないメニューアイテムがあるため、メニューをひとつずつなめる
    NSEnumerator *theMenuEnum = [[inMenu itemArray] objectEnumerator];
    id theMenuItem;

    while (theMenuItem = [theMenuEnum nextObject]) {
        if (([theMenuItem hasSubmenu]) && 
                ([theMenuItem tag] != k_servicesMenuItemTag) && 
                ([theMenuItem tag] != k_windowPanelsMenuItemTag) && 
                ([theMenuItem tag] != k_scriptMenuDirectoryTag)) {
            [self resetKeyBindingWithDictionaryTo:[theMenuItem submenu]];
        } else {
            NSString *theSelectorString = NSStringFromSelector([theMenuItem action]);
            // フォントサイズ変更、エンコーディングの各項目、カラーリングの各項目、などは変更しない
            if (([theSelectorString isEqualToString:@"modifyFont:"]) || 
                    ([theSelectorString isEqualToString:@"setEncoding:"]) || 
                    ([theSelectorString isEqualToString:@"setSyntaxStyle:"]) || 
                    ([theSelectorString isEqualToString:@"makeKeyAndOrderFront:"]) || 
                    ([theSelectorString isEqualToString:@"launchScript:"]) || 
                    ([theSelectorString isEqualToString:@"_openRecentDocument:"]) || // = 10.3 での「最近開いた書類」
                    ([theSelectorString isEqualToString:@"orderFrontCharacterPalette:"]) || // = 10.4「特殊文字…」
                    ([theMenuItem tag] == k_servicesMenuItemTag) || 
                    ([theMenuItem tag] == k_windowPanelsMenuItemTag) || 
                    ([theMenuItem tag] == k_scriptMenuDirectoryTag)) {
                continue;
            }
            NSString *theKeySpecChars = [self keySpecCharsInDictionaryFromSelectorString:theSelectorString];
            unsigned int theMod = 0;
            NSString *theKeyEquivalent = [[NSApp delegate] keyEquivalentAndModifierMask:&theMod
                            fromString:theKeySpecChars includingCommandKey:YES];

            // theKeySpecChars があり Cmd が設定されている場合だけ、反映させる
            if ((theKeySpecChars != nil) && ([theKeySpecChars length] > 0) && (theMod & NSCommandKeyMask)) {
                // 日本語リソースが使われたとき、Input BackSlash の keyEquivalent を変更する
                // （半角円マークのままだと半角カナ「エ」に化けるため）
                if (([theKeyEquivalent isEqualToString:[NSString stringWithCharacters:&k_yenMark length:1]]) && 
                        ([[[[[NSBundle mainBundle] pathForResource:@"InfoPlist" ofType:@"strings"] 
                            stringByDeletingLastPathComponent] lastPathComponent] 
                            isEqualToString:@"Japanese.lproj"])) {
                    [theMenuItem setKeyEquivalent:@"\\"];
                } else {
                    [theMenuItem setKeyEquivalent:theKeyEquivalent];
                }
                [theMenuItem setKeyEquivalentModifierMask:theMod];
            }
        }
    }
}


//------------------------------------------------------
- (NSMutableArray *)mainMenuArrayForOutlineData:(NSMenu *)inMenu
// 現在のメニューからショートカットキー設定を読み込み編集用アウトラインビューデータ配列を返す
//------------------------------------------------------
{
    NSMutableArray *outArray = [NSMutableArray array];
    NSEnumerator *theMenuEnum = [[inMenu itemArray] objectEnumerator];
    NSMutableDictionary *theDict;
    NSString *theSelectorString, *theKeyEquivalent, *theKeySpecChars;
    id theMenuItem;
    unsigned int theMod;

    while (theMenuItem = [theMenuEnum nextObject]) {
        if (([theMenuItem isSeparatorItem]) || ([[theMenuItem title] length] < 1)) {
            continue;
        } else if (([theMenuItem hasSubmenu]) && 
                ([theMenuItem tag] != k_servicesMenuItemTag) && 
                ([theMenuItem tag] != k_windowPanelsMenuItemTag) && 
                ([theMenuItem tag] != k_scriptMenuDirectoryTag)) {
            NSMutableArray *theSubArray = [self mainMenuArrayForOutlineData:[theMenuItem submenu]];
            theDict = [NSMutableDictionary dictionaryWithObjectsAndKeys:
                    [theMenuItem title], k_title, 
                    theSubArray, k_children, 
                    nil];
        } else {
            theSelectorString = NSStringFromSelector([theMenuItem action]);
            // フォントサイズ変更、エンコーディングの各項目、カラーリングの各項目、などはリストアップしない
            if (([theSelectorString isEqualToString:@"modifyFont:"]) || 
                    ([theSelectorString isEqualToString:@"setEncoding:"]) || 
                    ([theSelectorString isEqualToString:@"setSyntaxStyle:"]) || 
                    ([theSelectorString isEqualToString:@"makeKeyAndOrderFront:"]) || 
                    ([theSelectorString isEqualToString:@"launchScript:"]) || 
                    ([theSelectorString isEqualToString:@"_openRecentDocument:"]) || // = 10.3 での「最近開いた書類」
                    ([theSelectorString isEqualToString:@"orderFrontCharacterPalette:"]) || // = 10.4「特殊文字…」
                    ([theMenuItem tag] == k_servicesMenuItemTag) || 
                    ([theMenuItem tag] == k_windowPanelsMenuItemTag) || 
                    ([theMenuItem tag] == k_scriptMenuDirectoryTag)) {
                continue;
            }
            theKeyEquivalent = [theMenuItem keyEquivalent];
            if ((theKeyEquivalent != nil) && ([theKeyEquivalent length] > 0)) {
                theMod = [theMenuItem keyEquivalentModifierMask];
                theKeySpecChars = [self keySpecCharsFromKeyEquivalent:theKeyEquivalent modifierFrags:theMod];
            } else {
                theKeySpecChars = [NSString stringWithString:@""];
            }
            theDict = [NSMutableDictionary dictionaryWithObjectsAndKeys:
                        [theMenuItem title], k_title, 
                        theKeySpecChars, k_keyBindingKey, 
                        theSelectorString, k_selectorString, 
                        nil];
        }
        [outArray addObject:theDict];
    }
    return outArray;
}


//------------------------------------------------------
- (NSMutableArray *)textKeySpecCharArrayForOutlineDataWithFactoryDefaults:(BOOL)inBool
// テキストキーバインディングの現在の保持データから設定を読み込み編集用アウトラインビューデータ配列を返す
//------------------------------------------------------
{
    // inBool == YES で標準設定を返す。NO なら現在の設定を返す。

    NSMutableArray *outArray = [NSMutableArray array];
    NSEnumerator *theEnumerator = [[self textKeyBindingSelectorStrArray] objectEnumerator];
    NSMutableDictionary *theDict;
    NSArray *theKeysArray;
    id theSelector;
    id theKey;

    while (theSelector = [theEnumerator nextObject]) {
        if ((theSelector != nil) && ([theSelector isKindOfClass:[NSString class]]) && 
                ([theSelector length] > 0)) {
            if (inBool) {
                NSString *theSource = [[[NSBundle mainBundle] bundlePath] 
                        stringByAppendingPathComponent:@"/Contents/Resources/DefaultTextKeyBindings.plist"];
                NSDictionary *theDefaultDict = [NSDictionary dictionaryWithContentsOfFile:theSource];
                theKeysArray = [theDefaultDict allKeysForObject:theSelector];
            } else {
                theKeysArray = [_textKeyBindingDict allKeysForObject:theSelector];
            }
            if ((theKeysArray != nil) && ([theKeysArray count] > 0)) {
                theKey = [theKeysArray objectAtIndex:0];
                theDict = [NSMutableDictionary dictionaryWithObjectsAndKeys:
                            theSelector, k_title, //*****
                            theKey, k_keyBindingKey, 
                            theSelector, k_selectorString, 
                            nil];
            } else {
                theDict = [NSMutableDictionary dictionaryWithObjectsAndKeys:
                            theSelector, k_title, //*****
                            @"", k_keyBindingKey, 
                            theSelector, k_selectorString, 
                            nil];
            }
            [outArray addObject:theDict];
        }
    }
    return outArray;
}


//------------------------------------------------------
- (NSString *)readableKeyStringsFromKeySpecChars:(NSString *)inString
// キーバインディング定義文字列から表示用文字列を生成し、返す
//------------------------------------------------------
{
    int theLength = [inString length];
    if (theLength < 2) { return @""; }
    NSString *theKeyEquivalent = [inString substringFromIndex:(theLength - 1)];
    NSString *theKeyStr = [self readableKeyStringsFromKeyEquivalent:theKeyEquivalent];
    BOOL theBoolDrawShift = (isupper([theKeyEquivalent characterAtIndex:0]) == 1);
    NSString *theModKeyStr = 
            [self readableKeyStringsFromModKeySpecChars:[inString substringToIndex:(theLength - 1)] 
                withShiftKey:theBoolDrawShift];

    return [NSString stringWithFormat:@"%@%@", theModKeyStr, theKeyStr];
}


//------------------------------------------------------
- (NSString *)readableKeyStringsFromKeyEquivalent:(NSString *)inString
// メニューのキーボードショートカットから表示用文字列を返す
//------------------------------------------------------
{
    if ([inString length] < 1) { return @""; }

    unichar theChar = [inString characterAtIndex:0];
    if ([[NSCharacterSet alphanumericCharacterSet] characterIsMember:theChar]) {
        return [inString uppercaseString];
    } else {
        return [self visibleCharFromIgnoringModChar:inString];
    }
}


//------------------------------------------------------
- (NSString *)keySpecCharsFromKeyEquivalent:(NSString *)inString modifierFrags:(unsigned int)inModFlags
// メニューのキーボードショートカットからキーバインディング定義文字列を返す
//------------------------------------------------------
{
    if ([inString length] < 1) { return @""; }

    NSMutableString *outStr = [NSMutableString string];
    unichar theChar = [inString characterAtIndex:0];
    BOOL theBoolShiftPress = NO;
    int i, theMax = sizeof(k_modifierKeysList) / sizeof(unsigned int);

    if (theMax != (sizeof(k_keySpecCharList) / sizeof(unichar))) {
        NSLog(@"internal data error! 'k_modifierKeysList' and 'k_keySpecCharList' size is different.");
        return @"";
    }

    for (i = 0; i < theMax; i++) {
        if ((inModFlags & k_modifierKeysList[i]) || ((i == 2) && (isupper(theChar) == 1))) {
            // （メニューから定義値を取得した時、アルファベット+シフトの場合にシフトの定義が欠落するための回避処置）
            [outStr appendFormat:@"%C", k_keySpecCharList[i]];
            if ((i == 2) && (isupper(theChar) == 1)) {
                theBoolShiftPress = YES;
            }
        }
    }
    [outStr appendString:((theBoolShiftPress) ? [inString uppercaseString] : inString)];

    return outStr;
}


//------------------------------------------------------
- (NSString *)readableKeyStringsFromModKeySpecChars:(NSString *)inModString withShiftKey:(BOOL)inBool
// キーバインディング定義文字列から表示用モディファイアキー文字列を生成し、返す
//------------------------------------------------------
{
    NSCharacterSet *theModStringSet = [NSCharacterSet characterSetWithCharactersInString:inModString];
    NSMutableString *outStr = [NSMutableString string];
    unichar theChar;
    int i, theMax = sizeof(k_keySpecCharList) / sizeof(unichar);

    if (theMax != (sizeof(k_readableKeyStringsList) / sizeof(unichar))) {
        NSLog(@"internal data error! 'k_keySpecCharList' and 'k_readableKeyStringsList' size is different.");
        return @"";
    }

    for (i = 0; i < theMax; i++) {
        theChar = k_keySpecCharList[i];
        if ([theModStringSet characterIsMember:theChar]) {
            [outStr appendFormat:@"%C", k_readableKeyStringsList[i]];
        }
    }
    return outStr;
}


//------------------------------------------------------
- (NSString *)visibleCharFromIgnoringModChar:(NSString *)inIgModChar
// キーバインディング定義文字列またはキーボードショートカットキーからキー表示用文字列を生成し、返す
//------------------------------------------------------
{
    NSString *outString = [_noPrintableKeyDict objectForKey:inIgModChar];

    return (outString) ? outString : inIgModChar;
}


//------------------------------------------------------
- (void)addCatchedMenuShortcutString:(NSNotification *)inNotification
// 新しいキーバインディングキーの押下をアウトラインビューに取り込む
//------------------------------------------------------
{
    id theSheet, theOutlineView;
    if (_outlineMode == k_outlineViewModeMenu) {
        theSheet = _menuEditSheet;
        theOutlineView = _menuOutlineView;
    } else if (_outlineMode == k_outlineViewModeText) {
        theSheet = _textEditSheet;
        theOutlineView = _textOutlineView;
    } else {
        return;
    }
    if ((theSheet != nil) && (theOutlineView != nil)) {

        NSDictionary *theUserInfo = [inNotification userInfo];
        unsigned int theModFlags = [[theUserInfo valueForKey:k_keyBindingModFlags] unsignedIntValue];
        id theFieldEditor = [theSheet fieldEditor:NO forObject:theOutlineView];
        NSString *theCharIgnoringMod = [theUserInfo valueForKey:k_keyBindingChar];
        NSString *theFieldString = 
                [self keySpecCharsFromKeyEquivalent:theCharIgnoringMod modifierFrags:theModFlags];

        [theFieldEditor setString:theFieldString];
        [theSheet endEditingFor:theFieldEditor];
        [theSheet makeFirstResponder:theOutlineView];
    }
}


//------------------------------------------------------
- (BOOL)showDuplicateKeySpecCharsMessageWithKeySpecChars:(NSString *)inKeySpec oldChars:(NSString *)inOldSpec
// 重複などの警告メッセージを表示
//------------------------------------------------------
{
    BOOL outBool = NO;

    if ((_duplicateKeyCheckArray == nil) || (inKeySpec == nil)) { return outBool; }

    NSString *theReadableKeyStr;

    // 他のキーバインディングと重複している時
    if (([inKeySpec length] > 0) && (![inKeySpec isEqualToString:inOldSpec]) && 
            ([_duplicateKeyCheckArray containsObject:inKeySpec])) {
        // メッセージ表示
        theReadableKeyStr = [self readableKeyStringsFromKeySpecChars:inKeySpec];
        if (_outlineMode == k_outlineViewModeMenu) { // === Menu
            [_menuDuplicateTextField setStringValue:
                    [NSString stringWithFormat:
                        NSLocalizedString(@"'%@' have already been used. Edit it again.",@""), 
                        theReadableKeyStr]];
            [_menuOkButton setEnabled:NO];
        } else if (_outlineMode == k_outlineViewModeText) { // === Text
            [_textDuplicateTextField setStringValue:
                    [NSString stringWithFormat:
                        NSLocalizedString(@"'%@' have already been used. Edit it again.",@""), 
                        theReadableKeyStr]];
            [_textOkButton setEnabled:NO];
        }
        NSBeep();
        outBool = NO;

    } else {
        NSRange theCmdRange = [inKeySpec rangeOfString:@"@"];
        BOOL theBoolAccept = NO;

        // コマンドキーの存在チェック
        if ([inKeySpec isEqualToString:@""]) { // 空文字（入力なし = 削除された）の場合はスルー
            theBoolAccept = YES;
        } else if (_outlineMode == k_outlineViewModeMenu) { // === Menu
            theBoolAccept = ((theCmdRange.location != NSNotFound) && 
                            (theCmdRange.location != ([inKeySpec length] - 1)));
        } else if (_outlineMode == k_outlineViewModeText) { // === Text
            theBoolAccept = ((theCmdRange.location == NSNotFound) || 
                            (theCmdRange.location == ([inKeySpec length] - 1)));
        }

        // モードとコマンドキーの有無が合致しなければメッセージ表示
        if (!theBoolAccept) {
            theReadableKeyStr = [self readableKeyStringsFromKeySpecChars:inKeySpec];
            if (_outlineMode == k_outlineViewModeMenu) { // === Menu
                [_menuDuplicateTextField setStringValue:
                        [NSString stringWithFormat:
                            NSLocalizedString(@"'%@' NOT include Command Key. Edit it again.",@""), 
                            theReadableKeyStr]];
                [_menuOkButton setEnabled:NO];
            } else if (_outlineMode == k_outlineViewModeText) { // === Text
                [_textDuplicateTextField setStringValue:
                        [NSString stringWithFormat:
                            NSLocalizedString(@"'%@' include Command Key. Edit it again.",@""), 
                            theReadableKeyStr]];
                [_textOkButton setEnabled:NO];
            }
            NSBeep();
            outBool = NO;

        } else {
            // メッセージ消去
            if (_outlineMode == k_outlineViewModeMenu) { // === Menu
                [_menuDuplicateTextField setStringValue:@""];
                [_menuOkButton setEnabled:YES];
            } else if (_outlineMode == k_outlineViewModeText) { // === Text
                [_textDuplicateTextField setStringValue:@""];
                [_textOkButton setEnabled:YES];
            }
            outBool = YES;
            // 重複チェック配列更新
            if ((inOldSpec != nil) && ([inOldSpec length] > 0) && (![inKeySpec isEqualToString:inOldSpec])) {
                [_duplicateKeyCheckArray removeObject:inOldSpec];
            }
            // 重複チェック配列更新
            if ((inKeySpec != nil) && ([inKeySpec length] > 0) && (![inKeySpec isEqualToString:inOldSpec])) {
                [_duplicateKeyCheckArray addObject:inKeySpec];
            }
        }
    }
    return outBool;
}


//------------------------------------------------------
- (NSMutableArray *)duplicateKeyCheckArrayWithMenu:(NSMenu *)inMenu
// 重複チェック配列を生成
//------------------------------------------------------
{
    NSMutableArray *outArray = [NSMutableArray array];
    NSEnumerator *theEnumerator = [[inMenu itemArray] objectEnumerator];
    NSString *theKeyEquivalent, *theKeySpecChars;
    id theMenuItem;
    unsigned int theMod;

    while (theMenuItem = [theEnumerator nextObject]) {
        if ([theMenuItem hasSubmenu]) {
            NSArray *theTmpArray = [self duplicateKeyCheckArrayWithMenu:[theMenuItem submenu]];
            [outArray addObjectsFromArray:theTmpArray];
            continue;
        }
        theKeyEquivalent = [theMenuItem keyEquivalent];
        if ([theKeyEquivalent length] > 0) {
            theMod = [theMenuItem keyEquivalentModifierMask];
            theKeySpecChars = [self keySpecCharsFromKeyEquivalent:theKeyEquivalent modifierFrags:theMod];
            if ([theKeySpecChars length] > 1) {
                [outArray addObject:theKeySpecChars];
            }
        }
    }
    return outArray;
}


//------------------------------------------------------
- (NSArray *)duplicateKeyCheckArrayWithArray:(NSArray *)inArray
// 重複チェック配列を生成
//------------------------------------------------------
{
    if (inArray == nil) { return nil; }

    NSEnumerator *theEnumerator = [inArray objectEnumerator];
    NSMutableArray *outArray = [NSMutableArray array];
    NSArray *theChildrenArray;
    id theItem, theChildren, theKeySpecChars;

    while (theItem = [theEnumerator nextObject]) {
        theChildren = [theItem valueForKey:k_children];
        if (theChildren != nil) {
            theChildrenArray = [self duplicateKeyCheckArrayWithArray:theChildren];
            [outArray addObjectsFromArray:theChildrenArray];
        }
        theKeySpecChars = [theItem valueForKey:k_keyBindingKey];
        if ((theKeySpecChars != nil) && ([theKeySpecChars length] > 0)) {
            if (![outArray containsObject:theKeySpecChars]) {
                [outArray addObject:theKeySpecChars];
            }
        }
    }
    return outArray;
}


//------------------------------------------------------
- (NSMutableDictionary *)keyBindingDictionaryFromOutlineViewDataArray:(NSArray *)inArray
// アウトラインビューデータから保存用辞書を生成
//------------------------------------------------------
{
    NSEnumerator *theEnumerator = [inArray objectEnumerator];
    NSMutableDictionary *outDict = [NSMutableDictionary dictionary];
    NSDictionary *theChildDict;
    id theItem, theChildren, theKeySpecChars, theSelectorStr;

    while (theItem = [theEnumerator nextObject]) {
        theChildren = [theItem valueForKey:k_children];
        if (theChildren != nil) {
            theChildDict = [self keyBindingDictionaryFromOutlineViewDataArray:theChildren];
            [outDict addEntriesFromDictionary:theChildDict];
        }
        theKeySpecChars = [theItem valueForKey:k_keyBindingKey];
        theSelectorStr = [theItem valueForKey:k_selectorString];
        if ((theKeySpecChars != nil) && (theSelectorStr != nil) && 
                ([theKeySpecChars length] > 0) && ([theSelectorStr length] > 0)) {
            [outDict setValue:theSelectorStr forKey:theKeySpecChars];
        }
    }
    return outDict;
}


//------------------------------------------------------
- (void)saveOutlineViewData
// アウトラインビューデータ保存
//------------------------------------------------------
{
    NSFileManager *theFileManager = [NSFileManager defaultManager];
    NSString *theFilePath, *theDirPath;
    BOOL theExists, theValueIsDir = NO, theValueCreated = NO;

    if (_outlineMode == k_outlineViewModeMenu) {
        theFilePath = [self pathOfMenuKeyBindingSettingFile]; // データディレクトリパス取得
        theDirPath = [theFilePath stringByDeletingLastPathComponent];

        // ディレクトリの存在チェック
        theExists = [theFileManager fileExistsAtPath:theDirPath isDirectory:&theValueIsDir];
        if (!theExists) {
            theValueCreated = [theFileManager createDirectoryAtPath:theDirPath attributes:nil];
        }
        if ((theExists && theValueIsDir) || (theValueCreated)) {
            [_menuKeyBindingDict release];
            _menuKeyBindingDict = 
                [[self keyBindingDictionaryFromOutlineViewDataArray:_outlineDataArray] retain]; // ===== retain

            if (![_menuKeyBindingDict writeToFile:theFilePath atomically:YES]) {
                NSLog(@"Error! Could not save the Menu keyBindings setting file...");
                return;
            }
        } else {
            NSLog(@"Error! Key Bindings directory could not be found.");
            return;
        }
        // メニューに反映させる
        [self resetAllMenuKeyBindingWithDictionary];

    } else if (_outlineMode == k_outlineViewModeText) {
        id theValues = [[NSUserDefaultsController sharedUserDefaultsController] values];
        NSArray *theContentArray = [[[_textInsertStringArrayController content] copy] autorelease];

        theFilePath = [self pathOfTextKeyBindingSettingFile]; // データディレクトリパス取得
        theDirPath = [theFilePath stringByDeletingLastPathComponent];

        // ディレクトリの存在チェック
        theExists = [theFileManager fileExistsAtPath:theDirPath isDirectory:&theValueIsDir];
        if (!theExists) {
            theValueCreated = [theFileManager createDirectoryAtPath:theDirPath attributes:nil];
        }
        if ((theExists && theValueIsDir) || (theValueCreated)) {
            [_textKeyBindingDict release];
            _textKeyBindingDict = 
                [[self keyBindingDictionaryFromOutlineViewDataArray:_outlineDataArray] retain]; // ===== retain

            if (![_textKeyBindingDict writeToFile:theFilePath atomically:YES]) {
                NSLog(@"Error! Could not save the Text keyBindings setting file...");
                return;
            }
        } else {
            NSLog(@"Error! Key Bindings directory could not be found.");
            return;
        }
        if (![theContentArray isEqualToArray:[theValues valueForKey:k_key_insertCustomTextArray]]) {
            NSUserDefaults *theDefaults = [NSUserDefaults standardUserDefaults];
            NSMutableArray *theDefaultsArray = [NSMutableArray array];
            NSString *theInsertText;
            int i, theMax = [theContentArray count];

            for (i = 0; i < theMax; i++) {
                theInsertText = [[theContentArray objectAtIndex:i] objectForKey:k_key_insertCustomText];
                if (theInsertText == nil) {
                    theInsertText = [NSString stringWithString:@""];
                }
                [theDefaultsArray addObject:theInsertText];
            }
            [theDefaults setObject:theDefaultsArray forKey:k_key_insertCustomTextArray];
            [_textInsertStringArrayController setContent:nil];
        }
    }
}


//------------------------------------------------------
- (NSString *)keySpecCharsInDictionaryFromSelectorString:(NSString *)inSelectorStr
// セレクタ名を定義しているキーバインディング文字列（キー）を得る
//------------------------------------------------------
{
    NSArray *theKeyArray = [_menuKeyBindingDict allKeysForObject:inSelectorStr];

    if ((theKeyArray != nil) && ([theKeyArray count] > 0)) {
        return (NSString *)[theKeyArray objectAtIndex:0];
    }
    return @"";
}


//------------------------------------------------------
- (NSString *)keySpecCharsInDefaultDictionaryFromSelectorString:(NSString *)inSelectorStr
// デフォルト設定の、セレクタ名を定義しているキーバインディング文字列（キー）を得る
//------------------------------------------------------
{
    NSArray *theKeyArray = [_defaultMenuKeyBindingDict allKeysForObject:inSelectorStr];

    if ((theKeyArray != nil) && ([theKeyArray count] > 0)) {
        return (NSString *)[theKeyArray objectAtIndex:0];
    }
    return @"";
}


//------------------------------------------------------
- (void)resetKeySpecCharsToFactoryDefaultsOfOutlineDataArray:(NSMutableArray *)inArray
// 配列中のキーバインディング設定文字列をデフォルトに戻す
//------------------------------------------------------
{
    NSEnumerator *theEnumerator = [inArray objectEnumerator];
    NSMutableArray *theChildrenArray;
    id theItem, theSelectorStr, theKeySpecChars;

    while (theItem = [theEnumerator nextObject]) {
        theChildrenArray = [theItem valueForKey:k_children];
        if (theChildrenArray != nil) {
            [self resetKeySpecCharsToFactoryDefaultsOfOutlineDataArray:theChildrenArray];
        }
        theSelectorStr = [theItem valueForKey:k_selectorString];
        theKeySpecChars = [self keySpecCharsInDefaultDictionaryFromSelectorString:theSelectorStr];
        [theItem setValue:theKeySpecChars forKey:k_keyBindingKey];
    }
}


//------------------------------------------------------
- (void)performEditOutlineViewSelectedKeyBindingKeyColumn
// キーを重複入力された時に再び選択状態にする
//------------------------------------------------------
{
    id theOutlineView = nil;

    if (_outlineMode == k_outlineViewModeMenu) {
        theOutlineView = _menuOutlineView;
    } else if (_outlineMode == k_outlineViewModeText) {
        theOutlineView = _textOutlineView;
    }
    if (theOutlineView == nil) { return; }

    int theSelectedRow = [theOutlineView selectedRow];

    if (theSelectedRow != -1) {

        id theItem = [theOutlineView itemAtRow:theSelectedRow];
        NSTableColumn *theColumn = [theOutlineView tableColumnWithIdentifier:k_keyBindingKey];

        if ([self outlineView:theOutlineView shouldEditTableColumn:theColumn item:theItem]) {
            if (_outlineMode == k_outlineViewModeMenu) {
                [_menuDeleteKeyButton setEnabled:YES];
            } else if (_outlineMode == k_outlineViewModeText) {
                [_textDeleteKeyButton setEnabled:YES];
            }
            [theOutlineView editColumn:[theOutlineView columnWithIdentifier:k_keyBindingKey] 
                    row:theSelectedRow withEvent:nil select:YES];
        }
    }
}


//------------------------------------------------------
- (NSDictionary *)noPrintableKeyDictionary
// そのまま表示できないキーバインディング定義文字列の変換辞書を返す
//------------------------------------------------------
{
// 下記の情報を参考にさせていただきました (2005.09.05)
// http://www.cocoabuilder.com/archive/message/2004/3/19/102023
    NSArray *theVisibleCharArray = [NSArray arrayWithObjects:
        [NSString stringWithFormat:@"%C", 0x2191], // "↑" NSUpArrowFunctionKey, 
        [NSString stringWithFormat:@"%C", 0x2193], // "↓" NSDownArrowFunctionKey, 
        [NSString stringWithFormat:@"%C", 0x2190], // "←" NSLeftArrowFunctionKey, 
        [NSString stringWithFormat:@"%C", 0x2192], // "→" NSRightArrowFunctionKey, 
        [NSString stringWithString:@"F1"], // NSF1FunctionKey, 
        [NSString stringWithString:@"F2"], // NSF2FunctionKey, 
        [NSString stringWithString:@"F3"], // NSF3FunctionKey, 
        [NSString stringWithString:@"F4"], // NSF4FunctionKey, 
        [NSString stringWithString:@"F5"], // NSF5FunctionKey, 
        [NSString stringWithString:@"F6"], // NSF6FunctionKey, 
        [NSString stringWithString:@"F7"], // NSF7FunctionKey, 
        [NSString stringWithString:@"F8"], // NSF8FunctionKey, 
        [NSString stringWithString:@"F9"], // NSF9FunctionKey, 
        [NSString stringWithString:@"F10"], // NSF10FunctionKey, 
        [NSString stringWithString:@"F11"], // NSF11FunctionKey, 
        [NSString stringWithString:@"F12"], // NSF12FunctionKey, 
        [NSString stringWithString:@"F13"], // NSF13FunctionKey, 
        [NSString stringWithString:@"F14"], // NSF14FunctionKey, 
        [NSString stringWithString:@"F15"], // NSF15FunctionKey, 
        [NSString stringWithString:@"F16"], // NSF16FunctionKey, 
        [NSString stringWithFormat:@"%C", 0x2326], // NSDeleteCharacter = "Delete forward"
        [NSString stringWithFormat:@"%C", 0x2196], // "↖" NSHomeFunctionKey, 
        [NSString stringWithFormat:@"%C", 0x2198], // "↘" NSEndFunctionKey, 
        [NSString stringWithFormat:@"%C", 0x21DE], // "⇞" NSPageUpFunctionKey, 
        [NSString stringWithFormat:@"%C", 0x21DF], // "⇟" NSPageDownFunctionKey, 
        [NSString stringWithFormat:@"%C", 0x2327], // "⌧" NSClearLineFunctionKey, 
        [NSString stringWithString:@"Help"], // NSHelpFunctionKey, 
        [NSString stringWithString:@"Space"], // "Space", 
        [NSString stringWithFormat:@"%C", 0x21E5], // "Tab"
        [NSString stringWithFormat:@"%C", 0x21A9], // "Return"
        [NSString stringWithFormat:@"%C", 0x232B], // "⌫" "Backspace"
        [NSString stringWithFormat:@"%C", 0x2305], // "Enter"
        [NSString stringWithFormat:@"%C", 0x21E4], // "Backtab"
        [NSString stringWithFormat:@"%C", 0x238B], // "Escape"
        nil];

    int theMax = sizeof(k_noPrintableKeyList) / sizeof(unichar);
    if (theMax != [theVisibleCharArray count]) {
        NSLog(@"internal data error! 'k_noPrintableKeyList' and 'theVisibleCharArray' size is different.");
        return @"";
    }
    NSMutableArray *theKeyArray = [NSMutableArray array];
    int i;

    for (i = 0; i < theMax; i++) {
        [theKeyArray addObject:[NSString stringWithFormat:@"%C", k_noPrintableKeyList[i]]];
    }

    return [NSDictionary dictionaryWithObjects:theVisibleCharArray forKeys:theKeyArray];
}


//------------------------------------------------------
- (NSArray *)textKeyBindingSelectorStrArray
// 独自定義のセレクタ名配列を返す
//------------------------------------------------------
{
    NSArray *outArray = [NSArray arrayWithObjects:
                @"insertCustomText_00:",
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
                @"insertCustomText_30:",
                nil];

    return outArray;
}



@end
