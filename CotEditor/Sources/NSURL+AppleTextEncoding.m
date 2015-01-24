/*
 ==============================================================================
 NSURL+AppleTextEncoding
 
 CotEditor
 http://coteditor.com
 
 Created on 2015-01-25 by 1024jp
 encoding="UTF-8"
 ------------------------------------------------------------------------------
 
 © 2015 1024jp
 
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

#import "NSURL+AppleTextEncoding.h"
#import <sys/xattr.h>


// constants
static char const XATTR_ENCODING_NAME[] = "com.apple.TextEncoding";


@implementation NSURL (AppleTextEncoding)

// ------------------------------------------------------
/// read text encoding from the `com.apple.TextEncoding` extended attribute of the file at URL
- (NSStringEncoding)getAppleTextEncoding
// ------------------------------------------------------
{
    // get xattr data
    NSMutableData* data = nil;
    const char *path = [self fileSystemRepresentation];
    ssize_t bufferSize = getxattr(path, XATTR_ENCODING_NAME, NULL, 0, 0, XATTR_NOFOLLOW);
    if (bufferSize > 0) {
        data = [NSMutableData dataWithLength:bufferSize];
        getxattr(path, XATTR_ENCODING_NAME, [data mutableBytes], [data length], 0, XATTR_NOFOLLOW);
    }
    
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
    
    if (cfEncoding != kCFStringEncodingInvalidId) {
        return CFStringConvertEncodingToNSStringEncoding(cfEncoding);
    }
    
    return NSNotFound;
}


// ------------------------------------------------------
/// write `com.apple.TextEncoding` extended attribute to the file at URL
- (void)setAppleTextEncoding:(NSStringEncoding)encoding
// ------------------------------------------------------
{
    CFStringEncoding cfEncoding = CFStringConvertNSStringEncodingToEncoding(encoding);
    
    if (cfEncoding == kCFStringEncodingInvalidId) { return; }
    
    NSString *IANACharSetName = (NSString *)CFStringConvertEncodingToIANACharSetName(cfEncoding);
    NSString *string = [NSString stringWithFormat:@"%@;%ul", IANACharSetName, cfEncoding];
    NSData *data = [string dataUsingEncoding:NSUTF8StringEncoding];
    
    if (!data) { return; }
    
    setxattr([self fileSystemRepresentation], XATTR_ENCODING_NAME, [data bytes], [data length], 0, XATTR_NOFOLLOW);
}

@end
