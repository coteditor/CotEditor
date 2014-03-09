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

@implementation CEPrefEncodingDataSource

#pragma mark ===== Public method =====

//=======================================================
// Public method
//
//=======================================================

// ------------------------------------------------------
- (void)dealloc
// あとかたづけ
// ------------------------------------------------------
{
    [super dealloc];
}


// ------------------------------------------------------
- (void)setupEncodingsToEdit
// 表示／変更のためのエンコーディングリストをセットアップ
// ------------------------------------------------------
{
    id theValues = [[NSUserDefaultsController sharedUserDefaultsController] values];
    id theInitValues = [[NSUserDefaultsController sharedUserDefaultsController] initialValues];
    NSMutableArray *theEncodings = [NSMutableArray arrayWithArray:[theValues valueForKey:k_key_encodingList]];
    BOOL theBoolNotToRevert = [theEncodings isEqualToArray:
            (NSArray *)[theInitValues valueForKey:k_key_encodingList]];

    [theEncodings retain]; // ===== retain
    if (_encodingsForTmp) {
        [_encodingsForTmp release];
    }
    _encodingsForTmp = theEncodings;
    [_revertButton setEnabled:(!theBoolNotToRevert)]; // 出荷時に戻すボタンの有効化／無効化を制御
    [_tableView reloadData]; // 表示を初期化(これがないとスクロールバーが無効化してしまう)
}


// ------------------------------------------------------
- (void)writeEncodingsToUserDefaults
// エンコーディングリストを userDefaults に書き戻す
// ------------------------------------------------------
{
    id theValues = [[NSUserDefaultsController sharedUserDefaultsController] values];

    if (![_encodingsForTmp isEqualToArray:[theValues valueForKey:k_key_encodingList]]) {
        NSUserDefaults *theDefaults = [NSUserDefaults standardUserDefaults];
        [theDefaults setObject:_encodingsForTmp forKey:k_key_encodingList];
    }
}



#pragma mark ===== Protocol =====

//=======================================================
// NSTableDataSource Protocol
//
//=======================================================

// ------------------------------------------------------
- (NSInteger)numberOfRowsInTableView:(NSTableView *)inTableView
// tableView の行数を返す
// ------------------------------------------------------
{
    return ([_encodingsForTmp count]);
}


// ------------------------------------------------------
- (id)tableView:(NSTableView *)inTableView 
        objectValueForTableColumn:(NSTableColumn *)inTableColumn 
        row:(NSInteger)inRowIndex
// tableViewの列・行で指定された内容を返す
// ------------------------------------------------------
{
    CFStringEncoding theCFEncoding = [_encodingsForTmp[inRowIndex] unsignedLongValue];
    NSString *outStr;

    if (theCFEncoding == kCFStringEncodingInvalidId) { // = separator
        outStr = @"-----";
    } else {
        NSStringEncoding theEncoding = CFStringConvertEncodingToNSStringEncoding(theCFEncoding);
        NSString *theIanaName = (NSString *)CFStringConvertEncodingToIANACharSetName(theCFEncoding);
        if (theIanaName == nil) {
            theIanaName = @"-";
        }
        outStr = [NSString stringWithFormat:@"%@ : [%@]", 
                    [NSString localizedNameOfStringEncoding:theEncoding], theIanaName];
    }
    return outStr;
}


// ------------------------------------------------------
- (BOOL)tableView:(NSTableView *)inTableView 
        writeRows:(NSArray *)inRows toPasteboard:(NSPasteboard *)ioPboard
// ドラッグ開始／tableView からのドラッグアイテム内容をセット
// ------------------------------------------------------
{
    // ドラッグ受付タイプを登録
    [inTableView registerForDraggedTypes:@[k_dropMyselfPboardType]];
    // すべての選択を解除して、改めてドラッグされる行を選択し直す
    NSMutableIndexSet *theIndexes = [NSMutableIndexSet indexSet];
    [inTableView deselectAll:self];
    for (NSNumber *index in inRows) {
        [theIndexes addIndex:[index unsignedIntegerValue]];
    }
    [inTableView selectRowIndexes:theIndexes byExtendingSelection:YES];
    // ドラッグされる行の保持、Pasteboard の設定
    _draggedItems = inRows; // ドラッグ中にのみ必要なオブジェクトなので、retainしない
    [ioPboard declareTypes:@[k_dropMyselfPboardType] owner:nil];
    [ioPboard setData:[NSData data] forType:k_dropMyselfPboardType];

    return YES;
}


// ------------------------------------------------------
- (NSDragOperation)tableView:(NSTableView *)inTableView 
        validateDrop:(id <NSDraggingInfo>)inInfo proposedRow:(NSInteger)inRow
        proposedDropOperation:(NSTableViewDropOperation)inOperation
// tableViewへドラッグアイテムが入ってきたときの判定
// ------------------------------------------------------
{
    if ([inInfo draggingSource]) { // = Local dragging
        BOOL validity = NO;

        validity = (((inRow == k_lastRow) && (inOperation == NSTableViewDropOn)) || 
                ((inRow != k_lastRow) && (inOperation == NSTableViewDropAbove)));

        return validity ? NSDragOperationGeneric : NSDragOperationNone;
    }
    return NSDragOperationNone;
}


// ------------------------------------------------------
- (BOOL)tableView:(NSTableView *)inTableView 
        acceptDrop:(id <NSDraggingInfo>)inInfo row:(NSInteger)inRow
        dropOperation:(NSTableViewDropOperation)inOperation
// ドロップの許可、アイテムの移動挿入
// ------------------------------------------------------
{
    NSMutableIndexSet *theSelectIndexSet = [NSMutableIndexSet indexSet];
    NSEnumerator *theEnumerator = [_draggedItems reverseObjectEnumerator];
    NSMutableArray *theDraggingArray = [NSMutableArray array];
    NSMutableArray *theNewArray = [NSMutableArray arrayWithArray:_encodingsForTmp];
    id theObject;
    NSInteger i, theCount, theNewRow = inRow;

    while (theObject = [theEnumerator nextObject]) {
        if ([theObject unsignedIntegerValue] < [theNewArray count]) {
            [theDraggingArray addObject:
                    [[theNewArray[[theObject unsignedIntegerValue]] copy] autorelease]];
            [theNewArray removeObjectAtIndex:[theObject unsignedIntegerValue]];
            if ([theObject integerValue] < inRow) { // 下方へドラッグ移動されるときの調整
                theNewRow--;
            }
        }
    }
    theCount = [theDraggingArray count];
    for (i = 0; i < theCount; i++) {
        if (inRow != k_lastRow) {
            [theNewArray insertObject:theDraggingArray[i] atIndex:theNewRow];
            [theSelectIndexSet addIndex:(theNewRow + i)];
        } else {
            [theNewArray addObject:theDraggingArray[(theCount - i - 1)]];
            [theSelectIndexSet addIndex:i];
        }
    }

    // リストが変更されたら、_encodingsForTmp に書き戻す
    if (![theNewArray isEqualToArray:_encodingsForTmp]) {
        [_encodingsForTmp setArray:theNewArray];
    }
    [inTableView reloadData];
    [inTableView selectRowIndexes:theSelectIndexSet byExtendingSelection:NO];
    return YES;
}



#pragma mark === Delegate and Notification ===

//=======================================================
// Delegate method (NSTableView)
//  <== _tableView
//=======================================================

// ------------------------------------------------------
- (void)tableViewSelectionDidChange:(NSNotification *)inNotification
// tableView の選択行が変更される直前にその許可を出す
// ------------------------------------------------------
{
    NSIndexSet *theSelectIndexSet = [_tableView selectedRowIndexes];

    if ([theSelectIndexSet count] > 0) {
        id theObject;
        NSUInteger i;

        for (i = 0; i < [_encodingsForTmp count]; i++) {
            theObject = _encodingsForTmp[i];
            if (([theSelectIndexSet containsIndex:i]) && 
                        ([theObject unsignedLongValue] == kCFStringEncodingInvalidId)) {
                [_delSeparatorButton setEnabled:YES];
                return;
            }
        }
    }
    [_delSeparatorButton setEnabled:NO];
}



#pragma mark ===== Action messages =====

//=======================================================
// Action messages
//
//=======================================================

// ------------------------------------------------------
- (IBAction)revertDefaultEncodings:(id)sender
// デフォルトのエンコーディング設定に戻す
// ------------------------------------------------------
{
    id theInitValues = [[NSUserDefaultsController sharedUserDefaultsController] initialValues];
    NSMutableArray *theEncodings = 
            [NSMutableArray arrayWithArray:[theInitValues valueForKey:k_key_encodingList]];

    [theEncodings retain]; // ===== retain
    if (_encodingsForTmp) {
        [_encodingsForTmp release];
    }
    _encodingsForTmp = theEncodings;
    [_tableView reloadData];
    [_revertButton setEnabled:NO];
}


// ------------------------------------------------------
- (IBAction)addSeparator:(id)sender
// セパレータ追加
// ------------------------------------------------------
{
    NSInteger theIndex, theSelected = [_tableView selectedRow];

    theIndex = (theSelected < 0) ? 0 : theSelected;
    [_encodingsForTmp insertObject:[NSNumber numberWithUnsignedLong:kCFStringEncodingInvalidId] 
                atIndex:theIndex];
    [_tableView reloadData];
    [_tableView selectRowIndexes:[NSIndexSet indexSetWithIndex:theIndex] byExtendingSelection:NO];
}


// ------------------------------------------------------
- (IBAction)deleteSeparator:(id)sender
// セパレータ削除
// ------------------------------------------------------
{
    NSIndexSet *theSelectIndexSet = [_tableView selectedRowIndexes];

    if ([theSelectIndexSet count] == 0) {
        return;
    }
    NSMutableArray *theNewArray = [NSMutableArray array];
    id theObject;
    NSUInteger i, theDeleted = 0;

    for (i = 0; i < [_encodingsForTmp count]; i++) {
        theObject = _encodingsForTmp[i];
        if (([theSelectIndexSet containsIndex:i]) && 
                ([theObject unsignedLongValue] == kCFStringEncodingInvalidId)) {
            theDeleted++;
            continue;
        }
        [theNewArray addObject:theObject];
    }
    if (theDeleted == 0) {
        return;
    }
    [_tableView deselectAll:self];
    // リストが変更されたら、_encodingsForTmp に書き戻す
    if (![theNewArray isEqualToArray:_encodingsForTmp]) {
        [_encodingsForTmp setArray:theNewArray];
    }
    [_tableView reloadData];
}


@end
