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
@class CETextView;
@class CETheme;


@interface CEEditorWrapper : NSResponder

@property (nonatomic, nullable) CEDocument *document;

@property (nonatomic) BOOL showsLineNum;
@property (nonatomic) BOOL wrapsLines;
@property (nonatomic) BOOL showsPageGuide;
@property (nonatomic) BOOL showsInvisibles;
@property (nonatomic, getter=isVerticalLayoutOrientation) BOOL verticalLayoutOrientation;

// readonly
@property (readonly, nonatomic, nullable) CETextView *focusedTextView;


#pragma mark Public Methods

- (void)markupRanges:(nonnull NSArray<NSValue *> *)ranges;
- (void)clearAllMarkup;

// style
- (nullable NSFont *)font;
- (nullable CETheme *)theme;

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




#pragma mark -

@interface CEEditorWrapper (TextEditing)

// text processing
- (nonnull NSString *)string;
- (nonnull NSString *)substringWithRange:(NSRange)range;
- (nonnull NSString *)substringWithSelection;

- (void)insertTextViewString:(nonnull NSString *)inString;
- (void)insertTextViewStringAfterSelection:(nonnull NSString *)string;
- (void)replaceTextViewAllStringWithString:(nonnull NSString *)string;
- (void)appendTextViewString:(nonnull NSString *)string;

- (NSRange)selectedRange;  // line ending applied
- (void)setSelectedRange:(NSRange)charRange;  // line ending applied

@end




#pragma mark -

@interface CEEditorWrapper (Locating)

- (NSRange)rangeWithLocation:(NSInteger)location length:(NSInteger)length;  // line ending applied
- (void)setSelectedCharacterRangeWithLocation:(NSInteger)location length:(NSInteger)length;  // line ending applied
- (void)setSelectedLineRangeWithLocation:(NSInteger)location length:(NSInteger)length;  // line ending applied

@end
