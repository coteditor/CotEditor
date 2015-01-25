/*
 ==============================================================================
 CEDocument
 
 CotEditor
 http://coteditor.com
 
 Created on 2004-12-08 by nakamuxu
 encoding="UTF-8"
 ------------------------------------------------------------------------------
 
 © 2004-2007 nakamuxu
 © 2011,2014 usami-k
 © 2014-2015 1024jp
 
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

@import ObjectiveC.message;
#import "CEDocument.h"
#import "CEDocumentController.h"
#import "CEPrintPanelAccessoryController.h"
#import "CEPrintView.h"
#import "CEODBEventSender.h"
#import "CESyntaxManager.h"
#import "CEUtils.h"
#import "NSURL+AppleTextEncoding.h"
#import "constants.h"


// constants
static char const UTF8_BOM[] = {0xef, 0xbb, 0xbf};

// incompatible chars dictionary keys
NSString *const CEIncompatibleLineNumberKey = @"lineNumber";
NSString *const CEIncompatibleRangeKey = @"incompatibleRange";
NSString *const CEIncompatibleCharKey = @"incompatibleChar";
NSString *const CEIncompatibleConvertedCharKey = @"convertedChar";


@interface CEDocument ()

@property (nonatomic) CEPrintPanelAccessoryController *printPanelAccessoryController;

@property (atomic) BOOL needsShowUpdateAlertWithBecomeKey;
@property (atomic, getter=isRevertingForExternalFileUpdate) BOOL revertingForExternalFileUpdate;
@property (nonatomic) BOOL didAlertNotWritable;  // 文書が読み込み専用のときにその警告を表示したかどうか
@property (nonatomic, copy) NSString *fileContentString;  // string that is read from the document file
@property (nonatomic) CEODBEventSender *ODBEventSender;
@property (nonatomic) BOOL shouldSaveXattr;

// readonly
@property (readwrite, nonatomic) CEWindowController *windowController;
@property (readwrite, nonatomic) CETextSelection *selection;
@property (readwrite, nonatomic) NSStringEncoding encoding;
@property (readwrite, nonatomic) CENewLineType lineEnding;
@property (readwrite, nonatomic, copy) NSDictionary *fileAttributes;
@property (readwrite, nonatomic, getter=isWritable) BOOL writable;

@end




#pragma mark -

@implementation CEDocument

#pragma mark Superclass Methods

// ------------------------------------------------------
/// enable AutoSave
+ (BOOL)autosavesInPlace
// ------------------------------------------------------
{
    return NO;
}


// ------------------------------------------------------
/// enable Versions
+ (BOOL)preservesVersions
// ------------------------------------------------------
{
    return NO;
}


// ------------------------------------------------------
/// initialize instance
- (instancetype)init
// ------------------------------------------------------
{
    self = [super init];
    if (self) {
        [self setHasUndoManager:YES];
        
        _encoding = [[NSUserDefaults standardUserDefaults] integerForKey:CEDefaultEncodingInNewKey];
        _lineEnding = [[NSUserDefaults standardUserDefaults] integerForKey:CEDefaultLineEndCharCodeKey];
        _selection = [[CETextSelection alloc] initWithDocument:self];
        _writable = YES;
        _shouldSaveXattr = YES;
        
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(documentDidFinishOpen:)
                                                     name:CEDocumentDidFinishOpenNotification object:nil];
        
        // アプリケーションがアクティブになったタイミングで外部プロセスによって変更保存されていた場合の通知を行なう
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(showUpdatedByExternalProcessAlert)
                                                     name:NSApplicationDidBecomeActiveNotification object:nil];
    }
    return self;
}


// ------------------------------------------------------
/// initialize instance with existing file
- (instancetype)initWithContentsOfURL:(NSURL *)url ofType:(NSString *)typeName error:(NSError *__autoreleasing *)outError
// ------------------------------------------------------
{
    self = [super initWithContentsOfURL:url ofType:typeName error:outError];
    if (self) {
        // set sender of external editor protocol (ODB Editor Suite)
        _ODBEventSender = [[CEODBEventSender alloc] init];
        
        // check writability
        NSNumber *isWritable = nil;
        [url getResourceValue:&isWritable forKey:NSURLIsWritableKey error:nil];
        _writable = [isWritable boolValue];
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
    [self setWindowController:[[CEWindowController alloc] initWithWindowNibName:@"DocumentWindow"]];
    [self addWindowController:[self windowController]];
}


// ------------------------------------------------------
/// ファイルを読み込み、成功したかどうかを返す
- (BOOL)readFromURL:(NSURL *)url ofType:(NSString *)typeName error:(NSError **)outError
// ------------------------------------------------------
{
    // set encoding to read file
    // -> The value is either user setting or selection of open panel.
    NSStringEncoding encoding = [[CEDocumentController sharedDocumentController] accessorySelectedEncoding];
    
    return [self readFromURL:url encoding:encoding];
}


// ------------------------------------------------------
/// セーブ時の状態に戻す
- (BOOL)revertToContentsOfURL:(NSURL *)url ofType:(NSString *)typeName error:(NSError **)outError
// ------------------------------------------------------
{
    // 認証が必要な時に重なって表示されるのを避けるため、まず復帰確認シートを片づける
    //（外部プロセスによる変更通知アラートシートはそのままに）
    if (![self isRevertingForExternalFileUpdate]) {
        [[[self windowForSheet] attachedSheet] orderOut:self];
    }
    
    BOOL success = [self readFromURL:url encoding:CEAutoDetectEncoding];
    
    if (success) {
        [self setStringToEditor];
    }
    return success;
}


// ------------------------------------------------------
/// 保存用のデータを生成
- (NSData *)dataOfType:(NSString *)typeName error:(NSError **)outError
// ------------------------------------------------------
{
    // エンコーディングを見て、半角円マークを変換しておく
    NSString *string = [self convertCharacterString:[self stringForSave] encoding:[self encoding]];
    
    // stringから保存用のdataを得る
    NSData *data = [string dataUsingEncoding:[self encoding] allowLossyConversion:YES];
    
    // 必要であれば UTF-8 BOM 追加 (2008-12-13)
    if ([[NSUserDefaults standardUserDefaults] boolForKey:CEDefaultSaveUTF8BOMKey] &&
        ([self encoding] == NSUTF8StringEncoding))
    {
        NSMutableData *mutableData = [NSMutableData dataWithBytes:UTF8_BOM length:3];
        [mutableData appendData:data];
        data = [NSData dataWithData:mutableData];
    }
    
    return data;
}


// ------------------------------------------------------
/// ファイルの保存(保存処理で包括的に呼ばれる)
- (BOOL)writeSafelyToURL:(NSURL *)url ofType:(NSString *)typeName forSaveOperation:(NSSaveOperationType)saveOperation error:(NSError **)outError
// ------------------------------------------------------
{
    // break undo grouping before and after saving
    [[[self editor] focusedTextView] breakUndoCoalescing];
    
    id token = [self changeCountTokenForSaveOperation:saveOperation];
    
    // 新規書類を最初に保存する場合のフラグをセット
    BOOL isFirstSave = (![self fileURL] || (saveOperation == NSSaveAsOperation));
    
    // 保存処理実行
    BOOL success = [self forceWriteToURL:url ofType:typeName forSaveOperation:saveOperation];

    if (success) {
        // 新規保存時、カラーリングのために拡張子を保持
        if (isFirstSave) {
            [self setSyntaxStyleWithFileName:[url lastPathComponent] coloring:YES];
        }

        // 保持しているファイル情報／表示する文書情報を更新
        [self getFileAttributes];
        
        // 外部エディタプロトコル(ODB Editor Suite)のファイル更新通知送信
        [[self ODBEventSender] sendModifiedEventWithURL:url operation:saveOperation];
        
        // changeCountを更新
        [self updateChangeCountWithToken:token forSaveOperation:saveOperation];
    }

    return success;
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
- (BOOL)prepareSavePanel:(NSSavePanel *)savePanel
// ------------------------------------------------------
{
    // reset file types, otherwise:
    //   - alert dialog will be displayed if user inputs another extension.
    //   - cannot save without extension.
    [savePanel setAllowedFileTypes:nil];
    
    // disable hide extension checkbox
    [savePanel setExtensionHidden:NO];
    [savePanel setCanSelectHiddenExtension:NO];
    
    return [super prepareSavePanel:savePanel];
}


// ------------------------------------------------------
/// セーブパネルを表示
- (void)runModalSavePanelForSaveOperation:(NSSaveOperationType)saveOperation delegate:(id)delegate
                          didSaveSelector:(SEL)didSaveSelector contextInfo:(void *)contextInfo
// ------------------------------------------------------
{
    [super runModalSavePanelForSaveOperation:saveOperation delegate:delegate
                             didSaveSelector:didSaveSelector contextInfo:contextInfo];
    
    // 以下、拡張子を付与もしくは保持してるように見せつつも NSSavePanel には拡張子ではないと判断させるための小細工
    
    // find file name field
    NSSavePanel *savePanel = (NSSavePanel *)[[self windowForSheet] attachedSheet];
    NSText *text;
    for (id view in [[savePanel contentView] subviews]) {
        if ([view isKindOfClass:[NSTextField class]]) {
            text = [savePanel fieldEditor:NO forObject:view];
            break;
        }
    }
    
    if (!text) { return; }
    
    NSString *fileName = [self displayName];
    
    // 新規保存の場合は現在のシンタックスに対応したものを追加する
    if (![self fileURL]) {
        NSString *styleName = [[self editor] syntaxStyleName];
        NSArray *extensions = [[CESyntaxManager sharedManager] extensionsForStyleName:styleName];
        
        if ([extensions count] > 0) {
            fileName = [fileName stringByAppendingPathExtension:[extensions firstObject]];
        }
    }
    
    // あたらめてファイル名をセットし、拡張子をのぞいた部分を選択状態にする
    [text setString:fileName];
    [text setSelectedRange:NSMakeRange(0, [[fileName stringByDeletingPathExtension] length])];
}


// ------------------------------------------------------
/// ドキュメントが閉じられる前に保存のためのダイアログの表示などを行う
- (void)canCloseDocumentWithDelegate:(id)delegate shouldCloseSelector:(SEL)shouldCloseSelector contextInfo:(void *)contextInfo
// ------------------------------------------------------
{
    // This method is based on the following page (2005-07-08)
    // http://www.cocoadev.com/index.pl?ReplaceSaveChangesSheet

    // Finder のロックが解除できず、かつダーティーフラグがたっているときは相応のダイアログを出す
    if ([self isDocumentEdited] &&
        ![self canUnlockFileAtURL:[self fileURL] isLocked:nil lockAgain:YES])
    {
        NSAlert *alert = [[NSAlert alloc] init];
        [alert setMessageText:NSLocalizedString(@"Finder's lock is On.", nil)];
        [alert setInformativeText:NSLocalizedString(@"Finder's lock could not be released. So, you can not save your changes on this file, but you will be able to save a copy somewhere else.\n\nDo you want to close?", nil)];
        [alert addButtonWithTitle:NSLocalizedString(@"Cancel", nil)];
        [alert addButtonWithTitle:NSLocalizedString(@"Don't Save, and Close", nil)];

        NSButton *dontSaveButton = [alert buttons][1];
        [dontSaveButton setKeyEquivalent:@"d"];
        [dontSaveButton setKeyEquivalentModifierMask:NSCommandKeyMask];
        
        NSDictionary *contextInfoDict = @{@"delegate": delegate,
                                         @"shouldCloseSelector": [NSValue valueWithPointer:shouldCloseSelector],
                                         @"contextInfo": [NSValue valueWithPointer:contextInfo]};
        
        [alert beginSheetModalForWindow:[self windowForSheet]
                          modalDelegate:self
                         didEndSelector:@selector(alertForNotWritableDocCloseDidEnd:returnCode:contextInfo:)
                            contextInfo:(__bridge_retained void *)(contextInfoDict)];
    } else {
        // Disable save dialog if content is empty and not saved
        if (![self fileURL] && [[[self editor] string] length] == 0) {
            [self updateChangeCount:NSChangeCleared];
        }
        
        [super canCloseDocumentWithDelegate:delegate shouldCloseSelector:shouldCloseSelector contextInfo:contextInfo];
    }
}


// ------------------------------------------------------
/// ドキュメントを閉じる
- (void)close
// ------------------------------------------------------
{
    // 外部エディタプロトコル(ODB Editor Suite)のファイルクローズを送信
    [[self ODBEventSender] sendCloseEventWithURL:[self fileURL]];
    
    [super close];
}


// ------------------------------------------------------
/// プリントパネルを含むプリント用設定を生成して返す
- (NSPrintOperation *)printOperationWithSettings:(NSDictionary *)printSettings error:(NSError *__autoreleasing *)outError
// ------------------------------------------------------
{
    if (![self printPanelAccessoryController]) {
        [self setPrintPanelAccessoryController:[[CEPrintPanelAccessoryController alloc] init]];
    }
    CEPrintPanelAccessoryController *accessoryController = [self printPanelAccessoryController];
    
    // プリントビュー生成
    CEPrintView *printView = [[CEPrintView alloc] init];
    [printView setString:[[self editor] string]];
    [printView setTheme:[[self editor] theme]];
    [printView setDocumentName:[self displayName]];
    [printView setFilePath:[[self fileURL] path]];
    [printView setSyntaxName:[[self editor] syntaxStyleName]];
    [printView setPrintPanelAccessoryController:[self printPanelAccessoryController]];
    [printView setDocumentShowsInvisibles:[[self editor] showsInvisibles]];
    [printView setDocumentShowsLineNum:[[self editor] showsLineNum]];
    [printView setLineSpacing:[[[self editor] focusedTextView] lineSpacing]];
    
    // プリントに使用するフォント
    NSFont *font;
    if ([[NSUserDefaults standardUserDefaults] integerForKey:CEDefaultSetPrintFontKey] == 1) { // == プリンタ専用フォントで印字
        font = [NSFont fontWithName:[[NSUserDefaults standardUserDefaults] stringForKey:CEDefaultPrintFontNameKey]
                               size:(CGFloat)[[NSUserDefaults standardUserDefaults] doubleForKey:CEDefaultPrintFontSizeKey]];
    } else {
        font = [[self editor] font];
    }
    [printView setFont:font];
    
    // PrintInfo 設定
    NSPrintInfo *printInfo = [self printInfo];
    [printInfo setHorizontalPagination:NSFitPagination];
    [printInfo setHorizontallyCentered:NO];
    [printInfo setVerticallyCentered:NO];
    [printInfo setLeftMargin:kPrintTextHorizontalMargin];
    [printInfo setRightMargin:kPrintTextHorizontalMargin];
    [printInfo setTopMargin:kPrintHFVerticalMargin];
    [printInfo setBottomMargin:kPrintHFVerticalMargin];
    
    // プリントオペレーション生成、設定、プリント実行
    NSPrintOperation *printOperation = [NSPrintOperation printOperationWithView:printView printInfo:printInfo];
    [printOperation setJobTitle:[self displayName]];
    [printOperation setShowsProgressPanel:YES];
    [[printOperation printPanel] addAccessoryController:accessoryController];
    
    return printOperation;
}



#pragma mark Protocol

//=======================================================
// NSMenuValidation Protocol
//=======================================================

// ------------------------------------------------------
/// メニュー項目の有効・無効を制御
- (BOOL)validateMenuItem:(NSMenuItem *)menuItem
// ------------------------------------------------------
{
    NSInteger state = NSOffState;
    NSString *name;
    
    if ([menuItem action] == @selector(saveDocument:)) {
        // 書き込み不可の時は、アラートが表示され「OK」されるまで保存メニューを無効化する
        return ([self isWritable] || [self didAlertNotWritable]);
    } else if ([menuItem action] == @selector(changeEncoding:)) {
        state = ([menuItem tag] == [self encoding]) ? NSOnState : NSOffState;
    } else if (([menuItem action] == @selector(changeLineEndingToLF:)) ||
               ([menuItem action] == @selector(changeLineEndingToCR:)) ||
               ([menuItem action] == @selector(changeLineEndingToCRLF:)) ||
               ([menuItem action] == @selector(changeLineEnding:)))
    {
        state = ([menuItem tag] == [self lineEnding]) ? NSOnState : NSOffState;
    } else if ([menuItem action] == @selector(changeTheme:)) {
        name = [[[self editor] theme] name];
        if (name && [[menuItem title] isEqualToString:name]) {
            state = NSOnState;
        }
    } else if ([menuItem action] == @selector(changeSyntaxStyle:)) {
        name = [[self editor] syntaxStyleName];
        if (name && [[menuItem title] isEqualToString:name]) {
            state = NSOnState;
        }
    } else if ([menuItem action] == @selector(recolorAll:)) {
        name = [[self editor] syntaxStyleName];
        if (name && [name isEqualToString:NSLocalizedString(@"None", @"")]) {
            return NO;
        }
    }
    [menuItem setState:state];
    
    return [super validateMenuItem:menuItem];
}


//=======================================================
// NSToolbarItemValidation Protocol
//=======================================================

// ------------------------------------------------------
/// ツールバー項目の有効・無効を制御
-(BOOL)validateToolbarItem:(NSToolbarItem *)item
// ------------------------------------------------------
{
    if ([item action] == @selector(recolorAll:)) {
        NSString *name = [[self editor] syntaxStyleName];
        if ([name isEqualToString:NSLocalizedString(@"None", @"")]) {
            return NO;
        }
    }
    return YES;
}


//=======================================================
// NSFilePresenter Protocol
//=======================================================

// ------------------------------------------------------
/// file has been modified by an external process
- (void)presentedItemDidChange
// ------------------------------------------------------
{
    // check modification date of represented file
    __block NSDate *contentModificationDate;
    NSFileCoordinator *coordinator = [[NSFileCoordinator alloc] initWithFilePresenter:self];
    [coordinator coordinateReadingItemAtURL:[self fileURL] options:NSFileCoordinatorReadingWithoutChanges
                                      error:nil byAccessor:^(NSURL *newURL)
     {
         [newURL getResourceValue:&contentModificationDate forKey:NSURLContentModificationDateKey error:nil];
     }];
    
    // ignore if contents wasn't changed.
    if ([contentModificationDate isEqualToDate:[self fileModificationDate]]) { return; }
    
    // notify about external file update
    [self setNeedsShowUpdateAlertWithBecomeKey:YES];
    if ([NSApp isActive]) {
        // display dialog
        __weak typeof(self) weakSelf = self;
        dispatch_async(dispatch_get_main_queue(), ^{
            [weakSelf showUpdatedByExternalProcessAlert];
        });
        
    } else if ([[NSUserDefaults standardUserDefaults] boolForKey:CEDefaultNotifyEditByAnotherKey]) {
        // let application icon in Dock jump
        [NSApp requestUserAttention:NSInformationalRequest];
    }
}



#pragma mark Public Methods

// ------------------------------------------------------
/// 改行コードを指定のものに置換したメイン textView の文字列を返す
- (NSString *)stringForSave
// ------------------------------------------------------
{
    return [[[self editor] string] stringByReplacingNewLineCharacersWith:[self lineEnding]];
}


// ------------------------------------------------------
/// transfer file content string to editor
- (void)setStringToEditor
// ------------------------------------------------------
{
    [self setSyntaxStyleWithFileName:[[self fileURL] lastPathComponent] coloring:NO];
    
    // standardize line endings to LF (File Open)
    // (Line endings replacemement by other text modifications are processed in the following methods.)
    //
    // # Methods Standardizing Line Endings on Text Editing
    //   - File Open: CEDocument > setStringToEditor
    //   - Script: CEEditorView > textView:shouldChangeTextInRange:replacementString:
    //   - Key Type: CEEditorView > textView:shouldChangeTextInRange:replacementString:
    //   - Paste: CETextView > readSelectionFromPasteboard:type:
    //   - Drop (from other documents/apps): CETextView > readSelectionFromPasteboard:type:
    //   - Drop (from the same document): CETextView > performDragOperation:
    //   - Replace on Find Penel: (OgreKit) OgreTextViewPlainAdapter > replaceCharactersInRange:withOGString:
    
    if ([self fileContentString]) {
        CENewLineType lineEnding = [[self fileContentString] detectNewLineType];
        if (lineEnding != CENewLineNone) {  // keep default if no line endings are found
            [self setLineEnding:lineEnding];
        }
        
        NSString *string = [[self fileContentString] stringByReplacingNewLineCharacersWith:CENewLineLF];
        
        [[self editor] setString:string];  // In this `setString:`, caret will be moved to the beginning.
        [self setFileContentString:nil];  // release
        
    } else {
        [[self editor] setString:@""];
    }
    
    // update line endings menu selection in toolbar
    [self applyLineEndingToView];
    
    // update encoding menu selection in toolbar, status bar and document inspector
    [self updateEncodingInToolbarAndInfo];
    
    // update syntax highlights and outline menu
    // -> Since a coloring indicator will be attached to the window if the file is large,
    //    insert delay in order to display the window at first.
    [[self editor] updateColoringAndOutlineMenuWithDelay];
    
    [[self windowController] updateIncompatibleCharsIfNeeded];
}


// ------------------------------------------------------
/// 設定されたエンコーディングの IANA Charset 名を返す
- (NSString *)currentIANACharSetName
// ------------------------------------------------------
{
    CFStringEncoding cfEncoding = CFStringConvertNSStringEncodingToEncoding([self encoding]);
    
    if (cfEncoding != kCFStringEncodingInvalidId) {
        return (NSString *)CFStringConvertEncodingToIANACharSetName(cfEncoding);
    }
    return nil;
}


// ------------------------------------------------------
/// 指定されたエンコードにコンバートできない文字列をリストアップし配列を返す
- (NSArray *)findCharsIncompatibleWithEncoding:(NSStringEncoding)encoding
// ------------------------------------------------------
{
    NSMutableArray *incompatibleChars = [NSMutableArray array];
    NSString *currentString = [self stringForSave];
    NSUInteger currentLength = [currentString length];
    NSData *data = [currentString dataUsingEncoding:encoding allowLossyConversion:YES];
    NSString *convertedString = [[NSString alloc] initWithData:data encoding:encoding];
    
    if (!convertedString || ([convertedString length] != currentLength)) { // 正しいリストが取得できない時
        return nil;
    }
    
    // 削除／変換される文字をリストアップ
    BOOL isInvalidYenEncoding = [CEUtils isInvalidYenEncoding:encoding];
    
    for (NSUInteger i = 0; i < currentLength; i++) {
        unichar currentUnichar = [currentString characterAtIndex:i];
        unichar convertedUnichar = [convertedString characterAtIndex:i];
        
        if (currentUnichar == convertedUnichar) { continue; }
        
        if (isInvalidYenEncoding && currentUnichar == kYenMark) {
            convertedUnichar = '\\';
        }
        
        NSString *currentChar = [NSString stringWithCharacters:&currentUnichar length:1];
        NSString *convertedChar = [NSString stringWithCharacters:&convertedUnichar length:1];
        
        NSUInteger lineNumber = 1;
        for (NSUInteger index = 0, lines = 0; index < currentLength; lines++) {
            if (index <= i) {
                lineNumber = lines + 1;
            } else {
                break;
            }
            index = NSMaxRange([currentString lineRangeForRange:NSMakeRange(index, 0)]);
        }
        
        [incompatibleChars addObject:@{CEIncompatibleLineNumberKey: @(lineNumber),
                                       CEIncompatibleRangeKey: [NSValue valueWithRange:NSMakeRange(i, 1)],
                                       CEIncompatibleCharKey: currentChar,
                                       CEIncompatibleConvertedCharKey: convertedChar}];
    }
    
    return [incompatibleChars copy];
}


// ------------------------------------------------------
/// 指定されたエンコーディングでファイルを再解釈する
- (BOOL)reinterpretWithEncoding:(NSStringEncoding)encoding
// ------------------------------------------------------
{
    if (encoding == NSNotFound || ![self fileURL]) { return NO; }
    
    // do nothing if given encoding is the same as current one
    if (encoding == [self encoding]) { return YES; }
    
    // reinterpret
    BOOL success = [self readFromURL:[self fileURL] encoding:encoding];
    
    if (success) {
        [self setStringToEditor];
        
        // clear dirty flag
        [[self undoManager] removeAllActions];
        [self updateChangeCount:NSChangeCleared];
        
        // update popup menu in the toolbar
        [[[self windowController] toolbarController] setSelectedEncoding:[self encoding]];
    }
    
    return success;
}


// ------------------------------------------------------
/// 新規エンコーディングをセット
- (BOOL)doSetEncoding:(NSStringEncoding)encoding updateDocument:(BOOL)updateDocument askLossy:(BOOL)askLossy lossy:(BOOL)lossy asActionName:(NSString *)actionName
// ------------------------------------------------------
{
    if (encoding == [self encoding]) {
        return YES;
    }
    
    BOOL shouldShowList = NO;
    
    if (updateDocument) {
        NSString *curString = [self stringForSave];
        BOOL allowsLossy = NO;

        if (askLossy) {
            if (![curString canBeConvertedToEncoding:encoding]) {
                NSString *encodingNameStr = [NSString localizedNameOfStringEncoding:encoding];
                NSAlert *alert = [[NSAlert alloc] init];
                [alert setMessageText:[NSString stringWithFormat:NSLocalizedString(@"The characters would have to be changed or deleted in saving as “%@”.", nil), encodingNameStr]];
                [alert setInformativeText:NSLocalizedString(@"Do you want to change encoding and show incompatible characters?", nil)];
                [alert addButtonWithTitle:NSLocalizedString(@"Cancel", nil)];
                [alert addButtonWithTitle:NSLocalizedString(@"Change Encoding", nil)];

                NSInteger returnCode = [alert runModal];
                if (returnCode == NSAlertFirstButtonReturn) { // == Cancel
                    return NO;
                }
                shouldShowList = YES;
                allowsLossy = YES;
            }
        } else {
            allowsLossy = lossy;
        }
        
        // register undo
        NSUndoManager *undoManager = [self undoManager];
        [[undoManager prepareWithInvocationTarget:self] redoSetEncoding:encoding updateDocument:updateDocument
                                                               askLossy:NO lossy:allowsLossy
                                                           asActionName:actionName];  // redo in undo
        if (shouldShowList) {
            [[undoManager prepareWithInvocationTarget:[self windowController]] showIncompatibleCharList];
        }
        [[undoManager prepareWithInvocationTarget:self] updateEncodingInToolbarAndInfo];
        [[undoManager prepareWithInvocationTarget:self] setEncoding:[self encoding]];  // エンコード値設定
        if (actionName) {
            [undoManager setActionName:actionName];
        }
    }
    
    [self setEncoding:encoding];
    [self updateEncodingInToolbarAndInfo];  // ツールバーのエンコーディングメニュー、ステータスバー、インスペクタを更新
    
    if (shouldShowList) {
        [[self windowController] showIncompatibleCharList];
    } else {
        [[self windowController] updateIncompatibleCharsIfNeeded];
    }
    
    return YES;
}


// ------------------------------------------------------
/// 改行コードを変更する
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
    [self applyLineEndingToView];
}


// ------------------------------------------------------
/// 新しいシンタックスカラーリングスタイルを適用
- (void)doSetSyntaxStyle:(NSString *)name
// ------------------------------------------------------
{
    if ([name length] == 0) { return; }
    
    [[self editor] setSyntaxStyleName:name recolorNow:YES];
    [[[self windowController] toolbarController] setSelectedSyntaxWithName:name];
}



#pragma mark Notifications

//=======================================================
// Notification  <- CEWindowController
//=======================================================

// ------------------------------------------------------
/// 書類オープン処理が完了した
- (void)documentDidFinishOpen:(NSNotification *)notification
// ------------------------------------------------------
{
    if ([notification object] == [self windowController]) {
        // 書き込み禁止アラートを表示
        [self showNotWritableAlert];
    }
}



#pragma mark Action Messages

// ------------------------------------------------------
/// 保存
- (IBAction)saveDocument:(id)sender
// ------------------------------------------------------
{
    if (![self acceptSaveDocumentWithIANACharSetName]) { return; }
    if (![self acceptSaveDocumentToConvertEncoding]) { return; }
    
    [super saveDocument:sender];
}


// ------------------------------------------------------
/// 別名で保存
- (IBAction)saveDocumentAs:(id)sender
// ------------------------------------------------------
{
    if (![self acceptSaveDocumentWithIANACharSetName]) { return; }
    if (![self acceptSaveDocumentToConvertEncoding]) { return; }
    
    [super saveDocumentAs:sender];
}


// ------------------------------------------------------
/// ドキュメントに新しい改行コードをセットする
- (IBAction)changeLineEndingToLF:(id)sender
// ------------------------------------------------------
{
    [self doSetLineEnding:CENewLineLF];
}


// ------------------------------------------------------
/// ドキュメントに新しい改行コードをセットする
- (IBAction)changeLineEndingToCR:(id)sender
// ------------------------------------------------------
{
    [self doSetLineEnding:CENewLineCR];
}


// ------------------------------------------------------
/// ドキュメントに新しい改行コードをセットする
- (IBAction)changeLineEndingToCRLF:(id)sender
// ------------------------------------------------------
{
    [self doSetLineEnding:CENewLineCRLF];
}


// ------------------------------------------------------
/// ドキュメントに新しい改行コードをセットする
- (IBAction)changeLineEnding:(id)sender
// ------------------------------------------------------
{
    [self doSetLineEnding:[sender tag]];
}


// ------------------------------------------------------
/// ドキュメントに新しいエンコーディングをセットする
- (IBAction)changeEncoding:(id)sender
// ------------------------------------------------------
{
    NSStringEncoding encoding = [sender tag];

    if ((encoding < 1) || (encoding == [self encoding])) {
        return;
    }
    NSInteger result;
    NSString *encodingName = [sender title];

    // 文字列がないまたは未保存の時は直ちに変換プロセスへ
    if (([[[self editor] string] length] < 1) || (![self fileURL])) {
        result = NSAlertFirstButtonReturn;
    } else {
        // 変換するか再解釈するかの選択ダイアログを表示
        NSAlert *alert = [[NSAlert alloc] init];
        [alert setMessageText:NSLocalizedString(@"File encoding", nil)];
        [alert setInformativeText:[NSString stringWithFormat:NSLocalizedString(@"Do you want to convert or reinterpret it using “%@”?", nil), encodingName]];
        [alert addButtonWithTitle:NSLocalizedString(@"Convert", nil)];
        [alert addButtonWithTitle:NSLocalizedString(@"Reinterpret", nil)];
        [alert addButtonWithTitle:NSLocalizedString(@"Cancel", nil)];

        result = [alert runModal];
    }
    
    if (result == NSAlertFirstButtonReturn) {  // = Convert 変換
        NSString *actionName = [NSString stringWithFormat:NSLocalizedString(@"Encoding to “%@”", nil),
                                [NSString localizedNameOfStringEncoding:encoding]];

        [self doSetEncoding:encoding updateDocument:YES askLossy:YES lossy:NO asActionName:actionName];

    } else if (result == NSAlertSecondButtonReturn) {  // = Reinterpret 再解釈
        if (![self fileURL]) { return; } // まだファイル保存されていない時（ファイルがない時）は、戻る
        if ([self isDocumentEdited]) {
            NSAlert *alert = [[NSAlert alloc] init];
            [alert setMessageText:[NSString stringWithFormat:NSLocalizedString(@"The file “%@” has unsaved changes.", nil), [[self fileURL] path]]];
             [alert setInformativeText:NSLocalizedString(@"Do you want to discard the changes and reset the file encodidng?", nil)];
             [alert addButtonWithTitle:NSLocalizedString(@"Cancel", nil)];
             [alert addButtonWithTitle:NSLocalizedString(@"Discard Changes", nil)];

            NSInteger secondResult = [alert runModal];
            if (secondResult != NSAlertSecondButtonReturn) { // != Discard Change
                // ツールバーから変更された場合のため、ツールバーアイテムの選択状態をリセット
                [[[self windowController] toolbarController] setSelectedEncoding:[self encoding]];
                return;
            }
        }
        
        BOOL success = [self reinterpretWithEncoding:encoding];
        
        if (!success) {
            NSAlert *alert = [[NSAlert alloc] init];
            [alert setMessageText:NSLocalizedString(@"Can not reinterpret", nil)];
            [alert setInformativeText:[NSString stringWithFormat:NSLocalizedString(@"The file “%@” could not be reinterpreted using the new encoding “%@”.", nil), [[self fileURL] path], encodingName]];
            [alert addButtonWithTitle:NSLocalizedString(@"Done", nil)];
            [alert setAlertStyle:NSCriticalAlertStyle];
            
            NSBeep();
            [alert runModal];
        }
    }
    // ツールバーから変更された場合のため、ツールバーアイテムの選択状態をリセット
    [[[self windowController] toolbarController] setSelectedEncoding:[self encoding]];
}


// ------------------------------------------------------
/// 新しいテーマを適用
- (IBAction)changeTheme:(id)sender
// ------------------------------------------------------
{
    NSString *name = [sender title];
    
    if ([name length] > 0) {
        [[self editor] setThemeWithName:name];
    }
}


// ------------------------------------------------------
/// 新しいシンタックスカラーリングスタイルを適用
- (IBAction)changeSyntaxStyle:(id)sender
// ------------------------------------------------------
{
    NSString *name = [sender title];

    if ([name length] > 0) {
        [self doSetSyntaxStyle:name];
    }
}


// ------------------------------------------------------
/// IANA文字コード名を挿入する
- (IBAction)insertIANACharSetName:(id)sender
// ------------------------------------------------------
{
    NSString *string = [self currentIANACharSetName];

    if (string) {
        [[[self editor] focusedTextView] insertText:string];
    }
}


// ------------------------------------------------------
/// IANA文字コード名を挿入する
- (IBAction)insertIANACharSetNameWithCharset:(id)sender
// ------------------------------------------------------
{
    NSString *string = [self currentIANACharSetName];

    if (string) {
        [[[self editor] focusedTextView] insertText:[NSString stringWithFormat:@"charset=\"%@\"", string]];
    }
}


// ------------------------------------------------------
/// IANA文字コード名を挿入する
- (IBAction)insertIANACharSetNameWithEncoding:(id)sender
// ------------------------------------------------------
{
    NSString *string = [self currentIANACharSetName];

    if (string) {
        [[[self editor] focusedTextView] insertText:[NSString stringWithFormat:@"encoding=\"%@\"", string]];
    }
}



#pragma mark Private Methods

// ------------------------------------------------------
/// ファイル情報辞書を更新
- (void)getFileAttributes
// ------------------------------------------------------
{
    __block NSDictionary *attributes;
    NSFileCoordinator *coordinator = [[NSFileCoordinator alloc] initWithFilePresenter:self];
    [coordinator coordinateReadingItemAtURL:[self fileURL] options:NSFileCoordinatorReadingWithoutChanges
                                      error:nil
                                 byAccessor:^(NSURL *newURL)
     {
         attributes = [[NSFileManager defaultManager] attributesOfItemAtPath:[newURL path] error:nil];
     }];
    
    if (attributes) {
        [self setFileAttributes:attributes];
        [[self windowController] updateFileInfo];
    }
}


// ------------------------------------------------------
/// editor を通じて syntax インスタンスをセット
- (void)setSyntaxStyleWithFileName:(NSString *)fileName coloring:(BOOL)doColoring
// ------------------------------------------------------
{
    if (![[NSUserDefaults standardUserDefaults] boolForKey:CEDefaultEnableSyntaxHighlightKey]) { return; }
    
    NSString *styleName = [[CESyntaxManager sharedManager] styleNameFromFileName:fileName];
    
    [[self editor] setSyntaxStyleName:styleName recolorNow:doColoring];
    
    // ツールバーのカラーリングポップアップの表示を更新、再カラーリング
    [[[self windowController] toolbarController] setSelectedSyntaxWithName:styleName];
}


// ------------------------------------------------------
/// ツールバーのエンコーディングメニュー、ステータスバー、インスペクタを更新
- (void)updateEncodingInToolbarAndInfo
// ------------------------------------------------------
{
    // ツールバーのエンコーディングメニューを更新
    [[[self windowController] toolbarController] setSelectedEncoding:[self encoding]];
    // ステータスバー、インスペクタを更新
    [[self windowController] updateModeInfoIfNeeded];
}


// ------------------------------------------------------
/// 改行コードをエディタに反映
- (void)applyLineEndingToView
// ------------------------------------------------------
{
    [[self windowController] updateModeInfoIfNeeded];
    [[self windowController] updateEditorInfoIfNeeded];
    [[[self windowController] toolbarController] setSelectedLineEnding:[self lineEnding]];
}


// ------------------------------------------------------
// authopen コマンドを使って読み込む
- (NSData *)forceReadDataFromURL:(NSURL *)url
// ------------------------------------------------------
{
    NSString *convertedPath = @([[url path] UTF8String]);
    NSTask *task = [[NSTask alloc] init];
    
    [task setLaunchPath:@"/usr/libexec/authopen"];
    [task setArguments:@[convertedPath]];
    [task setStandardOutput:[NSPipe pipe]];
    
    [task launch];
    NSData *data = [NSData dataWithData:[[[task standardOutput] fileHandleForReading] readDataToEndOfFile]];
    [task waitUntilExit];
    
    int status = [task terminationStatus];
    
    return (status == 0) ? data : nil;
}


// ------------------------------------------------------
/// ファイルを読み込み、成功したかどうかを返す
- (BOOL)readFromURL:(NSURL *)url encoding:(NSStringEncoding)encoding
// ------------------------------------------------------
{
    // authopen コマンドを使って読み込む
    NSData *data = [self forceReadDataFromURL:url];
    
    if (!data) {
        // オープンダイアログでのエラーアラートは CEDocumentController > openDocument: で表示する
        // アプリアイコンへのファイルドロップでのエラーアラートは NSDocumentController (NSApp ?) 内部で表示される
        // 復帰時は NSDocument 内部で表示
        return NO;
    }
    
    // try reading the `com.apple.TextEncoding` extended attribute
    NSStringEncoding xattrEncoding = [url getAppleTextEncoding];
    
    // don't save xattr if file doesn't have it in order to avoid saving wrong encoding (2015-01 by 1024jp).
    [self setShouldSaveXattr:(xattrEncoding != NSNotFound)];
    
    return [self readStringFromData:data encoding:encoding xattrEncoding:xattrEncoding];
}


//------------------------------------------------------
/// データから指定エンコードで文字列を読み込み、成功したかどうかを返す
- (BOOL)readStringFromData:(NSData *)data encoding:(NSStringEncoding)encoding xattrEncoding:(NSStringEncoding)xattrEncoding
//------------------------------------------------------
{
    NSString *string;
    NSStringEncoding usedEncoding;
    
    if (encoding != CEAutoDetectEncoding) {  // interpret with specific encoding
        usedEncoding = encoding;
        string = ([data length] == 0) ? @"" : [[NSString alloc] initWithData:data encoding:encoding];
        
    } else {  // Auto-Detection
        // try interpreting with xattr encoding
        if (xattrEncoding != NSNotFound) {
            // just trust xattr encoding if content is empty
            string = ([data length] == 0) ? @"" : [[NSString alloc] initWithData:data encoding:xattrEncoding];
            
            if (string) {
                usedEncoding = xattrEncoding;
            }
        }
        
        if (!string) {
            // detect encoding from data
            string = [self stringFromData:data usedEncoding:&usedEncoding];
        }
    }
    
    if (string) {
        [self setFileContentString:string];  // _fileContentString will be released in `setStringToEditor`
        [self doSetEncoding:usedEncoding updateDocument:NO askLossy:NO lossy:NO asActionName:nil];
        
        // 保持しているファイル情報を更新
        [self getFileAttributes];
        return YES;
    }
    
    return NO;
}


//------------------------------------------------------
/// データからエンコードを推測して文字列を得る
- (NSString *)stringFromData:(NSData *)data usedEncoding:(NSStringEncoding *)usedEncoding
//------------------------------------------------------
{
    BOOL shouldSkipISO2022JP = NO;
    BOOL shouldSkipUTF8 = NO;
    BOOL shouldSkipUTF16 = NO;
    
    if ([data length] > 0) {
        // ISO 2022-JP / UTF-8 / UTF-16の判定は、「藤棚工房別棟 −徒然−」の
        // 「Cocoaで文字エンコーディングの自動判別プログラムを書いてみました」で公開されている
        // FJDDetectEncoding を参考にさせていただきました (2006-09-30)
        // http://blogs.dion.ne.jp/fujidana/archives/4169016.html
        
        // BOM 付き UTF-8 判定
        if (memchr([data bytes], *UTF8_BOM, 3) != NULL) {
            shouldSkipUTF8 = YES;
            NSString *string = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
            if (string) {
                *usedEncoding = NSUTF8StringEncoding;
                return string;
            }
            // UTF-16 判定
        } else if ((memchr([data bytes], 0xfffe, 2) != NULL) ||
                   (memchr([data bytes], 0xfeff, 2) != NULL))
        {
            shouldSkipUTF16 = YES;
            NSString *string = [[NSString alloc] initWithData:data encoding:NSUnicodeStringEncoding];
            if (string) {
                *usedEncoding = NSUnicodeStringEncoding;
                return string;
            }
            
            // ISO 2022-JP 判定
        } else if (memchr([data bytes], 0x1b, [data length]) != NULL) {
            shouldSkipISO2022JP = YES;
            NSString *string = [[NSString alloc] initWithData:data encoding:NSISO2022JPStringEncoding];
            if (string) {
                *usedEncoding = NSISO2022JPStringEncoding;
                return string;
            }
        }
    }
    
    // try encodings in order from the top of the encoding list
    NSArray *encodings = [[NSUserDefaults standardUserDefaults] arrayForKey:CEDefaultEncodingListKey];
    
    for (NSNumber *encodingNumber in encodings) {
        NSStringEncoding encoding = CFStringConvertEncodingToNSStringEncoding([encodingNumber unsignedIntegerValue]);
        
        if (((encoding == NSISO2022JPStringEncoding) && shouldSkipISO2022JP) ||
            ((encoding == NSUTF8StringEncoding) && shouldSkipUTF8) ||
            ((encoding == NSUnicodeStringEncoding) && shouldSkipUTF16))
        {
            continue;
        }
        
        NSString *string = [[NSString alloc] initWithData:data encoding:encoding];
        
        if (string) {
            // "charset=" や "encoding=" を読んでみて適正なエンコーディングが得られたら、そちらを優先
            NSStringEncoding scannedEncoding = [self scanCharsetOrEncodingFromString:string];
            
            if (scannedEncoding != NSNotFound && scannedEncoding != encoding) {
                NSString *tmpString = [[NSString alloc] initWithData:data encoding:scannedEncoding];
                if (tmpString) {
                    *usedEncoding = scannedEncoding;
                    return tmpString;
                }
            }
            
            *usedEncoding = encoding;
            return string;
        }
    }
    
    *usedEncoding = NSNotFound;
    return nil;
}


// ------------------------------------------------------
/// "charset=" "encoding="タグからエンコーディング定義を読み取る
- (NSStringEncoding)scanCharsetOrEncodingFromString:(NSString *)string
// ------------------------------------------------------
{
    // This method is based on Smultron's SMLTextPerformer.m by Peter Borg. (2005-08-10)
    // Smultron 2 was distributed on <http://smultron.sourceforge.net> under the terms of the BSD license.
    // Copyright (c) 2004-2006 Peter Borg
    
    NSStringEncoding encoding = NSNotFound;
    if (![[NSUserDefaults standardUserDefaults] boolForKey:CEDefaultReferToEncodingTagKey] || ([string length] < 9)) {
        return encoding; // 参照しない設定になっているか、含まれている余地が無ければ中断
    }
    
    NSString *stringToScan = ([string length] > kMaxEncodingScanLength) ? [string substringToIndex:kMaxEncodingScanLength] : string;
    NSScanner *scanner = [NSScanner scannerWithString:stringToScan];  // 文書前方のみスキャンする
    NSCharacterSet *stopSet = [NSCharacterSet characterSetWithCharactersInString:@"\"\' </>\n\r"];
    NSString *scannedStr = nil;

    [scanner setCharactersToBeSkipped:[NSCharacterSet characterSetWithCharactersInString:@"\"\' "]];
    // "charset="を探す
    while (![scanner isAtEnd]) {
        [scanner scanUpToString:@"charset=" intoString:nil];
        if ([scanner scanString:@"charset=" intoString:nil]) {
            if ([scanner scanUpToCharactersFromSet:stopSet intoString:&scannedStr]) {
                break;
            }
        }
    }
    // "charset="が見つからなければ、"encoding="を探す
    if (scannedStr == nil) {
        [scanner setScanLocation:0];
        while (![scanner isAtEnd]) {
            [scanner scanUpToString:@"encoding=" intoString:nil];
            if ([scanner scanString:@"encoding=" intoString:nil]) {
                if ([scanner scanUpToCharactersFromSet:stopSet intoString:&scannedStr]) {
                    break;
                }
            }
        }
    }
    // 見つからなければ、"@charset"を探す
    if (scannedStr == nil) {
        [scanner setScanLocation:0];
        while (![scanner isAtEnd]) {
            [scanner scanUpToString:@"@charset" intoString:nil];
            if ([scanner scanString:@"@charset" intoString:nil]) {
                if ([scanner scanUpToCharactersFromSet:stopSet intoString:&scannedStr]) {
                    break;
                }
            }
        }
    }
    
    // 見つかったら NSStringEncoding に変換して返す
    if (scannedStr) {
        CFStringEncoding cfEncoding = kCFStringEncodingInvalidId;
        // "Shift_JIS"だったら、kCFStringEncodingShiftJIS と kCFStringEncodingShiftJIS_X0213 の
        // 優先順位の高いものを取得する
        if ([[scannedStr uppercaseString] isEqualToString:@"SHIFT_JIS"]) {
            // （scannedStr をそのまま CFStringConvertIANACharSetNameToEncoding() で変換すると、大文字小文字を問わず
            // 「日本語（Shift JIS）」になってしまうため。IANA では大文字小文字を区別しないとしているのでこれはいいのだが、
            // CFStringConvertEncodingToIANACharSetName() では kCFStringEncodingShiftJIS と
            // kCFStringEncodingShiftJIS_X0213 がそれぞれ「SHIFT_JIS」「shift_JIS」と変換されるため、可逆性を持たせる
            // ための処理）
            NSArray *encodings = [[NSUserDefaults standardUserDefaults] arrayForKey:CEDefaultEncodingListKey];

            for (NSNumber *encodingNumber in encodings) {
                CFStringEncoding tmpCFEncoding = [encodingNumber unsignedLongValue];
                if ((tmpCFEncoding == kCFStringEncodingShiftJIS) ||
                    (tmpCFEncoding == kCFStringEncodingShiftJIS_X0213))
                {
                    cfEncoding = tmpCFEncoding;
                    break;
                }
            }
        } else {
            // "Shift_JIS" 以外はそのまま変換する
            cfEncoding = CFStringConvertIANACharSetNameToEncoding((CFStringRef)scannedStr);
        }
        if (cfEncoding != kCFStringEncodingInvalidId) {
            encoding = CFStringConvertEncodingToNSStringEncoding(cfEncoding);
        }
    }
    
    return encoding;
}


// ------------------------------------------------------
/// IANA文字コード名を読み、設定されたエンコーディングと矛盾があれば警告する
- (BOOL)acceptSaveDocumentWithIANACharSetName
// ------------------------------------------------------
{
    NSStringEncoding IANACharSetEncoding = [self scanCharsetOrEncodingFromString:[self stringForSave]];
    NSStringEncoding ShiftJIS = CFStringConvertEncodingToNSStringEncoding(kCFStringEncodingShiftJIS);
    NSStringEncoding X0213 = CFStringConvertEncodingToNSStringEncoding(kCFStringEncodingShiftJIS_X0213);

    if ((IANACharSetEncoding != NSNotFound) && (IANACharSetEncoding != [self encoding]) &&
        (!(((IANACharSetEncoding == ShiftJIS) || (IANACharSetEncoding == X0213)) &&
           (([self encoding] == ShiftJIS) || ([self encoding] == X0213))))) {
            // （Shift-JIS の時は要注意 = scanCharsetOrEncodingFromString: を参照）

        NSString *IANANameStr = [NSString localizedNameOfStringEncoding:IANACharSetEncoding];
        NSString *encodingNameStr = [NSString localizedNameOfStringEncoding:[self encoding]];
        NSAlert *alert = [[NSAlert alloc] init];
        [alert setMessageText:[NSString stringWithFormat:NSLocalizedString(@"The encoding is “%@”, but the IANA charset name in text is “%@”.", nil), encodingNameStr, IANANameStr]];
        [alert setInformativeText:NSLocalizedString(@"Do you want to continue processing?", nil)];
        [alert addButtonWithTitle:NSLocalizedString(@"Cancel", nil)];
        [alert addButtonWithTitle:NSLocalizedString(@"Continue Saving", nil)];

        NSInteger result = [alert runModal];
        if (result != NSAlertSecondButtonReturn) { // == Cancel
            return NO;
        }
    }
    return YES;
}


// ------------------------------------------------------
/// authopenを使ってファイルを書き込む
- (BOOL)forceWriteToURL:(NSURL *)url ofType:(NSString *)typeName forSaveOperation:(NSSaveOperationType)saveOperation
// ------------------------------------------------------
{
    BOOL success = NO;
    NSData *data = [self dataOfType:typeName error:nil];
    
    if (!data) { return NO; }
    
    // 設定すべきfileAttributesを準備しておく
    NSDictionary *attributes = [self fileAttributesToWriteToURL:url
                                                         ofType:typeName
                                               forSaveOperation:saveOperation
                                            originalContentsURL:nil
                                                          error:nil];
    
    // ユーザがオーナーでないファイルに Finder Lock がかかっていたら編集／保存できない
    BOOL isFinderLockOn = NO;
    if (![self canUnlockFileAtURL:url isLocked:&isFinderLockOn lockAgain:NO]) {
        NSAlert *alert = [[NSAlert alloc] init];
        [alert setMessageText:NSLocalizedString(@"Finder's lock could not be released.", nil)];
        [alert setInformativeText:NSLocalizedString(@"You can use “Save As” to save a copy.", nil)];
        [alert setAlertStyle:NSCriticalAlertStyle];
        [alert runModal];
        return NO;
    }
    
    // "authopen" コマンドを使って保存
    NSString *convertedPath = @([[url path] UTF8String]);
    NSTask *task = [[NSTask alloc] init];

    [task setLaunchPath:@"/usr/libexec/authopen"];
    [task setArguments:@[@"-c", @"-w", convertedPath]];
    [task setStandardInput:[NSPipe pipe]];

    [task launch];
    [[[task standardInput] fileHandleForWriting] writeData:data];
    [[[task standardInput] fileHandleForWriting] closeFile];
    [task waitUntilExit];

    int status = [task terminationStatus];
    success = (status == 0);
    
    if (success) {
        // クリエータなどを設定
        [[NSFileManager defaultManager] setAttributes:attributes ofItemAtPath:[url path] error:nil];
        
        // ファイル拡張属性 (com.apple.TextEncoding) にエンコーディングを保存
        if ([self shouldSaveXattr]) {
            [url setAppleTextEncoding:[self encoding]];
        }
    }
    
    // Finder Lock がかかってたなら、再びかける
    if (isFinderLockOn) {
        BOOL lockSuccess = [[NSFileManager defaultManager] setAttributes:@{NSFileImmutable:@YES} ofItemAtPath:[url path] error:nil];
        success = (success && lockSuccess);
    }
    
    return success;
}


// ------------------------------------------------------
/// ファイル保存前のエンコーディング変換チェック、ユーザに承認を求める
- (BOOL)acceptSaveDocumentToConvertEncoding
// ------------------------------------------------------
{
    // エンコーディングを見て、半角円マークを変換しておく
    NSString *curString = [self convertCharacterString:[self stringForSave] encoding:[self encoding]];
    
    if (![curString canBeConvertedToEncoding:[self encoding]]) {
        NSString *encodingName = [NSString localizedNameOfStringEncoding:[self encoding]];
        NSAlert *alert = [[NSAlert alloc] init];
        [alert setMessageText:[NSString stringWithFormat:NSLocalizedString(@"The characters would have to be changed or deleted in saving as “%@”.", nil), encodingName]];
        [alert setInformativeText:NSLocalizedString(@"Do you want to continue processing?", nil)];
        [alert addButtonWithTitle:NSLocalizedString(@"Show Incompatible Chars", nil)];
        [alert addButtonWithTitle:NSLocalizedString(@"Save Available Strings", nil)];
        [alert addButtonWithTitle:NSLocalizedString(@"Cancel", nil)];
        
        NSInteger result = [alert runModal];
        if (result != NSAlertSecondButtonReturn) { // != Save
            if (result == NSAlertFirstButtonReturn) { // == show incompatible chars
                [[self windowController] showIncompatibleCharList];
            }
            return NO;
        }
    }
    return YES;
}


// ------------------------------------------------------
/// 半角円マークを使えないエンコードの時はバックスラッシュに変換した文字列を返す
- (NSString *)convertCharacterString:(NSString *)string encoding:(NSStringEncoding)encoding
// ------------------------------------------------------
{
    if (([string length] > 0) && [CEUtils isInvalidYenEncoding:encoding]) {
        return [string stringByReplacingOccurrencesOfString:[NSString stringWithCharacters:&kYenMark length:1]
                                                 withString:@"\\"];
    }
    return string;
}


// ------------------------------------------------------
/// Finder のロックが解除出来るか試す。lockAgain が真なら再びロックする。
- (BOOL)canUnlockFileAtURL:(NSURL *)url isLocked:(BOOL *)isLocked lockAgain:(BOOL)lockAgain
// ------------------------------------------------------
{
    NSFileManager *fileManager = [NSFileManager defaultManager];
    BOOL isFinderLocked = [[fileManager attributesOfItemAtPath:[url path] error:nil] fileIsImmutable];
    BOOL success = NO;
    
    if (isFinderLocked) {
        // Finder Lock がかかっていれば、解除
        success = [fileManager setAttributes:@{NSFileImmutable:@NO} ofItemAtPath:[url path] error:nil];
        if (success) {
            if (lockAgain) {
                // フラグが立っていたなら、再びかける
                [fileManager setAttributes:@{NSFileImmutable:@YES} ofItemAtPath:[url path] error:nil];
            }
        } else {
            return NO;
        }
    }
    if (isLocked) {
        *isLocked = isFinderLocked;
    }
    return YES;
}


// ------------------------------------------------------
/// エンコードを変更するアクションのRedo登録
- (void)redoSetEncoding:(NSStringEncoding)encoding updateDocument:(BOOL)updateDocument
               askLossy:(BOOL)askLossy lossy:(BOOL)lossy asActionName:(NSString *)actionName
// ------------------------------------------------------
{
    [[[self undoManager] prepareWithInvocationTarget:self] doSetEncoding:encoding updateDocument:updateDocument
                                                                askLossy:askLossy lossy:lossy asActionName:actionName];
}


// ------------------------------------------------------
/// 改行コードを変更するアクションのRedo登録
- (void)redoSetLineEnding:(CENewLineType)lineEnding
// ------------------------------------------------------
{
    [[[self undoManager] prepareWithInvocationTarget:self] doSetLineEnding:lineEnding];
}


// ------------------------------------------------------
/// 書き込み禁止アラートを表示
- (void)showNotWritableAlert
// ------------------------------------------------------
{
    if ([self isWritable] || [self didAlertNotWritable]) { return; }
    
    if ([[NSUserDefaults standardUserDefaults] boolForKey:CEDefaultShowAlertForNotWritableKey]) {
        NSAlert *alert = [[NSAlert alloc] init];
        [alert setMessageText:NSLocalizedString(@"The file is not writable.", nil)];
        [alert setInformativeText:NSLocalizedString(@"You may not be able to save your changes, but you will be able to save a copy somewhere else.", nil)];
        
        [alert beginSheetModalForWindow:[self windowForSheet]
                          modalDelegate:self
                         didEndSelector:NULL
                            contextInfo:NULL];
    }
    [self setDidAlertNotWritable:YES];
}


// ------------------------------------------------------
/// 外部プロセスによって更新されたことをシート／ダイアログで通知
- (void)showUpdatedByExternalProcessAlert
// ------------------------------------------------------
{
    if (![self needsShowUpdateAlertWithBecomeKey]) { return; } // 表示フラグが立っていなければ、もどる
    
    NSString *messageText, *informativeText, *defaultButton;
    if ([self isDocumentEdited]) {
        messageText = @"The file has been modified by another process. There are also unsaved changes in CotEditor.";
        informativeText = @"Do you want to keep CotEditor's edition or update to the modified edition?";
        defaultButton = @"Keep CotEditor's Edition";
    } else {
        messageText = @"The file has been modified by another process.";
        informativeText = @"Do you want to keep unchanged or update to the modified edition?";
        defaultButton = @"Keep Unchanged";
        [self updateChangeCount:NSChangeDone]; // ダーティーフラグを立てる
    }
    
    NSAlert *alert = [[NSAlert alloc] init];
    [alert setMessageText:NSLocalizedString(messageText, nil)];
    [alert setInformativeText:NSLocalizedString(informativeText, nil)];
    [alert addButtonWithTitle:NSLocalizedString(defaultButton, nil)];
    [alert addButtonWithTitle:NSLocalizedString(@"Update", nil)];
    
    // シートが表示中でなければ、表示
    if ([[self windowForSheet] attachedSheet] == nil) {
        [self setRevertingForExternalFileUpdate:YES];
        [[self windowForSheet] orderFront:nil]; // 後ろにあるウィンドウにシートを表示させると不安定になることへの対策
        [alert beginSheetModalForWindow:[self windowForSheet]
                          modalDelegate:self
                         didEndSelector:@selector(alertForModByAnotherProcessDidEnd:returnCode:contextInfo:)
                            contextInfo:NULL];
        
    } else if ([self isRevertingForExternalFileUpdate]) {
        // （同じ外部プロセスによる変更通知アラートシートを表示中の時は、なにもしない）
        
        // 既にシートが出ている時はダイアログで表示
    } else {
        [self setRevertingForExternalFileUpdate:YES];
        [[self windowForSheet] orderFront:nil]; // 後ろにあるウィンドウにシートを表示させると不安定になることへの対策
        NSInteger result = [alert runModal]; // アラート表示
        [self alertForModByAnotherProcessDidEnd:alert returnCode:result contextInfo:NULL];
    }
}


// ------------------------------------------------------
/// 外部プロセスによる変更の通知アラートが閉じた
- (void)alertForModByAnotherProcessDidEnd:(NSAlert *)alert returnCode:(NSInteger)returnCode contextInfo:(void *)contextInfo
// ------------------------------------------------------
{
    if (returnCode == NSAlertSecondButtonReturn) { // == Revert
        // Revert 確認アラートを表示させないため、実行メソッドを直接呼び出す
        if ([self revertToContentsOfURL:[self fileURL] ofType:[self fileType] error:nil]) {
            [[self undoManager] removeAllActions];
            [self updateChangeCount:NSChangeCleared];
        }
    }
    [self setRevertingForExternalFileUpdate:YES];
    [self setNeedsShowUpdateAlertWithBecomeKey:NO];
}


// ------------------------------------------------------
/// 書き込み不可ドキュメントが閉じるときの確認アラートが閉じた
- (void)alertForNotWritableDocCloseDidEnd:(NSAlert *)alert returnCode:(int)returnCode contextInfo:(void *)contextInfo
// ------------------------------------------------------
{
    // This method is based on the following page (2005-07-08)
    // http://www.cocoadev.com/index.pl?ReplaceSaveChangesSheet
    
    NSDictionary *contextInfoDict = CFBridgingRelease(contextInfo);
    id delegate = contextInfoDict[@"delegate"];
    SEL shouldCloseSelector = [contextInfoDict[@"shouldCloseSelector"] pointerValue];
    void *originalContextInfo = [contextInfoDict[@"contextInfo"] pointerValue];
    BOOL shouldClose = (returnCode == NSAlertSecondButtonReturn); // YES == Don't Save and Close
    
    if (delegate) {
        void (*callback)(id, SEL, id, BOOL, void *) = (void (*)(id, SEL, id, BOOL, void *))objc_msgSend;
        (*callback)(delegate, shouldCloseSelector, self, shouldClose, originalContextInfo);
        if (shouldClose) {
            [[NSApplication sharedApplication] terminate:nil];
        }
    }
}

@end
