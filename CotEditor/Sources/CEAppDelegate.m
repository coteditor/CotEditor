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

#import "CEAppDelegate.h"
#import "CEPreferencesWindowController.h"
#import "CEHexColorTransformer.h"
#import "CEByteCountTransformer.h"
#import "CEOpacityPanelController.h"
#import "CELineSpacingPanelController.h"
#import "CEGoToPanelController.h"
#import "CEColorPanelController.h"
#import "CEScriptErrorPanelController.h"
#import "constants.h"


@interface CEAppDelegate ()

// readonly
@property (nonatomic, copy, readwrite) NSArray *encodingMenuItems;

@end




#pragma mark -

@implementation CEAppDelegate

#pragma mark Class Methods

//=======================================================
// Class method
//
//=======================================================

// ------------------------------------------------------
/// set binding keys and values
+ (void)initialize
// ------------------------------------------------------
{
    // Encoding list
    NSMutableArray *encodings = [[NSMutableArray alloc] initWithCapacity:k_size_of_CFStringEncodingList];
    for (NSUInteger i = 0; i < k_size_of_CFStringEncodingList; i++) {
        [encodings addObject:@(k_CFStringEncodingList[i])];
    }
    
    NSDictionary *defaults = @{k_key_showLineNumbers: @YES,
                               k_key_showStatusBar: @YES,
                               k_key_showStatusBarChars: @YES,
                               k_key_showStatusBarLines: @YES,
                               k_key_showStatusBarWords: @NO,
                               k_key_showStatusBarLocation: @YES,
                               k_key_showStatusBarLine: @YES,
                               k_key_showStatusBarColumn: @NO,
                               k_key_showStatusBarEncoding: @NO,
                               k_key_showStatusBarLineEndings: @NO,
                               k_key_showStatusBarFileSize: @YES,
                               k_key_countLineEndingAsChar: @YES,
                               k_key_syncFindPboard: @NO,
                               k_key_inlineContextualScriptMenu: @NO,
                               k_key_appendExtensionAtSaving: @YES,
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
                               k_key_defaultColoringStyleName: NSLocalizedString(@"None", nil),
                               k_key_delayColoring: @NO,
                               k_key_fileDropArray: @[@{k_key_fileDropExtensions: @"jpg, jpeg, gif, png",
                                                        k_key_fileDropFormatString: @"<img src=\"<<<RELATIVE-PATH>>>\" alt =\"<<<FILENAME-NOSUFFIX>>>\" title=\"<<<FILENAME-NOSUFFIX>>>\" width=\"<<<IMAGEWIDTH>>>\" height=\"<<<IMAGEHEIGHT>>>\" />"}],
                               k_key_NSDragAndDropTextDelay: @1,
                               k_key_smartInsertAndDelete: @NO,
                               k_key_enableSmartQuotes: @NO,
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
                               k_key_printHeader: @YES,
                               k_key_headerOneStringIndex: @3,
                               k_key_headerTwoStringIndex: @4,
                               k_key_headerOneAlignIndex: @0,
                               k_key_headerTwoAlignIndex: @2,
                               k_key_printHeaderSeparator: @YES,
                               k_key_printFooter: @YES,
                               k_key_footerOneStringIndex: @0,
                               k_key_footerTwoStringIndex: @5,
                               k_key_footerOneAlignIndex: @0,
                               k_key_footerTwoAlignIndex: @1,
                               k_key_printFooterSeparator: @YES,
                               k_key_printLineNumIndex: @0,
                               k_key_printInvisibleCharIndex: @0,
                               k_key_printColorIndex: @0,
                               
                               /* -------- 以下、環境設定にない設定項目 -------- */
                               k_key_HCCBackgroundColor: [NSArchiver archivedDataWithRootObject:[NSColor whiteColor]],
                               k_key_HCCForeColor: [NSArchiver archivedDataWithRootObject:[NSColor blackColor]],
                               k_key_HCCSampleText: @"Sample Text",
                               k_key_HCCForeComboBoxData: @[],
                               k_key_HCCBackComboBoxData: @[],
                               k_key_foreColorCBoxIsOk: @NO,
                               k_key_backgroundColorCBoxIsOk: @NO,
                               k_key_insertCustomTextArray: @[@"<br />\n", @"", @"", @"", @"", @"", @"", @"", @"", @"", @"",
                                                              @"", @"", @"", @"", @"", @"", @"", @"", @"", @"",
                                                              @"", @"", @"", @"", @"", @"", @"", @"", @"", @""],
                               
                               /* -------- 以下、隠し設定 -------- */
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
                               k_key_notifyEditByAnother: @YES,
                               k_key_smartIndentStartChars: @"{:"};
    [[NSUserDefaults standardUserDefaults] registerDefaults:defaults];
    
    // 出荷時へのリセットが必要な項目に付いては NSUserDefaultsController に初期値をセットする
    NSArray *resettableKeys = @[k_key_encodingList,
                                k_key_insertCustomTextArray,
                                k_key_windowWidth,
                                k_key_windowHeight];
    NSDictionary *initialValuesDict=[defaults dictionaryWithValuesForKeys:resettableKeys];
    [[NSUserDefaultsController sharedUserDefaultsController] setInitialValues:initialValuesDict];

    // transformer 登録
    [NSValueTransformer setValueTransformer:[[CEHexColorTransformer alloc] init]
                                    forName:@"HexColorTransformer"];
    [NSValueTransformer setValueTransformer:[[CEByteCountTransformer alloc] init]
                                    forName:@"CEByteCountTransformer"];
}



#pragma mark Public Methods

//=======================================================
// Public method
//
//=======================================================

// ------------------------------------------------------
/// あとかたづけ
- (void)dealloc
// ------------------------------------------------------
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}


// ------------------------------------------------------
/// すべてのエンコーディングメニューを生成
- (void)buildAllEncodingMenus
// ------------------------------------------------------
{
    [self buildEncodingMenuItems];
    [self buildFormatEncodingMenu];
}



#pragma mark Protocol

//=======================================================
// NSNibAwaking Protocol
//
//=======================================================

// ------------------------------------------------------
/// Nibファイル読み込み直後
- (void)awakeFromNib
// ------------------------------------------------------
{
    [self setupSupportDirectory];
    [self buildAllEncodingMenus];
    [self buildSyntaxMenu];
    [[CEScriptManager sharedManager] buildScriptMenu:nil];
    [self cacheInvisibleGlyphs];
    
    // シンタックススタイルリスト更新の通知依頼
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(buildSyntaxMenu)
                                                 name:CESyntaxListDidUpdateNotification
                                               object:nil];
}



#pragma mark Delegate and Notification

//=======================================================
// Delegate method (NSApplication)
//  <== File's Owner
//=======================================================

// ------------------------------------------------------
/// アプリ起動時に新規ドキュメント作成
- (BOOL)applicationShouldOpenUntitledFile:(NSApplication *)sender
// ------------------------------------------------------
{
    return [[NSUserDefaults standardUserDefaults] boolForKey:k_key_createNewAtStartup];
}


// ------------------------------------------------------
/// Re-Open AppleEvents へ対応してウィンドウを開くかどうかを返す
- (BOOL)applicationShouldHandleReopen:(NSApplication *)theApplication hasVisibleWindows:(BOOL)flag
// ------------------------------------------------------
{
    BOOL shouldReopen = [[NSUserDefaults standardUserDefaults] boolForKey:k_key_reopenBlankWindow];

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
/// アプリ起動直後
- (void)applicationDidFinishLaunching:(NSNotification *)notification
// ------------------------------------------------------
{
    // （CEKeyBindingManagerによって、キーボードショートカット設定は上書きされる。
    // アプリに内包する DefaultMenuKeyBindings.plist に、ショートカット設定を記述する必要がある。2007.05.19）

    // 「Select Outline item」「Goto」メニューを生成／追加
    NSMenu *findMenu = [[[NSApp mainMenu] itemAtIndex:k_findMenuIndex] submenu];
    NSMenuItem *menuItem;

    [findMenu addItem:[NSMenuItem separatorItem]];
    unichar upKey = NSUpArrowFunctionKey;
    menuItem = [[NSMenuItem alloc] initWithTitle:NSLocalizedString(@"Select Prev Outline Item", nil)
                                          action:@selector(selectPrevItemOfOutlineMenu:)
                                   keyEquivalent:[NSString stringWithCharacters:&upKey length:1]];
    [menuItem setKeyEquivalentModifierMask:(NSCommandKeyMask | NSAlternateKeyMask)];
    [findMenu addItem:menuItem];

    unichar downKey = NSDownArrowFunctionKey;
    menuItem = [[NSMenuItem alloc] initWithTitle:NSLocalizedString(@"Select Next Outline Item", nil)
                                          action:@selector(selectNextItemOfOutlineMenu:)
                                   keyEquivalent:[NSString stringWithCharacters:&downKey length:1]];
    [menuItem setKeyEquivalentModifierMask:(NSCommandKeyMask | NSAlternateKeyMask)];
    [findMenu addItem:menuItem];

    [findMenu addItem:[NSMenuItem separatorItem]];
    menuItem = [[NSMenuItem alloc] initWithTitle:NSLocalizedString(@"Go To…", nil)
                                          action:@selector(openGoToPanel:)
                                   keyEquivalent:@"l"];
    [findMenu addItem:menuItem];

    // AppleScript 起動のスピードアップのため一度動かしておく
    if ([[NSUserDefaults standardUserDefaults] boolForKey:k_key_runAppleScriptInLaunching]) {
        NSURL *URL = [[NSBundle mainBundle] URLForResource:@"startup" withExtension:@"applescript"];
        NSAppleScript *AppleScript = [[NSAppleScript alloc] initWithContentsOfURL:URL error:nil];
        [AppleScript executeAndReturnError:nil];
    }
    
    // KeyBindingManagerをセットアップ
    [[CEKeyBindingManager sharedManager] setupAtLaunching];
}


// ------------------------------------------------------
/// アプリがアクティブになった
- (void)applicationDidBecomeActive:(NSNotification *)notification
// ------------------------------------------------------
{
    // 各ドキュメントに外部プロセスによって変更保存されていた場合の通知を行わせる
    [[NSApp orderedDocuments] makeObjectsPerformSelector:@selector(showUpdatedByExternalProcessAlert)];
}


// ------------------------------------------------------
/// Dock メニュー生成
- (NSMenu *)applicationDockMenu:(NSApplication *)sender
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
/// メニューの有効化／無効化を制御
- (BOOL)validateMenuItem:(NSMenuItem *)menuItem
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
/// 環境設定ウィンドウを開く
- (IBAction)openPreferences:(id)sender
// ------------------------------------------------------
{
    [[CEPreferencesWindowController sharedController] showWindow:self];
}


// ------------------------------------------------------
/// アップルスクリプト辞書をスクリプトエディタで開く
- (IBAction)openAppleScriptDictionary:(id)sender
// ------------------------------------------------------
{
    NSURL *URL = [[NSBundle mainBundle] URLForResource:@"openDictionary" withExtension:@"applescript"];
    NSAppleScript *AppleScript = [[NSAppleScript alloc] initWithContentsOfURL:URL error:nil];
    [AppleScript executeAndReturnError:nil];
}


// ------------------------------------------------------
/// Scriptエラーウィンドウを表示
- (IBAction)openScriptErrorWindow:(id)sender
// ------------------------------------------------------
{
    [[CEScriptErrorPanelController sharedController] showWindow:self];
}


// ------------------------------------------------------
/// カラーコードウィンドウを表示
- (IBAction)openHexColorCodeEditor:(id)sender
// ------------------------------------------------------
{
    [[CEColorPanelController sharedController] showWindow:self];
}


// ------------------------------------------------------
/// 不透明度パネルを開く
- (IBAction)openOpacityPanel:(id)sender
// ------------------------------------------------------
{
    [[CEOpacityPanelController sharedController] showWindow:self];
}


// ------------------------------------------------------
/// 行間設定パネルを開く
- (IBAction)openLineSpacingPanel:(id)sender
// ------------------------------------------------------
{
    [[CELineSpacingPanelController sharedController] showWindow:self];
}


// ------------------------------------------------------
/// Go Toパネルを開く
- (IBAction)openGoToPanel:(id)sender
// ------------------------------------------------------
{
    [[CEGoToPanelController sharedController] showWindow:self];
}


// ------------------------------------------------------
/// Dockメニューの「新規」メニューアクション（まず自身をアクティベート）
- (IBAction)newInDockMenu:(id)sender
// ------------------------------------------------------
{
    [NSApp activateIgnoringOtherApps:YES];
    [[NSDocumentController sharedDocumentController] newDocument:nil];
}


// ------------------------------------------------------
/// Dockメニューの「開く」メニューアクション（まず自身をアクティベート）
- (IBAction)openInDockMenu:(id)sender
// ------------------------------------------------------
{
    [NSApp activateIgnoringOtherApps:YES];
    [[NSDocumentController sharedDocumentController] openDocument:nil];
}


// ------------------------------------------------------
/// 付属ドキュメントを開く
- (IBAction)openBundledDocument:(id)sender
// ------------------------------------------------------
{
    NSString *fileName = k_bundleDocumentTags[[sender tag]];
    NSURL *URL = [[NSBundle mainBundle] URLForResource:fileName withExtension:@"rtf"];
    
    [[NSWorkspace sharedWorkspace] openURL:URL];
}


// ------------------------------------------------------
/// Webサイト（coteditor.github.io）を開く
- (IBAction)openWebSite:(id)sender
// ------------------------------------------------------
{
    [[NSWorkspace sharedWorkspace] openURL:[NSURL URLWithString:k_webSiteURL]];
}


// ------------------------------------------------------
/// バグを報告する
- (IBAction)reportBug:(id)sender
// ------------------------------------------------------
{
    [[NSWorkspace sharedWorkspace] openURL:[NSURL URLWithString:k_issueTrackerURL]];
}



#pragma mark Private Methods

//=======================================================
// Private method
//
//=======================================================

//------------------------------------------------------
/// データ保存用ディレクトリの存在をチェック、なければつくる
- (void)setupSupportDirectory
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
            NSLog(@"Failed to create support directory for CotEditor...");
        }
    } else if (!isDirectory) {
        NSLog(@"\"%@\" is not dir.", URL);
    }
}


//------------------------------------------------------
/// エンコーディングメニューアイテムを生成
- (void)buildEncodingMenuItems
//------------------------------------------------------
{
    NSArray *encodings = [[NSUserDefaults standardUserDefaults] arrayForKey:k_key_encodingList];
    NSMutableArray *items = [[NSMutableArray alloc] initWithCapacity:[encodings count]];
    NSMenuItem *item;
    
    for (NSNumber *encodingNumber in encodings) {
        CFStringEncoding cfEncoding = [encodingNumber unsignedLongValue];
        if (cfEncoding == kCFStringEncodingInvalidId) {
            item = [NSMenuItem separatorItem];
        } else {
            NSStringEncoding encoding = CFStringConvertEncodingToNSStringEncoding(cfEncoding);
            NSString *menuTitle = [NSString localizedNameOfStringEncoding:encoding];
            item = [[NSMenuItem alloc] initWithTitle:menuTitle action:NULL keyEquivalent:@""];
            [item setTag:encoding];
        }
        
        [items addObject:item];
    }
    
    [self setEncodingMenuItems:items];
    
    // リストのできあがりを通知
    [[NSNotificationCenter defaultCenter] postNotificationName:CEEncodingListDidUpdateNotification object:self];
}


//------------------------------------------------------
/// フォーマットのエンコーディングメニューアイテムを生成
- (void)buildFormatEncodingMenu
//------------------------------------------------------
{
    NSArray *items = [[NSArray alloc] initWithArray:[self encodingMenuItems] copyItems:YES];
    
    NSMenu *menu = [[[[[NSApp mainMenu] itemAtIndex:k_formatMenuIndex] submenu] itemWithTag:k_fileEncodingMenuItemTag] submenu];
    
    [menu removeAllItems];
    for (NSMenuItem *item in items) {
        [item setAction:@selector(setEncoding:)];
        [item setTarget:nil];
        [menu addItem:item];
    }
}


//------------------------------------------------------
/// シンタックスカラーリングメニューを生成
- (void)buildSyntaxMenu
//------------------------------------------------------
{
    NSMenuItem *syntaxMenuItem = [[[[NSApp mainMenu] itemAtIndex:k_formatMenuIndex] submenu] itemWithTag:k_syntaxMenuItemTag];
    [syntaxMenuItem setSubmenu:[[NSMenu alloc] initWithTitle:@"SYNTAX"]]; // まず開放しておかないと、同じキーボードショートカットキーが設定できない
    NSMenu *menu = [syntaxMenuItem submenu];
    NSMenuItem *item;
    
    // None を追加
    item = [[NSMenuItem alloc] initWithTitle:NSLocalizedString(@"None", nil)
                                      action:@selector(changeSyntaxStyle:)
                               keyEquivalent:@""];
    [menu addItem:item];
    [menu addItem:[NSMenuItem separatorItem]];
    
    // シンタックススタイルをラインナップ
    NSArray *styleNames = [[CESyntaxManager sharedManager] styleNames];
    for (NSString *styleName in styleNames) {
        item = [[NSMenuItem alloc] initWithTitle:styleName
                                          action:@selector(changeSyntaxStyle:)
                                   keyEquivalent:@""];
        [item setTarget:nil];
        [menu addItem:item];
    }
    
    // 全文字列を再カラーリングするメニューを追加
    item = [[NSMenuItem alloc] initWithTitle:NSLocalizedString(@"Re-Color All", nil)
                                      action:@selector(recoloringAllStringOfDocument:)
                               keyEquivalent:@"r"];
    [item setKeyEquivalentModifierMask:(NSCommandKeyMask | NSAlternateKeyMask)]; // = Cmd + Opt + R
    [menu addItem:[NSMenuItem separatorItem]];
    [menu addItem:item];
}


//------------------------------------------------------
/// 不可視文字列表示時のタイムラグを短縮するため、キャッシュしておく
- (void)cacheInvisibleGlyphs
//------------------------------------------------------
{
    NSMutableString *chars = [NSMutableString string];

    for (NSUInteger i = 0; i < k_size_of_invisibleSpaceCharList; i++) {
        [chars appendString:[NSString stringWithCharacters:&k_invisibleSpaceCharList[i] length:1]];
    }
    for (NSUInteger i = 0; i < k_size_of_invisibleTabCharList; i++) {
        [chars appendString:[NSString stringWithCharacters:&k_invisibleTabCharList[i] length:1]];
    }
    for (NSUInteger i = 0; i < k_size_of_invisibleNewLineCharList; i++) {
        [chars appendString:[NSString stringWithCharacters:&k_invisibleNewLineCharList[i] length:1]];
    }
    for (NSUInteger i = 0; i < k_size_of_invisibleFullwidthSpaceCharList; i++) {
        [chars appendString:[NSString stringWithCharacters:&k_invisibleFullwidthSpaceCharList[i] length:1]];
    }
    if ([chars length] < 1) { return; }

    NSTextStorage *storage = [[NSTextStorage alloc] initWithString:chars];
    CELayoutManager *layoutManager = [[CELayoutManager alloc] init];
    NSTextContainer *container = [[NSTextContainer alloc] init];

    [layoutManager addTextContainer:container];
    [storage addLayoutManager:layoutManager];
    [layoutManager glyphRangeForTextContainer:container];
}

@end
