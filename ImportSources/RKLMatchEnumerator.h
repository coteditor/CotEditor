#import <Foundation/NSEnumerator.h>
#import <Foundation/NSString.h>
#import <stddef.h>

@interface NSString (RegexKitLiteEnumeratorAdditions)
- (NSEnumerator *)matchEnumeratorWithRegex:(NSString *)regex;
@end
