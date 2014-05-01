/*
 =================================================
 constants
 (for CotEditor)
 
 Copyright (C) 2004-2007 nakamuxu.
 Copyright (C) 2011, 2014 CotEditor Project
 http://coteditor.github.io
 =================================================
 
 encoding="UTF-8"
 Created:2004.12.13
 
 -------------------------------------------------
 
 This program is free software; you can redistribute it and/or
 modify it under the terms of the GNU General Public License
 as published by the Free Software Foundation; either version 2
 of the License, or (at your option) any later version.
 
 This program is distributed in the hope that it will be useful,
 but WITHOUT ANY WARRANTY; without even the implied warranty of
 MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 GNU General Public License for more details.
 
 You should have received a copy of the GNU General Public License
 along with this program; if not, write to the Free Software
 Foundation, Inc., 59 Temple Place - Suite 330, Boston, MA  02111-1307, USA.
 
 
 =================================================
 */


#pragma mark General

// ------------------------------------------------------
// General
// ------------------------------------------------------

// separator
extern NSString *const CESeparatorString;

// Localized Strings Table
extern NSString *const k_printLocalizeTable;

// Notification name
extern NSString *const CEEncodingListDidUpdateNotification;
extern NSString *const CEDocumentDidFinishOpenNotification;
extern NSString *const CESetKeyCatchModeToCatchMenuShortcutNotification;
extern NSString *const CECatchMenuShortcutNotification;



#pragma mark User Defaults Keys

// ------------------------------------------------------
// User Defaults Keys
// ------------------------------------------------------

// normal settings
extern NSString *const k_key_showLineNumbers;
extern NSString *const k_key_showStatusBar;
extern NSString *const k_key_showStatusBarLines;
extern NSString *const k_key_showStatusBarChars;
extern NSString *const k_key_showStatusBarWords;
extern NSString *const k_key_showStatusBarLocation;
extern NSString *const k_key_showStatusBarLine;
extern NSString *const k_key_showStatusBarColumn;
extern NSString *const k_key_showStatusBarEncoding;
extern NSString *const k_key_showStatusBarLineEndings;
extern NSString *const k_key_showStatusBarFileSize;
extern NSString *const k_key_countLineEndingAsChar;
extern NSString *const k_key_syncFindPboard;
extern NSString *const k_key_inlineContextualScriptMenu;
extern NSString *const k_key_appendExtensionAtSaving;
extern NSString *const k_key_showNavigationBar;
extern NSString *const k_key_wrapLines;
extern NSString *const k_key_defaultEncodingCode;
extern NSString *const k_key_defaultLineEndCharCode;
extern NSString *const k_key_encodingList;
extern NSString *const k_key_fontName;
extern NSString *const k_key_fontSize;
extern NSString *const k_key_encodingInOpen;
extern NSString *const k_key_encodingInNew;
extern NSString *const k_key_referToEncodingTag;
extern NSString *const k_key_createNewAtStartup;
extern NSString *const k_key_reopenBlankWindow;
extern NSString *const k_key_checkSpellingAsType;
extern NSString *const k_key_windowWidth;
extern NSString *const k_key_windowHeight;
extern NSString *const k_key_autoExpandTab;
extern NSString *const k_key_tabWidth;
extern NSString *const k_key_windowAlpha;
extern NSString *const k_key_autoIndent;
extern NSString *const k_key_invisibleCharactersColor;
extern NSString *const k_key_showInvisibleSpace;
extern NSString *const k_key_invisibleSpace;
extern NSString *const k_key_showInvisibleTab;
extern NSString *const k_key_invisibleTab;
extern NSString *const k_key_showInvisibleNewLine;
extern NSString *const k_key_invisibleNewLine;
extern NSString *const k_key_showInvisibleFullwidthSpace;
extern NSString *const k_key_invisibleFullwidthSpace;
extern NSString *const k_key_showOtherInvisibleChars;
extern NSString *const k_key_highlightCurrentLine;
extern NSString *const k_key_doColoring;
extern NSString *const k_key_defaultColoringStyleName;
extern NSString *const k_key_delayColoring;
extern NSString *const k_key_fileDropArray;
extern NSString *const k_key_fileDropExtensions;
extern NSString *const k_key_fileDropFormatString;
extern NSString *const k_key_NSDragAndDropTextDelay;
extern NSString *const k_key_smartInsertAndDelete;
extern NSString *const k_key_shouldAntialias;
extern NSString *const k_key_completeAddStandardWords;
extern NSString *const k_key_showPageGuide;
extern NSString *const k_key_pageGuideColumn;
extern NSString *const k_key_lineSpacing;
extern NSString *const k_key_swapYenAndBackSlashKey;
extern NSString *const k_key_fixLineHeight;
extern NSString *const k_key_highlightBraces;
extern NSString *const k_key_highlightLtGt;
extern NSString *const k_key_saveUTF8BOM;
extern NSString *const k_key_setPrintFont;
extern NSString *const k_key_printFontName;
extern NSString *const k_key_printFontSize;
extern NSString *const k_key_enableSmartQuotes;
extern NSString *const k_key_enableSmartIndent;

// print settings
extern NSString *const k_key_printHeader;
extern NSString *const k_key_headerOneStringIndex;
extern NSString *const k_key_headerTwoStringIndex;
extern NSString *const k_key_headerOneAlignIndex;
extern NSString *const k_key_headerTwoAlignIndex;
extern NSString *const k_key_printHeaderSeparator;
extern NSString *const k_key_printFooter;
extern NSString *const k_key_footerOneStringIndex;
extern NSString *const k_key_footerTwoStringIndex;
extern NSString *const k_key_footerOneAlignIndex;
extern NSString *const k_key_footerTwoAlignIndex;
extern NSString *const k_key_printFooterSeparator;
extern NSString *const k_key_printLineNumIndex;
extern NSString *const k_key_printInvisibleCharIndex;
extern NSString *const k_key_printColorIndex;

// settings that are not in preferences (環境設定にない設定項目)
extern NSString *const k_key_insertCustomTextArray;
extern NSString *const k_key_insertCustomText;
extern NSString *const k_key_colorCodeType;

// hidden settings（隠し設定の値は CEAppDelegate の initialize で設定している）
extern NSString *const k_key_lineNumFontName;
extern NSString *const k_key_lineNumFontSize;
extern NSString *const k_key_lineNumFontColor;
extern NSString *const k_key_basicColoringDelay;
extern NSString *const k_key_firstColoringDelay;
extern NSString *const k_key_secondColoringDelay;
extern NSString *const k_key_lineNumUpdateInterval;
extern NSString *const k_key_infoUpdateInterval;
extern NSString *const k_key_incompatibleCharInterval;
extern NSString *const k_key_outlineMenuInterval;
extern NSString *const k_key_navigationBarFontName;
extern NSString *const k_key_navigationBarFontSize;
extern NSString *const k_key_outlineMenuMaxLength;
extern NSString *const k_key_headerFooterFontName;
extern NSString *const k_key_headerFooterFontSize;
extern NSString *const k_key_headerFooterDateTimeFormat;
extern NSString *const k_key_headerFooterPathAbbreviatingWithTilde;
extern NSString *const k_key_textContainerInsetWidth;
extern NSString *const k_key_textContainerInsetHeightTop;
extern NSString *const k_key_textContainerInsetHeightBottom;
extern NSString *const k_key_showColoringIndicatorTextLength;
extern NSString *const k_key_runAppleScriptInLaunching;
extern NSString *const k_key_showAlertForNotWritable;
extern NSString *const k_key_notifyEditByAnother;



#pragma mark Setting Values

// ------------------------------------------------------
// Setting Values
// ------------------------------------------------------

// Tab width values
extern NSUInteger const k_tabWidthMin;
extern NSUInteger const k_tabWidthMax;

// Page guide column values
extern NSUInteger const k_pageGuideColumnMin;
extern NSUInteger const k_pageGuideColumnMax;

// custom line spacing values
extern CGFloat const k_lineSpacingMin;
extern CGFloat const k_lineSpacingMax;



#pragma mark Syntax

// ------------------------------------------------------
// Syntax
// ------------------------------------------------------

// syntax coloring
extern NSUInteger const k_ESCheckLength;
extern NSString  *const k_QCPosition;
extern NSString  *const k_QCPairKind;
extern NSUInteger const k_notUseKind;
extern NSUInteger const k_QC_SingleQ;
extern NSUInteger const k_QC_DoubleQ;
extern NSUInteger const k_QC_CommentBaseNum;
extern NSString  *const k_QCStartEnd;
extern NSUInteger const k_notUseStartEnd;
extern NSUInteger const k_QC_Start;
extern NSUInteger const k_QC_End;
extern NSString  *const k_QCStrLength;
extern NSString  *const k_allAlphabetChars;

// syntax coloring range buffer (in CEEditorView)
extern NSUInteger const k_coloringRangeBufferLength;  // number of characters

// syntax coloring indicator
extern CGFloat const k_perCompoIncrement;
extern CGFloat const k_minIncrement;

// syntax coloring color
extern NSString *const k_key_textColor;
extern NSString *const k_key_backgroundColor;
extern NSString *const k_key_insertionPointColor;
extern NSString *const k_key_selectionColor;
extern NSString *const k_key_highlightLineColor;
extern NSString *const k_key_keywordsColor;
extern NSString *const k_key_commandsColor;
extern NSString *const k_key_valuesColor;
extern NSString *const k_key_numbersColor;
extern NSString *const k_key_stringsColor;
extern NSString *const k_key_charactersColor;
extern NSString *const k_key_commentsColor;
extern NSString *const k_key_allSyntaxColors[];

// syntax style
extern NSString *const k_SCKey_styleName;
extern NSString *const k_SCKey_extensions;
extern NSString *const k_SCKey_ignoreCase;
extern NSString *const k_SCKey_regularExpression;
extern NSString *const k_SCKey_arrayKeyString;
extern NSString *const k_SCKey_beginString;
extern NSString *const k_SCKey_endString;
extern NSString *const k_SCKey_bold;
extern NSString *const k_SCKey_underline;
extern NSString *const k_SCKey_italic;
extern NSString *const k_SCKey_numOfObjInArray;
extern NSString *const k_SCKey_keywordsArray;
extern NSString *const k_SCKey_commandsArray;
extern NSString *const k_SCKey_valuesArray;
extern NSString *const k_SCKey_numbersArray;
extern NSString *const k_SCKey_stringsArray;
extern NSString *const k_SCKey_charactersArray;
extern NSString *const k_SCKey_commentsArray;
extern NSString *const k_SCKey_outlineMenuArray;
extern NSString *const k_SCKey_completionsArray;
extern NSString *const k_SCKey_allColoringArrays[];
extern NSUInteger const k_size_of_allColoringArrays;

// edit argument dictionary's key
extern NSString *const k_key_oldStyleName;
extern NSString *const k_key_newStyleName;



#pragma mark Main Menu

// ------------------------------------------------------
// Main Menu
// ------------------------------------------------------

// Main Menu index and tag
extern NSInteger const k_applicationMenuIndex;
extern NSInteger const k_fileMenuIndex;
extern NSInteger const k_editMenuIndex;
extern NSInteger const k_viewMenuIndex;
extern NSInteger const k_formatMenuIndex;
extern NSInteger const k_findMenuIndex;
extern NSInteger const k_utilityMenuIndex;
extern NSInteger const k_scriptMenuIndex;
extern NSInteger const k_newMenuItemTag;
extern NSInteger const k_openMenuItemTag;
extern NSInteger const k_openHiddenMenuItemTag;
extern NSInteger const k_openRecentMenuItemTag;
extern NSInteger const k_BSMenuItemTag;
extern NSInteger const k_showInvisibleCharMenuItemTag;
extern NSInteger const k_showInvisibleCharMenuItemTag;
extern NSInteger const k_fileEncodingMenuItemTag;
extern NSInteger const k_syntaxMenuItemTag;
extern NSInteger const k_servicesMenuItemTag;  // Menu KeyBindings Setting でリストアップしないための定数
extern NSInteger const k_windowPanelsMenuItemTag;  // Menu KeyBindings Setting でリストアップしないための定数
extern NSInteger const k_scriptMenuDirectoryTag;  // Menu KeyBindings Setting でリストアップしないための定数

// Contextual Menu tag
extern NSInteger const k_noMenuItem;
extern NSInteger const k_utilityMenuTag;
extern NSInteger const k_scriptMenuTag;

// Help Document Menu tag and path
extern NSString *const k_bundleDocumentTags[];

// distribution web site
extern NSString *const k_webSiteURL;
// issue tracker site
extern NSString *const k_issueTrackerURL;



#pragma mark CEEditorView

// ------------------------------------------------------
// CEEditorView
// ------------------------------------------------------

// CEEditorView and subView's dict key
extern NSString *const k_invocationAfterAlert;
extern NSString *const k_argsArrayAfterAlert;
extern NSString *const k_outlineMenuItemRange;
extern NSString *const k_outlineMenuItemTitle;
extern NSString *const k_outlineMenuItemSortKey;
extern NSString *const k_outlineMenuItemFontBold;
extern NSString *const k_outlineMenuItemFontItalic;
extern NSString *const k_outlineMenuItemUnderlineMask;

// CEEditorView and subView's constants
extern CGFloat const k_defaultLineNumWidth;
extern CGFloat const k_lineNumPadding;
extern CGFloat const k_statusBarHeight;
extern CGFloat const k_statusBarRightPadding;
extern CGFloat const k_statusBarReadOnlyWidth;
extern CGFloat const k_lineNumFontDescender;
extern CGFloat const k_navigationBarHeight;
extern CGFloat const k_outlineMenuLeftMargin;
extern CGFloat const k_outlineMenuWidth;
extern CGFloat const k_outlineButtonWidth;



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

extern CGFloat const k_printTextHorizontalMargin;    // テキスト用の左右のマージン
extern CGFloat const k_printHFHorizontalMargin;    // ヘッダ／フッタ用の左右のマージン
extern CGFloat const k_printHFVerticalMargin;    // ヘッダ／フッタ用の上下のマージン
extern CGFloat const k_headerFooterLineHeight;
extern CGFloat const k_separatorPadding;
extern CGFloat const k_noSeparatorPadding;



#pragma mark CEWindowController

// ------------------------------------------------------
// CEWindowController
// ------------------------------------------------------

// Drawer identifier
extern NSString *const k_infoIdentifier;
extern NSString *const k_incompatibleIdentifier;

// listController key
extern NSString *const k_listLineNumber;
extern NSString *const k_incompatibleRange;
extern NSString *const k_incompatibleChar;
extern NSString *const k_convertedChar;



#pragma mark CEColorCodePanelController

// ------------------------------------------------------
// CEColorCodePanelController
// ------------------------------------------------------

extern NSInteger const k_exportForeColorButtonTag;
extern NSInteger const k_exportBGColorButtonTag;
extern NSInteger const k_addCodeToForeButtonTag;
extern NSInteger const k_addCodeToBackButtonTag;
extern NSString *const k_ColorCodeDataControllerKey;



#pragma mark Preferences

// ------------------------------------------------------
// Preferences
// ------------------------------------------------------

// Help anchors
extern NSString *const k_helpPrefAnchors[];

// button
extern NSInteger const k_okButtonTag;

// Encoding list edit
extern NSString *const k_dropMyselfPboardType;
extern NSInteger const k_lastRow;



#pragma mark Document Window

// ------------------------------------------------------
// Document Window
// ------------------------------------------------------

// Line Endings
extern NSString *const k_lineEndingNames[];

// Toolbar item identifier
extern NSString *const k_docWindowToolbarID;
extern NSString *const k_getInfoItemID;
extern NSString *const k_showIncompatibleCharItemID;
extern NSString *const k_biggerFontItemID;
extern NSString *const k_smallerFontItemID;
extern NSString *const k_shiftLeftItemID;
extern NSString *const k_shiftRightItemID;
extern NSString *const k_autoTabExpandItemID;
extern NSString *const k_showNavigationBarItemID;
extern NSString *const k_showLineNumItemID;
extern NSString *const k_showStatusBarItemID;
extern NSString *const k_showInvisibleCharsItemID;
extern NSString *const k_showPageGuideItemID;
extern NSString *const k_wrapLinesItemID;
extern NSString *const k_lineEndingsItemID;
extern NSString *const k_fileEncodingsItemID;
extern NSString *const k_syntaxItemID;
extern NSString *const k_syntaxReColorAllItemID;
extern NSString *const k_editColorCodeItemID;



#pragma mark KeyBindingManager

// ------------------------------------------------------
// KeyBindingManager
// ------------------------------------------------------

// info dictionary key
extern NSString *const k_keyCatchMode;
extern NSString *const k_keyBindingModFlags;
extern NSString *const k_keyBindingChar;

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

extern CFStringEncodings const k_CFStringEncodingList[];
extern NSUInteger        const k_size_of_CFStringEncodingList;

// Encodings to convert Yen mark to back-slash
extern CFStringEncodings const k_CFStringEncodingInvalidYenList[];
extern NSUInteger        const k_size_of_CFStringEncodingInvalidYenList;


extern unichar const k_yenMark;

extern unichar    const k_invisibleSpaceCharList[];
extern NSUInteger const k_size_of_invisibleSpaceCharList;
extern unichar    const k_invisibleTabCharList[];
extern NSUInteger const k_size_of_invisibleTabCharList;
extern unichar    const k_invisibleNewLineCharList[];
extern NSUInteger const k_size_of_invisibleNewLineCharList;
extern unichar    const k_invisibleFullwidthSpaceCharList[];
extern NSUInteger const k_size_of_invisibleFullwidthSpaceCharList;

extern NSUInteger const k_modifierKeysList[];
extern NSUInteger const k_size_of_modifierKeysList;
extern unichar    const k_keySpecCharList[];
extern NSUInteger const k_size_of_keySpecCharList;
extern unichar    const k_readableKeyStringsList[];
extern NSUInteger const k_size_of_readableKeyStringsList;

extern unichar    const k_noPrintableKeyList[];
extern NSUInteger const k_size_of_noPrintableKeyList;
