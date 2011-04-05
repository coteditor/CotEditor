/*
 * Name: OgreTextFindThread.m
 * Project: OgreKit
 *
 * Creation Date: Sep 26 2003
 * Author: Isao Sonobe <sonoisa (AT) muse (DOT) ocn (DOT) ne (DOT) jp>
 * Copyright: Copyright (c) 2003 Isao Sonobe, All rights reserved.
 * License: OgreKit License
 *
 * Encoding: UTF8
 * Tabsize: 4
 */

#import <OgreKit/OgreTextFindThread.h>
#import <OgreKit/OgreTextFindRoot.h>

#import<OgreKit/OgreTextFindComponentEnumerator.h>

@implementation OgreTextFindThread

/* Creating and initializing */
- (id)initWithComponent:(NSObject <OgreTextFindComponent>*)aComponent;
{
#ifdef DEBUG_OGRE_FIND_PANEL
	NSLog(@"-initWithComponent: of %@", [self className]);
#endif
	self = [super init];
	if (self != nil) {
		_targetAdapter = [aComponent retain];
		_enumeratorStack = [[NSMutableArray alloc] initWithCapacity:10];
		_branchStack = [[NSMutableArray alloc] initWithCapacity:10];
		_terminated = NO;
		_exceptionRaised = NO;
		_processTime = 0;
		_asynchronous = NO;
		_shouldFinish = NO;
		_rootAdapter = [[OgreTextFindRoot alloc] initWithComponent:_targetAdapter];
		[_targetAdapter setParent:_rootAdapter];
		[_targetAdapter setIndex:0];
	}
	
	return self;
}

#ifdef MAC_OS_X_VERSION_10_6
- (void)finalize
{
#ifdef DEBUG_OGRE_FIND_PANEL
	NSLog(@"-finalize of %@", [self className]);
#endif
	[self finalizeFindingAll];
    [super finalize];
}
#endif

- (void)dealloc
{
#ifdef DEBUG_OGRE_FIND_PANEL
	NSLog(@"-dealloc of %@", [self className]);
#endif
	[self finalizeFindingAll];
	
	[_targetAdapter release];
	[_rootAdapter release];
	[_metronome release];
	[_processTime release];
	[_textFindResult release];
	[_didEndTarget release];
	[_highlightColor release];
	[_repex release];
	[_regex release];
	[super dealloc];
}

- (void)finalizeFindingAll
{
	if (_leafProcessing != nil) {
		[_leafProcessing finalizeFinding];
		[_leafProcessing release];
		_leafProcessing = nil;
	} else {
		[(OgreTextFindBranch*)[_branchStack lastObject] finalizeFinding];
	}
	
	while ([self popBranch] != nil);
	[_branchStack release];
	_branchStack = nil;
	
	while ([self popEnumerator] != nil);
	[_enumeratorStack release];
	_enumeratorStack = nil;
}

/* Running and stopping */
/* Template Methods */
- (void)detach
{
	_processTime = [[NSDate alloc] init];
	_metronome = [[NSDate alloc] init];
	
	_textFindResult = [[OgreTextFindResult alloc] initWithTarget:[_targetAdapter target] thread:self];
	
	NS_DURING
	
		_numberOfTotalLeaves = [_rootAdapter numberOfDescendantsInSelection:_inSelection];  // <= 0: indeterminate
		_numberOfDoneLeaves = 0;
		
		[self willProcessFindingAll];
		if (!_shouldFinish) [self visitBranch:_rootAdapter];
		
	NS_HANDLER
		
		_exceptionRaised =YES;
		[self exceptionRaised:localException];
		
		[self didProcessFindingAll];
		[self finishingUp:nil];
		
	NS_ENDHANDLER
}

- (void)willProcessFindingAll
{
#ifdef DEBUG_OGRE_FIND_PANEL
	NSLog(@"-willProcessFindingAll of %@", [self className]);
#endif
	/* do nothing */ 
}

- (void)didProcessFindingAll 
{
#ifdef DEBUG_OGRE_FIND_PANEL
	NSLog(@"-didProcessFindingAll of %@", [self className]);
#endif
	/* do nothing */ 
}

/* visitor pattern */
- (void)visitLeaf:(OgreTextFindLeaf*)aLeaf
// aLeaf == nil: resume from a break
{
#ifdef DEBUG_OGRE_FIND_PANEL
	NSLog(@"-visitLeaf: of %@", [self className]);
#endif
	NSAutoreleasePool   *pool = [[NSAutoreleasePool alloc] init];
	
	if (aLeaf != nil) {
		/* begin */
		_numberOfDoneLeaves++;
		_leafProcessing = [aLeaf retain];
		[_leafProcessing willProcessFinding:self];
		[self willProcessFindingInLeaf:_leafProcessing];
	}
#ifdef DEBUG_OGRE_FIND_PANEL
	else {
		NSLog(@"RESUME of %@", [self className]);
	}
#endif
	
	NS_DURING
	
		BOOL	shouldContinue;
		while (!_shouldFinish) {
			shouldContinue = [self shouldContinueFindingInLeaf:_leafProcessing];
			if (_numberOfMatches % 40 == 0) {
				[pool release];
				pool = [[NSAutoreleasePool alloc] init];
			}
			if (_asynchronous && (-[_metronome timeIntervalSinceNow] >= 1.0)) {
				/* coffee break */
				if (shouldContinue) {
					[_progressDelegate setProgress:[self progressPercentage] message:[self progressMessage]];
					[_progressDelegate setDonePerTotalMessage:[NSString stringWithFormat:@"%d/%@", _numberOfDoneLeaves, (_numberOfTotalLeaves <= 0? @"???" : [NSString stringWithFormat:@"%d", _numberOfTotalLeaves])]];
				}
				[_metronome release];
				_metronome = [[NSDate alloc] init];
				
	#ifdef DEBUG_OGRE_FIND_PANEL
				NSLog(@"BREAK of %@", [self className]);
	#endif
				[self performSelector:@selector(visitLeaf:) withObject:nil afterDelay:0];
				[pool release];
				NS_VOIDRETURN;
			}
			if (!shouldContinue) break;
		}
		
		/* end */
		[_leafProcessing didProcessFinding:self];
		[self didProcessFindingInLeaf:_leafProcessing];
		[_leafProcessing release];
		_leafProcessing = nil;
		
		[pool release];
		
		if (aLeaf == nil) [self visitBranch:nil];
		
	NS_HANDLER
		
		_exceptionRaised =YES;
		[self exceptionRaised:localException];
		
		[_leafProcessing didProcessFinding:self];
		[self didProcessFindingInLeaf:_leafProcessing];
		
		[pool release];
		
		[self didProcessFindingAll];
		[self finishingUp:nil];
		
	NS_ENDHANDLER
}

- (void)visitBranch:(OgreTextFindBranch*)aBranch
// aBranch == nil: resume from a break
{
#ifdef DEBUG_OGRE_FIND_PANEL
	NSLog(@"-visitBranch: of %@", [self className]);
#endif
	if (aBranch != nil) {
		/* begin */
		_enumeratorProcessing = [aBranch componentEnumeratorInSelection:[self inSelection]];
		[self pushEnumerator:_enumeratorProcessing];
		[self pushBranch:aBranch];
		
		[aBranch willProcessFinding:self];
		[self willProcessFindingInBranch:aBranch];
	}
	
	NSObject <OgreTextFindComponent>	*component;
	while (!_shouldFinish) {
		component = [_enumeratorProcessing nextObject];
		if (component == nil) break;
		
		[component acceptVisitor:self];
		if (_leafProcessing != nil) break;  // BREAK
	}
	
	if (_leafProcessing == nil && !_exceptionRaised) {
		/* end */
		id  processingBranch = [self topBranch];
		[processingBranch didProcessFinding:self];
		[self didProcessFindingInBranch:processingBranch];
		[self popBranch];
		
		[self popEnumerator];
		_enumeratorProcessing = [self topEnumerator];
		if (_enumeratorProcessing != nil) {
			/* continue */
			if (aBranch == nil) [self visitBranch:nil];
		} else {
			/* finish up */
			[_progressDelegate done:[self donePercentage] message:[self doneMessage]];
			[_progressDelegate setDonePerTotalMessage:[NSString stringWithFormat:@"%d/%@", _numberOfDoneLeaves, (_numberOfTotalLeaves == -1? @"???" : [NSString stringWithFormat:@"%d", _numberOfTotalLeaves])]];
			
			[self didProcessFindingAll];
			
			if (_shouldFinish) {
				if (_asynchronous) {
					[self performSelector:@selector(finishingUp:) withObject:nil afterDelay:0];
				} else {
					[self finishingUp:nil];
				}
			}
		}
	}
}

- (void)finishingUp:(id)sender
{
#ifdef DEBUG_OGRE_FIND_PANEL
	NSLog(@"-finishingUp: of %@", [self className]);
#endif
	[_metronome release];
	_metronome = nil;
	
#ifdef DEBUG_OGRE_FIND_PANEL
	NSLog(@"processTime: %lf", -[_processTime timeIntervalSinceNow]);
#endif
	
	[_processTime release];
	_processTime = nil;
	
	[_textFindResult setNumberOfMatches:_numberOfMatches];
	[_didEndTarget performSelector:_didEndSelector withObject:self];
}

- (void)exceptionRaised:(NSException*)exception
{
	[_textFindResult setType:OgreTextFindResultError];
	[_textFindResult setAlertSheet:_progressDelegate exception:exception];
	_shouldFinish = YES;
}

- (void)terminate
{
	[self terminate:self];
}

- (void)terminate:(id)sender
{
#ifdef DEBUG_OGRE_FIND_PANEL
	NSLog(@"-terminate: of %@", [self className]);
#endif
	_terminated = YES;
	_shouldFinish = YES;
}

- (void)finish
{
#ifdef DEBUG_OGRE_FIND_PANEL
	NSLog(@"-terminate: of %@", [self className]);
#endif
	_shouldFinish = YES;
}



/* result */
- (OgreTextFindResult*)result
{
	return _textFindResult;
}


/* Configuration */
- (void)setRegularExpression:(OGRegularExpression*)regex
{
	[_regex autorelease];
	_regex = [regex retain];
}

- (void)setReplaceExpression:(OGReplaceExpression*)repex
{
	[_repex autorelease];
	_repex = [repex retain];
}

- (void)setHighlightColor:(NSColor*)highlightColor
{
	[_highlightColor autorelease];
	_highlightColor = [highlightColor retain];
}

- (void)setOptions:(unsigned)options
{
	_searchOptions = options;
}

- (void)setInSelection:(BOOL)inSelection
{
	_inSelection = inSelection;
}

- (void)setDidEndSelector:(SEL)aSelector toTarget:(id)aTarget
{
	_didEndSelector = aSelector;
	[_didEndTarget autorelease];
	_didEndTarget = [aTarget retain];
}

- (void)setProgressDelegate:(NSObject <OgreTextFindProgressDelegate>*)aDelegate
{
#ifdef DEBUG_OGRE_FIND_PANEL
	NSLog(@"-setProgressDelegate: of %@", [self className]);
#endif
	_progressDelegate = aDelegate;  // retain しない。むしろretainしてもらう。
	[_progressDelegate setCancelSelector:@selector(terminate:) 
		toTarget:self // will be retained
		withObject:nil];
}

- (NSObject <OgreTextFindProgressDelegate>*)progressDelegate
{
	return _progressDelegate;
}

/* Accessors */
- (OGRegularExpression*)regularExpression
{
	return _regex;
}

- (OGReplaceExpression*)replaceExpression
{
	return _repex;
}


- (NSColor*)highlightColor
{
	return _highlightColor;
}


- (unsigned)options
{
	return _searchOptions;
}


- (BOOL)inSelection
{
	return _inSelection;
}


- (BOOL)isTerminated
{
	return _terminated;
}

- (NSTimeInterval)processTime
{
	return -[_processTime timeIntervalSinceNow];
}

- (void)setAsynchronous:(BOOL)asynchronous
{
	_asynchronous = asynchronous;
}
/* Methods implemented by subclasses */
- (void)willProcessFindingInBranch:(OgreTextFindBranch*)aBranch;
{
#ifdef DEBUG_OGRE_FIND_PANEL
	NSLog(@"-willProcessFindingInBranch: of %@ (BUG?)", [self className]);
#endif
	/* do nothing */
}

- (void)willProcessFindingInLeaf:(OgreTextFindLeaf*)aLeaf;
{
#ifdef DEBUG_OGRE_FIND_PANEL
	NSLog(@"-willProcessFindingInLeaf: of %@ (BUG?)", [self className]);
#endif
	/* do nothing */
}

- (BOOL)shouldContinueFindingInLeaf:(OgreTextFindLeaf*)aLeaf
{
#ifdef DEBUG_OGRE_FIND_PANEL
	NSLog(@"-shouldContinueFindingInLeaf: of %@ (BUG?)", [self className]);
#endif
	return NO;  // stop
}

- (void)didProcessFindingInLeaf:(OgreTextFindLeaf*)aLeaf;
{
#ifdef DEBUG_OGRE_FIND_PANEL
	NSLog(@"-didProcessFindingInLeaf: of %@ (BUG?)", [self className]);
#endif
	/* do nothing */
}

- (void)didProcessFindingInBranch:(OgreTextFindBranch*)aBranch;
{
#ifdef DEBUG_OGRE_FIND_PANEL
	NSLog(@"-didProcessFindingInBranch: of %@ (BUG?)", [self className]);
#endif
	/* do nothing */
}


- (SEL)didEndSelectorForFindPanelController
{
	return @selector(didEndUnknownTextFindThread:);
}

- (NSString*)progressMessage
{
	return @"Illegal progress message";
}

- (NSString*)doneMessage
{
	return @"Illegal progress message";
}


/* Protected methods */
- (unsigned)numberOfMatches
{
	return _numberOfMatches;
}

- (void)incrementNumberOfMatches
{
	_numberOfMatches++;
}

- (double)progressPercentage
{
#ifdef DEBUG_OGRE_FIND_PANEL
	NSLog(@"-progressPercentage of %@ (BUG?)", [self className]);
#endif
	return 0;
}

- (double)donePercentage
{
#ifdef DEBUG_OGRE_FIND_PANEL
	NSLog(@"-donePercentage of %@ (BUG?)", [self className]);
#endif
	return 1;
}

- (void)pushEnumerator:(NSEnumerator*)anEnumerator
{
	_enumeratorProcessing = anEnumerator;
	[_enumeratorStack addObject:anEnumerator];
}

- (NSEnumerator*)topEnumerator
{
	return [_enumeratorStack lastObject];
}

- (NSEnumerator*)popEnumerator
{
	if ([_enumeratorStack count] == 0) return nil;
	
	NSEnumerator  *anObject = [[_enumeratorStack lastObject] retain];
	[_enumeratorStack removeLastObject];
	
	return [anObject autorelease];
}

- (OgreTextFindBranch*)rootAdapter
{
	return _rootAdapter;
}

- (NSObject <OgreTextFindComponent, OgreTextFindTargetAdapter>*)targetAdapter
{
	return _targetAdapter;
}

- (void)pushBranch:(OgreTextFindBranch*)aBranch
{
	[_branchStack addObject:aBranch];
}

- (OgreTextFindBranch*)topBranch
{
	return [_branchStack lastObject];
}

- (OgreTextFindBranch*)popBranch
{
	if ([_branchStack count] == 0) return nil;
	
	OgreTextFindBranch  *anObject = [[_branchStack lastObject] retain];
	[_branchStack removeLastObject];
	
	return [anObject autorelease];
}


- (void)_setLeafProcessing:(OgreTextFindLeaf*)aLeaf
{
	[_leafProcessing autorelease];
	_leafProcessing = [aLeaf retain];
}


- (void)addResultLeaf:(id)aResultLeaf
{
	if (aResultLeaf != nil) [_textFindResult addLeaf:aResultLeaf];
}

- (void)beginGraftingToBranch:(OgreTextFindBranch*)aBranch
{
	OgreFindResultBranch	*findResult = [aBranch findResultBranchWithThread:self];
	[_textFindResult beginGraftingToBranch:findResult];
}

- (void)endGrafting
{
	[_textFindResult endGrafting];
}

@end
