/*
 
 CESettingManager.h
 
 CotEditor
 http://coteditor.com
 
 Created by 1024jp on 2016-06-11.
 
 ------------------------------------------------------------------------------
 
 © 2016 1024jp
 
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

#import "CESettingManager.h"


// General notification's userInfo keys
extern NSString *_Nonnull const CEOldNameKey;
extern NSString *_Nonnull const CENewNameKey;


@interface CESettingFileManager : CESettingManager

// override rquired
- (nonnull NSString *)filePathExtension;
- (nonnull NSArray<NSString *> *)settingNames;
- (nonnull NSArray<NSString *> *)bundledSettingNames;
- (void)updateCacheWithCompletionHandler:(nullable void (^)())completionHandler;


- (nonnull NSString *)settingNameFromURL:(nonnull NSURL *)fileURL;

// setting file location
- (nullable NSURL *)URLForUsedSettingWithName:(nonnull NSString *)settingNeme;
- (nullable NSURL *)URLForBundledSettingWithName:(nonnull NSString *)settingName available:(BOOL)available;
- (nullable NSURL *)URLForUserSettingWithName:(nonnull NSString *)settingName available:(BOOL)available;
- (nullable NSURL *)URLForUserSettingWithName:(nonnull NSString *)settingName;  // returns nil if file is not available

/// Return whether the setting that has the given name is bundled in the app.
- (BOOL)isBundledSetting:(nonnull NSString *)settingName cutomized:(nullable BOOL *)isCustomized;  // check only the name

// setting name
- (nonnull NSString *)copiedSettingName:(nonnull NSString *)originalName;
- (BOOL)validateSettingName:(nonnull NSString *)settingName originalName:(nonnull NSString *)originalSettingName error:(NSError * _Nullable __autoreleasing * _Nullable)outError;

// manage setting files
- (BOOL)removeSettingWithName:(nonnull NSString *)settingName error:(NSError * _Nullable __autoreleasing * _Nullable)outError;
- (BOOL)restoreSettingWithName:(nonnull NSString *)settingName error:(NSError * _Nullable __autoreleasing * _Nullable)outError;
- (BOOL)duplicateSettingWithName:(nonnull NSString *)settingName error:(NSError * _Nullable __autoreleasing * _Nullable)outError;
- (BOOL)renameSettingWithName:(nonnull NSString *)settingName toName:(nonnull NSString *)newSettingName error:(NSError * _Nullable __autoreleasing * _Nullable)outError;
- (BOOL)exportSettingWithName:(nonnull NSString *)settingName toURL:(nonnull NSURL *)URL error:(NSError * _Nullable __autoreleasing * _Nullable)outError;
- (BOOL)importSettingWithFileURL:(nonnull NSURL *)fileURL error:(NSError * _Nullable __autoreleasing * _Nullable)outError;


@end
