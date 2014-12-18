/*
 ==============================================================================
 CEDocument
 
 CotEditor
 http://coteditor.com
 
 Created on 2004-12-08 by nakamuxu
 encoding="UTF-8"
 ------------------------------------------------------------------------------
 
 © 2004-2007 nakamuxu
 © 2011, 2014 CotEditor Project
 
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
#import <sys/xattr.h>
#import "CEDocumentController.h"
#import "CEPrintPanelAccessoryController.h"
#import "CEGoToSheetController.h"
#import "CEPrintView.h"
#import "CEODBEventSender.h"
#import "CESyntaxManager.h"
#import "CEUtils.h"
#import "NSData+MD5.h"
#import "constants.h"


// constants
static char const XATTR_ENCODING_KEY[] = "com.apple.TextEncoding";

// listController key
NSString *const CEIncompatibleLineNumberKey = @"lineNumber";
NSString *const CEIncompatibleRangeKey = @"incompatibleRange";
NSString *const CEIncompatibleCharKey = @"incompatibleChar";
NSString *const CEIncompatibleConvertedCharKey = @"convertedChar";


@interface CEDocument ()

@property (nonatomic) CEPrintPanelAccessoryController *printPanelAccessoryController;

@property (atomic, copy) NSString *fileMD5;
@property (atomic) BOOL needsShowUpdateAlertWithBecomeKey;
@property (atomic, getter=isRevertingForExternalFileUpdate) BOOL revertingForExternalFileUpdate;
@property (nonatomic) BOOL didAlertNotWritable;  // 文書が読み込み専用のときにその警告を表示したかどうか
@property (nonatomic, copy) NSString *initialString;  // 初期表示文字列に表示する文字列;
@property (nonatomic) CEODBEventSender *ODBEventSender;

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

#pragma mark Class Methods

// ------------------------------------------------------
/// OS X 10.7 AutoSave
+ (BOOL)autosavesInPlace
// ------------------------------------------------------
{
    return NO;
}


// ------------------------------------------------------
/// OS X 10.7 Versions
+ (BOOL)preservesVersions
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
/// 初期化
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
/// あとかたづけ
- (void)dealloc
// ------------------------------------------------------
{
    // ノーティフィケーションセンタから自身を排除
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}


// ------------------------------------------------------
/// カスタム windowController を生成
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
    // 外部エディタプロトコル(ODB Editor Suite)用の値をセット
    [self setODBEventSender:[[CEODBEventSender alloc] init]];
    
    // 書き込み可能かをチェック
    NSNumber *isWritable = nil;
    [url getResourceValue:&isWritable forKey:NSURLIsWritableKey error:nil];
    [self setWritable:[isWritable boolValue]];
    
    NSStringEncoding encoding = [[CEDocumentController sharedDocumentController] accessorySelectedEncoding];
    
    return [self readFromURL:url withEncoding:encoding];
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
    
    BOOL success = [self readFromURL:url withEncoding:CEAutoDetectEncodingMenuItemTag];
    
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
    NSString *string = [self convertCharacterString:[self stringForSave] withEncoding:[self encoding]];
    
    // stringから保存用のdataを得る
    NSData *data = [string dataUsingEncoding:[self encoding] allowLossyConversion:YES];
    
    // 必要であれば UTF-8 BOM 追加 (2008.12.13)
    if ([[NSUserDefaults standardUserDefaults] boolForKey:CEDefaultSaveUTF8BOMKey] &&
        ([self encoding] == NSUTF8StringEncoding)) {
        const char utf8Bom[] = {0xef, 0xbb, 0xbf}; // UTF-8 BOM
        NSMutableData *mutableData = [NSMutableData dataWithBytes:utf8Bom length:3];
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
    // 保存の前後で編集内容をグルーピングさせないための処置
    // ダミーのグループを作り、そのままだと空のアンドゥ内容でダーティーフラグがたってしまうので、アンドゥしておく
    // ****** 空のアンドゥ履歴が残る問題あり  (2005.08.05) *******
    // (保存の前後で編集内容がグルーピングされてしまう例：キー入力後保存し、キャレットを動かすなどしないでそのまま入力
    // した場合、ダーティーフラグがたたず、アンドゥすると保存前まで戻されてしまう。さらに、戻された状態でリドゥすると、
    // 保存後の入力までが行われる。つまり、保存をはさんで前後の内容が同一アンドゥグループに入ってしまうための不具合)
    // CETextView > doInsertString:withRange:withSelected:withActionName: でも同様の対処を行っている
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
            [self setSyntaxStyleWithFileName:[url lastPathComponent] coloring:YES];
        }

        // 保持しているファイル情報／表示する文書情報を更新
        [self getFileAttributes];
        
        // 外部エディタプロトコル(ODB Editor Suite)のファイル更新通知送信
        [[self ODBEventSender] sendModifiedEventWithURL:url operation:saveOperation];
        
        // ファイル保存更新を Finder へ通知（デスクトップに保存した時に白紙アイコンになる問題への対応）
        [[NSWorkspace sharedWorkspace] noteFileSystemChanged:[url path]];
        
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
            fileName = [fileName stringByAppendingPathExtension:extensions[0]];
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
// このメソッドは下記のページの情報を参考にさせていただきました(2005.07.08)
// http://www.cocoadev.com/index.pl?ReplaceSaveChangesSheet

    // Finder のロックが解除できず、かつダーティーフラグがたっているときは相応のダイアログを出す
    if ([self isDocumentEdited] &&
        ![self canReleaseFinderLockAtURL:[self fileURL] isLocked:nil lockAgain:YES])
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
    [printView setLineSpacing:[[[self editor] textView] lineSpacing]];
    
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



#pragma mark Public Methods

//=======================================================
// Public method
//
//=======================================================

// ------------------------------------------------------
/// 改行コードを指定のものに置換したメイン textView の文字列を返す
- (NSString *)stringForSave
// ------------------------------------------------------
{
    return [[[self editor] string] stringByReplacingNewLineCharacersWith:[self lineEnding]];
}

// ------------------------------------------------------
/// editor に文字列をセット
- (void)setStringToEditor
// ------------------------------------------------------
{
    [self setSyntaxStyleWithFileName:[[self fileURL] lastPathComponent] coloring:NO];
    
    // 表示する文字列内の改行コードをLFに統一する
    // （その他の編集は、下記の通りの別の場所で置換している）
    // # テキスト編集時の改行コードの置換場所
    //  * ファイルオープン = CEDocument > setStringToEditor
    //  * スクリプト = CEEditorView > textView:shouldChangeTextInRange:replacementString:
    //  * キー入力 = CEEditorView > textView:shouldChangeTextInRange:replacementString:
    //  * ペースト = CETextView > readSelectionFromPasteboard:type:
    //  * ドロップ（別書類または別アプリから） = CETextView > readSelectionFromPasteboard:type:
    //  * ドロップ（同一書類内） = CETextView > performDragOperation:
    //  * 検索パネルでの置換 = (OgreKit) OgreTextViewPlainAdapter > replaceCharactersInRange:withOGString:
    
    if ([self initialString]) {
        CENewLineType lineEnding = [[self initialString] detectNewLineType];
        if (lineEnding != CENewLineNone) {  // 改行コードが含まれないときはデフォルトのままにする
            [self setLineEnding:lineEnding];
        }
        
        NSString *string = [[self initialString] stringByReplacingNewLineCharacersWith:CENewLineLF];
        
        [[self editor] setString:string]; // （editorWrapper の setString 内でキャレットを先頭に移動させている）
        [self setInitialString:nil];  // release
        
    } else {
        [[self editor] setString:@""];
    }
    // update toolbar
    [self applyLineEndingToView];
    
    // ツールバーのエンコーディングメニュー、ステータスバー、ドロワーを更新
    [self updateEncodingInToolbarAndInfo];
    // カラーリングと行番号を更新
    // （大きいドキュメントの時はインジケータを表示させるため、ディレイをかけてまずウィンドウを表示させる）
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
    NSString *yenMarkChar = [NSString stringWithCharacters:&kYenMark length:1];
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


//------------------------------------------------------
/// データから指定エンコードで文字列を得る
- (BOOL)readStringFromData:(NSData *)data encoding:(NSStringEncoding)encoding xattr:(BOOL)checksXattr
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
    
    // ファイル拡張属性(com.apple.TextEncoding)を試す
    if (checksXattr && (encoding != CEAutoDetectEncodingMenuItemTag)) {
        string = [[NSString alloc] initWithData:data encoding:encoding];
        if (!string) {
            encoding = CEAutoDetectEncodingMenuItemTag;
        }
    }
    
    if (([data length] > 0) && (encoding == CEAutoDetectEncodingMenuItemTag)) {
        const char utf8Bom[] = {0xef, 0xbb, 0xbf}; // UTF-8 BOM
        // BOM付きUTF-8判定
        if (memchr([data bytes], *utf8Bom, 3) != NULL) {
            shouldSkipUTF8 = YES;
            string = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
            if (string) {
                encoding = NSUTF8StringEncoding;
            }
            // UTF-16判定
        } else if ((memchr([data bytes], 0xfffe, 2) != NULL) ||
                   (memchr([data bytes], 0xfeff, 2) != NULL)) {
            
            shouldSkipUTF16 = YES;
            string = [[NSString alloc] initWithData:data encoding:NSUnicodeStringEncoding];
            if (string) {
                encoding = NSUnicodeStringEncoding;
            }
            
            // ISO 2022-JP判定
        } else if (memchr([data bytes], 0x1b, [data length]) != NULL) {
            shouldSkipISO2022JP = YES;
            string = [[NSString alloc] initWithData:data encoding:NSISO2022JPStringEncoding];
            if (string) {
                encoding = NSISO2022JPStringEncoding;
            }
        }
    }
    
    if (!string && (encoding == CEAutoDetectEncodingMenuItemTag)) {
        NSArray *encodings = [[[NSUserDefaults standardUserDefaults] arrayForKey:CEDefaultEncodingListKey] copy];
        
        for (NSNumber *encodingNumber in encodings) {
            encoding = CFStringConvertEncodingToNSStringEncoding([encodingNumber unsignedIntegerValue]);
            if ((encoding == NSISO2022JPStringEncoding) && shouldSkipISO2022JP) {
                break;
            } else if ((encoding == NSUTF8StringEncoding) && shouldSkipUTF8) {
                break;
            } else if ((encoding == NSUnicodeStringEncoding) && shouldSkipUTF16) {
                break;
            } else if (encoding == NSProprietaryStringEncoding) {
                NSLog(@"encoding == NSProprietaryStringEncoding");
                break;
            }
            string = [[NSString alloc] initWithData:data encoding:encoding];
            if (string) {
                // "charset="や"encoding="を読んでみて適正なエンコーディングが得られたら、そちらを優先
                NSStringEncoding tmpEncoding = [self scanCharsetOrEncodingFromString:string];
                if ((tmpEncoding == NSProprietaryStringEncoding) || (tmpEncoding == encoding)) {
                    break;
                }
                NSString *tmpStr = [[NSString alloc] initWithData:data encoding:tmpEncoding];
                if (tmpStr) {
                    string = tmpStr;
                    encoding = tmpEncoding;
                }
                break;
            }
        }
    } else if (!string) {
        string = [[NSString alloc] initWithData:data encoding:encoding];
    }
    
    if (string && (encoding != CEAutoDetectEncodingMenuItemTag)) {
        // 10.3.9 で、一部のバイナリファイルを開いたときにクラッシュする問題への暫定対応。
        // 10.4+ ではスルー（2005.12.25）
        // ＞＞ しかし「すべて2バイト文字で4096文字以上あるユニコードでない文書」は開けない（2005.12.25）
        // (下記の現象と同じ理由で発生していると思われる）
        // https://www.codingmonkeys.de/bugs/browse/HYR-529?page=all
        if (([data length] <= 8192) ||
            (([data length] > 8192) && ([data length] != ([string length] * 2 + 1)) &&
             ([data length] != ([string length] * 2)))) {
                
                [self setInitialString:string];
                // (_initialString はあとで開放 == "- (void)setStringToEditor".)
                [self doSetEncoding:encoding updateDocument:NO askLossy:NO lossy:NO asActionName:nil];
                return YES;
            }
    }
    
    return NO;
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
        
        // Undo登録
        NSUndoManager *undoManager = [self undoManager];
        [[undoManager prepareWithInvocationTarget:self]
                    redoSetEncoding:encoding updateDocument:updateDocument 
                    askLossy:NO lossy:allowsLossy asActionName:actionName]; // undo内redo
        if (shouldShowList) {
            [[undoManager prepareWithInvocationTarget:[self windowController]] showIncompatibleCharList];
        }
        [[undoManager prepareWithInvocationTarget:self] setEncoding:[self encoding]]; // エンコード値設定
        [[undoManager prepareWithInvocationTarget:self] updateEncodingInToolbarAndInfo];
        [[undoManager prepareWithInvocationTarget:self] updateChangeCount:NSChangeUndone]; // changeCount減値
        if (actionName) {
            [undoManager setActionName:actionName];
        }
        [self updateChangeCount:NSChangeDone];
    }
    
    [self setEncoding:encoding];
    [self updateEncodingInToolbarAndInfo];  // ツールバーのエンコーディングメニュー、ステータスバー、ドロワーを更新
    
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
    // 現在と同じ改行コードなら、何もしない
    if (lineEnding == [self lineEnding]) { return; }
    
    CENewLineType currentLineEnding = [self lineEnding];

    // Undo登録
    NSUndoManager *undoManager = [self undoManager];
    [[undoManager prepareWithInvocationTarget:self] redoSetLineEnding:lineEnding]; // undo内redo
    [[undoManager prepareWithInvocationTarget:self] setLineEnding:currentLineEnding]; // 元の改行コード
    [[undoManager prepareWithInvocationTarget:self] applyLineEndingToView]; // 元の改行コード
    [[undoManager prepareWithInvocationTarget:self] updateChangeCount:NSChangeUndone]; // changeCountデクリメント
    [undoManager setActionName:[NSString stringWithFormat:NSLocalizedString(@"Line Endings to “%@”", @""),
                                [NSString newLineNameWithType:lineEnding]]];

    [self setLineEnding:lineEnding];
    [self applyLineEndingToView];
    [self updateChangeCount:NSChangeDone]; // changeCountインクリメント
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


// ------------------------------------------------------
/// マイナス指定された文字範囲／長さをNSRangeにコンバートして返す
- (NSRange)rangeInTextViewWithLocation:(NSInteger)location length:(NSInteger)length
// ------------------------------------------------------
{
    CETextView *textView = [[self editor] textView];
    NSUInteger wholeLength = [[textView string] length];
    NSRange range = NSMakeRange(0, 0);
    
    NSInteger newLocation = (location < 0) ? (wholeLength + location) : location;
    NSInteger newLength = (length < 0) ? (wholeLength - newLocation + length) : length;
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
/// editor 内部の textView で指定された部分を文字単位で選択
- (void)setSelectedCharacterRangeInTextViewWithLocation:(NSInteger)location length:(NSInteger)length
// ------------------------------------------------------
{
    NSRange selectionRange = [self rangeInTextViewWithLocation:location length:length];
    
    [[self editor] setSelectedRange:selectionRange];
}


// ------------------------------------------------------
/// editor 内部の textView で指定された部分を行単位で選択
- (void)setSelectedLineRangeInTextViewWithLocation:(NSInteger)location length:(NSInteger)length
// ------------------------------------------------------
{
    CETextView *textView = [[self editor] textView];
    NSUInteger wholeLength = [[textView string] length];
    NSRegularExpression *regex = [NSRegularExpression regularExpressionWithPattern:@"^"
                                                                           options:NSRegularExpressionAnchorsMatchLines
                                                                             error:nil];
    NSArray *matches = [regex matchesInString:[textView string] options:0
                                        range:NSMakeRange(0, [[textView string] length])];
    
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
            
            NSTextCheckingResult *match = matches[(newLocation - 1)];
            NSRange range = [match range];
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
/// 選択範囲を変更する
- (void)gotoLocation:(NSInteger)location length:(NSInteger)length type:(CEGoToType)type
// ------------------------------------------------------
{
    switch (type) {
        case CEGoToLine:
            [self setSelectedLineRangeInTextViewWithLocation:location length:length];
            break;
        case CEGoToCharacter:
            [self setSelectedCharacterRangeInTextViewWithLocation:location length:length];
            break;
    }
    
    NSTextView *textView = [[self editor] textView];
    [[[self windowController] window] makeKeyAndOrderFront:self]; // 対象ウィンドウをキーに
    [textView scrollRangeToVisible:[textView selectedRange]]; // 選択範囲が見えるようにスクロール
    [textView showFindIndicatorForRange:[textView selectedRange]];  // 検索結果表示エフェクトを追加
}



#pragma mark Protocols

//=======================================================
// NSMenuValidation Protocol
//
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
//
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



#pragma mark Delegate and Notifications

//=======================================================
// Delegate method (NSFilePresenter)
//  <== NSFilePresenter
//=======================================================

// ------------------------------------------------------
/// ファイルが変更された
- (void)presentedItemDidChange
// ------------------------------------------------------
{
    // ファイルのmodificationDateがドキュメントのmodificationDateと同じ場合は無視
    NSFileCoordinator *coordinator = [[NSFileCoordinator alloc] initWithFilePresenter:self];
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
         MD5 = [[NSData dataWithContentsOfURL:newURL] MD5];
     }];
    if ([MD5 isEqualToString:[self fileMD5]]) {
        // documentの保持しているfileModificationDateを書き換える (2014-03 by 1024jp)
        // ここだけで無視してもファイル保存時にアラートが出るのことへの対策
        [self setFileModificationDate:fileModificationDate];
        
        return;
    }
    
    // 書き込み通知を行う
    [self setNeedsShowUpdateAlertWithBecomeKey:YES];
    // アプリがアクティブならシート／ダイアログを表示し、そうでなければ設定を見てDockアイコンをジャンプ
    if ([NSApp isActive]) {
        [self performSelectorOnMainThread:@selector(showUpdatedByExternalProcessAlert) withObject:nil waitUntilDone:NO];
        
    } else if ([[NSUserDefaults standardUserDefaults] boolForKey:CEDefaultNotifyEditByAnotherKey]) {
        [NSApp requestUserAttention:NSInformationalRequest];
    }
}


//=======================================================
// Notification method (CESplitView)
//  <== CESplitView
//=======================================================

// ------------------------------------------------------
/// 書類オープン処理が完了した
- (void)documentDidFinishOpen:(NSNotification *)notification
// ------------------------------------------------------
{
    if ([notification object] == [[self windowController] window]) {
        // 書き込み禁止アラートを表示
        [self showNotWritableAlert];
    }
}



#pragma mark Action Messages

//=======================================================
// Action messages
//
//=======================================================

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
/// Go Toパネルを開く
- (IBAction)gotoLocation:(id)sender
// ------------------------------------------------------
{
    CEGoToSheetController *sheetController = [[CEGoToSheetController alloc] init];
    [sheetController beginSheetForDocument:self];
}


// ------------------------------------------------------
/// ドキュメントに新しい改行コードをセットする
- (IBAction)changeLineEndingToLF:(id)sender
// ------------------------------------------------------
{
    [self changeLineEnding:sender];
}


// ------------------------------------------------------
/// ドキュメントに新しい改行コードをセットする
- (IBAction)changeLineEndingToCR:(id)sender
// ------------------------------------------------------
{
    [self changeLineEnding:sender];
}


// ------------------------------------------------------
/// ドキュメントに新しい改行コードをセットする
- (IBAction)changeLineEndingToCRLF:(id)sender
// ------------------------------------------------------
{
    [self changeLineEnding:sender];
}


// ------------------------------------------------------
/// ドキュメントに新しい改行コードをセットする
- (IBAction)changeLineEnding:(id)sender
// ------------------------------------------------------
{
    [self doSetLineEnding:[sender tag]];
}


// ------------------------------------------------------
- (IBAction)changeEncoding:(id)sender
/// ドキュメントに新しいエンコーディングをセットする
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
        NSString *actionName = [NSString stringWithFormat:NSLocalizedString(@"Encoding to “%@”",@""),
                    [NSString localizedNameOfStringEncoding:encoding]];

        [self doSetEncoding:encoding updateDocument:YES askLossy:YES lossy:NO asActionName:actionName];

    } else if (result == NSAlertSecondButtonReturn) {  // = Reinterpret 再解釈
        if (![self fileURL]) { return; } // まだファイル保存されていない時（ファイルがない時）は、戻る
        if ([self isDocumentEdited]) {
            NSAlert *secondAlert = [[NSAlert alloc] init];
            [secondAlert setMessageText:[NSString stringWithFormat:NSLocalizedString(@"The file “%@” has unsaved changes.", nil), [[self fileURL] path]]];
             [secondAlert setInformativeText:NSLocalizedString(@"Do you want to discard the changes and reset the file encodidng?", nil)];
             [secondAlert addButtonWithTitle:NSLocalizedString(@"Cancel", nil)];
             [secondAlert addButtonWithTitle:NSLocalizedString(@"Discard Changes", nil)];

            NSInteger secondResult = [secondAlert runModal];
            if (secondResult != NSAlertSecondButtonReturn) { // != Discard Change
                // ツールバーから変更された場合のため、ツールバーアイテムの選択状態をリセット
                [[[self windowController] toolbarController] setSelectedEncoding:[self encoding]];
                return;
            }
        }
        if ([self readFromURL:[self fileURL] withEncoding:encoding]) {
            [self setStringToEditor];
            // アンドゥ履歴をクリア
            [[self undoManager] removeAllActions];
            [self updateChangeCount:NSChangeCleared];
        } else {
            NSAlert *thirdAlert = [[NSAlert alloc] init];
            [thirdAlert setMessageText:NSLocalizedString(@"Can not reinterpret", nil)];
            [thirdAlert setInformativeText:[NSString stringWithFormat:NSLocalizedString(@"The file “%@” could not be reinterpreted using the new encoding “%@”.", nil), [[self fileURL] path], encodingName]];
            [thirdAlert addButtonWithTitle:NSLocalizedString(@"Done", nil)];
            [thirdAlert setAlertStyle:NSCriticalAlertStyle];

            NSBeep();
            [thirdAlert runModal];
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
    [[self editor] setThemeWithName:[sender title]];
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
        [[[self editor] textView] insertText:string];
    }
}


// ------------------------------------------------------
/// IANA文字コード名を挿入する
- (IBAction)insertIANACharSetNameWithCharset:(id)sender
// ------------------------------------------------------
{
    NSString *string = [self currentIANACharSetName];

    if (string) {
        [[[self editor] textView] insertText:[NSString stringWithFormat:@"charset=\"%@\"", string]];
    }
}


// ------------------------------------------------------
/// IANA文字コード名を挿入する
- (IBAction)insertIANACharSetNameWithEncoding:(id)sender
// ------------------------------------------------------
{
    NSString *string = [self currentIANACharSetName];

    if (string) {
        [[[self editor] textView] insertText:[NSString stringWithFormat:@"encoding=\"%@\"", string]];
    }
}



#pragma mark Private Methods

//=======================================================
// Private method
//
//=======================================================

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
/// ツールバーのエンコーディングメニュー、ステータスバー、ドロワーを更新
- (void)updateEncodingInToolbarAndInfo
// ------------------------------------------------------
{
    // ツールバーのエンコーディングメニューを更新
    [[[self windowController] toolbarController] setSelectedEncoding:[self encoding]];
    // ステータスバー、ドロワーを更新
    [[self windowController] updateModeInfoIfNeeded];
}


// ------------------------------------------------------
/// 改行コードをエディタに反映
- (void)applyLineEndingToView
// ------------------------------------------------------
{
    [[self editor] setLineEndingString:[NSString newLineStringWithType:[self lineEnding]]];
    [[[self windowController] toolbarController] setSelectedLineEnding:[self lineEnding]];
}


// ------------------------------------------------------
/// ファイルを読み込み、成功したかどうかを返す
- (BOOL)readFromURL:(NSURL *)url withEncoding:(NSStringEncoding)encoding
// ------------------------------------------------------
{
    // "authopen"コマンドを使って読み込む
    NSString *convertedPath = @([[url path] UTF8String]);
    NSTask *task = [[NSTask alloc] init];

    [task setLaunchPath:@"/usr/libexec/authopen"];
    [task setArguments:@[convertedPath]];
    [task setStandardOutput:[NSPipe pipe]];

    [task launch];
    NSData *data = [NSData dataWithData:[[[task standardOutput] fileHandleForReading] readDataToEndOfFile]];
    [task waitUntilExit];
    
    int status = [task terminationStatus];
    
    // presentedItemDidChangeにて内容の同一性を比較するためにファイルのMD5を保存する
    [self setFileMD5:[data MD5]];
    
    if (status != 0) {
        return NO;
    }
    if (data == nil) {
        // オープンダイアログでのエラーアラートは CEDocumentController > openDocument: で表示する
        // アプリアイコンへのファイルドロップでのエラーアラートは NSDocumentController (NSApp ?) 内部で表示される
        // 復帰時は NSDocument 内部で表示
        return NO;
    }

    NSStringEncoding newEncoding = encoding;
    BOOL success = NO;
    BOOL isEA = NO;

    if (encoding == CEAutoDetectEncodingMenuItemTag) {
        // ファイル拡張属性(com.apple.TextEncoding)からエンコーディング値を得る
        newEncoding = [self encodingFromComAppleTextEncodingAtURL:url];
        if ([data length] == 0) {
            success = YES;
            [self setInitialString:@""];
            // (_initialString はあとで開放 == "- (void)setStringToEditor".)
        }
        if (newEncoding != NSProprietaryStringEncoding) {
            if ([data length] == 0) {
                [self doSetEncoding:newEncoding updateDocument:NO askLossy:NO lossy:NO asActionName:nil];
            } else {
                isEA = YES;
            }
        } else {
            newEncoding = encoding;
        }
    }
    if (!success) {
        success = [self readStringFromData:data encoding:newEncoding xattr:isEA];
    }
    if (success) {
        // 保持しているファイル情報／表示する文書情報を更新
        [self getFileAttributes];
    }
    return success;
}


// ------------------------------------------------------
/// "charset=" "encoding="タグからエンコーディング定義を読み取る
- (NSStringEncoding)scanCharsetOrEncodingFromString:(NSString *)string
// ------------------------------------------------------
{
    // This method is based on Smultron's SMLTextPerformer.m by Peter Borg. (2005-08-10)
    // Smultron 2 was distributed on <http://smultron.sourceforge.net> under the terms of the BSD license.
    // Copyright (c) 2004-2006 Peter Borg
    
    NSStringEncoding encoding = NSProprietaryStringEncoding;
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
/// ファイル拡張属性 (com.apple.TextEncoding) からエンコーディングを得る
- (NSStringEncoding)encodingFromComAppleTextEncodingAtURL:(NSURL *)url
// ------------------------------------------------------
{
    NSStringEncoding encoding = NSProprietaryStringEncoding;
    
    // get xattr data
    NSMutableData* data = nil;
    const char *path = [[url path] UTF8String];
    ssize_t bufferSize = getxattr(path, XATTR_ENCODING_KEY, NULL, 0, 0, XATTR_NOFOLLOW);
    if (bufferSize > 0) {
        data = [NSMutableData dataWithLength:bufferSize];
        getxattr(path, XATTR_ENCODING_KEY, [data mutableBytes], [data length], 0, XATTR_NOFOLLOW);
    }
    
    // parse value
    NSString *string = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
    NSArray *strings = [string componentsSeparatedByString:@";"];
    if (([strings count] >= 2) && ([strings[1] length] > 1)) {
        // （配列の2番目の要素の末尾には改行コードが付加されているため、長さの最小は1）
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
/// IANA文字コード名を読み、設定されたエンコーディングと矛盾があれば警告する
- (BOOL)acceptSaveDocumentWithIANACharSetName
// ------------------------------------------------------
{
    NSStringEncoding IANACharSetEncoding = [self scanCharsetOrEncodingFromString:[self stringForSave]];
    NSStringEncoding ShiftJIS = CFStringConvertEncodingToNSStringEncoding(kCFStringEncodingShiftJIS);
    NSStringEncoding X0213 = CFStringConvertEncodingToNSStringEncoding(kCFStringEncodingShiftJIS_X0213);

    if ((IANACharSetEncoding != NSProprietaryStringEncoding) && (IANACharSetEncoding != [self encoding]) &&
        (!(((IANACharSetEncoding == ShiftJIS) || (IANACharSetEncoding == X0213)) &&
           (([self encoding] == ShiftJIS) || ([self encoding] == X0213))))) {
            // （Shift-JIS の時は要注意 = scannedCharsetOrEncodingFromString: を参照）

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
    if (![self canReleaseFinderLockAtURL:url isLocked:&isFinderLockOn lockAgain:NO]) {
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
        // presentedItemDidChange にて内容の同一性を比較するためにファイルの MD5 を保存する
        [self setFileMD5:[data MD5]];
        
        // クリエータなどを設定
        [[NSFileManager defaultManager] setAttributes:attributes ofItemAtPath:[url path] error:nil];
        
        // ファイル拡張属性(com.apple.TextEncoding)にエンコーディングを保存
        NSData *encodingData = [[[self currentIANACharSetName] stringByAppendingFormat:@";%u",
                                 (unsigned int)CFStringConvertNSStringEncodingToEncoding([self encoding])]
                                dataUsingEncoding:NSUTF8StringEncoding];
        if (encodingData) {
            setxattr([[url path] UTF8String], XATTR_ENCODING_KEY,
                     [encodingData bytes], [encodingData length], 0, XATTR_NOFOLLOW);
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
    NSString *curString = [self convertCharacterString:[self stringForSave]
                                          withEncoding:[self encoding]];
    
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
- (NSString *)convertCharacterString:(NSString *)string withEncoding:(NSStringEncoding)encoding
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
- (BOOL)canReleaseFinderLockAtURL:(NSURL *)url isLocked:(BOOL *)isLocked lockAgain:(BOOL)lockAgain
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
               askLossy:(BOOL)askLossy  lossy:(BOOL)lossy  asActionName:(NSString *)actionName
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
    // このメソッドは下記のページの情報を参考にさせていただきました(2005.07.08)
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
