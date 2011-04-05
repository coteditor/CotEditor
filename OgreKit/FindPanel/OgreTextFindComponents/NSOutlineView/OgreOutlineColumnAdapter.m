/*
 * Name: OgreOutlineColumnAdapter.m
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

#import <OgreKit/OgreOutlineColumnAdapter.h>
#import <OgreKit/OgreOutlineItemAdapter.h>
#import <OgreKit/OgreTextFindComponentEnumerator.h>
#import <OgreKit/OgreTextFindReverseComponentEnumerator.h>

#import <OgreKit/OgreOutlineColumnFindResult.h>

#import <OgreKit/OgreOutlineView.h>
#import <OgreKit/OgreOutlineColumn.h>

@implementation OgreOutlineColumnAdapter

- (id)initWithOutlineColumn:(OgreOutlineColumn*)anOutlineColumn
{
#ifdef DEBUG_OGRE_FIND_PANEL
	NSLog(@" -initWithOutlineColumn: of %@", [self className]);
#endif
    self = [super init];
    if (self != nil) {
        _outlineColumn = [anOutlineColumn retain];
    }
    return self;
}

- (void)dealloc
{
    [_outlineColumn release];
    [super dealloc];
}

/* Delegate methods of the OgreTextFindThread */
- (void)willProcessFinding:(NSObject <OgreTextFindVisitor>*)aVisitor 
{
#ifdef DEBUG_OGRE_FIND_PANEL
	NSLog(@"  -willProcessFinding: of %@(%@)", [self className], [self name]);
#endif
    /* do nothing */ 
}

- (void)didProcessFinding:(NSObject <OgreTextFindVisitor>*)aVisitor
{
#ifdef DEBUG_OGRE_FIND_PANEL
	NSLog(@"  -didProcessFinding: of %@(%@)", [self className], [self name]);
#endif
    /* do nothing */ 
}

/* Getting information */
- (id)target
{
#ifdef DEBUG_OGRE_FIND_PANEL
	NSLog(@"  -target of %@", [self className]);
#endif
    return _outlineColumn; 
}

- (id)name
{
#ifdef DEBUG_OGRE_FIND_PANEL
	NSLog(@"  -name of %@", [self className]);
#endif
    return [[_outlineColumn headerCell] stringValue]; 
}

- (id)outline
{
#ifdef DEBUG_OGRE_FIND_PANEL
	NSLog(@"  -outline of %@", [self className]);
#endif
    return @"";
}


/* Examing behavioral attributes */
- (BOOL)isEditable { return [_outlineColumn isEditable]; }
- (BOOL)isHighlightable { return NO; }

/* Getting structural detail */
- (unsigned)numberOfChildrenInSelection:(BOOL)inSelection
{
#ifdef DEBUG_OGRE_FIND_PANEL
	NSLog(@"  -numberOfChildrenInSelection: of %@", [self className]);
#endif
    if ([_outlineColumn isKindOfClass:[OgreOutlineColumn class]]) {
        return [_outlineColumn ogreNumberOfChildrenOfItem:nil /* root */];
    }
    
    return 0;
}

- (id)childAtIndex:(unsigned)index inSelection:(BOOL)inSelection
{
#ifdef DEBUG_OGRE_FIND_PANEL
	NSLog(@"  -childAtIndex:%d of %@", index, [self className]);
#endif
    id  item = [_outlineColumn ogreChild:index ofItem:nil /* root */];
    
    OgreOutlineItemAdapter  *outlineItemAdapter;
    outlineItemAdapter = [[[OgreOutlineItemAdapter alloc] initWithOutlineColumn:_outlineColumn item:item] autorelease];
    [outlineItemAdapter setParent:self];
    [outlineItemAdapter setIndex:index];
    [outlineItemAdapter setLevel:0];
    [outlineItemAdapter setReversed:[self isReversed]];
    
    if ([self isTerminal] && index == [[[(OgreOutlineView*)[_outlineColumn tableView] ogrePathComponentsOfSelectedItem] objectAtIndex:0] intValue]) {
        [outlineItemAdapter setTerminal:YES];
    }
    
    return outlineItemAdapter;
}

- (NSEnumerator*)componentEnumeratorInSelection:(BOOL)inSelection
{
#ifdef DEBUG_OGRE_FIND_PANEL
	NSLog(@"  -componentEnumeratorInSelection: of %@", [self className]);
#endif
    //unsigned count = [self numberOfChildrenInSelection:inSelection];
    
    OgreTextFindComponentEnumerator *enumerator;
    if ([self isReversed]) {
        enumerator = [OgreTextFindReverseComponentEnumerator alloc];
    } else {
        enumerator = [OgreTextFindComponentEnumerator alloc];
    }
    [[enumerator initWithBranch:self inSelection:(inSelection/* && (count > 0)*/)] autorelease];
    if ([self isTerminal]) [enumerator setTerminalIndex:[[[(OgreOutlineView*)[_outlineColumn tableView] ogrePathComponentsOfSelectedItem] objectAtIndex:0] intValue]];

    return enumerator;
}

-(NSIndexSet*)selectedIndexes
{
#ifdef DEBUG_OGRE_FIND_PANEL
	NSLog(@"  -selectedIndexes of %@", [self className]);
#endif
    unsigned count = [self numberOfChildrenInSelection:YES];
    
    return [NSIndexSet indexSetWithIndexesInRange:NSMakeRange(0, count)];
}

- (OgreFindResultBranch*)findResultBranchWithThread:(OgreTextFindThread*)aThread
{
#ifdef DEBUG_OGRE_FIND_PANEL
	NSLog(@"  -findResultBranchWithThread: of %@", [self className]);
#endif
    return [[[OgreOutlineColumnFindResult alloc] initWithOutlineColumn:_outlineColumn] autorelease];
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
    return [[_outlineColumn tableView] window];
}

- (void)expandItemEnclosingItem:(id)item
{
    /* do nothing */
}

@end
