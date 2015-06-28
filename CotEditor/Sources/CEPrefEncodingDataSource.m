/*
 ==============================================================================
 CEPrefEncodingDataSource
 
 CotEditor
 http://coteditor.com
 
 Created on 2004-12-16 by 1024jp
 encoding="UTF-8"
 ------------------------------------------------------------------------------
 
 © 2004-2007 nakamuxu
 © 2014-2015 1024jp
 
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

#import "CEPrefEncodingDataSource.h"
#import "constants.h"


// constants
static NSString *const CERowsType = @"CERowsType";
static NSInteger const kLastRow = -1;


@interface CEPrefEncodingDataSource ()

@property (nonatomic, nullable) NSMutableArray *encodingsForTmp;

@property (nonatomic, nullable, weak) IBOutlet NSTableView *tableView;
@property (nonatomic, nullable, weak) IBOutlet NSButton *deleteSeparatorButton;
@property (nonatomic, nullable, weak) IBOutlet NSButton *revertButton;

@end




#pragma mark -

@implementation CEPrefEncodingDataSource

#pragma mark Public Methods

// ------------------------------------------------------
/// 表示／変更のためのエンコーディングリストをセットアップ
- (void)setupEncodingsToEdit
// ------------------------------------------------------
{
    id values = [[NSUserDefaultsController sharedUserDefaultsController] values];
    NSDictionary *initValues = [[NSUserDefaultsController sharedUserDefaultsController] initialValues];
    NSMutableArray *encodings = [[values valueForKey:CEDefaultEncodingListKey] mutableCopy];
    BOOL shouldRevert = ![encodings isEqualToArray:initValues[CEDefaultEncodingListKey]];

    [self setEncodingsForTmp:encodings];
    [[self revertButton] setEnabled:shouldRevert]; // 出荷時に戻すボタンの有効化／無効化を制御
    [[self tableView] reloadData]; // 表示を初期化(これがないとスクロールバーが無効化してしまう)
}


// ------------------------------------------------------
/// エンコーディングリストを userDefaults に書き戻す
- (void)writeEncodingsToUserDefaults
// ------------------------------------------------------
{
    [[NSUserDefaults standardUserDefaults] setObject:[self encodingsForTmp] forKey:CEDefaultEncodingListKey];
}



#pragma mark Data Source

//=======================================================
// NSTableDataSource Protocol
//=======================================================

// ------------------------------------------------------
/// tableView の行数を返す
- (NSInteger)numberOfRowsInTableView:(nonnull NSTableView *)tableView
// ------------------------------------------------------
{
    return [[self encodingsForTmp] count];
}


// ------------------------------------------------------
/// tableViewの列・行で指定された内容を返す
- (nullable id)tableView:(nonnull NSTableView *)tableView objectValueForTableColumn:(nullable NSTableColumn *)tableColumn row:(NSInteger)rowIndex
// ------------------------------------------------------
{
    CFStringEncoding cfEncoding = [[self encodingsForTmp][rowIndex] unsignedLongValue];
    NSMutableAttributedString *attrString;

    if (cfEncoding == kCFStringEncodingInvalidId) {  // = separator
        attrString = [[NSMutableAttributedString alloc] initWithString:CESeparatorString];
        
    } else {
        NSStringEncoding encoding = CFStringConvertEncodingToNSStringEncoding(cfEncoding);
        NSString *encodingStr = [NSString localizedNameOfStringEncoding:encoding];
        NSString *ianaName = (NSString *)CFStringConvertEncodingToIANACharSetName(cfEncoding) ? : @"-";
        
        attrString = [[NSMutableAttributedString alloc] initWithString:[NSString stringWithFormat:@"%@  : %@",
                                                                        encodingStr, ianaName]];
        [attrString addAttributes:@{NSForegroundColorAttributeName: [NSColor disabledControlTextColor]}
                            range:NSMakeRange([encodingStr length] + 2, [ianaName length] + 2)];
    }
    
    return attrString;
}


// ------------------------------------------------------
/// ドラッグ開始／tableView からのドラッグアイテム内容をセット
- (BOOL)tableView:(nonnull NSTableView *)tableView writeRowsWithIndexes:(nonnull NSIndexSet *)rowIndexes toPasteboard:(nonnull NSPasteboard *)pboard
// ------------------------------------------------------
{
    // ドラッグ受付タイプを登録
    [tableView registerForDraggedTypes:@[CERowsType]];
    // すべての選択を解除して、改めてドラッグされる行を選択し直す
    [tableView deselectAll:self];
    [tableView selectRowIndexes:rowIndexes byExtendingSelection:YES];
    // ドラッグされる行の保持、Pasteboard の設定
    [pboard declareTypes:@[CERowsType] owner:nil];
    [pboard setPropertyList:[NSKeyedArchiver archivedDataWithRootObject:rowIndexes] forType:CERowsType];

    return YES;
}


// ------------------------------------------------------
/// tableViewへドラッグアイテムが入ってきたときの判定
- (NSDragOperation)tableView:(nonnull NSTableView *)tableView validateDrop:(nonnull id <NSDraggingInfo>)info proposedRow:(NSInteger)row proposedDropOperation:(NSTableViewDropOperation)operation
// ------------------------------------------------------
{
    if ([info draggingSource] == tableView) {  // = Local dragging
        BOOL isValid = (((row == kLastRow) && (operation == NSTableViewDropOn)) ||
                        ((row != kLastRow) && (operation == NSTableViewDropAbove)));
        
        return isValid ? NSDragOperationGeneric : NSDragOperationNone;
    }
    
    return NSDragOperationNone;
}


// ------------------------------------------------------
/// ドロップの許可、アイテムの移動挿入
- (BOOL)tableView:(nonnull NSTableView *)tableView acceptDrop:(nonnull id <NSDraggingInfo>)info row:(NSInteger)row dropOperation:(NSTableViewDropOperation)operation
// ------------------------------------------------------
{
    NSIndexSet *originalRows = [NSKeyedUnarchiver unarchiveObjectWithData:[[info draggingPasteboard] propertyListForType:CERowsType]];
    NSMutableIndexSet *selectRows = [NSMutableIndexSet indexSet];
    NSMutableArray *draggingArray = [NSMutableArray array];
    NSMutableArray *newArray = [[self encodingsForTmp] mutableCopy];
    __block NSInteger newRow = row;

    [originalRows enumerateIndexesWithOptions:NSEnumerationReverse usingBlock:^(NSUInteger idx, BOOL *stop) {
        if (idx >= [newArray count]) { return; }
        
        [draggingArray addObject:[newArray[idx] copy]];
        [newArray removeObjectAtIndex:idx];
        if (idx < row) { // 下方へドラッグ移動されるときの調整
            newRow--;
        }
    }];
    
    NSInteger count = [draggingArray count];
    for (NSUInteger i = 0; i < count; i++) {
        if (row != kLastRow) {
            [newArray insertObject:draggingArray[i] atIndex:newRow];
            [selectRows addIndex:(newRow + i)];
        } else {
            [newArray addObject:draggingArray[(count - i - 1)]];
            [selectRows addIndex:i];
        }
    }

    // リストが変更されたら、encodingsForTmp に書き戻す
    if (![newArray isEqualToArray:[self encodingsForTmp]]) {
        [[self encodingsForTmp] setArray:newArray];
    }
    
    // update UI
    [tableView removeRowsAtIndexes:originalRows withAnimation:NSTableViewAnimationEffectFade];
    [tableView insertRowsAtIndexes:selectRows withAnimation:NSTableViewAnimationEffectGap];
    [tableView selectRowIndexes:selectRows byExtendingSelection:NO];
    
    return YES;
}



#pragma mark Delegate

//=======================================================
// NSTableViewDelegate  < tableView
//=======================================================

// ------------------------------------------------------
/// tableView の選択行が変更される直前にその許可を出す
- (void)tableViewSelectionDidChange:(nonnull NSNotification *)notification
// ------------------------------------------------------
{
    NSIndexSet *selectedIndexes = [[self tableView] selectedRowIndexes];

    if ([selectedIndexes count] > 0) {
        NSUInteger i = 0;
        for (NSNumber *encodingNumber in [self encodingsForTmp]) {
            if ([selectedIndexes containsIndex:i] && ([encodingNumber unsignedLongValue] == kCFStringEncodingInvalidId)) {
                [[self deleteSeparatorButton] setEnabled:YES];
                return;
            }
            i++;
        }
    }
    [[self deleteSeparatorButton] setEnabled:NO];
}



#pragma mark Action Messages

// ------------------------------------------------------
/// restore encoding setting to default
- (IBAction)revertDefaultEncodings:(nullable id)sender
// ------------------------------------------------------
{
    NSDictionary *initValues = [[NSUserDefaultsController sharedUserDefaultsController] initialValues];
    NSMutableArray *encodings = [NSMutableArray arrayWithArray:initValues[CEDefaultEncodingListKey]];

    [self setEncodingsForTmp:encodings];
    [[self tableView] reloadData];
    [[self revertButton] setEnabled:NO];
}


// ------------------------------------------------------
/// add separator
- (IBAction)addSeparator:(nullable id)sender
// ------------------------------------------------------
{
    NSUInteger index = MAX([[self tableView] selectedRow], 0);
    
    [self addSeparatorAtIndex:index];
}


// ------------------------------------------------------
/// remove separator
- (IBAction)deleteSeparator:(nullable id)sender
// ------------------------------------------------------
{
    [self deleteSeparatorAtIndexes:[[self tableView] selectedRowIndexes]];
}



#pragma mark Private Methods

// ------------------------------------------------------
/// add separator to desired row
- (void)addSeparatorAtIndex:(NSUInteger)rowIndex
// ------------------------------------------------------
{
    // add to data
    [[self encodingsForTmp] insertObject:@(kCFStringEncodingInvalidId) atIndex:rowIndex];
    
    // update UI
    NSIndexSet *indexSet = [NSIndexSet indexSetWithIndex:rowIndex];
    [[self tableView] insertRowsAtIndexes:indexSet withAnimation:NSTableViewAnimationEffectGap];
    [[self tableView] selectRowIndexes:indexSet byExtendingSelection:NO];
}


// ------------------------------------------------------
/// remove separators at desired rows
- (void)deleteSeparatorAtIndexes:(nonnull NSIndexSet *)rowIndexes
// ------------------------------------------------------
{
    if ([rowIndexes count] == 0) { return; }
    
    NSMutableIndexSet *toDeleteIndexes = [NSMutableIndexSet indexSet];
    
    // pick only separators up
    NSArray *encodings = [self encodingsForTmp];
    [rowIndexes enumerateIndexesUsingBlock:^(NSUInteger idx, BOOL *stop) {
        CFStringEncoding encoding = [encodings[idx] unsignedLongLongValue];
        
        if (encoding == kCFStringEncodingInvalidId) {
            [toDeleteIndexes addIndex:idx];
        }
    }];
    
    if ([toDeleteIndexes count] == 0) { return; }
    
    // update UI
    [[self tableView] selectRowIndexes:toDeleteIndexes byExtendingSelection:NO];
    [[self tableView] removeRowsAtIndexes:toDeleteIndexes withAnimation:NSTableViewAnimationSlideUp];
    
    // update data
    [[self encodingsForTmp] removeObjectsAtIndexes:toDeleteIndexes];
}

@end
