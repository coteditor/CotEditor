/*
 
 CEKeyBindingManager.h
 
 CotEditor
 http://coteditor.com
 
 Created by nakamuxu on 2005-09-01.

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

#import "CESettingManager.h"


// outlineView data key, column identifier
extern NSString *_Nonnull const CEKeyBindingTitleKey;
extern NSString *_Nonnull const CEKeyBindingKeySpecCharsKey;
extern NSString *_Nonnull const CEKeyBindingSelectorStringKey;
extern NSString *_Nonnull const CEKeyBindingChildrenKey;


@interface CEKeyBindingManager : CESettingManager

@property (nonatomic, nonnull, copy) NSDictionary<NSString *, NSString *> *keyBindingDict;  // overwrite required


// overwrite required
- (nonnull NSString *)settingFileName;
- (nonnull NSDictionary<NSString *, NSString *> *)defaultKeyBindingDict;


- (nonnull NSURL *)keyBindingSettingFileURL;

- (BOOL)usesDefaultKeyBindings;
- (nonnull NSMutableArray<NSMutableDictionary<NSString *, id> *> *)keySpecCharsListForOutlineDataWithFactoryDefaults:(BOOL)usesFactoryDefaults;

- (BOOL)saveKeyBindings:(nonnull NSArray<NSDictionary<NSString *, id> *> *)outlineData;

- (BOOL)validateKeySpecChars:(nonnull NSString *)keySpec oldKeySpecChars:(nonnull NSString *)oldKeySpecChars error:(NSError * _Nullable __autoreleasing * _Nullable)outError;
- (nonnull NSError *)errorWithMessageFormat:(nonnull NSString *)message keySpecChars:(nonnull NSString *)keySpecChars;


@end
