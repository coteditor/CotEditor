/*
 
 CEKeyBindingManager.h
 
 CotEditor
 http://coteditor.com
 
 Created by nakamuxu on 2005-09-01.

 ------------------------------------------------------------------------------
 
 © 2004-2007 nakamuxu
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

@import Cocoa;


// outlineView data key, column identifier
extern NSString *_Nonnull const CEKeyBindingTitleKey;
extern NSString *_Nonnull const CEKeyBindingKeySpecCharsKey;
extern NSString *_Nonnull const CEKeyBindingSelectorStringKey;
extern NSString *_Nonnull const CEKeyBindingChildrenKey;


@interface CEKeyBindingManager : NSObject

// singleton
+ (nonnull instancetype)sharedManager;


// Public methods
+ (nonnull NSString *)printableKeyStringFromKeySpecChars:(nonnull NSString *)keySpecChars;
+ (nonnull NSString *)keySpecCharsFromKeyEquivalent:(nonnull NSString *)keyEquivalent modifierFrags:(NSEventModifierFlags)modifierFlags;

- (void)applyKeyBindingsToMainMenu;

- (nonnull NSMutableArray<NSString *> *)keySpecCharsListFromOutlineData:(nonnull NSArray<NSDictionary<NSString *, id> *> *)outlineData;
- (nonnull NSString *)selectorStringWithKeyEquivalent:(nonnull NSString *)keyEquivalent modifierFrags:(NSEventModifierFlags)modifierFlags;

- (BOOL)usesDefaultMenuKeyBindings;
- (BOOL)usesDefaultTextKeyBindings;

- (nonnull NSMutableArray<NSMutableDictionary<NSString *, id> *> *)menuKeySpecCharsArrayForOutlineDataWithFactoryDefaults:(BOOL)usesFactoryDefaults;
- (nonnull NSMutableArray<NSMutableDictionary<NSString *, NSString *> *> *)textKeySpecCharsArrayForOutlineDataWithFactoryDefaults:(BOOL)usesFactoryDefaults;

- (BOOL)saveMenuKeyBindings:(nonnull NSArray<NSDictionary<NSString *, id> *> *)outlineData;
- (BOOL)saveTextKeyBindings:(nonnull NSArray<NSDictionary<NSString *, NSString *> *> *)outlineData texts:(nullable NSArray<NSString *> *)texts;

@end



// Category for migration from CotEditor 1.x to 2.0. (2014-10)
// It can be removed when the most of users have been already migrated in the future.
@interface CEKeyBindingManager (Migration)

- (BOOL)resetMenuKeyBindings;

@end
