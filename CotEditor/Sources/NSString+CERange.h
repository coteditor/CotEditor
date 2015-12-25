/*
 
 NSString+CERange.h
 
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

@import Foundation;


@interface NSString (CERange)

/*
 Negative location accesses elements from the end of element counting backwards.
 e.g. `location == -1` is the last character / last.
 
 Likewise, negative length can be used to select rest elements except the last one element.
 e.g. `location: 3`, `length: -1` where string has 10 lines.
       -> element 3 to 9 (NSRange(3, 6)) will be retruned
 
 
 Well, this category is not so useful as you thought.
 */

/// convert location/length allowing negative value to valid NSRange.
- (NSRange)rangeForLocation:(NSInteger)location length:(NSInteger)length;

/**
 Return character range for line location/length allowing negative value.
 
 @param location   Index of the first line in range. The line location starts not with 0 but with 1.
                   Passing 0 to the location will return NSNotFound.
 @param length     Number of lines to include.
 
 @return Character range, or NSRange(NSNotFound, 0) if the given values are out of range.
 
 @note The last line break will be included.
 */
- (NSRange)rangeForLineLocation:(NSInteger)location length:(NSInteger)length;

@end
