/*
 * Name: ReplaceWithAttributesTest.m
 * Project: OgreKit
 *
 * Creation Date: Sep 23 2004
 * Author: Isao Sonobe <sonoisa (AT) muse (DOT) ocn (DOT) ne (DOT) jp>
 * Copyright: Copyright (c) 2004 Isao Sonobe, All rights reserved.
 * License: OgreKit License
 *
 * Encoding: UTF8
 * Tabsize: 4
 */

#import "ReplaceWithAttributesTest.h"

@implementation ReplaceWithAttributesTest

- (IBAction)replace:(id)sender
{
	NSTextStorage	*targetString  = [targetTextView textStorage];
	NSTextStorage	*findString    = [findTextView textStorage];
	NSTextStorage	*replaceString = [replaceTextView textStorage];
	
	// escape character
	NSString	*escapeChar = [escapeCharacterTextField stringValue];
	[OGRegularExpression setDefaultEscapeCharacter:escapeChar];
	// syntax
	[OGRegularExpression setDefaultSyntax:OgreRubySyntax];
	
	NSAttributedString	*resultString;
	OGRegularExpression	*rx;
	
	/*NSDate	*processTime;
	int i;
	double	sum = 0;
	for(i = 0; i < 100; i++) {
		processTime = [NSDate date];*/
		
		// create regex instance
		rx = [OGRegularExpression regularExpressionWithString:[findString string] 
			options:OgreCaptureGroupOption];
		// replace all
		resultString = [rx replaceAllMatchesInAttributedString:targetString 
			withAttributedString:replaceString 
			options:[self options]];
		
	/*	sum += -[processTime timeIntervalSinceNow];
	}
	NSLog(@"process time: %fsec/inst", sum/100);*/
	
	// 置換
	[targetString setAttributedString:resultString];
	[targetTextView display];
}

- (void)awakeFromNib
{
	[self setAttributedReplace:YES];
}

- (unsigned)options
{
	unsigned	options = OgreNoneOption;
	if (attributedReplace) options |= OgreReplaceWithAttributesOption;
	if (replaceFont) options |= OgreReplaceFontsOption;
	if (mergeAttributes) options |= OgreMergeAttributesOption;
	
	return options;
}

- (BOOL)attributedReplace
{
	return attributedReplace;
}

- (void)setAttributedReplace:(BOOL)yesOrNo
{
	attributedReplace = yesOrNo;
}

- (BOOL)applicationShouldTerminateAfterLastWindowClosed:(NSApplication*)aApp
{
	return YES;	// 全てのウィンドウを閉じたら終了する。
}

@end
