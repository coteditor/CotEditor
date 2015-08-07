/*
 
 CEEditorWrapper.h
 
 CotEditor
 http://coteditor.com
 
 Created by nakamuxu on 2004-12-08.
 
 ------------
 This class is based on JSDTextView (written by James S. Derry – http://www.balthisar.com)
 JSDTextView is released as public domain.
 arranged by nakamuxu, Dec 2004.
 
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
#import "CETextView.h"


@class CETextView;
@class CETheme;
@class CESyntaxParser;


@interface CEEditorWrapper : NSResponder

@property (nonatomic) BOOL showsLineNum;
@property (nonatomic) BOOL wrapsLines;
@property (nonatomic) BOOL showsPageGuide;
@property (nonatomic) BOOL showsInvisibles;
@property (nonatomic, getter=isVerticalLayoutOrientation) BOOL verticalLayoutOrientation;
@property (nonatomic) CETextView *focusedTextView;

@property (readonly, nonatomic) CESyntaxParser *syntaxParser;
@property (readonly, nonatomic) BOOL showsNavigationBar;
@property (readonly, nonatomic) BOOL canActivateShowInvisibles;


#pragma mark Public Methods

// text processing
- (NSString *)string;
- (NSString *)substringWithRange:(NSRange)range;
- (NSString *)substringWithSelection;
- (NSString *)substringWithSelectionForSave;  // line ending applied
- (void)setString:(NSString *)string;

- (void)insertTextViewString:(NSString *)inString;
- (void)insertTextViewStringAfterSelection:(NSString *)string;
- (void)replaceTextViewAllStringWithString:(NSString *)string;
- (void)appendTextViewString:(NSString *)string;

- (NSRange)selectedRange;  // line ending applied
- (void)setSelectedRange:(NSRange)charRange;  // line ending applied

- (void)markupRanges:(NSArray *)ranges;
- (void)clearAllMarkup;

- (BOOL)isAutoTabExpandEnabled;

// navigation bar
- (void)setShowsNavigationBar:(BOOL)showsNavigationBar animate:(BOOL)performAnimation;

// font
- (NSFont *)font;
- (void)setFont:(NSFont *)font;
- (BOOL)usesAntialias;

// theme
- (void)setThemeWithName:(NSString *)themeName;
- (CETheme *)theme;

// syntax
- (NSString *)syntaxStyleName;
- (void)setSyntaxStyleWithName:(NSString *)name coloring:(BOOL)doColoring;
- (void)recolorAllString;
- (void)updateColoringAndOutlineMenu;
- (void)setupColoringTimer;


#pragma mark Action Messages

- (IBAction)toggleLineNumber:(id)sender;
- (IBAction)toggleNavigationBar:(id)sender;
- (IBAction)toggleLineWrap:(id)sender;
- (IBAction)toggleLayoutOrientation:(id)sender;
- (IBAction)toggleAntialias:(id)sender;
- (IBAction)toggleInvisibleChars:(id)sender;
- (IBAction)togglePageGuide:(id)sender;
- (IBAction)toggleAutoTabExpand:(id)sender;
- (IBAction)selectPrevItemOfOutlineMenu:(id)sender;
- (IBAction)selectNextItemOfOutlineMenu:(id)sender;
- (IBAction)openSplitTextView:(id)sender;
- (IBAction)closeSplitTextView:(id)sender;
- (IBAction)recolorAll:(id)sender;

@end




#pragma mark -

typedef NS_ENUM(NSUInteger, CEGoToType) {
    CEGoToLine,
    CEGoToCharacter
};

@interface CEEditorWrapper (Locating)

- (NSRange)rangeWithLocation:(NSInteger)location length:(NSInteger)length;
- (void)setSelectedCharacterRangeWithLocation:(NSInteger)location length:(NSInteger)length;
- (void)setSelectedLineRangeWithLocation:(NSInteger)location length:(NSInteger)length;
- (void)gotoLocation:(NSInteger)location length:(NSInteger)length type:(CEGoToType)type;

@end
