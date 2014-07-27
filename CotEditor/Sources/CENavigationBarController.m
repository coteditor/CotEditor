/*
 =================================================
 CENavigationBarController
 (for CotEditor)
 
 Copyright (C) 2004-2007 nakamuxu.
 Copyright (C) 2014 CotEditor Project
 http://coteditor.github.io
 =================================================
 
 encoding="UTF-8"
 Created on 2005-08-22 by nakamuxu
 
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

#import "CENavigationBarController.h"
#import "CEEditorView.h"
#import "constants.h"


@interface CENavigationBarController ()

@property (nonatomic, weak) IBOutlet NSPopUpButton *outlineMenu;
@property (nonatomic, weak) IBOutlet NSButton *prevButton;
@property (nonatomic, weak) IBOutlet NSButton *nextButton;
@property (nonatomic, weak) IBOutlet NSButton *openSplitButton;
@property (nonatomic, weak) IBOutlet NSButton *closeSplitButton;
@property (nonatomic, weak) IBOutlet NSLayoutConstraint *heightConstraint;

@property (nonatomic, weak) IBOutlet NSProgressIndicator *outlineIndicator;
@property (nonatomic, weak) IBOutlet NSTextField *outlineLoadingMessage;

@end



#pragma mark -

@implementation CENavigationBarController

#pragma mark Superclass Methods

//=======================================================
// Superclass method
//
//=======================================================

// ------------------------------------------------------
/// designated initializer
- (instancetype)init
// ------------------------------------------------------
{
    return [super initWithNibName:@"NavigationBar" bundle:nil];
}


// ------------------------------------------------------
/// awake from nib
- (void)awakeFromNib
// ------------------------------------------------------
{
    [[self prevButton] setHidden:YES];
    [[self nextButton] setHidden:YES];
    [[self closeSplitButton] setHidden:YES];
    
    [[self outlineIndicator] setUsesThreadedAnimation:YES];
    [[self outlineLoadingMessage] setHidden:YES];
}



#pragma mark Public Methods

//=======================================================
// Public method
//
//=======================================================

// ------------------------------------------------------
/// set to show navigation bar.
- (void)setShowNavigationBar:(BOOL)showNavigationBar
// ------------------------------------------------------
{
    if (showNavigationBar != [self showNavigationBar]) {
        _showNavigationBar = showNavigationBar;
        
        CGFloat height = [self showNavigationBar] ? k_navigationBarHeight : 0.0;
        [self setHeight:height];
    }
}


// ------------------------------------------------------
/// 配列を元にアウトラインメニューを生成
- (void)setOutlineMenuArray:(NSArray *)outlineMenuArray
// ------------------------------------------------------
{
    // stop outine indicator
    [[self outlineIndicator] stopAnimation:self];
    [[self outlineLoadingMessage] setHidden:YES];
    
    [[self outlineMenu] removeAllItems];
    
    if ([outlineMenuArray count] == 0) {
        [[self outlineMenu] setHidden:YES];
        [[self prevButton] setHidden:YES];
        [[self nextButton] setHidden:YES];
        
        return;
    }
    
    NSMenu *menu = [[self outlineMenu] menu];
    NSFont *defaultFont = [NSFont fontWithName:k_navigationBarFontName
                                          size:[NSFont smallSystemFontSize]];
    
    for (NSDictionary *outlineItem in outlineMenuArray) {
        if ([[outlineItem valueForKey:k_outlineMenuItemTitle] isEqualToString:CESeparatorString]) {
            [menu addItem:[NSMenuItem separatorItem]];
            
        } else {
            NSFontManager *fontManager = [NSFontManager sharedFontManager];
            NSNumber *underlineMaskNumber = [outlineItem[k_outlineMenuItemUnderlineMask] copy];
            NSFontTraitMask fontMask = ([[outlineItem valueForKey:k_outlineMenuItemFontBold] boolValue]) ? NSBoldFontMask : 0;
            NSFont *font = [fontManager convertFont:defaultFont toHaveTrait:fontMask];
            
            NSMutableAttributedString *title = [[NSMutableAttributedString alloc]
                                                initWithString:outlineItem[k_outlineMenuItemTitle]
                                                attributes:@{NSFontAttributeName: font}];
            if (underlineMaskNumber) {
                [title addAttribute:NSUnderlineStyleAttributeName
                              value:underlineMaskNumber
                              range:NSMakeRange(0, [title length])];
            }
            if ([outlineItem[k_outlineMenuItemFontItalic] boolValue]) {
                [title addAttribute:NSFontAttributeName
                              value:[fontManager convertFont:font toHaveTrait:NSItalicFontMask]
                              range:NSMakeRange(0, [title length])];
            }
            NSMenuItem *menuItem = [[NSMenuItem alloc] initWithTitle:@" "
                                                              action:@selector(setSelectedRangeWithNSValue:)
                                                       keyEquivalent:@""];
            [menuItem setTarget:[[self masterView] textView]];
            [menuItem setAttributedTitle:title];
            [menuItem setRepresentedObject:[outlineItem valueForKey:k_outlineMenuItemRange]];
            [menu addItem:menuItem];
        }
    }
    // （メニューの再描画時のちらつき防止のため、ここで選択項目をセットする 2008.05.17.）
    [self selectOutlineMenuItemWithRange:[[[self masterView] editorView] selectedRange]];
    [[self outlineMenu] setMenu:menu];
    [[self outlineMenu] setHidden:NO];
    [[self prevButton] setHidden:NO];
    [[self nextButton] setHidden:NO];
}


// ------------------------------------------------------
/// アウトラインメニューの選択項目を設定
- (void)selectOutlineMenuItemWithRange:(NSRange)range
// ------------------------------------------------------
{
    if (![[self outlineMenu] isEnabled]) { return; }
    
    NSMenu *menu = [[self outlineMenu] menu];
    NSInteger i;
    NSInteger count = [menu numberOfItems];
    NSUInteger location = range.location;
    if (count < 1) { return; }

    if (NSEqualRanges(range, NSMakeRange(0, 0))) {
        i = 1;
    } else {
        for (i = 1; i < count; i++) {
            NSMenuItem *menuItem = [menu itemAtIndex:i];
            NSUInteger markedLocation = [[menuItem representedObject] rangeValue].location;
            if (markedLocation > location) {
                break;
            }
        }
    }
    // ループを抜けた時点で「次のアイテムインデックス」になっているので、減ずる
    i--;
    // セパレータを除外
    while ([[[self outlineMenu] itemAtIndex:i] isSeparatorItem]) {
        i--;
        if (i < 0) {
            break;
        }
    }
    [[self outlineMenu] selectItemAtIndex:i];
    [self updatePrevNextButtonEnabled];
}


// ------------------------------------------------------
/// 前／次移動ボタンの有効／無効を切り替え
- (void)updatePrevNextButtonEnabled
// ------------------------------------------------------
{
    [[self prevButton] setEnabled:[self canSelectPrevItem]];
    [[self nextButton] setEnabled:[self canSelectNextItem]];
}


// ------------------------------------------------------
/// can select prev item in outline menu?
- (BOOL)canSelectPrevItem
// ------------------------------------------------------
{
    return ([[self outlineMenu] indexOfSelectedItem] > 0);
}


// ------------------------------------------------------
/// can select next item in outline menu?
- (BOOL)canSelectNextItem
// ------------------------------------------------------
{
    for (NSInteger i = ([[self outlineMenu] indexOfSelectedItem] + 1); i < [[self outlineMenu] numberOfItems]; i++) {
        if (![[[self outlineMenu] itemAtIndex:i] isSeparatorItem]) {
            return YES;
        }
    }
    return NO;
}


// ------------------------------------------------------
/// start displaying outline indicator
- (void)showOutlineIndicator
// ------------------------------------------------------
{
    if (![[self outlineMenu] isEnabled]) {
        [[self outlineIndicator] startAnimation:self];
        [[self outlineLoadingMessage] setHidden:NO];
    }
}


// ------------------------------------------------------
/// set closeSplitButton enabled or disabled
- (void)setCloseSplitButtonEnabled:(BOOL)enabled
// ------------------------------------------------------
{
    [[self closeSplitButton] setHidden:!enabled];
}


// ------------------------------------------------------
/// set closeSplitButton enabled or disabled
- (void)setSplitOrientationVertical:(BOOL)isVertical
// ------------------------------------------------------
{
    NSString *imageName = isVertical ? @"openSplitButtonImgVertical" : @"openSplitButtonImg";
    
    [[self openSplitButton] setImage:[NSImage imageNamed:imageName]];
}



#pragma mark Action Messages

//=======================================================
// Action messages
//
//=======================================================

// ------------------------------------------------------
/// set select prev item of outline menu.
- (IBAction)selectPrevItem:(id)sender
// ------------------------------------------------------
{
    if (![self canSelectPrevItem]) { return; }
    
    NSInteger targetIndex = [[self outlineMenu] indexOfSelectedItem] - 1;
    
    while ([[[self outlineMenu] itemAtIndex:targetIndex] isSeparatorItem]) {
        targetIndex--;
        if (targetIndex < 0) {
            break;
        }
    }
    [[[self outlineMenu] menu] performActionForItemAtIndex:targetIndex];
}


// ------------------------------------------------------
/// set select next item of outline menu.
- (IBAction)selectNextItem:(id)sender
// ------------------------------------------------------
{
    if (![self canSelectNextItem]) { return; }
    
    NSInteger targetIndex = [[self outlineMenu] indexOfSelectedItem] + 1;
    NSInteger maxIndex = [[self outlineMenu] numberOfItems] - 1;
    
    while ([[[self outlineMenu] itemAtIndex:targetIndex] isSeparatorItem]) {
        targetIndex++;
        if (targetIndex > maxIndex) {
            break;
        }
    }
    [[[self outlineMenu] menu] performActionForItemAtIndex:targetIndex];
}



#pragma mark Private Methods

//=======================================================
// Private method
//
//=======================================================

// ------------------------------------------------------
/// set view height.
- (void)setHeight:(CGFloat)height
// ------------------------------------------------------
{
    [[self heightConstraint] setConstant:height];
}

@end
