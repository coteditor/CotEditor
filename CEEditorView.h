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
 
 -fno-objc-arc
 
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
#import "constants.h"


@class CEDocument;

@interface CEEditorView : NSView
{
    CESplitView *_splitView;
    CETextViewCore *_textViewCore;
    CEStatusBarView *_statusBar;
    NSTimer *_coloringTimer;
    NSTimer *_infoUpdateTimer;
    NSTimer *_incompatibleCharTimer;

    OgreNewlineCharacter _lineEndingCharacter;

    NSTimeInterval _basicColoringDelay;
    NSTimeInterval _firstColoringDelay;
    NSTimeInterval _secondColoringDelay;
    NSTimeInterval _infoUpdateInterval;
    NSTimeInterval _incompatibleCharInterval;
    BOOL _showLineNum;
    BOOL _showNavigationBar;
    BOOL _wrapLines;
    BOOL _isWritable;
    BOOL _alertedNotWritable;
    BOOL _coloring;
    BOOL _showPageGuide;
}

// Public method
- (CEDocument *)document;
- (id)windowController;
- (NSTextStorage *)textStorage;
- (CESplitView *)splitView;
- (CETextViewCore *)textView;
- (void)setTextView:(CETextViewCore *)inTextView;
- (CENavigationBarView *)navigationBar;
- (CESyntax *)syntax;
- (BOOL)isColoring;
- (void)setIsColoring:(BOOL)inBool;

- (NSString *)string;
- (NSString *)stringForSave;
- (NSString *)substringWithRange:(NSRange)inRange;
- (NSString *)substringWithSelection;
- (NSString *)substringWithSelectionForSave;
- (void)setString:(NSString *)inString;
- (void)replaceTextViewSelectedStringTo:(NSString *)inString scroll:(BOOL)inBoolScroll;
- (void)replaceTextViewAllStringTo:(NSString *)inString;
- (void)insertTextViewAfterSelectionStringTo:(NSString *)inString;
- (void)appendTextViewAfterAllStringTo:(NSString *)inString;
- (BOOL)setSyntaxExtension:(NSString *)inExtension;
- (NSFont *)font;
- (void)setFont:(NSFont *)inFont;
- (NSRange)selectedRange;
- (void)setSelectedRange:(NSRange)inCharRange;
- (NSArray *)allLayoutManagers;

- (BOOL)showLineNum;
- (void)setShowLineNum:(BOOL)inBool;
- (BOOL)showStatusBar;
- (void)setShowStatusBar:(BOOL)inBool;
- (BOOL)showNavigationBar;
- (void)setShowNavigationBar:(BOOL)inBool;
- (BOOL)wrapLines;
- (void)setWrapLines:(BOOL)inBool;
- (BOOL)isWritable;
- (void)setIsWritable:(BOOL)inBool;
- (BOOL)isAlertedNotWritable;
- (void)setIsAlertedNotWritable:(BOOL)inBool;
- (BOOL)shouldUseAntialias;
- (void)toggleShouldUseAntialias;
- (BOOL)showPageGuide;
- (void)setShowPageGuide:(BOOL)inBool;

- (NSInteger)lineEndingCharacter;
- (void)setLineEndingCharacter:(NSInteger)inNewLineEnding;
- (NSString *)syntaxStyleNameToColoring;
- (void)setSyntaxStyleNameToColoring:(NSString *)inName recolorNow:(BOOL)inValue;
- (void)recoloringAllString;
- (void)updateColoringAndOutlineMenuWithDelay;
- (void)alertForNotWritable;
- (void)updateDocumentInfoStringWithDrawerForceUpdate:(BOOL)inBool;
- (void)updateLineEndingsInStatusAndInfo:(BOOL)inBool;
- (void)setShowInvisibleChars:(BOOL)inBool;
- (void)updateShowInvisibleCharsMenuToolTip;
- (void)setColoringTimer;
- (void)setIncompatibleCharTimer;
- (void)setInfoUpdateTimer;
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
- (IBAction)openSplitTextView:(id)sender;
- (IBAction)closeSplitTextView:(id)sender;
- (IBAction)focusNextSplitTextView:(id)sender;
- (IBAction)focusPrevSplitTextView:(id)sender;

@end


