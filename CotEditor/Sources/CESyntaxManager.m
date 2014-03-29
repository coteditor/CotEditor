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
#import "constants.h"


@interface CESyntaxManager ()

@property (nonatomic) NSArray *coloringStyleArray;
@property (nonatomic) NSInteger sheetOpeningMode;
@property (nonatomic) NSUInteger selectedDetailTag; // Elementsタブでのポップアップメニュー選択用バインディング変数(#削除不可)

@property (nonatomic, weak) IBOutlet NSTextField *styleNameField;
@property (nonatomic, weak) IBOutlet NSTextField *messageField;
@property (nonatomic, weak) IBOutlet NSPopUpButton *elementPopUpButton;
@property (nonatomic, weak) IBOutlet NSButton *factoryDefaultsButton;
@property (nonatomic, strong) IBOutlet NSTextView *syntaxElementCheckTextView;  // on 10.8 NSTextView cannot be weak

@property (nonatomic) IBOutlet NSArrayController *styleController;

// readonly
@property (nonatomic, readwrite) NSString *selectedStyleName;
@property (nonatomic, readwrite) NSDictionary *xtsnAndStyleTable;
@property (nonatomic, readwrite) NSDictionary *extensionErrors;
@property (nonatomic, readwrite) NSArray *extensions;

@property (nonatomic, readwrite) IBOutlet NSWindow *editWindow;

@end



#pragma mark -

@implementation CESyntaxManager

#pragma mark Class Methods

//=======================================================
// Class method
//
//=======================================================

// ------------------------------------------------------
/// return singleton instance
+ (instancetype)sharedManager
// ------------------------------------------------------
{
    static dispatch_once_t predicate;
    static id shared = nil;
    
    dispatch_once(&predicate, ^{
        shared = [[self alloc] init];
    });
    
    return shared;
}




#pragma mark Superclass Methods

//=======================================================
// NSObject method
//
//=======================================================

// ------------------------------------------------------
/// 初期化
- (instancetype)init
// ------------------------------------------------------
{
    self = [super init];
    if (self) {
        (void)[NSBundle loadNibNamed:@"SyntaxEditSheet" owner:self];
        [self setSelectedStyleName:[NSString string]];
        [self setEditedNewStyleName:[NSString string]];
        [self setupColoringStyleArray];
        [self setupExtensionAndSyntaxTable];
    }
    return self;
}



#pragma mark Public Methods

//=======================================================
// Public method
//
//=======================================================

// ------------------------------------------------------
/// シートの表示に備え、シンタックスカラーリングスタイル定義配列のうちの一つを選択する（バインディングのため）
- (BOOL)setSelectionIndexOfStyle:(NSInteger)styleIndex mode:(NSInteger)mode
// ------------------------------------------------------
{
    NSArray *colorings;
    NSString *name;
    NSUInteger selected;

    [self setSheetOpeningMode:mode];
    switch (mode) {
        case k_syntaxCopyTag: // Copy
            selected = styleIndex;
            colorings = [self coloringStyleArray];
            name = [self copiedSyntaxName:colorings[styleIndex][k_SCKey_styleName]];
            colorings[styleIndex][k_SCKey_styleName] = name;
            break;
            
        case k_syntaxNewTag: // New
            selected = 0;
            colorings = @[[NSMutableDictionary dictionaryWithDictionary:[self emptyColoringStyle]]];
            name = @"";
            break;
            
        default: // Edit, Delete
            selected = styleIndex;
            colorings = [self coloringStyleArray];
            name = colorings[styleIndex][k_SCKey_styleName];
            break;
    }
    if (!name) { return NO; }
    
    [self setSelectedStyleName:name];
    [[self styleController] setContent:colorings];

    // シートのコントロール類をセットアップ
    [self setupSyntaxSheetControles];

    return ([[self styleController] setSelectionIndex:selected]);
}


// ------------------------------------------------------
/// 拡張子に応じたstyle名を返す
- (NSString *)syntaxNameFromExtension:(NSString *)extension
// ------------------------------------------------------
{
    NSString *syntaxName = [self xtsnAndStyleTable][extension];

    return (syntaxName) ? syntaxName : [[NSUserDefaults standardUserDefaults] stringForKey:k_key_defaultColoringStyleName];
}


// ------------------------------------------------------
/// style名に応じたstyle辞書を返す
- (NSDictionary *)syntaxWithStyleName:(NSString *)styleName
// ------------------------------------------------------
{
    if (![styleName isEqualToString:@""] && ![styleName isEqualToString:NSLocalizedString(@"None", nil)]) {
        NSMutableDictionary *styleDict;
        for (NSDictionary *dict in [self coloringStyleArray]) {
            if ([dict[k_SCKey_styleName] isEqualToString:styleName]) {
                NSArray *syntaxes = @[k_SCKey_allColoringArrays];
                NSArray *theArray;
                NSUInteger count = 0;
                styleDict = [dict mutableCopy];

                for (id key in syntaxes) {
                    theArray = styleDict[key];
                    count = count + [theArray count];
                }
                styleDict[k_SCKey_numOfObjInArray] = @(count);
                return styleDict;
            }
        }
    }
    // デフォルトデータを返す
    return [self emptyColoringStyle];
}


// ------------------------------------------------------
/// バンドルされているシンタックスカラーリングスタイルファイル名配列を返す
- (NSArray *)defaultSyntaxFileNames
// ------------------------------------------------------
{
    NSFileManager *fileManager = [NSFileManager defaultManager];
    NSURL *sourceDirURL = [[[NSBundle mainBundle] bundleURL] URLByAppendingPathComponent:@"/Contents/Resources"];
    NSDirectoryEnumerator *enumerator = [fileManager enumeratorAtURL:sourceDirURL
                                          includingPropertiesForKeys:nil
                                                             options:NSDirectoryEnumerationSkipsSubdirectoryDescendants
                                                        errorHandler:nil];
    NSMutableArray *fileNames = [NSMutableArray array];
    NSURL *URL;
    
    while (URL = [enumerator nextObject]) {
        if ([[URL lastPathComponent] hasPrefix:k_bundleSyntaxStyleFilePrefix] &&
            [[URL pathExtension] isEqualToString:@"plist"])
        {
            [fileNames addObject:[URL lastPathComponent]];
        }
    }
    return fileNames;
}


// ------------------------------------------------------
/// バンドルされているシンタックスカラーリングスタイルファイル名のプレフィックスを除いた配列を返す
- (NSArray *)defaultSyntaxFileNamesWithoutPrefix
// ------------------------------------------------------
{
    NSArray *fileNames = [self defaultSyntaxFileNames];
    NSMutableArray *fileNamesWithoutPrefix = [NSMutableArray array];
    NSUInteger prefixLength = [k_bundleSyntaxStyleFilePrefix length];
    
    for (NSString *fileName in fileNames) {
        [fileNamesWithoutPrefix addObject:[fileName substringFromIndex:prefixLength]];
    }
    return fileNamesWithoutPrefix;
}


// ------------------------------------------------------
/// あるスタイルネームがデフォルトで用意されているものかどうかを返す
- (BOOL)isDefaultSyntaxStyle:(NSString *)styleName
// ------------------------------------------------------
{
    if ([styleName isEqualToString:@""]) { return NO; }
    
    NSArray *names = [self defaultSyntaxFileNamesWithoutPrefix];
    
    return [names containsObject:[styleName stringByAppendingPathExtension:@"plist"]];
}


// ------------------------------------------------------
/// あるスタイルネームがデフォルトで用意されているものと同じかどうかを返す
- (BOOL)isEqualToDefaultSyntaxStyle:(NSString *)styleName
// ------------------------------------------------------
{
    if ([styleName isEqualToString:@""]) { return NO; }
    
    NSURL *destURL = [[[self URLOfStyleDirectory] URLByAppendingPathComponent:styleName] URLByAppendingPathExtension:@"plist"];
    NSURL *sourceDirURL =[[[NSBundle mainBundle] bundleURL] URLByAppendingPathComponent:@"/Contents/Resources"];
    NSURL *sourceURL = [[sourceDirURL URLByAppendingPathComponent:[NSString stringWithFormat:@"%@%@", k_bundleSyntaxStyleFilePrefix, styleName]] URLByAppendingPathExtension:@"plist"];
    
    if (![sourceDirURL checkResourceIsReachableAndReturnError:nil] ||
        ![destURL checkResourceIsReachableAndReturnError:nil])
    {
        return NO;
    }

    // （[self syntaxWithStyleName:[self selectedStyleName]]] で返ってくる辞書には numOfObjInArray が付加されている
    // ため、同じではない。ファイル同士を比較する。2008.05.06.
    NSDictionary *sourcePList = [NSDictionary dictionaryWithContentsOfURL:sourceURL];
    NSDictionary *destPList = [NSDictionary dictionaryWithContentsOfURL:destURL];

    return [sourcePList isEqualToDictionary:destPList];

// NSFileManager の contentsEqualAtPath:andPath: では、宣言部分の「Apple Computer（Tiger以前）」と「Apple（Leopard）」の違いが引っかかってしまうため、使えなくなった。 2008.05.06.
//    return ([theFileManager contentsEqualAtPath:[sourceURL path] andPath:[destURL path]]);
}


// ------------------------------------------------------
/// スタイル名配列を返す
- (NSArray *)styleNames
// ------------------------------------------------------
{
    NSMutableArray *styleNames = [NSMutableArray array];
    
    for (NSDictionary *dict in [self coloringStyleArray]) {
        [styleNames addObject:dict[k_SCKey_styleName]];
    }

    return styleNames;
}


//------------------------------------------------------
/// ある名前を持つstyleファイルがstyle保存ディレクトリにあるかどうかを返す
- (BOOL)existsStyleFileWithStyleName:(NSString *)styleName
//------------------------------------------------------
{
    NSURL *URL = [[[self URLOfStyleDirectory] URLByAppendingPathComponent:styleName] URLByAppendingPathExtension:@"plist"];

    return [URL checkResourceIsReachableAndReturnError:nil];
}


//------------------------------------------------------
/// 外部styleファイルを保存ディレクトリにコピーする
- (BOOL)importStyleFile:(NSString *)styleFileName
//------------------------------------------------------
{
    BOOL success = NO;
    NSFileManager *fileManager = [NSFileManager defaultManager];
    NSURL *fileURL = [NSURL fileURLWithPath:styleFileName];
    NSURL *destURL = [[self URLOfStyleDirectory] URLByAppendingPathComponent:[fileURL lastPathComponent]];

    if ([destURL checkResourceIsReachableAndReturnError:nil]) {
        [fileManager removeItemAtURL:destURL error:nil];
    }
    success = [fileManager copyItemAtURL:fileURL toURL:destURL error:nil];
    if (success) {
        // 内部で持っているキャッシュ用データを更新
        [self setupColoringStyleArray];
        [self setupExtensionAndSyntaxTable];
    }
    return success;
}


//------------------------------------------------------
/// style名に応じたstyleファイルを削除する
- (BOOL)removeStyleFileWithStyleName:(NSString *)styleName
//------------------------------------------------------
{
    BOOL success = NO;
    if ([styleName length] < 1) { return success; }
    NSFileManager *fileManager = [NSFileManager defaultManager];
    NSURL *URL = [[[self URLOfStyleDirectory] URLByAppendingPathComponent:styleName] URLByAppendingPathExtension:@"plist"];

    if ([URL checkResourceIsReachableAndReturnError:nil]) {
        success = [fileManager removeItemAtURL:URL error:nil];
        if (success) {
            // 内部で持っているキャッシュ用データを更新
            [self setupColoringStyleArray];
            [self setupExtensionAndSyntaxTable];
        } else {
            NSLog(@"Error. Could not remove \"%@\"", [URL path]);
        }
    } else {
        NSLog(@"Error. Could not be found \"%@\" for remove", [URL path]);
    }
    return success;
}


//------------------------------------------------------
/// style名からstyle定義ファイルのURLを返す
- (NSURL *)URLOfStyle:(NSString *)styleName
//------------------------------------------------------
{
    NSURL *URL = [[[self URLOfStyleDirectory] URLByAppendingPathComponent:styleName] URLByAppendingPathExtension:@"plist"];
    
    return [URL checkResourceIsReachableAndReturnError:nil] ? URL : nil;
}


//------------------------------------------------------
/// 拡張子重複エラーがあるかどうかを返す
- (BOOL)existsExtensionError
//------------------------------------------------------
{
    return ([[self extensionErrors] count] > 0);
}



#pragma mark Delegate and Notification

//=======================================================
// Delegate method (NSTableView)
//  <== tableViews in Preferences sheet
//=======================================================

// ------------------------------------------------------
/// tableView の選択が変更された
- (void)tableViewSelectionDidChange:(NSNotification *)notification
// ------------------------------------------------------
{
    NSTableView *tableView = [notification object];
    NSInteger row = [tableView selectedRow];

    // 最下行が選択されたのなら、編集開始のメソッドを呼び出す
    //（ここですぐに開始しないのは、選択行のセルが持つ文字列をこの段階では取得できないため）
    if ((row + 1) == [tableView numberOfRows]) {
        [tableView scrollRowToVisible:row];
        [self performSelectorOnMainThread:@selector(editNewAddedRowOfTableView:)
                               withObject:tableView
                            waitUntilDone:NO];
    }
}



#pragma mark Action Messages

//=======================================================
// Action messages
//
//=======================================================

// ------------------------------------------------------
/// スタイルの内容を出荷時設定に戻す
- (IBAction)setToFactoryDefaults:(id)sender
// ------------------------------------------------------
{
    if (![self isDefaultSyntaxStyle:[self selectedStyleName]]) { return; }
    NSURL *sourceDirURL = [[[NSBundle mainBundle] bundleURL] URLByAppendingPathComponent:@"/Contents/Resources"];
    NSURL *sourceURL = [[sourceDirURL URLByAppendingPathComponent:[NSString stringWithFormat:@"%@%@",
                                                                   k_bundleSyntaxStyleFilePrefix, [self selectedStyleName]]]
                        URLByAppendingPathExtension:@"plist"];
    
    if (![sourceURL checkResourceIsReachableAndReturnError:nil]) { return; }
    
    NSArray *contents = @[[NSMutableDictionary dictionaryWithContentsOfURL:sourceURL]];

    // フォーカスを移しておく
    [[sender window] makeFirstResponder:[sender window]];
    // コントローラに内容をセット
    [[self styleController] setContent:contents];
    (void)[[self styleController] setSelectionIndex:0];
    // シートのコントロール類をセットアップ
    [self setupSyntaxSheetControles];
    // デフォルト設定に戻すボタンを無効化
    [[self factoryDefaultsButton] setEnabled:NO];
}


// ------------------------------------------------------
/// カラーシンタックス編集シートの OK / Cancel ボタンが押された
- (IBAction)closeSyntaxEditSheet:(id)sender
// ------------------------------------------------------
{
    // フォーカスを移して入力中の値を確定
    [[sender window] makeFirstResponder:sender];
    // style名から先頭または末尾のスペース／タブ／改行を排除
    NSMutableString *string = [[[[self styleNameField] stringValue] stringByTrimmingCharactersInSet:
                                [NSCharacterSet whitespaceAndNewlineCharacterSet]] mutableCopy];
    (void)[string replaceOccurrencesOfString:@"\n" withString:@"" options:0 range:NSMakeRange(0, [string length])];
    (void)[string replaceOccurrencesOfString:@"\t" withString:@"" options:0 range:NSMakeRange(0, [string length])];
    [[self styleNameField] setStringValue:string];

    if ([sender tag] == k_okButtonTag) { // ok のときstyleを保存
        if (([self sheetOpeningMode] == k_syntaxCopyTag) || ([self sheetOpeningMode] == k_syntaxNewTag)) {
            if ([string length] < 1) { // ファイル名としても使われるので、空は不可
                [[self messageField] setStringValue:NSLocalizedString(@"Input the Style Name !",@"")];
                NSBeep();
                [[[self styleNameField] window] makeFirstResponder:[self styleNameField]];
                return;
            } else if ([self existsStyleFileWithStyleName:string]) { // 既にある名前は不可
                [[self messageField] setStringValue:[NSString stringWithFormat:
                            NSLocalizedString(@"\"%@\" is already exist. Input new name.",@""), string]];
                NSBeep();
                [[[self styleNameField] window] makeFirstResponder:[self styleNameField]];
                return;
            }
            // 入力されたstyle名をコントローラで選択されたものとして保持しておく（ファイル書き込み時の照合のため）
            [self setSelectedStyleName:string];
        }
        // エラー未チェックかつエラーがあれば、表示（エラーを表示していてOKボタンを押下したら、そのまま確定）
        if (([[[self syntaxElementCheckTextView] string] isEqualToString:@""]) && ([self syntaxElementError] > 0)) {
            // 「構文要素チェック」を選択
            // （selectItemAtIndex: だとバインディングが実行されないので、メニューを取得して選択している）
            NSBeep();
            [[[self elementPopUpButton] menu] performActionForItemAtIndex:11];
            return;
        }
        [self setEditedNewStyleName:string];
        [self setIsOkButtonPressed:YES];
        [self saveColoringStyle];
    }
    // 内部で持っているキャッシュ用データを更新
    [self setupColoringStyleArray];
    [self setupExtensionAndSyntaxTable];
    [[self syntaxElementCheckTextView] setString:@""]; // 構文チェック結果文字列を消去
    [NSApp stopModal];
}


// ------------------------------------------------------
/// 構文チェックを開始
- (IBAction)startSyntaxElementCheck:(id)sender
// ------------------------------------------------------
{
    (void)[self syntaxElementError];
}




#pragma mark Private Mthods

//=======================================================
// Private method
//
//=======================================================

//------------------------------------------------------
/// 空の新規styleを返す
- (NSDictionary *)emptyColoringStyle
//------------------------------------------------------
{
    return @{k_SCKey_styleName: [@"" mutableCopy],
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
}


//------------------------------------------------------
/// styleのファイルからのセットアップと読み込み
- (void)setupColoringStyleArray
//------------------------------------------------------
{
    NSURL *dirURL = [self URLOfStyleDirectory]; // データディレクトリパス取得

    // ディレクトリの存在チェック
    NSFileManager *fileManager = [NSFileManager defaultManager];
    BOOL isDirectory = NO, success = NO;
    BOOL exists = [fileManager fileExistsAtPath:[dirURL path] isDirectory:&isDirectory];
    if (!exists) {
		NSError *createDirError = nil;
		success = [fileManager createDirectoryAtURL:dirURL withIntermediateDirectories:NO attributes:nil error:&createDirError];
		if (createDirError != nil) {
			NSLog(@"Error. SyntaxStyles directory could not be created.");
			return;
		}
		
    }
    if ((exists && isDirectory) || (success)) {
        (void)[self copyDefaultSyntaxStylesTo:dirURL];
    } else {
        NSLog(@"Error. SyntaxStyles directory could not be found.");
        return;
    }

    // styleデータの読み込み
    NSMutableArray *styles = [NSMutableArray array];
    NSDirectoryEnumerator *enumerator = [fileManager enumeratorAtURL:dirURL
                                          includingPropertiesForKeys:nil
                                                             options:NSDirectoryEnumerationSkipsSubdirectoryDescendants | NSDirectoryEnumerationSkipsHiddenFiles
                                                        errorHandler:^BOOL(NSURL *url, NSError *error) {
                                                            NSLog(@"Error on seeking SyntaxStyle Files Directory.");
                                                            return YES;
                                                        }];
    
    NSURL *URL;
    while (URL = [enumerator nextObject]) {
        NSMutableDictionary *dict = [NSMutableDictionary dictionaryWithContentsOfURL:URL];
        // URLが無効だった場合などに、theDictがnilになる場合がある
        if (dict != nil) {
            // k_SCKey_styleName をファイル名にそろえておく(Finderで移動／リネームされたときへの対応)
            dict[k_SCKey_styleName] = [[URL lastPathComponent] stringByDeletingPathExtension];
            [styles addObject:dict]; // theDictがnilになってここで落ちる（MacBook Airの場合）
        }
    }
    [self setColoringStyleArray:styles];
}


// ------------------------------------------------------
/// 拡張子<->styleファイルの変換テーブル辞書(key = 拡張子)と、拡張子辞書、拡張子重複エラー辞書を更新
- (void)setupExtensionAndSyntaxTable
// ------------------------------------------------------
{
    NSMutableDictionary *table = [NSMutableDictionary dictionary];
    NSMutableDictionary *errorDict = [NSMutableDictionary dictionary];
    NSMutableArray *extensions = [NSMutableArray array];
    id styleDict, extension, addedName = nil;
    NSArray *extensionArray;

    for (styleDict in [self coloringStyleArray]) {
        extensionArray = styleDict[k_SCKey_extensions];
        if (!extensionArray) { continue; }
        for (NSDictionary *extensionDict in extensionArray) {
            extension = extensionDict[k_SCKey_arrayKeyString];
            if ((addedName = table[extension])) { // 同じ拡張子を持つものがすでにあるとき
                NSMutableArray *errorArray = errorDict[extension];
                if (!errorArray) {
                    errorArray = [NSMutableArray array];
                    [errorDict setValue:errorArray forKey:extension];
                }
                if (![errorArray containsObject:addedName]) {
                    [errorArray addObject:addedName];
                }
                [errorArray addObject:styleDict[k_SCKey_styleName]];
            } else {
                [table setValue:styleDict[k_SCKey_styleName] forKey:extension];
                [extensions addObject:extension];
            }
        }
    }
    [self setXtsnAndStyleTable:table];
    [self setExtensionErrors:errorDict];
    [self setExtensions:extensions];
}


//------------------------------------------------------
/// styleのファイルへの保存
- (void)saveColoringStyle
//------------------------------------------------------
{
    NSURL *dirURL = [self URLOfStyleDirectory]; // データディレクトリパス取得
    NSString *styleName;
    NSURL *saveURL;
    NSMutableDictionary *dict;
    NSArray *arraysArray = @[k_SCKey_allArrays];
    NSMutableArray *keyStrings;
    NSSortDescriptor *descriptorOne = [[NSSortDescriptor alloc] initWithKey:k_SCKey_beginString
                                                                  ascending:YES
                                                                   selector:@selector(caseInsensitiveCompare:)];
    NSSortDescriptor *descriptorTwo = [[NSSortDescriptor alloc] initWithKey:k_SCKey_arrayKeyString
                                                                  ascending:YES
                                                                   selector:@selector(caseInsensitiveCompare:)];
    NSArray *descriptors = @[descriptorOne, descriptorTwo];

    // styleController内のコンテンツオブジェクト取得
    NSArray *contents = [[self styleController] selectedObjects];
    // styleデータ保存（選択中のオブジェクトはひとつだから、配列の最初の要素のみ処理する 2008.11.02）
    dict = [contents[0] mutableCopy];
    for (id key in arraysArray) {
        keyStrings = dict[key];
        [keyStrings sortUsingDescriptors:descriptors];
    }
    styleName = [self editedNewStyleName];
    if ([styleName length] > 0) {
        saveURL = [[dirURL URLByAppendingPathComponent:styleName] URLByAppendingPathExtension:@"plist"];
        // style名が変更されたときは、古いファイルを削除する
        if (![styleName isEqualToString:[self selectedStyleName]]) {
            (void)[self removeStyleFileWithStyleName:[self selectedStyleName]];
        }
        [dict writeToURL:saveURL atomically:YES];
    }
}


//------------------------------------------------------
/// styleデータファイル保存用ディレクトリをNSURLで返す
- (NSURL *)URLOfStyleDirectory
//------------------------------------------------------
{
    return [[[NSFileManager defaultManager] URLForDirectory:NSApplicationSupportDirectory
                                                   inDomain:NSUserDomainMask
                                          appropriateForURL:nil
                                                     create:NO
                                                      error:nil]
             URLByAppendingPathComponent:@"CotEditor/SyntaxColorings"];
}


//------------------------------------------------------
/// styleデータファイルを保存用ディレクトリにコピー
- (BOOL)copyDefaultSyntaxStylesTo:(NSURL *)destDirURL
//------------------------------------------------------
{
    NSURL *sourceDirURL = [[[NSBundle mainBundle] bundleURL] URLByAppendingPathComponent:@"/Contents/Resources"];
    NSURL *sourceURL, *destURL;
    NSArray *sourceNames = [self defaultSyntaxFileNames];
    NSArray *destNames = [self defaultSyntaxFileNamesWithoutPrefix];
    NSFileManager *fileManager = [NSFileManager defaultManager];
    BOOL success = NO;
    
    for (NSUInteger i = 0; i < [sourceNames count]; i++) {
        sourceURL = [sourceDirURL URLByAppendingPathComponent:sourceNames[i]];
        destURL = [destDirURL URLByAppendingPathComponent:destNames[i]];
        if ([sourceURL checkResourceIsReachableAndReturnError:nil] &&
            ![destURL checkResourceIsReachableAndReturnError:nil])
        {
            success = [fileManager copyItemAtURL:sourceURL toURL:destURL error:nil];
            if (!success) {
                NSLog(@"Error. Could not copy \"%@\" to \"%@\"...", sourceURL, destURL);
            }
        }
    }
    return success;
}


//------------------------------------------------------
/// コピーされたstyle名を返す
- (NSString *)copiedSyntaxName:(NSString *)originalName
//------------------------------------------------------
{
    NSURL *URL = [self URLOfStyleDirectory];
    NSString *compareName = [originalName stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
    NSString *copyName;
    NSMutableString *copiedSyntaxName = [NSMutableString string];
    NSRange copiedStrRange;
    BOOL copiedState = NO;
    NSInteger i = 1;

    copiedStrRange = [compareName rangeOfRegularExpressionString:NSLocalizedString(@" copy$", nil)];
    if (copiedStrRange.location != NSNotFound) {
        copiedState = YES;
    } else {
        copiedStrRange = [compareName rangeOfRegularExpressionString:NSLocalizedString(@" copy [0-9]+$", nil)];
        if (copiedStrRange.location != NSNotFound) {
            copiedState = YES;
        }
    }
    if (copiedState) {
        copyName = [NSString stringWithFormat:@"%@%@",
                    [compareName substringWithRange:NSMakeRange(0, copiedStrRange.location)],
                    NSLocalizedString(@" copy",@"")];
    } else {
        copyName = [NSString stringWithFormat:@"%@%@", compareName, NSLocalizedString(@" copy", nil)];
    }
    [copiedSyntaxName appendFormat:@"%@.plist", copyName];
    while ([[URL URLByAppendingPathExtension:copiedSyntaxName] checkResourceIsReachableAndReturnError:nil]) {
        i++;
        [copiedSyntaxName setString:[NSString stringWithFormat:@"%@ %li", copyName, (long)i]];
        [copiedSyntaxName appendString:@".plist"];
    }
    return [copiedSyntaxName stringByDeletingPathExtension];
}


//------------------------------------------------------
/// シートのコントロール類をセットアップ
- (void)setupSyntaxSheetControles
//------------------------------------------------------
{
    BOOL isDefaultSyntax = [self isDefaultSyntaxStyle:[self selectedStyleName]];

    [[self styleNameField] setStringValue:[self selectedStyleName]];
    [[self styleNameField] setDrawsBackground:(!isDefaultSyntax)];
    [[self styleNameField] setBezeled:(!isDefaultSyntax)];
    [[self styleNameField] setSelectable:(!isDefaultSyntax)];
    [[self styleNameField] setEditable:(!isDefaultSyntax)];

    if (isDefaultSyntax) {
        [[self styleNameField] setBordered:YES];
        [[self messageField] setStringValue:NSLocalizedString(@"The default style name cannot be changed.",@"")];
        [[self factoryDefaultsButton] setEnabled:![self isEqualToDefaultSyntaxStyle:[self selectedStyleName]]];
    } else {
        [[self messageField] setStringValue:@""];
        [[self factoryDefaultsButton] setEnabled:NO];
    }
    [self setIsOkButtonPressed:NO];
}


//------------------------------------------------------
/// 最下行が選択され、一番左のコラムが入力されていなければ自動的に編集を開始する
- (void)editNewAddedRowOfTableView:(NSTableView *)tableView
//------------------------------------------------------
{
    NSTableColumn *column = [tableView tableColumns][0];
    NSInteger row = [tableView selectedRow];
    id cell = [column dataCellForRow:row];
    if (cell == nil) { return; }
    NSString *string = [cell stringValue];

    if ([string isEqualToString:@""]) {
        if ([[tableView window] makeFirstResponder:tableView]) {
            [tableView editColumn:0 row:row withEvent:nil select:YES];
        }
    }
}
// ------------------------------------------------------
/// 構文チェック実行
- (NSInteger)syntaxElementError
// ------------------------------------------------------
{
    return [self syntaxElementCheck];
}

// ------------------------------------------------------
/// 正規表現構文と重複のチェック実行
- (NSInteger)syntaxElementCheck
// ------------------------------------------------------
{
    NSArray *selectedArray = [[self styleController] selectedObjects];
    NSMutableString *resultStr = [NSMutableString string];
    NSInteger outCount = 0;

    if ([selectedArray count] == 1) {
        NSDictionary *dict = selectedArray[0];
        NSArray *syntaxes = @[k_SCKey_syntaxCheckArrays];
        NSArray *array;
        NSString *beginStr, *endStr, *tmpBeginStr = nil, *tmpEndStr = nil;
        NSString *arrayNameDeletingArray = nil;
        NSInteger capCount;
        NSError *error = nil;

        for (NSString *arrayName in syntaxes) {
            array = dict[arrayName];
            arrayNameDeletingArray = [arrayName substringToIndex:([arrayName length] - 5)];

            for (NSDictionary *dict in array) {
                beginStr = dict[k_SCKey_beginString];
                endStr = dict[k_SCKey_endString];

                if ([tmpBeginStr isEqualToString:beginStr] &&
                    ((!tmpEndStr && !endStr) || [tmpEndStr isEqualToString:endStr])) {

                    outCount++;
                    [resultStr appendFormat:@"%li.  %@ :(Begin string) > %@\n  >>> multiple registered.\n\n",
                     (long)outCount, arrayNameDeletingArray, beginStr];

                } else if ([dict[k_SCKey_regularExpression] boolValue]) {
                    capCount = [beginStr captureCountWithOptions:RKLNoOptions error:&error];
                    if (capCount == -1) { // エラーのとき
                        outCount++;
                        [resultStr appendFormat:@"%li.  %@ :(Begin string) > %@\n  >>> Error \"%@\" in column %@: %@<<HERE>>%@\n\n", 
                                (long)outCount, arrayNameDeletingArray, beginStr,
                                [error userInfo][RKLICURegexErrorNameErrorKey], 
                                [error userInfo][RKLICURegexOffsetErrorKey], 
                                [error userInfo][RKLICURegexPreContextErrorKey], 
                                [error userInfo][RKLICURegexPostContextErrorKey]];
                    }
                    if (endStr != nil) {
                        capCount = [endStr captureCountWithOptions:RKLNoOptions error:&error];
                        if (capCount == -1) { // エラーのとき
                            outCount++;
                            [resultStr appendFormat:@"%li.  %@ :(End string) > %@\n  >>> Error \"%@\" in column %@: %@<<HERE>>%@\n\n",
                                    (long)outCount, arrayNameDeletingArray, endStr, 
                                    [error userInfo][RKLICURegexErrorNameErrorKey], 
                                    [error userInfo][RKLICURegexOffsetErrorKey], 
                                    [error userInfo][RKLICURegexPreContextErrorKey], 
                                    [error userInfo][RKLICURegexPostContextErrorKey]];
                        }
                    }

                // （outlineMenuは、過去の定義との互換性保持のためもあってOgreKitを使っている 2008.05.16）
                } else if ([arrayName isEqualToString:k_SCKey_outlineMenuArray]) {
                    NS_DURING
                        (void)[OGRegularExpression regularExpressionWithString:beginStr];
                    NS_HANDLER
                        // 例外処理 (OgreKit付属のRegularExpressionTestのコードを参考にしています)
                        outCount++;
                        [resultStr appendFormat:@"%li.  %@ :(RE string) > %@\n  >>> %@\n\n", 
                                (long)outCount, arrayNameDeletingArray, beginStr, [localException reason]];
                    NS_ENDHANDLER
                }
                tmpBeginStr = beginStr;
                tmpEndStr = endStr;
            }
        }
        if (outCount == 0) {
            [resultStr setString:NSLocalizedString(@"No Error found.", nil)];
        } else if (outCount == 1) {
            [resultStr insertString:NSLocalizedString(@"One Error was Found !\n\n", nil) atIndex:0];
        } else {
            [resultStr insertString:
                    [NSString stringWithFormat:NSLocalizedString(@"%i Errors were Found !\n\n", nil), outCount]
                    atIndex:0];
        }
    } else {
        [resultStr setString:NSLocalizedString(@"An Error occuerd in Checking.\nNumber of selected object is 2 or more in 'styleController'.", nil)];
    }
    [[self syntaxElementCheckTextView] setString:resultStr];

    return outCount;
}

@end
