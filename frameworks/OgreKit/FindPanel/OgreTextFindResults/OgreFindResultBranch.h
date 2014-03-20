/*
 * Name: OgreFindResultBranch.h
 * Project: OgreKit
 *
 * Creation Date: Apr 18 2004
 * Author: Isao Sonobe <sonoisa (AT) muse (DOT) ocn (DOT) ne (DOT) jp>
 * Copyright: Copyright (c) 2003 Isao Sonobe, All rights reserved.
 * License: OgreKit License
 *
 * Encoding: UTF8
 * Tabsize: 4
 */

#import <OgreKit/OgreTextFindBranch.h>

@class OgreTextFindResult;

@interface OgreFindResultBranch : OgreTextFindBranch
{
    OgreTextFindResult  *_textFindResult;
}

/* methods overridden by subclass of OgreFindResultLeaf  */
- (void)addComponent:(NSObject <OgreTextFindComponent>*)aFindResultComponent;
- (void)endAddition;
- (OgreTextFindResult*)textFindResult;
- (void)setTextFindResult:(OgreTextFindResult*)textFindResult;

- (BOOL)showMatchedString;
- (BOOL)selectMatchedString;

@end
