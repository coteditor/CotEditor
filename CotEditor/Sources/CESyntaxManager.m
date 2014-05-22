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


@interface CESyntaxManager ()

@property (nonatomic, copy) NSArray *styles;  // 全てのカラーリング定義 (array of NSMutableDictonary)
@property (nonatomic, copy) NSDictionary *extensionToStyleTable;  // 拡張子<->styleファイルの変換テーブル辞書(key = 拡張子)
@property (nonatomic, copy) NSArray *extensions;  // 拡張子配列
@property (nonatomic, copy) NSArray *bundledStyleNames;  // バンドルされているシンタックススタイル名の配列


// readonly
@property (nonatomic, copy, readwrite) NSDictionary *extensionConflicts;

@end



@interface CESyntaxManager (Migration)

- (void)migrateDuplicatedDefaultColoringStylesInUserDomain;

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
        
        // 重複しているユーザ領域の定義ファイルを隔離
        [self migrateDuplicatedDefaultColoringStylesInUserDomain];
        
        [self updateCache];
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
/// 拡張子に応じたstyle名を返す
- (NSString *)syntaxNameFromExtension:(NSString *)extension
// ------------------------------------------------------
{
    NSString *syntaxName = [self extensionToStyleTable][extension];

    return (syntaxName) ? syntaxName : [[NSUserDefaults standardUserDefaults] stringForKey:k_key_defaultColoringStyleName];
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
    NSURL *URL = [self URLForUserStyle:styleName];

    return [URL checkResourceIsReachableAndReturnError:nil];
}


//------------------------------------------------------
/// 外部styleファイルをユーザ領域にコピーする
- (BOOL)importStyleFromURL:(NSURL *)fileURL
//------------------------------------------------------
{
    NSURL *destURL = [[self userStyleDirectoryURL] URLByAppendingPathComponent:[fileURL lastPathComponent]];
    
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
        [self updateCache];
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
    NSFileManager *fileManager = [[NSFileManager alloc] init];
    NSURL *URL = [self URLForUserStyle:styleName];

    if ([URL checkResourceIsReachableAndReturnError:nil]) {
        success = [fileManager removeItemAtURL:URL error:nil];
        if (success) {
            // 内部で持っているキャッシュ用データを更新
            [self updateCache];
        } else {
            NSLog(@"Error. Could not remove \"%@\".", URL);
        }
    } else {
        NSLog(@"Error. Could not be found \"%@\" for remove.", URL);
    }
    return success;
}


//------------------------------------------------------
/// 拡張子重複エラーがあるかどうかを返す
- (BOOL)existsExtensionConflict
//------------------------------------------------------
{
    return ([[self extensionConflicts] count] > 0);
}


//------------------------------------------------------
/// コピーされたstyle名を返す
- (NSString *)copiedStyleName:(NSString *)originalName
//------------------------------------------------------
{
    NSString *baseName = [originalName stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
    NSString *copyString;
    NSRange copiedStrRange;
    BOOL copiedState = NO;
    NSUInteger i = 2;
    
    NSRegularExpression *regex = [NSRegularExpression regularExpressionWithPattern:NSLocalizedString(@" copy$", nil)
                                                                           options:0 error:nil];
    copiedStrRange = [regex rangeOfFirstMatchInString:baseName options:0 range:NSMakeRange(0, [baseName length])];
    if (copiedStrRange.location != NSNotFound) {
        copiedState = YES;
    } else {
        regex = [NSRegularExpression regularExpressionWithPattern:NSLocalizedString(@" copy [0-9]+$", nil) options:0 error:nil];
        copiedStrRange = [regex rangeOfFirstMatchInString:baseName options:0 range:NSMakeRange(0, [baseName length])];
        if (copiedStrRange.location != NSNotFound) {
            copiedState = YES;
        }
    }
    if (copiedState) {
        copyString = [NSString stringWithFormat:@"%@%@",
                    [baseName substringWithRange:NSMakeRange(0, copiedStrRange.location)],
                    NSLocalizedString(@" copy", nil)];
    } else {
        copyString = [NSString stringWithFormat:@"%@%@", baseName, NSLocalizedString(@" copy", nil)];
    }
    NSMutableString *copiedStyleName = [copyString mutableCopy];
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
    NSURL *saveURL;
    NSMutableArray *keyStrings;
    NSSortDescriptor *descriptorOne = [[NSSortDescriptor alloc] initWithKey:k_SCKey_beginString
                                                                  ascending:YES
                                                                   selector:@selector(caseInsensitiveCompare:)];
    NSSortDescriptor *descriptorTwo = [[NSSortDescriptor alloc] initWithKey:k_SCKey_arrayKeyString
                                                                  ascending:YES
                                                                   selector:@selector(caseInsensitiveCompare:)];
    NSArray *descriptors = @[descriptorOne, descriptorTwo];
    
    NSMutableArray *syntaxDictKeys = [[NSMutableArray alloc] initWithCapacity:k_size_of_allColoringArrays + 2];
    for (NSUInteger i = 0; i < k_size_of_allColoringArrays; i++) {
        [syntaxDictKeys addObject:k_SCKey_allColoringArrays[i]];
    }
    [syntaxDictKeys addObjectsFromArray:@[k_SCKey_outlineMenuArray,
                                          k_SCKey_completionsArray]];
    
    for (NSString *key in syntaxDictKeys) {
        keyStrings = style[key];
        [keyStrings sortUsingDescriptors:descriptors];
    }
    
    
    NSMutableArray *emptyDicts = [NSMutableArray array];
    for (NSDictionary *extensionDict in style[k_SCKey_extensions]) {
        if (extensionDict[k_SCKey_arrayKeyString] == nil) {
            [emptyDicts addObject:extensionDict];
        }
    }
    [style[k_SCKey_extensions] removeObjectsInArray:emptyDicts];
    
    if ([name length] > 0) {
        saveURL = [self URLForUserStyle:name];
        // style名が変更されたときは、古いファイルを削除する
        if (![name isEqualToString:oldName]) {
            [[NSFileManager defaultManager] removeItemAtURL:[self URLForUserStyle:oldName] error:nil];
        }
        // 保存しようとしている定義がバンドル版と同じだった場合（出荷時に戻したときなど）はユーザ領域のファイルを削除して終わる
        if ([style isEqualToDictionary:[[self bundledStyleWithStyleName:name] mutableCopy]]) {
            if ([saveURL checkResourceIsReachableAndReturnError:nil]) {
                [[NSFileManager defaultManager] removeItemAtURL:saveURL error:nil];
            }
        } else {
            // 保存
            [style writeToURL:saveURL atomically:YES];
        }
    }
    // 内部で持っているキャッシュ用データを更新
    [self updateCache];
}


// ------------------------------------------------------
/// 正規表現構文と重複のチェック実行をしてエラーメッセージのArrayを返す
- (NSArray *)validateSyntax:(NSDictionary *)style
// ------------------------------------------------------
{
    NSMutableArray *errorMessages = [NSMutableArray array];
    NSArray *array;
    NSString *beginStr, *endStr, *tmpBeginStr = nil, *tmpEndStr = nil;
    NSString *arrayNameDeletingArray = nil;
    NSInteger capCount;
    NSError *error = nil;
    
    NSMutableArray *syntaxDictKeys = [[NSMutableArray alloc] initWithCapacity:(k_size_of_allColoringArrays + 1)];
    for (NSUInteger i = 0; i < k_size_of_allColoringArrays; i++) {
        [syntaxDictKeys addObject:k_SCKey_allColoringArrays[i]];
    }
    [syntaxDictKeys addObject:k_SCKey_outlineMenuArray];
    
    for (NSString *key in syntaxDictKeys) {
        array = style[key];
        arrayNameDeletingArray = [key substringToIndex:([key length] - 5)];
        
        for (NSDictionary *dict in array) {
            beginStr = dict[k_SCKey_beginString];
            endStr = dict[k_SCKey_endString];
            
            if ([tmpBeginStr isEqualToString:beginStr] &&
                ((!tmpEndStr && !endStr) || [tmpEndStr isEqualToString:endStr])) {
                [errorMessages addObject:[NSString stringWithFormat:
                                          @"%@ :(Begin string) > %@\n  >>> multiple registered.",
                                          arrayNameDeletingArray, beginStr]];
                
            } else if ([dict[k_SCKey_regularExpression] boolValue]) {
                capCount = [beginStr captureCountWithOptions:RKLNoOptions error:&error];
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
                    capCount = [endStr captureCountWithOptions:RKLNoOptions error:&error];
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
                NSRegularExpression *regex = [NSRegularExpression regularExpressionWithPattern:beginStr
                                                                                       options:0
                                                                                         error:&error];
                if (error) {
                    [errorMessages addObject:[NSString stringWithFormat:@"%@ :((RE string) > %@\n  >>> Regex Error: \"%@\"",
                                              arrayNameDeletingArray, beginStr, [error localizedFailureReason]]];
                }
            }
            tmpBeginStr = beginStr;
            tmpEndStr = endStr;
        }
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
             k_SCKey_keywordsArray: [NSMutableArray array],
             k_SCKey_commandsArray: [NSMutableArray array],
             k_SCKey_valuesArray: [NSMutableArray array],
             k_SCKey_numbersArray: [NSMutableArray array],
             k_SCKey_stringsArray: [NSMutableArray array],
             k_SCKey_charactersArray: [NSMutableArray array],
             k_SCKey_commentsArray: [NSMutableArray array],
             k_SCKey_outlineMenuArray: [NSMutableArray array],
             k_SCKey_completionsArray: [NSMutableArray array]};
}



#pragma mark Private Mthods

//=======================================================
// Private method
//
//=======================================================

// ------------------------------------------------------
/// 内部で持っているキャッシュ用データを更新
- (void)updateCache
// ------------------------------------------------------
{
    [self setupColoringStyles];
    [self setupExtensionAndSyntaxTable];
    
    // ラインナップの更新を通知する
    [[NSNotificationCenter defaultCenter] postNotificationName:CESyntaxListDidUpdateNotification object:nil];
}


//------------------------------------------------------
/// styleのファイルからのセットアップと読み込み
- (void)setupColoringStyles
//------------------------------------------------------
{
    NSURL *dirURL = [self userStyleDirectoryURL]; // ユーザディレクトリパス取得

    // ディレクトリの存在チェック
    NSFileManager *fileManager = [[NSFileManager alloc] init];
    BOOL isDirectory = NO, success = NO;
    BOOL exists = [fileManager fileExistsAtPath:[dirURL path] isDirectory:&isDirectory];
    if (!exists) {
		NSError *createDirError = nil;
		success = [fileManager createDirectoryAtURL:dirURL withIntermediateDirectories:NO attributes:nil error:&createDirError];
		if (createDirError != nil) {
			NSLog(@"Error. SyntaxStyles directory could not be created.");
			return;
		}
		
    }
    if (!(exists && isDirectory) && !success) {
        NSLog(@"Error. SyntaxStyles directory could not be found.");
        return;
    }

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
    NSDirectoryEnumerator *enumerator = [fileManager enumeratorAtURL:dirURL
                                          includingPropertiesForKeys:nil
                                                             options:NSDirectoryEnumerationSkipsSubdirectoryDescendants | NSDirectoryEnumerationSkipsHiddenFiles
                                                        errorHandler:^BOOL(NSURL *url, NSError *error) {
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
            styles[[styleName lowercaseString]] = styleDict; // dictがnilになってここで落ちる（MacBook Airの場合
        }
    }
    
    // 定義をアルファベット順にソートする
    NSArray *sortedKeys = [[styles allKeys] sortedArrayUsingSelector:@selector(compare:)];
    NSArray *sortedStyles = [styles objectsForKeys:sortedKeys notFoundMarker:[NSNull null]];
    
    [self setStyles:sortedStyles];
}


// ------------------------------------------------------
/// 拡張子<->styleファイルの変換テーブル辞書(key = 拡張子)と、拡張子辞書、拡張子重複エラー辞書を更新
- (void)setupExtensionAndSyntaxTable
// ------------------------------------------------------
{
    NSMutableDictionary *table = [NSMutableDictionary dictionary];
    NSMutableDictionary *conflictDict = [NSMutableDictionary dictionary];
    NSMutableArray *extensions = [NSMutableArray array];
    id extension, addedName = nil;
    NSArray *extensionDicts;

    for (NSMutableDictionary *style in [self styles]) {
        extensionDicts = style[k_SCKey_extensions];
        if (!extensionDicts) { continue; }
        for (NSDictionary *extensionDict in extensionDicts) {
            extension = extensionDict[k_SCKey_arrayKeyString];
            if ((addedName = table[extension])) { // 同じ拡張子を持つものがすでにあるとき
                NSMutableArray *errorArray = conflictDict[extension];
                if (!errorArray) {
                    errorArray = [NSMutableArray array];
                    [conflictDict setValue:errorArray forKey:extension];
                }
                if (![errorArray containsObject:addedName]) {
                    [errorArray addObject:addedName];
                }
                [errorArray addObject:style[k_SCKey_styleName]];
            } else {
                [table setValue:style[k_SCKey_styleName] forKey:extension];
                [extensions addObject:extension];
            }
        }
    }
    [self setExtensionToStyleTable:table];
    [self setExtensionConflicts:conflictDict];
    [self setExtensions:extensions];
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

@end




#pragma mark -

@implementation CESyntaxManager (Migration)

//------------------------------------------------------
/// ユーザ領域にあるバンドル版と重複したstyleデータファイルを隔離
- (void)migrateDuplicatedDefaultColoringStylesInUserDomain
//------------------------------------------------------
{
    // CotEditor 1.4.1までで自動的にコピーされたバンドル版定義ファイルを別のディレクトリに隔離する (2014-04-07 by 1024jp)
    // CotEditor 1.5で実装されたこのメソッドは、後に十分に移行が完了した時点で取り除く予定
    
    if (![[self userStyleDirectoryURL] checkResourceIsReachableAndReturnError:nil]) { return; }
    
    NSURL *migrationDirURL = [[[self userStyleDirectoryURL] URLByDeletingLastPathComponent]
                              URLByAppendingPathComponent:@"SyntaxColorings (old)"];
    
    NSFileManager *fileManager = [[NSFileManager alloc] init];
    
    for (NSString *styleName in [self bundledStyleNames]) {
        if ([self existsDuplicatedStyleInUserDomain:styleName]) {
            [fileManager createDirectoryAtURL:migrationDirURL withIntermediateDirectories:YES attributes:nil error:nil];
            
            NSURL *URL = [self URLForUserStyle:styleName];
            NSURL *migrationURL = [[migrationDirURL URLByAppendingPathComponent:styleName] URLByAppendingPathExtension:@"plist"];
            
            if ([migrationDirURL checkResourceIsReachableAndReturnError:nil]) {
                [fileManager removeItemAtURL:migrationURL error:nil];
            }
            [fileManager moveItemAtURL:URL toURL:migrationURL error:nil];
        }
    }
}


// ------------------------------------------------------
/// バンドル版と全く同じ定義のファイルがユーザ領域にあるかどうかを返す
- (BOOL)existsDuplicatedStyleInUserDomain:(NSString *)styleName
// ------------------------------------------------------
{
    if ([styleName isEqualToString:@""]) { return NO; }
    
    NSURL *destURL = [self URLForUserStyle:styleName];
    NSURL *sourceURL = [self URLForBundledStyle:styleName];
    
    if (![sourceURL checkResourceIsReachableAndReturnError:nil] ||
        ![destURL checkResourceIsReachableAndReturnError:nil])
    {
        return NO;
    }
    
    // （[self syntaxWithStyleName:[self selectedStyleName]]] で返ってくる辞書には numOfObjInArray が付加されている
    // ため、同じではない。ファイル同士を比較する。2008.05.06.
    NSDictionary *sourcePList = [NSDictionary dictionaryWithContentsOfURL:sourceURL];
    NSDictionary *destPList = [NSDictionary dictionaryWithContentsOfURL:destURL];
    
    return [sourcePList isEqualToDictionary:destPList];
    
    // NSFileManager の contentsEqualAtPath:andPath: では、宣言部分の「Apple Computer（Tiger以前）」と「Apple（Leopard）」の違いが引っかかってしまうため、使えなくなった。 2008.05.06.
    //    return ([theFileManager contentsEqualAtPath:[sourceURL path] andPath:[destURL path]]);
}

@end
