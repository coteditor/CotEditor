/*
 ==============================================================================
 CEEditorView
 
 CotEditor
 http://coteditor.github.io
 
 Created on 2006-03-18 by nakamuxu
 encoding="UTF-8"
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
#import "CEEditorWrapper.h"
#import "CENavigationBarController.h"
#import "CETextView.h"
#import "CESyntaxParser.h"


@class CEEditorWrapper;


@interface CEEditorView : NSView <NSTextViewDelegate>

@property (nonatomic, weak) CEEditorWrapper *editorWrapper;

// readonly
@property (readonly, nonatomic) CETextView *textView;
@property (readonly, nonatomic) CENavigationBarController *navigationBar;
@property (readonly, nonatomic) CESyntaxParser *syntaxParser;


// Public method
- (NSString *)string;
- (void)replaceTextStorage:(NSTextStorage *)textStorage;
- (void)setTextViewToEditorWrapper:(CETextView *)textView;
- (void)setShowLineNum:(BOOL)showLineNum;
- (void)setShowNavigationBar:(BOOL)setNavigationBar;
- (void)setWrapLines:(BOOL)wrapLines;
- (void)setShowInvisibles:(BOOL)showInvisibles;
- (void)setAutoTabExpandEnabled:(BOOL)isEnabled;
- (void)setUseAntialias:(BOOL)useAntialias;
- (void)updateCloseSplitViewButton:(BOOL)isEnabled;
- (BOOL)showPageGuide;
- (void)setCaretToBeginning;
- (void)setSyntaxWithName:(NSString *)styleName;
- (void)recolorAllTextViewString;
- (void)updateOutlineMenu;
- (void)updateOutlineMenuSelection;
- (void)stopUpdateLineNumberTimer;
- (void)stopUpdateOutlineMenuTimer;
- (NSCharacterSet *)firstCompletionCharacterSet;
- (void)setBackgroundColorAlpha:(CGFloat)alpha;

@end
