/*
 ==============================================================================
 CEThemeManager
 
 CotEditor
 http://coteditor.com
 
 Created on 2014-04-12 by 1024jp
 encoding="UTF-8"
 ------------------------------------------------------------------------------
 
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

@property (readonly, nonatomic, copy) NSArray *themeNames;


// class method
+ (instancetype)sharedManager;


// public methods
/// Theme dict in which objects are property list ready.
- (NSMutableDictionary *)archivedTheme:(NSString *)themeName isBundled:(BOOL *)isBundled;

/// Return whether the theme that has the given name is bundled with the app.
- (BOOL)isBundledTheme:(NSString *)themeName cutomized:(BOOL *)isCustomized;

// manage themes
- (BOOL)saveTheme:(NSDictionary *)theme name:(NSString *)themeName completionHandler:(void (^)(NSError *error))completionHandler;
- (BOOL)renameTheme:(NSString *)themeName toName:(NSString *)newThemeName error:(NSError **)error;
- (BOOL)removeTheme:(NSString *)themeName error:(NSError **)error;
- (BOOL)restoreTheme:(NSString *)themeName completionHandler:(void (^)(NSError *error))completionHandler;
- (BOOL)duplicateTheme:(NSString *)themeName error:(NSError **)error;
- (BOOL)exportTheme:(NSString *)themeName toURL:(NSURL *)URL error:(NSError **)error;
- (BOOL)importTheme:(NSURL *)URL replace:(BOOL)doReplace error:(NSError **)error;
- (BOOL)createUntitledThemeWithCompletionHandler:(void (^)(NSString *themeName, NSError *error))completionHandler;

@end



// Category for migration from CotEditor 1.x to 2.0. (2014-10)
// It can be removed when the most of users have been already migrated in the future.
@interface CEThemeManager (Migration)

- (BOOL)migrateTheme;

@end
