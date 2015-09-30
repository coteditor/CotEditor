/*
 
 CEKeyBindingsSheetController.m
 
 CotEditor
 http://coteditor.com
 
 Created by 1024jp on 2014-08-20.

 ------------------------------------------------------------------------------
 
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

#import "CEKeyBindingsSheetController.h"
#import "CEKeyBindingManager.h"
#import "Constants.h"


@interface CEKeyBindingsSheetController () <NSOutlineViewDataSource, NSOutlineViewDelegate, NSTextFieldDelegate>

@property (nonatomic) CEKeyBindingType mode;
@property (nonatomic, nonnull) NSMutableArray *outlineData;
@property (nonatomic, nullable, copy) NSString *warningMessage;  // for binding
@property (nonatomic, getter=isRestoreble) BOOL restoreble;  // for binding

@property (nonatomic, nullable, weak) IBOutlet NSOutlineView *outlineView;
@property (nonatomic, nullable, weak) IBOutlet NSButton *OKButton;

// only in text key bindings edit sheet
@property (nonatomic, nullable) IBOutlet NSArrayController *snippetArrayController;

@end




#pragma mark -

@implementation CEKeyBindingsSheetController

#pragma mark Window Controller Methods

// ------------------------------------------------------
/// initialize
- (nonnull instancetype)initWithMode:(CEKeyBindingType)mode
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
                _outlineData = [[CEKeyBindingManager sharedManager] textKeySpecCharArrayForOutlineDataWithFactoryDefaults:NO];
                _restoreble = ![[CEKeyBindingManager sharedManager] usesDefaultTextKeyBindings];
                break;
        }
    }
    return self;
}


// ------------------------------------------------------
/// setup UI
- (void)windowDidLoad
// ------------------------------------------------------
{
    [super windowDidLoad];
    
    switch ([self mode]) {
        case CEMenuKeyBindingsType:
            // toggle item expand by double-clicking
            [[self outlineView] setDoubleAction:@selector(toggleOutlineItemExpand:)];
            break;
            
        case CETextKeyBindingsType: {
            NSArray<NSString *> *insertTexts = [[NSUserDefaults standardUserDefaults] stringArrayForKey:CEDefaultInsertCustomTextArrayKey];
            NSMutableArray<NSMutableDictionary<NSString *, NSString *> *> *content = [NSMutableArray array];
            
            for (NSString *text in insertTexts) {
                [content addObject:[@{CEDefaultInsertCustomTextKey: text} mutableCopy]];
            }
            [[self snippetArrayController] setContent:content];
        } break;
    }
}



#pragma mark Data Source

//=======================================================
// NSOutlineViewDataSource Protocol  < outlineView
//=======================================================

// ------------------------------------------------------
/// 子アイテムの数を返す
- (NSInteger)outlineView:(nonnull NSOutlineView *)outlineView numberOfChildrenOfItem:(nullable id)item
// ------------------------------------------------------
{
    return [[self childrenOfItem:item] count];
}


// ------------------------------------------------------
/// アイテムが展開可能かどうかを返す
- (BOOL)outlineView:(nonnull NSOutlineView *)outlineView isItemExpandable:(nonnull id)item
// ------------------------------------------------------
{
    return ([self childrenOfItem:item]);
}


// ------------------------------------------------------
/// 子アイテムオブジェクトを返す
- (nonnull id)outlineView:(nonnull NSOutlineView *)outlineView child:(NSInteger)index ofItem:(nullable id)item
// ------------------------------------------------------
{
    return [self childrenOfItem:item][index];
}


// ------------------------------------------------------
/// コラムに応じたオブジェクト(表示文字列)を返す
- (nullable id)outlineView:(nonnull NSOutlineView *)outlineView objectValueForTableColumn:(nullable NSTableColumn *)tableColumn byItem:(nullable id)item
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
- (nullable NSView *)outlineView:(nonnull NSOutlineView *)outlineView viewForTableColumn:(nullable NSTableColumn *)tableColumn item:(nonnull id)item
// ------------------------------------------------------
{
    NSString *identifier = [tableColumn identifier];
    NSTableCellView *cellView = [outlineView makeViewWithIdentifier:identifier owner:self];
    NSString *content = [self outlineView:outlineView objectValueForTableColumn:tableColumn byItem:item];
    
    [[cellView textField] setStringValue:content];
    
    return cellView;
}



#pragma mark Delegate

//=======================================================
// NSOutlineViewDelegate  < outlineView
//=======================================================

// ------------------------------------------------------
/// 選択行の変更を許可
- (BOOL)outlineView:(nonnull NSOutlineView *)outlineView shouldSelectItem:(nonnull id)item
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
/// テーブルセルが編集可能かを設定する
- (void)outlineView:(nonnull NSOutlineView *)outlineView didAddRowView:(nonnull NSTableRowView *)rowView forRow:(NSInteger)row
// ------------------------------------------------------
{
    id item = [outlineView itemAtRow:row];
    
    if ([outlineView isExpandable:item]) {
        NSTableCellView *cellView = [rowView viewAtColumn:[outlineView columnWithIdentifier:CEKeyBindingKeySpecCharsKey]];
        [[cellView textField] setEditable:NO];
    }
}


//=======================================================
// NSTextFieldDelegate  < outlineView->CEShortcutKeyField
//=======================================================

// ------------------------------------------------------
/// データをセット
- (void)controlTextDidEndEditing:(nonnull NSNotification *)obj
// ------------------------------------------------------
{
    if (![[obj object] isKindOfClass:[NSTextField class]]) { return; }
    
    NSOutlineView *outlineView = [self outlineView];
    NSTextField *textField = (NSTextField *)[obj object];
    NSInteger row = [outlineView rowForView:textField];
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
            typeof(self) self = weakSelf;  // strong self
            
            [self performEditSelectedBindingKeyColumn];
        });
    }
    
    // reload row to apply printed form of key spec
    NSInteger column = [outlineView columnForView:textField];
    [outlineView reloadDataForRowIndexes:[NSIndexSet indexSetWithIndex:row]
                           columnIndexes:[NSIndexSet indexSetWithIndex:column]];
}



#pragma mark Action Messages

// ------------------------------------------------------
/// キーバインディングを出荷時設定に戻す
- (IBAction)setToFactoryDefaults:(nullable id)sender
// ------------------------------------------------------
{
    switch ([self mode]) {
        case CEMenuKeyBindingsType:
            [self resetKeySpecCharsToFactoryDefaults:[self outlineData]];
            break;
            
        case CETextKeyBindingsType: {
            NSMutableArray<NSMutableDictionary<NSString *, id> *> *content = [NSMutableArray array];
            NSArray<NSString *> *defaultInsertTexts = [[[NSUserDefaults alloc] init] volatileDomainForName:NSRegistrationDomain][CEDefaultInsertCustomTextArrayKey];
            
            for (id object in defaultInsertTexts) {
                [content addObject:[@{CEDefaultInsertCustomTextKey: object} mutableCopy]];
            }
            [self setOutlineData:[[CEKeyBindingManager sharedManager] textKeySpecCharArrayForOutlineDataWithFactoryDefaults:YES]];
            [[self snippetArrayController] setContent:content];
            [[self snippetArrayController] setSelectionIndex:NSNotFound];
        } break;
    }
    
    [self setRestoreble:NO];
    [[self outlineView] deselectAll:nil];
    [[self outlineView] reloadData];
}


// ------------------------------------------------------
/// キーバインディング編集シートの OK / Cancel ボタンが押された
- (IBAction)closeSheet:(nullable id)sender
// ------------------------------------------------------
{
    // end current editing progress
    [[self window] makeFirstResponder:sender];
    
    if (sender == [self OKButton]) { // save with OK button
        [self saveSettings];
    }
    
    // close sheet
    [NSApp stopModal];
}


//------------------------------------------------------
/// アウトラインビューの行がダブルクリックされた
- (IBAction)toggleOutlineItemExpand:(nullable id)sender
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

// ------------------------------------------------------
/// save current settings
- (void)saveSettings
// ------------------------------------------------------
{
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


// ------------------------------------------------------
/// 子アイテムを返す
- (nonnull NSArray<id> *)childrenOfItem:(id)item
// ------------------------------------------------------
{
    return item ? item[CEKeyBindingChildrenKey] : [self outlineData];
}


//------------------------------------------------------
/// 重複などの警告メッセージを表示
- (BOOL)validateKeySpecChars:(nonnull NSString *)keySpec oldChars:(nonnull NSString *)oldSpec
//------------------------------------------------------
{
    // clear error
    [self setWarningMessage:nil];
    [[self OKButton] setEnabled:YES];
    
    // blank key is always valid
    if ([keySpec length] == 0) { return YES; }
    
    NSString *warning = nil;
    NSArray<NSString *> *registeredKeySpecChars = [self keySpecCharsListFromOutlineData:[self outlineData]];
    
    if (![keySpec isEqualToString:oldSpec] && [registeredKeySpecChars containsObject:keySpec]) {
        // duplication check
        warning = NSLocalizedString(@"“%@” is already taken. Please choose another key.", nil);
        
    } else {
        // command key existance check
        BOOL containsCmd = ([keySpec rangeOfString:@"@"].location != NSNotFound);
        
        // command key and mode matching check
        if (([self mode] == CEMenuKeyBindingsType) && !containsCmd) {
            warning = NSLocalizedString(@"“%@” does not include the Command key. Please choose another key.", nil);
            
        } else if (([self mode] == CETextKeyBindingsType) && containsCmd) {
            warning = NSLocalizedString(@"“%@” includes the Command key. Please choose another key.", nil);
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
- (nonnull NSMutableArray<NSString *> *)keySpecCharsListFromOutlineData:(nonnull NSArray<NSDictionary *> *)outlineArray
//------------------------------------------------------
{
    NSMutableArray *keySpecCharsList = [NSMutableArray array];
    
    for (NSDictionary *item in outlineArray) {
        NSArray *children = item[CEKeyBindingChildrenKey];
        if (children) {
            NSArray<NSString *> *childList = [self keySpecCharsListFromOutlineData:children];
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
- (void)resetKeySpecCharsToFactoryDefaults:(nonnull NSMutableArray *)outlineArray
//------------------------------------------------------
{
    for (NSMutableDictionary *item in outlineArray) {
        NSMutableArray *children = item[CEKeyBindingChildrenKey];
        if (children) {
            [self resetKeySpecCharsToFactoryDefaults:children];
        }
        
        NSString *selector = item[CEKeyBindingSelectorStringKey];
        NSString *keySpecChars = [[CEKeyBindingManager sharedManager] keySpecCharsInDefaultDictionaryFromSelectorString:selector];
        item[CEKeyBindingKeySpecCharsKey] = keySpecChars;
    }
}

@end
