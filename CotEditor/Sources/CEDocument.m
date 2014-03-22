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
 
 ____This_class_is_under_MRC____
 
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
#import "constants.h"



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

@property (readwrite) CEWindowController *windowController;
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
        NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults ];

        [self setHasUndoManager:YES];
        (void)[self doSetEncoding:[defaults integerForKey:k_key_encodingInNew]
                   updateDocument:NO askLossy:NO lossy:NO asActionName:nil];
        _selection = [[CETextSelection alloc] initWithDocument:self]; // ===== alloc
        [self setCanActivateShowInvisibleCharsItem:
                [defaults boolForKey:k_key_showInvisibleSpace] ||
                [defaults boolForKey:k_key_showInvisibleTab] ||
                [defaults boolForKey:k_key_showInvisibleNewLine] ||
                [defaults boolForKey:k_key_showInvisibleFullwidthSpace] ||
                [defaults boolForKey:k_key_showOtherInvisibleChars]];
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
    [self setWindowController:[[CEWindowController alloc] initWithWindowNibName:@"DocWindow"]]; // ===== alloc
    [self addWindowController:[self windowController]];
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
    BOOL shouldAppendBOM = [[NSUserDefaults standardUserDefaults] boolForKey:k_key_saveUTF8BOM];
    
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
- (BOOL)revertToContentsOfURL:(NSURL *)url ofType:(NSString *)typeName error:(NSError **)outError
// セーブ時の状態に戻す
// ------------------------------------------------------
{
    // 認証が必要な時に重なって表示されるのを避けるため、まず復帰確認シートを片づける
    //（外部プロセスによる変更通知アラートシートはそのままに）
    if (![self isRevertingForExternalFileUpdate]) {
        [[[self windowForSheet] attachedSheet] orderOut:self];
    }

    BOOL outResult = [self readFromURL:url withEncoding:k_autoDetectEncodingMenuTag];

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
- (BOOL)prepareSavePanel:(NSSavePanel *)savePanel
// セーブパネルを準備
// ------------------------------------------------------
{
    // ファイル名に拡張子がない場合は追加する
    if ([[NSUserDefaults standardUserDefaults] boolForKey:k_key_appendExtensionAtSaving]) {
        if ([[[savePanel nameFieldStringValue] pathExtension] isEqualToString:@""]) {
            [savePanel setAllowedFileTypes:@[@"txt", @"****"]];  // ****も指定することで別の拡張子を入れたときのアラートを抑制している
        }
    }
    
    return [super prepareSavePanel:savePanel];
}


// ------------------------------------------------------
- (BOOL)readFromURL:(NSURL *)url ofType:(NSString *)typeName error:(NSError **)outError
// ファイルを読み込み、成功したかどうかを返す
// ------------------------------------------------------
{
    // フォルダをアイコンにドロップしても開けないようにする
    BOOL isDirectory = NO;
    (void)[[NSFileManager defaultManager] fileExistsAtPath:[url path] isDirectory:&isDirectory];
    if (isDirectory) { return NO; }
    
    // 外部エディタプロトコル(ODB Editor Suite)用の値をセット
    [self setupODB];
    
    NSStringEncoding encoding = [[CEDocumentController sharedDocumentController] accessorySelectedEncoding];

    return [self readFromURL:url withEncoding:encoding];
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
        ![self canReleaseFinderLockAtURL:[self fileURL] isLocked:nil lockAgain:YES]) {

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
    
    [_selection autorelease]; // （互いに参照しあっているため、dealloc でなく、ここで開放しておく）
    [self removeWindowController:(NSWindowController *)[self windowController]];

    [super close];
}


#pragma mark Public Methods

//=======================================================
// Public method
//
//=======================================================

//------------------------------------------------------
- (BOOL)stringFromData:(NSData *)data encoding:(NSStringEncoding)encoding xattr:(BOOL)boolXattr
// データから指定エンコードで文字列を得る
//------------------------------------------------------
{
    NSString *string = nil;
    BOOL shouldSkipISO2022JP = NO;
    BOOL shouldSkipUTF8 = NO;
    BOOL shouldSkipUTF16 = NO;

    // ISO 2022-JP / UTF-8 / UTF-16の判定は、「藤棚工房別棟 −徒然−」の
    // 「Cocoaで文字エンコーディングの自動判別プログラムを書いてみました」で公開されている
    // FJDDetectEncoding を参考にさせていただきました (2006.09.30)
    // http://blogs.dion.ne.jp/fujidana/archives/4169016.html

    // 10.5+でのファイル拡張属性(com.apple.TextEncoding)を試す
    if (boolXattr && (encoding != k_autoDetectEncodingMenuTag)) {
        string = [[[NSString alloc] initWithData:data encoding:encoding] autorelease];
        if (string == nil) {
            encoding = k_autoDetectEncodingMenuTag;
        }
    }

    if (([data length] > 0) && (encoding == k_autoDetectEncodingMenuTag)) {
        const char utf8Bom[] = {0xef, 0xbb, 0xbf}; // UTF-8 BOM
        // BOM付きUTF-8判定
        if (memchr([data bytes], *utf8Bom, 3) != NULL) {
            shouldSkipUTF8 = YES;
            string = [[[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding] autorelease];
            if (string != nil) {
                encoding = NSUTF8StringEncoding;
            }
        // UTF-16判定
        } else if ((memchr([data bytes], 0xfffe, 2) != NULL) ||
                   (memchr([data bytes], 0xfeff, 2) != NULL)) {

            shouldSkipUTF16 = YES;
            string = [[[NSString alloc] initWithData:data encoding:NSUnicodeStringEncoding] autorelease];
            if (string != nil) {
                encoding = NSUnicodeStringEncoding;
            }

        // ISO 2022-JP判定
        } else if (memchr([data bytes], 0x1b, [data length]) != NULL) {
            shouldSkipISO2022JP = YES;
            string = [[[NSString alloc] initWithData:data encoding:NSISO2022JPStringEncoding] autorelease];
            if (string != nil) {
                encoding = NSISO2022JPStringEncoding;
            }
        }
    }

    if ((string == nil) && (encoding == k_autoDetectEncodingMenuTag)) {
        NSArray *encodings = [[[[NSUserDefaults standardUserDefaults] arrayForKey:k_key_encodingList] copy] autorelease];
        NSInteger i = 0;

        while (string == nil) {
            encoding = CFStringConvertEncodingToNSStringEncoding([encodings[i] unsignedLongValue]);
            if ((encoding == NSISO2022JPStringEncoding) && shouldSkipISO2022JP) {
                break;
            } else if ((encoding == NSUTF8StringEncoding) && shouldSkipUTF8) {
                break;
            } else if ((encoding == NSUnicodeStringEncoding) && shouldSkipUTF16) {
                break;
            } else if (encoding == NSProprietaryStringEncoding) {
                NSLog(@"theEncoding == NSProprietaryStringEncoding");
                break;
            }
            string = [[[NSString alloc] initWithData:data encoding:encoding] autorelease];
            if (string != nil) {
                // "charset="や"encoding="を読んでみて適正なエンコーディングが得られたら、そちらを優先
                NSStringEncoding tmpEncoding = [self scannedCharsetOrEncodingFromString:string];
                if ((tmpEncoding == NSProprietaryStringEncoding) || (tmpEncoding == encoding)) {
                    break;
                }
                NSString *tmpStr = [[[NSString alloc] initWithData:data encoding:tmpEncoding] autorelease];
                if (tmpStr != nil) {
                    string = tmpStr;
                    encoding = tmpEncoding;
                }
            }
            i++;
        }
    } else if (string == nil) {
        string = [[[NSString alloc] initWithData:data encoding:encoding] autorelease];
    }

    if ((string != nil) && (encoding != k_autoDetectEncodingMenuTag)) {
        // 10.3.9 で、一部のバイナリファイルを開いたときにクラッシュする問題への暫定対応。
        // 10.4+ ではスルー（2005.12.25）
        // ＞＞ しかし「すべて2バイト文字で4096文字以上あるユニコードでない文書」は開けない（2005.12.25）
        // (下記の現象と同じ理由で発生していると思われる）
        // https://www.codingmonkeys.de/bugs/browse/HYR-529?page=all
        if (([data length] <= 8192) ||
            (([data length] > 8192) && ([data length] != ([string length] * 2 + 1)) &&
             ([data length] != ([string length] * 2)))) {
                    
            [self setInitialString:string];
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
    return [[self initialString] autorelease]; // ===== autorelease
}


// ------------------------------------------------------
- (void)setStringToEditorView
// editorView に文字列をセット
// ------------------------------------------------------
{
    [self setColoringExtension:[[self fileURL] pathExtension] coloring:NO];
    [self setStringToTextView:[self stringToWindowController]];
    if ([[self windowController] needsIncompatibleCharDrawerUpdate]) {
        [[self windowController] showIncompatibleCharList];
    }
    [self setIsWritableToEditorViewWithURL:[self fileURL]];
}


// ------------------------------------------------------
- (void)setStringToTextView:(NSString *)string
// 新たな文字列をセット
// ------------------------------------------------------
{
    if (string) {
        OgreNewlineCharacter lineEnding = [OGRegularExpression newlineCharacterInString:string];
        [self setLineEndingCharToView:lineEnding]; // for update toolbar item
        [[self editorView] setString:string]; // （editorView の setString 内でキャレットを先頭に移動させている）
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
- (BOOL)doSetEncoding:(NSStringEncoding)encoding updateDocument:(BOOL)updateDocument
        askLossy:(BOOL)askLossy  lossy:(BOOL)lossy  asActionName:(NSString *)actionName
// 新規エンコーディングをセット
// ------------------------------------------------------
{
    if (encoding == [self encodingCode]) {
        return YES;
    }
    NSInteger result = NSAlertOtherReturn;
    BOOL shouldShowList = NO;
    if (updateDocument) {

        shouldShowList = [[self windowController] needsIncompatibleCharDrawerUpdate];
        NSString *curString = [[self editorView] stringForSave];
        BOOL allowsLossy = NO;

        if (askLossy) {
            if (![curString canBeConvertedToEncoding:encoding]) {
                NSString *encodingNameStr = [NSString localizedNameOfStringEncoding:encoding];
                NSString *messageText = [NSString stringWithFormat:NSLocalizedString(@"The characters would have to be changed or deleted in saving as \"%@\".", nil), encodingNameStr];
                NSAlert *alert = [NSAlert alertWithMessageText:messageText
                                                 defaultButton:NSLocalizedString(@"Cancel", nil)
                                               alternateButton:NSLocalizedString(@"Change Encoding", nil)
                                                   otherButton:nil
                                     informativeTextWithFormat:NSLocalizedString(@"Do you want to change encoding and show incompatible character(s)?", nil)];

                result = [alert runModal];
                if (result == NSAlertDefaultReturn) { // == Cancel
                    return NO;
                }
                shouldShowList = YES;
                allowsLossy = YES;
            }
        } else {
            allowsLossy = lossy;
        }
        // Undo登録
        NSUndoManager *undoManager = [self undoManager];
        [[undoManager prepareWithInvocationTarget:self]
                    redoSetEncoding:encoding updateDocument:updateDocument 
                    askLossy:NO lossy:allowsLossy asActionName:actionName]; // undo内redo
        if (shouldShowList) {
            [[undoManager prepareWithInvocationTarget:[self windowController]] showIncompatibleCharList];
        }
        [[undoManager prepareWithInvocationTarget:self] doSetEncoding:[self encodingCode]]; // エンコード値設定
        [[undoManager prepareWithInvocationTarget:self] updateChangeCount:NSChangeUndone]; // changeCount減値
        if (actionName) {
            [undoManager setActionName:actionName];
        }
        [self updateChangeCount:NSChangeDone];
    }
    [self doSetEncoding:encoding];
    if (shouldShowList) {
        [[self windowController] showIncompatibleCharList];
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
- (NSArray *)markupCharCanNotBeConvertedToEncoding:(NSStringEncoding)encoding
// 指定されたエンコードにコンバートできない文字列をマークアップし、その配列を返す
// ------------------------------------------------------
{
    NSMutableArray *outArray = [NSMutableArray array];
    NSString *wholeString = [[self editorView] stringForSave];
    NSUInteger wholeLength = [wholeString length];
    NSData *data = [wholeString dataUsingEncoding:encoding allowLossyConversion:YES];
    NSString *convertedString = [[[NSString alloc] initWithData:data encoding:encoding] autorelease];

    if ((convertedString == nil) || ([convertedString length] != wholeLength)) { // 正しいリストが取得できない時
        return nil;
    }

    // 現存の背景色カラーリングをすべて削除（検索のハイライトも削除される）
    [self clearAllMarkupForIncompatibleChar];

    // 削除／変換される文字をリストアップ
    NSArray *managers = [[self editorView] allLayoutManagers];
    NSColor *foreColor = [NSUnarchiver unarchiveObjectWithData:[[NSUserDefaults standardUserDefaults] valueForKey:k_key_textColor]];
    NSColor *backColor = [NSUnarchiver unarchiveObjectWithData:[[NSUserDefaults standardUserDefaults] valueForKey:k_key_backgroundColor]];
    NSColor *incompatibleColor;
    NSDictionary *attrs;
    NSString *curChar, *convertedChar;
    NSString *yenMarkChar = [NSString stringWithCharacters:&k_yenMark length:1];
    unichar wholeUnichar, convertedUnichar;
    NSUInteger i, lines, index, curLine;
    CGFloat BG_R, BG_G, BG_B, F_R, F_G, F_B;

    // 文字色と背景色の中間色を得る
    [[foreColor colorUsingColorSpaceName:NSCalibratedRGBColorSpace] getRed:&F_R green:&F_G blue:&F_B alpha:nil];
    [[backColor colorUsingColorSpaceName:NSCalibratedRGBColorSpace] getRed:&BG_R green:&BG_G blue:&BG_B alpha:nil];
    incompatibleColor = [NSColor colorWithCalibratedRed:((BG_R + F_R) / 2)
                                                  green:((BG_G + F_G) / 2)
                                                   blue:((BG_B + F_B) / 2)
                                                  alpha:1.0];
    attrs = @{NSBackgroundColorAttributeName: incompatibleColor};

    for (i = 0; i < wholeLength; i++) {
        wholeUnichar = [wholeString characterAtIndex:i];
        convertedUnichar = [convertedString characterAtIndex:i];
        if (wholeUnichar != convertedUnichar) {
            curChar = [wholeString substringWithRange:NSMakeRange(i, 1)];
            convertedChar = [convertedString substringWithRange:NSMakeRange(i, 1)];

            if (([[NSApp delegate] isInvalidYenEncoding:encoding]) && 
                    ([curChar isEqualToString:yenMarkChar])) {
                curChar = yenMarkChar;
                convertedChar = @"\\";
            }

            for (NSLayoutManager *manager in managers) {
                [manager addTemporaryAttributes:attrs forCharacterRange:NSMakeRange(i, 1)];
            }
            curLine = 1;
            for (index = 0, lines = 0; index < wholeLength; lines++) {
                if (index <= i) {
                    curLine = lines + 1;
                } else {
                    break;
                }
                index = NSMaxRange([wholeString lineRangeForRange:NSMakeRange(index, 0)]);
            }
            [outArray addObject:[@{k_listLineNumber: @(curLine),
                                   k_incompatibleRange: [NSValue valueWithRange:NSMakeRange(i, 1)],
                                   k_incompatibleChar: curChar,
                                   k_convertedChar: convertedChar} mutableCopy]];
        }
    }
    return outArray;
}


// ------------------------------------------------------
- (void)doSetNewLineEndingCharacterCode:(NSInteger)newLineEnding
// 行末コードを変更する
// ------------------------------------------------------
{
    NSInteger currentEnding = [[self editorView] lineEndingCharacter];

    // 現在と同じ行末コードなら、何もしない
    if (currentEnding == newLineEnding) {
        return;
    }

    NSArray *lineEndingNames = @[k_lineEndingNames];
    NSString *actionName = [NSString stringWithFormat:NSLocalizedString(@"Line Endings to \"%@\"",@""),lineEndingNames[newLineEnding]];

    // Undo登録
    NSUndoManager *undoManager = [self undoManager];
    [[undoManager prepareWithInvocationTarget:self] 
                redoSetNewLineEndingCharacterCode:newLineEnding]; // undo内redo
    [[undoManager prepareWithInvocationTarget:self] setLineEndingCharToView:currentEnding]; // 元の行末コード
    [[undoManager prepareWithInvocationTarget:self] updateChangeCount:NSChangeUndone]; // changeCountデクリメント
    [undoManager setActionName:actionName];

    [self setLineEndingCharToView:newLineEnding];
    [self updateChangeCount:NSChangeDone]; // changeCountインクリメント
}


// ------------------------------------------------------
- (void)setLineEndingCharToView:(NSInteger)newLineEnding
// 行末コード番号をセット
// ------------------------------------------------------
{
    [[self editorView] setLineEndingCharacter:newLineEnding];
    [[[self windowController] toolbarController] setSelectEndingItemIndex:newLineEnding];
}


// ------------------------------------------------------
- (void)doSetSyntaxStyle:(NSString *)name
// 新しいシンタックスカラーリングスタイルを適用
// ------------------------------------------------------
{
    if ([name length] > 0) {
        [[self editorView] setSyntaxStyleNameToColoring:name recolorNow:YES];
        [[[self windowController] toolbarController] setSelectSyntaxItemWithTitle:name];
    }
}


// ------------------------------------------------------
- (void)doSetSyntaxStyle:(NSString *)name delay:(BOOL)needsDelay
// ディレイをかけて新しいシンタックスカラーリングスタイルを適用（ほぼNone専用）
// ------------------------------------------------------
{
    if (needsDelay) {
        if ([name length] > 0) {
            [[self editorView] setSyntaxStyleNameToColoring:name recolorNow:NO];
            [[[self windowController] toolbarController]
                    performSelector:@selector(setSelectSyntaxItemWithTitle:) withObject:name afterDelay:0];
        }
    } else {
        [self doSetSyntaxStyle:name];
    }
    
}


// ------------------------------------------------------
- (void)setColoringExtension:(NSString *)extension coloring:(BOOL)doColoring
// editorViewを通じてcoloringStyleインスタンスにドキュメント拡張子をセット
// ------------------------------------------------------
{
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    if (![defaults boolForKey:k_key_doColoring]) { return; }

    BOOL shouldUpdated = [[self editorView] setSyntaxExtension:extension];

    if (shouldUpdated) {
        // ツールバーのカラーリングポップアップの表示を更新、再カラーリング
        NSString *name = [[CESyntaxManager sharedInstance] syntaxNameFromExtension:extension];
        name = (!name || [name isEqualToString:@""]) ? [defaults stringForKey:k_key_defaultColoringStyleName]: name;
        [[[self windowController] toolbarController] setSelectSyntaxItemWithTitle:name];
        if (doColoring) {
            [self recoloringAllStringOfDocument:nil];
        }
    }
}


// ------------------------------------------------------
- (NSRange)rangeInTextViewWithLocation:(NSInteger)location withLength:(NSInteger)length
// マイナス指定された文字範囲／長さをNSRangeにコンバートして返す
// ------------------------------------------------------
{
    CETextViewCore *textView = [[self editorView] textView];
    NSUInteger wholeLength = [[textView string] length];
    NSInteger newLocation, newLength;
    NSRange range = NSMakeRange(0, 0);

    newLocation = (location < 0) ? (wholeLength + location) : location;
    newLength = (length < 0) ? (wholeLength - newLocation + length) : length;
    if ((newLocation < wholeLength) && ((newLocation + newLength) > wholeLength)) {
        newLength = wholeLength - newLocation;
    }
    if ((length < 0) && (newLength < 0)) {
        newLength = 0;
    }
    if ((newLocation < 0) || (newLength < 0)) {
        return range;
    }
    range = NSMakeRange(newLocation, newLength);
    if (wholeLength >= NSMaxRange(range)) {
        return range;
    }
    return range;
}


// ------------------------------------------------------
- (void)setSelectedCharacterRangeInTextViewWithLocation:(NSInteger)location withLength:(NSInteger)length
// editorView 内部の textView で指定された部分を文字単位で選択
// ------------------------------------------------------
{
    NSRange selectionRange = [self rangeInTextViewWithLocation:location withLength:length];

    [[self editorView] setSelectedRange:selectionRange];
}


// ------------------------------------------------------
- (void)setSelectedLineRangeInTextViewWithLocation:(NSInteger)location withLength:(NSInteger)length
// editorView 内部の textView で指定された部分を行単位で選択
// ------------------------------------------------------
{
    CETextViewCore *textView = [[self editorView] textView];
    NSUInteger wholeLength = [[textView string] length];
    OGRegularExpression *regex = [OGRegularExpression regularExpressionWithString:@"^"];
    NSArray *matches = [regex allMatchesInString:[textView string]];

    if (matches) {
        NSInteger count = [matches count];
        if (location == 0) {
            [textView setSelectedRange:NSMakeRange(0, 0)];
        } else if (location > count) {
            [textView setSelectedRange:NSMakeRange(wholeLength, 0)];
        } else {
            NSInteger newLocation, newLength;

            newLocation = (location < 0) ? (count + location + 1) : location;
            if (length < 0) {
                newLength = count - newLocation + length + 1;
            } else if (length == 0) {
                newLength = 1;
            } else {
                newLength = length;
            }
            if ((newLocation < count) && ((newLocation + newLength - 1) > count)) {
                newLength = count - newLocation + 1;
            }
            if ((length < 0) && (newLength < 0)) {
                newLength = 1;
            }
            if ((newLocation <= 0) || (newLength <= 0)) { return; }

            OGRegularExpressionMatch *match = matches[(newLocation - 1)];
            NSRange range = [match rangeOfMatchedString];
            NSRange tmpRange = range;
            NSInteger i;

            for (i = 0; i < newLength; i++) {
                if (NSMaxRange(tmpRange) > wholeLength) {
                    break;
                }
                range = [[textView string] lineRangeForRange:tmpRange];
                tmpRange.length = range.length + 1;
            }
            if (wholeLength < NSMaxRange(range)) {
                range.length = wholeLength - range.location;
            }
            [textView setSelectedRange:range];
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
- (void)gotoLocation:(NSInteger)location withLength:(NSInteger)length type:(CEGoToType)type
// 選択範囲を変更する
// ------------------------------------------------------
{
    switch (type) {
        case CEGoToLine:
            [self setSelectedLineRangeInTextViewWithLocation:location withLength:length];
            break;
        case CEGoToCharacter:
            [self setSelectedCharacterRangeInTextViewWithLocation:location withLength:length];
            break;
    }
    [self scrollToCenteringSelection]; // 選択範囲が見えるようにスクロール
    [[[self editorView] textView] showFindIndicatorForRange:[[[self editorView] textView] selectedRange]];  // 検索結果表示エフェクトを追加
    [[[self windowController] window] makeKeyAndOrderFront:self]; // 対象ウィンドウをキーに
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
        [[self windowController] updateFileAttrsInformation];
    }
}


// ------------------------------------------------------
- (void)rebuildToolbarEncodingItem
// toolbar のエンコーディングメニューアイテムを再生成する
// ------------------------------------------------------
{
    [[[self windowController] toolbarController] buildEncodingPopupButton];
    [[[self windowController] toolbarController] setSelectEncoding:[self encodingCode]];
}


// ------------------------------------------------------
- (void)rebuildToolbarSyntaxItem
// toolbar のシンタックスカラーリングメニューアイテムを再生成する
// ------------------------------------------------------
{
    NSString *title = [[[self windowController] toolbarController] selectedTitleOfSyntaxItem];

    [[[self windowController] toolbarController] buildSyntaxPopupButton];
    [[[self windowController] toolbarController] setSelectSyntaxItemWithTitle:title];
}


// ------------------------------------------------------
- (void)setRecolorFlagToWindowControllerWithStyleName:(NSDictionary *)styleNameDict
// 指定されたスタイルを適用していたら、WindowController のリカラーフラグを立てる
// ------------------------------------------------------
{
    NSString *oldName = styleNameDict[k_key_oldStyleName];
    NSString *newName = styleNameDict[k_key_newStyleName];
    NSString *curStyleName = [[self editorView] syntaxStyleNameToColoring];

    if ([oldName isEqualToString:curStyleName]) {
        if (oldName && newName && ![oldName isEqualToString:newName]) {
            [[self editorView] setSyntaxStyleNameToColoring:newName recolorNow:NO];
        }
        [[self windowController] setRecolorWithBecomeKey:YES];
    }
}


// ------------------------------------------------------
- (void)setStyleToNoneAndRecolorFlagWithStyleName:(NSString *)styleName
// 指定されたスタイルを適用していたら WindowController のリカラーフラグを立て、スタイル名を"None"にする
// ------------------------------------------------------
{
    NSString *curStyleName = [[self editorView] syntaxStyleNameToColoring];

    // 指定されたスタイル名と違ったら、無視
    if ([curStyleName isEqualToString:styleName]) {
        [[self windowController] setRecolorWithBecomeKey:YES];
        [[self editorView] setSyntaxStyleNameToColoring:NSLocalizedString(@"None",@"") recolorNow:NO];
    }
}


// ------------------------------------------------------
- (void)setSmartInsertAndDeleteToTextView
// スマートインサート／デリートをするかどうかをテキストビューへ設定
// ------------------------------------------------------
{
    BOOL enabled = [[NSUserDefaults standardUserDefaults] boolForKey:k_key_smartInsertAndDelete];
    
    [[[self editorView] textView] setSmartInsertDeleteEnabled:enabled];
}


// ------------------------------------------------------
- (void)setSmartQuotesToTextView
// スマート引用符／ダッシュを有効にするかどうかをテキストビューへ設定
// ------------------------------------------------------
{
    BOOL enabled = [[NSUserDefaults standardUserDefaults] boolForKey:k_key_enableSmartQuotes];
    
    [[[self editorView] textView] setAutomaticQuoteSubstitutionEnabled:enabled];
    [[[self editorView] textView] setAutomaticDashSubstitutionEnabled:enabled];
}


// ------------------------------------------------------
- (NSString *)currentIANACharSetName
// 設定されたエンコーディングの IANA Charset 名を返す
// ------------------------------------------------------
{
    NSString *charSetName = nil;
    CFStringEncoding cfEncoding = CFStringConvertNSStringEncodingToEncoding([self encodingCode]);

    if (cfEncoding != kCFStringEncodingInvalidId) {
        charSetName = (NSString *)CFStringConvertEncodingToIANACharSetName(cfEncoding);
    }
    return charSetName;
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



#pragma mark Protocols

//=======================================================
// NSMenuValidation Protocol
//
//=======================================================

// ------------------------------------------------------
- (BOOL)validateMenuItem:(NSMenuItem *)menuItem
// メニュー項目の有効・無効を制御
// ------------------------------------------------------
{
    NSInteger state = NSOffState;
    NSString *name;

    if ([menuItem action] == @selector(saveDocument:)) {
        // 書き込み不可の時は、アラートが表示され「OK」されるまで保存メニューを無効化する
        if ((![[self editorView] isWritable]) && (![[self editorView] isAlertedNotWritable])) {
            return NO;
        }
    } else if ([menuItem action] == @selector(selectPrevItemOfOutlineMenu:)) {
        return ([[[self editorView] navigationBar] canSelectPrevItem]);
    } else if ([menuItem action] == @selector(selectNextItemOfOutlineMenu:)) {
        return ([[[self editorView] navigationBar] canSelectNextItem]);
    } else if ([menuItem action] == @selector(setEncoding:)) {
        state = ([menuItem tag] == [self encodingCode]) ? NSOnState : NSOffState;
    } else if (([menuItem action] == @selector(setLineEndingCharToLF:)) ||
               ([menuItem action] == @selector(setLineEndingCharToCR:)) ||
               ([menuItem action] == @selector(setLineEndingCharToCRLF:))) {
        state = ([menuItem tag] == [[self editorView] lineEndingCharacter]) ? NSOnState : NSOffState;
    } else if ([menuItem action] == @selector(setSyntaxStyle:)) {
        name = [[self editorView] syntaxStyleNameToColoring];
        if (name && [[menuItem title] isEqualToString:name]) {
            state = NSOnState;
        }
    } else if ([menuItem action] == @selector(recoloringAllStringOfDocument:)) {
        name = [[self editorView] syntaxStyleNameToColoring];
        if (name && [name isEqualToString:NSLocalizedString(@"None",@"")]) {
            return NO;
        }
    }
    [menuItem setState:state];

    return [super validateMenuItem:menuItem];
}



//=======================================================
// NSToolbarItemValidation Protocol
//
//=======================================================

// ------------------------------------------------------
-(BOOL)validateToolbarItem:(NSToolbarItem *)item
// ツールバー項目の有効・無効を制御
// ------------------------------------------------------
{
    if ([[item itemIdentifier] isEqualToString:k_syntaxReColorAllItemID]) {
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
    // アプリがアクティブならシート／ダイアログを表示し、そうでなければ設定を見てDockアイコンをジャンプ
    if ([NSApp isActive]) {
        [self performSelectorOnMainThread:@selector(showUpdatedByExternalProcessAlert) withObject:nil waitUntilDone:NO];
        
    } else if ([[NSUserDefaults standardUserDefaults] boolForKey:k_key_notifyEditByAnother]) {
        [NSApp requestUserAttention:NSInformationalRequest];
    }
}


//=======================================================
// Notification method (CESplitView)
//  <== CESplitView
//=======================================================


// ------------------------------------------------------
- (void)documentDidFinishOpen:(NSNotification *)notification
// 書類オープン処理が完了した
// ------------------------------------------------------
{
    if ([notification object] != [self editorView]) { return; }

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

    [printPanel setAccessoryView:[[self windowController] printAccessoryView]];
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
    NSStringEncoding encoding = [sender tag];

    if ((encoding < 1) || (encoding == [self encodingCode])) {
        return;
    }
    NSInteger result;
    NSString *encodingName = [sender title];

    // 文字列がないまたは未保存の時は直ちに変換プロセスへ
    if (([[[self editorView] string] length] < 1) || (![self fileURL])) {
        result = NSAlertDefaultReturn;
    } else {
        // 変換するか再解釈するかの選択ダイアログを表示
        NSAlert *alert = [NSAlert alertWithMessageText:NSLocalizedString(@"File encoding", nil)
                                         defaultButton:NSLocalizedString(@"Convert", nil)
                                       alternateButton:NSLocalizedString(@"Reinterpret", nil)
                                           otherButton:NSLocalizedString(@"Cancel", nil)
                             informativeTextWithFormat:NSLocalizedString(@"Do you want to convert or reinterpret it using \"%@\"?", nil), encodingName];

        result = [alert runModal];
    }
    if (result == NSAlertDefaultReturn) { // = Convert 変換

        NSString *actionName = [NSString stringWithFormat:NSLocalizedString(@"Encoding to \"%@\"",@""),
                    [NSString localizedNameOfStringEncoding:encoding]];

        (void)[self doSetEncoding:encoding updateDocument:YES askLossy:YES lossy:NO asActionName:actionName];

    } else if (result == NSAlertAlternateReturn) { // = Reinterpret 再解釈

        if (![self fileURL]) { return; } // まだファイル保存されていない時（ファイルがない時）は、戻る
        if ([self isDocumentEdited]) {
            NSAlert *secondAlert = [NSAlert alertWithMessageText:[NSString stringWithFormat:NSLocalizedString(@"The file \'%@\' has unsaved changes.", nil), [[self fileURL] path]]
                                                   defaultButton:NSLocalizedString(@"Cancel", nil)
                                                 alternateButton:NSLocalizedString(@"Discard Changes", nil)
                                                     otherButton:nil
                                       informativeTextWithFormat:NSLocalizedString(@"Do you want to discard the changes and reset the file encodidng?", nil)];

            NSInteger secondResult = [secondAlert runModal];
            if (secondResult != NSAlertAlternateReturn) { // != Discard Change
                // ツールバーから変更された場合のため、ツールバーアイテムの選択状態をリセット
                [[[self windowController] toolbarController] setSelectEncoding:[self encodingCode]];
                return;
            }
        }
        if ([self readFromURL:[self fileURL] withEncoding:encoding]) {
            [self setStringToEditorView];
            // アンドゥ履歴をクリア
            [[self undoManager] removeAllActions];
            [self updateChangeCount:NSChangeCleared];
        } else {
            NSAlert *thirdAlert = [NSAlert alertWithMessageText:NSLocalizedString(@"Can not reinterpret", nil)
                                                  defaultButton:NSLocalizedString(@"Done", nil)
                                                alternateButton:nil
                                                    otherButton:nil
                                      informativeTextWithFormat:NSLocalizedString(@"The file \'%@\' could not be reinterpreted using the new encoding \"%@\".", nil), [[self fileURL] path], encodingName];
            [thirdAlert setAlertStyle:NSCriticalAlertStyle];

            NSBeep();
            (void)[thirdAlert runModal];
        }
    }
    // ツールバーから変更された場合のため、ツールバーアイテムの選択状態をリセット
    [[[self windowController] toolbarController] setSelectEncoding:[self encodingCode]];
}


// ------------------------------------------------------
- (IBAction)setSyntaxStyle:(id)sender
// 新しいシンタックスカラーリングスタイルを適用
// ------------------------------------------------------
{
    NSString *name = [sender title];

    if (name && ([name length] > 0)) {
        [self doSetSyntaxStyle:name];
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
- (IBAction)insertIANACharSetName:(id)sender
// IANA文字コード名を挿入する
// ------------------------------------------------------
{
    NSString *string = [self currentIANACharSetName];

    if (string) {
        [[[self editorView] textView] insertText:string];
    }
}


// ------------------------------------------------------
- (IBAction)insertIANACharSetNameWithCharset:(id)sender
// IANA文字コード名を挿入する
// ------------------------------------------------------
{
    NSString *string = [self currentIANACharSetName];

    if (string) {
        [[[self editorView] textView] insertText:[NSString stringWithFormat:@"charset=\"%@\"", string]];
    }
}


// ------------------------------------------------------
- (IBAction)insertIANACharSetNameWithEncoding:(id)sender
// IANA文字コード名を挿入する
// ------------------------------------------------------
{
    NSString *string = [self currentIANACharSetName];

    if (string) {
        [[[self editorView] textView] insertText:[NSString stringWithFormat:@"encoding=\"%@\"", string]];
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




#pragma mark Private Methods

//=======================================================
// Private method
//
//=======================================================

// ------------------------------------------------------
- (NSString *)convertedCharacterString:(NSString *)string withEncoding:(NSStringEncoding)encoding
// 半角円マークを使えないエンコードの時はバックスラッシュに変換した文字列を返す
// ------------------------------------------------------
{
    NSUInteger length = [string length];

    if (length > 0) {
        NSMutableString *outString = [string mutableCopy]; // ===== mutableCopy
        if ([[NSApp delegate] isInvalidYenEncoding:encoding]) {
            (void)[outString replaceOccurrencesOfString:
                        [NSString stringWithCharacters:&k_yenMark length:1] withString:@"\\" 
                        options:0 range:NSMakeRange(0, length)];
        }
        return [outString autorelease]; // autorelease
    } else {
        return string;
    }
}


// ------------------------------------------------------
- (void)doSetEncoding:(NSStringEncoding)encoding
// エンコード値を保存
// ------------------------------------------------------
{
    [self setEncodingCode:encoding];
    // ツールバーのエンコーディングメニュー、ステータスバー、ドローワを更新
    [self updateEncodingInToolbarAndInfo];
}


// ------------------------------------------------------
- (void)updateEncodingInToolbarAndInfo
// ツールバーのエンコーディングメニュー、ステータスバー、ドローワを更新
// ------------------------------------------------------
{
    // ツールバーのエンコーディングメニューを更新
    [[[self windowController] toolbarController] setSelectEncoding:[self encodingCode]];
    // ステータスバー、ドローワを更新
    [[self editorView] updateLineEndingsInStatusAndInfo:NO];
}


// ------------------------------------------------------
- (BOOL)readFromURL:(NSURL *)url withEncoding:(NSStringEncoding)encoding
// ファイルを読み込み、成功したかどうかを返す
// ------------------------------------------------------
{
    NSData *data = nil;

    // "authopen"コマンドを使って読み込む
    NSString *convertedPath = @([[url path] UTF8String]);
    NSTask *task = [[[NSTask alloc] init] autorelease];
    NSInteger status;

    [task setLaunchPath:@"/usr/libexec/authopen"];
    [task setArguments:@[convertedPath]];
    [task setStandardOutput:[NSPipe pipe]];

    [task launch];
    data = [NSData dataWithData:[[[task standardOutput] fileHandleForReading] readDataToEndOfFile]];
    [task waitUntilExit];
    
    // presentedItemDidChangeにて内容の同一性を比較するためにファイルのMD5を保存する
    [self setFileMD5:[data MD5]];

    status = [task terminationStatus];
    if (status != 0) {
        return NO;
    }
    if (data == nil) {
        // オープンダイアログでのエラーアラートは CEDocumentController > openDocument: で表示する
        // アプリアイコンへのファイルドロップでのエラーアラートは NSDocumentController (NSApp ?) 内部で表示される
        // 復帰時は NSDocument 内部で表示
        return NO;
    }

    BOOL result = NO;
    BOOL isEA = NO;
    NSStringEncoding newEncoding = encoding;

    if (encoding == k_autoDetectEncodingMenuTag) {
        // ファイル拡張属性(com.apple.TextEncoding)からエンコーディング値を得る
        newEncoding = [self encodingFromComAppleTextEncodingAtURL:url];
        if ([data length] == 0) {
            result = YES;
            [self setInitialString:[NSMutableString string] ];
            // (_initialString はあとで開放 == "- (NSString *)stringToWindowController".)
        }
        if (newEncoding != NSProprietaryStringEncoding) {
            if ([data length] == 0) {
                (void)[self doSetEncoding:newEncoding updateDocument:NO askLossy:NO lossy:NO asActionName:nil];
            } else {
                isEA = YES;
            }
        } else {
            newEncoding = encoding;
        }
    }
    if (!result) {
        result = [self stringFromData:data encoding:newEncoding xattr:isEA];
    }
    if (result) {
        // 保持しているファイル情報／表示する文書情報を更新
        [self getFileAttributes];
    }
    return result;
}


// ------------------------------------------------------
- (NSStringEncoding)scannedCharsetOrEncodingFromString:(NSString *)string
// "charset=" "encoding="タグからエンコーディング定義を読み取る
// ------------------------------------------------------
{
// このメソッドは、Smultron を参考にさせていただきました。(2005.08.10)
// This method is based on Smultron.(written by Peter Borg – http://smultron.sourceforge.net)
// Smultron  Copyright (c) 2004-2005 Peter Borg, All rights reserved.
// Smultron is released under GNU General Public License, http://www.gnu.org/copyleft/gpl.html

    NSStringEncoding encoding = NSProprietaryStringEncoding;
    if (![[NSUserDefaults standardUserDefaults] boolForKey:k_key_referToEncodingTag] || ([string length] < 9)) {
        return encoding; // 参照しない設定になっているか、含まれている余地が無ければ中断
    }
    NSScanner *scanner = [NSScanner scannerWithString:string];
    NSCharacterSet *stopSet = [NSCharacterSet characterSetWithCharactersInString:@"\"\' </>\n\r"];
    NSString *scannedStr = nil;

    [scanner setCharactersToBeSkipped:[NSCharacterSet characterSetWithCharactersInString:@"\"\' "]];
    // "charset="を探す
    while (![scanner isAtEnd]) {
        (void)[scanner scanUpToString:@"charset=" intoString:nil];
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
            (void)[scanner scanUpToString:@"encoding=" intoString:nil];
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
            (void)[scanner scanUpToString:@"@charset" intoString:nil];
            if ([scanner scanString:@"@charset" intoString:nil]) {
                if ([scanner scanUpToCharactersFromSet:stopSet intoString:&scannedStr]) {
                    break;
                }
            }
        }
    }
    // 見つかったら NSStringEncoding に変換して返す
    if (scannedStr != nil) {
        CFStringEncoding cfEncoding = kCFStringEncodingInvalidId;
        // "Shift_JIS"だったら、kCFStringEncodingShiftJIS と kCFStringEncodingShiftJIS_X0213_00 の
        // 優先順位の高いものを取得する
        if ([[scannedStr uppercaseString] isEqualToString:@"SHIFT_JIS"]) {
            // （theScannedStr をそのまま CFStringConvertIANACharSetNameToEncoding() で変換すると、大文字小文字を問わず
            // 「日本語（Shift JIS）」になってしまうため。IANA では大文字小文字を区別しないとしているのでこれはいいのだが、
            // CFStringConvertEncodingToIANACharSetName() では kCFStringEncodingShiftJIS と
            // kCFStringEncodingShiftJIS_X0213_00 がそれぞれ「SHIFT_JIS」「shift_JIS」と変換されるため、可逆性を持たせる
            // ための処理）
            NSArray *theEncodings = [[[[NSUserDefaults standardUserDefaults] valueForKeyPath:k_key_encodingList] copy] autorelease];
            CFStringEncoding tmpCFEncoding;

            for (NSNumber *encodingNumber in theEncodings) {
                tmpCFEncoding = [encodingNumber unsignedLongValue];
                if ((tmpCFEncoding == kCFStringEncodingShiftJIS) ||
                    (tmpCFEncoding == kCFStringEncodingShiftJIS_X0213_00)) {
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
- (void)redoSetEncoding:(NSStringEncoding)encoding updateDocument:(BOOL)updateDocument 
        askLossy:(BOOL)askLossy  lossy:(BOOL)lossy  asActionName:(NSString *)actionName
// エンコードを変更するアクションのRedo登録
// ------------------------------------------------------
{
    (void)[[[self undoManager] prepareWithInvocationTarget:self] 
            doSetEncoding:encoding updateDocument:updateDocument
                askLossy:askLossy lossy:lossy asActionName:actionName];
}


// ------------------------------------------------------
- (void)redoSetNewLineEndingCharacterCode:(NSInteger)newLineEnding
// 行末コードを変更するアクションのRedo登録
// ------------------------------------------------------
{
    [[[self undoManager] prepareWithInvocationTarget:self] doSetNewLineEndingCharacterCode:newLineEnding];
}


// ------------------------------------------------------
- (BOOL)acceptSaveDocumentWithIANACharSetName
// IANA文字コード名を読み、設定されたエンコーディングと矛盾があれば警告する
// ------------------------------------------------------
{
    NSStringEncoding IANACharSetEncoding = 
            [self scannedCharsetOrEncodingFromString:[[self editorView] stringForSave]];
    NSStringEncoding ShiftJIS = CFStringConvertEncodingToNSStringEncoding(kCFStringEncodingShiftJIS);
    NSStringEncoding X0213 = CFStringConvertEncodingToNSStringEncoding(kCFStringEncodingShiftJIS_X0213_00);

    if ((IANACharSetEncoding != NSProprietaryStringEncoding) && (IANACharSetEncoding != [self encodingCode]) &&
        (!(((IANACharSetEncoding == ShiftJIS) || (IANACharSetEncoding == X0213)) &&
           (([self encodingCode] == ShiftJIS) || ([self encodingCode] == X0213))))) {
            // （Shift-JIS の時は要注意 = scannedCharsetOrEncodingFromString: を参照）

        NSString *IANANameStr = [NSString localizedNameOfStringEncoding:IANACharSetEncoding];
        NSString *encodingNameStr = [NSString localizedNameOfStringEncoding:[self encodingCode]];
        NSAlert *alert = [NSAlert alertWithMessageText:[NSString stringWithFormat:NSLocalizedString(@"The encoding is \"%@\", but the IANA charset name in text is \"%@\".", nil), encodingNameStr, IANANameStr]
                                         defaultButton:NSLocalizedString(@"Cancel", nil)
                                       alternateButton:NSLocalizedString(@"Continue Saving", nil)
                                           otherButton:nil
                             informativeTextWithFormat:NSLocalizedString(@"Do you want to continue processing?", nil)];

        NSInteger result = [alert runModal];
        if (result != NSAlertAlternateReturn) { // == Cancel
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
    NSString *curString = [self convertedCharacterString:[[self editorView] stringForSave]
                                            withEncoding:[self encodingCode]];
    if (![curString canBeConvertedToEncoding:[self encodingCode]]) {
        NSString *encodingName = [NSString localizedNameOfStringEncoding:[self encodingCode]];
        NSAlert *alert = [NSAlert alertWithMessageText:[NSString stringWithFormat:NSLocalizedString(@"The characters would have to be changed or deleted in saving as \"%@\".", nil), encodingName]
                                         defaultButton:NSLocalizedString(@"Show Incompatible Char(s)", nil)
                                       alternateButton:NSLocalizedString(@"Save Available Strings", nil)
                                           otherButton:NSLocalizedString(@"Cancel", nil)
                             informativeTextWithFormat:NSLocalizedString(@"Do you want to continue processing?", nil)];

        NSInteger result = [alert runModal];
        if (result != NSAlertAlternateReturn) { // != Save
            if (result == NSAlertDefaultReturn) { // == show incompatible char
                [[self windowController] showIncompatibleCharList];
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
    if (![self canReleaseFinderLockAtURL:url isLocked:&isFinderLockOn lockAgain:NO]) {
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
- (void)setupODB
// 外部エディタプロトコル(ODB Editor Suite)用の値をセット
// ------------------------------------------------------
{
// この部分は、Smultron を参考にさせていただきました。(2005.04.20)
// This part is based on Smultron.(written by Peter Borg – http://smultron.sourceforge.net)
// Smultron  Copyright (c) 2004-2005 Peter Borg, All rights reserved.
// Smultron is released under GNU General Public License, http://www.gnu.org/copyleft/gpl.html
    
    NSAppleEventDescriptor *descriptor, *AEPropDescriptor, *fileSender, *fileToken;
    
    descriptor = [[NSAppleEventManager sharedAppleEventManager] currentAppleEvent];
    fileSender = [descriptor paramDescriptorForKeyword:keyFileSender];
    if (fileSender) {
        fileToken = [descriptor paramDescriptorForKeyword:keyFileSenderToken];
    } else {
        AEPropDescriptor = [descriptor paramDescriptorForKeyword:keyAEPropData];
        fileSender = [AEPropDescriptor paramDescriptorForKeyword:keyFileSender];
        fileToken = [AEPropDescriptor paramDescriptorForKeyword:keyFileSenderToken];
    }
    if (fileSender) {
        [self setFileSender:fileSender];
        if (fileToken) {
            [self setFileToken:fileToken];
        }
    }
}


// ------------------------------------------------------
- (void)sendModifiedEventToClientOfFile:(NSString *)saveAsPath
                              operation:(NSSaveOperationType)saveOperationType
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
    if (saveOperationType == NSSaveAsOperation) {
        theOSStatus = FSPathMakeRef((UInt8 *)[saveAsPath UTF8String], &theSaveAsRef, nil);
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
- (BOOL)canReleaseFinderLockAtURL:(NSURL *)url isLocked:(BOOL *)ioLocked lockAgain:(BOOL)lockAgain
// Finder のロックが解除出来るか試す。lockAgain が真なら再びロックする。
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
    if (ioLocked != nil) {
        *ioLocked = isFinderLocked;
    }
    return YES;
}


// ------------------------------------------------------
- (void)alertForModByAnotherProcessDidEnd:(NSAlert *)alert returnCode:(NSInteger)returnCode
            contextInfo:(void *)inContextInfo
// 外部プロセスによる変更の通知アラートが閉じた
// ------------------------------------------------------
{
    if (returnCode == NSAlertAlternateReturn) { // == Revert
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

    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    id printValues = [[self windowController] printValues];
    NSPrintInfo *printInfo = [self printInfo];
    NSSize paperSize = [printInfo paperSize];
    NSPrintOperation *printOperation;
    NSString *filePath = ([defaults boolForKey:k_key_headerFooterPathAbbreviatingWithTilde]) ?
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
        topMargin += (CGFloat)[defaults doubleForKey:k_key_headerFooterFontSize] - k_headerFooterLineHeight;
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
    if ([defaults integerForKey:k_key_setPrintFont] == 1) { // == プリンタ専用フォントで印字
        font = [NSFont fontWithName:[defaults valueForKey:k_key_printFontName]
                               size:(CGFloat)[defaults doubleForKey:k_key_printFontSize]];
    } else {
        font = [[self editorView] font];
    }
    
    // プリンタダイアログでの設定オブジェクトをコピー
    [printView setPrintValues:[[[[self windowController] printValues] copy] autorelease]];
    // プリントビューのテキストコンテナのパディングを固定する（印刷中に変動させるとラップの関連で末尾が印字されないことがある）
    [[printView textContainer] setLineFragmentPadding:k_printHFHorizontalMargin];
    // プリントビューに行間値／行番号表示の有無を設定
    [printView setLineSpacing:[[[self editorView] textView] lineSpacing]];
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
        printSyntax = [[[CESyntax alloc] init] autorelease];
        [printSyntax setSyntaxStyleName:[[[self windowController] toolbarController] selectedTitleOfSyntaxItem]];
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
        [printView setTextColor:[NSUnarchiver unarchiveObjectWithData:[defaults valueForKey:k_key_textColor]]];
        [printView setBackgroundColor:[NSUnarchiver unarchiveObjectWithData:[defaults valueForKey:k_key_backgroundColor]]];
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
- (NSStringEncoding)encodingFromComAppleTextEncodingAtURL:(NSURL *)url
// ファイル拡張属性(com.apple.TextEncoding)からエンコーディングを得る
// ------------------------------------------------------
{
    NSStringEncoding encoding = NSProprietaryStringEncoding;

    NSString *string = [UKXattrMetadataStore stringForKey:@"com.apple.TextEncoding" atPath:[url path] traverseLink:NO];
    NSArray *strings = [string componentsSeparatedByString:@";"];
    if (([strings count] >= 2) && ([strings[1] length] > 1)) {
        // （配列の2番目の要素の末尾には行末コードが付加されているため、長さの最小は1）
        encoding = CFStringConvertEncodingToNSStringEncoding([strings[1] integerValue]);
    } else if ([strings[0] length] > 1) {
        CFStringEncoding cfEncoding = CFStringConvertIANACharSetNameToEncoding((CFStringRef)strings[0]);
        if (cfEncoding != kCFStringEncodingInvalidId) {
            encoding = CFStringConvertEncodingToNSStringEncoding(cfEncoding);
        }
    }
    
    return encoding;
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
