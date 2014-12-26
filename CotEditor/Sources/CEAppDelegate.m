/*
 ==============================================================================
 CEAppDelegate
 
 CotEditor
 http://coteditor.com
 
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

#import "CEAppDelegate.h"
#import <OgreKit/OgreTextFinder.h>
#import "CESyntaxManager.h"
#import "CEEncodingManager.h"
#import "CEKeyBindingManager.h"
#import "CEScriptManager.h"
#import "CEThemeManager.h"
#import "CEHexColorTransformer.h"
#import "CELineHeightTransformer.h"
#import "CEPreferencesWindowController.h"
#import "CEOpacityPanelController.h"
#import "CELineHightPanelController.h"
#import "CEColorCodePanelController.h"
#import "CEScriptErrorPanelController.h"
#import "CEUnicodeInputPanelController.h"
#import "CEMigrationWindowController.h"
#import "SWFSemanticVersion.h"
#import "constants.h"


@interface CEAppDelegate ()

@property (nonatomic) BOOL didFinishLaunching;

@property (nonatomic) BOOL hasSetting;  // for migration check
@property (nonatomic) CEMigrationWindowController *migrationWindowController;


// readonly
@property (readwrite, nonatomic) NSURL *supportDirectoryURL;

@end



@interface CEAppDelegate (Migration)

- (void)migrateIfNeeded;
- (void)migrateBundleIdentifier;

@end




#pragma mark -

@implementation CEAppDelegate

#pragma mark Superclass Methods

// ------------------------------------------------------
/// set binding keys and values
+ (void)initialize
// ------------------------------------------------------
{
    // Encoding list
    NSMutableArray *encodings = [[NSMutableArray alloc] initWithCapacity:kSizeOfCFStringEncodingList];
    for (NSUInteger i = 0; i < kSizeOfCFStringEncodingList; i++) {
        [encodings addObject:@(kCFStringEncodingList[i])];
    }
    
    NSDictionary *defaults = @{CEDefaultLayoutTextVerticalKey: @NO,
                               CEDefaultSplitViewVerticalKey: @NO,
                               CEDefaultShowLineNumbersKey: @YES,
                               CEDefaultShowDocumentInspectorKey: @NO,
                               CEDefaultShowStatusBarKey: @YES,
                               CEDefaultShowStatusBarLinesKey: @YES,
                               CEDefaultShowStatusBarLengthKey: @NO,
                               CEDefaultShowStatusBarCharsKey: @YES,
                               CEDefaultShowStatusBarWordsKey: @NO,
                               CEDefaultShowStatusBarLocationKey: @YES,
                               CEDefaultShowStatusBarLineKey: @YES,
                               CEDefaultShowStatusBarColumnKey: @NO,
                               CEDefaultShowStatusBarEncodingKey: @NO,
                               CEDefaultShowStatusBarLineEndingsKey: @NO,
                               CEDefaultShowStatusBarFileSizeKey: @YES,
                               CEDefaultShowNavigationBarKey: @YES,
                               CEDefaultCountLineEndingAsCharKey: @YES,
                               CEDefaultSyncFindPboardKey: @NO,
                               CEDefaultInlineContextualScriptMenuKey: @NO,
                               CEDefaultWrapLinesKey: @YES,
                               CEDefaultLineEndCharCodeKey: @0,
                               CEDefaultEncodingListKey: encodings,
                               CEDefaultFontNameKey: [[NSFont controlContentFontOfSize:[NSFont systemFontSize]] fontName],
                               CEDefaultFontSizeKey: @([NSFont systemFontSize]),
                               CEDefaultEncodingInOpenKey: @(CEAutoDetectEncodingMenuItemTag),
                               CEDefaultEncodingInNewKey: @(CFStringConvertEncodingToNSStringEncoding(kCFStringEncodingUTF8)),
                               CEDefaultReferToEncodingTagKey: @YES,
                               CEDefaultCreateNewAtStartupKey: @YES,
                               CEDefaultReopenBlankWindowKey: @YES,
                               CEDefaultCheckSpellingAsTypeKey: @NO,
                               CEDefaultWindowWidthKey: @600.0f,
                               CEDefaultWindowHeightKey: @450.0f,
                               CEDefaultWindowAlphaKey: @1.0f,
                               CEDefaultAutoExpandTabKey: @NO,
                               CEDefaultTabWidthKey: @4U,
                               CEDefaultAutoIndentKey: @YES,
                               CEDefaultShowInvisiblesKey: @YES,
                               CEDefaultShowInvisibleSpaceKey: @NO,
                               CEDefaultInvisibleSpaceKey: @0U,
                               CEDefaultShowInvisibleTabKey: @NO,
                               CEDefaultInvisibleTabKey: @0U,
                               CEDefaultShowInvisibleNewLineKey: @NO,
                               CEDefaultInvisibleNewLineKey: @0U,
                               CEDefaultShowInvisibleFullwidthSpaceKey: @NO,
                               CEDefaultInvisibleFullwidthSpaceKey: @0U,
                               CEDefaultShowOtherInvisibleCharsKey: @NO,
                               CEDefaultHighlightCurrentLineKey: @NO,
                               CEDefaultThemeKey: @"Dendrobates",
                               CEDefaultEnableSyntaxHighlightKey: @YES,
                               CEDefaultSyntaxStyleKey: @"Plain Text",
                               CEDefaultDelayColoringKey: @NO,
                               CEDefaultFileDropArrayKey: @[@{CEFileDropExtensionsKey: @"jpg, jpeg, gif, png",
                                                              CEFileDropFormatStringKey: @"<img src=\"<<<RELATIVE-PATH>>>\" alt=\"<<<FILENAME-NOSUFFIX>>>\" title=\"<<<FILENAME-NOSUFFIX>>>\" width=\"<<<IMAGEWIDTH>>>\" height=\"<<<IMAGEHEIGHT>>>\" />"}],
                               CEDefaultSmartInsertAndDeleteKey: @NO,
                               CEDefaultEnableSmartQuotesKey: @NO,
                               CEDefaultEnableSmartIndentKey: @YES,
                               CEDefaultAppendsCommentSpacerKey: @YES,
                               CEDefaultCommentsAtLineHeadKey: @YES,
                               CEDefaultShouldAntialiasKey: @YES,
                               CEDefaultAutoCompleteKey: @NO,
                               CEDefaultCompletionWordsKey: @2U,
                               CEDefaultShowPageGuideKey: @NO,
                               CEDefaultPageGuideColumnKey: @80,
                               CEDefaultLineSpacingKey: @0.1f,
                               CEDefaultSwapYenAndBackSlashKey: @NO,
                               CEDefaultFixLineHeightKey: @YES,
                               CEDefaultHighlightBracesKey: @YES,
                               CEDefaultHighlightLtGtKey: @NO,
                               CEDefaultSaveUTF8BOMKey: @NO,
                               CEDefaultSetPrintFontKey: @0,
                               CEDefaultPrintFontNameKey: [[NSFont controlContentFontOfSize:[NSFont systemFontSize]] fontName],
                               CEDefaultPrintFontSizeKey: @([NSFont systemFontSize]),
                               CEDefaultPrintHeaderKey: @YES,
                               CEDefaultHeaderOneStringIndexKey: @(CEFilePathPrintInfo),
                               CEDefaultHeaderOneAlignIndexKey: @(CEAlignLeft),
                               CEDefaultHeaderTwoStringIndexKey: @(CEPrintDatePrintInfo),
                               CEDefaultHeaderTwoAlignIndexKey: @(CEAlignRight),
                               CEDefaultPrintHeaderSeparatorKey: @YES,
                               CEDefaultPrintFooterKey: @YES,
                               CEDefaultFooterOneStringIndexKey: @(CENoPrintInfo),
                               CEDefaultFooterOneAlignIndexKey: @(CEAlignLeft),
                               CEDefaultFooterTwoStringIndexKey: @(CEPageNumberPrintInfo),
                               CEDefaultFooterTwoAlignIndexKey: @(CEAlignCenter),
                               CEDefaultPrintFooterSeparatorKey: @YES,
                               CEDefaultPrintLineNumIndexKey: @(CENoLinePrint),
                               CEDefaultPrintInvisibleCharIndexKey: @(CENoInvisibleCharsPrint),
                               CEDefaultPrintColorIndexKey: @(CEBlackColorPrint),
                               
                               /* -------- settings not in preferences window -------- */
                               CEDefaultInsertCustomTextArrayKey: @[@"<br />\n", @"", @"", @"", @"", @"", @"", @"", @"", @"", @"",
                                                                    @"", @"", @"", @"", @"", @"", @"", @"", @"", @"",
                                                                    @"", @"", @"", @"", @"", @"", @"", @"", @"", @""],
                               CEDefaultColorCodeTypeKey: @1,
                               CEDefaultSidebarWidthKey: @220,
                               
                               /* -------- hidden settings -------- */
                               CEDefaultUsesTextFontForInvisiblesKey: @NO,
                               CEDefaultLineNumFontNameKey: @"ArialNarrow",
                               CEDefaultBasicColoringDelayKey: @0.001f, 
                               CEDefaultFirstColoringDelayKey: @0.3f, 
                               CEDefaultSecondColoringDelayKey: @0.7f,
                               CEDefaultAutoCompletionDelayKey: @0.25,
                               CEDefaultLineNumUpdateIntervalKey: @0.12f, 
                               CEDefaultInfoUpdateIntervalKey: @0.2f, 
                               CEDefaultIncompatibleCharIntervalKey: @0.42f, 
                               CEDefaultOutlineMenuIntervalKey: @0.37f, 
                               CEDefaultOutlineMenuMaxLengthKey: @110U, 
                               CEDefaultHeaderFooterFontNameKey: [[NSFont systemFontOfSize:[NSFont systemFontSize]] fontName], 
                               CEDefaultHeaderFooterFontSizeKey: @10.0f, 
                               CEDefaultHeaderFooterDateFormatKey: @"YYYY-MM-dd HH:mm",
                               CEDefaultHeaderFooterPathAbbreviatingWithTildeKey: @YES, 
                               CEDefaultTextContainerInsetWidthKey: @0.0f, 
                               CEDefaultTextContainerInsetHeightTopKey: @4.0f, 
                               CEDefaultTextContainerInsetHeightBottomKey: @16.0f, 
                               CEDefaultShowColoringIndicatorTextLengthKey: @50000U,
                               CEDefaultRunAppleScriptInLaunchingKey: @YES,
                               CEDefaultShowAlertForNotWritableKey: @YES, 
                               CEDefaultNotifyEditByAnotherKey: @YES,
                               CEDefaultColoringRangeBufferLengthKey: @5000,
                               CEDefaultLargeFileAlertThresholdKey: @(100 * pow(1024, 2)),  // 100 MB
                               };
    [[NSUserDefaults standardUserDefaults] registerDefaults:defaults];
    
    // set initial values to NSUserDefaultsController which can restore to defaults
    NSDictionary *initialValues = [defaults dictionaryWithValuesForKeys:@[CEDefaultEncodingListKey,
                                                                          CEDefaultInsertCustomTextArrayKey,
                                                                          CEDefaultWindowWidthKey,
                                                                          CEDefaultWindowHeightKey]];
    [[NSUserDefaultsController sharedUserDefaultsController] setInitialValues:initialValues];
    
    // register transformers
    [NSValueTransformer setValueTransformer:[[CEHexColorTransformer alloc] init]
                                    forName:@"CEHexColorTransformer"];
    [NSValueTransformer setValueTransformer:[[CELineHeightTransformer alloc] init]
                                    forName:@"CELineHeightTransformer"];
}


// ------------------------------------------------------
/// initialize
- (instancetype)init
// ------------------------------------------------------
{
    self = [super init];
    if (self) {
        [self migrateBundleIdentifier];
        
        _supportDirectoryURL = [[[NSFileManager defaultManager] URLForDirectory:NSApplicationSupportDirectory
                                                                       inDomain:NSUserDomainMask
                                                              appropriateForURL:nil
                                                                         create:NO
                                                                          error:nil]
                                URLByAppendingPathComponent:@"CotEditor"];
        
        [self setupSupportDirectory];
    }
    return self;
}


// ------------------------------------------------------
/// clean up
- (void)dealloc
// ------------------------------------------------------
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}


// ------------------------------------------------------
/// setup UI
- (void)awakeFromNib
// ------------------------------------------------------
{
    // build menus
    [self buildEncodingMenu];
    [self buildSyntaxMenu];
    [self buildThemeMenu];
    [[CEScriptManager sharedManager] buildScriptMenu:nil];
    
    // observe encoding list update
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(buildEncodingMenu)
                                                 name:CEEncodingListDidUpdateNotification
                                               object:nil];
    // observe syntax style lineup update
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(buildSyntaxMenu)
                                                 name:CESyntaxListDidUpdateNotification
                                               object:nil];
    // observe theme lineup update
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(buildThemeMenu)
                                                 name:CEThemeListDidUpdateNotification
                                               object:nil];
}


//=======================================================
// informal protocol of OgreKit
//=======================================================

// ------------------------------------------------------
/// avoid OgreKit find panel handling rich text (see OgreTextFinder.m L203-212 for details)
- (void)ogreKitShouldUseStylesInFindPanel:(OgreTextFinder*)textFinder
// ------------------------------------------------------
{
    [textFinder setUseStylesInFindPanel:NO];
}



#pragma mark Protocol

//=======================================================
// NSMenuValidation Protocol
//=======================================================

// ------------------------------------------------------
/// validate menu items
- (BOOL)validateMenuItem:(NSMenuItem *)menuItem
// ------------------------------------------------------
{
    if (([menuItem action] == @selector(showLineHeightPanel:)) ||
        ([menuItem action] == @selector(showUnicodeInputPanel:))) {
        return ([[NSDocumentController sharedDocumentController] currentDocument] != nil);
    }
    
    return YES;
}



#pragma mark Delegate

//=======================================================
// NSApplicationDelegate  < File's Owner
//=======================================================

// ------------------------------------------------------
/// creates a new document on launch?
- (BOOL)applicationShouldOpenUntitledFile:(NSApplication *)sender
// ------------------------------------------------------
{
    if (![self didFinishLaunching]) {
        return [[NSUserDefaults standardUserDefaults] boolForKey:CEDefaultCreateNewAtStartupKey];
    }
    
    return YES;
}


// ------------------------------------------------------
/// crates a new document on "Re-Open" AppleEvent
- (BOOL)applicationShouldHandleReopen:(NSApplication *)theApplication hasVisibleWindows:(BOOL)flag
// ------------------------------------------------------
{
    if ([[NSUserDefaults standardUserDefaults] boolForKey:CEDefaultReopenBlankWindowKey]) {
        return YES;
    }
    
    return flag;
}


// ------------------------------------------------------
/// just after application did launch
- (void)applicationDidFinishLaunching:(NSNotification *)notification
// ------------------------------------------------------
{
    // keyboard shortcuts will be overridden by CEKeyBindingManager
    //   - to apply shortcuts, write them in MenuKeyBindings.plist (2007-05-19)

    // add "Select Outline Item" and "Go To" to the main menu
    NSMenu *findMenu = [[[NSApp mainMenu] itemAtIndex:CEFindMenuIndex] submenu];
    NSMenuItem *menuItem;

    [findMenu addItem:[NSMenuItem separatorItem]];
    unichar upKey = NSUpArrowFunctionKey;
    menuItem = [[NSMenuItem alloc] initWithTitle:NSLocalizedString(@"Select Prev Outline Item", nil)
                                          action:@selector(selectPrevItemOfOutlineMenu:)
                                   keyEquivalent:[NSString stringWithCharacters:&upKey length:1]];
    [menuItem setKeyEquivalentModifierMask:(NSCommandKeyMask | NSAlternateKeyMask)];
    [findMenu addItem:menuItem];

    unichar downKey = NSDownArrowFunctionKey;
    menuItem = [[NSMenuItem alloc] initWithTitle:NSLocalizedString(@"Select Next Outline Item", nil)
                                          action:@selector(selectNextItemOfOutlineMenu:)
                                   keyEquivalent:[NSString stringWithCharacters:&downKey length:1]];
    [menuItem setKeyEquivalentModifierMask:(NSCommandKeyMask | NSAlternateKeyMask)];
    [findMenu addItem:menuItem];

    [findMenu addItem:[NSMenuItem separatorItem]];
    menuItem = [[NSMenuItem alloc] initWithTitle:NSLocalizedString(@"Go To…", nil)
                                          action:@selector(gotoLocation:)
                                   keyEquivalent:@"l"];
    [findMenu addItem:menuItem];
    
    // setup KeyBindingManager
    [[CEKeyBindingManager sharedManager] setupAtLaunching];
    
    // migrate usr settings if needed
    [self migrateIfNeeded];
    
    // store latest version
    NSString *lastVersion = [[NSUserDefaults standardUserDefaults] stringForKey:CEDefaultLastVersionKey];
    NSString *thisVersion = [[NSBundle mainBundle] objectForInfoDictionaryKey:@"CFBundleVersion"];
    SWFSemanticVersion *lastSemVer = lastVersion ? [SWFSemanticVersion semanticVersionWithString:lastVersion] : nil;
    SWFSemanticVersion *thisSemVer = [SWFSemanticVersion semanticVersionWithString:thisVersion];
    if (!lastSemVer || [lastSemVer compare:thisSemVer] == NSOrderedAscending) {  // lastVer < thisVer
        [[NSUserDefaults standardUserDefaults] setObject:thisVersion forKey:CEDefaultLastVersionKey];
    }
    
    // register Services
    [NSApp setServicesProvider:self];
    
    [self setDidFinishLaunching:YES];
}


// ------------------------------------------------------
/// setup Dock menu
- (NSMenu *)applicationDockMenu:(NSApplication *)sender
// ------------------------------------------------------
{
    NSMenu *menu = [[NSMenu alloc] init];
    NSMenuItem *newItem = [[[[[NSApp mainMenu] itemAtIndex:CEFileMenuIndex] submenu] itemWithTag:CENewMenuItemTag] copy];
    NSMenuItem *openItem = [[[[[NSApp mainMenu] itemAtIndex:CEFileMenuIndex] submenu] itemWithTag:CEOpenMenuItemTag] copy];

    [newItem setAction:@selector(newInDockMenu:)];
    [openItem setAction:@selector(openInDockMenu:)];

    [menu addItem:newItem];
    [menu addItem:openItem];

    return menu;
}


// ------------------------------------------------------
/// open file
- (BOOL)application:(NSApplication *)theApplication openFile:(NSString *)filename
// ------------------------------------------------------
{
    // perform install if the file is CotEditor theme file
    if ([[filename pathExtension] isEqualToString:CEThemeExtension]) {
        NSURL *URL = [NSURL fileURLWithPath:filename];
        NSString *themeName = [[URL lastPathComponent] stringByDeletingPathExtension];
        NSAlert *alert;
        NSInteger returnCode;
        
        // ask whether theme file should be opened as a text file
        alert = [[NSAlert alloc] init];
        [alert setMessageText:[NSString stringWithFormat:NSLocalizedString(@"“%@” is a CotEditor theme file.", nil), [URL lastPathComponent]]];
        [alert setInformativeText:NSLocalizedString(@"Do you want to install this theme?", nil)];
        [alert addButtonWithTitle:NSLocalizedString(@"Install", nil)];
        [alert addButtonWithTitle:NSLocalizedString(@"Open as Text File", nil)];
        
        returnCode = [alert runModal];
        if (returnCode == NSAlertSecondButtonReturn) {  // Edit as Text File
            return NO;
        }
        
        // import theme
        NSError *error = nil;
        [[CEThemeManager sharedManager] importTheme:URL replace:NO error:&error];
        
        // ask whether the old theme should be repleced with new one if the same name theme is already exists
        if ([error code] == CEThemeFileDuplicationError) {
            alert = [NSAlert alertWithError:error];
            
            returnCode = [alert runModal];
            if (returnCode == NSAlertFirstButtonReturn) {  // Canceled
                return YES;
            } else {
                error = nil;
                [[CEThemeManager sharedManager] importTheme:URL replace:YES error:&error];
            }
        }
        
        if (error) {
            alert = [NSAlert alertWithError:error];
        } else {
            [[NSSound soundNamed:@"Glass"] play];
            alert = [[NSAlert alloc] init];
            [alert setMessageText:[NSString stringWithFormat:NSLocalizedString(@"A new theme named “%@” has been successfully installed.", nil), themeName]];
        }
        [alert runModal];
        
        return YES;
    }
    
    return NO;
}



#pragma mark Action Messages

// ------------------------------------------------------
/// show Preferences window
- (IBAction)showPreferences:(id)sender
// ------------------------------------------------------
{
    [[CEPreferencesWindowController sharedController] showWindow:self];
}


// ------------------------------------------------------
/// Show script error panel
- (IBAction)showScriptErrorPanel:(id)sender
// ------------------------------------------------------
{
    [[CEScriptErrorPanelController sharedController] showWindow:self];
}


// ------------------------------------------------------
/// show color code editor panel
- (IBAction)showHexColorCodeEditor:(id)sender
// ------------------------------------------------------
{
    [[CEColorCodePanelController sharedController] showWindow:self];
}


// ------------------------------------------------------
/// show view opacity panel
- (IBAction)showOpacityPanel:(id)sender
// ------------------------------------------------------
{
    [[CEOpacityPanelController sharedController] showWindow:self];
}


// ------------------------------------------------------
/// show line hight panel
- (IBAction)showLineHeightPanel:(id)sender
// ------------------------------------------------------
{
    [[CELineHightPanelController sharedController] showWindow:self];
}


// ------------------------------------------------------
/// show Unicode input panel
- (IBAction)showUnicodeInputPanel:(id)sender
// ------------------------------------------------------
{
    [[CEUnicodeInputPanelController sharedController] showWindow:self];
}


// ------------------------------------------------------
/// open OSAScript dictionary in Script Editor
- (IBAction)openAppleScriptDictionary:(id)sender
// ------------------------------------------------------
{
    NSURL *URL = [[NSBundle mainBundle] URLForResource:@"openDictionary" withExtension:@"scpt"];
    NSAppleScript *AppleScript = [[NSAppleScript alloc] initWithContentsOfURL:URL error:nil];
    [AppleScript executeAndReturnError:nil];
}


// ------------------------------------------------------
/// activate self and perform "New" menu action
- (IBAction)newInDockMenu:(id)sender
// ------------------------------------------------------
{
    [NSApp activateIgnoringOtherApps:YES];
    [[NSDocumentController sharedDocumentController] newDocument:nil];
}


// ------------------------------------------------------
/// activate self and perform "Open..." menu action
- (IBAction)openInDockMenu:(id)sender
// ------------------------------------------------------
{
    [NSApp activateIgnoringOtherApps:YES];
    [[NSDocumentController sharedDocumentController] openDocument:nil];
}


// ------------------------------------------------------
/// open a specific page in Help contents
- (IBAction)openHelpAnchor:(id)sender
// ------------------------------------------------------
{
    NSString *bookName = [[NSBundle mainBundle] objectForInfoDictionaryKey: @"CFBundleHelpBookName"];
    
    [[NSHelpManager sharedHelpManager] openHelpAnchor:kHelpAnchors[[sender tag]]
                                               inBook:bookName];
    
}


// ------------------------------------------------------
/// open bundled documents in TextEdit.app
- (IBAction)openBundledDocument:(id)sender
// ------------------------------------------------------
{
    NSString *fileName = kBundledDocumentFileNames[[sender tag]];
    NSURL *URL = [[NSBundle mainBundle] URLForResource:fileName withExtension:@"rtf"];
    
    [[NSWorkspace sharedWorkspace] openURL:URL];
}


// ------------------------------------------------------
/// open web site (coteditor.com) in default web browser
- (IBAction)openWebSite:(id)sender
// ------------------------------------------------------
{
    [[NSWorkspace sharedWorkspace] openURL:[NSURL URLWithString:kWebSiteURL]];
}


// ------------------------------------------------------
/// open bug report page in default web browser
- (IBAction)reportBug:(id)sender
// ------------------------------------------------------
{
    [[NSWorkspace sharedWorkspace] openURL:[NSURL URLWithString:kIssueTrackerURL]];
}


// ------------------------------------------------------
/// open new bug report window
- (IBAction)createBugReport:(id)sender
// ------------------------------------------------------
{
    NSDictionary *appInfo = [[NSBundle mainBundle] infoDictionary];
    NSURL *URL = [[NSBundle mainBundle] URLForResource:@"ReportTemplate" withExtension:@"md"];
    NSString *template = [NSString stringWithContentsOfURL:URL encoding:NSUTF8StringEncoding error:nil];
    
    template = [template stringByReplacingOccurrencesOfString:@"%BUNDLE_VERSION%"
                                                   withString:appInfo[@"CFBundleVersion"]];
    template = [template stringByReplacingOccurrencesOfString:@"%SHORT_VERSION%"
                                                   withString:appInfo[@"CFBundleShortVersionString"]];
    template = [template stringByReplacingOccurrencesOfString:@"%SYSTEM_VERSION%"
                                                   withString:[[NSProcessInfo processInfo] operatingSystemVersionString]];
    
    CEDocument *document = [[NSDocumentController sharedDocumentController] openUntitledDocumentAndDisplay:YES error:nil];
    [document doSetSyntaxStyle:@"Markdown"];
    [[document editor] setString:template];
    [[[document windowController] window] setTitle:NSLocalizedString(@"Bug Report", nil)];
}



#pragma mark Private Methods

//------------------------------------------------------
/// check existance of the support directory and create it if not exists
- (void)setupSupportDirectory
//------------------------------------------------------
{
    NSURL *URL = [self supportDirectoryURL];
    NSNumber *isDirectory;
    if (![URL getResourceValue:&isDirectory forKey:NSURLIsDirectoryKey error:nil]) {
        BOOL success = [[NSFileManager defaultManager] createDirectoryAtURL:URL
                                                withIntermediateDirectories:YES
                                                                 attributes:nil
                                                                      error:nil];
        if (!success) {
            NSLog(@"Failed to create support directory for CotEditor...");
        }
    } else if (![isDirectory boolValue]) {
        NSLog(@"\"%@\" is not dir.", URL);
    } else {
        [self setHasSetting:YES];
    }
}


//------------------------------------------------------
/// build encoding menu in the main menu
- (void)buildEncodingMenu
//------------------------------------------------------
{
    NSMenu *menu = [[[[[NSApp mainMenu] itemAtIndex:CEFormatMenuIndex] submenu] itemWithTag:CEFileEncodingMenuItemTag] submenu];
    [menu removeAllItems];
    
    NSArray *items = [[CEEncodingManager sharedManager] encodingMenuItems];
    for (NSMenuItem *item in items) {
        [item setAction:@selector(changeEncoding:)];
        [item setTarget:nil];
        [menu addItem:item];
    }
}


//------------------------------------------------------
/// build syntax style menu in the main menu
- (void)buildSyntaxMenu
//------------------------------------------------------
{
    NSMenu *menu = [[[[[NSApp mainMenu] itemAtIndex:CEFormatMenuIndex] submenu] itemWithTag:CESyntaxMenuItemTag] submenu];
    [menu removeAllItems];
    
    // add None
    [menu addItemWithTitle:NSLocalizedString(@"None", nil)
                    action:@selector(changeSyntaxStyle:)
             keyEquivalent:@""];
    
    [menu addItem:[NSMenuItem separatorItem]];
    
    // add syntax styles
    NSArray *styleNames = [[CESyntaxManager sharedManager] styleNames];
    for (NSString *styleName in styleNames) {
        [menu addItemWithTitle:styleName
                        action:@selector(changeSyntaxStyle:)
                 keyEquivalent:@""];
    }
    
    [menu addItem:[NSMenuItem separatorItem]];
    
    // add item to recolor
    NSMenuItem *item = [[NSMenuItem alloc] initWithTitle:NSLocalizedString(@"Re-Color All", nil)
                                                  action:@selector(recolorAll:)
                                           keyEquivalent:@"r"];
    [item setKeyEquivalentModifierMask:(NSCommandKeyMask | NSAlternateKeyMask)]; // = Cmd + Opt + R
    [menu addItem:item];
}


//------------------------------------------------------
/// build theme menu in the main menu
- (void)buildThemeMenu
//------------------------------------------------------
{
    NSMenu *menu = [[[[[NSApp mainMenu] itemAtIndex:CEFormatMenuIndex] submenu] itemWithTag:CEThemeMenuItemTag] submenu];
    [menu removeAllItems];
    
    NSArray *themeNames = [[CEThemeManager sharedManager] themeNames];
    for (NSString *themeName in themeNames) {
        [menu addItemWithTitle:themeName
                        action:@selector(changeTheme:)
                 keyEquivalent:@""];
    }
}

@end




#pragma mark -

@implementation CEAppDelegate (Services)

// ------------------------------------------------------
/// open new document with string via Services
- (void)openSelection:(NSPasteboard *)pboard userData:(NSString *)userData error:(NSString **)error
// ------------------------------------------------------
{
    NSError *err = nil;
    CEDocument *document = [[NSDocumentController sharedDocumentController] openUntitledDocumentAndDisplay:YES error:&err];
    NSString *selection = [pboard stringForType:NSPasteboardTypeString];
    
    if (document) {
//    [document readFromData:[selection dataUsingEncoding:NSUTF8StringEncoding] ofType:nil error:nil];
        [[document editor] replaceTextViewSelectedStringTo:selection scroll:NO];
    } else {
        [[NSAlert alertWithError:err] runModal];
    }
}


// ------------------------------------------------------
/// open files via Services
- (void)openFile:(NSPasteboard *)pboard userData:(NSString *)userData error:(NSString **)error
// ------------------------------------------------------
{
    for (NSPasteboardItem *item in [pboard pasteboardItems]) {
        NSString *type = [item availableTypeFromArray:@[(NSString *)kUTTypeFileURL, (NSString *)kUTTypeText]];
        NSURL *fileURL = [NSURL URLWithString:[item stringForType:type]];
        
        if (![fileURL checkResourceIsReachableAndReturnError:nil]) {
            continue;
        }
        
        // get file UTI
        NSString *uti = nil;
        [fileURL getResourceValue:&uti forKey:NSURLTypeIdentifierKey error:nil];
        
        // process only plain-text files
        if (![[NSWorkspace sharedWorkspace] type:uti conformsToType:(NSString *)kUTTypeText]) {
            NSError *err = [NSError errorWithDomain:NSCocoaErrorDomain
                                               code:NSFileReadCorruptFileError
                                           userInfo:@{NSURLErrorKey: fileURL}];
            [[NSAlert alertWithError:err] runModal];
            continue;
        }
        
        // open file
        [[NSDocumentController sharedDocumentController] openDocumentWithContentsOfURL:fileURL
                                                                               display:YES
                                                                     completionHandler:^(NSDocument *document,
                                                                                         BOOL documentWasAlreadyOpen,
                                                                                         NSError *error)
         {
             if (error) {
                 [[NSAlert alertWithError:error] runModal];
             }
         }];
    }
}

@end




#pragma mark -

@implementation CEAppDelegate (Migration)

static NSString *const kOldIdentifier = @"com.aynimac.CotEditor";
static NSString *const kMigrationFlagKey = @"isMigratedToNewBundleIdentifier";


//------------------------------------------------------
/// migrate user settings from CotEditor v1.x if needed
- (void)migrateIfNeeded
//------------------------------------------------------
{
    NSString *lastVersion = [[NSUserDefaults standardUserDefaults] stringForKey:CEDefaultLastVersionKey];
    
    if (!lastVersion && [self hasSetting]) {
        [self migrateToVersion2];
    }
}


//------------------------------------------------------
/// perform migration from CotEditor 1.x to 2.0
- (void)migrateToVersion2
//------------------------------------------------------
{
    // show migration window
    CEMigrationWindowController *windowController = [[CEMigrationWindowController alloc] init];
    [self setMigrationWindowController:windowController];
    [windowController showWindow:self];
    
    // reset menu keybindings setting
    [windowController setInformative:@"Restorering menu key bindings settings…"];
    [[CEKeyBindingManager sharedManager] resetMenuKeyBindings];
    [windowController progressIndicator];
    [windowController setDidResetKeyBindings:YES];
    
    // migrate coloring setting
    [windowController setInformative:@"Migrating coloring settings…"];
    BOOL didMigrate = [[CEThemeManager sharedManager] migrateTheme];
    [windowController progressIndicator];
    [windowController setDidMigrateTheme:didMigrate];
    
    // migrate syntax styles to modern style
    [windowController setInformative:@"Migrating user syntax styles…"];
    [[CESyntaxManager sharedManager] migrateStylesWithCompletionHandler:^(BOOL success) {
        [windowController setDidMigrateSyntaxStyles:success];
        
        [windowController setInformative:@"Migration finished."];
        [windowController setMigrationFinished:YES];
    }];
}


//------------------------------------------------------
/// copy user defaults from com.aynimac.CotEditor
- (void)migrateBundleIdentifier
//------------------------------------------------------
{
    NSUserDefaults *oldDefaults = [[NSUserDefaults alloc] init];
    NSMutableDictionary *oldDefaultsDict = [[oldDefaults persistentDomainForName:kOldIdentifier] mutableCopy];
    
    if (!oldDefaultsDict || [oldDefaultsDict[kMigrationFlagKey] boolValue]) { return; }
    
    // remove deprecated setting key with "NS"-prefix
    [oldDefaultsDict removeObjectForKey:@"NSDragAndDropTextDelay"];
    
    // copy to current defaults
    [[NSUserDefaults standardUserDefaults] setPersistentDomain:oldDefaultsDict
                                                       forName:[[NSBundle mainBundle] bundleIdentifier]];
    
    // set migration flag to old defaults
    oldDefaultsDict[kMigrationFlagKey] = @(YES);
    [oldDefaults setPersistentDomain:oldDefaultsDict forName:kOldIdentifier];
}

@end
