/*
 
 NSString+ComposedCharacter.m
 
 CotEditor
 http://coteditor.com
 
 Created by 1024jp on 2014-05-04.
 
 ------------------------------------------------------------------------------
 
 © 2014 1024jp
 
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

#import "NSString+ComposedCharacter.h"


@implementation NSString (ComposedCharacter)

#pragma mark Public Methods

// ------------------------------------------------------
/// number of composed characters in the whole string
- (NSUInteger)numberOfComposedCharacters
// ------------------------------------------------------
{
    // normalize using NFC
    NSString *string = [self precomposedStringWithCanonicalMapping];
    
    // count composed chars
    __block NSUInteger count = 0;
    __block BOOL isRegionalIndicator = NO;
    NSRange regionalIndicatorRange = NSMakeRange(0xDDE6, 0xDDFF - 0xDDE6 + 1);
    [string enumerateSubstringsInRange:NSMakeRange(0, [string length])
                               options:NSStringEnumerationByComposedCharacterSequences | NSStringEnumerationSubstringNotRequired
                            usingBlock:^(NSString *substring, NSRange substringRange, NSRange enclosingRange, BOOL *stop)
     {
         // skip if the last composed character was a regional indicator surrogate-pair
         // 'Cause the so-called national flag emojis consist of two such surrogate pairs
         // and the first one is already counted in the last loop.
         // (To simplify the process, we don't check whether this character is also a regional indicator.)
         if (isRegionalIndicator) {
             isRegionalIndicator = NO;
             return;
         }
         
         // detect regional surrogate pair.
         if ((substringRange.length == 2) &&
             (NSLocationInRange([string characterAtIndex:substringRange.location + 1], regionalIndicatorRange)))
         {
             isRegionalIndicator = YES;
         }
         
         count++;
     }];
    
    return count;
}

@end
