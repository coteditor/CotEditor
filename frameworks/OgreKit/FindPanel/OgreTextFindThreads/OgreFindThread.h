/*
 * Name: OgreFindThread.h
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

#import <OgreKit/OgreTextFindThread.h>

@class OGRegularExpressionMatch, OGRegularExpressionEnumerator, OgreFindResult;
@class OgreTextFindThread;

@interface OgreFindThread : OgreTextFindThread 
{
    BOOL                _wrap;                  // wrapped search
    BOOL                _backward;              // search direction
    BOOL                _fromTop;               // search origin
    
    NSEnumerator        *matchEnumerator;
    BOOL                _lhsPhase;
}

- (BOOL)shouldPreprocessFindingInFirstLeaf;
- (BOOL)preprocessFindingInFirstLeaf:(OgreTextFindLeaf*)aLeaf;

- (void)setWrap:(BOOL)wrap;
- (BOOL)wrap;
- (void)setBackward:(BOOL)backward;
- (BOOL)backward;
- (void)setFromTop:(BOOL)fromTop;
- (BOOL)fromTop;

// private methods
- (BOOL)_preprocessFindingInFirstLeaf:(OgreTextFindLeaf*)aLeaf;

@end
