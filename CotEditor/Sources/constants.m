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
NSString *const k_printLocalizeTable =  @"Print";



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

// general settings
NSString *const CEDefaultLayoutTextVerticalKey = @"layoutTextVertical";
NSString *const CEDefaultSplitViewVerticalKey = @"splitViewVertical";
NSString *const CEDefaultShowLineNumbersKey = @"showLineNumbers";
NSString *const CEDefaultShowStatusBarKey = @"showStatusArea";
NSString *const CEDefaultShowStatusBarLinesKey = @"showStatusBarLines";
NSString *const CEDefaultShowStatusBarLengthKey = @"showStatusBarLength";
NSString *const CEDefaultShowStatusBarCharsKey = @"showStatusBarChars";
NSString *const CEDefaultShowStatusBarWordsKey = @"showStatusBarWords";
NSString *const CEDefaultShowStatusBarLocationKey = @"showStatusBarLocation";
NSString *const CEDefaultShowStatusBarLineKey = @"showStatusBarLine";
NSString *const CEDefaultShowStatusBarColumnKey = @"showStatusBarColumn";
NSString *const CEDefaultShowStatusBarEncodingKey = @"showStatusBarEncoding";
NSString *const CEDefaultShowStatusBarLineEndingsKey = @"showStatusBarLineEndings";
NSString *const CEDefaultShowStatusBarFileSizeKey = @"showStatusBarFileSize";
NSString *const CEDefaultShowNavigationBarKey = @"showNavigationBar";
NSString *const CEDefaultCountLineEndingAsCharKey = @"countLineEndingAsChar";
NSString *const CEDefaultSyncFindPboardKey = @"syncFindPboard";
NSString *const CEDefaultInlineContextualScriptMenuKey = @"inlineContextualScriptMenu";
NSString *const CEDefaultWrapLinesKey = @"wrapLines";
NSString *const CEDefaultLineEndCharCodeKey = @"defaultLineEndCharCode";
NSString *const CEDefaultEncodingListKey = @"encodingList";
NSString *const CEDefaultFontNameKey = @"fontName";
NSString *const CEDefaultFontSizeKey = @"fontSize";
NSString *const CEDefaultEncodingInOpenKey = @"encodingInOpen";
NSString *const CEDefaultEncodingInNewKey = @"encodingInNew";
NSString *const CEDefaultReferToEncodingTagKey = @"referToEncodingTag";
NSString *const CEDefaultCreateNewAtStartupKey = @"createNewAtStartup";
NSString *const CEDefaultReopenBlankWindowKey = @"reopenBlankWindow";
NSString *const CEDefaultCheckSpellingAsTypeKey = @"checkSpellingAsType";
NSString *const CEDefaultWindowWidthKey = @"windowWidth";
NSString *const CEDefaultWindowHeightKey = @"windowHeight";
NSString *const CEDefaultWindowAlphaKey = @"windowAlpha";
NSString *const CEDefaultAutoExpandTabKey = @"autoExpandTab";
NSString *const CEDefaultTabWidthKey = @"tabWidth";
NSString *const CEDefaultAutoIndentKey = @"autoIndent";
NSString *const CEDefaultShowInvisibleSpaceKey = @"showInvisibleSpace";
NSString *const CEDefaultInvisibleSpaceKey = @"invisibleSpace";
NSString *const CEDefaultShowInvisibleTabKey = @"showInvisibleTab";
NSString *const CEDefaultInvisibleTabKey = @"invisibleTab";
NSString *const CEDefaultShowInvisibleNewLineKey = @"showInvisibleNewLine";
NSString *const CEDefaultInvisibleNewLineKey = @"invisibleNewLine";
NSString *const CEDefaultShowInvisibleFullwidthSpaceKey = @"showInvisibleZenkakuSpace";
NSString *const CEDefaultInvisibleFullwidthSpaceKey = @"invisibleZenkakuSpace";
NSString *const CEDefaultShowOtherInvisibleCharsKey = @"showOtherInvisibleChars";
NSString *const CEDefaultHighlightCurrentLineKey = @"highlightCurrentLine";
NSString *const CEDefaultEnableSyntaxHighlightKey = @"doSyntaxColoring";
NSString *const CEDefaultSyntaxStyleKey = @"defaultColoringStyleName";
NSString *const CEDefaultThemeKey = @"defaultTheme";
NSString *const CEDefaultDelayColoringKey = @"delayColoring";
NSString *const CEDefaultFileDropArrayKey = @"fileDropArray";
NSString *const CEDefaultNSDragAndDropTextDelayKey = @"NSDragAndDropTextDelay";
NSString *const CEDefaultSmartInsertAndDeleteKey = @"smartInsertAndDelete";
NSString *const CEDefaultShouldAntialiasKey = @"shouldAntialias";
NSString *const CEDefaultAutoCompleteKey = @"autoComplete";
NSString *const CEDefaultCompletionWordsKey = @"completeAddStandardWords";
NSString *const CEDefaultShowPageGuideKey = @"showPageGuide";
NSString *const CEDefaultPageGuideColumnKey = @"pageGuideColumn";
NSString *const CEDefaultLineSpacingKey = @"lineSpacing";
NSString *const CEDefaultSwapYenAndBackSlashKey = @"swapYenAndBackSlashKey";
NSString *const CEDefaultFixLineHeightKey = @"fixLineHeight";
NSString *const CEDefaultHighlightBracesKey = @"highlightBraces";
NSString *const CEDefaultHighlightLtGtKey = @"highlightLtGt";
NSString *const CEDefaultSaveUTF8BOMKey = @"saveUTF8BOM";
NSString *const CEDefaultEnableSmartQuotesKey = @"enableSmartQuotes";
NSString *const CEDefaultEnableSmartIndentKey = @"enableSmartIndent";
NSString *const CEDefaultAppendsCommentSpacerKey = @"appendsCommentSpacer";
NSString *const CEDefaultCommentsAtLineHeadKey = @"commentsAtLineHead";

// print settings
NSString *const CEDefaultSetPrintFontKey = @"setPrintFont";
NSString *const CEDefaultPrintFontNameKey = @"printFontName";
NSString *const CEDefaultPrintFontSizeKey = @"printFontSize";
NSString *const CEDefaultPrintThemeKey = @"printTheme";
NSString *const CEDefaultPrintHeaderKey = @"printHeader";
NSString *const CEDefaultHeaderOneStringIndexKey = @"headerOneStringIndex";
NSString *const CEDefaultHeaderTwoStringIndexKey = @"headerTwoStringIndex";
NSString *const CEDefaultHeaderOneAlignIndexKey = @"headerOneAlignIndex";
NSString *const CEDefaultHeaderTwoAlignIndexKey = @"headerTwoAlignIndex";
NSString *const CEDefaultPrintHeaderSeparatorKey = @"printHeaderSeparator";
NSString *const CEDefaultPrintFooterKey = @"printFooter";
NSString *const CEDefaultFooterOneStringIndexKey = @"footerOneStringIndex";
NSString *const CEDefaultFooterTwoStringIndexKey = @"footerTwoStringIndex";
NSString *const CEDefaultFooterOneAlignIndexKey = @"footerOneAlignIndex";
NSString *const CEDefaultFooterTwoAlignIndexKey = @"footerTwoAlignIndex";
NSString *const CEDefaultPrintFooterSeparatorKey = @"printFooterSeparator";
NSString *const CEDefaultPrintLineNumIndexKey = @"printLineNumIndex";
NSString *const CEDefaultPrintInvisibleCharIndexKey = @"printInvisibleCharIndex";
NSString *const CEDefaultPrintColorIndexKey = @"printColorIndex";

// settings that are not in preferences
NSString *const CEDefaultInsertCustomTextArrayKey = @"insertCustomTextArray";
NSString *const CEDefaultInsertCustomTextKey = @"insertCustomText";
NSString *const CEDefaultColorCodeTypeKey = @"colorCodeType";

// hidden settings
NSString *const CEDefaultUsesTextFontForInvisiblesKey = @"usesTextFontForInvisibles";
NSString *const CEDefaultLineNumFontNameKey = @"lineNumFontName";
NSString *const CEDefaultLineNumFontColorKey = @"lineNumFontColor";
NSString *const CEDefaultBasicColoringDelayKey = @"basicColoringDelay";
NSString *const CEDefaultFirstColoringDelayKey = @"firstColoringDelay";
NSString *const CEDefaultSecondColoringDelayKey = @"secondColoringDelay";
NSString *const CEDefaultAutoCompletionDelayKey = @"autoCompletionDelay";
NSString *const CEDefaultLineNumUpdateIntervalKey = @"lineNumUpdateInterval";
NSString *const CEDefaultInfoUpdateIntervalKey = @"infoUpdateInterval";
NSString *const CEDefaultIncompatibleCharIntervalKey = @"incompatibleCharInterval";
NSString *const CEDefaultOutlineMenuIntervalKey = @"outlineMenuInterval";
NSString *const CEDefaultOutlineMenuMaxLengthKey = @"outlineMenuMaxLength";
NSString *const CEDefaultHeaderFooterFontNameKey = @"headerFooterFontName";
NSString *const CEDefaultHeaderFooterFontSizeKey = @"headerFooterFontSize";
NSString *const CEDefaultHeaderFooterDateFormatKey = @"headerFooterDateFormat";
NSString *const CEDefaultHeaderFooterPathAbbreviatingWithTildeKey = @"headerFooterPathAbbreviatingWithTilde";
NSString *const CEDefaultTextContainerInsetWidthKey = @"textContainerInsetWidth";
NSString *const CEDefaultTextContainerInsetHeightTopKey = @"textContainerInsetHeightTop";
NSString *const CEDefaultTextContainerInsetHeightBottomKey = @"textContainerInsetHeightBottom";
NSString *const CEDefaultShowColoringIndicatorTextLengthKey = @"showColoringIndicatorTextLength";
NSString *const CEDefaultRunAppleScriptInLaunchingKey = @"runAppleScriptInLaunching";
NSString *const CEDefaultShowAlertForNotWritableKey = @"showAlertForNotWritable";
NSString *const CEDefaultNotifyEditByAnotherKey = @"notifyEditByAnother";
NSString *const CEDefaultColoringRangeBufferLengthKey = @"coloringRangeBufferLength";

// keys for dicts in CEDefaultFileDropArrayKey
NSString *const CEFileDropExtensionsKey = @"extensions";
NSString *const CEFileDropFormatStringKey = @"formatString";



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

// syntax style keys
NSString *const CESyntaxStyleNameKey = @"styleName";
NSString *const CESyntaxMetadataKey = @"metadata";
NSString *const CESyntaxExtensionsKey = @"extensions";
NSString *const CESyntaxFileNamesKey = @"filenames";
NSString *const CESyntaxKeywordsKey = @"keywordsArray";
NSString *const CESyntaxCommandsKey = @"commandsArray";
NSString *const CESyntaxTypesKey = @"typesArray";
NSString *const CESyntaxAttributesKey = @"attributesArray";
NSString *const CESyntaxVariablesKey = @"variablesArray";
NSString *const CESyntaxValuesKey = @"valuesArray";
NSString *const CESyntaxNumbersKey = @"numbersArray";
NSString *const CESyntaxStringsKey = @"stringsArray";
NSString *const CESyntaxCharactersKey = @"charactersArray";
NSString *const CESyntaxCommentsKey = @"commentsArray";
NSString *const CESyntaxCommentDelimitersKey = @"commentDelimiters";
NSString *const CESyntaxOutlineMenuKey = @"outlineMenuArray";
NSString *const CESyntaxCompletionsKey = @"completionsArray";
NSString *const k_allColoringKeys[] = {
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
NSUInteger const k_size_of_allColoringKeys = sizeof(k_allColoringKeys)/sizeof(k_allColoringKeys[0]);

NSString *const CESyntaxKeyStringKey = @"keyString";
NSString *const CESyntaxBeginStringKey = @"beginString";
NSString *const CESyntaxEndStringKey = @"endString";
NSString *const CESyntaxIgnoreCaseKey = @"ignoreCase";
NSString *const CESyntaxRegularExpressionKey = @"regularExpression";

NSString *const CESyntaxInlineCommentKey = @"inlineDelimiter";
NSString *const CESyntaxBeginCommentKey = @"beginDelimiter";
NSString *const CESyntaxEndCommentKey = @"endDelimiter";

NSString *const CESyntaxBoldKey = @"bold";
NSString *const CESyntaxUnderlineKey = @"underline";
NSString *const CESyntaxItalicKey = @"italic";

// comment delimiter keys
NSString *const CEBeginDelimiterKey = @"beginDelimiter";
NSString *const CEEndDelimiterKey = @"endDelimiter";



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
