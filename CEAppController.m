/*
=================================================
CEAppController
(for CotEditor)

Copyright (C) 2004-2007 nakamuxu.
http://www.aynimac.com/
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
- (void)filterNotAvailableEncoding;
- (void)deleteWrongDotFile;
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
    NSMutableArray *theEncodings = [NSMutableArray array];
    int i;
    for (i = 0; i < sizeof(k_CFStringEncodingList)/sizeof(CFStringEncodings); i++) {
        [theEncodings addObject:[NSNumber numberWithUnsignedLong:k_CFStringEncodingList[i]]];
    }
    // 10.4+ で実行されていたら、さらにエンコーディングを追加
    if (floor(NSAppKitVersionNumber) > NSAppKitVersionNumber10_3) {
        [theEncodings addObject:[NSNumber numberWithUnsignedLong:kCFStringEncodingInvalidId]]; // セパレータ
        for (i = 0; i < sizeof(k_CFStringEncoding10_4List)/sizeof(CFStringEncodings); i++) {
            [theEncodings addObject:[NSNumber numberWithUnsignedLong:k_CFStringEncoding10_4List[i]]];
        }
    }

    NSDictionary *theDefaults = [NSDictionary dictionaryWithObjectsAndKeys:
                [NSNumber numberWithBool:YES], k_key_showLineNumbers, 
                [NSNumber numberWithBool:YES], k_key_showWrappedLineMark, 
                [NSNumber numberWithBool:YES], k_key_showStatusBar, 
                [NSNumber numberWithBool:YES], k_key_countLineEndingAsChar, 
                [NSNumber numberWithBool:NO], k_key_syncFindPboard, 
                [NSNumber numberWithBool:NO], k_key_inlineContextualScriptMenu, 
                [NSNumber numberWithBool:YES], k_key_showStatusBarThousSeparator, 
                [NSNumber numberWithBool:YES], k_key_showNavigationBar, 
                [NSNumber numberWithBool:YES], k_key_wrapLines, 
                [NSNumber numberWithInt:0], k_key_defaultLineEndCharCode, 
                theEncodings, k_key_encodingList, 
                [[NSFont controlContentFontOfSize:[NSFont systemFontSize]] fontName], k_key_fontName, 
                [NSNumber numberWithFloat:[NSFont systemFontSize]], k_key_fontSize, 
                [NSNumber numberWithUnsignedLong:k_autoDetectEncodingMenuTag], k_key_encodingInOpen, 
                [NSNumber 
                numberWithUnsignedLong:CFStringConvertEncodingToNSStringEncoding(kCFStringEncodingUTF8)], 
                        k_key_encodingInNew, 
                [NSNumber numberWithBool:YES], k_key_referToEncodingTag, 
                [NSNumber numberWithBool:YES], k_key_createNewAtStartup, 
                [NSNumber numberWithBool:YES], k_key_reopenBlankWindow, 
                [NSNumber numberWithBool:NO], k_key_checkSpellingAsType, 
                [NSNumber numberWithUnsignedInt:0], k_key_saveTypeCreator, 
                [NSNumber numberWithFloat:600.0], k_key_windowWidth, 
                [NSNumber numberWithFloat:450.0], k_key_windowHeight, 
                [NSNumber numberWithBool:NO], k_key_autoExpandTab, 
                [NSNumber numberWithUnsignedInt:4], k_key_tabWidth, 
                [NSNumber numberWithFloat:1.0], k_key_windowAlpha, 
                [NSNumber numberWithBool:YES], k_key_alphaOnlyTextView, 
                [NSNumber numberWithBool:YES], k_key_autoIndent, 
                [NSArchiver archivedDataWithRootObject:[NSColor grayColor]], k_key_invisibleCharactersColor, 
                [NSNumber numberWithBool:NO], k_key_showInvisibleSpace, 
                [NSNumber numberWithUnsignedInt:0], k_key_invisibleSpace, 
                [NSNumber numberWithBool:NO], k_key_showInvisibleTab, 
                [NSNumber numberWithUnsignedInt:0], k_key_invisibleTab, 
                [NSNumber numberWithBool:NO], k_key_showInvisibleNewLine, 
                [NSNumber numberWithUnsignedInt:0], k_key_invisibleNewLine, 
                [NSNumber numberWithBool:NO], k_key_showInvisibleFullwidthSpace, 
                [NSNumber numberWithUnsignedInt:0], k_key_invisibleFullwidthSpace, 
                [NSNumber numberWithBool:NO], k_key_showOtherInvisibleChars, 
                [NSNumber numberWithBool:NO], k_key_highlightCurrentLine, 
                [NSNumber numberWithBool:YES], k_key_setHiliteLineColorToIMChars, 
                [NSArchiver archivedDataWithRootObject:[NSColor textColor]], k_key_textColor, 
                [NSArchiver archivedDataWithRootObject:[NSColor textBackgroundColor]], k_key_backgroundColor, 
                [NSArchiver archivedDataWithRootObject:[NSColor textColor]], k_key_insertionPointColor, 
                [NSArchiver archivedDataWithRootObject:[NSColor selectedTextBackgroundColor]], 
                        k_key_selectionColor, 
                [NSArchiver archivedDataWithRootObject:
                        [NSColor colorWithCalibratedRed:0.843 green:0.953 blue:0.722 alpha:1.0]], 
                        k_key_highlightLineColor, 
                [NSArchiver archivedDataWithRootObject:
                        [NSColor colorWithCalibratedRed:0.047 green:0.102 blue:0.494 alpha:1.0]], 
                        k_key_keywordsColor, 
                [NSArchiver archivedDataWithRootObject:
                        [NSColor colorWithCalibratedRed:0.408 green:0.220 blue:0.129 alpha:1.0]], 
                        k_key_commandsColor, 
                [NSArchiver archivedDataWithRootObject:[NSColor blueColor]], k_key_numbersColor, 
                [NSArchiver archivedDataWithRootObject:
                        [NSColor colorWithCalibratedRed:0.463 green:0.059 blue:0.313 alpha:1.0]], 
                        k_key_valuesColor, 
                [NSArchiver archivedDataWithRootObject:
                        [NSColor colorWithCalibratedRed:0.537 green:0.075 blue:0.08 alpha:1.0]], 
                        k_key_stringsColor, 
                [NSArchiver archivedDataWithRootObject:[NSColor blueColor]], k_key_charactersColor, 
                [NSArchiver archivedDataWithRootObject:
                        [NSColor colorWithCalibratedRed:0.137 green:0.431 blue:0.145 alpha:1.0]], 
                        k_key_commentsColor, 
                [NSNumber numberWithBool:YES], k_key_doColoring, 
                NSLocalizedString(@"None",@""), k_key_defaultColoringStyleName, 
                [NSNumber numberWithBool:NO], k_key_delayColoring, 
                [NSArray arrayWithObjects: 
                        [NSDictionary  dictionaryWithObjectsAndKeys:
                            @"jpg, jpeg, gif, png", k_key_fileDropExtensions, 
                            @"<img src=\"<<<RELATIVE-PATH>>>\" alt =\"<<<FILENAME-NOSUFFIX>>>\" title=\"<<<FILENAME-NOSUFFIX>>>\" width=\"<<<IMAGEWIDTH>>>\" height=\"<<<IMAGEHEIGHT>>>\" />", k_key_fileDropFormatString, 
                        nil], nil], k_key_fileDropArray, 
                [NSNumber numberWithInt:1], k_key_NSDragAndDropTextDelay, 
                [NSNumber numberWithBool:NO], k_key_smartInsertAndDelete, 
                [NSNumber numberWithBool:YES], k_key_shouldAntialias, 
                [NSNumber numberWithUnsignedInt:0], k_key_completeAddStandardWords, 
                [NSNumber numberWithBool:NO], k_key_showPageGuide, 
                [NSNumber numberWithInt:80], k_key_pageGuideColumn, 
                [NSNumber numberWithFloat:0.0], k_key_lineSpacing, 
                [NSNumber numberWithBool:NO], k_key_swapYenAndBackSlashKey, 
                [NSNumber numberWithBool:YES], k_key_fixLineHeight, 
                [NSNumber numberWithBool:YES], k_key_highlightBraces, 
                [NSNumber numberWithBool:NO], k_key_highlightLtGt, 
                [NSNumber numberWithBool:NO], k_key_saveUTF8BOM, 
                [NSNumber numberWithInt:0], k_key_setPrintFont, 
                [[NSFont controlContentFontOfSize:[NSFont systemFontSize]] fontName], k_key_printFontName, 
                [NSNumber numberWithFloat:[NSFont systemFontSize]], k_key_printFontSize, 
                [NSNumber numberWithBool:YES], k_printHeader, 
                [NSNumber numberWithInt:3], k_headerOneStringIndex, 
                [NSNumber numberWithInt:4], k_headerTwoStringIndex, 
                [NSNumber numberWithInt:0], k_headerOneAlignIndex, 
                [NSNumber numberWithInt:2], k_headerTwoAlignIndex, 
                [NSNumber numberWithBool:YES], k_printHeaderSeparator, 
                [NSNumber numberWithBool:YES], k_printFooter, 
                [NSNumber numberWithInt:0], k_footerOneStringIndex, 
                [NSNumber numberWithInt:5], k_footerTwoStringIndex, 
                [NSNumber numberWithInt:0], k_footerOneAlignIndex, 
                [NSNumber numberWithInt:1], k_footerTwoAlignIndex, 
                [NSNumber numberWithBool:YES], k_printFooterSeparator, 
                [NSNumber numberWithInt:0], k_printLineNumIndex, 
                [NSNumber numberWithInt:0], k_printInvisibleCharIndex, 
                [NSNumber numberWithInt:0], k_printColorIndex, 

        /* -------- 以下、環境設定にない設定項目 -------- */
                [NSNumber numberWithInt:1], k_key_gotoObjectMenuIndex, // in Only goto window (not pref).
                [NSArchiver archivedDataWithRootObject:
                        [NSColor colorWithCalibratedRed:1.0 green:1.0 blue:1.0 alpha:1.0]], 
                        k_key_HCCBackgroundColor, 
                [NSArchiver archivedDataWithRootObject:
                        [NSColor colorWithCalibratedRed:0.0 green:0.0 blue:0.0 alpha:1.0]], 
                        k_key_HCCForeColor, 
                [NSString stringWithString:@"Sample Text"], k_key_HCCSampleText, 
                [NSArray array], k_key_HCCForeComboBoxData, 
                [NSArray array], k_key_HCCBackComboBoxData, 
                [NSNumber numberWithBool:NO], k_key_foreColorCBoxIsOk, 
                [NSNumber numberWithBool:NO], k_key_backgroundColorCBoxIsOk, 
                [self factoryDefaultOfTextInsertStringArray], k_key_insertCustomTextArray, 

        /* -------- 以下、隠し設定 -------- */
                [NSString stringWithString:@"Courier"], k_key_statusBarFontName, 
                [NSNumber numberWithFloat:12.0], k_key_statusBarFontSize, 
                [NSString stringWithString:@"ArialNarrow"], k_key_lineNumFontName, 
                [NSNumber numberWithFloat:10.0], k_key_lineNumFontSize, 
                [NSArchiver archivedDataWithRootObject:[NSColor darkGrayColor]], k_key_lineNumFontColor, 
                [NSNumber numberWithFloat:0.001], k_key_basicColoringDelay, 
                [NSNumber numberWithFloat:0.3], k_key_firstColoringDelay, 
                [NSNumber numberWithFloat:0.7], k_key_secondColoringDelay, 
                [NSNumber numberWithFloat:0.12], k_key_lineNumUpdateInterval, 
                [NSNumber numberWithFloat:0.2], k_key_infoUpdateInterval, 
                [NSNumber numberWithFloat:0.42], k_key_incompatibleCharInterval, 
                [NSNumber numberWithFloat:0.37], k_key_outlineMenuInterval, 
                [NSString stringWithString:@"Helvetica"], k_key_navigationBarFontName, 
                [NSNumber numberWithFloat:11.0], k_key_navigationBarFontSize, 
                [NSNumber numberWithUnsignedInt:110], k_key_outlineMenuMaxLength, 
                [[NSFont systemFontOfSize:[NSFont systemFontSize]] fontName], k_key_headerFooterFontName, 
                [NSNumber numberWithFloat:10.0], k_key_headerFooterFontSize, 
                [NSString stringWithString:@"%Y-%m-%d  %H:%M:%S"], k_key_headerFooterDateTimeFormat, 
                [NSNumber numberWithBool:YES], k_key_headerFooterPathAbbreviatingWithTilde, 
                [NSNumber numberWithFloat:0.0], k_key_textContainerInsetWidth, 
                [NSNumber numberWithFloat:4.0], k_key_textContainerInsetHeightTop, 
                [NSNumber numberWithFloat:16.0], k_key_textContainerInsetHeightBottom, 
                [NSNumber numberWithUnsignedInt:115000], k_key_showColoringIndicatorTextLength, 
                [NSNumber numberWithBool:YES], k_key_runAppleScriptInLaunching, 
                [NSNumber numberWithBool:YES], k_key_showAlertForNotWritable, 
                [NSNumber numberWithBool:YES], k_key_notifyEditByAnother, // 0.9.4までは環境設定にあった(2008.06.03)

                nil];
    [[NSUserDefaultsController sharedUserDefaultsController] setInitialValues:theDefaults];

    // transformer 登録
    id theTransformer = [[[CEHexColorTransformer alloc] init] autorelease];
    [NSValueTransformer setValueTransformer:theTransformer forName:@"HexColorTransformer"];
}


// ------------------------------------------------------
+ (NSArray *)factoryDefaultOfTextInsertStringArray
// 文字列挿入メソッドの標準設定配列を返す
// ------------------------------------------------------
{
// インデックスが0-30の、合計31個
    return [NSArray arrayWithObjects:
                    @"<br />\n", @"", @"", @"", @"", @"", @"", @"", @"", @"", @"", 
                    @"", @"", @"", @"", @"", @"", @"", @"", @"", @"", 
                    @"", @"", @"", @"", @"", @"", @"", @"", @"", @"", nil];
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
        int i;
        for (i = 0; i < sizeof(k_CFStringEncodingInvalidYenList)/sizeof(CFStringEncodings); i++) {
            theEncoding = CFStringConvertEncodingToNSStringEncoding(k_CFStringEncodingInvalidYenList[i]);
            [theEncodings addObject:[NSNumber numberWithUnsignedInt:theEncoding]];
        }
        _invalidYenEncodings = [theEncodings retain];
        _thousandsSeparator = [[[NSUserDefaults standardUserDefaults] valueForKey:NSThousandsSeparator] retain];
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
- (NSString *)invisibleSpaceCharacter:(unsigned int)inIndex
// 非表示半角スペース表示用文字を返すユーティリティメソッド
// ------------------------------------------------------
{
    unsigned int theMax = (sizeof(k_invisibleSpaceCharList) / sizeof(unichar)) - 1;
    unsigned int theIndex = (inIndex > theMax) ? theMax : inIndex;
    unichar theUnichar = k_invisibleSpaceCharList[theIndex];

    return ([NSString stringWithCharacters:&theUnichar length:1]);
}


// ------------------------------------------------------
- (NSString *)invisibleTabCharacter:(unsigned int)inIndex
// 非表示タブ表示用文字を返すユーティリティメソッド
// ------------------------------------------------------
{
    unsigned int theMax = (sizeof(k_invisibleTabCharList) / sizeof(unichar)) - 1;
    unsigned int theIndex = (inIndex > theMax) ? theMax : inIndex;
    unichar theUnichar = k_invisibleTabCharList[theIndex];

    return ([NSString stringWithCharacters:&theUnichar length:1]);
}


// ------------------------------------------------------
- (NSString *)invisibleNewLineCharacter:(unsigned int)inIndex
// 非表示改行表示用文字を返すユーティリティメソッド
// ------------------------------------------------------
{
    unsigned int theMax = (sizeof(k_invisibleNewLineCharList) / sizeof(unichar)) - 1;
    unsigned int theIndex = (inIndex > theMax) ? theMax : inIndex;
    unichar theUnichar = k_invisibleNewLineCharList[theIndex];

    return ([NSString stringWithCharacters:&theUnichar length:1]);
}


// ------------------------------------------------------
- (NSString *)invisibleFullwidthSpaceCharacter:(unsigned int)inIndex
// 非表示全角スペース表示用文字を返すユーティリティメソッド
// ------------------------------------------------------
{
    unsigned int theMax = (sizeof(k_invisibleFullwidthSpaceCharList) / sizeof(unichar)) - 1;
    unsigned int theIndex = (inIndex > theMax) ? theMax : inIndex;
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
    int i, theCount = [theEncodings count];

    for (i = 0; i < theCount; i++) {
        CFStringEncoding theCFEncoding = [[theEncodings objectAtIndex:i] unsignedLongValue];
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
- (NSString *)keyEquivalentAndModifierMask:(unsigned int *)ioModMask 
        fromString:(NSString *)inString includingCommandKey:(BOOL)inBool
// 文字列からキーボードショートカット定義を読み取るユーティリティメソッド
//------------------------------------------------------
{
    *ioModMask = 0;
    int theLength = [inString length];
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
- (NSString *)stringFromUnsignedInt:(unsigned int)inInt
// unsigned int を文字列に変換するユーティリティメソッド
//------------------------------------------------------
{
// このメソッドは、Smultron を参考にさせていただきました。(2006.04.30)
// This method is based on Smultron.(written by Peter Borg – http://smultron.sourceforge.net)
// Smultron  Copyright (c) 2004-2005 Peter Borg, All rights reserved.
// Smultron is released under GNU General Public License, http://www.gnu.org/copyleft/gpl.html

// Leopard で検証した限りでは、NSNumberFormatter を使うよりも速い (2008.04.05)

    id theValues = [[NSUserDefaultsController sharedUserDefaultsController] values];
    NSMutableString *outString = [NSMutableString stringWithFormat:@"%u", inInt];

    if ((![[theValues valueForKey:k_key_showStatusBarThousSeparator] boolValue]) || 
                (_thousandsSeparator == nil) || ([_thousandsSeparator length] < 1)) {
        return outString;
    }
    int thePosition = [outString length] - 3;

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
    [self filterNotAvailableEncoding];
    [self buildAllEncodingMenus];
    [self setSyntaxMenu:[self buildSyntaxMenu]];
    [[CEScriptManager sharedInstance] buildScriptMenu:nil];
    [self cacheTheInvisibleGlyph];
    [self deleteWrongDotFile];
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

        NSString *thePath = [[NSBundle mainBundle] pathForResource:@"startup" ofType:@"applescript"];
        if (thePath == nil) { return; }
        NSURL *theURL = [NSURL fileURLWithPath:thePath];
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
            makeObjectsPerformSelector:@selector(showUpdateAlertWithUKKQueueNotification)];
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
    NSString *thePath = [[NSBundle mainBundle] pathForResource:@"openDictionary" ofType:@"applescript"];
    NSString *theSource = [NSString stringWithContentsOfFile:thePath];
    NSDictionary *theErrorInfo;
    NSAppleScript *theAppleScript = [[[NSAppleScript alloc] initWithSource:theSource] autorelease];
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
    NSMenuItem *theMenuItem = (NSMenuItem *)sender;
    NSString *theDocumentPath = [[[NSBundle mainBundle] bundlePath] stringByAppendingPathComponent:@"/Contents/Resources/Docs"];
    int i;
    
    for (i = 0; k_bundleDocumentList[i].tag != 0; i++) {
        if (k_bundleDocumentList[i].tag == theMenuItem.tag) {
            theDocumentPath = [theDocumentPath stringByAppendingPathComponent:k_bundleDocumentList[i].path];
            break;
        }
    }

    [[NSWorkspace sharedWorkspace] openFile:theDocumentPath];
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
    id theDoc = [[NSApp orderedDocuments] objectAtIndex:0];

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
    NSString *theDirPath = [NSHomeDirectory( ) 
            stringByAppendingPathComponent:@"Library/Application Support/CotEditor"];
    NSFileManager *theFileManager = [NSFileManager defaultManager];
    BOOL theValueIsDir = NO, theValueCreated = NO;

    if (![theFileManager fileExistsAtPath:theDirPath isDirectory:&theValueIsDir]) {
        theValueCreated = [theFileManager createDirectoryAtPath:theDirPath attributes:nil];
        if (!theValueCreated) {
            NSLog(@"Could not create support directory for CotEditor...");
        }
    } else if (!theValueIsDir) {
        NSLog(@"\"%@\" is not dir.", theDirPath);
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
    int i, theCount = [inArray count];

    [theAccessoryEncodingMenuButton removeAllItems];
    theItem = [[[NSMenuItem alloc] initWithTitle:NSLocalizedString(@"Auto-Detect",@"") 
                    action:nil keyEquivalent:@""] autorelease];
    [theItem setTag:k_autoDetectEncodingMenuTag];
    [theAccessoryEncodingMenu addItem:theItem];
    [theAccessoryEncodingMenu addItem:[NSMenuItem separatorItem]];

    for (i = 0; i < theCount; i++) {
        CFStringEncoding theCFEncoding = [[inArray objectAtIndex:i] unsignedLongValue];
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
    int i, theCount = [inArray count];

    for (i = 0; i < theCount; i++) {
        CFStringEncoding theCFEncoding = [[inArray objectAtIndex:i] unsignedLongValue];
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
    int i, theCount = [theArray count];
    
    [theFormatMenuItem setSubmenu:nil]; // まず開放しておかないと、同じキーボードショートカットキーが設定できない

    for (i = 0; i < (theCount + 2); i++) { // "None"+Separator分を加える
        if (i == 1) {
            [theColoringMenu addItem:[NSMenuItem separatorItem]];
        } else {
            if (i == 0) {
                theMenuTitle = NSLocalizedString(@"None",@"");
            } else {
                theMenuTitle = [theArray objectAtIndex:(i - 2)];
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
    int i;

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


//------------------------------------------------------
- (void)filterNotAvailableEncoding
// 実行環境で使えないエンコーディングを削除する
//------------------------------------------------------
{
// 新しいバージョンの Mac OS X から古いバージョンへ環境設定ファイルが写された場合への対応

    if (floor(NSAppKitVersionNumber) <=  NSAppKitVersionNumber10_3) { // = 10.3.x以前
        NSUserDefaults *theUserDefaults = [NSUserDefaults standardUserDefaults];
        NSMutableArray *theNewList = [[[theUserDefaults arrayForKey:k_key_encodingList] mutableCopy] autorelease];
        NSNumber *theNum;
        int i;

        for (i = 0; i < sizeof(k_CFStringEncoding10_4List)/sizeof(CFStringEncodings); i++) {
            theNum = [NSNumber numberWithUnsignedLong:k_CFStringEncoding10_4List[i]];
            if ([theNewList containsObject:theNum]) {
                [theNewList removeObject:theNum];
            }
        }
        [theUserDefaults setObject:theNewList forKey:k_key_encodingList];
        [theUserDefaults synchronize];
    }
}


//------------------------------------------------------
- (void)deleteWrongDotFile
// 0.9.5までのバグで作成された可能性のある不正なファイルを削除
//------------------------------------------------------
{
    // 0.9.5まで、シンタックススタイルシートを新規に作成した場合の処理が不正で「.plist」というファイルが作成されてしまっていた。
    // その「~/Library/Application Support/CotEditor/SyntaxColorings/.plist」を削除する(2008.11.02)
    NSFileManager *theFileManager = [NSFileManager defaultManager];
    NSString *thePath = [NSHomeDirectory( ) 
            stringByAppendingPathComponent:@"Library/Application Support/CotEditor/SyntaxColorings/.plist"];

    if ([theFileManager fileExistsAtPath:thePath]) {
        (void)[theFileManager removeFileAtPath:thePath handler:nil];
    }
}



@end
