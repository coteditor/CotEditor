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
extern NSString *const CEThemeExtension;

// keys for theme dict
extern NSString *const CEThemeTextKey;
extern NSString *const CEThemeBackgroundKey;
extern NSString *const CEThemeInvisiblesKey;
extern NSString *const CEThemeSelectionKey;
extern NSString *const CEThemeInsertionPointKey;
extern NSString *const CEThemeLineHighlightKey;

extern NSString *const CEThemeKeywordsKey;
extern NSString *const CEThemeCommandsKey;
extern NSString *const CEThemeTypesKey;
extern NSString *const CEThemeAttributesKey;
extern NSString *const CEThemeVariablesKey;
extern NSString *const CEThemeValuesKey;
extern NSString *const CEThemeNumbersKey;
extern NSString *const CEThemeStringsKey;
extern NSString *const CEThemeCharactersKey;
extern NSString *const CEThemeCommentsKey;

extern NSString *const CEThemeColorKey;
extern NSString *const CEThemeUsesSystemSettingKey;


// notifications
extern NSString *const CEThemeListDidUpdateNotification;
extern NSString *const CEThemeDidUpdateNotification;



@interface CEThemeManager : NSObject

@property (readonly, nonatomic, copy) NSArray<NSString *> *themeNames;


// singleton
+ (instancetype)sharedManager;


// public methods
/// Theme dict in which objects are property list ready.
- (NSMutableDictionary<NSString *, NSMutableDictionary<NSString *, id> *> *)archivedTheme:(NSString *)themeName isBundled:(BOOL *)isBundled;

/// Return whether the theme that has the given name is bundled with the app.
- (BOOL)isBundledTheme:(NSString *)themeName cutomized:(BOOL *)isCustomized;

// manage themes
- (BOOL)saveTheme:(NSDictionary<NSString *, NSDictionary<NSString *, id> *> *)theme name:(NSString *)themeName completionHandler:(void (^)(NSError *error))completionHandler;
- (BOOL)renameTheme:(NSString *)themeName toName:(NSString *)newThemeName error:(NSError **)outError;
- (BOOL)removeTheme:(NSString *)themeName error:(NSError **)outError;
- (BOOL)restoreTheme:(NSString *)themeName completionHandler:(void (^)(NSError *error))completionHandler;
- (BOOL)duplicateTheme:(NSString *)themeName error:(NSError **)outError;
- (BOOL)exportTheme:(NSString *)themeName toURL:(NSURL *)URL error:(NSError **)outError;
- (BOOL)importTheme:(NSURL *)URL replace:(BOOL)doReplace error:(NSError **)outError;
- (BOOL)createUntitledThemeWithCompletionHandler:(void (^)(NSString *themeName, NSError *error))completionHandler;

@end



// Category for migration from CotEditor 1.x to 2.0. (2014-10)
// It can be removed when the most of users have been already migrated in the future.
@interface CEThemeManager (Migration)

- (BOOL)migrateTheme;

@end
