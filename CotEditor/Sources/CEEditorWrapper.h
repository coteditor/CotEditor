/*
 ==============================================================================
 CEEditorWrapper
 
 CotEditor
 http://coteditor.github.io
 
 Created on 2004-12-08 by nakamuxu
 encoding="UTF-8"
 
 ------------
 This class is based on JSDTextView (written by James S. Derry – http://www.balthisar.com)
 JSDTextView is released as public domain.
 arranged by nakamuxu, Dec 2004.
 ------------------------------------------------------------------------------
 
 © 2004-2007 nakamuxu
 © 2014 CotEditor Project
 
 This program is free software; you can redistribute it and/or modify it under
 the terms of the GNU General Public License as published by the Free Software
 Foundation; either version 2 of the License, or (at your option) any later
 version.
 
 This program is distributed in the hope that it will be useful, but WITHOUT
 ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS
 FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.
 
 You should have received a copy of the GNU General Public License along with
 this program; if not, write to the Free Software Foundation, Inc., 59 Temple
 Place - Suite 330, Boston, MA  02111-1307, USA.
 
 ==============================================================================
 */

@import Cocoa;
#import "CEEditorView.h"
#import "CETextView.h"
#import "CEWindowController.h"


@class CEDocument;
@class CEWindowController;


@interface CEEditorWrapper : NSResponder

@property (nonatomic) BOOL showsLineNum;
@property (nonatomic) BOOL showsNavigationBar;
@property (nonatomic) BOOL wrapsLines;
@property (nonatomic) BOOL showsPageGuide;
@property (nonatomic) BOOL showsInvisibles;
@property (nonatomic, getter=isVerticalLayoutOrientation) BOOL verticalLayoutOrientation;
@property (nonatomic) CETextView *textView;

@property (readonly, nonatomic) BOOL canActivateShowInvisibles;


// Public method
- (CEDocument *)document;
- (CEWindowController *)windowController;
- (NSTextStorage *)textStorage;

- (NSString *)string;
- (NSString *)substringWithRange:(NSRange)range;
- (NSString *)substringWithSelection;
- (NSString *)substringWithSelectionForSave;
- (void)setString:(NSString *)string;
- (void)setLineEndingString:(NSString *)lineEndingString;
- (void)replaceTextViewSelectedStringTo:(NSString *)inString scroll:(BOOL)doScroll;
- (void)replaceTextViewAllStringTo:(NSString *)string;
- (void)insertTextViewAfterSelectionStringTo:(NSString *)string;
- (void)appendTextViewAfterAllStringTo:(NSString *)string;
- (NSRange)selectedRange;
- (void)setSelectedRange:(NSRange)charRange;

- (NSFont *)font;
- (void)setFont:(NSFont *)font;

- (void)markupRanges:(NSArray *)ranges;
- (void)clearAllMarkup;

- (BOOL)usesAntialias;

- (void)setThemeWithName:(NSString *)themeName;
- (CETheme *)theme;

- (NSString *)syntaxStyleName;
- (void)setSyntaxStyleName:(NSString *)inName recolorNow:(BOOL)recolorNow;
- (void)recolorAllString;
- (void)updateColoringAndOutlineMenuWithDelay;
- (void)setupColoringTimer;

- (void)setBackgroundAlpha:(CGFloat)alpha;


// Action Message
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
- (IBAction)recoloringAllStringOfDocument:(id)sender;

@end
