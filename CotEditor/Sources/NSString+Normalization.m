/*
 
 NSString+Normalization.m
 
 CotEditor
 http://coteditor.com
 
 Created by 1024jp on 2015-08-25.
 
 ------------------------------------------------------------------------------
 
 © 2015 1024jp
 © 2015 Yusuke Terada
 
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

#import "NSString+Normalization.h"
#import "icu/unorm2.h"
#import "icu/ustring.h"


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
    unsigned long length = strlen(utf8_src) * 256;
    
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
    
    NSString *result = [NSString stringWithUTF8String:utf8_dest];
    free(utf8_dest);
    
    return result;
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
    NSString *result = success ? [NSString stringWithUTF8String:destStr] : self;
    free(destStr);
    
    return result;
}

@end
