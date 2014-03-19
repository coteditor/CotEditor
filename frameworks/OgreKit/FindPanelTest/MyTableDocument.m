/*
 * Name: MyTableDocument.m
 * Project: OgreKit
 *
 * Creation Date: Sep 29 2003
 * Author: Isao Sonobe <sonoisa (AT) muse (DOT) ocn (DOT) ne (DOT) jp>
 * Copyright: Copyright (c) 2003 Isao Sonobe, All rights reserved.
 * License: OgreKit License
 *
 * Encoding: UTF8
 * Tabsize: 4
 */

#import "MyTableDocument.h"
#import "MyTableColumnSheet.h"
#import <OgreKit/OgreKit.h>

static NSString *gMyTableRowPboardType = @"OgreKit Find Panel Test TableRows";
static NSString *gMyTableRowPropertyType = @"rows";

@implementation MyTableDocument

// 検索対象となるtableViewをOgreTextFinderに教える。
// 検索させたくない場合はnilをsetする。
// 定義を省略した場合、main windowのfirst responderが検索可能ならばそれを採用する。
- (void)tellMeTargetToFindIn:(id)textFinder
{
	[textFinder setTargetToFindIn:tableView];
}


/* ここから下は検索パネルに関係しないコード */
- (void)awakeFromNib
{
    _useCustomSheetPosition = NO;
    [tableView registerForDraggedTypes:[NSArray arrayWithObject:gMyTableRowPboardType]];
    [tableView setTarget:self];
    [tableView setDoubleAction:@selector(tableViewDoubleClicked)];
}

- (void)dealloc
{
    [_titleArray release];
    [_dict release];
    [super dealloc];
}

- (NSString*)windowNibName 
{
    return @"MyTableDocument";
}

- (NSData*)dataRepresentationOfType:(NSString*)type 
{
    OGRegularExpression *escRegex = [OGRegularExpression regularExpressionWithString:@"\""];
    
	NSMutableString *aString = [NSMutableString string];
    NSArray         *columnArray = [tableView tableColumns];
    OgreTableColumn   *column;
    int             columnIndex, numberOfColumns = [columnArray count];
    int             rowIndex, numberOfRows = [self numberOfRows];
    NSArray         *array;
    NSMutableArray  *identifierArray = [NSMutableArray arrayWithCapacity:numberOfColumns];
    
    for (columnIndex = 0; columnIndex < numberOfColumns; columnIndex++) {
        column = [columnArray objectAtIndex:columnIndex];
        [identifierArray addObject:[column identifier]];
        [aString appendFormat:@"\"%@\"", [escRegex replaceAllMatchesInString:[[column headerCell] stringValue] withString:@"\"\""]];
        if (columnIndex < numberOfColumns - 1) [aString appendFormat:@","];
    }
    [aString appendFormat:@"\n"];
    
    for (rowIndex = 0; rowIndex < numberOfRows; rowIndex++) {
        for (columnIndex = 0; columnIndex < numberOfColumns; columnIndex++) {
            array = [_dict objectForKey:[identifierArray objectAtIndex:columnIndex]];
            [aString appendFormat:@"\"%@\"", [escRegex replaceAllMatchesInString:[array objectAtIndex:rowIndex] withString:@"\"\""]];
            if (columnIndex < numberOfColumns - 1) [aString appendFormat:@","];
        }
        [aString appendFormat:@"\n"];
    }
    
	// 改行コードを(置換すべきなら)置換し、保存する。
	if ([aString newlineCharacter] != _newlineCharacter) {
		aString = (NSMutableString*)[OGRegularExpression replaceNewlineCharactersInString:aString 
			withCharacter:_newlineCharacter];
	}
	
    return [aString dataUsingEncoding:NSShiftJISStringEncoding];
}

- (BOOL)loadDataRepresentation:(NSData*)data ofType:(NSString*)type 
{
	// ファイルから読み込む。(UTF8決めうち。)
	NSMutableString *aString = [[[NSMutableString alloc] initWithData:data encoding:NSShiftJISStringEncoding] autorelease];
    
	// 改行コードの種類を得る。
	_newlineCharacter = [aString newlineCharacter];
	if (_newlineCharacter == OgreNonbreakingNewlineCharacter) {
		// 改行のない場合はOgreUnixNewlineCharacterとみなす。
		//NSLog(@"nonbreaking");
		_newlineCharacter = OgreUnixNewlineCharacter;
	}
	
	// 改行コードを(置換すべきなら)置換する。
	if (_newlineCharacter != OgreUnixNewlineCharacter) {
		[aString replaceNewlineCharactersWithCharacter:OgreUnixNewlineCharacter];
	}
    
    OGRegularExpression *regex = [OGRegularExpression regularExpressionWithString:@"^(?:\"(?@[^\"]*(?:\"\"[^\"]*)*)\"(?:,[ ]*|\\t+|))+$"];
    OGRegularExpression *rmEscRegex = [OGRegularExpression regularExpressionWithString:@"\"\""];
    
    OGRegularExpressionMatch    *match;
    OGRegularExpressionCapture  *capture;
    NSEnumerator                *matchEnumerator = [regex matchEnumeratorInString:aString];
    unsigned                    numberOfCaptures = 0, colIndex;
    NSMutableArray              *array;
    NSString                    *identifier;
    
     NSMutableArray  *dictArray = nil;;
    
    if ((match = [matchEnumerator nextObject]) != nil) {
        capture = [match captureHistory];
        
        numberOfCaptures = [capture numberOfChildren];
        _dict = [[NSMutableDictionary alloc] initWithCapacity:numberOfCaptures];
        //NSLog(@"%d", numberOfCaptures);
        dictArray = [NSMutableArray arrayWithCapacity:numberOfCaptures];
        for (colIndex = 0; colIndex < numberOfCaptures; colIndex++) {
            array = [NSMutableArray arrayWithCapacity:50];
            identifier = [NSString stringWithFormat:@"%d", colIndex + 1];
            [_dict setObject:array forKey:identifier];
            [dictArray addObject:array];
        }
        
        _titleArray = [[NSMutableArray alloc] initWithCapacity:numberOfCaptures];
        for (colIndex = 0; colIndex < numberOfCaptures; colIndex++) {
            [_titleArray addObject:[rmEscRegex replaceAllMatchesInString:[[capture childAtIndex:colIndex] string] withString:@"\""]];
        }
    }
    
    while ((match = [matchEnumerator nextObject]) != nil) {
        capture = [match captureHistory];
        for (colIndex = 0; colIndex < numberOfCaptures; colIndex++) {
            [[dictArray objectAtIndex:colIndex] addObject:[rmEscRegex replaceAllMatchesInString:[[capture childAtIndex:colIndex] string] withString:@"\""]];
        }
    }
	
    _numberOfColumns = numberOfCaptures;
    
    return YES;
}

- (void)windowControllerDidLoadNib:(NSWindowController*)controller
{
	if (_dict != nil) {
        //NSLog(@"%@", [_dict description]);
        unsigned    numberOfColumns = [_dict count], i;
        NSString    *identifier;
        for (i = 0; i < numberOfColumns; i++) {
            // add columns
            identifier = [NSString stringWithFormat:@"%d", i + 1];
            OgreTableColumn   *aColumn = [[[OgreTableColumn alloc] initWithIdentifier:identifier] autorelease];
            NSTableHeaderCell   *headerCell=[[[NSTableHeaderCell alloc] initTextCell:[_titleArray objectAtIndex:i]] autorelease];
            NSTextFieldCell *dataCell=[[[NSTextFieldCell alloc] initTextCell:@""] autorelease];
            [aColumn setHeaderCell:headerCell];
            [aColumn setDataCell:dataCell];
            [dataCell setEditable:YES];
            [aColumn setEditable:YES];
            [tableView addTableColumn:aColumn];
        }
        _titleArray = nil;
        [tableView reloadData];
	} else {
        _dict = [[NSMutableDictionary alloc] init];
		_newlineCharacter = OgreUnixNewlineCharacter;	// デフォルトの改行コード
        
        _numberOfColumns = 0;
	}
    
    [super windowControllerDidLoadNib:controller];
}

// 改行コードの変更
- (void)setNewlineCharacter:(OgreNewlineCharacter)aNewlineCharacter
{
	_newlineCharacter = aNewlineCharacter;
}

- (unsigned)numberOfRows
{
    NSEnumerator *enumerator = [_dict objectEnumerator];
    id value;

    while ((value = [enumerator nextObject]) != nil) {
       return [value count];
    }
    
    return 0;
}

/* NSTableDataSource */
- (int)numberOfRowsInTableView:(NSTableView *)aTableView
{
    return [self numberOfRows];
}

- (id)tableView:(NSTableView *)aTableView objectValueForTableColumn:(NSTableColumn *)aTableColumn row:(int)rowIndex
{
    NSString    *identifier = [aTableColumn identifier];
    NSArray     *array = [_dict objectForKey:identifier];
    
    return [array objectAtIndex:rowIndex];
}

- (void)tableView:(NSTableView *)aTableView setObjectValue:(id)anObject forTableColumn:(NSTableColumn *)aTableColumn row:(int)rowIndex
{
    NSString        *identifier = [aTableColumn identifier];
    NSMutableArray  *array = [_dict objectForKey:identifier];
    
    id  oldObject = [array objectAtIndex:rowIndex];
    if ([oldObject isEqualToString:anObject]) return;
    
    [array replaceObjectAtIndex:rowIndex withObject:anObject];
    [self updateChangeCount:NSChangeDone];
}

/* drag&drop rows */
- (BOOL)tableView:(NSTableView *)aTableView acceptDrop:(id <NSDraggingInfo>)info row:(int)row dropOperation:(NSTableViewDropOperation)operation
{
    NSPasteboard    *pboard = [info draggingPasteboard];
    NSEnumerator    *pEnumerator;
    NSArray         *rowIndexArray;
    NSNumber        *rowIndexNumber;
    
    NSMutableArray  *columnArray;
    NSEnumerator    *columnEnumerator;
    
    NSMutableArray  *middleArray = nil;
    NSEnumerator    *arrayEnumerator;
   
    id              anObject;
    int             overwrapCount = 0, anIndex;
    
    if (operation == NSTableViewDropAbove && [pboard availableTypeFromArray:[NSArray arrayWithObject:gMyTableRowPboardType]] != nil) {
        
        rowIndexArray = [pboard propertyListForType:gMyTableRowPropertyType];
        
        pEnumerator = [rowIndexArray reverseObjectEnumerator];
        while ((rowIndexNumber = [pEnumerator nextObject]) != nil) {
            anIndex = [rowIndexNumber intValue];
            if (anIndex < row) overwrapCount++;
        }
        
        columnEnumerator = [_dict objectEnumerator];
        while ((columnArray = [columnEnumerator nextObject]) != nil) {
            
            middleArray = [NSMutableArray arrayWithCapacity:1];
            pEnumerator = [rowIndexArray reverseObjectEnumerator];
            while ((rowIndexNumber = [pEnumerator nextObject]) != nil) {
                anIndex = [rowIndexNumber intValue];
                [middleArray addObject:[columnArray objectAtIndex:anIndex]];
                [columnArray removeObjectAtIndex:anIndex];
            }
            
            arrayEnumerator = [middleArray objectEnumerator];
            while ((anObject = [arrayEnumerator nextObject]) != nil) [columnArray insertObject:anObject atIndex:(row - overwrapCount)];
        }
        
        [tableView deselectAll:nil];
        for (anIndex = row - overwrapCount; anIndex < (row - overwrapCount + [middleArray count]); anIndex++) {
            [tableView selectRowIndexes:[NSIndexSet indexSetWithIndex: anIndex] byExtendingSelection:[tableView allowsMultipleSelection]];
        }

        [tableView reloadData];
        [self updateChangeCount:NSChangeDone];
        return YES;
        
    } else {
        
        return NO;
    }
}

- (NSDragOperation)tableView:(NSTableView *)tableView validateDrop:(id <NSDraggingInfo>)info proposedRow:(int)row proposedDropOperation:(NSTableViewDropOperation)operation
{
    NSPasteboard *pboard=[info draggingPasteboard];
    if (operation == NSTableViewDropAbove && [pboard availableTypeFromArray:[NSArray arrayWithObject:gMyTableRowPboardType]] != nil) return NSTableViewDropAbove;
    
    return NSDragOperationNone;
}

- (BOOL)tableView:(NSTableView *)tableView writeRows:(NSArray *)rows toPasteboard:(NSPasteboard *)pboard
{
    [pboard declareTypes:[NSArray arrayWithObject:gMyTableRowPboardType] owner:self];
    [pboard setPropertyList:rows forType:gMyTableRowPropertyType];
    
    return YES;
}

/* addition/remove rows and columns */
- (IBAction)addRow:(id)sender
{
    if ([_dict count] == 0) return;
    
    NSMutableArray  *columnArray;
    NSEnumerator    *columnEnumerator = [_dict objectEnumerator];
    
    int selectedRow = [tableView selectedRow], newRowIndex;
    if (selectedRow >= 0) {
        newRowIndex = selectedRow + 1;
    } else {
        newRowIndex = [self numberOfRows];
    }
    while ((columnArray = [columnEnumerator nextObject]) != nil) [columnArray insertObject:[NSString string] atIndex:newRowIndex];
    
    // update
    [tableView reloadData];
    [tableView selectRowIndexes:[NSIndexSet indexSetWithIndex:newRowIndex] byExtendingSelection:NO];
    [tableView scrollRowToVisible:newRowIndex];
    [self updateChangeCount:NSChangeDone];
}

- (IBAction)removeRow:(id)sender
{
    NSIndexSet  *selectedIndexes = [tableView selectedRowIndexes];
#ifdef MAC_OS_X_VERSION_10_6
    NSUInteger  numberOfIndexes = [selectedIndexes count];
    if (numberOfIndexes == 0) return;
    NSMutableArray  *columnArray;
    NSEnumerator    *columnEnumerator = [_dict objectEnumerator];
    while ((columnArray = [columnEnumerator nextObject]) != nil) [columnArray removeObjectsAtIndexes:selectedIndexes];
#else
    unsigned    numberOfIndexes = [selectedIndexes count];
    if (numberOfIndexes == 0) return;
    unsigned    *indexes = (unsigned*)NSZoneMalloc([self zone], numberOfIndexes * sizeof(unsigned));
    if (indexes == NULL) {
        return;
    }
    [selectedIndexes getIndexes:indexes maxCount:numberOfIndexes inIndexRange:NULL];
    
    NSMutableArray  *columnArray;
    NSEnumerator    *columnEnumerator = [_dict objectEnumerator];
    while ((columnArray = [columnEnumerator nextObject]) != nil) [columnArray removeObjectsFromIndices:indexes numIndices:numberOfIndexes];
    NSZoneFree([self zone], indexes);
#endif
    [tableView deselectAll:nil];
    [tableView reloadData];
    [self updateChangeCount:NSChangeDone];
}

- (IBAction)addColumn:(id)sender
{
    NSString    *identifier = [NSString stringWithFormat:@"%d", ++_numberOfColumns];
    
    // create the data source corresponding to new column
    unsigned    i, numberOfRows = [self numberOfRows];
    NSMutableArray  *array = [NSMutableArray arrayWithCapacity:numberOfRows];
    for (i = 0; i < numberOfRows; i++) [array addObject:[NSString string]];
    [_dict setObject:array forKey:identifier];
    
    // add new column
    OgreTableColumn   *aColumn = [[[OgreTableColumn alloc] initWithIdentifier:identifier] autorelease];
    NSTableHeaderCell *headerCell=[[[NSTableHeaderCell alloc] initTextCell:identifier] autorelease];
    NSTextFieldCell *dataCell=[[[NSTextFieldCell alloc] initTextCell:@""] autorelease];
    [aColumn setHeaderCell:headerCell];
    [aColumn setDataCell:dataCell];
    [dataCell setEditable:YES];
    [aColumn setEditable:YES];
    [tableView addTableColumn:aColumn];
    
    // move and select
    int selectIndex;
    int selectedColumn = [tableView selectedColumn];
    if (selectedColumn >= 0) {
        [tableView moveColumn:(_numberOfColumns - 1) toColumn:(selectedColumn + 1)];
        selectIndex = selectedColumn + 1;
    } else {
        selectIndex = _numberOfColumns - 1;
    }
    
    // update
    [tableView reloadData];
    [tableView selectColumnIndexes:[NSIndexSet indexSetWithIndex:selectIndex] byExtendingSelection:NO];
    [tableView scrollColumnToVisible:selectIndex];
    [self updateChangeCount:NSChangeDone];
}

- (IBAction)removeColumn:(id)sender
{
    int selectedColumn = [tableView selectedColumn];
    if (selectedColumn == -1) {
        // no column is selected
        NSBeep();
        return;
    }
    
    while (YES) {
        // remove all selected columns
        NSArray *columnArray = [tableView tableColumns];
        OgreTableColumn   *aColumn = [columnArray objectAtIndex:selectedColumn];
        [_dict removeObjectForKey:[aColumn identifier]];
        
        [tableView removeTableColumn:aColumn];
        
        selectedColumn = [tableView selectedColumn];
        if (selectedColumn == -1) {
            // no column is selected
            // update
            [tableView reloadData];
            [self updateChangeCount:NSChangeDone];
            return;
        }
    }
}

// 
- (void)tableViewDoubleClicked
{
	int	clickedRowIndex = [tableView clickedRow];
    int selectedColumn = [tableView selectedColumn];
	if ((clickedRowIndex != -1) || (selectedColumn == -1)) return;
    
    NSArray         *columnArray = [tableView tableColumns];
    OgreTableColumn   *aColumn = [columnArray objectAtIndex:selectedColumn];
    
    _sheetPosition = [[[tableView window] contentView] convertRect:[tableView frameOfCellAtColumn:selectedColumn row:0] fromView:tableView];
    _sheetPosition.origin.y += _sheetPosition.size.height + 1;
    _sheetPosition.size.height = 0;
    _useCustomSheetPosition = YES;
    
    [[[MyTableColumnSheet alloc] initWithParentWindow:[tableView window] tableColumn:aColumn OKSelector:@selector(changeTitleOfColumn:) CancelSelector:@selector(doNotChangeTitleOfColumn:) target:self] autorelease];
}

- (void)changeTitleOfColumn:(MyTableColumnSheet*)sheet
{
    _useCustomSheetPosition = NO;
    NSTableHeaderCell *headerCell = [[sheet tableColumn] headerCell];
    [headerCell setStringValue:[sheet newTitle]];
}

- (void)doNotChangeTitleOfColumn:(MyTableColumnSheet*)sheet
{
    _useCustomSheetPosition = NO;
}

- (NSRect)window:(NSWindow*)window willPositionSheet:(NSWindow*)sheet usingRect:(NSRect)rect
{
    if (_useCustomSheetPosition) return _sheetPosition;
    
    return rect;
}

@end
