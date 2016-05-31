/*
 
 CEDocument.m
 
 CotEditor
 http://coteditor.com
 
 Created by nakamuxu on 2004-12-08.

 ------------------------------------------------------------------------------
 
 © 2004-2007 nakamuxu
 © 2011,2014 usami-k
 © 2013-2016 1024jp
 
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

@import ObjectiveC.message;

#import <NSHash/NSData+NSHash.h>

#import "CEDocument.h"
#import "CEDocumentController.h"
#import "CEDocumentAnalyzer.h"
#import "CEIncompatibleCharacterScanner.h"
#import "CEPrintPanelAccessoryController.h"
#import "CEPrintView.h"
#import "CETextSelection.h"
#import "CEODBEventSender.h"
#import "CESyntaxManager.h"
#import "CESyntaxStyle.h"
#import "CEWindowController.h"
#import "CEEditorWrapper.h"
#import "CETextView.h"

#import "NSString+CEEncoding.h"

#import "CEErrors.h"
#import "CEDefaults.h"
#import "CEEncodings.h"
#import "Constants.h"


// constants
static NSUInteger const CEUniqueFileIDLength = 8;
static NSString *_Nonnull const CEReadingEncodingKey = @"readingEncoding";
static NSString *_Nonnull const CESyntaxStyleKey = @"syntaxStyle";
static NSString *_Nonnull const CEAutosaveIdentierKey = @"autosaveIdentifier";

// file extended attributes
static NSString *_Nonnull const CEFileExtendedAttributes = @"NSFileExtendedAttributes";
static NSString *_Nonnull const CEXattrEncodingName = @"com.apple.TextEncoding";
static NSString *_Nonnull const CEXattrVerticalTextName = @"com.coteditor.VerticalText";

// error key
static NSString *_Nonnull const CEStringEncodingUTF8BOMErrorKey = @"CEStringEncodingUTF8BOMErrorKey";

// notifications
NSString *_Nonnull const CEDocumentSyntaxStyleDidChangeNotification = @"CEDocumentSyntaxStyleDidChangeNotification";


@interface CEDocument ()

@property (nonatomic, nullable) CEWindowController *windowController;
@property (nonatomic, nullable) CEPrintPanelAccessoryController *printPanelAccessoryController;
@property (nonatomic, nullable) IBOutlet NSView *savePanelAccessoryView;

@property (nonatomic) NSStringEncoding readingEncoding;  // encoding to read document file
@property (nonatomic) BOOL needsShowUpdateAlertWithBecomeKey;
@property (nonatomic, getter=isExternalUpdateAlertShown) BOOL externalUpdateAlertShown;
@property (nonatomic, nullable, copy) NSData *fileMD5;
@property (nonatomic, getter=isVerticalText) BOOL verticalText;
@property (nonatomic, nullable) CEODBEventSender *ODBEventSender;
@property (nonatomic) BOOL shouldSaveXattr;
@property (nonatomic, nonnull, copy) NSString *autosaveIdentifier;
@property (nonatomic) BOOL suppressesIANACharsetConflictAlert;
@property (nonatomic, getter=isExecutable) BOOL executable;

// readonly
@property (readwrite, nonatomic, nonnull) NSTextStorage *textStorage;
@property (readwrite, nonatomic) NSStringEncoding encoding;
@property (readwrite, nonatomic) BOOL hasUTF8BOM;
@property (readwrite, nonatomic) CENewLineType lineEnding;
@property (readwrite, nonatomic, nullable, copy) NSDictionary<NSString *, id> *fileAttributes;
@property (readwrite, nonatomic, nonnull) CESyntaxStyle *syntaxStyle;

@property (readwrite, nonatomic, nonnull) CETextSelection *selection;
@property (readwrite, nonatomic, nonnull) CEDocumentAnalyzer *analyzer;
@property (readwrite, nonatomic, nonnull) CEIncompatibleCharacterScanner *incompatibleCharacterScanner;

@end




#pragma mark -

@implementation CEDocument

#pragma mark Superclass Methods

// ------------------------------------------------------
/// enable Autosave in Place
+ (BOOL)autosavesInPlace
// ------------------------------------------------------
{
    static dispatch_once_t onceToken;
    static BOOL autosavesInPlace;
    
    // avoid changing the value while the application is running
    dispatch_once(&onceToken, ^{
        autosavesInPlace = [[NSUserDefaults standardUserDefaults] boolForKey:CEDefaultEnablesAutosaveInPlaceKey];
    });
    
    return autosavesInPlace;
}


// ------------------------------------------------------
/// can read document on a background thread?
+ (BOOL)canConcurrentlyReadDocumentsOfType:(nonnull NSString *)typeName
// ------------------------------------------------------
{
    return YES;
}


// ------------------------------------------------------
/// initialize instance
- (nonnull instancetype)init
// ------------------------------------------------------
{
    self = [super init];
    if (self) {
        [self setHasUndoManager:YES];
        
        _shouldSaveXattr = YES;
        _autosaveIdentifier = [[[NSUUID UUID] UUIDString] substringToIndex:CEUniqueFileIDLength];
        
        _textStorage = [[NSTextStorage alloc] init];
        _encoding = [[NSUserDefaults standardUserDefaults] integerForKey:CEDefaultEncodingInNewKey];
        if (_encoding == NSUTF8StringEncoding) {
            _hasUTF8BOM = [[NSUserDefaults standardUserDefaults] boolForKey:CEDefaultSaveUTF8BOMKey];
        }
        _lineEnding = [[NSUserDefaults standardUserDefaults] integerForKey:CEDefaultLineEndCharCodeKey];
        _syntaxStyle = [[CESyntaxManager sharedManager] styleWithName:[[NSUserDefaults standardUserDefaults] stringForKey:CEDefaultSyntaxStyleKey]];
        
        _selection = [[CETextSelection alloc] initWithDocument:self];
        _analyzer = [[CEDocumentAnalyzer alloc] initWithDocument:self];
        _incompatibleCharacterScanner = [[CEIncompatibleCharacterScanner alloc] initWithDocument:self];
        
        // set encoding to read file
        // -> The value is either user setting or selection of open panel.
        // -> This must be set before `readFromData:ofType:error:` is called.
        _readingEncoding = [[CEDocumentController sharedDocumentController] accessorySelectedEncoding];
        
        // observe sytnax style update
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(syntaxDidUpdate:)
                                                     name:CESyntaxDidUpdateNotification
                                                   object:nil];
    }
    return self;
}


// ------------------------------------------------------
/// initialize instance with existing file
- (nullable instancetype)initWithContentsOfURL:(nonnull NSURL *)url ofType:(nonnull NSString *)typeName error:(NSError * _Nullable __autoreleasing * _Nullable)outError
// ------------------------------------------------------
{
    // [caution] This method may be called from a background thread due to concurrent-opening.
    // This method won't be invoked on Resume. (2015-01-26)
    
    self = [super initWithContentsOfURL:url ofType:typeName error:outError];
    if (self) {
        // set sender of external editor protocol (ODB Editor Suite)
        _ODBEventSender = [[CEODBEventSender alloc] init];
        
        // check file meta data for text orientation
        if ([[NSUserDefaults standardUserDefaults] boolForKey:CEDefaultSavesTextOrientationKey]) {
            NSDictionary<NSString *, id> *attributes = [[NSFileManager defaultManager] attributesOfItemAtPath:[url path] error:outError];  // FILE_READ
            _verticalText = attributes[CEFileExtendedAttributes][CEXattrVerticalTextName];
        }
    }
    return self;
}


// ------------------------------------------------------
/// clean up
- (void)dealloc
// ------------------------------------------------------
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}


// ------------------------------------------------------
/// make custom windowControllers
- (void)makeWindowControllers
// ------------------------------------------------------
{
    [self setWindowController:[[CEWindowController alloc] init]];
    [self addWindowController:[self windowController]];
}


// ------------------------------------------------------
/// load document from file and return whether it succeeded
- (BOOL)readFromURL:(nonnull NSURL *)url ofType:(nonnull NSString *)typeName error:(NSError * _Nullable __autoreleasing * _Nullable)outError
// ------------------------------------------------------
{
    // [caution] This method may be called from a background thread due to concurrent-opening.
    
    NSData *data = [NSData dataWithContentsOfURL:url options:0 error:outError];  // FILE_READ
    if (!data) { return NO; }
    
    // store file hash (MD5) in order to check the file content identity in `presentedItemDidChange`
    [self setFileMD5:[data MD5]];
    
    // read file attributes only if `fileURL` exists
    // -> The passed-in `url` in this method can point to a file that isn't the real document file,
    //    for example on resuming of an unsaved document.
    if ([self fileURL]) {
        NSDictionary<NSString *, id> *attributes = [[NSFileManager defaultManager] attributesOfItemAtPath:[[self fileURL] path] error:outError];  // FILE_READ
        [self setFileAttributes:attributes];
        [self setExecutable:([attributes filePosixPermissions] & S_IXUSR) != 0];
    }
    
    // try reading the `com.apple.TextEncoding` extended attribute
    NSDictionary<NSString *, id> *extendedAttributes = [[NSFileManager defaultManager] attributesOfItemAtPath:[url path] error:outError][CEFileExtendedAttributes];  // FILE_READ
    NSStringEncoding xattrEncoding = decodeXattrEncoding(extendedAttributes[CEXattrEncodingName]);
    
    // don't save xattr if file doesn't have it in order to avoid saving wrong encoding (2015-01 by 1024jp).
    [self setShouldSaveXattr:(xattrEncoding != NSNotFound) || ([data length] == 0)];
    
    NSString *string;
    NSStringEncoding usedEncoding;
    
    if ([self readingEncoding] == CEAutoDetectEncoding) {
        string = [self stringFromData:data xattrEncoding:xattrEncoding usedEncoding:&usedEncoding error:outError];
    } else {  // interpret with specific encoding
        usedEncoding = [self readingEncoding];
        string = ([data length] > 0) ? [NSString stringWithContentsOfURL:url encoding:[self readingEncoding] error:outError] : @"";  // FILE_READ
    }
    BOOL hasUTF8BOM = (usedEncoding == NSUTF8StringEncoding) ? [data hasUTF8BOM] : NO;
    
    if (!string) { return NO; }
    
    // set read values
    [self setEncoding:usedEncoding];
    [self setHasUTF8BOM:hasUTF8BOM];
    
    CENewLineType lineEnding = [string detectNewLineType];
    if (lineEnding != CENewLineNone) {  // keep default if no line endings are found
        [self setLineEnding:lineEnding];
    }
    
    // standardize line endings to LF (File Open)
    // (Line endings replacemement by other text modifications are processed in the following methods.)
    //
    // # Methods Standardizing Line Endings on Text Editing
    //   - File Open:
    //       - CEDocument > readFromURL:ofType:error:
    //   - Key Typing, Script, Paste, Drop or Replace via Find Panel:
    //       - CETextViewDelegate > textView:shouldChangeTextInRange:replacementString:
    string = [string stringByReplacingNewLineCharacersWith:CENewLineLF];
    
    [[self textStorage] replaceCharactersInRange:NSMakeRange(0, [[self textStorage] length]) withString:string];
    
    // determine syntax style
    NSString *styleName = [[CESyntaxManager sharedManager] styleNameFromFileName:[url lastPathComponent]];
    if (!styleName && string) {
        styleName = [[CESyntaxManager sharedManager] styleNameFromContent:string];
    }
    styleName = styleName ? : [[NSUserDefaults standardUserDefaults] stringForKey:CEDefaultSyntaxStyleKey];
    [self setSyntaxStyleWithName:styleName];
    
    return YES;
}


// ------------------------------------------------------
/// revert to saved file contents
- (BOOL)revertToContentsOfURL:(nonnull NSURL *)url ofType:(nonnull NSString *)typeName error:(NSError * _Nullable __autoreleasing * _Nullable)outError
// ------------------------------------------------------
{
    BOOL success = [super revertToContentsOfURL:url ofType:typeName error:outError];
    
    // apply to UI
    if (success) {
        [self applyContentToWindow];
    }
    
    return success;
}


// ------------------------------------------------------
/// return preferred file extension corresponding the current syntax style
- (nullable NSString *)fileNameExtensionForType:(nonnull NSString *)typeName saveOperation:(NSSaveOperationType)saveOperation
// ------------------------------------------------------
{
    if ([self fileURL]) {
        return [[self fileURL] pathExtension];
    }
    
    NSString *styleName = [[self syntaxStyle] styleName];
    NSArray<NSString *> *extensions = [[CESyntaxManager sharedManager] extensionsForStyleName:styleName];
    
    return [extensions firstObject];
}


// ------------------------------------------------------
/// create NSData object to save
- (nullable NSData *)dataOfType:(nonnull NSString *)typeName error:(NSError * _Nullable __autoreleasing * _Nullable)outError
// ------------------------------------------------------
{
    NSStringEncoding encoding = [self encoding];
    BOOL hasUTF8BOM = [self hasUTF8BOM];
    
    // convert Yen sign in consideration of the current encoding
    NSString *string = [[self string] stringByConvertingYenSignForEncoding:encoding];
    
    // unblock the user interface, since fetching current document state has been done here
    [self unblockUserInteraction];
    
    // get data from string to save
    NSData *data = [string dataUsingEncoding:encoding allowLossyConversion:YES];
    
    // show encoding error if encoding failed
    if (!data && outError) {
        *outError = [NSError errorWithDomain:NSCocoaErrorDomain
                                        code:NSFileWriteInapplicableStringEncodingError
                                    userInfo:@{NSStringEncodingErrorKey: @(encoding)}];
    }
    if (!data) { return nil; }
    
    // add UTF-8 BOM if needed
    if ((encoding == NSUTF8StringEncoding) && hasUTF8BOM) {
        data = [data dataByAddingUTF8BOM];
    }
    
    return data;
}


// ------------------------------------------------------
/// enable asynchronous saving
- (BOOL)canAsynchronouslyWriteToURL:(nonnull NSURL *)url ofType:(nonnull NSString *)typeName forSaveOperation:(NSSaveOperationType)saveOperation
// ------------------------------------------------------
{
    return (saveOperation == NSAutosaveElsewhereOperation ||
            saveOperation == NSAutosaveInPlaceOperation);
}


// ------------------------------------------------------
/// save or autosave the document contents to a file
- (void)saveToURL:(nonnull NSURL *)url ofType:(nonnull NSString *)typeName forSaveOperation:(NSSaveOperationType)saveOperation completionHandler:(nonnull void (^)(NSError * _Nullable))completionHandler
// ------------------------------------------------------
{
    // trim trailing whitespace if needed
    if ([[NSUserDefaults standardUserDefaults] boolForKey:CEDefaultTrimsTrailingWhitespaceOnSaveKey]) {
        BOOL keepsEditingPoint = (saveOperation == NSAutosaveInPlaceOperation || saveOperation == NSAutosaveElsewhereOperation);
        [[[self editor] focusedTextView] trimTrailingWhitespaceKeepingEditingPoint:keepsEditingPoint];
    }
    
    // break undo grouping
    [[[self editor] focusedTextView] breakUndoCoalescing];
    
    // modify place to create backup file
    //   -> save backup file always in `~/Library/Autosaved Information/` directory
    //      (The default backup URL is the same directory as the fileURL.)
    if (saveOperation == NSAutosaveElsewhereOperation && [self fileURL]) {
        NSURL *autosaveDirectoryURL =  [[CEDocumentController sharedDocumentController] autosaveDirectoryURL];
        NSString *baseFileName = [[self fileURL] lastPathComponent];
        if ([baseFileName hasPrefix:@"."]) {  // avoid file to be hidden
            baseFileName = [baseFileName substringFromIndex:1];
        }
        NSString *fileName = [NSString stringWithFormat:@"%@ (%@)",
                              [baseFileName stringByDeletingPathExtension],
                              [self autosaveIdentifier]];  // append a unique string to avoid overwriting another backup file with the same file name.
        
        url = [[autosaveDirectoryURL URLByAppendingPathComponent:fileName] URLByAppendingPathExtension:[baseFileName pathExtension]];
    }
    
    __weak typeof(self) weakSelf = self;
    [super saveToURL:url ofType:typeName forSaveOperation:saveOperation completionHandler:^(NSError *error)
     {
         // [note] This completionHandler block will always be invoked on the main thread.
         
         typeof(self) self = weakSelf;  // strong self
         
         if (!error) {
             // apply syntax style that is inferred from the file name
             if (saveOperation == NSSaveAsOperation) {
                 NSString *styleName = [[CESyntaxManager sharedManager] styleNameFromFileName:[url lastPathComponent]];
                 if (styleName) {
                     [self setSyntaxStyleWithName:styleName];
                 }
             }
             
             if (saveOperation != NSAutosaveElsewhereOperation) {
                 // get the latest file attributes
                 NSDictionary<NSString *, id> *attributes = [[NSFileManager defaultManager] attributesOfItemAtPath:[url path] error:nil];  // FILE_READ
                 [self setFileAttributes:attributes];
                 
                 // update file information
                 [[self analyzer] invalidateFileInfo];
                 
                 // send file update notification for the external editor protocol (ODB Editor Suite)
                 [[self ODBEventSender] sendModifiedEventWithURL:url operation:saveOperation];
             }
         }
         
         completionHandler(error);
     }];
}


// ------------------------------------------------------
/// ファイルの保存(保存処理で包括的に呼ばれる)
- (BOOL)writeToURL:(nonnull NSURL *)url ofType:(nonnull NSString *)typeName forSaveOperation:(NSSaveOperationType)saveOperation originalContentsURL:(nullable NSURL *)absoluteOriginalContentsURL error:(NSError * _Nullable __autoreleasing * _Nullable)outError
// ------------------------------------------------------
{
    // [caution] This method may be called from a background thread due to async-saving.
    
    // store current state here, since the main thread will already be unblocked after `dataOfType:error:`
    NSStringEncoding encoding = [self encoding];
    [self setVerticalText:[[self editor] isVerticalLayoutOrientation]];
    
    BOOL success = [super writeToURL:url ofType:typeName forSaveOperation:saveOperation originalContentsURL:absoluteOriginalContentsURL error:outError];

    if (success) {
        if (saveOperation != NSAutosaveElsewhereOperation) {
            // store file hash (MD5) in order to check the file content identity in `presentedItemDidChange`
            NSData *data = [NSData dataWithContentsOfURL:url];  // FILE_READ
            [self setFileMD5:[data MD5]];
            
            // store file encoding for revert
            [self setReadingEncoding:encoding];
        }
    }

    return success;
}


// ------------------------------------------------------
/// customize document's file attributes
- (nullable NSDictionary<NSString *, id> *)fileAttributesToWriteToURL:(nonnull NSURL *)url ofType:(nonnull NSString *)typeName forSaveOperation:(NSSaveOperationType)saveOperation originalContentsURL:(nullable NSURL *)absoluteOriginalContentsURL error:(NSError * _Nullable __autoreleasing *)outError
// ------------------------------------------------------
{
    NSMutableDictionary<NSString *, id> *attributes = [[super fileAttributesToWriteToURL:url ofType:typeName forSaveOperation:saveOperation originalContentsURL:absoluteOriginalContentsURL error:outError] mutableCopy];
    
    if (!attributes) { return nil; }  // super failed
    
    // save encoding to the external file attributes (com.apple.TextEncoding)
    if (saveOperation == NSAutosaveElsewhereOperation || [self shouldSaveXattr]) {
        if (!attributes[CEFileExtendedAttributes]) {
            attributes[CEFileExtendedAttributes] = [NSMutableDictionary dictionary];
        }
        attributes[CEFileExtendedAttributes][CEXattrEncodingName] = encodeXattrEncoding([self encoding]);
    }
    // save text orientation state to the external file attributes (com.coteditor.VerticalText)
    if ([[NSUserDefaults standardUserDefaults] boolForKey:CEDefaultSavesTextOrientationKey]) {
        if (!attributes[CEFileExtendedAttributes] && [self isVerticalText]) {
            attributes[CEFileExtendedAttributes] = [NSMutableDictionary dictionary];
        }
        attributes[CEFileExtendedAttributes][CEXattrVerticalTextName] = [self isVerticalText] ? [NSData dataWithBytes:"1" length:1] : nil;
    }
    
    // give the execute permission if user requested
    if ([self isExecutable] && saveOperation != NSAutosaveElsewhereOperation) {
        NSUInteger permissions = [attributes filePosixPermissions];
        if (permissions == 0) {
            if (absoluteOriginalContentsURL) {  // read from old one if not exists
                permissions = [[[NSFileManager defaultManager] attributesOfItemAtPath:[absoluteOriginalContentsURL path] error:outError] filePosixPermissions];  // FILE_READ
            } else {
                permissions = 0644;  // ???: Is the default permission really always 644?
            }
        }
        attributes[NSFilePosixPermissions] = @(permissions | S_IXUSR);
    }
    
    return attributes;
}


// ------------------------------------------------------
/// セーブパネルへ標準のアクセサリビュー(ポップアップメニューでの書類の切り替え)を追加しない
- (BOOL)shouldRunSavePanelWithAccessoryView
// ------------------------------------------------------
{
    return NO;
}


// ------------------------------------------------------
/// セーブパネルを準備
- (BOOL)prepareSavePanel:(nonnull NSSavePanel *)savePanel
// ------------------------------------------------------
{
    // reset file types, otherwise:
    //   - alert dialog will be displayed if user inputs another extension.
    //   - cannot save without extension.
    [savePanel setAllowedFileTypes:nil];
    
    // disable hide extension checkbox
    [savePanel setExtensionHidden:NO];
    [savePanel setCanSelectHiddenExtension:NO];
    
    // set accessory view
    if (![self savePanelAccessoryView]) {
        [[NSBundle mainBundle] loadNibNamed:@"SaveDocumentAccessory" owner:self topLevelObjects:nil];
    }
    [savePanel setAccessoryView:[self savePanelAccessoryView]];
    
    // append file extension as a part of the file name
    // -> NSSaveAsOperation will remove the current file extension from file name in the nameField
    //    as we set nil to `setAllowedFileTypes:` just above.
    //    So, we need to set it again manually.
    NSString *extension = [self fileNameExtensionForType:[self fileType] saveOperation:NSSaveOperation];
    if (extension) {
        [savePanel setNameFieldStringValue:[[savePanel nameFieldStringValue] stringByAppendingPathExtension:extension]];
    }
    
    return [super prepareSavePanel:savePanel];
}


// ------------------------------------------------------
/// ドキュメントが閉じられる前に保存のためのダイアログの表示などを行う
- (void)canCloseDocumentWithDelegate:(nonnull id)delegate shouldCloseSelector:(nullable SEL)shouldCloseSelector contextInfo:(nullable void *)contextInfo
// ------------------------------------------------------
{
    // Disable save dialog if content is empty and not saved
    if (![self fileURL] && [[self textStorage] length] == 0) {
        [self updateChangeCount:NSChangeCleared];
    }
    
    [super canCloseDocumentWithDelegate:delegate shouldCloseSelector:shouldCloseSelector contextInfo:contextInfo];
}


// ------------------------------------------------------
/// ドキュメントを閉じる
- (void)close
// ------------------------------------------------------
{
    [[self syntaxStyle] cancelAllParses];
    
    // send file close notification for the external editor protocol (ODB Editor Suite)
    if ([self fileURL]) {
        [[self ODBEventSender] sendCloseEventWithURL:[self fileURL]];
    }
    
    [super close];
}


// ------------------------------------------------------
/// プリントパネルを含むプリント用設定を生成して返す
- (nullable NSPrintOperation *)printOperationWithSettings:(nonnull NSDictionary<NSString *, id> *)printSettings error:(NSError * _Nullable __autoreleasing * _Nullable)outError
// ------------------------------------------------------
{
    // create printView
    CEPrintView *printView = [[CEPrintView alloc] init];
    [printView setLayoutOrientation:[[[self editor] focusedTextView] layoutOrientation]];
    [printView setTheme:[[self editor] theme]];
    [printView setDocumentName:[self displayName]];
    [printView setFilePath:[[self fileURL] path]];
    [printView setSyntaxName:[[self syntaxStyle] styleName]];
    [printView setDocumentShowsInvisibles:[[self editor] showsInvisibles]];
    [printView setDocumentShowsLineNum:[[self editor] showsLineNum]];
    [printView setLineSpacing:[[[self editor] focusedTextView] lineSpacing]];
    
    // set font for printing
    NSFont *font;
    if ([[NSUserDefaults standardUserDefaults] integerForKey:CEDefaultSetPrintFontKey] == 1) { // == use printing font
        font = [NSFont fontWithName:[[NSUserDefaults standardUserDefaults] stringForKey:CEDefaultPrintFontNameKey]
                               size:(CGFloat)[[NSUserDefaults standardUserDefaults] doubleForKey:CEDefaultPrintFontSizeKey]];
    } else {
        font = [[self editor] font];
    }
    [printView setFont:font];
    
    // [caution] need to set string after setting other properties
    [printView setString:[[self textStorage] string]];
    
    // create print operation
    NSPrintOperation *printOperation = [NSPrintOperation printOperationWithView:printView printInfo:[self printInfo]];
    [[[printOperation printInfo] dictionary] addEntriesFromDictionary:printSettings];
    [printOperation setShowsProgressPanel:YES];
    [printOperation setCanSpawnSeparateThread:YES];  // display print progress panel as a sheet
    
    // setup print panel
    if (![self printPanelAccessoryController]) {
        [self setPrintPanelAccessoryController:[[CEPrintPanelAccessoryController alloc] init]];
    }
    NSPrintPanel *printPanel = [printOperation printPanel];
    [printPanel addAccessoryController:[self printPanelAccessoryController]];
    [printPanel setOptions:[printPanel options] |  NSPrintPanelShowsPaperSize | NSPrintPanelShowsOrientation | NSPrintPanelShowsScaling];
    
    return printOperation;
}


// ------------------------------------------------------
/// printing information associated with the document
- (nonnull NSPrintInfo *)printInfo
// ------------------------------------------------------
{
    NSPrintInfo *printInfo = [super printInfo];
    
    [printInfo setHorizontalPagination:NSFitPagination];
    [printInfo setHorizontallyCentered:NO];
    [printInfo setVerticallyCentered:NO];
    [printInfo setLeftMargin:kHorizontalPrintMargin];
    [printInfo setRightMargin:kHorizontalPrintMargin];
    [printInfo setTopMargin:kVerticalPrintMargin];
    [printInfo setBottomMargin:kVerticalPrintMargin];
    [printInfo dictionary][NSPrintHeaderAndFooter] = @YES;
    
    return printInfo;
}


// ------------------------------------------------------
/// setup duplicated document
- (__kindof NSDocument *)duplicateAndReturnError:(NSError * _Nullable __autoreleasing * _Nullable)outError
// ------------------------------------------------------
{
    CEDocument *document = [super duplicateAndReturnError:outError];
    
    [document setSyntaxStyleWithName:[[self syntaxStyle] styleName]];
    [document setLineEnding:[self lineEnding]];
    [document setEncoding:[self encoding]];
    [document setHasUTF8BOM:[self hasUTF8BOM]];
    
    // apply text orientation
    [[document editor] setVerticalLayoutOrientation:[[self editor] isVerticalLayoutOrientation]];
    
    return document;
}


// ------------------------------------------------------
/// store internal document state
- (void)encodeRestorableStateWithCoder:(nonnull NSCoder *)coder
// ------------------------------------------------------
{
    [coder encodeInteger:[self encoding] forKey:CEReadingEncodingKey];
    [coder encodeObject:[self autosaveIdentifier] forKey:CEAutosaveIdentierKey];
    [coder encodeObject:[[self syntaxStyle] styleName] forKey:CESyntaxStyleKey];
    
    [super encodeRestorableStateWithCoder:coder];
}


// ------------------------------------------------------
/// resume UI state
- (void)restoreStateWithCoder:(nonnull NSCoder *)coder
// ------------------------------------------------------
{
    [super restoreStateWithCoder:coder];
    
    if ([coder containsValueForKey:CEReadingEncodingKey]) {
        [self setReadingEncoding:[coder decodeIntegerForKey:CEReadingEncodingKey]];
    }
    if ([coder containsValueForKey:CEAutosaveIdentierKey]) {
        [self setAutosaveIdentifier:[coder decodeObjectForKey:CEAutosaveIdentierKey]];
    }
    if ([coder containsValueForKey:CESyntaxStyleKey]) {
        [self setSyntaxStyleWithName:[coder decodeObjectForKey:CESyntaxStyleKey]];
    }
}


// ------------------------------------------------------
/// recover presented error
- (void)attemptRecoveryFromError:(nonnull NSError *)error optionIndex:(NSUInteger)recoveryOptionIndex delegate:(nullable id)delegate didRecoverSelector:(SEL)didRecoverSelector contextInfo:(nullable void *)contextInfo
// ------------------------------------------------------
{
    BOOL didRecover = NO;
    if ([[error domain] isEqualToString:CEErrorDomain]) {
        switch ([error code]) {
            case CEUnconvertibleCharactersError:
                switch (recoveryOptionIndex) {
                    case 0:  // == Show Incompatible Chars
                        [[self windowController] showIncompatibleCharList];
                        break;
                    case 1:  // == Save
                        didRecover = YES;
                        break;
                    case 2:  // == Cancel
                        break;
                }
                break;
                
            case CELossyEncodingConversionError:
                switch (recoveryOptionIndex) {
                    case 0:  // == Cancel
                        [self setEncoding:[self encoding]];  // reset to force reverting toolbar selection
                        break;
                    case 1:  // == Change Encoding
                        [self changeEncoding:[[error userInfo][NSStringEncodingErrorKey] unsignedIntegerValue]
                                 withUTF8BOM:[[error userInfo][CEStringEncodingUTF8BOMErrorKey] boolValue]
                                    askLossy:NO lossy:YES];
                        [[[self undoManager] prepareWithInvocationTarget:[self windowController]] showIncompatibleCharList];
                        [[self windowController] showIncompatibleCharList];
                        didRecover = YES;
                        break;
                }
                break;
        }
    }
    
    // call the delegate's didRecoverSelector
    if (delegate) {
        ((void (*)(id, SEL, BOOL, void *))objc_msgSend)(delegate, didRecoverSelector, didRecover, contextInfo);
    }
}



#pragma mark Protocol

//=======================================================
// NSMenuValidation Protocol
//=======================================================

// ------------------------------------------------------
/// メニュー項目の有効・無効を制御
- (BOOL)validateMenuItem:(nonnull NSMenuItem *)menuItem
// ------------------------------------------------------
{
    NSInteger state = NSOffState;
    
    if ([menuItem action] == @selector(changeEncoding:)) {
        NSInteger encodingTag = [self hasUTF8BOM] ? -[self encoding] : [self encoding];
        state = ([menuItem tag] == encodingTag) ? NSOnState : NSOffState;
        
    } else if (([menuItem action] == @selector(changeLineEndingToLF:)) ||
               ([menuItem action] == @selector(changeLineEndingToCR:)) ||
               ([menuItem action] == @selector(changeLineEndingToCRLF:)) ||
               ([menuItem action] == @selector(changeLineEnding:)))
    {
        state = ([menuItem tag] == [self lineEnding]) ? NSOnState : NSOffState;
        
    } else if ([menuItem action] == @selector(changeSyntaxStyle:)) {
        NSString *name = [[self syntaxStyle] styleName];
        if (name && [[menuItem title] isEqualToString:name]) {
            state = NSOnState;
        }
        
    }
    [menuItem setState:state];
    
    return [super validateMenuItem:menuItem];
}


//=======================================================
// NSFilePresenter Protocol
//=======================================================

// ------------------------------------------------------
/// file location has changed
- (void)presentedItemDidMoveToURL:(nonnull NSURL *)newURL
// ------------------------------------------------------
{
    [super presentedItemDidMoveToURL:newURL];
    
    __weak typeof(self) weakSelf = self;
    dispatch_async(dispatch_get_main_queue(), ^{
        typeof(self) self = weakSelf;  // strong self
        if (!self) { return; }
        
        // -> `fileURL` property will be updated automatically after this `presentedItemDidMoveToURL:`.
        //    However, we don't know when exactly, therefore update it manually before update documentAnalyzer. (2016-05-19 / OS X 10.11.5)
        [self setFileURL:newURL];
        
        [[self analyzer] invalidateFileInfo];
    });
}


// ------------------------------------------------------
/// file has been modified by an external process
- (void)presentedItemDidChange
// ------------------------------------------------------
{
    // [caution] This method can be called from any thread.
    
    CEDocumentConflictOption option = [[NSUserDefaults standardUserDefaults] integerForKey:CEDefaultDocumentConflictOptionKey];
    
    // do nothing
    if (option == CEDocumentConflictIgnore) { return; }
    
    // don't check twice if document is already marked as modified
    if ([self needsShowUpdateAlertWithBecomeKey]) { return; }
    
    // ignore if file's modificationDate is the same as document's modificationDate
    __block NSDate *fileModificationDate;
    NSFileCoordinator *coordinator = [[NSFileCoordinator alloc] initWithFilePresenter:self];
    [coordinator coordinateReadingItemAtURL:[self fileURL] options:NSFileCoordinatorReadingWithoutChanges
                                      error:nil byAccessor:^(NSURL *newURL)
     {
         NSDictionary<NSString *, id> *fileAttrs = [[NSFileManager defaultManager] attributesOfItemAtPath:[newURL path] error:nil];  // FILE_READ
         fileModificationDate = [fileAttrs fileModificationDate];
     }];
    if ([fileModificationDate isEqualToDate:[self fileModificationDate]]) { return; }
    
    // ignore if file's MD5 hash is the same as the stored MD5 and deal as if it was not modified
    __block NSData *MD5;
    [coordinator coordinateReadingItemAtURL:[self fileURL] options:NSFileCoordinatorReadingWithoutChanges
                                      error:nil byAccessor:^(NSURL *newURL)
     {
         MD5 = [[NSData dataWithContentsOfURL:newURL] MD5];  // FILE_READ
     }];
    if ([MD5 isEqualToData:[self fileMD5]]) {
        // update the document's fileModificationDate for a workaround (2014-03 by 1024jp)
        // If not, an alert shows up when user saves the file.
        if ([fileModificationDate compare:[self fileModificationDate]] == NSOrderedDescending) {
            [self setFileModificationDate:fileModificationDate];
        }
        
        return;
    }
    
    // notify about external file update
    __weak typeof(self) weakSelf = self;
    dispatch_async(dispatch_get_main_queue(), ^{
        typeof(self) self = weakSelf;  // strong self
        if (!self) { return; }
        
        if (option == CEDocumentConflictRevert) {
            // revert
            [self revertToContentsOfURL:[self fileURL] ofType:[self fileType] error:nil];
            
        } else {
            // notify and show dialog later
            [self notifyExternalFileUpdate];
        }
    });
}



#pragma mark Public Methods

// ------------------------------------------------------
/// 改行コードを指定のものに置換したメイン textView の文字列を返す
- (nonnull NSString *)string
// ------------------------------------------------------
{
    NSString *editorString = [[self textStorage] string];  // line endings are always LF
    
    if (!editorString) {
        return @"";
    }
    if ([self lineEnding] == CENewLineLF) {
        return [NSString stringWithString:editorString];
    }
    
    return [editorString stringByReplacingNewLineCharacersWith:[self lineEnding]];
}


// ------------------------------------------------------
/// return document window's editor wrapper
- (nullable CEEditorWrapper *)editor
// ------------------------------------------------------
{
    return [[self windowController] editor];
}


// ------------------------------------------------------
/// transfer file information to UI
- (void)applyContentToWindow
// ------------------------------------------------------
{
    CEEditorWrapper *editor = [self editor];
    
    [editor invalidateStyleInTextStorage];
    
    // update status bar and document inspector
    [[self analyzer] invalidateFileInfo];
    [[self analyzer] invalidateModeInfo];
    [[self analyzer] invalidateEditorInfo];
    
    // update incompatible characters if pane is visible
    [[self incompatibleCharacterScanner] invalidate];
    
    // apply text orientation
    [editor setVerticalLayoutOrientation:[self isVerticalText]];
}


// ------------------------------------------------------
/// reinterpret file with the desired encoding and show error dialog if failed
- (void)reinterpretWithEncoding:(NSStringEncoding)encoding
// ------------------------------------------------------
{
    NSError *error = nil;
    [self reinterpretWithEncoding:encoding error:&error];
    
    if (error) {
        NSBeep();
        [self presentError:error modalForWindow:[self windowForSheet] delegate:nil didPresentSelector:NULL contextInfo:NULL];
    }
}


// ------------------------------------------------------
/// 指定されたエンコーディングでファイルを再解釈する
- (BOOL)reinterpretWithEncoding:(NSStringEncoding)encoding error:(NSError * _Nullable __autoreleasing * _Nullable)outError
// ------------------------------------------------------
{
    BOOL success = NO;
    
    if (encoding == NSNotFound || ![self fileURL]) {
        if (outError) {
            // TODO: add userInfo (The outError under this condition will actually not be used, but better not to pass an empty errer pointer.)
            *outError = [NSError errorWithDomain:CEErrorDomain code:CEReinterpretationFailedError userInfo:nil];
        }
        return NO;
    }
    
    // do nothing if given encoding is the same as current one
    if (encoding == [self encoding]) { return YES; }
    
    // reinterpret
    [self setReadingEncoding:encoding];
    success = [self revertToContentsOfURL:[self fileURL] ofType:[self fileType] error:nil];
    
    // set outError
    if (!success && outError) {
        NSString *encodingName = [NSString localizedNameOfStringEncoding:encoding];
        
        *outError = [NSError errorWithDomain:CEErrorDomain
                                        code:CEReinterpretationFailedError
                                    userInfo:@{NSLocalizedDescriptionKey: NSLocalizedString(@"Can not reinterpret.", nil),
                                               NSLocalizedRecoverySuggestionErrorKey: [NSString stringWithFormat:NSLocalizedString(@"The file “%@” could not be reinterpreted using the new encoding “%@”.", nil), [[self fileURL] lastPathComponent], encodingName],
                                               NSStringEncodingErrorKey: @(encoding),
                                               NSURLErrorKey: [self fileURL],
                                               }];
    }
    
    return success;
}


// ------------------------------------------------------
/// change string encoding registering process to the undo manager
- (BOOL)changeEncoding:(NSStringEncoding)encoding withUTF8BOM:(BOOL)withUTF8BOM askLossy:(BOOL)askLossy lossy:(BOOL)lossy
// ------------------------------------------------------
{
    if (encoding == [self encoding] && withUTF8BOM == [self hasUTF8BOM]) {
        return YES;
    }
    
    NSString *encodingName = [NSString localizedNameOfStringEncoding:encoding withUTF8BOM:withUTF8BOM];
    
    if (askLossy) {
        if (![[self string] canBeConvertedToEncoding:encoding]) {
            NSError *error = [NSError errorWithDomain:CEErrorDomain
                                                 code:CELossyEncodingConversionError
                                             userInfo:@{NSLocalizedDescriptionKey: [NSString stringWithFormat:NSLocalizedString(@"Some characters would have to be changed or deleted in saving as “%@”.", nil), encodingName],
                                                        NSLocalizedRecoverySuggestionErrorKey: NSLocalizedString(@"Do you want to change encoding and show incompatible characters?", nil),
                                                        NSLocalizedRecoveryOptionsErrorKey: @[NSLocalizedString(@"Cancel", nil),
                                                                                              NSLocalizedString(@"Change Encoding", nil)],
                                                        NSRecoveryAttempterErrorKey: self,
                                                        NSStringEncodingErrorKey: @(encoding),
                                                        CEStringEncodingUTF8BOMErrorKey: @(withUTF8BOM),
                                                        }];
            
            [[[self windowForSheet] attachedSheet] orderOut:self];  // close previous sheet
            [self presentError:error modalForWindow:[self windowForSheet] delegate:nil didPresentSelector:NULL contextInfo:NULL];
            return NO;
        }
    }
    
    // register undo
    NSUndoManager *undoManager = [self undoManager];
    [[undoManager prepareWithInvocationTarget:self] redoChangeEncoding:encoding withUTF8BOM:withUTF8BOM askLossy:NO lossy:lossy];  // redo in undo
    [[undoManager prepareWithInvocationTarget:self] applyEncodingToView];
    [[undoManager prepareWithInvocationTarget:[self incompatibleCharacterScanner]] scan];
    [[undoManager prepareWithInvocationTarget:self] setEncoding:[self encoding]];
    [[undoManager prepareWithInvocationTarget:self] setHasUTF8BOM:[self hasUTF8BOM]];
    [undoManager setActionName:[NSString stringWithFormat:NSLocalizedString(@"Encoding to “%@”", nil), encodingName]];
    
    // update encoding
    [self setEncoding:encoding];
    [self setHasUTF8BOM:withUTF8BOM];
    [[self incompatibleCharacterScanner] scan];
    [self applyEncodingToView];  // update UI
    
    return YES;
}


// ------------------------------------------------------
/// change line endings registering process to the undo manager
- (void)doSetLineEnding:(CENewLineType)lineEnding
// ------------------------------------------------------
{
    if (lineEnding == [self lineEnding]) { return; }
    
    CENewLineType currentLineEnding = [self lineEnding];

    // register undo
    NSUndoManager *undoManager = [self undoManager];
    [[undoManager prepareWithInvocationTarget:self] redoSetLineEnding:lineEnding];  // redo in undo
    [[undoManager prepareWithInvocationTarget:self] applyLineEndingToView];
    [[undoManager prepareWithInvocationTarget:self] setLineEnding:currentLineEnding];
    [undoManager setActionName:[NSString stringWithFormat:NSLocalizedString(@"Line Endings to “%@”", nil),
                                [NSString newLineNameWithType:lineEnding]]];

    [self setLineEnding:lineEnding];
    [self applyLineEndingToView];  // update UI
}


// ------------------------------------------------------
/// 新しいシンタックスカラーリングスタイルを適用
- (void)setSyntaxStyleWithName:(nullable NSString *)styleName
// ------------------------------------------------------
{
    if ([styleName length] == 0) { return; }
    
    CESyntaxStyle *syntaxStyle = [[CESyntaxManager sharedManager] styleWithName:styleName];
    
    if ([syntaxStyle isEqualToSyntaxStyle:[self syntaxStyle]]) { return; }
    
    [[self syntaxStyle] cancelAllParses];
    
    // update
    [syntaxStyle setTextStorage:[self textStorage]];
    [self setSyntaxStyle:syntaxStyle];
    
    [[NSNotificationCenter defaultCenter] postNotificationName:CEDocumentSyntaxStyleDidChangeNotification
                                                        object:self];
}



#pragma mark Notifications

//=======================================================
// Notification  <- CESyntaxManager
//=======================================================

// ------------------------------------------------------
/// set a flag of syntax highlight update if corresponded style has been updated
- (void)syntaxDidUpdate:(nonnull NSNotification *)notification
// ------------------------------------------------------
{
    NSString *oldName = [notification userInfo][CEOldNameKey];
    NSString *newName = [notification userInfo][CENewNameKey];
    
    if (![oldName isEqualToString:[[self syntaxStyle] styleName]]) { return; }
    
    [self setSyntaxStyleWithName:newName];
}



#pragma mark Action Messages

// ------------------------------------------------------
/// 保存
- (IBAction)saveDocument:(nullable id)sender
// ------------------------------------------------------
{
    [self askSavingSafetyWithCompletionHandler:^(BOOL continuesSaving) {
        if (continuesSaving) {
            [super saveDocument:sender];
        }
    }];
}


// ------------------------------------------------------
/// 別名で保存
- (IBAction)saveDocumentAs:(nullable id)sender
// ------------------------------------------------------
{
    [self askSavingSafetyWithCompletionHandler:^(BOOL continuesSaving) {
        if (continuesSaving) {
            [super saveDocumentAs:sender];
        }
    }];
}


// ------------------------------------------------------
/// show Share Service menu
- (IBAction)share:(nullable id)sender
// ------------------------------------------------------
{
    NSURL *url = [self fileURL];
    NSArray<NSURL *> *items = url ? @[url] : @[];
    
    NSSharingServicePicker *sharingServicePicker = [[NSSharingServicePicker alloc] initWithItems:items];
    [sharingServicePicker showRelativeToRect:[sender bounds]
                                      ofView:sender
                               preferredEdge:NSMinYEdge];
}


// ------------------------------------------------------
/// share document
- (IBAction)shareFromService:(nullable id)sender
// ------------------------------------------------------
{
    if ([[sender representedObject] isKindOfClass:[NSSharingService class]]) {
        [(NSSharingService *)[sender representedObject] performWithItems:@[[self fileURL]]];
    }
}


// ------------------------------------------------------
/// ドキュメントに新しい改行コードをセットする
- (IBAction)changeLineEndingToLF:(nullable id)sender
// ------------------------------------------------------
{
    [self doSetLineEnding:CENewLineLF];
}


// ------------------------------------------------------
/// ドキュメントに新しい改行コードをセットする
- (IBAction)changeLineEndingToCR:(nullable id)sender
// ------------------------------------------------------
{
    [self doSetLineEnding:CENewLineCR];
}


// ------------------------------------------------------
/// ドキュメントに新しい改行コードをセットする
- (IBAction)changeLineEndingToCRLF:(nullable id)sender
// ------------------------------------------------------
{
    [self doSetLineEnding:CENewLineCRLF];
}


// ------------------------------------------------------
/// ドキュメントに新しい改行コードをセットする
- (IBAction)changeLineEnding:(nullable id)sender
// ------------------------------------------------------
{
    [self doSetLineEnding:[sender tag]];
}


// ------------------------------------------------------
/// ドキュメントに新しいエンコーディングをセットする
- (IBAction)changeEncoding:(nullable id)sender
// ------------------------------------------------------
{
    NSStringEncoding encoding = labs([sender tag]);
    BOOL withUTF8BOM = ([sender tag] == -NSUTF8StringEncoding);

    if ((encoding == [self encoding]) && (withUTF8BOM == [self hasUTF8BOM])) { return; }
    
    // change encoding immediately if there is nothing to worry about
    if (([[self textStorage] length] < 1) ||  // no content yet
        ![self fileURL] ||  // not yet saved
       (encoding == NSUTF8StringEncoding  && encoding == [self encoding])) // toggle only BOM existance
    {
        [self changeEncoding:encoding withUTF8BOM:withUTF8BOM askLossy:YES lossy:NO];
        return;
    }
    
    // ask whether just change the encoding or reinterpret docuemnt file
    NSString *encodingName = [sender title];
    NSAlert *alert = [[NSAlert alloc] init];
    [alert setMessageText:NSLocalizedString(@"File encoding", nil)];
    [alert setInformativeText:[NSString stringWithFormat:NSLocalizedString(@"Do you want to convert or reinterpret this document using “%@”?", nil), encodingName]];
    [alert addButtonWithTitle:NSLocalizedString(@"Convert", nil)];
    [alert addButtonWithTitle:NSLocalizedString(@"Reinterpret", nil)];
    [alert addButtonWithTitle:NSLocalizedString(@"Cancel", nil)];
    
    __weak typeof(self) weakSelf = self;
    [alert beginSheetModalForWindow:[self windowForSheet] completionHandler:^(NSInteger returnCode)
     {
         typeof(self) self = weakSelf;
         
         switch (returnCode) {
             case NSAlertFirstButtonReturn:  // = Convert
                 [self changeEncoding:encoding withUTF8BOM:withUTF8BOM askLossy:YES lossy:NO];
                 break;
                 
             case NSAlertSecondButtonReturn:  // = Reinterpret
                 if ([self isDocumentEdited]) {
                     NSAlert *alert = [[NSAlert alloc] init];
                     [alert setMessageText:[NSString stringWithFormat:NSLocalizedString(@"The file “%@” has unsaved changes.", nil), [[self fileURL] lastPathComponent]]];
                     [alert setInformativeText:NSLocalizedString(@"Do you want to discard the changes and reset the file encoding?", nil)];
                     [alert addButtonWithTitle:NSLocalizedString(@"Cancel", nil)];
                     [alert addButtonWithTitle:NSLocalizedString(@"Discard Changes", nil)];
                     
                     [[[self windowForSheet] attachedSheet] orderOut:self];  // close previous sheet
                     [alert beginSheetModalForWindow:[self windowForSheet] completionHandler:^(NSInteger returnCode) {
                         switch (returnCode) {
                             case NSAlertFirstButtonReturn:  // = Cancel
                                 // reset toolbar selection for in case if the operation was invoked from the toolbar popup
                                 [self setEncoding:[self encoding]];
                                 break;
                                 
                             default:  // = Discard Changes
                                 [self reinterpretWithEncoding:encoding];
                                 break;
                         }
                     }];
                 } else {
                     [self reinterpretWithEncoding:encoding];
                 }
                 break;
                 
             default:  // = Cancel
                 // reset toolbar selection for in case if the operation was invoked from the toolbar popup
                 [self setEncoding:[self encoding]];
         }
     }];
}


// ------------------------------------------------------
/// 新しいシンタックスカラーリングスタイルを適用
- (IBAction)changeSyntaxStyle:(nullable id)sender
// ------------------------------------------------------
{
    NSString *name = [sender title];

    if (![name isEqualToString:[[self syntaxStyle] styleName]]) {
        [self setSyntaxStyleWithName:name];
    }
}


// ------------------------------------------------------
/// IANA文字コード名を挿入する
- (IBAction)insertIANACharSetName:(nullable id)sender
// ------------------------------------------------------
{
    NSString *string = [NSString IANACharSetNameOfStringEncoding:[self encoding]];
    
    if (!string) { return; }
    
    [[self editor] insertTextViewString:string];
}



#pragma mark Private Methods

// ------------------------------------------------------
/// ツールバーのエンコーディングメニュー、ステータスバー、インスペクタを更新
- (void)applyEncodingToView
// ------------------------------------------------------
{
    [[self analyzer] invalidateModeInfo];
}


// ------------------------------------------------------
/// 改行コードをエディタに反映
- (void)applyLineEndingToView
// ------------------------------------------------------
{
    [[self analyzer] invalidateModeInfo];
    [[self analyzer] invalidateEditorInfo];
}


//------------------------------------------------------
/// データから指定エンコードで文字列を読み込み返す (auto detection)
- (nullable NSString *)stringFromData:(nonnull NSData *)data xattrEncoding:(NSStringEncoding)xattrEncoding usedEncoding:(nonnull NSStringEncoding *)usedEncoding error:(NSError * _Nullable __autoreleasing * _Nullable)outError
//------------------------------------------------------
{
    NSString *string;
    
    // try interpreting with xattr encoding
    if (xattrEncoding != NSNotFound) {
        // just trust xattr encoding if content is empty
        string = ([data length] > 0) ? [[NSString alloc] initWithData:data encoding:xattrEncoding] : @"";
        
        if (string) {
            *usedEncoding = xattrEncoding;
            return string;
        }
    }
    
    // detect encoding from data
    string = [[NSString alloc] initWithData:data
                       suggestedCFEncodings:[[NSUserDefaults standardUserDefaults] arrayForKey:CEDefaultEncodingListKey] ?: @[]
                               usedEncoding:usedEncoding
                                      error:outError];
    
    if (string) {
        // "charset=" や "encoding=" を読んでみて適正なエンコーディングが得られたら、そちらを優先
        NSStringEncoding scannedEncoding = [self scanEncodingDeclarationInString:string];
        if (scannedEncoding != NSNotFound && scannedEncoding != *usedEncoding) {
            NSString *tmpString = [[NSString alloc] initWithData:data encoding:scannedEncoding];
            if (tmpString) {
                *usedEncoding = scannedEncoding;
                return tmpString;
            }
        }
    } else if (outError) {
        *outError = [NSError errorWithDomain:NSCocoaErrorDomain
                                        code:NSFileReadUnknownStringEncodingError
                                    userInfo:nil];
    }
    
    return string;
}


// ------------------------------------------------------
/// "charset=" "encoding="タグなどからエンコーディング定義を読み取る
- (NSStringEncoding)scanEncodingDeclarationInString:(nonnull NSString *)string
// ------------------------------------------------------
{
    if (![[NSUserDefaults standardUserDefaults] boolForKey:CEDefaultReferToEncodingTagKey]) {
        return NSNotFound;
    }
    
    return [string scanEncodingDeclarationForTags:@[@"charset=", @"encoding=", @"@charset", @"encoding:", @"coding:"]
                                        upToIndex:kMaxEncodingScanLength
                             suggestedCFEncodings:[[NSUserDefaults standardUserDefaults] arrayForKey:CEDefaultEncodingListKey]];
}


// ------------------------------------------------------
/// check can save safety with the current encoding and ask if not
- (void)askSavingSafetyWithCompletionHandler:(nonnull void (^)(BOOL))completionHandler
// ------------------------------------------------------
{
    NSString *string = [self string];
    NSStringEncoding encoding = [self encoding];
    
    NSError *error;
    
    // IANA文字コード名を読み、設定されたエンコーディングと矛盾があれば警告する
    if (![self suppressesIANACharsetConflictAlert]) {
        if (![self checkSavingSafetyWithIANACharSetNameForString:string encoding:encoding error:&error]) {
            // --> ask directly with a non-sheet NSAlert for the suppression button
            NSAlert *alert = [NSAlert alertWithError:error];
            [alert setShowsSuppressionButton:YES];
            [[alert suppressionButton] setTitle:NSLocalizedString(@"Do not show this warning for this document again", nil)];
            
            NSInteger result = [alert runModal];
            // do not show the alert in this document again
            if ([[alert suppressionButton] state] == NSOnState) {
                [self setSuppressesIANACharsetConflictAlert:YES];
            }
            
            switch (result) {
                case NSAlertFirstButtonReturn:  // == Cancel
                    completionHandler(NO);
                    return;
                    
                case NSAlertSecondButtonReturn:  // == Continue Saving
                    break;
            }
        }
    }
    
    // ファイル保存前のエンコーディング変換チェック、ユーザに承認を求める
    if (![self checkSavingSafetyForConvertingString:string encoding:encoding error:&error]) {
        [self presentError:error
            modalForWindow:[self windowForSheet]
                  delegate:self
        didPresentSelector:@selector(didPresentErrorWithRecovery:block:)
               contextInfo:Block_copy((__bridge void *)completionHandler)];
    
    } else {
        completionHandler(YES);
    }
}


// ------------------------------------------------------
/// 書類内のIANA文字コード名と設定されたエンコーディングの矛盾をチェック
- (BOOL)checkSavingSafetyWithIANACharSetNameForString:(nonnull NSString *)string encoding:(NSStringEncoding)encoding error:(NSError * _Nullable __autoreleasing *  _Nullable)outError
// ------------------------------------------------------
{
    NSStringEncoding IANACharSetEncoding = [self scanEncodingDeclarationInString:string];
    
    if ((IANACharSetEncoding != NSNotFound) &&
        !CEIsCompatibleIANACharSetEncoding(IANACharSetEncoding, encoding))
    {
        if (outError) {
            NSString *encodingName = [NSString localizedNameOfStringEncoding:encoding];
            NSString *IANAName = [NSString localizedNameOfStringEncoding:IANACharSetEncoding];
            
            *outError = [NSError errorWithDomain:CEErrorDomain
                                            code:CEIANACharsetNameConflictError
                                        userInfo:@{NSLocalizedDescriptionKey: [NSString stringWithFormat:NSLocalizedString(@"The encoding is “%@”, but the IANA charset name in text is “%@”.", nil), encodingName, IANAName],
                                                   NSLocalizedRecoverySuggestionErrorKey: NSLocalizedString(@"Do you want to continue processing?", nil),
                                                   NSLocalizedRecoveryOptionsErrorKey: @[NSLocalizedString(@"Cancel", nil),
                                                                                         NSLocalizedString(@"Continue Saving", nil)],
                                                   NSRecoveryAttempterErrorKey: self,
                                                   NSStringEncodingErrorKey: @(encoding),
                                                   }];
        }
        
        return NO;
    }
    
    return YES;
}


// ------------------------------------------------------
/// ファイル保存前のエンコーディング変換チェック
- (BOOL)checkSavingSafetyForConvertingString:(nonnull NSString *)string encoding:(NSStringEncoding)encoding error:(NSError * _Nullable __autoreleasing *  _Nullable)outError
// ------------------------------------------------------
{
    // エンコーディングを見て、半角円マークを変換しておく
    NSString *newString = [string stringByConvertingYenSignForEncoding:encoding];
    
    if (![newString canBeConvertedToEncoding:encoding]) {
        if (outError) {
            NSString *encodingName = [NSString localizedNameOfStringEncoding:encoding];
            
            *outError = [NSError errorWithDomain:CEErrorDomain
                                            code:CEUnconvertibleCharactersError
                                        userInfo:@{NSLocalizedDescriptionKey: [NSString stringWithFormat:NSLocalizedString(@"Some characters would have to be changed or deleted in saving as “%@”.", nil), encodingName],
                                                   NSLocalizedRecoverySuggestionErrorKey: NSLocalizedString(@"Do you want to continue processing?", nil),
                                                   NSLocalizedRecoveryOptionsErrorKey: @[NSLocalizedString(@"Show Incompatible Chars", nil),
                                                                                         NSLocalizedString(@"Save Available Strings", nil),
                                                                                         NSLocalizedString(@"Cancel", nil)],
                                                   NSRecoveryAttempterErrorKey: self,
                                                   NSStringEncodingErrorKey: @(encoding),
                                                   }];
        }
        
        return NO;
    }
    
    return YES;
}


// ------------------------------------------------------
/// エンコードを変更するアクションのRedo登録
- (void)redoChangeEncoding:(NSStringEncoding)encoding withUTF8BOM:(BOOL)withUTF8BOM askLossy:(BOOL)askLossy lossy:(BOOL)lossy
// ------------------------------------------------------
{
    [[[self undoManager] prepareWithInvocationTarget:self] changeEncoding:encoding withUTF8BOM:withUTF8BOM askLossy:askLossy lossy:lossy];
}


// ------------------------------------------------------
/// 改行コードを変更するアクションのRedo登録
- (void)redoSetLineEnding:(CENewLineType)lineEnding
// ------------------------------------------------------
{
    [[[self undoManager] prepareWithInvocationTarget:self] doSetLineEnding:lineEnding];
}


// ------------------------------------------------------
/// notify about external file update
- (void)notifyExternalFileUpdate
// ------------------------------------------------------
{
    // rise a flag
    [self setNeedsShowUpdateAlertWithBecomeKey:YES];
    
    if ([NSApp isActive]) {
        // display dialog immediately
        [self showUpdatedByExternalProcessAlert];
        
    } else {
        // alert first when application becomes active
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(showUpdatedByExternalProcessAlert)
                                                     name:NSApplicationDidBecomeActiveNotification object:nil];
        
        // let application icon in Dock jump
        [NSApp requestUserAttention:NSInformationalRequest];
    }
}


// ------------------------------------------------------
/// display alert about file modification by an external process
- (void)showUpdatedByExternalProcessAlert
// ------------------------------------------------------
{
    [[NSNotificationCenter defaultCenter] removeObserver:self name:NSApplicationDidBecomeActiveNotification object:nil];
    
    if (![self needsShowUpdateAlertWithBecomeKey]) { return; }
    if ([self isExternalUpdateAlertShown]) { return; }  // do nothing if alert is already shown
    
    NSString *messageText;
    if ([self isDocumentEdited]) {
        messageText = @"The file has been modified by another application. There are also unsaved changes in CotEditor.";
    } else {
        messageText = @"The file has been modified by another application.";
    }
    
    NSAlert *alert = [[NSAlert alloc] init];
    [alert setMessageText:NSLocalizedString(messageText, nil)];
    [alert setInformativeText:NSLocalizedString(@"Do you want to keep CotEditor’s edition or update to the modified edition?", nil)];
    [alert addButtonWithTitle:NSLocalizedString(@"Keep CotEditor’s Edition", nil)];
    [alert addButtonWithTitle:NSLocalizedString(@"Update", nil)];
    
    // completion handler for alert sheet
    __weak typeof(self) weakSelf = self;
    void (^did_close_alert)(NSInteger) = ^(NSInteger returnCode) {
        typeof(self) self = weakSelf;  // strong self
        
        if (returnCode == NSAlertSecondButtonReturn) { // == Revert
            [self revertToContentsOfURL:[self fileURL] ofType:[self fileType] error:nil];
        }
        [self setExternalUpdateAlertShown:NO];
        [self setNeedsShowUpdateAlertWithBecomeKey:NO];
    };
    
    [self setExternalUpdateAlertShown:YES];
    [[self windowForSheet] orderFront:nil];
    
    // display alert
    if ([[self windowForSheet] attachedSheet]) {  // show alert as a normal dialog if any of sheet is already attached
        NSInteger result = [alert runModal];
        did_close_alert(result);
        
    } else {
        [alert beginSheetModalForWindow:[self windowForSheet] completionHandler:did_close_alert];
    }
}


// ------------------------------------------------------
/// perform didRecoverBlock after recovering presented error
- (void)didPresentErrorWithRecovery:(BOOL)didRecover block:(void (^)(BOOL))block
// ------------------------------------------------------
{
    block(didRecover);
}

@end
