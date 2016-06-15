/*
 
 CESyntaxManager.m
 
 CotEditor
 http://coteditor.com
 
 Created by nakamuxu on 2004-12-24.

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

#import "CESyntaxManager.h"
#import "CESyntaxStyle.h"
#import "CESyntaxDictionaryKeys.h"
#import "CEDefaults.h"

#import <YAML-Framework/YAMLSerialization.h>


// notifications
NSString *_Nonnull const CESyntaxListDidUpdateNotification = @"CESyntaxListDidUpdateNotification";
NSString *_Nonnull const CESyntaxDidUpdateNotification = @"CESyntaxDidUpdateNotification";
NSString *_Nonnull const CESyntaxHistoryDidUpdateNotification = @"CESyntaxHistoryDidUpdateNotification";

// keys for validation result
NSString *_Nonnull const CESyntaxValidationTypeKey = @"SyntaxTypeKey";
NSString *_Nonnull const CESyntaxValidationRoleKey = @"RoleKey";
NSString *_Nonnull const CESyntaxValidationStringKey = @"StringKey";
NSString *_Nonnull const CESyntaxValidationMessageKey = @"MessageKey";


@interface CESyntaxManager ()

@property (nonatomic, nonnull) NSMutableOrderedSet<NSString *> *recentStyleNameSet;
@property (nonatomic) NSUInteger maximumRecentStyleNameCount;
@property (nonatomic, nonnull) NSMutableDictionary<NSString *, NSMutableDictionary *> *styleCaches;  // カラーリング定義のキャッシュ
@property (nonatomic, nonnull, copy) NSDictionary<NSString *, NSDictionary<NSString *, NSArray *> *> *map;  // style名と拡張子/ファイル名の対応テーブル

@property (nonatomic, nonnull, copy) NSArray<NSString *> *bundledStyleNames;  // バンドルされているシンタックススタイル名の配列
@property (nonatomic, nonnull, copy) NSDictionary<NSString *, NSDictionary<NSString *, NSArray *> *> *bundledMap;

@property (nonatomic, nonnull, copy) NSDictionary<NSString *, NSString *> *extensionToStyleTable;  // 拡張子<->styleファイルの変換テーブル辞書(key = 拡張子)
@property (nonatomic, nonnull, copy) NSDictionary<NSString *, NSString *> *filenameToStyleTable;  // ファイル名<->styleファイルの変換テーブル辞書(key = ファイル名)
@property (nonatomic, nonnull, copy) NSDictionary<NSString *, NSString *> *interpreterToStyleTable;  // インタープリタ<->styleファイルの変換テーブル辞書(key = インタープリタ名)


// readonly
@property (readwrite, nonatomic, nonnull, copy) NSArray<NSString *> *styleNames;
@property (readwrite, nonatomic, nonnull, copy) NSDictionary<NSString *, NSMutableArray<NSString *> *> *extensionConflicts;
@property (readwrite, nonatomic, nonnull, copy) NSDictionary<NSString *, NSMutableArray<NSString *> *> *filenameConflicts;

@end




#pragma mark -

@implementation CESyntaxManager

#pragma mark Singleton

// ------------------------------------------------------
/// return singleton instance
+ (nonnull CESyntaxManager *)sharedManager
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
        _recentStyleNameSet = [NSMutableOrderedSet orderedSetWithArray:[[NSUserDefaults standardUserDefaults] stringArrayForKey:CEDefaultRecentlyUsedStyleNamesKey]];
        _maximumRecentStyleNameCount = [[NSUserDefaults standardUserDefaults] integerForKey:CEDefaultMaximumRecentStyleCountKey];
        _styleCaches = [NSMutableDictionary dictionary];
        
        // バンドルされているstyle定義の一覧を読み込んでおく
        NSURL *URL = [[NSBundle mainBundle] URLForResource:@"SyntaxMap" withExtension:@"json"];
        _bundledMap = [NSJSONSerialization JSONObjectWithData:[NSData dataWithContentsOfURL:URL]
                                                      options:0
                                                        error:nil];
        _bundledStyleNames = [[_bundledMap allKeys]
                              sortedArrayUsingSelector:@selector(caseInsensitiveCompare:)];
        
        // cache user styles
        [self updateStyleTables];
        [self setupExtensionAndSyntaxTable];
    }
    return self;
}


//------------------------------------------------------
/// directory name in both Application Support and bundled Resources
- (nonnull NSString *)directoryName
//------------------------------------------------------
{
    return @"Syntaxes";
}


//------------------------------------------------------
/// path extension for user setting file
- (nonnull NSString *)filePathExtension
//------------------------------------------------------
{
    return @"yaml";
}


//------------------------------------------------------
/// list of names of setting file name (without extension)
- (nonnull NSArray<NSString *> *)settingNames
//------------------------------------------------------
{
    return [self styleNames];
}


//------------------------------------------------------
/// list of names of setting file name which are bundled (without extension)
- (nonnull NSArray<NSString *> *)bundledSettingNames
//------------------------------------------------------
{
    return [self bundledStyleNames];
}



#pragma mark Public Methods

// ------------------------------------------------------
/// return recently used style history as an array
- (nonnull NSArray<NSString *> *)recentStyleNames
// ------------------------------------------------------
{
    NSArray *styleNames;
    
    @synchronized ([self recentStyleNameSet]) {
        NSUInteger itemNumber = MIN([[self recentStyleNameSet] count], [self maximumRecentStyleNameCount]);
        styleNames = [[[self recentStyleNameSet] array] subarrayWithRange:NSMakeRange(0, itemNumber)];
    }
    
    return styleNames;
}


// ------------------------------------------------------
/// create new CESyntaxStyle instance
- (nullable CESyntaxStyle *)styleWithName:(NSString *)styleName
// ------------------------------------------------------
{
    CESyntaxStyle *style = nil;
    if (!styleName || [styleName isEqualToString:NSLocalizedString(@"None", nil)]) {
        style = [[CESyntaxStyle alloc] initWithDictionary:nil name:NSLocalizedString(@"None", nil)];
        
    } else if ([[self styleNames] containsObject:styleName]) {
        NSDictionary<NSString *, id> *highlightDictionary = [self styleDictionaryWithStyleName:styleName];
        style = [[CESyntaxStyle alloc] initWithDictionary:highlightDictionary name:styleName];
    }
    
    if (style && styleName) {
        @synchronized ([self recentStyleNameSet]) {
            [[self recentStyleNameSet] removeObject:styleName];
            [[self recentStyleNameSet] insertObject:styleName atIndex:0];
        }
        [[NSUserDefaults standardUserDefaults] setObject:[self recentStyleNames] forKey:CEDefaultRecentlyUsedStyleNamesKey];
        [[NSNotificationCenter defaultCenter] postNotificationName:CESyntaxHistoryDidUpdateNotification
                                                            object:self];
    }
    
    return style;
}


// ------------------------------------------------------
/// ファイル名に応じたstyle名を返す
- (nullable NSString *)styleNameFromDocumentFileName:(nullable NSString *)fileName
// ------------------------------------------------------
{
    NSString *styleName = [self filenameToStyleTable][fileName];
    
    styleName = styleName ? : [self extensionToStyleTable][[fileName pathExtension]];
    
    return styleName;
}


// ------------------------------------------------------
/// 本文からシェバンをスキャンして、内容に応じたstyle名を返す
- (nullable NSString *)styleNameFromDocumentContent:(nonnull NSString *)contentString
// ------------------------------------------------------
{
    NSString *interpreter = [self scanLanguageFromShebangInString:contentString];
    NSString *styleName = [self interpreterToStyleTable][interpreter];
    
    // check XML declaration
    if (!styleName && [contentString hasPrefix:@"<?xml "]) {
        styleName = @"XML";
    }
    
    return styleName;
}


// ------------------------------------------------------
/// style名に応じた拡張子リストを返す
- (nonnull NSArray<NSString *> *)extensionsForStyleName:(nonnull NSString *)styleName
// ------------------------------------------------------
{
    NSArray<NSString *> *extensions = [self map][styleName][CESyntaxExtensionsKey];
    
    return ([extensions count] > 0) ? extensions : @[];
}


// ------------------------------------------------------
/// style名に応じたstyle辞書を返す
- (nonnull NSDictionary<NSString *, id> *)styleDictionaryWithStyleName:(nonnull NSString *)styleName
// ------------------------------------------------------
{
    NSMutableDictionary<NSString *, id> *style;
    
    if (![styleName isEqualToString:@""] && ![styleName isEqualToString:NSLocalizedString(@"None", nil)]) {
        style = [self styleCaches][styleName] ? : [self styleDictWithURL:[self URLForUsedSettingWithName:styleName]];
        
        // 新たに読み込んだ場合はキャッシュする
        if (![self styleCaches][styleName] && style) {
            [self styleCaches][styleName] = style;
        }
    }
    
    return style ? : [self emptyStyleDictionary];  // 存在しない場合は空のデータを返す
}


// ------------------------------------------------------
/// style名に応じたバンドル版のstyle辞書を返す（ない場合はnil）
- (nullable NSDictionary<NSString *, id> *)bundledStyleDictionaryWithStyleName:(nonnull NSString *)styleName
// ------------------------------------------------------
{
    return [self styleDictWithURL:[self URLForBundledSettingWithName:styleName available:NO]];
}


// ------------------------------------------------------
/// スタイルがバンドル版スタイルと同じ内容かどうかを返す
- (BOOL)isEqualToBundledStyle:(nonnull NSDictionary<NSString *, id> *)style name:(nonnull NSString *)styleName
// ------------------------------------------------------
{
    if (![self isBundledSetting:styleName cutomized:nil]) { return NO; }
    
    // numOfObjInArray などが混入しないようにスタイル定義部分だけを比較する
    NSArray<NSString *> *keys = [[self emptyStyleDictionary] allKeys];
    NSDictionary<NSString *, id> *bundledStyle = [[self bundledStyleDictionaryWithStyleName:styleName] dictionaryWithValuesForKeys:keys];
    
    return [[style dictionaryWithValuesForKeys:keys] isEqualToDictionary:bundledStyle];
}


//------------------------------------------------------
/// 外部 style ファイルをユーザ領域にコピーする
- (BOOL)importSettingWithFileURL:(NSURL *)fileURL error:(NSError *__autoreleasing  _Nullable *)outError
//------------------------------------------------------
{
    if ([[fileURL pathExtension] isEqualToString:@"plist"]) {
        return [self importLegacyStyleWithFileURL:fileURL];
    }
    
    return [super importSettingWithFileURL:fileURL error:nil];
}


//------------------------------------------------------
/// style名に応じたstyleファイルを削除する
- (BOOL)removeSettingWithName:(NSString *)settingName error:(NSError *__autoreleasing  _Nullable *)outError
//------------------------------------------------------
{
    BOOL success = [super removeSettingWithName:settingName error:outError];
    
    // 内部で持っているキャッシュ用データを更新
    [[self styleCaches] removeObjectForKey:settingName];
    
    __weak typeof(self) weakSelf = self;
    [self updateCacheWithCompletionHandler:^{
        typeof(self) self = weakSelf;  // strong self
        
        [[NSNotificationCenter defaultCenter] postNotificationName:CESyntaxDidUpdateNotification
                                                            object:self
                                                          userInfo:@{CEOldNameKey: settingName,
                                                                     CENewNameKey: NSLocalizedString(@"None", nil)}];
    }];
    
    return success;
}


//------------------------------------------------------
/// style名に応じたstyleファイルをリストアする
- (BOOL)restoreSettingWithName:(NSString *)settingName error:(NSError *__autoreleasing  _Nullable *)outError
//------------------------------------------------------
{
    BOOL success = [super restoreSettingWithName:settingName error:outError];
    
    // 内部で持っているキャッシュ用データを更新
    [self styleCaches][settingName] = [[self bundledStyleDictionaryWithStyleName:settingName] mutableCopy];
    
    __weak typeof(self) weakSelf = self;
    [self updateCacheWithCompletionHandler:^{
        typeof(self) self = weakSelf;  // strong self
        
        [[NSNotificationCenter defaultCenter] postNotificationName:CESyntaxDidUpdateNotification
                                                            object:self
                                                          userInfo:@{CEOldNameKey: settingName,
                                                                     CENewNameKey: settingName}];
    }];
    
    return success;
}


//------------------------------------------------------
/// styleのファイルへの保存
- (void)saveStyle:(nonnull NSMutableDictionary<NSString *, id> *)style name:(nonnull NSString *)name oldName:(nonnull NSString *)oldName
//------------------------------------------------------
{
    if ([name length] == 0) { return; }
    
    // sanitize
    [(NSMutableArray<NSDictionary *> *)style[CESyntaxExtensionsKey] removeObject:@{}];
    [(NSMutableArray<NSDictionary *> *)style[CESyntaxFileNamesKey] removeObject:@{}];
    [(NSMutableArray<NSDictionary *> *)style[CESyntaxInterpretersKey] removeObject:@{}];
    
    // sort
    NSArray<NSSortDescriptor *> *descriptors = @[[NSSortDescriptor sortDescriptorWithKey:CESyntaxBeginStringKey
                                                                               ascending:YES
                                                                                selector:@selector(caseInsensitiveCompare:)],
                                                 [NSSortDescriptor sortDescriptorWithKey:CESyntaxKeyStringKey
                                                                               ascending:YES
                                                                                selector:@selector(caseInsensitiveCompare:)]];
    
    NSMutableArray<NSString *> *syntaxDictKeys = [NSMutableArray array];
    for (NSUInteger i = 0; i < kSizeOfAllSyntaxKeys; i++) {
        [syntaxDictKeys addObject:kAllSyntaxKeys[i]];
    }
    [syntaxDictKeys addObjectsFromArray:@[CESyntaxOutlineMenuKey,
                                          CESyntaxCompletionsKey]];
    
    for (NSString *key in syntaxDictKeys) {
        [style[key] sortUsingDescriptors:descriptors];
    }
    
    // ユーザ領域にシンタックス定義用ディレクトリがまだない場合は作成する
    if (![self prepareUserSettingDirectory]) { return; }
    
    // save
    NSURL *saveURL = [self URLForUserSettingWithName:name available:NO];
    // style名が変更されたときは、古いファイルを削除する
    if (![name isEqualToString:oldName]) {
        [[NSFileManager defaultManager] removeItemAtURL:[self URLForUserSettingWithName:oldName available:NO] error:nil];
    }
    // 保存しようとしている定義がバンドル版と同じだった場合（出荷時に戻したときなど）はユーザ領域のファイルを削除して終わる
    if ([style isEqualToDictionary:[self bundledStyleDictionaryWithStyleName:name]]) {
        if ([saveURL checkResourceIsReachableAndReturnError:nil]) {
            [[NSFileManager defaultManager] removeItemAtURL:saveURL error:nil];
            [[self styleCaches] removeObjectForKey:name];
        }
    } else {
        // 保存
        NSData *yamlData = [YAMLSerialization YAMLDataWithObject:style
                                                         options:kYAMLWriteOptionSingleDocument
                                                           error:nil];
        [yamlData writeToURL:saveURL atomically:YES];
    }
    
    // 内部で持っているキャッシュ用データを更新
    __weak typeof(self) weakSelf = self;
    [self updateCacheWithCompletionHandler:^{
        typeof(self) self = weakSelf;  // strong self
        
        // notify
        [[NSNotificationCenter defaultCenter] postNotificationName:CESyntaxDidUpdateNotification
                                                            object:self
                                                          userInfo:@{CEOldNameKey: oldName,
                                                                     CENewNameKey: name}];
    }];
}


//------------------------------------------------------
/// マッピング重複エラーがあるかどうかを返す
- (BOOL)existsMappingConflict
//------------------------------------------------------
{
    return (([[self extensionConflicts] count] + [[self filenameConflicts] count]) > 0);
}


// ------------------------------------------------------
/// 正規表現構文と重複のチェック実行をしてエラーメッセージ(NSDictionary)のArrayを返す
- (nonnull NSArray<NSDictionary<NSString *, NSString *> *> *)validateSyntax:(nonnull NSDictionary *)style
// ------------------------------------------------------
{
    NSMutableArray<NSDictionary<NSString *, NSString *> *> *results = [NSMutableArray array];
    NSString *tmpBeginStr = nil, *tmpEndStr = nil;
    NSError *error = nil;
    
    NSMutableArray<NSString *> *syntaxDictKeys = [[NSMutableArray alloc] initWithCapacity:(kSizeOfAllSyntaxKeys + 1)];
    for (NSUInteger i = 0; i < kSizeOfAllSyntaxKeys; i++) {
        [syntaxDictKeys addObject:kAllSyntaxKeys[i]];
    }
    [syntaxDictKeys addObject:CESyntaxOutlineMenuKey];
    
    for (NSString *key in syntaxDictKeys) {
        NSMutableArray<NSDictionary<NSString *, id> *> *dicts = [style[key] mutableCopy];
        
        // sort for duplication check
        [dicts sortUsingComparator:^NSComparisonResult(id obj1, id obj2) {
            NSComparisonResult result = [obj1[CESyntaxBeginStringKey] compare:obj2[CESyntaxBeginStringKey]];
            if (result == NSOrderedSame) {
                result = [obj1[CESyntaxEndStringKey] compare:obj2[CESyntaxEndStringKey]];
            }
            return result;
        }];
        
        for (NSDictionary<NSString *, id> *dict in dicts) {
            NSString *beginStr = dict[CESyntaxBeginStringKey];
            NSString *endStr = dict[CESyntaxEndStringKey];
            
            if ([tmpBeginStr isEqualToString:beginStr] &&
                ((!tmpEndStr && !endStr) || [tmpEndStr isEqualToString:endStr])) {
                [results addObject:@{CESyntaxValidationTypeKey: NSLocalizedString(key, nil),
                                     CESyntaxValidationRoleKey: NSLocalizedString(@"Begin string", nil),
                                     CESyntaxValidationStringKey: beginStr,
                                     CESyntaxValidationMessageKey: NSLocalizedString(@"multiple registered.", nil)}];
                
            } else if ([dict[CESyntaxRegularExpressionKey] boolValue]) {
                error = nil;
                [NSRegularExpression regularExpressionWithPattern:beginStr options:0 error:&error];
                if (error) {
                    [results addObject:@{CESyntaxValidationTypeKey: NSLocalizedString(key, nil),
                                         CESyntaxValidationRoleKey: NSLocalizedString(@"Begin string", nil),
                                         CESyntaxValidationStringKey: beginStr,
                                         CESyntaxValidationMessageKey: [NSString stringWithFormat:NSLocalizedString(@"Regex Error: %@", nil),
                                                                        [error localizedFailureReason]]}];
                }
                
                if (endStr) {
                    error = nil;
                    [NSRegularExpression regularExpressionWithPattern:endStr options:0 error:&error];
                    if (error) {
                        [results addObject:@{CESyntaxValidationTypeKey: NSLocalizedString(key, nil),
                                             CESyntaxValidationRoleKey: NSLocalizedString(@"End string", nil),
                                             CESyntaxValidationStringKey: endStr,
                                             CESyntaxValidationMessageKey: [NSString stringWithFormat:NSLocalizedString(@"Regex Error: %@", nil),
                                                                            [error localizedFailureReason]]}];
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
    
    return [results copy];
}


//------------------------------------------------------
/// 空の新規 style を返す
- (nonnull NSDictionary<NSString *, id> *)emptyStyleDictionary
//------------------------------------------------------
{
    return @{CESyntaxMetadataKey: [NSMutableDictionary dictionary],
             CESyntaxExtensionsKey: [NSMutableArray array],
             CESyntaxFileNamesKey: [NSMutableArray array],
             CESyntaxInterpretersKey: [NSMutableArray array],
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

//------------------------------------------------------
/// URLからスタイル辞書を返す
- (nullable NSMutableDictionary<NSString *, id> *)styleDictWithURL:(NSURL *)URL
//------------------------------------------------------
{
    NSData *yamlData = [NSData dataWithContentsOfURL:URL];
    
    return [YAMLSerialization objectWithYAMLData:yamlData
                                         options:kYAMLReadOptionMutableContainersAndLeaves
                                           error:nil];
}


// ------------------------------------------------------
/// 内部で持っているキャッシュ用データを更新
- (void)updateCacheWithCompletionHandler:(nullable void (^)())completionHandler
// ------------------------------------------------------
{
    __weak typeof(self) weakSelf = self;
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        typeof(self) self = weakSelf;  // strong self
        if (!self) { return; }
        
        [self updateStyleTables];
        [self setupExtensionAndSyntaxTable];
        
        dispatch_sync(dispatch_get_main_queue(), ^{
            // Notificationを発行
            [[NSNotificationCenter defaultCenter] postNotificationName:CESyntaxListDidUpdateNotification
                                                                object:self];
            
            if (completionHandler) {
                completionHandler();
            }
        });
    });
}


//------------------------------------------------------
/// ユーザ領域のスタイル定義を読み直しキャッシュおよびマッピングテーブルを再構築する
- (void)updateStyleTables
//------------------------------------------------------
{
    NSURL *dirURL = [self userSettingDirectoryURL]; // ユーザディレクトリパス取得
    NSMutableDictionary<NSString *, NSDictionary<NSString *, NSArray *> *> *map = [[self bundledMap] mutableCopy];
    
    // ユーザ定義用ディレクトリが存在する場合は読み込む
    if ([dirURL checkResourceIsReachableAndReturnError:nil]) {
        NSArray<NSURL *> *URLs = [[NSFileManager defaultManager] contentsOfDirectoryAtURL:dirURL
                                                               includingPropertiesForKeys:nil
                                                                                  options:NSDirectoryEnumerationSkipsSubdirectoryDescendants | NSDirectoryEnumerationSkipsHiddenFiles
                                                                                    error:nil];
        for (NSURL *URL in URLs) {
            if (![@[[self filePathExtension], @"yml"] containsObject:[URL pathExtension]]) { continue; }
            
            NSString *styleName = [self settingNameFromURL:URL];
            NSMutableDictionary<NSString *, id> *style = [self styleDictWithURL:URL];
            
            // URLが無効だった場合などに、dictがnilになる場合がある
            if (!style) { continue; }
            
            map[styleName] = @{CESyntaxExtensionsKey: [self keyStringsFromDicts:style[CESyntaxExtensionsKey]],
                               CESyntaxFileNamesKey: [self keyStringsFromDicts:style[CESyntaxFileNamesKey]],
                               CESyntaxInterpretersKey: [self keyStringsFromDicts:style[CESyntaxInterpretersKey]]};
            
            // せっかく読み込んだのでキャッシュしておく
            [self styleCaches][styleName] = style;
        }
    }
    [self setMap:map];
    
    // 定義をアルファベット順にソートする
    NSMutableArray<NSString *> *styleNames = [[map allKeys] mutableCopy];
    [styleNames sortUsingSelector:@selector(caseInsensitiveCompare:)];
    [self setStyleNames:styleNames];
    
    // remove deleted styles
    // -> don't care about style name change just for laziness
    @synchronized ([self recentStyleNameSet]) {
        [[self recentStyleNameSet] intersectSet:[NSSet setWithArray:styleNames]];
    }
    [[NSUserDefaults standardUserDefaults] setObject:[self recentStyleNames] forKey:CEDefaultRecentlyUsedStyleNamesKey];
}


// ------------------------------------------------------
/// 拡張子<->styleファイルの変換テーブル辞書(key = 拡張子)と、拡張子辞書、拡張子重複エラー辞書を更新
- (void)setupExtensionAndSyntaxTable
// ------------------------------------------------------
{
    NSMutableOrderedSet<NSString *> *styleNames = [NSMutableOrderedSet orderedSetWithArray:[self styleNames]];
    NSMutableDictionary<NSString *, NSString *> *extensionToStyleTable = [NSMutableDictionary dictionary];
    NSMutableDictionary<NSString *, NSMutableArray<NSString *> *> *extensionConflicts = [NSMutableDictionary dictionary];
    NSMutableDictionary<NSString *, NSString *> *filenameToStyleTable = [NSMutableDictionary dictionary];
    NSMutableDictionary<NSString *, NSMutableArray<NSString *> *> *filenameConflicts = [NSMutableDictionary dictionary];
    NSMutableDictionary<NSString *, NSString *> *interpreterToStyleTable = [NSMutableDictionary dictionary];
    NSString *addedName = nil;
    
    // postpone bundled styles
    [styleNames removeObjectsInArray:[self bundledStyleNames]];
    [styleNames addObjectsFromArray:[self bundledStyleNames]];
    
    for (NSString *styleName in styleNames) {
        for (NSString *extension in [self map][styleName][CESyntaxExtensionsKey]) {
            if ((addedName = extensionToStyleTable[extension])) { // 同じ拡張子を持つものがすでにあるとき
                NSMutableArray<NSString *> *errors = extensionConflicts[extension];
                if (!errors) {
                    errors = [NSMutableArray array];
                    [extensionConflicts setValue:errors forKey:extension];
                }
                if (![errors containsObject:addedName]) {
                    [errors addObject:addedName];
                }
                [errors addObject:styleName];
            } else {
                [extensionToStyleTable setValue:styleName forKey:extension];
            }
        }
        
        for (NSString *filename in [self map][styleName][CESyntaxFileNamesKey]) {
            if ((addedName = filenameToStyleTable[filename])) { // 同じファイル名を持つものがすでにあるとき
                NSMutableArray<NSString *> *errors = filenameConflicts[filename];
                if (!errors) {
                    errors = [NSMutableArray array];
                    [filenameConflicts setValue:errors forKey:filename];
                }
                if (![errors containsObject:addedName]) {
                    [errors addObject:addedName];
                }
                [errors addObject:styleName];
            } else {
                [filenameToStyleTable setValue:styleName forKey:filename];
            }
        }
        
        for (NSString *interpreter in [self map][styleName][CESyntaxInterpretersKey]) {
            if ((addedName = interpreterToStyleTable[interpreter])) { // 同じインタープリタ名を持つものがすでにあるとき
//                NSMutableArray<NSString *> *errors = interpreterConflicts[interpreter];
//                if (!errors) {
//                    errors = [NSMutableArray array];
//                    [interpreterConflicts setValue:errors forKey:interpreter];
//                }
//                if (![errors containsObject:addedName]) {
//                    [errors addObject:addedName];
//                }
//                [errors addObject:styleName];
            } else {
                [interpreterToStyleTable setValue:styleName forKey:interpreter];
            }
        }
    }
    [self setExtensionToStyleTable:extensionToStyleTable];
    [self setExtensionConflicts:extensionConflicts];
    [self setFilenameToStyleTable:filenameToStyleTable];
    [self setFilenameConflicts:filenameConflicts];
    [self setInterpreterToStyleTable:interpreterToStyleTable];
}


// ------------------------------------------------------
/// 辞書の array から keyString をキーに持つ string を集めて返す
- (nonnull NSArray<NSString *> *)keyStringsFromDicts:(nonnull NSArray *)dicts
// ------------------------------------------------------
{
    NSMutableArray<NSString *> *strings = [NSMutableArray array];
    
    for (NSDictionary *dict in dicts) {
        [strings addObject:dict[CESyntaxKeyStringKey]];
    }
    
    return [strings copy];
}


// ------------------------------------------------------
/// try extracting used language from the shebang line
- (nullable NSString *)scanLanguageFromShebangInString:(nonnull NSString *)string
// ------------------------------------------------------
{
    // get first line
    __block NSString *firstLine = nil;
    [string enumerateLinesUsingBlock:^(NSString *line, BOOL *stop) {
        firstLine = line;
        *stop = YES;
    }];
    
    // not found
    if (![firstLine hasPrefix:@"#!"]) { return nil; }
    
    // remove #! symbol
    firstLine = [firstLine stringByReplacingOccurrencesOfString:@"^#! *" withString:@""
                                                        options:NSRegularExpressionSearch
                                                          range:NSMakeRange(0, [firstLine length])];
    
    // find interpreter
    NSArray<NSString *> *components = [firstLine componentsSeparatedByString:@" "];
    NSString * path = components[0];
    NSString *interpreter = [[path componentsSeparatedByString:@"/"] lastObject];
    // use first arg if the path targets env
    if ([interpreter isEqualToString:@"env"]) {
        interpreter = components[1];
    }
    
    return interpreter;
}

@end




#pragma mark -

@implementation CESyntaxManager (Migration)

// ------------------------------------------------------
/// CotEditor 1.x から CotEdito 2.0 への移行
- (void)migrateStylesWithCompletionHandler:(nullable void (^)(BOOL success))completionHandler;
// ------------------------------------------------------
{
    BOOL success = NO;
    NSURL *oldDirURL = [[[self userSettingDirectoryURL] URLByDeletingLastPathComponent] URLByAppendingPathComponent:@"SyntaxColorings"];
    
    // 移行の必要性チェック
    if (![oldDirURL checkResourceIsReachableAndReturnError:nil] ||
        [[self userSettingDirectoryURL] checkResourceIsReachableAndReturnError:nil])
    {
        completionHandler(NO);
        return;
    }
    
    [self prepareUserSettingDirectory];
    
    NSArray<NSURL *> *URLs = [[NSFileManager defaultManager] contentsOfDirectoryAtURL:oldDirURL
                                                           includingPropertiesForKeys:nil
                                                                              options:NSDirectoryEnumerationSkipsSubdirectoryDescendants | NSDirectoryEnumerationSkipsHiddenFiles
                                                                                error:nil];
    
    for (NSURL *URL in URLs) {
        if ([self importLegacyStyleWithFileURL:URL]) {
            success = YES;
        }
    }
    
    if (completionHandler) {
        if (success) {
            [self updateCacheWithCompletionHandler:^{
                completionHandler(YES);
            }];
        } else {
            completionHandler(NO);
        }
    }
}


// ------------------------------------------------------
/// plist 形式のシンタックス定義を YAML 形式に変換してユーザ領域に保存
- (BOOL)importLegacyStyleWithFileURL:(nonnull NSURL *)fileURL
// ------------------------------------------------------
{
    if (![[fileURL pathExtension] isEqualToString:@"plist"]) { return NO; }

    __block BOOL success = NO;
    NSString *styleName = [self settingNameFromURL:fileURL];
    NSURL *destURL = [self URLForUserSettingWithName:styleName available:NO];
    
    NSFileCoordinator *coordinator = [[NSFileCoordinator alloc] initWithFilePresenter:nil];
    [coordinator coordinateReadingItemAtURL:fileURL options:NSFileCoordinatorReadingWithoutChanges
                           writingItemAtURL:destURL options:0
                                      error:nil byAccessor:^(NSURL *newReadingURL, NSURL *newWritingURL)
     {
         NSDictionary<NSString *, id> *style = [NSDictionary dictionaryWithContentsOfURL:fileURL];
         
         if (!style) { return; }
         
         NSMutableDictionary<NSString *, id> *newStyle = [NSMutableDictionary dictionary];
         
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
