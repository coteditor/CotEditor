/*
 ==============================================================================
 CEThemeViewController
 
 CotEditor
 http://coteditor.github.io
 
 Created on 2014-09-12 by 1024jp
 encoding="UTF-8"
 ------------------------------------------------------------------------------
 
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

#import "CEThemeViewController.h"
#import "CEThemeManager.h"
#import "NSColor+WFColorCode.h"
#import "constants.h"


@interface CEThemeViewController () <NSTextFieldDelegate>

@property (nonatomic) IBOutlet NSPopover *popover;

@end




#pragma mark -

@implementation CEThemeViewController

#pragma mark Superclass methods

// ------------------------------------------------------
/// init
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
    NSDictionary *theme = [self representedObject];
    
    for (NSString *key in [theme allKeys]) {
        [theme removeObserver:self forKeyPath:key];
    }
}


// ------------------------------------------------------
/// observe theme dict changes
- (void)setRepresentedObject:(id)representedObject
// ------------------------------------------------------
{
    // remove current observing (in case when the theme is restored)
    if ([self representedObject]) {
        NSDictionary *currentTheme = [self representedObject];
        for (NSString *key in [currentTheme allKeys]) {
            [currentTheme removeObserver:self forKeyPath:key];
        }
    }
    
    // observe input theme
    NSDictionary *theme = representedObject;
    for (NSString *key in [theme allKeys]) {
        [theme addObserver:self forKeyPath:key options:0 context:NULL];
    }
    
    [super setRepresentedObject:theme];
}


// ------------------------------------------------------
/// theme is modified
- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context
// ------------------------------------------------------
{
    if (object == [self representedObject]) {
        [[self delegate] didUpdateTheme:object];
    }
}



#pragma mark Delegate

// ------------------------------------------------------
/// meta data was possible edited
- (BOOL)control:(NSControl *)control textShouldEndEditing:(NSText *)fieldEditor
// ------------------------------------------------------
{
    [[self delegate] didUpdateTheme:[self representedObject]];
    
    return YES;
}



#pragma mark Action Messages

// ------------------------------------------------------
/// apply system highlight color to color well
- (IBAction)applySystemSelectionColor:(id)sender
// ------------------------------------------------------
{
    if ([sender state] == NSOnState) {
        NSColor *color = [NSColor selectedTextBackgroundColor];
        [self representedObject][CEThemeSelectionColorKey] = [[color colorUsingColorSpaceName:NSCalibratedRGBColorSpace] colorCodeWithType:WFColorCodeHex];
    }
}


// ------------------------------------------------------
/// show medatada of theme file via popover
- (IBAction)showMedatada:(id)sender
// ------------------------------------------------------
{
    [[self popover] showRelativeToRect:[sender frame] ofView:[self view] preferredEdge:NSMaxYEdge];
    [[sender window] makeFirstResponder:[sender window]];
}


// ------------------------------------------------------
/// jump to theme's destribution URL
- (IBAction)jumpToURL:(id)sender
// ------------------------------------------------------
{
    NSURL *URL = [NSURL URLWithString:[self representedObject][@"metadata"][@"distributionURL"]];
    
    if (!URL) {
        NSBeep();
        return;
    }
    
    [[NSWorkspace sharedWorkspace] openURL:URL];
}

@end
