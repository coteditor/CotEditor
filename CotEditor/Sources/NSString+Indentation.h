/*
 
 NSString+Indentation.h
 
 CotEditor
 http://coteditor.com
 
 Created by 1024jp on 2015-10-16.
 
 ------------------------------------------------------------------------------
 
 © 2015-2016 1024jp
 
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


typedef NS_ENUM(NSInteger, CEIndentStyle) {
    CEIndentStyleNotFound,
    CEIndentStyleTab,
    CEIndentStyleSpace,
};


@interface NSString (Indentation)

/// string repeating spaces desired times
+ (nonnull NSString *)stringWithSpaces:(NSUInteger)numberOfSpaces;

/// detect indent style
- (CEIndentStyle)detectIndentStyle;

/// standardize indent style
- (nonnull NSString *)stringByStandardizingIndentStyleTo:(CEIndentStyle)indentStyle tabWidth:(NSInteger)tabWidth;

/// detect indent level of line at the location
- (NSInteger)indentLevelAtLocation:(NSInteger)location tabWidth:(NSInteger)tabWidth;

/// calculate column number at location in the line expanding tab (\t) character
- (NSInteger)columnOfLocation:(NSInteger)location tabWidth:(NSInteger)tabWidth;

/// range of indent characters in line at the location
- (NSRange)rangeOfIndentAtIndex:(NSInteger)location;

@end
