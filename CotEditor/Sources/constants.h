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
};

// Localized Strings Table
extern NSString *const k_printLocalizeTable;



#pragma mark Notifications

// ------------------------------------------------------
// Notifications
// ------------------------------------------------------

// Notification name
extern NSString *const CEEncodingListDidUpdateNotification;
extern NSString *const CEDocumentDidFinishOpenNotification;

// General notification's userInfo keys
extern NSString *const CEOldNameKey;
extern NSString *const CENewNameKey;



#pragma mark User Defaults

// ------------------------------------------------------
// User Defaults Keys
// ------------------------------------------------------

// normal settings
extern NSString *const CEDefaultLayoutTextVerticalKey;
extern NSString *const CEDefaultSplitViewVerticalKey;
extern NSString *const CEDefaultShowLineNumbersKey;
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
extern NSString *const CEDefaultNSDragAndDropTextDelayKey;
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

// settings that are not in preferences
extern NSString *const CEDefaultInsertCustomTextArrayKey;
extern NSString *const CEDefaultInsertCustomTextKey;
extern NSString *const CEDefaultColorCodeTypeKey;

// hidden settings
extern NSString *const CEDefaultUsesTextFontForInvisiblesKey;
extern NSString *const CEDefaultLineNumFontNameKey;
extern NSString *const CEDefaultLineNumFontColorKey;
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

// keys for dicts in CEDefaultFileDropArrayKey
extern NSString *const CEFileDropExtensionsKey;
extern NSString *const CEFileDropFormatStringKey;



// ------------------------------------------------------
// User Defaults Values
// ------------------------------------------------------

typedef NS_ENUM(NSUInteger, CELineEnding) {
    CELineEndingLF,
    CELineEndingCR,
    CELineEndingCRLF
};

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
extern NSUInteger const k_minPageGuideColumn;
extern NSUInteger const k_maxPageGuideColumn;



#pragma mark Syntax

// ------------------------------------------------------
// Syntax
// ------------------------------------------------------

// syntax parsing
extern NSUInteger const k_maxEscapesCheckLength;
extern NSString  *const k_allAlphabetChars;

// syntax style keys
extern NSString *const CESyntaxStyleNameKey;
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
extern NSString *const k_allColoringKeys[];
extern NSUInteger const k_size_of_allColoringKeys;

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
    CENewMenuItemTag            =  100,
    CEOpenMenuItemTag           =  101,
    CEOpenHiddenMenuItemTag     =  102,
    CEOpenRecentMenuItemTag     =  103,
    CEInputBackSlashMenuItemTag =  209,
    CEFileEncodingMenuItemTag   = 4001,
    CESyntaxMenuItemTag         = 4002,
    CEThemeMenuItemTag          = 4003,
    CEServicesMenuItemTag       =  999,  // const not to list up in "Menu Key Bindings" Setting
    CEWindowPanelsMenuItemTag   = 7999,  // const not to list up in "Menu Key Bindings" Setting
    CEScriptMenuDirectoryTag    = 8999,  // const not to list up in "Menu Key Bindings" Setting
    
    // in contextual menu
    CEUtilityMenuItemTag        =  600,
    CEScriptMenuItemTag         =  800,
};

// Help document file names table
extern NSString *const k_bundledDocumentFileNames[];

// Online URLs
extern NSString *const k_webSiteURL;
extern NSString *const k_issueTrackerURL;



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
extern CGFloat const k_defaultLineNumWidth;
extern CGFloat const k_lineNumPadding;
extern CGFloat const k_lineNumFontDescender;
extern NSString *const k_navigationBarFontName;



#pragma mark CEATSTypeSetter

// ------------------------------------------------------
// CEATSTypeSetter
// ------------------------------------------------------

// CEATSTypeSetter (Layouting)
extern CGFloat const k_defaultLineHeightMultiple;



#pragma mark Print

// ------------------------------------------------------
// Print
// ------------------------------------------------------

extern CGFloat const k_printTextHorizontalMargin;  // left/light margin for text
extern CGFloat const k_printHFHorizontalMargin;    // left/light margin for header/footer
extern CGFloat const k_printHFVerticalMargin;      // top/bottom margin for header/footer
extern CGFloat const k_headerFooterLineHeight;
extern CGFloat const k_separatorPadding;
extern CGFloat const k_noSeparatorPadding;



#pragma mark Preferences

// ------------------------------------------------------
// Preferences
// ------------------------------------------------------

// Help anchors
extern NSString *const k_helpPrefAnchors[];



#pragma mark Document Window

// ------------------------------------------------------
// Document Window
// ------------------------------------------------------

// Line Endings
extern NSString *const k_lineEndingNames[];

// Toolbar item identifier
extern NSString *const CEToolbarDocWindowToolbarID;
extern NSString *const CEToolbarGetInfoItemID;
extern NSString *const CEToolbarShowIncompatibleCharItemID;
extern NSString *const CEToolbarBiggerFontItemID;
extern NSString *const CEToolbarSmallerFontItemID;
extern NSString *const CEToolbarToggleCommentItemID;
extern NSString *const CEToolbarShiftLeftItemID;
extern NSString *const CEToolbarShiftRightItemID;
extern NSString *const CEToolbarAutoTabExpandItemID;
extern NSString *const CEToolbarShowNavigationBarItemID;
extern NSString *const CEToolbarShowLineNumItemID;
extern NSString *const CEToolbarShowStatusBarItemID;
extern NSString *const CEToolbarShowInvisibleCharsItemID;
extern NSString *const CEToolbarShowPageGuideItemID;
extern NSString *const CEToolbarWrapLinesItemID;
extern NSString *const CEToolbarTextOrientationItemID;
extern NSString *const CEToolbarLineEndingsItemID;
extern NSString *const CEToolbarFileEncodingsItemID;
extern NSString *const CEToolbarSyntaxItemID;
extern NSString *const CEToolbarSyntaxReColorAllItemID;
extern NSString *const CEToolbarEditColorCodeItemID;



#pragma mark KeyBindingManager

// ------------------------------------------------------
// KeyBindingManager
// ------------------------------------------------------

// outlineView data key, column identifier
extern NSString *const k_title;
extern NSString *const k_children;
extern NSString *const k_keyBindingKey;
extern NSString *const k_selectorString;



#pragma mark Encodings

// ------------------------------------------------------
// Encodings
// ------------------------------------------------------

// Encoding menu
extern NSInteger const k_autoDetectEncodingMenuTag;

// Max length to scan encoding declaration
extern NSUInteger        const k_maxEncodingScanLength;

// Encodings list
extern CFStringEncodings const k_CFStringEncodingList[];
extern NSUInteger        const k_size_of_CFStringEncodingList;

// Encodings that need convert Yen mark to back-slash
extern CFStringEncodings const k_CFStringEncodingInvalidYenList[];
extern NSUInteger        const k_size_of_CFStringEncodingInvalidYenList;

// Yen mark char
extern unichar const k_yenMark;



// ------------------------------------------------------
// Invisibles
// ------------------------------------------------------

// Substitutes for invisible characters
extern unichar    const k_invisibleSpaceCharList[];
extern NSUInteger const k_size_of_invisibleSpaceCharList;

extern unichar    const k_invisibleTabCharList[];
extern NSUInteger const k_size_of_invisibleTabCharList;

extern unichar    const k_invisibleNewLineCharList[];
extern NSUInteger const k_size_of_invisibleNewLineCharList;

extern unichar    const k_invisibleFullwidthSpaceCharList[];
extern NSUInteger const k_size_of_invisibleFullwidthSpaceCharList;



// ------------------------------------------------------
// Keybindings
// ------------------------------------------------------

// Modifier masks and characters for keybindings
extern NSUInteger const k_modifierKeyMaskList[];
extern unichar    const k_modifierKeySymbolCharList[];
extern unichar    const k_keySpecCharList[];

// size of k_modifierKeyMaskList, k_keySpecCharList and k_modifierKeySymbolCharList
extern NSUInteger const k_size_of_modifierKeys;
// indexes of k_modifierKeyMaskList, k_keySpecCharList and k_modifierKeySymbolCharList
typedef NS_ENUM(NSUInteger, CEModifierKeyIndex) {
    CEControlKeyIndex,
    CEAlternateKeyIndex,
    CEShiftKeyIndex,
    CECommandKeyIndex,
};

// Unprintable key list
extern unichar    const k_unprintableKeyList[];
extern NSUInteger const k_size_of_unprintableKeyList;
