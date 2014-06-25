/*
=================================================
CESubSplitView
(for CotEditor)

 Copyright (C) 2004-2007 nakamuxu.
 Copyright (C) 2014 CotEditor Project
 http://coteditor.github.io
=================================================

encoding="UTF-8"
Created:2006.03.18
 
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
#import "CEEditorView.h"
#import "CELineNumView.h"
#import "CENavigationBarView.h"
#import "CETextViewCore.h"
#import "CESyntax.h"


@interface CESubSplitView : NSView <NSTextViewDelegate>

@property (nonatomic) CEEditorView *editorView;

// readonly
@property (nonatomic, readonly) NSScrollView *scrollView;
@property (nonatomic, readonly) CETextViewCore *textView;
@property (nonatomic, readonly) CELineNumView *lineNumView;
@property (nonatomic, readonly) CENavigationBarView *navigationBar;
@property (nonatomic, readonly) CESyntax *syntax;


// Public method
- (void)releaseEditorView;
- (NSString *)string;
- (void)viewDidEndLiveResize;
- (void)replaceTextStorage:(NSTextStorage *)inTextStorage;
- (BOOL)isWritable;
- (BOOL)isAlertedNotWritable;
- (void)setTextViewToEditorView:(CETextViewCore *)inTextView;
- (void)setShowLineNumWithNumber:(NSNumber *)inNumber;
- (void)setShowNavigationBarWithNumber:(NSNumber *)inNumber;
- (void)setWrapLinesWithNumber:(NSNumber *)inNumber;
- (void)setShowInvisiblesWithNumber:(NSNumber *)inNumber;
- (void)setAutoTabExpandEnabledWithNumber:(NSNumber *)inNumber;
- (void)setUseAntialiasWithNumber:(NSNumber *)inNumber;
- (BOOL)showPageGuide;
- (void)setCaretToBeginning;
- (void)setSyntaxWithName:(NSString *)inName;
- (void)recolorAllTextViewString;
- (void)updateOutlineMenu;
- (void)updateOutlineMenuSelection;
- (void)stopUpdateLineNumberTimer;
- (void)stopUpdateOutlineMenuTimer;
- (NSCharacterSet *)firstCompletionCharacterSet;
- (void)setBackgroundColorAlphaWithNumber:(NSNumber *)inNumber;

@end
