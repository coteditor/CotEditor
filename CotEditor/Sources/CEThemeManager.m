/*
 =================================================
 CEThemeManager
 (for CotEditor)
 
 Copyright (C) 2014 CotEditor Project
 http://coteditor.github.io
 =================================================
 
 encoding="UTF-8"
 Created:2014-04-12 by 1024jp
 
 -------------------------------------------------
 
 This program is free software; you can redistribute it and/or
 modify it under the terms of the GNU General Public License
 as published by the Free Software Foundation; either version 2
 of the License, or (at your option) any later version.
 
 This program is distributed in the hope that it will be useful,
 but WITHOUT ANY WARRANTY; without even the implied warranty of
 MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 GNU General Public License for more details.
 
 You should have received a copy of the GNU General Public License
 along with this program; if not, write to the Free Software
 Foundation, Inc., 59 Temple Place - Suite 330, Boston, MA  02111-1307, USA.
 
 
 =================================================
 */

#import "CEThemeManager.h"
#import "constants.h"


// keys for theme dict
NSString *const CEThemeTextColorKey = @"textColor";
NSString *const CEThemeBackgroundColorKey = @"backgroundColor";
NSString *const CEThemeInvisiblesColorKey = @"invisiblesColor";
NSString *const CEThemeSelectionColorKey = @"selectionColor";
NSString *const CEThemeInsertionPointColorKey = @"insertionPointColor";
NSString *const CEThemeLineHighlightColorKey = @"lineHighlightColor";

NSString *const CEThemeKeywordsColorKey = @"keywordsColor";
NSString *const CEThemeCommandsColorKey = @"commandsColor";
NSString *const CEThemeTypesColorKey = @"typesColor";
NSString *const CEThemeAttributesColorKey = @"attributesColor";
NSString *const CEThemeVariablesColorKey = @"variablesColor";
NSString *const CEThemeValuesColorKey = @"valuesColor";
NSString *const CEThemeNumbersColorKey = @"numbersColor";
NSString *const CEThemeStringsColorKey = @"stringsColor";
NSString *const CEThemeCharactersColorKey = @"charactersColor";
NSString *const CEThemeCommentsColorKey = @"commentsColor";

NSString *const CEThemeUsesSystemSelectionColorKey = @"usesSystemSelectionColor";

// notifications
NSString *const CEThemeListDidUpdateNotification = @"CEThemeListDidUpdateNotification";
NSString *const CEThemeDidUpdateNotification = @"CEThemeDidUpdateNotification";



@interface CEThemeManager ()

@property (nonatomic, copy) NSDictionary *archivedThemes;
@property (nonatomic, copy) NSArray *bundledThemeNames;

// readonly
@property (nonatomic, copy, readwrite) NSArray *themeNames;

@end



/// CotEditor 1.6 以前からの引き継ぎ作業用カテゴリ。引き継ぎが十分済んだら削除して良い。
@interface CEThemeManager (Migration)

- (void)migrateTheme;

@end



#pragma mark -

@implementation CEThemeManager

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
        // CotEditor 1.5までのカラーリング設定の引き継ぎ
        [self migrateTheme];
        
        // バンドルされているテーマの名前を読み込んでおく
        NSArray *URLs = [[NSBundle mainBundle] URLsForResourcesWithExtension:@"cottheme" subdirectory:@"Themes"];
        NSMutableArray *themeNames = [NSMutableArray array];
        for (NSURL *URL in URLs) {
            [themeNames addObject:[[URL lastPathComponent] stringByDeletingPathExtension]];
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
        dispatch_release(semaphore);
    }
    return self;
}



#pragma mark Public Methods

//=======================================================
// Public methodƒ
//
//=======================================================

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
    NSData *plistData = [NSPropertyListSerialization dataWithPropertyList:theme
                                                                   format:NSPropertyListXMLFormat_v1_0
                                                                  options:0
                                                                    error:&error];
    
    [self prepareUserThemeDirectory];
    
    BOOL success = [plistData writeToURL:[self URLForUserTheme:themeName] options:NSDataWritingAtomic error:&error];
    
    if (success) {
        __block typeof(self) blockSelf = self;
        [self updateCacheWithCompletionHandler:^{
            [[NSNotificationCenter defaultCenter] postNotificationName:CEThemeDidUpdateNotification
                                                                object:blockSelf
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
        if ([[[NSUserDefaults standardUserDefaults] stringForKey:k_key_defaultTheme] isEqualToString:themeName]) {
            [[NSUserDefaults standardUserDefaults] setObject:newThemeName forKey:k_key_defaultTheme];
        }
        
        __block typeof(self) blockSelf = self;
        [self updateCacheWithCompletionHandler:^{
            [[NSNotificationCenter defaultCenter] postNotificationName:CEThemeDidUpdateNotification
                                                                object:blockSelf
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
        success = [[NSFileManager defaultManager] removeItemAtURL:URL error:error];
    }
    
    if (success) {
        __block typeof(self) blockSelf = self;
        [self updateCacheWithCompletionHandler:^{
            // 開いているウインドウのテーマをデフォルトに戻す
            NSString *defaultThemeName = [[NSUserDefaults standardUserDefaults] stringForKey:k_key_defaultTheme];
            
            [[NSNotificationCenter defaultCenter] postNotificationName:CEThemeDidUpdateNotification
                                                                object:blockSelf
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
        __block typeof(self) blockSelf = self;
        [self updateCacheWithCompletionHandler:^{
            [[NSNotificationCenter defaultCenter] postNotificationName:CEThemeDidUpdateNotification
                                                                object:blockSelf
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
    NSString *themeName = [[URL lastPathComponent] stringByDeletingPathExtension];
    
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

//=======================================================
// Private method
//
//=======================================================

//------------------------------------------------------
/// Application Support内のテーマファイル保存ディレクトリ
- (NSURL *)userThemeDirectoryURL
//------------------------------------------------------
{
    return [[[NSFileManager defaultManager] URLForDirectory:NSApplicationSupportDirectory
                                                   inDomain:NSUserDomainMask
                                          appropriateForURL:nil
                                                     create:NO
                                                      error:nil]
            URLByAppendingPathComponent:@"CotEditor/Themes"];
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
    return [[[self userThemeDirectoryURL] URLByAppendingPathComponent:themeName] URLByAppendingPathExtension:@"cottheme"];
}


//------------------------------------------------------
/// テーマ名からユーザ領域のテーマ定義ファイルのURLを返す
- (NSURL *)URLForBundledTheme:(NSString *)themeName
//------------------------------------------------------
{
    return [[NSBundle mainBundle] URLForResource:themeName withExtension:@"cottheme" subdirectory:@"Themes"];
}


//------------------------------------------------------
/// 内部で持っているキャッシュ用データを更新
- (void)updateCacheWithCompletionHandler:(void (^)())completionHandler
//------------------------------------------------------
{
    __block typeof(self) blockSelf = self;
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        NSURL *userDirURL = [blockSelf userThemeDirectoryURL];
        
        NSMutableArray *themeNames = [[blockSelf bundledThemeNames] mutableCopy];
        
        // ユーザ定義用ディレクトリが存在する場合は読み込む
        if ([userDirURL checkResourceIsReachableAndReturnError:nil]) {
            NSDirectoryEnumerator *enumerator = [[NSFileManager defaultManager] enumeratorAtURL:userDirURL
                                                                     includingPropertiesForKeys:nil
                                                                                        options:NSDirectoryEnumerationSkipsSubdirectoryDescendants | NSDirectoryEnumerationSkipsHiddenFiles
                                                                                   errorHandler:^BOOL(NSURL *url, NSError *error)
                                                 {
                                                     NSLog(@"%@", [error description]);
                                                     return YES;
                                                 }];
            NSURL *URL;
            while (URL = [enumerator nextObject]) {
                NSString *name = [[URL lastPathComponent] stringByDeletingPathExtension];
                if (![themeNames containsObject:name]) {
                    [themeNames addObject:name];
                }
            }
        }
        
        BOOL isListUpdated = ![themeNames isEqualToArray:[self themeNames]];
        [self setThemeNames:themeNames];
        
        // 定義をキャッシュする
        NSMutableDictionary *themes = [NSMutableDictionary dictionary];
        for (NSString *name in [blockSelf themeNames]) {
            themes[name] = [NSPropertyListSerialization propertyListWithData:[NSData dataWithContentsOfURL:[self URLForUsedTheme:name]]
                                                                     options:NSPropertyListMutableContainersAndLeaves
                                                                      format:NULL
                                                                       error:nil];
        }
        [self setArchivedThemes:themes];
        
        // デフォルトテーマが見当たらないときはリセットする
        if (![[blockSelf themeNames] containsObject:[[NSUserDefaults standardUserDefaults] stringForKey:k_key_defaultTheme]]) {
            [[NSUserDefaults standardUserDefaults] removeObjectForKey:k_key_defaultTheme];
        }
        
        dispatch_async(dispatch_get_main_queue(), ^{
            // Notificationを発行
            if (isListUpdated) {
                [[NSNotificationCenter defaultCenter] postNotificationName:CEThemeListDidUpdateNotification object:blockSelf];
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
    return @{CEThemeTextColorKey: [NSArchiver archivedDataWithRootObject:[NSColor textColor]],
             CEThemeBackgroundColorKey: [NSArchiver archivedDataWithRootObject:[NSColor textBackgroundColor]],
             CEThemeInvisiblesColorKey: [NSArchiver archivedDataWithRootObject:[NSColor grayColor]],
             CEThemeSelectionColorKey: [NSArchiver archivedDataWithRootObject:[NSColor selectedTextBackgroundColor]],
             CEThemeUsesSystemSelectionColorKey: @YES,
             CEThemeInsertionPointColorKey: [NSArchiver archivedDataWithRootObject:[NSColor textColor]],
             CEThemeLineHighlightColorKey: [NSArchiver archivedDataWithRootObject:[NSColor colorWithWhite:0.94 alpha:1]],
             CEThemeKeywordsColorKey: [NSArchiver archivedDataWithRootObject:[NSColor textColor]],
             CEThemeCommandsColorKey: [NSArchiver archivedDataWithRootObject:[NSColor textColor]],
             CEThemeTypesColorKey: [NSArchiver archivedDataWithRootObject:[NSColor textColor]],
             CEThemeAttributesColorKey: [NSArchiver archivedDataWithRootObject:[NSColor textColor]],
             CEThemeVariablesColorKey: [NSArchiver archivedDataWithRootObject:[NSColor textColor]],
             CEThemeValuesColorKey: [NSArchiver archivedDataWithRootObject:[NSColor textColor]],
             CEThemeNumbersColorKey: [NSArchiver archivedDataWithRootObject:[NSColor textColor]],
             CEThemeStringsColorKey: [NSArchiver archivedDataWithRootObject:[NSColor textColor]],
             CEThemeCharactersColorKey: [NSArchiver archivedDataWithRootObject:[NSColor textColor]],
             CEThemeCommentsColorKey: [NSArchiver archivedDataWithRootObject:[NSColor textColor]]
             };
}

@end




#pragma mark -

@implementation CEThemeManager (Migration)

//------------------------------------------------------
/// CotEditor 1.5以前から CotEdito 1.6 への移行
- (void)migrateTheme
//------------------------------------------------------
{
    // テーマディレクトリがある場合は移行済み
    if ([[self userThemeDirectoryURL] checkResourceIsReachableAndReturnError:nil]) {
        return;
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
        
        if (color && ![color isEqual:theme[modernKey]]) {
            isCustomized = YES;
            theme[modernKey] = [NSArchiver archivedDataWithRootObject:color];
            if ([classicKey isEqualToString:@"selectionColor"]) {
                theme[CEThemeUsesSystemSelectionColorKey] = @NO;
            }
        }
    }
    
    // カスタマイズされたカラー設定があった場合は移行テーマを生成する
    if (isCustomized) {
        NSString *themeName = NSLocalizedString(@"Customized Theme", nil);
        [self saveTheme:theme name:themeName completionHandler:nil];
        // カスタマイズされたテーマを選択
        [[NSUserDefaults standardUserDefaults] setObject:themeName forKey:k_key_defaultTheme];
    }
}



# pragma mark Private Methods

//------------------------------------------------------
/// CotEditor 1.5までで使用されていたデフォルトテーマに新たなキーワードを加えたもの
- (NSDictionary *)classicTheme
//------------------------------------------------------
{
    return @{CEThemeTextColorKey: [NSArchiver archivedDataWithRootObject:[NSColor textColor]],
             CEThemeBackgroundColorKey: [NSArchiver archivedDataWithRootObject:[NSColor textBackgroundColor]],
             CEThemeInvisiblesColorKey: [NSArchiver archivedDataWithRootObject:[NSColor grayColor]],
             CEThemeSelectionColorKey: [NSArchiver archivedDataWithRootObject:[NSColor selectedTextBackgroundColor]],
             CEThemeUsesSystemSelectionColorKey: @YES,
             CEThemeInsertionPointColorKey: [NSArchiver archivedDataWithRootObject:[NSColor textColor]],
             CEThemeLineHighlightColorKey: [NSArchiver archivedDataWithRootObject:
                                          [NSColor colorWithCalibratedRed:0.843 green:0.953 blue:0.722 alpha:1.0]],
             CEThemeKeywordsColorKey: [NSArchiver archivedDataWithRootObject:
                                       [NSColor colorWithCalibratedRed:0.047 green:0.102 blue:0.494 alpha:1.0]],
             CEThemeCommandsColorKey: [NSArchiver archivedDataWithRootObject:
                                       [NSColor colorWithCalibratedRed:0.408 green:0.220 blue:0.129 alpha:1.0]],
             CEThemeTypesColorKey: [NSArchiver archivedDataWithRootObject:
                                    [NSColor colorWithCalibratedRed:0.05 green:0.553 blue:0.659 alpha:1.0]],
             CEThemeAttributesColorKey: [NSArchiver archivedDataWithRootObject:
                                         [NSColor colorWithCalibratedRed:0.078 green:0.3333 blue:0.659 alpha:1.0]],
             CEThemeVariablesColorKey: [NSArchiver archivedDataWithRootObject:
                                        [NSColor colorWithCalibratedRed:0.42 green:0.42 blue:0.474 alpha:1.0]],
             CEThemeValuesColorKey: [NSArchiver archivedDataWithRootObject:
                                     [NSColor colorWithCalibratedRed:0.463 green:0.059 blue:0.313 alpha:1.0]],
             CEThemeNumbersColorKey: [NSArchiver archivedDataWithRootObject:[NSColor blueColor]],
             CEThemeStringsColorKey: [NSArchiver archivedDataWithRootObject:
                                      [NSColor colorWithCalibratedRed:0.537 green:0.075 blue:0.08 alpha:1.0]],
             CEThemeCharactersColorKey: [NSArchiver archivedDataWithRootObject:[NSColor blueColor]],
             CEThemeCommentsColorKey: [NSArchiver archivedDataWithRootObject:
                                       [NSColor colorWithCalibratedRed:0.137 green:0.431 blue:0.145 alpha:1.0]]
             };
}


//------------------------------------------------------
/// CotEditor 1.5までで使用されていたカラーリング設定のUserDefaultsキーとテーマファイルで使用しているキーの対応テーブル
- (NSDictionary *)classicThemeKeyTable
//------------------------------------------------------
{
    return @{@"textColor": CEThemeTextColorKey,
             @"backgroundColor": CEThemeBackgroundColorKey,
             @"invisibleCharactersColor": CEThemeInvisiblesColorKey,
             @"selectionColor": CEThemeSelectionColorKey,
             @"insertionPointColor": CEThemeInsertionPointColorKey,
             @"highlightLineColor": CEThemeLineHighlightColorKey,
             @"keywordsColor": CEThemeKeywordsColorKey,
             @"commandsColor": CEThemeCommandsColorKey,
             @"valuesColor": CEThemeValuesColorKey,
             @"numbersColor": CEThemeNumbersColorKey,
             @"stringsColor": CEThemeStringsColorKey,
             @"charactersColor": CEThemeCharactersColorKey,
             @"commentsColor": CEThemeCommentsColorKey,
             };
}

@end
