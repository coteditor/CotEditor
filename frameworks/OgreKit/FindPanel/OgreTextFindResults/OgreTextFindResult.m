/*
 * Name: OgreTextFindResult.m
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

#import <OgreKit/OgreTextFindResult.h>
#import <OgreKit/OgreTextFindProgressSheet.h>
#import <OgreKit/OgreTextFindThread.h>
#import <OgreKit/OgreTextFindThread.h>

@implementation OgreTextFindResult

+ (id)textFindResultWithTarget:(id)targetFindingIn thread:(OgreTextFindThread*)aThread
{
	return [[[[self class] alloc] initWithTarget:targetFindingIn thread:aThread] autorelease];
}

- (id)initWithTarget:(id)targetFindingIn thread:(OgreTextFindThread*)aThread
{
#ifdef DEBUG_OGRE_FIND_PANEL
	NSLog(@" -initWithTarget: of %@", [self className]);
#endif
	self = [super init];
	if (self != nil) {
		_target = targetFindingIn;
        _branchStack = [[NSMutableArray alloc] init];
		
		_maxLeftMargin = -1;			// 無制限
		_maxMatchedStringLength = -1;   // 無制限
        
        _numberOfMatches = 0;

        _regex = [[aThread regularExpression] retain];
	}
	return self;
}

#ifdef MAC_OS_X_VERSION_10_6
- (void)finalize
{
#ifdef DEBUG_OGRE_FIND_PANEL
	NSLog(@" -finalize of %@", [self className]);
#endif
    [super finalize];
}
#endif

- (void)dealloc
{
#ifdef DEBUG_OGRE_FIND_PANEL
	NSLog(@" -dealloc of %@", [self className]);
#endif
	[_title release];
    [_regex release];
    [_branchStack release];
    [_resultTree release];
	[_exception release];
	[_alertSheet release];
    [_highlightColorArray release];
	[super dealloc];
}

- (void)setType:(OgreTextFindResultType)resultType
{
    _resultType = resultType;
}

- (BOOL)isSuccess
{
	switch(_resultType) {
		case OgreTextFindResultSuccess:
			return YES;
		case OgreTextFindResultFailure:
		case OgreTextFindResultError:
		default:
			return NO;
	}
}

- (NSString*)findString
{
    return [_regex expressionString];
}

/* result Informaion (OgreFindResult instance, error reason)*/
- (void)setAlertSheet:(id /*<OgreTextFindProgressDelegate>*/)aSheet exception:(NSException*)anException
{
    [_alertSheet autorelease];
	_alertSheet = [aSheet retain];
    
    [_exception autorelease];
	_exception = [anException retain];
}

- (BOOL)alertIfErrorOccurred;
{
	if ((_resultType != OgreTextFindResultError) || (_exception == nil)) return NO;  // no error
	
	if (_alertSheet == nil) {
		// create an alert sheet
		_alertSheet = [[OgreTextFinder sharedTextFinder] alertSheetOnTarget:_target];
	}
	[(id <OgreTextFindProgressDelegate>)_alertSheet showErrorAlert:[_exception name] message:[_exception reason]];
	
	return YES;
}

- (void)beginGraftingToBranch:(OgreFindResultBranch*)aFindResultBranch
{
    [aFindResultBranch setTextFindResult:self];
    [aFindResultBranch setParentNoRetain:_branch];
    
    if (_branch != nil) {
        [_branch addComponent:aFindResultBranch];
        // push
        [_branchStack addObject:_branch];
        _branch = aFindResultBranch;
    } else {
        _resultTree = _branch = [aFindResultBranch retain];
    }
}

- (void)addLeaf:(id)aLeaf
{
    [aLeaf setTextFindResult:self];
    [aLeaf setParentNoRetain:_branch];
    
    [_branch addComponent:aLeaf];
}

- (void)endGrafting
{
    [_branch endAddition];
    if ([_branchStack count] > 0) {
        // pop
        _branch = [_branchStack lastObject];
        [_branchStack removeLastObject];
    }
}

- (NSObject <OgreTextFindComponent>*)result
{
    return _resultTree;
}


// -matchedStringAtIndex:にて、マッチした文字列の左側の最大文字数 (-1: 無制限)
- (int)maximumLeftMargin
{
    return _maxLeftMargin;
}

- (void)setMaximumLeftMargin:(int)leftMargin
{
	_maxLeftMargin = leftMargin;
}

// -matchedStringAtIndex:の返す最大文字数 (-1: 無制限)
- (int)maximumMatchedStringLength
{
    return _maxMatchedStringLength;
}

- (void)setMaximumMatchedStringLength:(int)aLength
{
	_maxMatchedStringLength = aLength;
}

- (void)setHighlightColor:(NSColor*)aColor regularExpression:(OGRegularExpression*)regex;
{
#ifdef MAC_OS_X_VERSION_10_6
    CGFloat hue, saturation, brightness, alpha;
#else
    float   hue, saturation, brightness, alpha;
#endif
    double  dummy;
    
    [[aColor colorUsingColorSpaceName:NSCalibratedRGBColorSpace] 
        getHue: &hue 
        saturation: &saturation 
        brightness: &brightness 
        alpha: &alpha];
        
    BOOL    isSimple = ([regex syntax] == OgreSimpleMatchingSyntax && ([regex options] & OgreDelimitByWhitespaceOption) != 0);
    
    unsigned    numberOfGroups = [_regex numberOfGroups], i;
    
    _highlightColorArray = [[NSMutableArray alloc] initWithCapacity:numberOfGroups];
    for (i = 0; i <= numberOfGroups; i++) {
        [_highlightColorArray addObject:[NSColor colorWithCalibratedHue: 
            modf(hue + (isSimple? (float)(i - 1) : (float)i) / (isSimple? (float)numberOfGroups : (float)(numberOfGroups + 1)), &dummy) 
            saturation: saturation 
            brightness: brightness 
            alpha: alpha]];
    }
}

// aString中のaRangeArrayの範囲を強調する。
- (NSAttributedString*)highlightedStringInRange:(NSArray*)aRangeArray ofString:(NSString*)aString
{
	int							i, n = [aRangeArray count], delta = 0;
	NSRange						lineRange, intersectionRange, matchRange;
	NSMutableAttributedString	*highlightedString;
    
	/* マッチした文字列の先頭のある行の範囲・内容 */
	matchRange = [[aRangeArray objectAtIndex:0] rangeValue];
	if ([aString length] < NSMaxRange(matchRange)) {
		// matchRangeの範囲の文字列が存在しない場合
		return [[[NSAttributedString alloc] initWithString:OgreTextFinderLocalizedString(@"Missing.") attributes:[NSDictionary dictionaryWithObject:[NSColor redColor] forKey:NSForegroundColorAttributeName]] autorelease];
	}
	lineRange = [aString lineRangeForRange:NSMakeRange(matchRange.location, 0)];
    
	highlightedString = [[[NSMutableAttributedString alloc] initWithString:@""] autorelease];
	if ((_maxLeftMargin >= 0) && (matchRange.location > lineRange.location + _maxLeftMargin)) {
		// MatchedStringの左側の文字数を制限する
		delta = matchRange.location - (lineRange.location + _maxLeftMargin);
		lineRange.location += delta;
		lineRange.length   -= delta;
		[highlightedString appendAttributedString:[[[NSAttributedString alloc] 
			initWithString:@"..." 
			attributes:[NSDictionary dictionaryWithObject:[NSColor grayColor] forKey:NSForegroundColorAttributeName]] autorelease]];
	}
	if ((_maxMatchedStringLength >= 0) && (lineRange.length > _maxMatchedStringLength)) {
		// 全文字数を制限する
		lineRange.length = _maxMatchedStringLength;
		[highlightedString appendAttributedString:[[[NSAttributedString alloc] 
			initWithString:[aString substringWithRange:lineRange]] autorelease]];
		[highlightedString appendAttributedString:[[[NSAttributedString alloc] 
			initWithString:@"..." 
			attributes:[NSDictionary dictionaryWithObject:[NSColor grayColor] forKey:NSForegroundColorAttributeName]] autorelease]];
	} else {
		[highlightedString appendAttributedString:[[[NSAttributedString alloc] 
			initWithString:[aString substringWithRange:lineRange]] autorelease]];
	}
	
	/* 彩色 */
	[highlightedString beginEditing];
	for(i = 0; i < n; i++) {
		matchRange = [[aRangeArray objectAtIndex:i] rangeValue];
		intersectionRange = NSIntersectionRange(lineRange, matchRange);
		
		if (intersectionRange.length > 0) {
			[highlightedString setAttributes:
				[NSDictionary dictionaryWithObject:[_highlightColorArray objectAtIndex:i] forKey:NSBackgroundColorAttributeName] 
				range:NSMakeRange(intersectionRange.location - lineRange.location + ((delta == 0)? 0 : 3), intersectionRange.length)];
		}
	}
	[highlightedString endEditing];

	return highlightedString;
}

- (NSAttributedString*)missingString
{
    return [[[NSAttributedString alloc] initWithString:OgreTextFinderLocalizedString(@"Missing.") attributes:[NSDictionary dictionaryWithObject:[NSColor redColor] forKey:NSForegroundColorAttributeName]] autorelease];
}


// delegate
- (void)setDelegate:(id)aDelegate
{
	_delegate = aDelegate;
}

- (id)delegate
{
    return _delegate;
}

- (void)didUpdate
{
    [(id <OgreTextFindResultDelegateProtocol>)_delegate didUpdateTextFindResult:self];
}

- (unsigned)numberOfMatches
{
    return _numberOfMatches;
}

- (void)setNumberOfMatches:(unsigned)aNumber
{
    _numberOfMatches = aNumber;
}

- (NSAttributedString*)messageOfStringsFound:(unsigned)numberOfMatches
{
    NSString        *message;
    if (numberOfMatches > 1) {
        message = OgreTextFinderLocalizedString(@"%d strings found.");
    } else {
        message = OgreTextFinderLocalizedString(@"%d string found.");
    }
    return [[[NSAttributedString alloc] initWithString:[NSString stringWithFormat:message, numberOfMatches] attributes:[NSDictionary dictionaryWithObject:[NSColor darkGrayColor] forKey:NSForegroundColorAttributeName]] autorelease];
}

- (NSAttributedString*)messageOfItemsFound:(unsigned)numberOfMatches
{
    NSString        *message;
    if (numberOfMatches > 1) {
        message = OgreTextFinderLocalizedString(@"Found in %d items.");
    } else {
        message = OgreTextFinderLocalizedString(@"Found in %d item.");
    }
    return [[[NSAttributedString alloc] initWithString:[NSString stringWithFormat:message, numberOfMatches] attributes:[NSDictionary dictionaryWithObject:[NSColor darkGrayColor] forKey:NSForegroundColorAttributeName]] autorelease];
}


- (void)outlineView:(NSOutlineView *)outlineView willDisplayCell:(id)cell forTableColumn:(NSTableColumn *)tableColumn item:(id)item
{
    if (tableColumn != [outlineView outlineTableColumn]) return;
    id  delegate;
    if ([item target] == nil) {
        [cell setImage:nil];
        if ([cell isKindOfClass:[NSBrowserCell class]]) [cell setLeaf:YES];
        return;
    }
    
    if ([_target isKindOfClass:[NSOutlineView class]]) {
        delegate = [_target delegate];
        if ([delegate respondsToSelector:@selector(outlineView:willDisplayCell:forTableColumn:item:)]) {
            [delegate outlineView:outlineView willDisplayCell:cell forTableColumn:tableColumn item:[(id <OgreTextFindComponent>)item target]];
        }
    }
}

- (NSCell*)nameCell
{
    NSCell  *nameCell;
    if ([_target isKindOfClass:[NSOutlineView class]]) {
        nameCell = [[[[(NSOutlineView*)_target outlineTableColumn] dataCell] copy] autorelease];
    } else {
        nameCell = [[[NSTextFieldCell alloc] init] autorelease];
        [nameCell setEditable:NO];
    }
    
    return nameCell;
}

- (float)rowHeight
{
    if ([_target isKindOfClass:[NSOutlineView class]]) {
        return [(NSOutlineView*)_target rowHeight];
    } else {
        return 16;
    }
}

- (NSString*)title
{
	if (_title == nil) {
		if ([_target respondsToSelector:@selector(window)]) {
			return [[_target window] title];
		} else {
			return @"Untitled Object";
		}
	}
	
	return _title;
}

- (void)setTitle:(NSString*)title
{
	[_title autorelease];
	_title = [title retain];
}

@end
