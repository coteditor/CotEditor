/*
=================================================
CEDocument
(for CotEditor)

 Copyright (C) 2004-2007 nakamuxu.
 Copyright (C) 2011, 2014 CotEditor Project
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

#import "CEDocument.h"
#import "ODBEditorSuite.h"
#import "NSData+MD5.h"



//=======================================================
// not defined in __LP64__
// 2014-02 by 1024jp
//=======================================================
#ifdef __LP64__
enum { typeFSS = 'fss ' };
#endif



//=======================================================
// Private properties
//
//=======================================================

@interface CEDocument ()

@property (atomic, retain) NSString *fileMD5;
@property (atomic) BOOL showUpdateAlertWithBecomeKey;
@property (atomic) BOOL isRevertingForExternalFileUpdate;
@property (retain) NSString *initialString;  // 初期表示文字列に表示する文字列;

@property (readwrite) BOOL canActivateShowInvisibleCharsItem;
@property (readwrite) NSStringEncoding encodingCode;
@property (readwrite, retain) NSDictionary *fileAttributes;

@end


//------------------------------------------------------------------------------------------




@implementation CEDocument

#pragma mark Class Methods

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


#pragma mark NSDocument Methods

//=======================================================
// NSDocument methods
//
//=======================================================

// ------------------------------------------------------
- (instancetype)init
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
        if ([[theValues valueForKey:k_key_saveTypeCreator] unsignedIntegerValue] <= 1) {
            [self setFileAttributes:[self myCreatorAndTypeCodeAttributes]];
        }
        (void)[self doSetEncoding:[[theValues valueForKey:k_key_encodingInNew] unsignedLongValue] 
                updateDocument:NO askLossy:NO lossy:NO asActionName:nil];
        _selection = [[CETextSelection alloc] initWithDocument:self]; // ===== alloc
        [self setCanActivateShowInvisibleCharsItem:
                [[theValues valueForKey:k_key_showInvisibleSpace] boolValue] ||
                [[theValues valueForKey:k_key_showInvisibleTab] boolValue] || 
                [[theValues valueForKey:k_key_showInvisibleNewLine] boolValue] || 
                [[theValues valueForKey:k_key_showInvisibleFullwidthSpace] boolValue] || 
                [[theValues valueForKey:k_key_showOtherInvisibleChars] boolValue]];
        [self setDoCascadeWindow:YES];
        [self setInitTopLeftPoint:NSZeroPoint];
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(documentDidFinishOpen:)
                                                     name:k_documentDidFinishOpenNotification object:nil];
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
    
    [[self fileMD5] release];
    // initialString は既に autorelease されている == "- (NSString *)stringToWindowController"
    // _selection は既に autorelease されている == "- (void)close"
    [[[self editorView] splitView] releaseAllEditorView]; // 各subSplitView が持つ editorView 参照を削除
    [[self editorView] release]; // 自身のメンバを削除
    [_windowController release];
    [[self fileAttributes] release];
    [[self fileToken] release];
     // fileSender は既にnilがセットされている == "- (void)sendModifiedEventToClientOfFile:(NSString *)inSaveAsPath  operation:(NSSaveOperationType)inSaveOperationType", "- (void)sendCloseEventToClient"

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
// ファイルの保存(保存処理で包括的に呼ばれる)
// ------------------------------------------------------
{
    // 保存の前後で編集内容をグルーピングさせないための処置
    // ダミーのグループを作り、そのままだと空のアンドゥ内容でダーティーフラグがたってしまうので、アンドゥしておく
    // ****** 空のアンドゥ履歴が残る問題あり  (2005.08.05) *******
    // (保存の前後で編集内容がグルーピングされてしまう例：キー入力後保存し、キャレットを動かすなどしないでそのまま入力
    // した場合、ダーティーフラグがたたず、アンドゥすると保存前まで戻されてしまう。さらに、戻された状態でリドゥすると、
    // 保存後の入力までが行われる。つまり、保存をはさんで前後の内容が同一アンドゥグループに入ってしまうための不具合)
    // CETextViewCore > doInsertString:withRange:withSelected:withActionName: でも同様の対処を行っている
    // ****** 何かもっとうまい回避方法があるはずなんだが … (2005.08.05) *******
    [[self undoManager] beginUndoGrouping];
    [[self undoManager] endUndoGrouping];
    [[self undoManager] undo];
    
    
    id token = [self changeCountTokenForSaveOperation:saveOperation];
    
    // 新規書類を最初に保存する場合のフラグをセット
    BOOL isFirstSave = (![self fileURL] || (saveOperation == NSSaveAsOperation));
    
    // 保存処理実行
    BOOL success = [self forceWriteToURL:url ofType:typeName forSaveOperation:saveOperation];

    if (success) {
        // 新規保存時、カラーリングのために拡張子を保持
        if (isFirstSave) {
            [self setColoringExtension:[url pathExtension] coloring:YES];
        }

        // 保持しているファイル情報／表示する文書情報を更新
        [self getFileAttributes];
        
        // 外部エディタプロトコル(ODB Editor Suite)のファイル更新通知送信
        [self sendModifiedEventToClientOfFile:[url path] operation:saveOperation];
        
        // ファイル保存更新を Finder へ通知（デスクトップに保存した時に白紙アイコンになる問題への対応）
        [[NSWorkspace sharedWorkspace] noteFileSystemChanged:[url path]];
        
        // changeCountを更新
        [self updateChangeCountWithToken:token forSaveOperation:saveOperation];
    }

    return success;
}


// ------------------------------------------------------
- (NSData *)dataOfType:(NSString *)typeName error:(NSError **)outError
// 保存用のデータを生成
// ------------------------------------------------------
{
    id defaults = [[NSUserDefaultsController sharedUserDefaultsController] values];
    BOOL shouldAppendBOM = [[defaults valueForKey:k_key_saveUTF8BOM] boolValue];
    
    // エンコーディングを見て、半角円マークを変換しておく
    NSString *string = [self convertedCharacterString:[[self editorView] stringForSave] withEncoding:[self encodingCode]];
    
    // stringから保存用のdataを得る
    NSData *data = [string dataUsingEncoding:[self encodingCode] allowLossyConversion:YES];
    
    // 必要であれば UTF-8 BOM 追加 (2008.12.13)
    if (shouldAppendBOM && ([self encodingCode] == NSUTF8StringEncoding)) {
        const char utf8Bom[] = {0xef, 0xbb, 0xbf}; // UTF-8 BOM
        NSMutableData *mutableData = [NSMutableData dataWithBytes:utf8Bom length:3];
        [mutableData appendData:data];
        data = [NSData dataWithData:mutableData];
    }
    
    return data;
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
        OSType theCreator = [[self fileAttributes] fileHFSCreatorCode];
        OSType theType = [[self fileAttributes] fileHFSTypeCode];
        if ((theCreator == 0) || (theType == 0)) {
            [outDict addEntriesFromDictionary:[self myCreatorAndTypeCodeAttributes]];
        } else {
            outDict[NSFileHFSCreatorCode] = [self fileAttributes][NSFileHFSCreatorCode];
            outDict[NSFileHFSTypeCode] = [self fileAttributes][NSFileHFSTypeCode];
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
    if (![self isRevertingForExternalFileUpdate]) {
        [[[self windowForSheet] attachedSheet] orderOut:self];
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
- (void)runModalSavePanelForSaveOperation:(NSSaveOperationType)saveOperation delegate:(id)delegate 
            didSaveSelector:(SEL)didSaveSelector contextInfo:(void *)contextInfo
// セーブパネルを表示
// ------------------------------------------------------
{
    [super runModalSavePanelForSaveOperation:saveOperation delegate:delegate 
            didSaveSelector:didSaveSelector contextInfo:contextInfo];

    // セーブパネル表示時の処理
    NSSavePanel *theSavePanel = (NSSavePanel *)[[self windowForSheet] attachedSheet];
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
- (void)canCloseDocumentWithDelegate:(id)delegate shouldCloseSelector:(SEL)shouldCloseSelector contextInfo:(void *)contextInfo
// ドキュメントが閉じられる前に保存のためのダイアログの表示などを行う
// ------------------------------------------------------
{
// このメソッドは下記のページの情報を参考にさせていただきました(2005.07.08)
// http://www.cocoadev.com/index.pl?ReplaceSaveChangesSheet

    // 各種更新タイマーを停止
    [[self editorView] stopAllTimer];

    // Finder のロックが解除できず、かつダーティーフラグがたっているときは相応のダイアログを出す
    if ([self isDocumentEdited] &&
        ![self canReleaseFinderLockOfFile:[[self fileURL] path] isLocked:nil lockAgain:YES]) {

        NSAlert *alert = [NSAlert alertWithMessageText:NSLocalizedString(@"Finder's lock is ON", nil)
                                         defaultButton:NSLocalizedString(@"Cancel", nil)
                                       alternateButton:NSLocalizedString(@"Don't Save, and Close", nil)
                                           otherButton:nil
                             informativeTextWithFormat:NSLocalizedString(@"Finder's lock could not be released. So, you can not save your changes on this file, but you will be able to save a copy somewhere else. \n\nDo you want to close?", nil)];

        for (NSButton *button in [alert buttons]) {
            if ([[button title] isEqualToString:NSLocalizedString(@"Don't Save, and Close",@"")]) {
                [button setKeyEquivalent:@"d"];
                [button setKeyEquivalentModifierMask:NSCommandKeyMask];
                break;
            }
        }
        
        [alert beginSheetModalForWindow:[self windowForSheet] completionHandler:^(NSModalResponse returnCode) {
            BOOL theReturn = (returnCode != NSAlertDefaultReturn); // YES == Don't Save (Close)
            
            if (delegate) {
                objc_msgSend(delegate, shouldCloseSelector, self, theReturn, contextInfo);
            }
        }];
    } else {
        [super canCloseDocumentWithDelegate:delegate shouldCloseSelector:shouldCloseSelector contextInfo:contextInfo];
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
    [self removeWindowController:(NSWindowController *)_windowController];

    [super close];
}


#pragma mark Public Methods

//=======================================================
// Public method
//
//=======================================================

// ------------------------------------------------------
- (id)windowController
// windowController を返す
// ------------------------------------------------------
{
    return _windowController;
}


//------------------------------------------------------
- (BOOL)stringFromData:(NSData *)data encoding:(NSStringEncoding)encoding xattr:(BOOL)boolXattr
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
    if ((boolXattr) && (encoding != k_autoDetectEncodingMenuTag)) {
        theStr = [[[NSString alloc] initWithData:data encoding:encoding] autorelease];
        if (theStr == nil) {
            encoding = k_autoDetectEncodingMenuTag;
        }
    }

    if (([data length] > 0) && (encoding == k_autoDetectEncodingMenuTag)) {
        const char theUtf8Bom[] = {0xef, 0xbb, 0xbf}; // UTF-8 BOM
        // BOM付きUTF-8判定
        if (memchr([data bytes], *theUtf8Bom, 3) != NULL) {

            theBoolToSkipUTF8 = YES;
            theStr = [[[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding] autorelease];
            if (theStr != nil) {
                encoding = NSUTF8StringEncoding;
            }
        // UTF-16判定
        } else if ((memchr([data bytes], 0xfffe, 2) != NULL) || 
                    (memchr([data bytes], 0xfeff, 2) != NULL)) {

            theBoolToSkipUTF16 = YES;
            theStr = [[[NSString alloc] initWithData:data encoding:NSUnicodeStringEncoding] autorelease];
            if (theStr != nil) {
                encoding = NSUnicodeStringEncoding;
            }

        // ISO 2022-JP判定
        } else if (memchr([data bytes], 0x1b, [data length]) != NULL) {
            theBoolToSkipISO2022JP = YES;
            theStr = [[[NSString alloc] initWithData:data encoding:NSISO2022JPStringEncoding] autorelease];
            if (theStr != nil) {
                encoding = NSISO2022JPStringEncoding;
            }
        }
    }

    if ((theStr == nil) && (encoding == k_autoDetectEncodingMenuTag)) {
        id theValues = [[NSUserDefaultsController sharedUserDefaultsController] values];
        NSArray *theEncodings = [[[theValues valueForKey:k_key_encodingList] copy] autorelease];
        NSInteger i = 0;

        while (theStr == nil) {
            encoding = 
                    CFStringConvertEncodingToNSStringEncoding([theEncodings[i] unsignedLongValue]);
            if ((encoding == NSISO2022JPStringEncoding) && theBoolToSkipISO2022JP) {
                break;
            } else if ((encoding == NSUTF8StringEncoding) && theBoolToSkipUTF8) {
                break;
            } else if ((encoding == NSUnicodeStringEncoding) && theBoolToSkipUTF16) {
                break;
            } else if (encoding == NSProprietaryStringEncoding) {
                NSLog(@"theEncoding == NSProprietaryStringEncoding");
                break;
            }
            theStr = [[[NSString alloc] initWithData:data encoding:encoding] autorelease];
            if (theStr != nil) {
                // "charset="や"encoding="を読んでみて適正なエンコーディングが得られたら、そちらを優先
                NSStringEncoding theTmpEncoding = [self scannedCharsetOrEncodingFromString:theStr];
                if ((theTmpEncoding == NSProprietaryStringEncoding) || (theTmpEncoding == encoding)) {
                    break;
                }
                NSString *theTmpStr = 
                        [[[NSString alloc] initWithData:data encoding:theTmpEncoding] autorelease];
                if (theTmpStr != nil) {
                    theStr = theTmpStr;
                    encoding = theTmpEncoding;
                }
            }
            i++;
        }
    } else if (theStr == nil) {
        theStr = [[[NSString alloc] initWithData:data encoding:encoding] autorelease];
    }

    if ((theStr != nil) && (encoding != k_autoDetectEncodingMenuTag)) {
        // 10.3.9 で、一部のバイナリファイルを開いたときにクラッシュする問題への暫定対応。
        // 10.4+ ではスルー（2005.12.25）
        // ＞＞ しかし「すべて2バイト文字で4096文字以上あるユニコードでない文書」は開けない（2005.12.25）
        // (下記の現象と同じ理由で発生していると思われる）
        // https://www.codingmonkeys.de/bugs/browse/HYR-529?page=all
        if ((floor(NSAppKitVersionNumber) > NSAppKitVersionNumber10_3) || // = 10.4+ 
                ([data length] <= 8192) || 
                (([data length] > 8192) && ([data length] != ([theStr length] * 2 + 1)) && 
                        ([data length] != ([theStr length] * 2)))) {
                    
            _initialString = [theStr retain]; // ===== retain
            // (_initialString はあとで開放 == "- (NSString *)stringToWindowController".)
            (void)[self doSetEncoding:encoding updateDocument:NO askLossy:NO lossy:NO asActionName:nil];
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
    [self setIsWritableToEditorViewWithURL:[self fileURL]];
}


// ------------------------------------------------------
- (void)setStringToTextView:(NSString *)inString
// 新たな文字列をセット
// ------------------------------------------------------
{
    if (inString) {
        OgreNewlineCharacter theLineEnd = [OGRegularExpression newlineCharacterInString:inString];
        [self setLineEndingCharToView:theLineEnd]; // for update toolbar item
        [[self editorView] setString:inString]; // （editorView の setString 内でキャレットを先頭に移動させている）
    } else {
        [[self editorView] setString:@""];
    }
    // ツールバーのエンコーディングメニュー、ステータスバー、ドローワを更新
    [self updateEncodingInToolbarAndInfo];
    // テキストビューへフォーカスを移動
    [[[self editorView] window] makeFirstResponder:[[[[self editorView] splitView] subviews][0] textView]];
    // カラーリングと行番号を更新
    // （大きいドキュメントの時はインジケータを表示させるため、ディレイをかけてまずウィンドウを表示させる）
    [[self editorView] updateColoringAndOutlineMenuWithDelay];
}


// ------------------------------------------------------
- (BOOL)doSetEncoding:(NSStringEncoding)inEncoding updateDocument:(BOOL)inDocUpdate 
        askLossy:(BOOL)inAskLossy  lossy:(BOOL)inLossy  asActionName:(NSString *)inName
// 新規エンコーディングをセット
// ------------------------------------------------------
{
    if (inEncoding == [self encodingCode]) {
        return YES;
    }
    NSInteger theResult = NSAlertOtherReturn;
    BOOL theBoolNeedsShowList = NO;
    if (inDocUpdate) {

        theBoolNeedsShowList = [_windowController needsIncompatibleCharDrawerUpdate];
        NSString *theCurString = [[self editorView] stringForSave];
        BOOL theAllowLossy = NO;

        if (inAskLossy) {
            if (![theCurString canBeConvertedToEncoding:inEncoding]) {
                NSString *theEncodingNameStr = [NSString localizedNameOfStringEncoding:inEncoding];
                NSString *theMessageText = [NSString stringWithFormat:NSLocalizedString(@"The characters would have to be changed or deleted in saving as \"%@\".", nil), theEncodingNameStr];
                NSAlert *theAlert = [NSAlert alertWithMessageText:theMessageText
                                                    defaultButton:NSLocalizedString(@"Cancel", nil)
                                                  alternateButton:NSLocalizedString(@"Change Encoding", nil)
                                                      otherButton:nil
                                        informativeTextWithFormat:NSLocalizedString(@"Do you want to change encoding and show incompatible character(s)?", nil)];

                theResult = [theAlert runModal];
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
        [[theUndoManager prepareWithInvocationTarget:self] doSetEncoding:[self encodingCode]]; // エンコード値設定
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
    NSArray *managers = [[self editorView] allLayoutManagers];

    for (NSLayoutManager *manager in managers) {
        // 現存の背景色カラーリングをすべて削除（検索のハイライトも削除される）
        [manager removeTemporaryAttribute:NSBackgroundColorAttributeName
                        forCharacterRange:NSMakeRange(0, [[[self editorView] string] length])];
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
    NSString *theWholeString = [[self editorView] stringForSave];
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
    NSArray *theManagers = [[self editorView] allLayoutManagers];
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
    NSInteger theCurrentEnding = [[self editorView] lineEndingCharacter];

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
    [[self editorView] setLineEndingCharacter:inNewLineEnding];
    [[_windowController toolbarController] setSelectEndingItemIndex:inNewLineEnding];
}


// ------------------------------------------------------
- (void)doSetSyntaxStyle:(NSString *)inName
// 新しいシンタックスカラーリングスタイルを適用
// ------------------------------------------------------
{
    if ([inName length] > 0) {
        [[self editorView] setSyntaxStyleNameToColoring:inName recolorNow:YES];
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
            [[self editorView] setSyntaxStyleNameToColoring:inName recolorNow:NO];
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

    BOOL theBoolIsUpdated = [[self editorView] setSyntaxExtension:inExtension];

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
    CGFloat theSize = (CGFloat)[[theValues valueForKey:k_key_fontSize] doubleValue];
    NSFont *theFont = [NSFont fontWithName:theName size:theSize];

    [[self editorView] setFont:theFont];
}


// ------------------------------------------------------
- (NSRange)rangeInTextViewWithLocation:(NSInteger)inLocation withLength:(NSInteger)inLength
// マイナス指定された文字範囲／長さをNSRangeにコンバートして返す
// ------------------------------------------------------
{
    CETextViewCore *theTextView = [[self editorView] textView];
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

    [[self editorView] setSelectedRange:theSelectionRange];
}


// ------------------------------------------------------
- (void)setSelectedLineRangeInTextViewWithLocation:(NSInteger)inLocation withLength:(NSInteger)inLength
// editorView 内部の textView で指定された部分を行単位で選択
// ------------------------------------------------------
{
    CETextViewCore *theTextView = [[self editorView] textView];
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
    [[[self editorView] textView] scrollRangeToVisible:[[[self editorView] textView] selectedRange]];
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
    [[[self editorView] textView] showFindIndicatorForRange:[[[self editorView] textView] selectedRange]];  // 検索結果表示エフェクトを追加
    [[_windowController window] makeKeyAndOrderFront:self]; // 対象ウィンドウをキーに
}


// ------------------------------------------------------
- (void)getFileAttributes
// ファイル情報辞書を保持
// ------------------------------------------------------
{
    NSDictionary *attributes = [[NSFileManager defaultManager] attributesOfItemAtPath:[[self fileURL] path]
                                                                                error:nil];

    if (attributes) {
        [self setFileAttributes:attributes];
        [_windowController updateFileAttrsInformation];
    }
}


// ------------------------------------------------------
- (void)rebuildToolbarEncodingItem
// toolbar のエンコーディングメニューアイテムを再生成する
// ------------------------------------------------------
{
    [[_windowController toolbarController] buildEncodingPopupButton];
    [[_windowController toolbarController] setSelectEncoding:[self encodingCode]];
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
    NSString *theCurStyleName = [[self editorView] syntaxStyleNameToColoring];

    if ([theOldName isEqualToString:theCurStyleName]) {
        if ((theOldName != nil) && (theNewName != nil) && (![theOldName isEqualToString:theNewName])) {
            [[self editorView] setSyntaxStyleNameToColoring:theNewName recolorNow:NO];
        }
        [_windowController setRecolorWithBecomeKey:YES];
    }
}


// ------------------------------------------------------
- (void)setStyleToNoneAndRecolorFlagWithStyleName:(NSString *)inStyleName
// 指定されたスタイルを適用していたら WindowController のリカラーフラグを立て、スタイル名を"None"にする
// ------------------------------------------------------
{
    NSString *theCurStyleName = [[self editorView] syntaxStyleNameToColoring];

    // 指定されたスタイル名と違ったら、無視
    if ([theCurStyleName isEqualToString:inStyleName]) {
        [_windowController setRecolorWithBecomeKey:YES];
        [[self editorView] setSyntaxStyleNameToColoring:NSLocalizedString(@"None",@"") recolorNow:NO];
    }
}


// ------------------------------------------------------
- (void)setSmartInsertAndDeleteToTextView
// スマートインサート／デリートをするかどうかをテキストビューへ設定
// ------------------------------------------------------
{
    id theValues = [[NSUserDefaultsController sharedUserDefaultsController] values];

    [[[self editorView] textView] setSmartInsertDeleteEnabled:
            [[theValues valueForKey:k_key_smartInsertAndDelete] boolValue]];
}


// ------------------------------------------------------
- (NSString *)currentIANACharSetName
// 設定されたエンコーディングの IANA Charset 名を返す
// ------------------------------------------------------
{
    NSString *outString = nil;
    CFStringEncoding theCFEncoding = CFStringConvertNSStringEncodingToEncoding([self encodingCode]);

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
    if (![self showUpdateAlertWithBecomeKey]) { return; } // 表示フラグが立っていなければ、もどる

    NSAlert *alert;
    NSString *messageText, *informativeText, *defaultButton;

    if ([self isDocumentEdited]) {
        messageText = @"The file has been modified by another process. There are also unsaved changes in CotEditor.";
        informativeText = @"Do you want to keep CotEditor's edition or update to the modified edition?";
        defaultButton = @"Keep CotEditor's Edition";
    } else {
        messageText = @"The file has been modified by another process.";
        informativeText = @"Do you want to keep unchanged or Update to the modified edition?";
        defaultButton = @"Keep Unchanged";
        [self updateChangeCount:NSChangeDone]; // ダーティーフラグを立てる
    }
    alert = [NSAlert alertWithMessageText:NSLocalizedString(messageText, nil)
                            defaultButton:NSLocalizedString(defaultButton, nil)
                          alternateButton:NSLocalizedString(@"Update", nil)
                              otherButton:nil
                informativeTextWithFormat:NSLocalizedString(informativeText, nil)];

    // シートが表示中でなければ、表示
    if ([[self windowForSheet] attachedSheet] == nil) {
        [self setIsRevertingForExternalFileUpdate:YES];
        [[self windowForSheet] orderFront:nil]; // 後ろにあるウィンドウにシートを表示させると不安定になることへの対策
        [alert beginSheetModalForWindow:[self windowForSheet]
                    modalDelegate:self 
                    didEndSelector:@selector(alertForModByAnotherProcessDidEnd:returnCode:contextInfo:) 
                    contextInfo:NULL];

    } else if ([self isRevertingForExternalFileUpdate]) {
        // （同じ外部プロセスによる変更通知アラートシートを表示中の時は、なにもしない）

    // 既にシートが出ている時はダイアログで表示
    } else {
        [self setIsRevertingForExternalFileUpdate:YES];
        [[self windowForSheet] orderFront:nil]; // 後ろにあるウィンドウにシートを表示させると不安定になることへの対策
        NSInteger theResult = [alert runModal]; // アラート表示
        [self alertForModByAnotherProcessDidEnd:alert returnCode:theResult contextInfo:NULL];
    }
}


// ------------------------------------------------------
- (CGFloat)lineSpacingInTextView
// テキストビューに設定されている行間値を返す
// ------------------------------------------------------
{
    return ([[[self editorView] textView] lineSpacing]);
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
    [[[self editorView] textView] setNewLineSpacingAndUpdate:theSpacing];
}



#pragma mark Protocols

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
        if ((![[self editorView] isWritable]) && (![[self editorView] isAlertedNotWritable])) {
            return NO;
        }
    } else if ([inMenuItem action] == @selector(selectPrevItemOfOutlineMenu:)) {
        return ([[[self editorView] navigationBar] canSelectPrevItem]);
    } else if ([inMenuItem action] == @selector(selectNextItemOfOutlineMenu:)) {
        return ([[[self editorView] navigationBar] canSelectNextItem]);
    } else if ([inMenuItem action] == @selector(setEncoding:)) {
        theState = ([inMenuItem tag] == [self encodingCode]) ? NSOnState : NSOffState;
    } else if (([inMenuItem action] == @selector(setLineEndingCharToLF:)) || 
            ([inMenuItem action] == @selector(setLineEndingCharToCR:)) || 
            ([inMenuItem action] == @selector(setLineEndingCharToCRLF:))) {
        theState = ([inMenuItem tag] == [[self editorView] lineEndingCharacter]) ? NSOnState : NSOffState;
    } else if ([inMenuItem action] == @selector(setSyntaxStyle:)) {
        theName = [[self editorView] syntaxStyleNameToColoring];
        if (theName && [[inMenuItem title] isEqualToString:theName]) {
            theState = NSOnState;
        }
    } else if ([inMenuItem action] == @selector(recoloringAllStringOfDocument:)) {
        theName = [[self editorView] syntaxStyleNameToColoring];
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
-(BOOL)validateToolbarItem:(NSToolbarItem *)theItem
// ツールバー項目の有効・無効を制御
// ------------------------------------------------------
{
    if ([[theItem itemIdentifier] isEqualToString:k_syntaxReColorAllItemID]) {
        NSString *name = [[self editorView] syntaxStyleNameToColoring];
        if ([name isEqualToString:NSLocalizedString(@"None", @"")]) {
            return NO;
        }
    }
    return YES;
}



#pragma mark Delegate and Notifications

//=======================================================
// Delegate method (NSFilePresenter)
//  <== NSFilePresenter
//=======================================================

// ------------------------------------------------------
- (void)presentedItemDidChange
// ファイルが変更された
// ------------------------------------------------------
{
    // ファイルのmodificationDateがドキュメントのmodificationDateと同じ場合は無視
    NSFileCoordinator *coordinator = [[[NSFileCoordinator alloc] initWithFilePresenter:self] autorelease];
    __block NSDate *fileModificationDate;
    [coordinator coordinateReadingItemAtURL:[self fileURL] options:NSFileCoordinatorReadingWithoutChanges
                                      error:nil byAccessor:^(NSURL *newURL)
    {
        NSDictionary *fileAttrs = [[NSFileManager defaultManager] attributesOfItemAtPath:[newURL path] error:nil];
        fileModificationDate = [fileAttrs fileModificationDate];
    }];
    if ([fileModificationDate isEqualToDate:[self fileModificationDate]]) { return; }
    
    // ファイルのMD5ハッシュが保持しているものと同じ場合は編集されていないと認識させた上で無視
    __block NSString *MD5;
    [coordinator coordinateReadingItemAtURL:[self fileURL] options:NSFileCoordinatorReadingWithoutChanges
                                      error:nil byAccessor:^(NSURL *newURL)
     {
         NSData *data = [NSData dataWithContentsOfURL:newURL];
         MD5 = [data MD5];
     }];
    if ([MD5 isEqualToString:[self fileMD5]]) {
        // documentの保持しているfileModificationDateを書き換える (2014-03 by 1024jp)
        // ここだけで無視してもファイル保存時にアラートが出るのことへの対策
        [self setFileModificationDate:fileModificationDate];
        
        return;
    }
    
    // 書き込み通知を行う
    [self setShowUpdateAlertWithBecomeKey:YES];
    id defaults = [[NSUserDefaultsController sharedUserDefaultsController] values];
    // アプリがアクティブならシート／ダイアログを表示し、そうでなければ設定を見てDockアイコンをジャンプ
    if ([NSApp isActive]) {
        [self performSelectorOnMainThread:@selector(showUpdatedByExternalProcessAlert) withObject:nil waitUntilDone:NO];
        
    } else if ([[defaults valueForKey:k_key_notifyEditByAnother] boolValue]) {
        [NSApp requestUserAttention:NSInformationalRequest];
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
    if ([inNotification object] != [self editorView]) { return; }

    [self showAlertForNotWritable];
}



#pragma mark Action Messages

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

    NSPrintPanel *printPanel = [NSPrintPanel printPanel];

    [printPanel setAccessoryView:[_windowController printAccessoryView]];
    [printPanel beginSheetWithPrintInfo:[self printInfo]
                         modalForWindow:[self windowForSheet]
                               delegate:self
                         didEndSelector:@selector(printPanelDidEnd:returnCode:contextInfo:)
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

    if ((theEncoding < 1) || (theEncoding == [self encodingCode])) {
        return;
    }
    NSInteger theResult;
    NSString *theEncodingName = [sender title];

    // 文字列がないまたは未保存の時は直ちに変換プロセスへ
    if (([[[self editorView] string] length] < 1) || (![self fileURL])) {
        theResult = NSAlertDefaultReturn;
    } else {
        // 変換するか再解釈するかの選択ダイアログを表示
        NSAlert *theAlert = [NSAlert alertWithMessageText:NSLocalizedString(@"File encoding", nil)
                                            defaultButton:NSLocalizedString(@"Convert", nil)
                                          alternateButton:NSLocalizedString(@"Reinterpret", nil)
                                              otherButton:NSLocalizedString(@"Cancel", nil)
                                informativeTextWithFormat:NSLocalizedString(@"Do you want to convert or reinterpret it using \"%@\"?", nil), theEncodingName];

        theResult = [theAlert runModal];
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
            NSAlert *theSecondAlert = [NSAlert alertWithMessageText:[NSString stringWithFormat:NSLocalizedString(@"The file \'%@\' has unsaved changes.", nil), [[self fileURL] path]]
                                                      defaultButton:NSLocalizedString(@"Cancel", nil)
                                                    alternateButton:NSLocalizedString(@"Discard Changes", nil)
                                                        otherButton:nil
                                          informativeTextWithFormat:NSLocalizedString(@"Do you want to discard the changes and reset the file encodidng?", nil)];

            NSInteger theSecondResult = [theSecondAlert runModal];
            if (theSecondResult != NSAlertAlternateReturn) { // != Discard Change
                // ツールバーから変更された場合のため、ツールバーアイテムの選択状態をリセット
                [[_windowController toolbarController] setSelectEncoding:[self encodingCode]];
                return;
            }
        }
        if ([self readFromFile:[[self fileURL] path] withEncoding:theEncoding]) {
            [self setStringToEditorView];
            // アンドゥ履歴をクリア
            [[self undoManager] removeAllActions];
            [self updateChangeCount:NSChangeCleared];
        } else {
            NSAlert *theThirdAlert = [NSAlert alertWithMessageText:NSLocalizedString(@"Can not reinterpret", nil)
                                                     defaultButton:NSLocalizedString(@"Done", nil)
                                                   alternateButton:nil
                                                       otherButton:nil
                                         informativeTextWithFormat:NSLocalizedString(@"The file \'%@\' could not be reinterpreted using the new encoding \"%@\".", nil), [[self fileURL] path], theEncodingName];
            [theThirdAlert setAlertStyle:NSCriticalAlertStyle];

            NSBeep();
            (void)[theThirdAlert runModal];
        }
    }
    // ツールバーから変更された場合のため、ツールバーアイテムの選択状態をリセット
    [[_windowController toolbarController] setSelectEncoding:[self encodingCode]];
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
    [[self editorView] recoloringAllString];
}


// ------------------------------------------------------
- (IBAction)setWindowAlpha:(id)sender
// ウィンドウの不透明度を設定
// ------------------------------------------------------
{
    [(CEWindowController *)[self windowController] setAlpha:(CGFloat)[sender doubleValue]];
}


// ------------------------------------------------------
- (IBAction)insertIANACharSetName:(id)sender
// IANA文字コード名を挿入する
// ------------------------------------------------------
{
    NSString *theString = [self currentIANACharSetName];

    if (theString != nil) {
        [[[self editorView] textView] insertText:theString];
    }
}


// ------------------------------------------------------
- (IBAction)insertIANACharSetNameWithCharset:(id)sender
// IANA文字コード名を挿入する
// ------------------------------------------------------
{
    NSString *theString = [self currentIANACharSetName];

    if (theString != nil) {
        [[[self editorView] textView] insertText:[NSString stringWithFormat:@"charset=\"%@\"", theString]];
    }
}


// ------------------------------------------------------
- (IBAction)insertIANACharSetNameWithEncoding:(id)sender
// IANA文字コード名を挿入する
// ------------------------------------------------------
{
    NSString *theString = [self currentIANACharSetName];

    if (theString != nil) {
        [[[self editorView] textView] insertText:[NSString stringWithFormat:@"encoding=\"%@\"", theString]];
    }
}


// ------------------------------------------------------
- (IBAction)selectPrevItemOfOutlineMenu:(id)sender
// アウトラインメニューの前の項目を選択（メニューバーからのアクションを中継）
// ------------------------------------------------------
{
    [[[self editorView] navigationBar] selectPrevItem];
}


// ------------------------------------------------------
- (IBAction)selectNextItemOfOutlineMenu:(id)sender
// アウトラインメニューの次の項目を選択（メニューバーからのアクションを中継）
// ------------------------------------------------------
{
    [[[self editorView] navigationBar] selectNextItem];
}




#pragma mark - Private Methods

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
    [self setEncodingCode:inEncoding];
    // ツールバーのエンコーディングメニュー、ステータスバー、ドローワを更新
    [self updateEncodingInToolbarAndInfo];
}


// ------------------------------------------------------
- (void)updateEncodingInToolbarAndInfo
// ツールバーのエンコーディングメニュー、ステータスバー、ドローワを更新
// ------------------------------------------------------
{
    // ツールバーのエンコーディングメニューを更新
    [[_windowController toolbarController] setSelectEncoding:[self encodingCode]];
    // ステータスバー、ドローワを更新
    [[self editorView] updateLineEndingsInStatusAndInfo:NO];
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
    
    // presentedItemDidChangeにて内容の同一性を比較するためにファイルのMD5を保存する
    [self setFileMD5:[theData MD5]];

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
    NSDictionary *outDict = @{NSFileHFSCreatorCode: @('cEd1'),
                              NSFileHFSTypeCode: @('TEXT')};
    return outDict;
}


// ------------------------------------------------------
- (BOOL)acceptSaveDocumentWithIANACharSetName
// IANA文字コード名を読み、設定されたエンコーディングと矛盾があれば警告する
// ------------------------------------------------------
{
    NSStringEncoding theIANACharSetEncoding = 
            [self scannedCharsetOrEncodingFromString:[[self editorView] stringForSave]];
    NSStringEncoding theShiftJIS = CFStringConvertEncodingToNSStringEncoding(kCFStringEncodingShiftJIS);
    NSStringEncoding theX0213 = CFStringConvertEncodingToNSStringEncoding(kCFStringEncodingShiftJIS_X0213_00);

    if ((theIANACharSetEncoding != NSProprietaryStringEncoding) && (theIANACharSetEncoding != [self encodingCode]) &&
            (!(((theIANACharSetEncoding == theShiftJIS) || (theIANACharSetEncoding == theX0213)) && 
            (([self encodingCode] == theShiftJIS) || ([self encodingCode] == theX0213))))) {
            // （Shift-JIS の時は要注意 = scannedCharsetOrEncodingFromString: を参照）

        NSString *theIANANameStr = [NSString localizedNameOfStringEncoding:theIANACharSetEncoding];
        NSString *theEncodingNameStr = [NSString localizedNameOfStringEncoding:[self encodingCode]];
        NSAlert *theAlert = [NSAlert alertWithMessageText:[NSString stringWithFormat:NSLocalizedString(@"The encoding is \"%@\", but the IANA charset name in text is \"%@\".", nil), theEncodingNameStr, theIANANameStr]
                                            defaultButton:NSLocalizedString(@"Cancel", nil)
                                          alternateButton:NSLocalizedString(@"Continue Saving", nil)
                                              otherButton:nil
                                informativeTextWithFormat:NSLocalizedString(@"Do you want to continue processing?", nil)];

        NSInteger theResult = [theAlert runModal];
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
    NSString *theCurString = [self convertedCharacterString:[[self editorView] stringForSave]
            withEncoding:[self encodingCode]];
    if (![theCurString canBeConvertedToEncoding:[self encodingCode]]) {
        NSString *theEncodingNameStr = [NSString localizedNameOfStringEncoding:[self encodingCode]];
        NSAlert *theAlert = [NSAlert alertWithMessageText:[NSString stringWithFormat:NSLocalizedString(@"The characters would have to be changed or deleted in saving as \"%@\".", nil), theEncodingNameStr]
                                            defaultButton:NSLocalizedString(@"Show Incompatible Char(s)", nil)
                                          alternateButton:NSLocalizedString(@"Save Available Strings", nil)
                                              otherButton:NSLocalizedString(@"Cancel", nil)
                                informativeTextWithFormat:NSLocalizedString(@"Do you want to continue processing?", nil)];

        NSInteger theResult = [theAlert runModal];
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
- (BOOL)forceWriteToURL:(NSURL *)url ofType:(NSString *)typeName forSaveOperation:(NSSaveOperationType)saveOperation
// authopenを使ってファイルを書き込む
// ------------------------------------------------------
{
    BOOL success = NO;
    NSData *data = [self dataOfType:typeName error:nil];
    
    if (data == nil) { return NO; }
    

    // 設定すべきfileAttributesを準備しておく
    NSDictionary *attributes = [self fileAttributesToWriteToURL:url
                                                         ofType:typeName
                                               forSaveOperation:saveOperation
                                            originalContentsURL:nil
                                                          error:nil];
    
    // ユーザがオーナーでないファイルに Finder Lock がかかっていたら編集／保存できない
    BOOL isFinderLockOn = NO;
    if (![self canReleaseFinderLockOfFile:[url path] isLocked:&isFinderLockOn lockAgain:NO]) {
        NSAlert *alert = [NSAlert alertWithMessageText:NSLocalizedString(@"Finder's lock could not be released.", nil)
                                         defaultButton:nil
                                       alternateButton:nil
                                           otherButton:nil
                             informativeTextWithFormat:NSLocalizedString(@"You can use \"Save As\" to save a copy.", nil)];
        [alert setAlertStyle:NSCriticalAlertStyle];
        (void)[alert runModal];
        return NO;
    }
    
    // "authopen" コマンドを使って保存
    NSString *convertedPath = @([[url path] UTF8String]);
    NSTask *task = [[[NSTask alloc] init] autorelease];

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
        // presentedItemDidChangeにて内容の同一性を比較するためにファイルのMD5を保存する
        [self setFileMD5:[data MD5]];
        
        // クリエータなどを設定
        [[NSFileManager defaultManager] setAttributes:attributes ofItemAtPath:[url path] error:nil];
        
        // ファイル拡張属性(com.apple.TextEncoding)にエンコーディングを保存
        NSString *textEncoding = [[self currentIANACharSetName] stringByAppendingFormat:@";%@",
                                  [@(CFStringConvertNSStringEncodingToEncoding([self encodingCode])) stringValue]];
        [UKXattrMetadataStore setString:textEncoding forKey:@"com.apple.TextEncoding" atPath:[url path] traverseLink:NO];
    }
    
    // Finder Lock がかかってたなら、再びかける
    if (isFinderLockOn) {
        BOOL lockSuccess = [[NSFileManager defaultManager] setAttributes:@{NSFileImmutable:@YES} ofItemAtPath:[url path] error:nil];
        success = (success && lockSuccess);
    }
    
    [self setIsWritableToEditorViewWithURL:url];
    
    return success;
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
    OSType creatorCode = [[self fileSender] typeCodeValue];
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
    
    if ([self fileToken]) {
        [theAppleEvent setParamDescriptor:[self fileToken] forKeyword:keySenderToken];
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
    OSType creatorCode = [[self fileSender] typeCodeValue];
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
    
    if ([self fileToken]) {
        [theAppleEvent setParamDescriptor:[self fileToken] forKeyword:keySenderToken];
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
    [self setIsRevertingForExternalFileUpdate:YES];
    [self setShowUpdateAlertWithBecomeKey:NO];
}


// ------------------------------------------------------
- (void)printPanelDidEnd:(NSPrintPanel *)printPanel returnCode:(NSInteger)returnCode contextInfo:(void *)contextInfo
// プリントパネルが閉じた
// ------------------------------------------------------
{
    if (returnCode != NSOKButton) { return; }

    id values = [[NSUserDefaultsController sharedUserDefaultsController] values];
    id printValues = [_windowController printValues];
    NSPrintInfo *printInfo = [self printInfo];
    NSSize paperSize = [printInfo paperSize];
    NSPrintOperation *printOperation;
    NSString *filePath = ([[values valueForKey:k_key_headerFooterPathAbbreviatingWithTilde] boolValue]) ?
                         [[[self fileURL] path] stringByAbbreviatingWithTildeInPath] : [[self fileURL] path];
    CELayoutManager *layoutManager = [[[CELayoutManager alloc] init] autorelease];
    CEPrintView *printView;
    CESyntax *printSyntax;
    CGFloat topMargin = k_printHFVerticalMargin;
    CGFloat bottomMargin = k_printHFVerticalMargin;
    BOOL doColoring = ([[printValues valueForKey:k_printColorIndex] integerValue] == 1);
    BOOL showsInvisibles = [(CELayoutManager *)[[[self editorView] textView] layoutManager] showInvisibles];
    BOOL showsControls = showsInvisibles;

    // ヘッダ／フッタの高さ（文書を印刷しない高さ）を得る
    if ([[printValues valueForKey:k_printHeader] boolValue]) {
        if ([[printValues valueForKey:k_headerOneStringIndex] integerValue] > 1) { // 行1 = 印字あり
            topMargin += k_headerFooterLineHeight;
        }
        if ([[printValues valueForKey:k_headerTwoStringIndex] integerValue] > 1) { // 行2 = 印字あり
            topMargin += k_headerFooterLineHeight;
        }
    }
    // ヘッダと本文との距離をセパレータも勘案して決定する（フッタは本文との間が開くことが多いため、入れない）
    if (topMargin > k_printHFVerticalMargin) {
        topMargin += (CGFloat)[[values valueForKey:k_key_headerFooterFontSize] doubleValue] - k_headerFooterLineHeight;
        if ([[printValues valueForKey:k_printHeaderSeparator] boolValue]) {
            topMargin += k_separatorPadding;
        } else {
            topMargin += k_noSeparatorPadding;
        }
    } else {
        if ([[printValues valueForKey:k_printHeaderSeparator] boolValue]) {
            topMargin += k_separatorPadding;
        }
    }
    if ([[printValues valueForKey:k_printFooter] boolValue]) {
        if ([[printValues valueForKey:k_footerOneStringIndex] integerValue] > 1) { // 行1 = 印字あり
            bottomMargin += k_headerFooterLineHeight;
        }
        if ([[printValues valueForKey:k_footerTwoStringIndex] integerValue] > 1) { // 行2 = 印字あり
            bottomMargin += k_headerFooterLineHeight;
        }
    }
    if ((bottomMargin == k_printHFVerticalMargin) && [[printValues valueForKey:k_printFooterSeparator] boolValue]) {
        bottomMargin += k_separatorPadding;
    }

    // プリントビュー生成
    NSRect frame = NSMakeRect(0, 0,
                              paperSize.width - (k_printTextHorizontalMargin * 2),
                              paperSize.height - topMargin - bottomMargin);
    printView = [[[CEPrintView alloc] initWithFrame:frame] autorelease];
    // 設定するフォント
    NSFont *font;
    if ([[values valueForKey:k_key_setPrintFont] integerValue] == 1) { // == プリンタ専用フォントで印字
        font = [NSFont fontWithName:[values valueForKey:k_key_printFontName]
                               size:(CGFloat)[[values valueForKey:k_key_printFontSize] doubleValue]];
    } else {
        font = [[self editorView] font];
    }
    
    // プリンタダイアログでの設定オブジェクトをコピー
    [printView setPrintValues:[[[_windowController printValues] copy] autorelease]];
    // プリントビューのテキストコンテナのパディングを固定する（印刷中に変動させるとラップの関連で末尾が印字されないことがある）
    [[printView textContainer] setLineFragmentPadding:k_printHFHorizontalMargin];
    // プリントビューに行間値／行番号表示の有無を設定
    [printView setLineSpacing:[self lineSpacingInTextView]];
    [printView setIsShowingLineNum:[[self editorView] showLineNum]];
    // 制御文字印字を取得
    if ([[printValues valueForKey:k_printInvisibleCharIndex] integerValue] == 0) { // = No print
        showsControls = NO;
    } else if ([[printValues valueForKey:k_printInvisibleCharIndex] integerValue] == 2) { // = Print all
        showsControls = YES;
    }
    // layoutManager を入れ替え
    [layoutManager setTextFont:font];
    [layoutManager setFixLineHeight:NO];
    [layoutManager setIsPrinting:YES];
    [layoutManager setShowInvisibles:showsInvisibles];
    [layoutManager setShowsControlCharacters:showsControls];
    [[printView textContainer] replaceLayoutManager:layoutManager];

    if (doColoring) {
        // カラーリング実行オブジェクトを用意
        printSyntax = [[[CESyntax allocWithZone:[self zone]] init] autorelease];
        [printSyntax setSyntaxStyleName:[[_windowController toolbarController] selectedTitleOfSyntaxItem]];
        [printSyntax setLayoutManager:layoutManager];
        [printSyntax setIsPrinting:YES];
    }

    // ドキュメントが未保存ならウィンドウ名をパスとして設定
    if (filePath == nil) {
        filePath = [self displayName];
    }
    [printView setFilePath:filePath];

    // PrintInfo 設定
    [printInfo setHorizontalPagination:NSFitPagination];
    [printInfo setHorizontallyCentered:NO];
    [printInfo setVerticallyCentered:NO];
    [printInfo setLeftMargin:k_printTextHorizontalMargin];
    [printInfo setRightMargin:k_printTextHorizontalMargin];
    // ???: どこかで天地がflipしているのでbottomとtopのmarginを入れ替えている (2014-03-11 by 1024jp)
    [printInfo setTopMargin:bottomMargin];
    [printInfo setBottomMargin:topMargin];

    // プリントビューの設定
    [printView setFont:font];
    if (doColoring) { // カラーリングする
        [printView setTextColor:[NSUnarchiver unarchiveObjectWithData:[values valueForKey:k_key_textColor]]];
        [printView setBackgroundColor:[NSUnarchiver unarchiveObjectWithData:[values valueForKey:k_key_backgroundColor]]];
    } else {
        [printView setTextColor:[NSColor blackColor]];
        [printView setBackgroundColor:[NSColor whiteColor]];
    }
    // プリントビューへ文字列を流し込む
    [printView setString:[[self editorView] string]];
    if (doColoring) { // カラーリングする
// 現状では、印刷するページ数に関係なく全ページがカラーリングされている。20080104*****
        [printSyntax colorAllString:[[self editorView] string]];
    }
    // プリントオペレーション生成、設定、プリント実行
    printOperation = [NSPrintOperation printOperationWithView:printView printInfo:printInfo];
    // プリントパネルの表示を制御し、プログレスパネルは表示させる
    [printOperation setShowsPrintPanel:NO];
    [printOperation setShowsProgressPanel:YES];
    [printOperation runOperation];
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
- (void)setIsWritableToEditorViewWithURL:(NSURL *)url
// 書き込み可能かを EditorView にセット
// ------------------------------------------------------
{
    BOOL isWritable = YES; // default = YES
    
    if ([url checkResourceIsReachableAndReturnError:nil]) {
        isWritable = [[NSFileManager defaultManager] isWritableFileAtPath:[url path]];
    }
    [[self editorView] setIsWritable:isWritable];
}


// ------------------------------------------------------
- (void)showAlertForNotWritable
// EditorView で、書き込み禁止アラートを表示
// ------------------------------------------------------
{
    [[self editorView] alertForNotWritable];
}



@end
