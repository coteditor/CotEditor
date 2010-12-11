/*
=================================================
CEStatusBarView
(for CotEditor)

Copyright (C) 2004-2007 nakamuxu.
http://www.aynimac.com/
=================================================

encoding="UTF-8"
Created:2005.03.30

------------
This class is based on JSDTextView (written by James S. Derry – http://www.balthisar.com)
JSDTextView is released as public domain.
arranged by nakamuxu, Dec 2004.
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

#import "CEStatusBarView.h"
#import "CEEditorView.h"


//=======================================================
// Private method
//
//=======================================================

@interface CEStatusBarView (Private)
- (void)setHeight:(float)inValue;
@end


//------------------------------------------------------------------------------------------




@implementation CEStatusBarView

#pragma mark ===== Public method =====

//=======================================================
// Public method
//
//=======================================================

// ------------------------------------------------------
- (id)initWithFrame:(NSRect)inFrame
// 初期化
// ------------------------------------------------------
{
    self = [super initWithFrame:inFrame];
    if (self) {

        id theValues = [[NSUserDefaultsController sharedUserDefaultsController] values];

        // setup the TextField.
        NSFont *theFont = [NSFont fontWithName:[theValues valueForKey:k_key_statusBarFontName] 
                    size:[[theValues valueForKey:k_key_statusBarFontSize] floatValue]];
        if (theFont == nil) {
            theFont = [NSFont controlContentFontOfSize:11.0];
        }
        NSRect theTextFieldFrame = inFrame;
        theTextFieldFrame.origin.x += k_statusBarReadOnlyWidth;
        theTextFieldFrame.origin.y -= (k_statusBarHeight - [theFont pointSize]) / 4 ;
        theTextFieldFrame.size.width -= 
                ([NSScroller scrollerWidth] + k_statusBarReadOnlyWidth + k_statusBarRightPadding);
        _leftTextField = [[NSTextField allocWithZone:[self zone]] initWithFrame:theTextFieldFrame]; // ===== alloc
        [_leftTextField setEditable:NO];
        [_leftTextField setSelectable:NO];
        [_leftTextField setAutoresizingMask:(NSViewWidthSizable | NSViewHeightSizable)];
        [_leftTextField setFont:theFont];
        [_leftTextField setBordered:NO];
        [_leftTextField setDrawsBackground:NO];
        [_leftTextField setAlignment:NSLeftTextAlignment];

        _rightTextField = [[NSTextField allocWithZone:[self zone]] initWithFrame:theTextFieldFrame]; // ===== alloc
        [_rightTextField setEditable:NO];
        [_rightTextField setSelectable:NO];
        [_rightTextField setAutoresizingMask:(NSViewWidthSizable | NSViewHeightSizable)];
        [_rightTextField setFont:theFont];
        [_rightTextField setBordered:NO];
        [_rightTextField setDrawsBackground:NO];
        [_rightTextField setAlignment:NSRightTextAlignment];


        // setup the ReadOnly icon.
        NSRect theReadOnlyFrame = inFrame;
        theReadOnlyFrame.size.width = k_statusBarReadOnlyWidth;
        _readOnlyView = 
                [[NSImageView allocWithZone:[self zone]] initWithFrame:theReadOnlyFrame]; // ===== alloc
        [_readOnlyView setAutoresizingMask:NSViewHeightSizable];

        [self setReadOnlyIcon:NO];
        [self setAutoresizingMask:NSViewWidthSizable];
        [self addSubview:_leftTextField];
        [self addSubview:_rightTextField];
        [self addSubview:_readOnlyView];
    }
    return self;
}


// ------------------------------------------------------
- (void)dealloc
// 後片付け
// ------------------------------------------------------
{
    // _masterView is not retain.
    [_leftTextField release];
    [_rightTextField release];
    [_readOnlyView release];

    [super dealloc];
}


// ------------------------------------------------------
- (NSTextField *)leftTextField
// 左側のテキストフィールドを返す
// ------------------------------------------------------
{
    return _leftTextField;
}


// ------------------------------------------------------
- (NSTextField *)rightTextField
// 右側のテキストフィールドを返す
// ------------------------------------------------------
{
    return _rightTextField;
}


// ------------------------------------------------------
- (CEEditorView *)masterView
// テキストビューを返す
// ------------------------------------------------------
{
    return _masterView; // retain していない
}


// ------------------------------------------------------
- (void)setMasterView:(CEEditorView *)inView
// テキストビューをセット。retainしない。
// ------------------------------------------------------
{
    _masterView = inView;
}


// ------------------------------------------------------
- (BOOL)showStatusBar
// ステータスバーを表示するかどうかを返す
// ------------------------------------------------------
{
    return _showStatusBar;
}


// ------------------------------------------------------
- (void)setShowStatusBar:(BOOL)inBool
// ステータスバー表示の有無をセット
// ------------------------------------------------------
{
    if (inBool != _showStatusBar) {
        _showStatusBar = !_showStatusBar;
        if (!_showStatusBar) {
            [self setHeight:0];
        } else {
            [self setHeight:k_statusBarHeight];
        }
    }
}


// ------------------------------------------------------
- (void)setReadOnlyIcon:(BOOL)inBool
// "ReadOnly"アイコン表示の有無をセット
// ------------------------------------------------------
{
    if (inBool) {
        [_readOnlyView setImage:[NSImage imageNamed:@"lockOnImg"]];
        [_readOnlyView setToolTip:NSLocalizedString(@"This Doc is ReadOnly",@"")];
    } else {
        [_readOnlyView setImage:nil];
        [_readOnlyView setToolTip:nil];
    }
}


// ------------------------------------------------------
- (void)drawRect:(NSRect)inRect
// 矩形を描画
// ------------------------------------------------------
{
    if ((!_masterView) || (!_showStatusBar)) {
        return;
    }
    // fill in the background
    [[NSColor gridColor] set];
    [NSBezierPath fillRect:inRect];
    // draw frame border
    [[NSColor controlShadowColor] set];
    [NSBezierPath strokeRect:[self frame]];
}



@end



@implementation CEStatusBarView (Private)

// ------------------------------------------------------
- (void)setHeight:(float)inValue
// 高さをセット
// ------------------------------------------------------
{
    float theAdjHeight = (inValue - NSHeight([self frame]));
    NSRect theNewFrame;

    // set masterView height
    theNewFrame = [[_masterView splitView] frame];
    theNewFrame.origin.y += theAdjHeight;
    theNewFrame.size.height -= theAdjHeight;
    [[_masterView splitView] setFrame:theNewFrame];
    // set statusBar height
    theNewFrame = [self frame];
    theNewFrame.size.height += theAdjHeight;
    [self setFrame:theNewFrame];

    [[[self window] contentView] setNeedsDisplay:YES];
}


@end