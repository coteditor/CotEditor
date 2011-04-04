/*
 * Name: OGMutableAttributedString.h
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

#import <OgreKit/OGMutableString.h>
#import <OgreKit/OGAttributedString.h>

@interface OGMutableAttributedString : OGAttributedString <OGMutableStringProtocol>
{
	NSString		*_currentFontFamilyName;
	NSFontTraitMask	_currentFontTraits;
	float			_currentFontWeight;
	float			_currentFontPointSize;
	NSDictionary	*_currentAttributes;
	NSFontManager	*_fontManager;
}

@end
