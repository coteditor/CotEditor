/*
 * Name: OgreTableView.h
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


@interface OgreTableView : NSTableView <OgreView>
{
    int     _ogreSelectedColumn;
    int     _ogreSelectedRow;
    NSRange _ogreSelectedRange;
}

- (NSObject <OgreTextFindComponent>*)ogreAdapter;

- (int)ogreSelectedColumn;
- (void)ogreSetSelectedColumn:(int)column;

- (int)ogreSelectedRow;
- (void)ogreSetSelectedRow:(int)row;

- (NSRange)ogreSelectedRange;
- (void)ogreSetSelectedRange:(NSRange)aRange;

@end
