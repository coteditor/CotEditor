/*
 
 CEMigrationWindowController.m
 
 CotEditor
 http://coteditor.com
 
 Created by 1024jp on 2014-10-09.

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

#import "CEMigrationWindowController.h"
#import "CEAppDelegate.h"


@interface CEMigrationWindowController ()

@property (nonatomic, nonnull, copy) NSString *appName;

@property (nonatomic, nullable) IBOutlet NSView *finishedView;
@property (nonatomic, nullable) IBOutlet NSView *initialView;

@property (nonatomic, nullable, weak) IBOutlet NSView *slideView;
@property (nonatomic, nullable, weak) IBOutlet NSProgressIndicator *indicator;
@property (nonatomic, nullable, weak) IBOutlet NSTextField *informativeField;
@property (nonatomic, nullable, weak) IBOutlet NSButton *button;

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
- (void)setInformative:(nonnull NSString *)informative
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
- (IBAction)didFinishMigration:(nullable id)sender
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
- (IBAction)openHelpAnchor:(nullable id)sender
// ------------------------------------------------------
{
    [(CEAppDelegate *)[NSApp delegate] openHelpAnchor:sender];
}



#pragma mark Private Methods

// ------------------------------------------------------
/// swap current slide view with another view
- (void)swapView:(nonnull NSView *)newView
// ------------------------------------------------------
{
    NSView *currentView = [[[self slideView] subviews] firstObject];
    
    [[[self slideView] animator] replaceSubview:currentView with:newView];
}

@end
