/*
 * Name: OgreTextViewUndoer.h
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


@interface OgreTextViewUndoer : NSObject
{
    NSRange             *_rangeArray;
    NSMutableArray      *_attributedStringArray;
    unsigned            _count, _tail;
}
- (id)initWithCapacity:(unsigned)aCapacity;
- (void)addRange:(NSRange)aRange attributedString:(NSAttributedString*)anAttributedString;
- (void)undoTextView:(id)aTarget jumpToSelection:(BOOL)jumpToSelection invocationTarget:(id)myself;
@end

/* [MEMO]
-[NSUndoManager prepareWithInvocationTarget:]のtargetはretainされないため、
invocationTarget:に自分を渡しretainされるようにした。
*/
