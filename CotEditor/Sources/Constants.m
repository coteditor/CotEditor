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
NSString *_Nonnull const CESeparatorString = @"-";

// Exported UTI
NSString *_Nonnull const CEUTTypeTheme = @"com.coteditor.CotEditor.theme";

// Error domain
NSString *_Nonnull const CEErrorDomain = @"com.coteditor.CotEditor.ErrorDomain";

// Metadata dict keys for themes and syntax styles
NSString *_Nonnull const CEMetadataKey = @"metadata";
NSString *_Nonnull const CEAuthorKey = @"author";
NSString *_Nonnull const CEDistributionURLKey = @"distributionURL";
NSString *_Nonnull const CELicenseKey = @"license";
NSString *_Nonnull const CEDescriptionKey = @"description";


// Help anchors
NSString *_Nonnull const kHelpAnchors[] = {
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
    @"pref_integration",
    @"about_file_mapping"
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
NSString *_Nonnull const CEDocumentDidFinishOpenNotification = @"CEDocumentDidFinishOpenNotification";

// General notification's userInfo keys
NSString *_Nonnull const CEOldNameKey = @"CEOldNameKey";
NSString *_Nonnull const CENewNameKey = @"CENewNameKey";



#pragma mark User Defaults Keys

// ------------------------------------------------------
// User Defaults Keys
// ------------------------------------------------------

// general settings
NSString *_Nonnull const CEDefaultLastVersionKey = @"lastVersion";
NSString *_Nonnull const CEDefaultDocumentConflictOptionKey = @"documentConflictOption";
NSString *_Nonnull const CEDefaultLayoutTextVerticalKey = @"layoutTextVertical";
NSString *_Nonnull const CEDefaultSplitViewVerticalKey = @"splitViewVertical";
NSString *_Nonnull const CEDefaultShowLineNumbersKey = @"showLineNumbers";
NSString *_Nonnull const CEDefaultShowDocumentInspectorKey = @"showDocumentInspector";
NSString *_Nonnull const CEDefaultShowStatusBarKey = @"showStatusArea";
NSString *_Nonnull const CEDefaultShowStatusBarLinesKey = @"showStatusBarLines";
NSString *_Nonnull const CEDefaultShowStatusBarLengthKey = @"showStatusBarLength";
NSString *_Nonnull const CEDefaultShowStatusBarCharsKey = @"showStatusBarChars";
NSString *_Nonnull const CEDefaultShowStatusBarWordsKey = @"showStatusBarWords";
NSString *_Nonnull const CEDefaultShowStatusBarLocationKey = @"showStatusBarLocation";
NSString *_Nonnull const CEDefaultShowStatusBarLineKey = @"showStatusBarLine";
NSString *_Nonnull const CEDefaultShowStatusBarColumnKey = @"showStatusBarColumn";
NSString *_Nonnull const CEDefaultShowStatusBarEncodingKey = @"showStatusBarEncoding";
NSString *_Nonnull const CEDefaultShowStatusBarLineEndingsKey = @"showStatusBarLineEndings";
NSString *_Nonnull const CEDefaultShowStatusBarFileSizeKey = @"showStatusBarFileSize";
NSString *_Nonnull const CEDefaultShowNavigationBarKey = @"showNavigationBar";
NSString *_Nonnull const CEDefaultCountLineEndingAsCharKey = @"countLineEndingAsChar";
NSString *_Nonnull const CEDefaultSyncFindPboardKey = @"syncFindPboard";
NSString *_Nonnull const CEDefaultInlineContextualScriptMenuKey = @"inlineContextualScriptMenu";
NSString *_Nonnull const CEDefaultWrapLinesKey = @"wrapLines";
NSString *_Nonnull const CEDefaultLineEndCharCodeKey = @"defaultLineEndCharCode";
NSString *_Nonnull const CEDefaultEncodingListKey = @"encodingList";
NSString *_Nonnull const CEDefaultFontNameKey = @"fontName";
NSString *_Nonnull const CEDefaultFontSizeKey = @"fontSize";
NSString *_Nonnull const CEDefaultEncodingInOpenKey = @"encodingInOpen";
NSString *_Nonnull const CEDefaultEncodingInNewKey = @"encodingInNew";
NSString *_Nonnull const CEDefaultReferToEncodingTagKey = @"referToEncodingTag";
NSString *_Nonnull const CEDefaultCreateNewAtStartupKey = @"createNewAtStartup";
NSString *_Nonnull const CEDefaultReopenBlankWindowKey = @"reopenBlankWindow";
NSString *_Nonnull const CEDefaultCheckSpellingAsTypeKey = @"checkSpellingAsType";
NSString *_Nonnull const CEDefaultWindowWidthKey = @"windowWidth";
NSString *_Nonnull const CEDefaultWindowHeightKey = @"windowHeight";
NSString *_Nonnull const CEDefaultWindowAlphaKey = @"windowAlpha";
NSString *_Nonnull const CEDefaultAutoExpandTabKey = @"autoExpandTab";
NSString *_Nonnull const CEDefaultTabWidthKey = @"tabWidth";
NSString *_Nonnull const CEDefaultAutoIndentKey = @"autoIndent";
NSString *_Nonnull const CEDefaultEnablesHangingIndentKey = @"enableHangingIndent";
NSString *_Nonnull const CEDefaultHangingIndentWidthKey = @"hangingIndentWidth";
NSString *_Nonnull const CEDefaultShowInvisiblesKey = @"showInvisibles";
NSString *_Nonnull const CEDefaultShowInvisibleSpaceKey = @"showInvisibleSpace";
NSString *_Nonnull const CEDefaultInvisibleSpaceKey = @"invisibleSpace";
NSString *_Nonnull const CEDefaultShowInvisibleTabKey = @"showInvisibleTab";
NSString *_Nonnull const CEDefaultInvisibleTabKey = @"invisibleTab";
NSString *_Nonnull const CEDefaultShowInvisibleNewLineKey = @"showInvisibleNewLine";
NSString *_Nonnull const CEDefaultInvisibleNewLineKey = @"invisibleNewLine";
NSString *_Nonnull const CEDefaultShowInvisibleFullwidthSpaceKey = @"showInvisibleZenkakuSpace";
NSString *_Nonnull const CEDefaultInvisibleFullwidthSpaceKey = @"invisibleZenkakuSpace";
NSString *_Nonnull const CEDefaultShowOtherInvisibleCharsKey = @"showOtherInvisibleChars";
NSString *_Nonnull const CEDefaultHighlightCurrentLineKey = @"highlightCurrentLine";
NSString *_Nonnull const CEDefaultEnableSyntaxHighlightKey = @"doSyntaxColoring";
NSString *_Nonnull const CEDefaultSyntaxStyleKey = @"defaultColoringStyleName";
NSString *_Nonnull const CEDefaultThemeKey = @"defaultTheme";
NSString *_Nonnull const CEDefaultDelayColoringKey = @"delayColoring";
NSString *_Nonnull const CEDefaultFileDropArrayKey = @"fileDropArray";
NSString *_Nonnull const CEDefaultSmartInsertAndDeleteKey = @"smartInsertAndDelete";
NSString *_Nonnull const CEDefaultShouldAntialiasKey = @"shouldAntialias";
NSString *_Nonnull const CEDefaultAutoCompleteKey = @"autoComplete";
NSString *_Nonnull const CEDefaultCompletesDocumentWordsKey = @"completesDocumentWords";
NSString *_Nonnull const CEDefaultCompletesSyntaxWordsKey = @"completesSyntaxWords";
NSString *_Nonnull const CEDefaultCompletesStandartWordsKey = @"completesStandardWords";
NSString *_Nonnull const CEDefaultShowPageGuideKey = @"showPageGuide";
NSString *_Nonnull const CEDefaultPageGuideColumnKey = @"pageGuideColumn";
NSString *_Nonnull const CEDefaultLineSpacingKey = @"lineSpacing";
NSString *_Nonnull const CEDefaultSwapYenAndBackSlashKey = @"swapYenAndBackSlashKey";
NSString *_Nonnull const CEDefaultFixLineHeightKey = @"fixLineHeight";
NSString *_Nonnull const CEDefaultHighlightBracesKey = @"highlightBraces";
NSString *_Nonnull const CEDefaultHighlightLtGtKey = @"highlightLtGt";
NSString *_Nonnull const CEDefaultSaveUTF8BOMKey = @"saveUTF8BOM";
NSString *_Nonnull const CEDefaultEnableSmartQuotesKey = @"enableSmartQuotes";
NSString *_Nonnull const CEDefaultEnableSmartIndentKey = @"enableSmartIndent";
NSString *_Nonnull const CEDefaultAppendsCommentSpacerKey = @"appendsCommentSpacer";
NSString *_Nonnull const CEDefaultCommentsAtLineHeadKey = @"commentsAtLineHead";
NSString *_Nonnull const CEDefaultChecksUpdatesForBetaKey = @"checksUpdatesForBeta";

// print settings
NSString *_Nonnull const CEDefaultSetPrintFontKey = @"setPrintFont";
NSString *_Nonnull const CEDefaultPrintFontNameKey = @"printFontName";
NSString *_Nonnull const CEDefaultPrintFontSizeKey = @"printFontSize";
NSString *_Nonnull const CEDefaultPrintThemeKey = @"printTheme";
NSString *_Nonnull const CEDefaultPrintHeaderKey = @"printHeader";
NSString *_Nonnull const CEDefaultPrimaryHeaderContentKey = @"headerOneStringIndex";
NSString *_Nonnull const CEDefaultPrimaryHeaderAlignmentKey = @"headerOneAlignIndex";
NSString *_Nonnull const CEDefaultSecondaryHeaderContentKey = @"headerTwoStringIndex";
NSString *_Nonnull const CEDefaultSecondaryHeaderAlignmentKey = @"headerTwoAlignIndex";
NSString *_Nonnull const CEDefaultPrintFooterKey = @"printFooter";
NSString *_Nonnull const CEDefaultPrimaryFooterContentKey = @"footerOneStringIndex";
NSString *_Nonnull const CEDefaultPrimaryFooterAlignmentKey = @"footerOneAlignIndex";
NSString *_Nonnull const CEDefaultSecondaryFooterContentKey = @"footerTwoStringIndex";
NSString *_Nonnull const CEDefaultSecondaryFooterAlignmentKey = @"footerTwoAlignIndex";
NSString *_Nonnull const CEDefaultPrintLineNumIndexKey = @"printLineNumIndex";
NSString *_Nonnull const CEDefaultPrintInvisibleCharIndexKey = @"printInvisibleCharIndex";
NSString *_Nonnull const CEDefaultPrintColorIndexKey = @"printColorIndex";

// find panel
NSString *_Nonnull const CEDefaultFindHistoryKey = @"findHistory";
NSString *_Nonnull const CEDefaultReplaceHistoryKey = @"replaceHistory";
NSString *_Nonnull const CEDefaultFindRegexSyntaxKey = @"findRegexSynatx";
NSString *_Nonnull const CEDefaultFindUsesRegularExpressionKey = @"findUsesRegularExpression";
NSString *_Nonnull const CEDefaultFindInSelectionKey = @"findInSelection";
NSString *_Nonnull const CEDefaultFindIsWrapKey = @"findIsWrap";
NSString *_Nonnull const CEDefaultFindNextAfterReplaceKey = @"findsNextAfterReplace";
NSString *_Nonnull const CEDefaultFindOptionsKey = @"findOptions";
NSString *_Nonnull const CEDefaultFindClosesIndicatorWhenDoneKey = @"findClosesIndicatorWhenDone";

// settings that are not in preferences
NSString *_Nonnull const CEDefaultInsertCustomTextArrayKey = @"insertCustomTextArray";
NSString *_Nonnull const CEDefaultInsertCustomTextKey = @"insertCustomText";
NSString *_Nonnull const CEDefaultColorCodeTypeKey = @"colorCodeType";
NSString *_Nonnull const CEDefaultSidebarWidthKey = @"sidebarWidth";

// hidden settings
NSString *_Nonnull const CEDefaultUsesTextFontForInvisiblesKey = @"usesTextFontForInvisibles";
NSString *_Nonnull const CEDefaultLineNumFontNameKey = @"lineNumFontName";
NSString *_Nonnull const CEDefaultBasicColoringDelayKey = @"basicColoringDelay";
NSString *_Nonnull const CEDefaultFirstColoringDelayKey = @"firstColoringDelay";
NSString *_Nonnull const CEDefaultSecondColoringDelayKey = @"secondColoringDelay";
NSString *_Nonnull const CEDefaultAutoCompletionDelayKey = @"autoCompletionDelay";
NSString *_Nonnull const CEDefaultInfoUpdateIntervalKey = @"infoUpdateInterval";
NSString *_Nonnull const CEDefaultIncompatibleCharIntervalKey = @"incompatibleCharInterval";
NSString *_Nonnull const CEDefaultOutlineMenuIntervalKey = @"outlineMenuInterval";
NSString *_Nonnull const CEDefaultHeaderFooterDateFormatKey = @"headerFooterDateFormat";
NSString *_Nonnull const CEDefaultHeaderFooterPathAbbreviatingWithTildeKey = @"headerFooterPathAbbreviatingWithTilde";
NSString *_Nonnull const CEDefaultTextContainerInsetWidthKey = @"textContainerInsetWidth";
NSString *_Nonnull const CEDefaultTextContainerInsetHeightTopKey = @"textContainerInsetHeightTop";
NSString *_Nonnull const CEDefaultTextContainerInsetHeightBottomKey = @"textContainerInsetHeightBottom";
NSString *_Nonnull const CEDefaultShowColoringIndicatorTextLengthKey = @"showColoringIndicatorTextLength";
NSString *_Nonnull const CEDefaultRunAppleScriptInLaunchingKey = @"runAppleScriptInLaunching";
NSString *_Nonnull const CEDefaultShowAlertForNotWritableKey = @"showAlertForNotWritable";
NSString *_Nonnull const CEDefaultNotifyEditByAnotherKey = @"notifyEditByAnother";
NSString *_Nonnull const CEDefaultColoringRangeBufferLengthKey = @"coloringRangeBufferLength";
NSString *_Nonnull const CEDefaultLargeFileAlertThresholdKey = @"largeFileAlertThreshold";
NSString *_Nonnull const CEDefaultAutosavingDelayKey = @"autosavingDelay";
NSString *_Nonnull const CEDefaultEnablesAutosaveInPlaceKey = @"enablesAutosaveInPlace";
NSString *_Nonnull const CEDefaultSavesTextOrientationKey = @"savesTextOrientation";
NSString *_Nonnull const CEDefaultCotCommandBookmarkKey = @"cotCommandBookmarkKey";



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
NSString *_Nonnull const kAllAlphabetChars = @"abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789_";

// syntax style keys
NSString *_Nonnull const CESyntaxMetadataKey = @"metadata";
NSString *_Nonnull const CESyntaxExtensionsKey = @"extensions";
NSString *_Nonnull const CESyntaxFileNamesKey = @"filenames";
NSString *_Nonnull const CESyntaxInterpretersKey = @"interpreters";
NSString *_Nonnull const CESyntaxKeywordsKey = @"keywords";
NSString *_Nonnull const CESyntaxCommandsKey = @"commands";
NSString *_Nonnull const CESyntaxTypesKey = @"types";
NSString *_Nonnull const CESyntaxAttributesKey = @"attributes";
NSString *_Nonnull const CESyntaxVariablesKey = @"variables";
NSString *_Nonnull const CESyntaxValuesKey = @"values";
NSString *_Nonnull const CESyntaxNumbersKey = @"numbers";
NSString *_Nonnull const CESyntaxStringsKey = @"strings";
NSString *_Nonnull const CESyntaxCharactersKey = @"characters";
NSString *_Nonnull const CESyntaxCommentsKey = @"comments";
NSString *_Nonnull const CESyntaxCommentDelimitersKey = @"commentDelimiters";
NSString *_Nonnull const CESyntaxOutlineMenuKey = @"outlineMenu";
NSString *_Nonnull const CESyntaxCompletionsKey = @"completions";
NSString *_Nonnull const kAllColoringKeys[] = {
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

NSString *_Nonnull const CESyntaxKeyStringKey = @"keyString";
NSString *_Nonnull const CESyntaxBeginStringKey = @"beginString";
NSString *_Nonnull const CESyntaxEndStringKey = @"endString";
NSString *_Nonnull const CESyntaxIgnoreCaseKey = @"ignoreCase";
NSString *_Nonnull const CESyntaxRegularExpressionKey = @"regularExpression";

NSString *_Nonnull const CESyntaxInlineCommentKey = @"inlineDelimiter";
NSString *_Nonnull const CESyntaxBeginCommentKey = @"beginDelimiter";
NSString *_Nonnull const CESyntaxEndCommentKey = @"endDelimiter";

NSString *_Nonnull const CESyntaxBoldKey = @"bold";
NSString *_Nonnull const CESyntaxUnderlineKey = @"underline";
NSString *_Nonnull const CESyntaxItalicKey = @"italic";

// comment delimiter keys
NSString *_Nonnull const CEBeginDelimiterKey = @"beginDelimiter";
NSString *_Nonnull const CEEndDelimiterKey = @"endDelimiter";



#pragma mark File Drop

// ------------------------------------------------------
// File Drop
// ------------------------------------------------------

// keys for dicts in CEDefaultFileDropArrayKey
NSString *_Nonnull const CEFileDropExtensionsKey = @"extensions";
NSString *_Nonnull const CEFileDropFormatStringKey = @"formatString";

// tokens
NSString *_Nonnull const CEFileDropAbsolutePathToken = @"<<<ABSOLUTE-PATH>>>";
NSString *_Nonnull const CEFileDropRelativePathToken = @"<<<RELATIVE-PATH>>>";
NSString *_Nonnull const CEFileDropFilenameToken = @"<<<FILENAME>>>";
NSString *_Nonnull const CEFileDropFilenameNosuffixToken = @"<<<FILENAME-NOSUFFIX>>>";
NSString *_Nonnull const CEFileDropFileextensionToken = @"<<<FILEEXTENSION>>>";
NSString *_Nonnull const CEFileDropFileextensionLowerToken = @"<<<FILEEXTENSION-LOWER>>>";
NSString *_Nonnull const CEFileDropFileextensionUpperToken = @"<<<FILEEXTENSION-UPPER>>>";
NSString *_Nonnull const CEFileDropDirectoryToken = @"<<<DIRECTORY>>>";
NSString *_Nonnull const CEFileDropImagewidthToken = @"<<<IMAGEWIDTH>>>";
NSString *_Nonnull const CEFileDropImagehightToken = @"<<<IMAGEHEIGHT>>>";



#pragma mark Main Menu

// ------------------------------------------------------
// Main Menu
// ------------------------------------------------------

// Help document file names table
NSString *_Nonnull const kBundledDocumentFileNames[] = {
    @"Acknowledgements",
    @"ScriptMenu Folder",
    @"AppleScript",
    @"ShellScript"
};

// Online URLs
NSString *_Nonnull const kWebSiteURL = @"http://coteditor.com";
NSString *_Nonnull const kIssueTrackerURL = @"https://github.com/coteditor/CotEditor/issues";



#pragma mark CEEditorWrapper

// ------------------------------------------------------
// CEEditorWrapper
// ------------------------------------------------------

// Outline item dict keys
NSString *_Nonnull const CEOutlineItemTitleKey = @"outlineItemTitle";
NSString *_Nonnull const CEOutlineItemRangeKey = @"outlineItemRange";
NSString *_Nonnull const CEOutlineItemStyleBoldKey = @"outlineItemStyleBold";
NSString *_Nonnull const CEOutlineItemStyleItalicKey = @"outlineItemStyleItalic";
NSString *_Nonnull const CEOutlineItemStyleUnderlineKey = @"outlineItemStyleUnderline";

// layout constants
NSString *_Nonnull const kNavigationBarFontName = @"Helvetica";



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
