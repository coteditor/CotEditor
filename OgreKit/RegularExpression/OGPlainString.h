/*
 * Name: OGPlainString.h
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

#import <OgreKit/OGString.h>

@interface OGPlainString : NSObject <OGStringProtocol, NSCopying, NSCoding>
{
	NSString	*_string;
}

- (id)initWithString:(NSString*)string;
- (id)initWithAttributedString:(NSAttributedString*)attributedString;
- (id)initWithString:(NSString*)string hasAttributesOfOGString:(NSObject<OGStringProtocol>*)ogString;

+ (id)stringWithString:(NSString*)string;
+ (id)stringWithAttributedString:(NSAttributedString*)attributedString;
+ (id)stringithString:(NSString*)string hasAttributesOfOGString:(NSObject<OGStringProtocol>*)ogString;

- (NSString*)_string;
- (void)_setString:(NSString*)string;

@end
