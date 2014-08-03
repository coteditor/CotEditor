/*
 ==============================================================================
 CEColorPanelController
 
 CotEditor
 http://coteditor.github.io
 
 Created by 2014-04-22 by 1024jp
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

#import "CEColorCodePanelController.h"
#import "CEDocument.h"
#import "NSColor+CEColorCode.h"
#import "constants.h"


@interface CEColorCodePanelController ()

@property (nonatomic) IBOutlet NSView *accessoryView;
@property (nonatomic) NSColor *color;
@property (nonatomic) NSString *colorCode;

@end




#pragma mark -

@implementation CEColorCodePanelController

#pragma mark Class Methods

//=======================================================
// Class method
//
//=======================================================

// ------------------------------------------------------
/// return singleton instance
+ (instancetype)sharedController
// ------------------------------------------------------
{
    static dispatch_once_t predicate;
    static id shared = nil;
    
    dispatch_once(&predicate, ^{
        shared = [[self alloc] init];
    });
    
    return shared;
}



#pragma mark Superclass Methods

//=======================================================
// Superclass method
//
//=======================================================

// ------------------------------------------------------
/// 初期化
- (instancetype)init
// ------------------------------------------------------
{
    self = [super init];
    if (self) {
        [NSBundle loadNibNamed:@"ColorCodePanelAccessory" owner:self];
    }
    return self;
}



#pragma mark Public Methods

//=======================================================
// Public method
//
//=======================================================

// ------------------------------------------------------
/// カラーコードから色をセットする
- (void)setColorWithCode:(NSString *)colorCode
// ------------------------------------------------------
{
    colorCode = [colorCode stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
    
    if ([colorCode length] == 0) {
        return;
    }
    
    CEColorCodeType codeType;
    NSColor *color = [NSColor colorWithColorCode:colorCode codeType:&codeType];
    
    if (color) {
        [[NSUserDefaults standardUserDefaults] setInteger:codeType forKey:k_key_colorCodeType];
        [(NSColorPanel *)[self window] setColor:color];
        return;
    }
    NSBeep();
}



#pragma mark Delegate

//=======================================================
// Delegate method (NSWindowDelegate)
//  <== NSColorPanel
//=======================================================

// ------------------------------------------------------
/// パネルをクローズ
- (void)windowWillClose:(NSNotification *)notification
// ------------------------------------------------------
{
    NSColorPanel *colorPanel = (NSColorPanel *)[self window];
    [[self window] setDelegate:nil];
    [colorPanel orderOut:self];
    [colorPanel setAccessoryView:nil];
    [colorPanel setShowsAlpha:NO];
}



#pragma mark Action Messages

//=======================================================
// Action Messages
//
//=======================================================

// ------------------------------------------------------
/// パネルを表示
- (void)showWindow:(id)sender
// ------------------------------------------------------
{
    // 共有カラーパネルをセットアップ
    NSColorPanel *colorPanel = [NSColorPanel sharedColorPanel];
    [colorPanel setAccessoryView:[self accessoryView]];
    [colorPanel setShowsAlpha:YES];
    [colorPanel setStyleMask:[colorPanel styleMask] & ~NSResizableWindowMask];
    [colorPanel setRestorable:NO];
    
    [colorPanel setDelegate:self];
    [colorPanel setAction:@selector(selectColor:)];
    [colorPanel setTarget:self];
    
    [self setWindow:colorPanel];
    [self setColor:[colorPanel color]];
    [self updateCode:self];
    
    [colorPanel orderFront:self];
}


// ------------------------------------------------------
/// 書類にカラーコードを挿入する
- (IBAction)insertCodeToDocument:(id)sender
// ------------------------------------------------------
{
    [[[self documentWindowController] editor] replaceTextViewSelectedStringTo:[self colorCode] scroll:YES];
}


// ------------------------------------------------------
/// カラーパネルで新しい色が選ばれた
- (IBAction)selectColor:(id)sender
// ------------------------------------------------------
{
    [self setColor:[sender color]];
    [self updateCode:sender];
}


// ------------------------------------------------------
/// カラーコードフィールドのカラーコードからカラーをセット
- (IBAction)applayColorCode:(id)sender
// ------------------------------------------------------
{
    [self setColorWithCode:[self colorCode]];
}


// ------------------------------------------------------
/// カラーコードを更新する
- (IBAction)updateCode:(id)sender
// ------------------------------------------------------
{
    CEColorCodeType codeType = [[NSUserDefaults standardUserDefaults] integerForKey:k_key_colorCodeType];
    NSString *code = [[[self color] colorUsingColorSpaceName:NSDeviceRGBColorSpace] colorCodeWithType:codeType];
    
    // 現在の Hex コードが大文字だったら大文字をキープ
    if ((codeType == CEColorCodeHex || codeType == CEColorCodeShortHex) &&
        [[self colorCode] rangeOfString:@"^#[0-9A-F]{1,6}$" options:NSRegularExpressionSearch].location != NSNotFound) {
        code = [code uppercaseString];
    }
    
    [self setColorCode:code];
}

@end
