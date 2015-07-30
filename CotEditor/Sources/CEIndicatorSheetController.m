/*
 ==============================================================================
 CEIndicatorSheetController
 
 CotEditor
 http://coteditor.com
 
 Created on 2014-06-07 by 1024jp
 encoding="UTF-8"
 ------------------------------------------------------------------------------
 
 © 2014-2015 1024jp
 
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

#import "CEIndicatorSheetController.h"


@interface CEIndicatorSheetController ()

@property (nonatomic, weak) IBOutlet NSProgressIndicator *indicator;

@property (nonatomic, nonnull, copy) NSString *message;
@property NSModalSession modalSession;

// readonly
@property (readwrite, nonatomic, getter=isCancelled) BOOL cancelled;

@end




#pragma mark -

@implementation CEIndicatorSheetController

#pragma mark Superclass Methods

// ------------------------------------------------------
/// initialize
- (nonnull instancetype)initWithMessage:(nonnull NSString *)message
// ------------------------------------------------------
{
    self = [super initWithWindowNibName:@"Indicator"];
    if (self) {
        _message = message;
        _informativeText = NSLocalizedString(@"Please wait for a while.", nil);
    }
    return self;
}


// ------------------------------------------------------
/// setup UI
- (void)windowDidLoad
// ------------------------------------------------------
{
    [super windowDidLoad];
    
    // init indicator
    [[self indicator] setIndeterminate:NO];
    [[self indicator] setDoubleValue:0];
    [[self indicator] setUsesThreadedAnimation:YES];
}



#pragma mark Public Methods

// ------------------------------------------------------
/// show as sheet
- (void)beginSheetForWindow:(nonnull NSWindow *)window
// ------------------------------------------------------
{
    if (NSAppKitVersionNumber >= NSAppKitVersionNumber10_9) { // on Mavericks or later
        [window beginSheet:[self window] completionHandler:nil];
        
    } else {
        [NSApp beginSheet:[self window] modalForWindow:window
            modalDelegate:self didEndSelector:NULL contextInfo:NULL];
        [self setModalSession:[NSApp beginModalSessionForWindow:[self window]]];
    }
}


// ------------------------------------------------------
/// end sheet
- (void)endSheet
// ------------------------------------------------------
{
    if (NSAppKitVersionNumber >= NSAppKitVersionNumber10_9) { // on Mavericks or later
        [[[self window] parentWindow] endSheet:[self window] returnCode:NSModalResponseCancel];
        
    } else {
        [NSApp abortModal];
        [NSApp endModalSession:[self modalSession]];
        [self setModalSession:nil];
        [NSApp endSheet:[self window]];
    }
    
    [[self window] close];
}


// ------------------------------------------------------
/// increase indicator
- (void)progressIndicator:(CGFloat)delta
// ------------------------------------------------------
{
    // set always on main thread
    NSProgressIndicator *indicator = [self indicator];
    dispatch_async(dispatch_get_main_queue(), ^{
        [indicator incrementBy:(double)delta];
    });
}



#pragma mark Action Messages

// ------------------------------------------------------
/// cancel current coloring
- (IBAction)cancelColoring:(nullable id)sender
// ------------------------------------------------------
{
    [self setCancelled:YES];
}

@end
