/*
 
 CECharacterInfo.m
 
 CotEditor
 http://coteditor.com
 
 Created by 1024jp on 2015-11-19.
 
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

#import "CECharacterInfo.h"
#import "NSString+ComposedCharacter.h"
#import "icu/uchar.h"


// variation selectors
static const unichar  kTextSequenceChar = 0xFE0E;
static const unichar kEmojiSequenceChar = 0xFE0F;

Boolean CEStringIsVariantSelector(UTF32Char character) {
    return ((character >= 0x180B && character <= 0x180D) ||
            (character >= 0xFE00 && character <= 0xFE0F) ||
            (character >= 0xE0100 && character <= 0xE01EF));
}

// emoji modifiers
static const UTF32Char kType12EmojiModifierChar = 0x1F3FB; // Emoji Modifier Fitzpatrick type-1-2
static const UTF32Char kType3EmojiModifierChar = 0x1F3FC;  // Emoji Modifier Fitzpatrick type-3
static const UTF32Char kType4EmojiModifierChar = 0x1F3FD;  // Emoji Modifier Fitzpatrick type-4
static const UTF32Char kType5EmojiModifierChar = 0x1F3FE;  // Emoji Modifier Fitzpatrick type-5
static const UTF32Char kType6EmojiModifierChar = 0x1F3FF;  // Emoji Modifier Fitzpatrick type-6


@interface CECharacterInfo ()

@property (nonatomic, nonnull, copy) NSArray<NSNumber *> *utf32Chars;
@property (nonatomic, getter=isComplexChar) BOOL complexChar;
@property (nonatomic, nullable, copy) NSString *variationSelectorAdditional;


// readonly
@property (nonatomic, readwrite, nonnull, copy) NSString *string;
@property (nonatomic, readwrite, nonnull, copy) NSString *unicode;
@property (nonatomic, readwrite, nullable, copy) NSString *unicodeName;
@property (nonatomic, readwrite, nullable, copy) NSString *unicodeBlockName;

@end




#pragma mark -

@implementation CECharacterInfo

#pragma mark Superclass Methods

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
+ (nullable CECharacterInfo *)characterInfoWithString:(nonnull NSString *)string
//------------------------------------------------------
{
    return [[CECharacterInfo alloc] initWithString:string];
}


//------------------------------------------------------
/// designated initializer
- (nullable instancetype)initWithString:(nonnull NSString *)string
//------------------------------------------------------
{
    if ([string numberOfComposedCharacters] != 1) { return nil; }
    
    self = [super init];
    if (self) {
        _string = string;
        _utf32Chars = [CECharacterInfo decomposeIntoUTF32Chars:string];
        
        // hex codes
        NSMutableArray<NSString *> *unicodes = [NSMutableArray arrayWithCapacity:[_utf32Chars count]];
        for (NSNumber *number in _utf32Chars) {
            UTF32Char character = toUTF32Char(number);
            [unicodes addObject:[CECharacterInfo getHexCodeString:character]];
        }
        _unicodes = [unicodes copy];
        
        // check variation selector
        if ([_utf32Chars count] == 2) {
            UTF32Char character = toUTF32Char([_utf32Chars lastObject]);
            
            switch (character) {
                case kEmojiSequenceChar:
                    _variationSelectorAdditional = @"Emoji Style";
                    break;
                case kTextSequenceChar:
                    _variationSelectorAdditional = @"Text Style";
                    break;
                    
                case kType12EmojiModifierChar:
                    _variationSelectorAdditional = @"Skin Tone I-II";  // Light Skin Tone
                    break;
                case kType3EmojiModifierChar:
                    _variationSelectorAdditional = @"Skin Tone III";  // Medium Light Skin Tone
                    break;
                case kType4EmojiModifierChar:
                    _variationSelectorAdditional = @"Skin Tone IV";  // Medium Skin Tone
                    break;
                case kType5EmojiModifierChar:
                    _variationSelectorAdditional = @"Skin Tone V";  // Medium Dark Skin Tone
                    break;
                case kType6EmojiModifierChar:
                    _variationSelectorAdditional = @"Skin Tone VI";  // Dark Skin Tone
                    break;
                default:
                    if (CEStringIsVariantSelector(character)) {
                        _variationSelectorAdditional = @"Variant";
                    } else {
                        _complexChar = YES;
                    }
            }
        } else if ([_utf32Chars count] > 2) {
            _complexChar = YES;
        }
    }
    return self;
}



#pragma mark Public Accessors

// ------------------------------------------------------
/// create human-readable description
- (nonnull NSString *)prettyDescription
// ------------------------------------------------------
{
    // number of characters message
    if ([self isComplexChar]) {
        return [NSString stringWithFormat:NSLocalizedStringFromTable(@"<a letter consisting of %d characters>", @"Unicode", nil),
                [[self unicodes] count]];
    }
    
    // unicode character name
    NSString *unicodeName = [self unicodeName];
    if ([self variationSelectorAdditional]) {
        unicodeName = [NSString stringWithFormat:@"%@ (%@)", [self unicodeName],
                       NSLocalizedStringFromTable([self variationSelectorAdditional], @"Unicode", nil)];
    }
    
    return unicodeName;
}


// ------------------------------------------------------
/// getter of unicode name
- (nullable NSString *)unicodeName
// ------------------------------------------------------
{
    if ([self isComplexChar]) { return nil; }
    
    // defer init
    if (!_unicodeName) {
        _unicodeName = [CECharacterInfo getUnicodeName:[self string]];
    }
    
    return _unicodeName;
}


// ------------------------------------------------------
/// getter of unicode block name
- (nullable NSString *)unicodeBlockName
// ------------------------------------------------------
{
    if ([self isComplexChar]) { return nil; }
    
    // defer init
    if (!_unicodeBlockName) {
        _unicodeBlockName = [CECharacterInfo getUnicodeBlockName:toUTF32Char([[self utf32Chars] firstObject])];
    }
    
    return _unicodeBlockName;
}


// ------------------------------------------------------
/// getter of localized unicode block name
- (nullable NSString *)localizedUnicodeBlockName
// ------------------------------------------------------
{
    if (![self unicodeBlockName]) { return nil; }
    
    return NSLocalizedStringFromTable([self unicodeBlockName], @"Unicode", nil);
}



#pragma mark Private Methods

// ------------------------------------------------------
///
+ (nonnull NSArray<NSNumber *> *)decomposeIntoUTF32Chars:(nonnull NSString *)string
// ------------------------------------------------------
{
    NSMutableArray<NSNumber *> *utf32Chars = [NSMutableArray array];
    NSUInteger length = [string length];
    
    for (NSUInteger i = 0; i < length; i++) {
        unichar theChar = [string characterAtIndex:i];
        unichar nextChar = (length > i + 1) ? [string characterAtIndex:i + 1] : 0;
        UTF32Char utf32Char;
        
        if (CFStringIsSurrogateHighCharacter(theChar) && CFStringIsSurrogateLowCharacter(nextChar)) {
            utf32Char = CFStringGetLongCharacterForSurrogatePair(theChar, nextChar);
            i++;
        } else {
            utf32Char = theChar;
        }
        
        [utf32Chars addObject:@(utf32Char)];
    }
    
    return [utf32Chars copy];
}


// ------------------------------------------------------
/// unicode hex numbers
+ (nonnull NSString *)getHexCodeString:(UTF32Char)charater
// ------------------------------------------------------
{
    UniChar surrogates[2];
    if (CFStringGetSurrogatePairForLongCharacter(charater, surrogates)) {
        return [NSString stringWithFormat:@"U+%04tX (U+%04X U+%04X)", charater, surrogates[0], surrogates[1]];
    } else {
        return [NSString stringWithFormat:@"U+%04X", charater];
    }
}


// ------------------------------------------------------
/// get Unicode name of the given character
+ (nonnull NSString *)getUnicodeName:(nonnull NSString *)string
// ------------------------------------------------------
{
    NSMutableString *unicodeName = [string mutableCopy];
    
    // You can't use kCFStringTransformToUnicodeName instead of `Any-Name` here,
    // because some characters (e.g. normal `a`) don't return their name when use this constant.
    CFStringTransform((__bridge CFMutableStringRef)unicodeName, NULL, CFSTR("Any-Name"), NO);
    
    NSRegularExpression *regex = [NSRegularExpression regularExpressionWithPattern:@"\\{(.+?)\\}" options:0 error:nil];
    NSTextCheckingResult *firstMatch = [regex firstMatchInString:unicodeName options:0
                                                           range:NSMakeRange(0, [unicodeName length])];
    
    return [unicodeName substringWithRange:[firstMatch rangeAtIndex:1]];
}


// ------------------------------------------------------
/// get Unicode block name the given character belong to
+ (nonnull NSString *)getUnicodeBlockName:(UTF32Char)character
// ------------------------------------------------------
{
    // get Unicode block
    int32_t prop = u_getIntPropertyValue(character, UCHAR_BLOCK);
    const char *blockNameChars = u_getPropertyValueName(UCHAR_BLOCK, prop, U_LONG_PROPERTY_NAME);
    
    // sanitize
    // -> This is actually a dirty workaround to make the block name the same as the Apple's block naming rule.
    //    Otherwise, we cannot localize block name correctly. (2015-11 by 1024jp)
    NSString *blockName = [NSString stringWithUTF8String:blockNameChars];
    blockName = [blockName stringByReplacingOccurrencesOfString:@"_" withString:@" "];
    blockName = [blockName stringByReplacingOccurrencesOfString:@" ([A-Z])$" withString:@"-$1"
                                                        options:NSRegularExpressionSearch range:NSMakeRange(0, [blockName length])];
    blockName = [blockName stringByReplacingOccurrencesOfString:@"Extension-" withString:@"Ext. "
                                                        options:NSRegularExpressionSearch range:NSMakeRange(0, [blockName length])];
    
    return blockName;
}


/// cast NSNumber to UTF32Char
UTF32Char toUTF32Char(NSNumber *number) { return (UTF32Char)[number unsignedIntValue]; }

@end
