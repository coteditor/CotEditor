/*
 * Name: OGString.h
 * Project: OgreKit
 *
 * Creation Date: Sep 22 2004
 * Author: Isao Sonobe <sonoisa (AT) muse (DOT) ocn (DOT) ne (DOT) jp>
 * Copyright: Copyright (c) 2004 Isao Sonobe, All rights reserved.
 * License: OgreKit License
 *
 * Encoding: UTF8
 * Tabsize: 4
 */

#import <Foundation/Foundation.h>

// exception name
extern NSString	* const OgreStringException;

@protocol OGStringProtocol
- (NSString*)string;
- (NSAttributedString*)attributedString;
- (unsigned)length;

- (NSObject<OGStringProtocol>*)substringWithRange:(NSRange)aRange;

- (Class)mutableClass;
@end
