/*
 * Name: MyTableRowModel.m
 * Project: OgreKit
 *
 * Creation Date: Jun 18 2004
 * Author: Isao Sonobe <sonoisa (AT) muse (DOT) ocn (DOT) ne (DOT) jp>
 * Copyright: Copyright (c) 2003 Isao Sonobe, All rights reserved.
 * License: OgreKit License
 *
 * Encoding: UTF8
 * Tabsize: 4
 */

#import "MyTableRowModel.h"


@implementation MyTableRowModel

- (id)init
{
    self = [super init];
    if (self != nil) {
        _foo = [[NSString alloc] initWithString:@"new foo"];
        _bar = [[NSString alloc] initWithString:@"new bar"];
    }
    
    return self;
}

- (void)dealloc
{
    [_foo release];
    [_bar release];
    [super dealloc];
}

- (NSString*)foo
{
    return _foo;
}

- (void)setFoo:(NSString*)newFoo
{
    [_foo autorelease];
    _foo = [newFoo retain];
}

- (NSString*)bar
{
    return _bar;
}

- (void)setBar:(NSString*)newBar
{
    [_bar autorelease];
    _bar = [newBar retain];
}

- (void)dump
{
    NSLog(@"foo:%@ bar:%@", _foo, _bar);
}

@end
