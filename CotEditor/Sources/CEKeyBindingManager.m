/*
 
 CEKeyBindingManager.m
 
 CotEditor
 http://coteditor.com
 
 Created by nakamuxu on 2005-09-01.

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

#import "CEKeyBindingManager.h"
#import "CEAppDelegate.h"
#import "CEKeyBindingUtils.h"
#import "CEDefaults.h"
#import "Constants.h"


// outlineView data key, column identifier
NSString *_Nonnull const CEKeyBindingTitleKey = @"title";
NSString *_Nonnull const CEKeyBindingKeySpecCharsKey = @"keyBindingKey";
NSString *_Nonnull const CEKeyBindingSelectorStringKey = @"selectorString";
NSString *_Nonnull const CEKeyBindingChildrenKey = @"children";


@interface CEKeyBindingManager ()

@property (nonatomic, nonnull, copy) NSDictionary<NSString *, NSString *> *defaultMenuKeyBindingDict;
@property (nonatomic, nonnull, copy) NSDictionary<NSString *, NSString *> *defaultTextKeyBindingDict;
@property (nonatomic, nonnull, copy) NSDictionary<NSString *, NSString *> *menuKeyBindingDict;
@property (nonatomic, nonnull, copy) NSDictionary<NSString *, NSString *> *textKeyBindingDict;

@end




#pragma mark -

@implementation CEKeyBindingManager

static NSDictionary<NSString *, NSString *> *kUnprintableKeyTable;


#pragma mark Singleton

// ------------------------------------------------------
/// return singleton instance
+ (nonnull CEKeyBindingManager *)sharedManager
// ------------------------------------------------------
{
    static dispatch_once_t onceToken;
    static id shared = nil;
    
    dispatch_once(&onceToken, ^{
        shared = [[self alloc] init];
    });
    
    return shared;
}



#pragma mark Superclass Methods

// ------------------------------------------------------
/// initialize class
+ (void)initialize
// ------------------------------------------------------
{
    // set statics
    kUnprintableKeyTable = [self unprintableKeyDictionary];
}


// ------------------------------------------------------
/// initialize instance
- (instancetype)init
// ------------------------------------------------------
{
    self = [super init];
    if (self) {
        // read default key bindings
        NSURL *menuURL = [[NSBundle mainBundle] URLForResource:@"MenuKeyBindings"
                                                 withExtension:@"plist"
                                                  subdirectory:@"KeyBindings"];
        _defaultMenuKeyBindingDict = [NSDictionary dictionaryWithContentsOfURL:menuURL];
        
        NSURL *textURL = [[NSBundle mainBundle] URLForResource:@"TextKeyBindings"
                                                 withExtension:@"plist"
                                                  subdirectory:@"KeyBindings"];
        _defaultTextKeyBindingDict = [NSDictionary dictionaryWithContentsOfURL:textURL];
        
        // read user key bindins if available
        _menuKeyBindingDict = [NSDictionary dictionaryWithContentsOfURL:[self menuKeyBindingSettingFileURL]] ?
                            : _defaultMenuKeyBindingDict;
        _textKeyBindingDict = [NSDictionary dictionaryWithContentsOfURL:[self textKeyBindingSettingFileURL]] ?
                            : _defaultTextKeyBindingDict;
    }
    return self;
}



#pragma mark Public Methods

//------------------------------------------------------
/// キーバインディング定義文字列から表示用文字列を生成し、返す
+ (nonnull NSString *)printableKeyStringFromKeySpecChars:(nonnull NSString *)keySpecChars
//------------------------------------------------------
{
    NSInteger length = [keySpecChars length];
    
    if (length < 2) { return @""; }
    
    NSString *keyEquivalent = [keySpecChars substringFromIndex:(length - 1)];
    NSString *keyStr = [self printableKeyStringFromKeyEquivalent:keyEquivalent];
    BOOL drawsShift = (isupper([keyEquivalent characterAtIndex:0]) == 1);
    NSString *modKeyStr = [self printableKeyStringFromModKeySpecChars:[keySpecChars substringToIndex:(length - 1)]
                                                         withShiftKey:drawsShift];
    
    return [NSString stringWithFormat:@"%@%@", modKeyStr, keyStr];
}


//------------------------------------------------------
/// メニューのキーボードショートカットからキーバインディング定義文字列を返す
+ (nonnull NSString *)keySpecCharsFromKeyEquivalent:(nonnull NSString *)keyEquivalent modifierFrags:(NSEventModifierFlags)modifierFlags
//------------------------------------------------------
{
    if ([keyEquivalent length] < 1) { return @""; }
    
    NSMutableString *keySpecChars = [NSMutableString string];
    unichar theChar = [keyEquivalent characterAtIndex:0];
    BOOL isShiftPressed = NO;
    
    for (NSInteger i = 0; i < kSizeOfModifierKeys; i++) {
        if ((modifierFlags & kModifierKeyMaskList[i]) ||
            ((i == CEShiftKeyIndex) && (isupper(theChar) == 1)))
        {
            // （メニューから定義値を取得した時、アルファベット+シフトの場合にシフトの定義が欠落するための回避処置）
            [keySpecChars appendFormat:@"%C", kKeySpecCharList[i]];
            if ((i == CEShiftKeyIndex) && (isupper(theChar) == 1)) {
                isShiftPressed = YES;
            }
        }
    }
    [keySpecChars appendString:(isShiftPressed ? [keyEquivalent uppercaseString] : keyEquivalent)];
    
    return keySpecChars;
}


//------------------------------------------------------
/// すべてのメニューにキーボードショートカットを設定し直す
- (void)applyKeyBindingsToMainMenu
//------------------------------------------------------
{
    // まず、全メニューのショートカット定義をクリアする
    [self clearMenuKeyBindingRecurrently:[NSApp mainMenu]];
    
    // メニュー更新（キーボードショートカット設定反映）
    [self applyMenuKeyBindingRecurrently:[NSApp mainMenu]];
}


//------------------------------------------------------
/// 重複チェック用配列を生成
- (nonnull NSMutableArray<NSString *> *)keySpecCharsListFromOutlineData:(nonnull NSArray<NSDictionary *> *)outlineData
//------------------------------------------------------
{
    NSMutableArray<NSString *> *keySpecCharsList = [NSMutableArray array];
    
    for (NSDictionary *item in outlineData) {
        NSArray *children = item[CEKeyBindingChildrenKey];
        if (children) {
            NSArray<NSString *> *childList = [self keySpecCharsListFromOutlineData:children];
            [keySpecCharsList addObjectsFromArray:childList];
        }
        NSString *keySpecChars = item[CEKeyBindingKeySpecCharsKey];
        if (([keySpecChars length] > 0) && ![keySpecCharsList containsObject:keySpecChars]) {
            [keySpecCharsList addObject:keySpecChars];
        }
    }
    return keySpecCharsList;
}


// ------------------------------------------------------
/// キー入力に応じたセレクタ文字列を返す
- (nonnull NSString *)selectorStringWithKeyEquivalent:(nonnull NSString *)keyEquivalent modifierFrags:(NSEventModifierFlags)modifierFlags
// ------------------------------------------------------
{
    NSString *keySpecChars = [[self class] keySpecCharsFromKeyEquivalent:keyEquivalent modifierFrags:modifierFlags];

    return [self textKeyBindingDict][keySpecChars];
}


// ------------------------------------------------------
/// メニューキーバインディングがカスタマイズされているか
- (BOOL)usesDefaultMenuKeyBindings
// ------------------------------------------------------
{
    return [[self menuKeyBindingDict] isEqualToDictionary:[self defaultMenuKeyBindingDict]];
}


// ------------------------------------------------------
/// テキストキーバインディングがカスタマイズされているか
- (BOOL)usesDefaultTextKeyBindings
// ------------------------------------------------------
{
    NSArray<NSString *> *defaultInsertTexts = [[[NSUserDefaults alloc] init] volatileDomainForName:NSRegistrationDomain][CEDefaultInsertCustomTextArrayKey];
    NSArray<NSString *> *insertTexts = [[NSUserDefaults standardUserDefaults] stringArrayForKey:CEDefaultInsertCustomTextArrayKey];
    
    return [insertTexts isEqualToArray:defaultInsertTexts] && [[self textKeyBindingDict] isEqualToDictionary:[self defaultTextKeyBindingDict]];
}


//------------------------------------------------------
/// メニューキーバインディングの現在の保持データから設定を読み込み編集用アウトラインビューデータ配列を返す（usesFactoryDefaults == YES で標準設定を、NO で現在の設定を返す）
- (nonnull NSMutableArray<NSMutableDictionary<NSString *, id> *> *)menuKeySpecCharsArrayForOutlineDataWithFactoryDefaults:(BOOL)usesFactoryDefaults
//------------------------------------------------------
{
    return [self menuKeySpecCharsArrayForMenu:[NSApp mainMenu] factoryDefaults:usesFactoryDefaults];
}


//------------------------------------------------------
/// テキストキーバインディングの現在の保持データから設定を読み込み編集用アウトラインビューデータ配列を返す（usesFactoryDefaults == YES で標準設定を、NO で現在の設定を返す）
- (nonnull NSMutableArray<NSMutableDictionary<NSString *, NSString *> *> *)textKeySpecCharsArrayForOutlineDataWithFactoryDefaults:(BOOL)usesFactoryDefaults
//------------------------------------------------------
{
    NSMutableArray<NSMutableDictionary<NSString *, NSString *> *> *textKeySpecCharsArray = [NSMutableArray array];
    NSDictionary<NSString *, NSString *> *dict = usesFactoryDefaults ? [self defaultTextKeyBindingDict] : [self textKeyBindingDict];
    const NSRange actionIndexRange = NSMakeRange(17, 2);  // range of numbers in "insertCustomText_00:"
    
    for (NSString *selector in [[self class] textKeyBindingSelectorStrings]) {
        if ([selector length] == 0) { continue; }
        
        NSString *title = [NSString stringWithFormat:NSLocalizedString(@"Insert Text %@", nil),
                           @([[selector substringWithRange:actionIndexRange] integerValue])] ? : @"";
        NSString *key = [[dict allKeysForObject:selector] firstObject] ? : @"";
        
        [textKeySpecCharsArray addObject:[@{CEKeyBindingTitleKey: title,
                                            CEKeyBindingKeySpecCharsKey: key,
                                            CEKeyBindingSelectorStringKey: selector} mutableCopy]];
    }
    
    return textKeySpecCharsArray;
}


//------------------------------------------------------
/// メニューキーバインディング設定を保存
- (BOOL)saveMenuKeyBindings:(nonnull NSArray<NSDictionary<NSString *, id> *> *)outlineData
//------------------------------------------------------
{
    NSDictionary<NSString *, id> *dictToSave = [self keyBindingDictionaryFromOutlineData:outlineData];
    NSURL *fileURL = [self menuKeyBindingSettingFileURL];
    BOOL success = NO;
    
    // デフォルトと同じ場合は現在のユーザ設定ファイルを削除する
    if ([dictToSave isEqualToDictionary:[self defaultMenuKeyBindingDict]]) {
        [[NSFileManager defaultManager] removeItemAtURL:fileURL error:nil];
        success = YES;
        
    } else {
        if ([self prepareUserSettingDicrectory]) {
            success = [dictToSave writeToURL:fileURL atomically:YES];
        }
    }
    
    // メニューに反映させる
    if (success) {
        [self setMenuKeyBindingDict:dictToSave];
    } else {
        NSLog(@"Error on saving the menu keybindings setting file.");
    }
    [self applyKeyBindingsToMainMenu];
    
    return success;
}


//------------------------------------------------------
/// テキストキーバインディング設定を保存
- (BOOL)saveTextKeyBindings:(nonnull NSArray<NSDictionary<NSString *, NSString *> *> *)outlineData texts:(nullable NSArray<NSString *> *)texts
//------------------------------------------------------
{
    NSDictionary<NSString *, id> *dictToSave = [self keyBindingDictionaryFromOutlineData:outlineData];
    NSURL *fileURL = [self textKeyBindingSettingFileURL];
    BOOL success = NO;
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    NSArray<NSString *> *defaultInsertTexts = [[[NSUserDefaults alloc] init] volatileDomainForName:NSRegistrationDomain][CEDefaultInsertCustomTextArrayKey];
    
    NSMutableArray<NSString *> *insertTexts = [NSMutableArray array];
    for (NSDictionary<NSString *, NSString *> *dict in texts) {
        NSString *insertText = dict[CEDefaultInsertCustomTextKey] ? : @"";
        [insertTexts addObject:insertText];
    }
    
    // デフォルトと同じ場合は現在のユーザ設定ファイルを削除する
    if ([dictToSave isEqualToDictionary:[self defaultTextKeyBindingDict]] &&
        [insertTexts isEqualToArray:defaultInsertTexts])
    {
        [[NSFileManager defaultManager] removeItemAtURL:fileURL error:nil];
        success = YES;
        
    } else {
        if ([self prepareUserSettingDicrectory]) {
            success = [dictToSave writeToURL:fileURL atomically:YES];
        }
    }
    
    // 新しいデータを保存する
    if (success) {
        [self setTextKeyBindingDict:dictToSave];
        [defaults setObject:insertTexts forKey:CEDefaultInsertCustomTextArrayKey];
        
    } else {
        NSLog(@"Error on saving the text keybindings setting file.");
    }
    
    return success;
}



#pragma mark Private Mthods

//------------------------------------------------------
/// キーバインディング設定ファイル保存用ディレクトリのURLを返す
- (nonnull NSURL *)userSettingDirecotryURL
//------------------------------------------------------
{
    return [[(CEAppDelegate *)[NSApp delegate] supportDirectoryURL] URLByAppendingPathComponent:@"KeyBindings"];
}


//------------------------------------------------------
/// メニューキーバインディング設定ファイル保存用ファイルのURLを返す
- (nonnull NSURL *)menuKeyBindingSettingFileURL
//------------------------------------------------------
{
    return [[[self userSettingDirecotryURL] URLByAppendingPathComponent:@"MenuKeyBindings"]
                                            URLByAppendingPathExtension:@"plist"];
}


//------------------------------------------------------
/// メニューキーバインディング設定ファイル保存用ファイルのURLを返す
- (nonnull NSURL *)textKeyBindingSettingFileURL
//------------------------------------------------------
{
    return [[[self userSettingDirecotryURL] URLByAppendingPathComponent:@"TextKeyBindings"]
                                            URLByAppendingPathExtension:@"plist"];
}


//------------------------------------------------------
/// ユーザ設定ディレクトリがない場合は作成する
- (BOOL)prepareUserSettingDicrectory
//------------------------------------------------------
{
    BOOL success = NO;
    NSURL *URL = [self userSettingDirecotryURL];
    NSNumber *isDirectory;
    
    if (![URL getResourceValue:&isDirectory forKey:NSURLIsDirectoryKey error:nil]) {
        success = [[NSFileManager defaultManager] createDirectoryAtURL:URL
                                           withIntermediateDirectories:YES attributes:nil error:nil];
    } else {
        success = [isDirectory boolValue];
    }
    
    if (!success) {
        NSLog(@"failed to create a directory at \"%@\".", URL);
    }
    
    return success;
}


//------------------------------------------------------
/// menu item to ignore by key binding setting
- (BOOL)shouldIgnoreItem:(nonnull NSMenuItem *)menuItem
//------------------------------------------------------
{
    // specific item types
    if ([menuItem isSeparatorItem] ||
        [menuItem isAlternate] ||  // hidden items
        [[menuItem title] length] == 0)
    {
        return YES;
    }
    
    // specific tags
    if ([menuItem tag] == CEServicesMenuItemTag ||
        [menuItem tag] == CESharingServiceMenuItemTag ||
        [menuItem tag] == CEScriptMenuDirectoryTag)
    {
        return YES;
    }
    
    // specific selectors
    NSString *selectorString = NSStringFromSelector([menuItem action]);
    if ([[[self class] selectorStringsToIgnore] containsObject:selectorString]) {
        return YES;
    }
    
    return NO;
}


//------------------------------------------------------
/// メニューのキーボードショートカットをクリアする
- (void)clearMenuKeyBindingRecurrently:(nonnull NSMenu *)menu
//------------------------------------------------------
{
    for (NSMenuItem *item in [menu itemArray]) {
        if ([self shouldIgnoreItem:item]) { continue; }
        
        [item setKeyEquivalent:@""];
        [item setKeyEquivalentModifierMask:0];
        
        if ([item hasSubmenu]) {
            [self clearMenuKeyBindingRecurrently:[item submenu]];
        }
    }
}


//------------------------------------------------------
/// メニューにキーボードショートカットを設定する
- (void)applyMenuKeyBindingRecurrently:(nonnull NSMenu *)menu
//------------------------------------------------------
{
    // NSMenu の indexOfItemWithTarget:andAction: だと取得できないメニューアイテムがあるため、メニューをひとつずつなめる
    for (NSMenuItem *item in [menu itemArray]) {
        if ([self shouldIgnoreItem:item]) { continue; }
        
        if ([item hasSubmenu]) {
            [self applyMenuKeyBindingRecurrently:[item submenu]];
            
        } else {
            NSUInteger modifierMask = 0;
            NSString *keySpecChars = [self keySpecCharsForSelector:[item action] factoryDefaults:NO];
            NSString *keyEquivalent = [CEKeyBindingUtils keyEquivalentAndModifierMask:&modifierMask
                                                                           fromString:keySpecChars
                                                                  includingCommandKey:YES];

            // keySpecChars があり Cmd が設定されている場合だけ、反映させる
            if (([keySpecChars length] > 0) && (modifierMask & NSCommandKeyMask)) {
                [item setKeyEquivalent:keyEquivalent];
                [item setKeyEquivalentModifierMask:modifierMask];
            }
        }
    }
    
    // ショートカット設定を反映させる
    [menu update];
}


//------------------------------------------------------
/// 現在のメニューからショートカットキー設定を読み込み編集用アウトラインビューデータ配列を返す
- (nonnull NSMutableArray<NSMutableDictionary<NSString *, id> *> *)menuKeySpecCharsArrayForMenu:(nonnull NSMenu *)menu factoryDefaults:(BOOL)usesFactoryDefaults
//------------------------------------------------------
{
    NSMutableArray<NSMutableDictionary<NSString *, id> *> *outlineData = [NSMutableArray array];
    
    for (NSMenuItem *item in [menu itemArray]) {
        if ([self shouldIgnoreItem:item]) { continue; }
        
        NSDictionary<NSString *, id> *row;
        if ([item hasSubmenu]) {
            NSMutableArray<NSMutableDictionary<NSString *, id> *> *subArray = [self menuKeySpecCharsArrayForMenu:[item submenu] factoryDefaults:usesFactoryDefaults];
            
            row = @{CEKeyBindingTitleKey: [item title],
                    CEKeyBindingChildrenKey: subArray};
            
        } else {
            if (![item action]) { continue; }
            
            NSString *keySpecChars = usesFactoryDefaults ? [self keySpecCharsForSelector:[item action] factoryDefaults:YES] :
                                                           [[self class] keySpecCharsFromKeyEquivalent:[item keyEquivalent]
                                                                                         modifierFrags:[item keyEquivalentModifierMask]];
            
            row = @{CEKeyBindingTitleKey: [item title],
                    CEKeyBindingKeySpecCharsKey: keySpecChars,
                    CEKeyBindingSelectorStringKey: NSStringFromSelector([item action])};
        }
        
        [outlineData addObject:[row mutableCopy]];
    }
    
    return outlineData;
}


//------------------------------------------------------
/// アウトラインビューデータから保存用辞書を生成
- (nonnull NSMutableDictionary<NSString *, id> *)keyBindingDictionaryFromOutlineData:(NSArray<NSDictionary<NSString *, id> *> *)outlineData
//------------------------------------------------------
{
    NSMutableDictionary<NSString *, id> *keyBindingDict = [NSMutableDictionary dictionary];

    for (NSDictionary<NSString *, id> *item in outlineData) {
        if (item[CEKeyBindingChildrenKey]) {
            NSArray<NSDictionary<NSString *, id> *> *children = item[CEKeyBindingChildrenKey];
            NSDictionary<NSString *, id> *childDict = [self keyBindingDictionaryFromOutlineData:children];
            [keyBindingDict addEntriesFromDictionary:childDict];
            
        } else {
            NSString *keySpecChars = item[CEKeyBindingKeySpecCharsKey];
            NSString *selectorString = item[CEKeyBindingSelectorStringKey];
            if (([keySpecChars length] > 0) && ([selectorString length] > 0)) {
                keyBindingDict[keySpecChars] = selectorString;
            }
        }
    }
    
    return keyBindingDict;
}


//------------------------------------------------------
/// セレクタ名を定義しているキーバインディング文字列（キー）を得る
- (nonnull NSString *)keySpecCharsForSelector:(SEL)selector factoryDefaults:(BOOL)usesFactoryDefaults
//------------------------------------------------------
{
    NSString *selectorString = NSStringFromSelector(selector);
    NSDictionary *dict = usesFactoryDefaults ? [self defaultMenuKeyBindingDict] : [self menuKeyBindingDict];
    NSArray<NSString *> *keys = [dict allKeysForObject:selectorString];
    
    return [keys firstObject] ? : @"";
}


//------------------------------------------------------
/// メニューのキーボードショートカットから表示用文字列を返す
+ (nonnull NSString *)printableKeyStringFromKeyEquivalent:(nonnull NSString *)keyEquivalent
//------------------------------------------------------
{
    if ([keyEquivalent length] < 1) { return @""; }
    
    unichar theChar = [keyEquivalent characterAtIndex:0];
    if ([[NSCharacterSet alphanumericCharacterSet] characterIsMember:theChar]) {
        return [keyEquivalent uppercaseString];
    } else {
        return [self printableCharFromIgnoringModChar:keyEquivalent];
    }
}


//------------------------------------------------------
/// キーバインディング定義文字列から表示用モディファイアキー文字列を生成し、返す
+ (nonnull NSString *)printableKeyStringFromModKeySpecChars:(nonnull NSString *)modKeySpecChars withShiftKey:(BOOL)drawsShiftKey
//------------------------------------------------------
{
    NSCharacterSet *modStringSet = [NSCharacterSet characterSetWithCharactersInString:modKeySpecChars];
    NSMutableString *keyString = [NSMutableString string];
    
    for (NSUInteger i = 0; i < kSizeOfModifierKeys; i++) {
        unichar theChar = kKeySpecCharList[i];
        if ([modStringSet characterIsMember:theChar] || ((i == CEShiftKeyIndex) && drawsShiftKey)) {
            [keyString appendFormat:@"%C", kModifierKeySymbolCharList[i]];
        }
    }
    
    return keyString;
}


//------------------------------------------------------
/// キーバインディング定義文字列またはキーボードショートカットキーからキー表示用文字列を生成し、返す
+ (nonnull NSString *)printableCharFromIgnoringModChar:(nonnull NSString *)modCharString
//------------------------------------------------------
{
    return kUnprintableKeyTable[modCharString] ? : modCharString;
}


//------------------------------------------------------
/// そのまま表示できないキーバインディング定義文字列の変換辞書を返す
+ (nonnull NSDictionary<NSString *, NSString *> *)unprintableKeyDictionary
//------------------------------------------------------
{
    // 下記の情報を参考にさせていただきました (2005.09.05)
    // http://www.cocoabuilder.com/archive/message/2004/3/19/102023
    NSArray<NSString *> *printableChars = @[[NSString stringWithFormat:@"%C", (unichar)0x2191], // "↑" NSUpArrowFunctionKey,
                                            [NSString stringWithFormat:@"%C", (unichar)0x2193], // "↓" NSDownArrowFunctionKey,
                                            [NSString stringWithFormat:@"%C", (unichar)0x2190], // "←" NSLeftArrowFunctionKey,
                                            [NSString stringWithFormat:@"%C", (unichar)0x2192], // "→" NSRightArrowFunctionKey,
                                            @"F1",  // NSF1FunctionKey,
                                            @"F2",  // NSF2FunctionKey,
                                            @"F3",  // NSF3FunctionKey,
                                            @"F4",  // NSF4FunctionKey,
                                            @"F5",  // NSF5FunctionKey,
                                            @"F6",  // NSF6FunctionKey,
                                            @"F7",  // NSF7FunctionKey,
                                            @"F8",  // NSF8FunctionKey,
                                            @"F9",  // NSF9FunctionKey,
                                            @"F10", // NSF10FunctionKey,
                                            @"F11", // NSF11FunctionKey,
                                            @"F12", // NSF12FunctionKey,
                                            @"F13", // NSF13FunctionKey,
                                            @"F14", // NSF14FunctionKey,
                                            @"F15", // NSF15FunctionKey,
                                            @"F16", // NSF16FunctionKey,
                                            [NSString stringWithFormat:@"%C", (unichar)0x2326], // "⌦" NSDeleteCharacter = "Delete forward"
                                            [NSString stringWithFormat:@"%C", (unichar)0x2196], // "↖" NSHomeFunctionKey,
                                            [NSString stringWithFormat:@"%C", (unichar)0x2198], // "↘" NSEndFunctionKey,
                                            [NSString stringWithFormat:@"%C", (unichar)0x21DE], // "⇞" NSPageUpFunctionKey,
                                            [NSString stringWithFormat:@"%C", (unichar)0x21DF], // "⇟" NSPageDownFunctionKey,
                                            [NSString stringWithFormat:@"%C", (unichar)0x2327], // "⌧" NSClearLineFunctionKey,
                                            @"Help", // NSHelpFunctionKey,
                                            NSLocalizedString(@"Space", @"keybord key name"), // "Space"
                                            [NSString stringWithFormat:@"%C", (unichar)0x21E5], // "⇥" "Tab"
                                            [NSString stringWithFormat:@"%C", (unichar)0x21A9], // "↩" "Return"
                                            [NSString stringWithFormat:@"%C", (unichar)0x232B], // "⌫" "Backspace"
                                            [NSString stringWithFormat:@"%C", (unichar)0x2305], // "⌅" "Enter"
                                            [NSString stringWithFormat:@"%C", (unichar)0x21E4], // "⇤" "Backtab"
                                            [NSString stringWithFormat:@"%C", (unichar)0x238B], // "⎋" "Escape"
                                            ];
    
    NSAssert(kSizeOfUnprintableKeyList == [printableChars count],
             @"Internal data error! Sizes of 'kUnprintableKeyList' and 'printableChars' are different.");
    
    NSMutableArray<NSString *> *keys = [NSMutableArray arrayWithCapacity:kSizeOfUnprintableKeyList];
    for (NSInteger i = 0; i < kSizeOfUnprintableKeyList; i++) {
        [keys addObject:[NSString stringWithFormat:@"%C", kUnprintableKeyList[i]]];
    }

    return [NSDictionary dictionaryWithObjects:printableChars forKeys:keys];
}


//------------------------------------------------------
/// 独自定義のセレクタ名配列を返す
+ (nonnull NSArray<NSString *> *)textKeyBindingSelectorStrings
//------------------------------------------------------
{
    return @[@"insertCustomText_00:",
             @"insertCustomText_01:",
             @"insertCustomText_02:",
             @"insertCustomText_03:",
             @"insertCustomText_04:",
             @"insertCustomText_05:",
             @"insertCustomText_06:",
             @"insertCustomText_07:",
             @"insertCustomText_08:",
             @"insertCustomText_09:",
             @"insertCustomText_10:",
             @"insertCustomText_11:",
             @"insertCustomText_12:",
             @"insertCustomText_13:",
             @"insertCustomText_14:",
             @"insertCustomText_15:",
             @"insertCustomText_16:",
             @"insertCustomText_17:",
             @"insertCustomText_18:",
             @"insertCustomText_19:",
             @"insertCustomText_20:",
             @"insertCustomText_21:",
             @"insertCustomText_22:",
             @"insertCustomText_23:",
             @"insertCustomText_24:",
             @"insertCustomText_25:",
             @"insertCustomText_26:",
             @"insertCustomText_27:",
             @"insertCustomText_28:",
             @"insertCustomText_29:",
             @"insertCustomText_30:"];
}


//------------------------------------------------------
/// 変更しない項目のセレクタ名配列を返す
+ (nonnull NSArray<NSString *> *)selectorStringsToIgnore
//------------------------------------------------------
{
    return @[@"modifyFont:",
             @"changeEncoding:",
             @"changeSyntaxStyle:",
             @"changeTheme:",
             @"changeTabWidth:",
             @"changeLineHeight:",
             @"makeKeyAndOrderFront:",
             @"launchScript:",
             @"_openRecentDocument:",  // = 10.3 の「最近開いた書類」
             @"orderFrontCharacterPalette:",  // = 10.4「特殊文字…」
             ];
}

@end




#pragma mark -

@implementation CEKeyBindingManager (Migration)

//------------------------------------------------------
/// ユーザのメニューキーバインディング設定をいったん削除する
- (BOOL)resetMenuKeyBindings
//------------------------------------------------------
{
    // 以前の CotEditor ではユーザがカスタムをしているしていないに関わらずメニューキーバインディングの設定が
    // ユーザ領域に作成されていたため最初にインストールしたバージョン以降でデフォルトのショートカットやメソッド名が
    // 変更された場合にそれに追従できなかった。
    // その負のサイクルを断ち切るために、過去の設定ファイルを一旦削除をする。
    
    BOOL success = NO;
    NSURL *URL = [self menuKeyBindingSettingFileURL];
    
    if ([URL checkResourceIsReachableAndReturnError:nil]) {
        success = [[NSFileManager defaultManager] removeItemAtURL:URL error:nil];
        
        [self setMenuKeyBindingDict:[self defaultMenuKeyBindingDict]];
        [self applyKeyBindingsToMainMenu];
    }
    
    return success;
}

@end
