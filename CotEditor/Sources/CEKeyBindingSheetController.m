/*
 ==============================================================================
 CEKeyBindingSheetController
 
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
#import "CEKeyBindingSheet.h"
#import "CEKeyBindingManager.h"
#import "constants.h"


@interface CEKeyBindingSheetController () <NSOutlineViewDataSource, NSOutlineViewDelegate>

@property (nonatomic) CEKeyBindingType keyBindingsMode;
@property (nonatomic) NSMutableArray *outlineDataArray;
@property (nonatomic) NSMutableArray *usedKeySpecCharsList;  // for duplication check
@property (nonatomic, copy) NSString *currentKeySpecChars;  // saved key spec chars setting for editing action

@property (nonatomic, weak) IBOutlet NSOutlineView *outlineView;
@property (nonatomic, weak) IBOutlet NSTextField *duplicateTextField;
@property (nonatomic, weak) IBOutlet NSButton *factoryDefaultsButton;
@property (nonatomic, weak) IBOutlet NSButton *OKButton;

// only in text key bindings edit sheet
@property (nonatomic, strong) IBOutlet NSTextView *textInsertStringTextView;  // NSTextView cannot be weak on 10.8
@property (nonatomic) IBOutlet NSArrayController *textInsertStringArrayController;

@end




#pragma mark -

@implementation CEKeyBindingSheetController

// ------------------------------------------------------
/// 初期化
- (instancetype)initWithMode:(CEKeyBindingType)mode
// ------------------------------------------------------
{
    NSString *nibName = (mode == CEMenuKeyBindingsType) ? @"MenuKeyBindingEditSheet" : @"TextKeyBindingEditSheet";
    
    self = [super initWithWindowNibName:nibName];
    if (self) {
        _keyBindingsMode = mode;
        
        switch (mode) {
            case CEMenuKeyBindingsType:
                _outlineDataArray = [[CEKeyBindingManager sharedManager] mainMenuArrayForOutlineData:[NSApp mainMenu]];
                _usedKeySpecCharsList = [self keySpecCharsListFromMenu:[NSApp mainMenu]];
                break;
                
            case CETextKeyBindingsType:
                _outlineDataArray = [[CEKeyBindingManager sharedManager] textKeySpecCharArrayForOutlineDataWithFactoryDefaults:NO];
                _usedKeySpecCharsList = [_outlineDataArray mutableCopy];  // （システム標準のキーバインディングとの重複は、チェックしない）
                break;
        }
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
    
    [[self duplicateTextField] setStringValue:@""];
    
    switch ([self keyBindingsMode]) {
        case CEMenuKeyBindingsType:
        {
            BOOL usesDefault = [[CEKeyBindingManager sharedManager] usesDefaultMenuKeyBindings];
            
            // ダブルクリックでトグルに展開するようアクションを設定する
            [[self outlineView] setDoubleAction:@selector(toggleOutlineItemExpand:)];
            [[self outlineView] setTarget:self];
            
            [[self factoryDefaultsButton] setEnabled:!usesDefault];
            [[self outlineView] reloadData];
            // 現在の設定がデフォルト設定ならばデフォルト値を入力する
            if (usesDefault) {
                [self setToFactoryDefaults:nil];
            }
        }
            break;
            
        case CETextKeyBindingsType:
        {
            NSArray *insertTextArray = [[NSUserDefaults standardUserDefaults] stringArrayForKey:CEDefaultInsertCustomTextArrayKey];
            NSArray *factoryDefault = [[[NSUserDefaults alloc] init] volatileDomainForName:NSRegistrationDomain][CEDefaultInsertCustomTextArrayKey];
            NSMutableArray *content = [NSMutableArray array];
            
            [[self factoryDefaultsButton] setEnabled:(![[self outlineDataArray] isEqualToArray:[self usedKeySpecCharsList]] ||
                                                      ![factoryDefault isEqualToArray:insertTextArray])];
            [[self outlineView] reloadData];
            for (NSString *object in insertTextArray) {
                [content addObject:[@{CEDefaultInsertCustomTextKey: object} mutableCopy]];
            }
            [[self textInsertStringArrayController] setContent:content];
            [[self textInsertStringArrayController] setSelectionIndex:NSNotFound]; // 選択なし
            [[self textInsertStringTextView] setEditable:NO];
            [[self textInsertStringTextView] setBackgroundColor:[NSColor controlHighlightColor]];
        }
            break;
    }
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(addCatchedMenuShortcutString:)
                                                 name:CEDidCatchMenuShortcutNotification
                                               object:[self window]];
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
    NSArray *children = item ? item[CEKeyBindingChildrenKey] : [self outlineDataArray];
    
    return [children count];
}


// ------------------------------------------------------
/// アイテムが展開可能かどうかを返す
- (BOOL)outlineView:(NSOutlineView *)outlineView isItemExpandable:(id)item
// ------------------------------------------------------
{
    NSArray *children = item ? item[CEKeyBindingChildrenKey] : [self outlineDataArray];
    
    return (children);
}


// ------------------------------------------------------
/// 子アイテムオブジェクトを返す
- (id)outlineView:(NSOutlineView *)outlineView child:(NSInteger)index ofItem:(id)item
// ------------------------------------------------------
{
    NSArray *children = item ? item[CEKeyBindingChildrenKey] : [self outlineDataArray];
    
    return children[index];
}


// ------------------------------------------------------
/// コラムに応じたオブジェクト(表示文字列)を返す
- (id)outlineView:(NSOutlineView *)outlineView objectValueForTableColumn:(NSTableColumn *)tableColumn byItem:(id)item
// ------------------------------------------------------
{
    NSString *identifier = [tableColumn identifier];
    
    if ([identifier isEqualToString:CEKeyBindingKeySpecCharsKey]) {
        return [CEKeyBindingManager printableKeyStringFromKeySpecChars:item[identifier]];
    }
    
    return item[identifier];
}


// ------------------------------------------------------
/// コラム編集直前、キー入力を取得するようにしてから許可を出す
- (BOOL)outlineView:(NSOutlineView *)outlineView shouldEditTableColumn:(NSTableColumn *)tableColumn item:(id)item
// ------------------------------------------------------
{
    NSString *identifier = [tableColumn identifier];
    
    if (![identifier isEqualToString:CEKeyBindingKeySpecCharsKey] || item[CEKeyBindingChildrenKey]) {
        return NO;
    }
    
    if (![self currentKeySpecChars]) {
        // （値が既にセットされている時は更新しない）
        [self setCurrentKeySpecChars:item[identifier]];
    }
    [(CEKeyBindingSheet *)[self window] setKeyCatchMode:CECatchMenuShortCutMode];
    
    return YES;
}


// ------------------------------------------------------
/// データをセット
- (void)outlineView:(NSOutlineView *)outlineView setObjectValue:(id)object forTableColumn:(NSTableColumn *)tableColumn byItem:(id)item
// ------------------------------------------------------
{
    NSString *identifier = [tableColumn identifier];
    
    // 現在の表示値との比較
    if ([object isEqualToString:[self outlineView:outlineView objectValueForTableColumn:tableColumn byItem:item]]) {
        // データソースの値でなく表示値がそのまま入ってきているのは、選択状態になったあと何の編集もされなかった時
        if (([[NSApp currentEvent] type] == NSLeftMouseDown) &&
            ([[[self duplicateTextField] stringValue] length] > 0))
        {
            item[identifier] = @"";
            [[self duplicateTextField] setStringValue:@""];
            [self validateKeySpecChars:@"" oldChars:[self currentKeySpecChars]];
        }
        
    } else {
        // 現在の表示値と違っていたら、セット
        item[identifier] = object;
        // 無効な値だったら再び編集状態にする
        if (![self validateKeySpecChars:object oldChars:[self currentKeySpecChars]]) {
            __unsafe_unretained typeof(self) weakSelf = self;  // cannot be weak on Lion
            dispatch_async(dispatch_get_main_queue(), ^{
                typeof(self) strongSelf = weakSelf;
                [strongSelf performEditSelectedBindingKeyColumn];
            });
        }
    }
    
    [self setCurrentKeySpecChars:nil];
}



#pragma mark Delegate and Notification

//=======================================================
// Delegate method (NSOutlineView)
//  <== outlineView
//=======================================================

// ------------------------------------------------------
/// 選択行の変更を許可
- (BOOL)outlineView:(NSOutlineView *)outlineView shouldSelectItem:(id)item
// ------------------------------------------------------
{
    // キー取得を停止
    [(CEKeyBindingSheet *)[self window] setKeyCatchMode:CEKeyDownNoCatchMode];
    
    // テキストのバインディングを編集している時は挿入文字列配列コントローラの選択オブジェクトを変更
    if ([self keyBindingsMode] == CETextKeyBindingsType) {
        BOOL isEnabled = [item[CEKeyBindingSelectorStringKey] hasPrefix:@"insertCustomText"];
        NSUInteger index = [outlineView rowForItem:item];
        
        [[self textInsertStringArrayController] setSelectionIndex:index];
        [[self textInsertStringTextView] setEditable:isEnabled];
        NSColor *color = isEnabled ? [NSColor controlBackgroundColor] : [NSColor controlHighlightColor];
        [[self textInsertStringTextView] setBackgroundColor:color];
    }
    
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
    [self performEditSelectedBindingKeyColumn];
}


// ------------------------------------------------------
/// キーバインディングを出荷時設定に戻す
- (IBAction)setToFactoryDefaults:(id)sender
// ------------------------------------------------------
{
    switch ([self keyBindingsMode]) {
        case CEMenuKeyBindingsType:
        {
            [self resetKeySpecCharsToFactoryDefaults:[self outlineDataArray]];
            [self setUsedKeySpecCharsList:[[self keySpecCharsListFromOutlineData:[self outlineDataArray]] mutableCopy]];
        }
            break;
            
        case CETextKeyBindingsType:
        {
            NSMutableArray *contents = [NSMutableArray array];
            NSArray *defaultInsertTexts = [[[NSUserDefaults alloc] init] volatileDomainForName:NSRegistrationDomain][CEDefaultInsertCustomTextArrayKey];
            
            for (id object in defaultInsertTexts) {
                [contents addObject:[@{CEDefaultInsertCustomTextKey: object} mutableCopy]];
            }
            [self setOutlineDataArray:[[CEKeyBindingManager sharedManager] textKeySpecCharArrayForOutlineDataWithFactoryDefaults:YES]];
            [self setUsedKeySpecCharsList:[[self outlineDataArray] mutableCopy]];
            [[self textInsertStringArrayController] setContent:contents];
            [[self textInsertStringArrayController] setSelectionIndex:NSNotFound]; // 選択なし
            [[self textInsertStringTextView] setEditable:NO];
            [[self textInsertStringTextView] setBackgroundColor:[NSColor controlHighlightColor]];
        }
            break;
    }
    
    [[self factoryDefaultsButton] setEnabled:NO];
    [[self outlineView] deselectAll:nil];
    [[self outlineView] reloadData];
}


// ------------------------------------------------------
/// キーバインディング編集シートの OK / Cancel ボタンが押された
- (IBAction)closeSheet:(id)sender
// ------------------------------------------------------
{
    // フォーカスを移して入力中の値を確定
    [[self window] makeFirstResponder:sender];
    // キー入力取得を停止
    [(CEKeyBindingSheet *)[self window] setKeyCatchMode:CEKeyDownNoCatchMode];
    
    if (sender == [self OKButton]) { // ok のときデータを保存、反映させる
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
- (IBAction)toggleOutlineItemExpand:(id)sender
// ------------------------------------------------------
{
    NSInteger selectedRow = [[self outlineView] selectedRow];
    
    if (selectedRow == -1) { return; }
    
    id item = [[self outlineView] itemAtRow:selectedRow];
    
    // ダブルクリックでトグルに展開する
    if ([[self outlineView] isExpandable:item]) {
        [[self outlineView] expandItem:item];
    } else {
        [[self outlineView] collapseItem:item];
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
    NSDictionary *userInfo = [notification userInfo];
    NSUInteger modifierFlags = [userInfo[CEKeyBindingModifierFlagsKey] unsignedIntegerValue];
    NSString *charsIgnoringModifiers = userInfo[CEKeyBindingCharsKey];
    NSString *fieldString = [CEKeyBindingManager keySpecCharsFromKeyEquivalent:charsIgnoringModifiers
                                                                 modifierFrags:modifierFlags];
    fieldString = ([fieldString isEqualToString:@"\b"]) ? @"" : fieldString;  // NSDeleteCharacter単独は削除扱い
    NSText *fieldEditor = [[self window] fieldEditor:NO forObject:[self outlineView]];
    
    [fieldEditor setString:fieldString];
    [[self window] endEditingFor:fieldEditor];
    [[self window] makeFirstResponder:[self outlineView]];
}


//------------------------------------------------------
/// 重複などの警告メッセージを表示
- (BOOL)validateKeySpecChars:(NSString *)keySpec oldChars:(NSString *)oldSpec
//------------------------------------------------------
{
    if (![self usedKeySpecCharsList] || !keySpec) { return NO; }
    
    NSString *warning = nil;
    
    if ([keySpec isEqualToString:@""]) {
        // 空文字（入力なし = 削除された）の場合はスルー
        
    } else if (![keySpec isEqualToString:oldSpec] && [[self usedKeySpecCharsList] containsObject:keySpec]) {
        // 他のキーバインディングと重複している時
        warning = @"“%@” has already been used. Edit it again.";
        
    } else {
        // コマンドキーの存在チェック
        NSUInteger cmdLocation = [keySpec rangeOfString:@"@"].location;
        BOOL containsCmd = ((cmdLocation != NSNotFound) && (cmdLocation != ([keySpec length] - 1)));
        
        // モードとコマンドキーの有無が合致しなければメッセージ表示
        if (([self keyBindingsMode] == CEMenuKeyBindingsType) && !containsCmd) {
            warning = @"“%@” does NOT include Command key. Edit it again.";
            
        } else if (([self keyBindingsMode] == CETextKeyBindingsType) && containsCmd) {
            warning = @"“%@” includes Command key. Edit it again.";
        }
    }
    
    // 警告がある場合は表示して抜ける
    if (warning) {
        NSString *printableKey = [CEKeyBindingManager printableKeyStringFromKeySpecChars:keySpec];
        
        [[self duplicateTextField] setStringValue:[NSString stringWithFormat:NSLocalizedString(warning, nil), printableKey]];
        [[self OKButton] setEnabled:NO];
        
        NSBeep();
        return NO;
    }
    
    // メッセージ消去
    [[self duplicateTextField] setStringValue:@""];
    [[self OKButton] setEnabled:YES];
    
    // 重複チェック配列更新
    if (![keySpec isEqualToString:oldSpec]) {
        if (([oldSpec length] > 0)) {
            [[self usedKeySpecCharsList] removeObject:oldSpec];
        }
        if (([keySpec length] > 0)) {
            [[self usedKeySpecCharsList] addObject:keySpec];
        }
    }

    return YES;
}


//------------------------------------------------------
/// キーを選択状態にする
- (void)performEditSelectedBindingKeyColumn
//------------------------------------------------------
{
    NSInteger selectedRow = [[self outlineView] selectedRow];
    
    if (selectedRow == -1) { return; }
    
    id item = [[self outlineView] itemAtRow:selectedRow];
    NSTableColumn *column = [[self outlineView] tableColumnWithIdentifier:CEKeyBindingKeySpecCharsKey];
    
    if ([self outlineView:[self outlineView] shouldEditTableColumn:column item:item]) {
        [[self outlineView] editColumn:[[self outlineView] columnWithIdentifier:CEKeyBindingKeySpecCharsKey]
                                   row:selectedRow withEvent:nil select:YES];
    }
}


//------------------------------------------------------
/// 重複チェック用配列を生成
- (NSMutableArray *)keySpecCharsListFromMenu:(NSMenu *)menu
//------------------------------------------------------
{
    NSMutableArray *keySpecCharsList = [NSMutableArray array];
    
    for (NSMenuItem *item in [menu itemArray]) {
        if ([item hasSubmenu]) {
            NSArray *childList = [self keySpecCharsListFromMenu:[item submenu]];
            [keySpecCharsList addObjectsFromArray:childList];
            continue;
        }
        NSString *keyEquivalent = [item keyEquivalent];
        if ([keyEquivalent length] > 0) {
            NSUInteger modifierFlags = [item keyEquivalentModifierMask];
            NSString *keySpecChars = [CEKeyBindingManager keySpecCharsFromKeyEquivalent:keyEquivalent
                                                                          modifierFrags:modifierFlags];
            if ([keySpecChars length] > 1) {
                [keySpecCharsList addObject:keySpecChars];
            }
        }
    }
    return keySpecCharsList;
}


//------------------------------------------------------
/// 重複チェック用配列を生成
- (NSArray *)keySpecCharsListFromOutlineData:(NSArray *)outlineArray
//------------------------------------------------------
{
    NSMutableArray *keySpecCharsList = [NSMutableArray array];
    
    for (NSDictionary *item in outlineArray) {
        NSArray *children = item[CEKeyBindingChildrenKey];
        if (children) {
            NSArray *childList = [self keySpecCharsListFromOutlineData:children];
            [keySpecCharsList addObjectsFromArray:childList];
        }
        NSString *keySpecChars = item[CEKeyBindingKeySpecCharsKey];
        if (([keySpecChars length] > 0) && ![keySpecCharsList containsObject:keySpecChars]) {
            [keySpecCharsList addObject:keySpecChars];
        }
    }
    return keySpecCharsList;
}


//------------------------------------------------------
/// 配列中のキーバインディング設定文字列をデフォルトに戻す
- (void)resetKeySpecCharsToFactoryDefaults:(NSMutableArray *)outlineArray
//------------------------------------------------------
{
    for (NSMutableDictionary *item in outlineArray) {
        NSMutableArray *children = item[CEKeyBindingChildrenKey];
        if (children) {
            [self resetKeySpecCharsToFactoryDefaults:children];
        }
        NSString *selectorStr = item[CEKeyBindingSelectorStringKey];
        NSString *keySpecChars = [[CEKeyBindingManager sharedManager] keySpecCharsInDefaultDictionaryFromSelectorString:selectorStr];
        item[CEKeyBindingKeySpecCharsKey] = keySpecChars;
    }
}

@end
