/*
 * Name: OGRegularExpressionCapture.m
 * Project: OgreKit
 *
 * Creation Date: Jun 24 2004
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
#import <OgreKit/OGRegularExpressionCapture.h>
#import <OgreKit/OGRegularExpressionCapturePrivate.h>
#import <OgreKit/OGString.h>


NSString	* const OgreCaptureException = @"OGRegularExpressionCaptureException";

// 自身をencoding/decodingするためのkey
static NSString	* const OgreIndexKey  = @"OgreCaptureIndex";
static NSString	* const OgreLevelKey  = @"OgreCaptureLevel";
static NSString	* const OgreMatchKey  = @"OgreCaptureMatch";
static NSString	* const OgreParentKey = @"OgreCaptureParent";


@implementation OGRegularExpressionCapture

/*********
 * 諸情報 *
 *********/
// グループ番号
- (unsigned)groupIndex
{
    return _captureNode->group;
}

// グループ名
- (NSString*)groupName
{
    return [_match nameOfSubstringAtIndex:[self groupIndex]];
}

// 何番目の子要素であるか 0,1,2,...
- (unsigned)index
{
    return _index;
}

// 深さ
- (unsigned)level
{
    return _level;
}

// 子要素の数
- (unsigned)numberOfChildren
{
    return _captureNode->num_childs;
}

// 子要素たち
// return nil in the case of numberOfChildren == 0
- (NSArray*)children
{
    unsigned    numberOfChildren = _captureNode->num_childs;
    if (numberOfChildren == 0) return nil;
    
    NSMutableArray  *children = [NSMutableArray arrayWithCapacity:numberOfChildren];
    int i;
    for (i = 0; i < numberOfChildren; i++) [children addObject:[self childAtIndex:i]];
    
    return children;
}


// index番目の子要素
- (OGRegularExpressionCapture*)childAtIndex:(unsigned)index
{
    if (index >= _captureNode->num_childs) {
        return nil;
    }
    
    return [[[[self class] alloc] initWithTreeNode:_captureNode->childs[index] 
        index:index 
        level:_level + 1 
        parentNode:self 
        match:_match] autorelease];
}


- (OGRegularExpressionMatch*)match
{
    return _match;
}


// description
- (NSString*)description
{
	NSDictionary	*dictionary = [NSDictionary 
		dictionaryWithObjects: [NSArray arrayWithObjects: 
			[NSNumber numberWithUnsignedInt: _captureNode->group], 
			[NSNumber numberWithUnsignedInt: _index], 
			[NSNumber numberWithUnsignedInt: _level], 
			[NSArray arrayWithObjects:
                [NSNumber numberWithUnsignedInt: _captureNode->beg], 
                [NSNumber numberWithUnsignedInt: _captureNode->end - _captureNode->beg], 
                nil], 
			[NSNumber numberWithUnsignedInt: _captureNode->num_childs], 
			nil]
		forKeys:[NSArray arrayWithObjects: 
			@"Group Index", 
			@"Index", 
			@"Level", 
			@"Range", 
			@"Number of Children", 
			nil]
		];
		
	return [dictionary description];
}

/*********
 * 文字列 *
 *********/
// マッチの対象になった文字列
- (NSString*)targetString
{
    return [_match targetString];
}

- (NSAttributedString*)targetAttributedString
{
	return [_match targetAttributedString];
}

// マッチした文字列
- (NSString*)string
{
	// index番目のsubstringが存在しない時には nil を返す
	if (_captureNode->beg == -1 || _captureNode->end == -1) {
		return nil;
	}
	
	return [[_match targetString] substringWithRange:NSMakeRange(_captureNode->beg / sizeof(unichar), (_captureNode->end - _captureNode->beg) / sizeof(unichar))];
}

- (NSAttributedString*)attributedString
{
	// index番目のsubstringが存在しない時には nil を返す
	if (_captureNode->beg == -1 || _captureNode->end == -1) {
		return nil;
	}
	
	return [[_match targetAttributedString] attributedSubstringFromRange:NSMakeRange(_captureNode->beg / sizeof(unichar), (_captureNode->end - _captureNode->beg) / sizeof(unichar))];
}

/*******
 * 範囲 *
 *******/
// マッチした文字列の範囲
- (NSRange)range
{
	if (_captureNode->beg == -1 || _captureNode->end == -1) {
		return NSMakeRange(NSNotFound, 0);
	}
	
	return NSMakeRange([_match _searchRange].location + _captureNode->beg / sizeof(unichar), (_captureNode->end - _captureNode->beg) / sizeof(unichar));
}


/************************
* adapt Visitor pattern *
*************************/
- (void)acceptVisitor:(id <OGRegularExpressionCaptureVisitor>)aVisitor 
{
    NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
    [aVisitor visitAtFirstCapture:self];
    
    [[self children] makeObjectsPerformSelector:@selector(acceptVisitor:) withObject:aVisitor];
    
    [aVisitor visitAtLastCapture:self];
    [pool release];
}


// NSCoding protocols
- (void)encodeWithCoder:(NSCoder*)encoder
{
#ifdef DEBUG_OGRE
	NSLog(@"-encodeWithCoder: of %@", [self className], [self className]);
#endif
	//[super encodeWithCoder:encoder]; NSObject does ont respond to method encodeWithCoder:
	
   if ([encoder allowsKeyedCoding]) {
		[encoder encodeObject: [NSNumber numberWithUnsignedInt:_index] forKey: OgreIndexKey];
		[encoder encodeObject: [NSNumber numberWithUnsignedInt:_level] forKey: OgreLevelKey];
		[encoder encodeObject: _match forKey: OgreMatchKey];
		[encoder encodeObject: _parent forKey: OgreParentKey];
	} else {
		[encoder encodeObject: [NSNumber numberWithUnsignedInt:_index]];
		[encoder encodeObject: [NSNumber numberWithUnsignedInt:_level]];
		[encoder encodeObject: _match];
		[encoder encodeObject: _parent];
	}
}

- (id)initWithCoder:(NSCoder*)decoder
{
#ifdef DEBUG_OGRE
	NSLog(@"-initWithCoder: of %@", [self className], [self className]);
#endif
	self = [super init];	// NSObject does ont respond to method initWithCoder:
	if (self == nil) return nil;
	
	BOOL			allowsKeyedCoding = [decoder allowsKeyedCoding];
	
	id  anObject;
	// unsigned                    _index,             // マッチした順番
    if (allowsKeyedCoding) {
		anObject = [decoder decodeObjectForKey: OgreIndexKey];
	} else {
		anObject = [decoder decodeObject];
	}
	if (anObject == nil) {
		// エラー。例外を発生させる。
		[self release];
		[NSException raise:NSInvalidUnarchiveOperationException format:@"fail to decode"];
	}
	_index = [anObject unsignedIntValue];	
	
    // unsigned                   _level;             // 深さ
    if (allowsKeyedCoding) {
		anObject = [decoder decodeObjectForKey: OgreLevelKey];
	} else {
		anObject = [decoder decodeObject];
	}
	if (anObject == nil) {
		// エラー。例外を発生させる。
		[self release];
		[NSException raise:NSInvalidUnarchiveOperationException format:@"fail to decode"];
	}
	_level = [anObject unsignedIntValue];	
	
	
	// OGRegularExpressionMatch	*_match;            // 生成主のOGRegularExpressionMatchオブジェクト
    if (allowsKeyedCoding) {
		_match = [decoder decodeObjectForKey: OgreMatchKey];
	} else {
		_match = [decoder decodeObject];
	}
	if (_match == nil) {
		// エラー。例外を発生させる。
		[self release];
		[NSException raise:NSInvalidUnarchiveOperationException format:@"fail to decode"];
	}
    [_match retain];
	
	// OGRegularExpressionCapture	*_parent;           // 親
    if (allowsKeyedCoding) {
		_parent = [decoder decodeObjectForKey: OgreParentKey];
	} else {
		_parent = [decoder decodeObject];
	}
	/*if (_parent == nil) {
		// エラー。例外を発生させる。
		[self release];
		[NSException raise:OgreCaptureException format:@"fail to decode"];
	}*/
    [_parent retain];
    
    
	// OnigCaptureTreeNode         *_captureNode;      // Oniguruma capture tree node
    if (_parent == nil) {
        _captureNode = [_match _region]->history_root;
    } else {
        _captureNode = [_parent _captureNode]->childs[_index];
    }
    
	return self;
}

// NSCopying protocol
- (id)copyWithZone:(NSZone*)zone
{
#ifdef DEBUG_OGRE
	NSLog(@"-copyWithZone: of %@", [self className], [self className]);
#endif
	return [[[self class] allocWithZone:zone] 
        initWithTreeNode:_captureNode 
        index:_index 
        level:_level 
        parentNode:_parent 
        match:_match];
}


@end
