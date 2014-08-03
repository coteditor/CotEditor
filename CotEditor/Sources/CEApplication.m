/*
 ==============================================================================
 CEApplication
 
 CotEditor
 http://coteditor.github.io
 
 Created on 2005-09-06 by nakamuxu
 encoding="UTF-8"
 ------------------------------------------------------------------------------
 
 © 2004-2007 nakamuxu
 © 2014 CotEditor Project
 
 This program is free software; you can redistribute it and/or modify it under
 the terms of the GNU General Public License as published by the Free Software
 Foundation; either version 2 of the License, or (at your option) any later
 version.
 
 This program is distributed in the hope that it will be useful, but WITHOUT
 ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS
 FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.
 
 You should have received a copy of the GNU General Public License along with
 this program; if not, write to the Free Software Foundation, Inc., 59 Temple
 Place - Suite 330, Boston, MA  02111-1307, USA.
 
 ==============================================================================
 */

#import "CEApplication.h"
#import "constants.h"


@interface CEApplication ()

@property (nonatomic) CEKeyCatchMode keyCatchMode;

@end




#pragma -

@implementation CEApplication

#pragma mark NSApplication Methods

//=======================================================
// NSApplication method
//
//=======================================================

// ------------------------------------------------------
/// 初期化
- (instancetype)init
// ------------------------------------------------------
{
    self = [super init];
    if (self) {
        _keyCatchMode = CEKeyDownNoCatchMode;
        
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(setKeyCatchModeWithNotification:)
                                                     name:CESetKeyCatchModeToCatchMenuShortcutNotification
                                                   object:nil];
    }
    return self;
}


// ------------------------------------------------------
/// あとかたづけ
- (void)dealloc
// ------------------------------------------------------
{
    // ノーティフィケーションセンタから自身を排除
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}


// ------------------------------------------------------
/// keyDownイベントをキャッチする
- (void)sendEvent:(NSEvent *)anEvent
// ------------------------------------------------------
{
    if (([self keyCatchMode] == CECatchMenuShortCutMode) && ([anEvent type] == NSKeyDown)) {
        NSString *charIgnoringMod = [anEvent charactersIgnoringModifiers];
        if ([charIgnoringMod length] > 0) {
            NSUInteger modifierFlags = [anEvent modifierFlags];
            NSCharacterSet *ignoringShiftSet = [NSCharacterSet characterSetWithCharactersInString:@"`~!@#$%^&()_{}|\":<>?=/*-+.'"];

            // Backspace または delete キーが押されていた時、是正する
            // （return 上の方にあるのが Backspace、テンキーとのあいだにある「delete」の刻印があるのが delete(forword)）
            switch ([charIgnoringMod characterAtIndex:0]) {
                case NSDeleteCharacter:
                    charIgnoringMod = [NSString stringWithFormat:@"%C", (unichar)NSBackspaceCharacter];
                    break;
                case NSDeleteFunctionKey:
                    charIgnoringMod = [NSString stringWithFormat:@"%C", (unichar)NSDeleteCharacter];
                    break;
            }
            // 不要なシフトを削除
            if ([ignoringShiftSet characterIsMember:[charIgnoringMod characterAtIndex:0]] &&
                (modifierFlags & NSShiftKeyMask)) {
                modifierFlags ^= NSShiftKeyMask;
            }
            [[NSNotificationCenter defaultCenter] postNotificationName:CECatchMenuShortcutNotification
                                                                object:self
                                                              userInfo:@{k_keyBindingModFlags: @(modifierFlags),
                                                                         k_keyBindingChar: charIgnoringMod}];
            [self setKeyCatchMode:CEKeyDownNoCatchMode];
            return;
        }
    }
    
    [super sendEvent:anEvent];
}



#pragma mark Private Methods

//=======================================================
// Private method
//
//=======================================================

// ------------------------------------------------------
/// ノーティフィケーションからキーキャッチモードを設定
- (void)setKeyCatchModeWithNotification:(NSNotification *)aNotification
// ------------------------------------------------------
{
    CEKeyCatchMode mode = [[aNotification userInfo][k_keyCatchMode] integerValue];

    [self setKeyCatchMode:mode];
}

@end
