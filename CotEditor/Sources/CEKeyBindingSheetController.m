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
@property (nonatomic) NSMutableArray *outlineData;
@property (nonatomic) NSMutableArray *registeredKeySpecCharsList;  // for duplication check
@property (nonatomic, copy) NSString *warningMessage;  // for binding
@property (nonatomic, getter=isRestoreble) BOOL restoreble;  // for binding

@property (nonatomic, weak) IBOutlet NSOutlineView *outlineView;
@property (nonatomic, weak) IBOutlet NSButton *OKButton;

// only in text key bindings edit sheet
@property (nonatomic) IBOutlet NSArrayController *snippetArrayController;

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
                _outlineData = [[CEKeyBindingManager sharedManager] mainMenuArrayForOutlineData:[NSApp mainMenu]];
                _restoreble = ![[CEKeyBindingManager sharedManager] usesDefaultMenuKeyBindings];
                break;
                
            case CETextKeyBindingsType:
            {
                NSArray *factoryDefault = [[[NSUserDefaults alloc] init] volatileDomainForName:NSRegistrationDomain][CEDefaultInsertCustomTextArrayKey];
                NSArray *insertTextArray = [[NSUserDefaults standardUserDefaults] stringArrayForKey:CEDefaultInsertCustomTextArrayKey];
                
                _outlineData = [[CEKeyBindingManager sharedManager] textKeySpecCharArrayForOutlineDataWithFactoryDefaults:NO];
                _restoreble = ![factoryDefault isEqualToArray:insertTextArray];
                break;
            }
        }
        
        _registeredKeySpecCharsList = [self keySpecCharsListFromOutlineData:_outlineData];
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
            [[self snippetArrayController] setContent:content];
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
        
        [[self snippetArrayController] setSelectionIndex:index];
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
    
    // comapre with current text field value (do nothing if it's not modified)
    if ([keySpecChars isEqualToString:[self outlineView:outlineView objectValueForTableColumn:tableColumn byItem:item]]) { return; }
        
    // validate input value
    if ([keySpecChars isEqualToString:@"\e"]) {
        // treat esc key as cancel
        
    } else if ([self validateKeySpecChars:keySpecChars oldChars:oldChars]) {
        // update data
        item[CEKeyBindingKeySpecCharsKey] = keySpecChars;
        
    } else {
        // make text field edit mode again if invalid
        __weak typeof(self) weakSelf = self;
        dispatch_async(dispatch_get_main_queue(), ^{
            typeof(self) strongSelf = weakSelf;
            [strongSelf performEditSelectedBindingKeyColumn];
        });
    }
    
    // reload row to apply printed form of key spec
    [outlineView reloadDataForRowIndexes:[NSIndexSet indexSetWithIndex:row]
                           columnIndexes:[NSIndexSet indexSetWithIndex:column]];
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
            [self resetKeySpecCharsToFactoryDefaults:[self outlineData]];
            break;
            
        case CETextKeyBindingsType:
        {
            NSMutableArray *contents = [NSMutableArray array];
            NSArray *defaultInsertTexts = [[[NSUserDefaults alloc] init] volatileDomainForName:NSRegistrationDomain][CEDefaultInsertCustomTextArrayKey];
            
            for (id object in defaultInsertTexts) {
                [contents addObject:[@{CEDefaultInsertCustomTextKey: object} mutableCopy]];
            }
            [self setOutlineData:[[CEKeyBindingManager sharedManager] textKeySpecCharArrayForOutlineDataWithFactoryDefaults:YES]];
            [[self snippetArrayController] setContent:contents];
            [[self snippetArrayController] setSelectionIndex:NSNotFound];
        }
            break;
    }
    
    [self setRegisteredKeySpecCharsList:[self keySpecCharsListFromOutlineData:[self outlineData]]];
    [self setRestoreble:NO];
    [[self outlineView] deselectAll:nil];
    [[self outlineView] reloadData];
}


// ------------------------------------------------------
/// キーバインディング編集シートの OK / Cancel ボタンが押された
- (IBAction)closeSheet:(id)sender
// ------------------------------------------------------
{
    // end current editing progress
    [[self window] makeFirstResponder:sender];
    
    if (sender == [self OKButton]) { // save with OK button
        switch ([self mode]) {
            case CEMenuKeyBindingsType:
                [[CEKeyBindingManager sharedManager] saveMenuKeyBindings:[self outlineData]];
                break;
                
            case CETextKeyBindingsType:
                [[CEKeyBindingManager sharedManager] saveTextKeyBindings:[self outlineData]
                                                                   texts:[[self snippetArrayController] content]];
                break;
        }
    }
    
    // close sheet
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
    
    // toggle by double-clicking
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
    return item ? item[CEKeyBindingChildrenKey] : [self outlineData];
}


//------------------------------------------------------
/// 重複などの警告メッセージを表示
- (BOOL)validateKeySpecChars:(NSString *)keySpec oldChars:(NSString *)oldSpec
//------------------------------------------------------
{
    if (![self registeredKeySpecCharsList] || !keySpec) { return NO; }
    
    NSString *warning = nil;
    if ([keySpec length] == 0) {
        // blank key is always valid
        
    } else if (![keySpec isEqualToString:oldSpec] && [[self registeredKeySpecCharsList] containsObject:keySpec]) {
        // duplication check
        warning = NSLocalizedString(@"“%@” has already been used. Edit it again.", nil);
        
    } else {
        // command key existance check
        BOOL containsCmd = ([keySpec rangeOfString:@"@"].location != NSNotFound);
        
        // command key and mode matching check
        if (([self mode] == CEMenuKeyBindingsType) && !containsCmd) {
            warning = NSLocalizedString(@"“%@” does NOT include Command key. Edit it again.", nil);
            
        } else if (([self mode] == CETextKeyBindingsType) && containsCmd) {
            warning = NSLocalizedString(@"“%@” includes Command key. Edit it again.", nil);
        }
    }
    
    // show warning and return
    if (warning) {
        NSString *printableKey = [CEKeyBindingManager printableKeyStringFromKeySpecChars:keySpec];
        
        [self setWarningMessage:[NSString stringWithFormat:warning, printableKey]];
        [[self OKButton] setEnabled:NO];
        
        NSBeep();
        return NO;
    }
    
    // clear error
    [self setWarningMessage:nil];
    [[self OKButton] setEnabled:YES];
    
    // update key spec array for dupliation check
    if (![keySpec isEqualToString:oldSpec]) {
        if ([oldSpec length] > 0) {
            [[self registeredKeySpecCharsList] removeObject:oldSpec];
        }
        if ([keySpec length] > 0) {
            [[self registeredKeySpecCharsList] addObject:keySpec];
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
    
    NSInteger *column = [[self outlineView] columnWithIdentifier:CEKeyBindingKeySpecCharsKey];
    
    [[self outlineView] editColumn:column row:selectedRow withEvent:nil select:YES];
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
