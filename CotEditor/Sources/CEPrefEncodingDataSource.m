/*
=================================================
CEPrefEncodingDataSource
(for CotEditor)

 Copyright (C) 2004-2007 nakamuxu.
 Copyright (C) 2014 CotEditor Project
 http://coteditor.github.io
=================================================

encoding="UTF-8"
Created:2004.12.16
 
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

#import "CEPrefEncodingDataSource.h"
#import "constants.h"


@interface CEPrefEncodingDataSource ()

@property (nonatomic) NSMutableArray *encodingsForTmp;
@property (nonatomic, weak) NSArray *draggedItems; // ドラッグ中にのみ必要なオブジェクトなので、retainしない

@property (nonatomic, weak) IBOutlet NSTableView *tableView;
@property (nonatomic, weak) IBOutlet NSButton *delSeparatorButton;
@property (nonatomic, weak) IBOutlet NSButton *revertButton;

@end


#pragma mark -

@implementation CEPrefEncodingDataSource

#pragma mark Public Methods

//=======================================================
// Public method
//
//=======================================================

// ------------------------------------------------------
- (void)setupEncodingsToEdit
// 表示／変更のためのエンコーディングリストをセットアップ
// ------------------------------------------------------
{
    id values = [[NSUserDefaultsController sharedUserDefaultsController] values];
    id initValues = [[NSUserDefaultsController sharedUserDefaultsController] initialValues];
    NSMutableArray *encodings = [NSMutableArray arrayWithArray:[values valueForKey:k_key_encodingList]];
    BOOL shouldRevert = ![encodings isEqualToArray:(NSArray *)[initValues valueForKey:k_key_encodingList]];

    [self setEncodingsForTmp:encodings];
    [[self revertButton] setEnabled:shouldRevert]; // 出荷時に戻すボタンの有効化／無効化を制御
    [[self tableView] reloadData]; // 表示を初期化(これがないとスクロールバーが無効化してしまう)
}


// ------------------------------------------------------
- (void)writeEncodingsToUserDefaults
// エンコーディングリストを userDefaults に書き戻す
// ------------------------------------------------------
{
    id values = [[NSUserDefaultsController sharedUserDefaultsController] values];

    if (![[self encodingsForTmp] isEqualToArray:[values valueForKey:k_key_encodingList]]) {
        NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
        [defaults setObject:[self encodingsForTmp] forKey:k_key_encodingList];
    }
}



#pragma mark Protocol

//=======================================================
// NSTableDataSource Protocol
//
//=======================================================

// ------------------------------------------------------
- (NSInteger)numberOfRowsInTableView:(NSTableView *)tableView
// tableView の行数を返す
// ------------------------------------------------------
{
    return [[self encodingsForTmp] count];
}


// ------------------------------------------------------
- (id)tableView:(NSTableView *)tableView objectValueForTableColumn:(NSTableColumn *)tableColumn row:(NSInteger)rowIndex
// tableViewの列・行で指定された内容を返す
// ------------------------------------------------------
{
    CFStringEncoding cfEncoding = [[self encodingsForTmp][rowIndex] unsignedLongValue];
    NSString *string;

    if (cfEncoding == kCFStringEncodingInvalidId) { // = separator
        string = @"-----";
    } else {
        NSStringEncoding encoding = CFStringConvertEncodingToNSStringEncoding(cfEncoding);
        NSString *ianaName = (NSString *)CFStringConvertEncodingToIANACharSetName(cfEncoding);
        if (ianaName == nil) {
            ianaName = @"-";
        }
        string = [NSString stringWithFormat:@"%@ : [%@]", [NSString localizedNameOfStringEncoding:encoding], ianaName];
    }
    return string;
}


// ------------------------------------------------------
- (BOOL)tableView:(NSTableView *)tableView writeRows:(NSArray *)rows toPasteboard:(NSPasteboard *)pasteboard
// ドラッグ開始／tableView からのドラッグアイテム内容をセット
// ------------------------------------------------------
{
    // ドラッグ受付タイプを登録
    [tableView registerForDraggedTypes:@[k_dropMyselfPboardType]];
    // すべての選択を解除して、改めてドラッグされる行を選択し直す
    NSMutableIndexSet *indexSet = [NSMutableIndexSet indexSet];
    [tableView deselectAll:self];
    for (NSNumber *index in rows) {
        [indexSet addIndex:[index unsignedIntegerValue]];
    }
    [tableView selectRowIndexes:indexSet byExtendingSelection:YES];
    // ドラッグされる行の保持、Pasteboard の設定
    [self setDraggedItems:rows];
    [pasteboard declareTypes:@[k_dropMyselfPboardType] owner:nil];
    [pasteboard setData:[NSData data] forType:k_dropMyselfPboardType];

    return YES;
}


// ------------------------------------------------------
- (NSDragOperation)tableView:(NSTableView *)tableView validateDrop:(id <NSDraggingInfo>)info proposedRow:(NSInteger)row proposedDropOperation:(NSTableViewDropOperation)inOperation
// tableViewへドラッグアイテムが入ってきたときの判定
// ------------------------------------------------------
{
    if ([info draggingSource]) { // = Local dragging
        BOOL isValid = NO;

        isValid = (((row == k_lastRow) && (inOperation == NSTableViewDropOn)) ||
                   ((row != k_lastRow) && (inOperation == NSTableViewDropAbove)));

        return isValid ? NSDragOperationGeneric : NSDragOperationNone;
    }
    return NSDragOperationNone;
}


// ------------------------------------------------------
- (BOOL)tableView:(NSTableView *)tableView 
        acceptDrop:(id <NSDraggingInfo>)info row:(NSInteger)row
        dropOperation:(NSTableViewDropOperation)operation
// ドロップの許可、アイテムの移動挿入
// ------------------------------------------------------
{
    NSMutableIndexSet *selectIndexSet = [NSMutableIndexSet indexSet];
    NSEnumerator *enumerator = [[self draggedItems] reverseObjectEnumerator];
    NSMutableArray *draggingArray = [NSMutableArray array];
    NSMutableArray *newArray = [NSMutableArray arrayWithArray:[self encodingsForTmp]];
    id object;
    NSInteger i, count, newRow = row;

    while (object = [enumerator nextObject]) {
        if ([object unsignedIntegerValue] < [newArray count]) {
            [draggingArray addObject:[newArray[[object unsignedIntegerValue]] copy]];
            [newArray removeObjectAtIndex:[object unsignedIntegerValue]];
            if ([object integerValue] < row) { // 下方へドラッグ移動されるときの調整
                newRow--;
            }
        }
    }
    count = [draggingArray count];
    for (i = 0; i < count; i++) {
        if (row != k_lastRow) {
            [newArray insertObject:draggingArray[i] atIndex:newRow];
            [selectIndexSet addIndex:(newRow + i)];
        } else {
            [newArray addObject:draggingArray[(count - i - 1)]];
            [selectIndexSet addIndex:i];
        }
    }

    // リストが変更されたら、encodingsForTmp に書き戻す
    if (![newArray isEqualToArray:[self encodingsForTmp]]) {
        [[self encodingsForTmp] setArray:newArray];
    }
    [tableView reloadData];
    [tableView selectRowIndexes:selectIndexSet byExtendingSelection:NO];
    
    return YES;
}



#pragma mark Delegate and Notification

//=======================================================
// Delegate method (NSTableView)
//  <== tableView
//=======================================================

// ------------------------------------------------------
- (void)tableViewSelectionDidChange:(NSNotification *)notification
// tableView の選択行が変更される直前にその許可を出す
// ------------------------------------------------------
{
    NSIndexSet *selectIndexSet = [[self tableView] selectedRowIndexes];

    if ([selectIndexSet count] > 0) {
        id object;
        NSUInteger i;

        for (i = 0; i < [[self encodingsForTmp] count]; i++) {
            object = [self encodingsForTmp][i];
            if (([selectIndexSet containsIndex:i]) &&
                ([object unsignedLongValue] == kCFStringEncodingInvalidId)) {
                [[self delSeparatorButton] setEnabled:YES];
                return;
            }
        }
    }
    [[self delSeparatorButton] setEnabled:NO];
}



#pragma mark Action Messages

//=======================================================
// Action messages
//
//=======================================================

// ------------------------------------------------------
- (IBAction)revertDefaultEncodings:(id)sender
// デフォルトのエンコーディング設定に戻す
// ------------------------------------------------------
{
    id initValues = [[NSUserDefaultsController sharedUserDefaultsController] initialValues];
    NSMutableArray *encodings = [NSMutableArray arrayWithArray:[initValues valueForKey:k_key_encodingList]];

    [self setEncodingsForTmp:encodings];
    [[self tableView] reloadData];
    [[self revertButton] setEnabled:NO];
}


// ------------------------------------------------------
- (IBAction)addSeparator:(id)sender
// セパレータ追加
// ------------------------------------------------------
{
    NSInteger index, selectedRow = [[self tableView] selectedRow];

    index = (selectedRow < 0) ? 0 : selectedRow;
    [[self encodingsForTmp] insertObject:@(kCFStringEncodingInvalidId) atIndex:index];
    [[self tableView] reloadData];
    [[self tableView] selectRowIndexes:[NSIndexSet indexSetWithIndex:index] byExtendingSelection:NO];
}


// ------------------------------------------------------
- (IBAction)deleteSeparator:(id)sender
// セパレータ削除
// ------------------------------------------------------
{
    NSIndexSet *selectIndexSet = [[self tableView] selectedRowIndexes];

    if ([selectIndexSet count] == 0) {
        return;
    }
    NSMutableArray *newArray = [NSMutableArray array];
    id theObject;
    NSUInteger i, deletedCount = 0;

    for (i = 0; i < [[self encodingsForTmp] count]; i++) {
        theObject = [self encodingsForTmp][i];
        if (([selectIndexSet containsIndex:i]) && 
                ([theObject unsignedLongValue] == kCFStringEncodingInvalidId)) {
            deletedCount++;
            continue;
        }
        [newArray addObject:theObject];
    }
    if (deletedCount == 0) {
        return;
    }
    [[self tableView] deselectAll:self];
    // リストが変更されたら、encodingsForTmp に書き戻す
    if (![newArray isEqualToArray:[self encodingsForTmp]]) {
        [[self encodingsForTmp] setArray:newArray];
    }
    [[self tableView] reloadData];
}

@end
