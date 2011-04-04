/*
 * Name: OgreOutlineCellFindResult.h
 * Project: OgreKit
 *
 * Creation Date: Jun 06 2004
 * Author: Isao Sonobe <sonoisa (AT) muse (DOT) ocn (DOT) ne (DOT) jp>
 * Copyright: Copyright (c) 2003 Isao Sonobe, All rights reserved.
 * License: OgreKit License
 *
 * Encoding: UTF8
 * Tabsize: 4
 */

#import <OgreKit/OgreFindResultBranch.h>
#import <OgreKit/OgreTextFindResult.h>

@class OgreOutlineColumn;

@interface OgreOutlineCellFindResult : OgreFindResultBranch <OgreFindResultCorrespondingToTextFindLeaf> 
{
    OgreOutlineColumn   *_outlineColumn;
    id                  _item;
    
    NSMutableArray      *_matchRangeArray, *_matchComponents;
}

- (id)initWithOutlineColumn:(OgreOutlineColumn*)outlineColumn item:(id)item;

// index番目にマッチした文字列のある項目名
- (id)nameOfMatchedStringAtIndex:(unsigned)index;
// index番目にマッチした文字列
- (NSAttributedString*)matchedStringAtIndex:(unsigned)index;
// index番目にマッチした文字列を選択・表示する
- (BOOL)showMatchedStringAtIndex:(unsigned)index;
// index番目にマッチした文字列を選択する
- (BOOL)selectMatchedStringAtIndex:(unsigned)index;

- (void)targetIsMissing;
- (NSArray*)children;

@end
