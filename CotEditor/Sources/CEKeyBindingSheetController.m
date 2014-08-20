/*
 ==============================================================================
 CEKeybindingsSheetController
 
 CotEditor
 http://coteditor.github.io
 
 Created on 2014-08-20 by 1024jp
 encoding="UTF-8"
 ------------------------------------------------------------------------------
 
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

#import "CEKeyBindingSheetController.h"
#import "CEKeyBindingManager.h"
#import "CEApplication.h"
#import "constants.h"


@interface CEKeyBindingSheetController () <NSOutlineViewDataSource, NSOutlineViewDelegate>

@property (nonatomic) CEKeyBindingsType keyBindingsMode;
@property (nonatomic) NSMutableArray *outlineDataArray;
@property (nonatomic, copy) NSString *currentKeySpecChars;
@property (nonatomic) NSMutableArray *duplicateKeyCheckArray;

@property (nonatomic, weak) IBOutlet NSOutlineView *menuOutlineView;
@property (nonatomic, weak) IBOutlet NSTextField *menuDuplicateTextField;
@property (nonatomic, weak) IBOutlet NSButton *menuEditKeyButton;
@property (nonatomic, weak) IBOutlet NSButton *menuDeleteKeyButton;
@property (nonatomic, weak) IBOutlet NSButton *menuFactoryDefaultsButton;
@property (nonatomic, weak) IBOutlet NSButton *menuOkButton;

@property (nonatomic, weak) IBOutlet NSOutlineView *textOutlineView;
@property (nonatomic, weak) IBOutlet  NSTextField *textDuplicateTextField;
@property (nonatomic, weak) IBOutlet NSButton *textEditKeyButton;
@property (nonatomic, weak) IBOutlet NSButton *textDeleteKeyButton;
@property (nonatomic, weak) IBOutlet NSButton *textFactoryDefaultsButton;
@property (nonatomic, weak) IBOutlet NSButton *textOkButton;
@property (nonatomic, strong) IBOutlet NSTextView *textInsertStringTextView;  // NSTextView cannot be weak on 10.8
@property (nonatomic) IBOutlet NSArrayController *textInsertStringArrayController;

@end




#pragma mark -

@implementation CEKeyBindingSheetController

// ------------------------------------------------------
/// 初期化
- (instancetype)initWithMode:(CEKeyBindingsType)mode
// ------------------------------------------------------
{
    NSString *nibName = (mode == CEMenuKeyBindingsType) ? @"MenuKeyBindingEditSheet" : @"TextKeyBindingEditSheet";
    
    self = [super initWithWindowNibName:nibName];
    if (self) {
        _keyBindingsMode = mode;
        
        switch (mode) {
            case CEMenuKeyBindingsType:
                _outlineDataArray = [[CEKeyBindingManager sharedManager] mainMenuArrayForOutlineData:[NSApp mainMenu]];
                _duplicateKeyCheckArray = [self duplicateKeyCheckArrayWithMenu:[NSApp mainMenu]];
                break;
                
            case CETextKeyBindingsType:
                _outlineDataArray = [[CEKeyBindingManager sharedManager] textKeySpecCharArrayForOutlineDataWithFactoryDefaults:NO];
                _duplicateKeyCheckArray = [_outlineDataArray mutableCopy];  // （システム標準のキーバインディングとの重複は、チェックしない）
                break;
        }
        
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(addCatchedMenuShortcutString:)
                                                     name:CEDidCatchMenuShortcutNotification
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
/// ウインドウ読み込み直後
- (void)windowDidLoad
// ------------------------------------------------------
{
    [super windowDidLoad];
    
    // ダブルクリックでトグルに展開するようアクションを設定する
    [[self menuOutlineView] setDoubleAction:@selector(doubleClickedOutlineViewRow:)];
    [[self menuOutlineView] setTarget:self];
    
    switch ([self keyBindingsMode]) {
        case CEMenuKeyBindingsType:
        {
            BOOL usesDefault = [[CEKeyBindingManager sharedManager] usesDefaultMenuKeyBindings];
            [[self menuDuplicateTextField] setStringValue:@""];
            [[self menuFactoryDefaultsButton] setEnabled:!usesDefault];
            [[self menuOutlineView] reloadData];
            [[self menuEditKeyButton] setEnabled:NO];
            // 現在の設定がデフォルト設定ならばデフォルト値を入力する
            if (usesDefault) {
                [self resetOutlineDataArrayToFactoryDefaults:nil];
            }
        }
            break;
            
        case CETextKeyBindingsType:
        {
            NSArray *insertTextArray = [[NSUserDefaults standardUserDefaults] stringArrayForKey:k_key_insertCustomTextArray];
            NSArray *factoryDefaults = [[[NSUserDefaults alloc] init] volatileDomainForName:NSRegistrationDomain][k_key_insertCustomTextArray];
            NSMutableArray *content = [NSMutableArray array];
            
            [[self textDuplicateTextField] setStringValue:@""];
            [[self textFactoryDefaultsButton] setEnabled:(![[self outlineDataArray] isEqualToArray:[self duplicateKeyCheckArray]] ||
                                                          ![factoryDefaults isEqualToArray:insertTextArray])];
            [[self textOutlineView] reloadData];
            for (NSString *object in insertTextArray) {
                [content addObject:[@{k_key_insertCustomText: object} mutableCopy]];
            }
            [[self textInsertStringArrayController] setContent:content];
            [[self textInsertStringArrayController] setSelectionIndex:NSNotFound]; // 選択なし
            [[self textInsertStringTextView] setEditable:NO];
            [[self textInsertStringTextView] setBackgroundColor:[NSColor controlHighlightColor]];
            [[self textEditKeyButton] setEnabled:NO];
        }
            break;
    }
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
        return [[CEKeyBindingManager sharedManager] readableKeyStringsFromKeySpecChars:[theItem valueForKey:identifier]];
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
        [(CEApplication *)NSApp setKeyCatchMode:CECatchMenuShortCutMode];
        
        switch ([self keyBindingsMode]) {
            case CEMenuKeyBindingsType:
                [[self menuDeleteKeyButton] setEnabled:YES];
                break;
            case CETextKeyBindingsType:
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
            ([self keyBindingsMode] == CEMenuKeyBindingsType) &&
            ([[[self menuDuplicateTextField] stringValue] length] > 0))
        {
            item[identifier] = @"";
            [[self menuDuplicateTextField] setStringValue:@""];
            [self showDuplicateKeySpecCharsMessageWithKeySpecChars:@"" oldChars:[self currentKeySpecChars]];
            
        } else if (([[NSApp currentEvent] type] == NSLeftMouseDown) &&
                   ([self keyBindingsMode] == CETextKeyBindingsType) &&
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
            __weak typeof(self) weakSelf = self;
            dispatch_async(dispatch_get_main_queue(), ^{
                typeof(self) strongSelf = weakSelf;
                [strongSelf performEditOutlineViewSelectedKeyBindingKeyColumn];
            });
        }
    }
    switch ([self keyBindingsMode]) {
        case CEMenuKeyBindingsType:
            [[self menuDeleteKeyButton] setEnabled:NO];
            break;
        case CETextKeyBindingsType:
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
    switch ([self keyBindingsMode]) {
        case CEMenuKeyBindingsType:
            editButton = [self menuEditKeyButton];
            break;
        case CETextKeyBindingsType:
            editButton = [self textEditKeyButton];
            break;
        default:
            return NO;
    }
    
    // キー取得を停止
    [(CEApplication *)NSApp setKeyCatchMode:CEKeyDownNoCatchMode];
    
    // テキストのバインディングを編集している時は挿入文字列配列コントローラの選択オブジェクトを変更
    if ([self keyBindingsMode] == CETextKeyBindingsType) {
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
    NSOutlineView *outlineView;
    
    switch ([self keyBindingsMode]) {
        case CEMenuKeyBindingsType:
            outlineView = [self menuOutlineView];
            break;
        case CETextKeyBindingsType:
            outlineView = [self textOutlineView];
            break;
    }
    
    NSText *fieldEditor = [[self window] fieldEditor:NO forObject:outlineView];
    
    [fieldEditor setString:@""];
    
    [[self window] endEditingFor:fieldEditor];
    [[self window] makeFirstResponder:outlineView];
}


// ------------------------------------------------------
/// キーバインディングを出荷時設定に戻す
- (IBAction)resetOutlineDataArrayToFactoryDefaults:(id)sender
// ------------------------------------------------------
{
    switch ([self keyBindingsMode]) {
        case CEMenuKeyBindingsType:
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
            
        case CETextKeyBindingsType:
        {
            NSMutableArray *contents = [NSMutableArray array];
            NSArray *defaultInsertTexts = [[[NSUserDefaults alloc] init] volatileDomainForName:NSRegistrationDomain][k_key_insertCustomTextArray];
            
            for (id object in defaultInsertTexts) {
                NSMutableDictionary *dict = [NSMutableDictionary dictionaryWithObject:object forKey:k_key_insertCustomText];
                [contents addObject:dict];
            }
            [[self textOutlineView] deselectAll:nil];
            [self setOutlineDataArray:[[CEKeyBindingManager sharedManager] textKeySpecCharArrayForOutlineDataWithFactoryDefaults:YES]];
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
    [(CEApplication *)NSApp setKeyCatchMode:CEKeyDownNoCatchMode];
    
    if ([sender tag] == k_okButtonTag) { // ok のときデータを保存、反映させる
        switch ([self keyBindingsMode]) {
            case CEMenuKeyBindingsType:
                [[CEKeyBindingManager sharedManager] saveMenuKeyBindings:[self outlineDataArray]];
                break;
                
            case CETextKeyBindingsType:
                [[CEKeyBindingManager sharedManager] saveTextKeyBindings:[self outlineDataArray]
                                                                   texts:[[self textInsertStringArrayController] content]];
                break;
        }
    }
    // シートを閉じる
    [NSApp stopModal];
}


//------------------------------------------------------
/// アウトラインビューの行がダブルクリックされた
- (IBAction)doubleClickedOutlineViewRow:(id)sender
// ------------------------------------------------------
{
    if (![sender isKindOfClass:[NSOutlineView class]]) { return; }
    
    NSOutlineView *outlineView = (NSOutlineView *)sender;
    
    NSInteger selectedRow = [outlineView selectedRow];
    
    if (selectedRow != -1) {
        id item = [outlineView itemAtRow:selectedRow];
        
        // ダブルクリックでトグルに展開する
        if ([outlineView isExpandable:item]) {
            [outlineView expandItem:item];
        } else {
            [outlineView collapseItem:item];
        }
    }
}



#pragma mark Private Mthods

//=======================================================
// Private method
//
//=======================================================

//------------------------------------------------------
/// 新しいキーバインディングキーの押下をアウトラインビューに取り込む
- (void)addCatchedMenuShortcutString:(NSNotification *)notification
//------------------------------------------------------
{
    NSOutlineView *outlineView;
    
    switch ([self keyBindingsMode]) {
        case CEMenuKeyBindingsType:
            outlineView = [self menuOutlineView];
            break;
        case CETextKeyBindingsType:
            outlineView = [self textOutlineView];
            break;
        default:
            return;
    }
    
    NSDictionary *userInfo = [notification userInfo];
    NSUInteger modifierFlags = [userInfo[CEKeyBindingModifierFlagsKey] unsignedIntegerValue];
    NSString *charsIgnoringModifiers = userInfo[CEKeyBindingCharsKey];
    NSString *fieldString = [[CEKeyBindingManager sharedManager] keySpecCharsFromKeyEquivalent:charsIgnoringModifiers
                                                                                 modifierFrags:modifierFlags];
    NSText *fieldEditor = [[self window] fieldEditor:NO forObject:outlineView];
    
    [fieldEditor setString:fieldString];
    [[self window] endEditingFor:fieldEditor];
    [[self window] makeFirstResponder:outlineView];
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
        readableKeyStr = [[CEKeyBindingManager sharedManager] readableKeyStringsFromKeySpecChars:keySpec];
        NSString *message = [NSString stringWithFormat:NSLocalizedString(@"“%@” has already been used. Edit it again.", nil),
                             readableKeyStr];
        switch ([self keyBindingsMode]) {
            case CEMenuKeyBindingsType:
                [[self menuDuplicateTextField] setStringValue:message];
                [[self menuOkButton] setEnabled:NO];
                break;
                
            case CETextKeyBindingsType:
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
            switch ([self keyBindingsMode]) {
                case CEMenuKeyBindingsType:
                    accepts = ((cmdRange.location != NSNotFound) && (cmdRange.location != ([keySpec length] - 1)));
                    break;
                    
                case CETextKeyBindingsType:
                    accepts = ((cmdRange.location == NSNotFound) || (cmdRange.location == ([keySpec length] - 1)));
                    break;
            }
        }
        
        // モードとコマンドキーの有無が合致しなければメッセージ表示
        if (!accepts) {
            readableKeyStr = [[CEKeyBindingManager sharedManager] readableKeyStringsFromKeySpecChars:keySpec];
            switch ([self keyBindingsMode]) {
                case CEMenuKeyBindingsType:
                    [[self menuDuplicateTextField] setStringValue:[NSString stringWithFormat:
                                                                   NSLocalizedString(@"“%@” does NOT include Command key. Edit it again.", nil), readableKeyStr]];
                    [[self menuOkButton] setEnabled:NO];
                    break;
                    
                case CETextKeyBindingsType:
                    [[self textDuplicateTextField] setStringValue:[NSString stringWithFormat:
                                                                   NSLocalizedString(@"“%@” includes Command key. Edit it again.", nil), readableKeyStr]];
                    [[self textOkButton] setEnabled:NO];
                    break;
            }
            
            NSBeep();
            showsMessage = NO;
            
        } else {
            // メッセージ消去
            switch ([self keyBindingsMode]) {
                case CEMenuKeyBindingsType:
                    [[self menuDuplicateTextField] setStringValue:@""];
                    [[self menuOkButton] setEnabled:YES];
                    break;
                    
                case CETextKeyBindingsType:
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
/// キーを重複入力された時に再び選択状態にする
- (void)performEditOutlineViewSelectedKeyBindingKeyColumn
//------------------------------------------------------
{
    NSOutlineView *outlineView = nil;
    
    switch ([self keyBindingsMode]) {
        case CEMenuKeyBindingsType:
            outlineView = [self menuOutlineView];
            break;
            
        case CETextKeyBindingsType:
            outlineView = [self textOutlineView];
            break;
    }
    
    NSInteger selectedRow = [outlineView selectedRow];
    
    if (selectedRow != -1) {
        id item = [outlineView itemAtRow:selectedRow];
        NSTableColumn *column = [outlineView tableColumnWithIdentifier:k_keyBindingKey];
        
        if ([self outlineView:outlineView shouldEditTableColumn:column item:item]) {
            switch ([self keyBindingsMode]) {
                case CEMenuKeyBindingsType:
                    [[self menuDeleteKeyButton] setEnabled:YES];
                    break;
                    
                case CETextKeyBindingsType:
                    [[self textDeleteKeyButton] setEnabled:YES];
                    break;
            }
            [outlineView editColumn:[outlineView columnWithIdentifier:k_keyBindingKey]
                                row:selectedRow withEvent:nil select:YES];
        }
    }
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
            NSString *keySpecChars = [[CEKeyBindingManager sharedManager] keySpecCharsFromKeyEquivalent:keyEquivalent
                                                                                          modifierFrags:modifierFlags];
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
        NSString *keySpecChars = [[CEKeyBindingManager sharedManager] keySpecCharsInDefaultDictionaryFromSelectorString:selectorStr];
        [item setValue:keySpecChars forKey:k_keyBindingKey];
    }
}

@end
