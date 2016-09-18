/*
 
 CEUnicodeCharacter.m
 
 CotEditor
 http://coteditor.com
 
 Created by 1024jp on 2015-11-21.
 
 ------------------------------------------------------------------------------
 
 © 2015-2016 1024jp
 
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
#import "CEControlCharacerNames.h"
#import "icu/uchar.h"


@interface CEUnicodeCharacter ()

// readonly
@property (nonatomic, readwrite) UTF32Char character;
@property (nonatomic, readwrite) unichar pictureCharacter;
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
- (nonnull instancetype)init
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
        
        // surrogate pair check
        UniChar surrogates[2];
        _surrogatePair = CFStringGetSurrogatePairForLongCharacter(character, surrogates);
        if (_surrogatePair) {
            _surrogateUnicodes = @[[NSString stringWithFormat:@"U+%04X", surrogates[0]],
                                   [NSString stringWithFormat:@"U+%04X", surrogates[1]]];
        }
        
        // UTF32Char to NSString
        BOOL isSingleSurrogate = CFStringIsSurrogateHighCharacter(character) || CFStringIsSurrogateLowCharacter(character);
        if (isSingleSurrogate) {
            unichar singleChar = character;  // downcast
            _string = [[NSString alloc] initWithCharacters:&singleChar length:1];
        } else {
            UTF32Char littleEdian = NSSwapHostIntToLittle(character);
            _string = [[NSString alloc] initWithBytes:&littleEdian length:4 encoding:NSUTF32LittleEndianStringEncoding];
        }
        NSAssert(_string != nil, @"Failed to covnert UTF32Char U+%04tX into NSString.", character);
        
        // alternate picture caracter for invisible control character
        if (CEIsC0ControlPoint(_character)) {
            _pictureCharacter = _character + 0x2400;  // shift 0x2400 to Unicode control pictures
        } else if (_character == CEDeleteCharacter) {  // DELETE character
            _pictureCharacter = 0x2421;  // SYMBOL FOR DELETE character
            
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
        _name = CEControlCharacterName([self character]);
        
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
        
        _categoryName = [@(categoryNameChars) stringByReplacingOccurrencesOfString:@"_" withString:@" "];  // sanitize
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
        
        _blockName = [@(blockNameChars) stringByReplacingOccurrencesOfString:@"_" withString:@" "];  // sanitize
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
        
        blockName = [[self class] sanitizeBlockName:blockName];
        
        _localizedBlockName = NSLocalizedStringFromTable(blockName, @"Unicode", nil);
        
    }
    return _localizedBlockName;
}


#pragma mark Private Methods

// ------------------------------------------------------
/// sanitize block name for localization
+ (nonnull NSString *)sanitizeBlockName:(nonnull NSString *)blockName
// ------------------------------------------------------
{
    // -> This is actually a dirty workaround to make the block name the same as the Apple's block naming rule.
    //    Otherwise, we cannot localize block name correctly. (2015-11 by 1024jp)
    blockName = [blockName stringByReplacingOccurrencesOfString:@" ([A-Z])$" withString:@"-$1"
                                                        options:NSRegularExpressionSearch range:NSMakeRange(0, [blockName length])];
    blockName = [blockName stringByReplacingOccurrencesOfString:@"Extension-" withString:@"Ext. "];
    blockName = [blockName stringByReplacingOccurrencesOfString:@" And " withString:@" and "];
    blockName = [blockName stringByReplacingOccurrencesOfString:@" For " withString:@" for "];
    blockName = [blockName stringByReplacingOccurrencesOfString:@" Mathematical " withString:@" Math "];
    blockName = [blockName stringByReplacingOccurrencesOfString:@"Latin 1" withString:@"Latin-1"];  // only for "Latin-1
    
    return blockName;
}


// ------------------------------------------------------
/// check which block names will be lozalized (only for test use)
+ (void)testUnicodeBlockNameLocalizationForLanguage:(NSString *)language
// ------------------------------------------------------
{
    NSURL *bundleURL = [[NSBundle mainBundle] URLForResource:language withExtension:@"lproj"];
    NSBundle *bundle = [NSBundle bundleWithURL:bundleURL];
    
    for (int i = 0; i < UBLOCK_COUNT; i++) {
        const char *blockNameChars = u_getPropertyValueName(UCHAR_BLOCK, i, U_LONG_PROPERTY_NAME);
        
        NSString *blockName = [@(blockNameChars) stringByReplacingOccurrencesOfString:@"_" withString:@" "];  // sanitize
        blockName = [[self class] sanitizeBlockName:blockName];
        
        NSString *localizedBlockName = [bundle localizedStringForKey:blockName value:nil table:@"Unicode"];
        
        NSLog(@"%@ %@ %@", [localizedBlockName isEqualToString:blockName] ? @"⚠️" : @"  ", blockName, localizedBlockName);
    }
}

@end
