/*
 ==============================================================================
 CEDraggableArrayController
 
 CotEditor
 http://coteditor.com
 
 Created on 2014-08-18 by 1024jp
 encoding="UTF-8"
 ------------------------------------------------------------------------------
 
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

#import "CEDraggableArrayController.h"


static NSString *__nonnull const CERowsType = @"CERowsType";
static NSString *__nonnull const CEObjectsType = @"CEObjectsType";


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
    NSArray *objects = [[self arrangedObjects] objectsAtIndexes:rowIndexes];
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
    NSArray *draggingItems = [[info draggingPasteboard] propertyListForType:CEObjectsType];
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
