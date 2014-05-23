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


#import <Foundation/Foundation.h>


// keys for theme dict
extern NSString *const CEThemeTextColorKey;
extern NSString *const CEThemeBackgroundColorKey;
extern NSString *const CEThemeInvisiblesColorKey;
extern NSString *const CEThemeSelectionColorKey;
extern NSString *const CEThemeInsertionPointColorKey;
extern NSString *const CEThemeLineHighlightColorKey;

extern NSString *const CEThemeKeywordsColorKey;
extern NSString *const CEThemeCommandsColorKey;
extern NSString *const CEThemeTypesColorKey;
extern NSString *const CEThemeVariablesColorKey;
extern NSString *const CEThemeValuesColorKey;
extern NSString *const CEThemeNumbersColorKey;
extern NSString *const CEThemeStringsColorKey;
extern NSString *const CEThemeCharactersColorKey;
extern NSString *const CEThemeCommentsColorKey;

extern NSString *const CEThemeUsesSystemSelectionColorKey;


// notifications
extern NSString *const CEThemeListDidUpdateNotification;
extern NSString *const CEThemeDidUpdateNotification;



@interface CEThemeManager : NSObject

@property (nonatomic, copy, readonly) NSArray *themeNames;


// class method
+ (instancetype)sharedManager;


// public methods
/// Theme dict in which objects are property list ready.
- (NSMutableDictionary *)archivedTheme:(NSString *)themeName isBundled:(BOOL *)isBundled;

// manage themes
- (BOOL)isBundledTheme:(NSString *)themeName cutomized:(BOOL *)isCustomized;
- (BOOL)saveTheme:(NSDictionary *)theme name:(NSString *)themeName;
- (BOOL)renameTheme:(NSString *)themeName toName:(NSString *)newThemeName error:(NSError **)error;
- (BOOL)removeTheme:(NSString *)themeName error:(NSError **)error;
- (BOOL)restoreTheme:(NSString *)themeName;
- (BOOL)duplicateTheme:(NSString *)themeName;
- (BOOL)exportTheme:(NSString *)themeName toURL:(NSURL *)URL;
- (BOOL)importTheme:(NSURL *)URL error:(NSError **)error;
- (BOOL)createUntitledTheme:(NSString **)themeName;

@end
