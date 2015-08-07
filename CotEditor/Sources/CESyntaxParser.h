/*
 
 CESyntaxParser.h
 
 CotEditor
 http://coteditor.com
 
 Created by nakamuxu on 2004-12-22.

 ------------------------------------------------------------------------------
 
 © 2004-2007 nakamuxu
 © 2014-2015 1024jp
 
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


@interface CESyntaxParser : NSObject

// readonly
@property (readonly, nonatomic, nonnull, copy) NSString *styleName;
@property (readonly, nonatomic, nullable, copy) NSArray *completionWords;  // 入力補完文字列配列
@property (readonly, nonatomic, nullable, copy) NSCharacterSet *firstCompletionCharacterSet;  // 入力補完の最初の1文字のセット
@property (readonly, nonatomic, nullable, copy) NSString *inlineCommentDelimiter;
@property (readonly, nonatomic, nullable, copy) NSDictionary *blockCommentDelimiters;
@property (readonly, nonatomic, getter=isNone) BOOL none;


/// designated initializer (return nil if no corresponded style dictionary can be found.)
- (nullable instancetype)initWithStyleName:(nullable NSString *)styleName NS_DESIGNATED_INITIALIZER;

@end



@interface CESyntaxParser (Outline)

- (nonnull NSArray *)outlineItemsWithWholeString:(nullable NSString *)wholeString;

@end



@interface CESyntaxParser (Highlighting)

- (void)colorWholeStringInTextStorage:(nonnull NSTextStorage *)textStorage temporal:(BOOL)isTemporal;
- (void)colorRange:(NSRange)range textStorage:(nonnull NSTextStorage *)textStorage temporal:(BOOL)isTemporal;

@end
