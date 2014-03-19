/*
 * Name: OgreOutlineView.m
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

#import <OgreKit/OgreOutlineView.h>
#import <OgreKit/OgreOutlineViewAdapter.h>


@implementation OgreOutlineView

- (NSObject <OgreTextFindComponent>*)ogreAdapter
{
    return [[[OgreOutlineViewAdapter alloc] initWithTarget:self] autorelease];
}

- (void)awakeFromNib
{
    _ogreSelectedColumn = -1;
    _ogreSelectedItem = nil;
    _ogreSelectedRange = NSMakeRange(0, 0);
    _ogrePathComponents = nil;
    
    [[NSNotificationCenter defaultCenter] addObserver:self 
        selector:@selector(ogreSelectionDidChange:) 
        name:NSOutlineViewSelectionDidChangeNotification 
        object:self];
}

- (void)ogreSelectionDidChange:(NSNotification*)aNotification
{
    _ogreSelectedColumn = [self selectedColumn];
    int selectedRow = [self selectedRow];
    
    if (_ogreSelectedColumn == -1 && selectedRow == -1) {
        _ogreSelectedRange = NSMakeRange(0, 0);
    } else {
        _ogreSelectedRange = NSMakeRange(NSNotFound, 0);
    }
    
    if (selectedRow != -1) {
        _ogreSelectedItem = [self itemAtRow:selectedRow];
    } else {
        _ogreSelectedItem = nil;
    }
    [_ogrePathComponents release];
    _ogrePathComponents = nil;
    
    //NSLog(@"column:%d, row:%d", _ogreSelectedColumn, selectedRow);
    //NSLog(@"path:%@", [[self ogrePathComponentsOfSelectedItem] description]);
}

- (NSArray*)ogrePathComponentsOfSelectedItem
{
    if (_ogrePathComponents != nil) {
        return _ogrePathComponents;
    }
    
    if (_ogreSelectedItem == nil) {
        _ogrePathComponents =  [[NSMutableArray alloc] initWithObjects:[NSNumber numberWithInt:0] /* firstItem */, [NSNumber numberWithInt:-1] /* cell */, nil];
        return _ogrePathComponents;
    }
    
    int level = [self levelForItem:_ogreSelectedItem];
    int row = [self rowForItem:_ogreSelectedItem];
    if (level == -1 || row == -1) return nil;
    
    _ogrePathComponents = [[NSMutableArray alloc] initWithCapacity:level + 1];
    
    int index = 0;
    int targetLevel;
    while (row > 0) {
        row--;
        targetLevel = [self levelForRow:row];
        if (targetLevel + 1 == level) {
            // parent level
            [_ogrePathComponents insertObject:[NSNumber numberWithInt:index] atIndex:0];
            level = targetLevel;
            index = 0;
        } else if (targetLevel == level) {
            // same level
            index++;
        }
    } 
    // finish
    [_ogrePathComponents insertObject:[NSNumber numberWithInt:index] atIndex:0];
    [_ogrePathComponents addObject:[NSNumber numberWithInt:-1] /* cell */];
    
    return _ogrePathComponents;
}

- (int)ogreSelectedColumn
{
    return (_ogreSelectedColumn == -1? 0 : _ogreSelectedColumn);
}

- (void)ogreSetSelectedColumn:(int)column
{
    _ogreSelectedColumn = column;
}

- (void)ogreSetSelectedItem:(id)item
{
    _ogreSelectedItem = item;
    [_ogrePathComponents release];
    _ogrePathComponents = nil;
}

- (NSRange)ogreSelectedRange
{
    return _ogreSelectedRange;
}

- (void)ogreSetSelectedRange:(NSRange)aRange
{
    _ogreSelectedRange = aRange;
}

#ifdef MAC_OS_X_VERSION_10_6
- (void)finalize
{
    [[NSNotificationCenter defaultCenter] removeObserver:self 
                                                    name:NSOutlineViewSelectionDidChangeNotification 
                                                  object:self];
    [super finalize];
}
#endif

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self 
                                                    name:NSOutlineViewSelectionDidChangeNotification 
                                                  object:self];
    [_ogrePathComponents release];
    [super dealloc];
}

@end
