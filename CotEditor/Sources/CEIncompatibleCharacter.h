/*
 
 CEIncompatibleCharacter.h
 
 CotEditor
 http://coteditor.com
 
 Created by 1024jp on 2016-05-28.
 
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


@interface CEIncompatibleCharacter : NSObject

@property (readonly, nonatomic, nonnull) NSString *character;
@property (readonly, nonatomic, nonnull) NSString *convertedCharacter;
@property (readonly, nonatomic) NSUInteger location;
@property (readonly, nonatomic) NSUInteger lineNumber;
@property (readonly, nonatomic) NSRange range;

- (nonnull instancetype)init NS_UNAVAILABLE;

@end




#pragma mark -

@interface NSString (IncompatibleCharacter)

/// list-up characters cannot be converted to the passed-in encoding
- (nullable NSArray<CEIncompatibleCharacter *> *)scanIncompatibleCharactersForEncoding:(NSStringEncoding)encoding;

@end
