/*
 
 NSTextView+CETextReplacement.h
 
 CotEditor
 http://coteditor.com
 
 Created by 1024jp on 2016-01-10.
 
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

@import Cocoa;

@interface NSTextView (CETextReplacement)

- (void)insertString:(nonnull NSString *)string;
- (void)insertStringAfterSelection:(nonnull NSString *)string;
- (void)replaceAllStringWithString:(nonnull NSString *)string;
- (void)appendString:(nonnull NSString *)string;

- (BOOL)replaceWithString:(nullable NSString *)string
                    range:(NSRange)range
            selectedRange:(NSRange)selectedRange
               actionName:(nullable NSString *)actionName;

- (BOOL)replaceWithStrings:(nonnull NSArray<NSString *> *)strings
                    ranges:(nonnull NSArray<NSValue *> *)ranges
            selectedRanges:(nullable NSArray<NSValue *> *)selectedRanges
                actionName:(nullable NSString *)actionName;

- (void)setSelectedRangesWithUndo:(nonnull NSArray<NSValue *> *)ranges;

@end
