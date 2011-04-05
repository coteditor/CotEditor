/*
 * Name: OgreOutlineView.h
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

#import <AppKit/AppKit.h>
#import <OgreKit/OgreView.h>


@interface OgreOutlineView : NSOutlineView <OgreView>
{
    int     _ogreSelectedColumn;
    id      _ogreSelectedItem;
    NSRange _ogreSelectedRange;
    
    NSMutableArray  *_ogrePathComponents;
}

- (int)ogreSelectedColumn;
- (void)ogreSetSelectedColumn:(int)column;

- (NSArray*)ogrePathComponentsOfSelectedItem;
- (void)ogreSetSelectedItem:(id)item;

- (NSRange)ogreSelectedRange;
- (void)ogreSetSelectedRange:(NSRange)aRange;

@end
