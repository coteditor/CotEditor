/*
 
 NSString+CECounting.m
 
 CotEditor
 http://coteditor.com
 
 Created by 1024jp on 2014-05-04.
 
 ------------------------------------------------------------------------------
 
 © 2014-2016 1024jp
 
 Licensed under the Apache License, Version 2.0 (the "License");
 you may not use this file except in compliance with the License.
 You may obtain a copy of the License at
 
 http://www.apache.org/licenses/LICENSE-2.0
 
 Unless required by applicable law or agreed to in writing, software
 distributed under the License is distributed on an "AS IS" BASIS,
 WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 See the License for the specific language governing permissions and
 limitations under the License.
 
 */

#import "NSString+CECounting.h"


@implementation NSString (CECounting)

#pragma mark Public Methods

// ------------------------------------------------------
/// number of composed characters in the whole string
- (NSUInteger)numberOfComposedCharacters
// ------------------------------------------------------
{
    if ([self length] == 0) { return 0; }
    
    // normalize using NFC
    NSString *string = [self precomposedStringWithCanonicalMapping];
    
    // count composed chars
    __block NSUInteger count = 0;
    __block BOOL isLastCharRegionalIndicator = NO;
    NSRange regionalIndicatorRange = NSMakeRange(0xDDE6, 0xDDFF - 0xDDE6 + 1);
    [string enumerateSubstringsInRange:NSMakeRange(0, [string length])
                               options:NSStringEnumerationByComposedCharacterSequences | NSStringEnumerationSubstringNotRequired
                            usingBlock:^(NSString *substring, NSRange substringRange, NSRange enclosingRange, BOOL *stop)
     {
         // detect regional indicator surrogate pair.
         BOOL isRegionalIndicator = ((substringRange.length == 2) &&
                                     [string characterAtIndex:substringRange.location] == 0xD83C &&
                                     NSLocationInRange([string characterAtIndex:substringRange.location + 1], regionalIndicatorRange));
         
         // skip if the last composed character was a regional indicator surrogate-pair
         // -> 'Cause the so-called national flag emojis consist of two such surrogate pairs
         //    and the first one is already counted in the last loop.
         if (isLastCharRegionalIndicator) {
             isLastCharRegionalIndicator = NO;
             if (isRegionalIndicator) {
                 return;
             }
         } else if (isRegionalIndicator) {
             isLastCharRegionalIndicator = YES;
         }
         
         count++;
     }];
    
    return count;
}


// ------------------------------------------------------
/// number of words in the whole string
- (NSUInteger)numberOfWords
// ------------------------------------------------------
{
    if ([self length] == 0) { return 0; }
    
    CFStringTokenizerRef tokenizer = CFStringTokenizerCreate(NULL, (CFStringRef)self, CFRangeMake(0, [self length]), kCFStringTokenizerUnitWord, NULL);
    
    NSUInteger count = 0;
    while (CFStringTokenizerAdvanceToNextToken(tokenizer) != kCFStringTokenizerTokenNone) {
        count++;
    }
    
    CFRelease(tokenizer);
    
    return count;
}


// ------------------------------------------------------
/// Return the number of lines in the range.
- (NSUInteger)numberOfLinesInRange:(NSRange)range includingLastNewLine:(BOOL)includingLastNewLine
// ------------------------------------------------------
{
    if ([self length] == 0 || range.length == 0) { return 0; }
    
    __block NSUInteger count = 0;
    
    [self enumerateSubstringsInRange:range
                             options:NSStringEnumerationByLines | NSStringEnumerationSubstringNotRequired
                          usingBlock:^(NSString * _Nullable substring, NSRange substringRange, NSRange enclosingRange, BOOL * _Nonnull stop)
     {
         count++;
     }];
    
    if (includingLastNewLine && [[NSCharacterSet newlineCharacterSet] characterIsMember:[self characterAtIndex:NSMaxRange(range) - 1]]) {
        count++;
    }
    
    return count;
}


// ------------------------------------------------------
/// Return the number of lines in the whole string ignoring the last new line character.
- (NSUInteger)numberOfLines
// ------------------------------------------------------
{
    return [self numberOfLinesInRange:NSMakeRange(0, [self length]) includingLastNewLine:NO];
}


// ------------------------------------------------------
/// Return the number of lines at the character index (1-based).
- (NSUInteger)lineNumberAtIndex:(NSUInteger)index
// ------------------------------------------------------
{
    if ([self length] == 0 || index == 0) { return 1; }
    
    NSUInteger number = [self numberOfLinesInRange:NSMakeRange(0, index) includingLastNewLine:YES];
    
    return number;
}

@end
