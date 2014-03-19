/*
 * Name: OgreTextViewAdapter.h
 * Project: OgreKit
 *
 * Creation Date: May 20 2004
 * Author: Isao Sonobe <sonoisa (AT) muse (DOT) ocn (DOT) ne (DOT) jp>
 * Copyright: Copyright (c) 2003 Isao Sonobe, All rights reserved.
 * License: OgreKit License
 *
 * Encoding: UTF8
 * Tabsize: 4
 */

#import <Cocoa/Cocoa.h>
#import <OgreKit/OgreTextFindLeaf.h>

@interface OgreTextViewAdapter : OgreTextFindLeaf <OgreTextFindTargetAdapter>
{
}

- (id)initWithTarget:(id)aTextView;

@end
