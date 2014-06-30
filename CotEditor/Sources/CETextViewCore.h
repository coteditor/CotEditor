/*
=================================================
CETextViewCore
(for CotEditor)

 Copyright (C) 2004-2007 nakamuxu.
 Copyright (C) 2014 CotEditor Project
 http://coteditor.github.io
=================================================

encoding="UTF-8"
Created:2005.03.30
 
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
#import "CETextViewProtocol.h"


@class CEEditorView;


@interface CETextViewCore : NSTextView <CETextViewProtocol>

@property (nonatomic) BOOL isReCompletion;  // 再度入力補完をするか
@property (nonatomic) BOOL updateOutlineMenuItemSelection;  // アウトラインメニュー項目の更新をすべきか
@property (nonatomic) BOOL isSelfDrop;  // 自己内ドラッグ&ドロップなのか
@property (nonatomic) BOOL isReadingFromPboard;  // ペーストまたはドロップ実行中なのか
@property (nonatomic) CGFloat lineSpacing;
@property (nonatomic) NSRect highlightLineAdditionalRect;  // ハイライト行で追加表示する矩形
@property (nonatomic) BOOL isAutoTabExpandEnabled;  // タブを自動的にスペースに展開するか
@property (nonatomic) NSUInteger tabWidth;  // タブ幅
@property (nonatomic, copy) NSString *inlineCommentDelimiter;  // インラインコメント開始文字列
@property (nonatomic, copy) NSDictionary *blockCommentDelimiters;  // ブロックコメント開始・終了文字列のペア

@property (nonatomic, weak) NSView *slaveView;  // LineNumView
@property (nonatomic, copy) NSString *lineEndingString;  // 行末文字
@property (nonatomic) CGFloat backgroundAlpha;  // ビューの不透明度

@property (nonatomic) CETheme *theme;

// readonly
@property (nonatomic, readonly) NSColor *highlightLineColor;  // カレント行ハイライト色


// Public method
- (void)drawHighlightLineAdditionalRect;
- (void)applyTypingAttributes;
- (void)replaceSelectedStringTo:(NSString *)inString scroll:(BOOL)inBoolScroll;
- (void)replaceAllStringTo:(NSString *)inString;
- (void)insertAfterSelection:(NSString *)inString;
- (void)appendAllString:(NSString *)inString;
- (void)insertCustomTextWithPatternNum:(NSInteger)inPatternNum;
- (void)resetFont:(id)sender;
- (NSArray *)readablePasteboardTypes;
- (NSArray *)pasteboardTypesForString;
- (NSUInteger)dragOperationForDraggingInfo:(id <NSDraggingInfo>)inDragInfo type:(NSString *)inType;
- (BOOL)readSelectionFromPasteboard:(NSPasteboard *)inPboard type:(NSString *)inType;
- (NSRange)selectionRangeForProposedRange:(NSRange)inProposedSelRange
                              granularity:(NSSelectionGranularity)inGranularity;
- (BOOL)isReCompletion;
- (void)setIsReCompletion:(BOOL)inValue;
- (void)setNewLineSpacingAndUpdate:(CGFloat)inLineSpacing;
- (void)doReplaceString:(NSString *)inString withRange:(NSRange)inRange 
            withSelected:(NSRange)inSelection withActionName:(NSString *)inActionName;
- (void)selectTextRangeValue:(NSValue *)inRangeValue;

// Action Message
- (IBAction)shiftRight:(id)sender;
- (IBAction)shiftLeft:(id)sender;
- (IBAction)toggleComment:(id)sender;
- (IBAction)commentOut:(id)sender;
- (IBAction)uncomment:(id)sender;
- (IBAction)selectLines:(id)sender;
- (IBAction)toggleLayoutOrientation:(id)sender;
- (IBAction)changeTabWidth:(id)sender;
- (IBAction)exchangeLowercase:(id)sender;
- (IBAction)exchangeUppercase:(id)sender;
- (IBAction)exchangeCapitalized:(id)sender;
- (IBAction)exchangeFullwidthRoman:(id)sender;
- (IBAction)exchangeHalfwidthRoman:(id)sender;
- (IBAction)exchangeKatakana:(id)sender;
- (IBAction)exchangeHiragana:(id)sender;
- (IBAction)unicodeNormalizationNFD:(id)sender;
- (IBAction)unicodeNormalizationNFC:(id)sender;
- (IBAction)unicodeNormalizationNFKD:(id)sender;
- (IBAction)unicodeNormalizationNFKC:(id)sender;
- (IBAction)unicodeNormalization:(id)sender;
- (IBAction)inputYenMark:(id)sender;
- (IBAction)inputBackSlash:(id)sender;
- (IBAction)editColorCode:(id)sender;
- (IBAction)setSelectedRangeWithNSValue:(id)sender;
- (IBAction)setLineSpacingFromMenu:(id)sender;
- (IBAction)showSelectionInfo:(id)sender;

@end
