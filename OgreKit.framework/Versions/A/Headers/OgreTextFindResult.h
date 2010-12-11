/*
 * Name: OgreTextFindResult.h
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

#import <OgreKit/OGRegularExpression.h>
#import <OgreKit/OGRegularExpressionMatch.h>
#import <OgreKit/OgreTextFinder.h>
#import <OgreKit/OgreFindResultLeaf.h>
#import <OgreKit/OgreFindResultBranch.h>

@protocol OgreTextFindProgressDelegate;

@protocol OgreTextFindResultDelegateProtocol
- (void)didUpdateTextFindResult:(id)textFindResult;
@end

@protocol OgreFindResultCorrespondingToTextFindLeaf
- (void)addMatch:(OGRegularExpressionMatch*)aMatch;
- (void)endAddition;
@end


typedef enum {
	OgreTextFindResultFailure = 0, 
	OgreTextFindResultSuccess = 1, 
	OgreTextFindResultError = 2
} OgreTextFindResultType;

@interface OgreTextFindResult : NSObject
{
	OgreTextFindResultType		_resultType;
	id							_target;
    unsigned                    _numberOfMatches;           // number of the matches
    OGRegularExpression         *_regex;
    
    OgreFindResultBranch        *_resultTree, *_branch;
    NSMutableArray              *_branchStack;
	
    /* handling exception */
	NSException					*_exception;
	id							_alertSheet;
    
    /* display */
	NSString					*_title;					// target window title
	int                         _maxMatchedStringLength;	// -matchedStringAtIndex:の返す最大文字数 (-1: 無制限)
	int                         _maxLeftMargin;				// マッチした文字列の左側の最大文字数 (-1: 無制限)
	id                          _delegate;                  // 更新連絡先
    
    /* highlight color */
    NSMutableArray              *_highlightColorArray;   // variations
}

+ (id)textFindResultWithTarget:(id)targetFindingIn thread:(OgreTextFindThread*)aThread;
- (id)initWithTarget:(id)targetFindingIn thread:(OgreTextFindThread*)aThread;

- (void)setType:(OgreTextFindResultType)resultType;
- (BOOL)isSuccess;				/* success or failure(including error) */
- (NSObject <OgreTextFindComponent>*)result;
- (NSString*)findString;

- (BOOL)alertIfErrorOccurred;
- (void)setAlertSheet:(id /*<OgreTextFindProgressDelegate>*/)aSheet exception:(NSException*)anException;

- (void)beginGraftingToBranch:(OgreFindResultBranch*)aBranch;
- (void)endGrafting;
- (void)addLeaf:(id)aLeaf;

- (unsigned)numberOfMatches;
- (void)setNumberOfMatches:(unsigned)aNumber;

- (NSString*)title;
- (void)setTitle:(NSString*)title;

// マッチした文字列の左側の最大文字数 (-1: 無制限)
- (int)maximumLeftMargin;
- (void)setMaximumLeftMargin:(int)leftMargin;
// 最大文字数 (-1: 無制限) ただし、省略記号@"..."はカウントに入れない。
- (int)maximumMatchedStringLength;
- (void)setMaximumMatchedStringLength:(int)aLength;
- (void)setHighlightColor:(NSColor*)aColor regularExpression:(OGRegularExpression*)regex;
// aString中のaRangeArrayの範囲を強調する。
- (NSAttributedString*)highlightedStringInRange:(NSArray*)aRangeArray ofString:(NSString*)aString;
- (NSAttributedString*)missingString;
- (NSAttributedString*)messageOfStringsFound:(unsigned)numberOfMatches;
- (NSAttributedString*)messageOfItemsFound:(unsigned)numberOfMatches;

// delegate
- (id)delegate;
- (void)setDelegate:(id)aDelegate;
- (void)didUpdate;

// setting of result outline view
- (NSCell*)nameCell;
- (float)rowHeight;
// delegate method of the find result outline view
- (void)outlineView:(NSOutlineView *)outlineView willDisplayCell:(id)cell forTableColumn:(NSTableColumn *)tableColumn item:(id)item;

@end
