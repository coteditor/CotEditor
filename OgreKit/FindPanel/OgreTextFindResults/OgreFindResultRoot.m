/*
 * Name: OgreTextFindRoot.m
 * Project: OgreKit
 *
 * Creation Date: Apr 18 2004
 * Author: Isao Sonobe <sonoisa (AT) muse (DOT) ocn (DOT) ne (DOT) jp>
 * Copyright: Copyright (c) 2003 Isao Sonobe, All rights reserved.
 * License: OgreKit License
 *
 * Encoding: UTF8
 * Tabsize: 4
 */

#import <OgreKit/OgreFindResultRoot.h>


@implementation OgreFindResultRoot

- (void)addComponent:(NSObject <OgreTextFindComponent>*)aFindResultComponent 
{
    [_component autorelease];
    _component = [aFindResultComponent retain];
}

- (void)endAddition { /* do nothing */ }

- (void)dealloc
{
    [_component release];
    [super dealloc];
}

- (id)name { return @"Root"; }
- (id)outline { return @""; }

- (unsigned)numberOfChildrenInSelection:(BOOL)inSelection 
{
    return ((_component != nil)? 1 : 0);
}

- (id)childAtIndex:(unsigned)index inSelection:(BOOL)inSelection 
{
    return _component;
}

- (NSEnumerator*)componetEnumeratorInSelection:(BOOL)inSelection 
{
    return [[NSArray arrayWithObject:_component] objectEnumerator]; 
}


@end
