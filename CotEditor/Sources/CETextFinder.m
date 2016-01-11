/*
 
 CETextFinder.m
 
 CotEditor
 http://coteditor.com
 
 Created by 1024jp on 2015-01-03.

 ------------------------------------------------------------------------------
 
 © 2015-2016 1024jp
 
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
#import "CETextFinder.h"
#import "CEFindPanelController.h"
#import "CEDefaults.h"


NSString * _Nonnull const kEscapeCharacter = @"\\";


@interface CETextFinder ()

@property (nonatomic, nonnull) CEFindPanelController *findPanelController;

@end


@implementation CETextFinder

#pragma mark Singleton

static CETextFinder	*singleton = nil;

// ------------------------------------------------------
/// return singleton instance
+ (nonnull CETextFinder *)sharedTextFinder
// ------------------------------------------------------
{
    if (!singleton) {
        singleton = [[self alloc] init];
    }
    
    return singleton;
}



#pragma mark Sueprclass Methods

// ------------------------------------------------------
/// register default setting for find panel
+ (void)initialize
// ------------------------------------------------------
{
    [super initialize];
    
    // register defaults for find panel here
    // sicne CEFindPanelController can be initialized before registering user defaults in CEAppDelegate. (2015-01 by 1024jp)
    NSDictionary<NSString *, id> *defaults = @{CEDefaultFindHistoryKey: @[],
                                               CEDefaultReplaceHistoryKey: @[],
                                               CEDefaultFindRegexSyntaxKey: @([OGRegularExpression defaultSyntax]),
                                               CEDefaultFindOptionsKey: @(OgreCaptureGroupOption),
                                               CEDefaultFindUsesRegularExpressionKey: @NO,
                                               CEDefaultFindInSelectionKey: @NO,
                                               CEDefaultFindIsWrapKey: @YES,
                                               CEDefaultFindNextAfterReplaceKey: @YES,
                                               CEDefaultFindClosesIndicatorWhenDoneKey: @YES,
                                               };
    
    [[NSUserDefaults standardUserDefaults] registerDefaults:defaults];
}


// ------------------------------------------------------
/// initialize instance
- (instancetype)init
// ------------------------------------------------------
{
    if (singleton) {
        return singleton;
    }
    
    self = [super init];
    if (self) {
        _findString = @"";
        _replacementString = @"";
        _findPanelController = [[CEFindPanelController alloc] init];
        
        // add to responder chain
        [NSApp setNextResponder:self];
        
        // observe application activation to sync find string with other apps
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(applicationDidBecomeActive:)
                                                     name:NSApplicationDidBecomeActiveNotification
                                                   object:nil];
        
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(applicationWillResignActive:)
                                                     name:NSApplicationWillResignActiveNotification
                                                   object:nil];
        
        // make singleton
        singleton = self;
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
/// validate menu item
- (BOOL)validateMenuItem:(nonnull NSMenuItem *)menuItem
// ------------------------------------------------------
{
    SEL action = [menuItem action];
    
    if (action == @selector(findNext:) ||
        action == @selector(findPrevious:) ||
        action == @selector(findSelectedText:) ||
        action == @selector(findAll:) ||
        action == @selector(replace:) ||
        action == @selector(replaceAndFind:) ||
        action == @selector(replaceAll:))
    {
        return ([self client] != nil);
        
    } else if (action == @selector(useSelectionForFind:) ||
               action == @selector(useSelectionForReplace:))
    {
        return ([self selectedString] != nil);
    }
    
    return YES;
}



#pragma mark Notification

// ------------------------------------------------------
/// sync search string on activating application
- (void)applicationDidBecomeActive:(nonnull NSNotification *)notification
// ------------------------------------------------------
{
    if ([[NSUserDefaults standardUserDefaults] boolForKey:CEDefaultSyncFindPboardKey]) {
        NSString *sharedFindString = [self findStringFromPasteboard];
        if (sharedFindString) {
            [self setFindString:sharedFindString];
        }
    }
}


// ------------------------------------------------------
/// sync search string on activating application
- (void)applicationWillResignActive:(nonnull NSNotification *)notification
// ------------------------------------------------------
{
    if ([[NSUserDefaults standardUserDefaults] boolForKey:CEDefaultSyncFindPboardKey]) {
        [self setFindStringToPasteboard:[self findString]];
    }
}



#pragma mark Public Methods

// ------------------------------------------------------
/// target text view
- (nullable NSTextView *)client
// ------------------------------------------------------
{
    id<CETextFinderClientProvider> provider = [NSApp targetForAction:@selector(focusedTextView)];
    if (provider) {
        return [provider focusedTextView];
    }
    
    return nil;
}

// ------------------------------------------------------
/// selected string in the current tareget
- (nullable NSString *)selectedString
// ------------------------------------------------------
{
    NSRange selectedRange = [[self client] selectedRange];
    
    if (selectedRange.length == 0) { return nil; }
    
    return [[[self client] string] substringWithRange:selectedRange];
}



#pragma mark Action Messages

// ------------------------------------------------------
/// activate find panel
- (IBAction)showFindPanel:(nullable id)sender
// ------------------------------------------------------
{
    [[self findPanelController] showWindow:sender];
}


// ------------------------------------------------------
/// find next matched string
- (IBAction)findNext:(nullable id)sender
// ------------------------------------------------------
{
    [[self findPanelController] findNext:sender];
}


// ------------------------------------------------------
/// find previous matched string
- (IBAction)findPrevious:(nullable id)sender
// ------------------------------------------------------
{
    [[self findPanelController] findPrevious:sender];
}


// ------------------------------------------------------
/// perform find action with the selected string
- (IBAction)findSelectedText:(nullable id)sender
// ------------------------------------------------------
{
    [self useSelectionForFind:sender];
    [self findNext:sender];
}


// ------------------------------------------------------
/// find all matched string in the target and show results in a table
- (IBAction)findAll:(nullable id)sender
// ------------------------------------------------------
{
    [[self findPanelController] findAll:sender];
}


// ------------------------------------------------------
/// replace next matched string with given string
- (IBAction)replace:(nullable id)sender
// ------------------------------------------------------
{
    [[self findPanelController] replace:sender];
}


// ------------------------------------------------------
/// replace all matched strings with given string
- (IBAction)replaceAll:(nullable id)sender
// ------------------------------------------------------
{
    [[self findPanelController] replaceAll:sender];
}


// ------------------------------------------------------
/// replace next matched string with given string and select the one after the next match
- (IBAction)replaceAndFind:(nullable id)sender
// ------------------------------------------------------
{
    [[self findPanelController] replaceAndFind:sender];
}


// ------------------------------------------------------
/// set selected string to find field
- (IBAction)useSelectionForFind:(nullable id)sender
// ------------------------------------------------------
{
    NSString *selectedString = [self selectedString];
    
    if (selectedString) {
        [self setFindString:selectedString];
    } else {
        NSBeep();
    }
}


// ------------------------------------------------------
/// set selected string to replace field
- (IBAction)useSelectionForReplace:(nullable id)sender
// ------------------------------------------------------
{
    NSString *selectedString = [self selectedString];
    
    if (selectedString) {
        [self setReplacementString:selectedString];
    } else {
        NSBeep();
    }
}



#pragma mark Private Methods

// ------------------------------------------------------
/// load find string from global domain
- (nullable NSString *)findStringFromPasteboard
// ------------------------------------------------------
{
    NSPasteboard *pasteboard = [NSPasteboard pasteboardWithName:NSFindPboard];
    
    return [pasteboard stringForType:NSStringPboardType];
}


// ------------------------------------------------------
/// put local find string to global domain
- (void)setFindStringToPasteboard:(nonnull NSString *)string
// ------------------------------------------------------
{
    if ([string length] == 0) { return; }
    
    NSPasteboard *pasteboard = [NSPasteboard pasteboardWithName:NSFindPboard];
    
    [pasteboard declareTypes:@[NSStringPboardType] owner:nil];
    [pasteboard setString:string forType:NSStringPboardType];
}

@end
