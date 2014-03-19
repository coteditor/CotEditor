/*
 * Name: OgreTextViewFindResult.h
 * Project: OgreKit
 *
 * Creation Date: Sep 18 2003
 * Author: Isao Sonobe <sonoisa (AT) muse (DOT) ocn (DOT) ne (DOT) jp>
 * Copyright: Copyright (c) 2003 Isao Sonobe, All rights reserved.
 * License: OgreKit License
 *
 * Encoding: UTF8
 * Tabsize: 4
 */

#import <OgreKit/OGRegularExpression.h>
#import <OgreKit/OGRegularExpressionMatch.h>
#import <OgreKit/OgreFindResultLeaf.h>
#import <OgreKit/OgreFindResultBranch.h>
#import <OgreKit/OgreTextFindResult.h>

extern NSString	*OgreTextViewFindResultException;

@interface OgreTextViewFindResult : OgreFindResultBranch <OgreFindResultCorrespondingToTextFindLeaf>
{
	NSTextView			*_textView;		// 検索対象
	
	NSString			*_text;					// 検索対象の文字列
	unsigned			_textLength;			// その長さ
	unsigned			_searchLineRangeLocation;	// 行の範囲を調べる起点
	unsigned			_line;					// 調べている行
	NSRange				_lineRange;				// _line行目の範囲
	
	NSMutableArray		*_lineOfMatchedStrings, // マッチした文字列のある行番号 (0番目はダミー。常に0。)
						*_matchRangeArray, 		// マッチした部分文字列の範囲 (0番目はダミー。常に((0,0))。)
												// 要素: (マッチ範囲, 1番目の部分マッチ範囲, 2番目の...)
												//  ただし、locationは相対位置を保持する。(更新を高速化するため)
												//  0番目の部分文字列は前のマッチとの相対位置
												//  1番目以降の部分文字列は0番目の部分文字列との相対位置
                        *_childArray;           // マッチした文字列のresult leaf array

	unsigned			_count;					// マッチした文字列の数
	
	int					_cacheIndex;			// 表示用キャッシュ
	unsigned			_cacheAbsoluteLocation;	// _cacheIndex番目のマッチの絶対位置
	
	int					_updateCacheIndex;				// 更新用キャッシュ
	unsigned			_updateCacheAbsoluteLocation;	// _updateCacheIndex番目のマッチの絶対位置
}

// 初期化
- (id)initWithTextView:(NSTextView*)textView;

/* pseudo-OgreFindResultLeaf  */
// マッチを追加
- (void)addMatch:(OGRegularExpressionMatch*)match;
// マッチの追加を終了する。
//- (void)endAddition;

// index番目にマッチした文字列のある行番号
- (NSNumber*)lineOfMatchedStringAtIndex:(unsigned)index;
// index番目にマッチした文字列
- (NSAttributedString*)matchedStringAtIndex:(unsigned)index;
// index番目にマッチした文字列を選択・表示する
- (BOOL)showMatchedStringAtIndex:(unsigned)index;
// index番目にマッチした文字列を選択する
- (BOOL)selectMatchedStringAtIndex:(unsigned)index;
// マッチ数
- (unsigned)count;

// 結果の更新
- (void)updateOldRange:(NSRange)oldRange newRange:(NSRange)newRange;
- (void)updateSubranges:(NSMutableArray*)target count:(unsigned)numberOfSubranges oldRange:(NSRange)oldRange newRange:(NSRange)newRange origin:(unsigned)origin leftAlign:(BOOL)leftAlign;

@end
