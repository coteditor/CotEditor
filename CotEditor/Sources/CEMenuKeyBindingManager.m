/*
 
 CEMenuKeyBindingManager.m
 
 CotEditor
 http://coteditor.com
 
 Created by 1024jp on 2016-06-22.
 
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

#import "CEMenuKeyBindingManager.h"
#import "CEKeyBindingUtils.h"
#import "Constants.h"


@interface CEMenuKeyBindingManager ()

@property (readwrite, nonatomic, nonnull, copy) NSDictionary<NSString *, NSString *> *defaultKeyBindingDict;

@end




#pragma mark -

@implementation CEMenuKeyBindingManager

#pragma mark Singleton

// ------------------------------------------------------
/// return singleton instance
+ (nonnull CEMenuKeyBindingManager *)sharedManager
// ------------------------------------------------------
{
    static dispatch_once_t onceToken;
    static id shared = nil;
    
    dispatch_once(&onceToken, ^{
        shared = [[self alloc] init];
    });
    
    return shared;
}



#pragma mark Key Binding Manager Methods

// ------------------------------------------------------
/// initialize instance
- (nonnull instancetype)init
// ------------------------------------------------------
{
    self = [super init];
    if (self) {
        NSAssert([NSApp mainMenu], @"%@ should be initialized after MainMenu.xib is loaded.", [self className]);
        
        // set default key bindings
        _defaultKeyBindingDict = [self scanMenuKeyBindingRecurrently:[NSApp mainMenu]];
        
        // read user key bindings if available
        self.keyBindingDict = [NSDictionary dictionaryWithContentsOfURL:[self keyBindingSettingFileURL]] ? : _defaultKeyBindingDict;
    }
    return self;
}


//------------------------------------------------------
/// name of file to save custom key bindings in the plist file form (without extension)
- (nonnull NSString *)settingFileName
//------------------------------------------------------
{
    return @"MenuKeyBindings";
}


//------------------------------------------------------
/// create a KVO-compatible dictionary for outlineView in preferences from the key binding setting
/// @param usesFactoryDefaults   YES for default setting and NO for the current setting
- (nonnull NSMutableArray<NSMutableDictionary<NSString *, id> *> *)keySpecCharsListForOutlineDataWithFactoryDefaults:(BOOL)usesFactoryDefaults
//------------------------------------------------------
{
    return [self keySpecCharsListForMenu:[NSApp mainMenu] factoryDefaults:usesFactoryDefaults];
}


//------------------------------------------------------
/// save passed-in key binding settings
- (BOOL)saveKeyBindings:(nonnull NSArray<NSDictionary<NSString *, id> *> *)outlineData
//------------------------------------------------------
{
    BOOL success = [super saveKeyBindings:outlineData];
    
    // apply new settings to the menu
    [self applyKeyBindingsToMainMenu];
    
    return success;
}


//------------------------------------------------------
/// validate new key spec chars are settable
- (BOOL)validateKeySpecChars:(nonnull NSString *)keySpec oldKeySpecChars:(nonnull NSString *)oldKeySpecChars error:(NSError * _Nullable __autoreleasing * _Nullable)outError
//------------------------------------------------------
{
    BOOL valid = [super validateKeySpecChars:keySpec oldKeySpecChars:oldKeySpecChars error:outError];
    
    // command key existance check
    if (valid && ![keySpec containsString:@"@"]) {
        if (outError) {
            *outError = [self errorWithMessageFormat:@"“%@” does not include the Command key." keySpecChars:keySpec];
        }
        return NO;
    }
    
    return valid;
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
/// re-apply keyboard short cut to all menu items
- (void)applyKeyBindingsToMainMenu
//------------------------------------------------------
{
    // at first, clear all current short cut sttings at first
    [self clearMenuKeyBindingRecurrently:[NSApp mainMenu]];
    
    // then apply the latest settings
    [self applyMenuKeyBindingRecurrently:[NSApp mainMenu]];
}



#pragma mark Private Methods

//------------------------------------------------------
/// selectors for menu items not to change its short cut
+ (nonnull NSArray<NSString *> *)selectorStringsToIgnore
//------------------------------------------------------
{
    return @[@"changeEncoding:",
             @"changeSyntaxStyle:",
             @"changeTheme:",
             @"changeTabWidth:",
             @"biggerFont:",
             @"smallerFont:",
             @"launchScript:",
             NSStringFromSelector(@selector(makeKeyAndOrderFront:)),
             NSStringFromSelector(@selector(orderFrontCharacterPalette:)),  // = "Emoji & Symbols"
             ];
}


//------------------------------------------------------
/// return key bindings for selector
- (nonnull NSString *)keySpecCharsForSelector:(SEL)selector factoryDefaults:(BOOL)usesFactoryDefaults
//------------------------------------------------------
{
    NSString *selectorString = NSStringFromSelector(selector);
    NSDictionary *dict = usesFactoryDefaults ? [self defaultKeyBindingDict] : [self keyBindingDict];
    NSArray<NSString *> *keys = [dict allKeysForObject:selectorString];
    
    return [keys firstObject] ? : @"";
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
/// clear keyboard short cuts in the passed-in menu
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
/// apply current keyboard short cut settings to the passed-in menu
- (void)applyMenuKeyBindingRecurrently:(nonnull NSMenu *)menu
//------------------------------------------------------
{
    // process item to item because there are menu items that cannnot obtain with NSMenu's `indexOfItemWithTarget:andAction:`
    for (NSMenuItem *item in [menu itemArray]) {
        if ([self shouldIgnoreItem:item]) { continue; }
        
        if ([item hasSubmenu]) {
            [self applyMenuKeyBindingRecurrently:[item submenu]];
            
        } else {
            NSUInteger modifierMask = 0;
            NSString *keyEquivalent = [self keyEquivalentForAction:[item action] modifierMask:&modifierMask];
            
            // apply only if keyEquivalent exists and the Command key is included
            if (([keyEquivalent length] > 0) && (modifierMask & NSCommandKeyMask)) {
                [item setKeyEquivalent:keyEquivalent];
                [item setKeyEquivalentModifierMask:modifierMask];
            }
        }
    }
    
    // apply
    [menu update];
}


//------------------------------------------------------
/// read key bindings from the menu and create an array data for outlineView to edit
- (nonnull NSMutableArray<NSMutableDictionary<NSString *, id> *> *)keySpecCharsListForMenu:(nonnull NSMenu *)menu factoryDefaults:(BOOL)usesFactoryDefaults
//------------------------------------------------------
{
    NSMutableArray<NSMutableDictionary<NSString *, id> *> *outlineData = [NSMutableArray array];
    
    for (NSMenuItem *item in [menu itemArray]) {
        if ([self shouldIgnoreItem:item]) { continue; }
        
        NSDictionary<NSString *, id> *row;
        if ([item hasSubmenu]) {
            NSMutableArray<NSMutableDictionary<NSString *, id> *> *subArray = [self keySpecCharsListForMenu:[item submenu] factoryDefaults:usesFactoryDefaults];
            
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

@end




#pragma mark -

@implementation CEMenuKeyBindingManager (Migration)

//------------------------------------------------------
/// ユーザのメニューキーバインディング設定をいったん削除する
- (BOOL)resetKeyBindings
//------------------------------------------------------
{
    // 以前の CotEditor ではユーザがカスタムをしているしていないに関わらずメニューキーバインディングの設定が
    // ユーザ領域に作成されていたため最初にインストールしたバージョン以降でデフォルトのショートカットやメソッド名が
    // 変更された場合にそれに追従できなかった。
    // その負のサイクルを断ち切るために、過去の設定ファイルを一旦削除をする。
    
    BOOL success = NO;
    NSURL *URL = [self keyBindingSettingFileURL];
    
    if ([URL checkResourceIsReachableAndReturnError:nil]) {
        success = [[NSFileManager defaultManager] removeItemAtURL:URL error:nil];
        
        [self setKeyBindingDict:[self defaultKeyBindingDict]];
        [self applyKeyBindingsToMainMenu];
    }
    
    return success;
}

@end
