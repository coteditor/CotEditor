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
const char kUTF8Bom[3] = {0xEF, 0xBB, 0xBF};
const char kUTF16BEBom[2] = {0xFE, 0xFF};
const char kUTF16LEBom[2] = {0xFF, 0xFE};
const char kUTF32BEBom[4] = {0x00, 0x00, 0xFE, 0xFF};
const char kUTF32LEBom[4] = {0xFF, 0xFE, 0x00, 0x00};

static const NSUInteger kMaxDetectionLength = 1024 * 8;


@implementation NSString (CEEncoding)

#pragma mark Public Methods

//------------------------------------------------------
/// obtain string from NSData with intelligent encoding detection
- (nullable instancetype)initWithData:(nonnull NSData *)data suggestedCFEncodings:(NSArray<NSNumber *> *)suggestedCFEncodings usedEncoding:(nonnull NSStringEncoding *)usedEncoding error:(NSError * _Nullable __autoreleasing * _Nullable)outError
//------------------------------------------------------
{
    // detect enoding from so-called "magic numbers"
    NSStringEncoding triedEncoding = NSNotFound;
    if ([data length] > 1) {
        char miniBytes[4] = {0};
        [data getBytes:&miniBytes length:4];
        
        NSRange detectionRange = NSMakeRange(0, MIN([data length], kMaxDetectionLength));
        
        // check UTF-8 BOM
        if (!memcmp(miniBytes, kUTF8Bom, 3)) {
            NSStringEncoding encoding = NSUTF8StringEncoding;
            triedEncoding = encoding;
            NSString *string = [self initWithData:data encoding:encoding];
            if (string) {
                *usedEncoding = encoding;
                return string;
            }
            
        // check UTF-32 BOM
        } else if (!memcmp(miniBytes, kUTF32BEBom, 4) || !memcmp(miniBytes, kUTF32LEBom, 4)) {
            NSStringEncoding encoding = NSUTF32StringEncoding;
            triedEncoding = encoding;
            NSString *string = [self initWithData:data encoding:encoding];
            if (string) {
                *usedEncoding = encoding;
                return string;
            }
            
        // check UTF-16 BOM
        } else if (!memcmp(miniBytes, kUTF16BEBom, 2) || !memcmp(miniBytes, kUTF16LEBom, 2)) {
            NSStringEncoding encoding = NSUTF16StringEncoding;
            triedEncoding = encoding;
            NSString *string = [self initWithData:data encoding:encoding];
            if (string) {
                *usedEncoding = encoding;
                return string;
            }
            
        // test ISO-2022-JP
        } else if (memchr([data bytes], 0x1b, detectionRange.length) != NULL) {
            NSStringEncoding encoding = NSISO2022JPStringEncoding;
            triedEncoding = encoding;
            
            // check existance of typical escape sequences
            // -> It's not perfect yet works in most cases. (2016-01 by 1024p)
            BOOL found = NO;
            NSArray<NSData *> *escapeSequences = @[[NSData dataWithBytes:"\x1B\x28\x42" length:3],  // ASCII
                                                   [NSData dataWithBytes:"\x1B\x28\x49" length:3],  // kana
                                                   [NSData dataWithBytes:"\x1b\x24\x40" length:3],  // 1978
                                                   [NSData dataWithBytes:"\x1b\x24\x42" length:3],  // 1983
                                                   [NSData dataWithBytes:"\x1b\x24\x28\x44" length:4]];  // JISX0212
            for (NSData *escapeSequence in escapeSequences) {
                if ([data rangeOfData:escapeSequence options:0 range:detectionRange].location != NSNotFound) {
                    found = YES;
                    break;
                }
            }
            
            if (found) {
                NSString *string = [self initWithData:data encoding:encoding];
                if (string) {
                    *usedEncoding = encoding;
                    return string;
                }
            }
        }
    }
    
    // try encodings in order from the top of the encoding list
    for (NSNumber *encodingNumber in suggestedCFEncodings) {
        CFStringEncoding cfEncoding = (CFStringEncoding)[encodingNumber unsignedIntegerValue];
        if (cfEncoding == kCFStringEncodingInvalidId) { continue; }
        
        NSStringEncoding encoding = CFStringConvertEncodingToNSStringEncoding(cfEncoding);
        
        // skip encoding already tried above
        if (encoding == triedEncoding) { continue; }
        
        NSString *string = [[NSString alloc] initWithData:data encoding:encoding];
        if (string) {
            *usedEncoding = encoding;
            return string;
        }
    }
    
    if (outError) {
        *outError = [NSError errorWithDomain:NSCocoaErrorDomain code:NSFileReadUnknownStringEncodingError userInfo:nil];
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
            CFStringEncoding tmpCFEncoding = (CFStringEncoding)[encodingNumber unsignedLongValue];
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
