/*
 ==============================================================================
 CEKeyBindingSheetController
 
 CotEditor
 http://coteditor.com
 
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
#import "constants.h"


@interface CEKeyBindingSheetController () <NSOutlineViewDataSource, NSOutlineViewDelegate, NSTextFieldDelegate>

@property (nonatomic) CEKeyBindingType mode;
@property (nonatomic) NSMutableArray *outlineDataArray;
@property (nonatomic) NSMutableArray *usedKeySpecCharsList;  // for duplication check
@property (nonatomic, copy) NSString *warningMessage;
@property (nonatomic, getter=isRestoreble) BOOL restoreble;

@property (nonatomic, weak) IBOutlet NSOutlineView *outlineView;
@property (nonatomic, weak) IBOutlet NSButton *OKButton;

// only in text key bindings edit sheet
@property (nonatomic) IBOutlet NSArrayController *snippetTextArrayController;

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
        _mode = mode;
        
        switch (mode) {
            case CEMenuKeyBindingsType:
                _outlineDataArray = [[CEKeyBindingManager sharedManager] mainMenuArrayForOutlineData:[NSApp mainMenu]];
                _usedKeySpecCharsList = [self keySpecCharsListFromMenu:[NSApp mainMenu]];
                _restoreble = ![[CEKeyBindingManager sharedManager] usesDefaultMenuKeyBindings];
                break;
                
            case CETextKeyBindingsType:
            {
                NSArray *factoryDefault = [[[NSUserDefaults alloc] init] volatileDomainForName:NSRegistrationDomain][CEDefaultInsertCustomTextArrayKey];
                NSArray *insertTextArray = [[NSUserDefaults standardUserDefaults] stringArrayForKey:CEDefaultInsertCustomTextArrayKey];
                
                _outlineDataArray = [[CEKeyBindingManager sharedManager] textKeySpecCharArrayForOutlineDataWithFactoryDefaults:NO];
                _usedKeySpecCharsList = [self keySpecCharsListFromOutlineData:_outlineDataArray];
                _restoreble = ![factoryDefault isEqualToArray:insertTextArray];
                break;
            }
        }
    }
    return self;
}


// ------------------------------------------------------
/// ウインドウ読み込み直後
- (void)windowDidLoad
// ------------------------------------------------------
{
    [super windowDidLoad];
    
    switch ([self mode]) {
        case CEMenuKeyBindingsType:
            // toggle item expand by double-clicking
            [[self outlineView] setDoubleAction:@selector(toggleOutlineItemExpand:)];
            [[self outlineView] setTarget:self];
            break;
            
        case CETextKeyBindingsType:
        {
            NSArray *insertTexts = [[NSUserDefaults standardUserDefaults] stringArrayForKey:CEDefaultInsertCustomTextArrayKey];
            NSMutableArray *content = [NSMutableArray array];
            
            for (NSString *text in insertTexts) {
                [content addObject:[@{CEDefaultInsertCustomTextKey: text} mutableCopy]];
            }
            [[self snippetTextArrayController] setContent:content];
        }
            break;
    }
}



#pragma mark Protocol

//=======================================================
// NSOutlineViewDataSource Protocol
//  <== outlineView
//=======================================================

// ------------------------------------------------------
/// 子アイテムの数を返す
- (NSInteger)outlineView:(NSOutlineView *)outlineView numberOfChildrenOfItem:(id)item
// ------------------------------------------------------
{
    return [[self childrenOfItem:item] count];
}


// ------------------------------------------------------
/// アイテムが展開可能かどうかを返す
- (BOOL)outlineView:(NSOutlineView *)outlineView isItemExpandable:(id)item
// ------------------------------------------------------
{
    return ([self childrenOfItem:item]);
}


// ------------------------------------------------------
/// 子アイテムオブジェクトを返す
- (id)outlineView:(NSOutlineView *)outlineView child:(NSInteger)index ofItem:(id)item
// ------------------------------------------------------
{
    return [self childrenOfItem:item][index];
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
/// コラムに応じたオブジェクト(表示文字列)をセットして返す
- (NSView *)outlineView:(NSOutlineView *)outlineView viewForTableColumn:(NSTableColumn *)tableColumn item:(id)item
// ------------------------------------------------------
{
    NSString *identifier = [tableColumn identifier];
    NSTableCellView *cellView = [outlineView makeViewWithIdentifier:identifier owner:self];
    NSString *content = [self outlineView:outlineView objectValueForTableColumn:tableColumn byItem:item];
    
    [[cellView textField] setStringValue:content];
    
    return cellView;
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
    // テキストのバインディングを編集している時は挿入文字列配列コントローラの選択オブジェクトを変更
    if ([self mode] == CETextKeyBindingsType) {
        NSUInteger index = [outlineView rowForItem:item];
        
        [[self snippetTextArrayController] setSelectionIndex:index];
    }
    
    return YES;
}


// ------------------------------------------------------
// テーブルセルが編集可能かを設定する
- (void)outlineView:(NSOutlineView *)outlineView didAddRowView:(NSTableRowView *)rowView forRow:(NSInteger)row
// ------------------------------------------------------
{
    id item = [outlineView itemAtRow:row];
    
    if ([outlineView isExpandable:item]) {
        NSTableCellView *cellView = [rowView viewAtColumn:[outlineView columnWithIdentifier:CEKeyBindingKeySpecCharsKey]];
        [[cellView textField] setEditable:NO];
    }
}


//=======================================================
// Delegate method (NSTextField)
//  <== outlineView->CEShortcutKeyField
//=======================================================

// ------------------------------------------------------
/// データをセット
- (void)controlTextDidEndEditing:(NSNotification *)obj
// ------------------------------------------------------
{
    if (![[obj object] isKindOfClass:[NSTextField class]]) { return; }
    
    NSOutlineView *outlineView = [self outlineView];
    NSTextField *textField = (NSTextField *)[obj object];
    NSInteger row = [outlineView rowForView:textField];
    NSInteger column = [outlineView columnWithIdentifier:CEKeyBindingKeySpecCharsKey];
    NSTableColumn *tableColumn = [outlineView tableColumnWithIdentifier:CEKeyBindingKeySpecCharsKey];
    id item = [outlineView itemAtRow:row];
    NSString *keySpecChars = [textField stringValue];
    NSString *oldChars = item[CEKeyBindingKeySpecCharsKey];
    
    // 現在の表示値との比較
    if ([keySpecChars isEqualToString:[self outlineView:outlineView objectValueForTableColumn:tableColumn byItem:item]]) {
        // データソースの値でなく表示値がそのまま入ってきているのは、選択状態になったあと何の編集もされなかった時
        if (([[NSApp currentEvent] type] == NSLeftMouseDown) && [self warningMessage]) {
            item[CEKeyBindingKeySpecCharsKey] = @"";
            [self setWarningMessage:nil];
            [self validateKeySpecChars:@"" oldChars:oldChars];
        }
        
    } else {
        // 現在の表示値と違っていたら、セット
        BOOL isValid = [self validateKeySpecChars:keySpecChars oldChars:oldChars];
        
        item[CEKeyBindingKeySpecCharsKey] = isValid ? keySpecChars : oldChars;  // reset if invalid
        
        // reload row to apply printed form of key spec
        [outlineView reloadDataForRowIndexes:[NSIndexSet indexSetWithIndex:row]
                               columnIndexes:[NSIndexSet indexSetWithIndex:column]];
        
        // 無効な値だったら再び編集状態にする
        if (!isValid) {
            __weak typeof(self) weakSelf = self;
            dispatch_async(dispatch_get_main_queue(), ^{
                typeof(self) strongSelf = weakSelf;
                [strongSelf performEditSelectedBindingKeyColumn];
            });
        }
    }
}



#pragma mark Action Messages

//=======================================================
// Action messages
//
//=======================================================

// ------------------------------------------------------
/// キーバインディングを出荷時設定に戻す
- (IBAction)setToFactoryDefaults:(id)sender
// ------------------------------------------------------
{
    switch ([self mode]) {
        case CEMenuKeyBindingsType:
            [self resetKeySpecCharsToFactoryDefaults:[self outlineDataArray]];
            break;
            
        case CETextKeyBindingsType:
        {
            NSMutableArray *contents = [NSMutableArray array];
            NSArray *defaultInsertTexts = [[[NSUserDefaults alloc] init] volatileDomainForName:NSRegistrationDomain][CEDefaultInsertCustomTextArrayKey];
            
            for (id object in defaultInsertTexts) {
                [contents addObject:[@{CEDefaultInsertCustomTextKey: object} mutableCopy]];
            }
            [self setOutlineDataArray:[[CEKeyBindingManager sharedManager] textKeySpecCharArrayForOutlineDataWithFactoryDefaults:YES]];
            [[self snippetTextArrayController] setContent:contents];
            [[self snippetTextArrayController] setSelectionIndex:NSNotFound]; // 選択なし
        }
            break;
    }
    
    [self setUsedKeySpecCharsList:[self keySpecCharsListFromOutlineData:[self outlineDataArray]]];
    [self setRestoreble:NO];
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
    
    if (sender == [self OKButton]) { // ok のときデータを保存、反映させる
        switch ([self mode]) {
            case CEMenuKeyBindingsType:
                [[CEKeyBindingManager sharedManager] saveMenuKeyBindings:[self outlineDataArray]];
                break;
                
            case CETextKeyBindingsType:
                [[CEKeyBindingManager sharedManager] saveTextKeyBindings:[self outlineDataArray]
                                                                   texts:[[self snippetTextArrayController] content]];
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

// ------------------------------------------------------
/// 子アイテムを返す
- (NSArray *)childrenOfItem:(id)item
// ------------------------------------------------------
{
    return item ? item[CEKeyBindingChildrenKey] : [self outlineDataArray];
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
        warning = NSLocalizedString(@"“%@” has already been used. Edit it again.", nil);
        
    } else {
        // コマンドキーの存在チェック
        BOOL containsCmd = ([keySpec rangeOfString:@"@"].location != NSNotFound);
        
        // モードとコマンドキーの有無が合致しなければメッセージ表示
        if (([self mode] == CEMenuKeyBindingsType) && !containsCmd) {
            warning = NSLocalizedString(@"“%@” does NOT include Command key. Edit it again.", nil);
            
        } else if (([self mode] == CETextKeyBindingsType) && containsCmd) {
            warning = NSLocalizedString(@"“%@” includes Command key. Edit it again.", nil);
        }
    }
    
    // 警告がある場合は表示して抜ける
    if (warning) {
        NSString *printableKey = [CEKeyBindingManager printableKeyStringFromKeySpecChars:keySpec];
        
        [self setWarningMessage:[NSString stringWithFormat:warning, printableKey]];
        [[self OKButton] setEnabled:NO];
        
        NSBeep();
        return NO;
    }
    
    // メッセージ消去
    [self setWarningMessage:nil];
    [[self OKButton] setEnabled:YES];
    
    // 重複チェック配列更新
    if (![keySpec isEqualToString:oldSpec]) {
        if ([oldSpec length] > 0) {
            [[self usedKeySpecCharsList] removeObject:oldSpec];
        }
        if ([keySpec length] > 0) {
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
    NSInteger *column = [[self outlineView] columnWithIdentifier:CEKeyBindingKeySpecCharsKey];
    
    [[self outlineView] editColumn:column row:selectedRow withEvent:nil select:YES];
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
- (NSMutableArray *)keySpecCharsListFromOutlineData:(NSArray *)outlineArray
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
