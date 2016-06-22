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

#import "CEKeyBindingUtils.h"


// indexes of kModifierKeyMaskList, kModifierKeySpecCharList and kModifierKeySymbolCharList
typedef NS_ENUM(NSUInteger, CEModifierKeyIndex) {
    CEControlKeyIndex,
    CEAlternateKeyIndex,
    CEShiftKeyIndex,
    CECommandKeyIndex,
};

// Modifier keys and characters
static NSEventModifierFlags const kModifierKeyMaskList[] = {
    NSControlKeyMask,
    NSAlternateKeyMask,
    NSShiftKeyMask,
    NSCommandKeyMask,
};
static unichar const kModifierKeySymbolCharList[] = {
    0x005E,  // ^
    0x2325,  // ⌥
    0x21E7,  // ⇧
    0x2318,  // ⌘
};
static unichar const kModifierKeySpecCharList[] = {
    '^',
    '~',
    '$',
    '@',
};

static NSUInteger const kSizeOfModifierKeys = sizeof(kModifierKeyMaskList) / sizeof(NSEventModifierFlags);




@implementation CEKeyBindingUtils

#pragma mark Public Methods

//------------------------------------------------------
/// return keySpecChars to store from keyEquivalent and modifierMask
+ (nonnull NSString *)keySpecCharsFromKeyEquivalent:(nonnull NSString *)keyEquivalent modifierMask:(NSEventModifierFlags)modifierMask
//------------------------------------------------------
{
    if ([keyEquivalent length] < 1) { return @""; }
    
    NSMutableString *keySpecChars = [NSMutableString string];
    unichar theChar = [keyEquivalent characterAtIndex:0];
    BOOL isShiftPressed = NO;
    
    for (NSInteger i = 0; i < kSizeOfModifierKeys; i++) {
        if ((modifierMask & kModifierKeyMaskList[i]) ||
            ((i == CEShiftKeyIndex) && (isupper(theChar) == 1)))
        {
            // （メニューから定義値を取得した時、アルファベット+シフトの場合にシフトの定義が欠落するための回避処置）
            [keySpecChars appendFormat:@"%C", kModifierKeySpecCharList[i]];
            if ((i == CEShiftKeyIndex) && (isupper(theChar) == 1)) {
                isShiftPressed = YES;
            }
        }
    }
    [keySpecChars appendString:(isShiftPressed ? [keyEquivalent uppercaseString] : keyEquivalent)];
    
    return keySpecChars;
}


// ------------------------------------------------------
/// return keyEquivalent and modifierMask from keySpecChars to store
+ (nonnull NSString *)keyEquivalentAndModifierMask:(nonnull NSEventModifierFlags *)modifierMask fromKeySpecChars:(nonnull NSString *)keySpecChars requiresCommandKey:(BOOL)requiresCommandKey
//------------------------------------------------------
{
    *modifierMask = 0;
    NSUInteger length = [keySpecChars length];
    
    if (length < 2) { return @""; }
    
    NSString *key = [keySpecChars substringFromIndex:(length - 1)];
    NSCharacterSet *modifierChararacterSet = [NSCharacterSet characterSetWithCharactersInString:[keySpecChars substringToIndex:(length - 1)]];
    
    if ([modifierChararacterSet characterIsMember:kModifierKeySpecCharList[CEControlKeyIndex]]) {
        *modifierMask |= NSControlKeyMask;
    }
    if ([modifierChararacterSet characterIsMember:kModifierKeySpecCharList[CEAlternateKeyIndex]]) {
        *modifierMask |= NSAlternateKeyMask;
    }
    if (([modifierChararacterSet characterIsMember:kModifierKeySpecCharList[CEShiftKeyIndex]]) ||
        isupper([key characterAtIndex:0]))
    {
        *modifierMask |= NSShiftKeyMask;
    }
    if ([modifierChararacterSet characterIsMember:kModifierKeySpecCharList[CECommandKeyIndex]]) {
        *modifierMask |= NSCommandKeyMask;
    }
    
    if (requiresCommandKey && !(*modifierMask & NSCommandKeyMask)) {
        *modifierMask = 0;
        return @"";
    }
    
    return (*modifierMask != 0) ? key : @"";
}


//------------------------------------------------------
/// return shortcut string to display from keySpecChars to store
+ (nonnull NSString *)printableKeyStringFromKeySpecChars:(nonnull NSString *)keySpecChars
//------------------------------------------------------
{
    NSInteger length = [keySpecChars length];
    
    if (length < 2) { return [keySpecChars uppercaseString] ?: @""; }
    
    NSString *keyEquivalent = [keySpecChars substringFromIndex:(length - 1)];
    
    NSString *modifierKeyString = [self printableKeyStringFromModKeySpecChars:[keySpecChars substringToIndex:(length - 1)]
                                                                 withShiftKey:isupper([keyEquivalent characterAtIndex:0])];
    NSString *keyString = [self printableKeyStringFromKeyEquivalent:keyEquivalent];
    
    return [NSString stringWithFormat:@"%@%@", modifierKeyString, keyString];
}



#pragma mark Private Methods

//------------------------------------------------------
/// キーバインディング定義文字列から表示用モディファイアキー文字列を生成し、返す
+ (nonnull NSString *)printableKeyStringFromModKeySpecChars:(nonnull NSString *)modKeySpecChars withShiftKey:(BOOL)printsShiftKey
//------------------------------------------------------
{
    NSCharacterSet *modKeySpecCharSet = [NSCharacterSet characterSetWithCharactersInString:modKeySpecChars];
    NSMutableString *keyString = [NSMutableString string];
    
    for (NSUInteger index = 0; index < kSizeOfModifierKeys; index++) {
        unichar modKeySpecChar = kModifierKeySpecCharList[index];
        if ([modKeySpecCharSet characterIsMember:modKeySpecChar] || ((index == CEShiftKeyIndex) && printsShiftKey)) {
            [keyString appendFormat:@"%C", kModifierKeySymbolCharList[index]];
        }
    }
    
    return keyString;
}


//------------------------------------------------------
/// メニューのキーボードショートカットから表示用文字列を返す
+ (nonnull NSString *)printableKeyStringFromKeyEquivalent:(nonnull NSString *)keyEquivalent
//------------------------------------------------------
{
    if ([keyEquivalent length] < 1) { return @""; }
    
    unichar character = [keyEquivalent characterAtIndex:0];
    if ([[NSCharacterSet alphanumericCharacterSet] characterIsMember:character]) {
        return [keyEquivalent uppercaseString];
    } else {
        // キーバインディング定義文字列またはキーボードショートカットキーからキー表示用文字列を生成し、返す
        return [self unprintableKeyTable][keyEquivalent] ? : keyEquivalent;
    }
}


//------------------------------------------------------
/// そのまま表示できないキーバインディング定義文字列の変換辞書を返す
+ (nonnull NSDictionary<NSString *, NSString *> *)unprintableKeyTable
//------------------------------------------------------
{
    static NSDictionary<NSString *, NSString *> *unprintableKeyTable;
    
    if (!unprintableKeyTable) {
        static unichar const kUnprintableKeyList[] = {
            NSUpArrowFunctionKey,
            NSDownArrowFunctionKey,
            NSLeftArrowFunctionKey,
            NSRightArrowFunctionKey,
            NSF1FunctionKey,
            NSF2FunctionKey,
            NSF3FunctionKey,
            NSF4FunctionKey,
            NSF5FunctionKey,
            NSF6FunctionKey,
            NSF7FunctionKey,
            NSF8FunctionKey,
            NSF9FunctionKey,
            NSF10FunctionKey,
            NSF11FunctionKey,
            NSF12FunctionKey,
            NSF13FunctionKey,
            NSF14FunctionKey,
            NSF15FunctionKey,
            NSF16FunctionKey,
            NSDeleteCharacter,  // do not use NSDeleteFunctionKey
            NSHomeFunctionKey,
            NSEndFunctionKey,
            NSPageUpFunctionKey,
            NSPageDownFunctionKey,
            NSClearLineFunctionKey,
            NSHelpFunctionKey,
            ' ',  // = Space
            '\t',  // = Tab
            '\r',  // = Return
            '\b',  // = Backspace, (delete backword)
            '\003',  // = Enter
            '\031',  // = Backtab
            '\033',  // = Escape
        };
        NSUInteger const sizeOfUnprintableKeyList = sizeof(kUnprintableKeyList) / sizeof(unichar);
        
        NSMutableArray<NSString *> *unprintableKeys = [NSMutableArray arrayWithCapacity:sizeOfUnprintableKeyList];
        for (NSUInteger i = 0; i < sizeOfUnprintableKeyList; i++) {
            [unprintableKeys addObject:[NSString stringWithFormat:@"%C", kUnprintableKeyList[i]]];
        }
        
        NSArray<NSString *> *printableChars = @[[NSString stringWithFormat:@"%C", (unichar)0x2191],  // "↑" NSUpArrowFunctionKey,
                                                [NSString stringWithFormat:@"%C", (unichar)0x2193],  // "↓" NSDownArrowFunctionKey,
                                                [NSString stringWithFormat:@"%C", (unichar)0x2190],  // "←" NSLeftArrowFunctionKey,
                                                [NSString stringWithFormat:@"%C", (unichar)0x2192],  // "→" NSRightArrowFunctionKey,
                                                @"F1",  // NSF1FunctionKey,
                                                @"F2",  // NSF2FunctionKey,
                                                @"F3",  // NSF3FunctionKey,
                                                @"F4",  // NSF4FunctionKey,
                                                @"F5",  // NSF5FunctionKey,
                                                @"F6",  // NSF6FunctionKey,
                                                @"F7",  // NSF7FunctionKey,
                                                @"F8",  // NSF8FunctionKey,
                                                @"F9",  // NSF9FunctionKey,
                                                @"F10",  // NSF10FunctionKey,
                                                @"F11",  // NSF11FunctionKey,
                                                @"F12",  // NSF12FunctionKey,
                                                @"F13",  // NSF13FunctionKey,
                                                @"F14",  // NSF14FunctionKey,
                                                @"F15",  // NSF15FunctionKey,
                                                @"F16",  // NSF16FunctionKey,
                                                [NSString stringWithFormat:@"%C", (unichar)0x2326],  // "⌦" NSDeleteCharacter = "Delete forward"
                                                [NSString stringWithFormat:@"%C", (unichar)0x2196],  // "↖" NSHomeFunctionKey,
                                                [NSString stringWithFormat:@"%C", (unichar)0x2198],  // "↘" NSEndFunctionKey,
                                                [NSString stringWithFormat:@"%C", (unichar)0x21DE],  // "⇞" NSPageUpFunctionKey,
                                                [NSString stringWithFormat:@"%C", (unichar)0x21DF],  // "⇟" NSPageDownFunctionKey,
                                                [NSString stringWithFormat:@"%C", (unichar)0x2327],  // "⌧" NSClearLineFunctionKey,
                                                @"Help",  // NSHelpFunctionKey,
                                                NSLocalizedString(@"Space", @"keybord key name"),  // "Space"
                                                [NSString stringWithFormat:@"%C", (unichar)0x21E5],  // "⇥" "Tab"
                                                [NSString stringWithFormat:@"%C", (unichar)0x21A9],  // "↩" "Return"
                                                [NSString stringWithFormat:@"%C", (unichar)0x232B],  // "⌫" "Backspace"
                                                [NSString stringWithFormat:@"%C", (unichar)0x2305],  // "⌅" "Enter"
                                                [NSString stringWithFormat:@"%C", (unichar)0x21E4],  // "⇤" "Backtab"
                                                [NSString stringWithFormat:@"%C", (unichar)0x238B],  // "⎋" "Escape"
                                                ];
        
        NSAssert([unprintableKeys count] == [printableChars count],
                 @"Internal data error! Sizes of 'kUnprintableKeyList' and 'printableChars' are different.");
        
        unprintableKeyTable = [NSDictionary dictionaryWithObjects:printableChars forKeys:unprintableKeys];
    }
    
    return unprintableKeyTable;
}

@end
