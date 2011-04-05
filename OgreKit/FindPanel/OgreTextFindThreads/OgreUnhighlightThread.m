/*
 * Name: OgreUnhighlightThread.m
 * Project: OgreKit
 *
 * Creation Date: May 20 2004
 * Author: Isao Sonobe <sonoisa (AT) muse (DOT) ocn (DOT) ne (DOT) jp>
 * Copyright: Copyright (c) 2004 Isao Sonobe, All rights reserved.
 * License: OgreKit License
 *
 * Encoding: UTF8
 * Tabsize: 4
 */

#import <OgreKit/OgreUnhighlightThread.h>


@implementation OgreUnhighlightThread

/* Methods implemented by subclasses of OgreTextFindThread */
- (SEL)didEndSelectorForFindPanelController
{
    return @selector(didEndUnhighlight:);
}

- (void)willProcessFindingInLeaf:(OgreTextFindLeaf*)aLeaf;
{
#ifdef DEBUG_OGRE_FIND_PANEL
	NSLog(@"-willProcessFindingInLeaf: of %@", [self className]);
#endif
    if ([aLeaf isHighlightable]) [aLeaf unhighlight];
}

- (BOOL)shouldContinueFindingInLeaf:(OgreTextFindLeaf*)aLeaf;
{
    return NO; // stop
}

- (void)didProcessFindingAll
{
#ifdef DEBUG_OGRE_FIND_PANEL
	NSLog(@" -didProcessFindingAll of %@", [self className]);
#endif
    [[self result] setType:OgreTextFindResultSuccess];
    
    [self finish];
}

@end
