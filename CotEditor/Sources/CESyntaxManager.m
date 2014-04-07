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
#import "constants.h"


@interface CESyntaxManager ()

@property (nonatomic) NSArray *coloringStyles;  // 全てのカラーリング定義
@property (nonatomic) NSDictionary *extensionToStyleTable;  // 拡張子<->styleファイルの変換テーブル辞書(key = 拡張子)
@property (nonatomic) NSArray *extensions;  // 拡張子配列

// readonly
@property (nonatomic, readwrite) NSDictionary *extensionErrors;

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
// NSObject method
//
//=======================================================

// ------------------------------------------------------
/// 初期化
- (instancetype)init
// ------------------------------------------------------
{
    self = [super init];
    if (self) {
        // 重複しているユーザ領域の定義ファイルを避難
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
/// 拡張子に応じたstyle名を返す
- (NSString *)syntaxNameFromExtension:(NSString *)extension
// ------------------------------------------------------
{
    NSString *syntaxName = [self extensionToStyleTable][extension];

    return (syntaxName) ? syntaxName : [[NSUserDefaults standardUserDefaults] stringForKey:k_key_defaultColoringStyleName];
}


// ------------------------------------------------------
/// style名に応じたstyle辞書を返す
- (NSDictionary *)syntaxWithStyleName:(NSString *)styleName
// ------------------------------------------------------
{
    if (![styleName isEqualToString:@""] && ![styleName isEqualToString:NSLocalizedString(@"None", nil)]) {
        NSMutableDictionary *styleDict;
        for (NSDictionary *dict in [self coloringStyles]) {
            if ([dict[k_SCKey_styleName] isEqualToString:styleName]) {
                NSArray *syntaxes = @[k_SCKey_allColoringArrays];
                NSArray *theArray;
                NSUInteger count = 0;
                styleDict = [dict mutableCopy];

                for (id key in syntaxes) {
                    theArray = styleDict[key];
                    count = count + [theArray count];
                }
                styleDict[k_SCKey_numOfObjInArray] = @(count);
                return styleDict;
            }
        }
    }
    // 空のデータを返す
    return [self emptyColoringStyle];
}


// ------------------------------------------------------
/// style名に応じたバンドル版のstyle辞書を返す
- (NSURL *)URLOfBundledStyle:(NSString *)styleName
// ------------------------------------------------------
{
    NSURL *URL = [[[self bundledStyleDirectoryURL] URLByAppendingPathComponent:styleName]
                  URLByAppendingPathExtension:@"plist"];
    
    if (![URL checkResourceIsReachableAndReturnError:nil]) { return nil; }
    
    return URL;
}


// ------------------------------------------------------
/// あるスタイルネームがデフォルトで用意されているものかどうかを返す
- (BOOL)isDefaultSyntaxStyle:(NSString *)styleName
// ------------------------------------------------------
{
    if ([styleName isEqualToString:@""]) { return NO; }
    
    NSArray *fileNames = [self bundledStyleNames];
    
    return [fileNames containsObject:styleName];
}


// ------------------------------------------------------
/// あるスタイルネームがデフォルトで用意されているものと同じかどうかを返す
- (BOOL)isEqualToBundledSyntaxStyle:(NSString *)styleName
// ------------------------------------------------------
{
    if ([styleName isEqualToString:@""]) { return NO; }
    
    NSURL *destURL = [[[self userStyleDirectoryURL] URLByAppendingPathComponent:styleName] URLByAppendingPathExtension:@"plist"];
    NSURL *sourceURL = [[[self bundledStyleDirectoryURL] URLByAppendingPathComponent:styleName] URLByAppendingPathExtension:@"plist"];
    
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


// ------------------------------------------------------
/// スタイル名配列を返す
- (NSArray *)styleNames
// ------------------------------------------------------
{
    NSMutableArray *styleNames = [NSMutableArray array];
    
    for (NSDictionary *dict in [self coloringStyles]) {
        [styleNames addObject:dict[k_SCKey_styleName]];
    }

    return styleNames;
}


//------------------------------------------------------
/// ある名前を持つstyleファイルがstyle保存ディレクトリにあるかどうかを返す
- (BOOL)existsStyleFileWithStyleName:(NSString *)styleName
//------------------------------------------------------
{
    NSURL *URL = [[[self userStyleDirectoryURL] URLByAppendingPathComponent:styleName] URLByAppendingPathExtension:@"plist"];

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
         [fileManager removeItemAtURL:newWritingURL error:nil];
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
    NSURL *sourceURL = [self URLOfStyle:styleName];
    
    __block BOOL success = NO;
    __block NSError *error = nil;
    NSFileCoordinator *coordinator = [[NSFileCoordinator alloc] initWithFilePresenter:nil];
    [coordinator coordinateReadingItemAtURL:sourceURL options:NSFileCoordinatorReadingWithoutChanges
                           writingItemAtURL:fileURL options:NSFileCoordinatorWritingForReplacing
                                      error:&error
                                 byAccessor:^(NSURL *newReadingURL, NSURL *newWritingURL)
     {
         NSFileManager *fileManager = [[NSFileManager alloc] init];
         [fileManager removeItemAtURL:newWritingURL error:nil];
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
    NSFileManager *fileManager = [NSFileManager defaultManager];
    NSURL *URL = [[[self userStyleDirectoryURL] URLByAppendingPathComponent:styleName] URLByAppendingPathExtension:@"plist"];

    if ([URL checkResourceIsReachableAndReturnError:nil]) {
        success = [fileManager removeItemAtURL:URL error:nil];
        if (success) {
            // 内部で持っているキャッシュ用データを更新
            [self updateCache];
        } else {
            NSLog(@"Error. Could not remove \"%@\"", [URL path]);
        }
    } else {
        NSLog(@"Error. Could not be found \"%@\" for remove", [URL path]);
    }
    return success;
}


//------------------------------------------------------
/// style名から有効なstyle定義ファイルのURLを返す
- (NSURL *)URLOfStyle:(NSString *)styleName
//------------------------------------------------------
{
    NSURL *URL = [[[self userStyleDirectoryURL] URLByAppendingPathComponent:styleName] URLByAppendingPathExtension:@"plist"];
    
    if (![URL checkResourceIsReachableAndReturnError:nil]) {
        URL = [[[self bundledStyleDirectoryURL] URLByAppendingPathComponent:styleName] URLByAppendingPathExtension:@"plist"];
    }
    
    return [URL checkResourceIsReachableAndReturnError:nil] ? URL : nil;
}


//------------------------------------------------------
/// 拡張子重複エラーがあるかどうかを返す
- (BOOL)existsExtensionError
//------------------------------------------------------
{
    return ([[self extensionErrors] count] > 0);
}


//------------------------------------------------------
/// コピーされたstyle名を返す
- (NSString *)copiedSyntaxName:(NSString *)originalName
//------------------------------------------------------
{
    NSURL *URL = [self userStyleDirectoryURL];
    NSString *compareName = [originalName stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
    NSString *copyName;
    NSMutableString *copiedSyntaxName = [NSMutableString string];
    NSRange copiedStrRange;
    BOOL copiedState = NO;
    NSInteger i = 1;
    
    copiedStrRange = [compareName rangeOfRegularExpressionString:NSLocalizedString(@" copy$", nil)];
    if (copiedStrRange.location != NSNotFound) {
        copiedState = YES;
    } else {
        copiedStrRange = [compareName rangeOfRegularExpressionString:NSLocalizedString(@" copy [0-9]+$", nil)];
        if (copiedStrRange.location != NSNotFound) {
            copiedState = YES;
        }
    }
    if (copiedState) {
        copyName = [NSString stringWithFormat:@"%@%@",
                    [compareName substringWithRange:NSMakeRange(0, copiedStrRange.location)],
                    NSLocalizedString(@" copy", nil)];
    } else {
        copyName = [NSString stringWithFormat:@"%@%@", compareName, NSLocalizedString(@" copy", nil)];
    }
    [copiedSyntaxName appendFormat:@"%@.plist", copyName];
    while ([[URL URLByAppendingPathExtension:copiedSyntaxName] checkResourceIsReachableAndReturnError:nil]) {
        i++;
        [copiedSyntaxName setString:[NSString stringWithFormat:@"%@ %li", copyName, (long)i]];
        [copiedSyntaxName appendString:@".plist"];
    }
    return [copiedSyntaxName stringByDeletingPathExtension];
}


//------------------------------------------------------
/// styleのファイルへの保存
- (void)saveColoringStyle:(NSMutableDictionary *)style name:(NSString *)name oldName:(NSString *)oldName
//------------------------------------------------------
{
    NSURL *saveURL;
    NSArray *arraysArray = @[k_SCKey_allArrays];
    NSMutableArray *keyStrings;
    NSSortDescriptor *descriptorOne = [[NSSortDescriptor alloc] initWithKey:k_SCKey_beginString
                                                                  ascending:YES
                                                                   selector:@selector(caseInsensitiveCompare:)];
    NSSortDescriptor *descriptorTwo = [[NSSortDescriptor alloc] initWithKey:k_SCKey_arrayKeyString
                                                                  ascending:YES
                                                                   selector:@selector(caseInsensitiveCompare:)];
    NSArray *descriptors = @[descriptorOne, descriptorTwo];
    for (id key in arraysArray) {
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
        saveURL = [[[self userStyleDirectoryURL] URLByAppendingPathComponent:name] URLByAppendingPathExtension:@"plist"];
        // style名が変更されたときは、古いファイルを削除する
        if (![name isEqualToString:oldName]) {
            [self removeStyleFileWithStyleName:oldName];
        }
        // 保存しようとしている定義がバンドル版と同じだった場合（出荷時に戻したときなど）はユーザ領域のファイルを削除して終わる
        BOOL isSameToBundledStyle = NO;
        if ([[self bundledStyleNames] containsObject:name]) {
            NSURL *bundledStyleURL = [[[self bundledStyleDirectoryURL] URLByAppendingPathComponent:name]
                                      URLByAppendingPathExtension:@"plist"];
            NSDictionary *bundledStyle = [NSDictionary dictionaryWithContentsOfURL:bundledStyleURL];
            isSameToBundledStyle = [style isEqualToDictionary:bundledStyle];
        }
        if (isSameToBundledStyle) {
            [self removeStyleFileWithStyleName:name];
        } else {
            [style writeToURL:saveURL atomically:YES];
        }
    }
    
    [self updateCache];  // 内部で持っているキャッシュ用データを更新
}


// ------------------------------------------------------
/// 正規表現構文と重複のチェック実行をしてエラーメッセージのArrayを返す
- (NSArray *)validateSyntax:(NSDictionary *)style
// ------------------------------------------------------
{
    NSMutableArray *errorMessages = [NSMutableArray array];
    
    NSArray *syntaxes = @[k_SCKey_syntaxCheckArrays];
    NSArray *array;
    NSString *beginStr, *endStr, *tmpBeginStr = nil, *tmpEndStr = nil;
    NSString *arrayNameDeletingArray = nil;
    NSInteger capCount;
    NSError *error = nil;
    
    for (NSString *arrayName in syntaxes) {
        array = style[arrayName];
        arrayNameDeletingArray = [arrayName substringToIndex:([arrayName length] - 5)];
        
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
                
                // （outlineMenuは、過去の定義との互換性保持のためもあってOgreKitを使っている 2008.05.16）
            } else if ([arrayName isEqualToString:k_SCKey_outlineMenuArray]) {
                NS_DURING
                (void)[OGRegularExpression regularExpressionWithString:beginStr];
                NS_HANDLER
                // 例外処理 (OgreKit付属のRegularExpressionTestのコードを参考にしています)
                [errorMessages addObject:[NSString stringWithFormat:
                                          @"%@ :(RE string) > %@\n  >>> %@",
                                          arrayNameDeletingArray, beginStr, [localException reason]]];
                NS_ENDHANDLER
            }
            tmpBeginStr = beginStr;
            tmpEndStr = endStr;
        }
    }
    
    return errorMessages;
}


//------------------------------------------------------
/// 空の新規styleを返す
- (NSDictionary *)emptyColoringStyle
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
}


// ------------------------------------------------------
/// バンドルされているシンタックスカラーリングスタイル名配列を返す
- (NSArray *)bundledStyleNames
// ------------------------------------------------------
{
    NSFileManager *fileManager = [NSFileManager defaultManager];
    NSURL *sourceDirURL = [self bundledStyleDirectoryURL];
    NSDirectoryEnumerator *enumerator = [fileManager enumeratorAtURL:sourceDirURL
                                          includingPropertiesForKeys:nil
                                                             options:NSDirectoryEnumerationSkipsSubdirectoryDescendants
                                                        errorHandler:nil];
    NSMutableArray *fileNames = [NSMutableArray array];
    NSURL *URL;
    
    while (URL = [enumerator nextObject]) {
        if ([[URL pathExtension] isEqualToString:@"plist"]) {
            [fileNames addObject:[[URL lastPathComponent] stringByDeletingPathExtension]];
        }
    }
    return fileNames;
}


//------------------------------------------------------
/// styleのファイルからのセットアップと読み込み
- (void)setupColoringStyles
//------------------------------------------------------
{
    NSURL *dirURL = [self userStyleDirectoryURL]; // ユーザディレクトリパス取得

    // ディレクトリの存在チェック
    NSFileManager *fileManager = [NSFileManager defaultManager];
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
    NSArray *bundledStyleNames = [self bundledStyleNames];
    for (styleName in bundledStyleNames) {
        URL = [[[self bundledStyleDirectoryURL] URLByAppendingPathComponent:styleName] URLByAppendingPathExtension:@"plist"];
        styleDict = [NSMutableDictionary dictionaryWithContentsOfURL:URL];
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
    
    [self setColoringStyles:sortedStyles];
}


// ------------------------------------------------------
/// 拡張子<->styleファイルの変換テーブル辞書(key = 拡張子)と、拡張子辞書、拡張子重複エラー辞書を更新
- (void)setupExtensionAndSyntaxTable
// ------------------------------------------------------
{
    NSMutableDictionary *table = [NSMutableDictionary dictionary];
    NSMutableDictionary *errorDict = [NSMutableDictionary dictionary];
    NSMutableArray *extensions = [NSMutableArray array];
    id styleDict, extension, addedName = nil;
    NSArray *extensionArray;

    for (styleDict in [self coloringStyles]) {
        extensionArray = styleDict[k_SCKey_extensions];
        if (!extensionArray) { continue; }
        for (NSDictionary *extensionDict in extensionArray) {
            extension = extensionDict[k_SCKey_arrayKeyString];
            if ((addedName = table[extension])) { // 同じ拡張子を持つものがすでにあるとき
                NSMutableArray *errorArray = errorDict[extension];
                if (!errorArray) {
                    errorArray = [NSMutableArray array];
                    [errorDict setValue:errorArray forKey:extension];
                }
                if (![errorArray containsObject:addedName]) {
                    [errorArray addObject:addedName];
                }
                [errorArray addObject:styleDict[k_SCKey_styleName]];
            } else {
                [table setValue:styleDict[k_SCKey_styleName] forKey:extension];
                [extensions addObject:extension];
            }
        }
    }
    [self setExtensionToStyleTable:table];
    [self setExtensionErrors:errorDict];
    [self setExtensions:extensions];
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


//------------------------------------------------------
/// bundle内のstyleデータファイル保存ディレクトリ
- (NSURL *)bundledStyleDirectoryURL
//------------------------------------------------------
{
    return [[[NSBundle mainBundle] bundleURL] URLByAppendingPathComponent:@"Contents/Resources/SyntaxColorings"];
}


//------------------------------------------------------
/// ユーザ領域にあるバンドル版と重複したstyleデータファイルを避難
- (BOOL)migrateDuplicatedDefaultColoringStylesInUserDomain
//------------------------------------------------------
{
    // CotEditor 1.4.1までで自動的にコピーされたバンドル版定義ファイルを別のディレクトリに避難させる (2014-04-07 by 1024jp)
    // CotEditor 1.5で実装されたこのメソッドは、後に十分に移行が完了した時点で取り除く予定
    
    if ([[self userStyleDirectoryURL] checkResourceIsReachableAndReturnError:nil]) { return YES; }
    
    NSURL *migrationDirURL = [[[self userStyleDirectoryURL] URLByDeletingLastPathComponent]
                              URLByAppendingPathComponent:@"SyntaxColorings (duplicated)"];
    
    NSArray *styleNames = [self bundledStyleNames];
    BOOL success = NO;
    
    for (NSString *styleName in styleNames) {
        if ([self isEqualToBundledSyntaxStyle:styleName]) {
            [[NSFileManager defaultManager] createDirectoryAtURL:migrationDirURL withIntermediateDirectories:YES attributes:nil error:nil];
            
            NSURL *URL = [self URLOfStyle:styleName];
            NSURL *migrationURL = [[migrationDirURL URLByAppendingPathComponent:styleName] URLByAppendingPathExtension:@"plist"];
            
            if ([migrationDirURL checkResourceIsReachableAndReturnError:nil]) {
                [[NSFileManager defaultManager] removeItemAtURL:migrationURL error:nil];
            }
            success = [[NSFileManager defaultManager] moveItemAtURL:URL toURL:migrationURL error:nil];
        }
    }
    return success;
}

@end
