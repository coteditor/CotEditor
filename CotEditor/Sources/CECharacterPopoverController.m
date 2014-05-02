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
    if ([string length] == 0 || [string length] > 2) { return NO; }
    
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
        
        // unicode hex
        NSString *unicode;
        if ([[self class] isSurrogatePair:character]) {
            unichar high = [character characterAtIndex:0];
            unichar low  = [character characterAtIndex:1];
            unsigned long uni = 0x10000 + (high - 0xD800) * 0x400 + (low - 0xDC00);
            unicode = [NSString stringWithFormat:@"U+%04lX (U+%04X U+%04X)", uni, high, low];
        } else if ([character length] == 1) {
            unicode = [NSString stringWithFormat:@"U+%04X", [character characterAtIndex:0]];
        } else {
            unicode = [NSString stringWithFormat:@"U+%04X U+%04X", [character characterAtIndex:0],
                                                                   [character characterAtIndex:1]];
        }
        [self setUnicode:unicode];
        
        // unicode character name
        NSMutableString *mutableUnicodeName = [character mutableCopy];
        CFStringTransform((__bridge CFMutableStringRef)mutableUnicodeName, NULL, CFSTR("Any-Name"), NO);
        NSString *unicodeName = [[mutableUnicodeName stringByReplacingOccurrencesOfString:@"\\N{" withString:@""]
                                 stringByReplacingOccurrencesOfString:@"}" withString:@""];
        [self setUnicodeName:unicodeName];
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
    [popover  showRelativeToRect:positioningRect ofView:parentView preferredEdge:NSMinYEdge];
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
