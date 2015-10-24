/*
 
 CEKeyBindingsViewController.m
 
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

#import "CEKeyBindingsViewController.h"
#import "CEKeyBindingManager.h"
#import "Constants.h"


@interface CEKeyBindingsViewController () <NSOutlineViewDataSource, NSOutlineViewDelegate, NSTextFieldDelegate, NSTextViewDelegate>

@property (nonatomic) CEKeyBindingType mode;
@property (nonatomic, nonnull) NSMutableArray *outlineData;
@property (nonatomic, nullable, copy) NSString *warningMessage;  // for binding
@property (nonatomic, getter=isRestoreble) BOOL restoreble;  // for binding

@property (nonatomic, nullable, weak) IBOutlet NSOutlineView *outlineView;

// only in text key bindings edit sheet
@property (nonatomic, nullable) IBOutlet NSArrayController *snippetArrayController;

@end




#pragma mark -

@implementation CEKeyBindingsViewController

#pragma mark Window Controller Methods

// ------------------------------------------------------
/// initialize
- (nonnull instancetype)initWithMode:(CEKeyBindingType)mode
// ------------------------------------------------------
{
    NSString *nibName = (mode == CEMenuKeyBindingsType) ? @"MenuKeyBindingsEditView" : @"TextKeyBindingsEditView";
    
    self = [super initWithNibName:nibName bundle:nil];
    if (self) {
        _mode = mode;
        
        switch (mode) {
            case CEMenuKeyBindingsType:
                _outlineData = [[CEKeyBindingManager sharedManager] menuKeySpecCharsArrayForOutlineDataWithFactoryDefaults:NO];
                _restoreble = ![[CEKeyBindingManager sharedManager] usesDefaultMenuKeyBindings];
                break;
                
            case CETextKeyBindingsType:
                _outlineData = [[CEKeyBindingManager sharedManager] textKeySpecCharsArrayForOutlineDataWithFactoryDefaults:NO];
                _restoreble = ![[CEKeyBindingManager sharedManager] usesDefaultTextKeyBindings];
                break;
        }
    }
    return self;
}


// ------------------------------------------------------
/// setup UI
- (void)viewDidLoad
// ------------------------------------------------------
{
    [super viewDidLoad];
    
    switch ([self mode]) {
        case CEMenuKeyBindingsType:
            // toggle item expand by double-clicking
            [[self outlineView] setDoubleAction:@selector(toggleOutlineItemExpand:)];
            break;
            
        case CETextKeyBindingsType: {
            NSArray<NSString *> *customTexts = [[NSUserDefaults standardUserDefaults] stringArrayForKey:CEDefaultInsertCustomTextArrayKey];
            [self setupCustomTexts:customTexts];
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
    return [[self childrenOfItem:item] count] > 0;
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
    id item = [outlineView itemAtRow:row];
    NSString *keySpecChars = [textField stringValue];
    NSString *oldChars = item[CEKeyBindingKeySpecCharsKey];
        
    // validate input value
    if ([keySpecChars isEqualToString:@"\e"]) {
        // treat esc key as cancel
        
    } else if ([self validateKeySpecChars:keySpecChars oldChars:oldChars]) {
        // update data
        item[CEKeyBindingKeySpecCharsKey] = keySpecChars;
        
        // save settings
        [self saveSettings];
        
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
    switch ([self mode]) {
        case CEMenuKeyBindingsType:
            [self setOutlineData:[[CEKeyBindingManager sharedManager] menuKeySpecCharsArrayForOutlineDataWithFactoryDefaults:YES]];
            break;
            
        case CETextKeyBindingsType: {
            [self setOutlineData:[[CEKeyBindingManager sharedManager] textKeySpecCharsArrayForOutlineDataWithFactoryDefaults:YES]];
            
            NSArray<NSString *> *defaultCustomTexts = [[[NSUserDefaults alloc] init] volatileDomainForName:NSRegistrationDomain][CEDefaultInsertCustomTextArrayKey];
            [self setupCustomTexts:defaultCustomTexts];
        } break;
    }
    
    [self saveSettings];
    
    [[self outlineView] deselectAll:nil];
    [[self outlineView] reloadData];
    [self setWarningMessage:nil];
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
            [self setRestoreble:![[CEKeyBindingManager sharedManager] usesDefaultMenuKeyBindings]];
            break;
            
        case CETextKeyBindingsType:
            [[CEKeyBindingManager sharedManager] saveTextKeyBindings:[self outlineData]
                                                               texts:[[self snippetArrayController] content]];
            [self setRestoreble:![[CEKeyBindingManager sharedManager] usesDefaultTextKeyBindings]];
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


// ------------------------------------------------------
/// カスタムテキスト設定を arrayController にセットする
- (void)setupCustomTexts:(NSArray<NSString *> *)customTexts
// ------------------------------------------------------
{
    NSMutableArray<NSMutableDictionary<NSString *, NSString *> *> *content = [NSMutableArray array];
    
    for (NSString *text in customTexts) {
        [content addObject:[@{CEDefaultInsertCustomTextKey: text} mutableCopy]];
    }
    [[self snippetArrayController] setContent:content];
    [[self snippetArrayController] setSelectionIndex:NSNotFound];
}


//------------------------------------------------------
/// 重複などの警告メッセージを表示
- (BOOL)validateKeySpecChars:(nonnull NSString *)keySpec oldChars:(nonnull NSString *)oldSpec
//------------------------------------------------------
{
    // clear error
    [self setWarningMessage:nil];
    
    // blank key is always valid
    if ([keySpec length] == 0) { return YES; }
    
    NSString *warning = nil;
    
    // 重複チェック用配列を生成
    NSArray<NSString *> *registeredKeySpecChars = [[CEKeyBindingManager sharedManager] keySpecCharsListFromOutlineData:[self outlineData]];
    
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

@end
