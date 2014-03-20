/*
 * Name: OGRegularExpressionFormatter.m
 * Project: OgreKit
 *
 * Creation Date: Feb 29 2004
 * Author: Isao Sonobe <sonoisa (AT) muse (DOT) ocn (DOT) ne (DOT) jp>
 * Copyright: Copyright (c) 2004 Isao Sonobe, All rights reserved.
 * License: OgreKit License
 *
 * Encoding: UTF8
 * Tabsize: 4
 */

#import <OgreKit/OGRegularExpression.h>

@interface NSString (OgreKitAdditions)

/*
 options:
 compile time options:
  OgreNoneOption				no option
  OgreSingleLineOption			'^' -> '\A', '$' -> '\z', '\Z' -> '\z'
  OgreMultilineOption			'.' match with newline
  OgreIgnoreCaseOption			ignore case (case-insensitive)
  OgreExtendOption				extended pattern form
  OgreFindLongestOption			find longest match
  OgreFindNotEmptyOption		ignore empty match
  OgreNegateSingleLineOption	clear OgreSINGLELINEOption which is default on
								in OgrePOSIXxxxxSyntax, OgrePerlSyntax and OgreJavaSyntax.
  OgreDontCaptureGroupOption	named group only captured.  (/.../g)
  OgreCaptureGroupOption		named and no-named group captured. (/.../G)
  OgreDelimitByWhitespaceOption	delimit words by whitespace in OgreSimpleMatchingSyntax
  								@"AAA BBB CCC" <=> @"(AAA)|(BBB)|(CCC)"
  
 search time options:
  OgreNotBOLOption			string head(str) isn't considered as begin of line
  OgreNotEOLOption			string end (end) isn't considered as end of line
  OgreFindEmptyOption		allow empty match being next to not empty matchs
	e.g. 
	regex = [OGRegularExpression regularExpressionWithString:@"[a-z]*" options:compileOptions];
	NSLog(@"%@", [regex replaceAllMatchesInString:@"abc123def" withString:@"(\\0)" options:searchOptions]);

	compileOptions			searchOptions				replaced string
 1. OgreFindNotEmptyOption  OgreNoneOption				(abc)123(def)
							(or OgreFindEmptyOption)		
 2. OgreNoneOption			OgreNoneOption				(abc)1()2()3(def)
 3. OgreNoneOption			OgreFindEmptyOption			(abc)()1()2()3(def)()

 */
/**********
 * Search *
 **********/
- (NSRange)rangeOfRegularExpressionString:(NSString*)expressionString;
- (NSRange)rangeOfRegularExpressionString:(NSString*)expressionString 
	options:(unsigned)options;
- (NSRange)rangeOfRegularExpressionString:(NSString*)expressionString 
	options:(unsigned)options 
	range:(NSRange)searchRange;

/*********
 * Split *
 *********/
// マッチした部分で文字列を分割し、NSArrayに収めて返す。
- (NSArray*)componentsSeparatedByRegularExpressionString:(NSString*)expressionString;

/*********************
 * Newline Character *
 *********************/
// 改行コードが何か調べる
- (OgreNewlineCharacter)newlineCharacter;

@end

@interface NSMutableString (OgreKitAdditions)

/***********
 * Replace *
 ***********/
- (unsigned)replaceOccurrencesOfRegularExpressionString:(NSString*)expressionString 
	withString:(NSString*)replaceString 
	options:(unsigned)options 
	range:(NSRange)searchRange;

/*********************
 * Newline Character *
 *********************/
// 改行コードをnewlineCharacterに統一する。
- (void)replaceNewlineCharactersWithCharacter:(OgreNewlineCharacter)newlineCharacter;
// 改行コードを取り除く
- (void)chomp;

@end