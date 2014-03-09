/*
=================================================
CEOutlineMenuButton
(for CotEditor)

 Copyright (C) 2004-2007 nakamuxu.
 Copyright (C) 2014 CotEditor Project
 http://coteditor.github.io
=================================================

encoding="UTF-8"
Created:2005.08.25

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

#import "CEOutlineMenuButton.h"


@implementation CEOutlineMenuButton

#pragma mark ===== Class method =====

//=======================================================
// Class method
//
//=======================================================

// ------------------------------------------------------
+ (Class)cellClass
// 使用するセルのクラスを返す
// ------------------------------------------------------
{
    return [CEOutlineMenuButtonCell class];
}



#pragma mark ===== Public method =====

//=======================================================
// Public method
//
//=======================================================

// ------------------------------------------------------
- (id)initWithFrame:(NSRect)inFrameRect pullsDown:(BOOL)inBool
// 初期化
// ------------------------------------------------------
{
    self = [super initWithFrame:inFrameRect pullsDown:inBool];
    if (self) {
        id theValues = [[NSUserDefaultsController sharedUserDefaultsController] values];
        id theCell = [self cell];

        [theCell setFont:
                [NSFont fontWithName:[theValues valueForKey:k_key_navigationBarFontName] 
                    size:(CGFloat)[[theValues valueForKey:k_key_navigationBarFontSize] doubleValue]]];
        [theCell setControlSize:NSSmallControlSize];
        [theCell setBordered:NO];
    }
    return self;
}

@end
