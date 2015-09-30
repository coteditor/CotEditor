/*
 
 CEUpdaterManager.m
 
 CotEditor
 http://coteditor.com
 
 Created by 1024jp on 2015-05-01.

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

@import Sparkle;
#import "CEUpdaterManager.h"
#import "Constants.h"


// constants
static NSString *_Nonnull const AppCastURL = @"http://coteditor.com/appcast.xml";
static NSString *_Nonnull const AppCastBetaURL = @"http://coteditor.com/appcast-beta.xml";


@interface CEUpdaterManager () <SUUpdaterDelegate>

@end




#pragma mark -

@implementation CEUpdaterManager

#pragma mark Singleton

// ------------------------------------------------------
/// return singleton instance
+ (nonnull instancetype)sharedManager
// ------------------------------------------------------
{
    static dispatch_once_t onceToken;
    static id shared = nil;
    
    dispatch_once(&onceToken, ^{
        shared = [[self alloc] init];
    });
    
    return shared;
}



#pragma mark Public Methods

// ------------------------------------------------------
/// setup Sparkle
- (void)setup
// ------------------------------------------------------
{
    SUUpdater *updater = [SUUpdater sharedUpdater];
    
    // set delegate
    [updater setDelegate:self];
    
    // insert "Check for Updates…" menu item
    NSMenuItem *menuItem = [[NSMenuItem alloc] initWithTitle:NSLocalizedString(@"Check for Updates…", nil)
                                                      action:@selector(checkForUpdates:)
                                               keyEquivalent:@""];
    [menuItem setTarget:updater];
    NSMenu *applicationMenu = [[[NSApp mainMenu] itemAtIndex:CEApplicationMenuIndex] submenu];
    [applicationMenu insertItem:menuItem atIndex:1];
    
    // lock update check interval to daily
    [updater setUpdateCheckInterval:60 * 60 * 24];
}


// ------------------------------------------------------
/// Is the running app a pre-release version?
- (BOOL)isPrerelease
// ------------------------------------------------------
{
    NSString *version = [[NSBundle mainBundle] objectForInfoDictionaryKey:@"CFBundleShortVersionString"];
    NSCharacterSet *digitSet = [NSCharacterSet characterSetWithCharactersInString:@"0123456789."];
    
    // pre-releases contain non-digit letter
    return [version rangeOfCharacterFromSet:[digitSet invertedSet]].location != NSNotFound;
}



#pragma mark Delegate

//=======================================================
// SUUpdaterDelegate
//=======================================================

// ------------------------------------------------------
/// return AppCast file URL dinamically
- (NSString *)feedURLStringForUpdater:(SUUpdater *)updater
// ------------------------------------------------------
{
    // force beta check if the current runnning one is a beta.
    BOOL checksBeta;
    if ([self isPrerelease]) {
        checksBeta = YES;
    } else {
        checksBeta = [[NSUserDefaults standardUserDefaults] boolForKey:CEDefaultChecksUpdatesForBetaKey];
        
    }
    return checksBeta ? AppCastBetaURL : AppCastURL;
}

@end
