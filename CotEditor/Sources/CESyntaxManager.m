/*
 ==============================================================================
 CESyntaxManager
 
 CotEditor
 http://coteditor.com
 
 Created on 2004-12-24 by nakamuxu
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

#import <YAML-Framework/YAMLSerialization.h>
#import "CESyntaxManager.h"
#import "CEAppDelegate.h"
#import "RegexKitLite.h"
#import "constants.h"


// notifications
NSString *const CESyntaxListDidUpdateNotification = @"CESyntaxListDidUpdateNotification";
NSString *const CESyntaxDidUpdateNotification = @"CESyntaxDidUpdateNotification";

// keys for validation result
NSString *const CESyntaxValidationTypeKey = @"SyntaxTypeKey";
NSString *const CESyntaxValidationRoleKey = @"RoleKey";
NSString *const CESyntaxValidationStringKey = @"StringKey";
NSString *const CESyntaxValidationMessageKey = @"MessageKey";


@interface CESyntaxManager ()

@property (nonatomic) NSMutableDictionary *styleCaches;  // カラーリング定義のキャッシュ (values are NSMutableDictonary)
@property (nonatomic, copy) NSArray *bundledStyleNames;  // バンドルされているシンタックススタイル名の配列
@property (nonatomic, copy) NSDictionary *bundledExtensionTable;
@property (nonatomic, copy) NSDictionary *bundledFilenameTable;
@property (nonatomic, copy) NSDictionary *extensionTable;
@property (nonatomic, copy) NSDictionary *filenameTable;
@property (nonatomic, copy) NSDictionary *extensionToStyleTable;  // 拡張子<->styleファイルの変換テーブル辞書(key = 拡張子)
@property (nonatomic, copy) NSDictionary *filenameToStyleTable;


// readonly
@property (readwrite, nonatomic, copy) NSArray *styleNames;
@property (readwrite, nonatomic, copy) NSDictionary *extensionConflicts;
@property (readwrite, nonatomic, copy) NSDictionary *filenameConflicts;

@end




#pragma mark -

@implementation CESyntaxManager

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
        _styleCaches = [NSMutableDictionary dictionary];
        
        // バンドルされているstyle定義の一覧を読み込んでおく
        NSURL *extensionTableURL = [[NSBundle mainBundle] URLForResource:@"ExtensionTable"
                                                           withExtension:@"plist"
                                                            subdirectory:@"SyntaxTables"];
        NSURL *filenameTableURL = [[NSBundle mainBundle] URLForResource:@"FilenameTable"
                                                          withExtension:@"plist"
                                                           subdirectory:@"SyntaxTables"];
        _bundledExtensionTable = [NSDictionary dictionaryWithContentsOfURL:extensionTableURL];
        _bundledFilenameTable = [NSDictionary dictionaryWithContentsOfURL:filenameTableURL];
        _bundledStyleNames = [_bundledExtensionTable allKeys];
        
        // cache user styles asynchronously but wait until the process will be done
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
// Public method
//
//=======================================================

// ------------------------------------------------------
/// ファイル名に応じたstyle名を返す
- (NSString *)styleNameFromFileName:(NSString *)fileName
// ------------------------------------------------------
{
    NSString *styleName = [self filenameToStyleTable][fileName];
    
    styleName = styleName ? : [self extensionToStyleTable][[fileName pathExtension]];
    styleName = styleName ? : [[NSUserDefaults standardUserDefaults] stringForKey:CEDefaultSyntaxStyleKey];
    
    return styleName;
}


// ------------------------------------------------------
/// style名に応じたデフォルト拡張子を返す
- (NSString *)defaultExensionWithStyleName:(NSString *)styleName
// ------------------------------------------------------
{
    NSArray *extensions = [self styleWithStyleName:styleName][CESyntaxExtensionsKey];
    
    return ([extensions count] > 0) ? (NSString *)extensions[0][CESyntaxKeyStringKey] : nil;
}


// ------------------------------------------------------
/// style名に応じたstyle辞書を返す
- (NSDictionary *)styleWithStyleName:(NSString *)styleName
// ------------------------------------------------------
{
    NSDictionary *style;
    
    if (![styleName isEqualToString:@""] && ![styleName isEqualToString:NSLocalizedString(@"None", nil)]) {
        style = [self styleCaches][styleName] ? : [self styleDictWithURL:[self URLForUsedStyle:styleName]];
        
        /// 新たに読み込んだ場合はキャッシュする
        if (![self styleCaches][styleName] && style) {
            [self styleCaches][styleName] = style;
        }
    }
    
    return style ? : [self emptyStyle];  // 存在しない場合は空のデータを返す
}


// ------------------------------------------------------
/// style名に応じたバンドル版のstyle辞書を返す（ない場合はnil）
- (NSDictionary *)bundledStyleWithStyleName:(NSString *)styleName
// ------------------------------------------------------
{
    return [self styleDictWithURL:[self URLForBundledStyle:styleName]];
}


// ------------------------------------------------------
/// あるスタイルネームがデフォルトで用意されているものかどうかを返す
- (BOOL)isBundledStyle:(NSString *)styleName
// ------------------------------------------------------
{
    return [[self bundledStyleNames] containsObject:styleName];
}


// ------------------------------------------------------
/// スタイルがバンドル版スタイルと同じ内容かどうかを返す
- (BOOL)isEqualToBundledStyle:(NSDictionary *)style name:(NSString *)styleName
// ------------------------------------------------------
{
    if (![self isBundledStyle:styleName]) { return NO; }
    
    // numOfObjInArray などが混入しないようにスタイル定義部分だけを比較する
    NSArray *keys = [[self emptyStyle] allKeys];
    NSDictionary *bundledStyle = [[self bundledStyleWithStyleName:styleName] dictionaryWithValuesForKeys:keys];
    
    return [[style dictionaryWithValuesForKeys:keys] isEqualToDictionary:bundledStyle];
}


//------------------------------------------------------
/// ある名前を持つstyleファイルがstyle保存ディレクトリにあるかどうかを返す
- (BOOL)existsStyleFileWithStyleName:(NSString *)styleName
//------------------------------------------------------
{
    return [[self URLForUserStyle:styleName] checkResourceIsReachableAndReturnError:nil];
}


//------------------------------------------------------
/// 外部styleファイルをユーザ領域にコピーする
- (BOOL)importStyleFromURL:(NSURL *)fileURL
//------------------------------------------------------
{
    if ([[fileURL pathExtension] isEqualToString:@"plist"]) {
        return [self importLegacyStyleFromURL:fileURL];
    }
    
    NSURL *destURL = [[self userStyleDirectoryURL] URLByAppendingPathComponent:[fileURL lastPathComponent]];
    
    // ユーザ領域にシンタックス定義用ディレクトリがまだない場合は作成する
    if (![self prepareUserStyleDirectory]) {
        return NO;
    }
    
    __block BOOL success = NO;
    __block NSError *error = nil;
    NSFileCoordinator *coordinator = [[NSFileCoordinator alloc] initWithFilePresenter:nil];
    [coordinator coordinateReadingItemAtURL:fileURL options:NSFileCoordinatorReadingWithoutChanges
                           writingItemAtURL:destURL options:NSFileCoordinatorWritingForReplacing
                                      error:&error
                                 byAccessor:^(NSURL *newReadingURL, NSURL *newWritingURL)
     {
         if ([newWritingURL checkResourceIsReachableAndReturnError:nil]) {
             [[NSFileManager defaultManager] removeItemAtURL:newWritingURL error:nil];
         }
         success = [[NSFileManager defaultManager] copyItemAtURL:newReadingURL toURL:newWritingURL error:&error];
     }];
    
    if (error) {
        NSLog(@"Error: %@", [error description]);
    }
    
    if (success) {
        // 内部で持っているキャッシュ用データを更新
        [[self styleCaches] removeObjectForKey:[self styleNameFromURL:fileURL]];
        [self updateCacheWithCompletionHandler:nil];
    }
    
    return success;
}


//------------------------------------------------------
/// styleファイルを指定のURLにコピーする
- (BOOL)exportStyle:(NSString *)styleName toURL:(NSURL *)fileURL
//------------------------------------------------------
{
    NSURL *sourceURL = [self URLForUsedStyle:styleName];
    
    __block BOOL success = NO;
    __block NSError *error = nil;
    NSFileCoordinator *coordinator = [[NSFileCoordinator alloc] initWithFilePresenter:nil];
    [coordinator coordinateReadingItemAtURL:sourceURL options:NSFileCoordinatorReadingWithoutChanges
                           writingItemAtURL:fileURL options:NSFileCoordinatorWritingForReplacing
                                      error:&error
                                 byAccessor:^(NSURL *newReadingURL, NSURL *newWritingURL)
     {
         if ([newWritingURL checkResourceIsReachableAndReturnError:nil]) {
             [[NSFileManager defaultManager] removeItemAtURL:newWritingURL error:nil];
         }
         success = [[NSFileManager defaultManager] copyItemAtURL:newReadingURL toURL:newWritingURL error:&error];
     }];
    
    if (error) {
        NSLog(@"Error: %@", [error description]);
    }
    
    return success;
}


//------------------------------------------------------
/// style名に応じたstyleファイルを削除する
- (BOOL)removeStyleFileWithStyleName:(NSString *)styleName
//------------------------------------------------------
{
    BOOL success = NO;
    if ([styleName length] < 1) { return success; }
    NSURL *URL = [self URLForUserStyle:styleName];

    if ([URL checkResourceIsReachableAndReturnError:nil]) {
        success = [[NSFileManager defaultManager] removeItemAtURL:URL error:nil];
        if (success) {
            // 内部で持っているキャッシュ用データを更新
            [[self styleCaches] removeObjectForKey:styleName];
            __weak typeof(self) weakSelf = self;
            [self updateCacheWithCompletionHandler:^{
                typeof(self) strongSelf = weakSelf;
                [[NSNotificationCenter defaultCenter] postNotificationName:CESyntaxDidUpdateNotification
                                                                    object:strongSelf
                                                                  userInfo:@{CEOldNameKey: styleName,
                                                                             CENewNameKey: NSLocalizedString(@"None", nil)}];
            }];
        } else {
            NSLog(@"Error. Could not remove \"%@\".", URL);
        }
    } else {
        NSLog(@"Error. Could not be found \"%@\" for remove.", URL);
    }
    return success;
}


//------------------------------------------------------
/// マッピング重複エラーがあるかどうかを返す
- (BOOL)existsMappingConflict
//------------------------------------------------------
{
    return (([[self extensionConflicts] count] > 0) || ([[self filenameConflicts] count] > 0));
}


//------------------------------------------------------
/// コピーされたstyle名を返す
- (NSString *)copiedStyleName:(NSString *)originalName
//------------------------------------------------------
{
    NSString *baseName = [originalName stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
    BOOL copiedState = NO;
    
    NSRegularExpression *regex = [NSRegularExpression regularExpressionWithPattern:NSLocalizedString(@" copy$", nil)
                                                                           options:0 error:nil];
    NSRange copiedStrRange = [regex rangeOfFirstMatchInString:baseName options:0 range:NSMakeRange(0, [baseName length])];
    if (copiedStrRange.location != NSNotFound) {
        copiedState = YES;
    } else {
        regex = [NSRegularExpression regularExpressionWithPattern:NSLocalizedString(@" copy [0-9]+$", nil) options:0 error:nil];
        copiedStrRange = [regex rangeOfFirstMatchInString:baseName options:0 range:NSMakeRange(0, [baseName length])];
        if (copiedStrRange.location != NSNotFound) {
            copiedState = YES;
        }
    }
    NSString *copyString;
    if (copiedState) {
        copyString = [NSString stringWithFormat:@"%@%@",
                      [baseName substringWithRange:NSMakeRange(0, copiedStrRange.location)],
                      NSLocalizedString(@" copy", nil)];
    } else {
        copyString = [NSString stringWithFormat:@"%@%@", baseName, NSLocalizedString(@" copy", nil)];
    }
    NSMutableString *copiedStyleName = [copyString mutableCopy];
    NSUInteger i = 2;
    while ([[self styleNames] containsObject:copiedStyleName]) {
        [copiedStyleName setString:[NSString stringWithFormat:@"%@ %tu", copyString, i]];
        i++;
    }
    return copiedStyleName;
}


//------------------------------------------------------
/// styleのファイルへの保存
- (void)saveStyle:(NSMutableDictionary *)style name:(NSString *)name oldName:(NSString *)oldName
//------------------------------------------------------
{
    if ([name length] == 0) { return; }
    
    // sanitize
    [(NSMutableArray *)style[CESyntaxExtensionsKey] removeObject:@{}];
    [(NSMutableArray *)style[CESyntaxFileNamesKey] removeObject:@{}];
    
    // sort
    NSArray *descriptors = @[[NSSortDescriptor sortDescriptorWithKey:CESyntaxBeginStringKey
                                                           ascending:YES
                                                            selector:@selector(caseInsensitiveCompare:)],
                             [NSSortDescriptor sortDescriptorWithKey:CESyntaxKeyStringKey
                                                           ascending:YES
                                                            selector:@selector(caseInsensitiveCompare:)]];
    
    NSMutableArray *syntaxDictKeys = [NSMutableArray array];
    for (NSUInteger i = 0; i < kSizeOfAllColoringKeys; i++) {
        [syntaxDictKeys addObject:kAllColoringKeys[i]];
    }
    [syntaxDictKeys addObjectsFromArray:@[CESyntaxOutlineMenuKey,
                                          CESyntaxCompletionsKey]];
    
    for (NSString *key in syntaxDictKeys) {
        [style[key] sortUsingDescriptors:descriptors];
    }
    
    // ユーザ領域にシンタックス定義用ディレクトリがまだない場合は作成する
    if (![self prepareUserStyleDirectory]) {
        return;
    }
    
    // save
    NSURL *saveURL = [self URLForUserStyle:name];
    // style名が変更されたときは、古いファイルを削除する
    if (![name isEqualToString:oldName]) {
        [[NSFileManager defaultManager] removeItemAtURL:[self URLForUserStyle:oldName] error:nil];
    }
    // 保存しようとしている定義がバンドル版と同じだった場合（出荷時に戻したときなど）はユーザ領域のファイルを削除して終わる
    if ([style isEqualToDictionary:[self bundledStyleWithStyleName:name]]) {
        if ([saveURL checkResourceIsReachableAndReturnError:nil]) {
            [[NSFileManager defaultManager] removeItemAtURL:saveURL error:nil];
        }
    } else {
        // 保存
        NSData *yamlData = [YAMLSerialization YAMLDataWithObject:style
                                                         options:kYAMLWriteOptionSingleDocument
                                                           error:nil];
        [yamlData writeToURL:saveURL atomically:YES];
    }
    
    // 内部で持っているキャッシュ用データを更新
    [[self styleCaches] removeObjectForKey:name];
    __weak typeof(self) weakSelf = self;
    [self updateCacheWithCompletionHandler:^{
        typeof(self) strongSelf = weakSelf;
        
        // notify
        [[NSNotificationCenter defaultCenter] postNotificationName:CESyntaxDidUpdateNotification
                                                            object:strongSelf
                                                          userInfo:@{CEOldNameKey: oldName,
                                                                     CENewNameKey: name}];
    }];
}


// ------------------------------------------------------
/// 正規表現構文と重複のチェック実行をしてエラーメッセージ(NSDictionary)のArrayを返す
- (NSArray *)validateSyntax:(NSDictionary *)style
// ------------------------------------------------------
{
    NSMutableArray *results = [NSMutableArray array];
    NSString *tmpBeginStr = nil, *tmpEndStr = nil;
    NSError *error = nil;
    
    NSMutableArray *syntaxDictKeys = [[NSMutableArray alloc] initWithCapacity:(kSizeOfAllColoringKeys + 1)];
    for (NSUInteger i = 0; i < kSizeOfAllColoringKeys; i++) {
        [syntaxDictKeys addObject:kAllColoringKeys[i]];
    }
    [syntaxDictKeys addObject:CESyntaxOutlineMenuKey];
    
    for (NSString *key in syntaxDictKeys) {
        for (NSDictionary *dict in style[key]) {
            NSString *beginStr = dict[CESyntaxBeginStringKey];
            NSString *endStr = dict[CESyntaxEndStringKey];
            
            if ([tmpBeginStr isEqualToString:beginStr] &&
                ((!tmpEndStr && !endStr) || [tmpEndStr isEqualToString:endStr])) {
                [results addObject:@{CESyntaxValidationTypeKey: NSLocalizedString(key, nil),
                                     CESyntaxValidationRoleKey: NSLocalizedString(@"Begin string", nil),
                                     CESyntaxValidationStringKey: beginStr,
                                     CESyntaxValidationMessageKey: NSLocalizedString(@"multiple registered.", nil)}];
                
            } else if ([dict[CESyntaxRegularExpressionKey] boolValue]) {
                if ([beginStr captureCountWithOptions:RKLNoOptions error:&error] == -1) { // エラーのとき
                    NSString *message = [NSString stringWithFormat:NSLocalizedString(@"Error “%@” in column %@: %@<<HERE>>%@", nil),
                                         [error userInfo][RKLICURegexErrorNameErrorKey],
                                         [error userInfo][RKLICURegexOffsetErrorKey],
                                         [error userInfo][RKLICURegexPreContextErrorKey],
                                         [error userInfo][RKLICURegexPostContextErrorKey]];
                    [results addObject:@{CESyntaxValidationTypeKey: NSLocalizedString(key, nil),
                                         CESyntaxValidationRoleKey: NSLocalizedString(@"Begin string", nil),
                                         CESyntaxValidationStringKey: beginStr,
                                         CESyntaxValidationMessageKey: message}];
                }
                if (endStr) {
                    if ([endStr captureCountWithOptions:RKLNoOptions error:&error] == -1) { // エラーのとき
                        NSString *message = [NSString stringWithFormat:NSLocalizedString(@"Error “%@” in column %@: %@<<HERE>>%@", nil),
                                             [error userInfo][RKLICURegexErrorNameErrorKey],
                                             [error userInfo][RKLICURegexOffsetErrorKey],
                                             [error userInfo][RKLICURegexPreContextErrorKey],
                                             [error userInfo][RKLICURegexPostContextErrorKey]];
                        [results addObject:@{CESyntaxValidationTypeKey: NSLocalizedString(key, nil),
                                             CESyntaxValidationRoleKey: NSLocalizedString(@"End string", nil),
                                             CESyntaxValidationStringKey: endStr,
                                             CESyntaxValidationMessageKey: message}];
                    }
                }
                
            } else if ([key isEqualToString:CESyntaxOutlineMenuKey]) {
                error = nil;
                [NSRegularExpression regularExpressionWithPattern:beginStr options:0 error:&error];
                if (error) {
                    [results addObject:@{CESyntaxValidationTypeKey: NSLocalizedString(key, nil),
                                         CESyntaxValidationRoleKey: NSLocalizedString(@"RE string", nil),
                                         CESyntaxValidationStringKey: beginStr,
                                         CESyntaxValidationMessageKey: [NSString stringWithFormat:NSLocalizedString(@"Regex Error: %@", nil),
                                                      [error localizedFailureReason]]}];
                }
            }
            tmpBeginStr = beginStr;
            tmpEndStr = endStr;
        }
    }
    
    // validate block comment delimiter pair
    NSString *beginDelimiter = style[CESyntaxCommentDelimitersKey][CESyntaxBeginCommentKey];
    NSString *endDelimiter = style[CESyntaxCommentDelimitersKey][CESyntaxEndCommentKey];
    if (([beginDelimiter length] >  0 && [endDelimiter length] == 0) ||
        ([beginDelimiter length] == 0 && [endDelimiter length] >  0))
    {
        NSString *role = ([beginDelimiter length] > 0) ? @"Begin string" : @"End string";
        [results addObject:@{CESyntaxValidationTypeKey: NSLocalizedString(@"comment", nil),
                             CESyntaxValidationRoleKey: NSLocalizedString(role, nil),
                             CESyntaxValidationStringKey: ([beginDelimiter length] > 0) ? beginDelimiter : endDelimiter,
                             CESyntaxValidationMessageKey: NSLocalizedString(@"Block comment needs both begin delimiter and end delimiter.", nil)}];
    }
    
    return results;
}


//------------------------------------------------------
/// 空の新規styleを返す
- (NSDictionary *)emptyStyle
//------------------------------------------------------
{
    return @{CESyntaxMetadataKey: [NSMutableDictionary dictionary],
             CESyntaxExtensionsKey: [NSMutableArray array],
             CESyntaxFileNamesKey: [NSMutableArray array],
             CESyntaxKeywordsKey: [NSMutableArray array],
             CESyntaxCommandsKey: [NSMutableArray array],
             CESyntaxTypesKey: [NSMutableArray array],
             CESyntaxAttributesKey: [NSMutableArray array],
             CESyntaxVariablesKey: [NSMutableArray array],
             CESyntaxValuesKey: [NSMutableArray array],
             CESyntaxNumbersKey: [NSMutableArray array],
             CESyntaxStringsKey: [NSMutableArray array],
             CESyntaxCharactersKey: [NSMutableArray array],
             CESyntaxCommentsKey: [NSMutableArray array],
             CESyntaxOutlineMenuKey: [NSMutableArray array],
             CESyntaxCompletionsKey: [NSMutableArray array],
             CESyntaxCommentDelimitersKey: [NSMutableDictionary dictionary]};
}



#pragma mark Private Mthods

//=======================================================
// Private method
//
//=======================================================

//------------------------------------------------------
/// スタイルファイルの URL からスタイル名を返す
- (NSString *)styleNameFromURL:(NSURL *)fileURL
//------------------------------------------------------
{
    return [[fileURL lastPathComponent] stringByDeletingPathExtension];
}


//------------------------------------------------------
/// Application Support内のstyleデータファイル保存ディレクトリ
- (NSURL *)userStyleDirectoryURL
//------------------------------------------------------
{
    return [[(CEAppDelegate *)[NSApp delegate] supportDirectoryURL] URLByAppendingPathComponent:@"Syntaxes"];
}


//------------------------------------------------------
/// ユーザ領域のテーマ保存用ディレクトリの存在をチェックし、ない場合は作成する
- (BOOL)prepareUserStyleDirectory
//------------------------------------------------------
{
    BOOL success = NO;
    NSError *error = nil;
    NSURL *URL = [self userStyleDirectoryURL];
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
/// style名から有効なstyle定義ファイルのURLを返す
- (NSURL *)URLForUsedStyle:(NSString *)styleName
//------------------------------------------------------
{
    NSURL *URL = [self URLForUserStyle:styleName];
    
    if (![URL checkResourceIsReachableAndReturnError:nil]) {
        URL = [self URLForBundledStyle:styleName];
    }
    
    return [URL checkResourceIsReachableAndReturnError:nil] ? URL : nil;
}


//------------------------------------------------------
/// style名からバンドル領域のstyle定義ファイルのURLを返す
- (NSURL *)URLForBundledStyle:(NSString *)styleName
//------------------------------------------------------
{
    return [[NSBundle mainBundle] URLForResource:styleName withExtension:@"yaml" subdirectory:@"Syntaxes"];
}


//------------------------------------------------------
/// style名からユーザ領域のstyle定義ファイルのURLを返す
- (NSURL *)URLForUserStyle:(NSString *)styleName
//------------------------------------------------------
{
    return [[[self userStyleDirectoryURL] URLByAppendingPathComponent:styleName] URLByAppendingPathExtension:@"yaml"];
}


//------------------------------------------------------
/// URLからテーマ辞書を返す
- (NSMutableDictionary *)styleDictWithURL:(NSURL *)URL
//------------------------------------------------------
{
    NSData *yamlData = [NSData dataWithContentsOfURL:URL];
    
    return [YAMLSerialization objectWithYAMLData:yamlData
                                         options:kYAMLReadOptionMutableContainersAndLeaves
                                           error:nil];
}


// ------------------------------------------------------
/// 内部で持っているキャッシュ用データを更新
- (void)updateCacheWithCompletionHandler:(void (^)())completionHandler
// ------------------------------------------------------
{
    __weak typeof(self) weakSelf = self;
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        typeof(self) strongSelf = weakSelf;
        [strongSelf updateStyleTables];
        [strongSelf setupExtensionAndSyntaxTable];
        
        dispatch_sync(dispatch_get_main_queue(), ^{
            // Notificationを発行
            [[NSNotificationCenter defaultCenter] postNotificationName:CESyntaxListDidUpdateNotification
                                                                object:strongSelf];
            
            if (completionHandler) {
                completionHandler();
            }
        });
    });
}


//------------------------------------------------------
/// styleのファイルからのセットアップと読み込み
- (void)cacheStyles
//------------------------------------------------------
{
    NSURL *dirURL = [self userStyleDirectoryURL]; // ユーザディレクトリパス取得
    NSMutableOrderedSet *styleNameSet = [NSMutableOrderedSet orderedSetWithArray:[self bundledStyleNames]];
    
    // ユーザ定義用ディレクトリが存在する場合は読み込む
    if ([dirURL checkResourceIsReachableAndReturnError:nil]) {
        NSArray *URLs = [[NSFileManager defaultManager] contentsOfDirectoryAtURL:dirURL
                                                      includingPropertiesForKeys:nil
                                                                         options:NSDirectoryEnumerationSkipsSubdirectoryDescendants | NSDirectoryEnumerationSkipsHiddenFiles
                                                                           error:nil];
        for (NSURL *URL in URLs) {
            if (![@[@"yaml", @"yml"] containsObject:[URL pathExtension]]) { continue; }
            
            NSString *styleName = [self styleNameFromURL:URL];
            [styleNameSet addObject:styleName];
        }
    }
    
    // 定義をアルファベット順にソートする
    [styleNameSet sortUsingComparator:^NSComparisonResult(NSString *name1, NSString *name2) {
        return [name1 caseInsensitiveCompare:name2];
    }];
    
    // 定義をキャッシュする
    NSMutableDictionary *styles = [NSMutableDictionary dictionary];
    for (NSString *styleName in styleNameSet) {
        NSURL *URL = [self URLForUsedStyle:styleName];
        NSMutableDictionary *style = [self styleDictWithURL:URL];
        
        // URLが無効だった場合などに、dictがnilになる場合がある
        if (!style) { continue; }
        
        styles[styleName] = style;
    }
    
    [self setStyleNames:[styleNameSet array]];
    [self setStyleCaches:styles];
}


//------------------------------------------------------
///
- (void)updateStyleTables
//------------------------------------------------------
{
    NSURL *dirURL = [self userStyleDirectoryURL]; // ユーザディレクトリパス取得
    NSMutableDictionary *extensionTable = [[self bundledExtensionTable] mutableCopy];
    NSMutableDictionary *filenameTable = [[self bundledFilenameTable] mutableCopy];
    
    // ユーザ定義用ディレクトリが存在する場合は読み込む
    if ([dirURL checkResourceIsReachableAndReturnError:nil]) {
        NSArray *URLs = [[NSFileManager defaultManager] contentsOfDirectoryAtURL:dirURL
                                                      includingPropertiesForKeys:nil
                                                                         options:NSDirectoryEnumerationSkipsSubdirectoryDescendants | NSDirectoryEnumerationSkipsHiddenFiles
                                                                           error:nil];
        for (NSURL *URL in URLs) {
            if (![@[@"yaml", @"yml"] containsObject:[URL pathExtension]]) { continue; }
            
            NSString *styleName = [self styleNameFromURL:URL];
            NSDictionary *style = [self styleDictWithURL:URL];
            
            // URLが無効だった場合などに、dictがnilになる場合がある
            if (!style) { continue; }
            
            extensionTable[styleName] = [self keyStringsFromDicts:style[CESyntaxExtensionsKey]];
            filenameTable[styleName] = [self keyStringsFromDicts:style[CESyntaxFileNamesKey]];
        }
    }
    
    [self setExtensionTable:extensionTable];
    [self setFilenameTable:filenameTable];
    
    // 定義をアルファベット順にソートする
    NSMutableArray *styleNames = [[extensionTable allKeys] mutableCopy];
    [styleNames sortUsingComparator:^NSComparisonResult(NSString *name1, NSString *name2) {
        return [name1 caseInsensitiveCompare:name2];
    }];
    [self setStyleNames:styleNames];
}


// ------------------------------------------------------
/// 拡張子<->styleファイルの変換テーブル辞書(key = 拡張子)と、拡張子辞書、拡張子重複エラー辞書を更新
- (void)setupExtensionAndSyntaxTable
// ------------------------------------------------------
{
    NSMutableDictionary *extensionTable = [NSMutableDictionary dictionary];
    NSMutableDictionary *extensionConflicts = [NSMutableDictionary dictionary];
    NSMutableDictionary *filenameTable = [NSMutableDictionary dictionary];
    NSMutableDictionary *filenameConflicts = [NSMutableDictionary dictionary];
    NSString *addedName = nil;
    
    for (NSString *styleName in [self styleNames]) {
        for (NSString *extension in [self extensionTable][styleName]) {
            if ((addedName = extensionTable[extension])) { // 同じ拡張子を持つものがすでにあるとき
                NSMutableArray *errors = extensionConflicts[extension];
                if (!errors) {
                    errors = [NSMutableArray array];
                    [extensionConflicts setValue:errors forKey:extension];
                }
                if (![errors containsObject:addedName]) {
                    [errors addObject:addedName];
                }
                [errors addObject:styleName];
            } else {
                [extensionTable setValue:styleName forKey:extension];
            }
        }
        
        for (NSString *filename in [self extensionTable][styleName]) {
            if ((addedName = filenameTable[filename])) { // 同じファイル名を持つものがすでにあるとき
                NSMutableArray *errors = filenameConflicts[filename];
                if (!errors) {
                    errors = [NSMutableArray array];
                    [filenameConflicts setValue:errors forKey:filename];
                }
                if (![errors containsObject:addedName]) {
                    [errors addObject:addedName];
                }
                [errors addObject:styleName];
            } else {
                [filenameTable setValue:styleName forKey:filename];
            }
        }
    }
    [self setExtensionToStyleTable:extensionTable];
    [self setExtensionConflicts:extensionConflicts];
    [self setFilenameToStyleTable:filenameTable];
    [self setFilenameConflicts:filenameConflicts];
}


// ------------------------------------------------------
/// 辞書の array から keyString をキーに持つ string を集めて返す
- (NSArray *)keyStringsFromDicts:(NSArray *)dicts
// ------------------------------------------------------
{
    NSMutableArray *strings = [NSMutableArray array];
    
    for (NSDictionary *dict in dicts) {
        [strings addObject:dict[CESyntaxKeyStringKey]];
    }
    
    return [strings copy];
}

@end




#pragma mark -

@implementation CESyntaxManager (Migration)

// ------------------------------------------------------
/// CotEditor 1.x から CotEdito 2.0 への移行
- (void)migrateStylesWithCompletionHandler:(void (^)(BOOL success))completionHandler;
// ------------------------------------------------------
{
    BOOL success = NO;
    NSURL *oldDirURL = [[(CEAppDelegate *)[NSApp delegate] supportDirectoryURL] URLByAppendingPathComponent:@"SyntaxColorings"];
    
    // 移行の必要性チェック
    if (![oldDirURL checkResourceIsReachableAndReturnError:nil] ||
        [[self userStyleDirectoryURL] checkResourceIsReachableAndReturnError:nil])
    {
        completionHandler(NO);
        return;
    }
    
    [self prepareUserStyleDirectory];
    
    NSArray *URLs = [[NSFileManager defaultManager] contentsOfDirectoryAtURL:oldDirURL
                                                  includingPropertiesForKeys:nil
                                                                     options:NSDirectoryEnumerationSkipsSubdirectoryDescendants | NSDirectoryEnumerationSkipsHiddenFiles
                                                                       error:nil];
    
    for (NSURL *URL in URLs) {
        if ([self importLegacyStyleFromURL:URL]) {
            success = YES;
        }
    }
    
    if (success) {
        [self updateCacheWithCompletionHandler:^{
            completionHandler(YES);
        }];
    } else {
        completionHandler(NO);
    }
}


// ------------------------------------------------------
/// plist 形式のシンタックス定義を YAML 形式に変換してユーザ領域に保存
- (BOOL)importLegacyStyleFromURL:(NSURL *)fileURL
// ------------------------------------------------------
{
    if (![[fileURL pathExtension] isEqualToString:@"plist"]) { return NO; }

    __block BOOL success = NO;
    NSString *styleName = [self styleNameFromURL:fileURL];
    NSURL *destURL = [self URLForUserStyle:styleName];
    
    NSFileCoordinator *coordinator = [[NSFileCoordinator alloc] initWithFilePresenter:nil];
    [coordinator coordinateReadingItemAtURL:fileURL options:NSFileCoordinatorReadingWithoutChanges
                           writingItemAtURL:destURL options:NULL
                                      error:nil byAccessor:^(NSURL *newReadingURL, NSURL *newWritingURL)
     {
         NSDictionary *style = [NSDictionary dictionaryWithContentsOfURL:fileURL];
         
         if (!style) { return; }
         
         NSMutableDictionary *newStyle = [NSMutableDictionary dictionary];
         
         // format migration
         for (NSString *key in style) {
             // remove lagacy "styleName" key
             if ([key isEqualToString:@"styleName"]) { continue; }
             
             // remove all `Array` suffix from dict keys
             NSString *newKey = [key stringByReplacingOccurrencesOfString:@"Array" withString:@""];
             newStyle[newKey] = style[key];
         }
         
         NSData *yamlData = [YAMLSerialization YAMLDataWithObject:newStyle
                                                          options:kYAMLWriteOptionSingleDocument
                                                            error:nil];
         success = [yamlData writeToURL:destURL atomically:YES];
     }];
    
    return success;
}

@end
