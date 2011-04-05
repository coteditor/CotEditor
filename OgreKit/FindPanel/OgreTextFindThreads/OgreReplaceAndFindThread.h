/*
 * Name: OgreReplaceAndFindThread.h
 * Project: OgreKit
 *
 * Creation Date: May 20 2004
 * Author: Isao Sonobe <sonoisa (AT) muse (DOT) ocn (DOT) ne (DOT) jp>
 * Copyright: Copyright (c) 2004 Isao Sonobe, All rights reserved.
 * License: OgreKit License
 *
 * Encoding: UTF8
 * Tabsize: 4
 */

#import <OgreKit/OgreFindThread.h>

@interface OgreReplaceAndFindThread : OgreFindThread 
{
    BOOL    _replacingOnly;
}

- (BOOL)replacingOnly;
- (void)setReplacingOnly:(BOOL)replacingOnly;

@end
