/*
 
 CEThemeManager.h
 
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

@import AppKit;


// extension for theme file
extern NSString *_Nonnull const CEThemeExtension;

// keys for theme dict
extern NSString *_Nonnull const CEThemeTextKey;
extern NSString *_Nonnull const CEThemeBackgroundKey;
extern NSString *_Nonnull const CEThemeInvisiblesKey;
extern NSString *_Nonnull const CEThemeSelectionKey;
extern NSString *_Nonnull const CEThemeInsertionPointKey;
extern NSString *_Nonnull const CEThemeLineHighlightKey;

extern NSString *_Nonnull const CEThemeKeywordsKey;
extern NSString *_Nonnull const CEThemeCommandsKey;
extern NSString *_Nonnull const CEThemeTypesKey;
extern NSString *_Nonnull const CEThemeAttributesKey;
extern NSString *_Nonnull const CEThemeVariablesKey;
extern NSString *_Nonnull const CEThemeValuesKey;
extern NSString *_Nonnull const CEThemeNumbersKey;
extern NSString *_Nonnull const CEThemeStringsKey;
extern NSString *_Nonnull const CEThemeCharactersKey;
extern NSString *_Nonnull const CEThemeCommentsKey;

extern NSString *_Nonnull const CEThemeColorKey;
extern NSString *_Nonnull const CEThemeUsesSystemSettingKey;


// notifications
extern NSString *_Nonnull const CEThemeListDidUpdateNotification;
extern NSString *_Nonnull const CEThemeDidUpdateNotification;



@interface CEThemeManager : NSObject

@property (readonly, nonatomic, nonnull, copy) NSArray<NSString *> *themeNames;


// singleton
+ (nonnull instancetype)sharedManager;


// public methods
/// Theme dict in which objects are property list ready.
- (nullable NSMutableDictionary<NSString *, NSMutableDictionary<NSString *, id> *> *)archivedTheme:(nonnull NSString *)themeName isBundled:(nullable BOOL *)isBundled;

/// Return whether the theme that has the given name is bundled with the app.
- (BOOL)isBundledTheme:(nonnull NSString *)themeName cutomized:(nullable BOOL *)isCustomized;

- (nullable NSURL *)URLForUserTheme:(nonnull NSString *)themeName;  // returns nil if file is not available

// manage themes
- (BOOL)saveTheme:(nonnull NSDictionary<NSString *, NSDictionary<NSString *, id> *> *)theme name:(nonnull NSString *)themeName completionHandler:(nullable void (^)(NSError *_Nullable error))completionHandler;
- (BOOL)renameTheme:(nonnull NSString *)themeName toName:(nonnull NSString *)newThemeName error:(NSError * _Nullable __autoreleasing * _Nullable)outError;
- (BOOL)removeTheme:(nonnull NSString *)themeName error:(NSError * _Nullable __autoreleasing * _Nullable)outError;
- (BOOL)restoreTheme:(nonnull NSString *)themeName completionHandler:(nullable void (^)(NSError *_Nullable error))completionHandler;
- (BOOL)duplicateTheme:(nonnull NSString *)themeName error:(NSError * _Nullable __autoreleasing * _Nullable)outError;
- (BOOL)exportTheme:(nonnull NSString *)themeName toURL:(nonnull NSURL *)URL error:(NSError * _Nullable __autoreleasing * _Nullable)outError;
- (BOOL)importTheme:(nonnull NSURL *)URL replace:(BOOL)doReplace error:(NSError * _Nullable __autoreleasing * _Nullable)outError;
- (BOOL)createUntitledThemeWithCompletionHandler:(nullable void (^)(NSString *_Nonnull themeName, NSError *_Nullable error))completionHandler;

@end



// Category for migration from CotEditor 1.x to 2.0. (2014-10)
// It can be removed when the most of users have been already migrated in the future.
@interface CEThemeManager (Migration)

- (BOOL)migrateTheme;

@end
