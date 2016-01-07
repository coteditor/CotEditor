/*
 
 CEIndicatorSheetController.m
 
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

#import "CEIndicatorSheetController.h"


@interface CEIndicatorSheetController ()

@property (nonatomic, weak) IBOutlet NSProgressIndicator *indicator;

@property (atomic) double progress;
@property (nonatomic, nonnull, copy) NSString *message;

// readonly
@property (readwrite, nonatomic, nullable, weak) IBOutlet NSButton *button;

@end




#pragma mark -

@implementation CEIndicatorSheetController

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
    return @"IndicatorSheet";
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
