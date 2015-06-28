/*
 ==============================================================================
 CEPrefEncodingDataSource
 
 CotEditor
 http://coteditor.com
 
 Created on 2014-12-16 by 1024jp
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
static NSString *const CERowsPboardType = @"CERowsPboardType";


@interface CEPrefEncodingDataSource ()

@property (nonatomic, nonnull, copy) NSArray *defaultEncodings;
@property (nonatomic, nonnull) NSMutableArray *encodings;
@property (nonatomic) BOOL canRestore;  // enability of "Restore Default" button

@property (nonatomic, nullable, weak) IBOutlet NSTableView *tableView;
@property (nonatomic, nullable, weak) IBOutlet NSButton *deleteSeparatorButton;

@end




#pragma mark -

@implementation CEPrefEncodingDataSource

// ------------------------------------------------------
/// initialize
- (instancetype)init
// ------------------------------------------------------
{
    self = [super init];
    if (self) {
        _defaultEncodings = [[NSUserDefaultsController sharedUserDefaultsController] initialValues][CEDefaultEncodingListKey];
        _encodings = [[[NSUserDefaults standardUserDefaults] arrayForKey:CEDefaultEncodingListKey] mutableCopy];
        _canRestore = ![_encodings isEqualToArray:_defaultEncodings];
    }
    return self;
}



#pragma mark Public Methods

// ------------------------------------------------------
/// write back current encoding list userDefaults
- (void)writeToUserDefaults
// ------------------------------------------------------
{
    [[NSUserDefaults standardUserDefaults] setObject:[self encodings] forKey:CEDefaultEncodingListKey];
}



#pragma mark Protocol

//=======================================================
// NSTableDataSource Protocol
//=======================================================

// ------------------------------------------------------
/// return number of rows in table
- (NSInteger)numberOfRowsInTableView:(nonnull NSTableView *)tableView
// ------------------------------------------------------
{
    return [[self encodings] count];
}


// ------------------------------------------------------
/// return content of each cell
- (nullable id)tableView:(nonnull NSTableView *)tableView objectValueForTableColumn:(nullable NSTableColumn *)tableColumn row:(NSInteger)rowIndex
// ------------------------------------------------------
{
    CFStringEncoding cfEncoding = [[self encodings][rowIndex] unsignedLongValue];
    
    // separator
    if (cfEncoding == kCFStringEncodingInvalidId) {
        return CESeparatorString;
    }
    
    // styled encoding name
    NSStringEncoding encoding = CFStringConvertEncodingToNSStringEncoding(cfEncoding);
    NSString *encodingName = [NSString localizedNameOfStringEncoding:encoding];
    NSString *ianaName = (NSString *)CFStringConvertEncodingToIANACharSetName(cfEncoding) ? : @"-";
    
    NSMutableAttributedString *attrString = [[NSMutableAttributedString alloc] initWithString:[NSString stringWithFormat:@"%@  : %@",
                                                                                               encodingName, ianaName]];
    [attrString addAttributes:@{NSForegroundColorAttributeName: [NSColor disabledControlTextColor]}
                        range:NSMakeRange([encodingName length] + 2, [ianaName length] + 2)];
    
    return attrString;
}


// ------------------------------------------------------
/// start dragging
- (BOOL)tableView:(nonnull NSTableView *)tableView writeRowsWithIndexes:(nonnull NSIndexSet *)rowIndexes toPasteboard:(nonnull NSPasteboard *)pboard
// ------------------------------------------------------
{
    // register dragged type
    [tableView registerForDraggedTypes:@[CERowsPboardType]];
    
    // declare types
    [pboard declareTypes:@[CERowsPboardType] owner:self];
    
    // select rows to drag
    [tableView selectRowIndexes:rowIndexes byExtendingSelection:NO];
    
    // set dragged items to pasteboard
    [pboard setPropertyList:[NSKeyedArchiver archivedDataWithRootObject:rowIndexes] forType:CERowsPboardType];

    return YES;
}


// ------------------------------------------------------
/// validate when dragged items come to tableView
- (NSDragOperation)tableView:(nonnull NSTableView *)tableView validateDrop:(nonnull id <NSDraggingInfo>)info proposedRow:(NSInteger)row proposedDropOperation:(NSTableViewDropOperation)operation
// ------------------------------------------------------
{
    // accept only self drag-and-drop
    if ([info draggingSource] != tableView) {
        return NSDragOperationNone;
    }
    
    // avoid drop-on
    if (operation == NSTableViewDropOn) {
        NSUInteger newRow = MIN(row + 1, [tableView numberOfRows] - 1);
        [tableView setDropRow:newRow dropOperation:NSTableViewDropAbove];
    }
    
    [tableView setDraggingDestinationFeedbackStyle:NSTableViewDraggingDestinationFeedbackStyleSourceList];
    
    return NSDragOperationMove;
}


// ------------------------------------------------------
/// check acceptability of dragged items and insert them to table
- (BOOL)tableView:(nonnull NSTableView *)tableView acceptDrop:(nonnull id <NSDraggingInfo>)info row:(NSInteger)row dropOperation:(NSTableViewDropOperation)operation
// ------------------------------------------------------
{
    // accept only self drag-and-drop
    if ([info draggingSource] != tableView) {
        return NO;
    }
    
    NSIndexSet *originalRows = [NSKeyedUnarchiver unarchiveObjectWithData:[[info draggingPasteboard] propertyListForType:CERowsPboardType]];
    NSArray *draggingItems = [[self encodings] objectsAtIndexes:originalRows];
    NSUInteger newRow = row - [originalRows countOfIndexesInRange:NSMakeRange(0, row)];  // real insertion point after removing items to move
    NSIndexSet *insertRows = [NSIndexSet indexSetWithIndexesInRange:NSMakeRange(newRow, [draggingItems count])];

    // update data
    [[self encodings] removeObjectsAtIndexes:originalRows];
    [[self encodings] insertObjects:draggingItems atIndexes:insertRows];
    
    // update UI
    [tableView removeRowsAtIndexes:originalRows withAnimation:NSTableViewAnimationEffectFade];
    [tableView insertRowsAtIndexes:insertRows withAnimation:NSTableViewAnimationEffectGap];
    [tableView selectRowIndexes:insertRows byExtendingSelection:NO];
    [self validateRestorebility];
    
    [tableView reloadData];

    
    return YES;
}



#pragma mark Delegate

//=======================================================
// NSTableViewDelegate  < tableView
//=======================================================

// ------------------------------------------------------
/// update UI just before selected rows are changed
- (void)tableViewSelectionDidChange:(nonnull NSNotification *)notification
// ------------------------------------------------------
{
    NSIndexSet *selectedIndexes = [[self tableView] selectedRowIndexes];
    
    // update enability of "Delete Separator" button
    __block BOOL includesSeparator = NO;
    [selectedIndexes enumerateIndexesUsingBlock:^(NSUInteger idx, BOOL *stop) {
        CFStringEncoding encoding = [[self encodings][idx] unsignedIntegerValue];
        if (encoding == kCFStringEncodingInvalidId) {
            includesSeparator = YES;
            *stop = YES;
        }
    }];
    [[self deleteSeparatorButton] setEnabled:includesSeparator];
}



#pragma mark Action Messages

// ------------------------------------------------------
/// restore encoding setting to default
- (IBAction)revertDefaultEncodings:(nullable id)sender
// ------------------------------------------------------
{
    [self setEncodings:[[self defaultEncodings] mutableCopy]];
    [[self tableView] reloadData];
    [self setCanRestore:NO];
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
/// validate "Restore Defaults" button
- (void)validateRestorebility
// ------------------------------------------------------
{
    [self setCanRestore:![[self encodings] isEqualToArray:[self defaultEncodings]]];
}


// ------------------------------------------------------
/// add separator to desired row
- (void)addSeparatorAtIndex:(NSUInteger)rowIndex
// ------------------------------------------------------
{
    // add to data
    [[self encodings] insertObject:@(kCFStringEncodingInvalidId) atIndex:rowIndex];
    
    // update UI
    NSIndexSet *indexSet = [NSIndexSet indexSetWithIndex:rowIndex];
    [[self tableView] insertRowsAtIndexes:indexSet withAnimation:NSTableViewAnimationEffectGap];
    [[self tableView] selectRowIndexes:indexSet byExtendingSelection:NO];
    
    [self validateRestorebility];
}


// ------------------------------------------------------
/// remove separators at desired rows
- (void)deleteSeparatorAtIndexes:(nonnull NSIndexSet *)rowIndexes
// ------------------------------------------------------
{
    if ([rowIndexes count] == 0) { return; }
    
    NSMutableIndexSet *toDeleteIndexes = [NSMutableIndexSet indexSet];
    
    // pick only separators up
    NSArray *encodings = [self encodings];
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
    [[self encodings] removeObjectsAtIndexes:toDeleteIndexes];
    
    [self validateRestorebility];
}

@end
