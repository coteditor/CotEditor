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
- (void)insertString:(NSString *)string;
- (void)insertStringAfterSelection:(NSString *)string;
- (void)replaceAllStringWithString:(NSString *)string;
- (void)appendString:(NSString *)string;
- (void)setLineSpacingAndUpdate:(CGFloat)lineSpacing;
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
