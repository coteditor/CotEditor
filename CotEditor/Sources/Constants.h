/*
 
 Constants.h
 
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

@import AppKit;


#pragma mark General

// ------------------------------------------------------
// General
// ------------------------------------------------------

// Separator
extern NSString *__nonnull const CESeparatorString;

// Exported UTI
extern NSString *__nonnull const CEUTTypeTheme;

// Error domain
extern NSString *__nonnull const CEErrorDomain;

typedef NS_ENUM(OSStatus, CEErrorCode) {
    CEInvalidNameError = 1000,
    CEThemeFileDuplicationError,
    CEScriptNoTargetDocumentError,
    
    // encoding errors
    CEIANACharsetNameConflictError,
    CEUnconvertibleCharactersError,
    CEReinterpretationFailedError,
    
    // for command-line tool
    CEApplicationNotInApplicationDirectoryError,
    CEApplicationNameIsModifiedError,
    CESymlinkCreationDeniedError,
};

// Metadata dict keys
extern NSString *__nonnull const CEMetadataKey;
extern NSString *__nonnull const CEAuthorKey;
extern NSString *__nonnull const CEDistributionURLKey;
extern NSString *__nonnull const CELicenseKey;
extern NSString *__nonnull const CEDescriptionKey;

// Help anchors
extern NSString *__nonnull const kHelpAnchors[];


// labels for system sound ID on AudioToolbox (There are no constants provided by Apple)
typedef NS_ENUM(UInt32, CESystemSoundID) {
    CESystemSoundID_MoveToTrash = 0x10,
};


// Convenient functions
/// compare CGFloats
BOOL CEIsAlmostEqualCGFloats(CGFloat float1, CGFloat float2);



#pragma mark Notifications

// ------------------------------------------------------
// Notifications
// ------------------------------------------------------

// Notification name
extern NSString *__nonnull const CEDocumentDidFinishOpenNotification;

// General notification's userInfo keys
extern NSString *__nonnull const CEOldNameKey;
extern NSString *__nonnull const CENewNameKey;



#pragma mark User Defaults

// ------------------------------------------------------
// User Defaults Keys
// ------------------------------------------------------

// general settings
extern NSString *__nonnull const CEDefaultLastVersionKey;
extern NSString *__nonnull const CEDefaultDocumentConflictOptionKey;
extern NSString *__nonnull const CEDefaultLayoutTextVerticalKey;
extern NSString *__nonnull const CEDefaultSplitViewVerticalKey;
extern NSString *__nonnull const CEDefaultShowLineNumbersKey;
extern NSString *__nonnull const CEDefaultShowDocumentInspectorKey;
extern NSString *__nonnull const CEDefaultShowStatusBarKey;
extern NSString *__nonnull const CEDefaultShowStatusBarLinesKey;
extern NSString *__nonnull const CEDefaultShowStatusBarLengthKey;
extern NSString *__nonnull const CEDefaultShowStatusBarCharsKey;
extern NSString *__nonnull const CEDefaultShowStatusBarWordsKey;
extern NSString *__nonnull const CEDefaultShowStatusBarLocationKey;
extern NSString *__nonnull const CEDefaultShowStatusBarLineKey;
extern NSString *__nonnull const CEDefaultShowStatusBarColumnKey;
extern NSString *__nonnull const CEDefaultShowStatusBarEncodingKey;
extern NSString *__nonnull const CEDefaultShowStatusBarLineEndingsKey;
extern NSString *__nonnull const CEDefaultShowStatusBarFileSizeKey;
extern NSString *__nonnull const CEDefaultShowNavigationBarKey;
extern NSString *__nonnull const CEDefaultCountLineEndingAsCharKey;
extern NSString *__nonnull const CEDefaultSyncFindPboardKey;
extern NSString *__nonnull const CEDefaultInlineContextualScriptMenuKey;
extern NSString *__nonnull const CEDefaultWrapLinesKey;
extern NSString *__nonnull const CEDefaultLineEndCharCodeKey;
extern NSString *__nonnull const CEDefaultEncodingListKey;
extern NSString *__nonnull const CEDefaultFontNameKey;
extern NSString *__nonnull const CEDefaultFontSizeKey;
extern NSString *__nonnull const CEDefaultEncodingInOpenKey;
extern NSString *__nonnull const CEDefaultEncodingInNewKey;
extern NSString *__nonnull const CEDefaultReferToEncodingTagKey;
extern NSString *__nonnull const CEDefaultCreateNewAtStartupKey;
extern NSString *__nonnull const CEDefaultReopenBlankWindowKey;
extern NSString *__nonnull const CEDefaultCheckSpellingAsTypeKey;
extern NSString *__nonnull const CEDefaultWindowWidthKey;
extern NSString *__nonnull const CEDefaultWindowHeightKey;
extern NSString *__nonnull const CEDefaultWindowAlphaKey;
extern NSString *__nonnull const CEDefaultAutoExpandTabKey;
extern NSString *__nonnull const CEDefaultTabWidthKey;
extern NSString *__nonnull const CEDefaultAutoIndentKey;
extern NSString *__nonnull const CEDefaultEnablesHangingIndentKey;
extern NSString *__nonnull const CEDefaultHangingIndentWidthKey;
extern NSString *__nonnull const CEDefaultShowInvisiblesKey;
extern NSString *__nonnull const CEDefaultShowInvisibleSpaceKey;
extern NSString *__nonnull const CEDefaultInvisibleSpaceKey;
extern NSString *__nonnull const CEDefaultShowInvisibleTabKey;
extern NSString *__nonnull const CEDefaultInvisibleTabKey;
extern NSString *__nonnull const CEDefaultShowInvisibleNewLineKey;
extern NSString *__nonnull const CEDefaultInvisibleNewLineKey;
extern NSString *__nonnull const CEDefaultShowInvisibleFullwidthSpaceKey;
extern NSString *__nonnull const CEDefaultInvisibleFullwidthSpaceKey;
extern NSString *__nonnull const CEDefaultShowOtherInvisibleCharsKey;
extern NSString *__nonnull const CEDefaultHighlightCurrentLineKey;
extern NSString *__nonnull const CEDefaultEnableSyntaxHighlightKey;
extern NSString *__nonnull const CEDefaultSyntaxStyleKey;
extern NSString *__nonnull const CEDefaultThemeKey;
extern NSString *__nonnull const CEDefaultDelayColoringKey;
extern NSString *__nonnull const CEDefaultFileDropArrayKey;
extern NSString *__nonnull const CEDefaultSmartInsertAndDeleteKey;
extern NSString *__nonnull const CEDefaultShouldAntialiasKey;
extern NSString *__nonnull const CEDefaultAutoCompleteKey;
extern NSString *__nonnull const CEDefaultCompletesDocumentWordsKey;
extern NSString *__nonnull const CEDefaultCompletesSyntaxWordsKey;
extern NSString *__nonnull const CEDefaultCompletesStandartWordsKey;
extern NSString *__nonnull const CEDefaultShowPageGuideKey;
extern NSString *__nonnull const CEDefaultPageGuideColumnKey;
extern NSString *__nonnull const CEDefaultLineSpacingKey;
extern NSString *__nonnull const CEDefaultSwapYenAndBackSlashKey;
extern NSString *__nonnull const CEDefaultFixLineHeightKey;
extern NSString *__nonnull const CEDefaultHighlightBracesKey;
extern NSString *__nonnull const CEDefaultHighlightLtGtKey;
extern NSString *__nonnull const CEDefaultSaveUTF8BOMKey;
extern NSString *__nonnull const CEDefaultEnableSmartQuotesKey;
extern NSString *__nonnull const CEDefaultEnableSmartIndentKey;
extern NSString *__nonnull const CEDefaultAppendsCommentSpacerKey;
extern NSString *__nonnull const CEDefaultCommentsAtLineHeadKey;
extern NSString *__nonnull const CEDefaultChecksUpdatesForBetaKey;

// print settings
extern NSString *__nonnull const CEDefaultSetPrintFontKey;
extern NSString *__nonnull const CEDefaultPrintFontNameKey;
extern NSString *__nonnull const CEDefaultPrintFontSizeKey;
extern NSString *__nonnull const CEDefaultPrintThemeKey;
extern NSString *__nonnull const CEDefaultPrintHeaderKey;
extern NSString *__nonnull const CEDefaultPrimaryHeaderContentKey;
extern NSString *__nonnull const CEDefaultPrimaryHeaderAlignmentKey;
extern NSString *__nonnull const CEDefaultSecondaryHeaderContentKey;
extern NSString *__nonnull const CEDefaultSecondaryHeaderAlignmentKey;
extern NSString *__nonnull const CEDefaultPrintFooterKey;
extern NSString *__nonnull const CEDefaultPrimaryFooterContentKey;
extern NSString *__nonnull const CEDefaultPrimaryFooterAlignmentKey;
extern NSString *__nonnull const CEDefaultSecondaryFooterContentKey;
extern NSString *__nonnull const CEDefaultSecondaryFooterAlignmentKey;
extern NSString *__nonnull const CEDefaultPrintLineNumIndexKey;
extern NSString *__nonnull const CEDefaultPrintInvisibleCharIndexKey;
extern NSString *__nonnull const CEDefaultPrintColorIndexKey;

// find panel
extern NSString *__nonnull const CEDefaultFindHistoryKey;
extern NSString *__nonnull const CEDefaultReplaceHistoryKey;
extern NSString *__nonnull const CEDefaultFindRegexSyntaxKey;
extern NSString *__nonnull const CEDefaultFindUsesRegularExpressionKey;
extern NSString *__nonnull const CEDefaultFindInSelectionKey;
extern NSString *__nonnull const CEDefaultFindIsWrapKey;
extern NSString *__nonnull const CEDefaultFindNextAfterReplaceKey;
extern NSString *__nonnull const CEDefaultFindOptionsKey;
extern NSString *__nonnull const CEDefaultFindClosesIndicatorWhenDoneKey;

// settings that are not in preferences
extern NSString *__nonnull const CEDefaultInsertCustomTextArrayKey;
extern NSString *__nonnull const CEDefaultInsertCustomTextKey;
extern NSString *__nonnull const CEDefaultColorCodeTypeKey;
extern NSString *__nonnull const CEDefaultSidebarWidthKey;

// hidden settings
extern NSString *__nonnull const CEDefaultUsesTextFontForInvisiblesKey;
extern NSString *__nonnull const CEDefaultLineNumFontNameKey;
extern NSString *__nonnull const CEDefaultBasicColoringDelayKey;
extern NSString *__nonnull const CEDefaultFirstColoringDelayKey;
extern NSString *__nonnull const CEDefaultSecondColoringDelayKey;
extern NSString *__nonnull const CEDefaultAutoCompletionDelayKey;
extern NSString *__nonnull const CEDefaultInfoUpdateIntervalKey;
extern NSString *__nonnull const CEDefaultIncompatibleCharIntervalKey;
extern NSString *__nonnull const CEDefaultOutlineMenuIntervalKey;
extern NSString *__nonnull const CEDefaultHeaderFooterDateFormatKey;
extern NSString *__nonnull const CEDefaultHeaderFooterPathAbbreviatingWithTildeKey;
extern NSString *__nonnull const CEDefaultTextContainerInsetWidthKey;
extern NSString *__nonnull const CEDefaultTextContainerInsetHeightTopKey;
extern NSString *__nonnull const CEDefaultTextContainerInsetHeightBottomKey;
extern NSString *__nonnull const CEDefaultShowColoringIndicatorTextLengthKey;
extern NSString *__nonnull const CEDefaultRunAppleScriptInLaunchingKey;
extern NSString *__nonnull const CEDefaultShowAlertForNotWritableKey;
extern NSString *__nonnull const CEDefaultNotifyEditByAnotherKey;
extern NSString *__nonnull const CEDefaultColoringRangeBufferLengthKey;
extern NSString *__nonnull const CEDefaultLargeFileAlertThresholdKey;
extern NSString *__nonnull const CEDefaultAutosavingDelayKey;
extern NSString *__nonnull const CEDefaultEnablesAutosaveInPlaceKey;
extern NSString *__nonnull const CEDefaultSavesTextOrientationKey;
extern NSString *__nonnull const CEDefaultCotCommandBookmarkKey;



// ------------------------------------------------------
// User Defaults Values
// ------------------------------------------------------

typedef NS_ENUM(NSUInteger, CEColorPrintMode) {
    CEBlackColorPrint,
    CESameAsDocumentColorPrint
};

typedef NS_ENUM(NSUInteger, CELineNumberPrintMode) {
    CENoLinePrint,
    CESameAsDocumentLinePrint,
    CEDoLinePrint
};

typedef NS_ENUM(NSUInteger, CEInvisibleCharsPrintMode) {
    CENoInvisibleCharsPrint,
    CESameAsDocumentInvisibleCharsPrint,
    CEAllInvisibleCharsPrint
};

typedef NS_ENUM(NSUInteger, CEPrintInfoType) {
    CENoPrintInfo,
    CESyntaxNamePrintInfo,
    CEDocumentNamePrintInfo,
    CEFilePathPrintInfo,
    CEPrintDatePrintInfo,
    CEPageNumberPrintInfo
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



// ------------------------------------------------------
// Setting thresholds
// ------------------------------------------------------

// Page guide column
extern NSUInteger const kMinPageGuideColumn;
extern NSUInteger const kMaxPageGuideColumn;



#pragma mark Syntax

// ------------------------------------------------------
// Syntax
// ------------------------------------------------------

// syntax parsing
extern NSUInteger const kMaxEscapesCheckLength;
extern NSString  *__nonnull const kAllAlphabetChars;

// syntax style keys
extern NSString *__nonnull const CESyntaxMetadataKey;
extern NSString *__nonnull const CESyntaxExtensionsKey;
extern NSString *__nonnull const CESyntaxFileNamesKey;
extern NSString *__nonnull const CESyntaxInterpretersKey;
extern NSString *__nonnull const CESyntaxKeywordsKey;
extern NSString *__nonnull const CESyntaxCommandsKey;
extern NSString *__nonnull const CESyntaxTypesKey;
extern NSString *__nonnull const CESyntaxAttributesKey;
extern NSString *__nonnull const CESyntaxVariablesKey;
extern NSString *__nonnull const CESyntaxValuesKey;
extern NSString *__nonnull const CESyntaxNumbersKey;
extern NSString *__nonnull const CESyntaxStringsKey;
extern NSString *__nonnull const CESyntaxCharactersKey;
extern NSString *__nonnull const CESyntaxCommentsKey;
extern NSString *__nonnull const CESyntaxCommentDelimitersKey;
extern NSString *__nonnull const CESyntaxOutlineMenuKey;
extern NSString *__nonnull const CESyntaxCompletionsKey;
extern NSString *__nonnull const kAllColoringKeys[];
extern NSUInteger const kSizeOfAllColoringKeys;

extern NSString *__nonnull const CESyntaxKeyStringKey;
extern NSString *__nonnull const CESyntaxBeginStringKey;
extern NSString *__nonnull const CESyntaxEndStringKey;
extern NSString *__nonnull const CESyntaxIgnoreCaseKey;
extern NSString *__nonnull const CESyntaxRegularExpressionKey;

extern NSString *__nonnull const CESyntaxInlineCommentKey;
extern NSString *__nonnull const CESyntaxBeginCommentKey;
extern NSString *__nonnull const CESyntaxEndCommentKey;

extern NSString *__nonnull const CESyntaxBoldKey;
extern NSString *__nonnull const CESyntaxUnderlineKey;
extern NSString *__nonnull const CESyntaxItalicKey;

// comment delimiter keys
extern NSString *__nonnull const CEBeginDelimiterKey;
extern NSString *__nonnull const CEEndDelimiterKey;



#pragma mark File Drop

// ------------------------------------------------------
// File Drop
// ------------------------------------------------------

// keys for dicts in CEDefaultFileDropArrayKey
extern NSString *__nonnull const CEFileDropExtensionsKey;
extern NSString *__nonnull const CEFileDropFormatStringKey;

// tokens
extern NSString *__nonnull const CEFileDropAbsolutePathToken;
extern NSString *__nonnull const CEFileDropRelativePathToken;
extern NSString *__nonnull const CEFileDropFilenameToken;
extern NSString *__nonnull const CEFileDropFilenameNosuffixToken;
extern NSString *__nonnull const CEFileDropFileextensionToken;
extern NSString *__nonnull const CEFileDropFileextensionLowerToken;
extern NSString *__nonnull const CEFileDropFileextensionUpperToken;
extern NSString *__nonnull const CEFileDropDirectoryToken;
extern NSString *__nonnull const CEFileDropImagewidthToken;
extern NSString *__nonnull const CEFileDropImagehightToken;



#pragma mark Main Menu

// ------------------------------------------------------
// Main Menu
// ------------------------------------------------------

// Main menu indexes
typedef NS_ENUM(NSUInteger, CEMainMenuIndex) {
    CEApplicationMenuIndex,
    CEFileMenuIndex,
    CEEditMenuIndex,
    CEViewMenuIndex,
    CEFormatMenuIndex,
    CEFindMenuIndex,
    CEUtilityMenuIndex,
    CEWindowMenuIndex,
    CEScriptMenuIndex,
};

// Menu item tags
typedef NS_ENUM(NSInteger, CEMenuItemTag) {
    // in main menu
    CEFileEncodingMenuItemTag   = 4001,
    CESyntaxMenuItemTag         = 4002,
    CEThemeMenuItemTag          = 4003,
    CEServicesMenuItemTag       =  999,  // const to not list up in "Menu Key Bindings" setting
    CEScriptMenuDirectoryTag    = 8999,  // const to not list up in "Menu Key Bindings" setting
    
    // in script menu
    CEDefaultScriptMenuItemTag  = 8001,  // const to not list up in context menu
    
    // in contextual menu
    CEUtilityMenuItemTag        =  600,
    CEScriptMenuItemTag         =  800,
};

// Help document file names table
extern NSString *__nonnull const kBundledDocumentFileNames[];

// Online URLs
extern NSString *__nonnull const kWebSiteURL;
extern NSString *__nonnull const kIssueTrackerURL;



#pragma mark CEEditorWrapper

// ------------------------------------------------------
// CEEditorWrapper
// ------------------------------------------------------

// Outline item dict keys
extern NSString *__nonnull const CEOutlineItemTitleKey;
extern NSString *__nonnull const CEOutlineItemRangeKey;
extern NSString *__nonnull const CEOutlineItemStyleBoldKey;
extern NSString *__nonnull const CEOutlineItemStyleItalicKey;
extern NSString *__nonnull const CEOutlineItemStyleUnderlineKey;

// layout constants
extern NSString *__nonnull const kNavigationBarFontName;



#pragma mark CEATSTypeSetter

// ------------------------------------------------------
// CEATSTypeSetter
// ------------------------------------------------------

// CEATSTypeSetter (Layouting)
extern CGFloat const kDefaultLineHeightMultiple;



#pragma mark Encodings

// ------------------------------------------------------
// Encodings
// ------------------------------------------------------

// Original special encoding type
extern NSInteger const CEAutoDetectEncoding;

// Max length to scan encoding declaration
extern NSUInteger        const kMaxEncodingScanLength;

// Encodings list
extern CFStringEncodings const kCFStringEncodingList[];
extern NSUInteger        const kSizeOfCFStringEncodingList;

// Encodings that need convert Yen mark to back-slash
extern CFStringEncodings const kCFStringEncodingInvalidYenList[];
extern NSUInteger        const kSizeOfCFStringEncodingInvalidYenList;

// Yen mark char
extern unichar const kYenMark;



// ------------------------------------------------------
// Invisibles
// ------------------------------------------------------

// Substitutes for invisible characters
extern unichar    const kInvisibleSpaceCharList[];
extern NSUInteger const kSizeOfInvisibleSpaceCharList;

extern unichar    const kInvisibleTabCharList[];
extern NSUInteger const kSizeOfInvisibleTabCharList;

extern unichar    const kInvisibleNewLineCharList[];
extern NSUInteger const kSizeOfInvisibleNewLineCharList;

extern unichar    const kInvisibleFullwidthSpaceCharList[];
extern NSUInteger const kSizeOfInvisibleFullwidthSpaceCharList;

extern unichar const kVerticalTabChar;



// ------------------------------------------------------
// Keybindings
// ------------------------------------------------------

// Modifier masks and characters for keybindings
extern NSEventModifierFlags const kModifierKeyMaskList[];
extern unichar const kModifierKeySymbolCharList[];
extern unichar const kKeySpecCharList[];

// size of kModifierKeyMaskList, kKeySpecCharList and kModifierKeySymbolCharList
extern NSUInteger const kSizeOfModifierKeys;
// indexes of kModifierKeyMaskList, kKeySpecCharList and kModifierKeySymbolCharList
typedef NS_ENUM(NSUInteger, CEModifierKeyIndex) {
    CEControlKeyIndex,
    CEAlternateKeyIndex,
    CEShiftKeyIndex,
    CECommandKeyIndex,
};

// Unprintable key list
extern unichar    const kUnprintableKeyList[];
extern NSUInteger const kSizeOfUnprintableKeyList;
