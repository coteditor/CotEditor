/*
 
 CEAppDelegate.m
 
 CotEditor
 http://coteditor.com
 
 Created by nakamuxu on 2004-12-13.

 ------------------------------------------------------------------------------
 
 © 2004-2007 nakamuxu
 © 2013-2016 1024jp
 
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

#import "CEAppDelegate.h"

#import "CESyntaxManager.h"
#import "CEEncodingManager.h"
#import "CEKeyBindingManager.h"
#import "CEScriptManager.h"
#import "CEThemeManager.h"

#import "CEHexColorTransformer.h"

#import "CEPreferencesWindowController.h"
#import "CEOpacityPanelController.h"
#import "CEColorCodePanelController.h"
#import "CEConsolePanelController.h"
#import "CEWebDocumentWindowController.h"
#import "CEMigrationWindowController.h"

#import "CEDocument.h"

#import "CEErrors.h"
#import "CEDefaults.h"
#import "CEEncodings.h"
#import "Constants.h"

#ifndef APPSTORE
#import "CEUpdaterManager.h"
#endif


@interface CEAppDelegate ()

@property (nonatomic) BOOL didFinishLaunching;

@property (nonatomic, nullable) CEWebDocumentWindowController *acknowledgementsWindowController;
@property (nonatomic, nullable) CEMigrationWindowController *migrationWindowController;

@property (nonatomic, nullable) IBOutlet NSMenu *encodingsMenu;
@property (nonatomic, nullable) IBOutlet NSMenu *syntaxStylesMenu;
@property (nonatomic, nullable) IBOutlet NSMenu *themesMenu;

@end



@interface CEAppDelegate (Migration)

- (void)migrateIfNeeded;

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
    NSMutableArray<NSNumber *> *encodings = [NSMutableArray arrayWithCapacity:kSizeOfCFStringEncodingList];
    for (NSUInteger i = 0; i < kSizeOfCFStringEncodingList; i++) {
        [encodings addObject:@(kCFStringEncodingList[i])];
    }
    
    NSDictionary<NSString *, id> *defaults = @{CEDefaultCreateNewAtStartupKey: @YES,
                                               CEDefaultReopenBlankWindowKey: @YES,
                                               CEDefaultEnablesAutosaveInPlaceKey: @NO,
                                               CEDefaultTrimsTrailingWhitespaceOnSaveKey: @NO,
                                               CEDefaultDocumentConflictOptionKey: @(CEDocumentConflictRevert),
                                               CEDefaultSyncFindPboardKey: @NO,
                                               CEDefaultInlineContextualScriptMenuKey: @NO,
                                               CEDefaultCountLineEndingAsCharKey: @YES,
                                               CEDefaultAutoLinkDetectionKey: @NO,
                                               CEDefaultCheckSpellingAsTypeKey: @NO,
                                               CEDefaultHighlightBracesKey: @YES,
                                               CEDefaultHighlightLtGtKey: @NO,
                                               CEDefaultChecksUpdatesForBetaKey: @NO,
                                               
                                               CEDefaultShowNavigationBarKey: @YES,
                                               CEDefaultShowDocumentInspectorKey: @NO,
                                               CEDefaultShowStatusBarKey: @YES,
                                               CEDefaultShowLineNumbersKey: @YES,
                                               CEDefaultShowPageGuideKey: @NO,
                                               CEDefaultPageGuideColumnKey: @80,
                                               CEDefaultShowStatusBarLinesKey: @YES,
                                               CEDefaultShowStatusBarCharsKey: @YES,
                                               CEDefaultShowStatusBarLengthKey: @NO,
                                               CEDefaultShowStatusBarWordsKey: @NO,
                                               CEDefaultShowStatusBarLocationKey: @YES,
                                               CEDefaultShowStatusBarLineKey: @YES,
                                               CEDefaultShowStatusBarColumnKey: @NO,
                                               CEDefaultShowStatusBarEncodingKey: @NO,
                                               CEDefaultShowStatusBarLineEndingsKey: @NO,
                                               CEDefaultShowStatusBarFileSizeKey: @YES,
                                               CEDefaultSplitViewVerticalKey: @NO,
                                               CEDefaultWindowWidthKey: @600.0f,
                                               CEDefaultWindowHeightKey: @620.0f,
                                               CEDefaultWindowAlphaKey: @1.0f,
                                               
                                               CEDefaultFontNameKey: [[NSFont userFontOfSize:0] fontName],
                                               CEDefaultFontSizeKey: @([NSFont systemFontSize]),
                                               CEDefaultShouldAntialiasKey: @YES,
                                               CEDefaultLineHeightKey: @1.2f,
                                               CEDefaultHighlightCurrentLineKey: @NO,
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
                                               CEDefaultThemeKey: @"Dendrobates",
                                               
                                               CEDefaultSmartInsertAndDeleteKey: @NO,
                                               CEDefaultBalancesBracketsKey: @NO,
                                               CEDefaultSwapYenAndBackSlashKey: @NO,
                                               CEDefaultEnableSmartQuotesKey: @NO,
                                               CEDefaultEnableSmartDashesKey: @NO,
                                               CEDefaultAutoIndentKey: @YES,
                                               CEDefaultTabWidthKey: @4U,
                                               CEDefaultAutoExpandTabKey: @NO,
                                               CEDefaultDetectsIndentStyleKey: @YES,
                                               CEDefaultAppendsCommentSpacerKey: @YES,
                                               CEDefaultCommentsAtLineHeadKey: @YES,
                                               CEDefaultWrapLinesKey: @YES,
                                               CEDefaultEnablesHangingIndentKey: @YES,
                                               CEDefaultHangingIndentWidthKey: @0U,
                                               CEDefaultCompletesDocumentWordsKey: @YES,
                                               CEDefaultCompletesSyntaxWordsKey: @YES,
                                               CEDefaultCompletesStandartWordsKey: @NO,
                                               CEDefaultAutoCompleteKey: @NO,
                                               
                                               CEDefaultLineEndCharCodeKey: @0,
                                               CEDefaultEncodingListKey: encodings,
                                               CEDefaultEncodingInNewKey: @(CFStringConvertEncodingToNSStringEncoding(kCFStringEncodingUTF8)),
                                               CEDefaultEncodingInOpenKey: @(CEAutoDetectEncoding),
                                               CEDefaultSaveUTF8BOMKey: @NO,
                                               CEDefaultReferToEncodingTagKey: @YES,
                                               CEDefaultEnableSyntaxHighlightKey: @YES,
                                               CEDefaultSyntaxStyleKey: @"Plain Text",
                                               
                                               CEDefaultFileDropArrayKey: @[@{CEFileDropExtensionsKey: @"jpg, jpeg, gif, png",
                                                                              CEFileDropFormatStringKey: @"<img src=\"<<<RELATIVE-PATH>>>\" alt=\"<<<FILENAME-NOSUFFIX>>>\" title=\"<<<FILENAME-NOSUFFIX>>>\" width=\"<<<IMAGEWIDTH>>>\" height=\"<<<IMAGEHEIGHT>>>\" />"}],
                                               
                                               CEDefaultInsertCustomTextArrayKey: @[@"<br />\n", @"", @"", @"", @"", @"", @"", @"", @"", @"", @"",
                                                                                    @"", @"", @"", @"", @"", @"", @"", @"", @"", @"",
                                                                                    @"", @"", @"", @"", @"", @"", @"", @"", @"", @""],
                                               
                                               CEDefaultSetPrintFontKey: @0,
                                               CEDefaultPrintFontNameKey: [[NSFont userFontOfSize:0] fontName],
                                               CEDefaultPrintFontSizeKey: @([NSFont systemFontSize]),
                                               CEDefaultPrintColorIndexKey: @(CEPrintColorBlackWhite),
                                               CEDefaultPrintLineNumIndexKey: @(CELinePrintNo),
                                               CEDefaultPrintInvisibleCharIndexKey: @(CEInvisibleCharsPrintNo),
                                               CEDefaultPrintHeaderKey: @YES,
                                               CEDefaultPrimaryHeaderContentKey: @(CEPrintInfoFilePath),
                                               CEDefaultPrimaryHeaderAlignmentKey: @(CEAlignLeft),
                                               CEDefaultSecondaryHeaderContentKey: @(CEPrintInfoPrintDate),
                                               CEDefaultSecondaryHeaderAlignmentKey: @(CEAlignRight),
                                               CEDefaultPrintFooterKey: @YES,
                                               CEDefaultPrimaryFooterContentKey: @(CEPrintInfoNone),
                                               CEDefaultPrimaryFooterAlignmentKey: @(CEAlignLeft),
                                               CEDefaultSecondaryFooterContentKey: @(CEPrintInfoPageNumber),
                                               CEDefaultSecondaryFooterAlignmentKey: @(CEAlignCenter),
                                               
                                               // ------ settings not in preferences window ------
                                               CEDefaultColorCodeTypeKey: @1,
                                               CEDefaultSidebarWidthKey: @220,
                                               CEDefaultRecentStyleNamesKey: @{},
                                               
                                               // settings for find panel are register in CETextFinder
                                               
                                               // ------ hidden settings ------
                                               CEDefaultUsesTextFontForInvisiblesKey: @NO,
                                               CEDefaultHeaderFooterDateFormatKey: @"YYYY-MM-dd HH:mm",
                                               CEDefaultHeaderFooterPathAbbreviatingWithTildeKey: @YES,
                                               CEDefaultAutoCompletionDelayKey: @0.25f,
                                               CEDefaultInfoUpdateIntervalKey: @0.2f,
                                               CEDefaultOutlineMenuIntervalKey: @0.37f,
                                               CEDefaultShowColoringIndicatorTextLengthKey: @75000U,
                                               CEDefaultColoringRangeBufferLengthKey: @5000U,
                                               CEDefaultLargeFileAlertThresholdKey: @(50 * pow(1024, 2)),  // 50 MB
                                               CEDefaultAutosavingDelayKey: @5.0f,
                                               CEDefaultSavesTextOrientationKey: @YES,
                                               CEDefaultLayoutTextVerticalKey: @NO,
                                               CEDefaultEnableSmartIndentKey: @YES,
                                               CEDefaultMaximumRecentStyleCountKey: @6U,
                                               };
    [[NSUserDefaults standardUserDefaults] registerDefaults:defaults];
    
    // set initial values to NSUserDefaultsController which can be restored to defaults
    NSDictionary<NSString *, id> *initialValues = [defaults dictionaryWithValuesForKeys:@[CEDefaultEncodingListKey,
                                                                                          CEDefaultInsertCustomTextArrayKey,
                                                                                          CEDefaultWindowWidthKey,
                                                                                          CEDefaultWindowHeightKey]];
    [[NSUserDefaultsController sharedUserDefaultsController] setInitialValues:initialValues];
    
    // register transformers
    [NSValueTransformer setValueTransformer:[[CEHexColorTransformer alloc] init]
                                    forName:@"CEHexColorTransformer"];
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
    // store key bindings in MainMenu.xib before menu is modified
    [[CEKeyBindingManager sharedManager] scanDefaultMenuKeyBindings];
    
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



#pragma mark Delegate

//=======================================================
// NSApplicationDelegate  < File's Owner
//=======================================================

// ------------------------------------------------------
/// creates a new document on launch?
- (BOOL)applicationShouldOpenUntitledFile:(nonnull NSApplication *)sender
// ------------------------------------------------------
{
    if (![self didFinishLaunching]) {
        return [[NSUserDefaults standardUserDefaults] boolForKey:CEDefaultCreateNewAtStartupKey];
    }
    
    return YES;
}


// ------------------------------------------------------
/// crates a new document on "Re-Open" AppleEvent
- (BOOL)applicationShouldHandleReopen:(nonnull NSApplication *)application hasVisibleWindows:(BOOL)flag
// ------------------------------------------------------
{
    if ([[NSUserDefaults standardUserDefaults] boolForKey:CEDefaultReopenBlankWindowKey]) {
        return YES;
    }
    
    return flag;
}


#ifndef APPSTORE
// ------------------------------------------------------
/// setup Sparkle framework
- (void)applicationWillFinishLaunching:(nonnull NSNotification *)notification
// ------------------------------------------------------
{
    // setup updater
    [[CEUpdaterManager sharedManager] setup];
}
#endif


// ------------------------------------------------------
/// just after application did launch
- (void)applicationDidFinishLaunching:(nonnull NSNotification *)notification
// ------------------------------------------------------
{
    // setup KeyBindingManager
    [[CEKeyBindingManager sharedManager] applyKeyBindingsToMainMenu];
    
    // migrate user settings if needed
    [self migrateIfNeeded];
    
    // store latest version
    //     The bundle version (build number) format was changed on CotEditor 2.2.0. due to the iTunes Connect versioning rule.
    //      < 2.2.0 : The Semantic Versioning
    //     >= 2.2.0 : Single Integer
    NSString *lastVersion = [[NSUserDefaults standardUserDefaults] stringForKey:CEDefaultLastVersionKey];
    NSString *thisVersion = [[NSBundle mainBundle] objectForInfoDictionaryKey:(NSString *)kCFBundleVersionKey];
    
    BOOL isDigit = lastVersion && [lastVersion rangeOfString:@"^[\\d]+$" options:NSRegularExpressionSearch].location != NSNotFound;
    BOOL isPreRelease = lastVersion && [lastVersion rangeOfString:@"^[\\d]+[a-z]+[\\d]?$" options:NSRegularExpressionSearch].location != NSNotFound;
    //  -> [@"100b3" integerValue] is 100
    
    if ((!lastVersion) ||  // first launch
        (!isDigit && !isPreRelease) ||  // probably semver (semver must be older than 2.2.0)
        ((isDigit || isPreRelease) && ([thisVersion integerValue] > [lastVersion integerValue])))  // normal integer or Sparkle-style pre-release
    {
        [[NSUserDefaults standardUserDefaults] setObject:thisVersion forKey:CEDefaultLastVersionKey];
    }
    
    // register Services
    [NSApp setServicesProvider:self];
    
    // raise didFinishLaunching flag
    [self setDidFinishLaunching:YES];
}


// ------------------------------------------------------
/// open file
- (BOOL)application:(nonnull NSApplication *)application openFile:(nonnull NSString *)filename
// ------------------------------------------------------
{
    // perform install if the file is CotEditor theme file
    if ([[filename pathExtension] isEqualToString:CEThemeExtension]) {
        NSURL *URL = [NSURL fileURLWithPath:filename];
        NSString *themeName = [[URL lastPathComponent] stringByDeletingPathExtension];
        
        // ask whether theme file should be opened as a text file
        NSAlert *alert = [[NSAlert alloc] init];
        [alert setMessageText:[NSString stringWithFormat:NSLocalizedString(@"“%@” is a CotEditor theme file.", nil), [URL lastPathComponent]]];
        [alert setInformativeText:NSLocalizedString(@"Do you want to install this theme?", nil)];
        [alert addButtonWithTitle:NSLocalizedString(@"Install", nil)];
        [alert addButtonWithTitle:NSLocalizedString(@"Open as Text File", nil)];
        
        NSInteger returnCode = [alert runModal];
        if (returnCode == NSAlertSecondButtonReturn) {  // = Open as Text File
            return NO;
        }
        
        // import theme
        NSError *error = nil;
        BOOL success = [[CEThemeManager sharedManager] importSettingWithFileURL:URL error:&error];
        
        // ask whether the old theme should be repleced with new one if the same name theme is already exists
        if (!success && error) {
            success = [NSApp presentError:error];
        }
        
        // feedback for succession
        if (success) {
            [[NSSound soundNamed:@"Glass"] play];
            NSAlert *alert = [[NSAlert alloc] init];
            [alert setMessageText:[NSString stringWithFormat:NSLocalizedString(@"A new theme named “%@” has been successfully installed.", nil), themeName]];
            [alert runModal];
        }
        
        return YES;
    }
    
    return NO;
}



#pragma mark Action Messages

// ------------------------------------------------------
/// activate self and perform "New" menu action
- (IBAction)newInDockMenu:(nullable id)sender
// ------------------------------------------------------
{
    [NSApp activateIgnoringOtherApps:YES];
    [[NSDocumentController sharedDocumentController] newDocument:nil];
}


// ------------------------------------------------------
/// activate self and perform "Open..." menu action
- (IBAction)openInDockMenu:(nullable id)sender
// ------------------------------------------------------
{
    [NSApp activateIgnoringOtherApps:YES];
    [[NSDocumentController sharedDocumentController] openDocument:nil];
}


// ------------------------------------------------------
/// show Preferences window
- (IBAction)showPreferences:(nullable id)sender
// ------------------------------------------------------
{
    [[CEPreferencesWindowController sharedController] showWindow:self];
}


// ------------------------------------------------------
/// Show console panel
- (IBAction)showConsolePanel:(nullable id)sender
// ------------------------------------------------------
{
    [[CEConsolePanelController sharedController] showWindow:self];
}


// ------------------------------------------------------
/// show color code editor panel
- (IBAction)showColorCodePanel:(nullable id)sender
// ------------------------------------------------------
{
    [[CEColorCodePanelController sharedController] showWindow:self];
}


// ------------------------------------------------------
/// show view opacity panel
- (IBAction)showOpacityPanel:(nullable id)sender
// ------------------------------------------------------
{
    [[CEOpacityPanelController sharedController] showWindow:self];
}


// ------------------------------------------------------
/// show acknowlegements
- (IBAction)showAcknowledgements:(nullable id)sender
// ------------------------------------------------------
{
    if (![self acknowledgementsWindowController]) {
        [self setAcknowledgementsWindowController:[[CEWebDocumentWindowController alloc] initWithDocumentName:@"Acknowledgements"]];
    }
    
    [[self acknowledgementsWindowController] showWindow:sender];
}


// ------------------------------------------------------
/// open OSAScript dictionary in Script Editor
- (IBAction)openAppleScriptDictionary:(nullable id)sender
// ------------------------------------------------------
{
    NSURL *appURL = [[NSBundle mainBundle] bundleURL];
    NSString *scriptEditorIdentifier = @"com.apple.ScriptEditor2";
    
    [[NSWorkspace sharedWorkspace] openURLs:@[appURL] withAppBundleIdentifier:scriptEditorIdentifier
                                    options:0 additionalEventParamDescriptor:nil launchIdentifiers:nil];
}


// ------------------------------------------------------
/// open a specific page in Help contents
- (IBAction)openHelpAnchor:(nullable id)sender
// ------------------------------------------------------
{
    NSString *bookName = [[NSBundle mainBundle] objectForInfoDictionaryKey:@"CFBundleHelpBookName"];
    
    [[NSHelpManager sharedHelpManager] openHelpAnchor:kHelpAnchors[[sender tag]]
                                               inBook:bookName];
}


// ------------------------------------------------------
/// open web site (coteditor.com) in default web browser
- (IBAction)openWebSite:(nullable id)sender
// ------------------------------------------------------
{
    [[NSWorkspace sharedWorkspace] openURL:[NSURL URLWithString:kWebSiteURL]];
}


// ------------------------------------------------------
/// open bug report page in default web browser
- (IBAction)reportBug:(nullable id)sender
// ------------------------------------------------------
{
    [[NSWorkspace sharedWorkspace] openURL:[NSURL URLWithString:kIssueTrackerURL]];
}


// ------------------------------------------------------
/// open new bug report window
- (IBAction)createBugReport:(nullable id)sender
// ------------------------------------------------------
{
    NSBundle *bundle = [NSBundle mainBundle];
    NSURL *URL = [bundle URLForResource:@"ReportTemplate" withExtension:@"md"];
    NSString *template = [NSString stringWithContentsOfURL:URL encoding:NSUTF8StringEncoding error:nil];
    
    template = [template stringByReplacingOccurrencesOfString:@"%BUNDLE_VERSION%"
                                                   withString:[bundle objectForInfoDictionaryKey:(NSString *)kCFBundleVersionKey]];
    template = [template stringByReplacingOccurrencesOfString:@"%SHORT_VERSION%"
                                                   withString:[bundle objectForInfoDictionaryKey:@"CFBundleShortVersionString"]];
    template = [template stringByReplacingOccurrencesOfString:@"%SYSTEM_VERSION%"
                                                   withString:[[NSProcessInfo processInfo] operatingSystemVersionString]];
    
    CEDocument *document = [[NSDocumentController sharedDocumentController] openUntitledDocumentAndDisplay:NO error:nil];
    [document setDisplayName:NSLocalizedString(@"Bug Report", nil)];
    [[document textStorage] replaceCharactersInRange:NSMakeRange(0, 0) withString:template];
    [document setSyntaxStyleWithName:@"Markdown"];
    [document makeWindowControllers];
    [document showWindows];
}



#pragma mark Private Methods

//------------------------------------------------------
/// build encoding menu in the main menu
- (void)buildEncodingMenu
//------------------------------------------------------
{
    NSMenu *menu = [self encodingsMenu];
    
    [[CEEncodingManager sharedManager] updateChangeEncodingMenu:menu];
}


//------------------------------------------------------
/// build syntax style menu in the main menu
- (void)buildSyntaxMenu
//------------------------------------------------------
{
    NSMenu *menu = [self syntaxStylesMenu];
    [menu removeAllItems];
    
    // add None
    [menu addItemWithTitle:NSLocalizedString(@"None", nil)
                    action:@selector(changeSyntaxStyle:)
             keyEquivalent:@""];
    
    [menu addItem:[NSMenuItem separatorItem]];
    
    // add syntax styles
    NSArray<NSString *> *styleNames = [[CESyntaxManager sharedManager] styleNames];
    for (NSString *styleName in styleNames) {
        [menu addItemWithTitle:styleName
                        action:@selector(changeSyntaxStyle:)
                 keyEquivalent:@""];
    }
    
    [menu addItem:[NSMenuItem separatorItem]];
    
    // add item to recolor
    SEL recolorAction = @selector(recolorAll:);
    NSEventModifierFlags modifierMask;
    NSString *keyEquivalent = [[CEKeyBindingManager sharedManager] keyEquivalentForAction:recolorAction modifierMask:&modifierMask];
    NSMenuItem *item = [[NSMenuItem alloc] initWithTitle:NSLocalizedString(@"Re-Color All", nil)
                                                  action:recolorAction
                                           keyEquivalent:keyEquivalent];
    [item setKeyEquivalentModifierMask:modifierMask]; // = Cmd + Opt + R
    [menu addItem:item];
}


//------------------------------------------------------
/// build theme menu in the main menu
- (void)buildThemeMenu
//------------------------------------------------------
{
    NSMenu *menu = [self themesMenu];
    [menu removeAllItems];
    
    NSArray<NSString *> *themeNames = [[CEThemeManager sharedManager] themeNames];
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
- (void)openSelection:(nonnull NSPasteboard *)pboard userData:(nonnull NSString *)userData error:(NSString * _Nullable * _Nullable)error
// ------------------------------------------------------
{
    NSString *selection = [pboard stringForType:NSPasteboardTypeString];
    
    if (!selection) { return; }
    
    NSError *err = nil;
    CEDocument *document = [[NSDocumentController sharedDocumentController] openUntitledDocumentAndDisplay:NO error:&err];
    
    if (document) {
        [[document textStorage] replaceCharactersInRange:NSMakeRange(0, 0) withString:selection];
        [document makeWindowControllers];
        [document showWindows];
    } else {
        [[NSAlert alertWithError:err] runModal];
    }
}


// ------------------------------------------------------
/// open files via Services
- (void)openFile:(nonnull NSPasteboard *)pboard userData:(nonnull NSString *)userData error:(NSString * _Nullable * _Nullable)error
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
                                                                     completionHandler:^(NSDocument * _Nullable document,
                                                                                         BOOL documentWasAlreadyOpen,
                                                                                         NSError * _Nullable error)
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

//------------------------------------------------------
/// migrate user settings from CotEditor v1.x if needed
- (void)migrateIfNeeded
//------------------------------------------------------
{
    NSString *lastVersion = [[NSUserDefaults standardUserDefaults] stringForKey:CEDefaultLastVersionKey];
    NSURL *keybindingURL = [[CEKeyBindingManager sharedManager] userSettingDirectoryURL];  // KeyBindings dir was invariably made on the previous versions.
    
    if (!lastVersion && [keybindingURL checkResourceIsReachableAndReturnError:nil]) {
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
    [windowController setInformative:@"Restoring menu key bindings settings…"];
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

@end
