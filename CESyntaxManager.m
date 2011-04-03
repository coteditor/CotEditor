/*
=================================================
CESyntaxManager
(for CotEditor)

Copyright (C) 2004-2007 nakamuxu.
http://www.aynimac.com/
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
- (BOOL)copyDefaultSyntaxStylesTo:(NSString *)inDestinationPath;
- (NSString *)copiedSyntaxName:(NSString *)inOriginalName;
- (void)setExtensionErrorToTextView;
- (void)setupSyntaxSheetControles;
- (void)editNewAddedRowOfTableView:(NSTableView *)inTableView;
- (int)syntaxElementError;
- (int)syntaxElementCheckInPanter;
- (int)syntaxElementCheck;
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
- (BOOL)setSelectionIndexOfStyle:(int)inStyleIndex mode:(int)inMode
// シートの表示に備え、シンタックスカラーリングスタイル定義配列のうちの一つを選択する（バインディングのため）
// ------------------------------------------------------
{
    NSArray *theColoringArray;
    NSString *theName;
    unsigned int theSelected;

    _sheetOpeningMode = inMode;
    if (inMode == k_syntaxCopyTag) { // Copy
        theSelected = inStyleIndex;
        theColoringArray = _coloringStyleArray;
        theName = [self copiedSyntaxName: 
                    [[theColoringArray objectAtIndex:inStyleIndex] objectForKey:k_SCKey_styleName]];
        [[theColoringArray objectAtIndex:inStyleIndex] setObject:theName forKey:k_SCKey_styleName];

    } else if (inMode == k_syntaxNewTag) { // New
        theSelected = 0;
        theColoringArray = [NSArray arrayWithObject:
                [NSMutableDictionary dictionaryWithDictionary:[self emptyColoringStyle]]];
        theName = [NSString stringWithString:@""];

    } else { // Edit, Delete
        theSelected = inStyleIndex;
        theColoringArray = _coloringStyleArray;
        theName = [[theColoringArray objectAtIndex:inStyleIndex] objectForKey:k_SCKey_styleName];
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
    NSString *outName = [[self xtsnAndStyleTable] objectForKey:inExtension];

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
        NSDictionary *theDict = nil;
        int i, theStyleCount = [_coloringStyleArray count];
        for (i = 0; i < theStyleCount; i++) {
            theDict = [_coloringStyleArray objectAtIndex:i];
            if ([[theDict objectForKey:k_SCKey_styleName] isEqualToString:inStyleName]) {
                NSArray *theSyntaxArray = [NSArray arrayWithObjects:k_SCKey_allColoringArrays, nil];
                NSArray *theArray;
                int j, theCount = 0, theSyntaxCount = [theSyntaxArray count];
                outDict = [NSMutableDictionary dictionaryWithDictionary:theDict];

                for (j = 0; j < theSyntaxCount; j++) {
                    theArray = [outDict objectForKey:[theSyntaxArray objectAtIndex:j]];
                    theCount = theCount + [theArray count];
                }
                [outDict setObject:[NSNumber numberWithInt:theCount] forKey:k_SCKey_numOfObjInArray];
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
    NSEnumerator *theEnumerator = [[theFileManager directoryContentsAtPath:theSourceDirPath] objectEnumerator];
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
    NSString *theStr = nil;
    int i, thePrefixLength, theCount = [theDefaultArray count];

    thePrefixLength = [[NSString stringWithString:k_bundleSyntaxStyleFilePrefix] length];
    for (i = 0; i < theCount; i++) {
        theStr = [[theDefaultArray objectAtIndex:i] substringFromIndex:thePrefixLength];
        [outArray addObject:theStr];
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
    NSString *theSourceDirPath = 
            [[[NSBundle mainBundle] bundlePath] stringByAppendingPathComponent:@"/Contents/Resources"];
    NSString *theSourcePath = [theSourceDirPath stringByAppendingFormat:@"/%@%@.plist", 
            k_bundleSyntaxStyleFilePrefix, inStyleName];
    NSString *theDestPath = [[self pathOfStyleDirectory] stringByAppendingFormat:@"/%@.plist", inStyleName];

    if ((![theFileManager fileExistsAtPath:theSourcePath]) || 
                (![theFileManager fileExistsAtPath:theDestPath])) {
        return NO;
    }

    // （[self syntaxWithStyleName:[self selectedStyleName]]] で返ってくる辞書には numOfObjInArray が付加されている
    // ため、同じではない。ファイル同士を比較する。2008.05.06.
    NSDictionary *theSourcePList = [NSDictionary dictionaryWithContentsOfFile:theSourcePath];
    NSDictionary *theDestPList = [NSDictionary dictionaryWithContentsOfFile:theDestPath];

    return ([theSourcePList isEqualToDictionary:theDestPList]);

// NSFileManager の contentsEqualAtPath:andPath: では、宣言部分の「Apple Computer（Tiger以前）」と「Apple（Leopard）」の違いが引っかかってしまうため、使えなくなった。 2008.05.06.
//    return ([theFileManager contentsEqualAtPath:theSourcePath andPath:theDestPath]);
}


// ------------------------------------------------------
- (NSArray *)styleNames
// スタイル名配列を返す
// ------------------------------------------------------
{
    NSMutableArray *outArray = [NSMutableArray array];
    int i, theCount = [_coloringStyleArray count];

    for (i = 0; i < theCount; i++) {
        [outArray addObject:[[_coloringStyleArray objectAtIndex:i] objectForKey:k_SCKey_styleName]];
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
- (BOOL)existsStyleFileWithStyleName:(NSString *)inStyleFileName
// あるファイル名を持つファイルがstyle保存ディレクトリにあるかどうかを返す（引数はファイルパスまたはstyle名）
//------------------------------------------------------
{
    NSFileManager *theFileManager = [NSFileManager defaultManager];
    NSString *thePath = [NSString stringWithFormat:@"%@/%@%@", 
                [self pathOfStyleDirectory], 
                [[inStyleFileName lastPathComponent] stringByDeletingPathExtension], 
                @".plist"];

    return ([theFileManager fileExistsAtPath:thePath]);
}


//------------------------------------------------------
- (BOOL)importStyleFile:(NSString *)inStyleFileName
// 外部styleファイルを保存ディレクトリにコピーする
//------------------------------------------------------
{
    BOOL outBool = NO;
    NSFileManager *theFileManager = [NSFileManager defaultManager];
    NSString *theDestination = 
            [[self pathOfStyleDirectory] stringByAppendingPathComponent:[inStyleFileName lastPathComponent]];

    if ([theFileManager fileExistsAtPath:theDestination]) {
        (void)[theFileManager removeFileAtPath:theDestination handler:nil];
    }
    outBool = [theFileManager copyPath:inStyleFileName toPath:theDestination handler:nil];
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
    NSString *thePath = 
            [NSString stringWithFormat:@"%@/%@%@", [self pathOfStyleDirectory], inStyleName, @".plist"];

    if ([theFileManager fileExistsAtPath:thePath]) {
        outValue = [theFileManager removeFileAtPath:thePath handler:nil];
        if (outValue) {
            // 内部で持っているキャッシュ用データを更新
            [self setupColoringStyleArray];
            [self setupExtensionAndSyntaxTable];
        } else {
            NSLog(@"Error. Could not remove \"%@\"", thePath);
        }
    } else {
        NSLog(@"Error. Could not be found \"%@\" for remove", thePath);
    }
    return outValue;
}


//------------------------------------------------------
- (NSString *)filePathOfStyleName:(NSString *)inStyleName
// style名からstyle定義ファイルのパスを返す
//------------------------------------------------------
{
    NSFileManager *theFileManager = [NSFileManager defaultManager];
    NSString *thePath = 
            [NSString stringWithFormat:@"%@/%@%@", [self pathOfStyleDirectory], inStyleName, @".plist"];

    if ([theFileManager fileExistsAtPath:thePath]) {
        return thePath;
    } else {
        return nil;
    }
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
    int theRow = [theTableView selectedRow];

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
    NSArray *theContents = [NSArray arrayWithObject:
                [NSMutableDictionary dictionaryWithContentsOfFile:theSourcePath]];

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
    NSDictionary *outDict = [NSDictionary dictionaryWithObjectsAndKeys:
                    [NSMutableString stringWithString:@""] , k_SCKey_styleName, 
                    [NSMutableArray array], k_SCKey_extensions, 
                    [NSMutableArray array], k_SCKey_keywordsArray, 
                    [NSMutableArray array], k_SCKey_commandsArray, 
                    [NSMutableArray array], k_SCKey_valuesArray, 
                    [NSMutableArray array], k_SCKey_numbersArray, 
                    [NSMutableArray array], k_SCKey_stringsArray, 
                    [NSMutableArray array], k_SCKey_charactersArray, 
                    [NSMutableArray array], k_SCKey_commentsArray, 
                    [NSMutableArray array], k_SCKey_outlineMenuArray, 
                    [NSMutableArray array], k_SCKey_completionsArray, 
                    nil];

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
#if MAC_OS_X_VERSION_10_5 > MAC_OS_X_VERSION_MAX_ALLOWED
		theValueCreated = [theFileManager createDirectoryAtPath:theDirPath attributes:nil];
#else	
		NSError *createDirError = nil;
		theValueCreated = [theFileManager createDirectoryAtPath:theDirPath withIntermediateDirectories:NO attributes:nil error:&createDirError];
		if (createDirError != nil) {
			NSLog(@"Error. SyntaxStyles directory could not be created.");
			return;
		}
#endif		
		
    }
    if ((theExists && theValueIsDir) || (theValueCreated)) {
        (void)[self copyDefaultSyntaxStylesTo:theDirPath];
    } else {
        NSLog(@"Error. SyntaxStyles directory could not be found.");
        return;
    }

    // styleデータの読み込み
    NSMutableArray *theArray = [NSMutableArray array];
#if MAC_OS_X_VERSION_10_5 > MAC_OS_X_VERSION_MAX_ALLOWED
    NSArray *theFiles = [theFileManager directoryContentsAtPath:theDirPath];
#else
	NSError *findFileError = nil;
    NSArray *theFiles = [theFileManager contentsOfDirectoryAtPath:theDirPath error:	&findFileError];
	if (findFileError != nil) {
        NSLog(@"Error on seeking SyntaxStyle Files Directory.");
        return;		
	}
#endif
    
	NSString *thePath = nil;
    int i, theCount = [theFiles count];
    for (i = 0; i < theCount; i++) {
        NSString *theFileName = [theFiles objectAtIndex:i];
        if ((![theFileName hasPrefix:@"."]) && ([theFileName hasSuffix:@".plist"])) { // ドットファイル除去
            thePath = [theDirPath stringByAppendingPathComponent:theFileName];
            NSMutableDictionary *theDict = [NSMutableDictionary dictionaryWithContentsOfFile:thePath];
			// thePathが無効だった場合などに、theDictがnilになる場合がある
			if (theDict != nil) {				
				// k_SCKey_styleName をファイル名にそろえておく(Finderで移動／リネームされたときへの対応)
				[theDict setObject:[[theFileName lastPathComponent] stringByDeletingPathExtension] 
						forKey:k_SCKey_styleName];
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
    int i, theCount;

    while (theDict = [theEnumerator nextObject]) {
        theArray = [theDict objectForKey:k_SCKey_extensions];
        if (!theArray) { continue; }
        theCount = [theArray count];
        for (i = 0; i < theCount; i++) {
            theExtension = [[theArray objectAtIndex:i] valueForKey:k_SCKey_arrayKeyString];
            if (theAddedName = [theTable valueForKey:theExtension]) { // 同じ拡張子を持つものがすでにあるとき
                NSMutableArray *theErrorArray = [theErrors valueForKey:theExtension];
                if (!theErrorArray) {
                    theErrorArray = [NSMutableArray array];
                    [theErrors setValue:theErrorArray forKey:theExtension];
                }
                if (![theErrorArray containsObject:theAddedName]) {
                    [theErrorArray addObject:theAddedName];
                }
                [theErrorArray addObject:[theDict valueForKey:k_SCKey_styleName]];
            } else {
                [theTable setValue:[theDict valueForKey:k_SCKey_styleName] forKey:theExtension];
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
    NSArray *theArraysArray = [NSArray arrayWithObjects:k_SCKey_allArrays, nil];
    NSMutableArray *theKeyStringArray;
    NSSortDescriptor *theDescriptorOne = [[[NSSortDescriptor alloc] initWithKey:k_SCKey_beginString 
                    ascending:YES selector:@selector(caseInsensitiveCompare:)] autorelease];
    NSSortDescriptor *theDescriptorTwo = [[[NSSortDescriptor alloc] initWithKey:k_SCKey_arrayKeyString 
                    ascending:YES selector:@selector(caseInsensitiveCompare:)] autorelease];
    NSArray *theDescriptors = [NSArray arrayWithObjects:theDescriptorOne, theDescriptorTwo, nil];
    int i;

    // _styleController内のコンテンツオブジェクト取得
    NSArray *theContent = [_styleController selectedObjects];
    // styleデータ保存（選択中のオブジェクトはひとつだから、配列の最初の要素のみ処理する 2008.11.02）
    theDict = [[theContent objectAtIndex:0] mutableCopy]; // ===== mutableCopy
    for (i = 0; i < [theArraysArray count]; i++) {
        theKeyStringArray = [theDict objectForKey:[theArraysArray objectAtIndex:i]];
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
    NSString *outPath = [NSHomeDirectory( ) 
            stringByAppendingPathComponent:@"Library/Application Support/CotEditor/SyntaxColorings"];

    return outPath;
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
    int i;

    for (i = 0; i < [theSourceNames count]; i++) {
        theSource = [theSourceDirPath stringByAppendingPathComponent:[theSourceNames objectAtIndex:i]];
        theDestination = [inDestinationPath stringByAppendingPathComponent:[theDestNames objectAtIndex:i]];
        if (([theFileManager fileExistsAtPath:theSource]) && 
                    (![theFileManager fileExistsAtPath:theDestination])) {
            theValue = [theFileManager copyPath:theSource toPath:theDestination handler:nil];
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
    int i = 1;

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
        [outName setString:[NSString stringWithFormat:@"%@ %i", theCopyName, i]];
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
        id theKey, theArray;
        int i, theCount;

        [theStr setString:NSLocalizedString(@"The following Extension list is registered by two or more styles for one extension. \nCotEditor uses the first style.\n\n",@"")];
        [theStr appendString:NSLocalizedString(@"\"Extension\" = \"Style Names\"\n  -  -  -  -  -  -  -\n",@"")];

        // [NSDictionary descriptionInStringsFileFormat] だと日本語がユニコード16進表示になってしまうので、
        // マニュアルで分解し文字列に変換（もっとうまいやり方あるだろ (-_-; ... 2005.12.03）
        while (theKey = [theEnumerator nextObject]) {
            theArray = [theErrors objectForKey:theKey];
            theCount = [theArray count];
            [theStr appendFormat:@"\"%@\" = \"", theKey];
            for (i = 0; i < theCount; i++) {
                [theStr appendString:[theArray objectAtIndex:i]];
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

    NSTableColumn *theColumn = [[inTableView tableColumns] objectAtIndex:0];
    int theRow = [inTableView selectedRow];
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
- (int)syntaxElementError
// 構文チェック実行
// ------------------------------------------------------
{
    if (floor(NSAppKitVersionNumber) <=  NSAppKitVersionNumber10_3) { // = 10.3.x以前
        return ([self syntaxElementCheckInPanter]);
    } else {
        return ([self syntaxElementCheck]);
    }
}


// ------------------------------------------------------
- (int)syntaxElementCheckInPanter
// 10.3で、正規表現構文と重複のチェック実行
// ------------------------------------------------------
{
    NSArray *theSelectedArray = [_styleController selectedObjects];
    NSMutableString *theResultStr = [NSMutableString string];
    int outCount = 0;

    if ([theSelectedArray count] == 1) {
        NSDictionary *theDict = [theSelectedArray objectAtIndex:0];
        NSArray *theSyntaxArray = [NSArray arrayWithObjects:k_SCKey_syntaxCheckArrays, nil];
        NSArray *theArray;
        NSString *theBeginStr, *theEndStr, *theTmpBeginStr = nil, *theTmpEndStr = nil;
        NSString *theArrayName = nil, *theArrayNameDeletingArray = nil;
        int i, j, theSyntaxCount = [theSyntaxArray count];

        for (i = 0; i < theSyntaxCount; i++) {
            theArrayName = [theSyntaxArray objectAtIndex:i];
            theArray = [theDict objectForKey:theArrayName];
            theArrayNameDeletingArray = [theArrayName substringToIndex:([theArrayName length] - 5)];
            int theArrayCount = [theArray count];
            for (j = 0; j < theArrayCount; j++) {
                theBeginStr = [[theArray objectAtIndex:j] objectForKey:k_SCKey_beginString];
                theEndStr = [[theArray objectAtIndex:j] objectForKey:k_SCKey_endString];
                if (([theTmpBeginStr isEqualToString:theBeginStr]) && 
                        (((theTmpEndStr == nil) && (theEndStr == nil)) || 
                            ([theTmpEndStr isEqualToString:theEndStr]))) {
                    outCount++;
                    [theResultStr appendFormat:@"%i.  %@ :(Begin string) > %@\n  >>> multiple registered.\n\n", 
                            outCount, theArrayNameDeletingArray, theBeginStr];
                } else if ([[[theArray objectAtIndex:j] objectForKey:k_SCKey_regularExpression] boolValue]) {
                    NS_DURING
                        (void)[OGRegularExpression regularExpressionWithString:theBeginStr];
                    NS_HANDLER
                        // 例外処理 (OgreKit付属のRegularExpressionTestのコードを参考にしています)
                        outCount++;
                        [theResultStr appendFormat:@"%i.  %@ :(Begin string) > %@\n  >>> %@\n\n", 
                                outCount, theArrayNameDeletingArray, theBeginStr, [localException reason]];
                    NS_ENDHANDLER

                    if (theEndStr != nil) {
                        NS_DURING
                            (void)[OGRegularExpression regularExpressionWithString:theEndStr];
                        NS_HANDLER
                            // 例外処理 (OgreKit付属のRegularExpressionTestのコードを参考にしています)
                            outCount++;
                            [theResultStr appendFormat:@"%i.  %@ :(End string) > %@\n  >>> %@\n\n", 
                                outCount, theArrayNameDeletingArray, theEndStr, [localException reason]];
                        NS_ENDHANDLER
                    }
                } else if ([theArrayName isEqualToString:k_SCKey_outlineMenuArray]) {
                    NS_DURING
                        (void)[OGRegularExpression regularExpressionWithString:theBeginStr];
                    NS_HANDLER
                        // 例外処理 (OgreKit付属のRegularExpressionTestのコードを参考にしています)
                        outCount++;
                        [theResultStr appendFormat:@"%i.  %@ :(RE string) > %@\n  >>> %@\n\n", 
                                outCount, theArrayNameDeletingArray, theBeginStr, [localException reason]];
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


// ------------------------------------------------------
- (int)syntaxElementCheck
// 10.4+で、正規表現構文と重複のチェック実行
// ------------------------------------------------------
{
    NSArray *theSelectedArray = [_styleController selectedObjects];
    NSMutableString *theResultStr = [NSMutableString string];
    int outCount = 0;

    if ([theSelectedArray count] == 1) {
        NSDictionary *theDict = [theSelectedArray objectAtIndex:0];
        NSArray *theSyntaxArray = [NSArray arrayWithObjects:k_SCKey_syntaxCheckArrays, nil];
        NSArray *theArray;
        NSString *theBeginStr, *theEndStr, *theTmpBeginStr = nil, *theTmpEndStr = nil;
        NSString *theArrayName = nil, *theArrayNameDeletingArray = nil;
        int i, j, theSyntaxCount = [theSyntaxArray count];
        int theCapCount;
        NSError *theError = NULL;

        for (i = 0; i < theSyntaxCount; i++) {
            theArrayName = [theSyntaxArray objectAtIndex:i];
            theArray = [theDict objectForKey:theArrayName];
            theArrayNameDeletingArray = [theArrayName substringToIndex:([theArrayName length] - 5)];
            int theArrayCount = [theArray count];

            for (j = 0; j < theArrayCount; j++) {
                theBeginStr = [[theArray objectAtIndex:j] objectForKey:k_SCKey_beginString];
                theEndStr = [[theArray objectAtIndex:j] objectForKey:k_SCKey_endString];

                if (([theTmpBeginStr isEqualToString:theBeginStr]) && 
                        (((theTmpEndStr == nil) && (theEndStr == nil)) || 
                            ([theTmpEndStr isEqualToString:theEndStr]))) {

                    outCount++;
                    [theResultStr appendFormat:@"%i.  %@ :(Begin string) > %@\n  >>> multiple registered.\n\n", 
                            outCount, theArrayNameDeletingArray, theBeginStr];

                } else if ([[[theArray objectAtIndex:j] objectForKey:k_SCKey_regularExpression] boolValue]) {

                    theCapCount = 
                            [NSString captureCountForRegex:theBeginStr options:RKLNoOptions error:&theError];
                    if (theCapCount == -1) { // エラーのとき
                        outCount++;
                        [theResultStr appendFormat:@"%i.  %@ :(Begin string) > %@\n  >>> Error \"%@\" in column %@: %@<<HERE>>%@\n\n", 
                                outCount, theArrayNameDeletingArray, theBeginStr, 
                                [[theError userInfo] objectForKey:RKLICURegexErrorNameErrorKey], 
                                [[theError userInfo] objectForKey:RKLICURegexOffsetErrorKey], 
                                [[theError userInfo] objectForKey:RKLICURegexPreContextErrorKey], 
                                [[theError userInfo] objectForKey:RKLICURegexPostContextErrorKey]];
                    }
                    if (theEndStr != nil) {
                        theCapCount = 
                                [NSString captureCountForRegex:theEndStr options:RKLNoOptions error:&theError];
                        if (theCapCount == -1) { // エラーのとき
                            outCount++;
                            [theResultStr appendFormat:@"%i.  %@ :(End string) > %@\n  >>> Error \"%@\" in column %@: %@<<HERE>>%@\n\n", 
                                    outCount, theArrayNameDeletingArray, theEndStr, 
                                    [[theError userInfo] objectForKey:RKLICURegexErrorNameErrorKey], 
                                    [[theError userInfo] objectForKey:RKLICURegexOffsetErrorKey], 
                                    [[theError userInfo] objectForKey:RKLICURegexPreContextErrorKey], 
                                    [[theError userInfo] objectForKey:RKLICURegexPostContextErrorKey]];
                        }
                    }

                // （outlineMenuは、過去の定義との互換性保持のためもあってOgreKitを使っている 2008.05.16）
                } else if ([theArrayName isEqualToString:k_SCKey_outlineMenuArray]) {
                    NS_DURING
                        (void)[OGRegularExpression regularExpressionWithString:theBeginStr];
                    NS_HANDLER
                        // 例外処理 (OgreKit付属のRegularExpressionTestのコードを参考にしています)
                        outCount++;
                        [theResultStr appendFormat:@"%i.  %@ :(RE string) > %@\n  >>> %@\n\n", 
                                outCount, theArrayNameDeletingArray, theBeginStr, [localException reason]];
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
