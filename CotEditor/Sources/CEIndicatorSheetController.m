/*
 
 CEIndicatorSheetController.m
 
 CotEditor
 http://coteditor.com
 
 Created by 1024jp on 2014-06-07.

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
    
    // setup indicator
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
        [[[self window] sheetParent] endSheet:[self window] returnCode:NSModalResponseCancel];
        
    } else {
        [NSApp abortModal];
        [NSApp endModalSession:[self modalSession]];
        [self setModalSession:nil];
        [NSApp endSheet:[self window]];
        [[self window] close];
    }
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
