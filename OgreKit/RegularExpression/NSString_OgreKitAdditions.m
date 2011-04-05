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

#import <OgreKit/NSString_OgreKitAdditions.h>
#import <OgreKit/OGRegularExpressionMatch.h>

@implementation NSString (OgreKitAdditions)

/**********
 * Search *
 **********/
- (NSRange)rangeOfRegularExpressionString:(NSString*)expressionString
{
	return [self rangeOfRegularExpressionString:expressionString 
		options:OgreNoneOption 
		range:NSMakeRange(0, [self length])];
}

- (NSRange)rangeOfRegularExpressionString:(NSString*)expressionString 
	options:(unsigned)options
{
	return [self rangeOfRegularExpressionString:expressionString 
		options:options 
		range:NSMakeRange(0, [self length])];
}

- (NSRange)rangeOfRegularExpressionString:(NSString*)expressionString 
	options:(unsigned)options 
	range:(NSRange)searchRange
{
	OGRegularExpressionMatch	*match = 
		[[OGRegularExpression regularExpressionWithString:expressionString options:options] 
				matchInString:self 
				options:options 
				range:searchRange];
	
	if (match == nil) {
		return NSMakeRange(NSNotFound, 0);
	} else {
		return [match rangeOfMatchedString];
	}
}

/*********
 * Split *
 *********/
// マッチした部分で文字列を分割し、NSArrayに収めて返す。
- (NSArray*)componentsSeparatedByRegularExpressionString:(NSString*)expressionString
{
	return [[OGRegularExpression regularExpressionWithString:expressionString] splitString:self];
}

/*********************
 * Newline Character *
 *********************/
// 改行コードが何か調べる
- (OgreNewlineCharacter)newlineCharacter
{
	return [OGRegularExpression newlineCharacterInString:self];
}

@end

@implementation NSMutableString (OgreKitAdditions)

/***********
 * Replace *
 ***********/
- (unsigned)replaceOccurrencesOfRegularExpressionString:(NSString*)expressionString 
	withString:(NSString*)replaceString 
	options:(unsigned)options 
	range:(NSRange)searchRange
{
	OGRegularExpression *regex = [OGRegularExpression regularExpressionWithString:expressionString
		options:options];
	unsigned	numberOfReplacement = 0;
	NSString	*replacedString = [regex replaceString:self 
		withString:replaceString 
		options:options 
		range:searchRange 
		replaceAll:YES
		numberOfReplacement:&numberOfReplacement];
	if (numberOfReplacement > 0) [self setString:replacedString];
	return numberOfReplacement;
}

// 改行コードをnewlineCharacterに統一する。
- (void)replaceNewlineCharactersWithCharacter:(OgreNewlineCharacter)newlineCharacter
{
	[self setString:[OGRegularExpression replaceNewlineCharactersInString:self withCharacter:newlineCharacter]];
}

// 改行コードを取り除く
- (void)chomp
{
	[self setString:[OGRegularExpression chomp:self]];
}


@end