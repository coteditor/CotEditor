/*
 * Name: OgreReplaceAllThread.m
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

#import <OgreKit/OgreReplaceAllThread.h>
#import <OgreKit/OGString.h>


@implementation OgreReplaceAllThread

/* Methods implemented by subclasses of OgreTextFindThread */
- (SEL)didEndSelectorForFindPanelController
{
    return @selector(didEndReplaceAll:);
}


- (void)willProcessFindingAll
{
#ifdef DEBUG_OGRE_FIND_PANEL
	NSLog(@" -willProcessFindingAll of %@", [self className]);
#endif
    progressMessage = [OgreTextFinderLocalizedString(@"%d string replaced.") retain];
    progressMessagePlural = [OgreTextFinderLocalizedString(@"%d strings replaced.") retain];
    remainingTimeMesssage = [OgreTextFinderLocalizedString(@"(%dsec remaining)") retain];
}

- (void)willProcessFindingInBranch:(OgreTextFindBranch*)aBranch;
{
#ifdef DEBUG_OGRE_FIND_PANEL
	NSLog(@" -willProcessFindingInBranch: of %@", [self className]);
#endif
    repex = [self replaceExpression];
}

- (void)willProcessFindingInLeaf:(OgreTextFindLeaf*)aLeaf;
{
#ifdef DEBUG_OGRE_FIND_PANEL
	NSLog(@" -willProcessFindingInLeaf: of %@", [self className]);
#endif
    NSObject<OGStringProtocol>    *string = [aLeaf ogString];
    
    if (![aLeaf isEditable] || (string == nil)) {
        aNumberOfMatches = 0;  // stop
        return;
    }
    
    unsigned    stringLength = [string length];
    
    NSRange     selectedRange = [aLeaf selectedRange];
	if (![self inSelection]) {
		selectedRange = NSMakeRange(0, stringLength);
	}
    
    matchArray = [[[self regularExpression] allMatchesInOGString:string 
			options: [self options] 
			range: selectedRange] retain];
    aNumberOfMatches = [matchArray count];
    aNumberOfReplaces = 0;
    
    if (aNumberOfMatches != 0) { 
        [aLeaf beginRegisteringUndoWithCapacity:aNumberOfMatches];
        [aLeaf beginEditing];
    }
}

- (BOOL)shouldContinueFindingInLeaf:(OgreTextFindLeaf*)aLeaf;
{
    if (aNumberOfReplaces >= aNumberOfMatches) return NO;   // stop
    
    aNumberOfReplaces++;
    [self incrementNumberOfMatches];
    
    OGRegularExpressionMatch        *match;
    NSRange                         matchRange;
    match = [matchArray objectAtIndex:(aNumberOfMatches - aNumberOfReplaces)];
    matchRange = [match rangeOfMatchedString];
    replacedString = [repex replaceMatchedOGStringOf:match];
    [aLeaf replaceCharactersInRange:matchRange withOGString:replacedString];
    
    return YES; // continue
}

- (void)didProcessFindingInLeaf:(OgreTextFindLeaf*)aLeaf;
{
#ifdef DEBUG_OGRE_FIND_PANEL
	NSLog(@" -didProcessFindingInLeaf: of %@", [self className]);
#endif
    if (aNumberOfMatches != 0) {
        [aLeaf endEditing];
        [aLeaf endRegisteringUndo];
        [matchArray release];
    }
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
    [remainingTimeMesssage release];
    [progressMessage release];
    [progressMessagePlural release];
    
    if ([self numberOfMatches] > 0) [[self result] setType:OgreTextFindResultSuccess];
    
    [self finish];
}



- (NSString*)progressMessage
{
    NSString    *message = [NSString stringWithFormat:(([self numberOfMatches] > 1)? progressMessagePlural : progressMessage), [self numberOfMatches]];
    
    if (_numberOfTotalLeaves > 0) {
        double  progressPercentage = [self progressPercentage] + 0.00000001;
        message = [message stringByAppendingFormat:remainingTimeMesssage, (int)ceil([self processTime] * (1.0 - progressPercentage)/progressPercentage)];
    }
    
    return message;
}

- (NSString*)doneMessage
{
	NSString	*finishedMessage, *finishedMessagePlural, 
				*cancelledMessage, *cancelledMessagePlural, 
				*notFoundMessage, *cancelledNotFoundMessage;
    
	notFoundMessage				= OgreTextFinderLocalizedString(@"Not found. (%.3fsec)");
	cancelledNotFoundMessage	= OgreTextFinderLocalizedString(@"Not found. (canceled, %.3fsec)");
    finishedMessage             = OgreTextFinderLocalizedString(@"%d string replaced. (%.3fsec)");
    finishedMessagePlural       = OgreTextFinderLocalizedString(@"%d strings replaced. (%.3fsec)");
    cancelledMessage            = OgreTextFinderLocalizedString(@"%d string replaced. (canceled, %.3fsec)");
    cancelledMessagePlural      = OgreTextFinderLocalizedString(@"%d strings replaced. (canceled, %.3fsec)");
    
    NSString    *message;
    unsigned    count = [self numberOfMatches];
	if ([self isTerminated]) {
		if (count == 0) {
			NSBeep();
			message = [NSString stringWithFormat:cancelledNotFoundMessage, 
				[self processTime] + 0.0005 /* 四捨五入 */];
		} else {
			message = [NSString stringWithFormat:((count > 1)? cancelledMessagePlural : cancelledMessage), 
				count, 
				[self processTime] + 0.0005 /* 四捨五入 */];
		}
	} else {
		if (count == 0) {
			NSBeep();
			message = [NSString stringWithFormat:notFoundMessage, 
				[self processTime] + 0.0005 /* 四捨五入 */];
		} else {
			message = [NSString stringWithFormat:((count > 1)? finishedMessagePlural : finishedMessage), 
				count, 
				[self processTime] + 0.0005 /* 四捨五入 */];
		}
	}
    
    return message;
}

- (double)progressPercentage
{
    if (_numberOfTotalLeaves <= 0 ) return -1;
    
    return (double)(_numberOfDoneLeaves - 1 + (double)aNumberOfReplaces/(double)aNumberOfMatches) / (double)_numberOfTotalLeaves;
}

- (double)donePercentage
{
    if ([self isTerminated]) {
        if (_numberOfTotalLeaves <= 0 ) return -1;
        
        return (double)(_numberOfDoneLeaves - 1 + (double)aNumberOfReplaces/(double)aNumberOfMatches) / (double)_numberOfTotalLeaves;
    }
    
    return 1;
    
    //return (double)aNumberOfReplaces/(double)aNumberOfMatches;
}

@end
