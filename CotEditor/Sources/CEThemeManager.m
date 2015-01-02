/*
 ==============================================================================
 CEThemeManager
 
 CotEditor
 http://coteditor.com
 
 Created on 2014-04-12 by 1024jp
 encoding="UTF-8"
 ------------------------------------------------------------------------------
 
 © 2014-2015 1024jp
 
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

#import "CEThemeManager.h"
#import "CEAppDelegate.h"
#import "NSColor+WFColorCode.h"
#import "constants.h"


// extension for theme file
NSString *const CEThemeExtension = @"cottheme";

// keys for theme dict
NSString *const CEThemeTextKey = @"text";
NSString *const CEThemeBackgroundKey = @"background";
NSString *const CEThemeInvisiblesKey = @"invisibles";
NSString *const CEThemeSelectionKey = @"selection";
NSString *const CEThemeInsertionPointKey = @"insertionPoint";
NSString *const CEThemeLineHighlightKey = @"lineHighlight";

NSString *const CEThemeKeywordsKey = @"keywords";
NSString *const CEThemeCommandsKey = @"commands";
NSString *const CEThemeTypesKey = @"types";
NSString *const CEThemeAttributesKey = @"attributes";
NSString *const CEThemeVariablesKey = @"variables";
NSString *const CEThemeValuesKey = @"values";
NSString *const CEThemeNumbersKey = @"numbers";
NSString *const CEThemeStringsKey = @"strings";
NSString *const CEThemeCharactersKey = @"characters";
NSString *const CEThemeCommentsKey = @"comments";

NSString *const CEThemeColorKey = @"color";
NSString *const CEThemeUsesSystemSettingKey = @"usesSystemSetting";

// notifications
NSString *const CEThemeListDidUpdateNotification = @"CEThemeListDidUpdateNotification";
NSString *const CEThemeDidUpdateNotification = @"CEThemeDidUpdateNotification";



@interface CEThemeManager ()

@property (nonatomic, copy) NSDictionary *archivedThemes;
@property (nonatomic, copy) NSArray *bundledThemeNames;

// readonly
@property (readwrite, nonatomic, copy) NSArray *themeNames;

@end



#pragma mark -

@implementation CEThemeManager

#pragma mark Singleton

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

// ------------------------------------------------------
/// initialize
- (instancetype)init
// ------------------------------------------------------
{
    self = [super init];
    if (self) {
        // バンドルされているテーマの名前を読み込んでおく
        NSArray *URLs = [[NSBundle mainBundle] URLsForResourcesWithExtension:CEThemeExtension subdirectory:@"Themes"];
        NSMutableArray *themeNames = [NSMutableArray array];
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



#pragma mark Public Methods

//------------------------------------------------------
/// テーマ名からProperty list形式のテーマ定義を返す
- (NSMutableDictionary *)archivedTheme:(NSString *)themeName isBundled:(BOOL *)isBundled
//------------------------------------------------------
{
    if (isBundled) {
        *isBundled = [[self bundledThemeNames] containsObject:themeName];
    }
    return [[self archivedThemes][themeName] mutableCopy];
}


//------------------------------------------------------
/// テーマ名と同名のバンドルテーマが存在するかを返す
- (BOOL)isBundledTheme:(NSString *)themeName cutomized:(BOOL *)isCustomized
//------------------------------------------------------
{
    BOOL isBundled = [[self bundledThemeNames] containsObject:themeName];
    
    if (isBundled && isCustomized) {
        *isCustomized = [[self URLForUserTheme:themeName] checkResourceIsReachableAndReturnError:nil];
    }
    
    return isBundled;
}


//------------------------------------------------------
/// テーマを保存する
- (BOOL)saveTheme:(NSDictionary *)theme name:(NSString *)themeName completionHandler:(void (^)(NSError *))completionHandler
//------------------------------------------------------
{
    NSError *error = nil;
    
    NSData *jsonData = [NSJSONSerialization dataWithJSONObject:theme
                                                       options:NSJSONWritingPrettyPrinted
                                                         error:&error];
    
    [self prepareUserThemeDirectory];
    
    BOOL success = [jsonData writeToURL:[self URLForUserTheme:themeName] options:NSDataWritingAtomic error:&error];
    
    if (success) {
        __weak typeof(self) weakSelf = self;
        [self updateCacheWithCompletionHandler:^{
            typeof(self) strongSelf = weakSelf;
            [[NSNotificationCenter defaultCenter] postNotificationName:CEThemeDidUpdateNotification
                                                                object:strongSelf
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
- (BOOL)renameTheme:(NSString *)themeName toName:(NSString *)newThemeName error:(NSError *__autoreleasing *)error
//------------------------------------------------------
{
    BOOL success = NO;
    
    newThemeName = [newThemeName stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
    
    if (![self validateThemeName:newThemeName originalName:themeName error:error]) {
        return NO;
    }
    
    success = [[NSFileManager defaultManager] moveItemAtURL:[self URLForUserTheme:themeName]
                                                      toURL:[self URLForUserTheme:newThemeName] error:nil];
    
    if (success) {
        if ([[[NSUserDefaults standardUserDefaults] stringForKey:CEDefaultThemeKey] isEqualToString:themeName]) {
            [[NSUserDefaults standardUserDefaults] setObject:newThemeName forKey:CEDefaultThemeKey];
        }
        
        __weak typeof(self) weakSelf = self;
        [self updateCacheWithCompletionHandler:^{
            typeof(self) strongSelf = weakSelf;
            [[NSNotificationCenter defaultCenter] postNotificationName:CEThemeDidUpdateNotification
                                                                object:strongSelf
                                                              userInfo:@{CEOldNameKey: themeName,
                                                                         CENewNameKey: newThemeName}];
        }];
    }
    
    return success;
}


//------------------------------------------------------
/// テーマ名に応じたテーマファイルを削除する
- (BOOL)removeTheme:(NSString *)themeName error:(NSError *__autoreleasing *)error
//------------------------------------------------------
{
    BOOL success = NO;
    NSURL *URL = [self URLForUserTheme:themeName];
    
    if ([URL checkResourceIsReachableAndReturnError:nil]) {
        success = [[NSFileManager defaultManager] trashItemAtURL:URL resultingItemURL:nil error:nil];
    }
    
    if (success) {
        __weak typeof(self) weakSelf = self;
        [self updateCacheWithCompletionHandler:^{
            typeof(self) strongSelf = weakSelf;
            
            // 開いているウインドウのテーマをデフォルトに戻す
            NSString *defaultThemeName = [[NSUserDefaults standardUserDefaults] stringForKey:CEDefaultThemeKey];
            
            [[NSNotificationCenter defaultCenter] postNotificationName:CEThemeDidUpdateNotification
                                                                object:strongSelf
                                                              userInfo:@{CEOldNameKey: themeName,
                                                                         CENewNameKey: defaultThemeName}];
        }];
    }
    
    return success;
}


//------------------------------------------------------
/// カスタマイズされたバンドルテーマをオリジナルに戻す
- (BOOL)restoreTheme:(NSString *)themeName completionHandler:(void (^)(NSError *))completionHandler
//------------------------------------------------------
{
    // バンドルテーマでないものはそもそもリストアできない
    if (![self isBundledTheme:themeName cutomized:nil]) { return NO; }

    NSError *error = nil;
    BOOL success = [[NSFileManager defaultManager] removeItemAtURL:[self URLForUserTheme:themeName] error:&error];
    
    if (success) {
        __weak typeof(self) weakSelf = self;
        [self updateCacheWithCompletionHandler:^{
            typeof(self) strongSelf = weakSelf;
            [[NSNotificationCenter defaultCenter] postNotificationName:CEThemeDidUpdateNotification
                                                                object:strongSelf
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
- (BOOL)importTheme:(NSURL *)URL replace:(BOOL)doReplace error:(NSError *__autoreleasing *)error
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
            if (error) {
                NSDictionary *userInfo = @{NSLocalizedDescriptionKey: [NSString stringWithFormat:NSLocalizedString(@"A new theme named “%@” will be installed, but a custom theme with the same name already exists.", nil), themeName],
                                           NSLocalizedRecoverySuggestionErrorKey: NSLocalizedString(@"Do you want to replace it?\nReplaced theme cannot be restored.", nil),
                                           NSLocalizedRecoveryOptionsErrorKey: @[NSLocalizedString(@"Cancel", nil),
                                                                                 NSLocalizedString(@"Replace", nil)],
                                           NSURLErrorKey: URL};
                *error = [NSError errorWithDomain:CEErrorDomain code:CEThemeFileDuplicationError userInfo:userInfo];
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
                           writingItemAtURL:[self URLForUserTheme:themeName] options:NSFileCoordinatorWritingForReplacing
                                      error:error byAccessor:^(NSURL *newReadingURL, NSURL *newWritingURL)
     {
         if ([newWritingURL checkResourceIsReachableAndReturnError:nil]) {
             [[NSFileManager defaultManager] removeItemAtURL:newWritingURL error:error];
         }
         
         success = [[NSFileManager defaultManager] copyItemAtURL:newReadingURL toURL:newWritingURL error:error];
     }];
    
    if (success) {
        [self updateCacheWithCompletionHandler:nil];
    }
    
    return success;
}


//------------------------------------------------------
/// テーマファイルを指定のURLにコピーする
- (BOOL)exportTheme:(NSString *)themeName toURL:(NSURL *)URL error:(NSError *__autoreleasing *)error
//------------------------------------------------------
{
    __block BOOL success = NO;
    
    NSFileCoordinator *coordinator = [[NSFileCoordinator alloc] initWithFilePresenter:nil];
    [coordinator coordinateReadingItemAtURL:[self URLForUserTheme:themeName] options:NSFileCoordinatorReadingWithoutChanges
                           writingItemAtURL:URL options:NSFileCoordinatorWritingForMoving
                                      error:error byAccessor:^(NSURL *newReadingURL, NSURL *newWritingURL)
     {
         if ([newWritingURL checkResourceIsReachableAndReturnError:nil]) {
             [[NSFileManager defaultManager] removeItemAtURL:newWritingURL error:error];
         }
         
         success = [[NSFileManager defaultManager] copyItemAtURL:newReadingURL toURL:newWritingURL error:error];
     }];
    
    return success;
}


//------------------------------------------------------
/// テーマを複製する
- (BOOL)duplicateTheme:(NSString *)themeName error:(NSError *__autoreleasing *)error
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
    while ([[self URLForUserTheme:newThemeName] checkResourceIsReachableAndReturnError:nil]) {
        newThemeName = [nameBase stringByAppendingFormat:@" %tu", counter];
        counter++;
    }
    
    success = [[NSFileManager defaultManager] copyItemAtURL:[self URLForUsedTheme:themeName]
                                                      toURL:[self URLForUserTheme:newThemeName] error:error];
    
    if (success) {
        [self updateCacheWithCompletionHandler:nil];
    }
    
    return success;
}


//------------------------------------------------------
/// 新規テーマを作成
- (BOOL)createUntitledThemeWithCompletionHandler:(void (^)(NSString *, NSError *))completionHandler
//------------------------------------------------------
{
    BOOL success = NO;
    NSString *nameBase = NSLocalizedString(@"Untitled", nil);
    NSString *newThemeName = nameBase;
    
    // すでに同名のファイルが存在したら数字を追加する
    NSUInteger counter = 2;
    while ([[self URLForUserTheme:newThemeName] checkResourceIsReachableAndReturnError:nil]) {
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
- (NSString *)themeNameFromURL:(NSURL *)fileURL
//------------------------------------------------------
{
    return [[fileURL lastPathComponent] stringByDeletingPathExtension];
}


//------------------------------------------------------
/// Application Support内のテーマファイル保存ディレクトリ
- (NSURL *)userThemeDirectoryURL
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
- (NSURL *)URLForUsedTheme:(NSString *)themeName
//------------------------------------------------------
{
    NSURL *URL = [self URLForUserTheme:themeName];
    
    if (![URL checkResourceIsReachableAndReturnError:nil]) {
        URL = [self URLForBundledTheme:themeName];
    }
    
    return [URL checkResourceIsReachableAndReturnError:nil] ? URL : nil;
}


//------------------------------------------------------
/// テーマ名からユーザ領域のテーマ定義ファイルのURLを返す
- (NSURL *)URLForUserTheme:(NSString *)themeName
//------------------------------------------------------
{
    return [[[self userThemeDirectoryURL] URLByAppendingPathComponent:themeName] URLByAppendingPathExtension:CEThemeExtension];
}


//------------------------------------------------------
/// テーマ名からユーザ領域のテーマ定義ファイルのURLを返す
- (NSURL *)URLForBundledTheme:(NSString *)themeName
//------------------------------------------------------
{
    return [[NSBundle mainBundle] URLForResource:themeName withExtension:CEThemeExtension subdirectory:@"Themes"];
}


//------------------------------------------------------
/// URLからテーマ辞書を返す
- (NSMutableDictionary *)themeDictWithURL:(NSURL *)URL
//------------------------------------------------------
{
    return [NSJSONSerialization JSONObjectWithData:[NSData dataWithContentsOfURL:URL]
                                           options:NSJSONReadingMutableContainers
                                             error:nil];
}


//------------------------------------------------------
/// 内部で持っているキャッシュ用データを更新
- (void)updateCacheWithCompletionHandler:(void (^)())completionHandler
//------------------------------------------------------
{
    __weak typeof(self) weakSelf = self;
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        typeof(self) strongSelf = weakSelf;
        NSURL *userDirURL = [strongSelf userThemeDirectoryURL];
        
        NSMutableOrderedSet *themeNameSet = [NSMutableOrderedSet orderedSetWithArray:[strongSelf bundledThemeNames]];
        
        // ユーザ定義用ディレクトリが存在する場合は読み込む
        if ([userDirURL checkResourceIsReachableAndReturnError:nil]) {
            NSArray *URLs = [[NSFileManager defaultManager] contentsOfDirectoryAtURL:userDirURL
                                                          includingPropertiesForKeys:nil
                                                                             options:NSDirectoryEnumerationSkipsSubdirectoryDescendants | NSDirectoryEnumerationSkipsHiddenFiles
                                                                               error:nil];
            
            for (NSURL *URL in URLs) {
                if (![[URL pathExtension] isEqualToString:CEThemeExtension]) { continue; }
                
                NSString *name = [strongSelf themeNameFromURL:URL];
                [themeNameSet addObject:name];
            }
        }
        
        BOOL isListUpdated = ![[themeNameSet array] isEqualToArray:[self themeNames]];
        [self setThemeNames:[themeNameSet array]];
        
        // 定義をキャッシュする
        NSMutableDictionary *themes = [NSMutableDictionary dictionary];
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
                                                                    object:strongSelf];
            }
            
            if (completionHandler) {
                completionHandler();
            }
        });
    });
}


// ------------------------------------------------------
// 有効なテーマ名かチェックしてエラーメッセージを返す
- (BOOL)validateThemeName:(NSString *)themeName originalName:(NSString *)originalThemeName error:(NSError *__autoreleasing *)error
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
        description = NSLocalizedString(@"Theme name cannot be empty.", nil);
    } else if ([themeName rangeOfString:@"/"].location != NSNotFound) {  // ファイル名としても使われるので、"/" が含まれる名前は不可
        description = NSLocalizedString(@"Theme name cannot contain “/”.", nil);
    } else if ([themeName hasPrefix:@"."]) {  // ファイル名としても使われるので、"." から始まる名前は不可
        description = NSLocalizedString(@"Theme name cannot begin with “.”.", nil);
    } else if ([[self themeNames] indexOfObjectPassingTest:caseInsensitiveContains] != NSNotFound) {  // 既にある名前は不可
        description = [NSString stringWithFormat:NSLocalizedString(@"“%@” is already exist.", nil), duplicatedThemeName];
    }
    
    if (error && description) {
        *error = [NSError errorWithDomain:CEErrorDomain
                                     code:CEInvalidNameError
                                 userInfo:@{NSLocalizedDescriptionKey: description,
                                            NSLocalizedRecoverySuggestionErrorKey: NSLocalizedString(@"Input another name.", nil)}];
    }
    
    return (!description);
}


//------------------------------------------------------
/// 新規作成時のベースとなる何もないテーマ
- (NSDictionary *)plainTheme
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
    if ([[self URLForUserTheme:themeName] checkResourceIsReachableAndReturnError:nil]) {
        return NO;
    }
    
    // UserDefaultsからデフォルトから変更されているテーマカラーを探す
    NSMutableDictionary *theme = [[self classicTheme] mutableCopy];
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
- (NSMutableDictionary *)classicTheme
//------------------------------------------------------
{
    NSMutableDictionary *theme = [self themeDictWithURL:[self URLForBundledTheme:@"Classic"]];
    
    theme[CEMetadataKey] = [@{CEDescriptionKey: NSLocalizedString(@"Auto-generated theme that is mgrated from user's coloring setting on CotEditor 1.x", nil)}
                          mutableCopy];
    
    return theme;
}


//------------------------------------------------------
/// CotEditor 1.5までで使用されていたカラーリング設定のUserDefaultsキーとテーマファイルで使用しているキーの対応テーブル
- (NSDictionary *)classicThemeKeyTable
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
