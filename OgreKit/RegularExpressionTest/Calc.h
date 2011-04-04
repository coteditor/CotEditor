/*
 * Name: Calc.h
 * Project: OgreKit
 *
 * Creation Date: Jun 26 2004
 * Author: Isao Sonobe <sonoisa (AT) muse (DOT) ocn (DOT) ne (DOT) jp>
 * Copyright: Copyright (c) 2003 Isao Sonobe, All rights reserved.
 * License: OgreKit License
 *
 * Encoding: UTF8
 * Tabsize: 4
 */

#import <Foundation/Foundation.h>
#import <OgreKit/OgreKit.h>


/* calculator with four operations '+', '-', '*', '/' and parentheses '(', ')' */
@interface Calc : NSObject <OGRegularExpressionCaptureVisitor>
{
    NSMutableArray  *_stack;
}

- (id)eval:(NSString*)expression;
- (void)push:(id)item;
- (id)pop;

@end
