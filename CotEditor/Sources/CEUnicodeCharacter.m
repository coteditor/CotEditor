/*
 
 CEUnicodeCharacter.m
 
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

#import "CEUnicodeCharacter.h"
#import "icu/uchar.h"


@interface CEUnicodeCharacter ()

// readonly
@property (nonatomic, readwrite) UTF32Char character;
@property (nonatomic, readwrite, nonnull, copy) NSString *string;
@property (nonatomic, readwrite, nonnull, copy) NSString *unicode;
@property (nonatomic, readwrite, getter=isSurrogatePair) BOOL surrogatePair;
@property (nonatomic, readwrite, nullable, copy) NSArray<NSString *> *surrogateUnicodes;

@property (nonatomic, readwrite, nonnull, copy) NSString *name;
@property (nonatomic, readwrite, nonnull, copy) NSString *categoryName;
@property (nonatomic, readwrite, nonnull, copy) NSString *blockName;
@property (nonatomic, readwrite, nonnull, copy) NSString *localizedBlockName;

@end



@implementation CEUnicodeCharacter

//------------------------------------------------------
/// disable superclass's designated initializer
- (nullable instancetype)init
//------------------------------------------------------
{
    @throw nil;
}



#pragma mark Public Methods

//------------------------------------------------------
/// convenience constractor
+ (nonnull CEUnicodeCharacter *)unicodeCharacterWithCharacter:(UTF32Char)character
//------------------------------------------------------
{
    return [[CEUnicodeCharacter alloc] initWithCharacter:character];
}


//------------------------------------------------------
/// designated initializer
- (nonnull instancetype)initWithCharacter:(UTF32Char)character
//------------------------------------------------------
{
    self = [super init];
    if (self) {
        _character = character;
        _unicode = [NSString stringWithFormat:@"U+%04tX", character];
        
        // UTF32Char to NSString
        UTF32Char littleEdian = NSSwapHostIntToLittle(character);
        _string = [[NSString alloc] initWithBytes:&littleEdian length:4 encoding:NSUTF32LittleEndianStringEncoding];
        
        // surrogate pair check
        UniChar surrogates[2];
        _surrogatePair = CFStringGetSurrogatePairForLongCharacter(character, surrogates);
        if (_surrogatePair) {
            _surrogateUnicodes = @[[NSString stringWithFormat:@"U+%04X", surrogates[0]],
                                   [NSString stringWithFormat:@"U+%04X", surrogates[1]]];
        }
    }
    return self;
}



# pragma mark Public Accessors


// ------------------------------------------------------
/// Unicode name
- (nonnull NSString *)name
// ------------------------------------------------------
{
    // defer init
    if (!_name) {
        NSMutableString *unicodeName = [[self string] mutableCopy];
        
        // You can't use kCFStringTransformToUnicodeName instead of `Any-Name` here,
        // because some characters (e.g. normal `a`) don't return their name when use this constant.
        CFStringTransform((__bridge CFMutableStringRef)unicodeName, NULL, CFSTR("Any-Name"), NO);
        
        NSRegularExpression *regex = [NSRegularExpression regularExpressionWithPattern:@"\\{(.+?)\\}" options:0 error:nil];
        NSTextCheckingResult *firstMatch = [regex firstMatchInString:unicodeName options:0
                                                               range:NSMakeRange(0, [unicodeName length])];
        
        _name = [unicodeName substringWithRange:[firstMatch rangeAtIndex:1]];
    }
    
    return _name;
}


// ------------------------------------------------------
/// Unicode category name
- (nonnull NSString *)categoryName
// ------------------------------------------------------
{
    // defer init
    if (!_categoryName) {
        int32_t prop = u_getIntPropertyValue([self character], UCHAR_GENERAL_CATEGORY);
        const char *categoryNameChars = u_getPropertyValueName(UCHAR_GENERAL_CATEGORY, prop, U_LONG_PROPERTY_NAME);
        
        _categoryName = [[NSString stringWithUTF8String:categoryNameChars]
                         stringByReplacingOccurrencesOfString:@"_" withString:@" "];  // sanitize
    }
    
    return _categoryName;
}


// ------------------------------------------------------
/// Unicode block name just returned from an icu function
- (nonnull NSString *)blockName
// ------------------------------------------------------
{
    // defer init
    if (!_blockName) {
        int32_t prop = u_getIntPropertyValue([self character], UCHAR_BLOCK);
        const char *blockNameChars = u_getPropertyValueName(UCHAR_BLOCK, prop, U_LONG_PROPERTY_NAME);
        
        _blockName = [[NSString stringWithUTF8String:blockNameChars]
                      stringByReplacingOccurrencesOfString:@"_" withString:@" "];  // sanitize
    }
    
    return _blockName;
}


// ------------------------------------------------------
/// Localized and sanitized unicode block name
- (nonnull NSString *)localizedBlockName
// ------------------------------------------------------
{
    // defer init
    if (!_localizedBlockName) {
        NSString *blockName = [self blockName];
        
        // sanitize for localization
        // -> This is actually a dirty workaround to make the block name the same as the Apple's block naming rule.
        //    Otherwise, we cannot localize block name correctly. (2015-11 by 1024jp)
        blockName = [blockName stringByReplacingOccurrencesOfString:@" ([A-Z])$" withString:@"-$1"
                                                            options:NSRegularExpressionSearch range:NSMakeRange(0, [blockName length])];
        blockName = [blockName stringByReplacingOccurrencesOfString:@"Extension-" withString:@"Ext. "];
        blockName = [blockName stringByReplacingOccurrencesOfString:@" And " withString:@" and "];
        blockName = [blockName stringByReplacingOccurrencesOfString:@"Latin 1" withString:@"Latin-1"];  // only for "Latin-1 Supplement"
        
        _localizedBlockName = NSLocalizedStringFromTable(blockName, @"Unicode", nil);
        
    }
    return _localizedBlockName;
}

@end
