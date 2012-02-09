/*
=================================================
constants
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

// binding keys
// userdefaults
#define k_key_showLineNumbers   @"showLineNumbers"
#define k_key_showWrappedLineMark   @"showWrappedLineMark"
#define k_key_showStatusBar     @"showStatusArea"
#define k_key_countLineEndingAsChar @"countLineEndingAsChar"
#define k_key_syncFindPboard        @"syncFindPboard"
#define k_key_inlineContextualScriptMenu    @"inlineContextualScriptMenu"
#define k_key_appendExtensionAtSaving       @"appendExtensionAtSaving"
#define k_key_showStatusBarThousSeparator   @"showStatusThousSeparator"
#define k_key_showNavigationBar @"showNavigationBar"
#define k_key_wrapLines         @"wrapLines"
#define k_key_defaultEncodingCode   @"defaultEncoding"
#define k_key_defaultLineEndCharCode    @"defaultLineEndCharCode"
#define k_key_encodingList  @"encodingList"
#define k_key_fontName      @"fontName"
#define k_key_fontSize      @"fontSize"
#define k_key_encodingInOpen    @"encodingInOpen"
#define k_key_encodingInNew     @"encodingInNew"
#define k_key_referToEncodingTag    @"referToEncodingTag"
#define k_key_createNewAtStartup    @"createNewAtStartup"
#define k_key_reopenBlankWindow     @"reopenBlankWindow"
#define k_key_checkSpellingAsType   @"checkSpellingAsType"
#define k_key_saveTypeCreator   @"saveTypeCreator"
#define k_key_windowWidth   @"windowWidth"
#define k_key_windowHeight  @"windowHeight"
#define k_key_autoExpandTab     @"autoExpandTab"
#define k_key_tabWidth      @"tabWidth"
#define k_key_windowAlpha   @"windowAlpha"
#define k_key_alphaOnlyTextView   @"alphaOnlyTextView"
#define k_key_autoIndent   @"autoIndent"
#define k_key_invisibleCharactersColor  @"invisibleCharactersColor"
#define k_key_showInvisibleSpace        @"showInvisibleSpace"
#define k_key_invisibleSpace            @"invisibleSpace"
#define k_key_showInvisibleTab          @"showInvisibleTab"
#define k_key_invisibleTab              @"invisibleTab"
#define k_key_showInvisibleNewLine      @"showInvisibleNewLine"
#define k_key_invisibleNewLine          @"invisibleNewLine"
#define k_key_showInvisibleFullwidthSpace   @"showInvisibleZenkakuSpace"
#define k_key_invisibleFullwidthSpace   @"invisibleZenkakuSpace"
#define k_key_showOtherInvisibleChars   @"showOtherInvisibleChars"
#define k_key_highlightCurrentLine      @"highlightCurrentLine"
#define k_key_setHiliteLineColorToIMChars   @"setHiliteLineColorToIMChars"
#define k_key_doColoring                @"doSyntaxColoring"
#define k_key_defaultColoringStyleName  @"defaultColoringStyleName"
#define k_key_delayColoring             @"delayColoring"
#define k_key_fileDropArray         @"fileDropArray"
#define k_key_fileDropExtensions    @"extensions"
#define k_key_fileDropFormatString  @"formatString"
#define k_key_NSDragAndDropTextDelay    @"NSDragAndDropTextDelay"
#define k_key_smartInsertAndDelete      @"smartInsertAndDelete"
#define k_key_shouldAntialias           @"shouldAntialias"
#define k_key_completeAddStandardWords  @"completeAddStandardWords"
#define k_key_showPageGuide         @"showPageGuide"
#define k_key_pageGuideColumn       @"pageGuideColumn"
#define k_key_lineSpacing           @"lineSpacing"
#define k_key_swapYenAndBackSlashKey    @"swapYenAndBackSlashKey"
#define k_key_fixLineHeight     @"fixLineHeight"
#define k_key_highlightBraces   @"highlightBraces"
#define k_key_highlightLtGt     @"highlightLtGt"
#define k_key_saveUTF8BOM       @"saveUTF8BOM"
#define k_key_setPrintFont      @"setPrintFont"
#define k_key_printFontName     @"printFontName"
#define k_key_printFontSize     @"printFontSize"
// （以下の印刷設定関連キー、当初の隠し設定時に間違えたという「歴史的経緯」により「key_」なし）
#define k_printHeader           @"printHeader"
#define k_headerOneStringIndex  @"headerOneStringIndex"
#define k_headerTwoStringIndex  @"headerTwoStringIndex"
#define k_headerOneAlignIndex   @"headerOneAlignIndex"
#define k_headerTwoAlignIndex   @"headerTwoAlignIndex"
#define k_printHeaderSeparator  @"printHeaderSeparator"
#define k_printFooter           @"printFooter"
#define k_footerOneStringIndex  @"footerOneStringIndex"
#define k_footerTwoStringIndex  @"footerTwoStringIndex"
#define k_footerOneAlignIndex   @"footerOneAlignIndex"
#define k_footerTwoAlignIndex   @"footerTwoAlignIndex"
#define k_printFooterSeparator  @"printFooterSeparator"
#define k_printLineNumIndex     @"printLineNumIndex"
#define k_printInvisibleCharIndex   @"printInvisibleCharIndex"
#define k_printColorIndex       @"printColorIndex"
//------ 以下、環境設定にない設定項目 ------
#define k_key_gotoObjectMenuIndex       @"gotoObjectMenuIndex"
#define k_key_HCCBackgroundColor    @"HCCBackgroundColor"
#define k_key_HCCForeColor          @"HCCForeColor"
#define k_key_HCCSampleText         @"HCCSampleText"
#define k_key_HCCForeComboBoxData       @"HCCForeComboBoxData"
#define k_key_HCCBackComboBoxData       @"HCCBackComboBoxData"
#define k_key_foreColorCBoxIsOk         @"foreColorCBoxIsOk"
#define k_key_backgroundColorCBoxIsOk   @"backgroundColorCBoxIsOk"
#define k_key_insertCustomTextArray     @"insertCustomTextArray"
#define k_key_insertCustomText          @"insertCustomText"
//------ 以下、隠し設定 ------
//（隠し設定の値は CEAppController の initialize で設定している）
#define k_key_statusBarFontName    @"statusAreaFontName"
#define k_key_statusBarFontSize    @"statusAreaFontSize"
#define k_key_lineNumFontName       @"lineNumFontName"
#define k_key_lineNumFontSize       @"lineNumFontSize"
#define k_key_lineNumFontColor      @"lineNumFontColor"
#define k_key_basicColoringDelay    @"basicColoringDelay"
#define k_key_firstColoringDelay    @"firstColoringDelay"
#define k_key_secondColoringDelay   @"secondColoringDelay"
#define k_key_lineNumUpdateInterval @"lineNumUpdateInterval"
#define k_key_infoUpdateInterval    @"infoUpdateInterval"
#define k_key_incompatibleCharInterval  @"incompatibleCharInterval"
#define k_key_outlineMenuInterval   @"outlineMenuInterval"
#define k_key_navigationBarFontName @"navigationBarFontName"
#define k_key_navigationBarFontSize @"navigationBarFontSize"
#define k_key_outlineMenuMaxLength  @"outlineMenuMaxLength"
#define k_key_headerFooterFontName  @"headerFooterFontName"
#define k_key_headerFooterFontSize  @"headerFooterFontSize"
#define k_key_headerFooterDateTimeFormat    @"headerFooterDateTimeFormat"
#define k_key_headerFooterPathAbbreviatingWithTilde @"headerFooterPathAbbreviatingWithTilde"
#define k_key_textContainerInsetWidth       @"textContainerInsetWidth"
#define k_key_textContainerInsetHeightTop       @"textContainerInsetHeightTop"
#define k_key_textContainerInsetHeightBottom    @"textContainerInsetHeightBottom"
#define k_key_showColoringIndicatorTextLength   @"showColoringIndicatorTextLength"
#define k_key_runAppleScriptInLaunching     @"runAppleScriptInLaunching"
#define k_key_showAlertForNotWritable       @"showAlertForNotWritable"
#define k_key_notifyEditByAnother       @"notifyEditByAnother"


// transparencyController
#define k_key_curWindowAlpha    @"curWindowAlpha"
#define k_key_curAlphaOnlyTextView  @"curAlphaOnlyTextView"

// Tab width values
#define k_tabWidthMin   1
#define k_tabWidthMax   99

// Page guide column values
#define k_pageGuideColumnMin    1
#define k_pageGuideColumnMax    1000

// custom line spacing values
#define k_lineSpacingMin    0.0
#define k_lineSpacingMax    10.0

// syntax coloring
#define k_ESCheckLength     16
#define k_QCPosition        @"QCPosition"
#define k_QCPairKind        @"QCPairKind"
#define k_notUseKind            0
#define k_QC_SingleQ            1
#define k_QC_DoubleQ            2
#define k_QC_CommentBaseNum     100
#define k_QCStartEnd        @"QCStartEnd"
#define k_notUseStartEnd        0
#define k_QC_Start              1
#define k_QC_End                2
#define k_QCStrLength       @"QCStrLength"
#define k_allAlphabetChars  @"abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ"

// syntax coloring indicator
#define k_perCompoIncrement     80.0
#define k_minIncrement          3.4

// syntax coloring color
#define k_key_textColor         @"textColor"
#define k_key_backgroundColor   @"backgroundColor"
#define k_key_insertionPointColor   @"insertionPointColor"
#define k_key_selectionColor    @"selectionColor"
#define k_key_highlightLineColor    @"highlightLineColor"
#define k_key_keywordsColor     @"keywordsColor"
#define k_key_commandsColor     @"commandsColor"
#define k_key_numbersColor      @"numbersColor"
#define k_key_valuesColor       @"valuesColor"
#define k_key_stringsColor      @"stringsColor"
#define k_key_charactersColor   @"charactersColor"
#define k_key_commentsColor     @"commentsColor"
#define k_key_allSyntaxColors   k_key_keywordsColor, k_key_commandsColor, k_key_valuesColor, k_key_numbersColor, k_key_stringsColor, k_key_charactersColor, k_key_commentsColor

// syntax style
#define k_SCKey_styleName   @"styleName"
#define k_SCKey_extensions  @"extensions"
#define k_SCKey_ignoreCase  @"ignoreCase"
#define k_SCKey_regularExpression   @"regularExpression"
#define k_SCKey_arrayKeyString  @"keyString"
#define k_SCKey_beginString     @"beginString"
#define k_SCKey_endString       @"endString"
#define k_SCKey_bold            @"bold"
#define k_SCKey_underline       @"underline"
#define k_SCKey_italic          @"italic"
#define k_SCKey_numOfObjInArray @"numOfObjInArray"
#define k_SCKey_keywordsArray   @"keywordsArray"
#define k_SCKey_commandsArray   @"commandsArray"
#define k_SCKey_valuesArray     @"valuesArray"
#define k_SCKey_numbersArray    @"numbersArray"
#define k_SCKey_stringsArray    @"stringsArray"
#define k_SCKey_charactersArray @"charactersArray"
#define k_SCKey_commentsArray   @"commentsArray"
#define k_SCKey_outlineMenuArray    @"outlineMenuArray"
#define k_SCKey_completionsArray    @"completionsArray"
#define k_SCKey_allColoringArrays   k_SCKey_keywordsArray, k_SCKey_commandsArray, k_SCKey_valuesArray, k_SCKey_numbersArray, k_SCKey_stringsArray, k_SCKey_charactersArray, k_SCKey_commentsArray
#define k_SCKey_syntaxCheckArrays   k_SCKey_allColoringArrays, k_SCKey_outlineMenuArray
#define k_SCKey_allArrays           k_SCKey_syntaxCheckArrays, k_SCKey_completionsArray

// edit argument dictionary's key
#define k_key_oldStyleName       @"oldStyleName"
#define k_key_newStyleName       @"newStyleName"


// Default bundle SyntaxStyle files name prefix
#define k_bundleSyntaxStyleFilePrefix    @"defaultSyntaxStyle_"


// Main Menu index and tag
#define k_applicationMenuIndex  0
#define k_fileMenuIndex     1
#define k_editMenuIndex     2
#define k_viewMenuIndex     3
#define k_formatMenuIndex   4
#define k_findMenuIndex     5
#define k_utilityMenuIndex  6
#define k_scriptMenuIndex   8
#define k_newMenuItemTag            100
#define k_openMenuItemTag           101
#define k_openHiddenMenuItemTag     102
#define k_openRecentMenuItemTag     103
#define k_BSMenuItemTag             209
#define k_showInvisibleCharMenuItemTag      304
#define k_fileEncodingMenuItemTag   4001
#define k_syntaxMenuItemTag         4002
#define k_servicesMenuItemTag       999 // Menu KeyBindings Setting でリストアップしないための定数
#define k_windowPanelsMenuItemTag   7999 // Menu KeyBindings Setting でリストアップしないための定数
#define k_scriptMenuDirectoryTag    8999 // Menu KeyBindings Setting でリストアップしないための定数

// Contextual Menu tag
#define k_noMenuItem        -1
#define k_utilityMenuTag    600
#define k_scriptMenuTag     800

// Help Document Menu tag and path
static struct {
    int tag;
    NSString *path;
} k_bundleDocumentList[] = {
    {100, @"/GPL.txt"},
    {101, @"/OgreKit License.txt"},
    {200, @"/EN/ReadMe-en.rtf"},
    {201, @"/EN/History-en.rtf"},
    {202, @"/EN/Known_problems-en.rtf"},
    {300, @"/JP/ReadMe-jp.rtf"},
    {301, @"/JP/History-jp.rtf"},
    {302, @"/JP/Known_problems-jp.rtf"},
    {303, @"/JP/To_ATOK_Users-jp.rtf"},
    {304, @"/JP/To_0.7.x_Users-jp.rtf"},
    {0, nil}
};

// Goto window object index
#define k_gotoCharacterIndex    0
#define k_gotoLineIndex         1


// CEEditorView and subView's dict key
#define k_invocationAfterAlert      @"invocationAfterAlert"
#define k_argsArrayAfterAlert       @"argsArrayAfterAlert"
#define k_outlineMenuItemRange      @"outlineMenuItemRange"
#define k_outlineMenuItemTitle      @"outlineMenuItemTitle"
#define k_outlineMenuItemSortKey    @"outlineMenuItemSortKey"
#define k_outlineMenuItemFontBold   @"outlineMenuItemFontBold"
#define k_outlineMenuItemFontItalic @"outlineMenuItemFontItalic"
#define k_outlineMenuItemUnderlineMask   @"outlineMenuItemUnderlineMask"


// CEEditorView and subView's constants
#define k_defaultLineNumWidth       32.0
#define k_lineNumPadding            2.0
#define k_statusBarHeight           20.0
#define k_statusBarRightPadding     10.0
#define k_statusBarReadOnlyWidth    k_defaultLineNumWidth
#define k_lineNumFontDescender      -2.1
#define k_navigationBarHeight       16.0
#define k_outlineMenuLeftMargin     70.0
#define k_outlineMenuWidth          300.0
#define k_outlineButtonWidth        20.0
#define k_splitDividerThickness     7.0
#define k_outlineMenuSeparatorSymbol    @"-"


// CEATSTypeSetter (Layouting)
#define k_defaultLineHeightMultiple     1.19


// Print settings
#define k_printTextHorizontalMargin     8.0    // テキスト用の左右のマージン
#define k_printHFHorizontalMargin      34.0    // ヘッダ／フッタ用の左右のマージン
#define k_printHFVerticalMargin        34.0    // ヘッダ／フッタ用の上下のマージン
#define k_headerFooterLineHeight    15.0
#define k_separatorPadding      8.0
#define k_noSeparatorPadding    18.0


// CEWindowController
// Drawer identifier
#define k_infoIdentifier            @"info"
#define k_incompatibleIdentifier    @"incompatibleChar"
// listController key
#define k_listLineNumber        @"lineNumber"
#define k_incompatibleRange     @"incompatibleRange"
#define k_incompatibleChar      @"incompatibleChar"
#define k_convertedChar         @"convertedChar"


// CEHCCManager
#define k_exportForeColorButtonTag      1000
#define k_exportBGColorButtonTag        2000
#define k_optionViewHeight              250.0
#define k_addCodeToForeButtonTag        1001
#define k_addCodeToBackButtonTag        2001
#define k_HCCDataControllerKey      @"codeString"


// CEPreferences
// tab title (toolbarItem) identifier
#define k_prefWindowToolbarID   @"prefWindowToolbarID"
#define k_prefGeneralItemID     @"prefGeneralItemID"
#define k_prefWindowItemID      @"prefWindowItemID"
#define k_prefViewItemID        @"prefViewItemID"
#define k_prefFormatItemID      @"prefFormatItemID"
#define k_prefSyntaxItemID      @"prefSyntaxItemID"
#define k_prefFileDropItemID    @"prefFileDropItemID"
#define k_prefKeyBindingsItemID @"prefKeyBindingsItemID"
#define k_prefPrintItemID       @"prefPrintItemID"

// Help anchors
#define k_helpPrefAnchors       @"pref_general", @"pref_window", @"pref_appearance", @"pref_format", @"pref_syntax", @"pref_filedrop", @"pref_keybinding", @"pref_print"

// tab item view tag
#define k_prefTabItemViewTag    3000

// button
#define k_okButtonTag       100
#define k_syntaxCopyTag     -100
#define k_syntaxNewTag      -200
#define k_syntaxDeleteTag   -1000
#define k_syntaxImportTag   -1001
#define k_syntaxNoSheetTag  0

// min & max window size
#define k_minWindowSize 100.0
#define k_maxWindowSize 10000.0

// Encoding list edit
#define k_dropMyselfPboardType  @"dropMyself"
#define k_lastRow   -1

// Line Endings
#define k_lineEndingNames   @"LF", @"CR", @"CR/LF"


// ScriptMenuManager
// outputType values
#define k_noOutput              0
#define k_replaceSelection      1
#define k_replaceAllText        2
#define k_insertAfterSelection  3
#define k_appendToAllText       4
#define k_pasteboard        5


// Notification name
#define k_documentDidFinishOpenNotification     @"documentDidFinishOpenNotification"
#define k_setKeyCatchModeToCatchMenuShortcut    @"setKeyCatchModeToCatchMenuShortcut"
#define k_catchMenuShortcutNotification         @"catchMenuShortcutNotification"

// Application & KeyBindingManager
// key catch mode
#define k_keyDownNoCatch        0
#define k_catchMenuShortcut     1

// info dictionary key
#define k_keyCatchMode          @"keyCatchMode"
#define k_keyBindingModFlags    @"keyBindingModFlags"
#define k_keyBindingChar        @"keyBindingChar"

// KeyBindingManager
// outlineView data mode
#define k_outlineViewModeMenu   0
#define k_outlineViewModeText   1

// outlineView data key, column identifier
#define k_title             @"title"
#define k_children          @"children"
#define k_keyBindingKey     @"keyBindingKey"
#define k_selectorString    @"selectorString"

// Toolbar item identifier
#define k_docWindowToolbarID    @"docWindowToolbarID"
#define k_getInfoItemID         @"searchFieldItemID"
#define k_showIncompatibleCharItemID    @"showIncompatibleCharItemID"
#define k_preferencesItemID     @"preferencesItemID"
#define k_saveItemID            @"saveItemID"
#define k_saveAsItemID          @"saveAsItemID"
#define k_pageSetupItemID       @"pageSetupItemID"
#define k_openTransparencyPanelItemID  @"openTransparencyPanelItemID"
#define k_biggerFontItemID      @"biggerFontItemID"
#define k_smallerFontItemID     @"smallerFontItemID"
#define k_shiftLeftItemID       @"shiftLeftItemID"
#define k_shiftRightItemID      @"shiftRightItemID"
#define k_showNavigationBarItemID   @"showNavigationBarItemID"
#define k_showLineNumItemID     @"showLineNumItemID"
#define k_showStatusBarItemID   @"showStatusAreaItemID"
#define k_showInvisibleCharsItemID  @"showInvisibleCharsItemID"
#define k_showPageGuideItemID   @"showPageGuideItemID"
#define k_wrapLinesItemID       @"wrapLinesItemID"
#define k_lineEndingsItemID     @"lineEndingsItemID"
#define k_fileEncodingsItemID   @"fileEncodingsItemID"
#define k_syntaxItemID          @"syntaxColoringItemID"
#define k_syntaxReColorAllItemID  @"syntaxReColorAllItemID"
#define k_editHexAsForeItemID   @"editHexAsForeItemID"
#define k_editHexAsBGItemID     @"editHexAsBGItemID"


// Encodings
// Encoding menu
#define k_autoDetectEncodingMenuTag 0

static CFStringEncodings k_CFStringEncodingList[] = {
    kCFStringEncodingShiftJIS, // Japanese (Shift JIS)
    kCFStringEncodingEUC_JP, // Japanese (EUC)
    kCFStringEncodingInvalidId, // ----------

    kCFStringEncodingUTF8, // Unicode (UTF-8)
    kCFStringEncodingInvalidId, // ----------

    kCFStringEncodingDOSJapanese, // Japanese (Windows, DOS)
    kCFStringEncodingShiftJIS_X0213_00, // Japanese (Shift JIS X0213)
    kCFStringEncodingMacJapanese, // Japanese (Mac OS)
    kCFStringEncodingISO_2022_JP, // Japanese (ISO 2022-JP)
    kCFStringEncodingInvalidId, // ----------

    kCFStringEncodingUnicode, // Unicode (UTF-16), kCFStringEncodingUTF16(in 10.4)
    kCFStringEncodingInvalidId, // ----------

    kCFStringEncodingMacRoman, // Western (Mac OS Roman)
    kCFStringEncodingWindowsLatin1, // Western (Windows Latin 1)
    kCFStringEncodingInvalidId, // ----------

    kCFStringEncodingMacChineseTrad, // Traditional Chinese (Mac OS)
    kCFStringEncodingMacChineseSimp, // Simplified Chinese (Mac OS)
    kCFStringEncodingEUC_TW,  // Traditional Chinese (EUC)
    kCFStringEncodingEUC_CN,  // Simplified Chinese (EUC)
    kCFStringEncodingDOSChineseTrad,  // Traditional Chinese (Windows, DOS)
    kCFStringEncodingDOSChineseSimplif,  // Simplified Chinese (Windows, DOS)
    kCFStringEncodingInvalidId, // ----------

    kCFStringEncodingMacKorean, // Korean (Mac OS)
    kCFStringEncodingEUC_KR,  // Korean (EUC)
    kCFStringEncodingDOSKorean,  // Korean (Windows, DOS)
    kCFStringEncodingInvalidId, // ----------

    kCFStringEncodingMacArabic, // Arabic (Mac OS)
    kCFStringEncodingMacHebrew, // Hebrew (Mac OS)
    kCFStringEncodingMacGreek, // Greek (Mac OS)
    kCFStringEncodingISOLatinGreek, // Greek (ISO 8859-7)
    kCFStringEncodingMacCyrillic, // Cyrillic (Mac OS)
    kCFStringEncodingISOLatinCyrillic, // Cyrillic (ISO 8859-5)
    kCFStringEncodingMacCentralEurRoman, // Central European (Mac OS)
    kCFStringEncodingMacTurkish, // Turkish (Mac OS)
    kCFStringEncodingMacIcelandic, // Icelandic (Mac OS)
    kCFStringEncodingInvalidId, // ----------

    kCFStringEncodingISOLatin1, // Western (ISO Latin 1)
    kCFStringEncodingISOLatin2, // Central European (ISO Latin 2)
    kCFStringEncodingISOLatin3, // Western (ISO Latin 3)
    kCFStringEncodingISOLatin4, // Central European (ISO Latin 4)
    kCFStringEncodingISOLatin5, // Turkish (ISO Latin 5)
    kCFStringEncodingDOSLatinUS, // Latin-US (DOS)
    kCFStringEncodingWindowsLatin2, // Central European (Windows Latin 2)
    kCFStringEncodingNextStepLatin, // Western (NextStep)
    kCFStringEncodingNonLossyASCII, // Non-lossy ASCII
};

// Encodings available 10.4 and later (CotEditor added in 0.8.0)
static CFStringEncodings k_CFStringEncoding10_4List[] = {
    0x10000100, // kCFStringEncodingUTF16BE
    0x14000100, // kCFStringEncodingUTF16LE
    0x0c000100, // kCFStringEncodingUTF32
    0x18000100, // kCFStringEncodingUTF32BE
    0x1c000100, // kCFStringEncodingUTF32LE
};

// Encodings to convert Yen mark to back-slash
static CFStringEncodings k_CFStringEncodingInvalidYenList[] = {
    kCFStringEncodingDOSJapanese, // Japanese (Windows, DOS) 
    kCFStringEncodingEUC_JP,  // Japanese (EUC)
    kCFStringEncodingEUC_TW,  // Traditional Chinese (EUC)
    kCFStringEncodingEUC_CN,  // Simplified Chinese (EUC)
    kCFStringEncodingEUC_KR,  // Korean (EUC)
    kCFStringEncodingDOSKorean,  // Korean (Windows, DOS)
    kCFStringEncodingMacArabic, // Arabic (Mac OS)
    kCFStringEncodingMacHebrew, // Hebrew (Mac OS)
    kCFStringEncodingISOLatinGreek, // Greek (ISO 8859-7)
    kCFStringEncodingMacCyrillic, // Cyrillic (Mac OS)
    kCFStringEncodingISOLatinCyrillic, // Cyrillic (ISO 8859-5)
    kCFStringEncodingMacCentralEurRoman, // Central European (Mac OS)
    kCFStringEncodingISOLatin2, // Central European (ISO Latin 2)
    kCFStringEncodingISOLatin3, // Western (ISO Latin 3)
    kCFStringEncodingISOLatin4, // Central European (ISO Latin 4)
    kCFStringEncodingDOSLatinUS, // Latin-US (DOS)
    kCFStringEncodingWindowsLatin2, // Central European (Windows Latin 2)
};

static unichar k_yenMark = {0x00A5};

static unichar k_invisibleSpaceCharList[] = {0x00B7, 0x00B0, 0x02D0, 0x2423};
static unichar k_invisibleTabCharList[] = {0x00AC, 0x21E5, 0x2023, 0x25B9};
static unichar k_invisibleNewLineCharList[] = {0x00B6, 0x21A9, 0x21B5, 0x23CE};
static unichar k_invisibleFullwidthSpaceCharList[] = {0x25A1, 0x22A0, 0x25A0, 0x2022};

static unsigned int k_modifierKeysList[] = 
            {NSControlKeyMask, NSAlternateKeyMask, NSShiftKeyMask, NSCommandKeyMask};
static unichar k_keySpecCharList[] = {0x005E, 0x007E, 0x0024, 0x0040}; // == "^~$@"
static unichar k_readableKeyStringsList[] = {0x005E, 0x2325, 0x21E7, 0x2318};

static unichar k_noPrintableKeyList[] = {
            NSUpArrowFunctionKey,
            NSDownArrowFunctionKey,
            NSLeftArrowFunctionKey,
            NSRightArrowFunctionKey,
            NSF1FunctionKey,
            NSF2FunctionKey,
            NSF3FunctionKey,
            NSF4FunctionKey,
            NSF5FunctionKey,
            NSF6FunctionKey,
            NSF7FunctionKey,
            NSF8FunctionKey,
            NSF9FunctionKey,
            NSF10FunctionKey,
            NSF11FunctionKey,
            NSF12FunctionKey,
            NSF13FunctionKey,
            NSF14FunctionKey,
            NSF15FunctionKey,
            NSF16FunctionKey,
            NSDeleteCharacter, // NSDeleteFunctionKey は使わない
            NSHomeFunctionKey,
            NSEndFunctionKey,
            NSPageUpFunctionKey,
            NSPageDownFunctionKey,
            NSClearLineFunctionKey,
            NSHelpFunctionKey,
            ' ', // = Space
            '\t', // = Tab
            '\r', // = Return
            '\b', // = Backspace, (delete backword)
            '\003', // = Enter
            '\031', // = Backtab
            '\033', // = Escape
};

static unichar k_braceCharList[] = {0x0028, 0x005B, 0x007B, 0x003C}; // == ([{<

