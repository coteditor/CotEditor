/*
=================================================
CEStatusBarView
(for CotEditor)

 Copyright (C) 2004-2007 nakamuxu.
 Copyright (C) 2014 CotEditor Project
 http://coteditor.github.io
=================================================

encoding="UTF-8"
Created:2005.03.30

------------
This class is based on JSDTextView (written by James S. Derry – http://www.balthisar.com)
JSDTextView is released as public domain.
arranged by nakamuxu, Dec 2004.
arranged by 1024jp, Mar 2014.
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
#import "constants.h"


@interface CEStatusBarView ()

@property (nonatomic) NSTextField *leftTextField;
@property (nonatomic, readwrite) NSTextField *rightTextField;

@property (nonatomic) NSNumberFormatter *decimalFormatter;

@property (nonatomic) NSImageView *readOnlyView;

@end




#pragma mark -

@implementation CEStatusBarView

#pragma mark NSView Methods

//=======================================================
// NSView method
//
//=======================================================

// ------------------------------------------------------
/// 初期化
- (instancetype)initWithFrame:(NSRect)frameRect
// ------------------------------------------------------
{
    self = [super initWithFrame:frameRect];
    if (self) {
        // set number formatter
        [self setDecimalFormatter:[[NSNumberFormatter alloc] init]];
        [[self decimalFormatter] setNumberStyle:NSNumberFormatterDecimalStyle];
        
        // setup TextField
        NSFont *font = [NSFont controlContentFontOfSize:[NSFont smallSystemFontSize]];
        
        NSRect textFieldFrame = frameRect;
        textFieldFrame.origin.x += k_statusBarReadOnlyWidth;
        textFieldFrame.origin.y -= (k_statusBarHeight - [font pointSize]) / 4;
        textFieldFrame.size.width -= [NSScroller scrollerWidth] + k_statusBarReadOnlyWidth + k_statusBarRightPadding;
        
        [self setLeftTextField:[[NSTextField allocWithZone:nil] initWithFrame:textFieldFrame]];
        [[self leftTextField] setEditable:NO];
        [[self leftTextField] setSelectable:NO];
        [[self leftTextField] setAutoresizingMask:(NSViewWidthSizable | NSViewHeightSizable)];
        [[self leftTextField] setFont:font];
        [[self leftTextField] setBordered:NO];
        [[self leftTextField] setDrawsBackground:NO];
        [[self leftTextField] setAlignment:NSLeftTextAlignment];

        [self setRightTextField:[[NSTextField allocWithZone:nil] initWithFrame:textFieldFrame]];
        [[self rightTextField] setEditable:NO];
        [[self rightTextField] setSelectable:NO];
        [[self rightTextField] setAutoresizingMask:(NSViewWidthSizable | NSViewHeightSizable)];
        [[self rightTextField] setFont:font];
        [[self rightTextField] setBordered:NO];
        [[self rightTextField] setDrawsBackground:NO];
        [[self rightTextField] setAlignment:NSRightTextAlignment];

        // setup ReadOnly icon
        NSRect readOnlyFrame = frameRect;
        readOnlyFrame.size.width = k_statusBarReadOnlyWidth;
        [self setReadOnlyView:[[NSImageView allocWithZone:nil] initWithFrame:readOnlyFrame]];
        [[self readOnlyView] setAutoresizingMask:NSViewHeightSizable];

        [self setShowsReadOnlyIcon:NO];
        [self setAutoresizingMask:NSViewWidthSizable];
        
        [self addSubview:[self leftTextField]];
        [self addSubview:[self rightTextField]];
        [self addSubview:[self readOnlyView]];
    }
    return self;
}


// ------------------------------------------------------
/// 矩形を描画
- (void)drawRect:(NSRect)dirtyRect
// ------------------------------------------------------
{
    if (![self masterView] || ![self showStatusBar]) {
        return;
    }
    
    // fill in background
    [[NSColor windowBackgroundColor] set];
    [NSBezierPath fillRect:dirtyRect];
    
    // draw frame border (only top line)
    [[NSColor controlShadowColor] set];
    [NSBezierPath strokeLineFromPoint:NSMakePoint(NSMinX([self frame]), NSMaxY([self frame]))
                              toPoint:NSMakePoint(NSMaxX([self frame]), NSMaxY([self frame]))];
}



#pragma mark Public Methods

//=======================================================
// Public method
//
//=======================================================

// ------------------------------------------------------
/// 左側の情報欄を描画し直す
- (void)updateLeftField
// ------------------------------------------------------
{
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    NSMutableString *status = [NSMutableString string];
    NSString *space = @"  ";
    NSNumberFormatter *formatter = [self decimalFormatter];
    
    if ([defaults boolForKey:k_key_showStatusBarLines]) {
        [status appendFormat:NSLocalizedString(@"Lines: %@", nil), [formatter stringFromNumber:@([self linesInfo])]];
    }
    if ([defaults boolForKey:k_key_showStatusBarChars]) {
        if ([status length] > 0) { [status appendString:space]; }
        [status appendFormat:NSLocalizedString(@"Chars: %@", nil), [formatter stringFromNumber:@([self charsInfo])]];
        
        if ([self selectedCharsInfo] > 0) {
            [status appendFormat:@" (%@)", [formatter stringFromNumber:@([self selectedCharsInfo])]];
        }
    }
    if ([defaults boolForKey:k_key_showStatusBarWords]) {
        if ([status length] > 0) { [status appendString:space]; }
        [status appendFormat:NSLocalizedString(@"Words: %@", nil), [formatter stringFromNumber:@([self wordsInfo])]];
        
        if ([self selectedWordsInfo] > 0) {
            [status appendFormat:@" (%@)", [formatter stringFromNumber:@([self selectedWordsInfo])]];
        }
    }
    if ([defaults boolForKey:k_key_showStatusBarLocation]) {
        if ([status length] > 0) { [status appendString:space]; }
        [status appendFormat:NSLocalizedString(@"Location: %@", nil), [formatter stringFromNumber:@([self locationInfo])]];
    }
    if ([defaults boolForKey:k_key_showStatusBarLine]) {
        if ([status length] > 0) { [status appendString:space]; }
        [status appendFormat:NSLocalizedString(@"Line: %@", nil), [formatter stringFromNumber:@([self lineInfo])]];
    }
    if ([defaults boolForKey:k_key_showStatusBarColumn]) {
        if ([status length] > 0) { [status appendString:space]; }
        [status appendFormat:NSLocalizedString(@"Column: %@", nil), [formatter stringFromNumber:@([self columnInfo])]];
    }
    
    [[self leftTextField] setStringValue:status];
}


// ------------------------------------------------------
/// 右側の情報欄を描画し直す
- (void)updateRightField
// ------------------------------------------------------
{
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    NSMutableString *status = [NSMutableString string];
    
    if ([defaults boolForKey:k_key_showStatusBarEncoding]) {
        [status appendString:[self encodingInfo]];
    }
    if ([defaults boolForKey:k_key_showStatusBarLineEndings]) {
        [status appendString:@" "];
        [status appendString:[self lineEndingsInfo]];
    }
    
    [[self rightTextField] setStringValue:status];
}


// ------------------------------------------------------
/// ステータスバー表示の有無をセット
- (void)setShowStatusBar:(BOOL)showStatusBar
// ------------------------------------------------------
{
    if (showStatusBar != [self showStatusBar]) {
        _showStatusBar = showStatusBar;

        CGFloat height = [self showStatusBar] ? k_statusBarHeight : 0.0;
        [self setHeight:height];
    }
}


// ------------------------------------------------------
/// "ReadOnly"アイコン表示の有無をセット
- (void)setShowsReadOnlyIcon:(BOOL)showsReadOnlyIcon
// ------------------------------------------------------
{
    if (showsReadOnlyIcon) {
        [[self readOnlyView] setImage:[NSImage imageNamed:@"lockOnImg"]];
        [[self readOnlyView] setToolTip:NSLocalizedString(@"This Document is ReadOnly", nil)];
    } else {
        [[self readOnlyView] setImage:nil];
        [[self readOnlyView] setToolTip:nil];
    }
}



#pragma mark Private Methods

//=======================================================
// Private method
//
//=======================================================

// ------------------------------------------------------
/// 高さをセット
- (void)setHeight:(CGFloat)height
// ------------------------------------------------------
{
    CGFloat adjHeight = height - NSHeight([self frame]);
    NSRect newFrame;

    // set masterView height
    newFrame = [[[self masterView] splitView] frame];
    newFrame.origin.y += adjHeight;
    newFrame.size.height -= adjHeight;
    [[[self masterView] splitView] setFrame:newFrame];
    
    // set statusBar height
    newFrame = [self frame];
    newFrame.size.height += adjHeight;
    [self setFrame:newFrame];

    [[[self window] contentView] setNeedsDisplay:YES];
}

@end
