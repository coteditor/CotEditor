/*
=================================================
CEDocument
(for CotEditor)

Copyright (C) 2004-2007 nakamuxu.
http://www.aynimac.com/
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
#import "UKKQueue.h"
#import "UKXattrMetadataStore.h"

@class CEEditorView;
@class UKXattrMetadataStore;

typedef struct {
     id delegate;
     SEL shouldCloseSelector;
     void *contextInfo;
} CanCloseAlertContext;

@interface CEDocument : NSDocument
{
    CEEditorView *_editorView;
    id _windowController;
    NSString *_initialString;
    NSStringEncoding _encoding;
    NSDictionary *_fileAttr;
    CETextSelection *_selection;
    NSAppleEventDescriptor *_fileSender;
    NSAppleEventDescriptor *_fileToken;

    BOOL _alphaOnlyTextViewInThisWindow;
    BOOL _doCascadeWindow;
    BOOL _isSaving;
    BOOL _showUpdateAlertWithBecomeKey;
    BOOL _isRevertingWithUKKQueueNotification;
    BOOL _canActivateShowInvisibleCharsItem;
    NSPoint _initTopLeftPoint;
}

// Public method
- (CEEditorView *)editorView;
- (void)setEditorView:(CEEditorView *)inEditorView;
- (id)windowController;
- (BOOL)stringFromData:(NSData *)inData encoding:(NSStringEncoding)ioEncoding xattr:(BOOL)inBoolXattr;

- (NSString *)stringToWindowController;
- (void)setStringToEditorView;
- (void)setStringToTextView:(NSString *)inString;
- (NSStringEncoding)encodingCode;
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
- (BOOL)alphaOnlyTextViewInThisWindow;
- (CGFloat)alpha;
- (void)setAlpha:(CGFloat)inAlpha;
- (void)setAlphaOnlyTextViewInThisWindow:(BOOL)inBool;
- (void)setAlphaToWindowAndTextView;
- (void)setAlphaToWindowAndTextViewDefaultValue;
- (void)setAlphaValueToTransparencyController;
- (NSAppleEventDescriptor *)fileSender;
- (void)setFileSender:(NSAppleEventDescriptor *)inFileSender;
- (NSAppleEventDescriptor *)fileToken;
- (void)setFileToken:(NSAppleEventDescriptor *)inFileToken;
- (NSRange)rangeInTextViewWithLocation:(NSInteger)inLocation withLength:(NSInteger)inLength;
- (void)setSelectedCharacterRangeInTextViewWithLocation:(NSInteger)inLocation withLength:(NSInteger)inLength;
- (void)setSelectedLineRangeInTextViewWithLocation:(NSInteger)inLocation withLength:(NSInteger)inLength;
- (void)scrollToCenteringSelection;
- (void)gotoLocation:(NSInteger)inLocation withLength:(NSInteger)inLength;
- (void)getFileAttributes;
- (NSDictionary *)documentFileAttributes;
- (void)rebuildToolbarEncodingItem;
- (void)rebuildToolbarSyntaxItem;
- (void)setRecolorFlagToWindowControllerWithStyleName:(NSDictionary *)inDictionary;
- (void)setStyleToNoneAndRecolorFlagWithStyleName:(NSString *)inStyleName;
- (BOOL)doCascadeWindow;
- (void)setDoCascadeWindow:(BOOL)inBool;
- (NSPoint)initTopLeftPoint;
- (void)setInitTopLeftPoint:(NSPoint)inPoint;
- (void)setSmartInsertAndDeleteToTextView;
- (NSString *)currentIANACharSetName;
- (void)showUpdateAlertWithUKKQueueNotification;
- (CGFloat)lineSpacingInTextView;
- (void)setCustomLineSpacingToTextView:(CGFloat)inSpacing;
- (BOOL)canActivateShowInvisibleCharsItem;

// Action Message
- (IBAction)setLineEndingCharToLF:(id)sender;
- (IBAction)setLineEndingCharToCR:(id)sender;
- (IBAction)setLineEndingCharToCRLF:(id)sender;
- (IBAction)setLineEndingChar:(id)sender;
- (IBAction)setEncoding:(id)sender;
- (IBAction)setSyntaxStyle:(id)sender;
- (IBAction)recoloringAllStringOfDocument:(id)sender;
- (IBAction)setWindowAlpha:(id)sender;
- (IBAction)setTransparencyOnlyTextView:(id)sender;
- (IBAction)insertIANACharSetName:(id)sender;
- (IBAction)insertIANACharSetNameWithCharset:(id)sender;
- (IBAction)insertIANACharSetNameWithEncoding:(id)sender;
- (IBAction)selectPrevItemOfOutlineMenu:(id)sender;
- (IBAction)selectNextItemOfOutlineMenu:(id)sender;

@end
