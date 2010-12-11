/*
=================================================
CEApplication
(for CotEditor)

Copyright (C) 2004-2007 nakamuxu.
http://www.aynimac.com/
=================================================

encoding="UTF-8"
Created:2005.09.06

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

#import "CEApplication.h"


@interface CEApplication (Private)
- (void)setKeyCatchModeWithNotification:(NSNotification *)inNotification;
@end


//------------------------------------------------------------------------------------------




@implementation CEApplication

#pragma mark ===== Public method =====

//=======================================================
// Public method
//
//=======================================================

// ------------------------------------------------------
- (id)init
// 初期化
// ------------------------------------------------------
{
    self = [super init];
    if (self) {
        [self setKeyCatchMode:k_keyDownNoCatch];
        [[NSNotificationCenter defaultCenter] addObserver:self 
                selector:@selector(setKeyCatchModeWithNotification:) 
                name:k_setKeyCatchModeToCatchMenuShortcut object:nil];
    }

    return self;
}


// ------------------------------------------------------
- (void)dealloc
// あとかたづけ
// ------------------------------------------------------
{
    // ノーティフィケーションセンタから自身を排除
    [[NSNotificationCenter defaultCenter] removeObserver:self];

    [super dealloc];
}


// ------------------------------------------------------
- (void)sendEvent:(NSEvent *)inEvent
// keyDownイベントをキャッチする
// ------------------------------------------------------
{
    if ((_keyCatchMode == k_catchMenuShortcut) && ([inEvent type] == NSKeyDown)) {

        NSString *theCharIgnoringMod = [inEvent charactersIgnoringModifiers];
        if ((theCharIgnoringMod != nil) && ([theCharIgnoringMod length] > 0)) {
            unichar theChar = [theCharIgnoringMod characterAtIndex:0];
            unsigned int theModFlags = [inEvent modifierFlags];
            NSCharacterSet *theIgnoringShiftSet = 
                    [NSCharacterSet characterSetWithCharactersInString:@"`~!@#$%^&()_{}|\":<>?=/*-+.'"];

            // Backspace または delete キーが押されていた時、是正する
            // （return 上の方にあるのが Backspace、テンキーとのあいだにある「delete」の刻印があるのが delete(forword)）
            if (theChar == NSDeleteCharacter) {
                unichar theBSChar = NSBackspaceCharacter;
                theCharIgnoringMod = [NSString stringWithCharacters:&theBSChar length:1];
            } else if (theChar == NSDeleteFunctionKey) {
                unichar theDeleteForwardChar = NSDeleteCharacter;
                theCharIgnoringMod = [NSString stringWithCharacters:&theDeleteForwardChar length:1];
            }
            // 不要なシフトを削除
            if (([theIgnoringShiftSet characterIsMember:[theCharIgnoringMod characterAtIndex:0]]) && 
                    (theModFlags & NSShiftKeyMask)) {
                theModFlags ^= NSShiftKeyMask;
            }
            NSDictionary *theUserInfo = [NSDictionary dictionaryWithObjectsAndKeys:
                        [NSNumber numberWithUnsignedInt:theModFlags], k_keyBindingModFlags, 
                        theCharIgnoringMod, k_keyBindingChar, 
                        nil];
            [[NSNotificationCenter defaultCenter] postNotificationName:k_catchMenuShortcutNotification 
                        object:self userInfo:theUserInfo];
            [self setKeyCatchMode:k_keyDownNoCatch];
            return;
        }
    }
    [super sendEvent:inEvent];
}


// ------------------------------------------------------
- (void)setKeyCatchMode:(int)inMode
// キーキャッチモード設定
// ------------------------------------------------------
{
    _keyCatchMode = inMode;
}



@end

@implementation CEApplication (Private)

//=======================================================
// Private method
//
//=======================================================


// ------------------------------------------------------
- (void)setKeyCatchModeWithNotification:(NSNotification *)inNotification
// ノーティフィケーションからキーキャッチモードを設定
// ------------------------------------------------------
{
    int theMode = [[[inNotification userInfo] objectForKey:k_keyCatchMode] intValue];

    [self setKeyCatchMode:theMode];
}


@end
