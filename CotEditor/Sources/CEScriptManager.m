/*
=================================================
CEScriptManager
(for CotEditor)

 Copyright (C) 2004-2007 nakamuxu.
 Copyright (C) 2014 CotEditor Project
 http://coteditor.github.io
=================================================

encoding="UTF-8"
Created:2005.03.12
 
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

#import "CEScriptManager.h"
#import "CEScriptErrorPanelController.h"
#import "CEDocument.h"
#import "constants.h"


typedef NS_ENUM(NSUInteger, CEScriptOutputType) {
    CENoOutputType,
    CEReplaceSelectionType,
    CEReplaceAllTextType,
    CEInsertAfterSelectionType,
    CEAppendToAllTextType,
    CEPasteboardType
};


@interface CEScriptManager ()

@property (nonatomic) NSFileHandle *outputHandle;
@property (nonatomic) NSFileHandle *errorHandle;
@property (nonatomic) CEScriptOutputType outputType;

@end




#pragma mark -

@implementation CEScriptManager

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
// Superclass method
//
//=======================================================

// ------------------------------------------------------
/// 初期化
- (instancetype)init
// ------------------------------------------------------
{
    self = [super init];
    if (self) {
        [self setupMenuIcon];
        [self setupScriptFolder];
        
        // ノーティフィケーションセンタへデータ出力読み込み完了の通知を依頼
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(availableOutput:)
                                                     name:NSFileHandleReadToEndOfFileCompletionNotification
                                                   object:nil];
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


//------------------------------------------------------
/// Scriptメニューを生成
- (void)buildScriptMenu:(id)sender
//------------------------------------------------------
{
    // メニューデータの読み込みとメニュー構成
    NSMenu *menu = [[[NSApp mainMenu] itemAtIndex:k_scriptMenuIndex] submenu];
    [self removeAllMenuItemsFromParent:menu];
    NSMenuItem *menuItem;

    [self addChildFileItemTo:menu fromDir:[self scriptDirectoryURL]];
    if ([menu numberOfItems] > 0) {
        [menu addItem:[NSMenuItem separatorItem]];
    }
    menuItem = [[NSMenuItem alloc] initWithTitle:NSLocalizedString(@"Open Scripts Folder", nil)
                                          action:@selector(openScriptFolder:)
                                   keyEquivalent:@"a"];
    [menuItem setTarget:self];
    [menu addItem:menuItem];
    menuItem = [[NSMenuItem alloc] initWithTitle:NSLocalizedString(@"Copy Sample to Scripts Folder", nil)
                                          action:@selector(copySampleScriptToUserDomain:)
                                   keyEquivalent:@""];
    [menuItem setTarget:self];
    [menuItem setAlternate:YES];
    [menuItem setKeyEquivalentModifierMask:NSAlternateKeyMask];
    [menuItem setTag:k_scriptMenuDirectoryTag];  // Alternate表示のための修飾キーをCotEditor menu key bindingsの対応外にする
    [menuItem setToolTip:NSLocalizedString(@"Copy bundled sample scripts to the scripts folder.", nil)];
    [menu addItem:menuItem];
    menuItem = [[NSMenuItem alloc] initWithTitle:NSLocalizedString(@"Update Script Menu", nil)
                                          action:@selector(buildScriptMenu:)
                                   keyEquivalent:@""];
    [menuItem setTarget:self];
    [menu addItem:menuItem];
}


//------------------------------------------------------
/// コンテキストメニュー用のメニューを返す
- (NSMenu *)contexualMenu
//------------------------------------------------------
{
    NSMenu *menu = [[[NSApp mainMenu] itemAtIndex:k_scriptMenuIndex] submenu];

    return [menu copy];
}


//------------------------------------------------------
/// Script実行
- (void)launchScript:(id)sender
//------------------------------------------------------
{
    NSURL *URL;
    if ([sender isMemberOfClass:[NSMenuItem class]]) {
        URL = [sender representedObject];
    }
    if (URL == nil) { return; }

    // ファイルがない場合は警告して抜ける
    if (![URL checkResourceIsReachableAndReturnError:nil]) {
        [self showAlertWithMessage:[NSString stringWithFormat:NSLocalizedString(@"The script “%@” does not exist.\n\nCheck it and do “Update Script Menu”.", @""), URL]];
        return;
    }

    // Optキーが押されていたら、アプリでスクリプトを開く
    NSUInteger flags = [NSEvent modifierFlags];
    NSString *extension = [URL pathExtension];
    NSString *message = nil;
    BOOL isModifierPressed = NO;
    BOOL success = YES;
    if (flags == NSAlternateKeyMask) {
        isModifierPressed = YES;
        if ([[self AppleScriptExtensions] containsObject:extension]) {
            success = [[NSWorkspace sharedWorkspace] openURLs:@[URL]
                                     withAppBundleIdentifier:@"com.apple.ScriptEditor2"
                                                     options:0
                              additionalEventParamDescriptor:nil
                                           launchIdentifiers:NULL];
        } else if ([[self scriptExtensions] containsObject:extension]) {
            success = [[NSWorkspace sharedWorkspace] openFile:[URL path] withApplication:[[NSBundle mainBundle] bundlePath]];
        }
        if (!success) {
            message = [NSString stringWithFormat:NSLocalizedString(@"Could not open the script file “%@”.", nil), URL];
        }
    } else if (flags == (NSAlternateKeyMask | NSShiftKeyMask)) {
        isModifierPressed = YES;
        [[NSWorkspace sharedWorkspace] activateFileViewerSelectingURLs:@[URL]];
    }
    if (!success && (message != nil)) {
        // 開けなかったり選択できなければその旨を表示
        [self showAlertWithMessage:message];
    }
    if (isModifierPressed) { return; }

    if ([[self AppleScriptExtensions] containsObject:extension]) {
        NSAppleScript *appleScript = nil;
        NSDictionary *errorInfo = nil;
        NSAppleEventDescriptor *descriptor;
        
        appleScript = [[NSAppleScript alloc] initWithContentsOfURL:URL error:&errorInfo];
        if (appleScript != nil) {
            descriptor = [appleScript executeAndReturnError:&errorInfo];
        }
        // エラーが発生したら、表示
        if (((appleScript == nil) || (descriptor == nil)) && (errorInfo != nil)) {
            [self showAlertWithMessage:[NSString stringWithFormat:NSLocalizedString(@"%@\nErrorNumber: %i",@""),
                                        [errorInfo valueForKey:NSAppleScriptErrorMessage],
                                        [[errorInfo valueForKey:NSAppleScriptErrorNumber] integerValue]]];
        }
    } else if ([[self scriptExtensions] containsObject:extension]) {
        // 実行権限がない場合は警告して抜ける
        if (![[NSFileManager defaultManager] isExecutableFileAtPath:[URL path]]) {
            [self showAlertWithMessage:[NSString stringWithFormat:NSLocalizedString(@"Cannnot execute the script “%@”.\nShell scripts have to have the execute permission.\n\nCheck it's permission.",@""), URL]];
            return;
        }
        [self doLaunchShellScript:URL];
    }
}



#pragma mark Action Messages

//=======================================================
// Action messages
//
//=======================================================

// ------------------------------------------------------
/// ScriptフォルダウィンドウをFinderで表示
- (IBAction)openScriptFolder:(id)sender
// ------------------------------------------------------
{
    NSURL *URL = [[NSBundle mainBundle] URLForResource:@"openScriptMenu" withExtension:@"applescript"];
    
    if (URL == nil) { return; }
    
    NSAppleScript *appleScript = [[NSAppleScript alloc] initWithContentsOfURL:URL error:nil];
    [appleScript executeAndReturnError:nil];
}


// ------------------------------------------------------
/// サンプルスクリプトをユーザ領域にコピー
- (IBAction)copySampleScriptToUserDomain:(id)sender
// ------------------------------------------------------
{
    NSURL *sourceURL = [[NSBundle mainBundle] URLForResource:@"SampleScripts" withExtension:nil];
    NSURL *destURL = [[self scriptDirectoryURL] URLByAppendingPathComponent:@"SampleScript"];
    
    if (![destURL checkResourceIsReachableAndReturnError:nil]) {
        BOOL success = [[NSFileManager defaultManager] copyItemAtURL:sourceURL toURL:destURL error:nil];
        
        if (success) {
            [self buildScriptMenu:self];
        } else {
            NSLog(@"Error. Sample script folder could not be copied.");
        }
        
    } else if ([sender isKindOfClass:[NSMenuItem class]]) {
        // ユーザがメニューからコピーを実行し、すでにサンプルフォルダがあった場合は警告を出す
        NSAlert *alert = [NSAlert alertWithMessageText:NSLocalizedString(@"SampleScript folder exists already.", nil)
                                         defaultButton:nil
                                       alternateButton:nil
                                           otherButton:nil
                             informativeTextWithFormat:NSLocalizedString(@"If you want to replace it with the new one, remove the existing folder at “%@” at first.", nil), [destURL relativePath]];
        [alert runModal];
    }
}



#pragma mark Private Methods

//=======================================================
// Private method
//
//=======================================================

// ------------------------------------------------------
/// 対応しているスクリプトの拡張子
- (NSArray *)scriptExtensions
// ------------------------------------------------------
{
    return @[@"sh", @"pl", @"php", @"rb", @"py"];
}


// ------------------------------------------------------
/// 対応しているAppleScriptの拡張子
- (NSArray *)AppleScriptExtensions
// ------------------------------------------------------
{
    return @[@"applescript", @"scpt"];
}


//------------------------------------------------------
/// メニューバーにアイコンを表示
- (void)setupMenuIcon
//------------------------------------------------------
{
    NSMenuItem *menuItem = [[NSApp mainMenu] itemAtIndex:k_scriptMenuIndex];

    [menuItem setTitle:NSLocalizedString(@"Script Menu", @"")];
    [menuItem setImage:[NSImage imageNamed:@"scriptMenuIcon"]];
}


//------------------------------------------------------
/// Scriptファイル保存用ディレクトリを返す
- (NSURL *)scriptDirectoryURL
//------------------------------------------------------
{
    return [[[NSFileManager defaultManager] URLForDirectory:NSApplicationSupportDirectory
                                                   inDomain:NSUserDomainMask
                                          appropriateForURL:nil
                                                     create:YES
                                                      error:nil]
            URLByAppendingPathComponent:@"CotEditor/ScriptMenu"];
}


//------------------------------------------------------
/// Scriptフォルダの準備をする
- (void)setupScriptFolder
//------------------------------------------------------
{
    NSURL *directoryURL = [self scriptDirectoryURL]; // データディレクトリパス取得
    
    // ディレクトリの存在チェック
    NSNumber *isDirectory = @NO;
    BOOL success = NO;
    [directoryURL getResourceValue:&isDirectory forKey:NSURLIsDirectoryKey error:nil];
    if (![isDirectory boolValue]) {
        success = [[NSFileManager defaultManager] createDirectoryAtURL:directoryURL
                                              withIntermediateDirectories:YES attributes:nil error:nil];
        
        if (!success) {
            NSLog(@"Error. ScriptMenu directory could not found.");
            return;
        }
        
        // サンプルスクリプトをユーザ領域にコピー
        [self copySampleScriptToUserDomain:self];
    }
}


//------------------------------------------------------
/// ファイルを読み込みメニューアイテムを生成／追加する
- (void)addChildFileItemTo:(NSMenu *)menu fromDir:(NSURL *)directoryURL
//------------------------------------------------------
{
    NSArray *URLs = [[NSFileManager defaultManager] contentsOfDirectoryAtURL:directoryURL
                                                  includingPropertiesForKeys:@[NSURLFileResourceTypeKey]
                                                                     options:NSDirectoryEnumerationSkipsPackageDescendants | NSDirectoryEnumerationSkipsHiddenFiles
                                                                       error:nil];
    NSString *menuTitle;
    NSMenuItem *menuItem;
    NSString *resourceType;
    
    for (NSURL *URL in URLs) {
        NSString *extension = [URL pathExtension];
        [URL getResourceValue:&resourceType forKey:NSURLFileResourceTypeKey error:nil];
        if ([resourceType isEqualToString:NSURLFileResourceTypeDirectory]) {
            menuTitle = [self menuTitleFromFileName:[URL lastPathComponent]];
            if ([menuTitle isEqualToString:@"-"]) { // セパレータ
                [menu addItem:[NSMenuItem separatorItem]];
                continue;
            }
            NSMenu *subMenu = [[NSMenu alloc] initWithTitle:menuTitle];
            menuItem = [[NSMenuItem alloc] initWithTitle:menuTitle action:nil keyEquivalent:@""];
            [menuItem setTag:k_scriptMenuDirectoryTag];
            [menu addItem:menuItem];
            [menuItem setSubmenu:subMenu];
            [self addChildFileItemTo:subMenu fromDir:URL];
        } else if ([resourceType isEqualToString:NSURLFileResourceTypeRegular] &&
                ([[self AppleScriptExtensions] containsObject:extension] ||
                 [[self scriptExtensions] containsObject:extension])) {
            NSUInteger modifierMask = 0;
            NSString *keyEquivalent = [self keyEquivalentAndModifierMask:&modifierMask fromFileName:[URL lastPathComponent]];
            menuTitle = [self menuTitleFromFileName:[URL lastPathComponent]];
            menuItem = [[NSMenuItem alloc] initWithTitle:menuTitle
                                                  action:@selector(launchScript:)
                                           keyEquivalent:keyEquivalent];
            [menuItem setKeyEquivalentModifierMask:modifierMask];
            [menuItem setRepresentedObject:URL];
            [menuItem setTarget:self];
            [menuItem setToolTip:NSLocalizedString(@"“Opt + click” to open in Script Editor.",@"")];
            [menu addItem:menuItem];
        }
    }
}


//------------------------------------------------------
/// すべてのメニューアイテムを削除
- (void)removeAllMenuItemsFromParent:(NSMenu *)menu
//------------------------------------------------------
{
    NSArray *items = [menu itemArray];
    NSMenuItem *menuItem;
    NSInteger i;

    for (i = ([items count] - 1); i >= 0; i--) {
        menuItem = items[i];
        if (![menuItem isSeparatorItem] && [menuItem hasSubmenu]) {
            [self removeAllMenuItemsFromParent:[menuItem submenu]];
        }
        [menu removeItem:menuItem];
    }
}


//------------------------------------------------------
/// ファイル／フォルダ名からメニューアイテムタイトル名を生成
- (NSString *)menuTitleFromFileName:(NSString *)fileName
//------------------------------------------------------
{
    NSString *menuTitle = [fileName stringByDeletingPathExtension];
    NSString *extnFirstChar = [[menuTitle pathExtension] substringFromIndex:0];
    NSCharacterSet *specSet = [NSCharacterSet characterSetWithCharactersInString:@"^~$@"];

    // 順番調整の冒頭の番号を削除
    NSRegularExpression *regex = [NSRegularExpression regularExpressionWithPattern:@"^[0-9]+\\)"
                                                                           options:0 error:nil];
    menuTitle = [regex stringByReplacingMatchesInString:menuTitle
                                                options:0
                                                  range:NSMakeRange(0, [menuTitle length])
                                           withTemplate:@""];
    
    // キーボードショートカット定義があれば、削除して返す
    if (([extnFirstChar length] > 0) &&
        [specSet characterIsMember:[extnFirstChar characterAtIndex:0]]) {
        return [menuTitle stringByDeletingPathExtension];
    }
    
    return menuTitle;
}


//------------------------------------------------------
/// ファイル名からキーボードショートカット定義を読み取る
- (NSString *)keyEquivalentAndModifierMask:(NSUInteger *)modifierMask fromFileName:(NSString *)fileName
//------------------------------------------------------
{
    NSString *keySpec = [[fileName stringByDeletingPathExtension] pathExtension];

    return [[NSApp delegate] keyEquivalentAndModifierMask:modifierMask fromString:keySpec includingCommandKey:YES];
}


//------------------------------------------------------
/// エラーアラートを表示
- (void)showAlertWithMessage:(NSString *)message
//------------------------------------------------------
{
    NSAlert *alert = [NSAlert alertWithMessageText:NSLocalizedString(@"Script Error", nil)
                                     defaultButton:nil
                                   alternateButton:nil
                                       otherButton:nil
                         informativeTextWithFormat:message, nil];
    [alert setAlertStyle:NSCriticalAlertStyle];
    [alert runModal];
}


//------------------------------------------------------
/// スクリプトの文字列を得る
- (NSString *)stringOfScript:(NSURL *)URL
//------------------------------------------------------
{
    NSString *scriptString = nil;
    NSData *data = [NSData dataWithContentsOfURL:URL];
    
    if ((data == nil) || ([data length] < 1)) { return nil; }
    
    NSArray *encodings = [[NSUserDefaults standardUserDefaults] arrayForKey:k_key_encodingList];
    NSStringEncoding encoding;
    NSInteger i = 0;
    while (scriptString == nil) {
        encoding = CFStringConvertEncodingToNSStringEncoding([encodings[i] unsignedLongValue]);
        if (encoding == NSProprietaryStringEncoding) {
            NSLog(@"encoding == NSProprietaryStringEncoding");
            break;
        }
        scriptString = [[NSString alloc] initWithData:data encoding:encoding];
        if (scriptString != nil) { break; }
        i++;
    }
    
    return scriptString;
}


//------------------------------------------------------
/// シェルスクリプト実行
- (void)doLaunchShellScript:(NSURL *)URL
//------------------------------------------------------
{
    NSString *script = [self stringOfScript:URL];

    // スクリプトファイル内容を得られない場合は警告して抜ける
    if (!script || ([script length] < 1)) {
        [self showAlertWithMessage:[NSString stringWithFormat:NSLocalizedString(@"Could NOT read the script “%@”.", nil), URL]];
        return;
    }

    CEDocument *document = nil;
    NSScanner *scanner = [NSScanner scannerWithString:script];
    NSString *inputType = nil;
    NSString *outputType = nil;
    NSString *inputString = nil;
    NSData *inputData = nil;
    NSTask *task = [[NSTask alloc] init];
    NSPipe *outPipe = [NSPipe pipe];
    NSPipe *errorPipe = [NSPipe pipe];
    BOOL docExists = NO;
    BOOL hasError = NO;

    if ([[NSApp orderedDocuments] count] > 0) {
        docExists = YES;
        document = [NSApp orderedDocuments][0];
    }
    [self setOutputHandle:[outPipe fileHandleForReading]];
    [self setErrorHandle:[errorPipe fileHandleForReading]];
    [scanner setCaseSensitive:YES];
    while (![scanner isAtEnd]) {
        (void)[scanner scanUpToString:@"%%%{CotEditorXInput=" intoString:nil];
        if ([scanner scanString:@"%%%{CotEditorXInput=" intoString:nil]) {
            if ([scanner scanUpToString:@"}%%%" intoString:&inputType]) {
                break;
            }
        }
    }
    if ((inputType != nil) && ([inputType isEqualToString:@"Selection"])) {
        if (docExists) {
            NSRange selectedRange = [[[document editorView] textView] selectedRange];
            inputString = [[[document editorView] string] substringWithRange:selectedRange];
            // ([[theDoc editorView] string] は行末コードLFの文字列を返すが、[[theDoc editorView] selectedRange] は
            // 行末コードを反映させた範囲を返すので、「CR/LF」では使えない。そのため、
            // [[[theDoc editorView] textView] selectedRange] を使う必要がある。2009-04-12

        } else {
            hasError = YES;
        }
    } else if (inputType && ([inputType isEqualToString:@"AllText"])) {
        if (docExists) {
            inputString = [[document editorView] string];
        } else {
            hasError = YES;
        }
    } else { // == "None"
    }
    if (hasError) {
        [self showScriptErrorLog:[NSString stringWithFormat:@"[ %@ ]\n%@",
                                  [[NSDate date] description], @"NO document, no Input."]];
        return;
    }
    if (inputString != nil) {
        inputData = [inputString dataUsingEncoding:NSUTF8StringEncoding];
    }
    [scanner setScanLocation:0];
    while (![scanner isAtEnd]) {
        [scanner scanUpToString:@"%%%{CotEditorXOutput=" intoString:nil];
        if ([scanner scanString:@"%%%{CotEditorXOutput=" intoString:nil]) {
            if ([scanner scanUpToString:@"}%%%" intoString:&outputType]) {
                break;
            }
        }
    }
    if (outputType == nil) {
        [self setOutputType:CENoOutputType];
    } else if ([outputType isEqualToString:@"ReplaceSelection"]) {
        [self setOutputType:CEReplaceSelectionType];
    } else if ([outputType isEqualToString:@"ReplaceAllText"]) {
        [self setOutputType:CEReplaceAllTextType];
    } else if ([outputType isEqualToString:@"InsertAfterSelection"]) {
        [self setOutputType:CEInsertAfterSelectionType];
    } else if ([outputType isEqualToString:@"AppendToAllText"]) {
        [self setOutputType:CEAppendToAllTextType];
    } else if ([outputType isEqualToString:@"Pasteboard"]) {
        [self setOutputType:CEPasteboardType];
    } else if ([outputType isEqualToString:@"Pasteboard puts"]) { // 以前の定義文字列。互換性のため。(2007.05.26)
        [self setOutputType:CEPasteboardType];
    } else { // == "Discard"
        [self setOutputType:CENoOutputType];
    }

    // タスク実行準備
    // （task に引数をセットすると一部のスクリプトが誤動作する。例えば、Perl 5.8.xで「use encoding 'utf8'」のうえ
    // printコマンドを使用すると文字化けすることがある。2009-03-31）
    [task setLaunchPath:[URL path]];
    [task setCurrentDirectoryPath:NSHomeDirectory()];
    [task setStandardInput:[NSPipe pipe]];
    [task setStandardOutput:outPipe];
    [task setStandardError:errorPipe];
    // 出力をバックグラウンドで行うように指示
    [[[task standardOutput] fileHandleForReading] readToEndOfFileInBackgroundAndNotify];
    [[[task standardError] fileHandleForReading] readToEndOfFileInBackgroundAndNotify];

    [task launch];
    if (inputData && ([inputData length] > 0)) {
        [[[task standardInput] fileHandleForWriting] writeData:inputData];
        [[[task standardInput] fileHandleForWriting] closeFile];
    }
}


// ------------------------------------------------------
/// 標準出力を取得
- (void)availableOutput:(NSNotification *)aNotification
// ------------------------------------------------------
{
    NSData *outputData = [aNotification userInfo][NSFileHandleNotificationDataItem];
    CEDocument *document = nil;
    NSString *outputString = nil;
    NSPasteboard *pasteboard;

    if ([[NSApp orderedDocuments] count] > 0) {
        document = [NSApp orderedDocuments][0];
    }

    if (outputData == nil) { return; }
    if ([[aNotification object] isEqualTo:[self outputHandle]]) {
        outputString = [[NSString alloc] initWithData:outputData encoding:NSUTF8StringEncoding];
        if (outputString != nil) {
            switch ([self outputType]) {
                case CENoOutputType:
                    // do nothing
                    break;
                case CEReplaceSelectionType:
                    [[document editorView] replaceTextViewSelectedStringTo:outputString scroll:NO];
                    break;
                case CEReplaceAllTextType:
                    [[document editorView] replaceTextViewAllStringTo:outputString];
                    break;
                case CEInsertAfterSelectionType:
                    [[document editorView] insertTextViewAfterSelectionStringTo:outputString];
                    break;
                case CEAppendToAllTextType:
                    [[document editorView] appendTextViewAfterAllStringTo:outputString];
                    break;
                case CEPasteboardType:
                    pasteboard = [NSPasteboard generalPasteboard];
                    [pasteboard declareTypes:@[NSStringPboardType] owner:nil];
                    if (![pasteboard setString:outputString forType:NSStringPboardType]) {
                        NSBeep();
                    }
                    break;
            }
        }
        [self setOutputType:CENoOutputType];
        [self setOutputHandle:nil];
    } else if ([[aNotification object] isEqualTo:[self errorHandle]]) {
        outputString = [[NSString alloc] initWithData:outputData encoding:NSUTF8StringEncoding];
        if ((outputString != nil) && ([outputString length] > 0)) {
            [self showScriptErrorLog:[NSString stringWithFormat:@"[ %@ ]\n%@", [[NSDate date] description], outputString]];
        }
        [self setErrorHandle:nil];
    }
}


// ------------------------------------------------------
/// スクリプトエラーを追記し、エラーログウィンドウを表示
- (void)showScriptErrorLog:(NSString *)errorLog
// ------------------------------------------------------
{
    CEScriptErrorPanelController *sheetController = [CEScriptErrorPanelController sharedController];
    [sheetController showWindow:self];
    [sheetController addErrorString:errorLog];
}

@end
