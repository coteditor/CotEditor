/*
=================================================
CESyntaxManager
(for CotEditor)

 Copyright (C) 2004-2007 nakamuxu.
 Copyright (C) 2014 CotEditor Project
 http://coteditor.github.io
=================================================

encoding="UTF-8"
Created:2004.12.24

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

#import "CESyntaxManager.h"

//=======================================================
// Private method
//
//=======================================================

@interface CESyntaxManager (Private)
- (NSDictionary *)emptyColoringStyle;
- (void)setupColoringStyleArray;
- (void)setupExtensionAndSyntaxTable;
- (void)saveColoringStyle;
- (NSString *)pathOfStyleDirectory;
- (NSURL *)URLOfStyleDirectory;
- (BOOL)copyDefaultSyntaxStylesTo:(NSString *)inDestinationPath;
- (NSString *)copiedSyntaxName:(NSString *)inOriginalName;
- (void)setExtensionErrorToTextView;
- (void)setupSyntaxSheetControles;
- (void)editNewAddedRowOfTableView:(NSTableView *)inTableView;
- (NSInteger)syntaxElementError;
- (NSInteger)syntaxElementCheck;
@end


//------------------------------------------------------------------------------------------




@implementation CESyntaxManager

static CESyntaxManager *sharedInstance = nil;

#pragma mark ===== Class method =====

//=======================================================
// Class method
//
//=======================================================

// ------------------------------------------------------
+ (CESyntaxManager *)sharedInstance
// 共有インスタンスを返す
// ------------------------------------------------------
{
    return sharedInstance ? sharedInstance : [[self alloc] init];
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
    if (sharedInstance == nil) {
        self = [super init];
        (void)[NSBundle loadNibNamed:@"SyntaxManager" owner:self];
        _selectedStyleName = [[NSString string] retain]; // ===== retain
        _editedNewStyleName = [[NSString string] retain]; // ===== retain
        [self setupColoringStyleArray];
        [self setupExtensionAndSyntaxTable];
        [self setIsOkButtonPressed:NO];
        _addedItemInLeopard = NO;
        sharedInstance = self;
    }
    return sharedInstance;
}


// ------------------------------------------------------
- (void)dealloc
// あとかたづけ
// ------------------------------------------------------
{
    // NSBundle loadNibNamed: でロードされたオブジェクトを開放
    // 参考にさせていただきました > http://homepage.mac.com/mkino2/backnumber/2004_10.html#October%2012_1
    [_editWindow release]; // （コンテントビューは自動解放される）
    [_extensionErrorTextView release];
    [_styleController release];

    [_selectedStyleName release];
    [_editedNewStyleName release];
    [_extensions release];

    [super dealloc];
}


// ------------------------------------------------------
- (NSDictionary *)xtsnAndStyleTable
// 拡張子<->styleファイルの変換テーブル辞書(key = 拡張子)を返す
// ------------------------------------------------------
{
    return _xtsnAndStyleTable;
}


// ------------------------------------------------------
- (NSDictionary *)xtsnErrors
// 拡張子重複エラー辞書を返す
// ------------------------------------------------------
{
    return _xtsnErrors;
}


// ------------------------------------------------------
- (NSArray *)extensions
// 拡張子配列を返す
// ------------------------------------------------------
{
    return _extensions;
}


// ------------------------------------------------------
- (NSString *)selectedStyleName
// 編集対象となっているスタイル名を返す
// ------------------------------------------------------
{
    return _selectedStyleName;
}


// ------------------------------------------------------
- (NSString *)editedNewStyleName
// 編集された新しいスタイル名を返す
// ------------------------------------------------------
{
    return _editedNewStyleName;
}


// ------------------------------------------------------
- (void)setEditedNewStyleName:(NSString *)inString
// 編集された新しいスタイル名を保持
// ------------------------------------------------------
{
    [inString retain];
    [_editedNewStyleName release];
    _editedNewStyleName = inString;
}

// ------------------------------------------------------
- (BOOL)setSelectionIndexOfStyle:(NSInteger)inStyleIndex mode:(NSInteger)inMode
// シートの表示に備え、シンタックスカラーリングスタイル定義配列のうちの一つを選択する（バインディングのため）
// ------------------------------------------------------
{
    NSArray *theColoringArray;
    NSString *theName;
    NSUInteger theSelected;

    _sheetOpeningMode = inMode;
    if (inMode == k_syntaxCopyTag) { // Copy
        theSelected = inStyleIndex;
        theColoringArray = _coloringStyleArray;
        theName = [self copiedSyntaxName: 
                    theColoringArray[inStyleIndex][k_SCKey_styleName]];
        theColoringArray[inStyleIndex][k_SCKey_styleName] = theName;

    } else if (inMode == k_syntaxNewTag) { // New
        theSelected = 0;
        theColoringArray = @[[NSMutableDictionary dictionaryWithDictionary:[self emptyColoringStyle]]];
        theName = @"";

    } else { // Edit, Delete
        theSelected = inStyleIndex;
        theColoringArray = _coloringStyleArray;
        theName = theColoringArray[inStyleIndex][k_SCKey_styleName];
    }
    if (!theName) { return NO; }
    [theName retain];
    [_selectedStyleName release];
    _selectedStyleName = theName;
    [_styleController setContent:theColoringArray];

    // シートのコントロール類をセットアップ
    [self setupSyntaxSheetControles];

    return ([_styleController setSelectionIndex:theSelected]);
}


// ------------------------------------------------------
- (NSString *)syntaxNameFromExtension:(NSString *)inExtension
// 拡張子に応じたstyle名を返す
// ------------------------------------------------------
{
    NSString *outName = [self xtsnAndStyleTable][inExtension];

    if (outName == nil) {
        id theValues = [[NSUserDefaultsController sharedUserDefaultsController] values];
        return [theValues valueForKey:k_key_defaultColoringStyleName];
    }
    return outName;
}


// ------------------------------------------------------
- (NSDictionary *)syntaxWithStyleName:(NSString *)inStyleName
// style名に応じたstyle辞書を返す
// ------------------------------------------------------
{
    if ((![inStyleName isEqualToString:@""]) && 
            (![inStyleName isEqualToString:NSLocalizedString(@"None",@"")])) {
        NSMutableDictionary *outDict;
        for (NSDictionary *theDict in _coloringStyleArray) {
            if ([theDict[k_SCKey_styleName] isEqualToString:inStyleName]) {
                NSArray *theSyntaxArray = @[k_SCKey_allColoringArrays];
                NSArray *theArray;
                NSUInteger theCount = 0;
                outDict = [NSMutableDictionary dictionaryWithDictionary:theDict];

                for (id key in theSyntaxArray) {
                    theArray = outDict[key];
                    theCount = theCount + [theArray count];
                }
                outDict[k_SCKey_numOfObjInArray] = @(theCount);
                return outDict;
            }
        }
    }
    // デフォルトデータを返す
    return [self emptyColoringStyle];
}


// ------------------------------------------------------
- (NSArray *)defaultSyntaxFileNames
// バンドルされているシンタックスカラーリングスタイルファイル名配列を返す
// ------------------------------------------------------
{
    NSFileManager *theFileManager = [NSFileManager defaultManager];
    NSString *theSourceDirPath = 
            [[[NSBundle mainBundle] bundlePath] stringByAppendingPathComponent:@"/Contents/Resources"];
    NSEnumerator *theEnumerator = [[theFileManager contentsOfDirectoryAtPath:theSourceDirPath error:nil] objectEnumerator];
    // (enumeratorAtPath:はサブディレクトリの内容も返すので、使えない)
    NSMutableArray *outArray = [NSMutableArray array];
    id theFileName;

    while (theFileName = [theEnumerator nextObject]) {
        if (([theFileName hasPrefix:k_bundleSyntaxStyleFilePrefix]) && 
                ([[theFileName pathExtension] isEqualToString:@"plist"])) {
            [outArray addObject:theFileName];
        }
    }
    return outArray;
}


// ------------------------------------------------------
- (NSArray *)defaultSyntaxFileNamesWithoutPrefix
// バンドルされているシンタックスカラーリングスタイルファイル名のプレフィックスを除いた配列を返す
// ------------------------------------------------------
{
    NSArray *theDefaultArray = [self defaultSyntaxFileNames];
    NSMutableArray *outArray = [NSMutableArray array];
    NSUInteger thePrefixLength = [k_bundleSyntaxStyleFilePrefix length];
    
    for (NSString *fileName in theDefaultArray) {
        [outArray addObject:[fileName substringFromIndex:thePrefixLength]];
    }
    return outArray;
}


// ------------------------------------------------------
- (BOOL)isDefaultSyntaxStyle:(NSString *)inStyleName
// あるスタイルネームがデフォルトで用意されているものかどうかを返す
// ------------------------------------------------------
{
    if ((inStyleName == nil) || ([inStyleName isEqualToString:@""])) { return NO; }
    NSArray *theNames = [self defaultSyntaxFileNamesWithoutPrefix];
    BOOL outValue = [theNames containsObject:[inStyleName stringByAppendingPathExtension:@"plist"]];

    return outValue;
}


// ------------------------------------------------------
- (BOOL)isEqualToDefaultSyntaxStyle:(NSString *)inStyleName
// あるスタイルネームがデフォルトで用意されているものと同じかどうかを返す
// ------------------------------------------------------
{
    if ((inStyleName == nil) || ([inStyleName isEqualToString:@""])) { return NO; }
    NSFileManager *theFileManager = [NSFileManager defaultManager];
    NSURL *destURL = [[[self URLOfStyleDirectory] URLByAppendingPathComponent:inStyleName] URLByAppendingPathExtension:@"plist"];
    NSURL *sourceDirURL =[[[NSBundle mainBundle] bundleURL] URLByAppendingPathComponent:@"/Contents/Resources"];
    NSURL *sourceURL = [[sourceDirURL URLByAppendingPathComponent:[NSString stringWithFormat:@"%@%@", k_bundleSyntaxStyleFilePrefix, inStyleName]] URLByAppendingPathExtension:@"plist"];
    
    if (![theFileManager fileExistsAtPath:[sourceURL path]] || ![theFileManager fileExistsAtPath:[destURL path]]) {
        return NO;
    }

    // （[self syntaxWithStyleName:[self selectedStyleName]]] で返ってくる辞書には numOfObjInArray が付加されている
    // ため、同じではない。ファイル同士を比較する。2008.05.06.
    NSDictionary *theSourcePList = [NSDictionary dictionaryWithContentsOfURL:sourceURL];
    NSDictionary *theDestPList = [NSDictionary dictionaryWithContentsOfURL:destURL];

    return ([theSourcePList isEqualToDictionary:theDestPList]);

// NSFileManager の contentsEqualAtPath:andPath: では、宣言部分の「Apple Computer（Tiger以前）」と「Apple（Leopard）」の違いが引っかかってしまうため、使えなくなった。 2008.05.06.
//    return ([theFileManager contentsEqualAtPath:[sourceURL path] andPath:[destURL path]]);
}


// ------------------------------------------------------
- (NSArray *)styleNames
// スタイル名配列を返す
// ------------------------------------------------------
{
    NSMutableArray *outArray = [NSMutableArray array];
    
    for (NSDictionary *dict in _coloringStyleArray) {
        [outArray addObject:dict[k_SCKey_styleName]];
    }

    return outArray;
}


// ------------------------------------------------------
- (NSWindow *)editWindow
// カラーシンタックス編集シート用ウィンドウを返す
// ------------------------------------------------------
{
    return _editWindow;
}


// ------------------------------------------------------
- (BOOL)isOkButtonPressed
// シートでOKボタンが押されたかどうかを返す
// ------------------------------------------------------
{
    return _okButtonPressed;
}


// ------------------------------------------------------
- (void)setIsOkButtonPressed:(BOOL)inValue
// シートでOKボタンが押されたかどうかをセット
// ------------------------------------------------------
{
    _okButtonPressed = inValue;
}


//------------------------------------------------------
- (BOOL)existsStyleFileWithStyleName:(NSString *)inStyleName
// ある名前を持つstyleファイルがstyle保存ディレクトリにあるかどうかを返す
//------------------------------------------------------
{
    NSURL *URL = [[[self URLOfStyleDirectory] URLByAppendingPathComponent:inStyleName] URLByAppendingPathExtension:@"plist"];

    return ([[NSFileManager defaultManager] fileExistsAtPath:[URL path]]);
}


//------------------------------------------------------
- (BOOL)importStyleFile:(NSString *)inStyleFileName
// 外部styleファイルを保存ディレクトリにコピーする
//------------------------------------------------------
{
    BOOL outBool = NO;
    NSFileManager *theFileManager = [NSFileManager defaultManager];
    NSURL *styleFileURL = [NSURL fileURLWithPath:inStyleFileName];
    NSURL *destinationURL = [[self URLOfStyleDirectory] URLByAppendingPathComponent:[styleFileURL lastPathComponent]];

    if ([theFileManager fileExistsAtPath:[destinationURL path]]) {
        [theFileManager removeItemAtURL:destinationURL error:nil];
    }
    outBool = [theFileManager copyItemAtURL:styleFileURL toURL:destinationURL error:nil];
    if (outBool) {
        // 内部で持っているキャッシュ用データを更新
        [self setupColoringStyleArray];
        [self setupExtensionAndSyntaxTable];
    }
    return outBool;
}


//------------------------------------------------------
- (BOOL)removeStyleFileWithStyleName:(NSString *)inStyleName
// style名に応じたstyleファイルを削除する
//------------------------------------------------------
{
    BOOL outValue = NO;
    if ([inStyleName length] < 1) { return outValue; }
    NSFileManager *theFileManager = [NSFileManager defaultManager];
    NSURL *URL = [[[self URLOfStyleDirectory] URLByAppendingPathComponent:inStyleName] URLByAppendingPathExtension:@"plist"];

    if ([theFileManager fileExistsAtPath:[URL path]]) {
        outValue = [theFileManager removeItemAtURL:URL error:nil];
        if (outValue) {
            // 内部で持っているキャッシュ用データを更新
            [self setupColoringStyleArray];
            [self setupExtensionAndSyntaxTable];
        } else {
            NSLog(@"Error. Could not remove \"%@\"", [URL path]);
        }
    } else {
        NSLog(@"Error. Could not be found \"%@\" for remove", [URL path]);
    }
    return outValue;
}


//------------------------------------------------------
- (NSURL *)URLOfStyle:(NSString *)styleName
// style名からstyle定義ファイルのURLを返す
//------------------------------------------------------
{
    NSURL *URL = [[[self URLOfStyleDirectory] URLByAppendingPathComponent:styleName] URLByAppendingPathExtension:@"plist"];
    
    return ([[NSFileManager defaultManager] fileExistsAtPath:[URL path]]) ? URL : nil;
}


//------------------------------------------------------
- (BOOL)existsExtensionError
// 拡張子重複エラーがあるかどうかを返す
//------------------------------------------------------
{
    BOOL outBool = ([[self xtsnErrors] count] > 0);

    return outBool;
}


//------------------------------------------------------
- (NSWindow *)extensionErrorWindow
// 拡張子重複エラー表示ウィンドウを返す
//------------------------------------------------------
{
    [self setExtensionErrorToTextView];

    return [_extensionErrorTextView window];
}



#pragma mark === Delegate and Notification ===

//=======================================================
// Delegate method (NSTableView)
//  <== tableViews in Preferences sheet
//=======================================================

// ------------------------------------------------------
- (void)tableViewSelectionDidChange:(NSNotification *)inNotification
// tableView の選択が変更された
// ------------------------------------------------------
{
    NSTableView *theTableView = [inNotification object];
    NSInteger theRow = [theTableView selectedRow];

    // 最下行が選択されたのなら、編集開始のメソッドを呼び出す
    //（ここですぐに開始しないのは、選択行のセルが持つ文字列をこの段階では取得できないため）
    if ((theRow + 1) == [theTableView numberOfRows]) {
        [self performSelectorOnMainThread:@selector(editNewAddedRowOfTableView:) 
                withObject:theTableView waitUntilDone:NO];
    }
}



#pragma mark ===== Action messages =====

//=======================================================
// Action messages
//
//=======================================================

// ------------------------------------------------------
- (IBAction)setToFactoryDefaults:(id)sender
// スタイルの内容を出荷時設定に戻す
// ------------------------------------------------------
{
    if (![self isDefaultSyntaxStyle:[self selectedStyleName]]) { return; }
    NSString *theSourceDirPath = 
            [[[NSBundle mainBundle] bundlePath] stringByAppendingPathComponent:@"/Contents/Resources"];
    NSString *theSourcePath = [theSourceDirPath stringByAppendingFormat:@"/%@%@.plist", 
            k_bundleSyntaxStyleFilePrefix, [self selectedStyleName]];
    if (![[NSFileManager defaultManager] fileExistsAtPath:theSourcePath]) { return; }
    NSArray *theContents = @[[NSMutableDictionary dictionaryWithContentsOfFile:theSourcePath]];

    // フォーカスを移しておく
    [[sender window] makeFirstResponder:[sender window]];
    // コントローラに内容をセット
    [_styleController setContent:theContents];
    (void)[_styleController setSelectionIndex:0];
    // シートのコントロール類をセットアップ
    [self setupSyntaxSheetControles];
    // デフォルト設定に戻すボタンを無効化
    [_factoryDefaultsButton setEnabled:NO];
}


// ------------------------------------------------------
- (IBAction)closeSyntaxEditSheet:(id)sender
// カラーシンタックス編集シートの OK / Cancel ボタンが押された
// ------------------------------------------------------
{
    // フォーカスを移して入力中の値を確定
    [[sender window] makeFirstResponder:sender];
    // style名から先頭または末尾のスペース／タブ／改行を排除
    NSMutableString *theStr = [NSMutableString stringWithString:
            [[_styleNameField stringValue] stringByTrimmingCharactersInSet:
                    [NSCharacterSet whitespaceAndNewlineCharacterSet]]];
    (void)[theStr replaceOccurrencesOfString:@"\n" 
                withString:@"" options:0 range:NSMakeRange(0, [theStr length])];
    (void)[theStr replaceOccurrencesOfString:@"\t" 
                withString:@"" options:0 range:NSMakeRange(0, [theStr length])];
    [_styleNameField setStringValue:theStr];

    if ([sender tag] == k_okButtonTag) { // ok のときstyleを保存
        if ((_sheetOpeningMode == k_syntaxCopyTag) || (_sheetOpeningMode == k_syntaxNewTag)) {
            if ([theStr length] < 1) { // ファイル名としても使われるので、空は不可
                [_messageField setStringValue:NSLocalizedString(@"Input the Style Name !",@"")];
                NSBeep();
                [[_styleNameField window] makeFirstResponder:_styleNameField];
                return;
            } else if ([self existsStyleFileWithStyleName:theStr]) { // 既にある名前は不可
                [_messageField setStringValue:[NSString stringWithFormat:
                            NSLocalizedString(@"\"%@\" is already exist. Input new name.",@""), theStr]];
                NSBeep();
                [[_styleNameField window] makeFirstResponder:_styleNameField];
                return;
            }
            // 入力されたstyle名をコントローラで選択されたものとして保持しておく（ファイル書き込み時の照合のため）
            [theStr retain];
            [_selectedStyleName release];
            _selectedStyleName = theStr;
        }
        // エラー未チェックかつエラーがあれば、表示（エラーを表示していてOKボタンを押下したら、そのまま確定）
        if (([[_syntaxElementCheckTextView string] isEqualToString:@""]) && ([self syntaxElementError] > 0)) {
            // 「構文要素チェック」を選択
            // （selectItemAtIndex: だとバインディングが実行されないので、メニューを取得して選択している）
            NSBeep();
            [[_elementPopUpButton menu] performActionForItemAtIndex:11];
            return;
        }
        [self setEditedNewStyleName:theStr];
        [self setIsOkButtonPressed:YES];
        [self saveColoringStyle];
    }
    // 内部で持っているキャッシュ用データを更新
    [self setupColoringStyleArray];
    [self setupExtensionAndSyntaxTable];
    [_syntaxElementCheckTextView setString:@""]; // 構文チェック結果文字列を消去
    [NSApp stopModal];
}


// ------------------------------------------------------
- (IBAction)closeSyntaxExtensionErrorSheet:(id)sender
// カラーシンタックス拡張子重複エラー表示シートの Done ボタンが押された
// ------------------------------------------------------
{
    [NSApp stopModal];
}


// ------------------------------------------------------
- (IBAction)startSyntaxElementCheck:(id)sender
// 構文チェックを開始
// ------------------------------------------------------
{
    (void)[self syntaxElementError];
}



@end



@implementation CESyntaxManager (Private)

//=======================================================
// Private method
//
//=======================================================

//------------------------------------------------------
- (NSDictionary *)emptyColoringStyle
// 空の新規styleを返す
//------------------------------------------------------
{
    NSDictionary *outDict = @{k_SCKey_styleName: [NSMutableString stringWithString:@""], 
                    k_SCKey_extensions: [NSMutableArray array], 
                    k_SCKey_keywordsArray: [NSMutableArray array], 
                    k_SCKey_commandsArray: [NSMutableArray array], 
                    k_SCKey_valuesArray: [NSMutableArray array], 
                    k_SCKey_numbersArray: [NSMutableArray array], 
                    k_SCKey_stringsArray: [NSMutableArray array], 
                    k_SCKey_charactersArray: [NSMutableArray array], 
                    k_SCKey_commentsArray: [NSMutableArray array], 
                    k_SCKey_outlineMenuArray: [NSMutableArray array], 
                    k_SCKey_completionsArray: [NSMutableArray array]};

    return outDict;
}


//------------------------------------------------------
- (void)setupColoringStyleArray
// styleのファイルからのセットアップと読み込み
//------------------------------------------------------
{
    NSString *theDirPath = [self pathOfStyleDirectory]; // データディレクトリパス取得

    // ディレクトリの存在チェック
    NSFileManager *theFileManager = [NSFileManager defaultManager];
    BOOL theValueIsDir = NO, theValueCreated = NO;
    BOOL theExists = [theFileManager fileExistsAtPath:theDirPath isDirectory:&theValueIsDir];
    if (!theExists) {
		NSError *createDirError = nil;
		theValueCreated = [theFileManager createDirectoryAtPath:theDirPath withIntermediateDirectories:NO attributes:nil error:&createDirError];
		if (createDirError != nil) {
			NSLog(@"Error. SyntaxStyles directory could not be created.");
			return;
		}
		
    }
    if ((theExists && theValueIsDir) || (theValueCreated)) {
        (void)[self copyDefaultSyntaxStylesTo:theDirPath];
    } else {
        NSLog(@"Error. SyntaxStyles directory could not be found.");
        return;
    }

    // styleデータの読み込み
    NSMutableArray *theArray = [NSMutableArray array];
	NSError *findFileError = nil;
    NSArray *theFiles = [theFileManager contentsOfDirectoryAtPath:theDirPath error:	&findFileError];
	if (findFileError != nil) {
        NSLog(@"Error on seeking SyntaxStyle Files Directory.");
        return;		
	}
    
	NSString *thePath = nil;
    for (NSString *fileName in theFiles) {
        if ((![fileName hasPrefix:@"."]) && ([fileName hasSuffix:@".plist"])) { // ドットファイル除去
            thePath = [theDirPath stringByAppendingPathComponent:fileName];
            NSMutableDictionary *theDict = [NSMutableDictionary dictionaryWithContentsOfFile:thePath];
			// thePathが無効だった場合などに、theDictがnilになる場合がある
			if (theDict != nil) {
				// k_SCKey_styleName をファイル名にそろえておく(Finderで移動／リネームされたときへの対応)
				theDict[k_SCKey_styleName] = [[fileName lastPathComponent] stringByDeletingPathExtension];
				[theArray addObject:theDict]; // theDictがnilになってここで落ちる（MacBook Airの場合）
			}
        }
    }
    [theArray retain]; // ===== retain
    [_coloringStyleArray release];
    _coloringStyleArray = theArray;
}


// ------------------------------------------------------
- (void)setupExtensionAndSyntaxTable
// 拡張子<->styleファイルの変換テーブル辞書(key = 拡張子)と、拡張子辞書、拡張子重複エラー辞書を更新
// ------------------------------------------------------
{
    NSEnumerator *theEnumerator = [_coloringStyleArray objectEnumerator];
    NSMutableDictionary *theTable = [NSMutableDictionary dictionary];
    NSMutableDictionary *theErrors = [NSMutableDictionary dictionary];
    NSMutableArray *theExtensions = [NSMutableArray array];
    id theDict, theExtension, theAddedName = nil;
    NSArray *theArray;

    while (theDict = [theEnumerator nextObject]) {
        theArray = theDict[k_SCKey_extensions];
        if (!theArray) { continue; }
        for (NSDictionary *extensionDict in theArray) {
            theExtension = extensionDict[k_SCKey_arrayKeyString];
            if ((theAddedName = theTable[theExtension])) { // 同じ拡張子を持つものがすでにあるとき
                NSMutableArray *theErrorArray = theErrors[theExtension];
                if (!theErrorArray) {
                    theErrorArray = [NSMutableArray array];
                    [theErrors setValue:theErrorArray forKey:theExtension];
                }
                if (![theErrorArray containsObject:theAddedName]) {
                    [theErrorArray addObject:theAddedName];
                }
                [theErrorArray addObject:theDict[k_SCKey_styleName]];
            } else {
                [theTable setValue:theDict[k_SCKey_styleName] forKey:theExtension];
                [theExtensions addObject:theExtension];
            }
        }
    }
    [theTable retain]; // ===== retain
    [_xtsnAndStyleTable release];
    _xtsnAndStyleTable = theTable;
    [theErrors retain]; // ===== retain
    [_xtsnErrors release];
    _xtsnErrors = theErrors;
    [theExtensions retain]; // ===== retain
    [_extensions release];
    _extensions = theExtensions;
}


//------------------------------------------------------
- (void)saveColoringStyle
// styleのファイルへの保存
//------------------------------------------------------
{
    NSString *theDirPath = [self pathOfStyleDirectory]; // データディレクトリパス取得
    NSString *theSaveFile, *theSavePath;
    NSMutableDictionary *theDict;
    NSArray *theArraysArray = @[k_SCKey_allArrays];
    NSMutableArray *theKeyStringArray;
    NSSortDescriptor *theDescriptorOne = [[[NSSortDescriptor alloc] initWithKey:k_SCKey_beginString 
                    ascending:YES selector:@selector(caseInsensitiveCompare:)] autorelease];
    NSSortDescriptor *theDescriptorTwo = [[[NSSortDescriptor alloc] initWithKey:k_SCKey_arrayKeyString 
                    ascending:YES selector:@selector(caseInsensitiveCompare:)] autorelease];
    NSArray *theDescriptors = @[theDescriptorOne, theDescriptorTwo];

    // _styleController内のコンテンツオブジェクト取得
    NSArray *theContent = [_styleController selectedObjects];
    // styleデータ保存（選択中のオブジェクトはひとつだから、配列の最初の要素のみ処理する 2008.11.02）
    theDict = [theContent[0] mutableCopy]; // ===== mutableCopy
    for (id key in theArraysArray) {
        theKeyStringArray = theDict[key];
        [theKeyStringArray sortUsingDescriptors:theDescriptors];
    }
    theSaveFile = [self editedNewStyleName];
    if ([theSaveFile length] > 0) {
        theSavePath = [NSString stringWithFormat:@"%@/%@%@", theDirPath, theSaveFile, @".plist"];
        // style名が変更されたときは、古いファイルを削除する
        if (![theSaveFile isEqualToString:[self selectedStyleName]]) {
            (void)[self removeStyleFileWithStyleName:[self selectedStyleName]];
        }
        [theDict writeToFile:theSavePath atomically:YES];
    }
    [theDict release]; // ===== release
}


//------------------------------------------------------
- (NSString *)pathOfStyleDirectory
// styleデータファイル保存用ディレクトリを返す
//------------------------------------------------------
{
    return [[self URLOfStyleDirectory] path];
}


//------------------------------------------------------
- (NSURL *)URLOfStyleDirectory
// styleデータファイル保存用ディレクトリをNSURLで返す
//------------------------------------------------------
{
    NSURL *URL = [[[NSFileManager defaultManager] URLForDirectory:NSApplicationSupportDirectory
                                                        inDomain:NSUserDomainMask
                                               appropriateForURL:nil
                                                          create:NO
                                                           error:nil]
                  URLByAppendingPathComponent:@"CotEditor/SyntaxColorings"];
    
    return URL;
}


//------------------------------------------------------
- (BOOL)copyDefaultSyntaxStylesTo:(NSString *)inDestinationPath
// styleデータファイルを保存用ディレクトリにコピー
//------------------------------------------------------
{
    NSString *theSourceDirPath = 
            [[[NSBundle mainBundle] bundlePath] stringByAppendingPathComponent:@"/Contents/Resources"];
    NSString *theSource, *theDestination;
    NSArray *theSourceNames = [self defaultSyntaxFileNames];
    NSArray *theDestNames = [self defaultSyntaxFileNamesWithoutPrefix];
    NSFileManager *theFileManager = [NSFileManager defaultManager];
    BOOL theValue = NO;
    NSUInteger i;
    
    for (i = 0; i < [theSourceNames count]; i++) {
        theSource = [theSourceDirPath stringByAppendingPathComponent:theSourceNames[i]];
        theDestination = [inDestinationPath stringByAppendingPathComponent:theDestNames[i]];
        if (([theFileManager fileExistsAtPath:theSource]) && 
                    (![theFileManager fileExistsAtPath:theDestination])) {
            theValue = [theFileManager copyItemAtPath:theSource toPath:theDestination error:nil];
            if (!theValue) {
                NSLog(@"Error. Could not copy \"%@\" to \"%@\"...", theSource, inDestinationPath);
            }
        }
    }
    return theValue;
}


//------------------------------------------------------
- (NSString *)copiedSyntaxName:(NSString *)inOriginalName
// コピーされたstyle名を返す
//------------------------------------------------------
{
    NSFileManager *theFileManager = [NSFileManager defaultManager];
    NSString *thePath = [self pathOfStyleDirectory];
    NSString *theCompareName = [inOriginalName stringByTrimmingCharactersInSet:
                        [NSCharacterSet whitespaceAndNewlineCharacterSet]];
    NSString *theCopyName;
    NSMutableString *outName = [NSMutableString string];
    NSRange theCopiedStrRange;
    BOOL theCopiedState = NO;
    NSInteger i = 1;

    theCopiedStrRange = [theCompareName rangeOfRegularExpressionString:NSLocalizedString(@" copy$",@"")];
    if (theCopiedStrRange.location != NSNotFound) {
        theCopiedState = YES;
    } else {
        theCopiedStrRange = [theCompareName rangeOfRegularExpressionString:
                            NSLocalizedString(@" copy [0-9]+$",@"")];
        if (theCopiedStrRange.location != NSNotFound) {
            theCopiedState = YES;
        }
    }
    if (theCopiedState) {
        theCopyName = [NSString stringWithFormat:@"%@%@", 
                [theCompareName substringWithRange:NSMakeRange(0, theCopiedStrRange.location)], 
                NSLocalizedString(@" copy",@"")];
    } else {
        theCopyName = [NSString stringWithFormat:@"%@%@", theCompareName, NSLocalizedString(@" copy",@"")];
    }
    [outName appendFormat:@"%@.plist", theCopyName];
    while ([theFileManager fileExistsAtPath:[thePath stringByAppendingPathComponent:outName]]) {
        i++;
        [outName setString:[NSString stringWithFormat:@"%@ %li", theCopyName, (long)i]];
        [outName appendString:@".plist"];
    }
    return [outName stringByDeletingPathExtension];
}


//------------------------------------------------------
- (void)setExtensionErrorToTextView
// カラーシンタックス拡張子重複エラー表示シートに表示するエラー内容をセット
//------------------------------------------------------
{
    NSMutableString *theStr = [NSMutableString string];

    if ([[self xtsnErrors] count] > 0) {
        NSDictionary *theErrors = [self xtsnErrors];
        NSEnumerator *theEnumerator = [theErrors keyEnumerator];
        NSArray *theArray;
        id theKey;
        NSInteger i, theCount;

        [theStr setString:NSLocalizedString(@"The following Extension list is registered by two or more styles for one extension. \nCotEditor uses the first style.\n\n",@"")];
        [theStr appendString:NSLocalizedString(@"\"Extension\" = \"Style Names\"\n  -  -  -  -  -  -  -\n",@"")];

        // [NSDictionary descriptionInStringsFileFormat] だと日本語がユニコード16進表示になってしまうので、
        // マニュアルで分解し文字列に変換（もっとうまいやり方あるだろ (-_-; ... 2005.12.03）
        while (theKey = [theEnumerator nextObject]) {
            theArray = theErrors[theKey];
            theCount = [theArray count];
            [theStr appendFormat:@"\"%@\" = \"", theKey];
            for (i = 0; i < theCount; i++) {
                [theStr appendString:theArray[i]];
                if (i < (theCount - 1)) {
                    [theStr appendString:@", "];
                } else {
                    break;
                }
            }
            [theStr appendString:@"\"\n"];
        }
    } else {
        [theStr setString:NSLocalizedString(@"No Error found.",@"")];
    }
    [_extensionErrorTextView setString:theStr];
}


//------------------------------------------------------
- (void)setupSyntaxSheetControles
// シートのコントロール類をセットアップ
//------------------------------------------------------
{
    BOOL theValue = [self isDefaultSyntaxStyle:[self selectedStyleName]];

    [_styleNameField setStringValue:[self selectedStyleName]];
    [_styleNameField setDrawsBackground:(!theValue)];
    [_styleNameField setBezeled:(!theValue)];
    [_styleNameField setSelectable:(!theValue)];
    [_styleNameField setEditable:(!theValue)];

    if (theValue) {
        [_styleNameField setBordered:YES];
        [_messageField setStringValue:NSLocalizedString(@"The default style name cannot be changed.",@"")];
        [_factoryDefaultsButton setEnabled:(![self isEqualToDefaultSyntaxStyle:[self selectedStyleName]])];
    } else {
        [_messageField setStringValue:@""];
        [_factoryDefaultsButton setEnabled:NO];
    }
    [self setIsOkButtonPressed:NO];
}


//------------------------------------------------------
- (void)editNewAddedRowOfTableView:(NSTableView *)inTableView
// 最下行が選択され、一番左のコラムが入力されていなければ自動的に編集を開始する
//------------------------------------------------------
{
    // 10.5.2で実行されているとき、selectedRow では実際の選択行番号が返ってくるが、
    // [[theColumn dataCellForRow:[inTableView selectedRow]] stringValue] で、
    // 表示上の最下行の内容が返ってくる（更新タイミングが変更された？）ため、「小手先の処理」をおこなう。 2008.05.06.
    if (floor(NSAppKitVersionNumber) >= 949) { // 949 = LeopardのNSAppKitVersionNumber
        if (_addedItemInLeopard == NO) {
            _addedItemInLeopard = YES;
            [inTableView scrollRowToVisible:[inTableView selectedRow]];
            [self performSelectorOnMainThread:@selector(editNewAddedRowOfTableView:) 
                    withObject:inTableView waitUntilDone:NO];
            return;
        }
        _addedItemInLeopard = NO;
    }

    NSTableColumn *theColumn = [inTableView tableColumns][0];
    NSInteger theRow = [inTableView selectedRow];
    id theCell = [theColumn dataCellForRow:theRow];
    if (theCell == nil) { return; }
    NSString *theStr = [theCell stringValue];

    if ((theStr == nil) || ([theStr isEqualToString:@""])) {
        if ([[inTableView window] makeFirstResponder:inTableView]) {
            [inTableView editColumn:0 row:theRow withEvent:nil select:YES];
        }
    }
}
// ------------------------------------------------------
- (NSInteger)syntaxElementError
// 構文チェック実行
// ------------------------------------------------------
{
    return ([self syntaxElementCheck]);
}

// ------------------------------------------------------
- (NSInteger)syntaxElementCheck
// 正規表現構文と重複のチェック実行
// ------------------------------------------------------
{
    NSArray *theSelectedArray = [_styleController selectedObjects];
    NSMutableString *theResultStr = [NSMutableString string];
    NSInteger outCount = 0;

    if ([theSelectedArray count] == 1) {
        NSDictionary *theDict = theSelectedArray[0];
        NSArray *theSyntaxArray = @[k_SCKey_syntaxCheckArrays];
        NSArray *theArray;
        NSString *theBeginStr, *theEndStr, *theTmpBeginStr = nil, *theTmpEndStr = nil;
        NSString *theArrayNameDeletingArray = nil;
        NSInteger theCapCount;
        NSError *theError = nil;

        for (NSString *theArrayName in theSyntaxArray) {
            theArray = theDict[theArrayName];
            theArrayNameDeletingArray = [theArrayName substringToIndex:([theArrayName length] - 5)];

            for (NSDictionary *dict in theArray) {
                theBeginStr = dict[k_SCKey_beginString];
                theEndStr = dict[k_SCKey_endString];

                if (([theTmpBeginStr isEqualToString:theBeginStr]) && 
                        (((theTmpEndStr == nil) && (theEndStr == nil)) || 
                            ([theTmpEndStr isEqualToString:theEndStr]))) {

                    outCount++;
                    [theResultStr appendFormat:@"%li.  %@ :(Begin string) > %@\n  >>> multiple registered.\n\n",
                            (long)outCount, theArrayNameDeletingArray, theBeginStr];

                } else if ([dict[k_SCKey_regularExpression] boolValue]) {

                    theCapCount = [theBeginStr captureCountWithOptions:RKLNoOptions error:&theError];
                    if (theCapCount == -1) { // エラーのとき
                        outCount++;
                        [theResultStr appendFormat:@"%li.  %@ :(Begin string) > %@\n  >>> Error \"%@\" in column %@: %@<<HERE>>%@\n\n", 
                                (long)outCount, theArrayNameDeletingArray, theBeginStr,
                                [theError userInfo][RKLICURegexErrorNameErrorKey], 
                                [theError userInfo][RKLICURegexOffsetErrorKey], 
                                [theError userInfo][RKLICURegexPreContextErrorKey], 
                                [theError userInfo][RKLICURegexPostContextErrorKey]];
                    }
                    if (theEndStr != nil) {
                        theCapCount = [theEndStr captureCountWithOptions:RKLNoOptions error:&theError];
                        if (theCapCount == -1) { // エラーのとき
                            outCount++;
                            [theResultStr appendFormat:@"%li.  %@ :(End string) > %@\n  >>> Error \"%@\" in column %@: %@<<HERE>>%@\n\n",
                                    (long)outCount, theArrayNameDeletingArray, theEndStr, 
                                    [theError userInfo][RKLICURegexErrorNameErrorKey], 
                                    [theError userInfo][RKLICURegexOffsetErrorKey], 
                                    [theError userInfo][RKLICURegexPreContextErrorKey], 
                                    [theError userInfo][RKLICURegexPostContextErrorKey]];
                        }
                    }

                // （outlineMenuは、過去の定義との互換性保持のためもあってOgreKitを使っている 2008.05.16）
                } else if ([theArrayName isEqualToString:k_SCKey_outlineMenuArray]) {
                    NS_DURING
                        (void)[OGRegularExpression regularExpressionWithString:theBeginStr];
                    NS_HANDLER
                        // 例外処理 (OgreKit付属のRegularExpressionTestのコードを参考にしています)
                        outCount++;
                        [theResultStr appendFormat:@"%li.  %@ :(RE string) > %@\n  >>> %@\n\n", 
                                (long)outCount, theArrayNameDeletingArray, theBeginStr, [localException reason]];
                    NS_ENDHANDLER
                }
                theTmpBeginStr = theBeginStr;
                theTmpEndStr = theEndStr;
            }
        }
        if (outCount == 0) {
            [theResultStr setString:NSLocalizedString(@"No Error found.",@"")];
        } else if (outCount == 1) {
            [theResultStr insertString:NSLocalizedString(@"One Error was Found !\n\n",@"") atIndex:0];
        } else {
            [theResultStr insertString:
                    [NSString stringWithFormat:NSLocalizedString(@"%i Errors were Found !\n\n",@""), outCount] 
                    atIndex:0];
        }
    } else {
        [theResultStr setString:NSLocalizedString(@"An Error occuerd in Checking.\nNumber of selected object is 2 or more in '_styleController'.",@"")];
    }
    [_syntaxElementCheckTextView setString:theResultStr];

    return outCount;
}



@end
