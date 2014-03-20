/*
 * Name: OgreTextViewFindResult.m
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

#import <OgreKit/OgreTextViewFindResult.h>
#import <OgreKit/OGRegularExpressionMatch.h>
#import <OgreKit/OgreTextViewMatchFindResult.h>
#import <OgreKit/OgreTextFinder.h>
#import <OgreKit/OgreTextFindResult.h>

static const unsigned   OgreTextViewFindResultInitialCapacity = 30;

@implementation OgreTextViewFindResult

- (id)initWithTextView:(NSTextView*)textView
{
#ifdef DEBUG_OGRE_FIND_PANEL
	NSLog(@" -initWithString: of %@", [self className]);
#endif	
	self = [super init];
	if (self) {
        _textView = [textView retain];
		/* 1行目の範囲を得る */
		_text = [[_textView string] retain];
		_textLength = [_text length];
		_lineRange = [_text lineRangeForRange:NSMakeRange(0, 0)];
		_searchLineRangeLocation = _lineRange.location + _lineRange.length;
		
		_lineOfMatchedStrings = [[NSMutableArray alloc] initWithCapacity:OgreTextViewFindResultInitialCapacity];
		[_lineOfMatchedStrings addObject:[NSNumber numberWithUnsignedInt:0]];
		_matchRangeArray = [[NSMutableArray alloc] initWithCapacity:OgreTextViewFindResultInitialCapacity];
		[_matchRangeArray addObject:[NSArray arrayWithObject:[NSValue valueWithRange:NSMakeRange(0, 0)]]];
		_count = 0;
		
		_line = 1;
		_cacheAbsoluteLocation = 0;
	}
	
	return self;
}

- (void)endAddition
{
	[_text release];
	
	if ([self count] == 0) return;	// マッチしなかった場合
	//targetのあるwindowのcloseを検出する。
	[[NSNotificationCenter defaultCenter] addObserver: self 
		selector: @selector(windowWillClose:) 
		name: NSWindowWillCloseNotification
		object: [_textView window]];
	
	//text storageの変更を検出する。
	[[NSNotificationCenter defaultCenter] addObserver: self 
		selector: @selector(textStorageWillProcessEditing:) 
		name: NSTextStorageWillProcessEditingNotification
		object: [_textView textStorage]];
	
	// 絶対位置のキャッシュ
	_cacheIndex = 0;
	_cacheAbsoluteLocation = 0;
	
	// 更新用絶対位置のキャッシュ
	_updateCacheIndex = 0;
	_updateCacheAbsoluteLocation = 0;
    
    // result leaf array
    int index, count = [self count];
    _childArray = [[NSMutableArray alloc] initWithCapacity:count];
    for (index = 0; index < count; index++) {
        OgreTextViewMatchFindResult *child = [[[OgreTextViewMatchFindResult alloc] init] autorelease];
        [child setIndex:index];
        [child setParentNoRetain:self];
        [_childArray addObject:child];
    }
}

#ifdef MAC_OS_X_VERSION_10_6
- (void)finalize
{
	[[NSNotificationCenter defaultCenter] removeObserver:self];
    [super finalize];
}
#endif

- (void)dealloc
{
	[[NSNotificationCenter defaultCenter] removeObserver:self];
	
    [_childArray release];
    [_textView release];
	[_lineOfMatchedStrings release];
	[_matchRangeArray release];
    [super dealloc];
}

/* addMatch */
- (void)addMatch:(OGRegularExpressionMatch*)match
{
	NSRange			range = [match rangeOfMatchedString];
	unsigned		newAbsoluteLocation = range.location;
	
	_count++;
	
	// マッチの相対位置
	// 0番目の部分文字列は前のマッチとの相対位置
	// 1番目以降の部分文字列は0番目の部分文字列との相対位置
	int				i, n = [match count];
	NSMutableArray	*rangeArray = [NSMutableArray arrayWithCapacity:n];
	range = [match rangeOfSubstringAtIndex:0];
	[rangeArray addObject:[NSValue valueWithRange:NSMakeRange(range.location - _cacheAbsoluteLocation, range.length)]];
	for (i = 1; i < n; i++) {
		range = [match rangeOfSubstringAtIndex:i];
		[rangeArray addObject:[NSValue valueWithRange:NSMakeRange(range.location - newAbsoluteLocation, range.length)]];
	}
	_cacheAbsoluteLocation = newAbsoluteLocation;
	
	// マッチした文字列が何行目にあるのか探す
	while (newAbsoluteLocation >= _searchLineRangeLocation) {
		_lineRange = [_text lineRangeForRange:NSMakeRange(_searchLineRangeLocation, 0)];
		_searchLineRangeLocation = _lineRange.location + _lineRange.length;
		_line++;
		if (_searchLineRangeLocation == _textLength) {
			if (_textLength == 0) _line--;
			break;
		}
	}
	
	// マッチした文字列の先頭が_line行目にある場合
	[_lineOfMatchedStrings addObject:[NSNumber numberWithUnsignedInt:_line]];
	[_matchRangeArray addObject:rangeArray];
}

- (NSNumber*)lineOfMatchedStringAtIndex:(unsigned)index
{
    //NSLog(@"lineOfMatchedStringAtIndex:%d", index);
	return [_lineOfMatchedStrings objectAtIndex:(index + 1)];   // 0番目はダミー
}

- (NSAttributedString*)matchedStringAtIndex:(unsigned)index
{
    //NSLog(@"matchedStringAtIndex:%d", index);
	if (_textView == nil) return [[self textFindResult] missingString];
	
	NSArray         *matchArray = [_matchRangeArray objectAtIndex:(index + 1)];   // 0番目はダミー
    NSMutableArray  *rangeArray;
	int             i, n = [matchArray count];
	NSString        *text = [_textView string];
    NSRange         range, matchRange;
    int             matchLocation = 0;
    
	// キャッシュを更新
	if (index > _cacheIndex) {
		while (_cacheIndex != index) {
			_cacheIndex++;
			range = [[[_matchRangeArray objectAtIndex:_cacheIndex] objectAtIndex:0] rangeValue];
			_cacheAbsoluteLocation += range.location;
		}
	} else if (index < _cacheIndex) {
		while (_cacheIndex != index) {
			range = [[[_matchRangeArray objectAtIndex:_cacheIndex] objectAtIndex:0] rangeValue];
			_cacheAbsoluteLocation -= range.location;
			_cacheIndex--;
		}
	}
	
    rangeArray = [NSMutableArray arrayWithCapacity:n];

	for(i = 0; i < n; i++) {
		range = [[matchArray objectAtIndex:i] rangeValue];
		if (i == 0) {
			// 0番目の部分文字列は前のマッチとの相対位置
			matchLocation = range.location + _cacheAbsoluteLocation;
			matchRange = NSMakeRange(matchLocation, range.length);
		} else {
			// 1番目以降の部分文字列は0番目の部分文字列との相対位置
			matchRange = NSMakeRange(range.location + matchLocation, range.length);
		}
        [rangeArray addObject:[NSValue valueWithRange:matchRange]];
	}

	return [[self textFindResult] highlightedStringInRange:rangeArray ofString:text];
}

- (BOOL)showMatchedStringAtIndex:(unsigned)index
{
	if (_textView == nil) return NO;
	
	[[_textView window] makeKeyAndOrderFront:self];
	return [self selectMatchedStringAtIndex:index];
}

- (BOOL)selectMatchedStringAtIndex:(unsigned)index
{
	if (_textView == nil) return NO;
	
	NSRange	range, matchRange;
	// キャッシュを更新
	if (index > _cacheIndex) {
		while (_cacheIndex != index) {
			_cacheIndex++;
			range = [[[_matchRangeArray objectAtIndex:_cacheIndex] objectAtIndex:0] rangeValue];
			_cacheAbsoluteLocation += range.location;
		}
	} else if (index < _cacheIndex) {
		while (_cacheIndex != index) {
			range = [[[_matchRangeArray objectAtIndex:_cacheIndex] objectAtIndex:0] rangeValue];
			_cacheAbsoluteLocation -= range.location;
			_cacheIndex--;
		}
	}
	
	// index番目にマッチした文字列の先頭のある行の範囲・内容
	range = [[[_matchRangeArray objectAtIndex:(index + 1)] objectAtIndex:0] rangeValue];
	matchRange = NSMakeRange(range.location + _cacheAbsoluteLocation, range.length);
	if ([[_textView string] length] < (matchRange.location + matchRange.length)) return NO;
	
	[_textView setSelectedRange:matchRange];
	[_textView scrollRangeToVisible:matchRange];
	
	return YES;
}

- (unsigned)count
{
	return _count;
}

// [_textView window] will close
- (void)windowWillClose:(NSNotification*)aNotification
{
#ifdef DEBUG_OGRE_FIND_PANEL
	NSLog(@"-windowWillClose: of %@", [self className]);
#endif
	[[NSNotificationCenter defaultCenter] removeObserver:self];
    [_textView release];
	_textView = nil;
    [[self textFindResult] didUpdate];
}

- (NSString*)description
{
	return [[NSDictionary dictionaryWithObjects:[NSArray arrayWithObjects:
			_lineOfMatchedStrings, 
			_matchRangeArray, 
			[NSNumber numberWithUnsignedInt:_line], 
			[NSNumber numberWithUnsignedInt:_count], 
		nil] forKeys:[NSArray arrayWithObjects:
			@"Match Line", 
			@"Match Range", 
			@"Line", 
			@"Count", 
		nil]] description];
}

- (void)textStorageWillProcessEditing:(NSNotification*)aNotification
{
	NSTextStorage   *textStorage = [aNotification object];
	NSRange			editedRange = [textStorage editedRange];
	int				changeInLength = [textStorage changeInLength];
	
	if ([textStorage editedMask] & NSTextStorageEditedCharacters) {
		// 文字の変更の場合
		/*NSLog(@"w: (%d, %d) -> (%d, %d)", 
			editedRange.location, editedRange.length - changeInLength, 
			editedRange.location, editedRange.length);*/
		// 表示の更新
		[self updateOldRange:NSMakeRange(editedRange.location, editedRange.length - changeInLength) newRange:NSMakeRange(editedRange.location, editedRange.length)];
	}
}

// 表示を更新
- (void)updateOldRange:(NSRange)oldRange newRange:(NSRange)newRange
{
#ifdef DEBUG_OGRE_FIND_PANEL
	NSLog(@"-updateOldRange: of %@", [self className]);
#endif
	// Notation
	//  (a b) : changed range
	//  [c d] : range of matched string
	// Possible configurations of these ranges "(), []"
	//  0. [ ] ( )
	//  1. ( ) [ ]
	//  2. ( [ ) ]
	//  3. ( [ ] )
	//  4. [ ( ) ]
	//  5. [ ( ] )
	
	NSMutableArray *target;
	NSRange		range, updatedRange;
	unsigned	a, b, c, d, b2;
	unsigned	i, j, 
				count = [self count], 
				numberOfSubranges = [[_matchRangeArray objectAtIndex:1] count];
	
	a = oldRange.location;
	b = NSMaxRange(oldRange);
	b2 = NSMaxRange(newRange);
	
	// 更新用絶対位置キャッシュの更新 (影響を受けない("[ ] ( )"となる)最大のindexを求める。)
	range = [[[_matchRangeArray objectAtIndex:_updateCacheIndex] objectAtIndex:0] rangeValue];
	d = _updateCacheAbsoluteLocation + range.length;
	if (a < d) {
		// ( ... ] ... の場合。
		do {
			// 一つ左の[]に行く。
			range = [[[_matchRangeArray objectAtIndex:_updateCacheIndex] objectAtIndex:0] rangeValue];
			_updateCacheAbsoluteLocation -= range.location;
			_updateCacheIndex--;
			range = [[[_matchRangeArray objectAtIndex:_updateCacheIndex] objectAtIndex:0] rangeValue];
			d = _updateCacheAbsoluteLocation + range.length;
		} while (a < d);
	} else if (d < a) {
		// [ ] ( ) の場合
		do {
			if (_updateCacheIndex == count) {
				// これ以上右の[]がない場合
				range.location = 0;		// _updateCacheAbsoluteLocation -= range.location;の相殺項
				_updateCacheIndex++;	// _updateCacheIndex--;の相殺項
				break;
			}
			// 一つ右の[]に行く。
			_updateCacheIndex++;
			range = [[[_matchRangeArray objectAtIndex:_updateCacheIndex] objectAtIndex:0] rangeValue];
			_updateCacheAbsoluteLocation += range.location;
			d = _updateCacheAbsoluteLocation + range.length;
		} while (d < a);
		// 行き過ぎた分戻す。
		_updateCacheAbsoluteLocation -= range.location;
		_updateCacheIndex--;
	}
	
#ifdef DEBUG_OGRE_FIND_PANEL
	NSLog(@"the maximal index of undisturbed matched string: %d", _updateCacheIndex);
#endif
	
	// 表示用絶対位置キャッシュの更新
	if (_updateCacheIndex < _cacheIndex) {
		_cacheIndex = _updateCacheIndex;
		_cacheAbsoluteLocation = _updateCacheAbsoluteLocation;
	}
	
	c = _updateCacheAbsoluteLocation;   // _updateCacheIndex番目の絶対位置
	for (i = _updateCacheIndex + 1; i <= count; i++) {
		target = [_matchRangeArray objectAtIndex:i];
		range = [[target objectAtIndex:0] rangeValue];
		c += range.location;
		d = c + range.length;
		
		if (d <= a) {
			// 0. [ ] ( )
#ifdef DEBUG_OGRE_FIND_PANEL
			NSLog(@"0. [ ] ( )");
#endif
		} else if ((a <= b) && (b <= c) && (c <= d)) {
			// 1. ( ) [ ]
#ifdef DEBUG_OGRE_FIND_PANEL
			NSLog(@"1. ( ) [ ]");
#endif
			updatedRange = NSMakeRange(range.location + b2 - b, range.length);  // ( ) [ ]
			[target replaceObjectAtIndex:0 withObject:[NSValue valueWithRange:updatedRange]];
			break;
		} else if ((c < a) && (a <= b) && (b < d)) {
			// 4. [ ( ) ]
#ifdef DEBUG_OGRE_FIND_PANEL
			NSLog(@"4. [ ( ) ]");
#endif
			updatedRange = NSMakeRange(range.location, range.length + b2 - b);  // [ ( ) ]
			[target replaceObjectAtIndex:0 withObject:[NSValue valueWithRange:updatedRange]];
			[self updateSubranges:target 
				count:numberOfSubranges 
				oldRange:oldRange 
				newRange:NSMakeRange(a, b2 - a) 
				origin:c 
				leftAlign:NO];
		} else if ((a <= c) && (c <= d) && (d <= b)) {
			// 3. ( [ ] )
#ifdef DEBUG_OGRE_FIND_PANEL
			NSLog(@"3. ( [ ] )");
#endif
			updatedRange = NSMakeRange(range.location + b2 - c, 0);		// (   )[]
			[target replaceObjectAtIndex:0 withObject:[NSValue valueWithRange:updatedRange]];
			b2 = c;
			// 部分文字列の範囲を更新
			for (j = 1; j < numberOfSubranges; j++) {
				[target replaceObjectAtIndex:j withObject:[NSValue valueWithRange:NSMakeRange(0, 0)]];
			}
		} else if ((a <= c) && (c < b) && (b < d)) {
			// 2. ( [ ) ]
#ifdef DEBUG_OGRE_FIND_PANEL
			NSLog(@"2. ( [ ) ]");
#endif
			updatedRange = NSMakeRange(range.location + b2 - c, range.length - (b - c));	// (   )[ ]
			[target replaceObjectAtIndex:0 withObject:[NSValue valueWithRange:updatedRange]];
			b2 = c;
			[self updateSubranges:target 
				count:numberOfSubranges 
				oldRange:oldRange 
				newRange:NSMakeRange(a, b2 - a) 
				origin:c 
				leftAlign:NO];
		} else if ((c < a) && (a < d) && (d <= b)) {
			// 5. [ ( ] )
#ifdef DEBUG_OGRE_FIND_PANEL
			NSLog(@"5. [ ( ] )");
#endif
			updatedRange = NSMakeRange(range.location, range.length - (d - a));		// [ ](   )
			[target replaceObjectAtIndex:0 withObject:[NSValue valueWithRange:updatedRange]];
			[self updateSubranges:target 
				count:numberOfSubranges 
				oldRange:oldRange 
				newRange:NSMakeRange(a, b2 - a) 
				origin:c 
				leftAlign:YES];
		} else {
			// その他
#ifdef DEBUG_OGRE_FIND_PANEL
			NSLog(@"others");
#endif
		}
	}
	
    [[self textFindResult] didUpdate];
}

- (void)updateSubranges:(NSMutableArray*)target count:(unsigned)numberOfSubranges oldRange:(NSRange)oldRange newRange:(NSRange)newRange origin:(unsigned)origin leftAlign:(BOOL)leftAlign
{
#ifdef DEBUG_OGRE_FIND_PANEL
	NSLog(@"-updateSubranges: of %@", [self className]);
#endif
	unsigned	i, a, b, b2, c, d;
	NSRange		range, updatedRange;
	a = oldRange.location;
	b = NSMaxRange(oldRange);
	b2 = NSMaxRange(newRange);
	
	for (i = 1; i < numberOfSubranges; i++) {
		range = [[target objectAtIndex:i] rangeValue];
		c = origin + range.location;
		d = c + range.length;
		
		if (d <= a) {
			// 0. [ ] ( )
#ifdef DEBUG_OGRE_FIND_PANEL
			NSLog(@"0. [ ] ( )");
#endif
		} else if ((a <= b) && (b <= c) && (c <= d)) {
			// 1. ( ) [ ]
#ifdef DEBUG_OGRE_FIND_PANEL
			NSLog(@"1. ( ) [ ]");
#endif
			updatedRange = NSMakeRange(range.location + b2 - b, range.length);
			[target replaceObjectAtIndex:i withObject:[NSValue valueWithRange:updatedRange]];
		} else if ((c < a) && (a <= b) && (b < d)) {
			// 4. [ ( ) ]
#ifdef DEBUG_OGRE_FIND_PANEL
			NSLog(@"4. [ ( ) ]");
#endif
			updatedRange = NSMakeRange(range.location, range.length + b2 - b);
			[target replaceObjectAtIndex:i withObject:[NSValue valueWithRange:updatedRange]];
		} else if ((a <= c) && (c <= d) && (d <= b)) {
			// 3. ( [ ] )
#ifdef DEBUG_OGRE_FIND_PANEL
			NSLog(@"3. ( [ ] )");
#endif
			if (leftAlign) {
				updatedRange = NSMakeRange(range.location - (c - a), 0);	// []( )
			} else {
				updatedRange = NSMakeRange(range.location + b2 - c, 0);		// ( )[]
			}
			[target replaceObjectAtIndex:i withObject:[NSValue valueWithRange:updatedRange]];
		} else if ((a <= c) && (c < b) && (b < d)) {
			// 2. ( [ ) ]
#ifdef DEBUG_OGRE_FIND_PANEL
			NSLog(@"2. ( [ ) ]");
#endif
			updatedRange = NSMakeRange(range.location + b2 - c, range.length - (b - c));
			[target replaceObjectAtIndex:i withObject:[NSValue valueWithRange:updatedRange]];
		} else if ((c < a) && (a < d) && (d <= b)) {
			// 5. [ ( ] )
#ifdef DEBUG_OGRE_FIND_PANEL
			NSLog(@"5. [ ( ] )");
#endif
			updatedRange = NSMakeRange(range.location, range.length - (d - a));
			[target replaceObjectAtIndex:i withObject:[NSValue valueWithRange:updatedRange]];
		} else {
			// その他
#ifdef DEBUG_OGRE_FIND_PANEL
			NSLog(@"others");
#endif
		}
	}
}

/* override methods of the OgreFindResultBranch */
- (id)name
{
    if (_textView == nil) return [[self textFindResult] missingString];
    return [_textView className]; 
}

- (id)outline
{ 
    if (_textView == nil) return [[self textFindResult] missingString];
    return [[self textFindResult] messageOfStringsFound:[self numberOfChildrenInSelection:NO]]; 
}


- (unsigned)numberOfChildrenInSelection:(BOOL)inSelection
{ 
    return [self count]; 
}

- (id)childAtIndex:(unsigned)index inSelection:(BOOL)inSelection 
{
    if (!inSelection) return [_childArray objectAtIndex:index];
    
    return [_childArray objectAtIndex:index];
}

- (BOOL)showMatchedString
{
    if (_textView == nil) return NO;
    
	[[_textView window] makeKeyAndOrderFront:self];
    return YES;
}

- (BOOL)selectMatchedString
{
    return (_textView != nil);
}

@end
