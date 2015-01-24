/*
 ==============================================================================
 constants
 
 CotEditor
 http://coteditor.com
 
 Created on 2004-12-13 by nakamuxu
 encoding="UTF-8"
 ------------------------------------------------------------------------------
 
 © 2004-2007 nakamuxu
 © 2014-2015 1024jp
 
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

@import AppKit;


#pragma mark General

// ------------------------------------------------------
// General
// ------------------------------------------------------

// Separator
extern NSString *const CESeparatorString;

// Error domain
extern NSString *const CEErrorDomain;

typedef NS_ENUM(OSStatus, CEErrorCode) {
    CEInvalidNameError = 1000,
    CEThemeFileDuplicationError,
    CEScriptNoTargetDocumentError,
    
    // for command-line tool
    CEApplicationNotInApplicationDirectoryError,
    CEApplicationNameIsModifiedError,
};

// Metadata dict keys
extern NSString *const CEMetadataKey;
extern NSString *const CEAuthorKey;
extern NSString *const CEDistributionURLKey;
extern NSString *const CELisenceKey;
extern NSString *const CEDescriptionKey;

// Help anchors
extern NSString *const kHelpAnchors[];


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
extern NSString *const CEDocumentDidFinishOpenNotification;

// General notification's userInfo keys
extern NSString *const CEOldNameKey;
extern NSString *const CENewNameKey;



#pragma mark User Defaults

// ------------------------------------------------------
// User Defaults Keys
// ------------------------------------------------------

// general settings
extern NSString *const CEDefaultLastVersionKey;
extern NSString *const CEDefaultLayoutTextVerticalKey;
extern NSString *const CEDefaultSplitViewVerticalKey;
extern NSString *const CEDefaultShowLineNumbersKey;
extern NSString *const CEDefaultShowDocumentInspectorKey;
extern NSString *const CEDefaultShowStatusBarKey;
extern NSString *const CEDefaultShowStatusBarLinesKey;
extern NSString *const CEDefaultShowStatusBarLengthKey;
extern NSString *const CEDefaultShowStatusBarCharsKey;
extern NSString *const CEDefaultShowStatusBarWordsKey;
extern NSString *const CEDefaultShowStatusBarLocationKey;
extern NSString *const CEDefaultShowStatusBarLineKey;
extern NSString *const CEDefaultShowStatusBarColumnKey;
extern NSString *const CEDefaultShowStatusBarEncodingKey;
extern NSString *const CEDefaultShowStatusBarLineEndingsKey;
extern NSString *const CEDefaultShowStatusBarFileSizeKey;
extern NSString *const CEDefaultShowNavigationBarKey;
extern NSString *const CEDefaultCountLineEndingAsCharKey;
extern NSString *const CEDefaultSyncFindPboardKey;
extern NSString *const CEDefaultInlineContextualScriptMenuKey;
extern NSString *const CEDefaultWrapLinesKey;
extern NSString *const CEDefaultLineEndCharCodeKey;
extern NSString *const CEDefaultEncodingListKey;
extern NSString *const CEDefaultFontNameKey;
extern NSString *const CEDefaultFontSizeKey;
extern NSString *const CEDefaultEncodingInOpenKey;
extern NSString *const CEDefaultEncodingInNewKey;
extern NSString *const CEDefaultReferToEncodingTagKey;
extern NSString *const CEDefaultCreateNewAtStartupKey;
extern NSString *const CEDefaultReopenBlankWindowKey;
extern NSString *const CEDefaultCheckSpellingAsTypeKey;
extern NSString *const CEDefaultWindowWidthKey;
extern NSString *const CEDefaultWindowHeightKey;
extern NSString *const CEDefaultWindowAlphaKey;
extern NSString *const CEDefaultAutoExpandTabKey;
extern NSString *const CEDefaultTabWidthKey;
extern NSString *const CEDefaultAutoIndentKey;
extern NSString *const CEDefaultShowInvisiblesKey;
extern NSString *const CEDefaultShowInvisibleSpaceKey;
extern NSString *const CEDefaultInvisibleSpaceKey;
extern NSString *const CEDefaultShowInvisibleTabKey;
extern NSString *const CEDefaultInvisibleTabKey;
extern NSString *const CEDefaultShowInvisibleNewLineKey;
extern NSString *const CEDefaultInvisibleNewLineKey;
extern NSString *const CEDefaultShowInvisibleFullwidthSpaceKey;
extern NSString *const CEDefaultInvisibleFullwidthSpaceKey;
extern NSString *const CEDefaultShowOtherInvisibleCharsKey;
extern NSString *const CEDefaultHighlightCurrentLineKey;
extern NSString *const CEDefaultEnableSyntaxHighlightKey;
extern NSString *const CEDefaultSyntaxStyleKey;
extern NSString *const CEDefaultThemeKey;
extern NSString *const CEDefaultDelayColoringKey;
extern NSString *const CEDefaultFileDropArrayKey;
extern NSString *const CEDefaultSmartInsertAndDeleteKey;
extern NSString *const CEDefaultShouldAntialiasKey;
extern NSString *const CEDefaultAutoCompleteKey;
extern NSString *const CEDefaultCompletionWordsKey;
extern NSString *const CEDefaultShowPageGuideKey;
extern NSString *const CEDefaultPageGuideColumnKey;
extern NSString *const CEDefaultLineSpacingKey;
extern NSString *const CEDefaultSwapYenAndBackSlashKey;
extern NSString *const CEDefaultFixLineHeightKey;
extern NSString *const CEDefaultHighlightBracesKey;
extern NSString *const CEDefaultHighlightLtGtKey;
extern NSString *const CEDefaultSaveUTF8BOMKey;
extern NSString *const CEDefaultEnableSmartQuotesKey;
extern NSString *const CEDefaultEnableSmartIndentKey;
extern NSString *const CEDefaultAppendsCommentSpacerKey;
extern NSString *const CEDefaultCommentsAtLineHeadKey;

// print settings
extern NSString *const CEDefaultSetPrintFontKey;
extern NSString *const CEDefaultPrintFontNameKey;
extern NSString *const CEDefaultPrintFontSizeKey;
extern NSString *const CEDefaultPrintThemeKey;
extern NSString *const CEDefaultPrintHeaderKey;
extern NSString *const CEDefaultHeaderOneStringIndexKey;
extern NSString *const CEDefaultHeaderTwoStringIndexKey;
extern NSString *const CEDefaultHeaderOneAlignIndexKey;
extern NSString *const CEDefaultHeaderTwoAlignIndexKey;
extern NSString *const CEDefaultPrintHeaderSeparatorKey;
extern NSString *const CEDefaultPrintFooterKey;
extern NSString *const CEDefaultFooterOneStringIndexKey;
extern NSString *const CEDefaultFooterTwoStringIndexKey;
extern NSString *const CEDefaultFooterOneAlignIndexKey;
extern NSString *const CEDefaultFooterTwoAlignIndexKey;
extern NSString *const CEDefaultPrintFooterSeparatorKey;
extern NSString *const CEDefaultPrintLineNumIndexKey;
extern NSString *const CEDefaultPrintInvisibleCharIndexKey;
extern NSString *const CEDefaultPrintColorIndexKey;

// find panel
extern NSString *const CEDefaultFindHistoryKey;
extern NSString *const CEDefaultReplaceHistoryKey;
extern NSString *const CEDefaultFindRegexSyntaxKey;
extern NSString *const CEDefaultFindEscapeCharacterKey;
extern NSString *const CEDefaultFindUsesRegularExpressionKey;
extern NSString *const CEDefaultFindInSelectionKey;
extern NSString *const CEDefaultFindIsWrapKey;
extern NSString *const CEDefaultFindOptionsKey;
extern NSString *const CEDefaultFindClosesIndicatorWhenDoneKey;

// settings that are not in preferences
extern NSString *const CEDefaultInsertCustomTextArrayKey;
extern NSString *const CEDefaultInsertCustomTextKey;
extern NSString *const CEDefaultColorCodeTypeKey;
extern NSString *const CEDefaultSidebarWidthKey;

// hidden settings
extern NSString *const CEDefaultUsesTextFontForInvisiblesKey;
extern NSString *const CEDefaultLineNumFontNameKey;
extern NSString *const CEDefaultBasicColoringDelayKey;
extern NSString *const CEDefaultFirstColoringDelayKey;
extern NSString *const CEDefaultSecondColoringDelayKey;
extern NSString *const CEDefaultAutoCompletionDelayKey;
extern NSString *const CEDefaultLineNumUpdateIntervalKey;
extern NSString *const CEDefaultInfoUpdateIntervalKey;
extern NSString *const CEDefaultIncompatibleCharIntervalKey;
extern NSString *const CEDefaultOutlineMenuIntervalKey;
extern NSString *const CEDefaultOutlineMenuMaxLengthKey;
extern NSString *const CEDefaultHeaderFooterFontNameKey;
extern NSString *const CEDefaultHeaderFooterFontSizeKey;
extern NSString *const CEDefaultHeaderFooterDateFormatKey;
extern NSString *const CEDefaultHeaderFooterPathAbbreviatingWithTildeKey;
extern NSString *const CEDefaultTextContainerInsetWidthKey;
extern NSString *const CEDefaultTextContainerInsetHeightTopKey;
extern NSString *const CEDefaultTextContainerInsetHeightBottomKey;
extern NSString *const CEDefaultShowColoringIndicatorTextLengthKey;
extern NSString *const CEDefaultRunAppleScriptInLaunchingKey;
extern NSString *const CEDefaultShowAlertForNotWritableKey;
extern NSString *const CEDefaultNotifyEditByAnotherKey;
extern NSString *const CEDefaultColoringRangeBufferLengthKey;
extern NSString *const CEDefaultLargeFileAlertThresholdKey;



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
extern NSString  *const kAllAlphabetChars;

// syntax style keys
extern NSString *const CESyntaxMetadataKey;
extern NSString *const CESyntaxExtensionsKey;
extern NSString *const CESyntaxFileNamesKey;
extern NSString *const CESyntaxKeywordsKey;
extern NSString *const CESyntaxCommandsKey;
extern NSString *const CESyntaxTypesKey;
extern NSString *const CESyntaxAttributesKey;
extern NSString *const CESyntaxVariablesKey;
extern NSString *const CESyntaxValuesKey;
extern NSString *const CESyntaxNumbersKey;
extern NSString *const CESyntaxStringsKey;
extern NSString *const CESyntaxCharactersKey;
extern NSString *const CESyntaxCommentsKey;
extern NSString *const CESyntaxCommentDelimitersKey;
extern NSString *const CESyntaxOutlineMenuKey;
extern NSString *const CESyntaxCompletionsKey;
extern NSString *const kAllColoringKeys[];
extern NSUInteger const kSizeOfAllColoringKeys;

extern NSString *const CESyntaxKeyStringKey;
extern NSString *const CESyntaxBeginStringKey;
extern NSString *const CESyntaxEndStringKey;
extern NSString *const CESyntaxIgnoreCaseKey;
extern NSString *const CESyntaxRegularExpressionKey;

extern NSString *const CESyntaxInlineCommentKey;
extern NSString *const CESyntaxBeginCommentKey;
extern NSString *const CESyntaxEndCommentKey;

extern NSString *const CESyntaxBoldKey;
extern NSString *const CESyntaxUnderlineKey;
extern NSString *const CESyntaxItalicKey;

// comment delimiter keys
extern NSString *const CEBeginDelimiterKey;
extern NSString *const CEEndDelimiterKey;



#pragma mark File Drop

// ------------------------------------------------------
// File Drop
// ------------------------------------------------------

// keys for dicts in CEDefaultFileDropArrayKey
extern NSString *const CEFileDropExtensionsKey;
extern NSString *const CEFileDropFormatStringKey;

// tokens
extern NSString *const CEFileDropAbsolutePathToken;
extern NSString *const CEFileDropRelativePathToken;
extern NSString *const CEFileDropFilenameToken;
extern NSString *const CEFileDropFilenameNosuffixToken;
extern NSString *const CEFileDropFileextensionToken;
extern NSString *const CEFileDropFileextensionLowerToken;
extern NSString *const CEFileDropFileextensionUpperToken;
extern NSString *const CEFileDropDirectoryToken;
extern NSString *const CEFileDropImagewidthToken;
extern NSString *const CEFileDropImagehightToken;



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
    CEWindowPanelsMenuItemTag   = 7999,  // const to not list up in "Menu Key Bindings" setting
    CEScriptMenuDirectoryTag    = 8999,  // const to not list up in "Menu Key Bindings" setting
    
    // in script menu
    CEDefaultScriptMenuItemTag  = 8001,  // const to not list up in context menu
    
    // in contextual menu
    CEUtilityMenuItemTag        =  600,
    CEScriptMenuItemTag         =  800,
};

// Help document file names table
extern NSString *const kBundledDocumentFileNames[];

// Online URLs
extern NSString *const kWebSiteURL;
extern NSString *const kIssueTrackerURL;



#pragma mark CEEditorWrapper

// ------------------------------------------------------
// CEEditorWrapper
// ------------------------------------------------------

// Outline item dict keys
extern NSString *const CEOutlineItemTitleKey;
extern NSString *const CEOutlineItemRangeKey;
extern NSString *const CEOutlineItemSortKeyKey;
extern NSString *const CEOutlineItemFontBoldKey;
extern NSString *const CEOutlineItemFontItalicKey;
extern NSString *const CEOutlineItemUnderlineMaskKey;

// layout constants
extern CGFloat const kLineNumPadding;
extern NSString *const kNavigationBarFontName;



#pragma mark CEATSTypeSetter

// ------------------------------------------------------
// CEATSTypeSetter
// ------------------------------------------------------

// CEATSTypeSetter (Layouting)
extern CGFloat const kDefaultLineHeightMultiple;



#pragma mark Print

// ------------------------------------------------------
// Print
// ------------------------------------------------------

extern CGFloat const kPrintTextHorizontalMargin;  // left/light margin for text
extern CGFloat const kPrintHFHorizontalMargin;    // left/light margin for header/footer
extern CGFloat const kPrintHFVerticalMargin;      // top/bottom margin for header/footer
extern CGFloat const kHeaderFooterLineHeight;
extern CGFloat const kSeparatorPadding;
extern CGFloat const kNoSeparatorPadding;



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
