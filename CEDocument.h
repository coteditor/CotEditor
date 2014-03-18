/*
=================================================
CEDocument
(for CotEditor)

 Copyright (C) 2004-2007 nakamuxu.
 Copyright (C) 2014 CotEditor Project
 http://coteditor.github.io
=================================================

encoding="UTF-8"
Created:2004.12.08

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
#import "CEApplication.h"
#import "CEDocumentController.h"
#import "CEEditorView.h"
#import "CEWindowController.h"
#import "CETextSelection.h"
#import "CEPrintView.h"
#import "UKXattrMetadataStore.h"


@class CEEditorView;
@class UKXattrMetadataStore;


typedef NS_ENUM(NSUInteger, CEGoToType) {
    CEGoToLine,
    CEGoToCharacter
};


@interface CEDocument : NSDocument
{
    id _windowController;
    CETextSelection *_selection;
}

@property (retain) CEEditorView *editorView;
@property BOOL doCascadeWindow;  // ウィンドウをカスケード表示するかどうか
@property NSPoint initTopLeftPoint;  // カスケードしないときのウィンドウ左上のポイント

// readonly properties
@property (readonly) BOOL canActivateShowInvisibleCharsItem;// 不可視文字表示メニュー／ツールバーアイテムを有効化できるか
@property (readonly) NSStringEncoding encodingCode;  // 表示しているファイルのエンコーディング
@property (readonly, retain) NSDictionary *fileAttributes;  // ファイル属性情報辞書

// ODB Editor Suite 対応プロパティ
@property (retain) NSAppleEventDescriptor *fileSender; // ファイルクライアントのシグネチャ
@property (retain) NSAppleEventDescriptor *fileToken; // ファイルクライアントの追加文字列

// Public methods
- (id)windowController;
- (BOOL)stringFromData:(NSData *)data encoding:(NSStringEncoding)encoding xattr:(BOOL)boolXattr;
- (NSString *)stringToWindowController;
- (void)setStringToEditorView;
- (void)setStringToTextView:(NSString *)inString;
- (BOOL)doSetEncoding:(NSStringEncoding)inEncoding updateDocument:(BOOL)inDocUpdate 
        askLossy:(BOOL)inAskLossy  lossy:(BOOL)inLossy asActionName:(NSString *)inName;
- (void)clearAllMarkupForIncompatibleChar;
- (NSArray *)markupCharCanNotBeConvertedToCurrentEncoding;
- (NSArray *)markupCharCanNotBeConvertedToEncoding:(NSStringEncoding)inEncoding;
- (void)doSetNewLineEndingCharacterCode:(NSInteger)inNewLineEnding;
- (void)setLineEndingCharToView:(NSInteger)inNewLineEnding;
- (void)doSetSyntaxStyle:(NSString *)inName;
- (void)doSetSyntaxStyle:(NSString *)inName delay:(BOOL)inBoolDelay;
- (void)setColoringExtension:(NSString *)inExtension coloring:(BOOL)inBoolColoring;
- (void)setFontToViewInWindow;
- (NSRange)rangeInTextViewWithLocation:(NSInteger)inLocation withLength:(NSInteger)inLength;
- (void)setSelectedCharacterRangeInTextViewWithLocation:(NSInteger)inLocation withLength:(NSInteger)inLength;
- (void)setSelectedLineRangeInTextViewWithLocation:(NSInteger)inLocation withLength:(NSInteger)inLength;
- (void)scrollToCenteringSelection;
- (void)gotoLocation:(NSInteger)inLocation withLength:(NSInteger)inLength type:(CEGoToType)type;
- (void)getFileAttributes;
- (void)rebuildToolbarEncodingItem;
- (void)rebuildToolbarSyntaxItem;
- (void)setRecolorFlagToWindowControllerWithStyleName:(NSDictionary *)inDictionary;
- (void)setStyleToNoneAndRecolorFlagWithStyleName:(NSString *)inStyleName;
- (void)setSmartInsertAndDeleteToTextView;
- (NSString *)currentIANACharSetName;
- (void)showUpdatedByExternalProcessAlert;

// Action Message
- (IBAction)setLineEndingCharToLF:(id)sender;
- (IBAction)setLineEndingCharToCR:(id)sender;
- (IBAction)setLineEndingCharToCRLF:(id)sender;
- (IBAction)setLineEndingChar:(id)sender;
- (IBAction)setEncoding:(id)sender;
- (IBAction)setSyntaxStyle:(id)sender;
- (IBAction)recoloringAllStringOfDocument:(id)sender;
- (IBAction)insertIANACharSetName:(id)sender;
- (IBAction)insertIANACharSetNameWithCharset:(id)sender;
- (IBAction)insertIANACharSetNameWithEncoding:(id)sender;
- (IBAction)selectPrevItemOfOutlineMenu:(id)sender;
- (IBAction)selectNextItemOfOutlineMenu:(id)sender;

@end
