/*
 * Name: OgreHighlightThread.m
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

#import <OgreKit/OgreHighlightThread.h>
#import <OgreKit/OGString.h>


@implementation OgreHighlightThread

/* Methods implemented by subclasses of OgreTextFindThread */
- (SEL)didEndSelectorForFindPanelController
{
    return @selector(didEndHighlight:);
}


- (void)willProcessFindingAll
{
#ifdef DEBUG_OGRE_FIND_PANEL
	NSLog(@" -willProcessFindingAll of %@", [self className]);
#endif
    progressMessage = [OgreTextFinderLocalizedString(@"%d string highlighted.") retain];
    progressMessagePlural = [OgreTextFinderLocalizedString(@"%d strings highlighted.") retain];
    remainingTimeMesssage = [OgreTextFinderLocalizedString(@"(%dsec remaining)") retain];
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
    
    NSObject<OGStringProtocol>            *string = [aLeaf ogString];
    
    if (![aLeaf isHighlightable] || (string == nil)) {
        matchEnumerator = nil;  // stop
        return;
    }
    
    OGRegularExpression *regex = [self regularExpression];
    
    /* blending highlight colors */
#ifdef MAC_OS_X_VERSION_10_6
    CGFloat hue, saturation, brightness, alpha;
#else
    float   hue, saturation, brightness, alpha;
#endif
    [[[self highlightColor] colorUsingColorSpaceName:NSCalibratedRGBColorSpace] 
        getHue: &hue 
        saturation: &saturation 
        brightness: &brightness 
        alpha: &alpha];
    
    numberOfGroups = [regex numberOfGroups];
    unsigned    i;
    BOOL        simple = ([regex syntax] == OgreSimpleMatchingSyntax);
    double      dummy;
    
    highlightColorArray = [[NSMutableArray alloc] initWithCapacity:numberOfGroups];
    for (i = 0; i <= numberOfGroups; i++) {
        [highlightColorArray addObject:[NSColor colorWithCalibratedHue: 
            modf(hue + (simple? (float)(i - 1) : (float)i) / 
                (simple? (float)numberOfGroups : (float)(numberOfGroups + 1)), &dummy)
            saturation: saturation 
            brightness: brightness 
            alpha: alpha]];
    }
    
    /* search */
    NSRange     searchRange = [aLeaf selectedRange];
	if (![self inSelection]) {
		searchRange = NSMakeRange(0, [string length]);
	}
    searchLength = searchRange.length;
    
    matchEnumerator = [[regex matchEnumeratorInOGString:string 
			options: [self options] 
			range: searchRange] retain];
    
    [aLeaf unhighlight];
}

- (BOOL)shouldContinueFindingInLeaf:(OgreTextFindLeaf*)aLeaf;
{
    if ((match = [matchEnumerator nextObject]) == nil) return NO;   // stop
    
    [lastMatch release];
    lastMatch = [match retain];
    
    unsigned    i;
    NSRange     aRange;
    
    for(i = 0; i <= numberOfGroups; i++) {
        aRange = [match rangeOfSubstringAtIndex:i];
        if (aRange.length > 0) {
            [aLeaf highlightCharactersInRange:aRange color:[highlightColorArray objectAtIndex:i]];
        }
    }
    
    [self incrementNumberOfMatches];
    
    return YES; // continue
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
    [lastMatch release];
    
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
    finishedMessage             = OgreTextFinderLocalizedString(@"%d string highlighted. (%.3fsec)");
    finishedMessagePlural       = OgreTextFinderLocalizedString(@"%d strings highlighted. (%.3fsec)");
    cancelledMessage            = OgreTextFinderLocalizedString(@"%d string highlighted. (canceled, %.3fsec)");
    cancelledMessagePlural      = OgreTextFinderLocalizedString(@"%d strings highlighted. (canceled, %.3fsec)");
    
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
    if (_numberOfTotalLeaves <= 0) return -1;
    
    NSRange matchRange = [lastMatch rangeOfMatchedString];
    return (double)(_numberOfDoneLeaves - 1 + (double)(NSMaxRange(matchRange) + 1)/(double)(searchLength + 1)) / (double)_numberOfTotalLeaves;
}

- (double)donePercentage
{
    double  percentage;
    
    if ([self isTerminated]) {
        if (_numberOfMatches == 0) {
            percentage = 0;
        } else {
            if (_numberOfTotalLeaves > 0) {
                NSRange matchRange = [lastMatch rangeOfMatchedString];
                percentage = (double)(_numberOfDoneLeaves - 1 + (double)(NSMaxRange(matchRange) + 1)/(double)(searchLength + 1)) / (double)_numberOfTotalLeaves;
            } else {
                percentage = -1;    // indeterminate
            }
        }
    } else {
        if (_numberOfMatches == 0) {
            percentage = 0;
        } else {
            percentage = 1;
        }
    }
    
    return percentage;
}



@end
