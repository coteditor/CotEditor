/*
 * Name: OgreAFPCEscapeCharacterFormatter.m
 * Project: OgreKit
 *
 * Creation Date: Feb 21 2004
 * Author: Isao Sonobe <sonoisa (AT) muse (DOT) ocn (DOT) ne (DOT) jp>
 * Copyright: Copyright (c) 2003 Isao Sonobe, All rights reserved.
 * License: OgreKit License
 *
 * Encoding: UTF8
 * Tabsize: 4
 */
 
#import <OgreKit/OgreAFPCEscapeCharacterFormatter.h>
#import <OgreKit/OGRegularExpression.h>
#import <OgreKit/OGRegularExpressionMatch.h>


@implementation OgreAFPCEscapeCharacterFormatter

- (id)init
{
	if ((self = [super init]) != nil) {
		_backslashRegex = [[OGRegularExpression alloc] initWithString:@"\\\\" 
			options:OgreNoneOption 
			syntax:OgreGrepSyntax 
			escapeCharacter:OgreBackslashCharacter];
		_yenRegex = [[OGRegularExpression alloc] initWithString:OgreGUIYenCharacter 
			options:OgreNoneOption 
			syntax:OgreGrepSyntax 
			escapeCharacter:OgreBackslashCharacter];
	}
	
	return self;
}

- (void)dealloc
{
	[_backslashRegex release];
	[_yenRegex release];
	[super dealloc];
}

- (NSString*)stringForObjectValue:(id)anObject
{
	NSString	*string = nil;

    if ([anObject isKindOfClass:[NSString class]]) {
		if ([_delegate shouldEquateYenWithBackslash]) {
			string = [self equateInString:(NSString*)anObject];
		} else {
			string = anObject;
		}
    } else if ([anObject isKindOfClass:[NSAttributedString class]]) {
		NSString	*string;
		if ([_delegate shouldEquateYenWithBackslash]) {
			string = [self equateInString:[(NSAttributedString*)anObject string]];
		} else {
			string = anObject;
		}
    }
	
	return string;
}

- (NSAttributedString*)attributedStringForObjectValue:(id)anObject withDefaultAttributes:(NSDictionary*)attributes
{
	NSAttributedString	*attrString = nil;

    if ([anObject isKindOfClass:[NSString class]]) {
		NSString	*string;
		if ([_delegate shouldEquateYenWithBackslash]) {
			string = [self equateInString:(NSString*)anObject];
		} else {
			string = anObject;
		}
		attrString = [[[NSAttributedString alloc] initWithString:string attributes:attributes] autorelease];
	} else if ([anObject isKindOfClass:[NSAttributedString class]]) {
		if ([_delegate shouldEquateYenWithBackslash]) {
			attrString = [self equateInAttributedString:(NSAttributedString*)anObject];
		} else {
			attrString = anObject;
		}
    }
	
	return attrString;
}

- (BOOL)getObjectValue:(id*)obj forString:(NSString*)string errorDescription:(NSString**)error
{
	if ([_delegate shouldEquateYenWithBackslash]) {
		*obj = [self equateInString:string];
	} else {
		*obj = string;
	}
	
	return YES;
}

- (void)setDelegate:(id)aDelegate
{
	_delegate = aDelegate;  // 注意! retainしない。
}

- (NSString*)equateInString:(NSString*)string
{
	NSString			*escapeCharacter = [_delegate escapeCharacter];
	OGRegularExpression *regex;
	if ([escapeCharacter isEqualToString:OgreBackslashCharacter]) {
		regex = _yenRegex;
	} else {
		regex = _backslashRegex;
	}
	
	return [regex replaceAllMatchesInString:string 
		delegate:self 
		replaceSelector:@selector(equateYenWithBackslash:contextInfo:) 
		contextInfo:escapeCharacter];
}

- (NSAttributedString*)equateInAttributedString:(NSAttributedString*)string
{
	NSString			*escapeCharacter = [_delegate escapeCharacter];
	OGRegularExpression *regex;
	if ([escapeCharacter isEqualToString:OgreBackslashCharacter]) {
		regex = _yenRegex;
	} else {
		regex = _backslashRegex;
	}
	
	return [regex replaceAllMatchesInAttributedString:string 
		delegate:self 
		replaceSelector:@selector(equateYenWithBackslashAttributed:contextInfo:) 
		contextInfo:escapeCharacter];
}

- (NSString*)equateYenWithBackslash:(OGRegularExpressionMatch*)aMatch 
	contextInfo:(id)contextInfo
{
	return contextInfo;
}

- (NSAttributedString*)equateYenWithBackslashAttributed:(OGRegularExpressionMatch*)aMatch 
	contextInfo:(id)contextInfo
{
	NSString	*string = (NSString*)contextInfo;
	NSAttributedString	*matchedString = [aMatch matchedAttributedString];
	
	return [[[NSAttributedString alloc] initWithString:string 
		attributes:[matchedString attributesAtIndex:0 effectiveRange:NULL]] autorelease];
}

@end

