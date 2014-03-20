/*
 * Name: OgreOutlineCellMatchFindResult.m
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

#import <OgreKit/OgreOutlineCellMatchFindResult.h>
#import <OgreKit/OgreOutlineCellFindResult.h>


@implementation OgreOutlineCellMatchFindResult

- (id)name
{
    NSString    *name = [(OgreOutlineCellFindResult*)[self parent] nameOfMatchedStringAtIndex:[self index]];
    if ([self index] == 0) return name;
    
    return [[[NSAttributedString alloc] initWithString:name attributes:[NSDictionary dictionaryWithObject:[NSColor lightGrayColor] forKey:NSForegroundColorAttributeName]] autorelease]; 
}

- (id)outline
{
    return [(OgreOutlineCellFindResult*)[self parent] matchedStringAtIndex:[self index]]; 
}

- (BOOL)showMatchedString
{
    return [(OgreOutlineCellFindResult*)[self parent] showMatchedStringAtIndex:[self index]];
}

- (BOOL)selectMatchedString
{
    return [(OgreOutlineCellFindResult*)[self parent] selectMatchedStringAtIndex:[self index]];
}

- (id)target
{
    return [(OgreOutlineCellFindResult*)[self parent] target];
}

@end
