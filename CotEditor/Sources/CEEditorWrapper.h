/*
=================================================
CEEditorWrapper
(for CotEditor)

 Copyright (C) 2004-2007 nakamuxu.
 Copyright (C) 2014 CotEditor Project
 http://coteditor.github.io
=================================================

encoding="UTF-8"
Created:2004.12.08
 
------------
This class is based on JSDTextView (written by James S. Derry – http://www.balthisar.com)
JSDTextView is released as public domain.
arranged by nakamuxu, Dec 2004.
-------------------------------------------------

This program is free software; you can redistribute it and/or
modify it under the terms of the GNU General Public License
as published by the Free Software Foundation; either version 2
of the License, or (at your option) any later version.

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU General Public License for more details.

You should have received a copy of the GNU General Public License
along with this program; if not, write to the Free Software
Foundation, Inc., 59 Temple Place - Suite 330, Boston, MA  02111-1307, USA. 


=================================================
*/

@import Cocoa;
#import "CESubSplitView.h"
#import "CETextView.h"
#import "CEWindowController.h"


@class CEDocument;
@class CEWindowController;


@interface CEEditorWrapper : NSResponder

@property (nonatomic) BOOL showLineNum;
@property (nonatomic) BOOL showNavigationBar;
@property (nonatomic) BOOL wrapLines;
@property (nonatomic) BOOL showPageGuide;
@property (nonatomic) BOOL showInvisibles;
@property (nonatomic) CETextView *textView;

@property (nonatomic, readonly) BOOL canActivateShowInvisibles;


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

- (NSFont *)font;
- (void)setFont:(NSFont *)font;

- (NSRange)selectedRange;
- (void)setSelectedRange:(NSRange)charRange;

- (void)markupRanges:(NSArray *)ranges;
- (void)clearAllMarkup;

- (BOOL)shouldUseAntialias;
- (void)toggleShouldUseAntialias;

- (NSString *)syntaxStyleName;
- (void)setSyntaxStyleName:(NSString *)inName recolorNow:(BOOL)recolorNow;
- (void)recolorAllString;
- (void)updateColoringAndOutlineMenuWithDelay;
- (void)setupColoringTimer;

- (void)setBackgroundAlpha:(CGFloat)alpha;


// Action Message
- (IBAction)toggleShowLineNum:(id)sender;
- (IBAction)toggleShowNavigationBar:(id)sender;
- (IBAction)toggleWrapLines:(id)sender;
- (IBAction)toggleUseAntialias:(id)sender;
- (IBAction)toggleShowInvisibleChars:(id)sender;
- (IBAction)toggleShowPageGuide:(id)sender;
- (IBAction)toggleAutoTabExpand:(id)sender;
- (IBAction)selectPrevItemOfOutlineMenu:(id)sender;
- (IBAction)selectNextItemOfOutlineMenu:(id)sender;
- (IBAction)openSplitTextView:(id)sender;
- (IBAction)closeSplitTextView:(id)sender;
- (IBAction)recoloringAllStringOfDocument:(id)sender;

@end
