/*
 
 CEProgressSheetController.m
 
 CotEditor
 http://coteditor.com
 
 Created by 1024jp on 2014-06-07.

 ------------------------------------------------------------------------------
 
 © 2014-2016 1024jp
 
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

#import "CEProgressSheetController.h"


@interface CEProgressSheetController ()

@property (nonatomic, weak) IBOutlet NSProgressIndicator *indicator;
@property (nonatomic, nullable, weak) IBOutlet NSButton *button;
@property (nonatomic) CEProgressSheetController *me;

@property (atomic) double progress;
@property (nonatomic, nonnull, copy) NSString *message;

@end




#pragma mark -

@implementation CEProgressSheetController

#pragma mark Superclass Methods

// ------------------------------------------------------
/// initialize instance
- (nonnull instancetype)initWithMessage:(nonnull NSString *)message
// ------------------------------------------------------
{
    self = [super init];
    if (self) {
        _message = message;
        _informativeText = NSLocalizedString(@"Please wait for a while.", nil);
    }
    return self;
}


// ------------------------------------------------------
/// nib name
- (nullable NSString *)windowNibName
// ------------------------------------------------------
{
    return @"ProgressSheet";
}


// ------------------------------------------------------
/// setup UI
- (void)windowDidLoad
// ------------------------------------------------------
{
    [super windowDidLoad];
    
    // setup indicator
    [[self indicator] setUsesThreadedAnimation:YES];
}



#pragma mark Public Methods

// ------------------------------------------------------
/// show as sheet
- (void)beginSheetForWindow:(nonnull NSWindow *)window completionHandler:(nullable void (^)(NSModalResponse))handler
// ------------------------------------------------------
{
    [window beginSheet:[self window] completionHandler:handler];
    
    [[self indicator] startAnimation:self];
    
    // retain itself to avoid dismiss controller while sheet is attached to a window
    [self setMe:self];
}


// ------------------------------------------------------
/// increase indicator
- (void)progressIndicator:(CGFloat)delta
// ------------------------------------------------------
{
    // set always on the main thread
    __weak typeof(self) weakSelf = self;
    dispatch_async(dispatch_get_main_queue(), ^{
        weakSelf.progress += delta;
    });
}


// ------------------------------------------------------
/// change state to done
- (void)doneWithButtonTitle:(nullable NSString *)title
// ------------------------------------------------------
{
    title = title ?: NSLocalizedString(@"OK", nil);
    
    [[self button] setTitle:title];
    [[self button] setAction:@selector(close:)];
    [[self button] setTarget:self];
    [[self button] setKeyEquivalent:@"\r"];
    
    [self setProgress:1.0];  // complete
    [[self indicator] stopAnimation:self];
}



#pragma mark Action Messages

// ------------------------------------------------------
/// close sheet
- (IBAction)close:(nullable id)sender
// ------------------------------------------------------
{
    [self setMe:nil];
    
    [[[self window] sheetParent] endSheet:[self window] returnCode:NSModalResponseOK];
}


// ------------------------------------------------------
/// cancel current process
- (IBAction)cancel:(nullable id)sender
// ------------------------------------------------------
{
    [self setMe:nil];
    
    [[[self window] sheetParent] endSheet:[self window] returnCode:NSModalResponseCancel];
}

@end
