/*
 * Name: OGReplaceExpressionPrivate.h
 * Project: OgreKit
 *
 * Creation Date: Sep 23 2003
 * Author: Isao Sonobe <sonoisa (AT) muse (DOT) ocn (DOT) ne (DOT) jp>
 * Copyright: Copyright (c) 2003 Isao Sonobe, All rights reserved.
 * License: OgreKit License
 *
 * Encoding: UTF8
 * Tabsize: 4
 */

@class OGReplaceExpression;

@interface OGReplaceExpression (Private)

/*********************
 * private accessors *
 *********************/
- (void)_setCompiledReplaceString:(NSArray*)compiledReplaceString;
- (void)_setCompiledReplaceStringType:(NSArray*)compiledReplaceStringType;
- (void)_setNameArray:(NSArray*)nameArray;
- (void)_setOptions:(unsigned)options;

@end
