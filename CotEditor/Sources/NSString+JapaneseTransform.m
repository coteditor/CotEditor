/*
 ==============================================================================
 NSString+JapaneseTransform
 
 CotEditor
 http://coteditor.com
 
 Created on 2014-07-31 by 1024jp
 encoding="UTF-8"
 ------------------------------------------------------------------------------
 
 © 2014 CotEditor Project
 
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

#import "NSString+JapaneseTransform.h"


@implementation NSString (JapaneseTransform)

// ------------------------------------------------------
/// 半角Romanを全角Romanへ変換
- (NSString *)fullWidthRomanString
// ------------------------------------------------------
{
    NSMutableString *fullRoman = [NSMutableString string];
    NSCharacterSet *latinCharSet = [NSCharacterSet characterSetWithRange:NSMakeRange((NSUInteger)'!', 94)];
    NSUInteger count = [self length];
    
    for (NSUInteger i = 0; i < count; i++) {
        unichar theChar = [self characterAtIndex:i];
        if ([latinCharSet characterIsMember:theChar]) {
            [fullRoman appendString:[NSString stringWithFormat:@"%C", (unichar)(theChar + 65248)]];
//            // 半角カナには未対応
//        } else if ([hankakuKanaCharSet characterIsMember:theChar]) {
//            [fullRoman appendString:[NSString stringWithFormat:@"%C", (unichar)(theChar + 65248)]];
        } else {
            [fullRoman appendString:[self substringWithRange:NSMakeRange(i, 1)]];
        }
    }
    return fullRoman;
}


// ------------------------------------------------------
/// 全角Romanを半角Romanへ変換
- (NSString *)halfWidthRomanString
// ------------------------------------------------------
{
    NSMutableString *halfRoman = [NSMutableString string];
    NSCharacterSet *fullwidthCharSet = [NSCharacterSet characterSetWithRange:NSMakeRange(65281, 94)];
    NSUInteger count = [self length];
    
    for (NSUInteger i = 0; i < count; i++) {
        unichar theChar = [self characterAtIndex:i];
        if ([fullwidthCharSet characterIsMember:theChar]) {
            [halfRoman appendString:[NSString stringWithFormat:@"%C", (unichar)(theChar - 65248)]];
        } else {
            [halfRoman appendString:[self substringWithRange:NSMakeRange(i, 1)]];
        }
    }
    return halfRoman;
}


// ------------------------------------------------------
/// ひらがなをカタカナへ変換
- (NSString *)katakanaString
// ------------------------------------------------------
{
    NSMutableString* katakana = [self mutableCopy];
    
    CFStringTransform((CFMutableStringRef)katakana, NULL, kCFStringTransformHiraganaKatakana, false);
    
    return [katakana copy];
}


// ------------------------------------------------------
/// カタカナをひらがなへ変換
- (NSString *)hiraganaString
// ------------------------------------------------------
{
    NSMutableString* hiragana = [self mutableCopy];
    
    CFStringTransform((CFMutableStringRef)hiragana, NULL, kCFStringTransformHiraganaKatakana, true);
    
    return [hiragana copy];
}

@end
