/*
 =================================================
 CEIndicatorSheetController
 (for CotEditor)
 
 Copyright (C) 2014 CotEditor Project
 http://coteditor.github.io
 =================================================
 
 encoding="UTF-8"
 Created:2014-06-07 by 1024jp
 
 -------------------------------------------------
 
 This program is free software; you can redistribute it and/or
 modify it under the terms of the GNU General Public License
 as published by the Free Software Foundation; either version 2
 of the License, or (at your option) any later version.
 
 This program is distributed in the hope that it will be useful,
 but WITHOUT ANY WARRANTY; without even the implied warranty of
 MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 GNU General Public License for more details.
 
 You should have received a copy of the GNU General Public License
 along with this program; if not, write to the Free Software
 Foundation, Inc., 59 Temple Place - Suite 330, Boston, MA  02111-1307, USA.
 
 
 =================================================
 */

#import "CEIndicatorSheetController.h"


@interface CEIndicatorSheetController ()

@property (nonatomic, weak) IBOutlet NSProgressIndicator *indicator;

@property (nonatomic, copy) NSString *message;

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
- (NSModalSession)beginSheetForWindow:(NSWindow *)window
// ------------------------------------------------------
{
    [NSApp beginSheet:[self window]
       modalForWindow:window
        modalDelegate:self
       didEndSelector:NULL
          contextInfo:NULL];
    
    return [NSApp beginModalSessionForWindow:[self window]];
}


// ------------------------------------------------------
/// シートを終わる
- (void)endSheet
// ------------------------------------------------------
{
    [NSApp endSheet:[self window]];
    [[self window] orderOut:self];
    
}

// ------------------------------------------------------
/// カラーリングインジケータの値を進める
- (void)progressIndicator:(CGFloat)delta
// ------------------------------------------------------
{
    [[self indicator] setDoubleValue:[[self indicator] doubleValue] + (double)delta];
}



#pragma mark Action Messages

//=======================================================
// Action messages
//
//=======================================================

// ------------------------------------------------------
/// カラーリング中止、インジケータシートのモーダルを停止
- (IBAction)cancelColoring:(id)sender
// ------------------------------------------------------
{
    [NSApp abortModal];
}

@end
