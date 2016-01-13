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
    [[self indicator] setIndeterminate:NO];
    [[self indicator] setDoubleValue:0];
    [[self indicator] setUsesThreadedAnimation:YES];
    [[self indicator] setIndeterminate:YES];
}



#pragma mark Public Methods

// ------------------------------------------------------
/// show as sheet
- (void)beginSheetForWindow:(nonnull NSWindow *)window completionHandler:(nullable void (^)(NSModalResponse))handler
// ------------------------------------------------------
{
    if (NSAppKitVersionNumber >= NSAppKitVersionNumber10_9) { // on Mavericks or later
        [window beginSheet:[self window] completionHandler:handler];
        
    } else {
        [NSApp beginSheet:[self window] modalForWindow:window
            modalDelegate:self didEndSelector:@selector(sheetDidEnd:returnCode:contextInfo:)
              contextInfo:(__bridge_retained void * _Null_unspecified)(handler)];
    }
    
    [[self indicator] setDoubleValue:[self progress]];
    [[self indicator] startAnimation:self];
    
    // retain itself to avoid dismiss controller while sheet is attached to a window
    [self setMe:self];
}


// ------------------------------------------------------
/// increase indicator
- (void)progressIndicator:(CGFloat)delta
// ------------------------------------------------------
{
    @synchronized(self) {
        self.progress += delta;
    }
    
    // set always on main thread
    NSProgressIndicator *indicator = [self indicator];
    dispatch_async(dispatch_get_main_queue(), ^{
        [indicator incrementBy:(double)delta];
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
    
    [[self indicator] stopAnimation:self];
    [[self indicator] setDoubleValue:1.0];
}


// ------------------------------------------------------
///
- (void)setIndetermine:(BOOL)indetermine
// ------------------------------------------------------
{
    [[self indicator] setIndeterminate:indetermine];
}


// ------------------------------------------------------
///
- (BOOL)isIndetermine
// ------------------------------------------------------
{
    return [[self indicator] isIndeterminate];
}



#pragma mark Action Messages

// ------------------------------------------------------
/// close sheet
- (IBAction)close:(nullable id)sender
// ------------------------------------------------------
{
    if (NSAppKitVersionNumber >= NSAppKitVersionNumber10_9) { // on Mavericks or later
        [[[self window] sheetParent] endSheet:[self window] returnCode:NSModalResponseOK];
        
    } else {
        [NSApp endSheet:[self window] returnCode:NSOKButton];
    }
    [self setMe:nil];
}

// ------------------------------------------------------
/// cancel current process
- (IBAction)cancel:(nullable id)sender
// ------------------------------------------------------
{
    if (NSAppKitVersionNumber >= NSAppKitVersionNumber10_9) { // on Mavericks or later
        [[[self window] sheetParent] endSheet:[self window] returnCode:NSModalResponseCancel];
        
    } else {
        [NSApp endSheet:[self window] returnCode:NSCancelButton];
    }
    [self setMe:nil];
}



#pragma mark Private Method

// ------------------------------------------------------
/// did sheet closed
- (void)sheetDidEnd:(nonnull NSWindow *)sheet returnCode:(NSInteger)returnCode contextInfo:(nullable void *)contextInfo
// ------------------------------------------------------
{
    if (contextInfo) {
        void(^completionHandler)(NSInteger) = (__bridge_transfer void(^)(NSInteger)) contextInfo;
        completionHandler(returnCode);
    }
    
    [[self window] orderOut:self];
}

@end
