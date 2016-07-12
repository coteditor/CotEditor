/*
 
 NSString+CECounting.h
 
 CotEditor
 http://coteditor.com
 
 Created by 1024jp on 2014-05-04.
 
 ------------------------------------------------------------------------------
 
 © 2014-2016 1024jp
 
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


@interface NSString (CECounting)

/// Return the number of composed characters in the whole string. The string is normalized using NFC before counting.
- (NSInteger)numberOfComposedCharacters;


/// Return the number of words in the current language.
- (NSInteger)numberOfWords;


/// Return the number of lines in the range.
- (NSInteger)numberOfLinesInRange:(NSRange)range includingLastNewLine:(BOOL)ignore;

/// Return the number of lines in the whole string without the last new line character.
- (NSInteger)numberOfLines;

/// Return the number of lines at the character index (1-based).
- (NSInteger)lineNumberAtIndex:(NSInteger)index;

@end
