/*
 * Name: OgreTextFindLeaf.m
 * Project: OgreKit
 *
 * Creation Date: Sep 26 2003
 * Author: Isao Sonobe <sonoisa (AT) muse (DOT) ocn (DOT) ne (DOT) jp>
 * Copyright: Copyright (c) 2003 Isao Sonobe, All rights reserved.
 * License: OgreKit License
 *
 * Encoding: UTF8
 * Tabsize: 4
 */

#import <OgreKit/OgreTextFindLeaf.h>
#import <OgreKit/OgreTextFindBranch.h>
#import <OgreKit/OgreFindResultLeaf.h>


@implementation OgreTextFindLeaf

#ifdef MAC_OS_X_VERSION_10_6
- (void)finalize
{
#ifdef DEBUG_OGRE_FIND_PANEL
	NSLog(@"  -finalize of %@", [self className]);
#endif
    [super finalize];
}
#endif

- (void)dealloc
{
#ifdef DEBUG_OGRE_FIND_PANEL
	NSLog(@"  -dealloc of %@", [self className]);
#endif
    if (_isParentRetained) [_parent release];
    [super dealloc];
}

- (void)acceptVisitor:(NSObject <OgreTextFindVisitor>*)aVisitor // visitor pattern
{
    [aVisitor visitLeaf:self];
}


/* Delegate methods of the OgreTextFindThread */
- (void)willProcessFinding:(NSObject <OgreTextFindVisitor>*)aVisitor
{
#ifdef DEBUG_OGRE_FIND_PANEL
	NSLog(@"  -willProcessFinding: of %@", [self className]);
#endif
    /* do nothing */
}

- (void)didProcessFinding:(NSObject <OgreTextFindVisitor>*)aVisitor
{
#ifdef DEBUG_OGRE_FIND_PANEL
	NSLog(@"  -didProcessFinding: of %@", [self className]);
#endif
    /* do nothing */
}


/* Getting information */
- (id)target
{
#ifdef DEBUG_OGRE_FIND_PANEL
	NSLog(@"  -target of %@", [self className]);
#endif
    return nil; 
}

- (id)name
{
#ifdef DEBUG_OGRE_FIND_PANEL
	NSLog(@"  -name of %@ (BUG!!!)", [self className]);
#endif
    return nil; 
}

- (id)outline
{
#ifdef DEBUG_OGRE_FIND_PANEL
	NSLog(@"  -outline of %@ (BUG!!!)", [self className]);
#endif
    return nil; 
}


/* Examing behavioral attributes */
- (BOOL)isEditable { return NO; }
- (BOOL)isHighlightable { return NO; }

/* Getting structural detail */
- (BOOL)isLeaf { return YES; }
- (BOOL)isBranch { return NO; }
- (unsigned)numberOfChildrenInSelection:(BOOL)inSelection { return 0; }
- (unsigned)numberOfDescendantsInSelection:(BOOL)inSelection { return 0; }
- (id)childAtIndex:(unsigned)index inSelection:(BOOL)inSelection { return nil; }

- (OgreTextFindBranch*)parent
{
#ifdef DEBUG_OGRE_FIND_PANEL
	if (_parent == nil) NSLog(@"  -parent == nil of OgreTextFindLeaf (BUG?)");
#endif
    return _parent;
}

- (void)setParent:(OgreTextFindBranch*)parent
{
    if (_isParentRetained) [_parent autorelease];
    _parent = [parent retain];
    _isParentRetained = YES;
}

- (void)setParentNoRetain:(OgreTextFindBranch*)parent
{
    if (_isParentRetained) [_parent autorelease];
    _parent = parent;
    _isParentRetained = NO;
}

/* Accessor methods */
- (void)beginEditing { /* do nothing */ }
- (void)endEditing { /* do nothing */ }
- (void)beginRegisteringUndoWithCapacity:(unsigned)aCapacity { /* do nothing */ }
- (void)endRegisteringUndo { /* do nothing */ }

- (BOOL)isSelected
{
    return NO;
}

- (NSRange)selectedRange 
{
#ifdef DEBUG_OGRE_FIND_PANEL
	NSLog(@"  -selectedRange of %@ (BUG?)", [self className]);
#endif
    return NSMakeRange(0, 0); 
}

- (void)setSelectedRange:(NSRange)aRange
{
#ifdef DEBUG_OGRE_FIND_PANEL
	NSLog(@"  -setSelectedRange: of %@ (BUG?)", [self className]);
#endif
    /* do nothing */
}

- (void)jumpToSelection
{
#ifdef DEBUG_OGRE_FIND_PANEL
	NSLog(@"  -jumpToSelection of %@ (BUG?)", [self className]);
#endif
    /* do nothing */
}


- (NSObject<OGStringProtocol>*)ogString 
{
#ifdef DEBUG_OGRE_FIND_PANEL
	NSLog(@"  -string of %@ (BUG!!!)", [self className]);
#endif
    return nil; 
}

- (void)setOGString:(NSObject<OGStringProtocol>*)aString 
{
#ifdef DEBUG_OGRE_FIND_PANEL
	NSLog(@"  -setOGString: of %@ (BUG?)", [self className]);
#endif
    /* do nothing */ 
}

- (void)replaceCharactersInRange:(NSRange)aRange withOGString:(NSObject<OGStringProtocol>*)aString
{
#ifdef DEBUG_OGRE_FIND_PANEL
	NSLog(@"  -replaceCharactersInRange:withOGString: of %@ (BUG?)", [self className]);
#endif
    /* do nothing */ 
}


- (void)unhighlight
{
#ifdef DEBUG_OGRE_FIND_PANEL
	NSLog(@"  -unhighlight of %@ (BUG?)", [self className]);
#endif
    /* do nothing */ 
}

- (void)highlightCharactersInRange:(NSRange)aRange color:(NSColor*)highlightColor
{
#ifdef DEBUG_OGRE_FIND_PANEL
	NSLog(@"  -highlightCharactersInRange:color: of %@ (BUG?)", [self className]);
#endif
    /* do nothing */ 
}


- (OgreFindResultLeaf*)findResultLeafWithThread:(OgreTextFindThread*)aThrea
{
#ifdef DEBUG_OGRE_FIND_PANEL
	NSLog(@"  -findResultLeafWithThread: of %@ (BUG!!!)", [self className]);
#endif
    return nil; 
}

- (int)index
{
    return _index;
}

- (void)setIndex:(int)index
{
    _index = index;
}

- (OgreTextFindLeaf*)selectedLeaf
{
    [self setFirstLeaf:YES];
    return self;
}

- (NSWindow*)window
{
#ifdef DEBUG_OGRE_FIND_PANEL
	NSLog(@"  -window of %@ (BUG!!!)", [self className]);
#endif
    return nil;
}

- (BOOL)isTerminal
{
    return _isTerminal;
}

- (void)setTerminal:(BOOL)isTerminal
{
    if (isTerminal) _isFirstLeaf = NO;
    _isTerminal = isTerminal;
}

- (BOOL)isFirstLeaf
{
    return _isFirstLeaf;
}

- (void)setFirstLeaf:(BOOL)isFirstLeaf
{
    if (isFirstLeaf) _isTerminal = NO;
    _isFirstLeaf = isFirstLeaf;
}

- (BOOL)isReversed
{
    return _isReversed;
}

- (void)setReversed:(BOOL)isReversed
{
    _isReversed = isReversed;
}

- (void)finalizeFinding
{
    [self didProcessFinding:nil];
    [_parent finalizeFinding];
}

@end
