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
 © 2014-2015 1024jp
 
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
@property (nonatomic) NSUInteger tabWidth;  // タブ幅
@property (nonatomic) NSRect highlightLineRect;  // ハイライト行の矩形
@property (nonatomic, getter=isAutoTabExpandEnabled) BOOL autoTabExpandEnabled;  // タブを自動的にスペースに展開するか
@property (nonatomic, copy) NSString *inlineCommentDelimiter;  // インラインコメント開始文字列
@property (nonatomic, copy) NSDictionary *blockCommentDelimiters;  // ブロックコメント開始・終了文字列のペア
@property (nonatomic, copy) NSCharacterSet *firstCompletionCharacterSet;  // 入力補完の最初の1文字のセット

@property (nonatomic) CETheme *theme;

// readonly
@property (readonly, nonatomic, getter=isSelfDrop) BOOL selfDrop;  // 自己内ドラッグ&ドロップなのか
@property (readonly, nonatomic, getter=isReadingFromPboard) BOOL readingFromPboard;  // ペーストまたはドロップ実行中なのか


// Public method
- (void)replaceSelectedStringWithString:(NSString *)string;
- (void)replaceAllStringWithString:(NSString *)string;
- (void)insertStringAfterSelection:(NSString *)string;
- (void)appendString:(NSString *)string;
- (void)insertCustomTextWithPatternNum:(NSInteger)patternNum;
- (void)setNewLineSpacingAndUpdate:(CGFloat)lineSpacing;
- (void)replaceWithString:(NSString *)string range:(NSRange)range
            selectedRange:(NSRange)selectedRange actionName:(NSString *)actionName;

// Action Message
- (IBAction)resetFont:(id)sender;
- (IBAction)shiftRight:(id)sender;
- (IBAction)shiftLeft:(id)sender;
- (IBAction)selectLines:(id)sender;
- (IBAction)changeTabWidth:(id)sender;
- (IBAction)inputYenMark:(id)sender;
- (IBAction)inputBackSlash:(id)sender;
- (IBAction)setSelectedRangeWithNSValue:(id)sender;
- (IBAction)changeLineHeight:(id)sender;
- (IBAction)showSelectionInfo:(id)sender;

@end



@interface CETextView (WordCompletion)

- (void)completeAfterDelay:(NSTimeInterval)delay;

// semi-private methods
- (void)stopCompletionTimer;

@end


@interface CETextView (Commenting)

- (IBAction)toggleComment:(id)sender;
- (IBAction)commentOut:(id)sender;
- (IBAction)uncomment:(id)sender;

// semi-private methods
- (BOOL)canUncommentRange:(NSRange)range;

@end


@interface CETextView (UtilityMenu)

- (IBAction)exchangeFullwidthRoman:(id)sender;
- (IBAction)exchangeHalfwidthRoman:(id)sender;
- (IBAction)exchangeKatakana:(id)sender;
- (IBAction)exchangeHiragana:(id)sender;
- (IBAction)normalizeUnicodeWithNFD:(id)sender;
- (IBAction)normalizeUnicodeWithNFC:(id)sender;
- (IBAction)normalizeUnicodeWithNFKD:(id)sender;
- (IBAction)normalizeUnicodeWithNFKC:(id)sender;
- (IBAction)editColorCode:(id)sender;

@end
