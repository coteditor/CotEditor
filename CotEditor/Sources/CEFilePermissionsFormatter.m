/*
 
 CEFilePermissionsFormatter.m
 
 CotEditor
 http://coteditor.com
 
 Created by 1024jp on 2016-06-02.
 
 ------------------------------------------------------------------------------
 
 © 2016 1024jp
 
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

#import "CEFilePermissionsFormatter.h"


@implementation CEFilePermissionsFormatter

// ------------------------------------------------------
/// format permission number to human readable permission expression
- (nullable NSString *)stringForObjectValue:(nullable id)obj
// ------------------------------------------------------
{
    if (![obj isKindOfClass:[NSNumber class]]) {
        return [obj description];
    }
    
    unsigned long permission = [(NSNumber *)obj unsignedLongValue];
    
    return [NSString stringWithFormat:@"%lo (%@)", permission, humanReadablePermission(permission)];
}


// ------------------------------------------------------
/// disable backwards formatting
- (BOOL)getObjectValue:(out id  _Nullable __autoreleasing *)obj forString:(NSString *)string errorDescription:(out NSString *__autoreleasing  _Nullable *)error
// ------------------------------------------------------
{
    return NO;
}



#pragma mark Private Function

// ------------------------------------------------------
/// create human-readable permission expression from integer
NSString *humanReadablePermission(unsigned long permission)
// ------------------------------------------------------
{
    NSArray<NSString *> *units = @[@"---", @"--x", @"-w-", @"-wx", @"r--", @"r-x", @"rw-", @"rwx"];
    NSMutableString *result = [NSMutableString stringWithString:@"-"];  // Document is always file.
    
    for (NSInteger i = 2; i >= 0; i--) {
        NSUInteger digit = (permission >> (i * 3)) & 0x7;
        
        [result appendString:units[digit]];
    }
    
    return [result copy];
}

@end
