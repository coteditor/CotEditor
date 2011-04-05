/*
 * Name: OgreKit.h
 * Project: OgreKit
 *
 * Creation Date: Sep 7 2003
 * Author: Isao Sonobe <sonoisa (AT) muse (DOT) ocn (DOT) ne (DOT) jp>
 * Copyright: Copyright (c) 2003 Isao Sonobe, All rights reserved.
 * License: OgreKit License
 *
 * Encoding: UTF8
 * Tabsize: 4
 */

#import <Foundation/Foundation.h>

#ifndef NOT_RUBY
#	define NOT_RUBY
#endif
#ifndef HAVE_CONFIG_H
#	define HAVE_CONFIG_H
#endif
#import <OgreKit/oniguruma.h>

// Regular Expressions
#import <OgreKit/OGRegularExpression.h>
#import <OgreKit/OGRegularExpressionEnumerator.h>
#import <OgreKit/OGRegularExpressionMatch.h>
#import <OgreKit/OGRegularExpressionCapture.h>
#import <OgreKit/OGRegularExpressionFormatter.h>
#import <OgreKit/OGReplaceExpression.h>
#import <OgreKit/NSString_OgreKitAdditions.h>
#import <OgreKit/OGString.h>
#import <OgreKit/OGMutableString.h>
