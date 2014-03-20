/*
 * Name: OGRegularExpressionEnumeratorPrivate.h
 * Project: OgreKit
 *
 * Creation Date: Sep 03 2003
 * Author: Isao Sonobe <sonoisa (AT) muse (DOT) ocn (DOT) ne (DOT) jp>
 * Copyright: Copyright (c) 2003 Isao Sonobe, All rights reserved.
 * License: OgreKit License
 *
 * Encoding: UTF8
 * Tabsize: 4
 */

#import <Foundation/Foundation.h>
#import <OgreKit/OGRegularExpressionEnumerator.h>
#import <OgreKit/OGString.h>

// aUTF16StringのUTF16文字長
static inline unsigned Ogre_UTF16charlen(unichar *const aUTF16String)
{
	unichar UTF16Char = *aUTF16String;
	
	if ((UTF16Char <= 0x9FFF) || (UTF16Char >= 0xE000)) return 1;       // 1 code point
	if ((UTF16Char & 0xFC00) == 0xD800) return 2;	// surrogate pair
	
	// illegal unicode character
	[NSException raise:OgreEnumeratorException format:@"illegal unicode character"];
	
	return 0;	// dummy
}

// aUTF16Stringより１文字前のUTF16文字長
static inline unsigned Ogre_UTF16prevcharlen(unichar *const aUTF16String)
{
    unichar UTF16Char = *(aUTF16String - 1);
	if ((UTF16Char <= 0x9FFF) || (UTF16Char >= 0xE000)) return 1;       // 1 code point
	if ((UTF16Char & 0xFC00) == 0xDC00) return 2;	// surrogate pair
	
	// 出会わないはずなので、出会ったら例外を起こす。
	[NSException raise:OgreEnumeratorException format:@"illegal byte code"];
	
	return 0;	// dummy
}


@class OGRegularExpression, OGRegularExpressionEnumerator;

@interface OGRegularExpressionEnumerator (Private)

/*********
 * 初期化 *
 *********/
- (id)initWithOGString:(NSObject<OGStringProtocol>*)targetString 
	options:(unsigned)searchOptions 
	range:(NSRange)searchRange 
	regularExpression:(OGRegularExpression*)regex;

/*********************
 * private accessors *
 *********************/
- (void)_setTerminalOfLastMatch:(int)location;
- (void)_setIsLastMatchEmpty:(BOOL)yesOrNo;
- (void)_setStartLocation:(unsigned)location;
- (void)_setNumberOfMatches:(unsigned)aNumber;

- (NSObject<OGStringProtocol>*)targetString;
- (unichar*)UTF16TargetString;

- (OGRegularExpression*)regularExpression;
- (void)setRegularExpression:(OGRegularExpression*)regularExpression;

- (NSRange)searchRange;

@end
