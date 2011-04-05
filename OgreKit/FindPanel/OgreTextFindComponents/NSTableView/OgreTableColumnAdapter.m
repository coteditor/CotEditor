/*
 * Name: OgreTableColumnAdapter.m
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

#import <OgreKit/OgreTableColumn.h>
#import <OgreKit/OgreTableColumnAdapter.h>
#import <OgreKit/OgreTableCellAdapter.h>

#import <OgreKit/OgreTextFindComponentEnumerator.h>
#import <OgreKit/OgreTextFindReverseComponentEnumerator.h>

#import <OgreKit/OgreTableColumnFindResult.h>
#import <OgreKit/OgreTableView.h>

@implementation OgreTableColumnAdapter

- (id)initWithTableColumn:(OgreTableColumn*)aTableColumn
{
#ifdef DEBUG_OGRE_FIND_PANEL
	NSLog(@" -initWithTableColumn: of %@", [self className]);
#endif
    self = [super init];
    if (self != nil) {
        _tableColumn = [aTableColumn retain];
    }
    return self;
}

- (void)dealloc
{
    [_tableColumn release];
    [super dealloc];
}

/* Delegate methods of the OgreTextFindThread */
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
    /* do nothing */ 
}

/* Getting information */
- (id)target
{
#ifdef DEBUG_OGRE_FIND_PANEL
	NSLog(@"  -target of %@", [self className]);
#endif
    return _tableColumn; 
}

- (id)name
{
#ifdef DEBUG_OGRE_FIND_PANEL
	NSLog(@"  -name of %@", [self className]);
#endif
    return [[_tableColumn headerCell] stringValue]; 
}

- (id)outline
{
#ifdef DEBUG_OGRE_FIND_PANEL
	NSLog(@"  -outline of %@", [self className]);
#endif
    return @"";
}


/* Examing behavioral attributes */
- (BOOL)isEditable { return [_tableColumn isEditable]; }
- (BOOL)isHighlightable { return NO; }

/* Getting structural detail */
- (unsigned)numberOfChildrenInSelection:(BOOL)inSelection
{
#ifdef DEBUG_OGRE_FIND_PANEL
	NSLog(@"  -numberOfChildrenInSelection: of %@", [self className]);
#endif
    if ([_tableColumn isKindOfClass:[OgreTableColumn class]]) {
        int count = [[_tableColumn tableView] numberOfSelectedRows];
        if (inSelection && (count > 0)) return count;
        
        return [[_tableColumn tableView] numberOfRows];
    }
    
    return 0;
}

- (id)childAtIndex:(unsigned)index inSelection:(BOOL)inSelection
{
#ifdef DEBUG_OGRE_FIND_PANEL
	NSLog(@"  -childAtIndex: of %@", [self className]);
#endif
    OgreTableCellAdapter *tableCellAdapter;
    unsigned            rowIndex;
    
    if (!inSelection) {
        rowIndex = index;
    } else {
        NSIndexSet  *selectedRowIndexes = [[_tableColumn tableView] selectedRowIndexes];
        if ([selectedRowIndexes count] == 0) {
            rowIndex = index;
        } else {
            if (index >= [selectedRowIndexes count]) return nil;
            
#ifdef MAC_OS_X_VERSION_10_6
            NSUInteger  *indexes = (NSUInteger*)NSZoneMalloc([self zone], sizeof(NSUInteger) * [selectedRowIndexes count]);
#else
            unsigned    *indexes = (unsigned*)NSZoneMalloc([self zone], sizeof(unsigned) * [selectedRowIndexes count]);
#endif
            if (indexes == NULL) {
                // エラー
                return nil;
            }
            [selectedRowIndexes getIndexes:indexes maxCount:[selectedRowIndexes count] inIndexRange:NULL];
            rowIndex = *(indexes + index);
            NSZoneFree([self zone], indexes);
        }
    }
    
    tableCellAdapter = [[[OgreTableCellAdapter alloc] initWithTableColumn:_tableColumn row:rowIndex] autorelease];
    [tableCellAdapter setParent:self];
    [tableCellAdapter setIndex:index];
    [tableCellAdapter setReversed:[self isReversed]];
    
    if ([self isTerminal] && rowIndex == [(OgreTableView*)[_tableColumn tableView] ogreSelectedRow]) {
        [tableCellAdapter setTerminal:YES];
    }
    
    return tableCellAdapter;
}

- (NSEnumerator*)componentEnumeratorInSelection:(BOOL)inSelection
{
#ifdef DEBUG_OGRE_FIND_PANEL
	NSLog(@"  -componentEnumeratorInSelection: of %@", [self className]);
#endif
    int count = [[_tableColumn tableView] numberOfSelectedRows];
    
    OgreTextFindComponentEnumerator *enumerator;
    if ([self isReversed]) {
        enumerator = [OgreTextFindReverseComponentEnumerator alloc];
    } else {
        enumerator = [OgreTextFindComponentEnumerator alloc];
    }
    [[enumerator initWithBranch:self inSelection:(inSelection && (count > 0))] autorelease];
    if ([self isTerminal]) [enumerator setTerminalIndex:[(OgreTableView*)[_tableColumn tableView] ogreSelectedRow]];
    
    return enumerator;
}

-(NSIndexSet*)selectedIndexes
{
#ifdef DEBUG_OGRE_FIND_PANEL
	NSLog(@"  -selectedIndexes of %@", [self className]);
#endif
    NSIndexSet *selectedRowIndexes = [[_tableColumn tableView] selectedRowIndexes];
    if ([selectedRowIndexes count] > 0) return selectedRowIndexes;
    
    return [NSIndexSet indexSetWithIndexesInRange:NSMakeRange(0, [[_tableColumn tableView] numberOfRows])];
}

- (OgreFindResultBranch*)findResultBranchWithThread:(OgreTextFindThread*)aThread
{
#ifdef DEBUG_OGRE_FIND_PANEL
	NSLog(@"  -findResultBranchWithThread: of %@", [self className]);
#endif
    return [[[OgreTableColumnFindResult alloc] initWithTableColumn:_tableColumn] autorelease];
}

- (OgreTextFindLeaf*)selectedLeaf
{
#ifdef DEBUG_OGRE_FIND_PANEL
	NSLog(@"  -selectedLeaf of %@", [self className]);
#endif
    return [[self childAtIndex:0 inSelection:YES] selectedLeaf];
}

- (NSWindow*)window
{
#ifdef DEBUG_OGRE_FIND_PANEL
	NSLog(@"  -window of %@", [self className]);
#endif
    return [[_tableColumn tableView] window];
}

@end
