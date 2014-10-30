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

// Localized strings table
NSString *const CEPrintLocalizeTable =  @"Print";

// Metadata dict keys for themes and syntax styles
NSString *const CEMetadataKey = @"metadata";
NSString *const CEAuthorKey = @"author";
NSString *const CEDistributionURLKey = @"distributionURL";
NSString *const CELisenceKey = @"lisence";
NSString *const CEDescriptionKey = @"description";


// Help anchors
NSString *const kHelpAnchors[] = {
    @"releasenotes",
    @"pref_general",
    @"pref_window",
    @"pref_appearance",
    @"pref_format",
    @"pref_syntax",
    @"pref_filedrop",
    @"pref_keybinding",
    @"pref_print"
};

#pragma mark Notifications

// ------------------------------------------------------
// Notifications
// ------------------------------------------------------

// Notification name
NSString *const CEDocumentDidFinishOpenNotification = @"CEDocumentDidFinishOpenNotification";

// General notification's userInfo keys
NSString *const CEOldNameKey = @"CEOldNameKey";
NSString *const CENewNameKey = @"CENewNameKey";



#pragma mark User Defaults Keys

// ------------------------------------------------------
// User Defaults Keys
// ------------------------------------------------------

// general settings
NSString *const CEDefaultLastVersionKey = @"lastVersion";
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
NSUInteger const kMinPageGuideColumn = 1;
NSUInteger const kMaxPageGuideColumn = 1000;



#pragma mark Syntax

// ------------------------------------------------------
// Syntax
// ------------------------------------------------------

// syntax coloring
NSUInteger const kMaxEscapesCheckLength = 16;
NSString  *const kAllAlphabetChars = @"abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789_";

// syntax style keys
NSString *const CESyntaxMetadataKey = @"metadata";
NSString *const CESyntaxExtensionsKey = @"extensions";
NSString *const CESyntaxFileNamesKey = @"filenames";
NSString *const CESyntaxKeywordsKey = @"keywords";
NSString *const CESyntaxCommandsKey = @"commands";
NSString *const CESyntaxTypesKey = @"types";
NSString *const CESyntaxAttributesKey = @"attributes";
NSString *const CESyntaxVariablesKey = @"variables";
NSString *const CESyntaxValuesKey = @"values";
NSString *const CESyntaxNumbersKey = @"numbers";
NSString *const CESyntaxStringsKey = @"strings";
NSString *const CESyntaxCharactersKey = @"characters";
NSString *const CESyntaxCommentsKey = @"comments";
NSString *const CESyntaxCommentDelimitersKey = @"commentDelimiters";
NSString *const CESyntaxOutlineMenuKey = @"outlineMenu";
NSString *const CESyntaxCompletionsKey = @"completions";
NSString *const kAllColoringKeys[] = {
    @"keywords",
    @"commands",
    @"types",
    @"attributes",
    @"variables",
    @"values",
    @"numbers",
    @"strings",
    @"characters",
    @"comments"
};
NSUInteger const kSizeOfAllColoringKeys = sizeof(kAllColoringKeys)/sizeof(kAllColoringKeys[0]);

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
NSString *const kBundledDocumentFileNames[] = {
    @"Acknowledgements",
    @"ScriptMenu Folder",
    @"AppleScript",
    @"ShellScript"
};

// Online URLs
NSString *const kWebSiteURL = @"http://coteditor.github.io";
NSString *const kIssueTrackerURL = @"https://github.com/coteditor/CotEditor/issues";



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
CGFloat const kDefaultLineNumWidth = 32.0;
CGFloat const kLineNumPadding = 3.0;
CGFloat const kLineNumFontDescender = -2.1;
NSString *const kNavigationBarFontName = @"Helvetica";



#pragma mark CEATSTypeSetter

// ------------------------------------------------------
// CEATSTypeSetter
// ------------------------------------------------------

// CEATSTypeSetter (Layouting)
CGFloat const kDefaultLineHeightMultiple = 1.19;



#pragma mark Print

// ------------------------------------------------------
// Print
// ------------------------------------------------------

CGFloat const kPrintTextHorizontalMargin = 8.0;
CGFloat const kPrintHFHorizontalMargin = 34.0;
CGFloat const kPrintHFVerticalMargin = 34.0;
CGFloat const kHeaderFooterLineHeight = 15.0;
CGFloat const kSeparatorPadding = 8.0;
CGFloat const kNoSeparatorPadding = 18.0;



#pragma mark Document Window

// ------------------------------------------------------
// Document Window
// ------------------------------------------------------

// Line Endings
NSString * const kLineEndingNames[]=  {
    @"LF",
    @"CR",
    @"CR/LF"
};



#pragma mark Encodings

// ------------------------------------------------------
// Encodings
// ------------------------------------------------------

// Encoding menu
NSInteger const CEAutoDetectEncodingMenuItemTag = 0;

// Max length to scan encding declaration
NSUInteger const kMaxEncodingScanLength = 2000;

// Encodings list
CFStringEncodings const kCFStringEncodingList[] = {
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
NSUInteger const kSizeOfCFStringEncodingList = sizeof(kCFStringEncodingList)/sizeof(CFStringEncodings);

// Encodings that need convert Yen mark to back-slash
CFStringEncodings const kCFStringEncodingInvalidYenList[] = {
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
NSUInteger const kSizeOfCFStringEncodingInvalidYenList = sizeof(kCFStringEncodingInvalidYenList)/sizeof(CFStringEncodings);

// Yen mark char
unichar const kYenMark = {0x00A5};



// ------------------------------------------------------
// Invisibles
// ------------------------------------------------------

// Substitutes for invisible characters
unichar     const kInvisibleSpaceCharList[] = {0x00B7, 0x00B0, 0x02D0, 0x2423};
NSUInteger  const kSizeOfInvisibleSpaceCharList = sizeof(kInvisibleSpaceCharList) / sizeof(unichar);

unichar     const kInvisibleTabCharList[] = {0x00AC, 0x21E5, 0x2023, 0x25B9};
NSUInteger  const kSizeOfInvisibleTabCharList = sizeof(kInvisibleTabCharList) / sizeof(unichar);

unichar     const kInvisibleNewLineCharList[] = {0x00B6, 0x21A9, 0x21B5, 0x23CE};
NSUInteger  const kSizeOfInvisibleNewLineCharList = sizeof(kInvisibleNewLineCharList) / sizeof(unichar);

unichar     const kInvisibleFullwidthSpaceCharList[] = {0x25A2, 0x22A0, 0x25B3, 0x2573};
NSUInteger  const kSizeOfInvisibleFullwidthSpaceCharList = sizeof(kInvisibleFullwidthSpaceCharList) / sizeof(unichar);



// ------------------------------------------------------
// Keybindings
// ------------------------------------------------------

// Modifier keys and characters for keybinding
NSUInteger const kModifierKeyMaskList[] = {
    NSControlKeyMask,
    NSAlternateKeyMask,
    NSShiftKeyMask,
    NSCommandKeyMask
};
unichar const kModifierKeySymbolCharList[] = {0x005E, 0x2325, 0x21E7, 0x2318};
unichar const kKeySpecCharList[]           = {0x005E, 0x007E, 0x0024, 0x0040};  // == "^~$@"

NSUInteger const kSizeOfModifierKeys = sizeof(kModifierKeyMaskList) / sizeof(NSUInteger);


// Unprintable key list
unichar const kUnprintableKeyList[] = {
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
NSUInteger const kSizeOfUnprintableKeyList = sizeof(kUnprintableKeyList) / sizeof(unichar);
