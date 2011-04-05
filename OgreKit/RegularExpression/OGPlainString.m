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

#import <OgreKit/OGPlainString.h>
#import <OgreKit/OGMutablePlainString.h>

// 自身をencoding/decodingするためのkey
static NSString * const	OgrePlainStringKey = @"OgrePlainString";

@implementation OGPlainString

- (id)initWithString:(NSString*)string
{
	if (string == nil) {
		[super release];
		[NSException raise:NSInvalidArgumentException format: @"nil string argument"];
	}
	
	self = [super init];
	if (self != nil) {
		_string = [string retain];
	}
	return self;
}

- (id)initWithAttributedString:(NSAttributedString*)attributedString
{
	return [self initWithString:[attributedString string]];
}


- (id)initWithString:(NSString*)string hasAttributesOfOGString:(NSObject<OGStringProtocol>*)ogString
{
	return [self initWithString:string];
}

+ (id)stringWithString:(NSString*)string
{
	return [[[[self class] alloc] initWithString:string] autorelease];
}

+ (id)stringWithAttributedString:(NSAttributedString*)attributedString
{
	return [[[[self class] alloc] initWithAttributedString:attributedString] autorelease];
}

+ (id)stringithString:(NSString*)string hasAttributesOfOGString:(NSObject<OGStringProtocol>*)ogString
{
	return [[[[self class] alloc] initWithString:string hasAttributesOfOGString:ogString] autorelease];
}

- (void)dealloc
{
	[_string release];
	[super dealloc];
}

- (NSString*)_string
{
	return _string;
}

- (void)_setString:(NSString*)string
{
	[_string autorelease];
	_string = [string retain];
}

/* OGString interface */
- (NSString*)string
{
	return (NSString*)_string;
}

- (NSAttributedString*)attributedString
{
	return [[[NSAttributedString alloc] initWithString:(NSString*)_string] autorelease];
}

- (unsigned)length
{
	return [_string length];
}

- (NSObject<OGStringProtocol>*)substringWithRange:(NSRange)aRange
{
	return [[self class] stringWithString:[(NSString*)_string substringWithRange:aRange]];
}

- (Class)mutableClass
{
	return [OGMutablePlainString class];
}

/* NSCopying protocol */
- (id)copyWithZone:(NSZone*)zone
{
#ifdef DEBUG_OGRE
	NSLog(@"-copyWithZone: of %@", [self className]);
#endif
	NSString	*string = [(NSString*)_string copy];
	id	copy = [[[self class] allocWithZone:zone] initWithString:string];
	[string release];
	
	return copy;
}

/* NSCoding protocol */
- (void)encodeWithCoder:(NSCoder*)encoder
{
#ifdef DEBUG_OGRE
	NSLog(@"-encodeWithCoder: of %@", [self className]);
#endif
    if ([encoder allowsKeyedCoding]) {
		[encoder encodeObject:_string forKey:OgrePlainStringKey];
	} else {
		[encoder encodeObject:_string];
	}
}

- (id)initWithCoder:(NSCoder*)decoder
{
#ifdef DEBUG_OGRE
	NSLog(@"-initWithCoder: of %@", [self className]);
#endif
	
	self = [super init];
	if (self == nil) return self;
	
	BOOL			allowsKeyedCoding = [decoder allowsKeyedCoding];
	// NSString		*_string;
    if (allowsKeyedCoding) {
		_string = [[decoder decodeObjectForKey:OgrePlainStringKey] retain];
	} else {
		_string = [[decoder decodeObject] retain];
	}
	if(_string == nil) {
		// エラー。例外を発生させる。
		[NSException raise:NSInvalidUnarchiveOperationException format:@"fail to decode"];
	}
	
	return self;	
}

/* description */
- (NSString*)description
{
	return (NSString*)_string;
}

@end
