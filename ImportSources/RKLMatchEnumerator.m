#import <Foundation/NSArray.h>
#import <Foundation/NSRange.h>
#import "RegexKitLite.h"
#import "RKLMatchEnumerator.h"

@interface RKLMatchEnumerator : NSEnumerator {
  NSString   *string;
  NSString   *regex;
  NSUInteger  location;
}

- (id)initWithString:(NSString *)initString regex:(NSString *)initRegex;

@end

@implementation RKLMatchEnumerator

- (id)initWithString:(NSString *)initString regex:(NSString *)initRegex
{
  if((self = [self init]) == NULL) { return(NULL); }
  string = [initString copy];
  regex  = [initRegex copy];
  return(self);
}

- (id)nextObject
{
  if(location != NSNotFound) {
    NSRange searchRange  = NSMakeRange(location, [string length] - location);
    NSRange matchedRange = [string rangeOfRegex:regex inRange:searchRange];

    location = NSMaxRange(matchedRange) + ((matchedRange.length == 0) ? 1 : 0);

    if(matchedRange.location != NSNotFound) {
      return([string substringWithRange:matchedRange]);
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

- (NSEnumerator *)matchEnumeratorWithRegex:(NSString *)regex
{
  return([[[RKLMatchEnumerator alloc] initWithString:self regex:regex] autorelease]);
}

@end
