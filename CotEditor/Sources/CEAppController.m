/*
=================================================
CEAppController
(for CotEditor)

 Copyright (C) 2004-2007 nakamuxu.
 Copyright (C) 2011, 2014 CotEditor Project
 http://coteditor.github.io
=================================================

encoding="UTF-8"
Created:2004.12.13
 
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

#import "CEAppController.h"
#import "CEHexColorTransformer.h"
#import "CEOpacityPanelController.h"
#import "CELineSpacingPanelController.h"
#import "CEGoToPanelController.h"
#import "CEColorCodePanelController.h"
#import "constants.h"


@interface CEAppController ()

@property (nonatomic, retain) NSArray *invalidYenEncodings;
@property (nonatomic) BOOL didFinishLaunching;

// readonly
@property (nonatomic, retain, readwrite) CEPreferences *preferencesController;

@end


//------------------------------------------------------------------------------------------




@implementation CEAppController

#pragma mark Class Methods

//=======================================================
// Class method
//
//=======================================================

// ------------------------------------------------------
+ (void)initialize
// set binding keys and values
// ------------------------------------------------------
{
    // Encoding list
    NSUInteger numberOfEncodings = sizeof(k_CFStringEncodingList)/sizeof(CFStringEncodings);
    NSMutableArray *encodings = [[NSMutableArray alloc] initWithCapacity:numberOfEncodings];
    for (NSUInteger i = 0; i < numberOfEncodings; i++) {
        [encodings addObject:@(k_CFStringEncodingList[i])];
    }
    
    NSDictionary *defaults = @{k_key_showLineNumbers: @YES,
                k_key_showWrappedLineMark: @YES, 
                k_key_showStatusBar: @YES, 
                k_key_countLineEndingAsChar: @YES, 
                k_key_syncFindPboard: @NO, 
                k_key_inlineContextualScriptMenu: @NO, 
                k_key_appendExtensionAtSaving: @YES, 
                k_key_showStatusBarThousSeparator: @YES, 
                k_key_showNavigationBar: @YES, 
                k_key_wrapLines: @YES, 
                k_key_defaultLineEndCharCode: @0, 
                k_key_encodingList: encodings, 
                k_key_fontName: [[NSFont controlContentFontOfSize:[NSFont systemFontSize]] fontName], 
                k_key_fontSize: @([NSFont systemFontSize]),
                k_key_encodingInOpen: @(k_autoDetectEncodingMenuTag),
                k_key_encodingInNew: @(CFStringConvertEncodingToNSStringEncoding(kCFStringEncodingUTF8)), 
                k_key_referToEncodingTag: @YES, 
                k_key_createNewAtStartup: @YES, 
                k_key_reopenBlankWindow: @YES, 
                k_key_checkSpellingAsType: @NO, 
                k_key_windowWidth: @600.0f, 
                k_key_windowHeight: @450.0f, 
                k_key_autoExpandTab: @NO, 
                k_key_tabWidth: @4U, 
                k_key_windowAlpha: @1.0f,  
                k_key_autoIndent: @YES, 
                k_key_invisibleCharactersColor: [NSArchiver archivedDataWithRootObject:[NSColor grayColor]], 
                k_key_showInvisibleSpace: @NO, 
                k_key_invisibleSpace: @0U, 
                k_key_showInvisibleTab: @NO, 
                k_key_invisibleTab: @0U, 
                k_key_showInvisibleNewLine: @NO, 
                k_key_invisibleNewLine: @0U, 
                k_key_showInvisibleFullwidthSpace: @NO, 
                k_key_invisibleFullwidthSpace: @0U, 
                k_key_showOtherInvisibleChars: @NO, 
                k_key_highlightCurrentLine: @NO, 
                k_key_setHiliteLineColorToIMChars: @YES, 
                k_key_textColor: [NSArchiver archivedDataWithRootObject:[NSColor textColor]], 
                k_key_backgroundColor: [NSArchiver archivedDataWithRootObject:[NSColor textBackgroundColor]], 
                k_key_insertionPointColor: [NSArchiver archivedDataWithRootObject:[NSColor textColor]], 
                k_key_selectionColor: [NSArchiver archivedDataWithRootObject:[NSColor selectedTextBackgroundColor]], 
                k_key_highlightLineColor: [NSArchiver archivedDataWithRootObject:
                        [NSColor colorWithCalibratedRed:0.843 green:0.953 blue:0.722 alpha:1.0]], 
                k_key_keywordsColor: [NSArchiver archivedDataWithRootObject:
                        [NSColor colorWithCalibratedRed:0.047 green:0.102 blue:0.494 alpha:1.0]], 
                k_key_commandsColor: [NSArchiver archivedDataWithRootObject:
                        [NSColor colorWithCalibratedRed:0.408 green:0.220 blue:0.129 alpha:1.0]], 
                k_key_numbersColor: [NSArchiver archivedDataWithRootObject:[NSColor blueColor]], 
                k_key_valuesColor: [NSArchiver archivedDataWithRootObject:
                        [NSColor colorWithCalibratedRed:0.463 green:0.059 blue:0.313 alpha:1.0]], 
                k_key_stringsColor: [NSArchiver archivedDataWithRootObject:
                        [NSColor colorWithCalibratedRed:0.537 green:0.075 blue:0.08 alpha:1.0]], 
                k_key_charactersColor: [NSArchiver archivedDataWithRootObject:[NSColor blueColor]], 
                k_key_commentsColor: [NSArchiver archivedDataWithRootObject:
                        [NSColor colorWithCalibratedRed:0.137 green:0.431 blue:0.145 alpha:1.0]], 
                k_key_doColoring: @YES, 
                k_key_defaultColoringStyleName: NSLocalizedString(@"None",@""), 
                k_key_delayColoring: @NO, 
                k_key_fileDropArray: @[@{k_key_fileDropExtensions: @"jpg, jpeg, gif, png", 
                            k_key_fileDropFormatString: @"<img src=\"<<<RELATIVE-PATH>>>\" alt =\"<<<FILENAME-NOSUFFIX>>>\" title=\"<<<FILENAME-NOSUFFIX>>>\" width=\"<<<IMAGEWIDTH>>>\" height=\"<<<IMAGEHEIGHT>>>\" />"}], 
                k_key_NSDragAndDropTextDelay: @1, 
                k_key_smartInsertAndDelete: @NO, 
                k_key_shouldAntialias: @YES, 
                k_key_completeAddStandardWords: @0U, 
                k_key_showPageGuide: @NO, 
                k_key_pageGuideColumn: @80, 
                k_key_lineSpacing: @0.0f, 
                k_key_swapYenAndBackSlashKey: @NO, 
                k_key_fixLineHeight: @YES, 
                k_key_highlightBraces: @YES, 
                k_key_highlightLtGt: @NO, 
                k_key_saveUTF8BOM: @NO, 
                k_key_setPrintFont: @0, 
                k_key_printFontName: [[NSFont controlContentFontOfSize:[NSFont systemFontSize]] fontName], 
                k_key_printFontSize: @([NSFont systemFontSize]),
                k_printHeader: @YES, 
                k_key_enableSmartQuotes: @NO,
                k_headerOneStringIndex: @3, 
                k_headerTwoStringIndex: @4, 
                k_headerOneAlignIndex: @0, 
                k_headerTwoAlignIndex: @2, 
                k_printHeaderSeparator: @YES, 
                k_printFooter: @YES, 
                k_footerOneStringIndex: @0, 
                k_footerTwoStringIndex: @5, 
                k_footerOneAlignIndex: @0, 
                k_footerTwoAlignIndex: @1, 
                k_printFooterSeparator: @YES, 
                k_printLineNumIndex: @0, 
                k_printInvisibleCharIndex: @0, 
                k_printColorIndex: @0, 

        /* -------- 以下、環境設定にない設定項目 -------- */
                k_key_HCCBackgroundColor: [NSArchiver archivedDataWithRootObject:
                        [NSColor colorWithCalibratedRed:1.0 green:1.0 blue:1.0 alpha:1.0]], 
                k_key_HCCForeColor: [NSArchiver archivedDataWithRootObject:
                        [NSColor colorWithCalibratedRed:0.0 green:0.0 blue:0.0 alpha:1.0]], 
                k_key_HCCSampleText: @"Sample Text", 
                k_key_HCCForeComboBoxData: @[],
                k_key_HCCBackComboBoxData: @[], 
                k_key_foreColorCBoxIsOk: @NO, 
                k_key_backgroundColorCBoxIsOk: @NO, 
                k_key_insertCustomTextArray: [self factoryDefaultOfTextInsertStringArray], 

        /* -------- 以下、隠し設定 -------- */
                k_key_statusBarFontSize: @11.0f, 
                k_key_lineNumFontName: @"ArialNarrow",
                k_key_lineNumFontSize: @10.0f, 
                k_key_lineNumFontColor: [NSArchiver archivedDataWithRootObject:[NSColor darkGrayColor]], 
                k_key_basicColoringDelay: @0.001f, 
                k_key_firstColoringDelay: @0.3f, 
                k_key_secondColoringDelay: @0.7f, 
                k_key_lineNumUpdateInterval: @0.12f, 
                k_key_infoUpdateInterval: @0.2f, 
                k_key_incompatibleCharInterval: @0.42f, 
                k_key_outlineMenuInterval: @0.37f, 
                k_key_navigationBarFontName: @"Helvetica", 
                k_key_navigationBarFontSize: @11.0f, 
                k_key_outlineMenuMaxLength: @110U, 
                k_key_headerFooterFontName: [[NSFont systemFontOfSize:[NSFont systemFontSize]] fontName], 
                k_key_headerFooterFontSize: @10.0f, 
                k_key_headerFooterDateTimeFormat: @"%Y-%m-%d  %H:%M:%S", 
                k_key_headerFooterPathAbbreviatingWithTilde: @YES, 
                k_key_textContainerInsetWidth: @0.0f, 
                k_key_textContainerInsetHeightTop: @4.0f, 
                k_key_textContainerInsetHeightBottom: @16.0f, 
                k_key_showColoringIndicatorTextLength: @115000U, 
                k_key_runAppleScriptInLaunching: @YES, 
                k_key_showAlertForNotWritable: @YES, 
                k_key_notifyEditByAnother: @YES};
    [[NSUserDefaults standardUserDefaults] registerDefaults:defaults];
    [[NSUserDefaultsController sharedUserDefaultsController] setInitialValues:defaults];

    // transformer 登録
    [NSValueTransformer setValueTransformer:[[CEHexColorTransformer alloc] init]
                                    forName:@"HexColorTransformer"];
}


// ------------------------------------------------------
+ (NSArray *)factoryDefaultOfTextInsertStringArray
// 文字列挿入メソッドの標準設定配列を返す
// ------------------------------------------------------
{
// インデックスが0-30の、合計31個
    return @[@"<br />\n", @"", @"", @"", @"", @"", @"", @"", @"", @"", @"", 
             @"", @"", @"", @"", @"", @"", @"", @"", @"", @"",
             @"", @"", @"", @"", @"", @"", @"", @"", @"", @""];
}



#pragma mark Public Methods

//=======================================================
// Public method
//
//=======================================================

// ------------------------------------------------------
- (instancetype)init
// 初期化
// ------------------------------------------------------
{
    self = [super init];
    if (self) {
        NSMutableArray *encodings = [NSMutableArray array];
        NSStringEncoding encoding;
        NSUInteger i;
        for (i = 0; i < sizeof(k_CFStringEncodingInvalidYenList)/sizeof(CFStringEncodings); i++) {
            encoding = CFStringConvertEncodingToNSStringEncoding(k_CFStringEncodingInvalidYenList[i]);
            [encodings addObject:@(encoding)];
        }
        [self setInvalidYenEncodings:encodings];
        [self setDidFinishLaunching:NO];
    }
    return self;
}

// ------------------------------------------------------
- (void)buildAllEncodingMenus
// すべてのエンコーディングメニューを生成
// ------------------------------------------------------
{
    id values = [[NSUserDefaultsController sharedUserDefaultsController] values];
    NSArray *encodings = [[values valueForKey:k_key_encodingList] copy];

    [[self preferencesController] setupEncodingMenus:[self encodingMenuNoActionFromArray:encodings]];
    [self setEncodingMenu:[self buildFormatEncodingMenuFromArray:encodings]];
    [[CEDocumentController sharedDocumentController] rebuildAllToolbarsEncodingItem];
}


// ------------------------------------------------------
- (void)buildAllSyntaxMenus
// すべてのシンタックスカラーリングメニューを生成
// ------------------------------------------------------
{
    [[self preferencesController] setupSyntaxMenus];
    [self setSyntaxMenu:[self buildSyntaxMenu]];
    [[CEDocumentController sharedDocumentController] rebuildAllToolbarsSyntaxItem];
}


// ------------------------------------------------------
- (NSString *)invisibleSpaceCharacter:(NSUInteger)index
// 非表示半角スペース表示用文字を返すユーティリティメソッド
// ------------------------------------------------------
{
    NSUInteger max = (sizeof(k_invisibleSpaceCharList) / sizeof(unichar)) - 1;
    NSUInteger sanitizedIndex = MIN(max, index);
    unichar theUnichar = k_invisibleSpaceCharList[sanitizedIndex];

    return [NSString stringWithCharacters:&theUnichar length:1];
}


// ------------------------------------------------------
- (NSString *)invisibleTabCharacter:(NSUInteger)index
// 非表示タブ表示用文字を返すユーティリティメソッド
// ------------------------------------------------------
{
    NSUInteger max = (sizeof(k_invisibleTabCharList) / sizeof(unichar)) - 1;
    NSUInteger sanitizedIndex = MIN(max, index);
    unichar theUnichar = k_invisibleTabCharList[sanitizedIndex];

    return [NSString stringWithCharacters:&theUnichar length:1];
}


// ------------------------------------------------------
- (NSString *)invisibleNewLineCharacter:(NSUInteger)index
// 非表示改行表示用文字を返すユーティリティメソッド
// ------------------------------------------------------
{
    NSUInteger max = (sizeof(k_invisibleNewLineCharList) / sizeof(unichar)) - 1;
    NSUInteger sanitizedIndex = MIN(max, index);
    unichar theUnichar = k_invisibleNewLineCharList[sanitizedIndex];

    return [NSString stringWithCharacters:&theUnichar length:1];
}


// ------------------------------------------------------
- (NSString *)invisibleFullwidthSpaceCharacter:(NSUInteger)index
// 非表示全角スペース表示用文字を返すユーティリティメソッド
// ------------------------------------------------------
{
    NSUInteger max = (sizeof(k_invisibleFullwidthSpaceCharList) / sizeof(unichar)) - 1;
    NSUInteger sanitizedIndex = MIN(max, index);
    unichar theUnichar = k_invisibleFullwidthSpaceCharList[sanitizedIndex];

    return [NSString stringWithCharacters:&theUnichar length:1];
}


// ------------------------------------------------------
- (NSStringEncoding)encodingFromName:(NSString *)encodingName
// エンコーディング名からNSStringEncodingを返すユーティリティメソッド
// ------------------------------------------------------
{
    id values = [[NSUserDefaultsController sharedUserDefaultsController] values];
    NSArray *encodings = [[values valueForKey:k_key_encodingList] copy];
    NSStringEncoding encoding;
    BOOL isValid = NO;

    for (NSNumber __strong *encodingNumber in encodings) {
        CFStringEncoding cfEncoding = [encodingNumber unsignedLongValue];
        if (cfEncoding != kCFStringEncodingInvalidId) { // = separator
            encoding = CFStringConvertEncodingToNSStringEncoding(cfEncoding);
            if ([encodingName isEqualToString:[NSString localizedNameOfStringEncoding:encoding]]) {
                isValid = YES;
                break;
            }
        }
    }
    return (isValid) ? encoding : NSNotFound;
}


// ------------------------------------------------------
- (BOOL)isInvalidYenEncoding:(NSStringEncoding)encoding
// エンコーディング名からNSStringEncodingを返すユーティリティメソッド
// ------------------------------------------------------
{
    return ([[self invalidYenEncodings] containsObject:@(encoding)]);
}


// ------------------------------------------------------
- (NSString *)keyEquivalentAndModifierMask:(NSUInteger *)modifierMask
        fromString:(NSString *)string includingCommandKey:(BOOL)isIncludingCommandKey
// 文字列からキーボードショートカット定義を読み取るユーティリティメソッド
//------------------------------------------------------
{
    *modifierMask = 0;
    NSUInteger length = [string length];
    if ((string == nil) || (length < 2)) { return @""; }

    NSString *key = [string substringFromIndex:(length - 1)];
    NSCharacterSet *charSet = [NSCharacterSet characterSetWithCharactersInString:[string substringToIndex:(length - 1)]];

    if (isIncludingCommandKey) { // === Cmd 必須のとき
        if ([charSet characterIsMember:k_keySpecCharList[3]]) { // @
            if ([charSet characterIsMember:k_keySpecCharList[0]]) { // ^
                *modifierMask |= NSControlKeyMask;
            }
            if ([charSet characterIsMember:k_keySpecCharList[1]]) { // ~
                *modifierMask |= NSAlternateKeyMask;
            }
            if (([charSet characterIsMember:k_keySpecCharList[2]]) ||
                    (isupper([key characterAtIndex:0]) == 1)) { // $
                *modifierMask |= NSShiftKeyMask;
            }
            *modifierMask |= NSCommandKeyMask;
        }
    } else {
        if ([charSet characterIsMember:k_keySpecCharList[0]]) {
            *modifierMask |= NSControlKeyMask;
        }
        if ([charSet characterIsMember:k_keySpecCharList[1]]) {
            *modifierMask |= NSAlternateKeyMask;
        }
        if ([charSet characterIsMember:k_keySpecCharList[2]]) {
            *modifierMask |= NSShiftKeyMask;
        }
        if ([charSet characterIsMember:k_keySpecCharList[3]]) {
            *modifierMask |= NSCommandKeyMask;
        }
    }

    return (modifierMask != 0) ? key : @"";
}



#pragma mark Protocol

//=======================================================
// NSNibAwaking Protocol
//
//=======================================================

// ------------------------------------------------------
- (void)awakeFromNib
// Nibファイル読み込み直後
// ------------------------------------------------------
{
    [self setupSupportDirectory];
    [self setPreferencesController:[[CEPreferences alloc] initWithAppController:self]];
    [self buildAllEncodingMenus];
    [self setSyntaxMenu:[self buildSyntaxMenu]];
    [[CEScriptManager sharedInstance] buildScriptMenu:nil];
    [self cacheTheInvisibleGlyph];
}



#pragma mark Delegate and Notification

//=======================================================
// Delegate method (NSApplication)
//  <== File's Owner
//=======================================================

// ------------------------------------------------------
- (BOOL)applicationShouldOpenUntitledFile:(NSApplication *)sender
// アプリ起動時に新規ドキュメント作成
// ------------------------------------------------------
{
    id values = [[NSUserDefaultsController sharedUserDefaultsController] values];

    if (![self didFinishLaunching]) {
        return ([[values valueForKey:k_key_createNewAtStartup] boolValue]);
    }
    return YES;
}


// ------------------------------------------------------
- (BOOL)applicationShouldHandleReopen:(NSApplication *)theApplication hasVisibleWindows:(BOOL)flag
// Re-Open AppleEvents へ対応してウィンドウを開くかどうかを返す
// ------------------------------------------------------
{
    id values = [[NSUserDefaultsController sharedUserDefaultsController] values];
    BOOL shouldReopen = [[values valueForKey:k_key_reopenBlankWindow] boolValue];

    if (shouldReopen) {
        return YES;
    } else if (flag) {
        // Re-Open に応えない設定でウィンドウがあるときは、すべてのウィンドウをチェックしひとつでも通常通り表示されていれば
        // NO を返し何もしない。表示されているウィンドウがすべて Dock にしまわれているときは、そのうちひとつを通常表示させる
        // ため、YES を返す。
        for (NSWindow *window in [NSApp windows]) {
            if ([window isVisible] && ![window isMiniaturized]) {
                return NO;
            }
        }
        
        return YES;
    }
    // Re-Open に応えず、かつウィンドウもないときは何もしない
    return NO;
}


// ------------------------------------------------------
- (void)applicationDidFinishLaunching:(NSNotification *)notification
// アプリ起動直後
// ------------------------------------------------------
{
    id values = [[NSUserDefaultsController sharedUserDefaultsController] values];

    // （CEKeyBindingManagerによって、キーボードショートカット設定は上書きされる。
    // アプリに内包する DefaultMenuKeyBindings.plist に、ショートカット設定を記述する必要がある。2007.05.19）

    // 「Select Outline item」「Goto」メニューを生成／追加
    NSMenu *findMenu = [[[NSApp mainMenu] itemAtIndex:k_findMenuIndex] submenu];
    NSMenuItem *menuItem;

    [findMenu addItem:[NSMenuItem separatorItem]];
    unichar upKey = NSUpArrowFunctionKey;
    menuItem = [[NSMenuItem alloc] initWithTitle:NSLocalizedString(@"Select Prev Outline Item",@"")
                                          action:@selector(selectPrevItemOfOutlineMenu:)
                                   keyEquivalent:[NSString stringWithCharacters:&upKey length:1]];
    [menuItem setKeyEquivalentModifierMask:(NSCommandKeyMask | NSAlternateKeyMask)];
    [findMenu addItem:menuItem];

    unichar theDownKey = NSDownArrowFunctionKey;
    menuItem = [[NSMenuItem alloc] initWithTitle:NSLocalizedString(@"Select Next Outline Item",@"")
                                          action:@selector(selectNextItemOfOutlineMenu:)
                                   keyEquivalent:[NSString stringWithCharacters:&theDownKey length:1]];
    [menuItem setKeyEquivalentModifierMask:(NSCommandKeyMask | NSAlternateKeyMask)];
    [findMenu addItem:menuItem];

    [findMenu addItem:[NSMenuItem separatorItem]];
    menuItem = [[NSMenuItem alloc] initWithTitle:NSLocalizedString(@"Go To...",@"")
                                          action:@selector(openGoToPanel:)
                                   keyEquivalent:@"l"];
    [findMenu addItem:menuItem];

    // AppleScript 起動のスピードアップのため一度動かしておく
    if ([[values valueForKey:k_key_runAppleScriptInLaunching] boolValue]) {

        NSURL *URL = [[NSBundle mainBundle] URLForResource:@"startup" withExtension:@"applescript"];
        if (URL == nil) { return; }
        NSAppleScript *AppleScript = [[NSAppleScript alloc] initWithContentsOfURL:URL error:nil];

        if (AppleScript) {
            (void)[AppleScript executeAndReturnError:nil];
        }
    }
    // KeyBindingManagerをセットアップ
    [[CEKeyBindingManager sharedInstance] setupAtLaunching];
    // ファイルを開くデフォルトエンコーディングをセット
    [[CEDocumentController sharedDocumentController] setSelectAccessoryEncodingMenuToDefault:self];

    // 廃止した UserDeafults の値を取り除く
    [self cleanDeprecatedDefaults];
    
    // 起動完了フラグをセット
    [self setDidFinishLaunching:YES];
}


// ------------------------------------------------------
- (void)applicationDidBecomeActive:(NSNotification *)notification
// アプリがアクティブになった
// ------------------------------------------------------
{
    // 各ドキュメントに外部プロセスによって変更保存されていた場合の通知を行わせる
    [[[CEDocumentController sharedDocumentController] documents] 
            makeObjectsPerformSelector:@selector(showUpdatedByExternalProcessAlert)];
}


// ------------------------------------------------------
- (void)applicationWillTerminate:(NSNotification *)notification
// アプリ終了の許可を返す
// ------------------------------------------------------
{
    // 環境設定の FileDrop タブ「Insert string format:」テキストビューにフォーカスがあるまま終了すると
    // 内容が保存されない問題への対処
    [[self preferencesController] makeFirstResponderToPrefWindow];
    // 環境設定の FileDrop 配列コントローラの値を書き戻す
    [[self preferencesController] writeBackFileDropArray];
}


// ------------------------------------------------------
- (NSMenu *)applicationDockMenu:(NSApplication *)sender
// Dock メニュー生成
// ------------------------------------------------------
{
    NSMenu *menu = [[NSMenu alloc] init];
    NSMenuItem *newItem = [[[[[NSApp mainMenu] itemAtIndex:k_fileMenuIndex] submenu] itemWithTag:k_newMenuItemTag] copy];
    NSMenuItem *openItem = [[[[[NSApp mainMenu] itemAtIndex:k_fileMenuIndex] submenu] itemWithTag:k_openMenuItemTag] copy];


    [newItem setAction:@selector(newInDockMenu:)];
    [openItem setAction:@selector(openInDockMenu:)];

    [menu addItem:newItem];
    [menu addItem:openItem];

    return menu;
}



// ------------------------------------------------------
- (BOOL)validateMenuItem:(NSMenuItem *)menuItem
// メニューの有効化／無効化を制御
// ------------------------------------------------------
{
    if ([menuItem action] == @selector(openLineSpacingPanel:)) {
        return ([[CEDocumentController sharedDocumentController] currentDocument] != nil);
    }
    
    return YES;
}



#pragma mark Action Messages

//=======================================================
// Action messages
//
//=======================================================

// ------------------------------------------------------
- (IBAction)openPrefWindow:(id)sender
// 環境設定ウィンドウを開く
// ------------------------------------------------------
{
    [[self preferencesController] openPrefWindow];
}

// ------------------------------------------------------
- (IBAction)openAppleScriptDictionary:(id)sender
// アップルスクリプト辞書をスクリプトエディタで開く
// ------------------------------------------------------
{
    NSURL *URL = [[NSBundle mainBundle] URLForResource:@"openDictionary" withExtension:@"applescript"];
    NSDictionary *errorInfo;
    NSAppleScript *AppleScript = [[NSAppleScript alloc] initWithContentsOfURL:URL error:nil];
    (void)[AppleScript executeAndReturnError:&errorInfo];
}


// ------------------------------------------------------
- (IBAction)openScriptErrorWindow:(id)sender
// Scriptエラーウィンドウを表示
// ------------------------------------------------------
{
    [[CEScriptManager sharedInstance] openScriptErrorWindow];
}


// ------------------------------------------------------
- (IBAction)openHexColorCodeEditor:(id)sender
// カラーコードウィンドウを表示
// ------------------------------------------------------
{
    [[CEColorCodePanelController sharedController] showWindow:self];
}


// ------------------------------------------------------
- (IBAction)openOpacityPanel:(id)sender
// 不透明度パネルを開く
// ------------------------------------------------------
{
    [[CEOpacityPanelController sharedController] showWindow:self];
}


// ------------------------------------------------------
- (IBAction)openLineSpacingPanel:(id)sender
// 行間設定パネルを開く
// ------------------------------------------------------
{
    [[CELineSpacingPanelController sharedController] showWindow:self];
}


// ------------------------------------------------------
- (IBAction)openGoToPanel:(id)sender
// Go Toパネルを開く
// ------------------------------------------------------
{
    [[CEGoToPanelController sharedController] showWindow:self];
}


// ------------------------------------------------------
- (IBAction)newInDockMenu:(id)sender
// Dockメニューの「新規」メニューアクション（まず自身をアクティベート）
// ------------------------------------------------------
{
    [NSApp activateIgnoringOtherApps:YES];
    [[NSDocumentController sharedDocumentController] newDocument:nil];
}


// ------------------------------------------------------
- (IBAction)openInDockMenu:(id)sender
// Dockメニューの「開く」メニューアクション（まず自身をアクティベート）
// ------------------------------------------------------
{
    [NSApp activateIgnoringOtherApps:YES];
    [[NSDocumentController sharedDocumentController] openDocument:nil];
}


// ------------------------------------------------------
- (IBAction)openBundledDocument:(id)sender
// 付属ドキュメントを開く
// ------------------------------------------------------
{
    NSString *fileName = k_bundleDocumentDict[@([sender tag])];
    NSURL *URL = [[NSBundle mainBundle] URLForResource:fileName withExtension:@"rtf"];
    
    [[NSWorkspace sharedWorkspace] openURL:URL];
}


// ------------------------------------------------------
- (IBAction)openWebSite:(id)sender
// Webサイト（coteditor.github.io）を開く
// ------------------------------------------------------
{
    [[NSWorkspace sharedWorkspace] openURL:[NSURL URLWithString:k_webSiteURL]];
}



#pragma mark Private Methods

//=======================================================
// Private method
//
//=======================================================

//------------------------------------------------------
- (void)setupSupportDirectory
// データ保存用ディレクトリの存在をチェック、なければつくる
//------------------------------------------------------
{
    NSFileManager *fileManager = [NSFileManager defaultManager];
    NSURL *URL = [[fileManager URLForDirectory:NSApplicationSupportDirectory
                                      inDomain:NSUserDomainMask
                             appropriateForURL:nil
                                        create:YES
                                         error:nil]
                  URLByAppendingPathComponent:@"CotEditor"];
    BOOL isDirectory = NO, success = NO;

    if (![fileManager fileExistsAtPath:[URL path] isDirectory:&isDirectory]) {
        success = [fileManager createDirectoryAtURL:URL
                        withIntermediateDirectories:YES
                                         attributes:nil
                                              error:nil];
        if (!success) {
            NSLog(@"Could not create support directory for CotEditor...");
        }
    } else if (!isDirectory) {
        NSLog(@"\"%@\" is not dir.", URL);
    }
    
}


//------------------------------------------------------
- (NSArray *)encodingMenuNoActionFromArray:(NSArray *)encodings
// エンコーディングメニューアイテムを生成
//------------------------------------------------------
{
    NSMutableArray *menuItems = [NSMutableArray array];
    NSPopUpButton *accessoryEncodingMenuButton = [[CEDocumentController sharedDocumentController] accessoryEncodingMenu];
    NSMenu *accessoryEncodingMenu = [accessoryEncodingMenuButton menu];
    NSMenuItem *item;

    [accessoryEncodingMenuButton removeAllItems];
    item = [[NSMenuItem alloc] initWithTitle:NSLocalizedString(@"Auto-Detect",@"")
                                      action:nil keyEquivalent:@""];
    [item setTag:k_autoDetectEncodingMenuTag];
    [accessoryEncodingMenu addItem:item];
    [accessoryEncodingMenu addItem:[NSMenuItem separatorItem]];

    for (NSNumber *encodingNumber in encodings) {
        CFStringEncoding theCFEncoding = [encodingNumber unsignedLongValue];
        if (theCFEncoding == kCFStringEncodingInvalidId) { // set separator
            [accessoryEncodingMenu addItem:[NSMenuItem separatorItem]];
            [menuItems addObject:[NSMenuItem separatorItem]];
        } else {
            NSStringEncoding theEncoding = CFStringConvertEncodingToNSStringEncoding(theCFEncoding);
            NSString *theMenuTitle = [NSString localizedNameOfStringEncoding:theEncoding];
            NSMenuItem *theAccessoryMenuItem = [[NSMenuItem alloc] initWithTitle:theMenuTitle
                                                                          action:nil keyEquivalent:@""];
            [theAccessoryMenuItem setTarget:nil];
            [theAccessoryMenuItem setTag:theEncoding];
            [accessoryEncodingMenu addItem:theAccessoryMenuItem];
            [menuItems addObject:theAccessoryMenuItem];
        }
    }
    return menuItems;
}


//------------------------------------------------------
- (void)cleanDeprecatedDefaults
// 廃止したuserDefaultsのデータをユーザのplistから削除
//------------------------------------------------------
{
    NSArray *deprecatedKeys = @[@"statusAreaFontName",  // deprecated on 1.4
                                @"alphaOnlyTextView",   // deprecated on 1.5
                                @"saveTypeCreator",     // deprecated on 1.5
                                @"gotoObjectMenuIndex"  // deprecated on 1.5
                                ];
    
    for (NSString *key in deprecatedKeys) {
        [[NSUserDefaults standardUserDefaults] removeObjectForKey:key];
    }
}


//------------------------------------------------------
- (NSMenu *)buildFormatEncodingMenuFromArray:(NSArray *)encodings
// フォーマットのエンコーディングメニューアイテムを生成
//------------------------------------------------------
{
    NSMenu *encodingMenu = [[NSMenu alloc] initWithTitle:@"ENCODEING"];
    NSMenuItem *formatMenuItem = [[[[NSApp mainMenu] itemAtIndex:k_formatMenuIndex] submenu] itemWithTag:k_fileEncodingMenuItemTag];

    for (NSNumber *encodingNumber in encodings) {
        CFStringEncoding cfEncoding = [encodingNumber unsignedLongValue];
        if (cfEncoding == kCFStringEncodingInvalidId) { // set separator
            [encodingMenu addItem:[NSMenuItem separatorItem]];
        } else {
            NSStringEncoding encoding = CFStringConvertEncodingToNSStringEncoding(cfEncoding);
            NSString *menuTitle = [NSString localizedNameOfStringEncoding:encoding];
            NSMenuItem *menuItem = [[NSMenuItem alloc] initWithTitle:menuTitle
                                                              action:@selector(setEncoding:) keyEquivalent:@""];
            [menuItem setTag:encoding];
            [encodingMenu addItem:menuItem];
        }
    }
    [formatMenuItem setSubmenu:encodingMenu];
    return [encodingMenu copy];
}


//------------------------------------------------------
- (NSMenu *)buildSyntaxMenu
// シンタックスカラーリングメニューを生成
//------------------------------------------------------
{
    NSMenu *coloringMenu = [[NSMenu alloc] initWithTitle:@"SYNTAX"];
    NSMenu *menu = nil;
    NSMenuItem *mormatMenuItem = [[[[NSApp mainMenu] itemAtIndex:k_formatMenuIndex] submenu] itemWithTag:k_syntaxMenuItemTag];
    NSMenuItem *menuItem;
    NSString *menuTitle;
    NSArray *styleNames = [[CESyntaxManager sharedInstance] styleNames];
    NSInteger i, count = [styleNames count];
    
    [mormatMenuItem setSubmenu:nil]; // まず開放しておかないと、同じキーボードショートカットキーが設定できない

    for (i = 0; i < (count + 2); i++) { // "None"+Separator分を加える
        if (i == 1) {
            [coloringMenu addItem:[NSMenuItem separatorItem]];
        } else {
            if (i == 0) {
                menuTitle = NSLocalizedString(@"None",@"");
            } else {
                menuTitle = styleNames[(i - 2)];
            }
            menuItem = [[NSMenuItem alloc] initWithTitle:menuTitle
                                                  action:@selector(setSyntaxStyle:)
                                           keyEquivalent:@""];
            [menuItem setTag:i];
            [coloringMenu addItem:menuItem];
        }
    }
    menu = [coloringMenu copy];

    [coloringMenu addItem:[NSMenuItem separatorItem]];
    // 全文字列を再カラーリングするメニューを追加
    menuTitle = NSLocalizedString(@"Re-color All",@"");
    menuItem = [[NSMenuItem alloc] initWithTitle:menuTitle
                                          action:@selector(recoloringAllStringOfDocument:)
                                   keyEquivalent:@"r"];
    [menuItem setKeyEquivalentModifierMask:(NSCommandKeyMask | NSAlternateKeyMask)]; // = Cmd + Opt + R
    [coloringMenu addItem:menuItem];
    [mormatMenuItem setSubmenu:coloringMenu];

    return menu;
}


//------------------------------------------------------
- (void)cacheTheInvisibleGlyph
// 不可視文字列表示時のタイムラグを短縮するため、キャッシュしておく
//------------------------------------------------------
{
    NSMutableString *chars = [NSMutableString string];
    NSUInteger i;

    for (i = 0; i < (sizeof(k_invisibleSpaceCharList) / sizeof(unichar)); i++) {
        [chars appendString:[NSString stringWithCharacters:&k_invisibleSpaceCharList[i] length:1]];
    }
    for (i = 0; i < (sizeof(k_invisibleTabCharList) / sizeof(unichar)); i++) {
        [chars appendString:[NSString stringWithCharacters:&k_invisibleTabCharList[i] length:1]];
    }
    for (i = 0; i < (sizeof(k_invisibleNewLineCharList) / sizeof(unichar)); i++) {
        [chars appendString:[NSString stringWithCharacters:&k_invisibleNewLineCharList[i] length:1]];
    }
    for (i = 0; i < (sizeof(k_invisibleFullwidthSpaceCharList) / sizeof(unichar)); i++) {
        [chars appendString:[NSString stringWithCharacters:&k_invisibleFullwidthSpaceCharList[i] length:1]];
    }
    if ([chars length] < 1) { return; }

    NSTextStorage *storage = [[NSTextStorage alloc] initWithString:chars];
    CELayoutManager *layoutManager = [[CELayoutManager alloc] init];
    NSTextContainer *container = [[NSTextContainer alloc] init];

    [layoutManager addTextContainer:container];
    [storage addLayoutManager:layoutManager];
    (void)[layoutManager glyphRangeForTextContainer:container];
}

@end
