/*
 * Name: OgreTableViewFindResult.m
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

#import <OgreKit/OgreTableViewFindResult.h>
#import <OgreKit/OgreTableColumnFindResult.h>
#import <OgreKit/OgreTextFindResult.h>

#import <OgreKit/OgreTableView.h>

@implementation OgreTableViewFindResult

- (id)initWithTableView:(OgreTableView*)tableView
{
    self = [super init];
    if (self != nil) {
        _tableView = [tableView retain];
        _components = [[NSMutableArray alloc] initWithCapacity:[_tableView numberOfColumns]];
    }
    return self;
}

#ifdef MAC_OS_X_VERSION_10_6
- (void)finalize
{
	[[NSNotificationCenter defaultCenter] removeObserver:self];
    [super finalize];
}
#endif

- (void)dealloc
{
	[[NSNotificationCenter defaultCenter] removeObserver:self];

    [_tableView release];
    [_components release];
    [super dealloc];
}

- (void)addComponent:(NSObject <OgreTextFindComponent>*)aFindResultComponent 
{
    [_components addObject:aFindResultComponent];
}

- (void)endAddition
{
	//targetのあるwindowのcloseを検出する。
	[[NSNotificationCenter defaultCenter] addObserver: self 
		selector: @selector(windowWillClose:) 
		name: NSWindowWillCloseNotification
		object: [_tableView window]];
	
    int columnIndex = 0;
    OgreTableColumnFindResult  *columnFindResult;
    
    while (columnIndex < [_components count]) {
        columnFindResult = [_components objectAtIndex:columnIndex];
        if ([columnFindResult numberOfChildrenInSelection:NO] == 0) {
            [_components removeObjectAtIndex:columnIndex];
        } else {
            columnIndex++;
        }
    }
}

- (id)name
{
    if (_tableView == nil) return [[self textFindResult] missingString];
    return [_tableView className];
}

- (id)outline
{
    if (_tableView == nil) return [[self textFindResult] missingString];
    return [[self textFindResult] messageOfItemsFound:[_components count]];
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
    if (_tableView == nil) return NO;
    
	[[_tableView window] makeKeyAndOrderFront:self];
    return YES;
}

- (BOOL)selectMatchedString
{
    return (_tableView != nil);
}

- (void)windowWillClose:(NSNotification*)aNotification
{
#ifdef DEBUG_OGRE_FIND_PANEL
	NSLog(@"-windowWillClose: of %@", [self className]);
#endif
	[[NSNotificationCenter defaultCenter] removeObserver:self];
    [_tableView release];
	_tableView = nil;
    [_components makeObjectsPerformSelector:@selector(targetIsMissing)];
    [[self textFindResult] didUpdate];
}

@end
