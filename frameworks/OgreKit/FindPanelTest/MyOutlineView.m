/*
 * Name: MyOutlineView.m
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

#import "MyOutlineView.h"

@implementation MyOutlineView

- (void)keyDown:(NSEvent*)event 
{
    unichar     key = [[event charactersIgnoringModifiers] characterAtIndex:0];
    unsigned    flags = ([event modifierFlags] & 0x00FF);
    
    if ((key == NSDeleteCharacter) && (flags == 0)) { 
        [(id <MyOutlineViewDelegate>)[self delegate] deleteKeyDownInOutlineView:self];
    } else {
        [super keyDown:event];
    }
}

@end
