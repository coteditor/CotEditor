/*
 
 CENavigationBarController.h
 
 CotEditor
 http://coteditor.com
 
 Created by nakamuxu on 2005-08-22.
 
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

@import AppKit;


@interface CENavigationBarController : NSViewController

@property (nonatomic, nullable, strong) NSTextView *textView;  // NSTextView cannot be weak

@property (readonly, nonatomic, getter=isShown) BOOL shown;


// Public method
- (void)setShown:(BOOL)shown animate:(BOOL)performAnimation;

- (void)setOutlineItems:(nonnull NSArray<NSDictionary<NSString *, id> *> *)outlineItems;
- (void)selectOutlineMenuItemWithRange:(NSRange)range;
- (void)updatePrevNextButtonEnabled;
- (BOOL)canSelectPrevItem;
- (BOOL)canSelectNextItem;
- (void)showOutlineIndicator;

- (void)setCloseSplitButtonEnabled:(BOOL)enabled;
- (void)setSplitOrientationVertical:(BOOL)isVertical;


// action messages
- (IBAction)selectPrevItem:(nullable id)sender;
- (IBAction)selectNextItem:(nullable id)sender;

@end
