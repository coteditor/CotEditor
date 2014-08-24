/*
 ==============================================================================
 constants
 
 CotEditor
 http://coteditor.github.io
 
 Created on 2004-12-13 by nakamuxu
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



#pragma mark Notifications

// ------------------------------------------------------
// Notifications
// ------------------------------------------------------

// Notification name
NSString *const CEEncodingListDidUpdateNotification = @"CESyntaxListDidUpdateNotification";
NSString *const CEDocumentDidFinishOpenNotification = @"CEDocumentDidFinishOpenNotification";

// General notification's userInfo keys
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
NSString *const k_key_usesTextFontForInvisibles = @"usesTextFontForInvisibles";
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
NSString *const k_key_headerFooterDateFormat = @"headerFooterDateFormat";
NSString *const k_key_headerFooterPathAbbreviatingWithTilde = @"headerFooterPathAbbreviatingWithTilde";
NSString *const k_key_textContainerInsetWidth = @"textContainerInsetWidth";
NSString *const k_key_textContainerInsetHeightTop = @"textContainerInsetHeightTop";
NSString *const k_key_textContainerInsetHeightBottom = @"textContainerInsetHeightBottom";
NSString *const k_key_showColoringIndicatorTextLength = @"showColoringIndicatorTextLength";
NSString *const k_key_runAppleScriptInLaunching = @"runAppleScriptInLaunching";
NSString *const k_key_showAlertForNotWritable = @"showAlertForNotWritable";
NSString *const k_key_notifyEditByAnother = @"notifyEditByAnother";
NSString *const k_key_coloringRangeBufferLength = @"coloringRangeBufferLength";



// ------------------------------------------------------
// Setting thresholds
// ------------------------------------------------------

// Page guide column
NSUInteger const k_minPageGuideColumn = 1;
NSUInteger const k_maxPageGuideColumn = 1000;



#pragma mark Syntax

// ------------------------------------------------------
// Syntax
// ------------------------------------------------------

// syntax coloring
NSUInteger const k_maxEscapesCheckLength = 16;
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

// Help document file names table
NSString *const k_bundledDocumentFileNames[] = {
    @"Version History",
    @"Acknowledgements",
    @"ScriptMenu Folder",
    @"AppleScript",
    @"ShellScript"
};

// Online URLs
NSString *const k_webSiteURL = @"http://coteditor.github.io";
NSString *const k_issueTrackerURL = @"https://github.com/coteditor/CotEditor/issues";



#pragma mark CEEditorWrapper

// ------------------------------------------------------
// CEEditorWrapper
// ------------------------------------------------------

// Outline item dict keys
NSString *const CEOutlineItemTitleKey = @"outlineItemTitle";
NSString *const CEOutlineItemRangeKey = @"outlineItemRange";
NSString *const CEOutlineItemSortKeyKey = @"outlineItemSortKey";
NSString *const CEOutlineItemFontBoldKey = @"outlineItemFontBold";
NSString *const CEOutlineItemFontItalicKey = @"outlineItemFontItalic";
NSString *const CEOutlineItemUnderlineMaskKey = @"outlineItemUnderlineMask";

// layout constants
CGFloat const k_defaultLineNumWidth = 32.0;
CGFloat const k_lineNumPadding = 3.0;
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
NSString *const k_textOrientationItemID = @"textOrientationItemID";
NSString *const k_lineEndingsItemID = @"lineEndingsItemID";
NSString *const k_fileEncodingsItemID = @"fileEncodingsItemID";
NSString *const k_syntaxItemID = @"syntaxColoringItemID";
NSString *const k_syntaxReColorAllItemID = @"syntaxReColorAllItemID";
NSString *const k_editColorCodeItemID = @"editColorCodeItemID";



#pragma mark KeyBindingManager

// ------------------------------------------------------
// KeyBindingManager
// ------------------------------------------------------

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

// Encodings list
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

// Encodings that need convert Yen mark to back-slash
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

// Yen mark char
unichar const k_yenMark = {0x00A5};



// ------------------------------------------------------
// Invisibles
// ------------------------------------------------------

// Substitutes for invisible characters
unichar     const k_invisibleSpaceCharList[] = {0x00B7, 0x00B0, 0x02D0, 0x2423};
NSUInteger  const k_size_of_invisibleSpaceCharList = sizeof(k_invisibleSpaceCharList) / sizeof(unichar);

unichar     const k_invisibleTabCharList[] = {0x00AC, 0x21E5, 0x2023, 0x25B9};
NSUInteger  const k_size_of_invisibleTabCharList = sizeof(k_invisibleTabCharList) / sizeof(unichar);

unichar     const k_invisibleNewLineCharList[] = {0x00B6, 0x21A9, 0x21B5, 0x23CE};
NSUInteger  const k_size_of_invisibleNewLineCharList = sizeof(k_invisibleNewLineCharList) / sizeof(unichar);

unichar     const k_invisibleFullwidthSpaceCharList[] = {0x25A2, 0x22A0, 0x25B3, 0x2573};
NSUInteger  const k_size_of_invisibleFullwidthSpaceCharList = sizeof(k_invisibleFullwidthSpaceCharList) / sizeof(unichar);



// ------------------------------------------------------
// Keybindings
// ------------------------------------------------------

// Modifier keys and characters for keybinding
NSUInteger const k_modifierKeyMaskList[] = {
    NSControlKeyMask,
    NSAlternateKeyMask,
    NSShiftKeyMask,
    NSCommandKeyMask
};
unichar const k_modifierKeySymbolCharList[] = {0x005E, 0x2325, 0x21E7, 0x2318};
unichar const k_keySpecCharList[]           = {0x005E, 0x007E, 0x0024, 0x0040};  // == "^~$@"

NSUInteger const k_size_of_modifierKeys = sizeof(k_modifierKeyMaskList) / sizeof(NSUInteger);


// Unprintable key list
unichar const k_unprintableKeyList[] = {
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
    NSDeleteCharacter, // do not use NSDeleteFunctionKey
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
NSUInteger const k_size_of_unprintableKeyList = sizeof(k_unprintableKeyList) / sizeof(unichar);
