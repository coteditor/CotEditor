/*
 * Name: OgreFindResultBranch.m
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

#import <OgreKit/OgreFindResultBranch.h>
#import <OgreKit/OgreTextFindResult.h>

@implementation OgreFindResultBranch

- (void)addComponent:(NSObject <OgreTextFindComponent>*)aFindResultComponent 
{
#ifdef DEBUG_OGRE_FIND_PANEL
	NSLog(@" -addComponent: of %@ (BUG!!!)", [self className]);
#endif
    /* do nothing */  
}
- (void)endAddition 
{
    /* do nothing */ 
}
- (OgreTextFindResult*)textFindResult
{
    return _textFindResult;
}

- (void)setTextFindResult:(OgreTextFindResult*)textFindResult
{
    _textFindResult = textFindResult;
}

- (BOOL)showMatchedString
{
    /* do nothing */
    return NO;
}

- (BOOL)selectMatchedString
{
    /* do nothing */
    return NO;
}

@end
