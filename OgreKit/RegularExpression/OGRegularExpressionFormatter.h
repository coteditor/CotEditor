/*
 * Name: OGRegularExpressionFormatter.h
 * Project: OgreKit
 *
 * Creation Date: Sep 05 2003
 * Author: Isao Sonobe <sonoisa (AT) muse (DOT) ocn (DOT) ne (DOT) jp>
 * Copyright: Copyright (c) 2003 Isao Sonobe, All rights reserved.
 * License: OgreKit License
 *
 * Encoding: UTF8
 * Tabsize: 4
 */

#import <Foundation/Foundation.h>
#import <OgreKit/OGRegularExpression.h>

// Exception name
extern NSString	* const OgreFormatterException;


@interface OGRegularExpressionFormatter : NSFormatter <NSCopying, NSCoding>
{
	NSString			*_escapeCharacter;		// \の代替文字
	unsigned			_options;				// コンパイルオプション
	OgreSyntax			_syntax;				// 正規表現の構文
}

// 必須メソッド
- (NSString*)stringForObjectValue:(id)anObject;
- (NSAttributedString*)attributedStringForObjectValue:(id)anObject 
	withDefaultAttributes:(NSDictionary*)attributes;
- (NSString*)editingStringForObjectValue:(id)anObject;

// エラー判定
- (BOOL)getObjectValue:(id*)obj forString:(NSString*)string 
	errorDescription:(NSString**)error;

- (id)init;
- (id)initWithOptions:(unsigned)options 
	syntax:(OgreSyntax)syntax 
	escapeCharacter:(NSString*)character;

- (NSString*)escapeCharacter;
- (void)setEscapeCharacter:(NSString*)character;

- (unsigned)options;
- (void)setOptions:(unsigned)options;

- (OgreSyntax)syntax;
- (void)setSyntax:(OgreSyntax)syntax;

@end
