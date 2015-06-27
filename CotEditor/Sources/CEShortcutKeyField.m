/*
 ==============================================================================
 CEShortcutKeyField
 
 CotEditor
 http://coteditor.com
 
 Created on 2014-12-16 by 1024jp
 encoding="UTF-8"
 ------------------------------------------------------------------------------
 
 © 2004-2007 nakamuxu
 © 2014-2015 1024jp
 
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

#import "CEShortcutKeyField.h"
#import "CEKeyBindingManager.h"


@interface CEShortcutKeyField ()

@property (nonatomic, nullable) id keyDownMonitor;

@end




#pragma mark -

@implementation CEShortcutKeyField

#pragma mark Superclass Methods

// ------------------------------------------------------
/// text field turns into edit mode
- (BOOL)becomeFirstResponder
// ------------------------------------------------------
{
    if (![super becomeFirstResponder]) { return NO; }
    
    __weak typeof(self) weakSelf = self;
    [self setKeyDownMonitor:[NSEvent addLocalMonitorForEventsMatchingMask:NSKeyDownMask handler:^NSEvent *(NSEvent *event)
    {
        typeof(weakSelf) strongSelf = weakSelf;
        NSString *charsIgnoringModifiers = [event charactersIgnoringModifiers];
        NSEventModifierFlags modifierFlags = [event modifierFlags];
        
        if ([charsIgnoringModifiers length] == 0) { return event; }
        
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
        NSCharacterSet *ignoringShiftSet = [NSCharacterSet characterSetWithCharactersInString:@"`~!@#$%^&()_{}|\":<>?=/*-+.'"];
        if ([ignoringShiftSet characterIsMember:[charsIgnoringModifiers characterAtIndex:0]] &&
            (modifierFlags & NSShiftKeyMask))
        {
            modifierFlags ^= NSShiftKeyMask;
        }
        
        // set input shortcut string to field
        NSString *keySpecChars = [CEKeyBindingManager keySpecCharsFromKeyEquivalent:charsIgnoringModifiers
                                                                      modifierFrags:modifierFlags];
        keySpecChars = [keySpecChars isEqualToString:@"\b"] ? @"" : keySpecChars;  // single NSDeleteCharacter should be deleted
        [strongSelf setStringValue:keySpecChars];
        
        // end editing
        [[strongSelf window] endEditingFor:nil];
        
        return nil;
    }]];
    
    return YES;
}


// ------------------------------------------------------
/// end editing
- (void)textDidEndEditing:(NSNotification *)notification
// ------------------------------------------------------
{
    // end monitoring key down event
    [NSEvent removeMonitor:[self keyDownMonitor]];
    [self setKeyDownMonitor:nil];
    
    [super textDidEndEditing:notification];
}

@end
