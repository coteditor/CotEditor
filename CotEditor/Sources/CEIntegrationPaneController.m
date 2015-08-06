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


static NSString *const kSymbolicLinkPath = @"/usr/local/bin/cot";


@interface CEIntegrationPaneController ()

@property (nonatomic, nonnull) NSURL *linkURL;
@property (nonatomic, nonnull) NSURL *executableURL;
@property (nonatomic, getter=isUninstallable) BOOL uninstallable;
@property (nonatomic, getter=isInstalled) BOOL installed;
@property (nonatomic, nullable, copy) NSString *warning;

@property (nonatomic, nullable, weak) IBOutlet NSButton *installButton;

@end




#pragma mark -

@implementation CEIntegrationPaneController

static const NSURL *kPreferredLinkTargetURL;


#pragma mark Superclass Methods

// ------------------------------------------------------
/// initialize class
+ (void)initialize
// ------------------------------------------------------
{
    NSString *appName = [[NSBundle mainBundle] objectForInfoDictionaryKey:@"CFBundleName"];
    NSURL *applicationDirURL = [[NSFileManager defaultManager] URLForDirectory:NSApplicationDirectory
                                                                      inDomain:NSLocalDomainMask
                                                             appropriateForURL:nil
                                                                        create:NO
                                                                         error:nil];
    kPreferredLinkTargetURL = [[[applicationDirURL URLByAppendingPathComponent:appName] URLByAppendingPathExtension:@"app"]
                               URLByAppendingPathComponent:@"Contents/MacOS/cot"];
}


// ------------------------------------------------------
/// initialize instance
- (nullable instancetype)initWithNibName:(nullable NSString *)nibNameOrNil bundle:(nullable NSBundle *)nibBundleOrNil
// ------------------------------------------------------
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        _linkURL = [NSURL fileURLWithPath:kSymbolicLinkPath];
        _executableURL = [[NSBundle mainBundle] URLForAuxiliaryExecutable:@"cot"];
        _uninstallable = YES;
        
        _installed = [self validateSymlink];
    }
    return self;
}


// ------------------------------------------------------
/// setup UI
- (void)loadView
// ------------------------------------------------------
{
    [super loadView];
    
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
    
    if ([[error domain] isEqualToString:CEErrorDomain]) {
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
    [self performUninstall];
}



#pragma mark Private Methods

// ------------------------------------------------------
/// create symlink to `cot` executable in bundle
- (void)performInstall
// ------------------------------------------------------
{
    __block BOOL success = NO;
    __block NSError *error = nil;
    
    NSFileCoordinator *coordinator = [[NSFileCoordinator alloc] init];
    [coordinator coordinateWritingItemAtURL:[self linkURL] options:0
                                      error:&error
                                 byAccessor:^(NSURL *newURL)
     {
         success = [[NSFileManager defaultManager] createSymbolicLinkAtURL:newURL
                                                        withDestinationURL:[self executableURL]
                                                                     error:&error];
     }];
    
    if (success) {
        [self setInstalled:YES];
        [self toggleInstallButtonState:YES];
        
    } else if (error) {
        [[self view] presentError:error modalForWindow:[[self view] window]
                         delegate:nil didPresentSelector:NULL contextInfo:NULL];
    }
}


// ------------------------------------------------------
/// unlink symlink at "/usr/local/bin/cot"
- (void)performUninstall
// ------------------------------------------------------
{
    BOOL success;
    NSError *error = nil;
    
    unlink([[[self linkURL] path] fileSystemRepresentation]);
    
    if (![[self linkURL] checkResourceIsReachableAndReturnError:nil]) {
        [self setInstalled:NO];
        [self toggleInstallButtonState:NO];
    }
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
    
    // not installed yet (= can install)
    if (![[self linkURL] checkResourceIsReachableAndReturnError:nil]) {
        return NO;
    }
    
    NSURL *linkDestinationURL = [[self linkURL] URLByResolvingSymlinksInPath];
    
    if ([linkDestinationURL isEqual:[self linkURL]]) {
        [self setUninstallable:NO];  // treat as "installed"
        return YES;
    }
    
    if ([linkDestinationURL isEqual:[[self executableURL] URLByStandardizingPath]] ||
        [linkDestinationURL isEqual:kPreferredLinkTargetURL])  // link to '/Applications/CotEditor.app' is always valid
    {
        // totaly valid link
        return YES;
    }
    
    // display warning for invalid link
    if ([linkDestinationURL checkResourceIsReachableAndReturnError:nil]) {
        // link destinaiton is not running CotEditor
        [self setWarning:NSLocalizedString(@"The current 'cot' symbolic link doesn't target on the running CotEditor.", nil)];
    } else {
        // link destination is unreachable
        [self setWarning:NSLocalizedString(@"The current 'cot' symbolic link may target on an invalid path.", nil)];
    }
    
    return YES;
}


// ------------------------------------------------------
/// check whether current running CotEditor is located in the /Application directory
- (BOOL)checkApplicationLocationAndReturnError:(NSError *__autoreleasing __nullable *)outError
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
                NSDictionary *userInfo = @{NSLocalizedDescriptionKey: NSLocalizedString(@"The running CotEditor is not located in the Application directory.", nil),
                                           NSLocalizedRecoverySuggestionErrorKey: [NSString stringWithFormat:NSLocalizedString(@"Do you really want to install the command-line tool for CotEditor at “%@”?\n\nWe recommend to move CotEditor.app to the Application directory at first.", nil),
                                                                                   [[[NSBundle mainBundle] bundleURL] path]],
                                           NSLocalizedRecoveryOptionsErrorKey: @[NSLocalizedString(@"Install", nil),
                                                                                 NSLocalizedString(@"Cancel", nil)],
                                           NSRecoveryAttempterErrorKey: self,
                                           NSURLErrorKey: appURL};
                
                *outError = [NSError errorWithDomain:CEErrorDomain code:CEApplicationNotInApplicationDirectoryError userInfo:userInfo];
            }
            return NO;
        }
    }
    
    if (![[[appURL lastPathComponent] stringByDeletingPathExtension] isEqualToString:preferredAppName]) {
        if (outError) {
            NSDictionary *userInfo = @{NSLocalizedDescriptionKey: NSLocalizedString(@"The name of the running CotEditor is modified.", nil),
                                       NSLocalizedRecoverySuggestionErrorKey: [NSString stringWithFormat:NSLocalizedString(@"Do you really want to install the command-line tool for “%@”?", nil),
                                                                               [appURL lastPathComponent]],
                                       NSLocalizedRecoveryOptionsErrorKey: @[NSLocalizedString(@"Install", nil),
                                                                             NSLocalizedString(@"Cancel", nil)],
                                       NSRecoveryAttempterErrorKey: self,
                                       NSURLErrorKey: appURL};
            
            *outError = [NSError errorWithDomain:CEErrorDomain code:CEApplicationNameIsModifiedError userInfo:userInfo];
        }
        return NO;
    }
    
    return YES;
}

@end
