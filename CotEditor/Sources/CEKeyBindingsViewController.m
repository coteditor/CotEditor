/*
 
 CEKeyBindingsViewController.m
 
 CotEditor
 http://coteditor.com
 
 Created by 1024jp on 2014-08-20.

 ------------------------------------------------------------------------------
 
 © 2014-2016 1024jp
 
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

#import "CEKeyBindingsViewController.h"
#import "CEMenuKeyBindingManager.h"
#import "CESnippetKeyBindingManager.h"
#import "CEKeyBindingUtils.h"


static NSString *_Nonnull const InsertCustomTextKey = @"insertCustomText";


@interface CEKeyBindingsViewController () <NSOutlineViewDataSource, NSOutlineViewDelegate, NSTextFieldDelegate, NSTextViewDelegate>

@property (nonatomic) KeyBindingsViewType mode;
@property (nonatomic, nonnull) NSMutableArray *outlineData;
@property (nonatomic, nullable, copy) NSString *warningMessage;  // for binding
@property (nonatomic, getter=isRestoreble) BOOL restoreble;  // for binding

@property (nonatomic, nullable, weak) IBOutlet NSOutlineView *outlineView;

// only in text key bindings edit sheet
@property (nonatomic, nullable) IBOutlet NSArrayController *snippetArrayController;
@property (nonatomic) NSArray *snippets;

@end




#pragma mark -

@implementation CEKeyBindingsViewController

#pragma mark Window Controller Methods

// ------------------------------------------------------
/// initialize
- (nonnull instancetype)initWithMode:(KeyBindingsViewType)mode
// ------------------------------------------------------
{
    self = [super initWithNibName:nil bundle:nil];
    if (self) {
        _mode = mode;
        _outlineData = [[self manager] keySpecCharsListForOutlineDataWithFactoryDefaults:NO];
        _restoreble = ![[self manager] usesDefaultKeyBindings];
        
        if (mode == KeyBindingsViewTypeText) {
            [self setupSnipetts:[[CESnippetKeyBindingManager sharedManager] snippetsWithFactoryDefaults:NO]];
        }
    }
    return self;
}


// ------------------------------------------------------
/// change nib by mode
- (nullable NSString *)nibName
// ------------------------------------------------------
{
    switch ([self mode]) {
        case KeyBindingsViewTypeMenu:
            return @"MenuKeyBindingsEditView";
            
        case KeyBindingsViewTypeText:
            return @"TextKeyBindingsEditView";
    }
}


// ------------------------------------------------------
/// finish current editing
- (void)viewWillDisappear
// ------------------------------------------------------
{
    [self commitEditing];
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
    return [self childrenOfItem:item] != nil;
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
        return [CEKeyBindingUtils printableKeyStringFromKeySpecChars:item[identifier]];
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
    if ([self mode] == KeyBindingsViewTypeText) {
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
// NSTextFieldDelegate  < outlineView->ShortcutKeyField
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
    id item = [outlineView itemAtRow:row];
    NSString *keySpecChars = [textField stringValue];
    NSString *oldKeySpecChars = item[CEKeyBindingKeySpecCharsKey];
    NSError *error;
    
    // validate input value
    if ([keySpecChars isEqualToString:@"\e"]) {
        // treat esc key as cancel
        
    } else if ([keySpecChars isEqualToString:[CEKeyBindingUtils printableKeyStringFromKeySpecChars:oldKeySpecChars]]) {  // not edited
        // do nothing
        
    } else if ([[self manager] validateKeySpecChars:keySpecChars oldKeySpecChars:oldKeySpecChars error:&error]) {
        [self setWarningMessage:nil];
        
        // update data
        item[CEKeyBindingKeySpecCharsKey] = keySpecChars;
        [self saveSettings];
        
    } else {
        NSBeep();
        [self setWarningMessage:[@[[error localizedDescription], [error localizedRecoverySuggestion]] componentsJoinedByString:@" "]];
        
        // make text field edit mode again if invalid
        __weak typeof(self) weakSelf = self;
        dispatch_async(dispatch_get_main_queue(), ^{
            typeof(self) self = weakSelf;  // strong self
            
            [self beginEditingSelectedKeyCell];
        });
    }
    
    // reload row to apply printed form of key spec
    NSInteger column = [outlineView columnForView:textField];
    [outlineView reloadDataForRowIndexes:[NSIndexSet indexSetWithIndex:row]
                           columnIndexes:[NSIndexSet indexSetWithIndex:column]];
}


//=======================================================
// NSTextViewDelegate  < insertion text view
//=======================================================

// ------------------------------------------------------
/// insertion text did update
- (void)textDidEndEditing:(NSNotification *)notification
// ------------------------------------------------------
{
    if ([[notification object] isKindOfClass:[NSTextView class]]) {
        [self saveSettings];
    }
}



#pragma mark Action Messages

// ------------------------------------------------------
/// キーバインディングを出荷時設定に戻す
- (IBAction)setToFactoryDefaults:(nullable id)sender
// ------------------------------------------------------
{
    if ([self mode] == KeyBindingsViewTypeText) {
        [self setupSnipetts:[[CESnippetKeyBindingManager sharedManager] snippetsWithFactoryDefaults:YES]];
    }
    
    [self setOutlineData:[[self manager] keySpecCharsListForOutlineDataWithFactoryDefaults:YES]];
    
    [self saveSettings];
    
    [[self outlineView] deselectAll:nil];
    [[self outlineView] reloadData];
    [self setWarningMessage:nil];
}



#pragma mark Private Mthods

//------------------------------------------------------
/// corresponding key binding manager
- (nonnull CEKeyBindingManager *)manager
//------------------------------------------------------
{
    switch ([self mode]) {
        case KeyBindingsViewTypeMenu:
            return [CEMenuKeyBindingManager sharedManager];
            
        case KeyBindingsViewTypeText:
            return [CESnippetKeyBindingManager sharedManager];
    }
}


// ------------------------------------------------------
/// 子アイテムを返す
- (nonnull NSArray<id> *)childrenOfItem:(nullable id)item
// ------------------------------------------------------
{
    return item ? item[CEKeyBindingChildrenKey] : [self outlineData];
}


// ------------------------------------------------------
/// save current settings
- (void)saveSettings
// ------------------------------------------------------
{
    if ([self mode] == KeyBindingsViewTypeText) {
        NSArray<NSString *> *texts = [[self snippets] valueForKey:InsertCustomTextKey];
        [[CESnippetKeyBindingManager sharedManager] saveSnippets:texts];
    }
    
    [[self manager] saveKeyBindings:[self outlineData]];
    [self setRestoreble:![[self manager] usesDefaultKeyBindings]];
}


// ------------------------------------------------------
/// カスタムテキスト設定を arrayController にセットする
- (void)setupSnipetts:(NSArray<NSString *> *)snippets
// ------------------------------------------------------
{
    NSMutableArray<NSMutableDictionary<NSString *, NSString *> *> *content = [NSMutableArray array];
    for (NSString *snippet in snippets) {
        [content addObject:[@{InsertCustomTextKey: snippet} mutableCopy]];
    }
    
    [self setSnippets:content];
}


//------------------------------------------------------
/// キーを選択状態にする
- (void)beginEditingSelectedKeyCell
//------------------------------------------------------
{
    NSInteger selectedRow = [[self outlineView] selectedRow];
    
    if (selectedRow == -1) { return; }
    
    NSInteger column = [[self outlineView] columnWithIdentifier:CEKeyBindingKeySpecCharsKey];
    
    [[self outlineView] editColumn:column row:selectedRow withEvent:nil select:YES];
}

@end
