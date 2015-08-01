/*

 NSString+JapaneseTransform.m
 
 CotEditor
 http://coteditor.com
 
 Created by 1024jp on 2014-07-31.
 
 ------------------------------------------------------------------------------
 
 © 2014-1025 1024jp
 
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

#import "NSString+JapaneseTransform.h"


@implementation NSString (JapaneseTransform)

#pragma mark Public Methods

// ------------------------------------------------------
/// transform half-width roman to full-width
- (nonnull NSString *)fullWidthRomanString
// ------------------------------------------------------
{
    NSMutableString *string = [NSMutableString string];
    NSCharacterSet *latinCharSet = [NSCharacterSet characterSetWithRange:NSMakeRange('!', 94)];
    NSUInteger count = [self length];
    
    for (NSUInteger i = 0; i < count; i++) {
        unichar character = [self characterAtIndex:i];
        if ([latinCharSet characterIsMember:character]) {
            character += 65248;
        }
        [string appendFormat:@"%C", character];
    }
    return [string copy];
}


// ------------------------------------------------------
/// transform full-width roman to half-width
- (nonnull NSString *)halfWidthRomanString
// ------------------------------------------------------
{
    NSMutableString *string = [NSMutableString string];
    NSCharacterSet *fullwidthCharSet = [NSCharacterSet characterSetWithRange:NSMakeRange(65281, 94)];
    NSUInteger count = [self length];
    
    for (NSUInteger i = 0; i < count; i++) {
        unichar character = [self characterAtIndex:i];
        if ([fullwidthCharSet characterIsMember:character]) {
            character -= 65248;
        }
        [string appendFormat:@"%C", character];
    }
    return [string copy];
}


// ------------------------------------------------------
/// transform Japanese Katakana to Hiragana
- (nonnull NSString *)katakanaString
// ------------------------------------------------------
{
    NSMutableString* string = [self mutableCopy];
    
    CFStringTransform((CFMutableStringRef)string, NULL, kCFStringTransformHiraganaKatakana, false);
    
    return [string copy];
}


// ------------------------------------------------------
/// transform Japanese Hiragana to Katakana
- (nonnull NSString *)hiraganaString
// ------------------------------------------------------
{
    NSMutableString* string = [self mutableCopy];
    
    CFStringTransform((CFMutableStringRef)string, NULL, kCFStringTransformHiraganaKatakana, true);
    
    return [string copy];
}

@end
