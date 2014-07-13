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

@property (nonatomic) CEOutlineMenuButton *outlineMenu;
@property (nonatomic) NSButton *prevButton;
@property (nonatomic) NSButton *nextButton;
@property (nonatomic) NSButton *openSplitButton;
@property (nonatomic) NSButton *closeSplitButton;

@property (nonatomic) NSProgressIndicator *outlineIndicator;
@property (nonatomic) NSTextField *outlineLoadingMessage;

@end



#pragma mark -

@implementation CENavigationBarView

#pragma mark NSView Methods

//=======================================================
// NSView method
//
//=======================================================

// ------------------------------------------------------
/// initialize
- (instancetype)initWithFrame:(NSRect)frame
// ------------------------------------------------------
{
    self = [super initWithFrame:frame];
    if (self) {
        CGFloat scrollerWidth = [NSScroller scrollerWidthForControlSize:NSRegularControlSize
                                                          scrollerStyle:NSScrollerStyleLegacy];
        
        // setup outlineMenu
        NSRect outlineMenuFrame = frame;
        outlineMenuFrame.origin.x += k_outlineMenuLeftMargin;
        outlineMenuFrame.origin.y = 1.0;
        outlineMenuFrame.size.height -= 1.0;
        outlineMenuFrame.size.width = k_outlineMenuWidth;
        [self convertRect:outlineMenuFrame toView:self];
        [self setOutlineMenu:[[CEOutlineMenuButton alloc] initWithFrame:outlineMenuFrame pullsDown:NO]];
        [[self outlineMenu] setAutoresizingMask:NSViewHeightSizable];
        
        // setup outline indicator
        [self setOutlineIndicator:[[NSProgressIndicator alloc] init]];
        [[self outlineIndicator] setStyle:NSProgressIndicatorSpinningStyle];
        [[self outlineIndicator] setUsesThreadedAnimation:YES];
        [[self outlineIndicator] setDisplayedWhenStopped:NO];
        [[self outlineIndicator] setControlSize:NSSmallControlSize];
        [[self outlineIndicator] sizeToFit];
        NSRect indicatorFrame = [[self outlineIndicator] frame];
        indicatorFrame.origin.x = outlineMenuFrame.origin.x + 6;
        indicatorFrame = NSInsetRect(indicatorFrame, 2, 2);
        [[self outlineIndicator] setFrame:indicatorFrame];
        
        // setup outline loading message
        NSRect loadingMessageFrame = outlineMenuFrame;
        loadingMessageFrame.origin.x = NSMaxX([[self outlineIndicator] frame]) + 2;
        loadingMessageFrame.origin.y -= 1;
        NSFont *messageFont = [NSFont fontWithName:k_navigationBarFontName
                                              size:[NSFont smallSystemFontSize]];
        messageFont = [[NSFontManager sharedFontManager] convertFont:messageFont toHaveTrait:NSItalicFontMask];
        [self setOutlineLoadingMessage:[[NSTextField alloc] initWithFrame:loadingMessageFrame]];
        [[self outlineLoadingMessage] setStringValue:NSLocalizedString(@"Extracting Outline…", nil)];
        [[self outlineLoadingMessage] setTextColor:[NSColor disabledControlTextColor]];
        [[self outlineLoadingMessage] setFont:messageFont];
        [[self outlineLoadingMessage] setDrawsBackground:NO];
        [[self outlineLoadingMessage] setEditable:NO];
        [[self outlineLoadingMessage] setBordered:NO];
        [[self outlineLoadingMessage] setHidden:YES];
        [[self outlineLoadingMessage] setAutoresizingMask:NSViewHeightSizable];

        // setup prevButton
        NSRect prevButtonFrame = outlineMenuFrame;
        prevButtonFrame.origin.x -= k_outlineButtonWidth;
        prevButtonFrame.size.width = k_outlineButtonWidth;
        [self convertRect:prevButtonFrame toView:self];
        [self setPrevButton:[[NSButton alloc] initWithFrame:prevButtonFrame]];
        [[self prevButton] setButtonType:NSMomentaryPushInButton];
        [[self prevButton] setBordered:NO];
        [[self prevButton] setImagePosition:NSImageOnly];
        [[self prevButton] setAction:@selector(selectPrevItem)];
        [[self prevButton] setTarget:self];
        [[self prevButton] setImage:[NSImage imageNamed:@"prevButtonImg"]];
        [[self prevButton] setHidden:YES];
        [[self prevButton] setToolTip:NSLocalizedString(@"Go to prev item", @"")];
        [[self prevButton] setAutoresizingMask:NSViewHeightSizable];

        // setup nextButton
        NSRect nextButtonFrame = outlineMenuFrame;
        nextButtonFrame.origin.x += NSWidth(outlineMenuFrame);
        nextButtonFrame.size.width = k_outlineButtonWidth;
        [self convertRect:nextButtonFrame toView:self];
        [self setNextButton:[[NSButton alloc] initWithFrame:nextButtonFrame]];
        [[self nextButton] setButtonType:NSMomentaryPushInButton];
        [[self nextButton] setBordered:NO];
        [[self nextButton] setImagePosition:NSImageOnly];
        [[self nextButton] setAction:@selector(selectNextItem)];
        [[self nextButton] setTarget:self];
        [[self nextButton] setImage:[NSImage imageNamed:@"nextButtonImg"]];
        [[self nextButton] setHidden:YES];
        [[self nextButton] setToolTip:NSLocalizedString(@"Go to next item", @"")];
        [[self nextButton] setAutoresizingMask:NSViewHeightSizable];

        // setup openSplitButton
        NSRect openSplitButtonFrame = frame;
        openSplitButtonFrame.origin.x += (NSWidth(frame) - scrollerWidth);
        openSplitButtonFrame.origin.y = 1.0;
        openSplitButtonFrame.size.width = scrollerWidth;
        [self convertRect:openSplitButtonFrame toView:self];
        [self setOpenSplitButton:[[NSButton alloc] initWithFrame:openSplitButtonFrame]];
        [[self openSplitButton] setButtonType:NSMomentaryPushInButton];
        [[self openSplitButton] setBordered:NO];
        [[self openSplitButton] setImagePosition:NSImageOnly];
        [[self openSplitButton] setAction:@selector(openSplitTextView:)];
        [[self openSplitButton] setAutoresizingMask:(NSViewHeightSizable | NSViewMinXMargin)];
        [[self openSplitButton] setImage:[NSImage imageNamed:@"openSplitButtonImg"]];
        [[self openSplitButton] setToolTip:NSLocalizedString(@"Split view", @"")];
        [[self openSplitButton] setEnabled:YES];

        // setup closeSplitButton
        NSRect closeSplitButtonFrame = frame;
        closeSplitButtonFrame.origin.x += (NSWidth(frame) - scrollerWidth * 2);
        closeSplitButtonFrame.origin.y = 1.0;
        closeSplitButtonFrame.size.width = scrollerWidth;
        [self convertRect:closeSplitButtonFrame toView:self];
        [self setCloseSplitButton:[[NSButton alloc] initWithFrame:closeSplitButtonFrame]];
        [[self closeSplitButton] setButtonType:NSMomentaryPushInButton];
        [[self closeSplitButton] setBordered:NO];
        [[self closeSplitButton] setImagePosition:NSImageOnly];
        [[self closeSplitButton] setAction:@selector(closeSplitTextView:)];
        [[self closeSplitButton] setAutoresizingMask:(NSViewHeightSizable | NSViewMinXMargin)];
        [[self closeSplitButton] setImage:[NSImage imageNamed:@"closeSplitButtonImg"]];
        [[self closeSplitButton] setToolTip:NSLocalizedString(@"Close split view", @"")];
        [[self closeSplitButton] setHidden:YES];
        
        [self setAutoresizingMask:(NSViewWidthSizable | NSViewMinYMargin | NSViewMaxYMargin)];
        [self addSubview:[self outlineMenu]];
        [self addSubview:[self outlineIndicator]];
        [self addSubview:[self outlineLoadingMessage]];
        [self addSubview:[self prevButton]];
        [self addSubview:[self nextButton]];
        [self addSubview:[self openSplitButton]];
        [self addSubview:[self closeSplitButton]];
    }
    return self;
}


// ------------------------------------------------------
/// draw background
- (void)drawRect:(NSRect)dirtyRect
// ------------------------------------------------------
{
    if (![self masterView] || ![self showNavigationBar]) {
        return;
    }
    // fill in the background
    [[NSColor controlColor] set];
    [NSBezierPath fillRect:dirtyRect];
    
    // draw frame border (only bottom line)
    [[NSColor colorWithWhite:0.75 alpha:1] set];
    [NSBezierPath strokeLineFromPoint:NSMakePoint(NSMinX(dirtyRect), 0.5)
                              toPoint:NSMakePoint(NSMaxX(dirtyRect), 0.5)];
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
/// アウトラインメニューの選択項目を設定
- (void)selectOutlineMenuItemWithRangeValue:(NSValue *)rangeValue
// ------------------------------------------------------
{
    [self selectOutlineMenuItemWithRange:[rangeValue rangeValue]];
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
/// set select prev item of outline menu.
- (void)selectPrevItem
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
- (void)selectNextItem
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
    if (![[[self outlineMenu] itemAtIndex:targetIndex] isSeparatorItem]) {
        [[[self outlineMenu] menu] performActionForItemAtIndex:targetIndex];
    }
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
/// set closeSplitButton enabled or disabled
- (void)setCloseSplitButtonEnabled:(BOOL)enabled
// ------------------------------------------------------
{
    [[self closeSplitButton] setHidden:!enabled];
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
    CGFloat adjHeight = height - NSHeight([self frame]);

    // set masterView height
    NSRect masterFrame = [[[self masterView] scrollView] frame];
    masterFrame.size.height -= adjHeight;
    [[[self masterView] scrollView] setFrame:masterFrame];
    
    // set LineNumView height
    NSRect lineNumFrame = [[[self masterView] lineNumView] frame];
    lineNumFrame.size.height -= adjHeight;
    [[[self masterView] lineNumView] setFrame:lineNumFrame];

    // set navigationBar height
    NSRect myFrame = [self frame];
    myFrame.origin.y -= adjHeight;
    myFrame.size.height += adjHeight;
    [self setFrame:myFrame];

    [[[self window] contentView] setNeedsDisplay:YES];
}

@end
