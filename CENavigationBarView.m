/*
=================================================
CENavigationBarView
(for CotEditor)

Copyright (C) 2004-2007 nakamuxu.
http://www.aynimac.com/
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


//=======================================================
// Private method
//
//=======================================================

@interface CENavigationBarView (Private)
- (void)setHeight:(float)inValue;
@end


//------------------------------------------------------------------------------------------




@implementation CENavigationBarView
// ------------------------------------------------------
- (id)initWithFrame:(NSRect)inFrame
// initialize
// ------------------------------------------------------
{
    self = [super initWithFrame:inFrame];
    if (self) {

        // setup outlineMenu
        NSRect theOutlineMenuFrame = inFrame;
        theOutlineMenuFrame.origin.x += k_outlineMenuLeftMargin;
        theOutlineMenuFrame.origin.y = 0.0;
        theOutlineMenuFrame.size.width = k_outlineMenuWidth;
        [self convertRect:theOutlineMenuFrame toView:self];
        _outlineMenu = [[CEOutlineMenuButton allocWithZone:[self zone]] 
                    initWithFrame:theOutlineMenuFrame pullsDown:NO]; // ===== alloc
        [_outlineMenu setAutoresizingMask:NSViewHeightSizable];

        // setup prevButton
        NSRect thePrevButtonFrame = theOutlineMenuFrame;
        thePrevButtonFrame.origin.x -= k_outlineButtonWidth;
        thePrevButtonFrame.origin.y = 1.0;
        thePrevButtonFrame.size.width = k_outlineButtonWidth;
        [self convertRect:thePrevButtonFrame toView:self];
        _prevButton = [[NSButton allocWithZone:[self zone]] initWithFrame:thePrevButtonFrame]; // ===== alloc
        [_prevButton setButtonType:NSMomentaryPushInButton];
        [_prevButton setBordered:NO];
        [_prevButton setImagePosition:NSImageOnly];
        [_prevButton setAction:@selector(selectPrevItem)];
        [_prevButton setTarget:self];
        [_prevButton setToolTip:NSLocalizedString(@"Go Prev item",@"")];
        [_prevButton setAutoresizingMask:NSViewHeightSizable];

        // setup nextButton
        NSRect theNextButtonFrame = theOutlineMenuFrame;
        theNextButtonFrame.origin.x += NSWidth(theOutlineMenuFrame);
        theNextButtonFrame.origin.y = 1.0;
        theNextButtonFrame.size.width = k_outlineButtonWidth;
        [self convertRect:theNextButtonFrame toView:self];
        _nextButton = [[NSButton allocWithZone:[self zone]] initWithFrame:theNextButtonFrame]; // ===== alloc
        [_nextButton setButtonType:NSMomentaryPushInButton];
        [_nextButton setBordered:NO];
        [_nextButton setImagePosition:NSImageOnly];
        [_nextButton setAction:@selector(selectNextItem)];
        [_nextButton setTarget:self];
        [_nextButton setToolTip:NSLocalizedString(@"Go Next item",@"")];
        [_nextButton setAutoresizingMask:NSViewHeightSizable];

        // setup openSplitButton
        NSRect theOpenSplitButtonFrame = inFrame;
        theOpenSplitButtonFrame.origin.x += (NSWidth(inFrame) - [NSScroller scrollerWidth]);
        theOpenSplitButtonFrame.origin.y = 1.0;
        theOpenSplitButtonFrame.size.width = [NSScroller scrollerWidth];
        [self convertRect:theOpenSplitButtonFrame toView:self];
        _openSplitButton = [[NSButton allocWithZone:[self zone]] initWithFrame:theOpenSplitButtonFrame]; // ===== alloc
        [_openSplitButton setButtonType:NSMomentaryPushInButton];
        [_openSplitButton setBordered:NO];
        [_openSplitButton setImagePosition:NSImageOnly];
        [_openSplitButton setAction:@selector(openSplitTextView:)];
        [_openSplitButton setAutoresizingMask:(NSViewHeightSizable | NSViewMinXMargin)];
        [_openSplitButton setImage:[NSImage imageNamed:@"openSplitButtonImg"]];
        [_openSplitButton setToolTip:NSLocalizedString(@"Open SplitView",@"")];
        [_openSplitButton setEnabled:YES];

        // setup closeSplitButton
        NSRect theDelSplitButtonFrame = inFrame;
        theDelSplitButtonFrame.origin.x += (NSWidth(inFrame) - [NSScroller scrollerWidth] * 2);
        theDelSplitButtonFrame.origin.y = 1.0;
        theDelSplitButtonFrame.size.width = [NSScroller scrollerWidth];
        [self convertRect:theDelSplitButtonFrame toView:self];
        _closeSplitButton = [[NSButton allocWithZone:[self zone]] initWithFrame:theDelSplitButtonFrame]; // ===== alloc
        [_closeSplitButton setButtonType:NSMomentaryPushInButton];
        [_closeSplitButton setBordered:NO];
        [_closeSplitButton setImagePosition:NSImageOnly];
        [_closeSplitButton setAction:@selector(closeSplitTextView:)];
        [_closeSplitButton setAutoresizingMask:(NSViewHeightSizable | NSViewMinXMargin)];
        [_closeSplitButton setImage:[NSImage imageNamed:@"closeSplitButtonImg"]];
        [_closeSplitButton setToolTip:NSLocalizedString(@"Close SplitView",@"")];
        [_closeSplitButton setHidden:YES];


        [self setAutoresizingMask:(NSViewWidthSizable | NSViewMinYMargin)];
        [self addSubview:_outlineMenu];
        [self addSubview:_prevButton];
        [self addSubview:_nextButton];
        [self addSubview:_openSplitButton];
        [self addSubview:_closeSplitButton];
    }
    return self;
}


// ------------------------------------------------------
- (void)dealloc
// clean up
// ------------------------------------------------------
{
    // _masterView is not retain.
    [_outlineMenu release];
    [_prevButton release];
    [_nextButton release];
    [_openSplitButton release];
    [_closeSplitButton release];

    [super dealloc];
}


// ------------------------------------------------------
- (CESubSplitView *)masterView
// return main textView
// ------------------------------------------------------
{
    return _masterView; // not retain
}


// ------------------------------------------------------
- (void)setMasterView:(CESubSplitView *)inView
// set main textView in myself. *NOT* retain.
// ------------------------------------------------------
{
    _masterView = inView;
}


// ------------------------------------------------------
- (BOOL)showNavigationBar
// is set to show navigation bar?
// ------------------------------------------------------
{
    return _showNavigationBar;
}


// ------------------------------------------------------
- (void)setShowNavigationBar:(BOOL)inBool
// set to show navigation bar.
// ------------------------------------------------------
{
    if (inBool != _showNavigationBar) {
        _showNavigationBar = !_showNavigationBar;
        if (!_showNavigationBar) {
            [self setHeight:0];
        } else {
            [self setHeight:k_navigationBarHeight];
        }
    }
}


// ------------------------------------------------------
- (void)setOutlineMenuArray:(NSArray *)inArray
// 配列を元にアウトラインメニューを生成
// ------------------------------------------------------
{
    id theValues = [[NSUserDefaultsController sharedUserDefaultsController] values];
    NSMenu *theMenu;
    NSMenuItem *theMenuItem;
    NSDictionary *theDict;
    NSFont *theDefaultFont = [NSFont fontWithName:[theValues valueForKey:k_key_navigationBarFontName] 
                    size:[[theValues valueForKey:k_key_navigationBarFontSize] floatValue]];

    NSFontManager *theManager = [NSFontManager sharedFontManager];
    NSFont *theFont;
    NSMutableAttributedString *theTitle;
    NSFontTraitMask theFontMask;
    NSNumber *theUnderlineMaskNumber;
    int i, theCount = [inArray count];

    [_outlineMenu removeAllItems];
    if (theCount < 1) {
        [_outlineMenu setEnabled:NO];
        [_prevButton setEnabled:NO];
        [_prevButton setImage:nil];
        [_nextButton setEnabled:NO];
        [_nextButton setImage:nil];
    } else {
        theMenu = [_outlineMenu menu];
        for (i = 0; i < theCount; i++) {
            theDict = [inArray objectAtIndex:i];
            if ([[theDict valueForKey:k_outlineMenuItemTitle] isEqualToString:k_outlineMenuSeparatorSymbol]) {
                // セパレータ
                [theMenu addItem:[NSMenuItem separatorItem]];
            } else {
                theUnderlineMaskNumber = 
                        [[[theDict valueForKey:k_outlineMenuItemUnderlineMask] copy] autorelease];
                theFontMask = ([[theDict valueForKey:k_outlineMenuItemFontBold] boolValue]) ? 
                        NSBoldFontMask : 0;
                theFont = [theManager convertFont:theDefaultFont toHaveTrait:theFontMask];
                theTitle = [[[NSMutableAttributedString alloc] 
                            initWithString:[theDict valueForKey:k_outlineMenuItemTitle] 
                            attributes:[NSDictionary dictionaryWithObjectsAndKeys:
                                theFont, NSFontAttributeName, 
                                theUnderlineMaskNumber, NSUnderlineStyleAttributeName, 
                                nil]] autorelease];
                if ([[theDict valueForKey:k_outlineMenuItemFontItalic] boolValue]) {
                    [theTitle addAttribute:NSFontAttributeName 
                            value:[theManager convertFont:theFont toHaveTrait:NSItalicFontMask]
                            range:NSMakeRange(0, [theTitle length])];
                }
                theMenuItem = [[[NSMenuItem alloc] initWithTitle:@" " 
                            action:@selector(setSelectedRangeWithNSValue:) keyEquivalent:@""] autorelease];
                [theMenuItem setTarget:[[self masterView] textView]];
                [theMenuItem setAttributedTitle:theTitle];
                [theMenuItem setRepresentedObject:[theDict valueForKey:k_outlineMenuItemRange]];
                [theMenu addItem:theMenuItem];
            }
        }
        // （メニューの再描画時のちらつき防止のため、ここで選択項目をセットする 2008.05.17.）
        [self selectOutlineMenuItemWithRange:[[(CESubSplitView *)_masterView editorView] selectedRange]];
        [_outlineMenu setMenu:theMenu];
        [_outlineMenu setEnabled:YES];
        [_prevButton setImage:[NSImage imageNamed:@"prevButtonImg"]];
        [_prevButton setEnabled:YES];
        [_nextButton setImage:[NSImage imageNamed:@"nextButtonImg"]];
        [_nextButton setEnabled:YES];
    }
}


// ------------------------------------------------------
- (void)selectOutlineMenuItemWithRange:(NSRange)inRange
// アウトラインメニューの選択項目を設定
// ------------------------------------------------------
{
    if (![_outlineMenu isEnabled]) { return; }
    NSMenu *theMenu = [_outlineMenu menu];
    id theItem = nil;
    int i, theCount = [theMenu numberOfItems];
    unsigned int theMark, theLocation = inRange.location;
    if (theCount < 1) { return; }

    if (NSEqualRanges(inRange, NSMakeRange(0, 0))) {
        i = 1;
    } else {
        for (i = 1; i < theCount; i++) {
            theItem = [theMenu itemAtIndex:i];
            theMark = [[theItem representedObject] rangeValue].location;
            if (theMark > theLocation) {
                break;
            }
        }
    }
    // ループを抜けた時点で「次のアイテムインデックス」になっているので、減ずる
    i--;
    // セパレータを除外
    while ([[_outlineMenu itemAtIndex:i] isSeparatorItem]) {
        i--;
        if (i < 0) {
            break;
        }
    }
    [_outlineMenu selectItemAtIndex:i];
    [self updatePrevNextButtonEnabled];
}


// ------------------------------------------------------
- (void)selectOutlineMenuItemWithRangeValue:(NSValue *)inRangeValue
// アウトラインメニューの選択項目を設定
// ------------------------------------------------------
{
    [self selectOutlineMenuItemWithRange:[inRangeValue rangeValue]];
}


// ------------------------------------------------------
- (void)updatePrevNextButtonEnabled
// 前／次移動ボタンの有効／無効を切り替え
// ------------------------------------------------------
{
    [_prevButton setEnabled:[self canSelectPrevItem]];
    [_nextButton setEnabled:[self canSelectNextItem]];
}


// ------------------------------------------------------
- (void)selectPrevItem
// set select prev item of outline menu.
// ------------------------------------------------------
{
    if ([self canSelectPrevItem]) {
        int theTargetIndex = [_outlineMenu indexOfSelectedItem] - 1;

        while ([[_outlineMenu itemAtIndex:theTargetIndex] isSeparatorItem]) {
            theTargetIndex--;
            if (theTargetIndex < 0) {
                break;
            }
        }
        [[_outlineMenu menu] performActionForItemAtIndex:theTargetIndex];
    }
}


// ------------------------------------------------------
- (void)selectNextItem
// set select next item of outline menu.
// ------------------------------------------------------
{
    if ([self canSelectNextItem]) {
        int theTargetIndex = [_outlineMenu indexOfSelectedItem] + 1;
        int theMaxIndex = [_outlineMenu numberOfItems] - 1;

        while ([[_outlineMenu itemAtIndex:theTargetIndex] isSeparatorItem]) {
            theTargetIndex++;
            if (theTargetIndex > theMaxIndex) {
                break;
            }
        }
        if (![[_outlineMenu itemAtIndex:theTargetIndex] isSeparatorItem]) {
            [[_outlineMenu menu] performActionForItemAtIndex:theTargetIndex];
        }
    }
}


// ------------------------------------------------------
- (BOOL)canSelectPrevItem
// can select prev item in outline menu?
// ------------------------------------------------------
{
    return ([_outlineMenu indexOfSelectedItem] > 0);
}


// ------------------------------------------------------
- (BOOL)canSelectNextItem
// can select next item in outline menu?
// ------------------------------------------------------
{
    BOOL outBool = NO;
    int i;

    for (i = ([_outlineMenu indexOfSelectedItem] + 1); i < [_outlineMenu numberOfItems]; i++) {
        if (![[_outlineMenu itemAtIndex:i] isSeparatorItem]) {
            outBool = YES;
            break;
        }
    }
    return outBool;
}


// ------------------------------------------------------
- (void)setCloseSplitButtonEnabled:(BOOL)inBool
// set closeSplitButton enabled or disabled
// ------------------------------------------------------
{
    [_closeSplitButton setHidden:(!inBool)];
}


// ------------------------------------------------------
- (void)drawRect:(NSRect)inRect
// draw background.
// ------------------------------------------------------
{
    if ((!_masterView) || (!_showNavigationBar)) {
        return;
    }
    // fill in the background
    [[NSColor controlColor] set];
    [NSBezierPath fillRect:inRect];

    // draw frame border (only bottom line)
    [[NSColor controlShadowColor] set];
    [NSBezierPath strokeLineFromPoint:NSMakePoint(NSMinX(inRect), NSMinY(inRect)) 
        toPoint:NSMakePoint(NSMaxX(inRect), NSMinY(inRect))];
}



@end



@implementation CENavigationBarView (Private)

// ------------------------------------------------------
- (void)setHeight:(float)inValue
// set view height.
// ------------------------------------------------------
{
    float theAdjHeight = (inValue - NSHeight([self frame]));
    NSRect theNewFrame;

    // set masterView height
    theNewFrame = [[[self masterView] scrollView] frame];
    theNewFrame.size.height -= theAdjHeight;
    [[[self masterView] scrollView] setFrame:theNewFrame];
    
    // set LineNumView height
    theNewFrame = [[[self masterView] lineNumView] frame];
    theNewFrame.size.height -= theAdjHeight;
    [[[self masterView] lineNumView] setFrame:theNewFrame];

    // set navigationBar height
    theNewFrame = [self frame];
    theNewFrame.origin.y -= theAdjHeight;
    theNewFrame.size.height += theAdjHeight;
    [self setFrame:theNewFrame];

    [[[self window] contentView] setNeedsDisplay:YES];
}


@end