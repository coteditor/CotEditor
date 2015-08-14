/*
 
 CEShortcutKeyField.m
 
 CotEditor
 http://coteditor.com
 
 Created by 1024jp on 2014-12-16.

 ------------------------------------------------------------------------------
 
 © 2004-2007 nakamuxu
 © 2014-2015 1024jp
 
 Licensed under the Apache License, Version 2.0 (the "License");
 you may not use this file except in compliance with the License.
 You may obtain a copy of the License at
 
 http://www.apache.org/licenses/LICENSE-2.0
 
 Unless required by applicable law or agreed to in writing, software
 distributed under the License is distributed on an "AS IS" BASIS,
 WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 See the License for the specific language governing permissions and
 limitations under the License.
 
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
        typeof(self) self = weakSelf;  // strong self
        if (!self) { return nil; }
        
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
        [self setStringValue:keySpecChars];
        
        // end editing
        [[self window] endEditingFor:nil];
        
        return nil;
    }]];
    
    return YES;
}


// ------------------------------------------------------
/// end editing
- (void)textDidEndEditing:(nonnull NSNotification *)notification
// ------------------------------------------------------
{
    // end monitoring key down event
    [NSEvent removeMonitor:[self keyDownMonitor]];
    [self setKeyDownMonitor:nil];
    
    [super textDidEndEditing:notification];
}

@end
