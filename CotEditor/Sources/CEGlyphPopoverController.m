/*
 ==============================================================================
 CEGlyphPopoverController
 
 CotEditor
 http://coteditor.com
 
 Created on 2014-05-01 by 1024jp
 encoding="UTF-8"
 ------------------------------------------------------------------------------
 
 © 2014-2015 1024jp
 
 This program is free software; you can redistribute it and/or modify it under
 the terms of the GNU General Public License as published by the Free Software
 Foundation; either version 2 of the License, or (at your option) any later
 version.
 
 This program is distributed in the hope that it will be useful, but WITHOUT
 ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS
 FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.
 
 You should have received a copy of the GNU General Public License along with
 this program; if not, write to the Free Software Foundation, Inc., 59 Temple
 Place - Suite 330, Boston, MA  02111-1307, USA.
 
 ==============================================================================
 */

#import "CEGlyphPopoverController.h"


// variation selectors
static const unichar  kTextSequenceChar = 0xFE0E;
static const unichar kEmojiSequenceChar = 0xFE0F;

// emoji modifiers
static const UTF32Char kType12EmojiModifierChar = 0x1F3FB; // Emoji Modifier Fitzpatrick type-1-2
static const UTF32Char kType3EmojiModifierChar = 0x1F3FC;  // Emoji Modifier Fitzpatrick type-3
static const UTF32Char kType4EmojiModifierChar = 0x1F3FD;  // Emoji Modifier Fitzpatrick type-4
static const UTF32Char kType5EmojiModifierChar = 0x1F3FE;  // Emoji Modifier Fitzpatrick type-5
static const UTF32Char kType6EmojiModifierChar = 0x1F3FF;  // Emoji Modifier Fitzpatrick type-6



@interface CEGlyphPopoverController () <NSPopoverDelegate>

@property (nonatomic, nonnull, copy) NSString *glyph;
@property (nonatomic, nonnull, copy) NSString *unicodeName;
@property (nonatomic, nonnull, copy) NSString *unicode;

@end




#pragma mark -

@implementation CEGlyphPopoverController

#pragma mark Public Methods

// ------------------------------------------------------
/// failable initialize
- (nullable instancetype)initWithCharacter:(nonnull NSString *)character
// ------------------------------------------------------
{
    if ([character numberOfComposedCharacters] != 1) { return nil; }
    
    self = [super initWithNibName:@"GlyphPopover" bundle:nil];
    if (self) {
        _glyph = character;
        
        NSUInteger length = [character length];
        
        // unicode hex
        NSMutableArray *unicodes = [NSMutableArray array];
        for (NSUInteger i = 0; i < length; i++) {
            unichar theChar = [character characterAtIndex:i];
            unichar nextChar = (length > i + 1) ? [character characterAtIndex:i + 1] : 0;
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
        _unicode = [unicodes componentsJoinedByString:@"  "];
        
        BOOL isMultipleChars = NO;
        
        // check variation selector
        NSString *variationSelectorAdditional;
        if ([unicodes count] == 2) {
            unichar lastChar = [character characterAtIndex:(length - 1)];
            if (lastChar == kEmojiSequenceChar) {
                variationSelectorAdditional = @"Emoji Style";
            } else if (lastChar == kTextSequenceChar) {
                variationSelectorAdditional = @"Text Style";
            } else if ((lastChar >= 0x180B && lastChar <= 0x180D) ||
                       (lastChar >= 0xFE00 && lastChar <= 0xFE0D))
            {
                variationSelectorAdditional = @"Variant";
            } else {
                unichar highSurrogate = [character characterAtIndex:(length - 2)];
                unichar lowSurrogate = [character characterAtIndex:(length - 1)];
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
        } else if ([unicodes count] > 2) {
            isMultipleChars = YES;
        }
        
        if (isMultipleChars) {
            // number of characters message
            _unicodeName = [NSString stringWithFormat:NSLocalizedString(@"<a letter consisting of %d characters>", nil), [unicodes count]];
            
        } else {
            // unicode character name
            NSMutableString *unicodeName = [character mutableCopy];
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
        }
    }
    return self;
}


// ------------------------------------------------------
/// show popover
- (void)showPopoverRelativeToRect:(NSRect)positioningRect ofView:(nonnull NSView *)parentView
// ------------------------------------------------------
{
    NSPopover *popover = [[NSPopover alloc] init];
    [popover setContentViewController:self];
    [popover setDelegate:self];
    [popover setBehavior:NSPopoverBehaviorSemitransient];
    [popover showRelativeToRect:positioningRect ofView:parentView preferredEdge:NSMinYEdge];
    [[parentView window] makeFirstResponder:parentView];
}



#pragma mark Delegate

//=======================================================
// NSPopoverDelegate
//=======================================================

// ------------------------------------------------------
/// make popover detachable (on Yosemite and later)
- (BOOL)popoverShouldDetach:(NSPopover *)popover
// ------------------------------------------------------
{
    return YES;
}

@end
