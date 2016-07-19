/*
 
 CETextView.h
 
 CotEditor
 http://coteditor.com
 
 Created by nakamuxu on 2005-03-30.
 
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
#import "CEThemableProtocol.h"


// notifications
extern NSString *_Nonnull const CETextViewDidBecomeFirstResponderNotification;


@interface CETextView : NSTextView <CEThemable>

@property (nonatomic) BOOL showsPageGuide;
@property (nonatomic) BOOL usesAntialias;
@property (nonatomic) BOOL showsInvisibles;
@property (nonatomic) NSInteger tabWidth;
@property (nonatomic, getter=isAutoTabExpandEnabled) BOOL autoTabExpandEnabled;  // タブを自動的にスペースに展開するか

@property (nonatomic, nullable) Theme *theme;

@property (nonatomic) NSRect highlightLineRect;  // ハイライト行の矩形

@property (nonatomic, nullable, copy) NSString *inlineCommentDelimiter;  // インラインコメント開始文字列
@property (nonatomic, nullable, copy) NSDictionary<NSString *, NSString *> *blockCommentDelimiters;  // ブロックコメント開始・終了文字列のペア

@property (nonatomic, nullable, copy) NSCharacterSet *firstSyntaxCompletionCharacterSet;  // 入力補完の最初の1文字のセット
@property (nonatomic) BOOL needsRecompletion;  // 再度入力補完をするか

// for Scaling category
@property (nonatomic) CGFloat initialMagnificationScale;
@property (nonatomic) CGFloat deferredMagnification;


// Public method
- (void)invalidateStyle;

// Action Message
- (IBAction)copyWithStyle:(nullable id)sender;
- (IBAction)inputYenMark:(nullable id)sender;
- (IBAction)inputBackSlash:(nullable id)sender;
- (IBAction)showSelectionInfo:(nullable id)sender;

@end



@interface CETextView (WordCompletion)

- (void)completeAfterDelay:(NSTimeInterval)delay;

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
- (IBAction)trimTrailingWhitespace:(nullable id)sender;

@end
