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

//=======================================================
// Private method
//
//=======================================================

@interface CEAppController (Private)
- (NSArray *)encodingMenuNoActionFromArray:(NSArray *)inArray;
- (NSMenu *)buildFormatEncodingMenuFromArray:(NSArray *)inArray;
- (void)setupSupportDirectory;
- (NSMenu *)buildSyntaxMenu;
- (void)cacheTheInvisibleGlyph;
@end


//------------------------------------------------------------------------------------------




@implementation CEAppController

#pragma mark ===== Class method =====

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
    NSMutableArray *theEncodings = [[NSMutableArray alloc] initWithCapacity:numberOfEncodings];
    for (NSUInteger i = 0; i < numberOfEncodings; i++) {
        [theEncodings addObject:@(k_CFStringEncodingList[i])];
    }
    
    NSDictionary *theDefaults = @{k_key_showLineNumbers: @YES,
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
                k_key_encodingList: theEncodings, 
                k_key_fontName: [[NSFont controlContentFontOfSize:[NSFont systemFontSize]] fontName], 
                k_key_fontSize: @([NSFont systemFontSize]),
                k_key_encodingInOpen: @(k_autoDetectEncodingMenuTag),
                k_key_encodingInNew: @(CFStringConvertEncodingToNSStringEncoding(kCFStringEncodingUTF8)), 
                k_key_referToEncodingTag: @YES, 
                k_key_createNewAtStartup: @YES, 
                k_key_reopenBlankWindow: @YES, 
                k_key_checkSpellingAsType: @NO, 
                k_key_saveTypeCreator: @0U, 
                k_key_windowWidth: @600.0f, 
                k_key_windowHeight: @450.0f, 
                k_key_autoExpandTab: @NO, 
                k_key_tabWidth: @4U, 
                k_key_windowAlpha: @1.0f, 
                k_key_alphaOnlyTextView: @YES, 
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
                k_key_gotoObjectMenuIndex: @1, // in Only goto window (not pref).
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
    [[NSUserDefaultsController sharedUserDefaultsController] setInitialValues:theDefaults];

    // transformer 登録
    CEHexColorTransformer *theTransformer = [[[CEHexColorTransformer alloc] init] autorelease];
    [NSValueTransformer setValueTransformer:theTransformer forName:@"HexColorTransformer"];
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
    self = [super init];
    if (self) {
        NSMutableArray *theEncodings = [NSMutableArray array];
        NSStringEncoding theEncoding;
        NSUInteger i;
        for (i = 0; i < sizeof(k_CFStringEncodingInvalidYenList)/sizeof(CFStringEncodings); i++) {
            theEncoding = CFStringConvertEncodingToNSStringEncoding(k_CFStringEncodingInvalidYenList[i]);
            [theEncodings addObject:[NSNumber numberWithUnsignedInt:theEncoding]];
        }
        _invalidYenEncodings = [theEncodings retain];
        _thousandsSeparator = [[[NSUserDefaults standardUserDefaults] valueForKey:NSLocaleGroupingSeparator] retain];
        _didFinishLaunching = NO;
    }
    return self;
}


// ------------------------------------------------------
- (void)dealloc
// 後片づけ
// ------------------------------------------------------
{
    [_preferences release];
    [_encodingMenu release];
    [_syntaxMenu release];
    [_invalidYenEncodings release];
    [_thousandsSeparator release];

    [super dealloc];
}


// ------------------------------------------------------
- (id)preferencesController
// 環境設定コントローラを返す
// ------------------------------------------------------
{
    return _preferences;
}


// ------------------------------------------------------
- (NSMenu *)encodingMenu
// エンコーディングメニューを返す
// ------------------------------------------------------
{
    return _encodingMenu;
}


// ------------------------------------------------------
- (void)setEncodingMenu:(NSMenu *)inEncodingMenu
// エンコーディングメニューを保持
// ------------------------------------------------------
{
    [inEncodingMenu retain];
    [_encodingMenu release];
    _encodingMenu = inEncodingMenu;
}


// ------------------------------------------------------
- (NSMenu *)syntaxMenu
// シンタックスカラーリングメニューを返す
// ------------------------------------------------------
{
    return _syntaxMenu;
}


// ------------------------------------------------------
- (void)setSyntaxMenu:(NSMenu *)inSyntaxMenu
// シンタックスカラーリングメニューを保持
// ------------------------------------------------------
{
    [inSyntaxMenu retain];
    [_syntaxMenu release];
    _syntaxMenu = inSyntaxMenu;
}


// ------------------------------------------------------
- (void)buildAllEncodingMenus
// すべてのエンコーディングメニューを生成
// ------------------------------------------------------
{
    id theValues = [[NSUserDefaultsController sharedUserDefaultsController] values];
    NSArray *theEncodings = [[[theValues valueForKey:k_key_encodingList] copy] autorelease];

    [_preferences setupEncodingMenus:[self encodingMenuNoActionFromArray:theEncodings]];
    [self setEncodingMenu:[self buildFormatEncodingMenuFromArray:theEncodings]];
    [[CEDocumentController sharedDocumentController] rebuildAllToolbarsEncodingItem];
}


// ------------------------------------------------------
- (void)buildAllSyntaxMenus
// すべてのシンタックスカラーリングメニューを生成
// ------------------------------------------------------
{
    [_preferences setupSyntaxMenus];
    [self setSyntaxMenu:[self buildSyntaxMenu]];
    [[CEDocumentController sharedDocumentController] rebuildAllToolbarsSyntaxItem];
}


// ------------------------------------------------------
- (NSString *)invisibleSpaceCharacter:(NSUInteger)inIndex
// 非表示半角スペース表示用文字を返すユーティリティメソッド
// ------------------------------------------------------
{
    NSUInteger theMax = (sizeof(k_invisibleSpaceCharList) / sizeof(unichar)) - 1;
    NSUInteger theIndex = (inIndex > theMax) ? theMax : inIndex;
    unichar theUnichar = k_invisibleSpaceCharList[theIndex];

    return ([NSString stringWithCharacters:&theUnichar length:1]);
}


// ------------------------------------------------------
- (NSString *)invisibleTabCharacter:(NSUInteger)inIndex
// 非表示タブ表示用文字を返すユーティリティメソッド
// ------------------------------------------------------
{
    NSUInteger theMax = (sizeof(k_invisibleTabCharList) / sizeof(unichar)) - 1;
    NSUInteger theIndex = (inIndex > theMax) ? theMax : inIndex;
    unichar theUnichar = k_invisibleTabCharList[theIndex];

    return ([NSString stringWithCharacters:&theUnichar length:1]);
}


// ------------------------------------------------------
- (NSString *)invisibleNewLineCharacter:(NSUInteger)inIndex
// 非表示改行表示用文字を返すユーティリティメソッド
// ------------------------------------------------------
{
    NSUInteger theMax = (sizeof(k_invisibleNewLineCharList) / sizeof(unichar)) - 1;
    NSUInteger theIndex = (inIndex > theMax) ? theMax : inIndex;
    unichar theUnichar = k_invisibleNewLineCharList[theIndex];

    return ([NSString stringWithCharacters:&theUnichar length:1]);
}


// ------------------------------------------------------
- (NSString *)invisibleFullwidthSpaceCharacter:(NSUInteger)inIndex
// 非表示全角スペース表示用文字を返すユーティリティメソッド
// ------------------------------------------------------
{
    NSUInteger theMax = (sizeof(k_invisibleFullwidthSpaceCharList) / sizeof(unichar)) - 1;
    NSUInteger theIndex = (inIndex > theMax) ? theMax : inIndex;
    unichar theUnichar = k_invisibleFullwidthSpaceCharList[theIndex];

    return ([NSString stringWithCharacters:&theUnichar length:1]);
}


// ------------------------------------------------------
- (NSStringEncoding)encodingFromName:(NSString *)inEncodingName
// エンコーディング名からNSStringEncodingを返すユーティリティメソッド
// ------------------------------------------------------
{
    id theValues = [[NSUserDefaultsController sharedUserDefaultsController] values];
    NSArray *theEncodings = [[[theValues valueForKey:k_key_encodingList] copy] autorelease];
    NSStringEncoding outEncoding;
    BOOL theCorrect = NO;

    for (NSNumber *encoding in theEncodings) {
        CFStringEncoding theCFEncoding = [encoding unsignedLongValue];
        if (theCFEncoding != kCFStringEncodingInvalidId) { // = separator
            outEncoding = CFStringConvertEncodingToNSStringEncoding(theCFEncoding);
            if ([inEncodingName isEqualToString:[NSString localizedNameOfStringEncoding:outEncoding]]) {
                theCorrect = YES;
                break;
            }
        }
    }
    return (theCorrect) ? outEncoding : NSNotFound;
}


// ------------------------------------------------------
- (BOOL)isInvalidYenEncoding:(NSStringEncoding)inEncoding
// エンコーディング名からNSStringEncodingを返すユーティリティメソッド
// ------------------------------------------------------
{
    return ([_invalidYenEncodings containsObject:[NSNumber numberWithUnsignedInt:inEncoding]]);
}


// ------------------------------------------------------
- (NSString *)keyEquivalentAndModifierMask:(NSUInteger *)ioModMask
        fromString:(NSString *)inString includingCommandKey:(BOOL)inBool
// 文字列からキーボードショートカット定義を読み取るユーティリティメソッド
//------------------------------------------------------
{
    *ioModMask = 0;
    NSUInteger theLength = [inString length];
    if ((inString == nil) || (theLength < 2)) { return @""; }

    NSString *outKey = [inString substringFromIndex:(theLength - 1)];
    NSCharacterSet *theSet = 
            [NSCharacterSet characterSetWithCharactersInString:[inString substringToIndex:(theLength - 1)]];

    if (inBool) { // === Cmd 必須のとき
        if ([theSet characterIsMember:k_keySpecCharList[3]]) { // @
            if ([theSet characterIsMember:k_keySpecCharList[0]]) { // ^
                *ioModMask |= NSControlKeyMask;
            }
            if ([theSet characterIsMember:k_keySpecCharList[1]]) { // ~
                *ioModMask |= NSAlternateKeyMask;
            }
            if (([theSet characterIsMember:k_keySpecCharList[2]]) ||
                    (isupper([outKey characterAtIndex:0]) == 1)) { // $
                *ioModMask |= NSShiftKeyMask;
            }
            *ioModMask |= NSCommandKeyMask;
        }
    } else {
        if ([theSet characterIsMember:k_keySpecCharList[0]]) {
            *ioModMask |= NSControlKeyMask;
        }
        if ([theSet characterIsMember:k_keySpecCharList[1]]) {
            *ioModMask |= NSAlternateKeyMask;
        }
        if ([theSet characterIsMember:k_keySpecCharList[2]]) {
            *ioModMask |= NSShiftKeyMask;
        }
        if ([theSet characterIsMember:k_keySpecCharList[3]]) {
            *ioModMask |= NSCommandKeyMask;
        }
    }

    if (ioModMask != 0) {
        return outKey;
    } else {
        return @"";
    }

}


// ------------------------------------------------------
- (NSString *)stringFromUnsignedInt:(NSUInteger)inInt
// NSUInteger を文字列に変換するユーティリティメソッド
//------------------------------------------------------
{
// このメソッドは、Smultron を参考にさせていただきました。(2006.04.30)
// This method is based on Smultron.(written by Peter Borg – http://smultron.sourceforge.net)
// Smultron  Copyright (c) 2004-2005 Peter Borg, All rights reserved.
// Smultron is released under GNU General Public License, http://www.gnu.org/copyleft/gpl.html

// Leopard で検証した限りでは、NSNumberFormatter を使うよりも速い (2008.04.05)

    id theValues = [[NSUserDefaultsController sharedUserDefaultsController] values];
    NSMutableString *outString = [NSMutableString stringWithFormat:@"%lu", (unsigned long)inInt];

    if ((![[theValues valueForKey:k_key_showStatusBarThousSeparator] boolValue]) || 
                (_thousandsSeparator == nil) || ([_thousandsSeparator length] < 1)) {
        return outString;
    }
    NSInteger thePosition = [outString length] - 3;

    while (thePosition > 0) {
        [outString insertString:_thousandsSeparator atIndex:thePosition];
        thePosition -= 3;
    }
    return outString;
}



#pragma mark ===== Protocol =====

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
    _preferences = [[CEPreferences alloc] initWithAppController:self];
    [self buildAllEncodingMenus];
    [self setSyntaxMenu:[self buildSyntaxMenu]];
    [[CEScriptManager sharedInstance] buildScriptMenu:nil];
    [self cacheTheInvisibleGlyph];
}



#pragma mark === Delegate and Notification ===

//=======================================================
// Delegate method (NSApplication)
//  <== File's Owner
//=======================================================

// ------------------------------------------------------
- (BOOL)applicationShouldOpenUntitledFile:(NSApplication *)sender
// アプリ起動時に新規ドキュメント作成
// ------------------------------------------------------
{
    id theValues = [[NSUserDefaultsController sharedUserDefaultsController] values];

    if (!_didFinishLaunching) {
        return ([[theValues valueForKey:k_key_createNewAtStartup] boolValue]);
    }
    return YES;
}


// ------------------------------------------------------
- (BOOL)applicationShouldHandleReopen:(NSApplication *)inApplication hasVisibleWindows:(BOOL)inFlag
// Re-Open AppleEvents へ対応してウィンドウを開くかどうかを返す
// ------------------------------------------------------
{
    id theValues = [[NSUserDefaultsController sharedUserDefaultsController] values];
    BOOL theBoolDoReopen = [[theValues valueForKey:k_key_reopenBlankWindow] boolValue];

    if (theBoolDoReopen) {
        return YES;
    } else if (inFlag) {
        // Re-Open に応えない設定でウィンドウがあるときは、すべてのウィンドウをチェックしひとつでも通常通り表示されていれば
        // NO を返し何もしない。表示されているウィンドウがすべて Dock にしまわれているときは、そのうちひとつを通常表示させる
        // ため、YES を返す。
        NSEnumerator *theWindowsEnum = [[NSApp windows] objectEnumerator];
        NSWindow *theWindow = nil;
        while (theWindow = [theWindowsEnum nextObject]) {
            if (([theWindow isVisible]) && (![theWindow isMiniaturized])) {
                return NO;
            }
        }
        return YES;
    }
    // Re-Open に応えず、かつウィンドウもないときは何もしない
    return NO;
}


// ------------------------------------------------------
- (void)applicationDidFinishLaunching:(NSNotification *)aNotification
// アプリ起動直後
// ------------------------------------------------------
{
    id theValues = [[NSUserDefaultsController sharedUserDefaultsController] values];

    // （CEKeyBindingManagerによって、キーボードショートカット設定は上書きされる。
    // アプリに内包する DefaultMenuKeyBindings.plist に、ショートカット設定を記述する必要がある。2007.05.19）

    // 「Select Outline item」「Goto」メニューを生成／追加
    NSMenu *theFindMenu = [[[NSApp mainMenu] itemAtIndex:k_findMenuIndex] submenu];
    NSMenuItem *theMenuItem;

    [theFindMenu addItem:[NSMenuItem separatorItem]];
    unichar theUpKey = NSUpArrowFunctionKey;
    theMenuItem = [[[NSMenuItem alloc] initWithTitle:NSLocalizedString(@"Select Prev Outline Item",@"") 
                    action:@selector(selectPrevItemOfOutlineMenu:) 
                    keyEquivalent:[NSString stringWithCharacters:&theUpKey length:1]] autorelease];
    [theMenuItem setKeyEquivalentModifierMask:(NSCommandKeyMask | NSAlternateKeyMask)];
    [theFindMenu addItem:theMenuItem];

    unichar theDownKey = NSDownArrowFunctionKey;
    theMenuItem = [[[NSMenuItem alloc] initWithTitle:NSLocalizedString(@"Select Next Outline Item",@"") 
                    action:@selector(selectNextItemOfOutlineMenu:) 
                    keyEquivalent:[NSString stringWithCharacters:&theDownKey length:1]] autorelease];
    [theMenuItem setKeyEquivalentModifierMask:(NSCommandKeyMask | NSAlternateKeyMask)];
    [theFindMenu addItem:theMenuItem];

    [theFindMenu addItem:[NSMenuItem separatorItem]];
    theMenuItem = [[[NSMenuItem alloc] initWithTitle:NSLocalizedString(@"Go To...",@"") 
                    action:@selector(openGotoPanel:) keyEquivalent:@"l"] autorelease];
    [theFindMenu addItem:theMenuItem];

    // AppleScript 起動のスピードアップのため一度動かしておく
    if ([[theValues valueForKey:k_key_runAppleScriptInLaunching] boolValue]) {

        NSURL *theURL = [[NSBundle mainBundle] URLForResource:@"startup" withExtension:@"applescript"];
        if (theURL == nil) { return; }
        NSAppleScript *theAppleScript = 
                [[[NSAppleScript alloc] initWithContentsOfURL:theURL error:nil] autorelease];

        if (theAppleScript != nil) {
            (void)[theAppleScript executeAndReturnError:nil];
        }
    }
    // HexColorCodeEditorの値を初期化
    [[CEHCCManager sharedInstance] setupHCCValues];
    // KeyBindingManagerをセットアップ
    [[CEKeyBindingManager sharedInstance] setupAtLaunching];
    // ファイルを開くデフォルトエンコーディングをセット
    [[CEDocumentController sharedDocumentController] setSelectAccessoryEncodingMenuToDefault:self];

    // 起動完了フラグをセット
    _didFinishLaunching = YES;
}


// ------------------------------------------------------
- (void)applicationDidBecomeActive:(NSNotification *)inNotification
// アプリがアクティブになった
// ------------------------------------------------------
{
    // 各ドキュメントに外部プロセスによって変更保存されていた場合の通知を行わせる
    [[[CEDocumentController sharedDocumentController] documents] 
            makeObjectsPerformSelector:@selector(showUpdatedByExternalProcessAlert)];
}


// ------------------------------------------------------
- (void)applicationWillTerminate:(NSNotification *)inNotification
// アプリ終了の許可を返す
// ------------------------------------------------------
{
    // 環境設定の FileDrop タブ「Insert string format:」テキストビューにフォーカスがあるまま終了すると
    // 内容が保存されない問題への対処
    [_preferences makeFirstResponderToPrefWindow];
    // 環境設定の FileDrop 配列コントローラの値を書き戻す
    [_preferences writeBackFileDropArray];
}


// ------------------------------------------------------
- (BOOL)application:(NSApplication *)sender delegateHandlesKey:(NSString *)inKey
// AppleScript へ、対応しているキーかどうかを返す
// ------------------------------------------------------
{
    return [inKey isEqualToString:@"selection"];
}


// ------------------------------------------------------
- (NSMenu *)applicationDockMenu:(NSApplication *)sender
// Dock メニュー生成
// ------------------------------------------------------
{
    NSMenu *outMenu = [[[NSMenu alloc] init] autorelease];
    NSMenuItem *theNewItem = [[(NSMenuItem *)[[[[NSApp mainMenu] itemAtIndex:k_fileMenuIndex]
                                submenu] itemWithTag:k_newMenuItemTag] copy] autorelease];
    NSMenuItem *theOpenItem = [[(NSMenuItem *)[[[[NSApp mainMenu] itemAtIndex:k_fileMenuIndex] 
                                submenu] itemWithTag:k_openMenuItemTag] copy] autorelease];


    [theNewItem setAction:@selector(newInDockMenu:)];
    [theOpenItem setAction:@selector(openInDockMenu:)];

    [outMenu addItem:theNewItem];
    [outMenu addItem:theOpenItem];

    return outMenu;
}



#pragma mark ===== Action messages =====

//=======================================================
// Action messages
//
//=======================================================

// ------------------------------------------------------
- (IBAction)openPrefWindow:(id)sender
// 環境設定ウィンドウを開く
// ------------------------------------------------------
{
    [_preferences openPrefWindow];
}

// ------------------------------------------------------
- (IBAction)openAppleScriptDictionary:(id)sender
// アップルスクリプト辞書をスクリプトエディタで開く
// ------------------------------------------------------
{
    NSURL *URL = [[NSBundle mainBundle] URLForResource:@"openDictionary" withExtension:@"applescript"];
    NSDictionary *theErrorInfo;
    NSAppleScript *theAppleScript = [[[NSAppleScript alloc] initWithContentsOfURL:URL error:nil] autorelease];
    (void)[theAppleScript executeAndReturnError:&theErrorInfo];
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
    [[CEHCCManager sharedInstance] openHexColorCodeEditor];
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
    NSURL *URL = [[NSBundle mainBundle] URLForResource:fileName withExtension:nil];
    
    [[NSWorkspace sharedWorkspace] openURL:URL];
}


// ------------------------------------------------------
- (IBAction)openWebSite:(id)sender
// Webサイト（coteditor.github.io）を開く
// ------------------------------------------------------
{
    [[NSWorkspace sharedWorkspace] openURL:[NSURL URLWithString:k_webSiteURL]];
}


#pragma mark ===== AppleScript accessor =====

//=======================================================
// AppleScript accessor
//
//=======================================================

// ------------------------------------------------------
- (CETextSelection *)selection
// 最も前面のドキュメントウィンドウの選択範囲オブジェクトを返す
// ------------------------------------------------------
{
    id theDoc = [NSApp orderedDocuments][0];

    if (theDoc != nil) {
        return (CETextSelection *)[theDoc selection];
    }
    return nil;
}


// ------------------------------------------------------
- (void)setSelection:(id)inObject
// 選択範囲へテキストを設定
// ------------------------------------------------------
{
    [[self selection] setContents:inObject];
}



@end



@implementation CEAppController (Private)

//=======================================================
// Private method
//
//=======================================================

//------------------------------------------------------
- (void)setupSupportDirectory
// データ保存用ディレクトリの存在をチェック、なければつくる
//------------------------------------------------------
{
    NSFileManager *theFileManager = [NSFileManager defaultManager];
    NSURL *URL = [[theFileManager URLForDirectory:NSApplicationSupportDirectory
                                         inDomain:NSUserDomainMask
                                appropriateForURL:nil
                                           create:YES
                                            error:nil]
                  URLByAppendingPathComponent:@"CotEditor"];
    BOOL theValueIsDir = NO, theValueCreated = NO;

    if (![theFileManager fileExistsAtPath:[URL path] isDirectory:&theValueIsDir]) {
        theValueCreated = [theFileManager createDirectoryAtURL:URL
                                   withIntermediateDirectories:YES
                                                    attributes:nil
                                                         error:nil];
        if (!theValueCreated) {
            NSLog(@"Could not create support directory for CotEditor...");
        }
    } else if (!theValueIsDir) {
        NSLog(@"\"%@\" is not dir.", [URL path]);
    }
    
}


//------------------------------------------------------
- (NSArray *)encodingMenuNoActionFromArray:(NSArray *)inArray
// エンコーディングメニューアイテムを生成
//------------------------------------------------------
{
    NSMutableArray *outArray = [NSMutableArray array];
    NSPopUpButton *theAccessoryEncodingMenuButton = 
            [[CEDocumentController sharedDocumentController] accessoryEncodingMenu];
    NSMenu *theAccessoryEncodingMenu = [theAccessoryEncodingMenuButton menu];
    NSMenuItem *theItem;

    [theAccessoryEncodingMenuButton removeAllItems];
    theItem = [[[NSMenuItem alloc] initWithTitle:NSLocalizedString(@"Auto-Detect",@"") 
                    action:nil keyEquivalent:@""] autorelease];
    [theItem setTag:k_autoDetectEncodingMenuTag];
    [theAccessoryEncodingMenu addItem:theItem];
    [theAccessoryEncodingMenu addItem:[NSMenuItem separatorItem]];

    for (NSNumber *encoding in inArray) {
        CFStringEncoding theCFEncoding = [encoding unsignedLongValue];
        if (theCFEncoding == kCFStringEncodingInvalidId) { // set separator
            [theAccessoryEncodingMenu addItem:[NSMenuItem separatorItem]];
            [outArray addObject:[NSMenuItem separatorItem]];
        } else {
            NSStringEncoding theEncoding = CFStringConvertEncodingToNSStringEncoding(theCFEncoding);
            NSString *theMenuTitle = [NSString localizedNameOfStringEncoding:theEncoding];
            NSMenuItem *theAccessoryMenuItem = [[[NSMenuItem alloc] initWithTitle:theMenuTitle 
                            action:nil keyEquivalent:@""] autorelease];
            [theAccessoryMenuItem setTarget:nil];
            [theAccessoryMenuItem setTag:theEncoding];
            [theAccessoryEncodingMenu addItem:theAccessoryMenuItem];
            [outArray addObject:theAccessoryMenuItem];
        }
    }
    return outArray;
}


//------------------------------------------------------
- (NSMenu *)buildFormatEncodingMenuFromArray:(NSArray *)inArray
// フォーマットのエンコーディングメニューアイテムを生成
//------------------------------------------------------
{
    NSMenu *theEncodingMenu = [[[NSMenu alloc] initWithTitle:@"ENCODEING"] autorelease];
    NSMenuItem *theFormatMenuItem = 
            [[[[NSApp mainMenu] itemAtIndex:k_formatMenuIndex] submenu] itemWithTag:k_fileEncodingMenuItemTag];

    for (NSNumber *encoding in inArray) {
        CFStringEncoding theCFEncoding = [encoding unsignedLongValue];
        if (theCFEncoding == kCFStringEncodingInvalidId) { // set separator
            [theEncodingMenu addItem:[NSMenuItem separatorItem]];
        } else {
            NSStringEncoding theEncoding = CFStringConvertEncodingToNSStringEncoding(theCFEncoding);
            NSString *theMenuTitle = [NSString localizedNameOfStringEncoding:theEncoding];
            NSMenuItem *theMenuItem = [[[NSMenuItem alloc] initWithTitle:theMenuTitle 
                            action:@selector(setEncoding:) keyEquivalent:@""] autorelease];
            [theMenuItem setTag:theEncoding];
            [theEncodingMenu addItem:theMenuItem];
        }
    }
    [theFormatMenuItem setSubmenu:theEncodingMenu];
    return [[theEncodingMenu copy] autorelease];
}


//------------------------------------------------------
- (NSMenu *)buildSyntaxMenu
// シンタックスカラーリングメニューを生成
//------------------------------------------------------
{
    NSMenu *theColoringMenu = [[[NSMenu alloc] initWithTitle:@"SYNTAX"] autorelease];
    NSMenu *outMenu = nil;
    NSMenuItem *theFormatMenuItem = 
            [[[[NSApp mainMenu] itemAtIndex:k_formatMenuIndex] submenu] itemWithTag:k_syntaxMenuItemTag];
    NSMenuItem *theMenuItem;
    NSString *theMenuTitle;
    NSArray *theArray = [[CESyntaxManager sharedInstance] styleNames];
    NSInteger i, theCount = [theArray count];
    
    [theFormatMenuItem setSubmenu:nil]; // まず開放しておかないと、同じキーボードショートカットキーが設定できない

    for (i = 0; i < (theCount + 2); i++) { // "None"+Separator分を加える
        if (i == 1) {
            [theColoringMenu addItem:[NSMenuItem separatorItem]];
        } else {
            if (i == 0) {
                theMenuTitle = NSLocalizedString(@"None",@"");
            } else {
                theMenuTitle = theArray[(i - 2)];
            }
            theMenuItem = [[[NSMenuItem alloc] initWithTitle:theMenuTitle 
                            action:@selector(setSyntaxStyle:) keyEquivalent:@""] autorelease];
            [theMenuItem setTag:i];
            [theColoringMenu addItem:theMenuItem];
        }
    }
    outMenu = [[theColoringMenu copy] autorelease];

    [theColoringMenu addItem:[NSMenuItem separatorItem]];
    // 全文字列を再カラーリングするメニューを追加
    theMenuTitle = NSLocalizedString(@"Re-color All",@"");
    theMenuItem = [[[NSMenuItem alloc] initWithTitle:theMenuTitle 
                    action:@selector(recoloringAllStringOfDocument:) keyEquivalent:@"r"] autorelease];
    [theMenuItem setKeyEquivalentModifierMask:(NSCommandKeyMask | NSAlternateKeyMask)]; // = Cmd + Opt + R
    [theColoringMenu addItem:theMenuItem];
    [theFormatMenuItem setSubmenu:theColoringMenu];

    return outMenu;
}


//------------------------------------------------------
- (void)cacheTheInvisibleGlyph
// 不可視文字列表示時のタイムラグを短縮するため、キャッシュしておく
//------------------------------------------------------
{
    NSMutableString *theChars = [NSMutableString string];
    NSUInteger i;

    for (i = 0; i < (sizeof(k_invisibleSpaceCharList) / sizeof(unichar)); i++) {
        [theChars appendString:[NSString stringWithCharacters:&k_invisibleSpaceCharList[i] length:1]];
    }
    for (i = 0; i < (sizeof(k_invisibleTabCharList) / sizeof(unichar)); i++) {
        [theChars appendString:[NSString stringWithCharacters:&k_invisibleTabCharList[i] length:1]];
    }
    for (i = 0; i < (sizeof(k_invisibleNewLineCharList) / sizeof(unichar)); i++) {
        [theChars appendString:[NSString stringWithCharacters:&k_invisibleNewLineCharList[i] length:1]];
    }
    for (i = 0; i < (sizeof(k_invisibleFullwidthSpaceCharList) / sizeof(unichar)); i++) {
        [theChars appendString:[NSString stringWithCharacters:&k_invisibleFullwidthSpaceCharList[i] length:1]];
    }
    if ([theChars length] < 1) { return; }

    NSTextStorage *theStorage = [[[NSTextStorage alloc] initWithString:theChars] autorelease];
    CELayoutManager *theLayoutManager = [[[CELayoutManager alloc] init] autorelease];
    NSTextContainer *theContainer = [[[NSTextContainer alloc] init] autorelease];

    [theLayoutManager addTextContainer:theContainer];
    [theStorage addLayoutManager:theLayoutManager];
    (void)[theLayoutManager glyphRangeForTextContainer:theContainer];
}

@end
