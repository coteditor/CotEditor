/*
 ==============================================================================
 CEGlyphPopoverController
 
 CotEditor
 http://coteditor.com
 
 Created on 2014-05-01 by 1024jp
 encoding="UTF-8"
 ------------------------------------------------------------------------------
 
 © 2014 CotEditor Project
 
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


// variation Selector
static const unichar  kTextSequenceChar = 0xFE0E;
static const unichar kEmojiSequenceChar = 0xFE0F;


@interface CEGlyphPopoverController ()

@property (nonatomic, copy) NSString *glyph;
@property (nonatomic, copy) NSString *unicodeName;
@property (nonatomic, copy) NSString *unicode;

@end




#pragma mark -

@implementation CEGlyphPopoverController

#pragma mark Public Methods

// ------------------------------------------------------
/// failable initialize
- (instancetype)initWithCharacter:(NSString *)character
// ------------------------------------------------------
{
    if ([character numberOfComposedCharacters] != 1) { return nil; }
    
    self = [super initWithNibName:@"GlyphPopover" bundle:nil];
    if (self) {
        [self setGlyph:character];
        
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
        [self setUnicode:[unicodes componentsJoinedByString:@"  "]];
        
        BOOL isMultipleChars = NO;
        
        // check valiation selector
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
                    if (pair >= 0xE0100 && pair <= 0xE01EF) {
                        variationSelectorAdditional = @"Variant";
                    } else {
                        isMultipleChars = YES;
                    }
                }
            }
        } else if ([unicodes count] > 2) {
            isMultipleChars = YES;
        }
        
        if (isMultipleChars) {
            // number of characters message
            [self setUnicodeName:[NSString stringWithFormat:NSLocalizedString(@"<a letter consisting of %d characters>", nil), [unicodes count]]];
            
        } else {
            // unicode character name
            NSMutableString *unicodeName = [character mutableCopy];
            CFStringTransform((__bridge CFMutableStringRef)unicodeName, NULL, CFSTR("Any-Name"), NO);
            
            NSRegularExpression *regex = [NSRegularExpression regularExpressionWithPattern:@"\\{(.+?)\\}" options:0 error:nil];
            NSTextCheckingResult *firstMatch = [regex firstMatchInString:unicodeName options:0
                                                                   range:NSMakeRange(0, [unicodeName length])];
            [self setUnicodeName:[unicodeName substringWithRange:[firstMatch rangeAtIndex:1]]];
            
            if (variationSelectorAdditional) {
                [self setUnicodeName:[NSString stringWithFormat:@"%@ (%@)", [self unicodeName],
                                      NSLocalizedString(variationSelectorAdditional, nil)]];
            }
        }
    }
    return self;
}


// ------------------------------------------------------
/// show popover
- (void)showPopoverRelativeToRect:(NSRect)positioningRect ofView:(NSView *)parentView
// ------------------------------------------------------
{
    NSPopover *popover = [[NSPopover alloc] init];
    [popover setContentViewController:self];
    [popover setBehavior:NSPopoverBehaviorSemitransient];
    [popover showRelativeToRect:positioningRect ofView:parentView preferredEdge:NSMinYEdge];
    [[parentView window] makeFirstResponder:parentView];
}

@end
