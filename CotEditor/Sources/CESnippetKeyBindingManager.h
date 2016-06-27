/*
 
 CESnippetKeyBindingManager.h
 
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


@interface CESnippetKeyBindingManager : CEKeyBindingManager

// singleton
+ (nonnull CESnippetKeyBindingManager *)sharedManager;


// Public methods
- (nullable NSString *)snippetWithKeyEquivalent:(nullable NSString *)keyEquivalent modifierMask:(NSEventModifierFlags)modifierMask;

- (nonnull NSArray<NSString *> *)snippetsWithDefaults:(BOOL)usesFactoryDefaults;
- (void)saveSnippets:(nullable NSArray<NSString *> *)snippets;

@end
