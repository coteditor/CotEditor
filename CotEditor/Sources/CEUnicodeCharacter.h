/*
 
 CEUnicodeCharacter.h
 
 CotEditor
 http://coteditor.com
 
 Created by 1024jp on 2015-11-21.
 
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


@interface CEUnicodeCharacter : NSObject

@property (nonatomic, readonly) UTF32Char character;
@property (nonatomic, readonly) unichar pictureCharacter;
@property (nonatomic, readonly, nonnull, copy) NSString *unicode;
@property (nonatomic, readonly, nonnull, copy) NSString *string;
@property (nonatomic, readonly, getter=isSurrogatePair) BOOL surrogatePair;
@property (nonatomic, readonly, nullable, copy) NSArray<NSString *> *surrogateUnicodes;
@property (nonatomic, readonly, nonnull, copy) NSString *name;
@property (nonatomic, readonly, nonnull, copy) NSString *categoryName;
@property (nonatomic, readonly, nonnull, copy) NSString *blockName;
@property (nonatomic, readonly, nonnull, copy) NSString *localizedBlockName;


+ (nonnull CEUnicodeCharacter *)unicodeCharacterWithCharacter:(UTF32Char)character;

/// designated initializer
- (nonnull instancetype)initWithCharacter:(UTF32Char)character NS_DESIGNATED_INITIALIZER;
- (nullable instancetype)init NS_UNAVAILABLE;

@end
