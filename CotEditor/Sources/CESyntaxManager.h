/*
 
 CESyntaxManager.h
 
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

#import "CESettingFileManager.h"


// notifications
/// Posted when the line-up of syntax styles is updated.  This will be used for syntax style menus.
extern NSString *_Nonnull const CESyntaxListDidUpdateNotification;

/// Posted when the recently used style list is updated.  This will be used for syntax style menu in toolbar.
extern NSString *_Nonnull const CESyntaxHistoryDidUpdateNotification;

/// Posted when a syntax style is updated.  Information about new/previous style name is in userInfo.
extern NSString *_Nonnull const CESyntaxDidUpdateNotification;

// keys for validation result
extern NSString *_Nonnull const CESyntaxValidationTypeKey;
extern NSString *_Nonnull const CESyntaxValidationRoleKey;
extern NSString *_Nonnull const CESyntaxValidationStringKey;
extern NSString *_Nonnull const CESyntaxValidationMessageKey;


@class CESyntaxStyle;


@interface CESyntaxManager : CESettingFileManager

// readonly
@property (readonly, nonatomic, nonnull, copy) NSArray<NSString *> *styleNames;

@property (readonly, nonatomic, nonnull, copy) NSArray<NSString *> *recentStyleNames;

/// conflict error dicts
@property (readonly, nonatomic, nonnull, copy) NSDictionary<NSString *, NSMutableArray<NSString *> *> *extensionConflicts;
@property (readonly, nonatomic, nonnull, copy) NSDictionary<NSString *, NSMutableArray<NSString *> *> *filenameConflicts;


// singleton
+ (nonnull CESyntaxManager *)sharedManager;


// public methods
- (nullable CESyntaxStyle *)styleWithName:(nullable NSString *)styleName;

- (nullable NSString *)styleNameFromDocumentFileName:(nullable NSString *)fileName;
- (nullable NSString *)styleNameFromDocumentContent:(nonnull NSString *)contentString;
- (nonnull NSArray<NSString *> *)extensionsForStyleName:(nonnull NSString *)styleName;
- (nonnull NSDictionary<NSString *, id> *)styleDictionaryWithStyleName:(nonnull NSString *)styleName;
- (nullable NSDictionary<NSString *, id> *)bundledStyleDictionaryWithStyleName:(nonnull NSString *)styleName;
- (nonnull NSDictionary<NSString *, id> *)emptyStyleDictionary;

- (BOOL)isEqualToBundledStyle:(nonnull NSDictionary<NSString *, id> *)style name:(nonnull NSString *)styleName;

// manage styles
- (void)saveStyle:(nonnull NSMutableDictionary<NSString *, id> *)style name:(nonnull NSString *)name oldName:(nonnull NSString *)oldName;

- (BOOL)existsMappingConflict;
- (nonnull NSArray<NSDictionary<NSString *, NSString *> *> *)validateSyntax:(nonnull NSDictionary<NSString *, id> *)style;

@end



// Category for migration from CotEditor 1.x to 2.0. (2014-10)
// It can be removed when the most of users have been already migrated in the future.
@interface CESyntaxManager (Migration)

- (void)migrateStylesWithCompletionHandler:(nullable void (^)(BOOL success))completionHandler;
- (BOOL)importLegacyStyleWithFileURL:(nonnull NSURL *)fileURL;

@end
