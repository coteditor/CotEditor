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
NSString *const CEThemeValuesColorKey = @"valuesColor";
NSString *const CEThemeNumbersColorKey = @"numbersColor";
NSString *const CEThemeStringsColorKey = @"stringsColor";
NSString *const CEThemeCharactersColorKey = @"charactersColor";
NSString *const CEThemeCommentsColorKey = @"commentsColor";

NSString *const CEThemeUsesSystemSelectionColorKey = @"usesSystemSelectionColor";

// notifications
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
        NSArray *URLs = [[NSBundle mainBundle] URLsForResourcesWithExtension:@"plist" subdirectory:@"Themes"];
        NSMutableArray *themeNames = [NSMutableArray array];
        for (NSURL *URL in URLs) {
            [themeNames addObject:[[URL lastPathComponent] stringByDeletingPathExtension]];
        }
        [self setBundledThemeNames:themeNames];
        
        // 読み込む
        [self updateCache];
    }
    return self;
}



#pragma mark Public Methods

//=======================================================
// Public method
//
//=======================================================

//------------------------------------------------------
/// テーマ名からProperty list形式のテーマ定義を返す
- (NSMutableDictionary *)archivedTheme:(NSString *)themeName isBundled:(BOOL *)isBundled
//------------------------------------------------------
{
    isBundled = [[self bundledThemeNames] containsObject:themeName];
    
    return [[self archivedThemes][themeName] mutableCopy];
}


//------------------------------------------------------
/// テーマ名と同名のバンドルテーマが存在するかを返す
- (BOOL)isBundledTheme:(NSString *)themeName
//------------------------------------------------------
{
    return [[self bundledThemeNames] containsObject:themeName];
}


//------------------------------------------------------
/// テーマを保存する
- (BOOL)saveTheme:(NSDictionary *)theme name:(NSString *)themeName  // TODO:not implemented
//------------------------------------------------------
{
    NSData *plistData = [NSPropertyListSerialization dataWithPropertyList:theme
                                                                   format:NSPropertyListBinaryFormat_v1_0
                                                                  options:0
                                                                    error:nil];
    
    [self prepareUserThemeDirectory];
    
    BOOL success = [plistData writeToURL:[self URLForUserTheme:themeName] atomically:YES];
    
    if (success) {
        [self updateCache];
    }
    
    return success;
}


//------------------------------------------------------
/// テーマ名を変更する
- (BOOL)renameTheme:(NSString *)themeName toName:(NSString *)newThemeName
//------------------------------------------------------
{
    BOOL success = NO;
    
    success = [[NSFileManager defaultManager] moveItemAtURL:[self URLForUserTheme:themeName]
                                                      toURL:[self URLForUserTheme:newThemeName] error:nil];
    
    if (success) {
        [self updateCache];
    }
    
    return success;
}


//------------------------------------------------------
/// テーマ名に応じたテーマファイルを削除する
- (BOOL)removeTheme:(NSString *)themeName
//------------------------------------------------------
{
    BOOL success = NO;
    NSURL *URL = [self URLForUserTheme:themeName];
    
    if ([URL checkResourceIsReachableAndReturnError:nil]) {
        success = [[NSFileManager defaultManager] removeItemAtURL:URL error:nil];
    }
    
    if (success) {
        [self updateCache];
    }
    
    return success;
}


//------------------------------------------------------
/// 外部テーマファイルをユーザ領域にコピーする
- (BOOL)importTheme:(NSURL *)URL
//------------------------------------------------------
{
    __block BOOL success = NO;
    __block NSError *error = nil;
    NSString *themeName = [[URL lastPathComponent] stringByDeletingPathExtension];
    
    // ユーザ領域にテーマ用ディレクトリがまだない場合は作成する
    if (![self prepareUserThemeDirectory]) {
        return NO;
    }
    
    // ファイルをコピー
    NSFileCoordinator *coordinator = [[NSFileCoordinator alloc] initWithFilePresenter:nil];
    [coordinator coordinateReadingItemAtURL:URL options:NSFileCoordinatorReadingWithoutChanges | NSFileCoordinatorReadingResolvesSymbolicLink
                           writingItemAtURL:[self URLForUserTheme:themeName] options:NSFileCoordinatorWritingForReplacing
                                      error:nil byAccessor:^(NSURL *newReadingURL, NSURL *newWritingURL)
     {
         if ([newWritingURL checkResourceIsReachableAndReturnError:nil]) {
             [[NSFileManager defaultManager] removeItemAtURL:newWritingURL error:&error];
         }
         
         success = [[NSFileManager defaultManager] copyItemAtURL:newReadingURL toURL:newWritingURL error:&error];
     }];
    
    if (error) {
        NSLog(@"Error: %@", [error description]);
    }
    
    if (success) {
        [self updateCache];
    }
    
    return success;
}


//------------------------------------------------------
/// テーマファイルを指定のURLにコピーする
- (BOOL)exportTheme:(NSString *)themeName toURL:(NSURL *)URL
//------------------------------------------------------
{
    __block BOOL success = NO;
    __block NSError *error = nil;
    
    NSFileCoordinator *coordinator = [[NSFileCoordinator alloc] initWithFilePresenter:nil];
    [coordinator coordinateReadingItemAtURL:[self URLForUserTheme:themeName] options:NSFileCoordinatorReadingWithoutChanges
                           writingItemAtURL:URL options:NSFileCoordinatorWritingForMoving
                                      error:nil byAccessor:^(NSURL *newReadingURL, NSURL *newWritingURL)
     {
         if ([newWritingURL checkResourceIsReachableAndReturnError:nil]) {
             [[NSFileManager defaultManager] removeItemAtURL:newWritingURL error:&error];
         }
         
         success = [[NSFileManager defaultManager] copyItemAtURL:newReadingURL toURL:newWritingURL error:&error];
     }];
    
    if (error) {
        NSLog(@"Error: %@", [error description]);
    }
    
    return success;
}


//------------------------------------------------------
/// テーマを複製する
- (BOOL)duplicateTheme:(NSString *)themeName  // TODO:not implemented
//------------------------------------------------------
{
    BOOL success = NO;
    NSString *newThemeName = [themeName stringByAppendingString:NSLocalizedString(@" copy", nil)];
    NSURL *baseURL = nil;
    
    // ユーザ領域にテーマ用ディレクトリがまだない場合は作成する
    if (![self prepareUserThemeDirectory]) {
        return NO;
    }

    // すでに同名のファイルが存在したら数字を追加する
    if ([[self URLForUserTheme:newThemeName] checkResourceIsReachableAndReturnError:nil]) {
        NSString *proposedNewThemeName = newThemeName;
        unsigned long counter = 2;
        while ([[self URLForUserTheme:proposedNewThemeName] checkResourceIsReachableAndReturnError:nil]) {
            proposedNewThemeName = [newThemeName stringByAppendingFormat:@" %li", counter];
            counter++;
        }
        newThemeName = proposedNewThemeName;
    }
    
    success = [[NSFileManager defaultManager] copyItemAtURL:baseURL toURL:[self URLForUserTheme:newThemeName] error:nil];
    
    if (success) {
        [self updateCache];
    }
    
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
    return [[[self userThemeDirectoryURL] URLByAppendingPathComponent:themeName] URLByAppendingPathExtension:@"plist"];
}


//------------------------------------------------------
/// テーマ名からユーザ領域のテーマ定義ファイルのURLを返す
- (NSURL *)URLForBundledTheme:(NSString *)themeName
//------------------------------------------------------
{
    return [[NSBundle mainBundle] URLForResource:themeName withExtension:@"plist" subdirectory:@"Themes"];
}


//------------------------------------------------------
/// 内部で持っているキャッシュ用データを更新
- (void)updateCache
//------------------------------------------------------
{
    NSURL *userDirURL = [self userThemeDirectoryURL];
    
    NSMutableArray *themeNames = [[self bundledThemeNames] mutableCopy];
    
    // ユーザ定義用ディレクトリが存在する場合は読み込む
    if ([userDirURL checkResourceIsReachableAndReturnError:nil]) {
        NSDirectoryEnumerator *enumerator = [[NSFileManager defaultManager] enumeratorAtURL:userDirURL
                                                                 includingPropertiesForKeys:nil
                                                                                    options:NSDirectoryEnumerationSkipsSubdirectoryDescendants | NSDirectoryEnumerationSkipsHiddenFiles
                                                                      errorHandler:^BOOL(NSURL *url, NSError *error) {
                                                                          NSLog(@"%@", [error description]);
                                                                          return YES;
                                                                      }];
        NSURL *URL;
        while (URL = [enumerator nextObject]) {
            [themeNames addObject:[[URL lastPathComponent] stringByDeletingPathExtension]];
        }
    }
    [self setThemeNames:themeNames];

    // 定義をキャッシュする
    NSMutableDictionary *themes = [NSMutableDictionary dictionary];
    for (NSString *name in [self themeNames]) {
        themes[name] = [NSPropertyListSerialization propertyListWithData:[NSData dataWithContentsOfURL:[self URLForUsedTheme:name]]
                                                                 options:NSPropertyListMutableContainersAndLeaves
                                                                  format:NULL
                                                                   error:nil];
    }
    [self setArchivedThemes:themes];
    
    // Notificationを発行
    [[NSNotificationCenter defaultCenter] postNotificationName:CEThemeDidUpdateNotification object:self];
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
        NSColor *color = [NSUnarchiver unarchiveObjectWithData:[[NSUserDefaults standardUserDefaults] dataForKey:classicKey]];
        
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
        [self saveTheme:theme name:themeName];
        // カスタマイズされたテーマを選択
        [[NSUserDefaults standardUserDefaults] setObject:themeName forKey:k_key_defaultTheme];
    }
}



# pragma mark Private Methods

//------------------------------------------------------
/// CotEditor 1.5までで使用されていたデフォルトテーマ
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
