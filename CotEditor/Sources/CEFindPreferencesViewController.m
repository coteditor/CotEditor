/*
 
 CEFindPreferencesViewController.m
 
 CotEditor
 http://coteditor.com
 
 Created by 1024jp on 2016-01-24.
 
 ------------------------------------------------------------------------------
 
 © 2016 1024jp
 
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

#import <OgreKit/OgreKit.h>
#import "CEFindPreferencesViewController.h"
#import "CEDefaults.h"


@implementation CEFindPreferencesViewController

#pragma mark Superclass Methods

// ------------------------------------------------------
/// nib name
- (nullable NSString *)nibName
// ------------------------------------------------------
{
    return @"FindPreferencesView";
}


// ------------------------------------------------------
/// add check mark to selectable menus
- (BOOL)validateMenuItem:(nonnull NSMenuItem *)menuItem
// ------------------------------------------------------
{
    if ([menuItem action] == @selector(changeSyntax:)) {
        OgreSyntax syntax = [[NSUserDefaults standardUserDefaults] integerForKey:CEDefaultFindRegexSyntaxKey];
        [menuItem setState:([menuItem tag] == syntax) ? NSOnState : NSOffState];
    }
    
    return YES;
}



#pragma Private Action Messages

// ------------------------------------------------------
/// change regex syntax setting via menu item
- (IBAction)changeSyntax:(nullable id)sender
// ------------------------------------------------------
{
    [[NSUserDefaults standardUserDefaults] setInteger:[sender tag] forKey:CEDefaultFindRegexSyntaxKey];
}

@end
