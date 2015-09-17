/*
 
 CEDraggableArrayController.m
 
 CotEditor
 http://coteditor.com
 
 Created by 1024jp on 2014-08-18.

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

#import "CEDraggableArrayController.h"


static NSString *_Nonnull const CERowsType = @"CERowsType";
static NSString *_Nonnull const CEObjectsType = @"CEObjectsType";


@implementation CEDraggableArrayController

#pragma mark Data Source

//=======================================================
// NSTableDataSource Protocol
//=======================================================

// ------------------------------------------------------
/// start dragging
- (BOOL)tableView:(nonnull NSTableView *)tableView writeRowsWithIndexes:(nonnull NSIndexSet *)rowIndexes toPasteboard:(nonnull NSPasteboard *)pboard
// ------------------------------------------------------
{
    [tableView registerForDraggedTypes:@[CERowsType, CEObjectsType]];
    
    // declare types
    [pboard declareTypes:@[CERowsType, CEObjectsType] owner:self];
    
    // store row index info to pasteboard
    [pboard setPropertyList:[NSKeyedArchiver archivedDataWithRootObject:rowIndexes] forType:CERowsType];
    
    // store objects to drag to pasteboard
    NSArray<id> *objects = [[self arrangedObjects] objectsAtIndexes:rowIndexes];
    [pboard setPropertyList:objects forType:CEObjectsType];
    
    return YES;
}


// ------------------------------------------------------
/// validate dorpped objects
- (NSDragOperation)tableView:(nonnull NSTableView *)tableView validateDrop:(nonnull id<NSDraggingInfo>)info proposedRow:(NSInteger)row proposedDropOperation:(NSTableViewDropOperation)operation
// ------------------------------------------------------
{
    // accept only self drag-and-drop
    if ([info draggingSource] != tableView) {
        return NSDragOperationNone;
    }
    
    if (operation == NSTableViewDropOn) {
        [tableView setDropRow:row dropOperation:NSTableViewDropAbove];
    }
    
    return NSDragOperationMove;
}


// ------------------------------------------------------
/// insert dropped objects
- (BOOL)tableView:(nonnull NSTableView *)tableView acceptDrop:(nonnull id<NSDraggingInfo>)info row:(NSInteger)row dropOperation:(NSTableViewDropOperation)dropOperation
// ------------------------------------------------------
{
    // accept only self drag-and-drop
    if ([info draggingSource] != tableView) {
        return NO;
    }
    
    NSIndexSet *originalRows = [NSKeyedUnarchiver unarchiveObjectWithData:[[info draggingPasteboard] propertyListForType:CERowsType]];
    NSArray<id> *draggingItems = [[info draggingPasteboard] propertyListForType:CEObjectsType];
    NSUInteger newRow = row - [originalRows countOfIndexesInRange:NSMakeRange(0, row)];  // real insertion point after removing items to move
    NSIndexSet *insertRows = [NSIndexSet indexSetWithIndexesInRange:NSMakeRange(newRow, [draggingItems count])];
    
    // remove original rows
    [self removeObjectsAtArrangedObjectIndexes:originalRows];
    
    // insert objects to new rows
    [self insertObjects:draggingItems atArrangedObjectIndexes:insertRows];
    
    // select dropped items
    [tableView selectRowIndexes:insertRows byExtendingSelection:NO];
    
    return  YES;
}

@end
