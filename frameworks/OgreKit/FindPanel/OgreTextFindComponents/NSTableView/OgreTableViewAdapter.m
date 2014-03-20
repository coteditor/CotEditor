/*
 * Name: OgreTextViewUndoer.m
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

#import <OgreKit/OgreTableView.h>
#import <OgreKit/OgreTableViewAdapter.h>
#import <OgreKit/OgreTableColumnAdapter.h>
#import <OgreKit/OgreTableCellAdapter.h>
#import <OgreKit/OgreTextFindComponentEnumerator.h>
#import <OgreKit/OgreTextFindReverseComponentEnumerator.h>

#import <OgreKit/OgreTableViewFindResult.h>

#import <OgreKit/OgreTextFindThread.h>


@implementation OgreTableViewAdapter

- (id)initWithTarget:(id)aTableView
{
#ifdef DEBUG_OGRE_FIND_PANEL
	NSLog(@" -initWithTarget: of %@", [self className]);
#endif
    self = [super init];
    if (self != nil) {
        _tableView = [aTableView retain];
    }
    
    return self;
}

- (void)dealloc
{
    [_tableView release];
    [super dealloc];
}

/* Delegate methods of the OgreTextFindThread */
- (OgreTextFindLeaf*)buildStackForSelectedLeafInThread:(OgreTextFindThread*)aThread
{
    NSEnumerator            *enumerator;
    OgreTextFindBranch      *branch;
    OgreTableColumnAdapter  *columnAdapter;
    OgreTableCellAdapter    *cellAdapter;
    
    if ([_tableView numberOfColumns] == 0 || [_tableView numberOfRows] == 0) return nil;
    
    // root
    branch = [aThread rootAdapter];
    enumerator = [branch componentEnumeratorInSelection:[aThread inSelection]];
    [aThread pushEnumerator:enumerator];
    [aThread pushBranch:branch];
    [branch willProcessFinding:aThread];
    [aThread willProcessFindingInBranch:branch];
    
    // table view
    branch = [enumerator nextObject];
    enumerator = [branch componentEnumeratorInSelection:[aThread inSelection]];
    [(OgreTextFindComponentEnumerator*)enumerator setStartIndex:[_tableView ogreSelectedColumn]];
    [aThread pushEnumerator:enumerator];
    [aThread pushBranch:branch];
    [branch willProcessFinding:aThread];
    [aThread willProcessFindingInBranch:branch];
    
    // table column
    columnAdapter = [enumerator nextObject];
    enumerator = [columnAdapter componentEnumeratorInSelection:[aThread inSelection]];
    [(OgreTextFindComponentEnumerator*)enumerator setStartIndex:[_tableView ogreSelectedRow]];
    [aThread pushEnumerator:enumerator];
    [aThread pushBranch:columnAdapter];
    [columnAdapter willProcessFinding:aThread];
    [aThread willProcessFindingInBranch:columnAdapter];
    
    // table cell
    cellAdapter = [enumerator nextObject];
    [cellAdapter setFirstLeaf:YES];
    //[cellAdapter willProcessFinding:aThread];
    //[aThread willProcessFindingInLeaf:cellAdapter];
    [aThread _setLeafProcessing:cellAdapter];
    
    return cellAdapter;
}

- (void)willProcessFinding:(NSObject <OgreTextFindVisitor>*)aVisitor 
{
#ifdef DEBUG_OGRE_FIND_PANEL
	NSLog(@"  -willProcessFinding: of %@", [self className]);
#endif
    /* do nothing */ 
}

- (void)didProcessFinding:(NSObject <OgreTextFindVisitor>*)aVisitor
{
#ifdef DEBUG_OGRE_FIND_PANEL
	NSLog(@"  -didProcessFinding: of %@", [self className]);
#endif
    [_tableView reloadData];
}

/* Getting information */
- (id)target
{
#ifdef DEBUG_OGRE_FIND_PANEL
	NSLog(@"  -target of %@", [self className]);
#endif
    return _tableView; 
}

- (id)name
{
#ifdef DEBUG_OGRE_FIND_PANEL
	NSLog(@"  -name of %@", [self className]);
#endif
    return [_tableView className]; 
}

- (id)outline
{
#ifdef DEBUG_OGRE_FIND_PANEL
	NSLog(@"  -outline of %@", [self className]);
#endif
    return @""; 
}


/* Examing behavioral attributes */
- (BOOL)isEditable { return YES; }
- (BOOL)isHighlightable { return NO; }

/* Getting structural detail */
- (unsigned)numberOfChildrenInSelection:(BOOL)inSelection
{
#ifdef DEBUG_OGRE_FIND_PANEL
	NSLog(@"  -numberOfChildrenInSelection: of %@", [self className]);
#endif
    int count = [_tableView numberOfSelectedColumns];
    if (inSelection && (count > 0)) return count;
    
    return [_tableView numberOfColumns];
}

- (id)childAtIndex:(unsigned)index inSelection:(BOOL)inSelection
{
#ifdef DEBUG_OGRE_FIND_PANEL
	NSLog(@"  -childAtIndex: of %@", [self className]);
#endif
    OgreTableColumnAdapter  *tableColumnAdapter;
    OgreTableColumn         *column;
    unsigned                concreteIndex;
    
    if (!inSelection) {
        concreteIndex = index;
    } else {
        NSIndexSet  *selectedColumnIndexes = [_tableView selectedColumnIndexes];
        if ([selectedColumnIndexes count] == 0) {
            concreteIndex = index;
        } else {
            if (index >= [selectedColumnIndexes count]) return nil;
            
#ifdef MAC_OS_X_VERSION_10_6
            NSUInteger  *indexes = (NSUInteger*)NSZoneMalloc([self zone], sizeof(NSUInteger) * [selectedColumnIndexes count]);
#else
            unsigned    *indexes = (unsigned*)NSZoneMalloc([self zone], sizeof(unsigned) * [selectedColumnIndexes count]);
#endif
            if (indexes == NULL) {
                // エラー
                return nil;
            }
            [selectedColumnIndexes getIndexes:indexes maxCount:[selectedColumnIndexes count] inIndexRange:NULL];
            concreteIndex = *(indexes + index);
            NSZoneFree([self zone], indexes);
        }
    }
    
    column = [[_tableView tableColumns] objectAtIndex:concreteIndex];
    tableColumnAdapter = [[[OgreTableColumnAdapter alloc] initWithTableColumn:column] autorelease];
    [tableColumnAdapter setParent:self];
    [tableColumnAdapter setIndex:index];
    [tableColumnAdapter setReversed:[self isReversed]];
    
    if ([self isTerminal] && concreteIndex == [_tableView ogreSelectedColumn]) {
        [tableColumnAdapter setTerminal:YES];
    }
    
    return tableColumnAdapter;
}

- (NSEnumerator*)componentEnumeratorInSelection:(BOOL)inSelection
{
#ifdef DEBUG_OGRE_FIND_PANEL
	NSLog(@"  -componentEnumeratorInSelection: of %@", [self className]);
#endif
    int count = [_tableView numberOfSelectedColumns];
    OgreTextFindComponentEnumerator *enumerator;
    if ([self isReversed]) {
        enumerator = [OgreTextFindReverseComponentEnumerator alloc];
    } else {
        enumerator = [OgreTextFindComponentEnumerator alloc];
    }
    [[enumerator initWithBranch:self inSelection:(inSelection && (count > 0))] autorelease];
    if ([self isTerminal]) [enumerator setTerminalIndex:[_tableView ogreSelectedColumn]];
    
    return enumerator;
}

-(NSIndexSet*)selectedIndexes
{
#ifdef DEBUG_OGRE_FIND_PANEL
	NSLog(@"  -selectedIndexes of %@", [self className]);
#endif
    NSIndexSet *selectedColumnIndexes = [_tableView selectedColumnIndexes];
    if ([selectedColumnIndexes count] > 0) return selectedColumnIndexes;
    
    return [NSIndexSet indexSetWithIndexesInRange:NSMakeRange(0, [_tableView numberOfColumns])];
}

- (OgreFindResultBranch*)findResultBranchWithThread:(OgreTextFindThread*)aThread
{
#ifdef DEBUG_OGRE_FIND_PANEL
	NSLog(@"  -findResultBranchWithThread: of %@", [self className]);
#endif
    return [[[OgreTableViewFindResult alloc] initWithTableView:_tableView] autorelease];
}

- (OgreTextFindLeaf*)selectedLeaf
{
#ifdef DEBUG_OGRE_FIND_PANEL
	NSLog(@"  -selectedLeaf of %@", [self className]);
#endif
    OgreTableColumnAdapter  *columnAdapter;
    OgreTableCellAdapter    *cellAdapter;
    
    if ([_tableView numberOfColumns] == 0 || [_tableView numberOfRows] == 0) return nil;
    
    // table view
    [self willProcessFinding:nil];
    
    // table column
    columnAdapter = [self childAtIndex:[_tableView ogreSelectedColumn] inSelection:NO];
    [columnAdapter willProcessFinding:nil];
    
    // table cell
    cellAdapter = [columnAdapter childAtIndex:[_tableView ogreSelectedRow] inSelection:NO];
    [cellAdapter setFirstLeaf:YES];
    
    return cellAdapter;
}

- (NSWindow*)window
{
#ifdef DEBUG_OGRE_FIND_PANEL
	NSLog(@"  -window of %@", [self className]);
#endif
    return [_tableView window];
}

- (void)moveHomePosition
{
    if ([_tableView numberOfRows] > 0) [_tableView selectRowIndexes:[NSIndexSet indexSetWithIndex:0] byExtendingSelection:NO];
    [_tableView ogreSetSelectedColumn:-1];
    [_tableView ogreSetSelectedRow:-1];
    [_tableView ogreSetSelectedRange:NSMakeRange(0, 0)];
}

@end
