/*
 
 CEMenuKeyBindingManager.h
 
 CotEditor
 http://coteditor.com
 
 Created by 1024jp on 2016-06-22.
 
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

#import "CEKeyBindingManager.h"
@import Cocoa;


@interface CEMenuKeyBindingManager : CEKeyBindingManager

// singleton
+ (nonnull CEMenuKeyBindingManager *)sharedManager;


// Public methods
- (void)scanDefaultMenuKeyBindings;  // This method should be called before main menu is modified.
- (void)applyKeyBindingsToMainMenu;

- (nonnull NSString *)keyEquivalentForAction:(nonnull SEL)action modifierMask:(nonnull NSEventModifierFlags *)modifierMask;

@end




// Category for migration from CotEditor 1.x to 2.0. (2014-10)
// It can be removed when the most of users have been already migrated in the future.
@interface CEMenuKeyBindingManager (Migration)

- (BOOL)resetKeyBindings;

@end
