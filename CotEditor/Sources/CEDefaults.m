/*
 
 CEDefaults.m
 
 CotEditor
 http://coteditor.com
 
 Created by 1024jp on 2016-01-03.
 
 ------------------------------------------------------------------------------
 
 © 2004-2007 nakamuxu
 © 2014-2016 1024jp
 
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

#import "CEDefaults.h"


// ------------------------------------------------------
// User Defaults Keys
// ------------------------------------------------------

// general settings
NSString *_Nonnull const CEDefaultCreateNewAtStartupKey = @"createNewAtStartup";
NSString *_Nonnull const CEDefaultReopenBlankWindowKey = @"reopenBlankWindow";
NSString *_Nonnull const CEDefaultEnablesAutosaveInPlaceKey = @"enablesAutosaveInPlace";
NSString *_Nonnull const CEDefaultTrimsTrailingWhitespaceOnSaveKey = @"trimsTrailingWhitespaceOnSave";
NSString *_Nonnull const CEDefaultDocumentConflictOptionKey = @"documentConflictOption";
NSString *_Nonnull const CEDefaultSyncFindPboardKey = @"syncFindPboard";
NSString *_Nonnull const CEDefaultInlineContextualScriptMenuKey = @"inlineContextualScriptMenu";
NSString *_Nonnull const CEDefaultCountLineEndingAsCharKey = @"countLineEndingAsChar";
NSString *_Nonnull const CEDefaultAutoLinkDetectionKey = @"autoLinkDetectionKey";
NSString *_Nonnull const CEDefaultCheckSpellingAsTypeKey = @"checkSpellingAsType";
NSString *_Nonnull const CEDefaultHighlightBracesKey = @"highlightBraces";
NSString *_Nonnull const CEDefaultHighlightLtGtKey = @"highlightLtGt";
NSString *_Nonnull const CEDefaultChecksUpdatesForBetaKey = @"checksUpdatesForBeta";

NSString *_Nonnull const CEDefaultShowNavigationBarKey = @"showNavigationBar";
NSString *_Nonnull const CEDefaultShowDocumentInspectorKey = @"showDocumentInspector";
NSString *_Nonnull const CEDefaultShowStatusBarKey = @"showStatusArea";
NSString *_Nonnull const CEDefaultShowLineNumbersKey = @"showLineNumbers";
NSString *_Nonnull const CEDefaultShowPageGuideKey = @"showPageGuide";
NSString *_Nonnull const CEDefaultPageGuideColumnKey = @"pageGuideColumn";
NSString *_Nonnull const CEDefaultShowStatusBarLinesKey = @"showStatusBarLines";
NSString *_Nonnull const CEDefaultShowStatusBarCharsKey = @"showStatusBarChars";
NSString *_Nonnull const CEDefaultShowStatusBarLengthKey = @"showStatusBarLength";
NSString *_Nonnull const CEDefaultShowStatusBarWordsKey = @"showStatusBarWords";
NSString *_Nonnull const CEDefaultShowStatusBarLocationKey = @"showStatusBarLocation";
NSString *_Nonnull const CEDefaultShowStatusBarLineKey = @"showStatusBarLine";
NSString *_Nonnull const CEDefaultShowStatusBarColumnKey = @"showStatusBarColumn";
NSString *_Nonnull const CEDefaultShowStatusBarEncodingKey = @"showStatusBarEncoding";
NSString *_Nonnull const CEDefaultShowStatusBarLineEndingsKey = @"showStatusBarLineEndings";
NSString *_Nonnull const CEDefaultShowStatusBarFileSizeKey = @"showStatusBarFileSize";
NSString *_Nonnull const CEDefaultSplitViewVerticalKey = @"splitViewVertical";
NSString *_Nonnull const CEDefaultWindowWidthKey = @"windowWidth";
NSString *_Nonnull const CEDefaultWindowHeightKey = @"windowHeight";
NSString *_Nonnull const CEDefaultWindowAlphaKey = @"windowAlpha";

NSString *_Nonnull const CEDefaultFontNameKey = @"fontName";
NSString *_Nonnull const CEDefaultFontSizeKey = @"fontSize";
NSString *_Nonnull const CEDefaultShouldAntialiasKey = @"shouldAntialias";
NSString *_Nonnull const CEDefaultLineHeightKey = @"lineHeight";
NSString *_Nonnull const CEDefaultHighlightCurrentLineKey = @"highlightCurrentLine";
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
NSString *_Nonnull const CEDefaultThemeKey = @"defaultTheme";

NSString *_Nonnull const CEDefaultSmartInsertAndDeleteKey = @"smartInsertAndDelete";
NSString *_Nonnull const CEDefaultBalancesBracketsKey = @"balancesBrackets";
NSString *_Nonnull const CEDefaultSwapYenAndBackSlashKey = @"swapYenAndBackSlashKey";
NSString *_Nonnull const CEDefaultEnableSmartQuotesKey = @"enableSmartQuotes";
NSString *_Nonnull const CEDefaultEnableSmartDashesKey = @"enableSmartDashes";
NSString *_Nonnull const CEDefaultAutoIndentKey = @"autoIndent";
NSString *_Nonnull const CEDefaultTabWidthKey = @"tabWidth";
NSString *_Nonnull const CEDefaultAutoExpandTabKey = @"autoExpandTab";
NSString *_Nonnull const CEDefaultDetectsIndentStyleKey = @"detectsIndentStyle";
NSString *_Nonnull const CEDefaultAppendsCommentSpacerKey = @"appendsCommentSpacer";
NSString *_Nonnull const CEDefaultCommentsAtLineHeadKey = @"commentsAtLineHead";
NSString *_Nonnull const CEDefaultWrapLinesKey = @"wrapLines";
NSString *_Nonnull const CEDefaultEnablesHangingIndentKey = @"enableHangingIndent";
NSString *_Nonnull const CEDefaultHangingIndentWidthKey = @"hangingIndentWidth";
NSString *_Nonnull const CEDefaultCompletesDocumentWordsKey = @"completesDocumentWords";
NSString *_Nonnull const CEDefaultCompletesSyntaxWordsKey = @"completesSyntaxWords";
NSString *_Nonnull const CEDefaultCompletesStandartWordsKey = @"completesStandardWords";
NSString *_Nonnull const CEDefaultAutoCompleteKey = @"autoComplete";

NSString *_Nonnull const CEDefaultLineEndCharCodeKey = @"defaultLineEndCharCode";
NSString *_Nonnull const CEDefaultEncodingListKey = @"encodingList";
NSString *_Nonnull const CEDefaultEncodingInNewKey = @"encodingInNew";
NSString *_Nonnull const CEDefaultEncodingInOpenKey = @"encodingInOpen";
NSString *_Nonnull const CEDefaultSaveUTF8BOMKey = @"saveUTF8BOM";
NSString *_Nonnull const CEDefaultReferToEncodingTagKey = @"referToEncodingTag";
NSString *_Nonnull const CEDefaultEnableSyntaxHighlightKey = @"doSyntaxColoring";
NSString *_Nonnull const CEDefaultSyntaxStyleKey = @"defaultColoringStyleName";

NSString *_Nonnull const CEDefaultFileDropArrayKey = @"fileDropArray";

NSString *_Nonnull const CEDefaultInsertCustomTextArrayKey = @"insertCustomTextArray";
NSString *_Nonnull const CEDefaultInsertCustomTextKey = @"insertCustomText";

NSString *_Nonnull const CEDefaultSetPrintFontKey = @"setPrintFont";
NSString *_Nonnull const CEDefaultPrintFontNameKey = @"printFontName";
NSString *_Nonnull const CEDefaultPrintFontSizeKey = @"printFontSize";
NSString *_Nonnull const CEDefaultPrintColorIndexKey = @"printColorIndex";
NSString *_Nonnull const CEDefaultPrintThemeKey = @"printTheme";
NSString *_Nonnull const CEDefaultPrintLineNumIndexKey = @"printLineNumIndex";
NSString *_Nonnull const CEDefaultPrintInvisibleCharIndexKey = @"printInvisibleCharIndex";
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

// find panel
NSString *_Nonnull const CEDefaultFindHistoryKey = @"findHistory";
NSString *_Nonnull const CEDefaultReplaceHistoryKey = @"replaceHistory";
NSString *_Nonnull const CEDefaultFindUsesRegularExpressionKey = @"findUsesRegularExpression";
NSString *_Nonnull const CEDefaultFindIgnoresCaseKey = @"findIgnoresCase";
NSString *_Nonnull const CEDefaultFindInSelectionKey = @"findInSelection";
NSString *_Nonnull const CEDefaultFindIsWrapKey = @"findIsWrap";
NSString *_Nonnull const CEDefaultFindNextAfterReplaceKey = @"findsNextAfterReplace";
NSString *_Nonnull const CEDefaultFindClosesIndicatorWhenDoneKey = @"findClosesIndicatorWhenDone";

NSString *_Nonnull const CEDefaultFindTextIsLiteralSearchKey = @"findTextIsLiteralSearch";
NSString *_Nonnull const CEDefaultFindTextIgnoresDiacriticMarksKey = @"findTextIgnoresDiacriticMarks";
NSString *_Nonnull const CEDefaultFindTextIgnoresWidthKey = @"findTextIgnoresWidth";
NSString *_Nonnull const CEDefaultFindRegexIsSinglelineKey = @"findRegexIsSingleline";
NSString *_Nonnull const CEDefaultFindRegexIsMultilineKey = @"findRegexIsMultiline";
NSString *_Nonnull const CEDefaultFindRegexUsesUnicodeBoundariesKey = @"regexUsesUnicodeBoundaries";

// settings that are not in preferences
NSString *_Nonnull const CEDefaultColorCodeTypeKey = @"colorCodeType";
NSString *_Nonnull const CEDefaultSidebarWidthKey = @"sidebarWidth";
NSString *_Nonnull const CEDefaultRecentlyUsedStyleNamesKey = @"recentlyUsedStyleNames";

// hidden settings
NSString *_Nonnull const CEDefaultLineNumFontNameKey = @"lineNumFontName";
NSString *_Nonnull const CEDefaultUsesTextFontForInvisiblesKey = @"usesTextFontForInvisibles";
NSString *_Nonnull const CEDefaultHeaderFooterDateFormatKey = @"headerFooterDateFormat";
NSString *_Nonnull const CEDefaultHeaderFooterPathAbbreviatingWithTildeKey = @"headerFooterPathAbbreviatingWithTilde";
NSString *_Nonnull const CEDefaultTextContainerInsetWidthKey = @"textContainerInsetWidth";
NSString *_Nonnull const CEDefaultTextContainerInsetHeightTopKey = @"textContainerInsetHeightTop";
NSString *_Nonnull const CEDefaultTextContainerInsetHeightBottomKey = @"textContainerInsetHeightBottom";
NSString *_Nonnull const CEDefaultAutoCompletionDelayKey = @"autoCompletionDelay";
NSString *_Nonnull const CEDefaultInfoUpdateIntervalKey = @"infoUpdateInterval";
NSString *_Nonnull const CEDefaultOutlineMenuIntervalKey = @"outlineMenuInterval";
NSString *_Nonnull const CEDefaultShowColoringIndicatorTextLengthKey = @"showColoringIndicatorTextLength";
NSString *_Nonnull const CEDefaultColoringRangeBufferLengthKey = @"coloringRangeBufferLength";
NSString *_Nonnull const CEDefaultLargeFileAlertThresholdKey = @"largeFileAlertThreshold";
NSString *_Nonnull const CEDefaultAutosavingDelayKey = @"autosavingDelay";
NSString *_Nonnull const CEDefaultSavesTextOrientationKey = @"savesTextOrientation";
NSString *_Nonnull const CEDefaultLayoutTextVerticalKey = @"layoutTextVertical";
NSString *_Nonnull const CEDefaultEnableSmartIndentKey = @"enableSmartIndent";
NSString *_Nonnull const CEDefaultRecentlyUsedStylesLimitKey = @"recentlyUsedStylesLimit";

NSString *_Nonnull const CEDefaultLastVersionKey = @"lastVersion";
