/*
=================================================
CEEditorView
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

#import <Cocoa/Cocoa.h>
#import "CESplitView.h"
#import "CESubSplitView.h"
#import "CELineNumView.h"
#import "CEStatusBarView.h"
#import "CENavigationBarView.h"
#import "CETextViewCore.h"
#import "CEWindowController.h"
#import "CESyntax.h"
#import "CELayoutManager.h"
#import "CEScriptManager.h"


@class CEDocument;
@class CEWindowController;


@interface CEEditorView : NSView

@property (nonatomic) OgreNewlineCharacter lineEndingCharacter;

@property (nonatomic) BOOL showLineNum;
@property (nonatomic) BOOL showNavigationBar;
@property (nonatomic) BOOL showStatusBar;
@property (nonatomic) BOOL wrapLines;
@property (nonatomic) BOOL isWritable;
@property (nonatomic) BOOL isAlertedNotWritable;  // 文書が読み込み専用のときにその警告を表示したかどうか
@property (nonatomic) BOOL showPageGuide;
@property (nonatomic) BOOL showInvisibles;
@property (nonatomic) BOOL isColoring;

@property (nonatomic) CETextViewCore *textView;

@property (nonatomic, readonly) CESplitView *splitView;
@property (nonatomic, readonly) BOOL canActivateShowInvisibles;


// Public method
- (CEDocument *)document;
- (CEWindowController *)windowController;
- (NSTextStorage *)textStorage;
- (CENavigationBarView *)navigationBar;
- (CESyntax *)syntax;

- (NSString *)string;
- (NSString *)stringForSave;
- (NSString *)substringWithRange:(NSRange)range;
- (NSString *)substringWithSelection;
- (NSString *)substringWithSelectionForSave;
- (void)setString:(NSString *)inString;
- (void)replaceTextViewSelectedStringTo:(NSString *)inString scroll:(BOOL)doScroll;
- (void)replaceTextViewAllStringTo:(NSString *)string;
- (void)insertTextViewAfterSelectionStringTo:(NSString *)string;
- (void)appendTextViewAfterAllStringTo:(NSString *)string;
- (NSFont *)font;
- (void)setFont:(NSFont *)font;
- (NSRange)selectedRange;
- (void)setSelectedRange:(NSRange)charRange;
- (NSArray *)allLayoutManagers;

- (BOOL)shouldUseAntialias;
- (void)toggleShouldUseAntialias;

- (NSString *)syntaxStyleName;
- (void)setSyntaxStyleName:(NSString *)inName recolorNow:(BOOL)recolorNow;
- (void)recolorAllString;
- (void)updateColoringAndOutlineMenuWithDelay;
- (void)alertForNotWritable;
- (void)updateDocumentInfoStringWithDrawerForceUpdate:(BOOL)doUpdate;
- (void)updateLineEndingsInStatusAndInfo:(BOOL)inBool;
- (void)setupColoringTimer;
- (void)setupIncompatibleCharTimer;
- (void)setupInfoUpdateTimer;
- (void)updateCloseSubSplitViewButton;
- (void)stopAllTimer;


// Action Message
- (IBAction)toggleShowLineNum:(id)sender;
- (IBAction)toggleShowStatusBar:(id)sender;
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
- (IBAction)focusNextSplitTextView:(id)sender;
- (IBAction)focusPrevSplitTextView:(id)sender;

@end
