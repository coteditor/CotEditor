/*
 
 NSString+CEEncodings.h
 
 CotEditor
 http://coteditor.com
 
 Created by 1024jp on 2016-01-16.
 
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


// Yen mark char
extern unichar const kYenCharacter;
extern unichar const kYenSubstitutionCharacter;


/// check IANA charset compatibility considering SHIFT_JIS
BOOL CEIsCompatibleIANACharSetEncoding(NSStringEncoding IANACharsetEncoding, NSStringEncoding encoding);

/// whether Yen sign (U+00A5) can be converted with the encoding
BOOL CEEncodingCanConvertYenSign(NSStringEncoding encoding);

// encode/decode `com.apple.TextEncoding` file extended attribute
NSStringEncoding decodeXattrEncoding(NSData * _Nullable data);
NSData * _Nullable encodeXattrEncoding(NSStringEncoding encoding);


@interface NSString (CEEncoding)

+ (nonnull NSString *)localizedNameOfStringEncoding:(NSStringEncoding)encoding withUTF8BOM:(BOOL)withBOM;
+ (nonnull NSString *)localizedNameOfUTF8EncodingWithBOM;

/// IANA CharSet Name for the given encoding
+ (nullable NSString *)IANACharSetNameOfStringEncoding:(NSStringEncoding)encoding;

/// obtain string from NSData with intelligent encoding detection
- (nullable instancetype)initWithData:(nonnull NSData *)data suggestedCFEncodings:(nonnull NSArray<NSNumber *> *)suggestedCFEncodings usedEncoding:(nonnull NSStringEncoding *)usedEncoding error:(NSError * _Nullable __autoreleasing * _Nullable)outError;

/// scan encoding declaration in string
- (NSStringEncoding)scanEncodingDeclarationForTags:(nonnull NSArray<NSString *> *)tags upToIndex:(NSUInteger)maxLength suggestedCFEncodings:(nonnull NSArray<NSNumber *> *)suggestedCFEncodings;

/// convert Yen sign in consideration of the encoding
- (nonnull NSString *)stringByConvertingYenSignForEncoding:(NSStringEncoding)encoding;

@end



@interface NSData (UTF8BOM)

- (nonnull NSData *)dataByAddingUTF8BOM;
- (BOOL)hasUTF8BOM;

@end
