/*
 * Name: OgreTableView.m
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

#import <OgreKit/OgreTableView.h>
#import <OgreKit/OgreTableViewAdapter.h>


@implementation OgreTableView

- (NSObject <OgreTextFindComponent>*)ogreAdapter
{
    return [[[OgreTableViewAdapter alloc] initWithTarget:self] autorelease];
}

- (int)ogreSelectedColumn
{
    return (_ogreSelectedColumn == -1? 0 : _ogreSelectedColumn);
}

- (void)ogreSetSelectedColumn:(int)column
{
    _ogreSelectedColumn = column;
}

- (int)ogreSelectedRow
{
    return (_ogreSelectedRow == -1? 0 : _ogreSelectedRow);
}

- (void)ogreSetSelectedRow:(int)row
{
    _ogreSelectedRow = row;
}

- (NSRange)ogreSelectedRange
{
    return _ogreSelectedRange;
}

- (void)ogreSetSelectedRange:(NSRange)aRange
{
    _ogreSelectedRange = aRange;
}


- (void)awakeFromNib
{
    _ogreSelectedColumn = -1;
    _ogreSelectedRow = -1;
    _ogreSelectedRange = NSMakeRange(0, 0);
    
    [[NSNotificationCenter defaultCenter] addObserver:self 
        selector:@selector(ogreSelectionDidChange:) 
        name:NSTableViewSelectionDidChangeNotification 
        object:self];
}

- (void)ogreSelectionDidChange:(NSNotification*)aNotification
{
    _ogreSelectedColumn = [self selectedColumn];
    _ogreSelectedRow = [self selectedRow];
    if (_ogreSelectedColumn == -1 && _ogreSelectedRow == -1) {
        _ogreSelectedRange = NSMakeRange(0, 0);
    } else {
        _ogreSelectedRange = NSMakeRange(NSNotFound, 0);
    }
}

#ifdef MAC_OS_X_VERSION_10_6
- (void)finalize
{
    [[NSNotificationCenter defaultCenter] removeObserver:self 
                                                    name:NSTableViewSelectionDidChangeNotification 
                                                  object:self];
    [super finalize];
}
#endif

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self 
                                                    name:NSTableViewSelectionDidChangeNotification 
                                                  object:self];
    [super dealloc];
}

@end
