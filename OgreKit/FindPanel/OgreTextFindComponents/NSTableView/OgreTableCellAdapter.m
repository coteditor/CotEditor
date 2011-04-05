/*
 * Name: OgreTableCellAdapter.m
 * Project: OgreKit
 *
 * Creation Date: Jun 05 2004
 * Author: Isao Sonobe <sonoisa (AT) muse (DOT) ocn (DOT) ne (DOT) jp>
 * Copyright: Copyright (c) 2003 Isao Sonobe, All rights reserved.
 * License: OgreKit License
 *
 * Encoding: UTF8
 * Tabsize: 4
 */

#import <OgreKit/OGPlainString.h>


#import <OgreKit/OgreTableView.h>
#import <OgreKit/OgreTableCellAdapter.h>
#import <OgreKit/OgreTableCellFindResult.h>
#import <OgreKit/OgreTextFindThread.h>

#import <OgreKit/OgreTableColumn.h>

@implementation OgreTableCellAdapter

- (id)initWithTableColumn:(OgreTableColumn*)tableColumn row:(int)rowIndex
{
#ifdef DEBUG_OGRE_FIND_PANEL
	NSLog(@" -initWithTextView: of %@", [self className]);
#endif
    self = [super init];
    if (self != nil) {
        _tableColumn = [tableColumn retain];
        _rowIndex = rowIndex;
    }
    
    return self;
}

- (void)dealloc
{
    [_tableColumn release];
    [super dealloc];
}

/* protocol of OgreTextFindComponent */
/* Delegate methods of the OgreTextFindVisitor */
- (void)willProcessFinding:(NSObject <OgreTextFindVisitor>*)aVisitor
{
#ifdef DEBUG_OGRE_FIND_PANEL
	NSLog(@" -willProcessFinding: of %@", [self className]);
#endif
    /* do nothing */
}

- (void)didProcessFinding:(NSObject <OgreTextFindVisitor>*)aVisitor
{
#ifdef DEBUG_OGRE_FIND_PANEL
	NSLog(@" -didProcessFinding: of %@", [self className]);
#endif
    /* do nothing */
}


/* Accessor methods */
- (NSObject<OGStringProtocol>*)ogString
{
    NSCell          *dataCell = [_tableColumn dataCell];
    id              anObject = nil;
    
    if ([dataCell type] == NSTextCellType) {
        anObject = [_tableColumn ogreObjectValueForRow:_rowIndex];
        [dataCell setObjectValue:anObject];
        return [[[OGPlainString alloc] initWithString:[dataCell stringValue]] autorelease];
    }
    
    return nil;
}

- (void)setOGString:(NSObject<OGStringProtocol>*)aString
{
    if ([_tableColumn isEditable]) {
        NSCell          *dataCell = [_tableColumn dataCell];
        id              anObject = nil;
        
        [dataCell setStringValue:[aString string]];
        anObject = [dataCell objectValue];
        [_tableColumn ogreSetObjectValue:anObject forRow:_rowIndex];
    }
}

- (void)replaceCharactersInRange:(NSRange)aRange withOGString:(NSObject<OGStringProtocol>*)aString
{
    if ([_tableColumn isEditable]) {
        NSCell          *dataCell = [_tableColumn dataCell];
        id              anObject = nil;
        
        NSMutableString *newString = [NSMutableString stringWithString:[[self ogString] string]];
        [newString replaceCharactersInRange:aRange withString:[aString string]];
        
        [dataCell setStringValue:newString];
        anObject = [dataCell objectValue];
        [_tableColumn ogreSetObjectValue:anObject forRow:_rowIndex];
    }
}

- (id)target
{
    return [_tableColumn dataCellForRow:_rowIndex];
}

- (void)beginEditing
{
#ifdef DEBUG_OGRE_FIND_PANEL
	NSLog(@" -beginEditing of %@", [self className]);
#endif
}

- (void)beginRegisteringUndoWithCapacity:(unsigned)aCapacity
{
}

- (void)endRegisteringUndo
{
}

- (void)endEditing
{
#ifdef DEBUG_OGRE_FIND_PANEL
	NSLog(@" -endEditing of %@", [self className]);
#endif
}

- (void)unhighlight
{
}

- (void)highlightCharactersInRange:(NSRange)aRange color:(NSColor*)highlightColor
{
}

- (id)name { return [[_tableColumn dataCell] className]; }
- (id)outline { return @""; }

- (BOOL)isEditable { return [_tableColumn isEditable]; }
- (BOOL)isHighlightable { return NO; }

- (OgreFindResultLeaf*)findResultLeafWithThread:(OgreTextFindThread*)aThread
{
    return [[[OgreTableCellFindResult alloc] initWithTableColumn:_tableColumn row:_rowIndex] autorelease]; 
}

- (BOOL)isSelected
{
    return YES;
}

- (NSRange)selectedRange
{
    NSRange     fullRange = NSMakeRange(0, [[self ogString] length]);
    
    if ([self isFirstLeaf] || [self isTerminal]) {
        NSRange     selectedRange = [(OgreTableView*)[_tableColumn tableView] ogreSelectedRange];
        if (selectedRange.location == NSNotFound) {
            selectedRange = fullRange;
            [self setSelectedRange:selectedRange];
        }
        
        return NSIntersectionRange(fullRange, selectedRange);
    }
    
    return fullRange;
}

- (void)setSelectedRange:(NSRange)aRange
{
    if (_tableColumn == nil) return;
    OgreTableView *tableView = (OgreTableView*)[_tableColumn tableView];
    
    [tableView selectRowIndexes:[NSIndexSet indexSetWithIndex:_rowIndex] byExtendingSelection:NO];
    
    [tableView ogreSetSelectedColumn:[tableView columnWithIdentifier:[_tableColumn identifier]]];
    [tableView ogreSetSelectedRow:_rowIndex];
    [tableView ogreSetSelectedRange:aRange];
}

- (void)jumpToSelection
{
    if (_tableColumn == nil) return;
    OgreTableView   *tableView = (OgreTableView*)[_tableColumn tableView];
    
    if ([tableView allowsColumnSelection]) {
        int selectedColumnIndex = [tableView selectedColumn];
        if (selectedColumnIndex != -1) [tableView scrollColumnToVisible:selectedColumnIndex];
    }
    
    int selectedRowIndex = [tableView selectedRow];
    if (selectedRowIndex != -1) [tableView scrollRowToVisible:selectedRowIndex];
}

- (NSWindow*)window
{
    return [[_tableColumn tableView] window];
}

@end
