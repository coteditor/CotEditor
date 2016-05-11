/*
 
 CESyntaxOutlineParser.h
 
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


// Outline item dict keys
extern NSString *_Nonnull const CEOutlineItemTitleKey;
extern NSString *_Nonnull const CEOutlineItemRangeKey;
extern NSString *_Nonnull const CEOutlineItemStyleBoldKey;
extern NSString *_Nonnull const CEOutlineItemStyleItalicKey;
extern NSString *_Nonnull const CEOutlineItemStyleUnderlineKey;


@interface CESyntaxOutlineParser : NSObject

- (nonnull instancetype)initWithDefinitions:(nonnull NSArray<NSDictionary *> *)definitions NS_DESIGNATED_INITIALIZER;
- (nullable instancetype)init NS_UNAVAILABLE;

- (void)parseString:(nonnull NSString *)string range:(NSRange)range completionHandler:(nullable void (^)(NSArray<NSDictionary<NSString *, id> *> * _Nonnull outlineItems))completionHandler;

@end
