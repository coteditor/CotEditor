/*
 
 CENavigationBarController.h
 
 CotEditor
 http://coteditor.com
 
 Created by nakamuxu on 2005-08-22.
 
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


@class CEOutlineItem;


@interface CENavigationBarController : NSViewController

@property (nonatomic, nullable, unsafe_unretained) NSTextView *textView;  // NSTextView cannot be weak


// public method
- (void)setOutlineItems:(nonnull NSArray<CEOutlineItem *> *)outlineItems;
- (void)updatePrevNextButtonEnabled;
- (BOOL)canSelectPrevItem;
- (BOOL)canSelectNextItem;
- (void)showOutlineIndicator;

- (void)setCloseSplitButtonEnabled:(BOOL)enabled;
- (void)setSplitOrientationVertical:(BOOL)isVertical;


// action messages
- (IBAction)selectPrevItemOfOutlineMenu:(nullable id)sender;
- (IBAction)selectNextItemOfOutlineMenu:(nullable id)sender;

@end
