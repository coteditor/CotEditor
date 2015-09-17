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
extern NSString *_Nonnull const CESeparatorString;

// Exported UTI
extern NSString *_Nonnull const CEUTTypeTheme;

// Error domain
extern NSString *_Nonnull const CEErrorDomain;

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
extern NSString *_Nonnull const CEMetadataKey;
extern NSString *_Nonnull const CEAuthorKey;
extern NSString *_Nonnull const CEDistributionURLKey;
extern NSString *_Nonnull const CELicenseKey;
extern NSString *_Nonnull const CEDescriptionKey;

// Help anchors
extern NSString *_Nonnull const kHelpAnchors[];


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
extern NSString *_Nonnull const CEDocumentDidFinishOpenNotification;

// General notification's userInfo keys
extern NSString *_Nonnull const CEOldNameKey;
extern NSString *_Nonnull const CENewNameKey;



#pragma mark User Defaults

// ------------------------------------------------------
// User Defaults Keys
// ------------------------------------------------------

// general settings
extern NSString *_Nonnull const CEDefaultLastVersionKey;
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
extern NSString *_Nonnull const CEDefaultEnableSmartQuotesKey;
extern NSString *_Nonnull const CEDefaultEnableSmartIndentKey;
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
extern NSString *_Nonnull const CEDefaultEnablesAutosaveInPlaceKey;
extern NSString *_Nonnull const CEDefaultSavesTextOrientationKey;
extern NSString *_Nonnull const CEDefaultCotCommandBookmarkKey;



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
extern NSString *_Nonnull const kAllAlphabetChars;

// syntax style keys
extern NSString *_Nonnull const CESyntaxMetadataKey;
extern NSString *_Nonnull const CESyntaxExtensionsKey;
extern NSString *_Nonnull const CESyntaxFileNamesKey;
extern NSString *_Nonnull const CESyntaxInterpretersKey;
extern NSString *_Nonnull const CESyntaxKeywordsKey;
extern NSString *_Nonnull const CESyntaxCommandsKey;
extern NSString *_Nonnull const CESyntaxTypesKey;
extern NSString *_Nonnull const CESyntaxAttributesKey;
extern NSString *_Nonnull const CESyntaxVariablesKey;
extern NSString *_Nonnull const CESyntaxValuesKey;
extern NSString *_Nonnull const CESyntaxNumbersKey;
extern NSString *_Nonnull const CESyntaxStringsKey;
extern NSString *_Nonnull const CESyntaxCharactersKey;
extern NSString *_Nonnull const CESyntaxCommentsKey;
extern NSString *_Nonnull const CESyntaxCommentDelimitersKey;
extern NSString *_Nonnull const CESyntaxOutlineMenuKey;
extern NSString *_Nonnull const CESyntaxCompletionsKey;
extern NSString *_Nonnull const kAllColoringKeys[];
extern NSUInteger const kSizeOfAllColoringKeys;

extern NSString *_Nonnull const CESyntaxKeyStringKey;
extern NSString *_Nonnull const CESyntaxBeginStringKey;
extern NSString *_Nonnull const CESyntaxEndStringKey;
extern NSString *_Nonnull const CESyntaxIgnoreCaseKey;
extern NSString *_Nonnull const CESyntaxRegularExpressionKey;

extern NSString *_Nonnull const CESyntaxInlineCommentKey;
extern NSString *_Nonnull const CESyntaxBeginCommentKey;
extern NSString *_Nonnull const CESyntaxEndCommentKey;

extern NSString *_Nonnull const CESyntaxBoldKey;
extern NSString *_Nonnull const CESyntaxUnderlineKey;
extern NSString *_Nonnull const CESyntaxItalicKey;

// comment delimiter keys
extern NSString *_Nonnull const CEBeginDelimiterKey;
extern NSString *_Nonnull const CEEndDelimiterKey;



#pragma mark File Drop

// ------------------------------------------------------
// File Drop
// ------------------------------------------------------

// keys for dicts in CEDefaultFileDropArrayKey
extern NSString *_Nonnull const CEFileDropExtensionsKey;
extern NSString *_Nonnull const CEFileDropFormatStringKey;

// tokens
extern NSString *_Nonnull const CEFileDropAbsolutePathToken;
extern NSString *_Nonnull const CEFileDropRelativePathToken;
extern NSString *_Nonnull const CEFileDropFilenameToken;
extern NSString *_Nonnull const CEFileDropFilenameNosuffixToken;
extern NSString *_Nonnull const CEFileDropFileextensionToken;
extern NSString *_Nonnull const CEFileDropFileextensionLowerToken;
extern NSString *_Nonnull const CEFileDropFileextensionUpperToken;
extern NSString *_Nonnull const CEFileDropDirectoryToken;
extern NSString *_Nonnull const CEFileDropImagewidthToken;
extern NSString *_Nonnull const CEFileDropImagehightToken;



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
extern NSString *_Nonnull const kBundledDocumentFileNames[];

// Online URLs
extern NSString *_Nonnull const kWebSiteURL;
extern NSString *_Nonnull const kIssueTrackerURL;



#pragma mark CEEditorWrapper

// ------------------------------------------------------
// CEEditorWrapper
// ------------------------------------------------------

// Outline item dict keys
extern NSString *_Nonnull const CEOutlineItemTitleKey;
extern NSString *_Nonnull const CEOutlineItemRangeKey;
extern NSString *_Nonnull const CEOutlineItemStyleBoldKey;
extern NSString *_Nonnull const CEOutlineItemStyleItalicKey;
extern NSString *_Nonnull const CEOutlineItemStyleUnderlineKey;

// layout constants
extern NSString *_Nonnull const kNavigationBarFontName;



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
