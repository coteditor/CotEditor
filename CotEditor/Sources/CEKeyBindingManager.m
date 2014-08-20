/*
 ==============================================================================
 CEKeyBindingManager
 
 CotEditor
 http://coteditor.github.io
 
 Created on 2005-09-01 by nakamuxu
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

#import "CEKeyBindingManager.h"
#import "CEUtils.h"
#import "constants.h"


@interface CEKeyBindingManager ()

@property (nonatomic, copy) NSDictionary *defaultMenuKeyBindingDict;
@property (nonatomic, copy) NSDictionary *menuKeyBindingDict;
@property (nonatomic, copy) NSDictionary *textKeyBindingDict;
@property (nonatomic, copy) NSDictionary *unprintableKeyDict;

@end




#pragma mark -

@implementation CEKeyBindingManager

#pragma mark Class Methods

//=======================================================
// Class method
//
//=======================================================

// ------------------------------------------------------
/// return singleton instance
+ (instancetype)sharedManager
// ------------------------------------------------------
{
    static dispatch_once_t predicate;
    static id shared = nil;
    
    dispatch_once(&predicate, ^{
        shared = [[self alloc] init];
    });
    
    return shared;
}



#pragma mark Superclass Methods

//=======================================================
// Superclass method
//
//=======================================================

// ------------------------------------------------------
/// 初期化
- (instancetype)init
// ------------------------------------------------------
{
    self = [super init];
    if (self) {
        _unprintableKeyDict = [self unprintableKeyDictionary];
    }
    return self;
}



#pragma mark Public Methods

//=======================================================
// Public method
//
//=======================================================

// ------------------------------------------------------
/// 起動時の準備
- (void)setupAtLaunching
// ------------------------------------------------------
{
    NSURL *URL = [[NSBundle mainBundle] URLForResource:@"DefaultMenuKeyBindings" withExtension:@"plist"];

    if ([URL checkResourceIsReachableAndReturnError:nil]) {
        [self setDefaultMenuKeyBindingDict:[NSDictionary dictionaryWithContentsOfURL:URL]];
    }
    /// 定義ファイルのセットアップと読み込み
    [self setupMenuKeyBindingDictionary];
    [self setupTextKeyBindingDictionary];
    
    [self resetAllMenuKeyBindingWithDictionary];
}


// ------------------------------------------------------
/// キー入力に応じたセレクタ文字列を返す
- (NSString *)selectorStringWithKeyEquivalent:(NSString *)string modifierFrags:(NSUInteger)modifierFlags
// ------------------------------------------------------
{
    NSString *keySpecChars = [self keySpecCharsFromKeyEquivalent:string modifierFrags:modifierFlags];

    return [self textKeyBindingDict][keySpecChars];
}


// ------------------------------------------------------
/// メニューキーバインディングがカスタマイズされているか
- (BOOL)usesDefaultMenuKeyBindings
// ------------------------------------------------------
{
    return ![[self menuKeyBindingSettingFileURL] checkResourceIsReachableAndReturnError:nil];
}


//------------------------------------------------------
/// テキストキーバインディングの現在の保持データから設定を読み込み編集用アウトラインビューデータ配列を返す
- (NSMutableArray *)textKeySpecCharArrayForOutlineDataWithFactoryDefaults:(BOOL)usesFactoryDefaults
//------------------------------------------------------
{
    // usesFactoryDefaults == YES で標準設定を返す。NO なら現在の設定を返す。
    
    NSMutableArray *textKeySpecCharArray = [NSMutableArray array];
    
    for (NSString *selector in [self textKeyBindingSelectorStrArray]) {
        if (([selector length] == 0) || ![selector isKindOfClass:[NSString class]]) { continue; }
        
        NSArray *keys;
        if (usesFactoryDefaults) {
            NSURL *sourceURL = [[NSBundle mainBundle] URLForResource:@"DefaultTextKeyBindings" withExtension:@"plist"];
            NSDictionary *defaultDict = [NSDictionary dictionaryWithContentsOfURL:sourceURL];
            keys = [defaultDict allKeysForObject:selector];
        } else {
            keys = [[self textKeyBindingDict] allKeysForObject:selector];
        }
        NSString *key = ([keys count] > 0) ? keys[0] : @"";
        
        [textKeySpecCharArray addObject:[@{k_title: selector, //*****
                                           k_keyBindingKey: key,
                                           k_selectorString: selector} mutableCopy]];
    }
    return textKeySpecCharArray;
}


//------------------------------------------------------
/// 現在のメニューからショートカットキー設定を読み込み編集用アウトラインビューデータ配列を返す
- (NSMutableArray *)mainMenuArrayForOutlineData:(NSMenu *)menu
//------------------------------------------------------
{
    NSMutableArray *outArray = [NSMutableArray array];
    
    for (NSMenuItem *item in [menu itemArray]) {
        if ([item isSeparatorItem] || ([[item title] length] == 0)) { continue; }
        
        NSMutableDictionary *theDict;
        if (([item hasSubmenu]) &&
            ([item tag] != CEServicesMenuItemTag) &&
            ([item tag] != CEWindowPanelsMenuItemTag) &&
            ([item tag] != CEScriptMenuDirectoryTag))
        {
            NSMutableArray *subArray = [self mainMenuArrayForOutlineData:[item submenu]];
            theDict = [@{k_title: [item title],
                         k_children: subArray} mutableCopy];
            
        } else {
            NSString *selectorString = NSStringFromSelector([item action]);
            // フォントサイズ変更、エンコーディングの各項目、カラーリングの各項目、などはリストアップしない
            if ([[self selectorStringsToIgnore] containsObject:selectorString] ||
                ([item tag] == CEServicesMenuItemTag) ||
                ([item tag] == CEWindowPanelsMenuItemTag) ||
                ([item tag] == CEScriptMenuDirectoryTag))
            {
                continue;
            }
            
            NSString *keyEquivalent = [item keyEquivalent];
            NSString *keySpecChars;
            if ([keyEquivalent length] > 0) {
                NSUInteger modifierMask = [item keyEquivalentModifierMask];
                keySpecChars = [self keySpecCharsFromKeyEquivalent:keyEquivalent modifierFrags:modifierMask];
            } else {
                keySpecChars = @"";
            }
            theDict = [@{k_title: [item title],
                         k_keyBindingKey: keySpecChars,
                         k_selectorString: selectorString} mutableCopy];
        }
        [outArray addObject:theDict];
    }
    return outArray;
}


//------------------------------------------------------
/// キーバインディング定義文字列から表示用文字列を生成し、返す
- (NSString *)readableKeyStringsFromKeySpecChars:(NSString *)string
//------------------------------------------------------
{
    NSInteger length = [string length];
    
    if (length < 2) { return @""; }
    
    NSString *keyEquivalent = [string substringFromIndex:(length - 1)];
    NSString *keyStr = [self readableKeyStringsFromKeyEquivalent:keyEquivalent];
    BOOL drawsShift = (isupper([keyEquivalent characterAtIndex:0]) == 1);
    NSString *modKeyStr = [self readableKeyStringsFromModKeySpecChars:[string substringToIndex:(length - 1)]
                                                         withShiftKey:drawsShift];
    
    return [NSString stringWithFormat:@"%@%@", modKeyStr, keyStr];
}


//------------------------------------------------------
/// メニューのキーボードショートカットからキーバインディング定義文字列を返す
- (NSString *)keySpecCharsFromKeyEquivalent:(NSString *)string modifierFrags:(NSUInteger)modifierFlags
//------------------------------------------------------
{
    if ([string length] < 1) { return @""; }
    
    NSMutableString *keySpecChars = [NSMutableString string];
    unichar theChar = [string characterAtIndex:0];
    BOOL isShiftPressed = NO;
    
    NSAssert(k_size_of_modifierKeysList == k_size_of_keySpecCharList,
             @"internal data error! 'k_modifierKeysList' and 'k_keySpecCharList' size is different.");
    
    for (NSInteger i = 0; i < k_size_of_modifierKeysList; i++) {
        if ((modifierFlags & k_modifierKeysList[i]) || ((i == 2) && (isupper(theChar) == 1))) {
            // （メニューから定義値を取得した時、アルファベット+シフトの場合にシフトの定義が欠落するための回避処置）
            [keySpecChars appendFormat:@"%C", k_keySpecCharList[i]];
            if ((i == 2) && (isupper(theChar) == 1)) {
                isShiftPressed = YES;
            }
        }
    }
    [keySpecChars appendString:((isShiftPressed) ? [string uppercaseString] : string)];
    
    return keySpecChars;
}


//------------------------------------------------------
/// デフォルト設定の、セレクタ名を定義しているキーバインディング文字列（キー）を得る
- (NSString *)keySpecCharsInDefaultDictionaryFromSelectorString:(NSString *)selectorString
//------------------------------------------------------
{
    NSArray *keys = [[self defaultMenuKeyBindingDict] allKeysForObject:selectorString];
    
    if ([keys count] > 0) {
        return (NSString *)keys[0];
    }
    return @"";
}


//------------------------------------------------------
/// メニューキーバインディング設定を保存
- (BOOL)saveMenuKeyBindings:(NSArray *)outlineViewData
//------------------------------------------------------
{
    NSDictionary *dictToSave = [self keyBindingDictionaryFromOutlineViewDataArray:outlineViewData];
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
    [self resetAllMenuKeyBindingWithDictionary];
    
    return success;
}


//------------------------------------------------------
/// テキストキーバインディング設定を保存
- (BOOL)saveTextKeyBindings:(NSArray *)outlineViewData texts:(NSArray *)texts
//------------------------------------------------------
{
    NSDictionary *dictToSave = [self keyBindingDictionaryFromOutlineViewDataArray:outlineViewData];
    NSURL *fileURL = [self textKeyBindingSettingFileURL];
    
    if ([self prepareUserSettingDicrectory]) {
        [self setTextKeyBindingDict:dictToSave];
        
        if (![dictToSave writeToURL:fileURL atomically:YES]) {
            NSLog(@"Error! Could not save the Text keyBindings setting file...");
            return NO;
        }
    }
    
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    if (![texts isEqualToArray:[defaults arrayForKey:k_key_insertCustomTextArray]]) {
        NSMutableArray *defaultsArray = [NSMutableArray array];
        
        for (NSDictionary *dict in texts) {
             NSString *insertText = dict[k_key_insertCustomText] ? : @"";
            [defaultsArray addObject:insertText];
        }
        [defaults setObject:defaultsArray forKey:k_key_insertCustomTextArray];
    }
    
    return YES;
}



#pragma mark Private Mthods

//=======================================================
// Private method
//
//=======================================================

//------------------------------------------------------
/// キーバインディング設定ファイル保存用ディレクトリのURLを返す
- (NSURL *)userSettingDirecotryURL
//------------------------------------------------------
{
    return [[[NSFileManager defaultManager] URLForDirectory:NSApplicationSupportDirectory
                                                   inDomain:NSUserDomainMask
                                          appropriateForURL:nil
                                                     create:NO
                                                      error:nil]
            URLByAppendingPathComponent:@"CotEditor/KeyBindings"];
    
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


// ------------------------------------------------------
/// メニューキーバインディング定義ファイルのセットアップと読み込み
- (void)setupMenuKeyBindingDictionary
// ------------------------------------------------------
{
    NSDictionary *dict = [NSDictionary dictionaryWithContentsOfURL:[self menuKeyBindingSettingFileURL]] ?
                       : [self defaultMenuKeyBindingDict];
    
    [self setMenuKeyBindingDict:dict];
}


// ------------------------------------------------------
/// テキストキーバインディング定義ファイルのセットアップと読み込み
- (void)setupTextKeyBindingDictionary
// ------------------------------------------------------
{
    NSURL *fileURL = [self textKeyBindingSettingFileURL];
    
    if ([self prepareUserSettingDicrectory]) {
        NSURL *sourceURL = [[NSBundle mainBundle] URLForResource:@"DefaultTextKeyBindings" withExtension:@"plist"];
        
        if ([sourceURL checkResourceIsReachableAndReturnError:nil] &&
            ![fileURL checkResourceIsReachableAndReturnError:nil]) {
            if (![[NSFileManager defaultManager] copyItemAtURL:sourceURL toURL:fileURL error:nil]) {
                NSLog(@"Error! Could not copy \"%@\" to \"%@\"...", sourceURL, fileURL);
                return;
            }
        }
        
        // データ読み込み
        [self setTextKeyBindingDict:[NSDictionary dictionaryWithContentsOfURL:fileURL]];
    }
}


//------------------------------------------------------
/// すべてのメニューのキーボードショートカットをクリアする
- (void)clearAllMenuKeyBindingOf:(NSMenu *)menu
//------------------------------------------------------
{
    for (NSMenuItem *item in [menu itemArray]) {
        // フォントサイズ変更、エンコーディングの各項目、カラーリングの各項目、などは変更しない
        if ([[self selectorStringsToIgnore] containsObject:NSStringFromSelector([item action])] ||
            ([item tag] == CEServicesMenuItemTag) ||
            ([item tag] == CEWindowPanelsMenuItemTag) ||
            ([item tag] == CEScriptMenuDirectoryTag))
        {
            continue;
        }
        [item setKeyEquivalent:@""];
        [item setKeyEquivalentModifierMask:0];
        if ([item hasSubmenu]) {
            [self clearAllMenuKeyBindingOf:[item submenu]];
        }
    }
}


//------------------------------------------------------
/// キーボードショートカット設定を反映させる
- (void)updateMenuValidation:(NSMenu *)menu
//------------------------------------------------------
{
    [menu update];
    
    for (NSMenuItem *item in [menu itemArray]) {
        if ([item hasSubmenu]) {
            [self updateMenuValidation:[item submenu]];
        }
    }
}


//------------------------------------------------------
/// すべてのメニューにキーボードショートカットを設定し直す
- (void)resetAllMenuKeyBindingWithDictionary
//------------------------------------------------------
{
    if (![self menuKeyBindingDict]) { return; }

    // まず、全メニューのショートカット定義をクリアする
    [self clearAllMenuKeyBindingOf:[NSApp mainMenu]];

    [self resetKeyBindingWithDictionaryTo:[NSApp mainMenu]];
    // メニュー更新（キーボードショートカット設定反映）
    [self updateMenuValidation:[NSApp mainMenu]];
}


//------------------------------------------------------
/// メニューにキーボードショートカットを設定する
- (void)resetKeyBindingWithDictionaryTo:(NSMenu *)menu
//------------------------------------------------------
{
// NSMenu の indexOfItemWithTarget:andAction: だと取得できないメニューアイテムがあるため、メニューをひとつずつなめる

    for (NSMenuItem *item in [menu itemArray]) {
        if (([item hasSubmenu]) &&
            ([item tag] != CEServicesMenuItemTag) &&
            ([item tag] != CEWindowPanelsMenuItemTag) &&
            ([item tag] != CEScriptMenuDirectoryTag))
        {
            [self resetKeyBindingWithDictionaryTo:[item submenu]];
        } else {
            NSString *selectorString = NSStringFromSelector([item action]);
            // フォントサイズ変更、エンコーディングの各項目、カラーリングの各項目、などは変更しない
            if ([[self selectorStringsToIgnore] containsObject:NSStringFromSelector([item action])] ||
                ([item tag] == CEServicesMenuItemTag) ||
                ([item tag] == CEWindowPanelsMenuItemTag) ||
                ([item tag] == CEScriptMenuDirectoryTag)) {
                continue;
            }
            NSString *keySpecChars = [self keySpecCharsInDictionaryFromSelectorString:selectorString];
            NSUInteger modifierMask = 0;
            NSString *keyEquivalent = [CEUtils keyEquivalentAndModifierMask:&modifierMask
                                                                 fromString:keySpecChars
                                                        includingCommandKey:YES];

            // keySpecChars があり Cmd が設定されている場合だけ、反映させる
            if (([keySpecChars length] > 0) && (modifierMask & NSCommandKeyMask)) {
                // 日本語リソースが使われたとき、Input BackSlash の keyEquivalent を変更する
                // （半角円マークのままだと半角カナ「エ」に化けるため）
                if ([keyEquivalent isEqualToString:[NSString stringWithCharacters:&k_yenMark length:1]] &&
                    [[[NSBundle mainBundle] preferredLocalizations][0] isEqualToString:@"ja"])
                {
                    [item setKeyEquivalent:@"\\"];
                } else {
                    [item setKeyEquivalent:keyEquivalent];
                }
                [item setKeyEquivalentModifierMask:modifierMask];
            }
        }
    }
}


//------------------------------------------------------
/// メニューのキーボードショートカットから表示用文字列を返す
- (NSString *)readableKeyStringsFromKeyEquivalent:(NSString *)string
//------------------------------------------------------
{
    if ([string length] < 1) { return @""; }

    unichar theChar = [string characterAtIndex:0];
    if ([[NSCharacterSet alphanumericCharacterSet] characterIsMember:theChar]) {
        return [string uppercaseString];
    } else {
        return [self visibleCharFromIgnoringModChar:string];
    }
}


//------------------------------------------------------
/// キーバインディング定義文字列から表示用モディファイアキー文字列を生成し、返す
- (NSString *)readableKeyStringsFromModKeySpecChars:(NSString *)modString withShiftKey:(BOOL)isShiftPressed
//------------------------------------------------------
{
    NSAssert(k_size_of_keySpecCharList == k_size_of_readableKeyStringsList,
             @"internal data error! 'k_keySpecCharList' and 'k_readableKeyStringsList' size is different.");
    
    NSCharacterSet *modStringSet = [NSCharacterSet characterSetWithCharactersInString:modString];
    NSMutableString *keyStrings = [NSMutableString string];

    for (NSUInteger i = 0; i < k_size_of_keySpecCharList; i++) {
        unichar theChar = k_keySpecCharList[i];
        if ([modStringSet characterIsMember:theChar]) {
            [keyStrings appendFormat:@"%C", k_readableKeyStringsList[i]];
        }
    }
    return keyStrings;
}


//------------------------------------------------------
/// キーバインディング定義文字列またはキーボードショートカットキーからキー表示用文字列を生成し、返す
- (NSString *)visibleCharFromIgnoringModChar:(NSString *)igunoresModChar
//------------------------------------------------------
{
    return [self unprintableKeyDict][igunoresModChar] ? : igunoresModChar;
}


//------------------------------------------------------
/// アウトラインビューデータから保存用辞書を生成
- (NSMutableDictionary *)keyBindingDictionaryFromOutlineViewDataArray:(NSArray *)array
//------------------------------------------------------
{
    NSMutableDictionary *keyBindingDict = [NSMutableDictionary dictionary];

    for (id item in array) {
        NSArray *children = item[k_children];
        if (children) {
            NSDictionary *childDict = [self keyBindingDictionaryFromOutlineViewDataArray:children];
            [keyBindingDict addEntriesFromDictionary:childDict];
        }
        NSString *keySpecChars = [item valueForKey:k_keyBindingKey];
        NSString *selectorStr = [item valueForKey:k_selectorString];
        if (([keySpecChars length] > 0) && ([selectorStr length] > 0)) {
            [keyBindingDict setValue:selectorStr forKey:keySpecChars];
        }
    }
    return keyBindingDict;
}


//------------------------------------------------------
/// セレクタ名を定義しているキーバインディング文字列（キー）を得る
- (NSString *)keySpecCharsInDictionaryFromSelectorString:(NSString *)selectorString
//------------------------------------------------------
{
    NSArray *keys = [[self menuKeyBindingDict] allKeysForObject:selectorString];
    
    if ([keys count] > 0) {
        return (NSString *)keys[0];
    }
    return @"";
}


//------------------------------------------------------
/// そのまま表示できないキーバインディング定義文字列の変換辞書を返す
- (NSDictionary *)unprintableKeyDictionary
//------------------------------------------------------
{
// 下記の情報を参考にさせていただきました (2005.09.05)
// http://www.cocoabuilder.com/archive/message/2004/3/19/102023
    NSArray *visibleChars = @[[NSString stringWithFormat:@"%C", (unichar)0x2191], // "↑" NSUpArrowFunctionKey,
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

    NSAssert(k_size_of_unprintableKeyList == [visibleChars count],
             @"Internal data error! Sizes of 'k_unprintableKeyList' and 'visibleChars' are different.");
    
    NSMutableArray *keys = [[NSMutableArray alloc] initWithCapacity:k_size_of_unprintableKeyList];
    for (NSInteger i = 0; i < k_size_of_unprintableKeyList; i++) {
        [keys addObject:[NSString stringWithFormat:@"%C", k_unprintableKeyList[i]]];
    }

    return [NSDictionary dictionaryWithObjects:visibleChars forKeys:keys];
}


//------------------------------------------------------
/// 独自定義のセレクタ名配列を返す
- (NSArray *)textKeyBindingSelectorStrArray
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
- (NSArray *)selectorStringsToIgnore
//------------------------------------------------------
{
    return @[@"modifyFont:",
             @"changeEncoding:",
             @"changeSyntaxStyle:",
             @"changeTheme:",
             @"makeKeyAndOrderFront:",
             @"launchScript:",
             @"_openRecentDocument:",  // = 10.3 の「最近開いた書類」
             @"orderFrontCharacterPalette:"  // = 10.4「特殊文字…」
             ];
}

@end
