/*
 * Name: OgreTextFindComponent.h
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

#import <Foundation/Foundation.h>

@protocol OgreTextFindVisitor;
@class OgreTextFindLeaf, OgreTextFindBranch, OgreTextFindThread;

@protocol OgreTextFindComponent
- (void)acceptVisitor:(NSObject <OgreTextFindVisitor>*)aVisitor; // visitor pattern

/* Delegate methods of the OgreTextFindThread */
- (void)willProcessFinding:(NSObject <OgreTextFindVisitor>*)aVisitor;
- (void)didProcessFinding:(NSObject <OgreTextFindVisitor>*)aVisitor;
- (void)finalizeFinding;

/* Getting information */
- (id)target;               // a target (view) wrapped by a OgreTextFindComponent
- (id)name;
- (id)outline;
- (NSWindow*)window;

/* Examing behavioral attributes */
- (BOOL)isEditable;
- (BOOL)isHighlightable;

/* Getting and setting structural detail */
- (BOOL)isLeaf;
- (BOOL)isBranch;
- (unsigned)numberOfChildrenInSelection:(BOOL)inSelection;
- (unsigned)numberOfDescendantsInSelection:(BOOL)inSelection;
- (id)childAtIndex:(unsigned)index inSelection:(BOOL)inSelection;

- (OgreTextFindBranch*)parent;
- (void)setParent:(OgreTextFindBranch*)parent;
- (void)setParentNoRetain:(OgreTextFindBranch*)parent;
- (int)index;
- (void)setIndex:(int)index;
- (OgreTextFindLeaf*)selectedLeaf;

- (BOOL)isTerminal;
- (void)setTerminal:(BOOL)isTerminal;
- (BOOL)isReversed;
- (void)setReversed:(BOOL)isReversed;

@end

@protocol OgreTextFindVisitor
- (void)visitLeaf:(OgreTextFindLeaf*)aLeaf;
- (void)visitBranch:(OgreTextFindBranch*)aBranch;
@end

@protocol OgreTextFindTargetAdapter
- (OgreTextFindLeaf*)buildStackForSelectedLeafInThread:(OgreTextFindThread*)aThread;
- (void)moveHomePosition;
@end
