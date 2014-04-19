/*
 =================================================
 CEUtilities
 (for CotEditor)
 
 Copyright (C) 2004-2007 nakamuxu.
 Copyright (C) 2014 CotEditor Project
 http://coteditor.github.io
 =================================================
 
 encoding="UTF-8"
 Created:2014-04-20
 
 -------------------------------------------------
 
 This program is free software; you can redistribute it and/or
 modify it under the terms of the GNU General Public License
 as published by the Free Software Foundation; either version 2
 of the License, or (at your option) any later version.
 
 This program is distributed in the hope that it will be useful,
 but WITHOUT ANY WARRANTY; without even the implied warranty of
 MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 GNU General Public License for more details.
 
 You should have received a copy of the GNU General Public License
 along with this program; if not, write to the Free Software
 Foundation, Inc., 59 Temple Place - Suite 330, Boston, MA  02111-1307, USA.
 
 
 =================================================
 */

#import "CEUtilities.h"
#import "constants.h"


@implementation CEUtilities

static NSArray *_invalidYenEncodings;


#pragma mark Superclass Class Methods

// ------------------------------------------------------
/// クラスの初期化
+ (void)initialize
// ------------------------------------------------------
{
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        NSMutableArray *encodings = [NSMutableArray array];
        for (NSUInteger i = 0; i < sizeof(k_CFStringEncodingInvalidYenList)/sizeof(CFStringEncodings); i++) {
            NSStringEncoding encoding = CFStringConvertEncodingToNSStringEncoding(k_CFStringEncodingInvalidYenList[i]);
            [encodings addObject:@(encoding)];
        }
        
        _invalidYenEncodings = [encodings copy];
    });
}



#pragma mark Public Class Methods

// ------------------------------------------------------
/// 非表示半角スペース表示用文字を返す
+ (NSString *)invisibleSpaceCharacter:(NSUInteger)index
// ------------------------------------------------------
{
    NSUInteger max = (sizeof(k_invisibleSpaceCharList) / sizeof(unichar)) - 1;
    NSUInteger sanitizedIndex = MIN(max, index);
    unichar theUnichar = k_invisibleSpaceCharList[sanitizedIndex];
    
    return [NSString stringWithCharacters:&theUnichar length:1];
}


// ------------------------------------------------------
/// 非表示タブ表示用文字を返す
+ (NSString *)invisibleTabCharacter:(NSUInteger)index
// ------------------------------------------------------
{
    NSUInteger max = (sizeof(k_invisibleTabCharList) / sizeof(unichar)) - 1;
    NSUInteger sanitizedIndex = MIN(max, index);
    unichar theUnichar = k_invisibleTabCharList[sanitizedIndex];
    
    return [NSString stringWithCharacters:&theUnichar length:1];
}


// ------------------------------------------------------
/// 非表示改行表示用文字を返す
+ (NSString *)invisibleNewLineCharacter:(NSUInteger)index
// ------------------------------------------------------
{
    NSUInteger max = (sizeof(k_invisibleNewLineCharList) / sizeof(unichar)) - 1;
    NSUInteger sanitizedIndex = MIN(max, index);
    unichar theUnichar = k_invisibleNewLineCharList[sanitizedIndex];
    
    return [NSString stringWithCharacters:&theUnichar length:1];
}


// ------------------------------------------------------
/// 非表示全角スペース表示用文字を返す
+ (NSString *)invisibleFullwidthSpaceCharacter:(NSUInteger)index
// ------------------------------------------------------
{
    NSUInteger max = (sizeof(k_invisibleFullwidthSpaceCharList) / sizeof(unichar)) - 1;
    NSUInteger sanitizedIndex = MIN(max, index);
    unichar theUnichar = k_invisibleFullwidthSpaceCharList[sanitizedIndex];
    
    return [NSString stringWithCharacters:&theUnichar length:1];
}


// ------------------------------------------------------
/// エンコーディング名からNSStringEncodingを返す
+ (NSStringEncoding)encodingFromName:(NSString *)encodingName
// ------------------------------------------------------
{
    NSArray *encodings = [[NSUserDefaults standardUserDefaults] arrayForKey:k_key_encodingList];
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
/// エンコーディング名からNSStringEncodingを返す
+ (BOOL)isInvalidYenEncoding:(NSStringEncoding)encoding
// ------------------------------------------------------
{
    return ([_invalidYenEncodings containsObject:@(encoding)]);
}


// ------------------------------------------------------
/// 文字列からキーボードショートカット定義を読み取る
+ (NSString *)keyEquivalentAndModifierMask:(NSUInteger *)modifierMask fromString:(NSString *)string includingCommandKey:(BOOL)isIncludingCommandKey
//------------------------------------------------------
{
    *modifierMask = 0;
    NSUInteger length = [string length];
    if ((string == nil) || (length < 2)) { return @""; }
    
    NSString *key = [string substringFromIndex:(length - 1)];
    NSCharacterSet *charSet = [NSCharacterSet characterSetWithCharactersInString:[string substringToIndex:(length - 1)]];
    
    if (isIncludingCommandKey) { // === Cmd 必須のとき
        if ([charSet characterIsMember:k_keySpecCharList[3]]) { // @
            if ([charSet characterIsMember:k_keySpecCharList[0]]) { // ^
                *modifierMask |= NSControlKeyMask;
            }
            if ([charSet characterIsMember:k_keySpecCharList[1]]) { // ~
                *modifierMask |= NSAlternateKeyMask;
            }
            if (([charSet characterIsMember:k_keySpecCharList[2]]) ||
                (isupper([key characterAtIndex:0]) == 1)) { // $
                *modifierMask |= NSShiftKeyMask;
            }
            *modifierMask |= NSCommandKeyMask;
        }
    } else {
        if ([charSet characterIsMember:k_keySpecCharList[0]]) {
            *modifierMask |= NSControlKeyMask;
        }
        if ([charSet characterIsMember:k_keySpecCharList[1]]) {
            *modifierMask |= NSAlternateKeyMask;
        }
        if ([charSet characterIsMember:k_keySpecCharList[2]]) {
            *modifierMask |= NSShiftKeyMask;
        }
        if ([charSet characterIsMember:k_keySpecCharList[3]]) {
            *modifierMask |= NSCommandKeyMask;
        }
    }
    
    return (modifierMask != 0) ? key : @"";
}

@end
