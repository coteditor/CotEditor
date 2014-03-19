/*
 * Name: OGRegularExpressionPrivate.h
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

#import <Foundation/Foundation.h>
#import <OgreKit/OGRegularExpression.h>
#import <OgreKit/OGString.h>

@class OGRegularExpression;

typedef enum OgreKindOfCharacters {
	OgreKindOfNil = -1,
	OgreKindOfEmpty, 
	OgreKindOfSpecial, 
	OgreKindOfBackslash, 
	OgreKindOfNormal
} OgreKindOfCharacter;

// 正規表現構文
OnigSyntaxType  OgrePrivatePOSIXBasicSyntax;
OnigSyntaxType  OgrePrivatePOSIXExtendedSyntax;
OnigSyntaxType  OgrePrivateEmacsSyntax;
OnigSyntaxType  OgrePrivateGrepSyntax;
OnigSyntaxType  OgrePrivateGNURegexSyntax;
OnigSyntaxType  OgrePrivateJavaSyntax;
OnigSyntaxType  OgrePrivatePerlSyntax;
OnigSyntaxType  OgrePrivateRubySyntax;


@interface OGRegularExpression (Private)

/* 非公開メソッド */

// OgreSyntaxに対応するOnigSyntaxType*を返す。
+ (OnigSyntaxType*)onigSyntaxTypeForSyntax:(OgreSyntax)syntax;

// string中の\をcharacterに置き換えた文字列を返す。characterがnilの場合、stringを返す。
+ (NSObject<OGStringProtocol>*)changeEscapeCharacterInOGString:(NSObject<OGStringProtocol>*)string toCharacter:(NSString*)character;

// characterの文字種を返す。
/*
 戻り値:
  OgreKindOfNil			nil
  OgreKindOfEmpty		@""
  OgreKindOfBackslash	@"\\"
  OgreKindOfNormal		その他
 */
+ (OgreKindOfCharacter)kindOfCharacter:(NSString*)character;

// 空白で単語をグループ分けする。例: @"alpha beta gamma" -> @"(alpha)|(beta)|(gamma)"
+ (NSString*)delimitByWhitespaceInString:(NSString*)string;

// oniguruma regular expression object
- (regex_t*)patternBuffer;

// 名前がnameのgroup number
// 存在しない名前の場合は-1を返す。
// 同一の名前を持つ部分文字列が複数ある場合は-2を返す。
- (int)groupIndexForName:(NSString*)name;
// index番目の部分文字列の名前
// 存在しない名前の場合は nil を返す。
- (NSString*)nameForGroupIndex:(unsigned)index;


@end
