/*
 * Name: OgreTableCellAdapter.h
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

#import <Cocoa/Cocoa.h>
#import <OgreKit/OgreTextFindBranch.h>
#import <OgreKit/OgreTextFindLeaf.h>

@class OgreTableColumn;

@interface OgreTableCellAdapter : OgreTextFindLeaf
{
    OgreTableColumn *_tableColumn;
    int             _rowIndex;
}

- (id)initWithTableColumn:(OgreTableColumn*)tableColumn row:(int)rowIndex;

@end
