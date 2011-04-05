/*
 * Name: OgreOutlineCellAdapter.m
 * Project: OgreKit
 *
 * Creation Date: Jun 06 2004
 * Author: Isao Sonobe <sonoisa (AT) muse (DOT) ocn (DOT) ne (DOT) jp>
 * Copyright: Copyright (c) 2003 Isao Sonobe, All rights reserved.
 * License: OgreKit License
 *
 * Encoding: UTF8
 * Tabsize: 4
 */

#import <OgreKit/OGPlainString.h>

#import <OgreKit/OgreOutlineCellAdapter.h>
#import <OgreKit/OgreOutlineCellFindResult.h>
#import <OgreKit/OgreOutlineItemAdapter.h>

#import <OgreKit/OgreOutlineView.h>
#import <OgreKit/OgreOutlineColumn.h>

@implementation OgreOutlineCellAdapter

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
    OgreOutlineColumn               *outlineColumn = [self outlineColumn];
    id                              item = [self target];
    NSCell                          *dataCell = [outlineColumn dataCell];
    id                              anObject = nil;
    
    if ([dataCell type] == NSTextCellType) {
        anObject = [outlineColumn ogreObjectValueForItem:item];
        [dataCell setObjectValue:anObject];
        return [[[OGPlainString alloc] initWithString:[dataCell stringValue]] autorelease];
    }
    
    return nil;
}

- (void)setOGString:(NSObject<OGStringProtocol>*)aString
{
    OgreOutlineColumn *outlineColumn = [self outlineColumn];
    if ([outlineColumn isEditable]) {
        id                              item = [self target];
        NSCell                          *dataCell = [outlineColumn dataCell];
        id                              anObject;
        
        [dataCell setStringValue:[aString string]];
        anObject = [dataCell objectValue];
        [outlineColumn ogreSetObjectValue:anObject forItem:item];
    }
}

- (void)replaceCharactersInRange:(NSRange)aRange withOGString:(NSObject<OGStringProtocol>*)aString
{
    OgreOutlineColumn *outlineColumn = [self outlineColumn];
    if ([outlineColumn isEditable]) {
        id                              item = [self target];
        NSCell                          *dataCell = [outlineColumn dataCell];
        id                              anObject;
        
        NSMutableString *newString = [NSMutableString stringWithString:[[self ogString] string]];
        [newString replaceCharactersInRange:aRange withString:[aString string]];
        
        [dataCell setStringValue:newString];
        anObject = [dataCell objectValue];
        [outlineColumn ogreSetObjectValue:anObject forItem:item];
    }
}

- (id)target
{
    return [[self parent] target];
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

- (id)name
{
    OgreOutlineColumn               *outlineColumn = [self outlineColumn];
    id                              item = [self target];
    OgreOutlineView                 *outlineView = (OgreOutlineView*)[outlineColumn tableView];
    NSCell                          *dataCell = [outlineColumn dataCell];
    
    if ([dataCell type] == NSTextCellType) {
        id  anObject = [(OgreOutlineColumn*)[outlineView outlineTableColumn] ogreObjectValueForItem:item];
        [dataCell setObjectValue:anObject];
        
        return [dataCell stringValue];
    }
    
    return nil;
}

- (id)outline 
{
    return @""; 
}

- (BOOL)isEditable 
{
    return [[self outlineColumn] isEditable]; 
}

- (BOOL)isHighlightable 
{
    return NO; 
}

- (OgreFindResultLeaf*)findResultLeafWithThread:(OgreTextFindThread*)aThread
{
    return [[[OgreOutlineCellFindResult alloc] initWithOutlineColumn:[self outlineColumn] item:[self target]] autorelease]; 
}

- (BOOL)isSelected
{
    return YES;
}

- (NSRange)selectedRange
{
    NSRange     fullRange = NSMakeRange(0, [[self ogString] length]);
    
    if ([self isFirstLeaf] || [self isTerminal]) {
        OgreOutlineColumn   *outlineColumn = [self outlineColumn];
        OgreOutlineView     *outlineView = (OgreOutlineView*)[outlineColumn tableView];
        NSRange     selectedRange = [outlineView ogreSelectedRange];
        
        if (selectedRange.location == NSNotFound) {
            selectedRange = fullRange;
            [self setSelectedRange:selectedRange];
        }
        
        return NSIntersectionRange(selectedRange, fullRange);
    }
        
    return fullRange;
}

- (void)setSelectedRange:(NSRange)aRange
{
    OgreOutlineColumn *outlineColumn = [self outlineColumn];
    if (outlineColumn == nil) return;

    OgreOutlineView *outlineView = (OgreOutlineView*)[outlineColumn tableView];
    id              item = [self target];

    if ([outlineView allowsColumnSelection]) {
        int columnIndex = [outlineView columnWithIdentifier:[outlineColumn identifier]];
        if (columnIndex != -1) [outlineView scrollColumnToVisible:columnIndex];
    }
    
    [(OgreOutlineItemAdapter*)[self parent] expandItemEnclosingItem:item];
    int rowIndex = [outlineView rowForItem:item];
    if (rowIndex != -1) {
        [outlineView selectRowIndexes:[NSIndexSet indexSetWithIndex:rowIndex] byExtendingSelection:NO];
        [outlineView scrollRowToVisible:rowIndex];
        
        [outlineView ogreSetSelectedColumn:[outlineView columnWithIdentifier:[outlineColumn identifier]]];
        [outlineView ogreSetSelectedItem:item];
        [outlineView ogreSetSelectedRange:aRange];
    }
}

- (void)jumpToSelection
{
    OgreOutlineColumn   *outlineColumn = [self outlineColumn];
    if (outlineColumn == nil) return;
    OgreOutlineView     *outlineView = (OgreOutlineView*)[outlineColumn tableView];

    if ([outlineView allowsColumnSelection]) {
        int selectedColumnIndex = [outlineView selectedColumn];
        if (selectedColumnIndex != -1) [outlineView scrollColumnToVisible:selectedColumnIndex];
    }
    
    int selectedRowIndex = [outlineView selectedRow];
    if (selectedRowIndex != -1) [outlineView scrollRowToVisible:selectedRowIndex];
}

- (NSWindow*)window
{
    OgreOutlineColumn *outlineColumn = [self outlineColumn];
    return [[outlineColumn tableView] window];
}

- (OgreOutlineColumn*)outlineColumn
{
    return [(OgreOutlineItemAdapter*)[self parent] outlineColumn];
}

@end
