/*
 ==============================================================================
 CETextView
 
 CotEditor
 http://coteditor.com
 
 Created on 2005-03-30 by nakamuxu
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
#import "CETextViewProtocol.h"
#import "CELayoutManager.h"


@interface CETextView : NSTextView <NSTextInputClient, CETextViewProtocol>

@property (nonatomic) BOOL showsPageGuide;
@property (nonatomic) BOOL needsRecompletion;  // 再度入力補完をするか
@property (nonatomic) BOOL needsUpdateOutlineMenuItemSelection;  // アウトラインメニュー項目の更新をすべきか
@property (nonatomic) CGFloat lineSpacing;
@property (nonatomic) NSRect highlightLineRect;  // ハイライト行の矩形
@property (nonatomic, getter=isAutoTabExpandEnabled) BOOL autoTabExpandEnabled;  // タブを自動的にスペースに展開するか
@property (nonatomic, copy) NSString *inlineCommentDelimiter;  // インラインコメント開始文字列
@property (nonatomic, copy) NSDictionary *blockCommentDelimiters;  // ブロックコメント開始・終了文字列のペア
@property (nonatomic, copy) NSCharacterSet *firstCompletionCharacterSet;  // 入力補完の最初の1文字のセット
@property (nonatomic, weak) NSView *lineNumberView;  // lineNumberView
@property (nonatomic, copy) NSString *lineEndingString;  // 行末文字

@property (nonatomic) CETheme *theme;

// readonly
@property (readonly, nonatomic, getter=isSelfDrop) BOOL selfDrop;  // 自己内ドラッグ&ドロップなのか
@property (readonly, nonatomic, getter=isReadingFromPboard) BOOL readingFromPboard;  // ペーストまたはドロップ実行中なのか


// Public method
- (void)completeAfterDelay:(NSTimeInterval)delay;
- (void)applyTypingAttributes;
- (void)replaceSelectedStringTo:(NSString *)inString scroll:(BOOL)inBoolScroll;
- (void)replaceAllStringTo:(NSString *)inString;
- (void)insertAfterSelection:(NSString *)inString;
- (void)appendAllString:(NSString *)inString;
- (void)insertCustomTextWithPatternNum:(NSInteger)inPatternNum;
- (void)resetFont:(id)sender;
- (void)setNewLineSpacingAndUpdate:(CGFloat)inLineSpacing;
- (void)doReplaceString:(NSString *)inString withRange:(NSRange)inRange 
           withSelected:(NSRange)inSelection withActionName:(NSString *)inActionName;

// Action Message
- (IBAction)shiftRight:(id)sender;
- (IBAction)shiftLeft:(id)sender;
- (IBAction)toggleComment:(id)sender;
- (IBAction)commentOut:(id)sender;
- (IBAction)uncomment:(id)sender;
- (IBAction)selectLines:(id)sender;
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
