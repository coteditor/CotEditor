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

@import Foundation;


// notifications
/// Posted when the line-up of syntax styles is updated.  This will be used for syntax style menus.
extern NSString *const CESyntaxListDidUpdateNotification;

/// Posted when a syntax style is updated.  Information about new/previous style name is in userInfo.
extern NSString *const CESyntaxDidUpdateNotification;

// keys for validation result
extern NSString *const CESyntaxValidationTypeKey;
extern NSString *const CESyntaxValidationRoleKey;
extern NSString *const CESyntaxValidationStringKey;
extern NSString *const CESyntaxValidationMessageKey;


@interface CESyntaxManager : NSObject

// readonly
@property (readonly, nonatomic, copy) NSArray *styleNames;
/// conflict error dicts
@property (readonly, nonatomic, copy) NSDictionary *extensionConflicts;
@property (readonly, nonatomic, copy) NSDictionary *filenameConflicts;


// class method
+ (instancetype)sharedManager;


// public methods
- (NSString *)styleNameFromFileName:(NSString *)fileName;
- (NSArray *)extensionsForStyleName:(NSString *)styleName;
- (NSDictionary *)styleWithStyleName:(NSString *)styleName;
- (NSDictionary *)bundledStyleWithStyleName:(NSString *)styleName;
- (NSDictionary *)emptyStyle;
- (NSURL *)URLForUserStyle:(NSString *)styleName;  // returns nil if file is not available
- (BOOL)isBundledStyle:(NSString *)styleName;  // check only the name
- (BOOL)isEqualToBundledStyle:(NSDictionary *)style name:(NSString *)styleName;
- (BOOL)importStyleFromURL:(NSURL *)fileURL;
- (BOOL)exportStyle:(NSString *)styleName toURL:(NSURL *)fileURL;
- (BOOL)removeStyleFileWithStyleName:(NSString *)styleName;
- (BOOL)existsMappingConflict;
- (NSString *)copiedStyleName:(NSString *)originalName;
- (void)saveStyle:(NSMutableDictionary *)style name:(NSString *)name oldName:(NSString *)oldName;
- (NSArray *)validateSyntax:(NSDictionary *)style;

@end



// Category for migration from CotEditor 1.x to 2.0. (2014-10)
// It can be removed when the most of users have been already migrated in the future.
@interface CESyntaxManager (Migration)

- (void)migrateStylesWithCompletionHandler:(void (^)(BOOL success))completionHandler;
- (BOOL)importLegacyStyleFromURL:(NSURL *)fileURL;

@end
