/*
 ==============================================================================
 CotEditor.h
 
 CotEditor
 http://coteditor.com
 
 Created on 2014-12-27 by 1024jp
 encoding="UTF-8"
 
 ------------
 generated from CotEditor.sdef using the following command:
   `sdef /Applications/CotEditor.app | sdp -fh --basename CotEditor`
 ------------------------------------------------------------------------------
 
 © 2014 1024jp
 
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

@import AppKit;
@import ScriptingBridge;


@class CotEditorApplication, CotEditorDocument, CotEditorWindow, CotEditorTextSelection, CotEditorRichText, CotEditorCharacter, CotEditorParagraph, CotEditorWord, CotEditorAttributeRun, CotEditorAttachment;

enum CotEditorSaveOptions {
	CotEditorSaveOptionsYes = 'yes ' /* Save the file. */,
	CotEditorSaveOptionsNo = 'no  ' /* Do not save the file. */,
	CotEditorSaveOptionsAsk = 'ask ' /* Ask the user whether or not to save the file. */
};
typedef enum CotEditorSaveOptions CotEditorSaveOptions;

enum CotEditorPrintingErrorHandling {
	CotEditorPrintingErrorHandlingStandard = 'lwst' /* Standard PostScript error handling */,
	CotEditorPrintingErrorHandlingDetailed = 'lwdt' /* print a detailed report of PostScript errors */
};
typedef enum CotEditorPrintingErrorHandling CotEditorPrintingErrorHandling;

enum CotEditorSaveableFileFormat {
	CotEditorSaveableFileFormatText = 'TXT ' /* The plain text. */
};
typedef enum CotEditorSaveableFileFormat CotEditorSaveableFileFormat;

enum CotEditorLineEndingCharacter {
	CotEditorLineEndingCharacterLF = 'leLF' /* OS X / Unix (LF) */,
	CotEditorLineEndingCharacterCR = 'leCR' /* Classic Mac OS (CR) */,
	CotEditorLineEndingCharacterCRLF = 'leCL' /* Windows (CR/LF) */
};
typedef enum CotEditorLineEndingCharacter CotEditorLineEndingCharacter;

enum CotEditorCaseType {
	CotEditorCaseTypeCapitalized = 'cCcp',
	CotEditorCaseTypeLower = 'cClw',
	CotEditorCaseTypeUpper = 'cCup'
};
typedef enum CotEditorCaseType CotEditorCaseType;

enum CotEditorKanaType {
	CotEditorKanaTypeHiragana = 'cHgn',
	CotEditorKanaTypeKatakana = 'cKkn'
};
typedef enum CotEditorKanaType CotEditorKanaType;

enum CotEditorUNFType {
	CotEditorUNFTypeNFC = 'cNfc',
	CotEditorUNFTypeNFD = 'cNfd',
	CotEditorUNFTypeNFKC = 'cNkc',
	CotEditorUNFTypeNFKD = 'cNkd'
};
typedef enum CotEditorUNFType CotEditorUNFType;

enum CotEditorCharacterWidthType {
	CotEditorCharacterWidthTypeFull = 'rWfl',
	CotEditorCharacterWidthTypeHalf = 'rWhf'
};
typedef enum CotEditorCharacterWidthType CotEditorCharacterWidthType;



/*
 * Standard Suite
 */

// The application's top-level scripting object.
@interface CotEditorApplication : SBApplication

- (SBElementArray *) documents;
- (SBElementArray *) windows;

@property (copy, readonly) NSString *name;  // The name of the application.
@property (readonly) BOOL frontmost;  // Is this the active application?
@property (copy, readonly) NSString *version;  // The version number of the application.

- (id) open:(id)x;  // Open a document.
- (void) print:(id)x withProperties:(NSDictionary *)withProperties printDialog:(BOOL)printDialog;  // Print a document.
- (void) quitSaving:(CotEditorSaveOptions)saving;  // Quit the application.
- (BOOL) exists:(id)x;  // Verify that an object exists.

@end

// A document.
@interface CotEditorDocument : SBObject

@property (copy, readonly) NSString *name;  // Its name.
@property (readonly) BOOL modified;  // Has it been modified since the last save?
@property (copy, readonly) NSURL *file;  // Its location on disk, if it has one.

- (void) closeSaving:(CotEditorSaveOptions)saving savingIn:(NSURL *)savingIn;  // Close a document.
- (void) saveIn:(NSURL *)in_ as:(CotEditorSaveableFileFormat)as;  // Save a document.
- (void) printWithProperties:(NSDictionary *)withProperties printDialog:(BOOL)printDialog;  // Print a document.
- (void) delete;  // Delete an object.
- (void) duplicateTo:(SBObject *)to withProperties:(NSDictionary *)withProperties;  // Copy an object.
- (void) moveTo:(SBObject *)to;  // Move an object to a new location.
- (BOOL) convertLossy:(BOOL)lossy to:(NSString *)to;  // Convert the document text to new encoding.
- (BOOL) findFor:(NSString *)for_ backwards:(BOOL)backwards ignoreCase:(BOOL)ignoreCase RE:(BOOL)RE wrap:(BOOL)wrap;  // Search text.
- (BOOL) reinterpretAs:(NSString *)as;  // Reinterpret the document text as new encoding.
- (NSInteger) replaceFor:(NSString *)for_ to:(NSString *)to all:(BOOL)all backwards:(BOOL)backwards ignoreCase:(BOOL)ignoreCase RE:(BOOL)RE wrap:(BOOL)wrap;  // Replace text.
- (void) scrollToCaret;  // Scroll document to caret or selected text.
- (NSString *) stringIn:(NSArray *)in_;  // Get text in desired range.

@end

// A window.
@interface CotEditorWindow : SBObject

@property (copy, readonly) NSString *name;  // The title of the window.
- (NSInteger) id;  // The unique identifier of the window.
@property NSInteger index;  // The index of the window, ordered front to back.
@property NSRect bounds;  // The bounding rectangle of the window.
@property (readonly) BOOL closeable;  // Does the window have a close button?
@property (readonly) BOOL miniaturizable;  // Does the window have a minimize button?
@property BOOL miniaturized;  // Is the window minimized right now?
@property (readonly) BOOL resizable;  // Can the window be resized?
@property BOOL visible;  // Is the window visible right now?
@property (readonly) BOOL zoomable;  // Does the window have a zoom button?
@property BOOL zoomed;  // Is the window zoomed right now?
@property (copy, readonly) CotEditorDocument *document;  // The document whose contents are displayed in the window.

- (void) closeSaving:(CotEditorSaveOptions)saving savingIn:(NSURL *)savingIn;  // Close a document.
- (void) saveIn:(NSURL *)in_ as:(CotEditorSaveableFileFormat)as;  // Save a document.
- (void) printWithProperties:(NSDictionary *)withProperties printDialog:(BOOL)printDialog;  // Print a document.
- (void) delete;  // Delete an object.
- (void) duplicateTo:(SBObject *)to withProperties:(NSDictionary *)withProperties;  // Copy an object.
- (void) moveTo:(SBObject *)to;  // Move an object to a new location.

@end



/*
 * CotEditor suite
 */

// A CotEditor window.
@interface CotEditorWindow (CotEditorSuite)

@property double viewOpacity;  // The opacity of the text view. (from ‘0.2’ to ‘1.0’)

@end

// A CotEditor document.
@interface CotEditorDocument (CotEditorSuite)

@property (copy) CotEditorAttributeRun *text;  // The whole text of the document.
@property (copy) NSString *coloringStyle;  // The current syntax style name.
@property (copy) CotEditorAttributeRun *contents;  // The contents of the document.
@property (copy, readonly) NSString *encoding;  // The encoding name of the document.
@property (copy, readonly) NSString *IANACharset;  // The IANA charset name of the document.
@property (readonly) NSInteger length;  // The number of characters in the document.
@property CotEditorLineEndingCharacter lineEnding;  // The line ending type of the document.
@property double lineSpacing;  // The spacing between text lines. (from ‘0.0’ to ‘10.0’)
@property NSInteger tabWidth;  // The width of a tab character in space equivalents.
@property (copy) CotEditorTextSelection *selection;  // The current selection.
@property BOOL wrapLines;  // Are lines wrapped?

@end

// A way to refer to the state of the current selection.
@interface CotEditorTextSelection : SBObject

@property (copy) CotEditorAttributeRun *contents;  // The contents of the selection.
@property (copy) NSArray *lineRange;  // The range of lines of the selection. The format is “{location, length}”.
@property (copy) NSArray *range;  // The range of characters in the selection. The format is “{location, length}”.

- (void) closeSaving:(CotEditorSaveOptions)saving savingIn:(NSURL *)savingIn;  // Close a document.
- (void) saveIn:(NSURL *)in_ as:(CotEditorSaveableFileFormat)as;  // Save a document.
- (void) printWithProperties:(NSDictionary *)withProperties printDialog:(BOOL)printDialog;  // Print a document.
- (void) delete;  // Delete an object.
- (void) duplicateTo:(SBObject *)to withProperties:(NSDictionary *)withProperties;  // Copy an object.
- (void) moveTo:(SBObject *)to;  // Move an object to a new location.
- (void) changeCaseTo:(CotEditorCaseType)to;  // Change the case of the selection.
- (void) changeKanaTo:(CotEditorKanaType)to;  // Change Japanese “Kana” mode of the selection.
- (void) changeRomanWidthTo:(CotEditorCharacterWidthType)to;  // Change width of Japanese roman charactors in the selection.
- (void) shiftLeft;  // Shift selected lines to left.
- (void) shiftRight;  // Shift selected lines to right.
- (void) commentOut;  // Append comment delimiters to selected text if possible.
- (void) uncomment;  // Remove comment delimiters from selected text if possible.
- (void) normalizeUnicodeTo:(CotEditorUNFType)to;  // Normalize Unicode.

@end



/*
 * Text Suite
 */

// Rich (styled) text.
@interface CotEditorRichText : SBObject

- (SBElementArray *) characters;
- (SBElementArray *) paragraphs;
- (SBElementArray *) words;
- (SBElementArray *) attributeRuns;
- (SBElementArray *) attachments;

@property (copy) NSColor *color;  // The color of the text’s first character.
@property (copy) NSString *font;  // The name of the font of the text’s first character.
@property NSInteger size;  // The size in points of the text’s first character.

- (void) closeSaving:(CotEditorSaveOptions)saving savingIn:(NSURL *)savingIn;  // Close a document.
- (void) saveIn:(NSURL *)in_ as:(CotEditorSaveableFileFormat)as;  // Save a document.
- (void) printWithProperties:(NSDictionary *)withProperties printDialog:(BOOL)printDialog;  // Print a document.
- (void) delete;  // Delete an object.
- (void) duplicateTo:(SBObject *)to withProperties:(NSDictionary *)withProperties;  // Copy an object.
- (void) moveTo:(SBObject *)to;  // Move an object to a new location.

@end

// One of some text’s characters.
@interface CotEditorCharacter : SBObject

- (SBElementArray *) characters;
- (SBElementArray *) paragraphs;
- (SBElementArray *) words;
- (SBElementArray *) attributeRuns;
- (SBElementArray *) attachments;

@property (copy) NSColor *color;  // Its color.
@property (copy) NSString *font;  // The name of its font.
@property NSInteger size;  // Its size, in points.

- (void) closeSaving:(CotEditorSaveOptions)saving savingIn:(NSURL *)savingIn;  // Close a document.
- (void) saveIn:(NSURL *)in_ as:(CotEditorSaveableFileFormat)as;  // Save a document.
- (void) printWithProperties:(NSDictionary *)withProperties printDialog:(BOOL)printDialog;  // Print a document.
- (void) delete;  // Delete an object.
- (void) duplicateTo:(SBObject *)to withProperties:(NSDictionary *)withProperties;  // Copy an object.
- (void) moveTo:(SBObject *)to;  // Move an object to a new location.

@end

// One of some text’s paragraphs.
@interface CotEditorParagraph : SBObject

- (SBElementArray *) characters;
- (SBElementArray *) paragraphs;
- (SBElementArray *) words;
- (SBElementArray *) attributeRuns;
- (SBElementArray *) attachments;

@property (copy) NSColor *color;  // The color of the paragraph’s first character.
@property (copy) NSString *font;  // The name of the font of the paragraph’s first character.
@property NSInteger size;  // The size in points of the paragraph’s first character.

- (void) closeSaving:(CotEditorSaveOptions)saving savingIn:(NSURL *)savingIn;  // Close a document.
- (void) saveIn:(NSURL *)in_ as:(CotEditorSaveableFileFormat)as;  // Save a document.
- (void) printWithProperties:(NSDictionary *)withProperties printDialog:(BOOL)printDialog;  // Print a document.
- (void) delete;  // Delete an object.
- (void) duplicateTo:(SBObject *)to withProperties:(NSDictionary *)withProperties;  // Copy an object.
- (void) moveTo:(SBObject *)to;  // Move an object to a new location.

@end

// One of some text’s words.
@interface CotEditorWord : SBObject

- (SBElementArray *) characters;
- (SBElementArray *) paragraphs;
- (SBElementArray *) words;
- (SBElementArray *) attributeRuns;
- (SBElementArray *) attachments;

@property (copy) NSColor *color;  // The color of the word’s first character.
@property (copy) NSString *font;  // The name of the font of the word’s first character.
@property NSInteger size;  // The size in points of the word’s first character.

- (void) closeSaving:(CotEditorSaveOptions)saving savingIn:(NSURL *)savingIn;  // Close a document.
- (void) saveIn:(NSURL *)in_ as:(CotEditorSaveableFileFormat)as;  // Save a document.
- (void) printWithProperties:(NSDictionary *)withProperties printDialog:(BOOL)printDialog;  // Print a document.
- (void) delete;  // Delete an object.
- (void) duplicateTo:(SBObject *)to withProperties:(NSDictionary *)withProperties;  // Copy an object.
- (void) moveTo:(SBObject *)to;  // Move an object to a new location.

@end

// A chunk of text that all has the same attributes.
@interface CotEditorAttributeRun : SBObject

- (SBElementArray *) characters;
- (SBElementArray *) paragraphs;
- (SBElementArray *) words;
- (SBElementArray *) attributeRuns;
- (SBElementArray *) attachments;

@property (copy) NSColor *color;  // Its color.
@property (copy) NSString *font;  // The name of its font.
@property NSInteger size;  // Its size, in points.

- (void) closeSaving:(CotEditorSaveOptions)saving savingIn:(NSURL *)savingIn;  // Close a document.
- (void) saveIn:(NSURL *)in_ as:(CotEditorSaveableFileFormat)as;  // Save a document.
- (void) printWithProperties:(NSDictionary *)withProperties printDialog:(BOOL)printDialog;  // Print a document.
- (void) delete;  // Delete an object.
- (void) duplicateTo:(SBObject *)to withProperties:(NSDictionary *)withProperties;  // Copy an object.
- (void) moveTo:(SBObject *)to;  // Move an object to a new location.

@end

// A file embedded in text. This is just for use when embedding a file using the make command.
@interface CotEditorAttachment : CotEditorRichText

@property (copy) NSString *fileName;  // The path to the embedded file.


@end

