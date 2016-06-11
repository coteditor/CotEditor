/*
 
 CEThemeManager.m
 
 CotEditor
 http://coteditor.com
 
 Created by 1024jp on 2014-04-12.

 ------------------------------------------------------------------------------
 
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

#import "CEThemeManager.h"
#import "CETheme.h"
#import "CEThemeDictionaryKeys.h"

#import "NSColor+WFColorCode.h"

#import "CEErrors.h"
#import "CEDefaults.h"
#import "Constants.h"


// extension for theme file
NSString *_Nonnull const CEThemeExtension = @"cottheme";

// notifications
NSString *_Nonnull const CEThemeListDidUpdateNotification = @"CEThemeListDidUpdateNotification";
NSString *_Nonnull const CEThemeDidUpdateNotification = @"CEThemeDidUpdateNotification";



@interface CEThemeManager ()

@property (nonatomic, nonnull, copy) NSDictionary<NSString *, NSDictionary *> *archivedThemes;
@property (nonatomic, nonnull, copy) NSArray<NSString *> *bundledThemeNames;

// readonly
@property (readwrite, nonatomic, nonnull, copy) NSArray<NSString *> *themeNames;

@end



#pragma mark -

@implementation CEThemeManager

#pragma mark Singleton

// ------------------------------------------------------
/// return singleton instance
+ (nonnull CEThemeManager *)sharedManager
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
/// initialize
- (nonnull instancetype)init
// ------------------------------------------------------
{
    self = [super init];
    if (self) {
        // バンドルされているテーマの名前を読み込んでおく
        NSArray<NSURL *> *URLs = [[NSBundle mainBundle] URLsForResourcesWithExtension:[self filePathExtension] subdirectory:[self directoryName]];
        NSMutableArray<NSString *> *themeNames = [NSMutableArray array];
        for (NSURL *URL in URLs) {
            if ([[URL lastPathComponent] hasPrefix:@"_"]) { continue; }
            
            [themeNames addObject:[self settingNameFromURL:URL]];
        }
        [self setBundledThemeNames:themeNames];
        
        // cache user themes asynchronously but wait until the process will be done
        dispatch_semaphore_t semaphore = dispatch_semaphore_create(0);
        [self updateCacheWithCompletionHandler:^{
            dispatch_semaphore_signal(semaphore);
        }];
        while (dispatch_semaphore_wait(semaphore, DISPATCH_TIME_NOW)) {  // avoid dead lock
            [[NSRunLoop currentRunLoop] runMode:NSDefaultRunLoopMode beforeDate:[NSDate distantFuture]];
        }
    }
    return self;
}


//------------------------------------------------------
/// directory name in both Application Support and bundled Resources
- (nonnull NSString *)directoryName
//------------------------------------------------------
{
    return @"Themes";
}


//------------------------------------------------------
/// path extension for user setting file
- (nonnull NSString *)filePathExtension
//------------------------------------------------------
{
    return CEThemeExtension;
}


//------------------------------------------------------
/// list of names of setting file name (without extension)
- (nonnull NSArray<NSString *> *)settingNames
//------------------------------------------------------
{
    return [self themeNames];
}


//------------------------------------------------------
/// list of names of setting file name which are bundled (without extension)
- (nonnull NSArray<NSString *> *)bundledSettingNames
//------------------------------------------------------
{
    return [self bundledThemeNames];
}



#pragma mark Public Methods

//------------------------------------------------------
/// テーマ名から CETheme インスタンスを返す
- (nullable CETheme *)themeWithName:(nonnull NSString *)themeName
//------------------------------------------------------
{
    NSDictionary<NSString *, NSDictionary *> *themeDict = [self archivedThemeWithName:themeName isBundled:NULL];
    if (!themeDict) { return nil; }
    
    return [CETheme themeWithDictinonary:themeDict name:themeName];
}


//------------------------------------------------------
/// テーマ名から Property list 形式のテーマ定義を返す
- (nullable NSMutableDictionary<NSString *, NSMutableDictionary<NSString *, id> *> *)archivedThemeWithName:(nonnull NSString *)themeName isBundled:(nullable BOOL *)isBundled
//------------------------------------------------------
{
    if (isBundled) {
        *isBundled = [[self bundledThemeNames] containsObject:themeName];
    }
    return [[self archivedThemes][themeName] mutableCopy];
}


//------------------------------------------------------
/// テーマを保存する
- (BOOL)saveTheme:(nonnull NSDictionary<NSString *, NSDictionary<NSString *, id> *> *)theme name:(nonnull NSString *)themeName completionHandler:(nullable void (^)(NSError *_Nullable))completionHandler
//------------------------------------------------------
{
    NSError *error = nil;
    
    NSData *jsonData = [NSJSONSerialization dataWithJSONObject:theme
                                                       options:NSJSONWritingPrettyPrinted
                                                         error:&error];
    
    if (![self prepareUserSettingDirectory]) { return NO; }
    
    BOOL success = [jsonData writeToURL:[self URLForUserSettingWithName:themeName available:NO] options:NSDataWritingAtomic error:&error];
    
    if (success) {
        __weak typeof(self) weakSelf = self;
        [self updateCacheWithCompletionHandler:^{
            typeof(self) self = weakSelf;  // strong self
            
            [[NSNotificationCenter defaultCenter] postNotificationName:CEThemeDidUpdateNotification
                                                                object:self
                                                              userInfo:@{CEOldNameKey: themeName,
                                                                         CENewNameKey: themeName}];
            if (completionHandler) {
                completionHandler(error);
            }
        }];
    } else {
        if (completionHandler) {
            completionHandler(error);
        }
    }
    
    return success;
}


//------------------------------------------------------
/// テーマ名を変更する
- (BOOL)renameThemeWithName:(nonnull NSString *)themeName toName:(nonnull NSString *)newThemeName error:(NSError * _Nullable __autoreleasing * _Nullable)outError
//------------------------------------------------------
{
    BOOL success = NO;
    
    newThemeName = [newThemeName stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
    
    if (![self validateSettingName:newThemeName originalName:themeName error:outError]) {
        return NO;
    }
    
    success = [[NSFileManager defaultManager] moveItemAtURL:[self URLForUserSettingWithName:themeName available:NO]
                                                      toURL:[self URLForUserSettingWithName:newThemeName available:NO] error:nil];
    
    if (success) {
        if ([[[NSUserDefaults standardUserDefaults] stringForKey:CEDefaultThemeKey] isEqualToString:themeName]) {
            [[NSUserDefaults standardUserDefaults] setObject:newThemeName forKey:CEDefaultThemeKey];
        }
        
        __weak typeof(self) weakSelf = self;
        [self updateCacheWithCompletionHandler:^{
            typeof(self) self = weakSelf;  // strong self
            
            [[NSNotificationCenter defaultCenter] postNotificationName:CEThemeDidUpdateNotification
                                                                object:self
                                                              userInfo:@{CEOldNameKey: themeName,
                                                                         CENewNameKey: newThemeName}];
        }];
    }
    
    return success;
}


//------------------------------------------------------
/// テーマ名に応じたテーマファイルを削除する
- (BOOL)removeSettingWithName:(nonnull NSString *)settingName error:(NSError *__autoreleasing  _Nullable *)outError
//------------------------------------------------------
{
    BOOL success = [super removeSettingWithName:settingName error:outError];
    
    __weak typeof(self) weakSelf = self;
    [self updateCacheWithCompletionHandler:^{
        typeof(self) self = weakSelf;  // strong self
        
        // 開いているウインドウのテーマをデフォルトに戻す
        NSString *defaultThemeName = [[NSUserDefaults standardUserDefaults] stringForKey:CEDefaultThemeKey];
        
        [[NSNotificationCenter defaultCenter] postNotificationName:CEThemeDidUpdateNotification
                                                            object:self
                                                          userInfo:@{CEOldNameKey: settingName,
                                                                     CENewNameKey: defaultThemeName}];
    }];
    
    return success;
}


//------------------------------------------------------
/// カスタマイズされたバンドルテーマをオリジナルに戻す
- (BOOL)restoreSettingWithName:(nonnull NSString *)settingName error:(NSError *__autoreleasing  _Nullable *)outError
//------------------------------------------------------
{
    BOOL success = [super restoreSettingWithName:settingName error:nil];
    
    __weak typeof(self) weakSelf = self;
    [self updateCacheWithCompletionHandler:^{
        typeof(self) self = weakSelf;  // strong self
        
        [[NSNotificationCenter defaultCenter] postNotificationName:CEThemeDidUpdateNotification
                                                            object:self
                                                          userInfo:@{CEOldNameKey: settingName,
                                                                     CENewNameKey: settingName}];
    }];
    
    return success;
}


//------------------------------------------------------
/// 外部テーマファイルをユーザ領域にコピーする
- (BOOL)importThemeWithFileURL:(nonnull NSURL *)fileURL replace:(BOOL)doReplace error:(NSError * _Nullable __autoreleasing * _Nullable)outError
//------------------------------------------------------
{
    // check duplication if required
    if (!doReplace) {
        NSString *settingName = [self settingNameFromURL:fileURL];
        
        BOOL isDuplicated = NO;
        for (NSString *name in [self settingNames]) {
            if ([name caseInsensitiveCompare:settingName] == NSOrderedSame) {
                BOOL isCustomized;
                BOOL isBundled = [self isBundledSetting:settingName cutomized:&isCustomized];
                isDuplicated = (!isBundled || (isBundled && isCustomized));
                break;
            }
        }
        if (isDuplicated) {
            if (outError) {
                *outError = [NSError errorWithDomain:CEErrorDomain
                                                code:CEThemeFileDuplicationError
                                            userInfo:@{NSLocalizedDescriptionKey: [NSString stringWithFormat:NSLocalizedString(@"A new theme named “%@” will be installed, but a custom theme with the same name already exists.", nil), settingName],
                                                       NSLocalizedRecoverySuggestionErrorKey: NSLocalizedString(@"Do you want to replace it?\nReplaced theme can’t be restored.", nil),
                                                       NSLocalizedRecoveryOptionsErrorKey: @[NSLocalizedString(@"Cancel", nil),
                                                                                             NSLocalizedString(@"Replace", nil)],
                                                       NSURLErrorKey: fileURL}];
            }
            return NO;
        }
    }
    
    return [super importSettingWithFileURL:fileURL error:outError];
}


//------------------------------------------------------
/// テーマを複製する
- (BOOL)duplicateThemeWithName:(nonnull NSString *)themeName error:(NSError * _Nullable __autoreleasing * _Nullable)outError
//------------------------------------------------------
{
    // ユーザ領域にテーマ用ディレクトリがまだない場合は作成する
    if (![self prepareUserSettingDirectory]) { return NO; }
    
    NSString *newThemeName = [self copiedSettingName:themeName];
    
    BOOL success = [[NSFileManager defaultManager] copyItemAtURL:[self URLForUsedSettingWithName:themeName]
                                                      toURL:[self URLForUserSettingWithName:newThemeName available:NO]
                                                      error:outError];
    
    if (success) {
        [self updateCacheWithCompletionHandler:nil];
    }
    
    return success;
}


//------------------------------------------------------
/// 新規テーマを作成
- (BOOL)createUntitledThemeWithCompletionHandler:(nullable void (^)(NSString *_Nonnull, NSError *_Nullable))completionHandler
//------------------------------------------------------
{
    NSString *newThemeName = NSLocalizedString(@"Untitled", nil);
    
    // append "Copy n" if "Untitled" already exists
    if ([self URLForUserSettingWithName:newThemeName available:YES]) {
        newThemeName = [self copiedSettingName:newThemeName];
    }
    
    BOOL success = [self saveTheme:[self plainTheme] name:newThemeName completionHandler:^(NSError *error) {
        if (completionHandler) {
            completionHandler(newThemeName, error);
        }
    }];
    
    return success;
}



#pragma mark Private Methods


//------------------------------------------------------
/// テーマ名からユーザ領域のテーマ定義ファイルのURLを返す
- (nullable NSURL *)URLForBundledTheme:(nonnull NSString *)themeName
//------------------------------------------------------
{
    return [self URLForBundledSettingWithName:themeName available:NO];
}


//------------------------------------------------------
/// URLからテーマ辞書を返す
- (nullable NSMutableDictionary<NSString *, NSMutableDictionary<NSString *, id> *> *)themeDictWithURL:(nonnull NSURL *)URL
//------------------------------------------------------
{
    return [NSJSONSerialization JSONObjectWithData:[NSData dataWithContentsOfURL:URL]
                                           options:NSJSONReadingMutableContainers
                                             error:nil];
}


//------------------------------------------------------
/// 内部で持っているキャッシュ用データを更新
- (void)updateCacheWithCompletionHandler:(nullable void (^)())completionHandler
//------------------------------------------------------
{
    __weak typeof(self) weakSelf = self;
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        typeof(self) self = weakSelf;  // strong self
        
        NSURL *userDirURL = [self userSettingDirectoryURL];
        
        NSMutableOrderedSet<NSString *> *themeNameSet = [NSMutableOrderedSet orderedSetWithArray:[self bundledThemeNames]];
        
        // ユーザ定義用ディレクトリが存在する場合は読み込む
        if ([userDirURL checkResourceIsReachableAndReturnError:nil]) {
            NSArray<NSURL *> *URLs = [[NSFileManager defaultManager] contentsOfDirectoryAtURL:userDirURL
                                                                   includingPropertiesForKeys:nil
                                                                                      options:NSDirectoryEnumerationSkipsSubdirectoryDescendants | NSDirectoryEnumerationSkipsHiddenFiles
                                                                                        error:nil];
            
            for (NSURL *URL in URLs) {
                if (![[URL pathExtension] isEqualToString:[self filePathExtension]]) { continue; }
                
                NSString *name = [self settingNameFromURL:URL];
                [themeNameSet addObject:name];
            }
        }
        
        BOOL isListUpdated = ![[themeNameSet array] isEqualToArray:[self themeNames]];
        [self setThemeNames:[themeNameSet array]];
        
        // 定義をキャッシュする
        NSMutableDictionary<NSString *, NSMutableDictionary *> *themes = [NSMutableDictionary dictionary];
        for (NSString *name in themeNameSet) {
            themes[name] = [self themeDictWithURL:[self URLForUsedSettingWithName:name]];
        }
        
        [self setArchivedThemes:themes];
        
        // デフォルトテーマが見当たらないときはリセットする
        if (![themeNameSet containsObject:[[NSUserDefaults standardUserDefaults] stringForKey:CEDefaultThemeKey]]) {
            [[NSUserDefaults standardUserDefaults] removeObjectForKey:CEDefaultThemeKey];
        }
        
        dispatch_sync(dispatch_get_main_queue(), ^{
            // Notificationを発行
            if (isListUpdated) {
                [[NSNotificationCenter defaultCenter] postNotificationName:CEThemeListDidUpdateNotification
                                                                    object:self];
            }
            
            if (completionHandler) {
                completionHandler();
            }
        });
    });
}


//------------------------------------------------------
/// 新規作成時のベースとなる何もないテーマ
- (nonnull NSDictionary<NSString *, NSDictionary<NSString *, id> *> *)plainTheme
//------------------------------------------------------
{
    return [self themeDictWithURL:[self URLForBundledTheme:@"_Plain"]];
}

@end




#pragma mark -

@implementation CEThemeManager (Migration)

//------------------------------------------------------
/// CotEditor 1.5以前から CotEdito 1.6 への移行
- (BOOL)migrateTheme
//------------------------------------------------------
{
    BOOL success = NO;
    NSString *themeName = NSLocalizedString(@"Customized Theme", nil);
    
    // カスタムテーマファイルがある場合は移行処理の必要なし（上書きを避けるため）
    if (![self URLForUserSettingWithName:themeName available:YES]) {
        return NO;
    }
    
    // UserDefaultsからデフォルトから変更されているテーマカラーを探す
    NSMutableDictionary<NSString *, NSMutableDictionary<NSString *, id> *> *theme = [[self classicTheme] mutableCopy];
    BOOL isCustomized = NO;
    for (NSString *classicKey in [self classicThemeKeyTable]) {
        NSString *modernKey = [self classicThemeKeyTable][classicKey];
        NSData *oldData = [[NSUserDefaults standardUserDefaults] dataForKey:classicKey];
        if (!oldData) {
            continue;
        }
        NSColor *color = [NSUnarchiver unarchiveObjectWithData:oldData];
        
        if (color) {
            isCustomized = YES;
            color = [color colorUsingColorSpaceName:NSCalibratedRGBColorSpace];
            theme[modernKey][CEThemeColorKey] = [color colorCodeWithType:WFColorCodeHex];
            if ([classicKey isEqualToString:@"selectionColor"]) {
                theme[CEThemeSelectionKey][CEThemeUsesSystemSettingKey] = @NO;
            }
        }
    }
    
    // カスタマイズされたカラー設定があった場合は移行テーマを生成する
    if (isCustomized) {
        [self saveTheme:theme name:themeName completionHandler:nil];
        
        // カスタマイズされたテーマを選択
        [[NSUserDefaults standardUserDefaults] setObject:themeName forKey:CEDefaultThemeKey];
        
        success = YES;
    }
    
    if (success) {
        [self updateCacheWithCompletionHandler:nil];
    }
    
    return success;
}



# pragma mark Private Methods

//------------------------------------------------------
/// CotEditor 1.5までで使用されていたデフォルトテーマに新たなキーワードを加えたもの
- (nonnull NSMutableDictionary<NSString *, NSMutableDictionary<NSString *, id> *> *)classicTheme
//------------------------------------------------------
{
    NSMutableDictionary<NSString *, NSMutableDictionary<NSString *, id> *> *theme = [self themeDictWithURL:[self URLForBundledTheme:@"Classic"]];
    
    theme[CEMetadataKey] = [@{CEDescriptionKey: NSLocalizedString(@"Auto-generated theme that is migrated from user’s coloring setting on CotEditor 1.x", nil)}
                          mutableCopy];
    
    return theme;
}


//------------------------------------------------------
/// CotEditor 1.5までで使用されていたカラーリング設定のUserDefaultsキーとテーマファイルで使用しているキーの対応テーブル
- (nonnull NSDictionary<NSString *, NSString *> *)classicThemeKeyTable
//------------------------------------------------------
{
    return @{@"textColor": CEThemeTextKey,
             @"backgroundColor": CEThemeBackgroundKey,
             @"invisibleCharactersColor": CEThemeInvisiblesKey,
             @"selectionColor": CEThemeSelectionKey,
             @"insertionPointColor": CEThemeInsertionPointKey,
             @"highlightLineColor": CEThemeLineHighlightKey,
             @"keywordsColor": CEThemeKeywordsKey,
             @"commandsColor": CEThemeCommandsKey,
             @"valuesColor": CEThemeValuesKey,
             @"numbersColor": CEThemeNumbersKey,
             @"stringsColor": CEThemeStringsKey,
             @"charactersColor": CEThemeCharactersKey,
             @"commentsColor": CEThemeCommentsKey,
             };
}

@end
