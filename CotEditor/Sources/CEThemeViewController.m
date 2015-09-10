/*
 
 CEThemeViewController.m
 
 CotEditor
 http://coteditor.com
 
 Created by 1024jp on 2014-09-12.

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

#import "CEThemeViewController.h"
#import "CEThemeManager.h"
#import "NSColor+WFColorCode.h"
#import "Constants.h"


@interface CEThemeViewController () <NSPopoverDelegate, NSTextFieldDelegate>

@property (nonatomic, getter=isMetadataEdited) BOOL metadataEdited;

@property (nonatomic, nullable) IBOutlet NSPopover *popover;

@end




#pragma mark -

@implementation CEThemeViewController

#pragma mark Superclass methods

// ------------------------------------------------------
/// initialize instance
- (instancetype)init
// ------------------------------------------------------
{
    return [super initWithNibName:@"ThemeView" bundle:nil];
}


// ------------------------------------------------------
/// clean up (end theme change observation)
- (void)dealloc
// ------------------------------------------------------
{
    [[self popover] setDelegate:nil];  // avoid crash (2014-12-31)
    [self endObservingTheme];
}


// ------------------------------------------------------
/// observe theme dict changes
- (void)setRepresentedObject:(nullable id)representedObject
// ------------------------------------------------------
{
    // remove current observing (in case when the theme is restored)
    [self endObservingTheme];
    
    // observe input theme
    NSDictionary<NSString *, NSMutableDictionary<NSString *, id> *> *theme = representedObject;
    [self observeTheme:theme];
    
    [super setRepresentedObject:theme];
}



#pragma mark Protocol

//=======================================================
// NSKeyValueObserving Protocol
//=======================================================

// ------------------------------------------------------
/// theme is modified
- (void)observeValueForKeyPath:(nullable NSString *)keyPath ofObject:(nullable id)object change:(nullable NSDictionary<NSString *, id> *)change context:(nullable void *)context
// ------------------------------------------------------
{
    if (object == [self representedObject]) {
        [[self delegate] didUpdateTheme:object];
    }
}



#pragma mark Delegate

// ------------------------------------------------------
/// meta data was possible edited
- (void)controlTextDidChange:(nonnull NSNotification *)obj
// ------------------------------------------------------
{
    [self setMetadataEdited:YES];
}


// ------------------------------------------------------
/// popover closed
- (void)popoverDidClose:(nonnull NSNotification *)notification
// ------------------------------------------------------
{
    if ([self isMetadataEdited]) {
        [[self delegate] didUpdateTheme:[self representedObject]];
        [self setMetadataEdited:NO];
    }
}



#pragma mark Action Messages

// ------------------------------------------------------
/// apply system highlight color to color well
- (IBAction)applySystemSelectionColor:(nullable id)sender
// ------------------------------------------------------
{
    if ([sender state] == NSOnState) {
        NSColor *color = [NSColor selectedTextBackgroundColor];
        [self representedObject][CEThemeSelectionKey][CEThemeColorKey] = [[color colorUsingColorSpaceName:NSCalibratedRGBColorSpace] colorCodeWithType:WFColorCodeHex];
    }
}


// ------------------------------------------------------
/// show medatada of theme file via popover
- (IBAction)showMedatada:(nullable id)sender
// ------------------------------------------------------
{
    [[self popover] showRelativeToRect:[sender frame] ofView:[self view] preferredEdge:NSMaxYEdge];
    [[sender window] makeFirstResponder:[sender window]];
}


// ------------------------------------------------------
/// jump to theme's destribution URL
- (IBAction)jumpToURL:(nullable id)sender
// ------------------------------------------------------
{
    NSURL *URL = [NSURL URLWithString:[self representedObject][CEMetadataKey][CEDistributionURLKey]];
    
    if (!URL) {
        NSBeep();
        return;
    }
    
    [[NSWorkspace sharedWorkspace] openURL:URL];
}



#pragma mark Private Methods

// ------------------------------------------------------
/// start observing theme change
- (void)observeTheme:(nonnull NSDictionary<NSString *, NSMutableDictionary<NSString *, id> *> *)theme
// ------------------------------------------------------
{
    for (NSString *key in [theme allKeys]) {
        if ([key isEqualToString:CEMetadataKey]) { continue; }
        
        for (NSString *subKey in [theme[key] allKeys]) {
            NSString *keyPath = [NSString stringWithFormat:@"%@.%@", key, subKey];
            
            [theme addObserver:self forKeyPath:keyPath options:0 context:NULL];
        }
    }
}


// ------------------------------------------------------
/// end observing current theme
- (void)endObservingTheme
// ------------------------------------------------------
{
    NSDictionary<NSString *, NSMutableDictionary<NSString *, id> *> *theme = [self representedObject];
    
    if (!theme) { return; }
    
    for (NSString *key in [theme allKeys]) {
        if ([key isEqualToString:CEMetadataKey]) { continue; }
        
        for (NSString *subKey in [theme[key] allKeys]) {
            NSString *keyPath = [NSString stringWithFormat:@"%@.%@", key, subKey];
            
            [theme removeObserver:self forKeyPath:keyPath];
        }
    }
}

@end
