/*
 
 CEEditorView.h
 
 CotEditor
 http://coteditor.com
 
 Created by nakamuxu on 2006-03-18.
 
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
#import "CENavigationBarController.h"
#import "CETextView.h"


@class CEEditorWrapper;
@class CESyntaxParser;


@interface CEEditorView : NSView <NSTextViewDelegate>

@property (nonatomic, nullable, weak) CEEditorWrapper *editorWrapper;

// readonly
@property (readonly, nonatomic, nonnull) CETextView *textView;
@property (readonly, nonatomic, nonnull) CENavigationBarController *navigationBar;


// Public method
- (void)replaceTextStorage:(nonnull NSTextStorage *)textStorage;
- (void)setShowsLineNum:(BOOL)showsLineNum;
- (void)setShowsNavigationBar:(BOOL)showsNavigationBar animate:(BOOL)performAnimation;
- (void)setWrapsLines:(BOOL)wrapsLines;
- (void)setShowsInvisibles:(BOOL)showsInvisibles;
- (void)setUsesAntialias:(BOOL)usesAntialias;
- (void)updateCloseSplitViewButton:(BOOL)isEnabled;
- (void)setCaretToBeginning;
- (void)applySyntax:(nonnull CESyntaxParser *)syntaxParser;

@end
