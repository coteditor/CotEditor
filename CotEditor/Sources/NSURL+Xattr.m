/*
 
 NSURL+Xattr.m
 
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

#import "NSURL+Xattr.h"
#import <sys/xattr.h>


// constants
// public
char const XATTR_VERTICAL_TEXT_NAME[] = "com.coteditor.VerticalText";

// private
static char const XATTR_ENCODING_NAME[] = "com.apple.TextEncoding";


@implementation NSURL (Xattr)

// ------------------------------------------------------
/// read text encoding from `com.apple.TextEncoding` extended attribute of the file at URL
- (NSStringEncoding)getXattrEncoding
// ------------------------------------------------------
{
    NSData *data = [self getXattrDataForName:XATTR_ENCODING_NAME];
    
    if (!data) { return NSNotFound; }
    
    // parse value
    CFStringEncoding cfEncoding = kCFStringEncodingInvalidId;
    NSString *string = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
    NSArray<NSString *> *strings = [string componentsSeparatedByString:@";"];
    
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
- (BOOL)setXattrEncoding:(NSStringEncoding)encoding
// ------------------------------------------------------
{
    CFStringEncoding cfEncoding = CFStringConvertNSStringEncodingToEncoding(encoding);
    
    if (cfEncoding == kCFStringEncodingInvalidId) { return NO; }
    
    NSString *IANACharSetName = (NSString *)CFStringConvertEncodingToIANACharSetName(cfEncoding);
    NSString *string = [NSString stringWithFormat:@"%@;%u", IANACharSetName, cfEncoding];
    NSData *data = [string dataUsingEncoding:NSUTF8StringEncoding];
    
    if (!data) { return NO; }
    
    return [self setXattrData:data forName:XATTR_ENCODING_NAME];
}



// ------------------------------------------------------
/// get boolean value of extended attribute for given name from the file at URL
- (BOOL)getXattrBoolForName:(const char *)name
// ------------------------------------------------------
{
    NSData *data = [self getXattrDataForName:name];
    
    return data != nil;  // just check the existance of the key
}


// ------------------------------------------------------
/// set boolean value as extended attribute for given name to the file at URL
- (BOOL)setXattrBool:(BOOL)value forName:(const char *)name
// ------------------------------------------------------
{
    if (value) {
        NSData *data = [NSData dataWithBytes:"1" length:1];
        
        return [self setXattrData:data forName:name];
    } else {
        return [self removeXattrDataForName:name];
    }
}



#pragma mark Private Methods

// ------------------------------------------------------
/// get extended attribute for given name from the file at URL
- (nullable NSData *)getXattrDataForName:(const char *)name
// ------------------------------------------------------
{
    // check buffer size
    const char *path = [[self path] fileSystemRepresentation];
    ssize_t bufferSize = getxattr(path, name, NULL, 0, 0, XATTR_NOFOLLOW);
    
    if (bufferSize <= 0) { return nil; }
    
    // get xattr data
    NSMutableData *data = [NSMutableData dataWithLength:bufferSize];
    getxattr(path, name, [data mutableBytes], [data length], 0, XATTR_NOFOLLOW);
    
    return [data copy];
}


// ------------------------------------------------------
/// set extended attribute for given name to the file at URL
- (BOOL)setXattrData:(nonnull NSData *)data forName:(const char *)name
// ------------------------------------------------------
{
    int result = setxattr([[self path] fileSystemRepresentation], name, [data bytes], [data length], 0, XATTR_NOFOLLOW);
    
    return result == 0;
}


// ------------------------------------------------------
/// remove extended attribute for given name from the file at URL
- (BOOL)removeXattrDataForName:(const char *)name
// ------------------------------------------------------
{
    return removexattr([[self path] fileSystemRepresentation], name, XATTR_NOFOLLOW);
}

@end
