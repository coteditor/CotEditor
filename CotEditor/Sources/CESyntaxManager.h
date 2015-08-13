/*
 
 CESyntaxManager.h
 
 CotEditor
 http://coteditor.com
 
 Created by nakamuxu on 2004-12-24.

 ------------------------------------------------------------------------------
 
 © 2004-2007 nakamuxu
 © 2014 1024jp
 
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


// singleton
+ (instancetype)sharedManager;


// public methods
- (NSString *)styleNameFromFileName:(NSString *)fileName;
- (NSString *)styleNameFromInterpreter:(NSString *)interpreter;
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
