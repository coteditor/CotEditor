/*
 * Name: OgreTextViewPlainAdapter.h
 * Project: OgreKit
 *
 * Creation Date: May 20 2004
 * Author: Isao Sonobe <sonoisa (AT) muse (DOT) ocn (DOT) ne (DOT) jp>
 * Copyright: Copyright (c) 2003 Isao Sonobe, All rights reserved.
 * License: OgreKit License
 *
 * Encoding: UTF8
 * Tabsize: 4
 */

#import <Cocoa/Cocoa.h>
#import <OgreKit/OgreTextFindLeaf.h>

@class OgreTextViewUndoer;

@interface OgreTextViewPlainAdapter : OgreTextFindLeaf <OgreTextFindTargetAdapter>
{
	NSTextView			*_textView;
	NSTextStorage		*_textStorage;
	NSUndoManager		*_undoManager;
	BOOL				_storageLocked;
	BOOL				_allowsUndo;
	OgreTextViewUndoer	*_undoer;
}

- (id)initWithTarget:(id)aTextView;
- (NSTextStorage*)textStorage;

@end
