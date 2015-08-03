/*
 
 CEUtils.m
 
 CotEditor
 http://coteditor.com
 
 Created by nakamuxu on 2014-04-20.
 
 ------------------------------------------------------------------------------
 
 © 2004-2007 nakamuxu
 © 2014-2015 1024jp
 
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

#import "CEUtils.h"
#import "Constants.h"


@implementation CEUtils

static const NSArray *invalidYenEncodings;


#pragma mark Superclass Methods

// ------------------------------------------------------
/// initialize class
+ (void)initialize
// ------------------------------------------------------
{
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        NSMutableArray *encodings = [NSMutableArray arrayWithCapacity:kSizeOfCFStringEncodingInvalidYenList];
        for (NSUInteger i = 0; i < kSizeOfCFStringEncodingInvalidYenList; i++) {
            NSStringEncoding encoding = CFStringConvertEncodingToNSStringEncoding(kCFStringEncodingInvalidYenList[i]);
            [encodings addObject:@(encoding)];
        }
        
        invalidYenEncodings = [encodings copy];
    });
}



#pragma mark Public Methods

// ------------------------------------------------------
/// returns substitute character for invisible space
+ (unichar)invisibleSpaceChar:(NSUInteger)index
// ------------------------------------------------------
{
    NSUInteger max = kSizeOfInvisibleSpaceCharList - 1;
    NSUInteger sanitizedIndex = MIN(max, index);
    
    return kInvisibleSpaceCharList[sanitizedIndex];
}


// ------------------------------------------------------
/// returns substitute character for invisible tab character
+ (unichar)invisibleTabChar:(NSUInteger)index
// ------------------------------------------------------
{
    NSUInteger max = kSizeOfInvisibleTabCharList - 1;
    NSUInteger sanitizedIndex = MIN(max, index);
    
    return kInvisibleTabCharList[sanitizedIndex];
}


// ------------------------------------------------------
/// returns substitute character for invisible new line character
+ (unichar)invisibleNewLineChar:(NSUInteger)index
// ------------------------------------------------------
{
    NSUInteger max = kSizeOfInvisibleNewLineCharList - 1;
    NSUInteger sanitizedIndex = MIN(max, index);
    
    return kInvisibleNewLineCharList[sanitizedIndex];
}


// ------------------------------------------------------
/// returns substitute character for invisible full-width space
+ (unichar)invisibleFullwidthSpaceChar:(NSUInteger)index
// ------------------------------------------------------
{
    NSUInteger max = kSizeOfInvisibleFullwidthSpaceCharList - 1;
    NSUInteger sanitizedIndex = MIN(max, index);
    
    return kInvisibleFullwidthSpaceCharList[sanitizedIndex];
}


// ------------------------------------------------------
/// returns corresponding NSStringEncoding from a encoding name
+ (NSStringEncoding)encodingFromName:(nonnull NSString *)encodingName
// ------------------------------------------------------
{
    NSArray *encodings = [[NSUserDefaults standardUserDefaults] arrayForKey:CEDefaultEncodingListKey];
    NSStringEncoding encoding;
    BOOL isValid = NO;
    
    for (NSNumber __strong *encodingNumber in encodings) {
        CFStringEncoding cfEncoding = [encodingNumber unsignedLongValue];
        if (cfEncoding != kCFStringEncodingInvalidId) { // = separator
            encoding = CFStringConvertEncodingToNSStringEncoding(cfEncoding);
            if ([encodingName isEqualToString:[NSString localizedNameOfStringEncoding:encoding]]) {
                isValid = YES;
                break;
            }
        }
    }
    return (isValid) ? encoding : NSNotFound;
}


// ------------------------------------------------------
/// whether Yen sign (U+00A5) can be converted to the given encoding
+ (BOOL)isInvalidYenEncoding:(NSStringEncoding)encoding
// ------------------------------------------------------
{
    return [invalidYenEncodings containsObject:@(encoding)];
}


// ------------------------------------------------------
/// returns string form keyEquivalent (keyboard shortcut) for menu item
+ (nonnull NSString *)keyEquivalentAndModifierMask:(nonnull NSUInteger *)modifierMask fromString:(nonnull NSString *)string includingCommandKey:(BOOL)needsIncludingCommandKey
//------------------------------------------------------
{
    *modifierMask = 0;
    NSUInteger length = [string length];
    
    if (length < 2) { return @""; }
    
    NSString *key = [string substringFromIndex:(length - 1)];
    NSCharacterSet *modCharSet = [NSCharacterSet characterSetWithCharactersInString:[string substringToIndex:(length - 1)]];
    
    if ([modCharSet characterIsMember:kKeySpecCharList[CEControlKeyIndex]]) {
        *modifierMask |= NSControlKeyMask;
    }
    if ([modCharSet characterIsMember:kKeySpecCharList[CEAlternateKeyIndex]]) {
        *modifierMask |= NSAlternateKeyMask;
    }
    if (([modCharSet characterIsMember:kKeySpecCharList[CEShiftKeyIndex]]) ||  // $
        (isupper([key characterAtIndex:0]) == 1))
    {
        *modifierMask |= NSShiftKeyMask;
    }
    if ([modCharSet characterIsMember:kKeySpecCharList[CECommandKeyIndex]]) {
        *modifierMask |= NSCommandKeyMask;
    }
    
    if (needsIncludingCommandKey && !(*modifierMask & NSCommandKeyMask)) {
        *modifierMask = 0;
        return @"";
    }
    
    return (*modifierMask != 0) ? key : @"";
}

@end
