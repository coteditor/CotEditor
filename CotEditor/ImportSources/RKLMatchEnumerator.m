/*
    RegexKitLite-2.1/examples/RKLMatchEnumerator.m（BSDライセンス）を改造しています。
*/

#import <Foundation/NSArray.h>
#import <Foundation/NSRange.h>
#import "RegexKitLite.h"
#import "RKLMatchEnumerator.h"

@interface RKLMatchEnumerator : NSEnumerator {
  NSString   *string;
  NSString   *regex;
  NSUInteger  location;
  RKLRegexOptions _options;
}

- (id)initWithString:(NSString *)initString regex:(NSString *)initRegex;

// edited by nakamuxu for CotEditor.
// オプションを使えるメソッドを追加
// 2008.05.01.
- (id)initWithString:(NSString *)initString regex:(NSString *)initRegex options:(RKLRegexOptions)inOptions;

@end

@implementation RKLMatchEnumerator

- (id)initWithString:(NSString *)initString regex:(NSString *)initRegex
{
  if((self = [self init]) == NULL) { return(NULL); }
  string = [initString copy];
  regex  = [initRegex copy];
  return(self);
}

- (id)initWithString:(NSString *)initString regex:(NSString *)initRegex options:(RKLRegexOptions)inOptions
{
  if((self = [self init]) == NULL) { return(NULL); }
  string = [initString copy];
  regex  = [initRegex copy];
  _options = inOptions;
  return(self);
}

- (id)nextObject
// edited by nakamuxu for CotEditor.
// マッチした範囲のNSValueを返すように変更
// 2008.05.01.
{
  if(location != NSNotFound) {
    NSRange searchRange  = NSMakeRange(location, [string length] - location);
    NSRange matchedRange = [string rangeOfRegex:regex options:_options inRange:searchRange capture:0 error:NULL];

    location = NSMaxRange(matchedRange) + ((matchedRange.length == 0) ? 1 : 0);

    if(matchedRange.location != NSNotFound) {
        return [NSValue valueWithRange:matchedRange];
    }
  }
  return(NULL);
}

- (void) dealloc
{
  [string release];
  [regex release];
  [super dealloc];
}

@end

@implementation NSString (RegexKitLiteEnumeratorAdditions)

- (NSEnumerator *)matchEnumeratorWithRegex:(NSString *)regexString
{
  return([[[RKLMatchEnumerator alloc] initWithString:self regex:regexString] autorelease]);
}

// edited by nakamuxu for CotEditor.
// オプションを使えるメソッドを追加
// 2008.05.01.
- (NSEnumerator *)matchEnumeratorWithRegex:(NSString *)regexString options:(RKLRegexOptions)inOptions
{
  return([[[RKLMatchEnumerator alloc] initWithString:self regex:regexString options:inOptions] autorelease]);
}

@end
