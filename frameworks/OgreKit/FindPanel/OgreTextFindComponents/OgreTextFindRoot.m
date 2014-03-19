/*
 * Name: OgreTextFindRoot.m
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

#import <OgreKit/OgreTextFindRoot.h>
#import <OgreKit/OgreFindResultRoot.h>


@implementation OgreTextFindRoot

- (id)initWithComponent:(NSObject <OgreTextFindComponent>*)aComponent
{
    self = [super init];
    if (self != nil) {
        _component = aComponent;
    }
    
    return self;
}

- (void)dealloc
{
    [super dealloc];
}

/* Examing behavioral attributes */
- (BOOL)isEditable { return YES; }
- (BOOL)isHighlightable { return YES; }

/* Getting structural detail */
- (unsigned)numberOfChildrenInSelection:(BOOL)inSelection
{
    return 1; 
}

- (id)childAtIndex:(unsigned)index inSelection:(BOOL)inSelection
{
    return _component; 
}

- (NSEnumerator*)componentEnumeratorInSelection:(BOOL)inSelection
{
#ifdef DEBUG_OGRE_FIND_PANEL
	NSLog(@"  -componentEnumeratorInSelection: of %@", [self className]);
#endif
    return [[NSArray arrayWithObject:_component] objectEnumerator]; 
}

-(NSIndexSet*)selectedIndexes
{
#ifdef DEBUG_OGRE_FIND_PANEL
	NSLog(@"  -selectedIndexes of %@", [self className]);
#endif
    return [NSIndexSet indexSetWithIndex:0]; 
}

- (OgreFindResultBranch*)findResultBranchWithThread:(OgreTextFindThread*)aThread
{
#ifdef DEBUG_OGRE_FIND_PANEL
	NSLog(@"  -findResultBranchWithThread: of %@", [self className]);
#endif
    return [[[OgreFindResultRoot alloc] init] autorelease]; 
}

- (OgreTextFindBranch*)parent
{
    return nil;
}

- (int)index
{
    return 0;
}

- (OgreTextFindLeaf*)selectedLeaf
{
    return [_component selectedLeaf];
}

- (NSWindow*)window
{
    return [_component window];
}

- (void)finalizeFinding
{
    /* do nothing */
}


@end
