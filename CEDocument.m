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

#import "CEDocument.h"
#import "ODBEditorSuite.h"



//=======================================================
// not defined in __LP64__
// 2014-02 by 1024jp
//=======================================================
#ifdef __LP64__
enum { typeFSS = 'fss ' };
#endif



//=======================================================
// Private method
//
//=======================================================

@interface CEDocument ()

@property (nonatomic) VDKQueue *fileObserver;
@property NSUInteger numberOfSavingFlags;

- (NSString *)convertedCharacterString:(NSString *)inString withEncoding:(NSStringEncoding)inEncoding;
- (void)doSetEncoding:(NSStringEncoding)inEncoding;
- (void)updateEncodingInToolbarAndInfo;
- (BOOL)readFromFile:(NSString *)inFileName withEncoding:(NSStringEncoding)inEncoding;
- (NSStringEncoding)scannedCharsetOrEncodingFromString:(NSString *)inString;
- (void)redoSetEncoding:(NSStringEncoding)inEncoding updateDocument:(BOOL)inDocUpdate 
        askLossy:(BOOL)inAskLossy  lossy:(BOOL)inLossy asActionName:(NSString *)inName;
- (void)redoSetNewLineEndingCharacterCode:(NSInteger)inNewLineEnding;
- (NSDictionary *)myCreatorAndTypeCodeAttributes;
- (BOOL)acceptSaveDocumentWithIANACharSetName;
- (BOOL)acceptSaveDocumentToConvertEncoding;
- (BOOL)saveToFile:(NSString *)inFileName ofType:(NSString *)inDocType 
            saveOperation:(NSSaveOperationType)inSaveOperationType;
- (void)sendModifiedEventToClientOfFile:(NSString *)inSaveAsPath 
        operation:(NSSaveOperationType)inSaveOperationType;
- (void)sendCloseEventToClient;
- (BOOL)canReleaseFinderLockOfFile:(NSString *)inFileName isLocked:(BOOL *)ioLocked lockAgain:(BOOL)inLockAgain;
- (void)alertForNotWritableCloseDocDidEnd:(NSAlert *)inAlert returnCode:(NSInteger)inReturnCode
            contextInfo:(void *)inContextInfo;
- (void)startWatchFile:(NSString *)inFileName;
- (void)stopWatchFile:(NSString *)inFileName;
- (void)alertForModByAnotherProcessDidEnd:(NSAlert *)inAlert returnCode:(NSInteger)inReturnCode
            contextInfo:(void *)inContextInfo;
- (void)printPanelDidEnd:(NSPrintPanel *)inPrintPanel returnCode:(NSInteger)inReturnCode
            contextInfo:(void *)inContextInfo;
- (NSStringEncoding)encodingFromComAppleTextEncodingAtPath:(NSString *)inFilePath;
- (void)setComAppleTextEncodingAtPath:(NSString *)inFilePath;
- (void)setIsWritableToEditorViewWithFileName:(NSString *)inFileName;
- (void)showAlertForNotWritable;
@end


//------------------------------------------------------------------------------------------




@implementation CEDocument

#pragma mark ===== Class method =====

// ------------------------------------------------------
+ (BOOL)autosavesInPlace
// OS X 10.7 AutoSave
// ------------------------------------------------------
{
    return NO;
}


// ------------------------------------------------------
+ (BOOL)preservesVersions
// OS X 10.7 Versions
// ------------------------------------------------------
{
    return NO;
}


#pragma mark ===== Public method =====

//=======================================================
// Public method
//
//=======================================================

// ------------------------------------------------------
- (id)init
// 初期化
// ------------------------------------------------------
{
    self = [super init];
    if (self) {
        id theValues = [[NSUserDefaultsController sharedUserDefaultsController] values];

        [self setHasUndoManager:YES];
        _initialString = nil;
        _windowController = nil;
        // CotEditor のクリエータ／タイプを使うなら、設定しておく
        _fileAttr = ([[theValues valueForKey:k_key_saveTypeCreator] unsignedIntegerValue] <= 1) ?
                [[self myCreatorAndTypeCodeAttributes] retain] : nil;
        (void)[self doSetEncoding:[[theValues valueForKey:k_key_encodingInNew] unsignedLongValue] 
                updateDocument:NO askLossy:NO lossy:NO asActionName:nil];
        _selection = [[CETextSelection alloc] initWithDocument:self]; // ===== alloc
        _fileSender = nil;
        _fileToken = nil;
        [self setNumberOfSavingFlags:0];
        _showUpdateAlertWithBecomeKey = NO;
        _isRevertingForExternalFileUpdate = NO;
        _canActivateShowInvisibleCharsItem = 
                ([[theValues valueForKey:k_key_showInvisibleSpace] boolValue] || 
                [[theValues valueForKey:k_key_showInvisibleTab] boolValue] || 
                [[theValues valueForKey:k_key_showInvisibleNewLine] boolValue] || 
                [[theValues valueForKey:k_key_showInvisibleFullwidthSpace] boolValue] || 
                [[theValues valueForKey:k_key_showOtherInvisibleChars] boolValue]);
        [self setDoCascadeWindow:YES];
        [self setInitTopLeftPoint:NSZeroPoint];
        [[NSNotificationCenter defaultCenter] addObserver:self 
                selector:@selector(documentDidFinishOpen:) 
                name:k_documentDidFinishOpenNotification object:nil];
        
        // ファイル変更オブサーバのセット
        [self setFileObserver:[[VDKQueue alloc] init]];
        [[self fileObserver] setDelegate:self];
    }
    return self;
}


// ------------------------------------------------------
- (void)dealloc
// あとかたづけ
// ------------------------------------------------------
{
    // ノーティフィケーションセンタから自身を排除
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    
    // 外部プロセスによるファイルの変更監視を停止
    if ([self fileURL]) {
        [[self fileObserver] removeAllPaths];
    }
    [[self fileObserver] setDelegate:nil];
    [[self fileObserver] release];
    
    // _initialString は既に autorelease されている == "- (NSString *)stringToWindowController"
    // _selection は既に autorelease されている == "- (void)close"
    [[_editorView splitView] releaseAllEditorView]; // 各subSplitView が持つ editorView 参照を削除
    [_editorView release]; // 自身のメンバを削除
    [_windowController release];
    [_fileAttr release];
    [_fileToken release];
     // _fileSender は既にnilがセットされている == "- (void)sendModifiedEventToClientOfFile:(NSString *)inSaveAsPath  operation:(NSSaveOperationType)inSaveOperationType", "- (void)sendCloseEventToClient"

    [super dealloc];
}


// ------------------------------------------------------
- (void)makeWindowControllers
// カスタム windowController を生成
// ------------------------------------------------------
{
    _windowController = [[CEWindowController alloc] initWithWindowNibName:@"DocWindow"]; // ===== alloc
    [self addWindowController:_windowController];
}


// ------------------------------------------------------
- (BOOL)writeSafelyToURL:(NSURL *)url ofType:(NSString *)typeName forSaveOperation:(NSSaveOperationType)saveOperation error:(NSError **)outError
// バックアップファイルの保存(保存処理で包括的に呼ばれる)
// ------------------------------------------------------
{
    // 保存中のフラグを立て、保存実行（自分自身が保存した時のファイル更新通知を区別するため）
    [self increaseSavingFlag];
    // SaveAs のとき古いパスを監視対象から外すために保持
    NSString *theOldPath = [[self fileURL] path];
    // 新規書類を最初に保存する場合のフラグをセット
    BOOL theBoolIsFirstSaving = ((theOldPath == nil) || (saveOperation == NSSaveAsOperation));
    // 保存処理実行
    BOOL outResult = [self saveToFile:[url path] ofType:typeName saveOperation:saveOperation];

    if (outResult) {
        NSUndoManager *theUndoManager = [self undoManager];

        // 新規保存時、カラーリングのために拡張子を保持
        if (theBoolIsFirstSaving) {
            [self setColoringExtension:[url pathExtension]
                    coloring:YES];
        }

        // 保存の前後で編集内容をグルーピングさせないための処置
        // ダミーのグループを作り、そのままだと空のアンドゥ内容でダーティーフラグがたってしまうので、アンドゥしておく
        // ****** 空のアンドゥ履歴が残る問題あり  (2005.08.05) *******
        // (保存の前後で編集内容がグルーピングされてしまう例：キー入力後保存し、キャレットを動かすなどしないでそのまま入力
        // した場合、ダーティーフラグがたたず、アンドゥすると保存前まで戻されてしまう。さらに、戻された状態でリドゥすると、
        // 保存後の入力までが行われる。つまり、保存をはさんで前後の内容が同一アンドゥグループに入ってしまうための不具合)
        // CETextViewCore > doInsertString:withRange:withSelected:withActionName: でも同様の対処を行っている
        // ****** 何かもっとうまい回避方法があるはずなんだが … (2005.08.05) *******
        [theUndoManager beginUndoGrouping];
        [theUndoManager endUndoGrouping];
        [theUndoManager undo];

        // 保持しているファイル情報／表示する文書情報を更新
        [self getFileAttributes];
        // SaveAs のとき古いパスの監視をやめる
        if ((theOldPath != nil) && (saveOperation == NSSaveAsOperation)) {
            [self stopWatchFile:theOldPath];
        }
        // 外部プロセスによる変更監視を開始
        if (theBoolIsFirstSaving) {
            [self startWatchFile:[url path]];
        }
    }
    // 外部エディタプロトコル(ODB Editor Suite)のファイル更新通知送信
    [self sendModifiedEventToClientOfFile:[url path] operation:saveOperation];
    // ファイル保存更新を Finder へ通知（デスクトップに保存した時に白紙アイコンになる問題への対応）
    [[NSWorkspace sharedWorkspace] noteFileSystemChanged:[url path]];

    // ディレイをかけて、保存中フラグをもどす
    [self performSelector:@selector(decreaseSavingFlag) withObject:nil afterDelay:0.5];

    return outResult;
}


// ------------------------------------------------------
- (NSDictionary *)fileAttributesToWriteToURL:(NSURL *)url ofType:(NSString *)typeName forSaveOperation:(NSSaveOperationType)saveOperation originalContentsURL:(NSURL *)absoluteOriginalContentsURL error:(NSError **)outError
// ファイル保存時のクリエータ／タイプなどファイル属性を決定する
// ------------------------------------------------------
{
    id theValues = [[NSUserDefaultsController sharedUserDefaultsController] values];
    NSMutableDictionary *outDict = [[super fileAttributesToWriteToURL:url
                                                               ofType:typeName
                                                     forSaveOperation:saveOperation
                                                  originalContentsURL:absoluteOriginalContentsURL
                                                                error:outError] mutableCopy];
    NSUInteger theSaveTypeCreator = [[theValues valueForKey:k_key_saveTypeCreator] unsignedIntegerValue];
    
    if (theSaveTypeCreator == 0) { // = same as original
        OSType theCreator = [_fileAttr fileHFSCreatorCode];
        OSType theType = [_fileAttr fileHFSTypeCode];
        if ((theCreator == 0) || (theType == 0)) {
            [outDict addEntriesFromDictionary:[self myCreatorAndTypeCodeAttributes]];
        } else {
            outDict[NSFileHFSCreatorCode] = _fileAttr[NSFileHFSCreatorCode];
            outDict[NSFileHFSTypeCode] = _fileAttr[NSFileHFSTypeCode];
        }
    } else if (theSaveTypeCreator == 1) { // = CotEditor's type
        [outDict addEntriesFromDictionary:[self myCreatorAndTypeCodeAttributes]];
    }
    
    return outDict;
}


// ------------------------------------------------------
- (BOOL)revertToContentsOfURL:(NSURL *)url ofType:(NSString *)typeName error:(NSError **)outError
// セーブ時の状態に戻す
// ------------------------------------------------------
{
    // 認証が必要な時に重なって表示されるのを避けるため、まず復帰確認シートを片づける
    //（外部プロセスによる変更通知アラートシートはそのままに）
    if (!_isRevertingForExternalFileUpdate) {
        [[[_editorView window] attachedSheet] orderOut:self];
    }

    BOOL outResult = [self readFromFile:[url path] withEncoding:k_autoDetectEncodingMenuTag];

    if (outResult) {
        [self setStringToEditorView];
    }
    return outResult;
}


// ------------------------------------------------------
- (BOOL)shouldRunSavePanelWithAccessoryView
// セーブパネルへ標準のアクセサリビュー(ポップアップメニューでの書類の切り替え)を追加しない
// ------------------------------------------------------
{
    return NO;
}


// ------------------------------------------------------
- (void)runModalSavePanelForSaveOperation:(NSSaveOperationType)inSaveOperation delegate:(id)inDelegate 
            didSaveSelector:(SEL)inDidSaveSelector contextInfo:(void *)inContextInfo
// セーブパネルを表示
// ------------------------------------------------------
{
    [super runModalSavePanelForSaveOperation:inSaveOperation delegate:inDelegate 
            didSaveSelector:inDidSaveSelector contextInfo:inContextInfo];

    // セーブパネル表示時の処理
    NSSavePanel *theSavePanel = (NSSavePanel *)[[_editorView window] attachedSheet];
    if (theSavePanel != nil) {
        NSEnumerator *theEnumerator = [[[theSavePanel contentView] subviews] objectEnumerator];
        NSTextField *theTextField = nil;
        id theView;

        while (theView = [theEnumerator nextObject]) {
            if ([theView isKindOfClass:[NSTextField class]]) {
                theTextField = theView;
                break;
            }
        }
        if (theTextField != nil) {
            NSText *theText = [theSavePanel fieldEditor:NO forObject:theTextField];
            NSString *theName = [theText string];

            // 保存時に拡張子を追加する
            id theValues = [[NSUserDefaultsController sharedUserDefaultsController] values];
            if ([[theValues valueForKey:k_key_appendExtensionAtSaving] boolValue]) {
                // ファイル名に拡張子がない場合は追加する
                if ([[theName pathExtension] compare:@""] == NSOrderedSame) {
                    [theText setString:[theName stringByAppendingPathExtension:@"txt"]];
                }
            }

            // 保存するファイル名の、拡張子をのぞいた部分を選択状態にする
            [theText setSelectedRange:NSMakeRange(0, [[theName stringByDeletingPathExtension] length])];
        }
    }
}


// ------------------------------------------------------
- (BOOL)readFromURL:(NSURL *)url ofType:(NSString *)typeName error:(NSError **)outError
// ファイルを読み込み、成功したかどうかを返す
// ------------------------------------------------------
{
    // フォルダをアイコンにドロップしても開けないようにする
    BOOL theBoolIsDir = NO;
    (void)[[NSFileManager defaultManager] fileExistsAtPath:[url path] isDirectory:&theBoolIsDir];
    if (theBoolIsDir) { return NO; }

    NSStringEncoding theEncoding = [[CEDocumentController sharedDocumentController] accessorySelectedEncoding];

    return [self readFromFile:[url path] withEncoding:theEncoding];
}


// ------------------------------------------------------
- (void)setString:(NSMutableString *)inString
// 初期表示文字列に表示する文字列を保持
// ------------------------------------------------------
{
    [inString retain];
    [_initialString release];
    _initialString = inString;
}


// ------------------------------------------------------
- (void)canCloseDocumentWithDelegate:(id)inDelegate shouldCloseSelector:(SEL)inShouldCloseSelector 
        contextInfo:(void *)inContextInfo
// ドキュメントが閉じられる前に保存のためのダイアログの表示などを行う
// ------------------------------------------------------
{
// このメソッドは下記のページの情報を参考にさせていただきました(2005.07.08)
// http://www.cocoadev.com/index.pl?ReplaceSaveChangesSheet

    // 各種更新タイマーを停止
    [[self editorView] stopAllTimer];

    // Finder のロックが解除できず、かつダーティーフラグがたっているときは相応のダイアログを出す
    if (([self isDocumentEdited]) && 
            (![self canReleaseFinderLockOfFile:[[self fileURL] path] isLocked:nil lockAgain:YES])) {
        CanCloseAlertContext *closeContext = malloc(sizeof(CanCloseAlertContext));
        closeContext->delegate = inDelegate;
        closeContext->shouldCloseSelector = inShouldCloseSelector;
        closeContext->contextInfo = inContextInfo;

        NSAlert *theAleart = [NSAlert alertWithMessageText:NSLocalizedString(@"Finder's Lock is ON",@"") 
                    defaultButton:NSLocalizedString(@"Cancel",@"") 
                    alternateButton:NSLocalizedString(@"Don't Save, and Close",@"") 
                    otherButton:nil 
                    informativeTextWithFormat:NSLocalizedString(@"Finder's Lock could not be released. So, You can not save your changes on this file, but you will be able to Save a Copy somewhere else. \n\nDo you want to close?\n",@"")
                    ];
        NSArray *theButtons = [theAleart buttons];

        for (NSButton *theDontSaveButton in theButtons) {
            if ([[theDontSaveButton title] isEqualToString:NSLocalizedString(@"Don't Save, and Close",@"")]) {
                [theDontSaveButton setKeyEquivalent:@"d"];
                [theDontSaveButton setKeyEquivalentModifierMask:NSCommandKeyMask];
                break;
            }
        }
        [theAleart beginSheetModalForWindow:[_editorView window] 
                    modalDelegate:self 
                    didEndSelector:@selector(alertForNotWritableCloseDocDidEnd:returnCode:contextInfo:) 
                    contextInfo:closeContext];
    } else {
        [super canCloseDocumentWithDelegate:inDelegate shouldCloseSelector:inShouldCloseSelector 
                contextInfo:inContextInfo];
    }
}


// ------------------------------------------------------
- (void)close
// ドキュメントを閉じる
// ------------------------------------------------------
{
    // アンドゥ履歴をクリア
    [[self undoManager] removeAllActionsWithTarget:self];
    // 外部エディタプロトコル(ODB Editor Suite)のファイルクローズを送信
    [self sendCloseEventToClient];

    [_selection autorelease]; // （互いに参照しあっているため、dealloc でなく、ここで開放しておく）
    [self removeWindowController:(NSWindowController *)_windowController];

    [super close];
}


// ------------------------------------------------------
- (CEEditorView *)editorView
// editorView を返す
// ------------------------------------------------------
{
    return _editorView;
}


// ------------------------------------------------------
- (void)setEditorView:(CEEditorView *)inEditorView
// editorView をセット
// ------------------------------------------------------
{
    [inEditorView retain];
    [_editorView release];
    _editorView = inEditorView;
}


// ------------------------------------------------------
- (id)windowController
// windowController を返す
// ------------------------------------------------------
{
    return _windowController;
}


//------------------------------------------------------
- (BOOL)stringFromData:(NSData *)inData encoding:(NSStringEncoding)ioEncoding xattr:(BOOL)inBoolXattr
// データから指定エンコードで文字列を得る
//------------------------------------------------------
{
    NSString *theStr = nil;
    BOOL theBoolToSkipISO2022JP = NO;
    BOOL theBoolToSkipUTF8 = NO;
    BOOL theBoolToSkipUTF16 = NO;

    // ISO 2022-JP / UTF-8 / UTF-16の判定は、「藤棚工房別棟 −徒然−」の
    // 「Cocoaで文字エンコーディングの自動判別プログラムを書いてみました」で公開されている
    // FJDDetectEncoding を参考にさせていただきました (2006.09.30)
    // http://blogs.dion.ne.jp/fujidana/archives/4169016.html

    // 10.5+でのファイル拡張属性(com.apple.TextEncoding)を試す
    if ((inBoolXattr) && (ioEncoding != k_autoDetectEncodingMenuTag)) {
        theStr = [[[NSString alloc] initWithData:inData encoding:ioEncoding] autorelease];
        if (theStr == nil) {
            ioEncoding = k_autoDetectEncodingMenuTag;
        }
    }

    if (([inData length] > 0) && (ioEncoding == k_autoDetectEncodingMenuTag)) {
        const char theUtf8Bom[] = {0xef, 0xbb, 0xbf}; // UTF-8 BOM
        // BOM付きUTF-8判定
        if (memchr([inData bytes], *theUtf8Bom, 3) != NULL) {

            theBoolToSkipUTF8 = YES;
            theStr = [[[NSString alloc] initWithData:inData encoding:NSUTF8StringEncoding] autorelease];
            if (theStr != nil) {
                ioEncoding = NSUTF8StringEncoding;
            }
        // UTF-16判定
        } else if ((memchr([inData bytes], 0xfffe, 2) != NULL) || 
                    (memchr([inData bytes], 0xfeff, 2) != NULL)) {

            theBoolToSkipUTF16 = YES;
            theStr = [[[NSString alloc] initWithData:inData encoding:NSUnicodeStringEncoding] autorelease];
            if (theStr != nil) {
                ioEncoding = NSUnicodeStringEncoding;
            }

        // ISO 2022-JP判定
        } else if (memchr([inData bytes], 0x1b, [inData length]) != NULL) {
            theBoolToSkipISO2022JP = YES;
            theStr = [[[NSString alloc] initWithData:inData encoding:NSISO2022JPStringEncoding] autorelease];
            if (theStr != nil) {
                ioEncoding = NSISO2022JPStringEncoding;
            }
        }
    }

    if ((theStr == nil) && (ioEncoding == k_autoDetectEncodingMenuTag)) {
        id theValues = [[NSUserDefaultsController sharedUserDefaultsController] values];
        NSArray *theEncodings = [[[theValues valueForKey:k_key_encodingList] copy] autorelease];
        NSInteger i = 0;

        while (theStr == nil) {
            ioEncoding = 
                    CFStringConvertEncodingToNSStringEncoding([theEncodings[i] unsignedLongValue]);
            if ((ioEncoding == NSISO2022JPStringEncoding) && theBoolToSkipISO2022JP) {
                break;
            } else if ((ioEncoding == NSUTF8StringEncoding) && theBoolToSkipUTF8) {
                break;
            } else if ((ioEncoding == NSUnicodeStringEncoding) && theBoolToSkipUTF16) {
                break;
            } else if (ioEncoding == NSProprietaryStringEncoding) {
                NSLog(@"theEncoding == NSProprietaryStringEncoding");
                break;
            }
            theStr = [[[NSString alloc] initWithData:inData encoding:ioEncoding] autorelease];
            if (theStr != nil) {
                // "charset="や"encoding="を読んでみて適正なエンコーディングが得られたら、そちらを優先
                NSStringEncoding theTmpEncoding = [self scannedCharsetOrEncodingFromString:theStr];
                if ((theTmpEncoding == NSProprietaryStringEncoding) || (theTmpEncoding == ioEncoding)) {
                    break;
                }
                NSString *theTmpStr = 
                        [[[NSString alloc] initWithData:inData encoding:theTmpEncoding] autorelease];
                if (theTmpStr != nil) {
                    theStr = theTmpStr;
                    ioEncoding = theTmpEncoding;
                }
            }
            i++;
        }
    } else if (theStr == nil) {
        theStr = [[[NSString alloc] initWithData:inData encoding:ioEncoding] autorelease];
    }

    if ((theStr != nil) && (ioEncoding != k_autoDetectEncodingMenuTag)) {
        // 10.3.9 で、一部のバイナリファイルを開いたときにクラッシュする問題への暫定対応。
        // 10.4+ ではスルー（2005.12.25）
        // ＞＞ しかし「すべて2バイト文字で4096文字以上あるユニコードでない文書」は開けない（2005.12.25）
        // (下記の現象と同じ理由で発生していると思われる）
        // https://www.codingmonkeys.de/bugs/browse/HYR-529?page=all
        if ((floor(NSAppKitVersionNumber) > NSAppKitVersionNumber10_3) || // = 10.4+ 
                ([inData length] <= 8192) || 
                (([inData length] > 8192) && ([inData length] != ([theStr length] * 2 + 1)) && 
                        ([inData length] != ([theStr length] * 2)))) {

            _initialString = [theStr retain]; // ===== retain
            // (_initialString はあとで開放 == "- (NSString *)stringToWindowController".)
            (void)[self doSetEncoding:ioEncoding updateDocument:NO askLossy:NO lossy:NO asActionName:nil];
            return YES;
        }
    }

    return NO;
}


// ------------------------------------------------------
- (NSString *)stringToWindowController
// windowController に表示する文字列を返す
// ------------------------------------------------------
{
    return [_initialString autorelease]; // ===== autorelease
}


// ------------------------------------------------------
- (void)setStringToEditorView
// editorView に文字列をセット
// ------------------------------------------------------
{
    [self setColoringExtension:[[self fileURL] pathExtension] coloring:NO];
    [self setStringToTextView:[self stringToWindowController]];
    if ([_windowController needsIncompatibleCharDrawerUpdate]) {
        [_windowController showIncompatibleCharList];
    }
    [self setIsWritableToEditorViewWithFileName:[[self fileURL] path]];
}


// ------------------------------------------------------
- (void)setStringToTextView:(NSString *)inString
// 新たな文字列をセット
// ------------------------------------------------------
{
    if (inString) {
        OgreNewlineCharacter theLineEnd = [OGRegularExpression newlineCharacterInString:inString];
        [self setLineEndingCharToView:theLineEnd]; // for update toolbar item
        [_editorView setString:inString]; // （editorView の setString 内でキャレットを先頭に移動させている）
    } else {
        [_editorView setString:@""];
    }
    // ツールバーのエンコーディングメニュー、ステータスバー、ドローワを更新
    [self updateEncodingInToolbarAndInfo];
    // テキストビューへフォーカスを移動
    [[_editorView window] makeFirstResponder:[[[_editorView splitView] subviews][0] textView]];
    // カラーリングと行番号を更新
    // （大きいドキュメントの時はインジケータを表示させるため、ディレイをかけてまずウィンドウを表示させる）
    [_editorView updateColoringAndOutlineMenuWithDelay];
}


// ------------------------------------------------------
- (NSStringEncoding)encodingCode
// 表示しているファイルのエンコーディングを返す
// ------------------------------------------------------
{
    return _encoding;
}


// ------------------------------------------------------
- (BOOL)doSetEncoding:(NSStringEncoding)inEncoding updateDocument:(BOOL)inDocUpdate 
        askLossy:(BOOL)inAskLossy  lossy:(BOOL)inLossy  asActionName:(NSString *)inName
// 新規エンコーディングをセット
// ------------------------------------------------------
{
    if (inEncoding == _encoding) {
        return YES;
    }
    NSInteger theResult = NSAlertOtherReturn;
    BOOL theBoolNeedsShowList = NO;
    if (inDocUpdate) {

        theBoolNeedsShowList = [_windowController needsIncompatibleCharDrawerUpdate];
        NSString *theCurString = [_editorView stringForSave];
        BOOL theAllowLossy = NO;

        if (inAskLossy) {
            if (![theCurString canBeConvertedToEncoding:inEncoding]) {
                NSString *theEncodingNameStr = [NSString localizedNameOfStringEncoding:inEncoding];
                NSString *theMessage = NSLocalizedString(@"The characters would have to be changed or deleted in saving as \"%@\".\n\nDo you want to change encoding and show incompatible character(s)?\n",@"");
                NSAlert *theAleart = [NSAlert alertWithMessageText:NSLocalizedString(@"Warning",@"") 
                            defaultButton:NSLocalizedString(@"Cancel",@"") 
                            alternateButton:NSLocalizedString(@"Change Encoding",@"") 
                            otherButton:nil 
                            informativeTextWithFormat:theMessage, theEncodingNameStr];

                theResult = [theAleart runModal];
                if (theResult == NSAlertDefaultReturn) { // == Cancel
                    return NO;
                }
                theBoolNeedsShowList = YES;
                theAllowLossy = YES;
            }
        } else {
            theAllowLossy = inLossy;
        }
        // Undo登録
        NSUndoManager *theUndoManager = [self undoManager];
        [[theUndoManager prepareWithInvocationTarget:self] 
                    redoSetEncoding:inEncoding updateDocument:inDocUpdate 
                    askLossy:NO lossy:theAllowLossy asActionName:inName]; // undo内redo
        if (theBoolNeedsShowList) {
            [[theUndoManager prepareWithInvocationTarget:_windowController] showIncompatibleCharList];
        }
        [[theUndoManager prepareWithInvocationTarget:self] doSetEncoding:_encoding]; // エンコード値設定
        [[theUndoManager prepareWithInvocationTarget:self] updateChangeCount:NSChangeUndone]; // changeCount減値
        if (inName) {
            [theUndoManager setActionName:inName];
        }
        [self updateChangeCount:NSChangeDone];
    }
    [self doSetEncoding:inEncoding];
    if (theBoolNeedsShowList) {
        [_windowController showIncompatibleCharList];
    }
    return YES;
}


// ------------------------------------------------------
- (void)clearAllMarkupForIncompatibleChar
// 背景色の変更を取り消し
// ------------------------------------------------------
{
    NSArray *managers = [_editorView allLayoutManagers];

    for (NSLayoutManager *manager in managers) {
        // 現存の背景色カラーリングをすべて削除（検索のハイライトも削除される）
        [manager removeTemporaryAttribute:NSBackgroundColorAttributeName
                        forCharacterRange:NSMakeRange(0, [[_editorView string] length])];
    }
}


// ------------------------------------------------------
- (NSArray *)markupCharCanNotBeConvertedToCurrentEncoding
// 現在のエンコードにコンバートできない文字列をマークアップし、その配列を返す
// ------------------------------------------------------
{
    return [self markupCharCanNotBeConvertedToEncoding:[self encodingCode]];
}


// ------------------------------------------------------
- (NSArray *)markupCharCanNotBeConvertedToEncoding:(NSStringEncoding)inEncoding
// 指定されたエンコードにコンバートできない文字列をマークアップし、その配列を返す
// ------------------------------------------------------
{
    NSMutableArray *outArray = [NSMutableArray array];
    NSString *theWholeString = [_editorView stringForSave];
    NSUInteger theWholeLength = [theWholeString length];
    NSData *theData = [theWholeString dataUsingEncoding:inEncoding allowLossyConversion:YES];
    NSString *theConvertedString = [[[NSString alloc] initWithData:theData encoding:inEncoding] autorelease];

    if ((theConvertedString == nil) || 
            ([theConvertedString length] != theWholeLength)) { // 正しいリストが取得できない時
        return nil;
    }

    // 現存の背景色カラーリングをすべて削除（検索のハイライトも削除される）
    [self clearAllMarkupForIncompatibleChar];

    // 削除／変換される文字をリストアップ
    id theValues = [[NSUserDefaultsController sharedUserDefaultsController] values];
    NSArray *theManagers = [_editorView allLayoutManagers];
    NSColor *theForeColor = 
            [NSUnarchiver unarchiveObjectWithData:[theValues valueForKey:k_key_textColor]];
    NSColor *theBGColor = 
            [NSUnarchiver unarchiveObjectWithData:[theValues valueForKey:k_key_backgroundColor]];
    NSColor *theIncompatibleColor;
    NSDictionary *theAttrs;
    NSString *theCurChar, *theConvertedChar;
    NSString *theYemMarkChar = [NSString stringWithCharacters:&k_yenMark length:1];
    unichar theWholeUnichar, theConvertedUnichar;
    NSUInteger i, theLines, theIndex, theCurLine;
    CGFloat theBG_R, theBG_G, theBG_B, theF_R, theF_G, theF_B;

    // 文字色と背景色の中間色を得る
    [[theForeColor colorUsingColorSpaceName:NSCalibratedRGBColorSpace] 
            getRed:&theF_R green:&theF_G blue:&theF_B alpha:nil];
    [[theBGColor colorUsingColorSpaceName:NSCalibratedRGBColorSpace] 
            getRed:&theBG_R green:&theBG_G blue:&theBG_B alpha:nil];
    theIncompatibleColor = [NSColor colorWithCalibratedRed:((theBG_R + theF_R) / 2) 
                green:((theBG_G + theF_G) / 2) 
                blue:((theBG_B + theF_B) / 2) 
                alpha:1.0];
    theAttrs = @{NSBackgroundColorAttributeName: theIncompatibleColor};

    for (i = 0; i < theWholeLength; i++) {
        theWholeUnichar = [theWholeString characterAtIndex:i];
        theConvertedUnichar = [theConvertedString characterAtIndex:i];
        if (theWholeUnichar != theConvertedUnichar) {
            theCurChar = [theWholeString substringWithRange:NSMakeRange(i, 1)];
            theConvertedChar = [theConvertedString substringWithRange:NSMakeRange(i, 1)];

            if (([[NSApp delegate] isInvalidYenEncoding:inEncoding]) && 
                    ([theCurChar isEqualToString:theYemMarkChar])) {
                theCurChar = theYemMarkChar;
                theConvertedChar = @"\\";
            }

            for (NSLayoutManager *manager in theManagers) {
                [manager addTemporaryAttributes:theAttrs forCharacterRange:NSMakeRange(i, 1)];
            }
            theCurLine = 1;
            for (theIndex = 0, theLines = 0; theIndex < theWholeLength; theLines++) {
                if (theIndex <= i) {
                    theCurLine = theLines + 1;
                } else {
                    break;
                }
                theIndex = NSMaxRange([theWholeString lineRangeForRange:NSMakeRange(theIndex, 0)]);
            }
            [outArray addObject:[NSMutableDictionary dictionaryWithObjectsAndKeys:
                    @(theCurLine), k_listLineNumber, 
                    [NSValue valueWithRange:NSMakeRange(i, 1)], k_incompatibleRange, 
                    theCurChar, k_incompatibleChar, 
                    theConvertedChar, k_convertedChar, 
                    nil]];
        }
    }
    return outArray;
}


// ------------------------------------------------------
- (void)doSetNewLineEndingCharacterCode:(NSInteger)inNewLineEnding
// 行末コードを変更する
// ------------------------------------------------------
{
    NSInteger theCurrentEnding = [_editorView lineEndingCharacter];

    // 現在と同じ行末コードなら、何もしない
    if (theCurrentEnding == inNewLineEnding) {
        return;
    }

    NSArray *lineEndingNames = @[k_lineEndingNames];
    NSString *theActionName = [NSString stringWithFormat:
                NSLocalizedString(@"Line Endings to \"%@\"",@""),lineEndingNames[inNewLineEnding]];

    // Undo登録
    NSUndoManager *theUndoManager = [self undoManager];
    [[theUndoManager prepareWithInvocationTarget:self] 
                redoSetNewLineEndingCharacterCode:inNewLineEnding]; // undo内redo
    [[theUndoManager prepareWithInvocationTarget:self] setLineEndingCharToView:theCurrentEnding]; // 元の行末コード
    [[theUndoManager prepareWithInvocationTarget:self] updateChangeCount:NSChangeUndone]; // changeCountデクリメント
    [theUndoManager setActionName:theActionName];

    [self setLineEndingCharToView:inNewLineEnding];
    [self updateChangeCount:NSChangeDone]; // changeCountインクリメント
}


// ------------------------------------------------------
- (void)setLineEndingCharToView:(NSInteger)inNewLineEnding
// 行末コード番号をセット
// ------------------------------------------------------
{
    [_editorView setLineEndingCharacter:inNewLineEnding];
    [[_windowController toolbarController] setSelectEndingItemIndex:inNewLineEnding];
}


// ------------------------------------------------------
- (void)doSetSyntaxStyle:(NSString *)inName
// 新しいシンタックスカラーリングスタイルを適用
// ------------------------------------------------------
{
    if ([inName length] > 0) {
        [_editorView setSyntaxStyleNameToColoring:inName recolorNow:YES];
        [[_windowController toolbarController] setSelectSyntaxItemWithTitle:inName];
    }
}


// ------------------------------------------------------
- (void)doSetSyntaxStyle:(NSString *)inName delay:(BOOL)inBoolDelay
// ディレイをかけて新しいシンタックスカラーリングスタイルを適用（ほぼNone専用）
// ------------------------------------------------------
{
    if (inBoolDelay) {
        if ([inName length] > 0) {
            [_editorView setSyntaxStyleNameToColoring:inName recolorNow:NO];
            [[_windowController toolbarController] 
                    performSelector:@selector(setSelectSyntaxItemWithTitle:) withObject:inName afterDelay:0];
        }
    } else {
        [self doSetSyntaxStyle:inName];
    }
    
}


// ------------------------------------------------------
- (void)setColoringExtension:(NSString *)inExtension coloring:(BOOL)inBoolColoring
// editorViewを通じてcoloringStyleインスタンスにドキュメント拡張子をセット
// ------------------------------------------------------
{
    id theValues = [[NSUserDefaultsController sharedUserDefaultsController] values];
    if (![[theValues valueForKey:k_key_doColoring] boolValue]) { return; }

    BOOL theBoolIsUpdated = [_editorView setSyntaxExtension:inExtension];

    if (theBoolIsUpdated) {
        // ツールバーのカラーリングポップアップの表示を更新、再カラーリング
        NSString *theName = [[CESyntaxManager sharedInstance] syntaxNameFromExtension:inExtension];
        theName = ((theName == nil) || ([theName isEqualToString:@""])) ? 
                    [theValues valueForKey:k_key_defaultColoringStyleName] : theName;
        [[_windowController toolbarController] setSelectSyntaxItemWithTitle:theName];
        if (inBoolColoring) {
            [self recoloringAllStringOfDocument:nil];
        }
    }
}


// ------------------------------------------------------
- (void)setFontToViewInWindow
// フォントを変更する
// ------------------------------------------------------
{
    id theValues = [[NSUserDefaultsController sharedUserDefaultsController] values];
    NSString *theName = [theValues valueForKey:k_key_fontName];
    CGFloat theSize = [[theValues valueForKey:k_key_fontSize] floatValue];
    NSFont *theFont = [NSFont fontWithName:theName size:theSize];

    [_editorView setFont:theFont];
}


// ------------------------------------------------------
- (BOOL)alphaOnlyTextViewInThisWindow
// TextView のみを透過するかどうかを返す
// ------------------------------------------------------
{
    return _alphaOnlyTextViewInThisWindow;
}


// ------------------------------------------------------
- (CGFloat)alpha
// ウィンドウまたは TextView の透明度を返す
// ------------------------------------------------------
{
    CGFloat outAlpha;
    if ([self alphaOnlyTextViewInThisWindow]) {
        outAlpha = [[[_editorView textView] backgroundColor] alphaComponent];
    } else {
        outAlpha = [[_windowController window] alphaValue];
    }
    if (outAlpha < 0.2) {
        outAlpha = 0.2;
    } else if (outAlpha > 1.0) {
        outAlpha = 1.0;
    }

    return outAlpha;
}

// ------------------------------------------------------
- (void)setAlpha:(CGFloat)inAlpha
// ウィンドウの透明度を変更する
// ------------------------------------------------------
{
    CGFloat theAlpha;

    if (inAlpha < 0.2) {
        theAlpha = 0.2;
    } else if (inAlpha > 1.0) {
        theAlpha = 1.0;
    } else {
        theAlpha = inAlpha;
    }
    if ([self alphaOnlyTextViewInThisWindow]) {
        [[_windowController window] invalidateShadow];
        [[_windowController window] setBackgroundColor:[NSColor clearColor]]; // ウィンドウ背景色に透明色をセット
        [[_windowController window] setOpaque:NO]; // ウィンドウを透明にする
        [[_windowController window] setAlphaValue:1.0];
        [[_editorView splitView] setAllBackgroundColorWithAlpha:theAlpha];
    } else {
        [[_windowController window] setBackgroundColor:[NSColor windowBackgroundColor]]; // 通常の背景色をセット
        [[_windowController window] setOpaque:YES]; // ウィンドウを不透明にする
        [[_windowController window] setAlphaValue:theAlpha];
        [[_editorView splitView] setAllBackgroundColorWithAlpha:1.0];
    }
}


// ------------------------------------------------------
- (void)setAlphaOnlyTextViewInThisWindow:(BOOL)inBool
// TextView のみを透過するかどうかを保持
// ------------------------------------------------------
{
    _alphaOnlyTextViewInThisWindow = inBool;
}


// ------------------------------------------------------
- (void)setAlphaToWindowAndTextView
// ウィンドウの透明度を変更する
// ------------------------------------------------------
{
    CGFloat theAlpha = [[CEDocumentController sharedDocumentController] windowAlphaControllerValue];

    [self setAlpha:theAlpha];
}


// ------------------------------------------------------
- (void)setAlphaToWindowAndTextViewDefaultValue
// ウィンドウの透明度にデフォルト値をセットする
// ------------------------------------------------------
{
    id theValues = [[NSUserDefaultsController sharedUserDefaultsController] values];
    CGFloat theAlpha = [[theValues valueForKey:k_key_windowAlpha] floatValue];

    [self setAlpha:theAlpha];
}


// ------------------------------------------------------
- (void)setAlphaValueToTransparencyController
// 透明度設定パネルに値をセット
// ------------------------------------------------------
{
    CGFloat theAlpha = [self alpha];

    NSMutableDictionary *outDict = [NSMutableDictionary dictionaryWithObjectsAndKeys:
            @(theAlpha), k_key_curWindowAlpha, 
            @([self alphaOnlyTextViewInThisWindow]), k_key_curAlphaOnlyTextView, 
            nil];
    [[CEDocumentController sharedDocumentController] setWindowAlphaControllerDictionary:outDict];
}


// ------------------------------------------------------
- (NSAppleEventDescriptor *)fileSender
// ODB Editor Suite 対応メソッド。ファイルクライアントのシグネチャを返す。
// ------------------------------------------------------
{
    return _fileSender;
}


// ------------------------------------------------------
- (void)setFileSender:(NSAppleEventDescriptor *)inFileSender
// ODB Editor Suite 対応メソッド。ファイルクライアントのシグネチャをセット。
// ------------------------------------------------------
{
    [inFileSender retain];
    [_fileSender release];
    _fileSender = inFileSender;
}


// ------------------------------------------------------
- (NSAppleEventDescriptor *)fileToken
// ODB Editor Suite 対応メソッド。ファイルクライアントの追加文字列を返す。
// ------------------------------------------------------
{
    return _fileToken;
}


// ------------------------------------------------------
- (void)setFileToken:(NSAppleEventDescriptor *)inFileToken
// ODB Editor Suite 対応メソッド。ファイルクライアントの追加文字列をセット。
// ------------------------------------------------------
{
    [inFileToken retain];
    [_fileToken release];
    _fileToken = inFileToken;
}


// ------------------------------------------------------
- (NSRange)rangeInTextViewWithLocation:(NSInteger)inLocation withLength:(NSInteger)inLength
// マイナス指定された文字範囲／長さをNSRangeにコンバートして返す
// ------------------------------------------------------
{
    CETextViewCore *theTextView = [_editorView textView];
    NSUInteger theWholeLength = [[theTextView string] length];
    NSInteger theLocation, theLength;
    NSRange outRange = NSMakeRange(0, 0);

    theLocation = (inLocation < 0) ? (theWholeLength + inLocation) : inLocation;
    theLength = (inLength < 0) ? (theWholeLength - theLocation + inLength) : inLength;
    if ((theLocation < theWholeLength) && ((theLocation + theLength) > theWholeLength)) {
        theLength = theWholeLength - theLocation;
    }
    if ((inLength < 0) && (theLength < 0)) {
        theLength = 0;
    }
    if ((theLocation < 0) || (theLength < 0)) {
        return outRange;
    }
    outRange = NSMakeRange(theLocation, theLength);
    if (theWholeLength >= NSMaxRange(outRange)) {
        return outRange;
    }
    return outRange;
}


// ------------------------------------------------------
- (void)setSelectedCharacterRangeInTextViewWithLocation:(NSInteger)inLocation withLength:(NSInteger)inLength
// editorView 内部の textView で指定された部分を文字単位で選択
// ------------------------------------------------------
{
    NSRange theSelectionRange = [self rangeInTextViewWithLocation:inLocation withLength:inLength];

    [_editorView setSelectedRange:theSelectionRange];
}


// ------------------------------------------------------
- (void)setSelectedLineRangeInTextViewWithLocation:(NSInteger)inLocation withLength:(NSInteger)inLength
// editorView 内部の textView で指定された部分を行単位で選択
// ------------------------------------------------------
{
    CETextViewCore *theTextView = [_editorView textView];
    NSUInteger theWholeLength = [[theTextView string] length];
    OGRegularExpression *regex = [OGRegularExpression regularExpressionWithString:@"^"];
    NSArray *theArray = [regex allMatchesInString:[theTextView string]];

    if (theArray) {
        NSInteger theCount = [theArray count];
        if (inLocation == 0) {
            [theTextView setSelectedRange:NSMakeRange(0, 0)];
        } else if (inLocation > theCount) {
            [theTextView setSelectedRange:NSMakeRange(theWholeLength, 0)];
        } else {
            NSInteger theLocation, theLength;

            theLocation = (inLocation < 0) ? (theCount + inLocation + 1) : inLocation;
            if (inLength < 0) {
                theLength = theCount - theLocation + inLength + 1;
            } else if (inLength == 0) {
                theLength = 1;
            } else {
                theLength = inLength;
            }
            if ((theLocation < theCount) && ((theLocation + theLength - 1) > theCount)) {
                theLength = theCount - theLocation + 1;
            }
            if ((inLength < 0) && (theLength < 0)) {
                theLength = 1;
            }
            if ((theLocation <= 0) || (theLength <= 0)) { return; }

            OGRegularExpressionMatch *theMatch = theArray[(theLocation - 1)];
            NSRange theRange = [theMatch rangeOfMatchedString];
            NSRange theTmpRange = theRange;
            NSInteger i;

            for (i = 0; i < theLength; i++) {
                if (NSMaxRange(theTmpRange) > theWholeLength) {
                    break;
                }
                theRange = [[theTextView string] lineRangeForRange:theTmpRange];
                theTmpRange.length = theRange.length + 1;
            }
            if (theWholeLength < NSMaxRange(theRange)) {
                theRange.length = theWholeLength - theRange.location;
            }
            [theTextView setSelectedRange:theRange];
        }
    }
}


// ------------------------------------------------------
- (void)scrollToCenteringSelection
// 選択範囲が見えるようにスクロール
// ------------------------------------------------------
{
    [[_editorView textView] scrollRangeToVisible:[[_editorView textView] selectedRange]];
}


// ------------------------------------------------------
- (void)gotoLocation:(NSInteger)inLocation withLength:(NSInteger)inLength
// 選択範囲を変更する
// ------------------------------------------------------
{
    id theValues = [[NSUserDefaultsController sharedUserDefaultsController] values];
    NSInteger theIndex = [[theValues valueForKey:k_key_gotoObjectMenuIndex] integerValue];

    if (theIndex == k_gotoCharacterIndex) {
        [self setSelectedCharacterRangeInTextViewWithLocation:inLocation withLength:inLength];
    } else if (theIndex == k_gotoLineIndex) {
        [self setSelectedLineRangeInTextViewWithLocation:inLocation withLength:inLength];
    }
    [self scrollToCenteringSelection]; // 選択範囲が見えるようにスクロール
    [[_editorView textView] showFindIndicatorForRange:[[_editorView textView] selectedRange]];  // 検索結果表示エフェクトを追加
    [[_windowController window] makeKeyAndOrderFront:self]; // 対象ウィンドウをキーに
}


// ------------------------------------------------------
- (void)getFileAttributes
// ファイル情報辞書を保持
// ------------------------------------------------------
{
    NSFileManager *theFileManager = [NSFileManager defaultManager];
    NSDictionary *theAttr = [theFileManager attributesOfItemAtPath:[[[self fileURL] URLByResolvingSymlinksInPath] path] error:nil];
    
    if (theAttr) {
        [theAttr retain];
        [_fileAttr release];
        _fileAttr = theAttr;
        [_windowController updateFileAttrsInformation];
    }
}


// ------------------------------------------------------
- (NSDictionary *)documentFileAttributes
// ファイル属性情報辞書を返す
// ------------------------------------------------------
{
    return _fileAttr;
}


// ------------------------------------------------------
- (void)rebuildToolbarEncodingItem
// toolbar のエンコーディングメニューアイテムを再生成する
// ------------------------------------------------------
{
    [[_windowController toolbarController] buildEncodingPopupButton];
    [[_windowController toolbarController] setSelectEncoding:_encoding];
}


// ------------------------------------------------------
- (void)rebuildToolbarSyntaxItem
// toolbar のシンタックスカラーリングメニューアイテムを再生成する
// ------------------------------------------------------
{
    NSString *theTitle = [[_windowController toolbarController] selectedTitleOfSyntaxItem];

    [[_windowController toolbarController] buildSyntaxPopupButton];
    [[_windowController toolbarController] setSelectSyntaxItemWithTitle:theTitle];
}


// ------------------------------------------------------
- (void)setRecolorFlagToWindowControllerWithStyleName:(NSDictionary *)inDictionary
// 指定されたスタイルを適用していたら、WindowController のリカラーフラグを立てる
// ------------------------------------------------------
{
    NSString *theOldName = inDictionary[k_key_oldStyleName];
    NSString *theNewName = inDictionary[k_key_newStyleName];
    NSString *theCurStyleName = [_editorView syntaxStyleNameToColoring];

    if ([theOldName isEqualToString:theCurStyleName]) {
        if ((theOldName != nil) && (theNewName != nil) && (![theOldName isEqualToString:theNewName])) {
            [_editorView setSyntaxStyleNameToColoring:theNewName recolorNow:NO];
        }
        [_windowController setRecolorWithBecomeKey:YES];
    }
}


// ------------------------------------------------------
- (void)setStyleToNoneAndRecolorFlagWithStyleName:(NSString *)inStyleName
// 指定されたスタイルを適用していたら WindowController のリカラーフラグを立て、スタイル名を"None"にする
// ------------------------------------------------------
{
    NSString *theCurStyleName = [_editorView syntaxStyleNameToColoring];

    // 指定されたスタイル名と違ったら、無視
    if ([theCurStyleName isEqualToString:inStyleName]) {
        [_windowController setRecolorWithBecomeKey:YES];
        [_editorView setSyntaxStyleNameToColoring:NSLocalizedString(@"None",@"") recolorNow:NO];
    }
}


// ------------------------------------------------------
- (BOOL)doCascadeWindow
// ウィンドウをカスケード表示するかどうかを返す
// ------------------------------------------------------
{
    return _doCascadeWindow;
}


// ------------------------------------------------------
- (void)setDoCascadeWindow:(BOOL)inBool
// ウィンドウをカスケード表示するかどうかをセット
// ------------------------------------------------------
{
    _doCascadeWindow = inBool;
}


// ------------------------------------------------------
- (NSPoint)initTopLeftPoint
// カスケードしないときのウィンドウ左上のポイントを返す
// ------------------------------------------------------
{
    return _initTopLeftPoint;
}


// ------------------------------------------------------
- (void)setInitTopLeftPoint:(NSPoint)inPoint
// カスケードしないときのウィンドウ左上のポイントをセット
// ------------------------------------------------------
{
    _initTopLeftPoint = inPoint;
}


// ------------------------------------------------------
- (void)setSmartInsertAndDeleteToTextView
// スマートインサート／デリートをするかどうかをテキストビューへ設定
// ------------------------------------------------------
{
    id theValues = [[NSUserDefaultsController sharedUserDefaultsController] values];

    [[_editorView textView] setSmartInsertDeleteEnabled:
            [[theValues valueForKey:k_key_smartInsertAndDelete] boolValue]];
}


// ------------------------------------------------------
- (NSString *)currentIANACharSetName
// 設定されたエンコーディングの IANA Charset 名を返す
// ------------------------------------------------------
{
    NSString *outString = nil;
    CFStringEncoding theCFEncoding = CFStringConvertNSStringEncodingToEncoding(_encoding);

    if (theCFEncoding != kCFStringEncodingInvalidId) {
        outString = (NSString *)CFStringConvertEncodingToIANACharSetName(theCFEncoding);
    }
    return outString;
}


// ------------------------------------------------------
- (void)showUpdatedByExternalProcessAlert
// 外部プロセスによって更新されたことをシート／ダイアログで通知
// ------------------------------------------------------
{
    if (!_showUpdateAlertWithBecomeKey) { return; } // 表示フラグが立っていなければ、もどる

    NSAlert *theAleart;
    NSString *theDefaultTitle, *theInfoText;

    if ([self isDocumentEdited]) {
        theDefaultTitle = NSLocalizedString(@"Keep CotEditor Edition",@"");
        theInfoText = NSLocalizedString(@"The file has been modified by another process.\nThere are also unsaved changes in CotEditor.\n\nDo you want to keep CotEditor Edition or Update to the modified edition?\n",@"");
    } else {
        theDefaultTitle = NSLocalizedString(@"Keep unchanged",@"");
        theInfoText = NSLocalizedString(@"The file has been modified by another process.\n\nDo you want to keep unchanged or Update to the modified edition?\n",@"");
        [self updateChangeCount:NSChangeDone]; // ダーティーフラグを立てる
    }
    theAleart = [NSAlert alertWithMessageText:NSLocalizedString(@"Warning",@"") 
                defaultButton:theDefaultTitle 
                alternateButton:NSLocalizedString(@"Update",@"") 
                otherButton:nil 
                informativeTextWithFormat:theInfoText, nil];

    // シートが表示中でなければ、表示
    if ([[_editorView window] attachedSheet] == nil) {
        _isRevertingForExternalFileUpdate = YES;
        [[_editorView window] orderFront:nil]; // 後ろにあるウィンドウにシートを表示させると不安定になることへの対策
        [theAleart beginSheetModalForWindow:[_editorView window] 
                    modalDelegate:self 
                    didEndSelector:@selector(alertForModByAnotherProcessDidEnd:returnCode:contextInfo:) 
                    contextInfo:NULL];

    } else if (_isRevertingForExternalFileUpdate) {
        // （同じ外部プロセスによる変更通知アラートシートを表示中の時は、なにもしない）

    // 既にシートが出ている時はダイアログで表示
    } else {
        _isRevertingForExternalFileUpdate = YES;
        [[_editorView window] orderFront:nil]; // 後ろにあるウィンドウにシートを表示させると不安定になることへの対策
        NSInteger theResult = [theAleart runModal]; // アラート表示
        [self alertForModByAnotherProcessDidEnd:theAleart returnCode:theResult contextInfo:NULL];
    }
}


// ------------------------------------------------------
- (CGFloat)lineSpacingInTextView
// テキストビューに設定されている行間値を返す
// ------------------------------------------------------
{
    return ([[_editorView textView] lineSpacing]);
}


// ------------------------------------------------------
- (void)setCustomLineSpacingToTextView:(CGFloat)inSpacing
// テキストビューにカスタム行間値をセットする
// ------------------------------------------------------
{
    CGFloat theSpacing;

    if (inSpacing < k_lineSpacingMin) {
        theSpacing = k_lineSpacingMin;
    } else if (inSpacing > k_lineSpacingMax) {
        theSpacing = k_lineSpacingMax;
    } else {
        theSpacing = inSpacing;
    }
    [[_editorView textView] setNewLineSpacingAndUpdate:theSpacing];
}


// ------------------------------------------------------
- (BOOL)canActivateShowInvisibleCharsItem
// 不可視文字表示メニュー／ツールバーアイテムを有効化できるかを返す
// ------------------------------------------------------
{
    return _canActivateShowInvisibleCharsItem;
}



#pragma mark ===== Protocol =====

//=======================================================
// NSMenuValidation Protocol
//
//=======================================================

// ------------------------------------------------------
- (BOOL)validateMenuItem:(NSMenuItem *)inMenuItem
// メニュー項目の有効・無効を制御
// ------------------------------------------------------
{
    NSInteger theState = NSOffState;
    NSString *theName;

    if ([inMenuItem action] == @selector(saveDocument:)) {
        // 書き込み不可の時は、アラートが表示され「OK」されるまで保存メニューを無効化する
        if ((![_editorView isWritable]) && (![_editorView isAlertedNotWritable])) {
            return NO;
        }
    } else if ([inMenuItem action] == @selector(selectPrevItemOfOutlineMenu:)) {
        return ([[_editorView navigationBar] canSelectPrevItem]);
    } else if ([inMenuItem action] == @selector(selectNextItemOfOutlineMenu:)) {
        return ([[_editorView navigationBar] canSelectNextItem]);
    } else if ([inMenuItem action] == @selector(setEncoding:)) {
        theState = ([inMenuItem tag] == _encoding) ? NSOnState : NSOffState;
    } else if (([inMenuItem action] == @selector(setLineEndingCharToLF:)) || 
            ([inMenuItem action] == @selector(setLineEndingCharToCR:)) || 
            ([inMenuItem action] == @selector(setLineEndingCharToCRLF:))) {
        theState = ([inMenuItem tag] == [_editorView lineEndingCharacter]) ? NSOnState : NSOffState;
    } else if ([inMenuItem action] == @selector(setSyntaxStyle:)) {
        theName = [_editorView syntaxStyleNameToColoring];
        if (theName && [[inMenuItem title] isEqualToString:theName]) {
            theState = NSOnState;
        }
    } else if ([inMenuItem action] == @selector(recoloringAllStringOfDocument:)) {
        theName = [_editorView syntaxStyleNameToColoring];
        if (theName && [theName isEqualToString:NSLocalizedString(@"None",@"")]) {
            return NO;
        }
    }
    [inMenuItem setState:theState];

    return [super validateMenuItem:inMenuItem];
}



//=======================================================
// NSToolbarItemValidation Protocol
//
//=======================================================

// ------------------------------------------------------
-(BOOL)validateToolbarItem:(NSToolbarItem *)inToolbarItem
// ツールバー項目の有効・無効を制御
// ------------------------------------------------------
{
    if ([[inToolbarItem itemIdentifier] isEqualToString:k_syntaxReColorAllItemID]) {
        NSString *theName = [_editorView syntaxStyleNameToColoring];
        if (theName && [theName isEqualToString:NSLocalizedString(@"None",@"")]) {
            return NO;
        }
    }
    return YES;
}



#pragma mark === Delegate and Notification ===

//=======================================================
// Delegate method (VDKQueue)
//  <== VDKQueue
//=======================================================

// ------------------------------------------------------
- (void)VDKQueue:(VDKQueue *)queue receivedNotification:(NSString *)noteName forPath:(NSString *)fpath
// VDKQueue からファイル変更に関する通知を受信
// ------------------------------------------------------
{
    if ([noteName isEqualToString:VDKQueueWriteNotification]) {
        [self fileWritten:fpath];
        
    } else if ([noteName isEqualToString:VDKQueueDeleteNotification]) {
        [self fileDeleted:fpath];
    }
}


// ------------------------------------------------------
- (void)fileWritten:(NSString *)filePath
// いま開いているファイルが外部プロセスによって上書き保存された
// ------------------------------------------------------
{
    // 自分が保存中でないなら、書き込み通知を行う
    if ([self numberOfSavingFlags] == 0) {
        id theValues = [[NSUserDefaultsController sharedUserDefaultsController] values];

        _showUpdateAlertWithBecomeKey = YES;
        // アプリがアクティブならシート／ダイアログを表示し、そうでなければ設定を見てDockアイコンをジャンプ
        if ([NSApp isActive]) {
            [self showUpdatedByExternalProcessAlert];
        } else if ([[theValues valueForKey:k_key_notifyEditByAnother] boolValue]) {
            NSInteger theRequestID = [NSApp requestUserAttention:NSInformationalRequest];
            // Dockアイコンジャンプを中止（本来なくてもいいはずだが10.4.3ではジャンプし続けるため、実行）
            [NSApp cancelUserAttentionRequest:theRequestID];
        }
    }
}


// ------------------------------------------------------
- (void)fileDeleted:(NSString *)filePath
// いま開いているファイルが外部プロセスによって削除された
// ------------------------------------------------------
{
    // VDKQueue から一旦パスを削除
    [[self fileObserver] removeAllPaths];
    
    // Cocoa アプリで標準的に使われる置き換え保存かどうかを確認する
    if ([[self fileURL] checkResourceIsReachableAndReturnError:nil]) {
        // 置き換え保存なら、上書き保存と同じ処理後、VDKQueue に再登録
        [self fileWritten:[[self fileURL] path]];
        [self startWatchFile:[[self fileURL] path]];
    }
}


//=======================================================
// Notification method (CESplitView)
//  <== CESplitView
//=======================================================


// ------------------------------------------------------
- (void)documentDidFinishOpen:(NSNotification *)inNotification
// 書類オープン処理が完了した
// ------------------------------------------------------
{
    if ([inNotification object] != _editorView) { return; }

    [self showAlertForNotWritable];
}



#pragma mark ===== Action messages =====

//=======================================================
// Action messages
//
//=======================================================

// ------------------------------------------------------
- (IBAction)saveDocument:(id)sender
// 保存
// ------------------------------------------------------
{
    if (![self acceptSaveDocumentWithIANACharSetName]) { return; }
    if (![self acceptSaveDocumentToConvertEncoding]) { return; }
    [super saveDocument:sender];
}


// ------------------------------------------------------
- (IBAction)saveDocumentAs:(id)sender
// 別名で保存
// ------------------------------------------------------
{
    if (![self acceptSaveDocumentWithIANACharSetName]) { return; }
    if (![self acceptSaveDocumentToConvertEncoding]) { return; }
    [super saveDocumentAs:sender];
}


// ------------------------------------------------------
- (IBAction)printDocument:(id)sender
// プリント
// ------------------------------------------------------
{
// このメソッドは、Smultron を参考にさせていただきました。(2005.12.17)
// This method is based on Smultron.(written by Peter Borg – http://smultron.sourceforge.net)
// Smultron  Copyright (c) 2004-2005 Peter Borg, All rights reserved.
// Smultron is released under GNU General Public License, http://www.gnu.org/copyleft/gpl.html

    NSPrintPanel *thePrintPanel = [NSPrintPanel printPanel];

    [thePrintPanel setAccessoryView:[_windowController printAccessoryView]];
    [thePrintPanel beginSheetWithPrintInfo:[self printInfo] 
                modalForWindow:[_editorView window] 
                delegate:self didEndSelector:@selector(printPanelDidEnd:returnCode:contextInfo:) 
                contextInfo:NULL];
}


// ------------------------------------------------------
- (IBAction)setLineEndingCharToLF:(id)sender
// ドキュメントに新しい行末コードをセットする
// ------------------------------------------------------
{
    [self setLineEndingChar:sender];
}


// ------------------------------------------------------
- (IBAction)setLineEndingCharToCR:(id)sender
// ドキュメントに新しい行末コードをセットする
// ------------------------------------------------------
{
    [self setLineEndingChar:sender];
}


// ------------------------------------------------------
- (IBAction)setLineEndingCharToCRLF:(id)sender
// ドキュメントに新しい行末コードをセットする
// ------------------------------------------------------
{
    [self setLineEndingChar:sender];
}


// ------------------------------------------------------
- (IBAction)setLineEndingChar:(id)sender
// ドキュメントに新しい行末コードをセットする
// ------------------------------------------------------
{
    [self doSetNewLineEndingCharacterCode:[sender tag]];
}


// ------------------------------------------------------
- (IBAction)setEncoding:(id)sender
// ドキュメントに新しいエンコーディングをセットする
// ------------------------------------------------------
{
    NSStringEncoding theEncoding = [sender tag];

    if ((theEncoding < 1) || (theEncoding == _encoding)) {
        return;
    }
    NSInteger theResult;
    NSString *theEncodingName = [sender title];

    // 文字列がないまたは未保存の時は直ちに変換プロセスへ
    if (([[_editorView string] length] < 1) || (![self fileURL])) {
        theResult = NSAlertDefaultReturn;
    } else {
        // 変換するか再解釈するかの選択ダイアログを表示
        NSAlert *theAleart = [NSAlert alertWithMessageText:NSLocalizedString(@"File Encoding",@"") 
                    defaultButton:NSLocalizedString(@"Convert",@"") 
                    alternateButton:NSLocalizedString(@"Reinterpret",@"") 
                    otherButton:NSLocalizedString(@"Cancel",@"") 
                    informativeTextWithFormat:NSLocalizedString(@"Do you want to convert or reinterpret using \"%@\"?\n",@""), theEncodingName];

        theResult = [theAleart runModal];
    }
    if (theResult == NSAlertDefaultReturn) { // = Convert 変換

        NSString *theActionName = [NSString stringWithFormat:
                    NSLocalizedString(@"Encoding to \"%@\"",@""), 
                    [NSString localizedNameOfStringEncoding:theEncoding]];

        (void)[self doSetEncoding:theEncoding updateDocument:YES askLossy:YES 
                    lossy:NO asActionName:theActionName];

    } else if (theResult == NSAlertAlternateReturn) { // = Reinterpret 再解釈

        if (![self fileURL]) { return; } // まだファイル保存されていない時（ファイルがない時）は、戻る
        if ([self isDocumentEdited]) {
            NSAlert *theSecondAleart = [NSAlert alertWithMessageText:NSLocalizedString(@"Warning",@"") 
                        defaultButton:NSLocalizedString(@"Cancel",@"") 
                        alternateButton:NSLocalizedString(@"Discard Changes",@"") 
                        otherButton:nil 
                        informativeTextWithFormat:
                            NSLocalizedString(@"The file \'%@\' has unsaved changes. \n\nDo you want to discard the changes and reset the file encodidng?\n",@""), [[self fileURL] path]];

            NSInteger theSecondResult = [theSecondAleart runModal];
            if (theSecondResult != NSAlertAlternateReturn) { // != Discard Change
                // ツールバーから変更された場合のため、ツールバーアイテムの選択状態をリセット
                [[_windowController toolbarController] setSelectEncoding:_encoding];
                return;
            }
        }
        if ([self readFromFile:[[self fileURL] path] withEncoding:theEncoding]) {
            [self setStringToEditorView];
            // アンドゥ履歴をクリア
            [[self undoManager] removeAllActions];
            [self updateChangeCount:NSChangeCleared];
        } else {
            NSAlert *theThirdAleart = [NSAlert alertWithMessageText:NSLocalizedString(@"Can Not reinterpret",@"") 
                        defaultButton:NSLocalizedString(@"Done",@"") 
                        alternateButton:nil 
                        otherButton:nil 
                        informativeTextWithFormat:NSLocalizedString(@"Sorry, the file \'%@\' could not reinterpret in the new encoding \"%@\".",@""), [[self fileURL] path], theEncodingName];
            [theThirdAleart setAlertStyle:NSCriticalAlertStyle];

            NSBeep();
            (void)[theThirdAleart runModal];
        }
    }
    // ツールバーから変更された場合のため、ツールバーアイテムの選択状態をリセット
    [[_windowController toolbarController] setSelectEncoding:_encoding];
}


// ------------------------------------------------------
- (IBAction)setSyntaxStyle:(id)sender
// 新しいシンタックスカラーリングスタイルを適用
// ------------------------------------------------------
{
    NSString *theName = [sender title];

    if ((theName != nil) && ([theName length] > 0)) {
        [self doSetSyntaxStyle:theName];
    }
}


// ------------------------------------------------------
- (IBAction)recoloringAllStringOfDocument:(id)sender
// ドキュメント全体を再カラーリング
// ------------------------------------------------------
{
    [_editorView recoloringAllString];
}


// ------------------------------------------------------
- (IBAction)setWindowAlpha:(id)sender
// ウィンドウの透明度を設定
// ------------------------------------------------------
{
    CGFloat theAlpha = [sender floatValue];
    
    [self setAlpha:theAlpha];
}


// ------------------------------------------------------
- (IBAction)setTransparencyOnlyTextView:(id)sender
// 透明度を textView だけに設定するかどうかをセット
// ------------------------------------------------------
{
    [self setAlphaOnlyTextViewInThisWindow:([sender state] == NSOnState)];
    [self setAlphaToWindowAndTextView];
}


// ------------------------------------------------------
- (IBAction)insertIANACharSetName:(id)sender
// IANA文字コード名を挿入する
// ------------------------------------------------------
{
    NSString *theString = [self currentIANACharSetName];

    if (theString != nil) {
        [[_editorView textView] insertText:theString];
    }
}


// ------------------------------------------------------
- (IBAction)insertIANACharSetNameWithCharset:(id)sender
// IANA文字コード名を挿入する
// ------------------------------------------------------
{
    NSString *theString = [self currentIANACharSetName];

    if (theString != nil) {
        [[_editorView textView] insertText:[NSString stringWithFormat:@"charset=\"%@\"", theString]];
    }
}


// ------------------------------------------------------
- (IBAction)insertIANACharSetNameWithEncoding:(id)sender
// IANA文字コード名を挿入する
// ------------------------------------------------------
{
    NSString *theString = [self currentIANACharSetName];

    if (theString != nil) {
        [[_editorView textView] insertText:[NSString stringWithFormat:@"encoding=\"%@\"", theString]];
    }
}


// ------------------------------------------------------
- (IBAction)selectPrevItemOfOutlineMenu:(id)sender
// アウトラインメニューの前の項目を選択（メニューバーからのアクションを中継）
// ------------------------------------------------------
{
    [[_editorView navigationBar] selectPrevItem];
}


// ------------------------------------------------------
- (IBAction)selectNextItemOfOutlineMenu:(id)sender
// アウトラインメニューの次の項目を選択（メニューバーからのアクションを中継）
// ------------------------------------------------------
{
    [[_editorView navigationBar] selectNextItem];
}




#pragma mark -
#pragma mark Private

//=======================================================
// Private method
//
//=======================================================

// ------------------------------------------------------
- (NSString *)convertedCharacterString:(NSString *)inString withEncoding:(NSStringEncoding)inEncoding
// 半角円マークを使えないエンコードの時はバックスラッシュに変換した文字列を返す
// ------------------------------------------------------
{
    NSUInteger theLength = [inString length];

    if (theLength > 0) {
        NSMutableString *outString = [inString mutableCopy]; // ===== mutableCopy
        if ([[NSApp delegate] isInvalidYenEncoding:inEncoding]) {
            (void)[outString replaceOccurrencesOfString:
                        [NSString stringWithCharacters:&k_yenMark length:1] withString:@"\\" 
                        options:0 range:NSMakeRange(0, theLength)];
        }
        return [outString autorelease]; // autorelease
    } else {
        return inString;
    }
}


// ------------------------------------------------------
- (void)doSetEncoding:(NSStringEncoding)inEncoding
// エンコード値を保存
// ------------------------------------------------------
{
    _encoding = inEncoding;
    // ツールバーのエンコーディングメニュー、ステータスバー、ドローワを更新
    [self updateEncodingInToolbarAndInfo];
}


// ------------------------------------------------------
- (void)updateEncodingInToolbarAndInfo
// ツールバーのエンコーディングメニュー、ステータスバー、ドローワを更新
// ------------------------------------------------------
{
    // ツールバーのエンコーディングメニューを更新
    [[_windowController toolbarController] setSelectEncoding:_encoding];
    // ステータスバー、ドローワを更新
    [_editorView updateLineEndingsInStatusAndInfo:NO];
}


// ------------------------------------------------------
- (BOOL)readFromFile:(NSString *)inFileName withEncoding:(NSStringEncoding)inEncoding
// ファイルを読み込み、成功したかどうかを返す
// ------------------------------------------------------
{
    NSData *theData = nil;

    // "authopen"コマンドを使って読み込む
    NSString *theConvertedPath = @([inFileName UTF8String]);
    NSTask *theTask = [[[NSTask alloc] init] autorelease];
    NSInteger status;

    [theTask setLaunchPath:@"/usr/libexec/authopen"];
    [theTask setArguments:@[theConvertedPath]];
    [theTask setStandardOutput:[NSPipe pipe]];

    [theTask launch];
    theData = [NSData dataWithData:[[[theTask standardOutput] fileHandleForReading] readDataToEndOfFile]];
    [theTask waitUntilExit];

    status = [theTask terminationStatus];
    if (status != 0) {
        return NO;
    }
    if (theData == nil) {
        // オープンダイアログでのエラーアラートは CEDocumentController > openDocument: で表示する
        // アプリアイコンへのファイルドロップでのエラーアラートは NSDocumentController (NSApp ?) 内部で表示される
        // 復帰時は NSDocument 内部で表示
        return NO;
    }

    BOOL outResult = NO;
    BOOL theBoolEA = NO;
    NSStringEncoding theEncoding = inEncoding;

    if (inEncoding == k_autoDetectEncodingMenuTag) {
        // ファイル拡張属性(com.apple.TextEncoding)からエンコーディング値を得る（10.5+）
        // （10.5未満ではNSProprietaryStringEncodingが返ってくる）
        theEncoding = [self encodingFromComAppleTextEncodingAtPath:inFileName];
        if ([theData length] == 0) {
            outResult = YES;
            _initialString = [[NSMutableString string] retain]; // ===== retain
            // (_initialString はあとで開放 == "- (NSString *)stringToWindowController".)
        }
        if (theEncoding != NSProprietaryStringEncoding) {
            if ([theData length] == 0) {
                (void)[self doSetEncoding:theEncoding updateDocument:NO askLossy:NO lossy:NO asActionName:nil];
            } else {
                theBoolEA = YES;
            }
        } else {
            theEncoding = inEncoding;
        }
    }
    if (!outResult) {
        outResult = [self stringFromData:theData encoding:theEncoding xattr:theBoolEA];
    }
    if (outResult) {
        // 外部プロセスによる変更監視を開始
        [self startWatchFile:inFileName];
        // 保持しているファイル情報／表示する文書情報を更新
        [self getFileAttributes];
    }
    return outResult;
}


// ------------------------------------------------------
- (NSStringEncoding)scannedCharsetOrEncodingFromString:(NSString *)inString
// "charset=" "encoding="タグからエンコーディング定義を読み取る
// ------------------------------------------------------
{
// このメソッドは、Smultron を参考にさせていただきました。(2005.08.10)
// This method is based on Smultron.(written by Peter Borg – http://smultron.sourceforge.net)
// Smultron  Copyright (c) 2004-2005 Peter Borg, All rights reserved.
// Smultron is released under GNU General Public License, http://www.gnu.org/copyleft/gpl.html

    id theValues = [[NSUserDefaultsController sharedUserDefaultsController] values];

    NSStringEncoding outEncoding = NSProprietaryStringEncoding;
    if ((![[theValues valueForKey:k_key_referToEncodingTag] boolValue]) || ([inString length] < 9)) {
        return outEncoding; // 参照しない設定になっているか、含まれている余地が無ければ中断
    }
    NSScanner *theScanner = [NSScanner scannerWithString:inString];
    NSCharacterSet *theStopSet = [NSCharacterSet characterSetWithCharactersInString:@"\"\' </>\n\r"];
    NSString *theScannedStr = nil;

    [theScanner setCharactersToBeSkipped:[NSCharacterSet characterSetWithCharactersInString:@"\"\' "]];
    // "charset="を探す
    while (![theScanner isAtEnd]) {
        (void)[theScanner scanUpToString:@"charset=" intoString:nil];
        if ([theScanner scanString:@"charset=" intoString:nil]) {
            if ([theScanner scanUpToCharactersFromSet:theStopSet intoString:&theScannedStr]) {
                break;
            }
        }
    }
    // "charset="が見つからなければ、"encoding="を探す
    if (theScannedStr == nil) {
        [theScanner setScanLocation:0];
        while (![theScanner isAtEnd]) {
            (void)[theScanner scanUpToString:@"encoding=" intoString:nil];
            if ([theScanner scanString:@"encoding=" intoString:nil]) {
                if ([theScanner scanUpToCharactersFromSet:theStopSet intoString:&theScannedStr]) {
                    break;
                }
            }
        }
    }
    // 見つからなければ、"@charset"を探す
    if (theScannedStr == nil) {
        [theScanner setScanLocation:0];
        while (![theScanner isAtEnd]) {
            (void)[theScanner scanUpToString:@"@charset" intoString:nil];
            if ([theScanner scanString:@"@charset" intoString:nil]) {
                if ([theScanner scanUpToCharactersFromSet:theStopSet intoString:&theScannedStr]) {
                    break;
                }
            }
        }
    }
    // 見つかったら NSStringEncoding に変換して返す
    if (theScannedStr != nil) {
        CFStringEncoding theCFEncoding = kCFStringEncodingInvalidId;
        // "Shift_JIS"だったら、kCFStringEncodingShiftJIS と kCFStringEncodingShiftJIS_X0213_00 の
        // 優先順位の高いものを取得する
        if ([[theScannedStr uppercaseString] isEqualToString:@"SHIFT_JIS"]) {
            // （theScannedStr をそのまま CFStringConvertIANACharSetNameToEncoding() で変換すると、大文字小文字を問わず
            // 「日本語（Shift JIS）」になってしまうため。IANA では大文字小文字を区別しないとしているのでこれはいいのだが、
            // CFStringConvertEncodingToIANACharSetName() では kCFStringEncodingShiftJIS と 
            // kCFStringEncodingShiftJIS_X0213_00 がそれぞれ「SHIFT_JIS」「shift_JIS」と変換されるため、可逆性を持たせる
            // ための処理）
            id theValues = [[NSUserDefaultsController sharedUserDefaultsController] values];
            NSArray *theEncodings = [[[theValues valueForKey:k_key_encodingList] copy] autorelease];
            CFStringEncoding theTmpCFEncoding;

            for (NSNumber *encoding in theEncodings) {
                theTmpCFEncoding = [encoding unsignedLongValue];
                if ((theTmpCFEncoding == kCFStringEncodingShiftJIS) || 
                        (theTmpCFEncoding == kCFStringEncodingShiftJIS_X0213_00)) {
                    theCFEncoding = theTmpCFEncoding;
                    break;
                }
            }
        } else {
            // "Shift_JIS" 以外はそのまま変換する
            theCFEncoding = CFStringConvertIANACharSetNameToEncoding((CFStringRef)theScannedStr);
        }
        if (theCFEncoding != kCFStringEncodingInvalidId) {
            outEncoding = CFStringConvertEncodingToNSStringEncoding(theCFEncoding);
        }
    }
    return outEncoding;
}


// ------------------------------------------------------
- (void)redoSetEncoding:(NSStringEncoding)inEncoding updateDocument:(BOOL)inDocUpdate 
        askLossy:(BOOL)inAskLossy  lossy:(BOOL)inLossy  asActionName:(NSString *)inName
// エンコードを変更するアクションのRedo登録
// ------------------------------------------------------
{
    (void)[[[self undoManager] prepareWithInvocationTarget:self] 
            doSetEncoding:inEncoding updateDocument:inDocUpdate 
                askLossy:inAskLossy lossy:inLossy asActionName:inName];
}


// ------------------------------------------------------
- (void)redoSetNewLineEndingCharacterCode:(NSInteger)inNewLineEnding
// 行末コードを変更するアクションのRedo登録
// ------------------------------------------------------
{
    [[[self undoManager] prepareWithInvocationTarget:self] doSetNewLineEndingCharacterCode:inNewLineEnding];
}


// ------------------------------------------------------
- (NSDictionary *)myCreatorAndTypeCodeAttributes
// CotEditor のタイプとクリエータを返す
// ------------------------------------------------------
{
    NSDictionary *outDict = @{NSFileHFSCreatorCode: [NSNumber numberWithUnsignedLong:'cEd1'], 
                    NSFileHFSTypeCode: [NSNumber numberWithUnsignedLong:'TEXT']};
    return outDict;
}


// ------------------------------------------------------
- (BOOL)acceptSaveDocumentWithIANACharSetName
// IANA文字コード名を読み、設定されたエンコーディングと矛盾があれば警告する
// ------------------------------------------------------
{
    NSStringEncoding theIANACharSetEncoding = 
            [self scannedCharsetOrEncodingFromString:[_editorView stringForSave]];
    NSStringEncoding theShiftJIS = CFStringConvertEncodingToNSStringEncoding(kCFStringEncodingShiftJIS);
    NSStringEncoding theX0213 = CFStringConvertEncodingToNSStringEncoding(kCFStringEncodingShiftJIS_X0213_00);

    if ((theIANACharSetEncoding != NSProprietaryStringEncoding) && (theIANACharSetEncoding != _encoding) && 
            (!(((theIANACharSetEncoding == theShiftJIS) || (theIANACharSetEncoding == theX0213)) && 
            ((_encoding == theShiftJIS) || (_encoding == theX0213))))) {
            // （Shift-JIS の時は要注意 = scannedCharsetOrEncodingFromString: を参照）

        NSString *theIANANameStr = [NSString localizedNameOfStringEncoding:theIANACharSetEncoding];
        NSString *theEncodingNameStr = [NSString localizedNameOfStringEncoding:_encoding];
        NSAlert *theAleart = [NSAlert alertWithMessageText:NSLocalizedString(@"Save Warning",@"") 
                    defaultButton:NSLocalizedString(@"Cancel",@"") 
                    alternateButton:NSLocalizedString(@"Continue Saving",@"") 
                    otherButton:nil 
                    informativeTextWithFormat:NSLocalizedString(@"The encoding is  \"%@\", but the IANA charset name in text is \"%@\".\n\nDo you want to continue processing?\n",@""), theEncodingNameStr, theIANANameStr];

        NSInteger theResult = [theAleart runModal];
        if (theResult != NSAlertAlternateReturn) { // == Cancel
            return NO;
        }
    }
    return YES;
}


// ------------------------------------------------------
- (BOOL)acceptSaveDocumentToConvertEncoding
// ファイル保存前のエンコーディング変換チェック、ユーザに承認を求める
// ------------------------------------------------------
{
    // エンコーディングを見て、半角円マークを変換しておく
    NSString *theCurString = [self convertedCharacterString:[_editorView stringForSave] 
            withEncoding:_encoding];
    if (![theCurString canBeConvertedToEncoding:_encoding]) {
        NSString *theEncodingNameStr = [NSString localizedNameOfStringEncoding:_encoding];
        NSAlert *theAleart = [NSAlert alertWithMessageText:NSLocalizedString(@"Save Warning",@"") 
                    defaultButton:NSLocalizedString(@"Show Incompatible Char(s)",@"") 
                    alternateButton:NSLocalizedString(@"Save Available strings",@"") 
                    otherButton:NSLocalizedString(@"Cancel",@"") 
                    informativeTextWithFormat:NSLocalizedString(@"The characters would have to be changed or deleted in saving as \"%@\".\n\nDo you want to continue processing?\n",@""), theEncodingNameStr];

        NSInteger theResult = [theAleart runModal];
        if (theResult != NSAlertAlternateReturn) { // != Save
            if (theResult == NSAlertDefaultReturn) { // == show incompatible char
                [_windowController showIncompatibleCharList];
            }
            return NO;
        }
    }
    return YES;
}


// ------------------------------------------------------
- (BOOL)saveToFile:(NSString *)inFileName ofType:(NSString *)inDocType 
            saveOperation:(NSSaveOperationType)inSaveOperationType
// ファイル保存
// ------------------------------------------------------
{
    id theValues = [[NSUserDefaultsController sharedUserDefaultsController] values];
    // エンコーディングを見て、半角円マークを変換しておく
    NSString *theCurString = [self convertedCharacterString:[_editorView stringForSave] 
            withEncoding:_encoding];
    NSData *theData;
    BOOL outResult = NO;

    if ((_encoding == NSUTF8StringEncoding) && ([[theValues valueForKey:k_key_saveUTF8BOM] boolValue])) {
        // UTF-8 BOM追加 2008.12.13
        const char theUtf8Bom[] = {0xef, 0xbb, 0xbf}; // UTF-8 BOM
        NSMutableData *theMutableData1 = [NSMutableData dataWithBytes:theUtf8Bom length:3];
        [theMutableData1 appendData:[theCurString dataUsingEncoding:_encoding allowLossyConversion:YES]];
        theData = [NSData dataWithData:theMutableData1];
    } else {
        theData = [theCurString dataUsingEncoding:_encoding allowLossyConversion:YES];
    }
    if (theData != nil) {
        NSDictionary *theAttrs = [self fileAttributesToWriteToURL:[NSURL fileURLWithPath:inFileName]
                                                           ofType:inDocType
                                                 forSaveOperation:inSaveOperationType
                                              originalContentsURL:nil
                                                            error:nil];
        NSFileManager *theManager = [NSFileManager defaultManager];
        NSString *theConvertedPath = @([inFileName UTF8String]);
        NSInteger status;
        BOOL theFinderLockON = NO;

        if (![self canReleaseFinderLockOfFile:inFileName isLocked:&theFinderLockON lockAgain:NO]) {
            // ユーザがオーナーでないファイルに Finder Lock がかかっていたら編集／保存できない
            NSAlert *theAleart = [NSAlert alertWithMessageText:NSLocalizedString(@"Warning",@"") 
                        defaultButton:NSLocalizedString(@"OK",@"") 
                        alternateButton:nil 
                        otherButton:nil 
                        informativeTextWithFormat:
                            NSLocalizedString(@"Could Not be released Finder's Lock.\n\nYou can use \"Save As\" to save a copy.\n",@"")];
            [theAleart setAlertStyle:NSCriticalAlertStyle];
            (void)[theAleart runModal];
            return NO;
        }
        // "authopen"コマンドを使って保存
        NSTask *theTask = [[[NSTask alloc] init] autorelease];

        [theTask setLaunchPath:@"/usr/libexec/authopen"];
        [theTask setArguments:@[@"-c", @"-w", theConvertedPath]];
        [theTask setStandardInput:[NSPipe pipe]];

        [theTask launch];
        [[[theTask standardInput] fileHandleForWriting] writeData:theData];
        [[[theTask standardInput] fileHandleForWriting] closeFile];
        [theTask waitUntilExit];

        status = [theTask terminationStatus];
        outResult = (status == 0);

        // クリエータなどを設定
        [theManager setAttributes:theAttrs ofItemAtPath:inFileName error:nil];
        
        // ファイル拡張属性(com.apple.TextEncoding)にエンコーディングを保存（10.5+）
        [self setComAppleTextEncodingAtPath:inFileName];
        if (theFinderLockON) {
            // Finder Lock がかかってたなら、再びかける
            BOOL theBoolToGo = [theManager setAttributes:@{NSFileImmutable:@YES} ofItemAtPath:inFileName error:nil];
            outResult = (outResult && theBoolToGo);
        }
    }
    [self setIsWritableToEditorViewWithFileName:inFileName];
    return outResult;
}


// ------------------------------------------------------
- (void)sendModifiedEventToClientOfFile:(NSString *)inSaveAsPath 
        operation:(NSSaveOperationType)inSaveOperationType
// 外部エディタプロトコル(ODB Editor Suite)対応メソッド。ファイルクライアントにファイル更新を通知する。
// ------------------------------------------------------
{
// このメソッドは、Smultron を参考にさせていただきました。(2005.04.19)
// This method is based on Smultron.(written by Peter Borg – http://smultron.sourceforge.net)
// Smultron  Copyright (c) 2004-2005 Peter Borg, All rights reserved.
// Smultron is released under GNU General Public License, http://www.gnu.org/copyleft/gpl.html

    NSString *thePath = [[self fileURL] path];
    if (thePath == nil) { return; }
    OSType creatorCode = [_fileSender typeCodeValue];
    if (creatorCode == 0) { return; }

    NSAppleEventDescriptor *theCreator, *theAppleEvent, *theFileSSpec;
    AppleEvent *theAppleEventPointer;

    FSRef theRef, theSaveAsRef;
    FSSpec theFSSpec, theSaveAsFSSpec;
    OSStatus theOSStatus;
    OSErr theErr;

    theOSStatus = FSPathMakeRef((UInt8 *)[thePath UTF8String], &theRef, nil);
    if (theOSStatus != noErr) {
        NSLog(@"'kAEModifiedFile' theOSStatus is err. <%d>", theOSStatus);
        return;
    }
    theErr = FSGetCatalogInfo(&theRef, kFSCatInfoNone, NULL, NULL, &theFSSpec, NULL);
    if (theErr != noErr) {
        NSLog(@"'kAEModifiedFile' theErr is err. <%d>", theErr);
        return;
    }

    theCreator = [NSAppleEventDescriptor 
            descriptorWithDescriptorType:typeApplSignature bytes:&creatorCode length:sizeof(OSType)];
    theAppleEvent = [NSAppleEventDescriptor 
            appleEventWithEventClass:kODBEditorSuite eventID:kAEModifiedFile targetDescriptor:theCreator 
            returnID:kAutoGenerateReturnID transactionID:kAnyTransactionID];
    theFileSSpec = [NSAppleEventDescriptor 
            descriptorWithDescriptorType:typeFSS bytes:&theFSSpec length:sizeof(FSSpec)];
    [theAppleEvent setParamDescriptor:theFileSSpec forKeyword:keyDirectObject];
    
    if (_fileToken) {
        [theAppleEvent setParamDescriptor:_fileToken forKeyword:keySenderToken];
    }
    if (inSaveOperationType == NSSaveAsOperation) {
        theOSStatus = FSPathMakeRef((UInt8 *)[inSaveAsPath UTF8String], &theSaveAsRef, nil);
        theErr = FSGetCatalogInfo(&theSaveAsRef, kFSCatInfoNone, NULL, NULL, &theSaveAsFSSpec, NULL);
        if ((theOSStatus != noErr) || (theErr != noErr)) {
            NSLog(@"\"SaveAs\" err. \n'kAEModifiedFile' theOSStatus = <%d>\n'kAEModifiedFile' theErr = <%d>", theOSStatus, theErr);
            return;
        }
        [theCreator setParamDescriptor:
            [NSAppleEventDescriptor descriptorWithDescriptorType:typeFSS 
                bytes:&theSaveAsFSSpec length:sizeof(FSSpec)] forKeyword:keyNewLocation];
        [self setFileSender:nil];
    }
    
    theAppleEventPointer = (AEDesc *)[theAppleEvent aeDesc];
    if (theAppleEventPointer) {
        AESendMessage(theAppleEventPointer, NULL, kAENoReply, kAEDefaultTimeout);
    }
}


// ------------------------------------------------------
- (void)sendCloseEventToClient
// 外部エディタプロトコル(ODB Editor Suite)対応メソッド。ファイルクライアントにファイルクローズを通知する。
// ------------------------------------------------------
{
// このメソッドは、Smultron を参考にさせていただきました。(2005.04.19)
// This method is based on Smultron.(written by Peter Borg – http://smultron.sourceforge.net)
// Smultron  Copyright (c) 2004-2005 Peter Borg, All rights reserved.
// Smultron is released under GNU General Public License, http://www.gnu.org/copyleft/gpl.html

    NSString *thePath = [[self fileURL] path];
    if (thePath == nil) { return; }
    OSType creatorCode = [_fileSender typeCodeValue];
    if (creatorCode == 0) { return; }

    NSAppleEventDescriptor *theCreator, *theAppleEvent, *theFileSSpec;
    AppleEvent *theAppleEventPointer;

    FSRef theRef;
    FSSpec theFSSpec;
    OSStatus theOSStatus;
    OSErr theErr;

    theOSStatus = FSPathMakeRef((UInt8 *)[thePath UTF8String], &theRef, nil);
    if (theOSStatus != noErr) {
        NSLog(@"'kAEClosedFile' theOSStatus is err. <%d>", theOSStatus);
        return;
    }
    theErr = FSGetCatalogInfo(&theRef, kFSCatInfoNone, NULL, NULL, &theFSSpec, NULL);
    if (theErr != noErr) {
        NSLog(@"'kAEClosedFile' theErr is err. <%d>", theErr);
        return;
    }

    theCreator = [NSAppleEventDescriptor 
            descriptorWithDescriptorType:typeApplSignature bytes:&creatorCode length:sizeof(OSType)];
    theAppleEvent = [NSAppleEventDescriptor 
            appleEventWithEventClass:kODBEditorSuite eventID:kAEClosedFile targetDescriptor:theCreator 
            returnID:kAutoGenerateReturnID transactionID:kAnyTransactionID];
    theFileSSpec = [NSAppleEventDescriptor 
            descriptorWithDescriptorType:typeFSS bytes:&theFSSpec length:sizeof(FSSpec)];
    [theAppleEvent setParamDescriptor:theFileSSpec forKeyword:keyDirectObject];
    
    if (_fileToken) {
        [theAppleEvent setParamDescriptor:_fileToken forKeyword:keySenderToken];
    }
    
    theAppleEventPointer = (AEDesc *)[theAppleEvent aeDesc];
    if (theAppleEventPointer) {
        AESendMessage(theAppleEventPointer, NULL, kAENoReply, kAEDefaultTimeout);
    }
    // 複数回コールされてしまう場合の予防措置
    [self setFileSender:nil];
}


// ------------------------------------------------------
- (BOOL)canReleaseFinderLockOfFile:(NSString *)inFileName isLocked:(BOOL *)ioLocked lockAgain:(BOOL)inLockAgain
// Finder のロックが解除出来るか試す。inLockAgain が真なら再びロックする。
// ------------------------------------------------------
{
    NSFileManager *theManager = [NSFileManager defaultManager];
    BOOL theFinderLockON = [[theManager attributesOfItemAtPath:[inFileName stringByResolvingSymlinksInPath] error:nil] fileIsImmutable];
    BOOL theBoolToGo = NO;

    if (theFinderLockON) {
        // Finder Lock がかかっていれば、解除
        theBoolToGo = [theManager setAttributes:@{NSFileImmutable:@NO} ofItemAtPath:inFileName error:nil];
        if (theBoolToGo) {
            if (inLockAgain) {
            // フラグが立っていたなら、再びかける
            [theManager setAttributes:@{NSFileImmutable:@YES} ofItemAtPath:inFileName error:nil];
            }
        } else {
            return NO;
        }
    }
    if (ioLocked != nil) {
        *ioLocked = theFinderLockON;
    }
    return YES;
}


// ------------------------------------------------------
- (void)alertForNotWritableCloseDocDidEnd:(NSAlert *)inAlert returnCode:(NSInteger)inReturnCode
            contextInfo:(void *)inContextInfo
// 書き込み不可ドキュメントが閉じるときの確認アラートが閉じた
// ------------------------------------------------------
{
// このメソッドは下記のページの情報を参考にさせていただきました(2005.07.08)
// http://www.cocoadev.com/index.pl?ReplaceSaveChangesSheet
    CanCloseAlertContext *theContextInfo = inContextInfo;
    BOOL theReturn = (inReturnCode != NSAlertDefaultReturn); // YES == Don't Save (Close)

    if (theContextInfo->delegate) {
        objc_msgSend(theContextInfo->delegate, theContextInfo->shouldCloseSelector, 
                self, theReturn, theContextInfo->contextInfo);
    }
    free(theContextInfo);
}


// ------------------------------------------------------
- (void)startWatchFile:(NSString *)inFileName
// 外部プロセスによるファイルの変更監視を開始
// ------------------------------------------------------
{
    if ([[NSFileManager defaultManager] fileExistsAtPath:inFileName]) {
        // いったんすべての監視を削除
        [[self fileObserver] removeAllPaths];
        
        // VDKQueue に新たにパスを追加
        u_int notificationType = VDKQueueNotifyAboutWrite | VDKQueueNotifyAboutDelete;
        [[self fileObserver] addPath:inFileName notifyingAbout:notificationType];
    }
}


// ------------------------------------------------------
- (void)stopWatchFile:(NSString *)inFileName
// 外部プロセスによるファイルの変更監視を停止
// ------------------------------------------------------
{
    // VDKQueue からパスを削除
    [[self fileObserver] removePath:inFileName];
}


// ------------------------------------------------------
- (void)increaseSavingFlag
// 保存中フラグを増やす
// ------------------------------------------------------
{
    @synchronized(self) {
        self.numberOfSavingFlags++;
    }
}


// ------------------------------------------------------
- (void)decreaseSavingFlag
// 保存中フラグを減らす
// ------------------------------------------------------
{
    @synchronized(self) {
        self.numberOfSavingFlags--;
    }
}


// ------------------------------------------------------
- (void)alertForModByAnotherProcessDidEnd:(NSAlert *)inAlert returnCode:(NSInteger)inReturnCode
            contextInfo:(void *)inContextInfo
// 外部プロセスによる変更の通知アラートが閉じた
// ------------------------------------------------------
{
    if (inReturnCode == NSAlertAlternateReturn) { // == Revert
        // Revert 確認アラートを表示させないため、実行メソッドを直接呼び出す
        if ([self revertToContentsOfURL:[self fileURL] ofType:[self fileType] error:nil]) {
            [[self undoManager] removeAllActions];
            [self updateChangeCount:NSChangeCleared];
        }
    }
    _isRevertingForExternalFileUpdate = NO;
    _showUpdateAlertWithBecomeKey = NO;
}


// ------------------------------------------------------
- (void)printPanelDidEnd:(NSPrintPanel *)inPrintPanel returnCode:(NSInteger)inReturnCode
            contextInfo:(void *)inContextInfo
// プリントパネルが閉じた
// ------------------------------------------------------
{
    if (inReturnCode != NSOKButton) { return; }

    id theValues = [[NSUserDefaultsController sharedUserDefaultsController] values];
    id thePrintValues = [_windowController printValues];
    NSPrintInfo *thePrintInfo = [self printInfo];
    NSSize thePaperSize = [thePrintInfo paperSize];
    NSPrintOperation *thePrintOperation;
    NSString *theFilePath = ([[theValues valueForKey:k_key_headerFooterPathAbbreviatingWithTilde] boolValue]) ?
            [[[self fileURL] path] stringByAbbreviatingWithTildeInPath] : [[self fileURL] path];
    CELayoutManager *theLayoutManager = [[[CELayoutManager alloc] init] autorelease];
    CEPrintView *thePrintView;
    CESyntax *thePrintSyntax;
    CGFloat theTopMargin = k_printHFVerticalMargin;
    CGFloat theBottomMargin = k_printHFVerticalMargin;
    BOOL theBoolDoColoring = ([[thePrintValues valueForKey:k_printColorIndex] integerValue] == 1);
    BOOL theBoolShowInvisibles = [(CELayoutManager *)[[_editorView textView] layoutManager] showInvisibles];
    BOOL theBoolShowControls = theBoolShowInvisibles;

    // ヘッダ／フッタの高さ（文書を印刷しない高さ）を得る
    if ([[thePrintValues valueForKey:k_printHeader] boolValue]) {
        if ([[thePrintValues valueForKey:k_headerOneStringIndex] integerValue] > 1) { // 行1 = 印字あり
            theTopMargin += k_headerFooterLineHeight;
        }
        if ([[thePrintValues valueForKey:k_headerTwoStringIndex] integerValue] > 1) { // 行2 = 印字あり
            theTopMargin += k_headerFooterLineHeight;
        }
    }
    // ヘッダと本文との距離をセパレータも勘案して決定する（フッタは本文との間が開くことが多いため、入れない）
    if (theTopMargin > k_printHFVerticalMargin) {
        theTopMargin += 
                ([[theValues valueForKey:k_key_headerFooterFontSize] floatValue] - k_headerFooterLineHeight);
        if ([[thePrintValues valueForKey:k_printHeaderSeparator] boolValue]) {
            theTopMargin += k_separatorPadding;
        } else {
            theTopMargin += k_noSeparatorPadding;
        }
    } else {
        if ([[thePrintValues valueForKey:k_printHeaderSeparator] boolValue]) {
            theTopMargin += k_separatorPadding;
        }
    }
    if ([[thePrintValues valueForKey:k_printFooter] boolValue]) {
        if ([[thePrintValues valueForKey:k_footerOneStringIndex] integerValue] > 1) { // 行1 = 印字あり
            theBottomMargin += k_headerFooterLineHeight;
        }
        if ([[thePrintValues valueForKey:k_footerTwoStringIndex] integerValue] > 1) { // 行2 = 印字あり
            theBottomMargin += k_headerFooterLineHeight;
        }
    }
    if ((theBottomMargin == k_printHFVerticalMargin) && 
                ([[thePrintValues valueForKey:k_printFooterSeparator] boolValue])) {
        theBottomMargin += k_separatorPadding;
    }

    // プリントビュー生成
    thePrintView = [[[CEPrintView alloc] initWithFrame:
            NSMakeRect(0, 0, 
                thePaperSize.width - (k_printTextHorizontalMargin * 2), 
                thePaperSize.height - theTopMargin - theBottomMargin)] autorelease];
    // 設定するフォント
    NSFont *theFont;
    if ([[theValues valueForKey:k_key_setPrintFont] integerValue] == 1) { // == プリンタ専用フォントで印字
        theFont = [NSFont fontWithName:[theValues valueForKey:k_key_printFontName] 
                            size:[[theValues valueForKey:k_key_printFontSize] floatValue]];
    } else {
        theFont = [_editorView font];
    }
    
    // プリンタダイアログでの設定オブジェクトをコピー
    [thePrintView setPrintValues:[[[_windowController printValues] copy] autorelease]];
    // プリントビューのテキストコンテナのパディングを固定する（印刷中に変動させるとラップの関連で末尾が印字されないことがある）
    [[thePrintView textContainer] setLineFragmentPadding:k_printHFHorizontalMargin];
    // プリントビューに行間値／行番号表示の有無を設定
    [thePrintView setLineSpacing:[self lineSpacingInTextView]];
    [thePrintView setIsShowingLineNum:[[self editorView] showLineNum]];
    // 制御文字印字を取得
    if ([[thePrintValues valueForKey:k_printInvisibleCharIndex] integerValue] == 0) { // = No print
        theBoolShowControls = NO;
    } else if ([[thePrintValues valueForKey:k_printInvisibleCharIndex] integerValue] == 2) { // = Print all
        theBoolShowControls = YES;
    }
    // layoutManager を入れ替え
    [theLayoutManager setTextFont:theFont];
    [theLayoutManager setFixLineHeight:NO];
    [theLayoutManager setIsPrinting:YES];
    [theLayoutManager setShowInvisibles:theBoolShowInvisibles];
    [theLayoutManager setShowsControlCharacters:theBoolShowControls];
    [[thePrintView textContainer] replaceLayoutManager:theLayoutManager];

    if (theBoolDoColoring) {
        // カラーリング実行オブジェクトを用意
        thePrintSyntax = [[[CESyntax allocWithZone:[self zone]] init] autorelease];
        [thePrintSyntax setSyntaxStyleName:[[_windowController toolbarController] selectedTitleOfSyntaxItem]];
        [thePrintSyntax setLayoutManager:theLayoutManager];
        [thePrintSyntax setIsPrinting:YES];
    }

    // ドキュメントが未保存ならウィンドウ名をパスとして設定
    if (theFilePath == nil) {
        theFilePath = [self displayName];
    }
    [thePrintView setFilePath:theFilePath];

    // PrintInfo 設定
    [thePrintInfo setHorizontalPagination:NSFitPagination];
    [thePrintInfo setHorizontallyCentered:NO];
    [thePrintInfo setVerticallyCentered:NO];
    [thePrintInfo setLeftMargin:k_printTextHorizontalMargin];
    [thePrintInfo setRightMargin:k_printTextHorizontalMargin];
    [thePrintInfo setTopMargin:theTopMargin];
    [thePrintInfo setBottomMargin:theBottomMargin];

    // プリントビューの設定
    [thePrintView setFont:theFont];
    if (theBoolDoColoring) { // カラーリングする
        [thePrintView setTextColor:
                    [NSUnarchiver unarchiveObjectWithData:[theValues valueForKey:k_key_textColor]]];
        [thePrintView setBackgroundColor:
                    [NSUnarchiver unarchiveObjectWithData:[theValues valueForKey:k_key_backgroundColor]]];
    } else {
        [thePrintView setTextColor:[NSColor blackColor]];
        [thePrintView setBackgroundColor:[NSColor whiteColor]];
    }
    // プリントビューへ文字列を流し込む
    [thePrintView setString:[_editorView string]];
    if (theBoolDoColoring) { // カラーリングする
// 現状では、印刷するページ数に関係なく全ページがカラーリングされている。20080104*****
        [thePrintSyntax colorAllString:[_editorView string]];
    }
    // プリントオペレーション生成、設定、プリント実行
    thePrintOperation = [NSPrintOperation printOperationWithView:thePrintView printInfo:thePrintInfo];
    // プリントパネルの表示を制御し、プログレスパネルは表示させる
    [thePrintOperation setShowsPrintPanel:NO];
    [thePrintOperation setShowsProgressPanel:YES];
    [thePrintOperation runOperation];
}


// ------------------------------------------------------
- (NSStringEncoding)encodingFromComAppleTextEncodingAtPath:(NSString *)inFilePath
// ファイル拡張属性(com.apple.TextEncoding)からエンコーディングを得る
// ------------------------------------------------------
{
    NSStringEncoding outEncoding = NSProprietaryStringEncoding;

    NSString *theStr = [UKXattrMetadataStore stringForKey:@"com.apple.TextEncoding"
                atPath:inFilePath traverseLink:NO];
    NSArray *theArray = [theStr componentsSeparatedByString:@";"];
    if (([theArray count] >= 2) && ([theArray[1] length] > 1)) {
        // （配列の2番目の要素の末尾には行末コードが付加されているため、長さの最小は1）
        outEncoding = CFStringConvertEncodingToNSStringEncoding([theArray[1] integerValue]);
    } else if ([theArray[0] length] > 1) {
        CFStringEncoding theCFEncoding = 
                CFStringConvertIANACharSetNameToEncoding((CFStringRef)theArray[0]);
        if (theCFEncoding != kCFStringEncodingInvalidId) {
            outEncoding = CFStringConvertEncodingToNSStringEncoding(theCFEncoding);
        }
    }
    
    return outEncoding;
}


// ------------------------------------------------------
- (void)setComAppleTextEncodingAtPath:(NSString *)inFilePath
// ファイル拡張属性(com.apple.TextEncoding)にエンコーディングをセット
// ------------------------------------------------------
{
    NSString *theEncodingStr = [[self currentIANACharSetName] stringByAppendingFormat:@";%@",
                [[NSNumber numberWithInt:CFStringConvertNSStringEncodingToEncoding(_encoding)] stringValue]];

    [UKXattrMetadataStore setString:theEncodingStr forKey:@"com.apple.TextEncoding" 
            atPath:inFilePath traverseLink:NO];
}


// ------------------------------------------------------
- (void)setIsWritableToEditorViewWithFileName:(NSString *)inFileName
// 書き込み可能かを EditorView にセット
// ------------------------------------------------------
{
    NSFileManager *theFileManager = [NSFileManager defaultManager];
    BOOL theBoolIsWritable = YES; // default = YES

    if ((inFileName) && ([theFileManager fileExistsAtPath:inFileName])) {
        theBoolIsWritable = [theFileManager isWritableFileAtPath:inFileName];
    }
    [_editorView setIsWritable:theBoolIsWritable];
}


// ------------------------------------------------------
- (void)showAlertForNotWritable
// EditorView で、書き込み禁止アラートを表示
// ------------------------------------------------------
{
    [_editorView alertForNotWritable];
}



@end
