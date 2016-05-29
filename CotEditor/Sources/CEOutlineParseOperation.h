/*
 
 CEOutlineParseOperation.h
 
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


@class CEOutlineItem;


@interface CEOutlineParseOperation : NSOperation

@property (nonatomic, nullable, copy) NSString *string;
@property (nonatomic) NSRange parseRange;

@property (readonly, nonatomic, nonnull) NSProgress *progress;
@property (readonly, nonatomic, nullable, copy) NSArray<CEOutlineItem *> *results;


- (nonnull instancetype)initWithDefinitions:(nonnull NSArray<NSDictionary *> *)definitions NS_DESIGNATED_INITIALIZER;
- (nullable instancetype)init NS_UNAVAILABLE;

@end
