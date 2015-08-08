/*
 
 Constants.m
 
 CotEditor
 http://coteditor.com
 
 Created by nakamuxu on 2004-12-13.
 
 ------------------------------------------------------------------------------
 
 © 2004-2007 nakamuxu
 © 2014-2015 1024jp
 
 Licensed under the Apache License, Version 2.0 (the "License");
 you may not use this file except in compliance with the License.
 You may obtain a copy of the License at
 
 http://www.apache.org/licenses/LICENSE-2.0
 
 Unless required by applicable law or agreed to in writing, software
 distributed under the License is distributed on an "AS IS" BASIS,
 WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 See the License for the specific language governing permissions and
 limitations under the License.
 
 */

#import "Constants.h"


#pragma mark General

// ------------------------------------------------------
// General
// ------------------------------------------------------

// separator
NSString *__nonnull const CESeparatorString = @"-";

// Exported UTI
NSString *__nonnull const CEUTTypeTheme = @"com.coteditor.CotEditor.theme";

// Error domain
NSString *__nonnull const CEErrorDomain = @"com.coteditor.CotEditor.ErrorDomain";

// Metadata dict keys for themes and syntax styles
NSString *__nonnull const CEMetadataKey = @"metadata";
NSString *__nonnull const CEAuthorKey = @"author";
NSString *__nonnull const CEDistributionURLKey = @"distributionURL";
NSString *__nonnull const CELisenceKey = @"lisence";
NSString *__nonnull const CEDescriptionKey = @"description";


// Help anchors
NSString *__nonnull const kHelpAnchors[] = {
    @"releasenotes",
    @"pref_general",
    @"pref_window",
    @"pref_appearance",
    @"pref_edit",
    @"pref_format",
    @"pref_filedrop",
    @"pref_keybindings",
    @"pref_print",
    @"whats_new",
    @"specification_changes",
    @"about_script_name",
    @"about_applescript",
    @"about_unixscript",
    @"pref_integration"
};


// Convenient functions
/// compare CGFloats
BOOL CEIsAlmostEqualCGFloats(CGFloat float1, CGFloat float2) {
    const double ACCURACY = 5;
    return (fabs(float1 - float2) < pow(10, -ACCURACY));
}



#pragma mark Notifications

// ------------------------------------------------------
// Notifications
// ------------------------------------------------------

// Notification name
NSString *__nonnull const CEDocumentDidFinishOpenNotification = @"CEDocumentDidFinishOpenNotification";

// General notification's userInfo keys
NSString *__nonnull const CEOldNameKey = @"CEOldNameKey";
NSString *__nonnull const CENewNameKey = @"CENewNameKey";



#pragma mark User Defaults Keys

// ------------------------------------------------------
// User Defaults Keys
// ------------------------------------------------------

// general settings
NSString *__nonnull const CEDefaultLastVersionKey = @"lastVersion";
NSString *__nonnull const CEDefaultDocumentConflictOptionKey = @"documentConflictOption";
NSString *__nonnull const CEDefaultLayoutTextVerticalKey = @"layoutTextVertical";
NSString *__nonnull const CEDefaultSplitViewVerticalKey = @"splitViewVertical";
NSString *__nonnull const CEDefaultShowLineNumbersKey = @"showLineNumbers";
NSString *__nonnull const CEDefaultShowDocumentInspectorKey = @"showDocumentInspector";
NSString *__nonnull const CEDefaultShowStatusBarKey = @"showStatusArea";
NSString *__nonnull const CEDefaultShowStatusBarLinesKey = @"showStatusBarLines";
NSString *__nonnull const CEDefaultShowStatusBarLengthKey = @"showStatusBarLength";
NSString *__nonnull const CEDefaultShowStatusBarCharsKey = @"showStatusBarChars";
NSString *__nonnull const CEDefaultShowStatusBarWordsKey = @"showStatusBarWords";
NSString *__nonnull const CEDefaultShowStatusBarLocationKey = @"showStatusBarLocation";
NSString *__nonnull const CEDefaultShowStatusBarLineKey = @"showStatusBarLine";
NSString *__nonnull const CEDefaultShowStatusBarColumnKey = @"showStatusBarColumn";
NSString *__nonnull const CEDefaultShowStatusBarEncodingKey = @"showStatusBarEncoding";
NSString *__nonnull const CEDefaultShowStatusBarLineEndingsKey = @"showStatusBarLineEndings";
NSString *__nonnull const CEDefaultShowStatusBarFileSizeKey = @"showStatusBarFileSize";
NSString *__nonnull const CEDefaultShowNavigationBarKey = @"showNavigationBar";
NSString *__nonnull const CEDefaultCountLineEndingAsCharKey = @"countLineEndingAsChar";
NSString *__nonnull const CEDefaultSyncFindPboardKey = @"syncFindPboard";
NSString *__nonnull const CEDefaultInlineContextualScriptMenuKey = @"inlineContextualScriptMenu";
NSString *__nonnull const CEDefaultWrapLinesKey = @"wrapLines";
NSString *__nonnull const CEDefaultLineEndCharCodeKey = @"defaultLineEndCharCode";
NSString *__nonnull const CEDefaultEncodingListKey = @"encodingList";
NSString *__nonnull const CEDefaultFontNameKey = @"fontName";
NSString *__nonnull const CEDefaultFontSizeKey = @"fontSize";
NSString *__nonnull const CEDefaultEncodingInOpenKey = @"encodingInOpen";
NSString *__nonnull const CEDefaultEncodingInNewKey = @"encodingInNew";
NSString *__nonnull const CEDefaultReferToEncodingTagKey = @"referToEncodingTag";
NSString *__nonnull const CEDefaultCreateNewAtStartupKey = @"createNewAtStartup";
NSString *__nonnull const CEDefaultReopenBlankWindowKey = @"reopenBlankWindow";
NSString *__nonnull const CEDefaultCheckSpellingAsTypeKey = @"checkSpellingAsType";
NSString *__nonnull const CEDefaultWindowWidthKey = @"windowWidth";
NSString *__nonnull const CEDefaultWindowHeightKey = @"windowHeight";
NSString *__nonnull const CEDefaultWindowAlphaKey = @"windowAlpha";
NSString *__nonnull const CEDefaultAutoExpandTabKey = @"autoExpandTab";
NSString *__nonnull const CEDefaultTabWidthKey = @"tabWidth";
NSString *__nonnull const CEDefaultAutoIndentKey = @"autoIndent";
NSString *__nonnull const CEDefaultShowInvisiblesKey = @"showInvisibles";
NSString *__nonnull const CEDefaultShowInvisibleSpaceKey = @"showInvisibleSpace";
NSString *__nonnull const CEDefaultInvisibleSpaceKey = @"invisibleSpace";
NSString *__nonnull const CEDefaultShowInvisibleTabKey = @"showInvisibleTab";
NSString *__nonnull const CEDefaultInvisibleTabKey = @"invisibleTab";
NSString *__nonnull const CEDefaultShowInvisibleNewLineKey = @"showInvisibleNewLine";
NSString *__nonnull const CEDefaultInvisibleNewLineKey = @"invisibleNewLine";
NSString *__nonnull const CEDefaultShowInvisibleFullwidthSpaceKey = @"showInvisibleZenkakuSpace";
NSString *__nonnull const CEDefaultInvisibleFullwidthSpaceKey = @"invisibleZenkakuSpace";
NSString *__nonnull const CEDefaultShowOtherInvisibleCharsKey = @"showOtherInvisibleChars";
NSString *__nonnull const CEDefaultHighlightCurrentLineKey = @"highlightCurrentLine";
NSString *__nonnull const CEDefaultEnableSyntaxHighlightKey = @"doSyntaxColoring";
NSString *__nonnull const CEDefaultSyntaxStyleKey = @"defaultColoringStyleName";
NSString *__nonnull const CEDefaultThemeKey = @"defaultTheme";
NSString *__nonnull const CEDefaultDelayColoringKey = @"delayColoring";
NSString *__nonnull const CEDefaultFileDropArrayKey = @"fileDropArray";
NSString *__nonnull const CEDefaultSmartInsertAndDeleteKey = @"smartInsertAndDelete";
NSString *__nonnull const CEDefaultShouldAntialiasKey = @"shouldAntialias";
NSString *__nonnull const CEDefaultAutoCompleteKey = @"autoComplete";
NSString *__nonnull const CEDefaultCompletionWordsKey = @"completeAddStandardWords";
NSString *__nonnull const CEDefaultShowPageGuideKey = @"showPageGuide";
NSString *__nonnull const CEDefaultPageGuideColumnKey = @"pageGuideColumn";
NSString *__nonnull const CEDefaultLineSpacingKey = @"lineSpacing";
NSString *__nonnull const CEDefaultSwapYenAndBackSlashKey = @"swapYenAndBackSlashKey";
NSString *__nonnull const CEDefaultFixLineHeightKey = @"fixLineHeight";
NSString *__nonnull const CEDefaultHighlightBracesKey = @"highlightBraces";
NSString *__nonnull const CEDefaultHighlightLtGtKey = @"highlightLtGt";
NSString *__nonnull const CEDefaultSaveUTF8BOMKey = @"saveUTF8BOM";
NSString *__nonnull const CEDefaultEnableSmartQuotesKey = @"enableSmartQuotes";
NSString *__nonnull const CEDefaultEnableSmartIndentKey = @"enableSmartIndent";
NSString *__nonnull const CEDefaultAppendsCommentSpacerKey = @"appendsCommentSpacer";
NSString *__nonnull const CEDefaultCommentsAtLineHeadKey = @"commentsAtLineHead";
NSString *__nonnull const CEDefaultChecksUpdatesForBetaKey = @"checksUpdatesForBeta";

// print settings
NSString *__nonnull const CEDefaultSetPrintFontKey = @"setPrintFont";
NSString *__nonnull const CEDefaultPrintFontNameKey = @"printFontName";
NSString *__nonnull const CEDefaultPrintFontSizeKey = @"printFontSize";
NSString *__nonnull const CEDefaultPrintThemeKey = @"printTheme";
NSString *__nonnull const CEDefaultPrintHeaderKey = @"printHeader";
NSString *__nonnull const CEDefaultHeaderOneStringIndexKey = @"headerOneStringIndex";
NSString *__nonnull const CEDefaultHeaderTwoStringIndexKey = @"headerTwoStringIndex";
NSString *__nonnull const CEDefaultHeaderOneAlignIndexKey = @"headerOneAlignIndex";
NSString *__nonnull const CEDefaultHeaderTwoAlignIndexKey = @"headerTwoAlignIndex";
NSString *__nonnull const CEDefaultPrintHeaderSeparatorKey = @"printHeaderSeparator";
NSString *__nonnull const CEDefaultPrintFooterKey = @"printFooter";
NSString *__nonnull const CEDefaultFooterOneStringIndexKey = @"footerOneStringIndex";
NSString *__nonnull const CEDefaultFooterTwoStringIndexKey = @"footerTwoStringIndex";
NSString *__nonnull const CEDefaultFooterOneAlignIndexKey = @"footerOneAlignIndex";
NSString *__nonnull const CEDefaultFooterTwoAlignIndexKey = @"footerTwoAlignIndex";
NSString *__nonnull const CEDefaultPrintFooterSeparatorKey = @"printFooterSeparator";
NSString *__nonnull const CEDefaultPrintLineNumIndexKey = @"printLineNumIndex";
NSString *__nonnull const CEDefaultPrintInvisibleCharIndexKey = @"printInvisibleCharIndex";
NSString *__nonnull const CEDefaultPrintColorIndexKey = @"printColorIndex";

// find panel
NSString *__nonnull const CEDefaultFindHistoryKey = @"findHistory";
NSString *__nonnull const CEDefaultReplaceHistoryKey = @"replaceHistory";
NSString *__nonnull const CEDefaultFindRegexSyntaxKey = @"findRegexSynatx";
NSString *__nonnull const CEDefaultFindUsesRegularExpressionKey = @"findUsesRegularExpression";
NSString *__nonnull const CEDefaultFindInSelectionKey = @"findInSelection";
NSString *__nonnull const CEDefaultFindIsWrapKey = @"findIsWrap";
NSString *__nonnull const CEDefaultFindNextAfterReplaceKey = @"findsNextAfterReplace";
NSString *__nonnull const CEDefaultFindOptionsKey = @"findOptions";
NSString *__nonnull const CEDefaultFindClosesIndicatorWhenDoneKey = @"findClosesIndicatorWhenDone";

// settings that are not in preferences
NSString *__nonnull const CEDefaultInsertCustomTextArrayKey = @"insertCustomTextArray";
NSString *__nonnull const CEDefaultInsertCustomTextKey = @"insertCustomText";
NSString *__nonnull const CEDefaultColorCodeTypeKey = @"colorCodeType";
NSString *__nonnull const CEDefaultSidebarWidthKey = @"sidebarWidth";

// hidden settings
NSString *__nonnull const CEDefaultUsesTextFontForInvisiblesKey = @"usesTextFontForInvisibles";
NSString *__nonnull const CEDefaultLineNumFontNameKey = @"lineNumFontName";
NSString *__nonnull const CEDefaultBasicColoringDelayKey = @"basicColoringDelay";
NSString *__nonnull const CEDefaultFirstColoringDelayKey = @"firstColoringDelay";
NSString *__nonnull const CEDefaultSecondColoringDelayKey = @"secondColoringDelay";
NSString *__nonnull const CEDefaultAutoCompletionDelayKey = @"autoCompletionDelay";
NSString *__nonnull const CEDefaultLineNumUpdateIntervalKey = @"lineNumUpdateInterval";
NSString *__nonnull const CEDefaultInfoUpdateIntervalKey = @"infoUpdateInterval";
NSString *__nonnull const CEDefaultIncompatibleCharIntervalKey = @"incompatibleCharInterval";
NSString *__nonnull const CEDefaultOutlineMenuIntervalKey = @"outlineMenuInterval";
NSString *__nonnull const CEDefaultHeaderFooterFontNameKey = @"headerFooterFontName";
NSString *__nonnull const CEDefaultHeaderFooterFontSizeKey = @"headerFooterFontSize";
NSString *__nonnull const CEDefaultHeaderFooterDateFormatKey = @"headerFooterDateFormat";
NSString *__nonnull const CEDefaultHeaderFooterPathAbbreviatingWithTildeKey = @"headerFooterPathAbbreviatingWithTilde";
NSString *__nonnull const CEDefaultTextContainerInsetWidthKey = @"textContainerInsetWidth";
NSString *__nonnull const CEDefaultTextContainerInsetHeightTopKey = @"textContainerInsetHeightTop";
NSString *__nonnull const CEDefaultTextContainerInsetHeightBottomKey = @"textContainerInsetHeightBottom";
NSString *__nonnull const CEDefaultShowColoringIndicatorTextLengthKey = @"showColoringIndicatorTextLength";
NSString *__nonnull const CEDefaultRunAppleScriptInLaunchingKey = @"runAppleScriptInLaunching";
NSString *__nonnull const CEDefaultShowAlertForNotWritableKey = @"showAlertForNotWritable";
NSString *__nonnull const CEDefaultNotifyEditByAnotherKey = @"notifyEditByAnother";
NSString *__nonnull const CEDefaultColoringRangeBufferLengthKey = @"coloringRangeBufferLength";
NSString *__nonnull const CEDefaultLargeFileAlertThresholdKey = @"largeFileAlertThreshold";
NSString *__nonnull const CEDefaultAutosavingDelayKey = @"autosavingDelay";
NSString *__nonnull const CEDefaultEnablesAutosaveInPlaceKey = @"enablesAutosaveInPlace";
NSString *__nonnull const CEDefaultSavesTextOrientationKey = @"savesTextOrientation";



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
NSString  *__nonnull const kAllAlphabetChars = @"abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789_";

// syntax style keys
NSString *__nonnull const CESyntaxMetadataKey = @"metadata";
NSString *__nonnull const CESyntaxExtensionsKey = @"extensions";
NSString *__nonnull const CESyntaxFileNamesKey = @"filenames";
NSString *__nonnull const CESyntaxKeywordsKey = @"keywords";
NSString *__nonnull const CESyntaxCommandsKey = @"commands";
NSString *__nonnull const CESyntaxTypesKey = @"types";
NSString *__nonnull const CESyntaxAttributesKey = @"attributes";
NSString *__nonnull const CESyntaxVariablesKey = @"variables";
NSString *__nonnull const CESyntaxValuesKey = @"values";
NSString *__nonnull const CESyntaxNumbersKey = @"numbers";
NSString *__nonnull const CESyntaxStringsKey = @"strings";
NSString *__nonnull const CESyntaxCharactersKey = @"characters";
NSString *__nonnull const CESyntaxCommentsKey = @"comments";
NSString *__nonnull const CESyntaxCommentDelimitersKey = @"commentDelimiters";
NSString *__nonnull const CESyntaxOutlineMenuKey = @"outlineMenu";
NSString *__nonnull const CESyntaxCompletionsKey = @"completions";
NSString *__nonnull const kAllColoringKeys[] = {
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

NSString *__nonnull const CESyntaxKeyStringKey = @"keyString";
NSString *__nonnull const CESyntaxBeginStringKey = @"beginString";
NSString *__nonnull const CESyntaxEndStringKey = @"endString";
NSString *__nonnull const CESyntaxIgnoreCaseKey = @"ignoreCase";
NSString *__nonnull const CESyntaxRegularExpressionKey = @"regularExpression";

NSString *__nonnull const CESyntaxInlineCommentKey = @"inlineDelimiter";
NSString *__nonnull const CESyntaxBeginCommentKey = @"beginDelimiter";
NSString *__nonnull const CESyntaxEndCommentKey = @"endDelimiter";

NSString *__nonnull const CESyntaxBoldKey = @"bold";
NSString *__nonnull const CESyntaxUnderlineKey = @"underline";
NSString *__nonnull const CESyntaxItalicKey = @"italic";

// comment delimiter keys
NSString *__nonnull const CEBeginDelimiterKey = @"beginDelimiter";
NSString *__nonnull const CEEndDelimiterKey = @"endDelimiter";



#pragma mark File Drop

// ------------------------------------------------------
// File Drop
// ------------------------------------------------------

// keys for dicts in CEDefaultFileDropArrayKey
NSString *__nonnull const CEFileDropExtensionsKey = @"extensions";
NSString *__nonnull const CEFileDropFormatStringKey = @"formatString";

// tokens
NSString *__nonnull const CEFileDropAbsolutePathToken = @"<<<ABSOLUTE-PATH>>>";
NSString *__nonnull const CEFileDropRelativePathToken = @"<<<RELATIVE-PATH>>>";
NSString *__nonnull const CEFileDropFilenameToken = @"<<<FILENAME>>>";
NSString *__nonnull const CEFileDropFilenameNosuffixToken = @"<<<FILENAME-NOSUFFIX>>>";
NSString *__nonnull const CEFileDropFileextensionToken = @"<<<FILEEXTENSION>>>";
NSString *__nonnull const CEFileDropFileextensionLowerToken = @"<<<FILEEXTENSION-LOWER>>>";
NSString *__nonnull const CEFileDropFileextensionUpperToken = @"<<<FILEEXTENSION-UPPER>>>";
NSString *__nonnull const CEFileDropDirectoryToken = @"<<<DIRECTORY>>>";
NSString *__nonnull const CEFileDropImagewidthToken = @"<<<IMAGEWIDTH>>>";
NSString *__nonnull const CEFileDropImagehightToken = @"<<<IMAGEHEIGHT>>>";



#pragma mark Main Menu

// ------------------------------------------------------
// Main Menu
// ------------------------------------------------------

// Help document file names table
NSString *__nonnull const kBundledDocumentFileNames[] = {
    @"Acknowledgements",
    @"ScriptMenu Folder",
    @"AppleScript",
    @"ShellScript"
};

// Online URLs
NSString *__nonnull const kWebSiteURL = @"http://coteditor.com";
NSString *__nonnull const kIssueTrackerURL = @"https://github.com/coteditor/CotEditor/issues";



#pragma mark CEEditorWrapper

// ------------------------------------------------------
// CEEditorWrapper
// ------------------------------------------------------

// Outline item dict keys
NSString *__nonnull const CEOutlineItemTitleKey = @"outlineItemTitle";
NSString *__nonnull const CEOutlineItemRangeKey = @"outlineItemRange";
NSString *__nonnull const CEOutlineItemStyleBoldKey = @"outlineItemStyleBold";
NSString *__nonnull const CEOutlineItemStyleItalicKey = @"outlineItemStyleItalic";
NSString *__nonnull const CEOutlineItemStyleUnderlineKey = @"outlineItemStyleUnderline";

// layout constants
CGFloat const kLineNumPadding = 3.0;
NSString *__nonnull const kNavigationBarFontName = @"Helvetica";



#pragma mark CEATSTypeSetter

// ------------------------------------------------------
// CEATSTypeSetter
// ------------------------------------------------------

// CEATSTypeSetter (Layouting)
CGFloat const kDefaultLineHeightMultiple = 1.19;



#pragma mark Encodings

// ------------------------------------------------------
// Encodings
// ------------------------------------------------------

// Encoding menu
NSInteger const CEAutoDetectEncoding = 0;

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
    kCFStringEncodingBig5_HKSCS_1999,  // Traditional Chinese (Big 5 HKSCS)
    kCFStringEncodingBig5_E,  // Traditional Chinese (Big 5-E)
    kCFStringEncodingBig5,  // Traditional Chinese (Big 5)
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
    kCFStringEncodingWindowsCyrillic, // Cyrillic (Windows)
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
    kCFStringEncodingWindowsCyrillic, // Cyrillic (Windows)
    kCFStringEncodingMacCentralEurRoman, // Central European (Mac OS)
    kCFStringEncodingISOLatin2, // Central European (ISO Latin 2)
    kCFStringEncodingISOLatin3, // Western (ISO Latin 3)
    kCFStringEncodingISOLatin4, // Central European (ISO Latin 4)
    kCFStringEncodingDOSLatinUS, // Latin-US (DOS)
    kCFStringEncodingWindowsLatin2, // Central European (Windows Latin 2)
};
NSUInteger const kSizeOfCFStringEncodingInvalidYenList = sizeof(kCFStringEncodingInvalidYenList) / sizeof(CFStringEncodings);

// Yen mark char
unichar const kYenMark = 0x00A5;



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

unichar     const kInvisibleFullwidthSpaceCharList[] = {0x25A1, 0x22A0, 0x25A0, 0x25B3};
NSUInteger  const kSizeOfInvisibleFullwidthSpaceCharList = sizeof(kInvisibleFullwidthSpaceCharList) / sizeof(unichar);

unichar const kVerticalTabChar = 0x240B;  // symbol for vertical tablation



// ------------------------------------------------------
// Keybindings
// ------------------------------------------------------

// Modifier keys and characters for keybinding
NSEventModifierFlags const kModifierKeyMaskList[] = {
    NSControlKeyMask,
    NSAlternateKeyMask,
    NSShiftKeyMask,
    NSCommandKeyMask
};
unichar const kModifierKeySymbolCharList[] = {0x005E, 0x2325, 0x21E7, 0x2318};
unichar const kKeySpecCharList[]           = {0x005E, 0x007E, 0x0024, 0x0040};  // == "^~$@"

NSUInteger const kSizeOfModifierKeys = sizeof(kModifierKeyMaskList) / sizeof(NSEventModifierFlags);


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
