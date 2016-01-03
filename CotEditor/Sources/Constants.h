/*
 
 Constants.h
 
 CotEditor
 http://coteditor.com
 
 Created by nakamuxu on 2004-12-13.
 
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


#pragma mark General

// ------------------------------------------------------
// General
// ------------------------------------------------------

// Separator
extern NSString *_Nonnull const CESeparatorString;

// Exported UTI
extern NSString *_Nonnull const CEUTTypeTheme;

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
extern NSString *_Nonnull const kAllSyntaxKeys[];
extern NSUInteger const kSizeOfAllSyntaxKeys;

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
    CETextMenuIndex,
    CEFindMenuIndex,
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
    CESharingServiceMenuItemTag = 1999,
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



#pragma mark CELayoutManager

// ------------------------------------------------------
// CELayoutManager
// ------------------------------------------------------

// CELayoutManager (Layouting)
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
