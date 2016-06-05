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

@property (nonatomic, nonnull) NSProgress *progress;
@property (nonatomic, nonnull, copy) NSString *message;

@property (nonatomic) CEProgressSheetController *me;

@property (nonatomic, nullable, weak) IBOutlet NSProgressIndicator *indicator;
@property (nonatomic, nullable, weak) IBOutlet NSButton *button;

@end




#pragma mark -

@implementation CEProgressSheetController

#pragma mark Superclass Methods

// ------------------------------------------------------
/// initialize instance
- (nonnull instancetype)initWithProgress:(nonnull NSProgress *)progress message:(nonnull NSString *)message
// ------------------------------------------------------
{
    self = [super init];
    if (self) {
        _progress = progress;
        _message = message;
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
- (void)beginSheetForWindow:(nonnull NSWindow *)window
// ------------------------------------------------------
{
    [window beginSheet:[self window] completionHandler:nil];
    
    // retain itself to avoid dismiss controller while sheet is attached to a window
    [self setMe:self];
}


// ------------------------------------------------------
/// change state to done
- (void)doneWithButtonTitle:(nullable NSString *)title
// ------------------------------------------------------
{
    title = title ?: NSLocalizedString(@"OK", nil);
    
    [[self button] setTitle:title];
    [[self button] setAction:@selector(close:)];
    [[self button] setKeyEquivalent:@"\r"];
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
    
    [[self progress] cancel];
    
    [[[self window] sheetParent] endSheet:[self window] returnCode:NSModalResponseCancel];
}

@end
