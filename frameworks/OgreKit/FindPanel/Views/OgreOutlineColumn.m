/*
 * Name: OgreOutlineColumn.m
 * Project: OgreKit
 *
 * Creation Date: Jun 13 2004
 * Author: Isao Sonobe <sonoisa (AT) muse (DOT) ocn (DOT) ne (DOT) jp>
 * Copyright: Copyright (c) 2003 Isao Sonobe, All rights reserved.
 * License: OgreKit License
 *
 * Encoding: UTF8
 * Tabsize: 4
 */

#import <OgreKit/OgreOutlineColumn.h>


@implementation OgreOutlineColumn

- (id)ogreObjectValueForItem:(id)item
{
    id  anObject = nil;
    id  dataSource;
    
    if ((dataSource = [[self tableView] dataSource]) != nil) {
        anObject = [dataSource outlineView:(NSOutlineView*)[self tableView] objectValueForTableColumn:self byItem:item];
    }
    
    return anObject;
}

- (void)ogreSetObjectValue:(id)anObject forItem:(id)item
{
    id  dataSource;
    
    if ((dataSource = [[self tableView] dataSource]) != nil) {
        [dataSource outlineView:(NSOutlineView*)[self tableView] setObjectValue:anObject forTableColumn:self byItem:item];
    }
}

- (int)ogreNumberOfChildrenOfItem:(id)item
{
    id  dataSource;
    
    if ((dataSource = [[self tableView] dataSource]) != nil) {
        return [dataSource outlineView:(NSOutlineView*)[self tableView] numberOfChildrenOfItem:item];
    }
    
    return 0;
}

- (id)ogreChild:(int)index ofItem:(id)item
{
    id  dataSource;
    
    if ((dataSource = [[self tableView] dataSource]) != nil) {
        return [dataSource outlineView:(NSOutlineView*)[self tableView] child:index ofItem:item];
    }
    
    return nil;
}

- (BOOL)ogreIsItemExpandable:(id)item
{
    id  dataSource;
    
    if ((dataSource = [[self tableView] dataSource]) != nil) {
        return [dataSource outlineView:(NSOutlineView*)[self tableView] isItemExpandable:item];
    }
    
    return NO;
}

@end
