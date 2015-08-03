/*
 
 NSURL+AppleTextEncoding.m
 
 CotEditor
 http://coteditor.com
 
 Created by 1024jp on 2015-01-25.
 
 ------------------------------------------------------------------------------
 
 © 2015 1024jp
 
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

#import "NSURL+AppleTextEncoding.h"
#import <sys/xattr.h>


// constants
static char const XATTR_ENCODING_NAME[] = "com.apple.TextEncoding";


@implementation NSURL (AppleTextEncoding)

// ------------------------------------------------------
/// read text encoding from `com.apple.TextEncoding` extended attribute of the file at URL
- (NSStringEncoding)getAppleTextEncoding
// ------------------------------------------------------
{
    // check buffer size
    const char *path = [[self path] UTF8String];
    ssize_t bufferSize = getxattr(path, XATTR_ENCODING_NAME, NULL, 0, 0, XATTR_NOFOLLOW);
    
    if (bufferSize <= 0) { return NSNotFound; }
    
    // get xattr data
    NSMutableData *data = [NSMutableData dataWithLength:bufferSize];
    getxattr(path, XATTR_ENCODING_NAME, [data mutableBytes], [data length], 0, XATTR_NOFOLLOW);
    
    // parse value
    CFStringEncoding cfEncoding = kCFStringEncodingInvalidId;
    NSString *string = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
    NSArray *strings = [string componentsSeparatedByString:@";"];
    
    if ([strings count] >= 2) {
        cfEncoding = [strings[1] integerValue];
    } else if ([strings firstObject]) {
        NSString *IANACharSetName = [strings firstObject];
        cfEncoding = CFStringConvertIANACharSetNameToEncoding((CFStringRef)IANACharSetName);
    }
    
    if (cfEncoding == kCFStringEncodingInvalidId) { return NSNotFound; }
    
    return CFStringConvertEncodingToNSStringEncoding(cfEncoding);
}


// ------------------------------------------------------
/// write `com.apple.TextEncoding` extended attribute to the file at URL
- (void)setAppleTextEncoding:(NSStringEncoding)encoding
// ------------------------------------------------------
{
    CFStringEncoding cfEncoding = CFStringConvertNSStringEncodingToEncoding(encoding);
    
    if (cfEncoding == kCFStringEncodingInvalidId) { return; }
    
    NSString *IANACharSetName = (NSString *)CFStringConvertEncodingToIANACharSetName(cfEncoding);
    NSString *string = [NSString stringWithFormat:@"%@;%u", IANACharSetName, cfEncoding];
    NSData *data = [string dataUsingEncoding:NSUTF8StringEncoding];
    
    if (!data) { return; }
    
    setxattr([[self path] UTF8String], XATTR_ENCODING_NAME, [data bytes], [data length], 0, XATTR_NOFOLLOW);
}

@end
