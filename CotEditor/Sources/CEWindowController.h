/*
=================================================
CEWindowController
(for CotEditor)

 Copyright (C) 2004-2007 nakamuxu.
 Copyright (C) 2014 CotEditor Project
 http://coteditor.github.io
=================================================

encoding="UTF-8"
Created:2004.12.13
 
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
#import <OgreKit/OgreKit.h>
#import "CEDocument.h"
#import "CEEditorView.h"
#import "CEToolbarController.h"


@interface CEWindowController : NSWindowController <NSWindowDelegate, NSDrawerDelegate, NSTabViewDelegate, OgreTextFindDataSource>

@property (nonatomic, weak, readonly) CEEditorView *editorView;
@property (nonatomic, weak, readonly) CEToolbarController *toolbarController;
@property (nonatomic) CGFloat alpha;

// document information (for binding in drawer)
@property (nonatomic, copy) NSString *encodingInfo;    // encoding of document
@property (nonatomic, copy) NSString *lineEndingsInfo; // line endings of document
@property (nonatomic) NSUInteger columnInfo;           // caret location from line head
@property (nonatomic) NSUInteger locationInfo;         // caret location from begining ob document
@property (nonatomic) NSUInteger lineInfo;             // current line
@property (nonatomic, copy) NSString *singleCharInfo;  // Unicode of selected single character (or surrogate-pair)

// Public method
- (BOOL)needsInfoDrawerUpdate;
- (BOOL)needsIncompatibleCharDrawerUpdate;
- (void)updateFileAttrsInformation;
- (void)updateIncompatibleCharList;
- (void)showIncompatibleCharList;

- (void)setLinesInfo:(NSUInteger)lines selected:(NSUInteger)selectedLines;                // number of lines
- (void)setCharsInfo:(NSUInteger)chars selected:(NSUInteger)selectedChars;                // number of composed characters
- (void)setLengthInfo:(NSUInteger)length selected:(NSUInteger)selectedLength;             // character length
- (void)setByteLengthInfo:(NSUInteger)byteLength selected:(NSUInteger)selectedByteLength; //  byte length in current encoding
- (void)setWordsInfo:(NSUInteger)words selected:(NSUInteger)selectedWords;                // number of words

// Action Message
- (IBAction)getInfo:(id)sender;
- (IBAction)toggleIncompatibleCharList:(id)sender;
- (IBAction)selectIncompatibleRange:(id)sender;

@end
