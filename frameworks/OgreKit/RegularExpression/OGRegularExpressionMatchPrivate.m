/*
 * Name: OGRegularExpressionMatchPrivate.m
 * Project: OgreKit
 *
 * Creation Date: Sep 01 2003
 * Author: Isao Sonobe <sonoisa (AT) muse (DOT) ocn (DOT) ne (DOT) jp>
 * Copyright: Copyright (c) 2003 Isao Sonobe, All rights reserved.
 * License: OgreKit License
 *
 * Encoding: UTF8
 * Tabsize: 4
 */

#import <OgreKit/OGRegularExpression.h>
#import <OgreKit/OGRegularExpressionPrivate.h>
#import <OgreKit/OGRegularExpressionMatch.h>
#import <OgreKit/OGRegularExpressionMatchPrivate.h>
#import <OgreKit/OGRegularExpressionEnumerator.h>
#import <OgreKit/OGRegularExpressionEnumeratorPrivate.h>


@implementation OGRegularExpressionMatch (Private)

/* 非公開メソッド */
- (id)initWithRegion:(OnigRegion*)region 
	index:(unsigned)anIndex
	enumerator:(OGRegularExpressionEnumerator*)enumerator
	terminalOfLastMatch:(unsigned)terminalOfLastMatch 
{
#ifdef DEBUG_OGRE
	NSLog(@"-initWithRegion: of %@", [self className]);
#endif
	self = [super init];
	if (self) {
		// match result region
		_region = region;	// retain
	
		// 生成主
		_enumerator = [enumerator retain];
		
		// 最後にマッチした文字列の終端位置
		_terminalOfLastMatch = terminalOfLastMatch;
		// マッチした順番
		_index = anIndex;
		
		// 頻繁に利用するものはキャッシュする。保持はしない。
		// 検索対象文字列
		_targetString     = [_enumerator targetString];
		// 検索範囲
		NSRange	searchRange = [_enumerator searchRange];
		_searchRange.location = searchRange.location;
		_searchRange.length   = searchRange.length;
	}
	
	return self;
}

#ifdef MAC_OS_X_VERSION_10_6
- (void)finalize
{
#ifdef DEBUG_OGRE
	NSLog(@"-finalize of %@", [self className]);
#endif
	if (_region != NULL) {
		onig_region_free(_region, 1 /* free all */);
	}
    [super finalize];
}
#endif

- (void)dealloc
{
#ifdef DEBUG_OGRE
	NSLog(@"-dealloc of %@", [self className]);
#endif
	[_enumerator release];

	if (_region != NULL) {
		onig_region_free(_region, 1 /* free self */);
	}
	
	[super dealloc];
}

- (NSObject<OGStringProtocol>*)_targetString
{
    return _targetString;
}

- (NSRange)_searchRange
{
    return _searchRange;
}

- (OnigRegion*)_region
{
    return _region;
}


@end
