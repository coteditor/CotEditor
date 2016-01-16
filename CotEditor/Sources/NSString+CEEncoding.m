/*
 
 NSString+CEEncodings.m
 
 CotEditor
 http://coteditor.com
 
 Created by 1024jp on 2016-01-16.
 
 ------------------------------------------------------------------------------
 
 © 2004-2007 nakamuxu
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

#import "NSString+CEEncoding.h"


// byte order marks
char const kUTF8Bom[] = {0xEF, 0xBB, 0xBF};
char const kUTF16BEBom[] = {0xFE, 0xFF};
char const kUTF16LEBom[] = {0xFF, 0xFE};
char const kUTF32BEBom[] = {0x00, 0x00, 0xFE, 0xFF};
char const kUTF32LEBom[] = {0xFF, 0xFE, 0x00, 0x00};


@implementation NSString (CEEncoding)

#pragma mark Public Methods

//------------------------------------------------------
/// obtain string from NSData with intelligent encoding detection
- (nullable instancetype)initWithData:(nonnull NSData *)data suggestedCFEncodings:(NSArray<NSNumber *> *)suggestedCFEncodings usedEncoding:(nonnull NSStringEncoding *)usedEncoding error:(NSError * _Nullable __autoreleasing * _Nullable)outError
//------------------------------------------------------
{
    // detect enoding from so-called "magic numbers"
    NSStringEncoding triedEncoding = NSNotFound;
    if ([data length] > 0) {
        // ISO 2022-JP / UTF-8 / UTF-16の判定は、「藤棚工房別棟 −徒然−」の
        // 「Cocoaで文字エンコーディングの自動判別プログラムを書いてみました」で公開されている
        // FJDDetectEncoding を参考にさせていただきました (2006-09-30)
        // http://blogs.dion.ne.jp/fujidana/archives/4169016.html
        
        // test UTF-8 with BOM
        if (memchr([data bytes], *kUTF8Bom, 3) != NULL) {
            NSStringEncoding encoding = NSUTF8StringEncoding;
            triedEncoding = encoding;
            NSString *string = [self initWithData:data encoding:encoding];
            if (string) {
                *usedEncoding = encoding;
                return string;
            }
            
            // test UTF-32
        } else if ((memchr([data bytes], *kUTF32BEBom, 4) != NULL) ||
                   (memchr([data bytes], *kUTF32LEBom, 4) != NULL))
        {
            NSStringEncoding encoding = NSUTF32StringEncoding;
            triedEncoding = encoding;
            NSString *string = [self initWithData:data encoding:encoding];
            if (string) {
                *usedEncoding = encoding;
                return string;
            }
            
            // test UTF-16
        } else if ((memchr([data bytes], *kUTF16BEBom, 2) != NULL) ||
                   (memchr([data bytes], *kUTF16LEBom, 2) != NULL))
        {
            NSStringEncoding encoding = NSUTF16StringEncoding;
            triedEncoding = encoding;
            NSString *string = [self initWithData:data encoding:encoding];
            if (string) {
                *usedEncoding = encoding;
                return string;
            }
            
            // test ISO-2022-JP
        } else if (memchr([data bytes], 0x1b, [data length]) != NULL) {
            NSStringEncoding encoding = NSISO2022JPStringEncoding;
            NSString *string = [self initWithData:data encoding:encoding];
            
            if (string) {
                // Since ISO-2022-JP is a Japanese encoding, string should have at least one Japanese character.
                NSRegularExpression *japaneseRegex = [NSRegularExpression regularExpressionWithPattern:@"[ぁ-んァ-ン、。]" options:0 error:nil];
                if ([japaneseRegex rangeOfFirstMatchInString:string options:0 range:NSMakeRange(0, [string length])].location != NSNotFound) {
                    *usedEncoding = encoding;
                    return string;
                };
            }
        }
    }
    
    // try encodings in order from the top of the encoding list
    for (NSNumber *encodingNumber in suggestedCFEncodings) {
        NSStringEncoding encoding = CFStringConvertEncodingToNSStringEncoding([encodingNumber unsignedIntegerValue]);
        
        // skip encoding already tried
        if (triedEncoding == encoding) { continue; }
        
        NSString *string = [self initWithData:data encoding:encoding];
        
        if (string) {
            *usedEncoding = encoding;
            return string;
        }
    }
    
    *usedEncoding = NSNotFound;
    return nil;
}


//------------------------------------------------------
/// scan encoding declaration in string
- (NSStringEncoding)scanEncodingDeclarationForTags:(nonnull NSArray<NSString *> *)tags upToIndex:(NSUInteger)maxLength suggestedCFEncodings:(nonnull NSArray<NSNumber *> *)suggestedCFEncodings
//------------------------------------------------------
{
    if ([self length] < 2) { return NSNotFound; }
    
    // This method is based on Smultron's SMLTextPerformer.m by Peter Borg. (2005-08-10)
    // Smultron 2 was distributed on <http://smultron.sourceforge.net> under the terms of the BSD license.
    // Copyright (c) 2004-2006 Peter Borg
    
    NSString *stringToScan = ([self length] > maxLength) ? [self substringToIndex:maxLength] : self;
    NSScanner *scanner = [NSScanner scannerWithString:stringToScan];  // scan only the beginning of string
    NSCharacterSet *stopSet = [NSCharacterSet characterSetWithCharactersInString:@"\"\' </>\n\r"];
    NSString *scannedStr = nil;
    
    [scanner setCharactersToBeSkipped:[NSCharacterSet characterSetWithCharactersInString:@"\"\' "]];
    
    // find encoding with tag in order
    for (NSString *tag in tags) {
        [scanner setScanLocation:0];
        while (![scanner isAtEnd]) {
            [scanner scanUpToString:tag intoString:nil];
            if ([scanner scanString:tag intoString:nil]) {
                if ([scanner scanUpToCharactersFromSet:stopSet intoString:&scannedStr]) {
                    break;
                }
            }
        }
        
        if (scannedStr) { break; }
    }
    
    if (!scannedStr) { return NSNotFound; }
    
    // 見つかったら NSStringEncoding に変換して返す
    CFStringEncoding cfEncoding = kCFStringEncodingInvalidId;
    // "Shift_JIS" だったら、kCFStringEncodingShiftJIS と kCFStringEncodingShiftJIS_X0213 の優先順位の高いものを取得する
    // -> scannedStr をそのまま CFStringConvertIANACharSetNameToEncoding() で変換すると、大文字小文字を問わず
    //   「日本語（Shift JIS）」になってしまうため。IANA では大文字小文字を区別しないとしているのでこれはいいのだが、
    //    CFStringConvertEncodingToIANACharSetName() では kCFStringEncodingShiftJIS と
    //    kCFStringEncodingShiftJIS_X0213 がそれぞれ「SHIFT_JIS」「shift_JIS」と変換されるため、可逆性を持たせるための処理
    if ([[scannedStr uppercaseString] isEqualToString:@"SHIFT_JIS"]) {
        for (NSNumber *encodingNumber in suggestedCFEncodings) {
            CFStringEncoding tmpCFEncoding = [encodingNumber unsignedLongValue];
            if ((tmpCFEncoding == kCFStringEncodingShiftJIS) || (tmpCFEncoding == kCFStringEncodingShiftJIS_X0213))
            {
                cfEncoding = tmpCFEncoding;
                break;
            }
        }
    } else {
        // "Shift_JIS" 以外はそのまま変換する
        cfEncoding = CFStringConvertIANACharSetNameToEncoding((CFStringRef)scannedStr);
    }
    
    if (cfEncoding == kCFStringEncodingInvalidId) { return NSNotFound; }
    
    return CFStringConvertEncodingToNSStringEncoding(cfEncoding);
}


//------------------------------------------------------
/// check IANA charset compatibility considering SHIFT_JIS
BOOL CEIsCompatibleIANACharSetEncoding(NSStringEncoding IANACharsetEncoding, NSStringEncoding encoding)
//------------------------------------------------------
{
    if (IANACharsetEncoding == encoding) { return YES; }
    
    // -> Caution needed on Shift-JIS. See `scanEncodingDeclarationForTags:` for details.
    const NSStringEncoding ShiftJIS = CFStringConvertEncodingToNSStringEncoding(kCFStringEncodingShiftJIS);
    const NSStringEncoding ShiftJIS_X0213 = CFStringConvertEncodingToNSStringEncoding(kCFStringEncodingShiftJIS_X0213);
    
    return ((encoding == ShiftJIS && IANACharsetEncoding == ShiftJIS_X0213) ||
            (encoding == ShiftJIS_X0213 && IANACharsetEncoding == ShiftJIS));
}

@end
