/*
 * Name: OgreOutlineViewAdapter.m
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

#import <OgreKit/OgreOutlineView.h>
#import <OgreKit/OgreOutlineColumn.h>

#import <OgreKit/OgreOutlineViewAdapter.h>
#import <OgreKit/OgreOutlineColumnAdapter.h>
#import <OgreKit/OgreOutlineItemAdapter.h>
#import <OgreKit/OgreOutlineCellAdapter.h>

#import <OgreKit/OgreTextFindComponentEnumerator.h>
#import <OgreKit/OgreTextFindReverseComponentEnumerator.h>

#import <OgreKit/OgreOutlineViewFindResult.h>
#import <OgreKit/OgreTextFindThread.h>


@implementation OgreOutlineViewAdapter

- (id)initWithTarget:(id)anOutlineView
{
#ifdef DEBUG_OGRE_FIND_PANEL
	NSLog(@" -initWithTarget: of %@", [self className]);
#endif
    self = [super init];
    if (self != nil) {
        _outlineView = [anOutlineView retain];
    }
    
    return self;
}

- (void)dealloc
{
    [_outlineView release];
    [super dealloc];
}

/* Delegate methods of the OgreTextFindThread */
- (OgreTextFindLeaf*)buildStackForSelectedLeafInThread:(OgreTextFindThread*)aThread
{
    NSEnumerator                *enumerator;
    OgreTextFindBranch          *branch;
    OgreOutlineColumnAdapter    *columnAdapter;
    OgreOutlineItemAdapter      *itemAdapter;
    OgreOutlineCellAdapter      *cellAdapter;
    
    if ([_outlineView numberOfColumns] == 0 || [_outlineView numberOfRows] == 0) return nil;
    int     level = 0, index;
    NSArray *path = [_outlineView ogrePathComponentsOfSelectedItem];
    
    // root
    branch = [aThread rootAdapter];
    enumerator = [branch componentEnumeratorInSelection:[aThread inSelection]];
    [aThread pushEnumerator:enumerator];
    [aThread pushBranch:branch];
    [branch willProcessFinding:aThread];
    [aThread willProcessFindingInBranch:branch];
    
    // outline view
    branch = [enumerator nextObject];
    enumerator = [branch componentEnumeratorInSelection:[aThread inSelection]];
    [(OgreTextFindComponentEnumerator*)enumerator setStartIndex:[_outlineView ogreSelectedColumn]];
    [aThread pushEnumerator:enumerator];
    [aThread pushBranch:branch];
    [branch willProcessFinding:aThread];
    [aThread willProcessFindingInBranch:branch];
    
    // table column
    columnAdapter = [enumerator nextObject];
    enumerator = [columnAdapter componentEnumeratorInSelection:[aThread inSelection]];
    index = [[path objectAtIndex:level] intValue];
    [(OgreTextFindComponentEnumerator*)enumerator setStartIndex:index];
    [aThread pushEnumerator:enumerator];
    [aThread pushBranch:columnAdapter];
    [columnAdapter willProcessFinding:aThread];
    [aThread willProcessFindingInBranch:columnAdapter];
    level++;
    
    // outline items
    while (level < [path count]) {
        itemAdapter = [enumerator nextObject];
        enumerator = [itemAdapter componentEnumeratorInSelection:[aThread inSelection]];
        index = [[path objectAtIndex:level] intValue] + 1 /* item's cell */;
        [(OgreTextFindComponentEnumerator*)enumerator setStartIndex:index];
        [aThread pushEnumerator:enumerator];
        [aThread pushBranch:itemAdapter];
        [itemAdapter willProcessFinding:aThread];
        [aThread willProcessFindingInBranch:itemAdapter];
        level++;
    }
    
    // outline cell
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
    [_outlineView reloadData];
}

/* Getting information */
- (id)target
{
#ifdef DEBUG_OGRE_FIND_PANEL
	NSLog(@"  -target of %@", [self className]);
#endif
    return _outlineView; 
}

- (id)name
{
#ifdef DEBUG_OGRE_FIND_PANEL
	NSLog(@"  -name of %@", [self className]);
#endif
    return [_outlineView className]; 
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
    int count = [_outlineView numberOfSelectedColumns];
    if (inSelection && (count > 0)) return count;
    
    return [_outlineView numberOfColumns];
}

- (id)childAtIndex:(unsigned)index inSelection:(BOOL)inSelection
{
#ifdef DEBUG_OGRE_FIND_PANEL
	NSLog(@"  -childAtIndex: of %@", [self className]);
#endif
    OgreOutlineColumnAdapter    *outlineColumnAdapter;
    OgreOutlineColumn           *column;
    unsigned                    concreteIndex;
    
    if (!inSelection) {
        concreteIndex = index;
    } else {
        NSIndexSet  *selectedColumnIndexes = [_outlineView selectedColumnIndexes];
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
    
    column = [[_outlineView tableColumns] objectAtIndex:concreteIndex];
    outlineColumnAdapter = [[[OgreOutlineColumnAdapter alloc] initWithOutlineColumn:column] autorelease];
    [outlineColumnAdapter setParent:self];
    [outlineColumnAdapter setIndex:index];
    [outlineColumnAdapter setReversed:[self isReversed]];
    
    if ([self isTerminal] && concreteIndex == [_outlineView ogreSelectedColumn]) {
        [outlineColumnAdapter setTerminal:YES];
    }
    
    return outlineColumnAdapter;
}

- (NSEnumerator*)componentEnumeratorInSelection:(BOOL)inSelection
{
#ifdef DEBUG_OGRE_FIND_PANEL
	NSLog(@"  -componentEnumeratorInSelection: of %@", [self className]);
#endif
    int count = [_outlineView numberOfSelectedColumns];
    
    OgreTextFindComponentEnumerator *enumerator;
    if ([self isReversed]) {
        enumerator = [OgreTextFindReverseComponentEnumerator alloc];
    } else {
        enumerator = [OgreTextFindComponentEnumerator alloc];
    }
    [[enumerator initWithBranch:self inSelection:(inSelection && (count > 0))] autorelease];
    if ([self isTerminal]) [enumerator setTerminalIndex:[_outlineView ogreSelectedColumn]];
    
    return enumerator;
}

-(NSIndexSet*)selectedIndexes
{
#ifdef DEBUG_OGRE_FIND_PANEL
	NSLog(@"  -selectedIndexes of %@", [self className]);
#endif
    NSIndexSet *selectedColumnIndexes = [_outlineView selectedColumnIndexes];
    if ([selectedColumnIndexes count] > 0) return selectedColumnIndexes;
    
    return [NSIndexSet indexSetWithIndexesInRange:NSMakeRange(0, [_outlineView numberOfColumns])];
}

- (OgreFindResultBranch*)findResultBranchWithThread:(OgreTextFindThread*)aThread
{
#ifdef DEBUG_OGRE_FIND_PANEL
	NSLog(@"  -findResultBranchWithThread: of %@", [self className]);
#endif
    return [[[OgreOutlineViewFindResult alloc] initWithOutlineView:_outlineView] autorelease];
}

- (OgreTextFindLeaf*)selectedLeaf
{
#ifdef DEBUG_OGRE_FIND_PANEL
	NSLog(@"  -selectedLeaf of %@", [self className]);
#endif
    OgreTextFindBranch          *branch;
    OgreOutlineCellAdapter      *cellAdapter;
    
    if ([_outlineView numberOfColumns] == 0 || [_outlineView numberOfRows] == 0) return nil;
    int     level = 0, index;
    NSArray *path = [_outlineView ogrePathComponentsOfSelectedItem];
    
    // outline view
    [self willProcessFinding:nil];
    
    // table column
    branch = [self childAtIndex:[_outlineView ogreSelectedColumn] inSelection:NO];
    index = [[path objectAtIndex:level] intValue];
    [branch willProcessFinding:nil];
    level++;
    
    // outline items
    while (level < [path count]) {
        branch = [branch childAtIndex:index inSelection:NO];
        index = [[path objectAtIndex:level] intValue] + 1 /* item's cell */;
        [branch willProcessFinding:nil];
        level++;
    }
    
    // outline cell
    cellAdapter = [branch childAtIndex:index inSelection:NO];
    [cellAdapter setFirstLeaf:YES];
    
    return cellAdapter;
}

- (NSWindow*)window
{
#ifdef DEBUG_OGRE_FIND_PANEL
	NSLog(@"  -window of %@", [self className]);
#endif
    return [_outlineView window];
}

- (unsigned)numberOfDescendantsInSelection:(BOOL)inSelection
{
    return -1;  // indeterminate
}

- (void)moveHomePosition
{
    if ([_outlineView numberOfRows] > 0) [_outlineView selectRowIndexes:[NSIndexSet indexSetWithIndex:0] byExtendingSelection:NO];
    [_outlineView ogreSetSelectedColumn:-1];
    [_outlineView ogreSetSelectedItem:nil];
    [_outlineView ogreSetSelectedRange:NSMakeRange(0, 0)];
}

@end
