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
    
    // check all available encodings
    for (NSUInteger i = 0; i < kSizeOfCFStringEncodingList; i++) {
        CFStringEncoding cfEncoding = kCFStringEncodingList[i];
        
        if (cfEncoding == kCFStringEncodingInvalidId) { continue; }
        
        NSStringEncoding encoding = CFStringConvertEncodingToNSStringEncoding(cfEncoding);
        NSString *encodingName = [NSString localizedNameOfStringEncoding:encoding];
        
        BOOL canConvertYen = [yen canBeConvertedToEncoding:encoding];
        BOOL contains = [invalidYenEncodings containsObject:@(cfEncoding)];
        
        // check if the list contains the encoding
        if (contains && canConvertYen) {
            XCTFail(@"\"%@\" is listed in the invalid Yen encodings even it can convert %@ mark.", encodingName, yen);
            
        } else if (!contains && !canConvertYen) {
            NSData *yenData = [yen dataUsingEncoding:encoding allowLossyConversion:YES];
            NSString *convertedYen = [[NSString alloc] initWithData:yenData encoding:encoding];
            
            NSMutableArray<NSString *> *codepoints = [NSMutableArray arrayWithCapacity:[convertedYen length]];
            for (NSUInteger i = 0; i < [convertedYen length]; i++) {
                [codepoints addObject:[NSString stringWithFormat:@"U+%04X", [convertedYen characterAtIndex:i]]];
            }
            
            XCTFail(@"\"%@\" is not listed in the invalid Yen encodings even it lossy converts %@ mark to %@ (%@).",
                    encodingName, yen, convertedYen, [codepoints componentsJoinedByString:@" "]);
        }
    }
}

@end
