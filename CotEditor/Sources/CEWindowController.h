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
@property (nonatomic) BOOL recolorWithBecomeKey; // ウィンドウがキーになったとき再カラーリングをするかどうかのフラグ

// document information (for binding in drawer)
@property (nonatomic) NSString *encodingInfo;// 文書のエンコーディング情報
@property (nonatomic) NSString *lineEndingsInfo;  // 文書の行末コード情報
@property (nonatomic) NSString *linesInfo;  // 行数
@property (nonatomic) NSString *charsInfo;  // 文字数
@property (nonatomic) NSString *wordsInfo;  // 単語数
@property (nonatomic) NSString *locationInfo;  // 文頭からのキャレット位置
@property (nonatomic) NSString *lineInfo;  // 現在行
@property (nonatomic) NSString *columnInfo;  // 文書の行頭からのキャレット位置
@property (nonatomic) NSString *singleCharInfo;  // 文書の選択文字

// Public method
- (BOOL)needsInfoDrawerUpdate;
- (BOOL)needsIncompatibleCharDrawerUpdate;
- (void)updateFileAttrsInformation;
- (void)updateIncompatibleCharList;
- (void)showIncompatibleCharList;

// Action Message
- (IBAction)getInfo:(id)sender;
- (IBAction)toggleIncompatibleCharList:(id)sender;
- (IBAction)selectIncompatibleRange:(id)sender;

@end
