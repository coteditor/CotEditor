/*
 =================================================
 CESplitView
 (for CotEditor)
 
 Copyright (C) 2014 CotEditor Project
 http://coteditor.github.io
 =================================================
 
 encoding="UTF-8"
 Created on 2014-07-26 by 1024jp
 
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

#import "CESplitView.h"


@implementation CESplitView

#pragma mark Superclass Methods

// ------------------------------------------------------
/// 分割方向によってデバイダーのスタイルを変える
- (NSSplitViewDividerStyle)dividerStyle
// ------------------------------------------------------
{
    return [self isVertical] ? NSSplitViewDividerStyleThin : NSSplitViewDividerStylePaneSplitter;
}


// ------------------------------------------------------
/// メニューの有効化／無効化を制御
- (BOOL)validateMenuItem:(NSMenuItem *)menuItem
// ------------------------------------------------------
{
    if ([menuItem action] == @selector(toggleSplitOrientation:)) {
        NSString *title = [self isVertical] ? @"Stack Views Horizontally" : @"Stack Views Vertically";
        [menuItem setTitle:NSLocalizedString(title, nil)];
    }
    return YES;
}



#pragma mark Action Messages

// ------------------------------------------------------
/// 分割方向を変更する
- (IBAction)toggleSplitOrientation:(id)sender
// ------------------------------------------------------
{
    [self setVertical:![self isVertical]];
}

@end
