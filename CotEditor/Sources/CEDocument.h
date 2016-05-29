/*
 
 CEDocument.h
 
 CotEditor
 http://coteditor.com
 
 Created by nakamuxu on 2004-12-08.

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
#import "NSString+CENewLine.h"


@class CEEditorWrapper;
@class CETextSelection;
@class CESyntaxStyle;
@class CEDocumentAnalyzer;
@class CEIncompatibleCharacterScanner;


// Notifications
extern NSString *_Nonnull const CEDocumentSyntaxStyleDidChangeNotification;


@interface CEDocument : NSDocument

// readonly properties
@property (readonly, nonatomic, nonnull) NSTextStorage *textStorage;
@property (readonly, nonatomic) NSStringEncoding encoding;
@property (readonly, nonatomic) BOOL hasUTF8BOM;
@property (readonly, nonatomic) CENewLineType lineEnding;
@property (readonly, nonatomic, nullable, copy) NSDictionary<NSString *, id> *fileAttributes;
@property (readonly, nonatomic, nonnull) CESyntaxStyle *syntaxStyle;

@property (readonly, nonatomic, nonnull) CETextSelection *selection;
@property (readonly, nonatomic, nonnull) CEDocumentAnalyzer *analyzer;
@property (readonly, nonatomic, nonnull) CEIncompatibleCharacterScanner *incompatibleCharacterScanner;

@property (readonly, nonatomic, nullable) CEEditorWrapper *editor;


#pragma mark - Public Methods

/// Return whole string in the current text storage which document's line endings are already applied to.  (Note: The internal text storage has always LF for its line ending.)
- (nonnull NSString *)string;

- (void)applyContentToWindow;

// string encoding
- (BOOL)reinterpretWithEncoding:(NSStringEncoding)encoding error:(NSError * _Nullable __autoreleasing * _Nullable)outError;
- (BOOL)doSetEncoding:(NSStringEncoding)encoding withUTF8BOM:(BOOL)withUTF8BOM updateDocument:(BOOL)updateDocument askLossy:(BOOL)askLossy lossy:(BOOL)lossy asActionName:(nullable NSString *)actionName;

// line ending
- (void)doSetLineEnding:(CENewLineType)lineEnding;

// syntax style
- (void)setSyntaxStyleWithName:(nullable NSString *)name;


#pragma mark Action Messages

- (IBAction)share:(nullable id)sender;
- (IBAction)changeLineEndingToLF:(nullable id)sender;
- (IBAction)changeLineEndingToCR:(nullable id)sender;
- (IBAction)changeLineEndingToCRLF:(nullable id)sender;
- (IBAction)changeLineEnding:(nullable id)sender;
- (IBAction)changeEncoding:(nullable id)sender;
- (IBAction)changeSyntaxStyle:(nullable id)sender;
- (IBAction)insertIANACharSetName:(nullable id)sender;
- (IBAction)insertIANACharSetNameWithCharset:(nullable id)sender;
- (IBAction)insertIANACharSetNameWithEncoding:(nullable id)sender;

@end
