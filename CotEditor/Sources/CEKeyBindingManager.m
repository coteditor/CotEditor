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
#import "CEKeyBindingUtils.h"
#import "CEAppDelegate.h"
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
/// initialize instance
- (nonnull instancetype)init
// ------------------------------------------------------
{
    self = [super init];
    if (self) {
        NSAssert([NSApp mainMenu], @"%@ should be initialized after MainMenu.xib is loaded.", [self className]);
        
        // set default key bindings
        _defaultMenuKeyBindingDict = [self scanMenuKeyBindingRecurrently:[NSApp mainMenu]];
        _defaultTextKeyBindingDict = @{@"$\n": @"insertCustomText_00:"};
        
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
/// scan key bindings in main menu and store them as default values
- (void)scanDefaultMenuKeyBindings
//------------------------------------------------------
{
    // do nothing
    // -> Actually, `defaultMenuKeyBindings` is already scanned in `init`.
}


// ------------------------------------------------------
/// keyEquivalent and modifierMask for passed-in selector
- (nonnull NSString *)keyEquivalentForAction:(nonnull SEL)action modifierMask:(nonnull NSEventModifierFlags *)modifierMask
// ------------------------------------------------------
{
    NSString *keySpecChars = [self keySpecCharsForSelector:action factoryDefaults:NO];
    
    return [CEKeyBindingUtils keyEquivalentAndModifierMask:modifierMask fromKeySpecChars:keySpecChars requiresCommandKey:YES];
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
            [keySpecCharsList addObjectsFromArray:[self keySpecCharsListFromOutlineData:children]];
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
- (nullable NSString *)selectorStringWithKeyEquivalent:(nonnull NSString *)keyEquivalent modifierMask:(NSEventModifierFlags)modifierMask
// ------------------------------------------------------
{
    NSString *keySpecChars = [CEKeyBindingUtils keySpecCharsFromKeyEquivalent:keyEquivalent modifierMask:modifierMask];

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
/// scan all key bindings as well as selector name in passed-in menu
- (nonnull NSDictionary<NSString *, NSString *> *)scanMenuKeyBindingRecurrently:(nonnull NSMenu *)menu
//------------------------------------------------------
{
    NSMutableDictionary<NSString *, NSString *> *dictionary = [NSMutableDictionary dictionary];
    
    for (NSMenuItem *item in [menu itemArray]) {
        if ([self shouldIgnoreItem:item]) { continue; }
        
        if ([item hasSubmenu]) {
            [dictionary addEntriesFromDictionary:[self scanMenuKeyBindingRecurrently:[item submenu]]];
            
        } else {
            NSString *selector = NSStringFromSelector([item action]);
            NSString *key = [CEKeyBindingUtils keySpecCharsFromKeyEquivalent:[item keyEquivalent]
                                                                modifierMask:[item keyEquivalentModifierMask]];
            
            if ([selector length] > 0 && [key length] > 0) {
                dictionary[key] = selector;
            }
        }
    }
    
    return dictionary;
}


//------------------------------------------------------
/// メニューのキーボードショートカットをクリアする
- (void)clearMenuKeyBindingRecurrently:(nonnull NSMenu *)menu
//------------------------------------------------------
{
    for (NSMenuItem *item in [menu itemArray]) {
        if ([self shouldIgnoreItem:item]) { continue; }
        
        if ([item hasSubmenu]) {
            [self clearMenuKeyBindingRecurrently:[item submenu]];
            
        } else {
            [item setKeyEquivalent:@""];
            [item setKeyEquivalentModifierMask:0];
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
            NSString *keyEquivalent = [self keyEquivalentForAction:[item action] modifierMask:&modifierMask];

            // keyEquivalent があり Cmd が設定されている場合だけ、反映させる
            if (([keyEquivalent length] > 0) && (modifierMask & NSCommandKeyMask)) {
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
                                                           [CEKeyBindingUtils keySpecCharsFromKeyEquivalent:[item keyEquivalent]
                                                                                               modifierMask:[item keyEquivalentModifierMask]];
            
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
    return @[@"changeEncoding:",
             @"changeSyntaxStyle:",
             @"changeTheme:",
             @"changeTabWidth:",
             @"biggerFont:",
             @"smallerFont:",
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
