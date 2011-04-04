/*
 * Name: OgreReplaceAllThread.h
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

#import <OgreKit/OgreTextFindThread.h>

@class OGRegularExpressionMatch, OGRegularExpressionEnumerator;
@class OgreTextFindThread, OgreFindResult;

@interface OgreReplaceAllThread : OgreTextFindThread 
{
    NSArray					*matchArray;
    OGReplaceExpression		*repex;
    unsigned				aNumberOfReplaces, aNumberOfMatches;
    NSString				*progressMessage, *progressMessagePlural, *remainingTimeMesssage;
	NSObject<OGStringProtocol>				*replacedString;
}

@end
