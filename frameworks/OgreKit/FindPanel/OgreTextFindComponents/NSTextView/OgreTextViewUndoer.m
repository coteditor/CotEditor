/*
 * Name: OgreTextViewUndoer.m
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

#import <OgreKit/OgreTextViewUndoer.h>


@implementation OgreTextViewUndoer
- (id)initWithCapacity:(unsigned)aCapacity
{
    self = [super init];
    if (self != nil) {
        _tail = 0;
        _count = aCapacity;
        _rangeArray = (NSRange*)NSZoneMalloc([self zone], sizeof(NSRange) * aCapacity);
        if (_rangeArray == NULL) {
            // ERROR!
        }
        _attributedStringArray = [[NSMutableArray alloc] initWithCapacity:aCapacity];
    }
    return self;
}

#ifdef MAC_OS_X_VERSION_10_6
- (void)finalize
{
    NSZoneFree([self zone], _rangeArray);
    [super finalize];
}
#endif

- (void)dealloc
{
    //NSLog(@"dealloc %@", self);
    [_attributedStringArray release];
    NSZoneFree([self zone], _rangeArray);
    [super dealloc];
}

- (void)addRange:(NSRange)aRange attributedString:(NSAttributedString*)anAttributedString
{
    if (_tail == _count) {
        // ERROR
    }
    *(_rangeArray + _tail) = aRange;
    [_attributedStringArray addObject:anAttributedString];
    _tail++;
}

/* Undo/Redo Replace */
- (void)undoTextView:(id)aTarget jumpToSelection:(BOOL)jumpToSelection invocationTarget:(id)myself
{
	NSTextStorage       *textStorage = [aTarget textStorage];
    NSRange             aRange, newRange;
    NSAttributedString  *aString;
    unsigned            i;
    OgreTextViewUndoer    *redoArray = [[OgreTextViewUndoer alloc] initWithCapacity:_count];
    
    [textStorage beginEditing];
    
    NSAutoreleasePool   *pool = [[NSAutoreleasePool alloc] init];
    
    i = _count;
    while (i > 0) {
        i--;
        aRange = *(_rangeArray + i);
        aString = [_attributedStringArray objectAtIndex:i];
        //NSLog(@"(%d, %d), %@", aRange.location, aRange.length, [aString string]);
        
        newRange = NSMakeRange(aRange.location, [aString length]);
        [redoArray addRange:newRange attributedString:[[[NSAttributedString alloc] initWithAttributedString:[textStorage attributedSubstringFromRange:aRange]] autorelease]];
        
        // undo
        [textStorage replaceCharactersInRange:aRange withAttributedString:aString];
        if (jumpToSelection) [aTarget scrollRangeToVisible:newRange];
        
        if ((_count - i) % 1000 == 0) {
            [pool release];
            pool = [[NSAutoreleasePool alloc] init];
        }
    }
    
    // redo　registeration
    [[[aTarget undoManager] prepareWithInvocationTarget:redoArray] 
        undoTextView:aTarget jumpToSelection:jumpToSelection
        invocationTarget:redoArray];
        
    [redoArray release];
    [pool release];
    
    [textStorage endEditing];
    [aTarget setSelectedRange:newRange];
}

@end
