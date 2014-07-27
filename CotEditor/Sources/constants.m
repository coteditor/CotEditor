/*
 =================================================
 constants
 (for CotEditor)
 
 Copyright (C) 2004-2007 nakamuxu.
 Copyright (C) 2011, 2014 CotEditor Project
 http://coteditor.github.io
 =================================================
 
 encoding="UTF-8"
 Created:20014-04-20
 
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

#import "constants.h"


#pragma mark General

// ------------------------------------------------------
// General
// ------------------------------------------------------

// separator
NSString *const CESeparatorString = @"-";

// Error domain
NSString *const CEErrorDomain = @"com.aynimac.CotEditor.ErrorDomain";

// Localized Strings Table
NSString *const k_printLocalizeTable =  @"print";

// Notification name
NSString *const CEEncodingListDidUpdateNotification = @"CESyntaxListDidUpdateNotification";
NSString *const CEDocumentDidFinishOpenNotification = @"documentDidFinishOpenNotification";
NSString *const CESetKeyCatchModeToCatchMenuShortcutNotification = @"setKeyCatchModeToCatchMenuShortcut";
NSString *const CECatchMenuShortcutNotification = @"catchMenuShortcutNotification";

// Notification userInfo keys
NSString *const CEOldNameKey = @"CEOldNameKey";
NSString *const CENewNameKey = @"CENewNameKey";



#pragma mark User Defaults Keys

// ------------------------------------------------------
// User Defaults Keys
// ------------------------------------------------------

// user defaults
NSString *const k_key_layoutTextVertical = @"layoutTextVertical";
NSString *const k_key_splitViewVertical = @"splitViewVertical";
NSString *const k_key_showLineNumbers = @"showLineNumbers";
NSString *const k_key_showStatusBar = @"showStatusArea";
NSString *const k_key_showStatusBarLines = @"showStatusBarLines";
NSString *const k_key_showStatusBarLength = @"showStatusBarLength";
NSString *const k_key_showStatusBarChars = @"showStatusBarChars";
NSString *const k_key_showStatusBarWords = @"showStatusBarWords";
NSString *const k_key_showStatusBarLocation = @"showStatusBarLocation";
NSString *const k_key_showStatusBarLine = @"showStatusBarLine";
NSString *const k_key_showStatusBarColumn = @"showStatusBarColumn";
NSString *const k_key_showStatusBarEncoding = @"showStatusBarEncoding";
NSString *const k_key_showStatusBarLineEndings = @"showStatusBarLineEndings";
NSString *const k_key_showStatusBarFileSize = @"showStatusBarFileSize";
NSString *const k_key_countLineEndingAsChar = @"countLineEndingAsChar";
NSString *const k_key_syncFindPboard = @"syncFindPboard";
NSString *const k_key_inlineContextualScriptMenu = @"inlineContextualScriptMenu";
NSString *const k_key_appendExtensionAtSaving = @"appendExtensionAtSaving";
NSString *const k_key_showNavigationBar = @"showNavigationBar";
NSString *const k_key_wrapLines = @"wrapLines";
NSString *const k_key_defaultEncodingCode = @"defaultEncoding";
NSString *const k_key_defaultLineEndCharCode = @"defaultLineEndCharCode";
NSString *const k_key_encodingList = @"encodingList";
NSString *const k_key_fontName = @"fontName";
NSString *const k_key_fontSize = @"fontSize";
NSString *const k_key_encodingInOpen = @"encodingInOpen";
NSString *const k_key_encodingInNew = @"encodingInNew";
NSString *const k_key_referToEncodingTag = @"referToEncodingTag";
NSString *const k_key_createNewAtStartup = @"createNewAtStartup";
NSString *const k_key_reopenBlankWindow = @"reopenBlankWindow";
NSString *const k_key_checkSpellingAsType = @"checkSpellingAsType";
NSString *const k_key_windowWidth = @"windowWidth";
NSString *const k_key_windowHeight = @"windowHeight";
NSString *const k_key_autoExpandTab = @"autoExpandTab";
NSString *const k_key_tabWidth = @"tabWidth";
NSString *const k_key_windowAlpha = @"windowAlpha";
NSString *const k_key_autoIndent = @"autoIndent";
NSString *const k_key_invisibleCharactersColor = @"invisibleCharactersColor";
NSString *const k_key_showInvisibleSpace = @"showInvisibleSpace";
NSString *const k_key_invisibleSpace = @"invisibleSpace";
NSString *const k_key_showInvisibleTab = @"showInvisibleTab";
NSString *const k_key_invisibleTab = @"invisibleTab";
NSString *const k_key_showInvisibleNewLine = @"showInvisibleNewLine";
NSString *const k_key_invisibleNewLine = @"invisibleNewLine";
NSString *const k_key_showInvisibleFullwidthSpace = @"showInvisibleZenkakuSpace";
NSString *const k_key_invisibleFullwidthSpace = @"invisibleZenkakuSpace";
NSString *const k_key_showOtherInvisibleChars = @"showOtherInvisibleChars";
NSString *const k_key_highlightCurrentLine = @"highlightCurrentLine";
NSString *const k_key_doColoring = @"doSyntaxColoring";
NSString *const k_key_defaultColoringStyleName = @"defaultColoringStyleName";
NSString *const k_key_defaultTheme = @"defaultTheme";
NSString *const k_key_delayColoring = @"delayColoring";
NSString *const k_key_fileDropArray = @"fileDropArray";
NSString *const k_key_fileDropExtensions = @"extensions";
NSString *const k_key_fileDropFormatString = @"formatString";
NSString *const k_key_NSDragAndDropTextDelay = @"NSDragAndDropTextDelay";
NSString *const k_key_smartInsertAndDelete = @"smartInsertAndDelete";
NSString *const k_key_shouldAntialias = @"shouldAntialias";
NSString *const k_key_autoComplete = @"autoComplete";
NSString *const k_key_completeAddStandardWords = @"completeAddStandardWords";
NSString *const k_key_showPageGuide = @"showPageGuide";
NSString *const k_key_pageGuideColumn = @"pageGuideColumn";
NSString *const k_key_lineSpacing = @"lineSpacing";
NSString *const k_key_swapYenAndBackSlashKey = @"swapYenAndBackSlashKey";
NSString *const k_key_fixLineHeight = @"fixLineHeight";
NSString *const k_key_highlightBraces = @"highlightBraces";
NSString *const k_key_highlightLtGt = @"highlightLtGt";
NSString *const k_key_saveUTF8BOM = @"saveUTF8BOM";
NSString *const k_key_enableSmartQuotes = @"enableSmartQuotes";
NSString *const k_key_enableSmartIndent = @"enableSmartIndent";
NSString *const k_key_appendsCommentSpacer = @"appendsCommentSpacer";
NSString *const k_key_commentsAtLineHead = @"commentsAtLineHead";

// print settings
NSString *const k_key_setPrintFont = @"setPrintFont";
NSString *const k_key_printFontName = @"printFontName";
NSString *const k_key_printFontSize = @"printFontSize";
NSString *const k_key_printTheme = @"printTheme";
NSString *const k_key_printHeader = @"printHeader";
NSString *const k_key_headerOneStringIndex = @"headerOneStringIndex";
NSString *const k_key_headerTwoStringIndex = @"headerTwoStringIndex";
NSString *const k_key_headerOneAlignIndex = @"headerOneAlignIndex";
NSString *const k_key_headerTwoAlignIndex = @"headerTwoAlignIndex";
NSString *const k_key_printHeaderSeparator = @"printHeaderSeparator";
NSString *const k_key_printFooter = @"printFooter";
NSString *const k_key_footerOneStringIndex = @"footerOneStringIndex";
NSString *const k_key_footerTwoStringIndex = @"footerTwoStringIndex";
NSString *const k_key_footerOneAlignIndex = @"footerOneAlignIndex";
NSString *const k_key_footerTwoAlignIndex = @"footerTwoAlignIndex";
NSString *const k_key_printFooterSeparator = @"printFooterSeparator";
NSString *const k_key_printLineNumIndex = @"printLineNumIndex";
NSString *const k_key_printInvisibleCharIndex = @"printInvisibleCharIndex";
NSString *const k_key_printColorIndex = @"printColorIndex";

// settings that are not in preferences
NSString *const k_key_insertCustomTextArray = @"insertCustomTextArray";
NSString *const k_key_insertCustomText = @"insertCustomText";
NSString *const k_key_colorCodeType = @"colorCodeType";

// hidden settings
NSString *const k_key_lineNumFontName = @"lineNumFontName";
NSString *const k_key_lineNumFontColor = @"lineNumFontColor";
NSString *const k_key_basicColoringDelay = @"basicColoringDelay";
NSString *const k_key_firstColoringDelay = @"firstColoringDelay";
NSString *const k_key_secondColoringDelay = @"secondColoringDelay";
NSString *const k_key_autoCompletionDelay = @"autoCompletionDelay";
NSString *const k_key_lineNumUpdateInterval = @"lineNumUpdateInterval";
NSString *const k_key_infoUpdateInterval = @"infoUpdateInterval";
NSString *const k_key_incompatibleCharInterval = @"incompatibleCharInterval";
NSString *const k_key_outlineMenuInterval = @"outlineMenuInterval";
NSString *const k_key_navigationBarFontName = @"navigationBarFontName";
NSString *const k_key_outlineMenuMaxLength = @"outlineMenuMaxLength";
NSString *const k_key_headerFooterFontName = @"headerFooterFontName";
NSString *const k_key_headerFooterFontSize = @"headerFooterFontSize";
NSString *const k_key_headerFooterDateTimeFormat = @"headerFooterDateTimeFormat";
NSString *const k_key_headerFooterPathAbbreviatingWithTilde = @"headerFooterPathAbbreviatingWithTilde";
NSString *const k_key_textContainerInsetWidth = @"textContainerInsetWidth";
NSString *const k_key_textContainerInsetHeightTop = @"textContainerInsetHeightTop";
NSString *const k_key_textContainerInsetHeightBottom = @"textContainerInsetHeightBottom";
NSString *const k_key_showColoringIndicatorTextLength = @"showColoringIndicatorTextLength";
NSString *const k_key_runAppleScriptInLaunching = @"runAppleScriptInLaunching";
NSString *const k_key_showAlertForNotWritable = @"showAlertForNotWritable";
NSString *const k_key_notifyEditByAnother = @"notifyEditByAnother";
NSString *const k_key_coloringRangeBufferLength = @"coloringRangeBufferLength";



#pragma mark Setting Values

// ------------------------------------------------------
// Setting Values
// ------------------------------------------------------

// Page guide column values
NSUInteger const k_pageGuideColumnMin =    1;
NSUInteger const k_pageGuideColumnMax = 1000;



#pragma mark Syntax

// ------------------------------------------------------
// Syntax
// ------------------------------------------------------

// syntax coloring
NSUInteger const k_ESCheckLength = 16;
NSString  *const k_allAlphabetChars = @"abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789_";

// syntax style
NSString *const k_SCKey_styleName = @"styleName";
NSString *const k_SCKey_extensions = @"extensions";
NSString *const k_SCKey_filenames = @"filenames";
NSString *const k_SCKey_ignoreCase = @"ignoreCase";
NSString *const k_SCKey_regularExpression = @"regularExpression";
NSString *const k_SCKey_arrayKeyString = @"keyString";
NSString *const k_SCKey_beginString = @"beginString";
NSString *const k_SCKey_endString = @"endString";
NSString *const k_SCKey_inlineComment = @"inlineDelimiter";
NSString *const k_SCKey_beginComment = @"beginDelimiter";
NSString *const k_SCKey_endComment = @"endDelimiter";
NSString *const k_SCKey_bold = @"bold";
NSString *const k_SCKey_underline = @"underline";
NSString *const k_SCKey_italic = @"italic";
NSString *const k_SCKey_numOfObjInArray = @"numOfObjInArray";
NSString *const k_SCKey_keywordsArray = @"keywordsArray";
NSString *const k_SCKey_commandsArray = @"commandsArray";
NSString *const k_SCKey_typesArray = @"typesArray";
NSString *const k_SCKey_attributesArray = @"attributesArray";
NSString *const k_SCKey_variablesArray = @"variablesArray";
NSString *const k_SCKey_valuesArray = @"valuesArray";
NSString *const k_SCKey_numbersArray = @"numbersArray";
NSString *const k_SCKey_stringsArray = @"stringsArray";
NSString *const k_SCKey_charactersArray = @"charactersArray";
NSString *const k_SCKey_commentsArray = @"commentsArray";
NSString *const k_SCKey_commentDelimitersDict = @"commentDelimiters";
NSString *const k_SCKey_outlineMenuArray = @"outlineMenuArray";
NSString *const k_SCKey_completionsArray = @"completionsArray";
NSString *const k_SCKey_allColoringArrays[] = {
    @"keywordsArray",
    @"commandsArray",
    @"typesArray",
    @"attributesArray",
    @"variablesArray",
    @"valuesArray",
    @"numbersArray",
    @"stringsArray",
    @"charactersArray",
    @"commentsArray"
};
NSUInteger const k_size_of_allColoringArrays = sizeof(k_SCKey_allColoringArrays)/sizeof(k_SCKey_allColoringArrays[0]);



#pragma mark Main Menu

// ------------------------------------------------------
// Main Menu
// ------------------------------------------------------

// Main Menu index and tag
NSInteger const k_applicationMenuIndex = 0;
NSInteger const k_fileMenuIndex = 1;
NSInteger const k_editMenuIndex = 2;
NSInteger const k_viewMenuIndex = 3;
NSInteger const k_formatMenuIndex = 4;
NSInteger const k_findMenuIndex = 5;
NSInteger const k_utilityMenuIndex = 6;
NSInteger const k_scriptMenuIndex = 8;
NSInteger const k_newMenuItemTag = 100;
NSInteger const k_openMenuItemTag = 101;
NSInteger const k_openHiddenMenuItemTag = 102;
NSInteger const k_openRecentMenuItemTag = 103;
NSInteger const k_BSMenuItemTag = 209;
NSInteger const k_fileEncodingMenuItemTag = 4001;
NSInteger const k_syntaxMenuItemTag = 4002;
NSInteger const k_themeMenuItemTag = 4003;
NSInteger const k_servicesMenuItemTag = 999;
NSInteger const k_windowPanelsMenuItemTag = 7999;
NSInteger const k_scriptMenuDirectoryTag = 8999;

// Contextual Menu tag
NSInteger const k_noMenuItem = -1;
NSInteger const k_utilityMenuTag = 600;
NSInteger const k_scriptMenuTag = 800;

// Help Document Menu tag and path
NSString *const k_bundleDocumentTags[] = {
    @"Version History",
    @"Acknowledgements",
    @"ScriptMenu Folder",
    @"AppleScript",
    @"ShellScript"
};

// distribution web site
NSString *const k_webSiteURL = @"http://coteditor.github.io";
NSString *const k_issueTrackerURL = @"https://github.com/coteditor/CotEditor/issues";



#pragma mark CEEditorView

// ------------------------------------------------------
// CEEditorView
// ------------------------------------------------------

// CEEditorView and subView's dict key
NSString *const k_outlineMenuItemRange = @"outlineMenuItemRange";
NSString *const k_outlineMenuItemTitle = @"outlineMenuItemTitle";
NSString *const k_outlineMenuItemSortKey = @"outlineMenuItemSortKey";
NSString *const k_outlineMenuItemFontBold = @"outlineMenuItemFontBold";
NSString *const k_outlineMenuItemFontItalic = @"outlineMenuItemFontItalic";
NSString *const k_outlineMenuItemUnderlineMask = @"outlineMenuItemUnderlineMask";


// CEEditorView and subView's constants
CGFloat const k_defaultLineNumWidth = 32.0;
CGFloat const k_lineNumPadding = 2.0;
CGFloat const k_lineNumFontDescender = -2.1;
NSString *const k_navigationBarFontName = @"Helvetica";



#pragma mark CEATSTypeSetter

// ------------------------------------------------------
// CEATSTypeSetter
// ------------------------------------------------------

// CEATSTypeSetter (Layouting)
CGFloat const k_defaultLineHeightMultiple = 1.19;



#pragma mark Print

// ------------------------------------------------------
// Print
// ------------------------------------------------------

CGFloat const k_printTextHorizontalMargin = 8.0;
CGFloat const k_printHFHorizontalMargin = 34.0;
CGFloat const k_printHFVerticalMargin = 34.0;
CGFloat const k_headerFooterLineHeight = 15.0;
CGFloat const k_separatorPadding = 8.0;
CGFloat const k_noSeparatorPadding = 18.0;



#pragma mark CEWindowController

// ------------------------------------------------------
// CEWindowController
// ------------------------------------------------------

// Drawer identifier
NSString *const k_infoIdentifier = @"info";
NSString *const k_incompatibleIdentifier = @"incompatibleChar";
// listController key
NSString *const k_listLineNumber = @"lineNumber";
NSString *const k_incompatibleRange = @"incompatibleRange";
NSString *const k_incompatibleChar = @"incompatibleChar";
NSString *const k_convertedChar = @"convertedChar";



#pragma mark Preferences

// ------------------------------------------------------
// Preferences
// ------------------------------------------------------

// Help anchors
NSString *const k_helpPrefAnchors[] = {
    @"pref_general",
    @"pref_window",
    @"pref_appearance",
    @"pref_format",
    @"pref_syntax",
    @"pref_filedrop",
    @"pref_keybinding",
    @"pref_print"
};

// button
NSInteger const k_okButtonTag = 100;

// Encoding list edit
NSString *const k_dropMyselfPboardType = @"dropMyself";
NSInteger const k_lastRow = -1;



#pragma mark Document Window

// ------------------------------------------------------
// Document Window
// ------------------------------------------------------

// Line Endings
NSString * const k_lineEndingNames[]=  {
    @"LF",
    @"CR",
    @"CR/LF"
};

// Toolbar item identifier
NSString *const k_docWindowToolbarID = @"docWindowToolbarID";
NSString *const k_getInfoItemID = @"searchFieldItemID";
NSString *const k_showIncompatibleCharItemID = @"showIncompatibleCharItemID";
NSString *const k_biggerFontItemID = @"biggerFontItemID";
NSString *const k_smallerFontItemID = @"smallerFontItemID";
NSString *const k_toggleCommentItemID = @"toggleCommentItemID";
NSString *const k_shiftLeftItemID = @"shiftLeftItemID";
NSString *const k_shiftRightItemID = @"shiftRightItemID";
NSString *const k_autoTabExpandItemID = @"autoTabExpandItemID";
NSString *const k_showNavigationBarItemID = @"showNavigationBarItemID";
NSString *const k_showLineNumItemID = @"showLineNumItemID";
NSString *const k_showStatusBarItemID = @"showStatusAreaItemID";
NSString *const k_showInvisibleCharsItemID = @"showInvisibleCharsItemID";
NSString *const k_showPageGuideItemID = @"showPageGuideItemID";
NSString *const k_wrapLinesItemID = @"wrapLinesItemID";
NSString *const k_lineEndingsItemID = @"lineEndingsItemID";
NSString *const k_fileEncodingsItemID = @"fileEncodingsItemID";
NSString *const k_syntaxItemID = @"syntaxColoringItemID";
NSString *const k_syntaxReColorAllItemID = @"syntaxReColorAllItemID";
NSString *const k_editColorCodeItemID = @"editColorCodeItemID";



#pragma mark KeyBindingManager

// ------------------------------------------------------
// KeyBindingManager
// ------------------------------------------------------

// info dictionary key
NSString *const k_keyCatchMode = @"keyCatchMode";
NSString *const k_keyBindingModFlags = @"keyBindingModFlags";
NSString *const k_keyBindingChar = @"keyBindingChar";

// outlineView data key, column identifier
NSString *const k_title = @"title";
NSString *const k_children = @"children";
NSString *const k_keyBindingKey = @"keyBindingKey";
NSString *const k_selectorString = @"selectorString";



#pragma mark Encodings

// ------------------------------------------------------
// Encodings
// ------------------------------------------------------

// Encoding menu
NSInteger const k_autoDetectEncodingMenuTag = 0;

// Max length to scan encding declaration
NSUInteger const k_maxEncodingScanLength = 2000;


CFStringEncodings const k_CFStringEncodingList[] = {
    kCFStringEncodingUTF8, // Unicode (UTF-8)
    kCFStringEncodingInvalidId, // ----------
    
    kCFStringEncodingShiftJIS, // Japanese (Shift JIS)
    kCFStringEncodingEUC_JP, // Japanese (EUC)
    kCFStringEncodingDOSJapanese, // Japanese (Windows, DOS)
    kCFStringEncodingShiftJIS_X0213, // Japanese (Shift JIS X0213)
    kCFStringEncodingMacJapanese, // Japanese (Mac OS)
    kCFStringEncodingISO_2022_JP, // Japanese (ISO 2022-JP)
    kCFStringEncodingInvalidId, // ----------
    
    kCFStringEncodingUnicode, // Unicode (UTF-16), kCFStringEncodingUTF16(in 10.4)
    kCFStringEncodingInvalidId, // ----------
    
    kCFStringEncodingMacRoman, // Western (Mac OS Roman)
    kCFStringEncodingWindowsLatin1, // Western (Windows Latin 1)
    kCFStringEncodingInvalidId, // ----------
    
    kCFStringEncodingGB_18030_2000,  // Chinese (GB18030)
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
    kCFStringEncodingASCII,  // Western (ASCII)
    kCFStringEncodingNonLossyASCII, // Non-lossy ASCII
    kCFStringEncodingInvalidId, // ----------
    
    // Encodings available 10.4 and later (CotEditor added in 0.8.0)
    kCFStringEncodingUTF16BE, // Unicode (UTF-16BE)
    kCFStringEncodingUTF16LE, // Unicode (UTF-16LE)
    kCFStringEncodingUTF32, // Unicode (UTF-32)
    kCFStringEncodingUTF32BE, // Unicode (UTF-32BE)
    kCFStringEncodingUTF32LE, // Unicode (UTF-16LE)
};
NSUInteger const k_size_of_CFStringEncodingList = sizeof(k_CFStringEncodingList)/sizeof(CFStringEncodings);

// Encodings to convert Yen mark to back-slash
CFStringEncodings const k_CFStringEncodingInvalidYenList[] = {
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
NSUInteger const k_size_of_CFStringEncodingInvalidYenList = sizeof(k_CFStringEncodingInvalidYenList)/sizeof(CFStringEncodings);


unichar const k_yenMark = {0x00A5};

unichar     const k_invisibleSpaceCharList[] = {0x00B7, 0x00B0, 0x02D0, 0x2423};
NSUInteger  const k_size_of_invisibleSpaceCharList = (sizeof(k_invisibleSpaceCharList) / sizeof(unichar));
unichar     const k_invisibleTabCharList[] = {0x00AC, 0x21E5, 0x2023, 0x25B9};
NSUInteger  const k_size_of_invisibleTabCharList = (sizeof(k_invisibleTabCharList) / sizeof(unichar));
unichar     const k_invisibleNewLineCharList[] = {0x00B6, 0x21A9, 0x21B5, 0x23CE};
NSUInteger  const k_size_of_invisibleNewLineCharList = (sizeof(k_invisibleNewLineCharList) / sizeof(unichar));
unichar     const k_invisibleFullwidthSpaceCharList[] = {0x25A1, 0x22A0, 0x25A0, 0x2022};
NSUInteger  const k_size_of_invisibleFullwidthSpaceCharList = (sizeof(k_invisibleFullwidthSpaceCharList) / sizeof(unichar));

NSUInteger const k_modifierKeysList[] = {
    NSControlKeyMask,
    NSAlternateKeyMask,
    NSShiftKeyMask,
    NSCommandKeyMask
};
NSUInteger const k_size_of_modifierKeysList = (sizeof(k_modifierKeysList) / sizeof(NSUInteger));
unichar    const k_keySpecCharList[] = {0x005E, 0x007E, 0x0024, 0x0040}; // == "^~$@"
NSUInteger const k_size_of_keySpecCharList = (sizeof(k_keySpecCharList) / sizeof(unichar));
unichar    const k_readableKeyStringsList[] = {0x005E, 0x2325, 0x21E7, 0x2318};
NSUInteger const k_size_of_readableKeyStringsList = (sizeof(k_readableKeyStringsList) / sizeof(unichar));

unichar const k_noPrintableKeyList[] = {
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
NSUInteger const k_size_of_noPrintableKeyList = sizeof(k_noPrintableKeyList) / sizeof(unichar);
