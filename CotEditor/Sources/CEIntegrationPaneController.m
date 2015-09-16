/*
 
 CEIntegrationPaneController.m
 
 CotEditor
 http://coteditor.com
 
 Created by 1024jp on 2014-12-20.

 ------------------------------------------------------------------------------
 
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

@import ObjectiveC.message;
#import "CEIntegrationPaneController.h"
#import "Constants.h"


// for OS X 10.10 SDK
#define CEAppKitVersionNumber10_11 1404

static NSString *const kPreferredSymbolicLinkPath = @"/usr/local/bin/cot";


@interface CEIntegrationPaneController ()

@property (nonatomic, nonnull) NSURL *preferredLinkTargetURL;
@property (nonatomic, nonnull) NSURL *preferredLinkURL;
@property (nonatomic, nonnull) NSURL *linkURL;
@property (nonatomic, nonnull) NSURL *commandURL;
@property (nonatomic, getter=isUninstallable) BOOL uninstallable;
@property (nonatomic, getter=isInstalled) BOOL installed;
@property (nonatomic, nullable, copy) NSString *warning;

@property (nonatomic, nullable, weak) IBOutlet NSButton *installButton;

@end




#pragma mark -

@implementation CEIntegrationPaneController

#pragma mark Superclass Methods

// ------------------------------------------------------
/// initialize instance
- (nullable instancetype)initWithNibName:(nullable NSString *)nibNameOrNil bundle:(nullable NSBundle *)nibBundleOrNil
// ------------------------------------------------------
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        NSString *appName = [[NSBundle mainBundle] objectForInfoDictionaryKey:@"CFBundleName"];
        NSURL *applicationDirURL = [[NSFileManager defaultManager] URLForDirectory:NSApplicationDirectory
                                                                          inDomain:NSLocalDomainMask
                                                                 appropriateForURL:nil
                                                                            create:NO
                                                                             error:nil];
        _preferredLinkTargetURL = [[[applicationDirURL URLByAppendingPathComponent:appName] URLByAppendingPathExtension:@"app"]
                                   URLByAppendingPathComponent:@"Contents/SharedSupport/bin/cot"];
        
        _preferredLinkURL = [NSURL fileURLWithPath:kPreferredSymbolicLinkPath];
        _commandURL = [[[NSBundle mainBundle] sharedSupportURL] URLByAppendingPathComponent:@"bin/cot"];
        _uninstallable = YES;
    }
    return self;
}


// ------------------------------------------------------
/// setup UI
- (void)loadView
// ------------------------------------------------------
{
    [super loadView];
    
    [self setInstalled:[self validateSymlink]];
    [self toggleInstallButtonState:[self isInstalled]];
}


// ------------------------------------------------------
/// update warnings before view appears (only on OS X 10.10 and later)
- (void)viewWillAppear
// ------------------------------------------------------
{
    [super viewWillAppear];
    
    [self setInstalled:[self validateSymlink]];
    [self toggleInstallButtonState:[self isInstalled]];
}



#pragma mark Protocol

//=======================================================
// NSErrorRecoveryAttempting Protocol
//=======================================================

// ------------------------------------------------------
/// alert asking to install command-line tool is closed (invoked in `install:`)
- (void)attemptRecoveryFromError:(nonnull NSError *)error optionIndex:(NSUInteger)recoveryOptionIndex delegate:(nullable id)delegate didRecoverSelector:(SEL)didRecoverSelector contextInfo:(nullable void *)contextInfo
// ------------------------------------------------------
{
    BOOL success = NO;
    
    if ([[error domain] isEqualToString:CEErrorDomain] &&
        ([error code] == CEApplicationNameIsModifiedError || [error code] == CEApplicationNotInApplicationDirectoryError))
    {
        if (recoveryOptionIndex == 0) {  // Install
            [self performInstall];
        }
        success = YES;
    }
    
    objc_msgSend(delegate, didRecoverSelector, success, contextInfo);
}



#pragma mark Action Messages

// ------------------------------------------------------
/// "Install" button is clicked
- (IBAction)install:(nullable id)sender
// ------------------------------------------------------
{
    NSError *error = nil;
    
    if (![self checkApplicationLocationAndReturnError:&error]) {
        NSBeep();
        [[self view] presentError:error modalForWindow:[[self view] window]
                         delegate:nil didPresentSelector:NULL contextInfo:NULL];
        return;
    }
    
    [self performInstall];
}


// ------------------------------------------------------
///  "Uninstall" button is clicked
- (IBAction)uninstall:(nullable id)sender
// ------------------------------------------------------
{
    // just turn off the button if command is already uninstalled
    if (![[self linkURL] checkResourceIsReachableAndReturnError:nil]) {
        [self setInstalled:[self validateSymlink]];
        [self toggleInstallButtonState:NO];
        return;
    }
    
    [self performUninstall];
}



#pragma mark Private Methods

// ------------------------------------------------------
/// return stored installed location if available
- (nullable NSURL *)bookmarkedURL
// ------------------------------------------------------
{
    NSData *bookmarkData = [[NSUserDefaults standardUserDefaults] objectForKey:CEDefaultCotCommandBookmarkKey];
    NSError *error = nil;
    NSURL *url = [NSURL URLByResolvingBookmarkData:bookmarkData
                                           options:NSURLBookmarkResolutionWithSecurityScope
                                     relativeToURL:nil
                               bookmarkDataIsStale:NO
                                             error:&error];
    
    return url;
}

// ------------------------------------------------------
/// build install command (this is actually not used...)
- (nonnull NSString *)installCommandString
// ------------------------------------------------------
{
    return [NSString stringWithFormat:@"ln -s \"%s\" \"%s\"",
                         [[[self commandURL] path] fileSystemRepresentation],
                         [[[self preferredLinkURL] path] fileSystemRepresentation]];
}


// ------------------------------------------------------
/// build uninstall command
- (nonnull NSString *)uninstallCommandString
// ------------------------------------------------------
{
    return [NSString stringWithFormat:@"unlink \"%s\"",
                         [[[self linkURL] path] fileSystemRepresentation]];
}


// ------------------------------------------------------
/// create symlink to `cot` command in bundle
- (void)performInstall
// ------------------------------------------------------
{
    __weak typeof(self) weakSelf = self;
    NSOpenPanel *openPanel = [NSOpenPanel openPanel];
    [openPanel setDirectoryURL:[[self preferredLinkURL] URLByDeletingLastPathComponent]];
    [openPanel setCanChooseFiles:NO];
    [openPanel setCanChooseDirectories:YES];
    [openPanel setMessage:[NSString stringWithFormat:NSLocalizedString(@"Select “Install” to install the command-line tool at the following location.\nThe default location is: %@", nil), [[self preferredLinkURL] path]]];
    [openPanel setPrompt:NSLocalizedString(@"Install", nil)];
    
    [openPanel beginSheetModalForWindow:[[self view] window]
                      completionHandler:^(NSInteger returnCode)
     {
         if (returnCode == NSFileHandlingPanelCancelButton) { return; }
         
         typeof(weakSelf) self = weakSelf;  // strong self
         
         NSURL *URL = [openPanel URL];
         NSError *error = nil;
         
         [[NSFileManager defaultManager] createSymbolicLinkAtURL:[URL URLByAppendingPathComponent:@"cot"]
                                              withDestinationURL:[self commandURL]
                                                           error:&error];
         
         if (error) {
             NSBeep();
             [[self view] presentError:error modalForWindow:[[self view] window]
                              delegate:nil didPresentSelector:NULL contextInfo:NULL];
             return;
         }
         
         // store installed URL for future use under Sandboxed environment
         NSData *bookmarkData = [URL bookmarkDataWithOptions:NSURLBookmarkCreationWithSecurityScope
                              includingResourceValuesForKeys:@[]
                                               relativeToURL:nil
                                                       error:&error];
         [[NSUserDefaults standardUserDefaults] setObject:bookmarkData forKey:CEDefaultCotCommandBookmarkKey];
         
         [self setInstalled:YES];
         [self toggleInstallButtonState:YES];
         [self validateSymlink];
     }];
}


// ------------------------------------------------------
/// unlink symlink at "/usr/local/bin/cot"
- (void)performUninstall
// ------------------------------------------------------
{
    // read stored cot command URL
    NSURL *url = [self bookmarkedURL];
    
    // uninstall cot command at the bookmarked Location
    if (url) {
        [url startAccessingSecurityScopedResource];
        [self uninsatllCommandAt:[url URLByAppendingPathComponent:@"cot"] securityScoped:YES];
        [url stopAccessingSecurityScopedResource];
        return;
    }
    
    // just show an uninstallation guide as a sheet
    [self showUninsatllGuideWithDescription:NSLocalizedString(@"Uninstallation was denied by the system.", nil)];
}


// ------------------------------------------------------
/// unlink symbolic link at given URL
- (void)uninsatllCommandAt:(nonnull NSURL *)URL securityScoped:(BOOL)isSecurityScoped
// ------------------------------------------------------
{
    if (isSecurityScoped) {
        [URL startAccessingSecurityScopedResource];
    }
    
    int status = unlink([[URL path] fileSystemRepresentation]);
    
    if (isSecurityScoped) {
        [URL stopAccessingSecurityScopedResource];
    }
    
    if (status >= 0) {
        if (isSecurityScoped) {
            [[NSUserDefaults standardUserDefaults] removeObjectForKey:CEDefaultCotCommandBookmarkKey];
        }
        
        [self setInstalled:NO];
        [self toggleInstallButtonState:NO];
        [self validateSymlink];
    }
}


// ------------------------------------------------------
/// display command install guide in Terminal.app as a sheet
- (void)showInstallGuideWithDescription:(nonnull NSString *)description
// ------------------------------------------------------
{
    NSString *suggestion = [NSString stringWithFormat:@"%@\n\n\t%@", NSLocalizedString(@"You can install cot command manually running the following command on Terminal:", nil), [self installCommandString]];
    
    NSError *error = [NSError errorWithDomain:CEErrorDomain
                                         code:CESymlinkCreationDeniedError
                                     userInfo:@{NSLocalizedDescriptionKey: description,
                                                NSLocalizedRecoverySuggestionErrorKey: suggestion,
                                                NSURLErrorKey: [self preferredLinkURL],
                                                NSHelpAnchorErrorKey: @"about_cot"}];
    
    [[self view] presentError:error modalForWindow:[[self view] window]
                     delegate:nil didPresentSelector:NULL contextInfo:NULL];
}


// ------------------------------------------------------
/// display command uninstall guide in Terminal.app as a sheet
- (void)showUninsatllGuideWithDescription:(nonnull NSString *)description
// ------------------------------------------------------
{
    NSString *suggestion = [NSString stringWithFormat:@"%@\n\n\t%@", NSLocalizedString(@"You can uninstall cot command manually running the following command on Terminal:", nil), [self uninstallCommandString]];
    
    NSError *error = [NSError errorWithDomain:CEErrorDomain
                                         code:CESymlinkCreationDeniedError
                                     userInfo:@{NSLocalizedDescriptionKey: description,
                                                NSLocalizedRecoverySuggestionErrorKey: suggestion,
                                                NSURLErrorKey: [self linkURL],
                                                NSHelpAnchorErrorKey: @"about_cot"}];
    
    [[self view] presentError:error modalForWindow:[[self view] window]
                     delegate:nil didPresentSelector:NULL contextInfo:NULL];
}


// ------------------------------------------------------
/// toggle Install button state between Install and Uninstall
- (void)toggleInstallButtonState:(BOOL)toUninstall
// ------------------------------------------------------
{
    if (toUninstall) {
        [[self installButton] setAction:@selector(uninstall:)];
        [[self installButton] setTitle:NSLocalizedString(@"Uninstall", nil)];
    } else {
        [[self installButton] setAction:@selector(install:)];
        [[self installButton] setTitle:NSLocalizedString(@"Install", nil)];
    }
}


// ------------------------------------------------------
/// check the destination of symlink and return whether 'cot' command is exists at '/usr/local/bin/'
- (BOOL)validateSymlink
// ------------------------------------------------------
{
    // reset once
    [self setUninstallable:YES];
    [self setWarning:nil];
    
    // use bookmarked link to display and to uninstall if it's valid
    NSURL *bookmarkedURL = [self bookmarkedURL];
    if (bookmarkedURL) {
        [bookmarkedURL startAccessingSecurityScopedResource];
        bookmarkedURL = [bookmarkedURL URLByAppendingPathComponent:@"cot"];
        [bookmarkedURL stopAccessingSecurityScopedResource];
    }
    if ([bookmarkedURL checkResourceIsReachableAndReturnError:nil]) {
        [self setLinkURL:bookmarkedURL];
    } else {
        [self setLinkURL:[self preferredLinkURL]];
    }
    
    // not installed yet (= can install)
    if (![[self linkURL] checkResourceIsReachableAndReturnError:nil]) {
        return NO;
    }
    
    // ???: `URLByResolvingSymlinksInPath` doesn't work correctly on OS X 10.10 SDK, so I use a legacy way (2015-08).
//    NSURL *linkDestinationURL = [[self linkURL] URLByResolvingSymlinksInPath];
    NSURL *linkDestinationURL = [NSURL fileURLWithPath:[[NSFileManager defaultManager]
                                                        destinationOfSymbolicLinkAtPath:[[self linkURL] path] error:nil]];
    
    // if it is not a symlink
    if ([linkDestinationURL isEqual:[self linkURL]]) {
        [self setUninstallable:NO];  // treat as "installed"
        return YES;
    }
    
    if ([linkDestinationURL isEqual:[[self commandURL] URLByStandardizingPath]] ||
        [linkDestinationURL isEqual:[self preferredLinkTargetURL]])  // link to '/Applications/CotEditor.app' is always valid
    {
        // totaly valid link
        return YES;
    }
    
    // display warning for invalid link
    if ([linkDestinationURL checkResourceIsReachableAndReturnError:nil]) {
        // link destinaiton is not running CotEditor
        [self setWarning:NSLocalizedString(@"The current 'cot' symbolic link doesn’t target the running CotEditor.", nil)];
    } else {
        // link destination is unreachable
        [self setWarning:NSLocalizedString(@"The current 'cot' symbolic link may target on an invalid path.", nil)];
    }
    
    return YES;
}


// ------------------------------------------------------
/// check whether current running CotEditor is located in the /Application directory
- (BOOL)checkApplicationLocationAndReturnError:(NSError * _Nullable __autoreleasing * _Nullable)outError
// ------------------------------------------------------
{
    NSString *preferredAppName = [[NSBundle mainBundle] objectForInfoDictionaryKey:@"CFBundleName"];
    NSURL *appURL = [[NSBundle mainBundle] bundleURL];
    
    // check current running app's location only on Yosemite and later (2015-02 by 1024jp)
    // (Just because `getRelation:~` is first available on Yosemite.)
    if (NSAppKitVersionNumber >= NSAppKitVersionNumber10_10) {
        NSURLRelationship relationship;
        [[NSFileManager defaultManager] getRelationship:&relationship
                                            ofDirectory:NSApplicationDirectory
                                               inDomain:NSLocalDomainMask
                                            toItemAtURL:appURL
                                                  error:nil];
        
        if (relationship != NSURLRelationshipContains) {
            if (outError) {
                *outError = [NSError errorWithDomain:CEErrorDomain
                                                code:CEApplicationNotInApplicationDirectoryError
                                            userInfo:@{NSLocalizedDescriptionKey: NSLocalizedString(@"The running CotEditor is not located in the Applications folder.", nil),
                                                       NSLocalizedRecoverySuggestionErrorKey: [NSString stringWithFormat:NSLocalizedString(@"Do you really want to install the command-line tool for CotEditor at “%@”?\n\nThe command will be invalid if the location of CotEditor is moved.", nil),
                                                                                               [[[NSBundle mainBundle] bundleURL] path]],
                                                       NSLocalizedRecoveryOptionsErrorKey: @[NSLocalizedString(@"Install", nil),
                                                                                             NSLocalizedString(@"Cancel", nil)],
                                                       NSRecoveryAttempterErrorKey: self,
                                                       NSURLErrorKey: appURL}];
            }
            return NO;
        }
    }
    
    if (![[[appURL lastPathComponent] stringByDeletingPathExtension] isEqualToString:preferredAppName]) {
        if (outError) {
            *outError = [NSError errorWithDomain:CEErrorDomain
                                            code:CEApplicationNameIsModifiedError
                                        userInfo:@{NSLocalizedDescriptionKey: NSLocalizedString(@"The name of the running CotEditor is modified.", nil),
                                                   NSLocalizedRecoverySuggestionErrorKey: [NSString stringWithFormat:NSLocalizedString(@"Do you really want to install the command-line tool for “%@”?\n\nThe command will be invalid if CotEditor is renamed.", nil),
                                                                                           [appURL lastPathComponent]],
                                                   NSLocalizedRecoveryOptionsErrorKey: @[NSLocalizedString(@"Install", nil),
                                                                                         NSLocalizedString(@"Cancel", nil)],
                                                   NSRecoveryAttempterErrorKey: self,
                                                   NSURLErrorKey: appURL}];
        }
        return NO;
    }
    
    return YES;
}


//------------------------------------------------------
/// return running system version as NSString
NSString *systemVersion()
//------------------------------------------------------
{
    NSDictionary<NSString *, id> * systemVersion = [NSDictionary dictionaryWithContentsOfFile:@"/System/Library/CoreServices/SystemVersion.plist"];
    return [systemVersion objectForKey:@"ProductVersion"];
}

@end
