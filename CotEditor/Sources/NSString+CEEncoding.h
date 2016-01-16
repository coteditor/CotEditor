/*
 
 NSString+CEEncodings.h
 
 CotEditor
 http://coteditor.com
 
 Created by 1024jp on 2016-01-16.
 
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

@import Foundation;


// byte order marks
extern char const kUTF8Bom[];
extern char const kUTF16BEBom[];
extern char const kUTF16LEBom[];
extern char const kUTF32BEBom[];
extern char const kUTF32LEBom[];


@interface NSString (CEEncoding)

/// obtain string from NSData with intelligent encoding detection
- (nullable instancetype)initWithData:(nonnull NSData *)data suggestedCFEncodings:(nonnull NSArray<NSNumber *> *)suggestedCFEncodings usedEncoding:(nonnull NSStringEncoding *)usedEncoding error:(NSError * _Nullable __autoreleasing * _Nullable)outError;

/// scan encoding declaration in string
- (NSStringEncoding)scanEncodingDeclarationForTags:(nonnull NSArray<NSString *> *)tags upToIndex:(NSUInteger)maxLength suggestedCFEncodings:(nonnull NSArray<NSNumber *> *)suggestedCFEncodings;

/// check IANA charset compatibility considering SHIFT_JIS
BOOL CEIsCompatibleIANACharSetEncoding(NSStringEncoding IANACharsetEncoding, NSStringEncoding encoding);

@end
