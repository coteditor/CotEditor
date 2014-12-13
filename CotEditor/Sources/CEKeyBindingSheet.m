/*
 ==============================================================================
 CEKeyBindingSheet
 
 CotEditor
 http://coteditor.com
 
 Created on 2014-08-20 by 1024jp
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

#import "CEKeyBindingSheet.h"


@implementation CEKeyBindingSheet

#pragma mark Superclass Methods

// ------------------------------------------------------
/// catch shortcut input
- (void)sendEvent:(NSEvent *)anEvent
// ------------------------------------------------------
{
    if ([self shouldCatchShortcut] && ([anEvent type] == NSKeyDown)) {
        NSString *charsIgnoringModifiers = [anEvent charactersIgnoringModifiers];
        
        if ([charsIgnoringModifiers length] > 0) {
            NSUInteger modifierFlags = [anEvent modifierFlags];
            NSCharacterSet *ignoringShiftSet = [NSCharacterSet characterSetWithCharactersInString:@"`~!@#$%^&()_{}|\":<>?=/*-+.'"];
            
            // correct Backspace and delete keys
            //   `Backspace` key: the key above `return`
            //   `delete(forword)` key: the key with printed `delete` where next to ten key pad.
            switch ([charsIgnoringModifiers characterAtIndex:0]) {
                case NSDeleteCharacter:
                    charsIgnoringModifiers = [NSString stringWithFormat:@"%C", (unichar)NSBackspaceCharacter];
                    break;
                case NSDeleteFunctionKey:
                    charsIgnoringModifiers = [NSString stringWithFormat:@"%C", (unichar)NSDeleteCharacter];
                    break;
            }
            
            // remove unwanted Shift
            if ([ignoringShiftSet characterIsMember:[charsIgnoringModifiers characterAtIndex:0]] &&
                (modifierFlags & NSShiftKeyMask))
            {
                modifierFlags ^= NSShiftKeyMask;
            }
            
            [[self keyCatchDelegate] didCatchModifierFlags:modifierFlags charsIgnoringModifiers:charsIgnoringModifiers];
            [self setShouldCatchShortcut:NO];
            
            return;
        }
    }
    
    [super sendEvent:anEvent];
}

@end
