/*
 
 CEGeneralPaneController.m
 
 CotEditor
 http://coteditor.com
 
 Created by 1024jp on 2015-07-15.

 ------------------------------------------------------------------------------
 
 © 2015 1024jp
 
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

#import "CEGeneralPaneController.h"
#import "CEDocument.h"
#import "Constants.h"

#ifndef APPSTORE
#import "CEUpdaterManager.h"
#endif


@interface CEGeneralPaneController ()

@property (nonatomic) BOOL hasUpdater;
@property (nonatomic, getter=isPrerelease) BOOL prerelease;
@property (nonatomic, weak) IBOutlet NSLayoutConstraint *updaterConstraint;

@end




#pragma mark -

@implementation CEGeneralPaneController

#pragma mark View Controller Methods

// ------------------------------------------------------
/// setup UI
- (void)awakeFromNib
// ------------------------------------------------------
{
    [super awakeFromNib];
    
    // remove updater option on AppStore ver.
#ifdef APPSTORE
    // cut down height for updater checkbox
    NSRect frame = [[self view] frame];
    frame.size.height -= 96;
    [[self view] setFrame:frame];
    
    // cut down x-position of visible labels
    [[self view] removeConstraint:[self updaterConstraint]];
#else
    [self setHasUpdater:YES];
    
    if ([[CEUpdaterManager sharedManager] isPrerelease]) {
        [self setPrerelease:YES];
    } else {
        // cut down height for pre-release note
        NSRect frame = [[self view] frame];
        frame.size.height -= 32;
        [[self view] setFrame:frame];
    }
#endif
}



#pragma mark Action Messages

// ------------------------------------------------------
/// "Enable Auto Save and Versions" checkbox was clicked
- (IBAction)updateAutosaveSetting:(nullable id)sender
// ------------------------------------------------------
{
    BOOL currentSetting = [CEDocument autosavesInPlace];
    BOOL newSetting = [[NSUserDefaults standardUserDefaults] boolForKey:CEDefaultEnablesAutosaveInPlaceKey];
    
    // do nothing if the setting returned to the current one.
    if (currentSetting == newSetting) { return; }
    
    NSAlert *alert = [[NSAlert alloc] init];
    [alert setMessageText:NSLocalizedString(@"The change will be applied first at the next launch.", nil)];
    [alert setInformativeText:NSLocalizedString(@"Do you want to restart CotEditor now?", nil)];
    [alert addButtonWithTitle:NSLocalizedString(@"Restart Now", nil)];
    [alert addButtonWithTitle:NSLocalizedString(@"Later", nil)];
    
    [alert beginSheetModalForWindow:[[self view] window]
                      modalDelegate:self
                     didEndSelector:@selector(autosaveSettingAlertDidEnd:returnCode:contextInfo:)
                        contextInfo:NULL];
}



#pragma mark Private Methods

// ------------------------------------------------------
/// autosaving alart did end
- (void)autosaveSettingAlertDidEnd:(nonnull NSAlert *)alert returnCode:(NSInteger)returnCode contextInfo:(nullable void *)contextInfo
// ------------------------------------------------------
{
    if (returnCode == NSAlertFirstButtonReturn) {  // Restart Now
        [self relaunchApplication];
    }
}


// ------------------------------------------------------
/// relaunch application itself with delay
- (void)relaunchApplication
// ------------------------------------------------------
{
    static const float delay = 3.0;  // in seconds
    
    NSTask *task = [[NSTask alloc] init];
    NSString *command = [NSString stringWithFormat:@"sleep %f; open \"%@\"", delay, [[NSBundle mainBundle] bundlePath]];
    [task setLaunchPath:@"/bin/sh"];
    [task setArguments:@[@"-c", command]];
    [task launch];
    
    [NSApp terminate:self];
}

@end
