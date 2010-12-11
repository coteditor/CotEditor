//
//  RegexKitLite.m
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

#import <CoreFoundation/CFBase.h>
#import <CoreFoundation/CFArray.h>
#import <CoreFoundation/CFString.h>
#import <Foundation/NSArray.h>
#import <Foundation/NSDictionary.h>
#import <Foundation/NSError.h>
#import <Foundation/NSException.h>
#ifdef __OBJC_GC__
#import <Foundation/NSGarbageCollector.h>
#endif
#import <libkern/OSAtomic.h>
#import <AvailabilityMacros.h>
#import <dlfcn.h>
#import <string.h>
#import <stdarg.h>
#import <stdlib.h>
#import "RegexKitLite.h"

// Compile time tuneables.

#ifndef RKL_CACHE_SIZE
#define RKL_CACHE_SIZE 23
#endif

#ifndef RKL_FIXED_LENGTH
#define RKL_FIXED_LENGTH 2048
#endif

#ifndef RKL_STACK_LIMIT
#define RKL_STACK_LIMIT (128 * 1024)
#endif

#define SCRATCH_BUFFERS 4

// These macros are nearly identical to their NSCParameterAssert siblings.
// This is required because nearly everything is done while cacheSpinLock is locked.
// We need to safely unlock before throwing any of these exceptions.
// @try {} @finally {} significantly slows things down so it's not used.
#define RKLCAssert(d, ...) RKLCAssertDictionary(__PRETTY_FUNCTION__, __FILE__, __LINE__, (d), ##__VA_ARGS__)
#ifdef NS_BLOCK_ASSERTIONS
#define _RKLCDelayedAssertBody(c, e, g, d, ...)
#else
#define _RKLCDelayedAssertBody(c, e, g, d, ...) do { id *_e=(e); if(*_e!=NULL) { goto g; } if(!(c)) { *_e = RKLCAssert((d), ##__VA_ARGS__); goto g; } } while(0)
#endif // NS_BLOCK_ASSERTIONS
#define RKLCDelayedAssert(c, e, g) _RKLCDelayedAssertBody(c, e, g, @"Invalid parameter not satisfying: %s", #c)

#define RKLRaiseException(e, f, ...) [[NSException exceptionWithName:(e) reason:RKLStringFromClassAndMethod((self), (_cmd), (f), ##__VA_ARGS__) userInfo:NULL] raise]

// Ugly macros to keep other parts clean.

#define NSMaxRange(r)               ((r).location + (r).length)
#define NSRangeInsideRange(in, win) (((((in).location - (win).location) <= (win).length) && ((NSMaxRange(in) - (win).location) <= (win).length)))
#define NSEqualRanges(r1, r2)       ((((r1).location == (r2).location) && ((r1).length == (r2).length)))
#define NSMakeRange(loc, len)       ((NSRange){(NSUInteger)(loc), (NSUInteger)(len)})
#define CFMakeRange(loc, len)       ((CFRange){(CFIndex)(loc), (CFIndex)(len)})
#define NSNotFoundRange             ((NSRange){NSNotFound, 0})
#define NSMaxiumRange               ((NSRange){0, NSUIntegerMax})

#if defined (__GNUC__) && (__GNUC__ >= 4)
#define RKL_PREFETCH(ptr, off)      { const char *p = ((const char *)(ptr)) + ((off) + 64); __builtin_prefetch(p); __builtin_prefetch(p + 64); }
#else
#define RKL_PREFETCH(ptr, off)
#endif

// If the gcc flag -mmacosx-version-min is used with, for example, '=10.2', give a warning that the libicucore.dylib is only available on >= 10.3.
// If you are reading this comment because of this warning, this is to let you know that linking to /usr/lib/libicucore.dylib will cause your executable to fail on < 10.3.
// You will need to build your own version of the ICU library and link to that in order for RegexKitLite to work successfully on < 10.3.  This is not simple.

#if MAC_OS_X_VERSION_MIN_REQUIRED < 1030
#warning The ICU dynamic shared library, /usr/lib/libicucore.dylib, is only available on Mac OS X 10.3 and later.
#warning You will need to supply a version of the ICU library to use RegexKitLite on Mac OS X 10.2 and earlier.
#endif

#define RKLGetRangeForCapture(re, s, c, r) ({ int32_t start = uregex_start((re), (int32_t)(c), (s)); if(start == -1) { r = NSNotFoundRange; } else { r.location = (NSUInteger)start; r.length = (NSUInteger)uregex_end((re), (int32_t)(c), (s)) - r.location; } *(s); })

// Exported symbols.  Exception names, error domains, keys, etc.
NSString * const RKLICURegexException            = @"RKLICURegexException";

NSString * const RKLICURegexErrorDomain          = @"RKLICURegexErrorDomain";

NSString * const RKLICURegexErrorCodeErrorKey    = @"RKLICURegexErrorCode";
NSString * const RKLICURegexErrorNameErrorKey    = @"RKLICURegexErrorName";
NSString * const RKLICURegexLineErrorKey         = @"RKLICURegexLine";
NSString * const RKLICURegexOffsetErrorKey       = @"RKLICURegexOffset";
NSString * const RKLICURegexPreContextErrorKey   = @"RKLICURegexPreContext";
NSString * const RKLICURegexPostContextErrorKey  = @"RKLICURegexPostContext";
NSString * const RKLICURegexRegexErrorKey        = @"RKLICURegexRegex";
NSString * const RKLICURegexRegexOptionsErrorKey = @"RKLICURegexRegexOptions";

// Type / struct definitions

typedef struct uregex uregex; // Opaque ICU regex type.

#define U_BUFFER_OVERFLOW_ERROR 15

#define U_PARSE_CONTEXT_LEN 16

typedef struct UParseError {
  int32_t line;
  int32_t offset;
  UniChar preContext[U_PARSE_CONTEXT_LEN];
  UniChar postContext[U_PARSE_CONTEXT_LEN];
} UParseError;

enum {
  RKLSplitOp        = 1,
  RKLReplaceOp      = 2,
  RKLRangeOp        = 3,
  RKLMaskOp         = 0xf,
  RKLReplaceMutable = 1 << 4,
};
typedef NSUInteger RKLRegexOp;

typedef struct {
  CFStringRef  string;
  CFHashCode   hash;
  CFIndex      length;
  UniChar     *uniChar;
} RKLBuffer;

typedef struct {
  CFStringRef      regexString;
  RKLRegexOptions  options;
  uregex          *icu_regex;
  NSInteger        captureCount;

  CFStringRef      setToString;
  CFHashCode       setToHash;
  CFIndex          setToLength;
  NSUInteger       setToIsImmutable:1;
  NSUInteger       setToNeedsConversion:1;
  const UniChar   *setToUniChar;
  NSRange          setToRange, lastFindRange, lastMatchRange;
  NSUInteger       pad[1]; // For 32 bits, this makes the struct 64 bytes exactly, which is good for cache line alignment.
} RKLCacheSlot;

// ICU functions.  See http://www.icu-project.org/apiref/icu4c/uregex_8h.html Tweaked slightly from the originals, but functionally identical.
const char *u_errorName              (int32_t status);
int32_t     u_strlen                 (const UniChar *s);
int32_t     uregex_appendReplacement (uregex *regexp, const UniChar *replacementText, int32_t replacementLength, UniChar **destBuf, int32_t *destCapacity, int32_t *status);
int32_t     uregex_appendTail        (uregex *regexp, UniChar **destBuf, int32_t *destCapacity, int32_t *status);
void        uregex_close             (uregex *regexp);
int32_t     uregex_end               (uregex *regexp, int32_t groupNum, int32_t *status);
BOOL        uregex_find              (uregex *regexp, int32_t location, int32_t *status);
BOOL        uregex_findNext          (uregex *regexp, int32_t *status);
int32_t     uregex_groupCount        (uregex *regexp, int32_t *status);
uregex     *uregex_open              (const UniChar *pattern, int32_t patternLength, RKLRegexOptions flags, UParseError *parseError, int32_t *status);
void        uregex_reset             (uregex *regexp, int32_t newIndex, int32_t *status);
void        uregex_setText           (uregex *regexp, const UniChar *text, int32_t textLength, int32_t *status);
int32_t     uregex_split             (uregex *regexp, UniChar *destBuf, int32_t destCapacity, int32_t *requiredCapacity, UniChar *destFields[], int32_t destFieldsCapacity, int32_t *status);
int32_t     uregex_start             (uregex *regexp, int32_t groupNum, int32_t *status);


static RKLCacheSlot *getCachedRegex             (NSString *regexString, RKLRegexOptions options, NSError **error, id *exception);
static BOOL          setCacheSlotToString       (RKLCacheSlot *cacheSlot, const NSRange *range, int32_t *status, id *exception);
static RKLCacheSlot *getCachedRegexSetToString  (NSString *regexString, RKLRegexOptions options, NSString *matchString, NSUInteger *matchLengthPtr, NSRange *matchRange, NSError **error, id *exception, int32_t *status);
static id           performRegexOp              (id self, SEL _cmd, RKLRegexOp doRegexOp, NSString *regexString, RKLRegexOptions options, NSInteger capture, id matchString, NSRange *matchRange, NSString *replacementString, NSError **error, void **result);

static void          rkl_find                   (RKLCacheSlot *cacheSlot, NSInteger capture, NSRange searchRange, NSRange *resultRange, id *exception, int32_t *status);
static NSArray      *rkl_splitArray             (RKLCacheSlot *cacheSlot, id *exception, int32_t *status);
static NSString     *rkl_replaceString          (RKLCacheSlot *cacheSlot, id searchString, NSUInteger searchU16Length, NSString *replacementString, NSUInteger replacementU16Length, NSUInteger *replacedCount, int replaceMutable, id *exception, int32_t *status);
static int32_t      rkl_replaceAll              (RKLCacheSlot *cacheSlot, const UniChar *replacementUniChar, int32_t replacementU16Length, UniChar *replacedUniChar, int32_t replacedU16Capacity, NSUInteger *replacedCount, id *exception, int32_t *status);

static void         clearBuffer                 (RKLBuffer *buffer, int freeDynamicBuffer);
static void         clearCacheSlotRegex         (RKLCacheSlot *cacheSlot);
static void         clearCacheSlotSetTo         (RKLCacheSlot *cacheSlot);

static NSDictionary *userInfoDictionary         (NSString *regexString, RKLRegexOptions options, const UParseError *parseError, int status, ...);
static NSError      *RKLNSErrorForRegex         (NSString *regexString, RKLRegexOptions options, const UParseError *parseError, int status);
static NSException  *RKLNSExceptionForRegex     (NSString *regexString, RKLRegexOptions options, const UParseError *parseError, int status);
static NSDictionary *RKLCAssertDictionary       (const char *function, const char *file, int line, NSString *format, ...);
static NSString     *RKLStringFromClassAndMethod(id object, SEL selector, NSString *format, ...);

#ifdef __OBJC_GC__
// If compiled with Garbage Collection, we need to be able to do a few things slightly differently.
// The basic premiss is that under GC we use a trampoline function pointer which is set to a _start function to catch the first invocation.
// The _start function checks if GC is running and then overwrites the function pointer with the appropriate routine.  Think of it as 'lazy linking'.

// rkl_collectingEnabled uses objc_getClass() to get the NSGarbageCollector class, which doesn't exist on earlier systems.
// This allows for graceful failure should we find ourselves running on an earlier version of the OS without NSGarbageCollector.
static BOOL  rkl_collectingEnabled_first (void);
static BOOL  rkl_collectingEnabled_yes   (void) { return(YES); }
static BOOL  rkl_collectingEnabled_no    (void) { return(NO); }
static BOOL(*rkl_collectingEnabled)      (void) = rkl_collectingEnabled_first;
static BOOL  rkl_collectingEnabled_first (void) { return((([objc_getClass("NSGarbageCollector") defaultCollector]!=NULL) ? (rkl_collectingEnabled=rkl_collectingEnabled_yes) : (rkl_collectingEnabled=rkl_collectingEnabled_no))()); }

static void   *rkl_realloc_first (void **ptr, size_t size, NSUInteger flags);
static void   *rkl_realloc_std   (void **ptr, size_t size, NSUInteger flags) { flags=flags; /*unused*/ return((*ptr = reallocf(*ptr, size))); }
static void   *rkl_realloc_gc    (void **ptr, size_t size, NSUInteger flags) { void *p=NULL; if(flags!=0) { p=NSAllocateCollectable((NSUInteger)size,flags); if(*ptr!=NULL) { free(*ptr); *ptr=NULL; } } else { p=*ptr=reallocf(*ptr, size); } return(p); }
static void *(*rkl_realloc)      (void **ptr, size_t size, NSUInteger flags) = rkl_realloc_first;
static void   *rkl_realloc_first (void **ptr, size_t size, NSUInteger flags) { return(((rkl_collectingEnabled()==YES) ? (rkl_realloc=rkl_realloc_gc) : (rkl_realloc=rkl_realloc_std))(ptr, size, flags)); }

static id  rkl_CFAutorelease_first (CFTypeRef obj);
static id  rkl_CFAutorelease_std   (CFTypeRef obj) { return([(id)obj autorelease]); }
static id  rkl_CFAutorelease_gc    (CFTypeRef obj) { return((id)CFMakeCollectable(obj)); }
static id(*rkl_CFAutorelease)      (CFTypeRef obj) = rkl_CFAutorelease_first;
static id  rkl_CFAutorelease_first (CFTypeRef obj) { return(((rkl_collectingEnabled()==YES) ? (rkl_CFAutorelease=rkl_CFAutorelease_gc) : (rkl_CFAutorelease=rkl_CFAutorelease_std))(obj)); }

#else  // __OBJC_GC__ not defined

static void *rkl_realloc       (void **ptr, size_t size, NSUInteger flags) { flags=flags; /*unused*/ return((*ptr = reallocf(*ptr, size))); }
static id    rkl_CFAutorelease (CFTypeRef obj)                             { return([(id)obj autorelease]); }

#endif // __OBJC_GC__

#ifdef RKL_FAST_MUTABLE_CHECK
// We use a trampoline function pointer to check at run time if the function __CFStringIsMutable is available.
// If it is, the trampoline function pointer is replaced with the address of that function.
// Otherwise, we assume the worst case that ever string is mutable.
// This hopefully helps to protect us since we're using an undocumented, non-public API call.
// We will keep on working if it ever does go away, just with a bit less performance due to the overhead of mutable checks.
static BOOL  rkl_CFStringIsMutable_first (CFStringRef str);
static BOOL  rkl_CFStringIsMutable_yes   (CFStringRef str) { str=str; /*unused*/ return(YES); }
static BOOL(*rkl_CFStringIsMutable)      (CFStringRef str) = rkl_CFStringIsMutable_first;
static BOOL  rkl_CFStringIsMutable_first (CFStringRef str) { if((rkl_CFStringIsMutable = dlsym(RTLD_DEFAULT, "__CFStringIsMutable")) == NULL) { rkl_CFStringIsMutable = rkl_CFStringIsMutable_yes; } return(rkl_CFStringIsMutable(str)); }
#else // RKL_FAST_MUTABLE_CHECK is not defined.  Assume that all strings are potentially mutable.
#define rkl_CFStringIsMutable(s) (YES)
#endif
BOOL __CFStringIsMutable(CFStringRef str);

// Translation unit scope global variables.

static UniChar        fixedUniChar[(RKL_FIXED_LENGTH)]; // This is the fixed sized UTF-16 conversion buffer.
static RKLCacheSlot   RKLCache[(RKL_CACHE_SIZE)], *lastCacheSlot;
static OSSpinLock     cacheSpinLock = OS_SPINLOCK_INIT;
static RKLBuffer      dynamicBuffer, fixedBuffer = {NULL, 0UL, 0L, &fixedUniChar[0]};
static const UniChar  emptyUniCharString[1];                          // For safety, icu_regexes are 'set' to this when the string they were searched is cleared.
static void          *scratchBuffer[(SCRATCH_BUFFERS)];               // Used to hold temporary allocations that are allocated via reallocf().

// These are used when running under manual memory management for the array that rkl_splitArray creates.
// The split strings are created, but not autoreleased.  The (immutable) array is created using these callbacks, which skips the CFRetain() call.
// For each split string this saves the overhead of an autorelease, then an array retain, then a autoreleasepool release. This is good for a ~30% speed increase.
static Boolean          RKLCFArrayEqualCallBack           (const void *value1,       const void *value2) { return(CFEqual(value1, value2));                          }
static void             RKLCFArrayRelease                 (CFAllocatorRef allocator, const void *ptr)    { allocator=allocator;/*unused*/ CFRelease(ptr);            }
static CFArrayCallBacks transferOwnershipArrayCallBacks =                                                { 0, NULL, RKLCFArrayRelease, NULL, RKLCFArrayEqualCallBack };

//  IMPORTANT!   This code is critical path code.  Because of this, it has been written for speed, not clarity.
//  IMPORTANT!   Should only be called with cacheSpinLock already locked!
//  ----------

static RKLCacheSlot *getCachedRegex(NSString *regexString, RKLRegexOptions options, NSError **error, id *exception) {
  CFHashCode    regexHash = 0;
  RKLCacheSlot *cacheSlot = NULL;

  RKLCDelayedAssert(regexString != NULL, exception, exitNow);

  // Fast path the common case where this regex is exactly the same one used last time.
  if((lastCacheSlot != NULL) && (lastCacheSlot->options == options) && (lastCacheSlot->icu_regex != NULL) && (lastCacheSlot->regexString != NULL) && (lastCacheSlot->regexString == (CFStringRef)regexString)) { return(lastCacheSlot); }

  regexHash = CFHash((CFTypeRef)regexString);
  cacheSlot = &RKLCache[(regexHash % RKL_CACHE_SIZE)]; // Retrieve the cache slot for this regex.

  // Return the cached entry if it's a match, otherwise clear the slot and create a new ICU regex in its place.
  if((cacheSlot->options == options) && (cacheSlot->icu_regex != NULL) && (cacheSlot->regexString != NULL) && ((cacheSlot->regexString == (CFStringRef)regexString) || (CFEqual((CFTypeRef)regexString, cacheSlot->regexString) == YES))) { lastCacheSlot = cacheSlot; return(cacheSlot); }

  clearCacheSlotRegex(cacheSlot);

  if((cacheSlot->regexString = CFStringCreateCopy(NULL, (CFStringRef)regexString)) == NULL) { goto exitNow; } ; // Get a cheap immutable copy.
  cacheSlot->options = options;

  CFIndex      regexStringU16Length = CFStringGetLength(cacheSlot->regexString); // In UTF16 code units.
  UParseError  parseError           = (UParseError){-1, -1, {0}, {0}};
  UniChar     *regexUniChar         = NULL;
  int32_t      status               = 0;

  // Try to quickly obtain regexString in UTF16 format.
  if((regexUniChar = (UniChar *)CFStringGetCharactersPtr(cacheSlot->regexString)) == NULL) { // We didn't get the UTF16 pointer quickly and need to perform a full conversion in a temp buffer.
    if((regexStringU16Length * sizeof(UniChar)) < RKL_STACK_LIMIT) { if((regexUniChar = alloca(regexStringU16Length * sizeof(UniChar))) == NULL) { goto exitNow; } } // Try to use the stack.
    else { if((regexUniChar = rkl_realloc(&scratchBuffer[0], regexStringU16Length * sizeof(UniChar), 0UL)) == NULL) { goto exitNow; } } // Otherwise use the heap.
    CFStringGetCharacters(cacheSlot->regexString, CFMakeRange(0, regexStringU16Length), (UniChar *)regexUniChar); // Convert regexString to UTF16.
  }

  // Create the ICU regex.
  if((cacheSlot->icu_regex = uregex_open(regexUniChar, (int32_t)regexStringU16Length, options, &parseError, &status)) == NULL) { goto exitNow; }
  if(status <= 0) { cacheSlot->captureCount = (NSInteger)uregex_groupCount(cacheSlot->icu_regex, &status); }
  if(status <= 0) { lastCacheSlot = cacheSlot; }

 exitNow:
  if(scratchBuffer[0] != NULL) { free(scratchBuffer[0]); scratchBuffer[0] = NULL; }
  if(status > 0) { cacheSlot = NULL; if(error != NULL) { *error = RKLNSErrorForRegex(regexString, options, &parseError, status); } }
  return(cacheSlot);
}

//  IMPORTANT!   This code is critical path code.  Because of this, it has been written for speed, not clarity.
//  IMPORTANT!   Should only be called with cacheSpinLock already locked!
//  ----------

static BOOL setCacheSlotToString(RKLCacheSlot *cacheSlot, const NSRange *range, int32_t *status, id *exception) {
  RKLCDelayedAssert((cacheSlot != NULL) && (cacheSlot->setToString != NULL) && (range != NULL) && (status != NULL), exception, exitNow);

  if(cacheSlot->setToNeedsConversion == NO) { goto setRegexText; }

  RKLBuffer *buffer = (cacheSlot->setToLength < RKL_FIXED_LENGTH) ? &fixedBuffer : &dynamicBuffer;
  if((cacheSlot->setToUniChar != NULL) && ((cacheSlot->setToString == buffer->string) || ((cacheSlot->setToLength == buffer->length) && (cacheSlot->setToHash == buffer->hash)))) { goto setRegexText; }

  clearBuffer(buffer, NO);

  if(cacheSlot->setToLength >= RKL_FIXED_LENGTH) {
    RKLCDelayedAssert(buffer == &dynamicBuffer, exception, exitNow);
    if((dynamicBuffer.uniChar = rkl_realloc((void *)&dynamicBuffer.uniChar, (cacheSlot->setToLength * sizeof(UniChar)), 0UL)) == NULL) { return(NO); } // Resize the buffer.
  }
  RKLCDelayedAssert(buffer->uniChar != NULL, exception, exitNow);
  CFStringGetCharacters(cacheSlot->setToString, CFMakeRange(0, cacheSlot->setToLength), (UniChar *)buffer->uniChar); // Convert to a UTF16 string.

  if((buffer->string = CFRetain(cacheSlot->setToString)) == NULL) { return(NO); }
  buffer->hash   = cacheSlot->setToHash;
  buffer->length = cacheSlot->setToLength;

  cacheSlot->setToUniChar = buffer->uniChar;
  cacheSlot->setToRange   = NSNotFoundRange;

 setRegexText:

  if(NSEqualRanges(cacheSlot->setToRange, *range) == NO) {
    RKLCDelayedAssert((cacheSlot->icu_regex != NULL) && (cacheSlot->setToUniChar != NULL) && (NSMaxRange(*range) <= (NSUInteger)cacheSlot->setToLength), exception, exitNow);
    cacheSlot->lastFindRange = cacheSlot->lastMatchRange = NSNotFoundRange;
    cacheSlot->setToRange    = *range;
    uregex_setText(cacheSlot->icu_regex, cacheSlot->setToUniChar + cacheSlot->setToRange.location, (int32_t)cacheSlot->setToRange.length, status);
    if(*status > 0) { return(NO); }
  }

  return(YES);

 exitNow:
  return(NO);
}

//  IMPORTANT!   This code is critical path code.  Because of this, it has been written for speed, not clarity.
//  IMPORTANT!   Should only be called with cacheSpinLock already locked!
//  ----------

static RKLCacheSlot *getCachedRegexSetToString(NSString *regexString, RKLRegexOptions options, NSString *matchString, NSUInteger *matchLengthPtr, NSRange *matchRange, NSError **error, id *exception, int32_t *status) {
  RKLCacheSlot *cacheSlot = NULL;
  RKLCDelayedAssert((regexString != NULL) && (exception != NULL) && (status != NULL), exception, exitNow);

  // Fast path the common case where this regex is exactly the same one used last time.
  if((lastCacheSlot != NULL) && (lastCacheSlot->regexString == (CFStringRef)regexString) && (lastCacheSlot->options == options)) { cacheSlot = lastCacheSlot; }
  else { if((cacheSlot = getCachedRegex(regexString, options, error, exception)) == NULL) { goto exitNow; } }

  // Optimize the case where the string to search (matchString) is immutable and the setToString immutable copy is the same string with its reference count incremented.
  BOOL    isSetTo     = ((cacheSlot->setToString != NULL) && (cacheSlot->setToString == (CFStringRef)matchString)) ? YES : NO;
  CFIndex matchLength = (isSetTo == YES) && (cacheSlot->setToIsImmutable == YES) ? cacheSlot->setToLength : CFStringGetLength((CFStringRef)matchString);

  *matchLengthPtr = (NSUInteger)matchLength;
  if(matchRange->length == NSUIntegerMax) { matchRange->length = matchLength; } // For convenience, allow NSUIntegerMax == string length.

  if((NSUInteger)matchLength < NSMaxRange(*matchRange)) { *exception = [NSException exceptionWithName:NSRangeException reason:@"Range or index out of bounds" userInfo:NULL]; goto exitNow; }

  if((cacheSlot->setToIsImmutable == NO) && (cacheSlot->setToString != NULL) && ((cacheSlot->setToLength != CFStringGetLength(cacheSlot->setToString)) || (cacheSlot->setToHash != CFHash(cacheSlot->setToString)))) { isSetTo = NO; }
  else { // If the first pointer equality check failed, check the hash and length.
    if(((isSetTo == NO) || (cacheSlot->setToIsImmutable == NO)) && (cacheSlot->setToString != NULL)) { isSetTo = ((cacheSlot->setToLength == matchLength) && (cacheSlot->setToHash == CFHash((CFStringRef)(matchString)))); }

    if((isSetTo == YES)) { // Make sure that the UTF16 conversion cache is set to this string, if conversion is required.
      if((cacheSlot->setToNeedsConversion == YES) && (setCacheSlotToString(cacheSlot, matchRange, status, exception) == NO)) { *exception = RKLCAssert(@"Failed to set up UTF16 buffer."); goto exitNow; }
      if(NSEqualRanges(cacheSlot->setToRange, *matchRange) == YES) { goto exitNow; } // Verify that the range to search is what the cached regex was prepped for last time.
    }
  }

  // Sometimes the range that the regex is set to isn't right, in which case we don't want to clear the cache slot.  Otherwise, flush it out.
  if((cacheSlot->setToString != NULL) && (isSetTo == NO)) { clearCacheSlotSetTo(cacheSlot); }

  if(cacheSlot->setToString == NULL) {
    cacheSlot->setToString          = CFRetain(matchString);
    RKLCDelayedAssert(cacheSlot->setToString != NULL, exception, exitNow);
    cacheSlot->setToUniChar         = CFStringGetCharactersPtr(cacheSlot->setToString);
    cacheSlot->setToNeedsConversion = (cacheSlot->setToUniChar == NULL) ? YES : NO;
    cacheSlot->setToIsImmutable     = !rkl_CFStringIsMutable(cacheSlot->setToString); // If RKL_FAST_MUTABLE_CHECK is not defined then the result is '0', or in other words mutable..
    cacheSlot->setToHash            = CFHash(cacheSlot->setToString);
    cacheSlot->setToRange           = NSNotFoundRange;
    cacheSlot->setToLength          = matchLength;
  }

  if(setCacheSlotToString(cacheSlot, matchRange, status, exception) == NO) { cacheSlot = NULL; goto exitNow; }

 exitNow:
  return(cacheSlot);
}

//  IMPORTANT!   This code is critical path code.  Because of this, it has been written for speed, not clarity.
//  ----------

static id performRegexOp(id self, SEL _cmd, RKLRegexOp doRegexOp, NSString *regexString, RKLRegexOptions options, NSInteger capture, id matchString, NSRange *matchRange, NSString *replacementString, NSError **error, void **result) {
  BOOL       replaceMutable = ((doRegexOp & RKLReplaceMutable) != 0) ? YES : NO;
  RKLRegexOp regexOp        = (doRegexOp & RKLMaskOp);

  if((error != NULL) && (*error != NULL))                      { *error = NULL; }

  if(regexString == NULL)                                      { RKLRaiseException(NSInvalidArgumentException, @"The regular expression argument is NULL."); }
  if(matchString == NULL)                                      { RKLRaiseException(NSInternalInconsistencyException, @"The match string argument is NULL."); }
  if((regexOp == RKLReplaceOp) && (replacementString == NULL)) { RKLRaiseException(NSInvalidArgumentException, @"The replacement string argument is NULL."); }

  NSUInteger    stringU16Length = 0UL, replacementU16Length = (NSUInteger)((replacementString != NULL) ? CFStringGetLength((CFStringRef)replacementString) : 0); // In UTF16 code units.
  NSRange       stringRange     = NSMakeRange(0, NSUIntegerMax), searchRange = (matchRange != NULL) ? *matchRange : NSNotFoundRange;
  RKLCacheSlot *cacheSlot       = NULL;
  id            exception       = NULL;
  id            resultObject    = NULL;
  int32_t       status          = 0;

  // IMPORTANT!   Once we have obtained the lock, code MUST exit via 'goto exitNow;' to unlock the lock!  NO EXCEPTIONS!
  // ----------
  OSSpinLockLock(&cacheSpinLock); // Grab the lock and get cache entry.

  if(((cacheSlot = getCachedRegexSetToString(regexString, options, matchString, &stringU16Length, (regexOp == RKLRangeOp) ? &stringRange : &searchRange, error, &exception, &status)) == NULL) || (exception != NULL) || (status > 0)) { goto exitNow; }

  if(searchRange.length == NSUIntegerMax)           { searchRange.length = stringU16Length; } // For convenience.
  if(stringU16Length     < NSMaxRange(searchRange)) { exception = [NSException exceptionWithName:NSRangeException reason:@"Range or index out of bounds" userInfo:NULL]; goto exitNow; }

  RKLCDelayedAssert((cacheSlot->icu_regex != NULL) && (exception == NULL), &exception, exitNow);

  if(cacheSlot->setToNeedsConversion != 0) {
    RKLBuffer *buffer = (cacheSlot->setToLength < RKL_FIXED_LENGTH) ? &fixedBuffer : &dynamicBuffer;
    RKLCDelayedAssert((cacheSlot->setToHash == buffer->hash) && (cacheSlot->setToLength == buffer->length) && (cacheSlot->setToUniChar == buffer->uniChar), &exception, exitNow);
  }

  switch(regexOp) {
    case RKLRangeOp:                  rkl_find(cacheSlot, capture, searchRange, (NSRange *)result, &exception, &status); break;
    case RKLSplitOp:   resultObject = rkl_splitArray(cacheSlot, &exception, &status);                                    break;
    case RKLReplaceOp: resultObject = rkl_replaceString(cacheSlot, matchString, stringU16Length, replacementString, replacementU16Length, (NSUInteger *)result, replaceMutable, &exception, &status); break;
    default:           exception    = RKLCAssert(@"Unknown regexOp code.");                                              break;
  }

 exitNow:
  OSSpinLockUnlock(&cacheSpinLock);

  if((status > 0) && (exception == NULL)) { exception = RKLNSExceptionForRegex(regexString, options, NULL, status); } // If we had a problem, throw an exception.
  if(exception != NULL) {
    if([exception isKindOfClass:[NSException class]]) { [[NSException exceptionWithName:[exception name] reason:RKLStringFromClassAndMethod(self, _cmd, [exception reason]) userInfo:[exception userInfo]] raise]; }
    else { [[NSAssertionHandler currentHandler] handleFailureInFunction:[exception objectForKey:@"function"] file:[exception objectForKey:@"file"] lineNumber:[[exception objectForKey:@"line"] longValue] description:[exception objectForKey:@"description"]]; }
  }
  if(replaceMutable == YES) { // We're working on a mutable string and if there were successfull matches with replaced text we still have work to do.  Done outside the cache lock.
    if(*((NSUInteger *)result) > 0) { NSCParameterAssert(resultObject != NULL); [matchString replaceCharactersInRange:searchRange withString:resultObject]; }
  }

  return(resultObject);
}

//  IMPORTANT!   This code is critical path code.  Because of this, it has been written for speed, not clarity.
//  IMPORTANT!   Should only be called from performRegexOp().
//  ----------

static void rkl_find(RKLCacheSlot *cacheSlot, NSInteger capture, NSRange searchRange, NSRange *resultRange, id *exception, int32_t *status) {
  NSRange captureRange = NSNotFoundRange;

  RKLCDelayedAssert((cacheSlot != NULL) && (resultRange != NULL) && (exception != NULL) && (status != NULL), exception, exitNow);

  if((capture < 0) || (capture > cacheSlot->captureCount)) { *exception = [NSException exceptionWithName:NSInvalidArgumentException reason:@"The capture argument is not valid." userInfo:NULL]; goto exitNow; }
  
  if((NSEqualRanges(searchRange, cacheSlot->lastFindRange) == NO)) { // Only perform an expensive 'find' operation iff the current find range is different than the last find range.
    RKL_PREFETCH(cacheSlot->setToUniChar, searchRange.location << 1); // Spool up the CPU caches.

    // Using uregex_findNext can be a slight performance win.
    BOOL useFindNext = (searchRange.location == (NSMaxRange(cacheSlot->lastMatchRange) + ((cacheSlot->lastMatchRange.length == 0) ? 1 : 0))) ? YES : NO;
    
    cacheSlot->lastFindRange = NSNotFoundRange; // Cleared the cached search/find range.
    if(useFindNext == NO) { if((uregex_find    (cacheSlot->icu_regex, (int32_t)searchRange.location, status) == NO) || (*status > 0)) { goto exitNow; } }
    else {                  if((uregex_findNext(cacheSlot->icu_regex,                                status) == NO) || (*status > 0)) { goto exitNow; } }
    
    if(RKLGetRangeForCapture(cacheSlot->icu_regex, status, 0, cacheSlot->lastMatchRange) !=  0) { goto exitNow; }
    if(NSRangeInsideRange(cacheSlot->lastMatchRange, searchRange)                        == NO) { goto exitNow; } // If the regex matched outside the requested range, exit.
    
    cacheSlot->lastFindRange = searchRange; // Cache the successful search/find range.
  }
  
  if(capture == 0) { captureRange = cacheSlot->lastMatchRange; } else { RKLGetRangeForCapture(cacheSlot->icu_regex, status, capture, captureRange); }

 exitNow:
  *resultRange = captureRange;
}

//  IMPORTANT!   This code is critical path code.  Because of this, it has been written for speed, not clarity.
//  IMPORTANT!   Should only be called from performRegexOp().
//  ----------

static NSArray *rkl_splitArray(RKLCacheSlot *cacheSlot, id *exception, int32_t *status) {
  NSArray    *resultArray         = NULL;

  RKLCDelayedAssert((cacheSlot != NULL) && (status != NULL), exception, exitNow);

  const char *setToUniCharChar    = (const char *)(cacheSlot->setToUniChar + cacheSlot->setToRange.location);
  NSUInteger  splitRangesCapacity = ((((RKL_STACK_LIMIT / sizeof(NSRange)) / 4) + ((cacheSlot->captureCount + 1) * 2)) + 2), splitRangesIndex = 0, lastLocation = 0, x = 0;
  size_t      splitRangesSize     = (splitRangesCapacity * sizeof(NSRange)), stackUsed = 0;
  NSInteger   captureCount        = cacheSlot->captureCount;
  uregex     *icu_regex           = cacheSlot->icu_regex;
  NSRange    *splitRanges         = NULL;
  BOOL        copiedStackToHeap   = NO;

  if(cacheSlot->setToLength == 0) { resultArray = [NSArray array]; goto exitNow; } // Return an empty array when there is nothing to search.

  if(splitRangesSize < RKL_STACK_LIMIT) { if((splitRanges = alloca(splitRangesSize)) == NULL) { goto exitNow; } stackUsed += splitRangesSize; }
  else { if((splitRanges = rkl_realloc(&scratchBuffer[0], splitRangesSize, 0UL)) == NULL) { goto exitNow; } }

  cacheSlot->lastFindRange = cacheSlot->lastMatchRange = NSNotFoundRange; // Clear the cached find information for this regex so a subsequent find works correctly.
  uregex_reset(icu_regex, 0, status); // Reset the regex to the start of the string.

  for(splitRangesIndex = 0; splitRangesIndex < splitRangesCapacity; splitRangesIndex++) {

    if(splitRangesIndex >= ((splitRangesCapacity - ((captureCount + 1) * 2)) - 1)) { // Check if we need to grow our NSRanges buffer.
      NSUInteger newCapacity = (((splitRangesCapacity + (splitRangesCapacity / 2)) + ((captureCount + 1) * 2)) + 2);
      size_t     newSize     = (newCapacity * sizeof(NSRange));
      NSRange   *newRanges   = NULL;

      if((newRanges = rkl_realloc(&scratchBuffer[0], newSize, 0UL)) == NULL) { goto exitNow; } // We only try to use the stack the first time, after that, we use the heap.
      if((stackUsed > 0) && (copiedStackToHeap == NO)) { memcpy(newRanges, splitRanges, splitRangesSize); copiedStackToHeap = YES; }

      splitRangesCapacity = newCapacity;
      splitRangesSize     = newSize;
      splitRanges         = newRanges;
    }

    RKL_PREFETCH(setToUniCharChar, lastLocation << 1); // Spool up the CPU caches.

    NSUInteger baseMatchIndex = splitRangesIndex;
    NSRange    tempRange;

    if((uregex_findNext(icu_regex, status) == NO) || (*status > 0)) { break; }
    if(RKLGetRangeForCapture(icu_regex, status, 0, tempRange) > 0) { goto exitNow; }

    splitRanges[splitRangesIndex] = NSMakeRange(lastLocation, tempRange.location - lastLocation);
    lastLocation = NSMaxRange(tempRange);

    int32_t capture;
    for(capture = 1; capture <= captureCount; capture++) {
      RKLCDelayedAssert(splitRangesIndex < (splitRangesCapacity - 2), exception, exitNow);
      splitRangesIndex++;
      
      if(RKLGetRangeForCapture(icu_regex, status, capture, splitRanges[splitRangesIndex]) > 0) { goto exitNow; }
      if(splitRanges[splitRangesIndex].location == NSNotFound) { splitRanges[splitRangesIndex] = NSMakeRange(splitRanges[baseMatchIndex].location, 0); }
    }
  }

  RKLCDelayedAssert(splitRangesIndex < (splitRangesCapacity - 2), exception, exitNow);
  splitRanges[splitRangesIndex] = NSMakeRange(lastLocation, (NSMaxRange(cacheSlot->setToRange) - cacheSlot->setToRange.location) - lastLocation);
  splitRangesIndex++;

  CFIndex      setToLocation    = cacheSlot->setToRange.location;
  CFStringRef  setToString      = cacheSlot->setToString;
  size_t       splitStringsSize = (splitRangesIndex * sizeof(id));
  id          *splitStrings     = NULL;

  if((stackUsed + splitStringsSize) < RKL_STACK_LIMIT) { if((splitStrings = alloca(splitStringsSize)) == NULL) { goto exitNow; } stackUsed += splitStringsSize; }
  else { if((splitStrings = rkl_realloc(&scratchBuffer[1], splitStringsSize, (NSUInteger)NSScannedOption)) == NULL) { goto exitNow; } }

#ifdef __OBJC_GC__ 
  if(rkl_collectingEnabled() == YES) { // I just don't trust the GC system with the faster CF way of doing things...  It never seems to work quite the way you expect it to.
    for(x = 0; x < splitRangesIndex; x++) { // Optimize the case where the length == 0 by substituting the string @"".
      splitStrings[x] = (splitRanges[x].length == 0) ? @"" : [(id)setToString substringWithRange:NSMakeRange(setToLocation + splitRanges[x].location, splitRanges[x].length)];
    }
    resultArray = [NSArray arrayWithObjects:splitStrings count:splitRangesIndex];
  } else
#endif
  { // This block of code is always compiled in.  It is used when not compiled with GC or when compiled with GC but the collector is not enabled.
    for(x = 0; x < splitRangesIndex; x++) { // Optimize the case where the length == 0 by substituting the string @"".
      splitStrings[x] = (splitRanges[x].length == 0) ? @"" : (id)CFStringCreateWithSubstring(NULL, setToString, CFMakeRange(setToLocation + splitRanges[x].location, (CFIndex)splitRanges[x].length));
    }
    resultArray = rkl_CFAutorelease(CFArrayCreate(NULL, (const void **)splitStrings, (CFIndex)splitRangesIndex, &transferOwnershipArrayCallBacks)); // Create the CF/NSArray of the split strings.
  }
  
 exitNow:
  if(scratchBuffer[0] != NULL) { free(scratchBuffer[0]); scratchBuffer[0] = NULL; }
  if(scratchBuffer[1] != NULL) { free(scratchBuffer[1]); scratchBuffer[1] = NULL; }

  return(resultArray);
}

//  IMPORTANT!   This code is critical path code.  Because of this, it has been written for speed, not clarity.
//  IMPORTANT!   Should only be called from performRegexOp().
//  ----------

static NSString *rkl_replaceString(RKLCacheSlot *cacheSlot, id searchString, NSUInteger searchU16Length, NSString *replacementString, NSUInteger replacementU16Length, NSUInteger *replacedCountPtr, int replaceMutable, id *exception, int32_t *status) {
  int32_t        resultU16Length    = 0, tempUniCharBufferU16Capacity = 0;
  UniChar       *tempUniCharBuffer  = NULL;
  const UniChar *replacementUniChar = NULL;
  id             resultObject       = NULL;
  NSUInteger     replacedCount      = 0;

  // Zero order approximation of the buffer sizes for holding the replaced string or split strings and split strings pointer offsets.  As UTF16 code units.
  tempUniCharBufferU16Capacity = (int32_t)((searchU16Length + (searchU16Length >> 1)) + (replacementU16Length * 2));
  
  // Buffer sizes converted from native units to bytes.
  size_t stackSize = 0, replacementSize = (replacementU16Length * sizeof(UniChar)), tempUniCharBufferSize = (tempUniCharBufferU16Capacity * sizeof(UniChar));
  
  // For the various buffers we require, we first try to allocate from the stack if we're not over the RKL_STACK_LIMIT.  If we are, switch to using the heap for the buffer.
  
  if(tempUniCharBufferSize > 0) {
    if((stackSize + tempUniCharBufferSize) < RKL_STACK_LIMIT) { if((tempUniCharBuffer = alloca(tempUniCharBufferSize)) == NULL) { goto exitNow; } stackSize += tempUniCharBufferSize; }
    else { if((tempUniCharBuffer = rkl_realloc(&scratchBuffer[0], tempUniCharBufferSize, 0UL)) == NULL) { goto exitNow; } }
  }
  
  // Try to get the pointer to the replacement strings UTF16 data.  If we can't, allocate some buffer space, then covert to UTF16.
  if((replacementUniChar = CFStringGetCharactersPtr((CFStringRef)replacementString)) == NULL) {
    if((stackSize + replacementSize) < RKL_STACK_LIMIT) { if((replacementUniChar = alloca(replacementSize)) == NULL) { goto exitNow; } stackSize += replacementSize; } 
    else { if((replacementUniChar = rkl_realloc(&scratchBuffer[1], replacementSize, 0UL)) == NULL) { goto exitNow; } }
    CFStringGetCharacters((CFStringRef)replacementString, CFMakeRange(0, replacementU16Length), (UniChar *)replacementUniChar); // Convert to a UTF16 string.
  }
  
  cacheSlot->lastFindRange = cacheSlot->lastMatchRange = NSNotFoundRange; // Clear the cached find information for this regex so a subsequent find works correctly.
  
  resultU16Length = rkl_replaceAll(cacheSlot, replacementUniChar, (int32_t)replacementU16Length, tempUniCharBuffer, tempUniCharBufferU16Capacity, &replacedCount, exception, status);
  
  if(*status == U_BUFFER_OVERFLOW_ERROR) { // Our buffer guess(es) were too small.  Resize the buffers and try again.
    tempUniCharBufferSize = ((tempUniCharBufferU16Capacity = resultU16Length + 4) * sizeof(UniChar));
    if((stackSize + tempUniCharBufferSize) < RKL_STACK_LIMIT) { if((tempUniCharBuffer = alloca(tempUniCharBufferSize)) == NULL) { goto exitNow; } stackSize += tempUniCharBufferSize; }
    else { if((tempUniCharBuffer = rkl_realloc(&scratchBuffer[0], tempUniCharBufferSize, 0UL)) == NULL) { goto exitNow; } }
    
    *status = 0; // Make sure the status var is cleared and try again.
    resultU16Length = rkl_replaceAll(cacheSlot, replacementUniChar, (int32_t)replacementU16Length, tempUniCharBuffer, tempUniCharBufferU16Capacity, &replacedCount, exception, status);
  }
  
  if(*status > 0) { goto exitNow; } // Something went wrong.
  
  if(resultU16Length == 0) { resultObject = @""; } // Optimize the case where the replaced text length == 0 with a @"" string.
  else if(((NSUInteger)resultU16Length == searchU16Length) && (replacedCount == 0)) { // Optimize the case where the replacement == original by creating a copy. Very fast if self is immutable.
    if(replaceMutable == NO) { resultObject = rkl_CFAutorelease(CFStringCreateCopy(NULL, (CFStringRef)searchString)); } // .. but only if this is not replacing a mutable self.
  } else { resultObject = rkl_CFAutorelease(CFStringCreateWithCharacters(NULL, tempUniCharBuffer, (CFIndex)resultU16Length)); } // otherwise, create a new string.
  
  // If replaceMutable == YES, we don't do the replacement here.  We wait until after we return and unlock the cache lock.
  // This is because we may be trying to mutate an immutable string object.
  if((replacedCount > 0) && (replaceMutable == YES)) { // We're working on a mutable string and there were successfull matches with replaced text, so there's work to do.
    clearBuffer((cacheSlot->setToLength < RKL_FIXED_LENGTH) ? &fixedBuffer : &dynamicBuffer, NO);
    clearCacheSlotSetTo(cacheSlot); // Flush any cached information about this string since it will mutate.
  }

 exitNow:
  if(scratchBuffer[0] != NULL) { free(scratchBuffer[0]); scratchBuffer[0] = NULL; }
  if(scratchBuffer[1] != NULL) { free(scratchBuffer[1]); scratchBuffer[1] = NULL; }
  if(replacedCountPtr != NULL) { *replacedCountPtr = replacedCount; }
  return(resultObject);
}

// Modified version of the ICU libraries uregex_replaceAll() that keeps count of the number of replacements made.
static int32_t rkl_replaceAll(RKLCacheSlot *cacheSlot, const UniChar *replacementUniChar, int32_t replacementU16Length, UniChar *replacedUniChar, int32_t replacedU16Capacity, NSUInteger *replacedCount, id *exception, int32_t *status) {
  NSUInteger replaced  = 0;
  int32_t    u16Length = 0;
  RKLCDelayedAssert((cacheSlot != NULL) && (replacementUniChar != NULL) && (replacedUniChar != NULL) && (status != NULL), exception, exitNow);
  
  uregex_reset(cacheSlot->icu_regex, 0, status);

  while(uregex_findNext(cacheSlot->icu_regex, status)) {
    replaced++;
    u16Length += uregex_appendReplacement(cacheSlot->icu_regex, replacementUniChar, replacementU16Length, &replacedUniChar, &replacedU16Capacity, status);
  }
  u16Length += uregex_appendTail(cacheSlot->icu_regex, &replacedUniChar, &replacedU16Capacity, status);
 
  if(replacedCount != 0) { *replacedCount = replaced; }
 exitNow:
  return(u16Length);
}

static void clearBuffer(RKLBuffer *buffer, int freeDynamicBuffer) {
  if(buffer == NULL) { return; }
  if((freeDynamicBuffer == YES) && (buffer->uniChar != NULL) && (buffer == &dynamicBuffer)) { free(dynamicBuffer.uniChar); dynamicBuffer.uniChar = NULL; }
  if(buffer->string != NULL) { CFRelease(buffer->string); buffer->string = NULL; }
  buffer->length = 0L;
  buffer->hash   = 0UL;
}

static void clearCacheSlotRegex(RKLCacheSlot *cacheSlot) {
  if(cacheSlot == NULL) { return; }
  if(cacheSlot->regexString != NULL) { CFRelease(cacheSlot->regexString);  cacheSlot->regexString = NULL; cacheSlot->options      =  0U; }
  if(cacheSlot->icu_regex   != NULL) { uregex_close(cacheSlot->icu_regex); cacheSlot->icu_regex   = NULL; cacheSlot->captureCount = -1L; }
  if(cacheSlot->setToString != NULL) { clearCacheSlotSetTo(cacheSlot); }
}

static void clearCacheSlotSetTo(RKLCacheSlot *cacheSlot) {
  if(cacheSlot == NULL) { return; }
  if(cacheSlot->icu_regex   != NULL) { int32_t status; uregex_setText(cacheSlot->icu_regex, &emptyUniCharString[0], 0, &status); }
  if(cacheSlot->setToString != NULL) { CFRelease(cacheSlot->setToString); cacheSlot->setToString = NULL; }
  cacheSlot->setToLength      = 0L;
  cacheSlot->setToHash        = 0UL;
  cacheSlot->setToIsImmutable = cacheSlot->setToNeedsConversion = 0UL;
  cacheSlot->lastFindRange    = cacheSlot->lastMatchRange = cacheSlot->setToRange = NSNotFoundRange;
  cacheSlot->setToUniChar     = NULL;
}

// Helps to keep things tidy.
#define addKeyAndObject(objs, keys, i, k, o) ({id _o=(o), _k=(k); if((_o != NULL) && (_k != NULL)) { objs[i] = _o; keys[i] = _k; i++; } })

static NSDictionary *userInfoDictionary(NSString *regexString, RKLRegexOptions options, const UParseError *parseError, int status, ...) {
  va_list varArgsList;
  va_start(varArgsList, status);

  if(regexString == NULL) { return(NULL); }

  id objects[64], keys[64];
  NSUInteger count = 0;

  NSString *errorNameString = [NSString stringWithUTF8String:u_errorName(status)];

  addKeyAndObject(objects, keys, count, RKLICURegexRegexErrorKey,        regexString);
  addKeyAndObject(objects, keys, count, RKLICURegexRegexOptionsErrorKey, [NSNumber numberWithUnsignedInt:options]);
  addKeyAndObject(objects, keys, count, RKLICURegexErrorCodeErrorKey,    [NSNumber numberWithInt:status]);
  addKeyAndObject(objects, keys, count, RKLICURegexErrorNameErrorKey,    errorNameString);

  if((parseError != NULL) && (parseError->line != -1)) {
    NSString *preContextString  = [NSString stringWithCharacters:&parseError->preContext[0]  length:(NSUInteger)u_strlen(&parseError->preContext[0])];
    NSString *postContextString = [NSString stringWithCharacters:&parseError->postContext[0] length:(NSUInteger)u_strlen(&parseError->postContext[0])];
    
    addKeyAndObject(objects, keys, count, RKLICURegexLineErrorKey,        [NSNumber numberWithInt:parseError->line]);
    addKeyAndObject(objects, keys, count, RKLICURegexOffsetErrorKey,      [NSNumber numberWithInt:parseError->offset]);
    addKeyAndObject(objects, keys, count, RKLICURegexPreContextErrorKey,  preContextString);
    addKeyAndObject(objects, keys, count, RKLICURegexPostContextErrorKey, postContextString);
    addKeyAndObject(objects, keys, count, @"NSLocalizedFailureReason",    ([NSString stringWithFormat:@"The error %@ occurred at line %d, column %d: %@<<HERE>>%@", errorNameString, parseError->line, parseError->offset, preContextString, postContextString]));
  } else {
    addKeyAndObject(objects, keys, count, @"NSLocalizedFailureReason",    ([NSString stringWithFormat:@"The error %@ occurred.", errorNameString]));
  }

  while(count < 62) { id obj = va_arg(varArgsList, id), key = va_arg(varArgsList, id); if((obj != NULL) && (key != NULL)) { addKeyAndObject(objects, keys, count, key, obj); } else { break; } }

  return([NSDictionary dictionaryWithObjects:&objects[0] forKeys:&keys[0] count:count]);
}

static NSError *RKLNSErrorForRegex(NSString *regexString, RKLRegexOptions options, const UParseError *parseError, int status) {
  return([NSError errorWithDomain:RKLICURegexErrorDomain code:(NSInteger)status userInfo:userInfoDictionary(regexString, options, parseError, status, @"There was an error compiling the regular expression.", @"NSLocalizedDescription", NULL)]);
}

static NSException *RKLNSExceptionForRegex(NSString *regexString, RKLRegexOptions options, const UParseError *parseError, int status) {
  return([NSException exceptionWithName:RKLICURegexException reason:[NSString stringWithFormat:@"ICU regular expression error #%d, %s", status, u_errorName(status)] userInfo:userInfoDictionary(regexString, options, parseError, status, NULL)]);
}

static NSDictionary *RKLCAssertDictionary(const char *function, const char *file, int line, NSString *format, ...) {
  va_list varArgsList;
  va_start(varArgsList, format);
  NSString *formatString   = [[[NSString alloc] initWithFormat:format arguments:varArgsList] autorelease];
  va_end(varArgsList);
  NSString *functionString = [NSString stringWithUTF8String:function], *fileString = [NSString stringWithUTF8String:file];
  return([NSDictionary dictionaryWithObjectsAndKeys:formatString, @"description", functionString, @"function", fileString, @"file", [NSNumber numberWithInt:line], @"line", NSInternalInconsistencyException, @"exceptionName", NULL]);
}

static NSString *RKLStringFromClassAndMethod(id object, SEL selector, NSString *format, ...) {
  va_list varArgsList;
  va_start(varArgsList, format);
  NSString *formatString   = [[[NSString alloc] initWithFormat:format arguments:varArgsList] autorelease];
  va_end(varArgsList);
  Class objectsClass = [object class];
  return([NSString stringWithFormat:@"*** %c[%@ %@]: %@", (object == objectsClass) ? '+' : '-', NSStringFromClass(objectsClass), NSStringFromSelector(selector), formatString]);
}

@implementation NSString (RegexKitLiteAdditions)

// Class methods

+ (void)clearStringCache
{
  OSSpinLockLock(&cacheSpinLock);
  lastCacheSlot = NULL;
  NSUInteger x = 0;
  for(x = 0; x < SCRATCH_BUFFERS; x++) { if(scratchBuffer[x] != NULL) { free(scratchBuffer[x]); scratchBuffer[x] = NULL; } }
  for(x = 0; x < RKL_CACHE_SIZE;  x++) { clearCacheSlotRegex(&RKLCache[x]); clearCacheSlotSetTo(&RKLCache[x]); }
  clearBuffer(&fixedBuffer, NO);
  clearBuffer(&dynamicBuffer, YES);
  OSSpinLockUnlock(&cacheSpinLock);
}

// captureCountForRegex:

+ (NSInteger)captureCountForRegex:(NSString *)regex
{
  return([self captureCountForRegex:regex options:RKLNoOptions error:NULL]);
}

+ (NSInteger)captureCountForRegex:(NSString *)regex options:(RKLRegexOptions)options error:(NSError **)error
{
  if((error != NULL) && (*error != NULL)) { *error = NULL; }
  if(regex == NULL) { RKLRaiseException(NSInvalidArgumentException, @"The regular expression argument is NULL."); }

  NSException  *exception    = NULL;
  RKLCacheSlot *cacheSlot    = NULL;
  NSInteger     captureCount = -1;

  OSSpinLockLock(&cacheSpinLock);
  if((cacheSlot = getCachedRegex(regex, options, error, &exception)) != NULL) { captureCount = cacheSlot->captureCount; }
  OSSpinLockUnlock(&cacheSpinLock);

  if(exception != NULL) { [exception raise]; }
  return(captureCount);
}

// Instance methods

// componentsSeparatedByRegex:

- (NSArray *)componentsSeparatedByRegex:(NSString *)regex
{
  NSRange range = NSMaxiumRange;
  return(performRegexOp(self, _cmd, (RKLRegexOp)RKLSplitOp, regex, 0, 0L, self, &range, NULL, NULL, NULL));
}

- (NSArray *)componentsSeparatedByRegex:(NSString *)regex range:(NSRange)range
{
  return(performRegexOp(self, _cmd, (RKLRegexOp)RKLSplitOp, regex, 0, 0L, self, &range, NULL, NULL, NULL));
}

- (NSArray *)componentsSeparatedByRegex:(NSString *)regex options:(RKLRegexOptions)options range:(NSRange)range error:(NSError **)error
{
  return(performRegexOp(self, _cmd, (RKLRegexOp)RKLSplitOp, regex, options, 0L, self, &range, NULL, error, NULL));
}

// isMatchedByRegex:

- (BOOL)isMatchedByRegex:(NSString *)regex
{
  NSRange result = NSNotFoundRange, range = NSMaxiumRange;
  performRegexOp(self, _cmd, (RKLRegexOp)RKLRangeOp, regex, 0, 0L, self, &range, NULL, NULL, (void **)((void *)&result));
  return((result.location == NSNotFound) ? NO : YES);
}

- (BOOL)isMatchedByRegex:(NSString *)regex inRange:(NSRange)range
{
  NSRange result = NSNotFoundRange;
  performRegexOp(self, _cmd, (RKLRegexOp)RKLRangeOp, regex, 0, 0L, self, &range, NULL, NULL, (void **)((void *)&result));
  return((result.location == NSNotFound) ? NO : YES);
}

- (BOOL)isMatchedByRegex:(NSString *)regex options:(RKLRegexOptions)options inRange:(NSRange)range error:(NSError **)error
{
  NSRange result = NSNotFoundRange;
  performRegexOp(self, _cmd, (RKLRegexOp)RKLRangeOp, regex, options, 0L, self, &range, NULL, error, (void **)((void *)&result));
  return((result.location == NSNotFound) ? NO : YES);
}

// rangeOfRegex:

- (NSRange)rangeOfRegex:(NSString *)regex
{
  NSRange result = NSNotFoundRange, range = NSMaxiumRange;
  performRegexOp(self, _cmd, (RKLRegexOp)RKLRangeOp, regex, 0, 0L, self, &range, NULL, NULL, (void **)((void *)&result));
  return(result);
}

- (NSRange)rangeOfRegex:(NSString *)regex capture:(NSInteger)capture
{
  NSRange result = NSNotFoundRange, range = NSMaxiumRange;
  performRegexOp(self, _cmd, (RKLRegexOp)RKLRangeOp, regex, 0, capture, self, &range, NULL, NULL, (void **)((void *)&result));
  return(result);
}

- (NSRange)rangeOfRegex:(NSString *)regex inRange:(NSRange)range
{
  NSRange result = NSNotFoundRange;
  performRegexOp(self, _cmd, (RKLRegexOp)RKLRangeOp, regex, 0, 0L, self, &range, NULL, NULL, (void **)((void *)&result));
  return(result);
}

- (NSRange)rangeOfRegex:(NSString *)regex options:(RKLRegexOptions)options inRange:(NSRange)range capture:(NSInteger)capture error:(NSError **)error
{
  NSRange result = NSNotFoundRange;
  performRegexOp(self, _cmd, (RKLRegexOp)RKLRangeOp, regex, options, capture, self, &range, NULL, error, (void **)((void *)&result));
  return(result);
}

// stringByMatching:

- (NSString *)stringByMatching:(NSString *)regex
{
  return([self stringByMatching:regex options:RKLNoOptions inRange:NSMaxiumRange capture:0L error:NULL]);
}

- (NSString *)stringByMatching:(NSString *)regex capture:(NSInteger)capture
{
  return([self stringByMatching:regex options:RKLNoOptions inRange:NSMaxiumRange capture:capture error:NULL]);
}

- (NSString *)stringByMatching:(NSString *)regex inRange:(NSRange)range
{
  return([self stringByMatching:regex options:RKLNoOptions inRange:range capture:0L error:NULL]);
}

- (NSString *)stringByMatching:(NSString *)regex options:(RKLRegexOptions)options inRange:(NSRange)range capture:(NSInteger)capture error:(NSError **)error
{
  NSRange matchedRange = [self rangeOfRegex:regex options:options inRange:range capture:capture error:error];
  return((matchedRange.location == NSNotFound) ? NULL : rkl_CFAutorelease(CFStringCreateWithSubstring(NULL, (CFStringRef)self, CFMakeRange(matchedRange.location, matchedRange.length))));
}

// stringByReplacingOccurrencesOfRegex:

- (NSString *)stringByReplacingOccurrencesOfRegex:(NSString *)regex withString:(NSString *)replacement
{
  NSRange searchRange = NSMaxiumRange;
  return(performRegexOp(self, _cmd, (RKLRegexOp)RKLReplaceOp, regex, 0, 0L, self, &searchRange, replacement, NULL, NULL));
}

- (NSString *)stringByReplacingOccurrencesOfRegex:(NSString *)regex withString:(NSString *)replacement range:(NSRange)searchRange
{
  return(performRegexOp(self, _cmd, (RKLRegexOp)RKLReplaceOp, regex, 0, 0L, self, &searchRange, replacement, NULL, NULL));
}

- (NSString *)stringByReplacingOccurrencesOfRegex:(NSString *)regex withString:(NSString *)replacement options:(RKLRegexOptions)options range:(NSRange)searchRange error:(NSError **)error
{
  return(performRegexOp(self, _cmd, (RKLRegexOp)RKLReplaceOp, regex, options, 0L, self, &searchRange, replacement, error, NULL));
}

@end


@implementation NSMutableString (RegexKitLiteAdditions)

// replaceOccurrencesOfRegex:

- (NSUInteger)replaceOccurrencesOfRegex:(NSString *)regex withString:(NSString *)replacement
{
  NSRange    searchRange   = NSMaxiumRange;
  NSUInteger replacedCount = 0;
  performRegexOp(self, _cmd, (RKLRegexOp)(RKLReplaceOp | RKLReplaceMutable), regex, 0, 0L, self, &searchRange, replacement, NULL, (void **)((void *)&replacedCount));
  return(replacedCount);
}

- (NSUInteger)replaceOccurrencesOfRegex:(NSString *)regex withString:(NSString *)replacement range:(NSRange)searchRange
{
  NSUInteger replacedCount = 0;
  performRegexOp(self, _cmd, (RKLRegexOp)(RKLReplaceOp | RKLReplaceMutable), regex, 0, 0L, self, &searchRange, replacement, NULL, (void **)((void *)&replacedCount));
  return(replacedCount);
}

- (NSUInteger)replaceOccurrencesOfRegex:(NSString *)regex withString:(NSString *)replacement options:(RKLRegexOptions)options range:(NSRange)searchRange error:(NSError **)error
{
  NSUInteger replacedCount = 0;
  performRegexOp(self, _cmd, (RKLRegexOp)(RKLReplaceOp | RKLReplaceMutable), regex, options, 0L, self, &searchRange, replacement, error, (void **)((void *)&replacedCount));
  return(replacedCount);
}

@end
