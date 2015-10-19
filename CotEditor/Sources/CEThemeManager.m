/*
 
 CEThemeManager.m
 
 CotEditor
 http://coteditor.com
 
 Created by 1024jp on 2014-04-12.

 ------------------------------------------------------------------------------
 
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

#import "CEThemeManager.h"
#import "CEAppDelegate.h"
#import "NSColor+WFColorCode.h"
#import "Constants.h"


// extension for theme file
NSString *_Nonnull const CEThemeExtension = @"cottheme";

// keys for theme dict
NSString *_Nonnull const CEThemeTextKey = @"text";
NSString *_Nonnull const CEThemeBackgroundKey = @"background";
NSString *_Nonnull const CEThemeInvisiblesKey = @"invisibles";
NSString *_Nonnull const CEThemeSelectionKey = @"selection";
NSString *_Nonnull const CEThemeInsertionPointKey = @"insertionPoint";
NSString *_Nonnull const CEThemeLineHighlightKey = @"lineHighlight";

NSString *_Nonnull const CEThemeKeywordsKey = @"keywords";
NSString *_Nonnull const CEThemeCommandsKey = @"commands";
NSString *_Nonnull const CEThemeTypesKey = @"types";
NSString *_Nonnull const CEThemeAttributesKey = @"attributes";
NSString *_Nonnull const CEThemeVariablesKey = @"variables";
NSString *_Nonnull const CEThemeValuesKey = @"values";
NSString *_Nonnull const CEThemeNumbersKey = @"numbers";
NSString *_Nonnull const CEThemeStringsKey = @"strings";
NSString *_Nonnull const CEThemeCharactersKey = @"characters";
NSString *_Nonnull const CEThemeCommentsKey = @"comments";

NSString *_Nonnull const CEThemeColorKey = @"color";
NSString *_Nonnull const CEThemeUsesSystemSettingKey = @"usesSystemSetting";

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
+ (nonnull instancetype)sharedManager
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
        NSArray<NSURL *> *URLs = [[NSBundle mainBundle] URLsForResourcesWithExtension:CEThemeExtension subdirectory:@"Themes"];
        NSMutableArray<NSString *> *themeNames = [NSMutableArray array];
        for (NSURL *URL in URLs) {
            if ([[URL lastPathComponent] hasPrefix:@"_"]) { continue; }
            
            [themeNames addObject:[self themeNameFromURL:URL]];
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

// ------------------------------------------------------
/// clean-up
- (void)dealloc
// ------------------------------------------------------
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}



#pragma mark Public Methods

//------------------------------------------------------
/// テーマ名から Property list 形式のテーマ定義を返す
- (nullable NSMutableDictionary<NSString *, NSMutableDictionary<NSString *, id> *> *)archivedTheme:(nonnull NSString *)themeName isBundled:(nullable BOOL *)isBundled
//------------------------------------------------------
{
    if (isBundled) {
        *isBundled = [[self bundledThemeNames] containsObject:themeName];
    }
    return [[self archivedThemes][themeName] mutableCopy];
}


//------------------------------------------------------
/// テーマ名と同名のバンドルテーマが存在するかを返す
- (BOOL)isBundledTheme:(nonnull NSString *)themeName cutomized:(nullable BOOL *)isCustomized
//------------------------------------------------------
{
    BOOL isBundled = [[self bundledThemeNames] containsObject:themeName];
    
    if (isBundled && isCustomized) {
        *isCustomized = ([self URLForUserTheme:themeName available:YES]);
    }
    
    return isBundled;
}


//------------------------------------------------------
/// テーマ名からユーザ領域のテーマ定義ファイルのURLを返す（ない場合はnil）
- (nullable NSURL *)URLForUserTheme:(nonnull NSString *)themeName
//------------------------------------------------------
{
    return [[[self userThemeDirectoryURL] URLByAppendingPathComponent:themeName] URLByAppendingPathExtension:CEThemeExtension];
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
    
    [self prepareUserThemeDirectory];
    
    BOOL success = [jsonData writeToURL:[self URLForUserTheme:themeName available:NO] options:NSDataWritingAtomic error:&error];
    
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
- (BOOL)renameTheme:(nonnull NSString *)themeName toName:(nonnull NSString *)newThemeName error:(NSError * _Nullable __autoreleasing * _Nullable)outError
//------------------------------------------------------
{
    BOOL success = NO;
    
    newThemeName = [newThemeName stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
    
    if (![self validateThemeName:newThemeName originalName:themeName error:outError]) {
        return NO;
    }
    
    success = [[NSFileManager defaultManager] moveItemAtURL:[self URLForUserTheme:themeName available:NO]
                                                      toURL:[self URLForUserTheme:newThemeName available:NO] error:nil];
    
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
- (BOOL)removeTheme:(nonnull NSString *)themeName error:(NSError * _Nullable __autoreleasing * _Nullable)outError
//------------------------------------------------------
{
    NSURL *URL = [self URLForUserTheme:themeName available:YES];
    
    if (!URL) { return NO; }
    
    BOOL success = [[NSFileManager defaultManager] trashItemAtURL:URL resultingItemURL:nil error:nil];
    
    if (success) {
        __weak typeof(self) weakSelf = self;
        [self updateCacheWithCompletionHandler:^{
            typeof(self) self = weakSelf;  // strong self
            
            // 開いているウインドウのテーマをデフォルトに戻す
            NSString *defaultThemeName = [[NSUserDefaults standardUserDefaults] stringForKey:CEDefaultThemeKey];
            
            [[NSNotificationCenter defaultCenter] postNotificationName:CEThemeDidUpdateNotification
                                                                object:self
                                                              userInfo:@{CEOldNameKey: themeName,
                                                                         CENewNameKey: defaultThemeName}];
        }];
    }
    
    return success;
}


//------------------------------------------------------
/// カスタマイズされたバンドルテーマをオリジナルに戻す
- (BOOL)restoreTheme:(nonnull NSString *)themeName completionHandler:(nullable void (^)(NSError *_Nullable))completionHandler
//------------------------------------------------------
{
    // バンドルテーマでないものはそもそもリストアできない
    if (![self isBundledTheme:themeName cutomized:nil]) { return NO; }

    NSError *error = nil;
    BOOL success = [[NSFileManager defaultManager] removeItemAtURL:[self URLForUserTheme:themeName available:NO] error:&error];
    
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
/// 外部テーマファイルをユーザ領域にコピーする
- (BOOL)importTheme:(nonnull NSURL *)URL replace:(BOOL)doReplace error:(NSError * _Nullable __autoreleasing * _Nullable)outError
//------------------------------------------------------
{
    __block BOOL success = NO;
    NSString *themeName = [self themeNameFromURL:URL];
    
    // 上書きをしない場合は重複をチェックする
    if (!doReplace) {
        BOOL isDuplicated = NO;
        for (NSString *name in [self themeNames]) {
            if ([name caseInsensitiveCompare:themeName] == NSOrderedSame) {
                BOOL isCustomized;
                BOOL isBundled = [self isBundledTheme:themeName cutomized:&isCustomized];
                isDuplicated = (!isBundled || (isBundled && isCustomized));
                break;
            }
        }
        if (isDuplicated) {
            if (outError) {
                *outError = [NSError errorWithDomain:CEErrorDomain
                                                code:CEThemeFileDuplicationError
                                            userInfo:@{NSLocalizedDescriptionKey: [NSString stringWithFormat:NSLocalizedString(@"A new theme named “%@” will be installed, but a custom theme with the same name already exists.", nil), themeName],
                                                       NSLocalizedRecoverySuggestionErrorKey: NSLocalizedString(@"Do you want to replace it?\nReplaced theme can’t be restored.", nil),
                                                       NSLocalizedRecoveryOptionsErrorKey: @[NSLocalizedString(@"Cancel", nil),
                                                                                             NSLocalizedString(@"Replace", nil)],
                                                       NSURLErrorKey: URL}];
            }
            return NO;
        }
    }
    
    // ユーザ領域にテーマ用ディレクトリがまだない場合は作成する
    if (![self prepareUserThemeDirectory]) {
        return NO;
    }
    
    // ファイルをコピー
    NSFileCoordinator *coordinator = [[NSFileCoordinator alloc] initWithFilePresenter:nil];
    [coordinator coordinateReadingItemAtURL:URL options:NSFileCoordinatorReadingWithoutChanges | NSFileCoordinatorReadingResolvesSymbolicLink
                           writingItemAtURL:[self URLForUserTheme:themeName available:NO] options:NSFileCoordinatorWritingForReplacing
                                      error:outError byAccessor:^(NSURL *newReadingURL, NSURL *newWritingURL)
     {
         if ([newWritingURL checkResourceIsReachableAndReturnError:nil]) {
             [[NSFileManager defaultManager] removeItemAtURL:newWritingURL error:outError];
         }
         
         success = [[NSFileManager defaultManager] copyItemAtURL:newReadingURL toURL:newWritingURL error:outError];
     }];
    
    if (success) {
        [self updateCacheWithCompletionHandler:nil];
    }
    
    return success;
}


//------------------------------------------------------
/// テーマファイルを指定のURLにコピーする
- (BOOL)exportTheme:(nonnull NSString *)themeName toURL:(nonnull NSURL *)URL error:(NSError * _Nullable __autoreleasing * _Nullable)outError
//------------------------------------------------------
{
    __block BOOL success = NO;
    
    NSFileCoordinator *coordinator = [[NSFileCoordinator alloc] initWithFilePresenter:nil];
    [coordinator coordinateReadingItemAtURL:[self URLForUserTheme:themeName available:NO] options:NSFileCoordinatorReadingWithoutChanges
                           writingItemAtURL:URL options:NSFileCoordinatorWritingForMoving
                                      error:outError byAccessor:^(NSURL *newReadingURL, NSURL *newWritingURL)
     {
         if ([newWritingURL checkResourceIsReachableAndReturnError:nil]) {
             [[NSFileManager defaultManager] removeItemAtURL:newWritingURL error:outError];
         }
         
         success = [[NSFileManager defaultManager] copyItemAtURL:newReadingURL toURL:newWritingURL error:outError];
     }];
    
    return success;
}


//------------------------------------------------------
/// テーマを複製する
- (BOOL)duplicateTheme:(nonnull NSString *)themeName error:(NSError * _Nullable __autoreleasing * _Nullable)outError
//------------------------------------------------------
{
    BOOL success = NO;
    NSString *nameBase = [themeName stringByAppendingString:NSLocalizedString(@" copy", nil)];
    NSString *newThemeName = nameBase;
    
    // ユーザ領域にテーマ用ディレクトリがまだない場合は作成する
    if (![self prepareUserThemeDirectory]) {
        return NO;
    }

    // すでに同名のファイルが存在したら数字を追加する
    NSUInteger counter = 2;
    while ([self URLForUserTheme:newThemeName available:YES]) {
        newThemeName = [nameBase stringByAppendingFormat:@" %tu", counter];
        counter++;
    }
    
    success = [[NSFileManager defaultManager] copyItemAtURL:[self URLForUsedTheme:themeName]
                                                      toURL:[self URLForUserTheme:newThemeName available:NO]
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
    BOOL success = NO;
    NSString *nameBase = NSLocalizedString(@"Untitled", nil);
    NSString *newThemeName = nameBase;
    
    // すでに同名のファイルが存在したら数字を追加する
    NSUInteger counter = 2;
    while ([self URLForUserTheme:newThemeName available:YES]) {
        newThemeName = [nameBase stringByAppendingFormat:@" %tu", counter];
        counter++;
    }
    
    success = [self saveTheme:[self plainTheme] name:newThemeName completionHandler:^(NSError *error) {
        if (completionHandler) {
            completionHandler(newThemeName, error);
        }
    }];
    
    return success;
}



#pragma mark Private Methods

//------------------------------------------------------
/// テーマファイルの URL からスタイル名を返す
- (nonnull NSString *)themeNameFromURL:(nonnull NSURL *)fileURL
//------------------------------------------------------
{
    return [[fileURL lastPathComponent] stringByDeletingPathExtension];
}


//------------------------------------------------------
/// Application Support内のテーマファイル保存ディレクトリ
- (nonnull NSURL *)userThemeDirectoryURL
//------------------------------------------------------
{
    return [[(CEAppDelegate *)[NSApp delegate] supportDirectoryURL] URLByAppendingPathComponent:@"Themes"];
}


//------------------------------------------------------
/// ユーザ領域のテーマ保存用ディレクトリの存在をチェックし、ない場合は作成する
- (BOOL)prepareUserThemeDirectory
//------------------------------------------------------
{
    BOOL success = NO;
    NSError *error = nil;
    NSURL *URL = [self userThemeDirectoryURL];
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
/// テーマ名から有効なテーマ定義ファイルのURLを返す
- (nullable NSURL *)URLForUsedTheme:(nonnull NSString *)themeName
//------------------------------------------------------
{
    NSURL *URL = [self URLForUserTheme:themeName available:YES] ? : [self URLForBundledTheme:themeName];
    
    return [URL checkResourceIsReachableAndReturnError:nil] ? URL : nil;
}


//------------------------------------------------------
/// テーマ名からユーザ領域のテーマファイルのURLを返す (availableがYESの場合はファイルが実際に存在するときだけ返す)
- (nullable NSURL *)URLForUserTheme:(NSString *)themeName available:(BOOL)available
//------------------------------------------------------
{
    NSURL *URL = [[[self userThemeDirectoryURL] URLByAppendingPathComponent:themeName] URLByAppendingPathExtension:CEThemeExtension];
    
    if (available) {
        return [URL checkResourceIsReachableAndReturnError:nil] ? URL : nil;
    } else {
        return URL;
    }
}


//------------------------------------------------------
/// テーマ名からユーザ領域のテーマ定義ファイルのURLを返す
- (nullable NSURL *)URLForBundledTheme:(nonnull NSString *)themeName
//------------------------------------------------------
{
    return [[NSBundle mainBundle] URLForResource:themeName withExtension:CEThemeExtension subdirectory:@"Themes"];
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
        
        NSURL *userDirURL = [self userThemeDirectoryURL];
        
        NSMutableOrderedSet<NSString *> *themeNameSet = [NSMutableOrderedSet orderedSetWithArray:[self bundledThemeNames]];
        
        // ユーザ定義用ディレクトリが存在する場合は読み込む
        if ([userDirURL checkResourceIsReachableAndReturnError:nil]) {
            NSArray<NSURL *> *URLs = [[NSFileManager defaultManager] contentsOfDirectoryAtURL:userDirURL
                                                                   includingPropertiesForKeys:nil
                                                                                      options:NSDirectoryEnumerationSkipsSubdirectoryDescendants | NSDirectoryEnumerationSkipsHiddenFiles
                                                                                        error:nil];
            
            for (NSURL *URL in URLs) {
                if (![[URL pathExtension] isEqualToString:CEThemeExtension]) { continue; }
                
                NSString *name = [self themeNameFromURL:URL];
                [themeNameSet addObject:name];
            }
        }
        
        BOOL isListUpdated = ![[themeNameSet array] isEqualToArray:[self themeNames]];
        [self setThemeNames:[themeNameSet array]];
        
        // 定義をキャッシュする
        NSMutableDictionary<NSString *, NSMutableDictionary *> *themes = [NSMutableDictionary dictionary];
        for (NSString *name in themeNameSet) {
            themes[name] = [self themeDictWithURL:[self URLForUsedTheme:name]];
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


// ------------------------------------------------------
/// 有効なテーマ名かチェックしてエラーメッセージを返す
- (BOOL)validateThemeName:(nonnull NSString *)themeName originalName:(nonnull NSString *)originalThemeName error:(NSError * _Nullable __autoreleasing * _Nullable)outError
// ------------------------------------------------------
{
    // 元の名前とのケース違いはOK
    if ([themeName caseInsensitiveCompare:originalThemeName] == NSOrderedSame) {
        return YES;
    }
    
    NSString *description;
    // NSArray を case insensitive に検索するブロック
    __block NSString *duplicatedThemeName;
    BOOL (^caseInsensitiveContains)() = ^(id obj, NSUInteger idx, BOOL *stop){
        BOOL found = (BOOL)([obj caseInsensitiveCompare:themeName] == NSOrderedSame);
        if (found) { duplicatedThemeName = obj; }
        return found;
    };
    
    if ([themeName length] < 1) {  // 空は不可
        description = NSLocalizedString(@"Theme name can’t be empty.", nil);
    } else if ([themeName rangeOfString:@"/"].location != NSNotFound) {  // ファイル名としても使われるので、"/" が含まれる名前は不可
        description = NSLocalizedString(@"You can’t use a theme name that contains “/”.", nil);
    } else if ([themeName hasPrefix:@"."]) {  // ファイル名としても使われるので、"." から始まる名前は不可
        description = NSLocalizedString(@"You can’t use a theme name that begins with a dot “.”.", nil);
    } else if ([[self themeNames] indexOfObjectPassingTest:caseInsensitiveContains] != NSNotFound) {  // 既にある名前は不可
        description = [NSString stringWithFormat:NSLocalizedString(@"The theme name “%@” is already taken.", nil), duplicatedThemeName];
    }
    
    if (outError && description) {
        *outError = [NSError errorWithDomain:CEErrorDomain
                                        code:CEInvalidNameError
                                    userInfo:@{NSLocalizedDescriptionKey: description,
                                               NSLocalizedRecoverySuggestionErrorKey: NSLocalizedString(@"Please choose another name.", nil)}];
    }
    
    return (!description);
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
    if (![self URLForUserTheme:themeName available:YES]) {
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
        [self updateCacheWithCompletionHandler:^{
            // do nothing
        }];
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
