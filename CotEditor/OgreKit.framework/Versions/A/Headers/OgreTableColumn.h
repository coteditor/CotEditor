/*
 * Name: OgreTableColumn.h
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


@interface OgreTableColumn : NSTableColumn 
{
    id              _ogreObservableController;
    NSString        *_ogreControllerKeyOfValueBinding;
    NSMutableString *_ogreModelKeyPathOfValueBinding;
}

- (int)ogreNumberOfRows;
- (id)ogreObjectValueForRow:(int)row;
- (void)ogreSetObjectValue:(id)anObject forRow:(int)row;

@end
