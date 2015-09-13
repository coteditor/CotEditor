/*
 
 CEDocument.h
 
 CotEditor
 http://coteditor.com
 
 Created by nakamuxu on 2004-12-08.

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
#import "CEWindowController.h"
#import "CETextSelection.h"
#import "CEEditorWrapper.h"
#import "NSString+CENewLine.h"


@class CEEditorWrapper;
@class CEWindowController;


// Incompatible chars listController key
extern NSString *__nonnull const CEIncompatibleLineNumberKey;
extern NSString *__nonnull const CEIncompatibleRangeKey;
extern NSString *__nonnull const CEIncompatibleCharKey;
extern NSString *__nonnull const CEIncompatibleConvertedCharKey;


@interface CEDocument : NSDocument

@property (nonatomic, nullable) CEEditorWrapper *editor;

// readonly properties
@property (readonly, nonatomic, nullable) CEWindowController *windowController;
@property (readonly, nonatomic, nonnull) CETextSelection *selection;
@property (readonly, nonatomic) NSStringEncoding encoding;
@property (readonly, nonatomic) CENewLineType lineEnding;
@property (readonly, nonatomic, nullable, copy) NSDictionary<NSString *, id> *fileAttributes;
@property (readonly, nonatomic, getter=isWritable) BOOL writable;


#pragma mark - Public Methods

/// Return whole string in the current text view which document's line endings are already applied to.  (Note: The internal string (e.g. in text storage) has always LF for its line ending.)
- (nonnull NSString *)stringForSave;

- (void)applyContentToEditor;

// string encoding
- (nonnull NSString *)currentIANACharSetName;
- (nullable NSArray<NSDictionary<NSString *, NSValue *> *> *)findCharsIncompatibleWithEncoding:(NSStringEncoding)encoding;
- (BOOL)reinterpretWithEncoding:(NSStringEncoding)encoding error:(NSError * __nullable __autoreleasing * __nullable)outError;
- (BOOL)doSetEncoding:(NSStringEncoding)encoding updateDocument:(BOOL)updateDocument askLossy:(BOOL)askLossy lossy:(BOOL)lossy asActionName:(nullable NSString *)actionName;

// line ending
- (void)doSetLineEnding:(CENewLineType)lineEnding;

// syntax style
- (void)doSetSyntaxStyle:(nullable NSString *)name;


#pragma mark Action Messages

- (IBAction)changeLineEndingToLF:(nullable id)sender;
- (IBAction)changeLineEndingToCR:(nullable id)sender;
- (IBAction)changeLineEndingToCRLF:(nullable id)sender;
- (IBAction)changeLineEnding:(nullable id)sender;
- (IBAction)changeEncoding:(nullable id)sender;
- (IBAction)changeTheme:(nullable id)sender;
- (IBAction)changeSyntaxStyle:(nullable id)sender;
- (IBAction)insertIANACharSetName:(nullable id)sender;
- (IBAction)insertIANACharSetNameWithCharset:(nullable id)sender;
- (IBAction)insertIANACharSetNameWithEncoding:(nullable id)sender;

@end
