/*
 
 CEKeyBindingManager.m
 
 CotEditor
 http://coteditor.com
 
 Created by nakamuxu on 2005-09-01.

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

#import "CEKeyBindingManager.h"
#import "CEAppDelegate.h"
#import "CEUtils.h"
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
+ (instancetype)sharedManager
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
    kUnprintableKeyTable = [CEKeyBindingManager unprintableKeyDictionary];
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
+ (nonnull NSString *)printableKeyStringFromKeySpecChars:(nonnull NSString *)string
//------------------------------------------------------
{
    NSInteger length = [string length];
    
    if (length < 2) { return @""; }
    
    NSString *keyEquivalent = [string substringFromIndex:(length - 1)];
    NSString *keyStr = [CEKeyBindingManager printableKeyStringsFromKeyEquivalent:keyEquivalent];
    BOOL drawsShift = (isupper([keyEquivalent characterAtIndex:0]) == 1);
    NSString *modKeyStr = [CEKeyBindingManager printableKeyStringFromModKeySpecChars:[string substringToIndex:(length - 1)]
                                                                        withShiftKey:drawsShift];
    
    return [NSString stringWithFormat:@"%@%@", modKeyStr, keyStr];
}


//------------------------------------------------------
/// メニューのキーボードショートカットからキーバインディング定義文字列を返す
+ (nonnull NSString *)keySpecCharsFromKeyEquivalent:(nonnull NSString *)string modifierFrags:(NSEventModifierFlags)modifierFlags
//------------------------------------------------------
{
    if ([string length] < 1) { return @""; }
    
    NSMutableString *keySpecChars = [NSMutableString string];
    unichar theChar = [string characterAtIndex:0];
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
    [keySpecChars appendString:(isShiftPressed ? [string uppercaseString] : string)];
    
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


// ------------------------------------------------------
/// キー入力に応じたセレクタ文字列を返す
- (nonnull NSString *)selectorStringWithKeyEquivalent:(nonnull NSString *)string modifierFrags:(NSEventModifierFlags)modifierFlags
// ------------------------------------------------------
{
    NSString *keySpecChars = [CEKeyBindingManager keySpecCharsFromKeyEquivalent:string modifierFrags:modifierFlags];

    return [self textKeyBindingDict][keySpecChars];
}


//------------------------------------------------------
/// デフォルト設定の、セレクタ名を定義しているキーバインディング文字列（キー）を得る
- (nonnull NSString *)keySpecCharsInDefaultDictionaryFromSelectorString:(nonnull NSString *)selectorString
//------------------------------------------------------
{
    NSArray<NSString *> *keys = [[self defaultMenuKeyBindingDict] allKeysForObject:selectorString];
    
    return [keys firstObject] ? : @"";
}


// ------------------------------------------------------
/// メニューキーバインディングがカスタマイズされているか
- (BOOL)usesDefaultMenuKeyBindings
// ------------------------------------------------------
{
    return ![[self menuKeyBindingSettingFileURL] checkResourceIsReachableAndReturnError:nil];
}


// ------------------------------------------------------
/// テキストキーバインディングがカスタマイズされているか
- (BOOL)usesDefaultTextKeyBindings
// ------------------------------------------------------
{
    NSArray<NSString *> *factoryDefault = [[[NSUserDefaults alloc] init] volatileDomainForName:NSRegistrationDomain][CEDefaultInsertCustomTextArrayKey];
    NSArray<NSString *> *insertTextArray = [[NSUserDefaults standardUserDefaults] stringArrayForKey:CEDefaultInsertCustomTextArrayKey];
    
    return [insertTextArray isEqualToArray:factoryDefault] && [[self textKeyBindingDict] isEqualToDictionary:[self defaultTextKeyBindingDict]];
}


//------------------------------------------------------
/// 現在のメニューからショートカットキー設定を読み込み編集用アウトラインビューデータ配列を返す
- (nonnull NSMutableArray<NSMutableDictionary<NSString *, id> *> *)mainMenuArrayForOutlineData:(nonnull NSMenu *)menu
//------------------------------------------------------
{
    NSMutableArray<NSMutableDictionary<NSString *, id> *> *outlineData = [NSMutableArray array];
    
    for (NSMenuItem *item in [menu itemArray]) {
        if ([self shouldIgnoreItem:item]) { continue; }
        
        NSDictionary<NSString *, id> *row;
        if ([item hasSubmenu]) {
            NSMutableArray<NSMutableDictionary<NSString *, id> *> *subArray = [self mainMenuArrayForOutlineData:[item submenu]];
            
            row = @{CEKeyBindingTitleKey: [item title],
                    CEKeyBindingChildrenKey: subArray};
            
        } else {
            if (![item action]) { continue; }
            
            NSString *keySpecChars = [CEKeyBindingManager keySpecCharsFromKeyEquivalent:[item keyEquivalent]
                                                                          modifierFrags:[item keyEquivalentModifierMask]];
            NSString *selector = NSStringFromSelector([item action]);
            
            row = @{CEKeyBindingTitleKey: [item title],
                    CEKeyBindingKeySpecCharsKey: keySpecChars,
                    CEKeyBindingSelectorStringKey: selector};
        }
        
        [outlineData addObject:[row mutableCopy]];
    }
    
    return outlineData;
}


//------------------------------------------------------
/// テキストキーバインディングの現在の保持データから設定を読み込み編集用アウトラインビューデータ配列を返す（usesFactoryDefaults == YES で標準設定を、NO で現在の設定を返す）
- (nonnull NSMutableArray<NSMutableDictionary<NSString *, NSString *> *> *)textKeySpecCharArrayForOutlineDataWithFactoryDefaults:(BOOL)usesFactoryDefaults
//------------------------------------------------------
{
    NSMutableArray<NSMutableDictionary<NSString *, NSString *> *> *textKeySpecCharArray = [NSMutableArray array];
    NSDictionary<NSString *, NSString *> *dict = usesFactoryDefaults ? [self defaultTextKeyBindingDict] : [self textKeyBindingDict];
    const NSRange actionIndexRange = NSMakeRange(17, 2);  // range of numbers in "insertCustomText_00:"
    
    for (NSString *selector in [CEKeyBindingManager textKeyBindingSelectorStrings]) {
        if ([selector length] == 0) { continue; }
        
        NSString *title = [NSString stringWithFormat:NSLocalizedString(@"Insert Text %@", nil),
                           @([[selector substringWithRange:actionIndexRange] integerValue])] ? : @"";
        NSString *key = [[dict allKeysForObject:selector] firstObject] ? : @"";
        
        [textKeySpecCharArray addObject:[@{CEKeyBindingTitleKey: title,
                                           CEKeyBindingKeySpecCharsKey: key,
                                           CEKeyBindingSelectorStringKey: selector} mutableCopy]];
    }
    
    return textKeySpecCharArray;
}


//------------------------------------------------------
/// メニューキーバインディング設定を保存
- (BOOL)saveMenuKeyBindings:(NSArray<NSDictionary<NSString *, id> *> *)outlineViewData
//------------------------------------------------------
{
    NSDictionary<NSString *, id> *dictToSave = [self keyBindingDictionaryFromOutlineViewDataArray:outlineViewData];
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
- (BOOL)saveTextKeyBindings:(NSArray<NSDictionary<NSString *, NSString *> *> *)outlineViewData texts:(nullable NSArray<NSString *> *)texts
//------------------------------------------------------
{
    NSDictionary<NSString *, id> *dictToSave = [self keyBindingDictionaryFromOutlineViewDataArray:outlineViewData];
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
- (NSURL *)userSettingDirecotryURL
//------------------------------------------------------
{
    return [[(CEAppDelegate *)[NSApp delegate] supportDirectoryURL] URLByAppendingPathComponent:@"KeyBindings"];
}


//------------------------------------------------------
/// メニューキーバインディング設定ファイル保存用ファイルのURLを返す
- (NSURL *)menuKeyBindingSettingFileURL
//------------------------------------------------------
{
    return [[[self userSettingDirecotryURL] URLByAppendingPathComponent:@"MenuKeyBindings"]
                                            URLByAppendingPathExtension:@"plist"];
}


//------------------------------------------------------
/// メニューキーバインディング設定ファイル保存用ファイルのURLを返す
- (NSURL *)textKeyBindingSettingFileURL
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
    NSError *error = nil;
    NSURL *URL = [self userSettingDirecotryURL];
    NSNumber *isDirectory;
    
    if (![URL getResourceValue:&isDirectory forKey:NSURLIsDirectoryKey error:nil]) {
        success = [[NSFileManager defaultManager] createDirectoryAtURL:URL
                                           withIntermediateDirectories:YES attributes:nil error:&error];
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
        [menuItem tag] == CEScriptMenuDirectoryTag)
    {
        return YES;
    }
    
    // specific selectors
    NSString *selectorString = NSStringFromSelector([menuItem action]);
    if ([[CEKeyBindingManager selectorStringsToIgnore] containsObject:selectorString]) {
        return YES;
    }
    
    return NO;
}


//------------------------------------------------------
/// メニューのキーボードショートカットをクリアする
- (void)clearMenuKeyBindingRecurrently:(NSMenu *)menu
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
- (void)applyMenuKeyBindingRecurrently:(NSMenu *)menu
//------------------------------------------------------
{
    BOOL isJapaneseResource = [[[[NSBundle mainBundle] preferredLocalizations] firstObject] isEqualToString:@"ja"];
    NSString *yen = [NSString stringWithCharacters:&kYenMark length:1];
    
    // NSMenu の indexOfItemWithTarget:andAction: だと取得できないメニューアイテムがあるため、メニューをひとつずつなめる
    for (NSMenuItem *item in [menu itemArray]) {
        if ([self shouldIgnoreItem:item]) { continue; }
        
        if ([item hasSubmenu]) {
            [self applyMenuKeyBindingRecurrently:[item submenu]];
            
        } else {
            NSUInteger modifierMask = 0;
            NSString *keySpecChars = [self keySpecCharsInDictionaryFromSelector:[item action]];
            NSString *keyEquivalent = [CEUtils keyEquivalentAndModifierMask:&modifierMask
                                                                 fromString:keySpecChars
                                                        includingCommandKey:YES];

            // keySpecChars があり Cmd が設定されている場合だけ、反映させる
            if (([keySpecChars length] > 0) && (modifierMask & NSCommandKeyMask)) {
                // 日本語リソースが使われたとき、Input BackSlash の keyEquivalent を変更する
                // （半角円マークのままだと半角カナ「エ」に化けるため）
                if (isJapaneseResource && [keyEquivalent isEqualToString:yen]) {
                    [item setKeyEquivalent:@"\\"];
                } else {
                    [item setKeyEquivalent:keyEquivalent];
                }
                [item setKeyEquivalentModifierMask:modifierMask];
            }
        }
    }
    
    // キーボードショートカット設定を反映させる
    [menu update];
}


//------------------------------------------------------
/// アウトラインビューデータから保存用辞書を生成
- (NSMutableDictionary<NSString *, id> *)keyBindingDictionaryFromOutlineViewDataArray:(NSArray<id> *)array
//------------------------------------------------------
{
    NSMutableDictionary<NSString *, id> *keyBindingDict = [NSMutableDictionary dictionary];

    for (id item in array) {
        NSArray<id> *children = item[CEKeyBindingChildrenKey];
        if (children) {
            NSDictionary<NSString *, id> *childDict = [self keyBindingDictionaryFromOutlineViewDataArray:children];
            [keyBindingDict addEntriesFromDictionary:childDict];
        }
        
        NSString *keySpecChars = item[CEKeyBindingKeySpecCharsKey];
        NSString *selectorStr = item[CEKeyBindingSelectorStringKey];
        if (([keySpecChars length] > 0) && ([selectorStr length] > 0)) {
            [keyBindingDict setValue:selectorStr forKey:keySpecChars];
        }
    }
    
    return keyBindingDict;
}


//------------------------------------------------------
/// セレクタ名を定義しているキーバインディング文字列（キー）を得る
- (NSString *)keySpecCharsInDictionaryFromSelector:(SEL)selector
//------------------------------------------------------
{
    NSString *selectorString = NSStringFromSelector(selector);
    NSArray<NSString *> *keys = [[self menuKeyBindingDict] allKeysForObject:selectorString];
    
    return [keys firstObject] ? : @"";
}


//------------------------------------------------------
/// メニューのキーボードショートカットから表示用文字列を返す
+ (NSString *)printableKeyStringsFromKeyEquivalent:(NSString *)string
//------------------------------------------------------
{
    if ([string length] < 1) { return @""; }
    
    unichar theChar = [string characterAtIndex:0];
    if ([[NSCharacterSet alphanumericCharacterSet] characterIsMember:theChar]) {
        return [string uppercaseString];
    } else {
        return [CEKeyBindingManager printableCharFromIgnoringModChar:string];
    }
}


//------------------------------------------------------
/// キーバインディング定義文字列から表示用モディファイアキー文字列を生成し、返す
+ (NSString *)printableKeyStringFromModKeySpecChars:(NSString *)modString withShiftKey:(BOOL)drawsShiftKey
//------------------------------------------------------
{
    NSCharacterSet *modStringSet = [NSCharacterSet characterSetWithCharactersInString:modString];
    NSMutableString *keyStrings = [NSMutableString string];
    
    for (NSUInteger i = 0; i < kSizeOfModifierKeys; i++) {
        unichar theChar = kKeySpecCharList[i];
        if ([modStringSet characterIsMember:theChar] || ((i == CEShiftKeyIndex) && drawsShiftKey)) {
            [keyStrings appendFormat:@"%C", kModifierKeySymbolCharList[i]];
        }
    }
    
    return keyStrings;
}


//------------------------------------------------------
/// キーバインディング定義文字列またはキーボードショートカットキーからキー表示用文字列を生成し、返す
+ (NSString *)printableCharFromIgnoringModChar:(NSString *)modCharString
//------------------------------------------------------
{
    return kUnprintableKeyTable[modCharString] ? : modCharString;
}


//------------------------------------------------------
/// そのまま表示できないキーバインディング定義文字列の変換辞書を返す
+ (NSDictionary<NSString *, NSString *> *)unprintableKeyDictionary
//------------------------------------------------------
{
    // 下記の情報を参考にさせていただきました (2005.09.05)
    // http://www.cocoabuilder.com/archive/message/2004/3/19/102023
    NSArray<NSString *> *printableChars = @[[NSString stringWithFormat:@"%C", (unichar)0x2191], // "↑" NSUpArrowFunctionKey,
                                            [NSString stringWithFormat:@"%C", (unichar)0x2193], // "↓" NSDownArrowFunctionKey,
                                            [NSString stringWithFormat:@"%C", (unichar)0x2190], // "←" NSLeftArrowFunctionKey,
                                            [NSString stringWithFormat:@"%C", (unichar)0x2192], // "→" NSRightArrowFunctionKey,
                                            @"F1", // NSF1FunctionKey,
                                            @"F2", // NSF2FunctionKey,
                                            @"F3", // NSF3FunctionKey,
                                            @"F4", // NSF4FunctionKey,
                                            @"F5", // NSF5FunctionKey,
                                            @"F6", // NSF6FunctionKey,
                                            @"F7", // NSF7FunctionKey,
                                            @"F8", // NSF8FunctionKey,
                                            @"F9", // NSF9FunctionKey,
                                            @"F10", // NSF10FunctionKey,
                                            @"F11", // NSF11FunctionKey,
                                            @"F12", // NSF12FunctionKey,
                                            @"F13", // NSF13FunctionKey,
                                            @"F14", // NSF14FunctionKey,
                                            @"F15", // NSF15FunctionKey,
                                            @"F16", // NSF16FunctionKey,
                                            [NSString stringWithFormat:@"%C", (unichar)0x2326], // NSDeleteCharacter = "Delete forward"
                                            [NSString stringWithFormat:@"%C", (unichar)0x2196], // "↖" NSHomeFunctionKey,
                                            [NSString stringWithFormat:@"%C", (unichar)0x2198], // "↘" NSEndFunctionKey,
                                            [NSString stringWithFormat:@"%C", (unichar)0x21DE], // "⇞" NSPageUpFunctionKey,
                                            [NSString stringWithFormat:@"%C", (unichar)0x21DF], // "⇟" NSPageDownFunctionKey,
                                            [NSString stringWithFormat:@"%C", (unichar)0x2327], // "⌧" NSClearLineFunctionKey,
                                            @"Help", // NSHelpFunctionKey,
                                            @"Space", // "Space",
                                            [NSString stringWithFormat:@"%C", (unichar)0x21E5], // "Tab"
                                            [NSString stringWithFormat:@"%C", (unichar)0x21A9], // "Return"
                                            [NSString stringWithFormat:@"%C", (unichar)0x232B], // "⌫" "Backspace"
                                            [NSString stringWithFormat:@"%C", (unichar)0x2305], // "Enter"
                                            [NSString stringWithFormat:@"%C", (unichar)0x21E4], // "Backtab"
                                            [NSString stringWithFormat:@"%C", (unichar)0x238B]];
    
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
+ (NSArray<NSString *> *)textKeyBindingSelectorStrings
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
+ (NSArray<NSString *> *)selectorStringsToIgnore
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
             @"orderFrontCharacterPalette:"  // = 10.4「特殊文字…」
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
