/*
 * Name: ReplaceWithAttributesTest.h
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

#import <Cocoa/Cocoa.h>
#import <OgreKit/OgreKit.h>

@interface ReplaceWithAttributesTest : NSObject
{
    IBOutlet NSTextView		*findTextView;
    IBOutlet NSTextView		*replaceTextView;
    IBOutlet NSTextView		*targetTextView;
	IBOutlet NSTextField	*escapeCharacterTextField;
	
	BOOL	attributedReplace;
	BOOL	replaceFont;
	BOOL	mergeAttributes;
}
- (IBAction)replace:(id)sender;

- (unsigned)options;
- (BOOL)attributedReplace;
- (void)setAttributedReplace:(BOOL)yesOrNo;

@end
