/*
 
 CEKeyBindingItem.m
 
 CotEditor
 http://coteditor.com
 
 Created by 1024jp on 2016-06-22.
 
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


@protocol CEKeyBindingItemInterface <NSObject>

- (nonnull NSString *)title;

@end


@interface CEKeyBindingItem : NSObject <CEKeyBindingItemInterface>

@property (readonly, nonatomic, nonnull) NSString *title;
@property (readonly, nonatomic, nonnull) NSString *selector;
@property (nonatomic, nullable) NSString *keySpecChars;


- (nonnull instancetype)initWithTitle:(nonnull NSString *)title selector:(nonnull NSString *)selector keySpecChars:(nullable NSString *)keySpecChars NS_DESIGNATED_INITIALIZER;
- (nonnull instancetype)init NS_UNAVAILABLE;

@end


@interface CEKeyBindingContainerItem : NSObject <CEKeyBindingItemInterface>

@property (readonly, nonatomic, nonnull) NSString *title;
@property (readonly, nonatomic, nonnull) NSArray<CEKeyBindingItem *> *children;


- (nonnull instancetype)initWithTitle:(nonnull NSString *)title children:(nonnull NSArray<CEKeyBindingItem *> *)children NS_DESIGNATED_INITIALIZER;
- (nonnull instancetype)init NS_UNAVAILABLE;

@end
