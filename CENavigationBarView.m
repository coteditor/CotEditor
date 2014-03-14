/*
=================================================
CENavigationBarView
(for CotEditor)

 Copyright (C) 2004-2007 nakamuxu.
 Copyright (C) 2014 CotEditor Project
 http://coteditor.github.io
=================================================

encoding="UTF-8"
Created:2005.08.22

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

#import "CENavigationBarView.h"
#import "CEEditorView.h"
#import "CEOutlineMenuButton.h"
#import "constants.h"


@interface CENavigationBarView ()

@property (nonatomic, retain) CEOutlineMenuButton *outlineMenu;
@property (nonatomic, retain) NSButton *prevButton;
@property (nonatomic, retain) NSButton *nextButton;
@property (nonatomic, retain) NSButton *openSplitButton;
@property (nonatomic, retain) NSButton *closeSplitButton;

@end

#pragma mark -


//------------------------------------------------------------------------------------------




@implementation CENavigationBarView

// ------------------------------------------------------
- (id)initWithFrame:(NSRect)frame
// initialize
// ------------------------------------------------------
{
    self = [super initWithFrame:frame];
    
    if (self) {
        // setup outlineMenu
        NSRect outlineMenuFrame = frame;
        outlineMenuFrame.origin.x += k_outlineMenuLeftMargin;
        outlineMenuFrame.origin.y = 1.0;
        outlineMenuFrame.size.height -= 1.0;
        outlineMenuFrame.size.width = k_outlineMenuWidth;
        [self convertRect:outlineMenuFrame toView:self];
        [self setOutlineMenu:[[CEOutlineMenuButton allocWithZone:[self zone]] initWithFrame:outlineMenuFrame pullsDown:NO]]; // ===== alloc
        [[self outlineMenu] setAutoresizingMask:NSViewHeightSizable];

        // setup prevButton
        NSRect prevButtonFrame = outlineMenuFrame;
        prevButtonFrame.origin.x -= k_outlineButtonWidth;
        prevButtonFrame.size.width = k_outlineButtonWidth;
        [self convertRect:prevButtonFrame toView:self];
        [self setPrevButton:[[NSButton allocWithZone:[self zone]] initWithFrame:prevButtonFrame]]; // ===== alloc
        [[self prevButton] setButtonType:NSMomentaryPushInButton];
        [[self prevButton] setBordered:NO];
        [[self prevButton] setImagePosition:NSImageOnly];
        [[self prevButton] setAction:@selector(selectPrevItem)];
        [[self prevButton] setTarget:self];
        [[self prevButton] setToolTip:NSLocalizedString(@"Go Prev item", @"")];
        [[self prevButton] setAutoresizingMask:NSViewHeightSizable];

        // setup nextButton
        NSRect nextButtonFrame = outlineMenuFrame;
        nextButtonFrame.origin.x += NSWidth(outlineMenuFrame);
        nextButtonFrame.size.width = k_outlineButtonWidth;
        [self convertRect:nextButtonFrame toView:self];
        [self setNextButton:[[NSButton allocWithZone:[self zone]] initWithFrame:nextButtonFrame]]; // ===== alloc
        [[self nextButton] setButtonType:NSMomentaryPushInButton];
        [[self nextButton] setBordered:NO];
        [[self nextButton] setImagePosition:NSImageOnly];
        [[self nextButton] setAction:@selector(selectNextItem)];
        [[self nextButton] setTarget:self];
        [[self nextButton] setToolTip:NSLocalizedString(@"Go Next item", @"")];
        [[self nextButton] setAutoresizingMask:NSViewHeightSizable];

        // setup openSplitButton
        NSRect openSplitButtonFrame = frame;
        openSplitButtonFrame.origin.x += (NSWidth(frame) - [NSScroller scrollerWidth]);
        openSplitButtonFrame.origin.y = 1.0;
        openSplitButtonFrame.size.width = [NSScroller scrollerWidth];
        [self convertRect:openSplitButtonFrame toView:self];
        [self setOpenSplitButton:[[NSButton allocWithZone:[self zone]] initWithFrame:openSplitButtonFrame]]; // ===== alloc
        [[self openSplitButton] setButtonType:NSMomentaryPushInButton];
        [[self openSplitButton] setBordered:NO];
        [[self openSplitButton] setImagePosition:NSImageOnly];
        [[self openSplitButton] setAction:@selector(openSplitTextView:)];
        [[self openSplitButton] setAutoresizingMask:(NSViewHeightSizable | NSViewMinXMargin)];
        [[self openSplitButton] setImage:[NSImage imageNamed:@"openSplitButtonImg"]];
        [[self openSplitButton] setToolTip:NSLocalizedString(@"Open SplitView", @"")];
        [[self openSplitButton] setEnabled:YES];

        // setup closeSplitButton
        NSRect closeSplitButtonFrame = frame;
        closeSplitButtonFrame.origin.x += (NSWidth(frame) - [NSScroller scrollerWidth] * 2);
        closeSplitButtonFrame.origin.y = 1.0;
        closeSplitButtonFrame.size.width = [NSScroller scrollerWidth];
        [self convertRect:closeSplitButtonFrame toView:self];
        [self setCloseSplitButton:[[NSButton allocWithZone:[self zone]] initWithFrame:closeSplitButtonFrame]]; // ===== alloc
        [[self closeSplitButton] setButtonType:NSMomentaryPushInButton];
        [[self closeSplitButton] setBordered:NO];
        [[self closeSplitButton] setImagePosition:NSImageOnly];
        [[self closeSplitButton] setAction:@selector(closeSplitTextView:)];
        [[self closeSplitButton] setAutoresizingMask:(NSViewHeightSizable | NSViewMinXMargin)];
        [[self closeSplitButton] setImage:[NSImage imageNamed:@"closeSplitButtonImg"]];
        [[self closeSplitButton] setToolTip:NSLocalizedString(@"Close SplitView", @"")];
        [[self closeSplitButton] setHidden:YES];


        [self setAutoresizingMask:(NSViewWidthSizable | NSViewMinYMargin)];
        [self addSubview:[self outlineMenu]];
        [self addSubview:[self prevButton]];
        [self addSubview:[self nextButton]];
        [self addSubview:[self openSplitButton]];
        [self addSubview:[self closeSplitButton]];
    }
    return self;
}


// ------------------------------------------------------
- (void)dealloc
// clean up
// ------------------------------------------------------
{
    // masterView is not retain.
    [[self outlineMenu] release];
    [[self prevButton] release];
    [[self nextButton] release];
    [[self openSplitButton] release];
    [[self closeSplitButton] release];

    [super dealloc];
}


// ------------------------------------------------------
- (void)setShowNavigationBar:(BOOL)showNavigationBar
// set to show navigation bar.
// ------------------------------------------------------
{
    if (showNavigationBar != [self showNavigationBar]) {
        _showNavigationBar = showNavigationBar;
        
        CGFloat height = [self showNavigationBar] ? k_navigationBarHeight : 0.0;
        [self setHeight:height];
    }
}


// ------------------------------------------------------
- (void)setOutlineMenuArray:(NSArray *)outlineMenuArray
// 配列を元にアウトラインメニューを生成
// ------------------------------------------------------
{
    id values = [[NSUserDefaultsController sharedUserDefaultsController] values];
    NSMenu *menu;
    NSMenuItem *menuItem;
    NSFont *defaultFont = [NSFont fontWithName:[values valueForKey:k_key_navigationBarFontName]
                                          size:(CGFloat)[[values valueForKey:k_key_navigationBarFontSize] doubleValue]];

    NSFontManager *fontManager = [NSFontManager sharedFontManager];
    NSFont *font;
    NSMutableAttributedString *title;
    NSFontTraitMask fontMask;
    NSNumber *underlineMaskNumber;

    [[self outlineMenu] removeAllItems];
    if ([outlineMenuArray count] < 1) {
        [[self outlineMenu] setEnabled:NO];
        [[self prevButton] setEnabled:NO];
        [[self prevButton] setImage:nil];
        [[self nextButton] setEnabled:NO];
        [[self nextButton] setImage:nil];
    } else {
        menu = [[self outlineMenu] menu];
        for (NSDictionary *outlineItem in outlineMenuArray) {
            if ([[outlineItem valueForKey:k_outlineMenuItemTitle] isEqualToString:k_outlineMenuSeparatorSymbol]) {
                // セパレータ
                [menu addItem:[NSMenuItem separatorItem]];
            } else {
                underlineMaskNumber = [[outlineItem[k_outlineMenuItemUnderlineMask] copy] autorelease];
                fontMask = ([[outlineItem valueForKey:k_outlineMenuItemFontBold] boolValue]) ? NSBoldFontMask : 0;
                font = [fontManager convertFont:defaultFont toHaveTrait:fontMask];
                
                title = [[[NSMutableAttributedString alloc] initWithString:outlineItem[k_outlineMenuItemTitle]
                                                                attributes:@{NSFontAttributeName: font}] autorelease];
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
                menuItem = [[[NSMenuItem alloc] initWithTitle:@" "
                                                       action:@selector(setSelectedRangeWithNSValue:) keyEquivalent:@""] autorelease];
                [menuItem setTarget:[[self masterView] textView]];
                [menuItem setAttributedTitle:title];
                [menuItem setRepresentedObject:[outlineItem valueForKey:k_outlineMenuItemRange]];
                [menu addItem:menuItem];
            }
        }
        // （メニューの再描画時のちらつき防止のため、ここで選択項目をセットする 2008.05.17.）
        [self selectOutlineMenuItemWithRange:[[[self masterView] editorView] selectedRange]];
        [[self outlineMenu] setMenu:menu];
        [[self outlineMenu] setEnabled:YES];
        [[self prevButton] setImage:[NSImage imageNamed:@"prevButtonImg"]];
        [[self prevButton] setEnabled:YES];
        [[self nextButton] setImage:[NSImage imageNamed:@"nextButtonImg"]];
        [[self nextButton] setEnabled:YES];
    }
}


// ------------------------------------------------------
- (void)selectOutlineMenuItemWithRange:(NSRange)range
// アウトラインメニューの選択項目を設定
// ------------------------------------------------------
{
    if (![[self outlineMenu] isEnabled]) { return; }
    
    NSMenu *menu = [[self outlineMenu] menu];
    NSMenuItem *menuItem;
    NSInteger i;
    NSInteger count = [menu numberOfItems];
    NSUInteger markedLocation;
    NSUInteger location = range.location;
    if (count < 1) { return; }

    if (NSEqualRanges(range, NSMakeRange(0, 0))) {
        i = 1;
    } else {
        for (i = 1; i < count; i++) {
            menuItem = [menu itemAtIndex:i];
            markedLocation = [[menuItem representedObject] rangeValue].location;
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
- (void)selectOutlineMenuItemWithRangeValue:(NSValue *)rangeValue
// アウトラインメニューの選択項目を設定
// ------------------------------------------------------
{
    [self selectOutlineMenuItemWithRange:[rangeValue rangeValue]];
}


// ------------------------------------------------------
- (void)updatePrevNextButtonEnabled
// 前／次移動ボタンの有効／無効を切り替え
// ------------------------------------------------------
{
    [[self prevButton] setEnabled:[self canSelectPrevItem]];
    [[self nextButton] setEnabled:[self canSelectNextItem]];
}


// ------------------------------------------------------
- (void)selectPrevItem
// set select prev item of outline menu.
// ------------------------------------------------------
{
    if ([self canSelectPrevItem]) {
        NSInteger targetIndex = [[self outlineMenu] indexOfSelectedItem] - 1;

        while ([[[self outlineMenu] itemAtIndex:targetIndex] isSeparatorItem]) {
            targetIndex--;
            if (targetIndex < 0) {
                break;
            }
        }
        [[[self outlineMenu] menu] performActionForItemAtIndex:targetIndex];
    }
}


// ------------------------------------------------------
- (void)selectNextItem
// set select next item of outline menu.
// ------------------------------------------------------
{
    if ([self canSelectNextItem]) {
        NSInteger targetIndex = [[self outlineMenu] indexOfSelectedItem] + 1;
        NSInteger maxIndex = [[self outlineMenu] numberOfItems] - 1;

        while ([[[self outlineMenu] itemAtIndex:targetIndex] isSeparatorItem]) {
            targetIndex++;
            if (targetIndex > maxIndex) {
                break;
            }
        }
        if (![[[self outlineMenu] itemAtIndex:targetIndex] isSeparatorItem]) {
            [[[self outlineMenu] menu] performActionForItemAtIndex:targetIndex];
        }
    }
}


// ------------------------------------------------------
- (BOOL)canSelectPrevItem
// can select prev item in outline menu?
// ------------------------------------------------------
{
    return ([[self outlineMenu] indexOfSelectedItem] > 0);
}


// ------------------------------------------------------
- (BOOL)canSelectNextItem
// can select next item in outline menu?
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
- (void)setCloseSplitButtonEnabled:(BOOL)enabled
// set closeSplitButton enabled or disabled
// ------------------------------------------------------
{
    [[self closeSplitButton] setHidden:!enabled];
}


// ------------------------------------------------------
- (void)drawRect:(NSRect)dirtyRect
// draw background
// ------------------------------------------------------
{
    if (![self masterView] || ![self showNavigationBar]) {
        return;
    }
    // fill in the background
    [[NSColor controlColor] set];
    [NSBezierPath fillRect:dirtyRect];

    // draw frame border (only bottom line)
    [[NSColor controlShadowColor] set];
    [NSBezierPath strokeLineFromPoint:NSMakePoint(NSMinX(dirtyRect), 0.5)
                              toPoint:NSMakePoint(NSMaxX(dirtyRect), 0.5)];
}




#pragma mark Private Methods

// ------------------------------------------------------
- (void)setHeight:(CGFloat)height
// set view height.
// ------------------------------------------------------
{
    CGFloat adjHeight = height - NSHeight([self frame]);
    NSRect newFrame;

    // set masterView height
    newFrame = [[[self masterView] scrollView] frame];
    newFrame.size.height -= adjHeight;
    [[[self masterView] scrollView] setFrame:newFrame];
    
    // set LineNumView height
    newFrame = [[[self masterView] lineNumView] frame];
    newFrame.size.height -= adjHeight;
    [[[self masterView] lineNumView] setFrame:newFrame];

    // set navigationBar height
    newFrame = [self frame];
    newFrame.origin.y -= adjHeight;
    newFrame.size.height += adjHeight;
    [self setFrame:newFrame];

    [[[self window] contentView] setNeedsDisplay:YES];
}


@end