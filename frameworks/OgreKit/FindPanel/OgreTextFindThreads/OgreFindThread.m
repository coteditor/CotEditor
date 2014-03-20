/*
 * Name: OgreFindThread.m
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

#import <OgreKit/OgreFindThread.h>
#import <OgreKit/OgreFindResultLeaf.h>
#import <OgreKit/OgreFindResultBranch.h>
#import <OgreKit/OgreFindResultBranch.h>
#import <OgreKit/OGString.h>


@implementation OgreFindThread

/* Methods implemented by subclasses of OgreTextFindThread */
- (SEL)didEndSelectorForFindPanelController
{
    return @selector(didEndFind:);
}


- (void)willProcessFindingAll
{
#ifdef DEBUG_OGRE_FIND_PANEL
	NSLog(@" -willProcessFindingAll of %@", [self className]);
#endif
    [[self targetAdapter] setReversed:[self backward]];
    if ([self fromTop]) [[self targetAdapter] moveHomePosition];
    
    _lhsPhase = NO;
    OgreTextFindLeaf    *firstLeaf;
    if ((firstLeaf = [(id  <OgreTextFindTargetAdapter>)[self targetAdapter] buildStackForSelectedLeafInThread:self]) != nil && [self _preprocessFindingInFirstLeaf:firstLeaf]) {
        [[self result] setType:OgreTextFindResultFailure];
        [firstLeaf willProcessFinding:self];
        [self willProcessFindingInLeaf:firstLeaf];
        [self visitLeaf:nil];   // visit selected leaf
    } else {
        [self finish];
    }
}

- (BOOL)shouldPreprocessFindingInFirstLeaf
{
    return NO;
}

- (BOOL)_preprocessFindingInFirstLeaf:(OgreTextFindLeaf*)aLeaf
{
    if (![self shouldPreprocessFindingInFirstLeaf]) return YES; // continue
    
    [aLeaf willProcessFinding:self];
    
    BOOL    shouldContinue = [self preprocessFindingInFirstLeaf:aLeaf];
    
    [aLeaf didProcessFinding:self];
    
    return shouldContinue;
}

- (BOOL)preprocessFindingInFirstLeaf:(OgreTextFindLeaf*)aLeaf
{
#ifdef DEBUG_OGRE_FIND_PANEL
	NSLog(@" -preprocessFindingInFirstLeaf: of %@", [self className]);
#endif
    return YES; // continue
}

- (void)willProcessFindingInBranch:(OgreTextFindBranch*)aBranch;
{
#ifdef DEBUG_OGRE_FIND_PANEL
	NSLog(@" -willProcessFindingInBranch: of %@", [self className]);
#endif
}

- (void)willProcessFindingInLeaf:(OgreTextFindLeaf*)aLeaf;
{
#ifdef DEBUG_OGRE_FIND_PANEL
	NSLog(@" -willProcessFindingInLeaf: of %@", [self className]);
#endif
    NSObject<OGStringProtocol>    *string = [aLeaf ogString];
    
    if (string == nil) {
        matchEnumerator = nil;
        return;
    }
    
    NSRange     searchRange = [aLeaf selectedRange];
    unsigned    maxRange;
    
    if (([aLeaf isFirstLeaf] && ![aLeaf isReversed]) || ([aLeaf isTerminal] && [aLeaf isReversed])) {
        maxRange = NSMaxRange(searchRange);
        searchRange = NSMakeRange(maxRange, [string length] - maxRange);
    } else if (([aLeaf isFirstLeaf] && [aLeaf isReversed]) || ([aLeaf isTerminal] && ![aLeaf isReversed])) {
        searchRange = NSMakeRange(0, searchRange.location);
    }
    
    OGRegularExpression *regex = [self regularExpression];
    matchEnumerator = [[regex matchEnumeratorInOGString:string 
			options: [self options] 
			range: searchRange] retain];
}

- (BOOL)shouldContinueFindingInLeaf:(OgreTextFindLeaf*)aLeaf;
{
    // 最初のマッチ結果を得る。
    OGRegularExpressionMatch    *match;
    
    if ([self backward]) {
        match = [[matchEnumerator allObjects] lastObject];
    } else {
        match = [matchEnumerator nextObject];
    }
    if (match == nil) return NO;    // next leaf
    
    // マッチした場合
    [self incrementNumberOfMatches];
    NSRange matchRange = [match rangeOfMatchedString];
    [aLeaf setSelectedRange:matchRange];
    [aLeaf jumpToSelection];
    [[self result] setType:OgreTextFindResultSuccess];
    [self finish];
    
    return NO;
}

- (void)didProcessFindingInLeaf:(OgreTextFindLeaf*)aLeaf;
{
#ifdef DEBUG_OGRE_FIND_PANEL
	NSLog(@" -didProcessFindingInLeaf: of %@", [self className]);
#endif
    [matchEnumerator release];
}

- (void)didProcessFindingInBranch:(OgreTextFindBranch*)aBranch;
{
#ifdef DEBUG_OGRE_FIND_PANEL
	NSLog(@" -didProcessFindingInBranch: of %@", [self className]);
#endif
}

- (void)didProcessFindingAll
{
#ifdef DEBUG_OGRE_FIND_PANEL
	NSLog(@" -didProcessFindingAll of %@", [self className]);
#endif
    if ([self numberOfMatches] > 0) return; // found
    if (!_wrap || _lhsPhase) {
        [self finish];  // don't wrap
        return;
    }
    
    /* wrapped search */
    _lhsPhase = YES;
    [[self targetAdapter] setTerminal:YES];
}

- (BOOL)shouldContinueProcessFindingFirstLeaf:(OgreTextFindLeaf*)aLeaf
{
    return YES; // continue
}

- (void)setWrap:(BOOL)wrap
{
    _wrap = wrap;
}

- (BOOL)wrap
{
    return _wrap;
}

- (void)setBackward:(BOOL)backward
{
    _backward = backward;
}

- (BOOL)backward
{
    return _backward;
}

- (void)setFromTop:(BOOL)fromTop
{
    _fromTop = fromTop;
}

- (BOOL)fromTop
{
    return _fromTop;
}


@end
