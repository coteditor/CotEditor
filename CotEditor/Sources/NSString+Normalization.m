/*
 
 NSString+Normalization.m
 
 CotEditor
 http://coteditor.com
 
 Created by 1024jp on 2015-08-25.
 
 ------------------------------------------------------------------------------
 
 © 2015-2016 1024jp
 © 2015-2016 Yusuke Terada
 
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

@import ICU;

#import "NSString+Normalization.h"


static NSString * _Nonnull const COMPOSITION_EXCLUSION_CHARS = @"\\x{0340}\\x{0341}\\x{0343}\\x{0344}\\x{0374}\\x{037E}\\x{0387}\\x{0958}-\\x{095F}\\x{09DC}\\x{09DD}\\x{09DF}\\x{0A33}\\x{0A36}\\x{0A59}-\\x{0A5B}\\x{0A5E}\\x{0B5C}\\x{0B5D}\\x{0F43}\\x{0F4D}\\x{0F52}\\x{0F57}\\x{0F5C}\\x{0F69}\\x{0F73}\\x{0F75}\\x{0F76}\\x{0F78}\\x{0F81}\\x{0F93}\\x{0F9D}\\x{0FA2}\\x{0FA7}\\x{0FAC}\\x{0FB9}\\x{1F71}\\x{1F73}\\x{1F75}\\x{1F77}\\x{1F79}\\x{1F7B}\\x{1F7D}\\x{1FBB}\\x{1FBE}\\x{1FC9}\\x{1FCB}\\x{1FD3}\\x{1FDB}\\x{1FE3}\\x{1FEB}\\x{1FEE}\\x{1FEF}\\x{1FF9}\\x{1FFB}\\x{1FFD}\\x{2000}\\x{2001}\\x{2126}\\x{212A}\\x{212B}\\x{2329}\\x{232A}\\x{2ADC}\\x{F900}-\\x{FA0D}\\x{FA10}\\x{FA12}\\x{FA15}-\\x{FA1E}\\x{FA20}\\x{FA22}\\x{FA25}\\x{FA26}\\x{FA2A}-\\x{FA6D}\\x{FA70}-\\x{FAD9}\\x{FB1D}\\x{FB1F}\\x{FB2A}-\\x{FB36}\\x{FB38}-\\x{FB3C}\\x{FB3E}\\x{FB40}\\x{FB41}\\x{FB43}\\x{FB44}\\x{FB46}-\\x{FB4E}\\x{1D15E}-\\x{1D164}\\x{1D1BB}-\\x{1D1C0}\\x{2F800}-\\x{2FA1D}";


@implementation NSString (Normalization)

// ------------------------------------------------------
/// A string made by normalizing the receiver’s contents using the Unicode Normalization Form KC with Casefold
- (nonnull NSString *)precomposedStringWithCompatibilityMappingWithCasefold
// ------------------------------------------------------
{
    UErrorCode error = U_ZERO_ERROR;
    
    const UNormalizer2 *normalizer = unorm2_getInstance(NULL, "nfkc_cf", UNORM2_COMPOSE, &error);
    
    if (U_FAILURE(error)) {
        NSLog(@"unorm2_getInstance failed - %s", u_errorName(error));
        return [self copy];
    }
    
    const char *utf8_src = [self UTF8String];
    int32_t length = (int32_t)strlen(utf8_src) * 256;
    
    UChar *utf16_src = (UChar*)malloc(sizeof(UChar) * length);
    u_strFromUTF8(utf16_src, length, NULL, utf8_src, -1, &error);
    
    if (U_FAILURE(error)) {
        NSLog(@"u_strFromUTF8 failed - %s", u_errorName(error));
        free(utf16_src);
        return [self copy];
    }
    
    UChar *utf16_dest = (UChar*)malloc(sizeof(UChar) * length);
    unorm2_normalize(normalizer, utf16_src, -1, utf16_dest, length, &error);
    free(utf16_src);
    
    if (U_FAILURE(error)) {
        NSLog(@"unorm2_normalize failed - %s", u_errorName(error));
        free(utf16_dest);
        return [self copy];
    }
    
    char *utf8_dest = (char*)malloc(sizeof(char) * length);
    u_strToUTF8(utf8_dest, length, NULL, utf16_dest, -1, &error);
    free(utf16_dest);
    
    if (U_FAILURE(error)) {
        NSLog(@"u_strToUTF8 failed - %s", u_errorName(error));
        free(utf8_dest);
        return [self copy];
    }
    
    NSString *result = @(utf8_dest);
    free(utf8_dest);
    
    return result;
}


// ------------------------------------------------------
/// A string made by normalizing the receiver’s contents using the normalization form adopted by HFS+, a.k.a. Apple Modified NFC
- (nonnull NSString *)precomposedStringWithHFSPlusMapping
// ------------------------------------------------------
{
    NSMutableString *result = [NSMutableString string];
    __block BOOL composed = NO;
    
    NSString *pattern = [NSString stringWithFormat:@"([%@]*)([^%@]+)([%@]*)",
                         COMPOSITION_EXCLUSION_CHARS, COMPOSITION_EXCLUSION_CHARS, COMPOSITION_EXCLUSION_CHARS];
    NSRegularExpression *regex = [NSRegularExpression regularExpressionWithPattern:pattern options:0 error:nil];
    
    __weak typeof(self) weakSelf = self;
    [regex enumerateMatchesInString:self options:0
                              range:NSMakeRange(0, [self length])
                         usingBlock:^(NSTextCheckingResult * _Nullable match, NSMatchingFlags flags, BOOL * _Nonnull stop)
     {
         typeof(self) self = weakSelf;
         
         [result appendFormat:@"%@%@%@",
          [self substringWithRange:[match rangeAtIndex:1]],
          [[self substringWithRange:[match rangeAtIndex:2]] precomposedStringWithCanonicalMapping],
          [self substringWithRange:[match rangeAtIndex:3]]];
         
         composed = YES;
     }];
    
    if (!composed) {
        return [self copy];
    }
    
    return [NSString stringWithString:result];
}


// ------------------------------------------------------
/// A string made by normalizing the receiver’s contents using the normalization form adopted by HFS+, a.k.a. Apple Modified NFD
- (nonnull NSString *)decomposedStringWithHFSPlusMapping
// ------------------------------------------------------
{
    CFStringRef sourceStr = (__bridge CFStringRef)self;
    CFIndex length = CFStringGetMaximumSizeOfFileSystemRepresentation(sourceStr);
    char *destStr = (char *)malloc(length);
    
    Boolean success = CFStringGetFileSystemRepresentation(sourceStr, destStr, length);
    NSString *result = success ? @(destStr) : self;
    free(destStr);
    
    return result;
}

@end
