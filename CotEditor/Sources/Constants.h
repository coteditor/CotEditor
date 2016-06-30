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


// Original special encoding type
extern NSInteger const CEAutoDetectEncoding;

// Max length to scan encoding declaration
extern NSUInteger const kMaxEncodingScanLength;


// Convenient functions
/// compare CGFloats
extern BOOL CEIsAlmostEqualCGFloats(CGFloat float1, CGFloat float2);

/// invoke passed-in block on main thread
extern void dispatch_sync_on_main_thread(_Nonnull dispatch_block_t block);



#pragma mark File Drop

// ------------------------------------------------------
// File Drop
// ------------------------------------------------------

// keys for dicts in CEDefaultFileDropArrayKey
extern NSString *_Nonnull const CEFileDropExtensionsKey;
extern NSString *_Nonnull const CEFileDropFormatStringKey;

// tokens
extern NSString *_Nonnull const CEFileDropTokenAbsolutePath;
extern NSString *_Nonnull const CEFileDropTokenRelativePath;
extern NSString *_Nonnull const CEFileDropTokenFilename;
extern NSString *_Nonnull const CEFileDropTokenFilenameNosuffix;
extern NSString *_Nonnull const CEFileDropTokenFileextension;
extern NSString *_Nonnull const CEFileDropTokenFileextensionLower;
extern NSString *_Nonnull const CEFileDropTokenFileextensionUpper;
extern NSString *_Nonnull const CEFileDropTokenDirectory;
extern NSString *_Nonnull const CEFileDropTokenImageWidth;
extern NSString *_Nonnull const CEFileDropTokenImageHeight;



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
    CEMenuItemTagServices        =  999,  // const to not list up in "Menu Key Bindings" setting
    CEMenuItemTagSharingService  = 1999,
    CEMenuItemTagScriptDirectory = 8999,  // const to not list up in "Menu Key Bindings" setting
    
    // in script menu
    CEMenuItemTagScriptsDefault  = 8001,  // const to not list up in context menu
    
    // in contextual menu
    CEMenuItemTagScript          =  800,
};
