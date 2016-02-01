/*
 
 CEDefaults.h
 
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

@import Foundation;


// ------------------------------------------------------
// User Defaults Keys
// ------------------------------------------------------

// general settings
extern NSString *_Nonnull const CEDefaultLastVersionKey;
extern NSString *_Nonnull const CEDefaultEnablesAutosaveInPlaceKey;
extern NSString *_Nonnull const CEDefaultDocumentConflictOptionKey;
extern NSString *_Nonnull const CEDefaultLayoutTextVerticalKey;
extern NSString *_Nonnull const CEDefaultSplitViewVerticalKey;
extern NSString *_Nonnull const CEDefaultShowLineNumbersKey;
extern NSString *_Nonnull const CEDefaultShowDocumentInspectorKey;
extern NSString *_Nonnull const CEDefaultShowStatusBarKey;
extern NSString *_Nonnull const CEDefaultShowStatusBarLinesKey;
extern NSString *_Nonnull const CEDefaultShowStatusBarLengthKey;
extern NSString *_Nonnull const CEDefaultShowStatusBarCharsKey;
extern NSString *_Nonnull const CEDefaultShowStatusBarWordsKey;
extern NSString *_Nonnull const CEDefaultShowStatusBarLocationKey;
extern NSString *_Nonnull const CEDefaultShowStatusBarLineKey;
extern NSString *_Nonnull const CEDefaultShowStatusBarColumnKey;
extern NSString *_Nonnull const CEDefaultShowStatusBarEncodingKey;
extern NSString *_Nonnull const CEDefaultShowStatusBarLineEndingsKey;
extern NSString *_Nonnull const CEDefaultShowStatusBarFileSizeKey;
extern NSString *_Nonnull const CEDefaultShowNavigationBarKey;
extern NSString *_Nonnull const CEDefaultCountLineEndingAsCharKey;
extern NSString *_Nonnull const CEDefaultSyncFindPboardKey;
extern NSString *_Nonnull const CEDefaultInlineContextualScriptMenuKey;
extern NSString *_Nonnull const CEDefaultWrapLinesKey;
extern NSString *_Nonnull const CEDefaultLineEndCharCodeKey;
extern NSString *_Nonnull const CEDefaultEncodingListKey;
extern NSString *_Nonnull const CEDefaultFontNameKey;
extern NSString *_Nonnull const CEDefaultFontSizeKey;
extern NSString *_Nonnull const CEDefaultEncodingInOpenKey;
extern NSString *_Nonnull const CEDefaultEncodingInNewKey;
extern NSString *_Nonnull const CEDefaultReferToEncodingTagKey;
extern NSString *_Nonnull const CEDefaultCreateNewAtStartupKey;
extern NSString *_Nonnull const CEDefaultReopenBlankWindowKey;
extern NSString *_Nonnull const CEDefaultCheckSpellingAsTypeKey;
extern NSString *_Nonnull const CEDefaultWindowWidthKey;
extern NSString *_Nonnull const CEDefaultWindowHeightKey;
extern NSString *_Nonnull const CEDefaultWindowAlphaKey;
extern NSString *_Nonnull const CEDefaultAutoExpandTabKey;
extern NSString *_Nonnull const CEDefaultTabWidthKey;
extern NSString *_Nonnull const CEDefaultAutoIndentKey;
extern NSString *_Nonnull const CEDefaultEnablesHangingIndentKey;
extern NSString *_Nonnull const CEDefaultHangingIndentWidthKey;
extern NSString *_Nonnull const CEDefaultDetectsIndentStyleKey;
extern NSString *_Nonnull const CEDefaultShowInvisiblesKey;
extern NSString *_Nonnull const CEDefaultShowInvisibleSpaceKey;
extern NSString *_Nonnull const CEDefaultInvisibleSpaceKey;
extern NSString *_Nonnull const CEDefaultShowInvisibleTabKey;
extern NSString *_Nonnull const CEDefaultInvisibleTabKey;
extern NSString *_Nonnull const CEDefaultShowInvisibleNewLineKey;
extern NSString *_Nonnull const CEDefaultInvisibleNewLineKey;
extern NSString *_Nonnull const CEDefaultShowInvisibleFullwidthSpaceKey;
extern NSString *_Nonnull const CEDefaultInvisibleFullwidthSpaceKey;
extern NSString *_Nonnull const CEDefaultShowOtherInvisibleCharsKey;
extern NSString *_Nonnull const CEDefaultHighlightCurrentLineKey;
extern NSString *_Nonnull const CEDefaultEnableSyntaxHighlightKey;
extern NSString *_Nonnull const CEDefaultSyntaxStyleKey;
extern NSString *_Nonnull const CEDefaultThemeKey;
extern NSString *_Nonnull const CEDefaultDelayColoringKey;
extern NSString *_Nonnull const CEDefaultFileDropArrayKey;
extern NSString *_Nonnull const CEDefaultSmartInsertAndDeleteKey;
extern NSString *_Nonnull const CEDefaultShouldAntialiasKey;
extern NSString *_Nonnull const CEDefaultAutoCompleteKey;
extern NSString *_Nonnull const CEDefaultCompletesDocumentWordsKey;
extern NSString *_Nonnull const CEDefaultCompletesSyntaxWordsKey;
extern NSString *_Nonnull const CEDefaultCompletesStandartWordsKey;
extern NSString *_Nonnull const CEDefaultShowPageGuideKey;
extern NSString *_Nonnull const CEDefaultPageGuideColumnKey;
extern NSString *_Nonnull const CEDefaultLineSpacingKey;
extern NSString *_Nonnull const CEDefaultSwapYenAndBackSlashKey;
extern NSString *_Nonnull const CEDefaultFixLineHeightKey;
extern NSString *_Nonnull const CEDefaultHighlightBracesKey;
extern NSString *_Nonnull const CEDefaultHighlightLtGtKey;
extern NSString *_Nonnull const CEDefaultSaveUTF8BOMKey;
extern NSString *_Nonnull const CEDefaultBalancesBracketsKey;
extern NSString *_Nonnull const CEDefaultEnableSmartQuotesKey;
extern NSString *_Nonnull const CEDefaultEnableSmartIndentKey;
extern NSString *_Nonnull const CEDefaultAutoLinkDetectionKey;
extern NSString *_Nonnull const CEDefaultAppendsCommentSpacerKey;
extern NSString *_Nonnull const CEDefaultCommentsAtLineHeadKey;
extern NSString *_Nonnull const CEDefaultChecksUpdatesForBetaKey;

// print settings
extern NSString *_Nonnull const CEDefaultSetPrintFontKey;
extern NSString *_Nonnull const CEDefaultPrintFontNameKey;
extern NSString *_Nonnull const CEDefaultPrintFontSizeKey;
extern NSString *_Nonnull const CEDefaultPrintThemeKey;
extern NSString *_Nonnull const CEDefaultPrintHeaderKey;
extern NSString *_Nonnull const CEDefaultPrimaryHeaderContentKey;
extern NSString *_Nonnull const CEDefaultPrimaryHeaderAlignmentKey;
extern NSString *_Nonnull const CEDefaultSecondaryHeaderContentKey;
extern NSString *_Nonnull const CEDefaultSecondaryHeaderAlignmentKey;
extern NSString *_Nonnull const CEDefaultPrintFooterKey;
extern NSString *_Nonnull const CEDefaultPrimaryFooterContentKey;
extern NSString *_Nonnull const CEDefaultPrimaryFooterAlignmentKey;
extern NSString *_Nonnull const CEDefaultSecondaryFooterContentKey;
extern NSString *_Nonnull const CEDefaultSecondaryFooterAlignmentKey;
extern NSString *_Nonnull const CEDefaultPrintLineNumIndexKey;
extern NSString *_Nonnull const CEDefaultPrintInvisibleCharIndexKey;
extern NSString *_Nonnull const CEDefaultPrintColorIndexKey;

// find panel
extern NSString *_Nonnull const CEDefaultFindHistoryKey;
extern NSString *_Nonnull const CEDefaultReplaceHistoryKey;
extern NSString *_Nonnull const CEDefaultFindRegexSyntaxKey;
extern NSString *_Nonnull const CEDefaultFindUsesRegularExpressionKey;
extern NSString *_Nonnull const CEDefaultFindInSelectionKey;
extern NSString *_Nonnull const CEDefaultFindIsWrapKey;
extern NSString *_Nonnull const CEDefaultFindNextAfterReplaceKey;
extern NSString *_Nonnull const CEDefaultFindOptionsKey;
extern NSString *_Nonnull const CEDefaultFindClosesIndicatorWhenDoneKey;

// settings that are not in preferences
extern NSString *_Nonnull const CEDefaultInsertCustomTextArrayKey;
extern NSString *_Nonnull const CEDefaultInsertCustomTextKey;
extern NSString *_Nonnull const CEDefaultColorCodeTypeKey;
extern NSString *_Nonnull const CEDefaultSidebarWidthKey;

// hidden settings
extern NSString *_Nonnull const CEDefaultUsesTextFontForInvisiblesKey;
extern NSString *_Nonnull const CEDefaultLineNumFontNameKey;
extern NSString *_Nonnull const CEDefaultBasicColoringDelayKey;
extern NSString *_Nonnull const CEDefaultFirstColoringDelayKey;
extern NSString *_Nonnull const CEDefaultSecondColoringDelayKey;
extern NSString *_Nonnull const CEDefaultAutoCompletionDelayKey;
extern NSString *_Nonnull const CEDefaultInfoUpdateIntervalKey;
extern NSString *_Nonnull const CEDefaultIncompatibleCharIntervalKey;
extern NSString *_Nonnull const CEDefaultOutlineMenuIntervalKey;
extern NSString *_Nonnull const CEDefaultHeaderFooterDateFormatKey;
extern NSString *_Nonnull const CEDefaultHeaderFooterPathAbbreviatingWithTildeKey;
extern NSString *_Nonnull const CEDefaultTextContainerInsetWidthKey;
extern NSString *_Nonnull const CEDefaultTextContainerInsetHeightTopKey;
extern NSString *_Nonnull const CEDefaultTextContainerInsetHeightBottomKey;
extern NSString *_Nonnull const CEDefaultShowColoringIndicatorTextLengthKey;
extern NSString *_Nonnull const CEDefaultRunAppleScriptInLaunchingKey;
extern NSString *_Nonnull const CEDefaultShowAlertForNotWritableKey;
extern NSString *_Nonnull const CEDefaultNotifyEditByAnotherKey;
extern NSString *_Nonnull const CEDefaultColoringRangeBufferLengthKey;
extern NSString *_Nonnull const CEDefaultLargeFileAlertThresholdKey;
extern NSString *_Nonnull const CEDefaultAutosavingDelayKey;
extern NSString *_Nonnull const CEDefaultSavesTextOrientationKey;



// ------------------------------------------------------
// User Defaults Values
// ------------------------------------------------------

typedef NS_ENUM(NSUInteger, CEPrintColorMode) {
    CEPrintColorBlackWhite,
    CEPrintColorSameAsDocument,
};

typedef NS_ENUM(NSUInteger, CELineNumberPrintMode) {
    CELinePrintNo,
    CELinePrintSameAsDocument,
    CELinePrintYes,
};

typedef NS_ENUM(NSUInteger, CEInvisibleCharsPrintMode) {
    CEInvisibleCharsPrintNo,
    CEInvisibleCharsPrintSameAsDocument,
    CEInvisibleCharsPrintAll,
};

typedef NS_ENUM(NSUInteger, CEPrintInfoType) {
    CEPrintInfoNone,
    CEPrintInfoSyntaxName,
    CEPrintInfoDocumentName,
    CEPrintInfoFilePath,
    CEPrintInfoPrintDate,
    CEPrintInfoPageNumber,
};

typedef NS_ENUM(NSUInteger, CEAlignmentType) {
    CEAlignLeft,
    CEAlignCenter,
    CEAlignRight
};

typedef NS_ENUM(NSUInteger, CEDocumentConflictOption) {
    CEDocumentConflictIgnore,
    CEDocumentConflictNotify,
    CEDocumentConflictRevert,
};
