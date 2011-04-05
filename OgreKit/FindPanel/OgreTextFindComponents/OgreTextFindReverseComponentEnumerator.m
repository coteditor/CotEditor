/*
 * Name: OgreTextFindReverseComponentEnumerator.m
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

#import <OgreKit/OgreTextFindReverseComponentEnumerator.h>
#import <OgreKit/OgreTextFindBranch.h>


@implementation OgreTextFindReverseComponentEnumerator

- (id)initWithBranch:(OgreTextFindBranch*)aBranch inSelection:(BOOL)inSelection
{
    self = [super initWithBranch:aBranch inSelection:inSelection];
    if (self != nil) {
        _nextIndex = _count - 1;
        _terminalIndex = 0;
    }
    return self;
}

- (id)nextObject
{
    if (_nextIndex < _terminalIndex) return nil;
    unsigned    concreteIndex;
    
    if (_inSelection) {
        concreteIndex = *(_indexes + _nextIndex);
    } else {
        concreteIndex = _nextIndex;
    }
    
    id  anComponent = [_branch childAtIndex:concreteIndex inSelection:NO];
    _nextIndex--;
    
    return anComponent;
}

@end
