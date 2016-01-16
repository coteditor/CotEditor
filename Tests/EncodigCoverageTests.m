/*

EncodigCoverageTests.m
Tests

CotEditor
http://coteditor.com

Created by 1024jp on 2016-01-17.

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

@import XCTest;
#import "CEEncodings.h"


@interface EncodigCoverageTests : XCTestCase

@end


@implementation EncodigCoverageTests

- (void)testInvalidYenListCoverage
{
    // put CFStringEncoding into NSArray
    NSMutableArray<NSNumber *> *invalidYenEncodings = [NSMutableArray arrayWithCapacity:kSizeOfCFStringEncodingInvalidYenList];
    for (NSUInteger i = 0; i < kSizeOfCFStringEncodingInvalidYenList; i++) {
        [invalidYenEncodings addObject:@(kCFStringEncodingInvalidYenList[i])];
    }
    
    NSString *yen = [NSString stringWithCharacters:&kYenMark length:1];
    NSString *backslash = @"\\";
    
    // check all available encodings
    for (NSUInteger i = 0; i < kSizeOfCFStringEncodingList; i++) {
        CFStringEncoding cfEncoding = kCFStringEncodingList[i];
        
        if (cfEncoding == kCFStringEncodingInvalidId) { continue; }
        
        NSStringEncoding encoding = CFStringConvertEncodingToNSStringEncoding(cfEncoding);
        NSString *encodingName = [NSString localizedNameOfStringEncoding:encoding];
        
        // try converting Yen
        NSData *yenData = [yen dataUsingEncoding:encoding allowLossyConversion:YES];
        NSString *convertedYen = [[NSString alloc] initWithData:yenData encoding:encoding];
        BOOL canConvertYen = [convertedYen isEqualToString:yen];
        
        // try converting backslash
        NSData *backslashData = [backslash dataUsingEncoding:encoding allowLossyConversion:YES];
        NSString *convertedBackslash = [[NSString alloc] initWithData:backslashData encoding:encoding];
        BOOL canConvertBackslash = [convertedBackslash isEqualToString:backslash];
        
        // check if the list contains this encoding
        BOOL contains = [invalidYenEncodings containsObject:@(cfEncoding)];
        if (contains && canConvertYen) {
            XCTFail(@"Invalid Yen List contains %@ even it can convert Yen mark.", encodingName);
            
        } else if (!contains && !canConvertYen) {
            if ([convertedYen isEqualToString:@"Y"] || [convertedYen isEqualToString:@"￥"]) {
                // -> ???: Actually, I'm not sure why they can be skipped. Nakamuxu-san did so. (2016-01 by 1024jp)
                continue;
            }
            NSMutableArray *codepoints = [NSMutableArray arrayWithCapacity:[convertedYen length]];
            for (NSUInteger i = 0; i < [convertedYen length]; i++) {
                [codepoints addObject:[NSString stringWithFormat:@"U+%04X", [convertedYen characterAtIndex:i]]];
            }
            XCTFail(@"Invalid Yen List doesn't contain \"%@\" even %@ mark is converted to %@ (%@).",
                    encodingName, yen, convertedYen, [codepoints componentsJoinedByString:@" "]);
        }
    }
}

@end

















