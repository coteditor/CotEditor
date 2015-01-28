/*
 ==============================================================================
 CEIntegrationPaneController
 
 CotEditor
 http://coteditor.com
 
 Created on 2014-12-20 by 1024jp
 encoding="UTF-8"
 ------------------------------------------------------------------------------
 
 © 2014 1024jp
 
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

#import "CEIntegrationPaneController.h"
#import "constants.h"


static NSString *const kSymbolicLinkPath = @"/usr/local/bin/cot";


@interface CEIntegrationPaneController ()

@property (nonatomic) NSURL *linkURL;
@property (nonatomic) NSURL *executableURL;
@property (nonatomic, getter=isUninstallable) BOOL uninstallable;
@property (nonatomic, getter=isInstalled) BOOL installed;
@property (nonatomic, copy) NSString *warning;

@property (nonatomic, weak) IBOutlet NSButton *installButton;

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
- (instancetype)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
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



#pragma mark Action Messages

// ------------------------------------------------------
/// "Install" button is clicked
- (IBAction)install:(id)sender
// ------------------------------------------------------
{
    NSError *error = nil;
    
    if (![self checkApplicationLocationAndReturnError:&error]) {
        NSAlert *alert = [NSAlert alertWithError:error];
        
        NSBeep();
        [alert beginSheetModalForWindow:[[self view] window]
                          modalDelegate:self
                         didEndSelector:@selector(installAlertDidEnd:returnCode:contextInfo:)
                            contextInfo:NULL];
        return;
    }
    
    [self performInstall];
}


// ------------------------------------------------------
///  "Uninstall" button is clicked
- (IBAction)uninstall:(id)sender
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
        NSAlert *alert = [NSAlert alertWithError:error];
        [alert beginSheetModalForWindow:[[self view] window] modalDelegate:nil didEndSelector:NULL contextInfo:NULL];
    }
}


// ------------------------------------------------------
/// unlink symlink at "/usr/local/bin/cot"
- (void)performUninstall
// ------------------------------------------------------
{
    BOOL success;
    NSError *error = nil;
    
    unlink([[[self linkURL] path] UTF8String]);
    
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
        [self setWarning:NSLocalizedString(@"The current 'cot' symbolic link doesn't target to the running CotEditor.", nil)];
    } else {
        // link destination is unreachable
        [self setWarning:NSLocalizedString(@"The current 'cot' symbolic link may target to an invalid path.", nil)];
    }
    
    return YES;
}


// ------------------------------------------------------
/// check whether current running CotEditor is located in the /Application directory
- (BOOL)checkApplicationLocationAndReturnError:(NSError **)error
// ------------------------------------------------------
{
    NSString *preferredAppName = [[NSBundle mainBundle] objectForInfoDictionaryKey:@"CFBundleName"];
    NSURL *appURL = [[NSBundle mainBundle] bundleURL];
    
    NSURLRelationship relationship;
    [[NSFileManager defaultManager] getRelationship:&relationship
                                        ofDirectory:NSApplicationDirectory
                                           inDomain:NSLocalDomainMask
                                        toItemAtURL:appURL
                                              error:nil];
    
    if (relationship != NSURLRelationshipContains) {
        if (error) {
            NSDictionary *userInfo = @{NSLocalizedDescriptionKey: NSLocalizedString(@"The running CotEditor is not located in the Application directory.", nil),
                                       NSLocalizedRecoverySuggestionErrorKey: [NSString stringWithFormat:NSLocalizedString(@"Do you really want to install the command-line tool for CotEditor at “%@”?\n\nWe recommend to move CotEditor.app to the Application directory at first.", nil),
                                                                               [[[NSBundle mainBundle] bundleURL] path]],
                                       NSLocalizedRecoveryOptionsErrorKey: @[NSLocalizedString(@"Install", nil),
                                                                             NSLocalizedString(@"Cancel", nil)],
                                       NSURLErrorKey: appURL};
            
            *error = [NSError errorWithDomain:CEErrorDomain code:CEApplicationNotInApplicationDirectoryError userInfo:userInfo];
        }
        return NO;
        
    } else if (![[[appURL lastPathComponent] stringByDeletingPathExtension] isEqualToString:preferredAppName]) {
        if (error) {
            NSDictionary *userInfo = @{NSLocalizedDescriptionKey: NSLocalizedString(@"The name of the running CotEditor is modified.", nil),
                                       NSLocalizedRecoverySuggestionErrorKey: [NSString stringWithFormat:NSLocalizedString(@"Do you really want to install the command-line tool for “%@”?", nil),
                                                                               [appURL lastPathComponent]],
                                       NSLocalizedRecoveryOptionsErrorKey: @[NSLocalizedString(@"Install", nil),
                                                                             NSLocalizedString(@"Cancel", nil)],
                                       NSURLErrorKey: appURL};
            
            *error = [NSError errorWithDomain:CEErrorDomain code:CEApplicationNameIsModifiedError userInfo:userInfo];
        }
        return NO;
    }
    
    return YES;
}


// ------------------------------------------------------
/// alert asking to install command-line tool is closed (invoked in `install:`)
- (void)installAlertDidEnd:(NSAlert *)alert returnCode:(NSInteger)returnCode contextInfo:(void *)contextInfo
// ------------------------------------------------------
{
    if (returnCode != NSAlertFirstButtonReturn) { return; }  // == Cancel

    [self performInstall];
}

@end
