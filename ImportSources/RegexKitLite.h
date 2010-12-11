//
//  RegexKitLite.h
//  http://regexkit.sourceforge.net/
//  Licensed under the terms of the BSD License, as specified below.
//

/*
 Copyright (c) 2008, John Engelhart
 
 All rights reserved.
 
 Redistribution and use in source and binary forms, with or without
 modification, are permitted provided that the following conditions are met:
 
 * Redistributions of source code must retain the above copyright
 notice, this list of conditions and the following disclaimer.
 
 * Redistributions in binary form must reproduce the above copyright
 notice, this list of conditions and the following disclaimer in the
 documentation and/or other materials provided with the distribution.
 
 * Neither the name of the Zang Industries nor the names of its
 contributors may be used to endorse or promote products derived from
 this software without specific prior written permission.
 
 THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
 "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT
 LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR
 A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT
 OWNER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL,
 SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED
 TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR
 PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF
 LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING
 NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS
 SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
*/ 

#ifdef    __OBJC__
#import <Foundation/NSObjCRuntime.h>
#import <Foundation/NSRange.h>
#import <Foundation/NSString.h>
#endif // __OBJC__

#include <limits.h>
#include <stdint.h>
#include <sys/types.h>

#ifndef REGEXKITLITE_VERSION_DEFINED
#define REGEXKITLITE_VERSION_DEFINED

#define REGEXKITLITE_VERSION_MAJOR 2
#define REGEXKITLITE_VERSION_MINOR 2

#define REGEXKITLITE_VERSION_CSTRING   _RKL_VERSION_STRING(REGEXKITLITE_VERSION_MAJOR, REGEXKITLITE_VERSION_MINOR)
#define REGEXKITLITE_VERSION_NSSTRING  @REGEXKITLITE_VERSION_CSTRING

#define _RKL__STRINGIFY(b)       #b
#define _RKL_STRINGIFY(a)        _RKL__STRINGIFY(a)
#define _RKL_JOIN_VERSION(a,b)   _RKL_STRINGIFY(a##.##b)
#define _RKL_VERSION_STRING(a,b) _RKL_JOIN_VERSION(a,b)

#endif // REGEXKITLITE_VERSION_DEFINED

#ifdef __cplusplus
extern "C" {
#endif

// For Mac OS X < 10.5.
#ifndef NSINTEGER_DEFINED
#define NSINTEGER_DEFINED
#ifdef __LP64__ || NS_BUILD_32_LIKE_64
typedef long           NSInteger;
typedef unsigned long  NSUInteger;
#define NSIntegerMin   LONG_MIN
#define NSIntegerMax   LONG_MAX
#define NSUIntegerMax  ULONG_MAX
#else // 32-bit
typedef int            NSInteger;
typedef unsigned int   NSUInteger;
#define NSIntegerMin   INT_MIN
#define NSIntegerMax   INT_MAX
#define NSUIntegerMax  UINT_MAX
#endif // __LP64__ || NS_BUILD_32_LIKE_64
#endif // NSINTEGER_DEFINED

#ifndef RKLREGEXOPTIONS_DEFINED
#define RKLREGEXOPTIONS_DEFINED

// These must be idential to their ICU regex counterparts. See http://www.icu-project.org/userguide/regexp.html
enum {
  RKLNoOptions             = 0,
  RKLCaseless              = 2,
  RKLComments              = 4,
  RKLDotAll                = 32,
  RKLMultiline             = 8,
  RKLUnicodeWordBoundaries = 256
};
typedef uint32_t RKLRegexOptions;

#endif // RKLREGEXOPTIONS_DEFINED

#ifndef _REGEXKITLITE_H_
#define _REGEXKITLITE_H_

#ifdef __OBJC__

@class NSError;

// NSException exception name.
extern NSString * const RKLICURegexException;

// NSError error domains and user info keys.
extern NSString * const RKLICURegexErrorDomain;

extern NSString * const RKLICURegexErrorCodeErrorKey;
extern NSString * const RKLICURegexErrorNameErrorKey;
extern NSString * const RKLICURegexLineErrorKey;
extern NSString * const RKLICURegexOffsetErrorKey;
extern NSString * const RKLICURegexPreContextErrorKey;
extern NSString * const RKLICURegexPostContextErrorKey;
extern NSString * const RKLICURegexRegexErrorKey;
extern NSString * const RKLICURegexRegexOptionsErrorKey;

// If it looks like low memory notifications might be available, add code to register and respond to them.
// This is (should be) harmless if it turns out that this isn't the case, since the notification that we register for,
// UIApplicationDidReceiveMemoryWarningNotification, is dynamically looked up via dlsym().
#if (TARGET_OS_EMBEDDED || TARGET_OS_IPHONE) && (!defined(RKL_REGISTER_FOR_IPHONE_LOWMEM_NOTIFICATIONS) || (RKL_REGISTER_FOR_IPHONE_LOWMEM_NOTIFICATIONS != 0))
#define RKL_REGISTER_FOR_IPHONE_LOWMEM_NOTIFICATIONS 1
#endif

#ifdef RKL_PREPEND_TO_METHODS
// This requires a few levels of rewriting to get the desired results.
#define RKL_METHOD_PREPEND_2(c,d) c ## d
#define RKL_METHOD_PREPEND_1(a,b) RKL_METHOD_PREPEND_2(a,b)
#define RKL_METHOD_PREPEND(x) RKL_METHOD_PREPEND_1(RKL_PREPEND_TO_METHODS, x)
#else
#define RKL_METHOD_PREPEND(x) x
#endif

@interface NSString (RegexKitLiteAdditions)

+ (void)RKL_METHOD_PREPEND(clearStringCache);

+ (NSInteger)RKL_METHOD_PREPEND(captureCountForRegex):(NSString *)regex;
+ (NSInteger)RKL_METHOD_PREPEND(captureCountForRegex):(NSString *)regex options:(RKLRegexOptions)options error:(NSError **)error;

- (NSArray *)RKL_METHOD_PREPEND(componentsSeparatedByRegex):(NSString *)regex;
- (NSArray *)RKL_METHOD_PREPEND(componentsSeparatedByRegex):(NSString *)regex range:(NSRange)range;
- (NSArray *)RKL_METHOD_PREPEND(componentsSeparatedByRegex):(NSString *)regex options:(RKLRegexOptions)options range:(NSRange)range error:(NSError **)error;

- (BOOL)RKL_METHOD_PREPEND(isMatchedByRegex):(NSString *)regex;
- (BOOL)RKL_METHOD_PREPEND(isMatchedByRegex):(NSString *)regex inRange:(NSRange)range;
- (BOOL)RKL_METHOD_PREPEND(isMatchedByRegex):(NSString *)regex options:(RKLRegexOptions)options inRange:(NSRange)range error:(NSError **)error;

- (NSRange)RKL_METHOD_PREPEND(rangeOfRegex):(NSString *)regex;
- (NSRange)RKL_METHOD_PREPEND(rangeOfRegex):(NSString *)regex capture:(NSInteger)capture;
- (NSRange)RKL_METHOD_PREPEND(rangeOfRegex):(NSString *)regex inRange:(NSRange)range;
- (NSRange)RKL_METHOD_PREPEND(rangeOfRegex):(NSString *)regex options:(RKLRegexOptions)options inRange:(NSRange)range capture:(NSInteger)capture error:(NSError **)error;

- (NSString *)RKL_METHOD_PREPEND(stringByMatching):(NSString *)regex;
- (NSString *)RKL_METHOD_PREPEND(stringByMatching):(NSString *)regex capture:(NSInteger)capture;
- (NSString *)RKL_METHOD_PREPEND(stringByMatching):(NSString *)regex inRange:(NSRange)range;
- (NSString *)RKL_METHOD_PREPEND(stringByMatching):(NSString *)regex options:(RKLRegexOptions)options inRange:(NSRange)range capture:(NSInteger)capture error:(NSError **)error;

- (NSString *)RKL_METHOD_PREPEND(stringByReplacingOccurrencesOfRegex):(NSString *)regex withString:(NSString *)replacement;
- (NSString *)RKL_METHOD_PREPEND(stringByReplacingOccurrencesOfRegex):(NSString *)regex withString:(NSString *)replacement range:(NSRange)searchRange;
- (NSString *)RKL_METHOD_PREPEND(stringByReplacingOccurrencesOfRegex):(NSString *)regex withString:(NSString *)replacement options:(RKLRegexOptions)options range:(NSRange)searchRange error:(NSError **)error;

@end

@interface NSMutableString (RegexKitLiteAdditions)

- (NSUInteger)RKL_METHOD_PREPEND(replaceOccurrencesOfRegex):(NSString *)regex withString:(NSString *)replacement;
- (NSUInteger)RKL_METHOD_PREPEND(replaceOccurrencesOfRegex):(NSString *)regex withString:(NSString *)replacement range:(NSRange)searchRange;
- (NSUInteger)RKL_METHOD_PREPEND(replaceOccurrencesOfRegex):(NSString *)regex withString:(NSString *)replacement options:(RKLRegexOptions)options range:(NSRange)searchRange error:(NSError **)error;

@end

#endif // __OBJC__

#endif // _REGEXKITLITE_H_

#ifdef __cplusplus
}  // extern "C"
#endif
