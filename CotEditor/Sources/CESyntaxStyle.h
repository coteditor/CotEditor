/*
 
 CESyntaxStyle.h
 
 CotEditor
 http://coteditor.com
 
 Created by nakamuxu on 2004-12-22.

 ------------------------------------------------------------------------------
 
 © 2004-2007 nakamuxu
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


@class OutlineItem;


@protocol CESyntaxStyleDelegate;


@interface CESyntaxStyle : NSObject

@property (nonatomic, nullable) NSTextStorage *textStorage;
@property (nonatomic, nullable, weak) id<CESyntaxStyleDelegate> delegate;

// readonly
@property (readonly, nonatomic, nonnull, copy) NSString *styleName;
@property (readonly, nonatomic, nullable, copy) NSArray<NSString *> *completionWords;  // 入力補完文字列配列
@property (readonly, nonatomic, nullable, copy) NSCharacterSet *firstCompletionCharacterSet;  // 入力補完の最初の1文字のセット
@property (readonly, nonatomic, nullable, copy) NSString *inlineCommentDelimiter;
@property (readonly, nonatomic, nullable, copy) NSDictionary<NSString *, NSString *> *blockCommentDelimiters;
@property (readonly, nonatomic, getter=isNone) BOOL none;


/// designated initializer (return nil if no corresponded style dictionary can be found.)
- (nonnull instancetype)initWithDictionary:(nullable NSDictionary<NSString *, id> *)dictionary name:(nonnull NSString *)styleName NS_DESIGNATED_INITIALIZER;

/// check equality of the content
- (BOOL)isEqualToSyntaxStyle:(nullable CESyntaxStyle *)syntaxStyle;

- (void)cancelAllParses;
- (BOOL)canParse;

@end



@interface CESyntaxStyle (Outline)

@property (readonly, nonatomic, nullable, copy) NSArray<OutlineItem *> *outlineItems;


- (void)invalidateOutline;

@end



@interface CESyntaxStyle (Highlighting)

- (void)highlightWholeStringWithCompletionHandler:(nullable void (^)())completionHandler;
- (void)highlightAroundEditedRange:(NSRange)editedRange;

@end


@protocol CESyntaxStyleDelegate <NSObject>

@optional
- (void)syntaxStyle:(nonnull CESyntaxStyle *)syntaxStyle didParseOutline:(nullable NSArray<OutlineItem *> *)outlineItems;

@end
