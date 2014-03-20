/*
 * Name: OgreOutlineColumnFindResult.m
 * Project: OgreKit
 *
 * Creation Date: Jun 07 2004
 * Author: Isao Sonobe <sonoisa (AT) muse (DOT) ocn (DOT) ne (DOT) jp>
 * Copyright: Copyright (c) 2003 Isao Sonobe, All rights reserved.
 * License: OgreKit License
 *
 * Encoding: UTF8
 * Tabsize: 4
 */

#import <OgreKit/OgreOutlineColumnFindResult.h>
#import <OgreKit/OgreTextFindResult.h>

#import <OgreKit/OgreOutlineView.h>
#import <OgreKit/OgreOutlineColumn.h>

@implementation OgreOutlineColumnFindResult

- (id)initWithOutlineColumn:(OgreOutlineColumn*)outlineColumn
{
    self = [super init];
    if (self != nil) {
        _outlineColumn = [outlineColumn retain];
        _components = [[NSMutableArray alloc] initWithCapacity:[[_outlineColumn tableView] numberOfColumns]];
    }
    return self;
}

- (void)dealloc
{
    [_outlineColumn release];
    [_components release];
    [super dealloc];
}

- (void)addComponent:(NSObject <OgreTextFindComponent>*)aFindResultComponent 
{
    [_components addObject:aFindResultComponent];
}

- (void)endAddition
{
    int i = 0;
    while (i < [_components count]) {
        if ([[_components objectAtIndex:i] numberOfChildrenInSelection:NO] == 0) {
            [_components removeObjectAtIndex:i];
        } else {
            i++;
        }
    }
}

- (void)mergeFindResult:(OgreOutlineCellFindResult*)aBranch
{
}

- (void)replaceFindResult:(OgreOutlineItemFindResult*)aBranch withFindResultsFromArray:(NSArray*)resultsArray
{    
}

- (id)name 
{
    if (_outlineColumn == nil) return [[self textFindResult] missingString];
    
    return [[_outlineColumn headerCell] stringValue];
}

- (id)outline 
{
    if (_outlineColumn == nil) return [[self textFindResult] missingString];
    
    return [[self textFindResult] messageOfItemsFound:[self numberOfChildrenInSelection:NO]]; 
}

- (unsigned)numberOfChildrenInSelection:(BOOL)inSelection 
{
    return [_components count];
}

- (id)childAtIndex:(unsigned)index inSelection:(BOOL)inSelection 
{
    return [_components objectAtIndex:index];
}

- (NSEnumerator*)componetEnumeratorInSelection:(BOOL)inSelection 
{
    return [_components objectEnumerator]; 
}

- (BOOL)showMatchedString
{
    if (_outlineColumn == nil) return NO;
    OgreOutlineView *outlineView = (OgreOutlineView*)[_outlineColumn tableView];
    
    [[outlineView window] makeKeyAndOrderFront:self];
    return [self selectMatchedString];
}

- (BOOL)selectMatchedString
{
    if (_outlineColumn == nil) return NO;
    OgreOutlineView *outlineView = (OgreOutlineView*)[_outlineColumn tableView];
    
    if (![outlineView allowsColumnSelection]) return YES;
    
    int columnIndex = [outlineView columnWithIdentifier:[_outlineColumn identifier]];
    if (columnIndex != -1) {
        [outlineView selectColumnIndexes:[NSIndexSet indexSetWithIndex:columnIndex] byExtendingSelection:NO];
        [outlineView scrollColumnToVisible:columnIndex];
    } else {
        [self targetIsMissing];
        return NO;
    }
    
    return (columnIndex != -1);
}

- (void)targetIsMissing
{
    [_outlineColumn release];
    _outlineColumn = nil;
    [_components makeObjectsPerformSelector:@selector(targetIsMissing)];
}


- (void)expandItemEnclosingItem:(id)item
{
    /* do nothing */
}

@end
