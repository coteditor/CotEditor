/*
 
 CEEditorWrapper.h
 
 CotEditor
 http://coteditor.com
 
 Created by nakamuxu on 2004-12-08.
 
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

@import Cocoa;


@class CEDocument;
@class Theme;


@interface CEEditorWrapper : NSResponder

@property (nonatomic, nullable) CEDocument *document;

@property (nonatomic) BOOL showsLineNumber;
@property (nonatomic) BOOL wrapsLines;
@property (nonatomic) BOOL showsPageGuide;
@property (nonatomic) BOOL showsInvisibles;
@property (nonatomic) BOOL verticalLayoutOrientation;
@property (nonatomic) NSUInteger tabWidth;

// readonly
@property (readonly, nonatomic, nullable) __kindof NSTextView *focusedTextView;
@property (readonly, nonatomic, nullable) NSFont *font;
@property (readonly, nonatomic, nullable) Theme *theme;


#pragma mark Public Methods

- (void)markupRanges:(nonnull NSArray<NSValue *> *)ranges;
- (void)clearAllMarkup;

- (void)invalidateStyleInTextStorage;


#pragma mark Action Messages

- (IBAction)toggleLineNumber:(nullable id)sender;
- (IBAction)toggleNavigationBar:(nullable id)sender;
- (IBAction)toggleLineWrap:(nullable id)sender;
- (IBAction)toggleLayoutOrientation:(nullable id)sender;
- (IBAction)toggleAntialias:(nullable id)sender;
- (IBAction)toggleInvisibleChars:(nullable id)sender;
- (IBAction)togglePageGuide:(nullable id)sender;
- (IBAction)toggleAutoTabExpand:(nullable id)sender;
- (IBAction)changeTabWidth:(nullable id)sender;
- (IBAction)changeTheme:(nullable id)sender;

- (IBAction)recolorAll:(nullable id)sender;

- (IBAction)openSplitTextView:(nullable id)sender;
- (IBAction)closeSplitTextView:(nullable id)sender;

@end
