/*
 ==============================================================================
 CEScriptManager
 
 CotEditor
 http://coteditor.com
 
 Created on 2005-03-12 by nakamuxu
 encoding="UTF-8"
 ------------------------------------------------------------------------------
 
 © 2004-2007 nakamuxu
 © 2014 CotEditor Project
 
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

#import "CEScriptManager.h"
#import "CEScriptErrorPanelController.h"
#import "CEDocument.h"
#import "CEAppDelegate.h"
#import "CEUtils.h"
#import "constants.h"


typedef NS_ENUM(NSUInteger, CEScriptOutputType) {
    CENoOutputType,
    CEReplaceSelectionType,
    CEReplaceAllTextType,
    CEInsertAfterSelectionType,
    CEAppendToAllTextType,
    CEPasteboardType
};

typedef NS_ENUM(NSUInteger, CEScriptInputType) {
    CENoInputType,
    CEInputSelectionType,
    CEInputAllTextType
};




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
        [self copySampleScriptToUserDomain:self];
    }
    return self;
}



#pragma mark Public Methods

//=======================================================
// Public method
//
//=======================================================

//------------------------------------------------------
/// Scriptメニューを生成
- (void)buildScriptMenu:(id)sender
//------------------------------------------------------
{
    // メニューデータの読み込みとメニュー構成
    NSMenu *menu = [[[NSApp mainMenu] itemAtIndex:CEScriptMenuIndex] submenu];
    [menu removeAllItems];
    NSMenuItem *menuItem;

    [self addChildFileItemTo:menu fromDir:[[self class] scriptDirectoryURL]];
    
    if ([menu numberOfItems] > 0) {
        menuItem = [NSMenuItem separatorItem];
        [menuItem setTag:CEDefaultScriptMenuItemTag];
        [menu addItem:menuItem];
    }
    
    menuItem = [[NSMenuItem alloc] initWithTitle:NSLocalizedString(@"Open Scripts Folder", nil)
                                          action:@selector(openScriptFolder:)
                                   keyEquivalent:@"a"];
    [menuItem setTarget:self];
    [menuItem setTag:CEDefaultScriptMenuItemTag];
    [menu addItem:menuItem];
    
    menuItem = [[NSMenuItem alloc] initWithTitle:NSLocalizedString(@"Copy Sample to Scripts Folder", nil)
                                          action:@selector(copySampleScriptToUserDomain:)
                                   keyEquivalent:@""];
    [menuItem setTarget:self];
    [menuItem setAlternate:YES];
    [menuItem setKeyEquivalentModifierMask:NSAlternateKeyMask];
    [menuItem setToolTip:NSLocalizedString(@"Copy bundled sample scripts to the scripts folder.", nil)];
    [menuItem setTag:CEDefaultScriptMenuItemTag];
    [menu addItem:menuItem];
    
    menuItem = [[NSMenuItem alloc] initWithTitle:NSLocalizedString(@"Update Script Menu", nil)
                                          action:@selector(buildScriptMenu:)
                                   keyEquivalent:@""];
    [menuItem setTarget:self];
    [menuItem setTag:CEDefaultScriptMenuItemTag];
    [menu addItem:menuItem];
}


//------------------------------------------------------
/// コンテキストメニュー用のメニューを返す
- (NSMenu *)contexualMenu
//------------------------------------------------------
{
    NSMenu *menu = [[[[NSApp mainMenu] itemAtIndex:CEScriptMenuIndex] submenu] copy];
    
    for (NSMenuItem *item in [menu itemArray]) {
        if ([item tag] == CEDefaultScriptMenuItemTag) {
            [menu removeItem:item];
        }
    }
    
    return ([menu numberOfItems] > 0) ? menu : nil;
}



#pragma mark Action Messages

//=======================================================
// Action messages
//
//=======================================================

//------------------------------------------------------
/// Script 実行
- (IBAction)launchScript:(id)sender
//------------------------------------------------------
{
    NSURL *URL = [sender representedObject];
    
    if (!URL) { return; }

    // ファイルがない場合は警告して抜ける
    if (![URL checkResourceIsReachableAndReturnError:nil]) {
        [self showAlertWithMessage:[NSString stringWithFormat:NSLocalizedString(@"The script “%@” does not exist.\n\nCheck it and do “Update Script Menu”.", @""), URL]];
        return;
    }
    
    NSString *extension = [URL pathExtension];

    // 修飾キーが押されている場合は挙動を変更
    NSUInteger flags = [NSEvent modifierFlags];
    if (flags == NSAlternateKeyMask) {  // Optキーが押されていたら、スクリプトを開く
        BOOL success = YES;
        NSString *identifier = [[self AppleScriptExtensions] containsObject:extension] ? @"com.apple.ScriptEditor2" : [[NSBundle mainBundle] bundleIdentifier];
        success = [[NSWorkspace sharedWorkspace] openURLs:@[URL]
                                  withAppBundleIdentifier:identifier
                                                  options:0
                           additionalEventParamDescriptor:nil
                                        launchIdentifiers:NULL];
        
        // 開けなかったり選択できなければその旨を表示
        if (!success) {
            NSString *message = [NSString stringWithFormat:NSLocalizedString(@"Could not open the script file “%@”.", nil), URL];
            [self showAlertWithMessage:message];
        }
        return;
        
    } else if (flags == (NSAlternateKeyMask | NSShiftKeyMask)) {  // Opt+Shiftキーが押されていたら、Finderで表示
        [[NSWorkspace sharedWorkspace] activateFileViewerSelectingURLs:@[URL]];
        return;
    }

    // AppleScript を実行
    if ([[self AppleScriptExtensions] containsObject:extension]) {
        [self runAppleScript:URL];
        
    // Shell Script を実行
    } else if ([[self scriptExtensions] containsObject:extension]) {
        // 実行権限がない場合は警告して抜ける
        if (![URL checkResourceIsReachableAndReturnError:nil]) {
            [self showAlertWithMessage:[NSString stringWithFormat:NSLocalizedString(@"Cannnot execute the script “%@”.\nShell script requires execute permission.\n\nCheck permission of the script file.", nil), URL]];
            return;
        }
        [self runShellScript:URL];
    }
}


// ------------------------------------------------------
/// ScriptフォルダウィンドウをFinderで表示
- (IBAction)openScriptFolder:(id)sender
// ------------------------------------------------------
{
    [[NSWorkspace sharedWorkspace] activateFileViewerSelectingURLs:@[[CEScriptManager scriptDirectoryURL]]];
}


// ------------------------------------------------------
/// サンプルスクリプトをユーザ領域にコピー
- (IBAction)copySampleScriptToUserDomain:(id)sender
// ------------------------------------------------------
{
    NSURL *sourceURL = [[NSBundle mainBundle] URLForResource:@"SampleScript" withExtension:nil];
    NSURL *destURL = [[[self class] scriptDirectoryURL] URLByAppendingPathComponent:@"SampleScript"];
    
    if (![sourceURL checkResourceIsReachableAndReturnError:nil]) {
        return;
    }
    
    if (![destURL checkResourceIsReachableAndReturnError:nil]) {
        [[NSFileManager defaultManager] createDirectoryAtURL:[destURL URLByDeletingLastPathComponent]
                                 withIntermediateDirectories:NO attributes:nil error:nil];
        BOOL success = [[NSFileManager defaultManager] copyItemAtURL:sourceURL toURL:destURL error:nil];
        
        if (success) {
            [self buildScriptMenu:self];
        } else {
            NSLog(@"Error. Sample script folder could not be copied.");
        }
        
    } else if ([sender isKindOfClass:[NSMenuItem class]]) {
        // ユーザがメニューからコピーを実行し、すでにサンプルフォルダがあった場合は警告を出す
        NSAlert *alert = [[NSAlert alloc] init];
        [alert setMessageText:NSLocalizedString(@"SampleScript folder exists already.", nil)];
        [alert setInformativeText:[NSString stringWithFormat:NSLocalizedString(@"If you want to replace it with the new one, remove the existing folder at “%@” at first.", nil), [destURL relativePath]]];
        [alert runModal];
    }
}



#pragma mark Private Class Methods

//=======================================================
// Private class method
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
/// Scriptファイル保存用ディレクトリを返す
+ (NSURL *)scriptDirectoryURL
//------------------------------------------------------
{
    return [[(CEAppDelegate *)[NSApp delegate] supportDirectoryURL] URLByAppendingPathComponent:@"ScriptMenu"];
}


// ------------------------------------------------------
/// スクリプトから出力タイプを読み取る
+ (CEScriptInputType)scanInputType:(NSString *)string
// ------------------------------------------------------
{
    NSString *scannedString = nil;
    NSScanner *scanner = [NSScanner scannerWithString:string];
    [scanner setCaseSensitive:YES];
    
    while (![scanner isAtEnd]) {
        [scanner scanUpToString:@"%%%{CotEditorXInput=" intoString:nil];
        if ([scanner scanString:@"%%%{CotEditorXInput=" intoString:nil]) {
            if ([scanner scanUpToString:@"}%%%" intoString:&scannedString]) {
                break;
            }
        }
    }
    
    if ([scannedString isEqualToString:@"Selection"]) {
        return CEInputSelectionType;
        
    } else if ([scannedString isEqualToString:@"AllText"]) {
        return CEInputAllTextType;
    }
    
    return CENoInputType;
}


// ------------------------------------------------------
/// スクリプトから出力タイプを読み取る
+ (CEScriptOutputType)scanOutputType:(NSString *)string
// ------------------------------------------------------
{
    NSString *scannedString = nil;
    NSScanner *scanner = [NSScanner scannerWithString:string];
    [scanner setCaseSensitive:YES];
    
    while (![scanner isAtEnd]) {
        [scanner scanUpToString:@"%%%{CotEditorXOutput=" intoString:nil];
        if ([scanner scanString:@"%%%{CotEditorXOutput=" intoString:nil]) {
            if ([scanner scanUpToString:@"}%%%" intoString:&scannedString]) {
                break;
            }
        }
    }
    
    if ([scannedString isEqualToString:@"ReplaceSelection"]) {
        return CEReplaceSelectionType;
        
    } else if ([scannedString isEqualToString:@"ReplaceAllText"]) {
        return CEReplaceAllTextType;
        
    } else if ([scannedString isEqualToString:@"InsertAfterSelection"]) {
        return CEInsertAfterSelectionType;
        
    } else if ([scannedString isEqualToString:@"AppendToAllText"]) {
        return CEAppendToAllTextType;
        
    } else if ([scannedString isEqualToString:@"Pasteboard"]) {
        return CEPasteboardType;
    }
    
    return CENoOutputType;
}


// ------------------------------------------------------
/// 入力タイプに即した現在の書類の内容を返す
+ (NSString *)documentStringWithInputType:(CEScriptInputType)inputType error:(BOOL *)hasError
// ------------------------------------------------------
{
    CEEditorWrapper *editor = [[[NSDocumentController sharedDocumentController] currentDocument] editor];
    
    switch (inputType) {
        case CEInputSelectionType:
            if (editor) {
                NSRange selectedRange = [[editor textView] selectedRange];
                return [[editor string] substringWithRange:selectedRange];
                // ([editor string] は改行コードLFの文字列を返すが、[editor selectedRange] は
                // 改行コードを反映させた範囲を返すので、「CR/LF」では使えない。そのため、
                // [[editor textView] selectedRange] を使う必要がある。2009-04-12
            }
            break;
            
        case CEInputAllTextType:
            if (editor) {
                return [editor string];
            }
            break;
            
        case CENoInputType:
            return nil;
    }
    
    if (hasError) {
        *hasError = YES;
    }
    
    return nil;
}


// ------------------------------------------------------
/// 出力タイプに即したスクリプト結果を現在の書類に反映
+ (void)setOutputToDocument:(NSString *)output outputType:(CEScriptOutputType)outputType
// ------------------------------------------------------
{
    CEEditorWrapper *editor = [[[NSDocumentController sharedDocumentController] currentDocument] editor];
    
    switch (outputType) {
        case CEReplaceSelectionType:
            [editor replaceTextViewSelectedStringTo:output scroll:NO];
            break;
            
        case CEReplaceAllTextType:
            [editor replaceTextViewAllStringTo:output];
            break;
            
        case CEInsertAfterSelectionType:
            [editor insertTextViewAfterSelectionStringTo:output];
            break;
            
        case CEAppendToAllTextType:
            [editor appendTextViewAfterAllStringTo:output];
            break;
            
        case CEPasteboardType: {
            NSPasteboard *pasteboard = [NSPasteboard generalPasteboard];
            [pasteboard declareTypes:@[NSStringPboardType] owner:nil];
            if (![pasteboard setString:output forType:NSStringPboardType]) {
                NSBeep();
            }
            break;
        }
        case CENoOutputType:
            break;  // do nothing
    }
}



#pragma mark Private Methods

//=======================================================
// Private method
//
//=======================================================

//------------------------------------------------------
/// ファイルを読み込みメニューアイテムを生成／追加する
- (void)addChildFileItemTo:(NSMenu *)menu fromDir:(NSURL *)directoryURL
//------------------------------------------------------
{
    NSArray *URLs = [[NSFileManager defaultManager] contentsOfDirectoryAtURL:directoryURL
                                                  includingPropertiesForKeys:@[NSURLFileResourceTypeKey]
                                                                     options:NSDirectoryEnumerationSkipsPackageDescendants | NSDirectoryEnumerationSkipsHiddenFiles
                                                                       error:nil];
    
    for (NSURL *URL in URLs) {
        // "_" から始まるファイル/フォルダは無視
        if ([[URL lastPathComponent] hasPrefix:@"_"]) {  continue; }
        
        NSString *resourceType;
        NSString *extension = [URL pathExtension];
        [URL getResourceValue:&resourceType forKey:NSURLFileResourceTypeKey error:nil];
        
        if ([resourceType isEqualToString:NSURLFileResourceTypeDirectory]) {
            NSString *title = [self menuTitleFromFileName:[URL lastPathComponent]];
            if ([title isEqualToString:@"-"]) { // セパレータ
                [menu addItem:[NSMenuItem separatorItem]];
                continue;
            }
            NSMenu *subMenu = [[NSMenu alloc] initWithTitle:title];
            NSMenuItem *item = [[NSMenuItem alloc] initWithTitle:title action:nil keyEquivalent:@""];
            [item setTag:CEScriptMenuDirectoryTag];
            [menu addItem:item];
            [item setSubmenu:subMenu];
            [self addChildFileItemTo:subMenu fromDir:URL];
            
        } else if ([resourceType isEqualToString:NSURLFileResourceTypeRegular] &&
                   ([[self AppleScriptExtensions] containsObject:extension] || [[self scriptExtensions] containsObject:extension]))
        {
            NSUInteger modifierMask = 0;
            NSString *keyEquivalent = [self keyEquivalentAndModifierMask:&modifierMask fromFileName:[URL lastPathComponent]];
            NSString *title = [self menuTitleFromFileName:[URL lastPathComponent]];
            NSMenuItem *item = [[NSMenuItem alloc] initWithTitle:title
                                                          action:@selector(launchScript:)
                                                   keyEquivalent:keyEquivalent];
            [item setKeyEquivalentModifierMask:modifierMask];
            [item setRepresentedObject:URL];
            [item setTarget:self];
            [item setToolTip:NSLocalizedString(@"“Opt + click” to open in Script Editor.", nil)];
            [menu addItem:item];
        }
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
    if (([extnFirstChar length] > 0) && [specSet characterIsMember:[extnFirstChar characterAtIndex:0]]) {
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

    return [CEUtils keyEquivalentAndModifierMask:modifierMask fromString:keySpec includingCommandKey:YES];
}


//------------------------------------------------------
/// エラーアラートを表示
- (void)showAlertWithMessage:(NSString *)message
//------------------------------------------------------
{
    NSAlert *alert = [[NSAlert alloc] init];
    [alert setMessageText:NSLocalizedString(@"Script Error", nil)];
    [alert setInformativeText:message];
    [alert setAlertStyle:NSCriticalAlertStyle];
    [alert runModal];
}


//------------------------------------------------------
/// スクリプトの文字列を得る
- (NSString *)stringOfScript:(NSURL *)URL
//------------------------------------------------------
{
    NSData *data = [NSData dataWithContentsOfURL:URL];
    
    if ([data length] == 0) { return nil; }
    
    NSArray *encodings = [[NSUserDefaults standardUserDefaults] arrayForKey:CEDefaultEncodingListKey];
    
    for (NSNumber *encodingNumber in encodings) {
        NSStringEncoding encoding = CFStringConvertEncodingToNSStringEncoding([encodingNumber unsignedLongValue]);
        NSString *scriptString = [[NSString alloc] initWithData:data encoding:encoding];
        if (scriptString) {
            return scriptString;
        }
    }
    
    return nil;
}


//------------------------------------------------------
/// AppleScript実行
- (void)runAppleScript:(NSURL *)URL
//------------------------------------------------------
{
    NSDictionary *errorInfo = nil;
    
    NSAppleScript *appleScript = [[NSAppleScript alloc] initWithContentsOfURL:URL error:&errorInfo];
    [appleScript executeAndReturnError:&errorInfo];
    
    // エラーが発生したら、表示
    if (errorInfo) {
        [self showAlertWithMessage:[NSString stringWithFormat:NSLocalizedString(@"%@\nErrorNumber: %@", nil),
                                    errorInfo[NSAppleScriptErrorMessage],
                                    errorInfo[NSAppleScriptErrorNumber]]];
    }
}


//------------------------------------------------------
/// シェルスクリプト実行
- (void)runShellScript:(NSURL *)URL
//------------------------------------------------------
{
    NSString *script = [self stringOfScript:URL];

    // スクリプトファイル内容を得られない場合は警告して抜ける
    if ([script length] == 0) {
        [self showAlertWithMessage:[NSString stringWithFormat:NSLocalizedString(@"Could not read the script “%@”.", nil), URL]];
        return;
    }

    // 入力を読み込む
    CEScriptInputType inputType = [[self class] scanInputType:script];
    BOOL hasError = NO;
    NSString *input = [[self class] documentStringWithInputType:inputType error:&hasError];
    if (hasError) {
        [self showScriptError:@"NO document, no Input."];
        return;
    }
    
    // 出力タイプを得る
    CEScriptOutputType outputType = [[self class] scanOutputType:script];

    // タスク実行準備
    // （task に引数をセットすると一部のスクリプトが誤動作する。例えば、Perl 5.8.xで「use encoding 'utf8'」のうえ
    // printコマンドを使用すると文字化けすることがある。2009-03-31）
    NSTask *task = [[NSTask alloc] init];
    [task setLaunchPath:[URL path]];
    [task setCurrentDirectoryPath:NSHomeDirectory()];
    
    // Standard Error
    __weak typeof(self) weakSelf = self;
    [task setStandardError:[NSPipe pipe]];
    [[[task standardError] fileHandleForReading] setReadabilityHandler:^(NSFileHandle *file) {
        typeof(self) strongSelf = weakSelf;
        NSString *error = [[NSString alloc] initWithData:[file readDataToEndOfFile] encoding:NSUTF8StringEncoding];
        
        if ([error length] > 0) {
            dispatch_async(dispatch_get_main_queue(), ^{
                [strongSelf showScriptError:error];
            });
        }
    }];
    
    // Standard Output
    [task setStandardOutput:[NSPipe pipe]];
    [[[task standardOutput] fileHandleForReading] setReadabilityHandler:^(NSFileHandle *file) {
        NSString *output = [[NSString alloc] initWithData:[file readDataToEndOfFile] encoding:NSUTF8StringEncoding];
        
        if (output) {
            dispatch_async(dispatch_get_main_queue(), ^{
                [CEScriptManager setOutputToDocument:output outputType:outputType];
            });
        }
    }];
    
    // Standard Input
    if ([input length] > 0) {
        [task setStandardInput:[NSPipe pipe]];
        [[[task standardInput] fileHandleForWriting] writeData:[input dataUsingEncoding:NSUTF8StringEncoding]];
        [[[task standardInput] fileHandleForWriting] closeFile];
    }
    
    [task launch];
}


// ------------------------------------------------------
/// スクリプトエラーを追記し、エラーログウィンドウを表示
- (void)showScriptError:(NSString *)newError
// ------------------------------------------------------
{
    [[CEScriptErrorPanelController sharedController] showWindow:nil];
    [[CEScriptErrorPanelController sharedController] addErrorString:[NSString stringWithFormat:@"[%@]\n%@",
                                                                     [[NSDate date] description], newError]];
}

@end
