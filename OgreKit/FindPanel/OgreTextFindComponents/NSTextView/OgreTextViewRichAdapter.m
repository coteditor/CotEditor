/*
 * Name: OgreTextViewRichAdapter.m
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

#import <OgreKit/OGAttributedString.h>

#import <OgreKit/OgreTextView.h>

#import <OgreKit/OgreTextViewPlainAdapter.h>
#import <OgreKit/OgreTextViewRichAdapter.h>
#import <OgreKit/OgreTextViewUndoer.h>


@implementation OgreTextViewRichAdapter

/* Accessor methods */
- (NSObject<OGStringProtocol>*)ogString
{
    return [[[OGAttributedString alloc] initWithAttributedString:[self textStorage]] autorelease];
}

- (void)setOGString:(NSObject<OGStringProtocol>*)aString
{
	NSTextStorage	*textStorage = [self textStorage];
    [textStorage setAttributedString:[aString attributedString]];
	[textStorage removeAttribute:NSAttachmentAttributeName range:NSMakeRange(0, [textStorage length])];
}

- (void)replaceCharactersInRange:(NSRange)aRange withOGString:(NSObject<OGStringProtocol>*)aString
{
	NSTextStorage	*textStorage = [self textStorage];
	unsigned	appendantLength = [aString length];
	
    // Undo操作の登録
    if (_allowsUndo) {
        //[_textView setSelectedRange:aRange];
        [_undoer addRange:NSMakeRange(aRange.location, appendantLength) 
			attributedString:[[[NSAttributedString alloc] 
				initWithAttributedString:[textStorage attributedSubstringFromRange:aRange]] autorelease]];
        //NSLog(@"(%d, %d), %@", aRange.location, aRange.length, [[textStorage attributedSubstringFromRange:aRange] string]);
    }
    
    // 置換
	[textStorage replaceCharactersInRange:aRange withAttributedString:[aString attributedString]];
	[textStorage removeAttribute:NSAttachmentAttributeName range:NSMakeRange(aRange.location, appendantLength)];
}

@end
