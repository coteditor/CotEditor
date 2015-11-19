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

// emoji modifiers
static const UTF32Char kType12EmojiModifierChar = 0x1F3FB; // Emoji Modifier Fitzpatrick type-1-2
static const UTF32Char kType3EmojiModifierChar = 0x1F3FC;  // Emoji Modifier Fitzpatrick type-3
static const UTF32Char kType4EmojiModifierChar = 0x1F3FD;  // Emoji Modifier Fitzpatrick type-4
static const UTF32Char kType5EmojiModifierChar = 0x1F3FE;  // Emoji Modifier Fitzpatrick type-5
static const UTF32Char kType6EmojiModifierChar = 0x1F3FF;  // Emoji Modifier Fitzpatrick type-6


@interface CECharacterInfo ()

@property (nonatomic, readwrite, nonnull, copy) NSString *string;
@property (nonatomic, readwrite, nonnull, copy) NSString *unicode;
@property (nonatomic, readwrite, nonnull, copy) NSString *unicodeName;
@property (nonatomic, readwrite, nullable, copy) NSString *unicodeGroupName;

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
+ (nullable CECharacterInfo *)characterWithString:(nonnull NSString *)string
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
        _unicodes = [self decomposeIntoHexCodes:string];
        
        BOOL isMultipleChars = NO;
        
        // check variation selector
        NSUInteger length = [string length];
        NSString *variationSelectorAdditional;
        if ([_unicodes count] == 2) {
            unichar lastChar = [string characterAtIndex:(length - 1)];
            if (lastChar == kEmojiSequenceChar) {
                variationSelectorAdditional = @"Emoji Style";
            } else if (lastChar == kTextSequenceChar) {
                variationSelectorAdditional = @"Text Style";
            } else if ((lastChar >= 0x180B && lastChar <= 0x180D) ||
                       (lastChar >= 0xFE00 && lastChar <= 0xFE0D))
            {
                variationSelectorAdditional = @"Variant";
            } else {
                unichar highSurrogate = [string characterAtIndex:(length - 2)];
                unichar lowSurrogate = [string characterAtIndex:(length - 1)];
                if (CFStringIsSurrogateHighCharacter(highSurrogate) &&
                    CFStringIsSurrogateLowCharacter(lowSurrogate))
                {
                    UTF32Char pair = CFStringGetLongCharacterForSurrogatePair(highSurrogate, lowSurrogate);
                    
                    switch (pair) {
                        case kType12EmojiModifierChar:
                            variationSelectorAdditional = @"Skin Tone I-II";  // Light Skin Tone
                            break;
                        case kType3EmojiModifierChar:
                            variationSelectorAdditional = @"Skin Tone III";  // Medium Light Skin Tone
                            break;
                        case kType4EmojiModifierChar:
                            variationSelectorAdditional = @"Skin Tone IV";  // Medium Skin Tone
                            break;
                        case kType5EmojiModifierChar:
                            variationSelectorAdditional = @"Skin Tone V";  // Medium Dark Skin Tone
                            break;
                        case kType6EmojiModifierChar:
                            variationSelectorAdditional = @"Skin Tone VI";  // Dark Skin Tone
                            break;
                        default:
                            if (pair >= 0xE0100 && pair <= 0xE01EF) {
                                variationSelectorAdditional = @"Variant";
                            } else {
                                isMultipleChars = YES;
                            }
                            break;
                    }
                }
            }
        } else if ([_unicodes count] > 2) {
            isMultipleChars = YES;
        }
        
        if (isMultipleChars) {
            // number of characters message
            _unicodeName = [NSString stringWithFormat:NSLocalizedString(@"<a letter consisting of %d characters>", nil), [_unicodes count]];
            
        } else {
            // unicode character name
            NSMutableString *unicodeName = [string mutableCopy];
            // You can't use kCFStringTransformToUnicodeName instead of `Any-Name` here,
            // because some characters (e.g. normal `a`) don't return their name when use this constant.
            CFStringTransform((__bridge CFMutableStringRef)unicodeName, NULL, CFSTR("Any-Name"), NO);
            
            NSRegularExpression *regex = [NSRegularExpression regularExpressionWithPattern:@"\\{(.+?)\\}" options:0 error:nil];
            NSTextCheckingResult *firstMatch = [regex firstMatchInString:unicodeName options:0
                                                                   range:NSMakeRange(0, [unicodeName length])];
            _unicodeName = [unicodeName substringWithRange:[firstMatch rangeAtIndex:1]];
            
            if (variationSelectorAdditional) {
                _unicodeName = [NSString stringWithFormat:@"%@ (%@)", _unicodeName,
                                NSLocalizedString(variationSelectorAdditional, nil)];
            }
            
            const char *groupName = getUnicodeGroup(string);
            _unicodeGroupName = [[NSString stringWithUTF8String:groupName] stringByReplacingOccurrencesOfString:@"_" withString:@" "];
        }
    }
    return self;
}



#pragma mark Private Methods

// ------------------------------------------------------
/// unicode hex numbers
- (nonnull NSArray<NSString *> *)decomposeIntoHexCodes:(nonnull NSString *)string
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
/// get Unicode group the given character belong to
const char *getUnicodeGroup(NSString *string)
// ------------------------------------------------------
{
    // get UTF32 form
    UTF32Char utf32;
    if ([string getBytes:&utf32 maxLength:4 usedLength:NULL encoding:NSUTF32LittleEndianStringEncoding options:0 range:NSMakeRange(0, 2) remainingRange:NULL]) {
        utf32 = NSSwapLittleIntToHost(utf32);
    }
    
    // get Unicode group
    int32_t prop = u_getIntPropertyValue(utf32, UCHAR_BLOCK);
    return u_getPropertyValueName(UCHAR_BLOCK, prop, U_LONG_PROPERTY_NAME);
}

@end
