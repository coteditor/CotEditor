/*
 
 CEKeyBindingUtils.h
 
 CotEditor
 http://coteditor.com
 
 Created by 1024jp on 2014-04-20.
 
 ------------------------------------------------------------------------------
 
 © 2004-2007 nakamuxu
 © 2014-2016 1024jp
 
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

@import AppKit;


// Modifier masks and characters for keybindings
extern NSEventModifierFlags const kModifierKeyMaskList[];
extern unichar const kModifierKeySymbolCharList[];
extern unichar const kKeySpecCharList[];

// size of kModifierKeyMaskList, kKeySpecCharList and kModifierKeySymbolCharList
extern NSUInteger const kSizeOfModifierKeys;
// indexes of kModifierKeyMaskList, kKeySpecCharList and kModifierKeySymbolCharList
typedef NS_ENUM(NSUInteger, CEModifierKeyIndex) {
    CEControlKeyIndex,
    CEAlternateKeyIndex,
    CEShiftKeyIndex,
    CECommandKeyIndex,
};

// Unprintable key list
extern unichar const kUnprintableKeyList[];
extern NSUInteger const kSizeOfUnprintableKeyList;


@interface CEKeyBindingUtils : NSObject

/// returns string form keyEquivalent (keyboard shortcut) for menu item
+ (nonnull NSString *)keyEquivalentAndModifierMask:(nonnull NSUInteger *)modifierMask
                                        fromString:(nonnull NSString *)string
                               includingCommandKey:(BOOL)needsIncludingCommandKey;

@end
