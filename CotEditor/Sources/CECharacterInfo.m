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

@property (nonatomic, nullable, copy) NSString *variationSelectorAdditional;


// readonly
@property (nonatomic, readwrite, nonnull, copy) NSString *string;
@property (nonatomic, readwrite, nonnull, copy) NSArray<CEUnicodeCharacter *> *unicodes;
@property (nonatomic, readwrite, nonnull, copy) NSString *unicode;
@property (nonatomic, readwrite, getter=isComplexChar) BOOL complexChar;

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
        _unicodes = [CECharacterInfo decomposeIntoUnicodes:string];
        
        // check variation selector
        if ([_unicodes count] == 2) {
            UTF32Char character = [[_unicodes lastObject] character];
            
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
        return [NSString stringWithFormat:NSLocalizedStringFromTable(@"<a letter consisting of %d characters>", @"Unicode", nil),
                [[self unicodes] count]];
    }
    
    // unicode character name
    NSString *unicodeName = [[[self unicodes] firstObject] name];
    if ([self variationSelectorAdditional]) {
        unicodeName = [NSString stringWithFormat:@"%@ (%@)", unicodeName,
                       NSLocalizedStringFromTable([self variationSelectorAdditional], @"Unicode", nil)];
    }
    
    return unicodeName;
}



#pragma mark Private Methods

// ------------------------------------------------------
/// devide given string into CEUnicodeCharacter objects
+ (nonnull NSArray<CEUnicodeCharacter *> *)decomposeIntoUnicodes:(nonnull NSString *)string
// ------------------------------------------------------
{
    NSMutableArray<CEUnicodeCharacter *> *unicodes = [NSMutableArray array];
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
        
        [unicodes addObject:[CEUnicodeCharacter unicodeCharacterWithCharacter:utf32Char]];
    }
    
    return [unicodes copy];
}

@end
