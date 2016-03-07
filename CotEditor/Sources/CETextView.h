/*
 
 CETextView.h
 
 CotEditor
 http://coteditor.com
 
 Created by nakamuxu on 2005-03-30.
 
 ------------
 This class is based on JSDTextView (written by James S. Derry – http://www.balthisar.com)
 JSDTextView is released as public domain.
 arranged by nakamuxu, Dec 2004.
 
 ------------------------------------------------------------------------------
 
 © 2004-2007 nakamuxu
 © 2014-2016 1024jp
 
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
#import "NSTextView+CETextReplacement.h"
#import "CETextViewProtocol.h"


@interface CETextView : NSTextView <CETextViewProtocol>

@property (nonatomic) BOOL showsPageGuide;
@property (nonatomic) BOOL needsRecompletion;  // 再度入力補完をするか
@property (nonatomic) BOOL needsUpdateOutlineMenuItemSelection;  // アウトラインメニュー項目の更新をすべきか
@property (nonatomic) CGFloat lineSpacing;
@property (nonatomic) NSUInteger tabWidth;  // タブ幅
@property (nonatomic) NSRect highlightLineRect;  // ハイライト行の矩形
@property (nonatomic, getter=isAutoTabExpandEnabled) BOOL autoTabExpandEnabled;  // タブを自動的にスペースに展開するか
@property (nonatomic, nullable, copy) NSString *inlineCommentDelimiter;  // インラインコメント開始文字列
@property (nonatomic, nullable, copy) NSDictionary<NSString *, NSString *> *blockCommentDelimiters;  // ブロックコメント開始・終了文字列のペア
@property (nonatomic, nullable, copy) NSCharacterSet *firstCompletionCharacterSet;  // 入力補完の最初の1文字のセット

@property (nonatomic, nullable) CETheme *theme;


// Public method
- (void)setLineSpacingAndUpdate:(CGFloat)lineSpacing;
- (void)detectLinkIfNeeded;

// Action Message
- (IBAction)copyWithStyle:(nullable id)sender;
- (IBAction)resetFont:(nullable id)sender;
- (IBAction)selectLines:(nullable id)sender;
- (IBAction)changeTabWidth:(nullable id)sender;
- (IBAction)inputYenMark:(nullable id)sender;
- (IBAction)inputBackSlash:(nullable id)sender;
- (IBAction)trimTrailingWhitespace:(nullable id)sender;
- (IBAction)setSelectedRangeWithNSValue:(nullable id)sender;
- (IBAction)changeLineHeight:(nullable id)sender;
- (IBAction)showSelectionInfo:(nullable id)sender;

@end



@interface CETextView (WordCompletion)

- (void)completeAfterDelay:(NSTimeInterval)delay;

@end


@interface CETextView (ColorCode)

- (IBAction)editColorCode:(nullable id)sender;

@end



#pragma mark - CETextView+Indentation.m

@interface CETextView (Indentation)

- (IBAction)shiftRight:(nullable id)sender;
- (IBAction)shiftLeft:(nullable id)sender;
- (IBAction)convertIndentationToSpaces:(nullable id)sender;
- (IBAction)convertIndentationToTabs:(nullable id)sender;

@end



#pragma mark - CETextView+Commenting.m

@interface CETextView (Commenting)

- (IBAction)toggleComment:(nullable id)sender;
- (IBAction)commentOut:(nullable id)sender;
- (IBAction)uncomment:(nullable id)sender;

// semi-private methods
- (BOOL)canUncommentRange:(NSRange)range;

@end



#pragma mark - CETextView+LineProcessing.m

@interface CETextView (LineProcessing)

- (IBAction)moveLineUp:(nullable id)sender;
- (IBAction)moveLineDown:(nullable id)sender;
- (IBAction)sortLinesAscending:(nullable id)sender;
- (IBAction)reverseLines:(nullable id)sender;
- (IBAction)deleteDuplicateLine:(nullable id)sender;
- (IBAction)duplicateLine:(nullable id)sender;
- (IBAction)deleteLine:(nullable id)sender;

@end



#pragma mark - CETextView+Transformation.m

@interface CETextView (Transformation)

- (IBAction)exchangeFullwidthRoman:(nullable id)sender;
- (IBAction)exchangeHalfwidthRoman:(nullable id)sender;
- (IBAction)exchangeKatakana:(nullable id)sender;
- (IBAction)exchangeHiragana:(nullable id)sender;
- (IBAction)normalizeUnicodeWithNFD:(nullable id)sender;
- (IBAction)normalizeUnicodeWithNFC:(nullable id)sender;
- (IBAction)normalizeUnicodeWithNFKD:(nullable id)sender;
- (IBAction)normalizeUnicodeWithNFKC:(nullable id)sender;
- (IBAction)normalizeUnicodeWithNFKCCF:(nullable id)sender;
- (IBAction)normalizeUnicodeWithModifiedNFD:(nullable id)sender;

@end
