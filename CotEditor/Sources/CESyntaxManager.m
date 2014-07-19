/*
=================================================
CESyntaxManager
(for CotEditor)

 Copyright (C) 2004-2007 nakamuxu.
 Copyright (C) 2014 CotEditor Project
 http://coteditor.github.io
=================================================

encoding="UTF-8"
Created:2004.12.24
 
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

#import "CESyntaxManager.h"
#import "RegexKitLite.h"
#import "constants.h"


// notifications
NSString *const CESyntaxListDidUpdateNotification = @"CESyntaxListDidUpdateNotification";
NSString *const CESyntaxDidUpdateNotification = @"CESyntaxDidUpdateNotification";


@interface CESyntaxManager ()

@property (nonatomic, copy) NSArray *styles;  // 全てのカラーリング定義 (array of NSMutableDictonary)
@property (nonatomic, copy) NSArray *bundledStyleNames;  // バンドルされているシンタックススタイル名の配列
@property (nonatomic, copy) NSDictionary *extensionToStyleTable;  // 拡張子<->styleファイルの変換テーブル辞書(key = 拡張子)
@property (nonatomic, copy) NSDictionary *filenameToStyleTable;


// readonly
@property (nonatomic, copy, readwrite) NSDictionary *extensionConflicts;
@property (nonatomic, copy, readwrite) NSDictionary *filenameConflicts;

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
        // バンドルされているstyle定義の名前を読み込んでおく
        NSArray *URLs = [[NSBundle mainBundle] URLsForResourcesWithExtension:@"plist" subdirectory:@"SyntaxColorings"];
        NSMutableArray *styleNames = [NSMutableArray array];
        for (NSURL *URL in URLs) {
            [styleNames addObject:[[URL lastPathComponent] stringByDeletingPathExtension]];
        }
        [self setBundledStyleNames:styleNames];
        
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
/// スタイル名配列を返す
- (NSArray *)styleNames
// ------------------------------------------------------
{
    NSMutableArray *styleNames = [NSMutableArray array];
    
    for (NSDictionary *style in [self styles]) {
        [styleNames addObject:style[k_SCKey_styleName]];
    }
    
    return styleNames;
}


// ------------------------------------------------------
/// ファイル名に応じたstyle名を返す
- (NSString *)styleNameFromFileName:(NSString *)fileName
// ------------------------------------------------------
{
    NSString *styleName = [self filenameToStyleTable][fileName];
    
    styleName = styleName ? : [self extensionToStyleTable][[fileName pathExtension]];
    styleName = styleName ? : [[NSUserDefaults standardUserDefaults] stringForKey:k_key_defaultColoringStyleName];
    
    return styleName;
}


// ------------------------------------------------------
/// style名に応じたstyle辞書を返す
- (NSDictionary *)styleWithStyleName:(NSString *)styleName
// ------------------------------------------------------
{
    if (![styleName isEqualToString:@""] && ![styleName isEqualToString:NSLocalizedString(@"None", nil)]) {
        for (NSDictionary *style in [self styles]) {
            if ([style[k_SCKey_styleName] isEqualToString:styleName]) {
                NSMutableDictionary *styleToReturn = [style mutableCopy];
                
                NSMutableArray *syntaxDictKeys = [[NSMutableArray alloc] initWithCapacity:k_size_of_allColoringArrays];
                for (NSUInteger i = 0; i < k_size_of_allColoringArrays; i++) {
                    [syntaxDictKeys addObject:k_SCKey_allColoringArrays[i]];
                }
                
                NSUInteger count = 0;
                for (NSString *key in syntaxDictKeys) {
                    count += [(NSArray *)styleToReturn[key] count];
                }
                styleToReturn[k_SCKey_numOfObjInArray] = @(count);
                
                return styleToReturn;
            }
        }
    }
    // 空のデータを返す
    return [self emptyStyle];
}


// ------------------------------------------------------
/// style名に応じたバンドル版のstyle辞書を返す（ない場合はnil）
- (NSDictionary *)bundledStyleWithStyleName:(NSString *)styleName
// ------------------------------------------------------
{
    return [NSMutableDictionary dictionaryWithContentsOfURL:[self URLForBundledStyle:styleName]];
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
         NSFileManager *fileManager = [[NSFileManager alloc] init];
         
         if ([newWritingURL checkResourceIsReachableAndReturnError:nil]) {
             [fileManager removeItemAtURL:newWritingURL error:nil];
         }
         success = [fileManager copyItemAtURL:newReadingURL toURL:newWritingURL error:&error];
     }];
    
    if (error) {
        NSLog(@"Error: %@", [error description]);
    }
    
    if (success) {
        // 内部で持っているキャッシュ用データを更新
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
         NSFileManager *fileManager = [[NSFileManager alloc] init];
         
         if ([newWritingURL checkResourceIsReachableAndReturnError:nil]) {
             [fileManager removeItemAtURL:newWritingURL error:nil];
         }
         success = [fileManager copyItemAtURL:newReadingURL toURL:newWritingURL error:&error];
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
            __block typeof(self) blockSelf = self;
            [self updateCacheWithCompletionHandler:^{
                [[NSNotificationCenter defaultCenter] postNotificationName:CESyntaxDidUpdateNotification
                                                                    object:blockSelf
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
    [(NSMutableArray *)style[k_SCKey_extensions] removeObject:@{}];
    [(NSMutableArray *)style[k_SCKey_filenames] removeObject:@{}];
    [style removeObjectForKey:k_SCKey_numOfObjInArray];
    
    // sort
    NSArray *descriptors = @[[NSSortDescriptor sortDescriptorWithKey:k_SCKey_beginString
                                                           ascending:YES
                                                            selector:@selector(caseInsensitiveCompare:)],
                             [NSSortDescriptor sortDescriptorWithKey:k_SCKey_arrayKeyString
                                                           ascending:YES
                                                            selector:@selector(caseInsensitiveCompare:)]];
    
    NSMutableArray *syntaxDictKeys = [NSMutableArray array];
    for (NSUInteger i = 0; i < k_size_of_allColoringArrays; i++) {
        [syntaxDictKeys addObject:k_SCKey_allColoringArrays[i]];
    }
    [syntaxDictKeys addObjectsFromArray:@[k_SCKey_outlineMenuArray,
                                          k_SCKey_completionsArray]];
    
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
        [style writeToURL:saveURL atomically:YES];
    }
    
    // 内部で持っているキャッシュ用データを更新
    [self updateCacheWithCompletionHandler:^{
        // notify
        __block typeof(self) blockSelf = self;
        [[NSNotificationCenter defaultCenter] postNotificationName:CESyntaxDidUpdateNotification
                                                            object:blockSelf
                                                          userInfo:@{CEOldNameKey: oldName,
                                                                     CENewNameKey: name}];
    }];
}


// ------------------------------------------------------
/// 正規表現構文と重複のチェック実行をしてエラーメッセージのArrayを返す
- (NSArray *)validateSyntax:(NSDictionary *)style
// ------------------------------------------------------
{
    NSMutableArray *errorMessages = [NSMutableArray array];
    NSString *tmpBeginStr = nil, *tmpEndStr = nil;
    NSError *error = nil;
    
    NSMutableArray *syntaxDictKeys = [[NSMutableArray alloc] initWithCapacity:(k_size_of_allColoringArrays + 1)];
    for (NSUInteger i = 0; i < k_size_of_allColoringArrays; i++) {
        [syntaxDictKeys addObject:k_SCKey_allColoringArrays[i]];
    }
    [syntaxDictKeys addObject:k_SCKey_outlineMenuArray];
    
    for (NSString *key in syntaxDictKeys) {
        NSArray *array = style[key];
        NSString *arrayNameDeletingArray = [key substringToIndex:([key length] - 5)];
        
        for (NSDictionary *dict in array) {
            NSString *beginStr = dict[k_SCKey_beginString];
            NSString *endStr = dict[k_SCKey_endString];
            
            if ([tmpBeginStr isEqualToString:beginStr] &&
                ((!tmpEndStr && !endStr) || [tmpEndStr isEqualToString:endStr])) {
                [errorMessages addObject:[NSString stringWithFormat:
                                          @"%@ :(Begin string) > %@\n  >>> multiple registered.",
                                          arrayNameDeletingArray, beginStr]];
                
            } else if ([dict[k_SCKey_regularExpression] boolValue]) {
                NSInteger capCount = [beginStr captureCountWithOptions:RKLNoOptions error:&error];
                if (capCount == -1) { // エラーのとき
                    [errorMessages addObject:[NSString stringWithFormat:
                                              @"%@ :(Begin string) > %@\n  >>> Error \"%@\" in column %@: %@<<HERE>>%@",
                                              arrayNameDeletingArray, beginStr,
                                              [error userInfo][RKLICURegexErrorNameErrorKey],
                                              [error userInfo][RKLICURegexOffsetErrorKey],
                                              [error userInfo][RKLICURegexPreContextErrorKey],
                                              [error userInfo][RKLICURegexPostContextErrorKey]]];
                }
                if (endStr != nil) {
                    NSInteger capCount = [endStr captureCountWithOptions:RKLNoOptions error:&error];
                    if (capCount == -1) { // エラーのとき
                        [errorMessages addObject:[NSString stringWithFormat:
                                                  @"%@ :(End string) > %@\n  >>> Error \"%@\" in column %@: %@<<HERE>>%@",
                                                  arrayNameDeletingArray, endStr,
                                                  [error userInfo][RKLICURegexErrorNameErrorKey],
                                                  [error userInfo][RKLICURegexOffsetErrorKey],
                                                  [error userInfo][RKLICURegexPreContextErrorKey],
                                                  [error userInfo][RKLICURegexPostContextErrorKey]]];
                    }
                }
                
            } else if ([key isEqualToString:k_SCKey_outlineMenuArray]) {
                error = nil;
                [NSRegularExpression regularExpressionWithPattern:beginStr options:0 error:&error];
                if (error) {
                    [errorMessages addObject:[NSString stringWithFormat:@"%@ :((RE string) > %@\n  >>> Regex Error: \"%@\"",
                                              arrayNameDeletingArray, beginStr, [error localizedFailureReason]]];
                }
            }
            tmpBeginStr = beginStr;
            tmpEndStr = endStr;
        }
    }
    
    // validate block comment delimiter pair
    NSString *beginDelimiter = style[k_SCKey_commentDelimitersDict][k_SCKey_beginComment];
    NSString *endDelimiter = style[k_SCKey_commentDelimitersDict][k_SCKey_endComment];
    if (([beginDelimiter length] >  0 && [endDelimiter length] == 0) ||
        ([beginDelimiter length] == 0 && [endDelimiter length] >  0))
    {
        [errorMessages addObject:NSLocalizedString(@"Block comment needs both begin delimiter and end delimiter.", nil)];
    }
    
    return errorMessages;
}


//------------------------------------------------------
/// 空の新規styleを返す
- (NSDictionary *)emptyStyle
//------------------------------------------------------
{
    return @{k_SCKey_styleName: [NSMutableString string],
             k_SCKey_extensions: [NSMutableArray array],
             k_SCKey_filenames: [NSMutableArray array],
             k_SCKey_keywordsArray: [NSMutableArray array],
             k_SCKey_commandsArray: [NSMutableArray array],
             k_SCKey_typesArray: [NSMutableArray array],
             k_SCKey_attributesArray: [NSMutableArray array],
             k_SCKey_variablesArray: [NSMutableArray array],
             k_SCKey_valuesArray: [NSMutableArray array],
             k_SCKey_numbersArray: [NSMutableArray array],
             k_SCKey_stringsArray: [NSMutableArray array],
             k_SCKey_charactersArray: [NSMutableArray array],
             k_SCKey_commentsArray: [NSMutableArray array],
             k_SCKey_outlineMenuArray: [NSMutableArray array],
             k_SCKey_completionsArray: [NSMutableArray array],
             k_SCKey_commentDelimitersDict: [NSMutableDictionary dictionary]};
}



#pragma mark Private Mthods

//=======================================================
// Private method
//
//=======================================================

//------------------------------------------------------
/// Application Support内のstyleデータファイル保存ディレクトリ
- (NSURL *)userStyleDirectoryURL
//------------------------------------------------------
{
    return [[[NSFileManager defaultManager] URLForDirectory:NSApplicationSupportDirectory
                                                   inDomain:NSUserDomainMask
                                          appropriateForURL:nil
                                                     create:NO
                                                      error:nil]
            URLByAppendingPathComponent:@"CotEditor/SyntaxColorings"];
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
    return [[NSBundle mainBundle] URLForResource:styleName withExtension:@"plist" subdirectory:@"SyntaxColorings"];
}


//------------------------------------------------------
/// style名からユーザ領域のstyle定義ファイルのURLを返す
- (NSURL *)URLForUserStyle:(NSString *)styleName
//------------------------------------------------------
{
    return [[[self userStyleDirectoryURL] URLByAppendingPathComponent:styleName] URLByAppendingPathExtension:@"plist"];
}

// ------------------------------------------------------
/// 内部で持っているキャッシュ用データを更新
- (void)updateCacheWithCompletionHandler:(void (^)())completionHandler
// ------------------------------------------------------
{
    __block typeof(self) blockSelf = self;
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        [blockSelf cacheStyles];
        [blockSelf setupExtensionAndSyntaxTable];
        
        dispatch_async(dispatch_get_main_queue(), ^{
            // Notificationを発行
            [[NSNotificationCenter defaultCenter] postNotificationName:CESyntaxListDidUpdateNotification object:blockSelf];
            
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

    // styleデータの読み込み
    NSMutableDictionary *styles = [NSMutableDictionary dictionary];
    NSMutableDictionary *styleDict;
    NSString *styleName;
    NSURL *URL;
    
    // バンドル版を読み込む
    for (styleName in [self bundledStyleNames]) {
        styleDict = [NSMutableDictionary dictionaryWithContentsOfURL:[self URLForBundledStyle:styleName]];
        if (styleDict) {
            styles[[styleName lowercaseString]] = styleDict;  // このキーは重複チェック＆ソート用なので小文字に揃えておく
        }
    }
    
    // ユーザ版を読み込む
    if ([dirURL checkResourceIsReachableAndReturnError:nil]) {
        NSDirectoryEnumerator *enumerator = [[NSFileManager defaultManager]
                                             enumeratorAtURL:dirURL
                                             includingPropertiesForKeys:nil
                                             options:NSDirectoryEnumerationSkipsSubdirectoryDescendants | NSDirectoryEnumerationSkipsHiddenFiles
                                             errorHandler:^BOOL(NSURL *url, NSError *error)
                                             {
                                                 NSLog(@"Error on seeking SyntaxStyle Files Directory.");
                                                 return YES;
                                             }];
        while (URL = [enumerator nextObject]) {
            styleDict = [NSMutableDictionary dictionaryWithContentsOfURL:URL];
            // URLが無効だった場合などに、dictがnilになる場合がある
            if (styleDict) {
                styleName = [[URL lastPathComponent] stringByDeletingPathExtension];
                // k_SCKey_styleName をファイル名にそろえておく(Finderで移動／リネームされたときへの対応)
                styleDict[k_SCKey_styleName] = styleName;
                styles[[styleName lowercaseString]] = styleDict;
            }
        }
    }
    
    // 定義をアルファベット順にソートする
    NSArray *sortedKeys = [[styles allKeys] sortedArrayUsingSelector:@selector(caseInsensitiveCompare:)];
    NSArray *sortedStyles = [styles objectsForKeys:sortedKeys notFoundMarker:[NSNull null]];
    
    [self setStyles:sortedStyles];
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

    for (NSMutableDictionary *style in [self styles]) {
        NSString *styleName = style[k_SCKey_styleName];
        NSArray *extensionDicts = style[k_SCKey_extensions];
        NSArray *filenameDicts = style[k_SCKey_filenames];
        
        for (NSDictionary *dict in extensionDicts) {
            NSString *extension = dict[k_SCKey_arrayKeyString];
            
            if (!extension) { continue; }
            
            if ((addedName = extensionTable[extension])) { // 同じ拡張子を持つものがすでにあるとき
                NSMutableArray *errors = extensionConflicts[extension];
                if (!errors) {
                    errors = [NSMutableArray array];
                    [extensionConflicts setValue:errors forKey:extension];
                }
                if (![errors containsObject:addedName]) {
                    [errors addObject:addedName];
                }
                [errors addObject:style[k_SCKey_styleName]];
            } else {
                [extensionTable setValue:styleName forKey:extension];
            }
        }
        
        for (NSDictionary *dict in filenameDicts) {
            NSString *filename = dict[k_SCKey_arrayKeyString];
            
            if (!filename) { continue; }
            
            if ((addedName = filenameTable[filename])) { // 同じファイル名を持つものがすでにあるとき
                NSMutableArray *errors = filenameConflicts[filename];
                if (!errors) {
                    errors = [NSMutableArray array];
                    [filenameConflicts setValue:errors forKey:filename];
                }
                if (![errors containsObject:addedName]) {
                    [errors addObject:addedName];
                }
                [errors addObject:style[k_SCKey_styleName]];
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

@end
