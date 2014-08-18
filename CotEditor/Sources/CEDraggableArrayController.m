/*
 ==============================================================================
 CEDraggableArrayController
 
 CotEditor
 http://coteditor.github.io
 
 Created on 2014-08-18 by 1024jp
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

#import "CEDraggableArrayController.h"


static NSString *CERowsType = @"CERowsType";
static NSString *CEObjectsType = @"CEObjectsType";


@implementation CEDraggableArrayController

// ------------------------------------------------------
/// start dragging
- (BOOL)tableView:(NSTableView *)tableView writeRowsWithIndexes:(NSIndexSet *)rowIndexes toPasteboard:(NSPasteboard *)pboard
// ------------------------------------------------------
{
    [tableView registerForDraggedTypes:@[CERowsType, CEObjectsType]];
    
    // declare types
    [pboard declareTypes:@[CERowsType, CEObjectsType] owner:self];
    
    // store row index info to pasteboard
    [pboard setPropertyList:[NSKeyedArchiver archivedDataWithRootObject:rowIndexes] forType:CERowsType];
    
    // store objects to drag to pasteboard
    __block NSMutableArray *objects = [NSMutableArray arrayWithCapacity:[rowIndexes count]];
    [rowIndexes enumerateIndexesUsingBlock:^(NSUInteger idx, BOOL *stop) {
        [objects addObject:[self arrangedObjects][idx]];
    }];
    [pboard setPropertyList:objects forType:CEObjectsType];
    
    return YES;
}


// ------------------------------------------------------
/// validate dorpped objects
- (NSDragOperation)tableView:(NSTableView *)tableView validateDrop:(id<NSDraggingInfo>)info proposedRow:(NSInteger)row proposedDropOperation:(NSTableViewDropOperation)operation
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
- (BOOL)tableView:(NSTableView *)tableView acceptDrop:(id<NSDraggingInfo>)info row:(NSInteger)row dropOperation:(NSTableViewDropOperation)dropOperation
// ------------------------------------------------------
{
    // accept only self drag-and-drop
    if ([info draggingSource] != tableView) {
        return NO;
    }
    
    NSIndexSet *originalRows = [NSKeyedUnarchiver unarchiveObjectWithData:[[info draggingPasteboard] propertyListForType:CERowsType]];
    NSMutableArray *objects = [[info draggingPasteboard] propertyListForType:CEObjectsType];
    
    // remove original rows
    [self removeObjectsAtArrangedObjectIndexes:originalRows];
    
    // insert objects to new rows
    __block NSUInteger newRow = row - [originalRows countOfIndexesInRange:NSMakeRange(0, row)];
    __block NSUInteger i = 0;
    [originalRows enumerateIndexesUsingBlock:^(NSUInteger idx, BOOL *stop) {
        [self insertObject:objects[i] atArrangedObjectIndex:newRow];
        newRow++;
        i++;
    }];
    
    return  YES;
}

@end
