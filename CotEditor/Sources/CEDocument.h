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


@class CEEditorView;
@class CEWindowController;
@class UKXattrMetadataStore;


typedef NS_ENUM(NSUInteger, CEGoToType) {
    CEGoToLine,
    CEGoToCharacter
};


@interface CEDocument : NSDocument

@property (nonatomic) CEEditorView *editorView;

// readonly properties
@property (nonatomic, readonly) CEWindowController *windowController;
@property (nonatomic, readonly) BOOL canActivateShowInvisibleCharsItem;// 不可視文字表示メニュー／ツールバーアイテムを有効化できるか
@property (nonatomic, readonly) NSStringEncoding encodingCode;  // 表示しているファイルのエンコーディング
@property (nonatomic, copy, readonly) NSDictionary *fileAttributes;  // ファイル属性情報辞書
@property (nonatomic, readonly) CETextSelection *selection;


// Public methods
- (BOOL)stringFromData:(NSData *)data encoding:(NSStringEncoding)encoding xattr:(BOOL)boolXattr;
- (NSString *)stringToWindowController;
- (void)setStringToEditorView;
- (void)setStringToTextView:(NSString *)string;
- (BOOL)doSetEncoding:(NSStringEncoding)encoding updateDocument:(BOOL)updateDocument
             askLossy:(BOOL)askLossy lossy:(BOOL)lossy asActionName:(NSString *)actionName;
- (void)clearAllMarkupForIncompatibleChar;
- (NSArray *)markupCharCanNotBeConvertedToCurrentEncoding;
- (NSArray *)markupCharCanNotBeConvertedToEncoding:(NSStringEncoding)encoding;
- (void)doSetNewLineEndingCharacterCode:(NSInteger)newLineEnding;
- (void)setLineEndingCharToView:(NSInteger)newLineEnding;
- (void)doSetSyntaxStyle:(NSString *)name;
- (void)doSetSyntaxStyle:(NSString *)name delay:(BOOL)needsDelay;
- (void)setColoringExtension:(NSString *)extension coloring:(BOOL)doColoring;
- (NSRange)rangeInTextViewWithLocation:(NSInteger)location withLength:(NSInteger)length;
- (void)setSelectedCharacterRangeInTextViewWithLocation:(NSInteger)location withLength:(NSInteger)length;
- (void)setSelectedLineRangeInTextViewWithLocation:(NSInteger)location withLength:(NSInteger)length;
- (void)scrollToCenteringSelection;
- (void)gotoLocation:(NSInteger)location withLength:(NSInteger)length type:(CEGoToType)type;
- (void)getFileAttributes;
- (void)rebuildToolbarEncodingItem;
- (void)setRecolorFlagToWindowControllerWithStyleName:(NSDictionary *)styleNameDict;
- (void)setStyleToNoneAndRecolorFlagWithStyleName:(NSString *)styleName;
- (NSString *)currentIANACharSetName;
- (void)showUpdatedByExternalProcessAlert;

// Action Message
- (IBAction)setLineEndingCharToLF:(id)sender;
- (IBAction)setLineEndingCharToCR:(id)sender;
- (IBAction)setLineEndingCharToCRLF:(id)sender;
- (IBAction)setLineEndingChar:(id)sender;
- (IBAction)setEncoding:(id)sender;
- (IBAction)changeSyntaxStyle:(id)sender;
- (IBAction)recoloringAllStringOfDocument:(id)sender;
- (IBAction)insertIANACharSetName:(id)sender;
- (IBAction)insertIANACharSetNameWithCharset:(id)sender;
- (IBAction)insertIANACharSetNameWithEncoding:(id)sender;
- (IBAction)selectPrevItemOfOutlineMenu:(id)sender;
- (IBAction)selectNextItemOfOutlineMenu:(id)sender;

@end
