/*
 * Name: OgreTextViewPlainAdapter.m
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

#import <OgreKit/OGString.h>
#import <OgreKit/OGPlainString.h>

#import <OgreKit/OgreTextView.h>

#import <OgreKit/OgreTextViewAdapter.h>
#import <OgreKit/OgreTextViewPlainAdapter.h>
#import <OgreKit/OgreTextViewUndoer.h>

#import <OgreKit/OgreTextViewFindResult.h>
#import <OgreKit/OgreTextFinder.h>
#import <OgreKit/OgreTextFindThread.h>


@implementation OgreTextViewPlainAdapter

/* Creating and initializing */
- (id)initWithTarget:(id)aTextView
{
#ifdef DEBUG_OGRE_FIND_PANEL
	NSLog(@" -initWithTextView: of %@", [self className]);
#endif
    self = [super init];
    if (self != nil) {
        _textView = [aTextView retain];
		_textStorage = [_textView textStorage];
        _storageLocked = NO;
        _allowsUndo = NO;
    }
    
    return self;
}


- (void)dealloc
{
    [_undoer release];
    [_textView release];
    [super dealloc];
}

/* protocol of OgreTextFindComponent */
/* Delegate methods of the OgreTextFindVisitor */
- (OgreTextFindLeaf*)buildStackForSelectedLeafInThread:(OgreTextFindThread*)aThread
{
    NSEnumerator        *enumerator;
    OgreTextFindBranch  *branch;
    OgreTextViewAdapter *textViewAdapter;
    
    // root
    branch = [aThread rootAdapter];
    enumerator = [branch componentEnumeratorInSelection:[aThread inSelection]];
    [aThread pushEnumerator:enumerator];
    [aThread pushBranch:branch];
    [branch willProcessFinding:aThread];
    [aThread willProcessFindingInBranch:branch];
    
    // text view
    textViewAdapter = [enumerator nextObject];
    [textViewAdapter setFirstLeaf:YES];
    [aThread _setLeafProcessing:textViewAdapter];
    
    return textViewAdapter;
}

- (void)willProcessFinding:(NSObject <OgreTextFindVisitor>*)aVisitor
{
#ifdef DEBUG_OGRE_FIND_PANEL
	NSLog(@" -willProcessFinding: of %@", [self className]);
#endif
    /* do nothing */
}

- (void)didProcessFinding:(NSObject <OgreTextFindVisitor>*)aVisitor
{
#ifdef DEBUG_OGRE_FIND_PANEL
	NSLog(@" -didProcessFinding: of %@", [self className]);
#endif
    /* do nothing */
}


/* Accessor methods */
- (NSRange)selectedRange
{
    return [_textView selectedRange];
}

- (NSObject<OGStringProtocol>*)ogString
{
    return [[[OGPlainString alloc] initWithString:[_textView string]] autorelease];
}

- (void)setOGString:(NSObject<OGStringProtocol>*)aString
{
    [_textView setString:[aString string]];
}

- (void)replaceCharactersInRange:(NSRange)aRange withOGString:(NSObject<OGStringProtocol>*)aString
{
    // Undo操作の登録
    if (_allowsUndo) {
        //[_textView setSelectedRange:aRange];
        [_undoer addRange:NSMakeRange(aRange.location, [aString length]) 
			attributedString:[[[NSAttributedString alloc] 
				initWithAttributedString:[_textStorage attributedSubstringFromRange:aRange]] autorelease]];
        //NSLog(@"(%d, %d), %@", aRange.location, aRange.length, [[_textStorage attributedSubstringFromRange:aRange] string]);
    }
    
    // 置換
	[_textStorage replaceCharactersInRange:aRange withString:[aString string]];
}

- (id)target
{
    return _textView;
}

- (void)beginEditing
{
#ifdef DEBUG_OGRE_FIND_PANEL
	NSLog(@" -beginEditing of %@", [self className]);
#endif
    if (!_storageLocked) {
        _storageLocked = YES;
        [_textStorage beginEditing];
    }
}

- (void)beginRegisteringUndoWithCapacity:(unsigned)aCapacity
{
    // Undo操作の登録開始
    _allowsUndo = [_textView allowsUndo];
    if (_allowsUndo) {
        _undoManager = [_textView undoManager];
        [_undoManager beginUndoGrouping];
        _undoer = [[OgreTextViewUndoer alloc] initWithCapacity:aCapacity];
    }
}

- (void)endRegisteringUndo
{
     if (_allowsUndo) {
        // registeration undo
        [[_undoManager prepareWithInvocationTarget:[_undoer autorelease]] undoTextView:_textView jumpToSelection:NO invocationTarget:_undoer];
        _undoer = nil;
        // Undo操作の登録完了
        [_undoManager setActionName:OgreTextFinderLocalizedString(@"Replace All")];
        [_undoManager endUndoGrouping];
    }
}

- (void)endEditing
{
#ifdef DEBUG_OGRE_FIND_PANEL
	NSLog(@" -endEditing of %@", [self className]);
#endif
    if (_storageLocked) {
        _storageLocked = NO;
        [_textStorage endEditing];
        
        if ([_textView isKindOfClass:[OgreTextView class]]) [(OgreTextView*)_textView ogreDidEndEditing];
    }
}

- (void)unhighlight
{
    [[_textView layoutManager] removeTemporaryAttribute:NSBackgroundColorAttributeName 
        forCharacterRange:NSMakeRange(0, [[_textView string] length])];
}

- (void)highlightCharactersInRange:(NSRange)aRange color:(NSColor*)highlightColor
{
    [[_textView layoutManager] 
        setTemporaryAttributes:[NSDictionary dictionaryWithObject:highlightColor forKey:NSBackgroundColorAttributeName] 
        forCharacterRange:aRange];
}

- (id)name { return [_textView className]; }
- (id)outline { return @""; }

- (BOOL)isEditable { return YES; }
- (BOOL)isHighlightable { return YES; }

- (OgreFindResultLeaf*)findResultLeafWithThread:(OgreTextFindThread*)aThread {
    return [[[OgreTextViewFindResult alloc] initWithTextView:_textView] autorelease]; 
}

- (BOOL)isSelected
{
    return YES;
}

- (void)setSelectedRange:(NSRange)aRange
{
    [_textView setSelectedRange:aRange];
}

- (void)jumpToSelection
{
    [_textView scrollRangeToVisible:[_textView selectedRange]];
}

- (NSWindow*)window
{
    return [_textView window];
}

- (void)moveHomePosition
{
    [_textView setSelectedRange:NSMakeRange(0, 0)];
}

- (NSTextStorage*)textStorage
{
	return _textStorage;
}

@end
