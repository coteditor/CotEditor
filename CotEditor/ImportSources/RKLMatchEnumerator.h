/*
    RegexKitLite-2.1/examples/RKLMatchEnumerator.h（BSDライセンス）を改造しています。
*/
#import <Foundation/NSEnumerator.h>
#import <Foundation/NSString.h>
#import <stddef.h>

@interface NSString (RegexKitLiteEnumeratorAdditions)
- (NSEnumerator *)matchEnumeratorWithRegex:(NSString *)regexString;
// edited by nakamuxu for CotEditor.
// オプションを使えるメソッドを追加
// 2008.05.01.
- (NSEnumerator *)matchEnumeratorWithRegex:(NSString *)regexString options:(RKLRegexOptions)inOptions;
@end
