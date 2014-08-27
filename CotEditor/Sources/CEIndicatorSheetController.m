/*
 ==============================================================================
 CEIndicatorSheetController
 
 CotEditor
 http://coteditor.github.io
 
 Created on 2014-06-07 by 1024jp
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

#import "CEIndicatorSheetController.h"


@interface CEIndicatorSheetController ()

@property (weak) IBOutlet NSProgressIndicator *indicator;
@property NSWindow *parentWindow;

@property (copy) NSString *message;
@property NSModalSession modalSession;

// readonly
@property (readwrite, getter=isCancelled) BOOL cancelled;

@end




#pragma mark -

@implementation CEIndicatorSheetController

#pragma mark Superclass Methods

//=======================================================
// Superclass method
//
//=======================================================

// ------------------------------------------------------
/// 初期化
- (instancetype)initWithMessage:(NSString *)message
// ------------------------------------------------------
{
    self = [super initWithWindowNibName:@"Indicator"];
    if (self) {
        [self setMessage:message];
        [self setInformativeText:NSLocalizedString(@"Please wait for a while.", nil)];
    }
    return self;
}


// ------------------------------------------------------
/// ウインドウをロードした直後
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

//=======================================================
// Public method
//
//=======================================================

// ------------------------------------------------------
/// カラーリングインジケータの値を返す
- (CGFloat)indicatorValue
// ------------------------------------------------------
{
    return (CGFloat)[[self indicator] doubleValue];
}


// ------------------------------------------------------
/// カラーリングインジケータの値を設定
- (void)setIndicatorValue:(CGFloat)indicatorValue
// ------------------------------------------------------
{
    [[self indicator] setDoubleValue:(double)indicatorValue];
    [[self indicator] displayIfNeeded];
}


// ------------------------------------------------------
/// シートとして表示する
- (void)beginSheetForWindow:(NSWindow *)window
// ------------------------------------------------------
{
    if (floor(NSAppKitVersionNumber) > NSAppKitVersionNumber10_8) { // on Mavericks or later
        [window beginSheet:[self window] completionHandler:nil];
        [self setParentWindow:window];
        
    } else {
        [NSApp beginSheet:[self window] modalForWindow:window
            modalDelegate:self didEndSelector:NULL contextInfo:NULL];
        [self setModalSession:[NSApp beginModalSessionForWindow:[self window]]];
    }
}


// ------------------------------------------------------
/// シートを終わる
- (void)endSheet
// ------------------------------------------------------
{
    if (floor(NSAppKitVersionNumber) > NSAppKitVersionNumber10_8) { // on Mavericks or later
        [[self parentWindow] endSheet:[self window] returnCode:NSModalResponseCancel];
        
    } else {
        [NSApp abortModal];
        [NSApp endModalSession:[self modalSession]];
        [self setModalSession:nil];
        [NSApp endSheet:[self window]];
    }
    
    [[self window] close];
}

// ------------------------------------------------------
/// カラーリングインジケータの値を進める
- (void)progressIndicator:(CGFloat)delta
// ------------------------------------------------------
{
    // set always on main thread
    NSProgressIndicator *indicator = [self indicator];
    dispatch_async(dispatch_get_main_queue(), ^{
        [indicator setDoubleValue:[indicator doubleValue] + (double)delta];
    });
}



#pragma mark Action Messages

//=======================================================
// Action messages
//
//=======================================================

// ------------------------------------------------------
/// カラーリング中止
- (IBAction)cancelColoring:(id)sender
// ------------------------------------------------------
{
    [self setCancelled:YES];
}

@end
