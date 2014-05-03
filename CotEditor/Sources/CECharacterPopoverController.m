/*
 =================================================
 CECharacterPopoverController
 (for CotEditor)
 
 Copyright (C) 2014 CotEditor Project
 http://coteditor.github.io
 =================================================
 
 encoding="UTF-8"
 Created:2014-05-01 by 1024jp
 
 -------------------------------------------------
 
 This program is free software; you can redistribute it and/or
 modify it under the terms of the GNU General Public License
 as published by the Free Software Foundation; either version 2
 of the License, or (at your option) any later version.
 
 This program is distributed in the hope that it will be useful,
 but WITHOUT ANY WARRANTY; without even the implied warranty of
 MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 GNU General Public License for more details.
 
 You should have received a copy of the GNU General Public License
 along with this program; if not, write to the Free Software
 Foundation, Inc., 59 Temple Place - Suite 330, Boston, MA  02111-1307, USA.
 
 
 =================================================
 */

#import "CECharacterPopoverController.h"


// variation Selector
unichar const  textSequenceChar = 0xFE0E;
unichar const emojiSequenceChar = 0xFE0F;


@interface CECharacterPopoverController ()

@property (nonatomic, weak) NSPopover *popover;
@property (nonatomic, copy) NSString *glyph;
@property (nonatomic, copy) NSString *unicodeName;
@property (nonatomic, copy) NSString *unicode;

@end




#pragma mark -

@implementation CECharacterPopoverController

#pragma mark Class Methods

// ------------------------------------------------------
/// 1文字かチェック
+ (BOOL)isSingleCharacter:(NSString *)string
// ------------------------------------------------------
{
    if ([string length] == 0) { return NO; }
    
    NSRange composedRange = [string rangeOfComposedCharacterSequenceAtIndex:0];
    
    return ([string length] == composedRange.length);
}


// ------------------------------------------------------
/// サロゲートペアかどうか
+ (BOOL)isSurrogatePair:(NSString *)string
// ------------------------------------------------------
{
    if ([string rangeOfComposedCharacterSequenceAtIndex:0].length == 2) {
        unichar firstChar = [string characterAtIndex:0];
        unichar secondChar = [string characterAtIndex:1];
        
        return (CFStringIsSurrogateHighCharacter(firstChar) && CFStringIsSurrogateLowCharacter(secondChar));
    }
    return NO;
}



#pragma mark Superclass Methods

// ------------------------------------------------------
/// 初期化
- (instancetype)initWithCharacter:(NSString *)character
// ------------------------------------------------------
{
    self = [super initWithNibName:@"CharacterPopover" bundle:nil];
    if (self) {
        [self setGlyph:character];
        
        NSUInteger length = [character length];
        BOOL isLigature;
        BOOL isSurrogatePair;
        
        // unicode hex
        NSString *unicode;
        NSMutableArray *unicodes = [NSMutableArray array];
        for (NSUInteger i = 0; i < length; i++) {
            [unicodes addObject:[NSString stringWithFormat:@"U+%04X", [character characterAtIndex:i]]];
        }
        
        /// surrogat pair (with variation sequence)
        if (length >= 2 && [[self class] isSurrogatePair:[character substringWithRange:NSMakeRange(0, 2)]]) {
            isSurrogatePair = YES;
            unichar high = [character characterAtIndex:0];
            unichar low  = [character characterAtIndex:1];
            UTF32Char pair = CFStringGetLongCharacterForSurrogatePair(high, low);
            
            unicode = [NSString stringWithFormat:@"U+%04lX (U+%04X U+%04X)", (long)pair, high, low];
            [unicodes removeObjectsInRange:NSMakeRange(0, 2)];
            [unicodes insertObject:unicode atIndex:0];
        }
        
        isLigature = ((isSurrogatePair && (length > 2)) || (!isSurrogatePair && (length > 1)));
        [self setUnicode:[unicodes componentsJoinedByString:@" "]];
        
        // emoji variation check
        NSString *emojiStyle;
        if (length == 2 || (isSurrogatePair && length == 3)) {
            switch ([character characterAtIndex:(length - 1)]) {
                case emojiSequenceChar:
                    emojiStyle = @"Emoji Style";
                    isLigature = NO;
                    break;
                
                case textSequenceChar:
                    emojiStyle = @"Text Style";
                    isLigature = NO;
                    break;
                    
                default:
                    break;
            }
        }
        
        if (isLigature) {
            // ligature message (ただし正確にはリガチャとは限らないので、letterとぼかしている)
            [self setUnicodeName:[NSString stringWithFormat:NSLocalizedString(@"<a letter consisting of %d characters>", nil), length]];
            
        } else {
            // unicode character name
            NSMutableString *mutableUnicodeName = [character mutableCopy];
            CFStringTransform((__bridge CFMutableStringRef)mutableUnicodeName, NULL, CFSTR("Any-Name"), NO);
            
            NSRegularExpression *regex = [NSRegularExpression regularExpressionWithPattern:@"\\{(.+?)\\}" options:0 error:nil];
            NSTextCheckingResult *firstMatch = [regex firstMatchInString:mutableUnicodeName options:0
                                                                   range:NSMakeRange(0, [mutableUnicodeName length])];
            [self setUnicodeName:[mutableUnicodeName substringWithRange:[firstMatch rangeAtIndex:1]]];
            
            if (emojiStyle) {
                [self setUnicodeName:[NSString stringWithFormat:@"%@ (%@)", [self unicodeName],
                                      NSLocalizedString(emojiStyle, nil)]];
            }
        }
    }
    return self;
}


// ------------------------------------------------------
/// 後片付け
- (void)dealloc
// ------------------------------------------------------
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}



#pragma mark Public Methods

// ------------------------------------------------------
/// popover を表示
- (void)showPopoverRelativeToRect:(NSRect)positioningRect inView:(NSTextView *)parentView
// ------------------------------------------------------
{
    NSPopover *popover = [[NSPopover alloc] init];
    [popover setContentViewController:self];
    [popover setDelegate:self];
    [popover showRelativeToRect:positioningRect ofView:parentView preferredEdge:NSMinYEdge];
    [self setPopover:popover];
    
    // 選択範囲が変更されたらポップオーバーを閉じる
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(closePopover:)
                                                 name:NSTextViewDidChangeSelectionNotification
                                               object:parentView];
    
    // 別のポップオーバーが表示されるならポップオーバーを閉じる
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(closePopover:)
                                                 name:NSPopoverWillShowNotification
                                               object:nil];
}



#pragma mark Private Methods

// ------------------------------------------------------
/// popover を閉じる
- (void)closePopover:(id)sender
// ------------------------------------------------------
{
    if ([[self popover] isShown]) {
        [[self popover] performClose:sender];
    }
}

@end
