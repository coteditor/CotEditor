/*
 
 CEIncompatibleCharacter.m
 
 CotEditor
 http://coteditor.com
 
 Created by 1024jp on 2016-05-28.
 
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

#import "CEIncompatibleCharacter.h"

#import "NSString+CEEncoding.h"
#import "NSString+CECounting.h"


@interface CEIncompatibleCharacter ()

@property (readwrite, nonatomic, nonnull) NSString *character;
@property (readwrite, nonatomic, nonnull) NSString *convertedCharacter;
@property (readwrite, nonatomic) NSUInteger location;
@property (readwrite, nonatomic) NSUInteger lineNumber;

@end




#pragma mark -

@implementation CEIncompatibleCharacter

#pragma mark Public Methods

//------------------------------------------------------
/// disable superclass's designated initializer
- (nullable instancetype)init
//------------------------------------------------------
{
    @throw nil;
}


// ------------------------------------------------------
/// initialize instance
- (nonnull instancetype)initWithCharacter:(unichar)character convertedCharacer:(unichar)convertedCharacter location:(NSUInteger)location lineNumber:(NSUInteger)lineNumber
// ------------------------------------------------------
{
    self = [super init];
    if (self) {
        _character = [NSString stringWithCharacters:&character length:1];
        _convertedCharacter = [NSString stringWithCharacters:&convertedCharacter length:1];
        _location = location;
        _lineNumber = lineNumber;
    }
    return self;
}


// ------------------------------------------------------
/// location as NSRange
- (NSRange)range
// ------------------------------------------------------
{
    return NSMakeRange(self.location, 1);
}

@end




#pragma mark -

@implementation NSString (IncompatibleCharacter)

#pragma mark Public Methods

// ------------------------------------------------------
/// list-up characters cannot be converted to the passed-in encoding
- (nullable NSArray<CEIncompatibleCharacter *> *)scanIncompatibleCharactersForEncoding:(NSStringEncoding)encoding
// ------------------------------------------------------
{
    NSData *data = [self dataUsingEncoding:encoding allowLossyConversion:YES];
    NSString *convertedString = [[NSString alloc] initWithData:data encoding:encoding];
    
    // failed to obtain valid data
    if (!convertedString || ([convertedString length] != [self length])) { return nil; }
    
    // list-up characters to be converted/deleted
    NSMutableArray<CEIncompatibleCharacter *> *incompatibles = [NSMutableArray array];
    BOOL isInvalidYenEncoding = CEEncodingCanConvertYenSign(encoding);
    
    for (NSUInteger index = 0; index < [self length]; index++) {
        unichar character = [self characterAtIndex:index];
        unichar convertedCharacter = [convertedString characterAtIndex:index];
        
        if (character == convertedCharacter) { continue; }
        
        if (isInvalidYenEncoding && character == kYenCharacter) {
            convertedCharacter = kYenSubstitutionCharacter;
        }
        
        [incompatibles addObject:[[CEIncompatibleCharacter alloc] initWithCharacter:character
                                                                  convertedCharacer:convertedCharacter
                                                                           location:index
                                                                         lineNumber:[self lineNumberAtIndex:index]]];
    }
    
    return [incompatibles copy];
}

@end
