/*
 
 NSString+CERange.m
 
 CotEditor
 http://coteditor.com
 
 Created by 1024jp on 2015-12-25.
 
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

#import "NSString+CERange.h"


@implementation NSString (CERange)

// ------------------------------------------------------
/// convert location/length allowing negative value to valid NSRange
- (NSRange)rangeForLocation:(NSInteger)location length:(NSInteger)length
// ------------------------------------------------------
{
    NSUInteger wholeLength = [self length];
    NSRange range = NSMakeRange(0, 0);
    
    NSInteger newLocation = (location < 0) ? (wholeLength + location) : location;
    NSInteger newLength = (length < 0) ? (wholeLength - newLocation + length) : length;
    if ((newLocation < wholeLength) && ((newLocation + newLength) > wholeLength)) {
        newLength = wholeLength - newLocation;
    }
    if ((length < 0) && (newLength < 0)) {
        newLength = 0;
    }
    if ((newLocation < 0) || (newLength < 0)) {
        return range;
    }
    range = NSMakeRange(newLocation, newLength);
    if (wholeLength >= NSMaxRange(range)) {
        return range;
    }
    
    return range;
}


// ------------------------------------------------------
/// return character range for line location/length allowing negative value
- (NSRange)rangeForLineLocation:(NSInteger)location length:(NSInteger)length
// ------------------------------------------------------
{
    NSUInteger wholeLength = [self length];
    NSRegularExpression *regex = [NSRegularExpression regularExpressionWithPattern:@"^"
                                                                           options:NSRegularExpressionAnchorsMatchLines
                                                                             error:nil];
    NSArray<NSTextCheckingResult *> *matches = [regex matchesInString:self options:0
                                                                range:NSMakeRange(0, wholeLength)];
    NSInteger count = [matches count];
    
    if (count == 0) { return NSMakeRange(NSNotFound, 0); }
    
    if (location == 0) {
        return NSMakeRange(0, 0);
        
    } else if (location > count) {
        return NSMakeRange(wholeLength, 0);
        
    } else {
        NSInteger newLocation, newLength;
        
        newLocation = (location < 0) ? (count + location + 1) : location;
        if (length < 0) {
            newLength = count - newLocation + length + 1;
        } else if (length == 0) {
            newLength = 1;
        } else {
            newLength = length;
        }
        if ((newLocation < count) && ((newLocation + newLength - 1) > count)) {
            newLength = count - newLocation + 1;
        }
        if ((length < 0) && (newLength < 0)) {
            newLength = 1;
        }
        if ((newLocation <= 0) || (newLength <= 0)) { return NSMakeRange(NSNotFound, 0); }
        
        NSTextCheckingResult *match = matches[(newLocation - 1)];
        NSRange range = [match range];
        NSRange tmpRange = range;
        
        for (NSInteger i = 0; i < newLength; i++) {
            if (NSMaxRange(tmpRange) > wholeLength) {
                break;
            }
            range = [self lineRangeForRange:tmpRange];
            tmpRange.length = range.length + 1;
        }
        if (wholeLength < NSMaxRange(range)) {
            range.length = wholeLength - range.location;
        }
        
        return range;
    }
    
    return NSMakeRange(NSNotFound, 0);
}

@end
