/*
 * Name: OgreTableCellFindResult.h
 * Project: OgreKit
 *
 * Creation Date: Jun 05 2004
 * Author: Isao Sonobe <sonoisa (AT) muse (DOT) ocn (DOT) ne (DOT) jp>
 * Copyright: Copyright (c) 2003 Isao Sonobe, All rights reserved.
 * License: OgreKit License
 *
 * Encoding: UTF8
 * Tabsize: 4
 */

#import <OgreKit/OgreFindResultBranch.h>
#import <OgreKit/OGRegularExpression.h>
#import <OgreKit/OgreTextFindResult.h>

@class OgreTableColumn;

@interface OgreTableCellFindResult : OgreFindResultBranch <OgreFindResultCorrespondingToTextFindLeaf>
{
    OgreTableColumn *_tableColumn;
    NSMutableArray  *_matchRangeArray, *_childArray;
    int             _rowIndex;
}

- (id)initWithTableColumn:(OgreTableColumn*)tableColumn row:(int)rowIndex;

// index番目にマッチした文字列のある行番号
- (NSNumber*)lineOfMatchedStringAtIndex:(unsigned)index;
// index番目にマッチした文字列
- (NSAttributedString*)matchedStringAtIndex:(unsigned)index;
// index番目にマッチした文字列を選択・表示する
- (BOOL)showMatchedStringAtIndex:(unsigned)index;
// index番目にマッチした文字列を選択する
- (BOOL)selectMatchedStringAtIndex:(unsigned)index;

- (void)targetIsMissing;

@end
