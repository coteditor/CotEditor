/*
 * Name: OgreTextFindBranch.h
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

#import <OgreKit/OgreTextFindComponent.h>

@class OgreFindResultBranch, OgreTextFindThread;

@interface OgreTextFindBranch : NSObject <OgreTextFindComponent>
{
    OgreTextFindBranch      *_parent;
    int                     _index;
    BOOL                    _isParentRetained;
    BOOL                    _isTerminal;
    BOOL                    _isReversed;
}

/* Getting selected components */
-(NSIndexSet*)selectedIndexes;

/* Getting an enumerator */
- (NSEnumerator*)componentEnumeratorInSelection:(BOOL)inSelection;  // in the responder chain ordering

- (OgreFindResultBranch*)findResultBranchWithThread:(OgreTextFindThread*)aThread;

@end
