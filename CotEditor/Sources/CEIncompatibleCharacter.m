/*
 
 CEIncompatibleCharacter.m
 
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

#import "CEIncompatibleCharacter.h"


@interface CEIncompatibleCharacter ()

@property (readwrite, nonatomic, nonnull) NSString *character;
@property (readwrite, nonatomic, nonnull) NSString *convertedCharacter;
@property (readwrite, nonatomic) NSRange range;
@property (readwrite, nonatomic) NSUInteger lineNumber;

@end




#pragma mark -

@implementation CEIncompatibleCharacter

//------------------------------------------------------
/// disable superclass's designated initializer
- (nullable instancetype)init
//------------------------------------------------------
{
    @throw nil;
}


// ------------------------------------------------------
/// initialize instance
- (nonnull instancetype)initWithCharacter:(unichar)character convertedCharacer:(unichar)convertedCharacter range:(NSRange)range lineNumber:(NSUInteger)lineNumber
// ------------------------------------------------------
{
    self = [super init];
    if (self) {
        _character = [NSString stringWithCharacters:&character length:1];
        _convertedCharacter = [NSString stringWithCharacters:&convertedCharacter length:1];
        _range = range;
        _lineNumber = lineNumber;
    }
    return self;
}

@end
