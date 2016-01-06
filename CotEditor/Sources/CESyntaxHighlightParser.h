/*
 
 CESyntaxHighlightParser.h
 
 CotEditor
 http://coteditor.com
 
 Created by 1024jp on 2016-01-06.
 
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

@import Foundation;


@interface CESyntaxHighlightParser : NSObject

@property (nonatomic, getter=isCancelled) BOOL cancelled;

// call-backs
@property (nonatomic, nullable, copy) void (^beginParsingBlock)(NSString * _Nonnull localizedBlockName);
@property (nonatomic, nullable, copy) void (^didProgress)(CGFloat delta);


- (nonnull instancetype)initWithString:(nonnull NSString *)string
                            dictionary:(nonnull NSDictionary *)dictionary
              simpleWordsCharacterSets:(nullable NSDictionary<NSString *, NSCharacterSet *> *)simpleWordsCharacterSets
                      pairedQuoteTypes:(nullable NSDictionary<NSString *, NSString *> *)pairedQuoteTypes
                inlineCommentDelimiter:(nullable NSString *)inlineCommentDelimiter
                blockCommentDelimiters:(nullable NSDictionary<NSString *, NSString *> *)blockCommentDelimiters NS_DESIGNATED_INITIALIZER;
- (nullable instancetype)init NS_UNAVAILABLE;


- (void)parseRange:(NSRange)range completionHandler:(nullable void (^)(NSDictionary<NSString *, NSArray<NSValue *> *> * _Nonnull highlights))completionHandler;

@end