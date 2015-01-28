/*
 ==============================================================================
 CEMigrationWindowController
 
 CotEditor
 http://coteditor.com
 
 Created on 2014-10-09 by 1024jp
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

#import "CEMigrationWindowController.h"
#import "CEAppDelegate.h"


@interface CEMigrationWindowController ()

@property (nonatomic) NSString *appName;

@property (nonatomic) IBOutlet NSView *finishedView;
@property (nonatomic) IBOutlet NSView *initialView;

@property (nonatomic, weak) IBOutlet NSView *slideView;
@property (nonatomic, weak) IBOutlet NSProgressIndicator *indicator;
@property (nonatomic, weak) IBOutlet NSTextField *informativeField;
@property (nonatomic, weak) IBOutlet NSButton *button;

@end




#pragma mark -

@implementation CEMigrationWindowController

// ------------------------------------------------------
/// init with fixed nib
- (instancetype)init
// ------------------------------------------------------
{
    self = [super initWithWindowNibName:@"MigrationWindow"];
    if (self) {
        NSString *appName = [[NSBundle mainBundle] objectForInfoDictionaryKey:@"CFBundleName"];
        NSString *appVersion = [[NSBundle mainBundle] objectForInfoDictionaryKey:@"CFBundleShortVersionString"];
        
        _appName = [NSString stringWithFormat:@"%@ %@", appName, appVersion];
    }
    return self;
}

// ------------------------------------------------------
/// initialize window
- (void)windowDidLoad
// ------------------------------------------------------
{
    [super windowDidLoad];
    
    [[self window] setLevel:NSFloatingWindowLevel];
    
    // set background color
    [[[self slideView] layer] setBackgroundColor:[[NSColor whiteColor] CGColor]];
    
    // init indicator
    [[self indicator] setMaxValue:5];
    [[self indicator] setUsesThreadedAnimation:YES];
    
    [[self indicator] startAnimation:self];
}



#pragma mark Public Methods

// ------------------------------------------------------
/// progress indicator
- (void)progressIndicator
// ------------------------------------------------------
{
    [[self indicator] setDoubleValue:[[self indicator] doubleValue] + 1];
    [[self indicator] displayIfNeeded];
}


// ------------------------------------------------------
/// update progress message
- (void)setInformative:(NSString *)informative
// ------------------------------------------------------
{
    [[self informativeField] setStringValue:NSLocalizedString(informative, nil)];
}


// ------------------------------------------------------
/// trigger migration finish.
- (void)setMigrationFinished:(BOOL)migrationFinished
// ------------------------------------------------------
{
    [[self button] setHidden:NO];
    
    [[self indicator] setDoubleValue:[[self indicator] maxValue]];
    [[self indicator] stopAnimation:self];
}



#pragma mark Action Messages

// ------------------------------------------------------
/// transit to finished mode
- (IBAction)didFinishMigration:(id)sender
// ------------------------------------------------------
{
    [self swapView:[self finishedView]];
    
    // change button
    [[self button] setTarget:[self window]];
    [[self button] setAction:@selector(orderOut:)];
    [[self button] setTitle:NSLocalizedString(@"Close", nil)];
}

// ------------------------------------------------------
/// open a specific help page with anchor
- (IBAction)openHelpAnchor:(id)sender
// ------------------------------------------------------
{
    [(CEAppDelegate *)[NSApp delegate] openHelpAnchor:sender];
}



#pragma mark Private Methods

// ------------------------------------------------------
/// swap current slide view with another view
- (void)swapView:(NSView *)newView
// ------------------------------------------------------
{
    NSView *currentView = [[[self slideView] subviews] firstObject];
    
    [[[self slideView] animator] replaceSubview:currentView with:newView];
}

@end
