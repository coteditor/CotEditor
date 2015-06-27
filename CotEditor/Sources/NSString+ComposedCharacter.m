/*
 ==============================================================================
 NSString+ComposedCharacter
 
 CotEditor
 http://coteditor.com
 
 Created on 2014-05-04 by 1024jp
 encoding="UTF-8"
 ------------------------------------------------------------------------------
 
 © 2014 1024jp
 
 This program is free software; you can redistribute it and/or modify it under
 the terms of the GNU General Public License as published by the Free Software
 Foundation; either version 2 of the License, or (at your option) any later
 version.
 
 This program is distributed in the hope that it will be useful, but WITHOUT
 ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS
 FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.
 
 You should have received a copy of the GNU General Public License along with
 this program; if not, write to the Free Software Foundation, Inc., 59 Temple
 Place - Suite 330, Boston, MA  02111-1307, USA.
 
 ==============================================================================
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
