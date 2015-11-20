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

Boolean CEStringIsVariantSelector(UniChar character) {
    return (character >= 0x180B && character <= 0x180D) || (character >= 0xFE00 && character <= 0xFE0F);
}
Boolean CEStringIsSurrogatePairedVariantSelector(UTF32Char character) {
    return (character >= 0xE0100 && character <= 0xE01EF);
}

// emoji modifiers
static const UTF32Char kType12EmojiModifierChar = 0x1F3FB; // Emoji Modifier Fitzpatrick type-1-2
static const UTF32Char kType3EmojiModifierChar = 0x1F3FC;  // Emoji Modifier Fitzpatrick type-3
static const UTF32Char kType4EmojiModifierChar = 0x1F3FD;  // Emoji Modifier Fitzpatrick type-4
static const UTF32Char kType5EmojiModifierChar = 0x1F3FE;  // Emoji Modifier Fitzpatrick type-5
static const UTF32Char kType6EmojiModifierChar = 0x1F3FF;  // Emoji Modifier Fitzpatrick type-6


@interface CECharacterInfo ()

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
        _unicodes = [CECharacterInfo decomposeIntoHexCodes:string];
        
        // check variation selector
        NSUInteger length = [string length];
        if ([_unicodes count] == 2) {
            unichar lastChar = [string characterAtIndex:(length - 1)];
            if (lastChar == kEmojiSequenceChar) {
                _variationSelectorAdditional = @"Emoji Style";
            } else if (lastChar == kTextSequenceChar) {
                _variationSelectorAdditional = @"Text Style";
            } else if (CEStringIsVariantSelector(lastChar)) {
                _variationSelectorAdditional = @"Variant";
            } else {
                unichar highSurrogate = [string characterAtIndex:(length - 2)];
                unichar lowSurrogate = [string characterAtIndex:(length - 1)];
                if (CFStringIsSurrogateHighCharacter(highSurrogate) &&
                    CFStringIsSurrogateLowCharacter(lowSurrogate))
                {
                    UTF32Char pair = CFStringGetLongCharacterForSurrogatePair(highSurrogate, lowSurrogate);
                    
                    switch (pair) {
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
                            if (CEStringIsSurrogatePairedVariantSelector(pair)) {
                                _variationSelectorAdditional = @"Variant";
                            } else {
                                _complexChar = YES;
                            }
                            break;
                    }
                }
            }
        } else if ([_unicodes count] > 2) {
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
        return [NSString stringWithFormat:NSLocalizedString(@"<a letter consisting of %d characters>", nil),
                [[self unicodes] count]];
    }
    
    // unicode character name
    NSString *unicodeName = [self unicodeName];
    if ([self variationSelectorAdditional]) {
        unicodeName = [NSString stringWithFormat:@"%@ (%@)", [self unicodeName],
                       NSLocalizedString([self variationSelectorAdditional], nil)];
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
        _unicodeBlockName = [CECharacterInfo getUnicodeBlockName:[self string]];
    }
    
    return _unicodeBlockName;
}


// ------------------------------------------------------
/// getter of localized unicode block name
- (nullable NSString *)localizedUnicodeBlockName
// ------------------------------------------------------
{
    if (![self unicodeBlockName]) { return nil; }
    
    return NSLocalizedStringFromTable([self unicodeBlockName], @"UnicodeBlocks", nil);
}



#pragma mark Private Methods

// ------------------------------------------------------
/// unicode hex numbers
+ (nonnull NSArray<NSString *> *)decomposeIntoHexCodes:(nonnull NSString *)string
// ------------------------------------------------------
{
    NSMutableArray<NSString *> *unicodes = [NSMutableArray array];
    NSUInteger length = [string length];
    
    for (NSUInteger i = 0; i < length; i++) {
        unichar theChar = [string characterAtIndex:i];
        unichar nextChar = (length > i + 1) ? [string characterAtIndex:i + 1] : 0;
        NSString *unicode;
        
        if (CFStringIsSurrogateHighCharacter(theChar) && CFStringIsSurrogateLowCharacter(nextChar)) {
            UTF32Char pair = CFStringGetLongCharacterForSurrogatePair(theChar, nextChar);
            unicode = [NSString stringWithFormat:@"U+%04tX (U+%04X U+%04X)", pair, theChar, nextChar];
            i++;
            
        } else {
            unicode = [NSString stringWithFormat:@"U+%04X", theChar];
        }
        
        [unicodes addObject:unicode];
    }
    
    return [unicodes copy];
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
+ (nonnull NSString *)getUnicodeBlockName:(nonnull NSString *)string
// ------------------------------------------------------
{
    // get UTF32 form
    UTF32Char utf32;
    if ([string getBytes:&utf32 maxLength:4 usedLength:NULL encoding:NSUTF32LittleEndianStringEncoding options:0 range:NSMakeRange(0, 2) remainingRange:NULL]) {
        utf32 = NSSwapLittleIntToHost(utf32);
    }
    
    // get Unicode block
    int32_t prop = u_getIntPropertyValue(utf32, UCHAR_BLOCK);
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

@end
