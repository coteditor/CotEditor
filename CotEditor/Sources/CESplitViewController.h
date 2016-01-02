/*
 
 CESplitViewController.h
 
 CotEditor
 http://coteditor.com
 
 Created by nakamuxu on 2006-03-26.
 
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

@import AppKit;


@class CEEditorViewController;


@interface CESplitViewController : NSViewController <NSSplitViewDelegate>

@property (readonly, nonatomic, nonnull) NSSplitView *splitView;


- (void)enumerateEditorViewsUsingBlock:(nonnull void (^)(CEEditorViewController * _Nonnull viewController))block;

- (void)addSubviewForViewController:(nonnull CEEditorViewController *)editorViewController relativeTo:(nullable NSView *)otherEditorView;
- (void)removeSubviewForViewController:(nonnull CEEditorViewController *)editorViewController;

- (nullable CEEditorViewController *)viewControllerForSubview:(nonnull __kindof NSView *)view;

- (IBAction)toggleSplitOrientation:(nullable id)sender;
- (IBAction)focusNextSplitTextView:(nullable id)sender;
- (IBAction)focusPrevSplitTextView:(nullable id)sender;

@end
