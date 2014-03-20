/*
 * Name: OgreFindProgressSheet.h
 * Project: OgreKit
 *
 * Creation Date: Oct 01 2003
 * Author: Isao Sonobe <sonoisa (AT) muse (DOT) ocn (DOT) ne (DOT) jp>
 * Copyright: Copyright (c) 2003 Isao Sonobe, All rights reserved.
 * License: OgreKit License
 *
 * Encoding: UTF8
 * Tabsize: 4
 */

#import <Cocoa/Cocoa.h>
#import <OgreKit/OgreTextFinder.h>
#import <OgreKit/OgreTextFindProgressDelegate.h>

@interface OgreTextFindProgressSheet : NSObject <OgreTextFindProgressDelegate>
{
    IBOutlet NSWindow				*progressWindow;        // 経過表示用シート
    IBOutlet NSTextField			*titleTextField;        // タイトル
    IBOutlet NSProgressIndicator	*progressBar;           // バー
	IBOutlet NSTextField			*progressTextField;     // 経過を表す文字列
    IBOutlet NSTextField			*donePerTotalTextField; // 処理項目率
	IBOutlet NSButton				*button;                // Cancel/OKボタン
	
	BOOL	_shouldRelease;			// OKボタンが押されたらこのオブジェクトをreleaseするかどうか
	
	NSWindow	*_parentWindow;		// シートを張るウィンドウ
	NSString	*_title;			// タイトル
	
	/* キャンセルされたときのaction */
	SEL			_cancelSelector;
	id			_cancelTarget;
	id			_cancelArgument;	// == selfの場合はretainしない
	/* シートが閉じたときのaction */
	SEL			_didEndSelector;
	id			_didEndTarget;
	id			_didEndArgument;	// == selfの場合はretainしない
}

/* 初期化 */
- (id)initWithWindow:(NSWindow*)parentWindow title:(NSString*)aTitle didEndSelector:(SEL)aSelector toTarget:(id)aTarget withObject:(id)anObject;

- (IBAction)cancel:(id)sender;

/* OgreTextFindProgressDelegate protocol */
/*
// show progress
- (void)setProgress:(double)progression message:(NSString*)message;
- (void)setDonePerTotalMessage:(NSString*)message;
// finish
- (void)done:(double)progression message:(NSString*)message;

// close sheet
- (void)close:(id)sender;
- (void)setReleaseWhenOKButtonClicked:(BOOL)shouldRelease;

// cancel
- (void)setCancelSelector:(SEL)aSelector toTarget:(id)aTarget withObject:(id)anObject;

// show error alert
- (void)showErrorAlert:(NSString*)title message:(NSString*)errorMessage;
*/

@end
