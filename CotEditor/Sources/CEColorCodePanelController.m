/*
 ==============================================================================
 CEColorPanelController
 
 CotEditor
 http://coteditor.com
 
 Created by 2014-04-22 by 1024jp
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

#import "CEColorCodePanelController.h"
#import "CEDocument.h"
#import "NSColor+WFColorCode.h"
#import "constants.h"


@interface CEColorCodePanelController ()

@property (nonatomic) IBOutlet NSView *accessoryView;
@property (nonatomic) NSColor *color;
@property (nonatomic) NSString *colorCode;

@end




#pragma mark -

@implementation CEColorCodePanelController

#pragma mark Singleton

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



#pragma mark NSWindowPanel Methods

// ------------------------------------------------------
/// initialize
- (instancetype)init
// ------------------------------------------------------
{
    self = [super init];
    if (self) {
        [[NSBundle mainBundle] loadNibNamed:@"ColorCodePanelAccessory" owner:self topLevelObjects:nil];
    }
    return self;
}



#pragma mark Public Methods

// ------------------------------------------------------
/// set color to color panel from color code
- (void)setColorWithCode:(NSString *)colorCode
// ------------------------------------------------------
{
    colorCode = [colorCode stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
    
    if ([colorCode length] == 0) {
        return;
    }
    
    WFColorCodeType codeType;
    NSColor *color = [NSColor colorWithColorCode:colorCode codeType:&codeType];
    
    if (color) {
        [[NSUserDefaults standardUserDefaults] setInteger:codeType forKey:CEDefaultColorCodeTypeKey];
        [(NSColorPanel *)[self window] setColor:color];
        return;
    }
    NSBeep();
}



#pragma mark Delegate

//=======================================================
// NSWindowDelegate  < NSColorPanel
//=======================================================

// ------------------------------------------------------
/// panel will close
- (void)windowWillClose:(NSNotification *)notification
// ------------------------------------------------------
{
    NSColorPanel *colorPanel = (NSColorPanel *)[self window];
    [[self window] setDelegate:nil];
    [colorPanel setAccessoryView:nil];
    [colorPanel setShowsAlpha:NO];
}



#pragma mark Action Messages

// ------------------------------------------------------
/// on show color panel
- (void)showWindow:(id)sender
// ------------------------------------------------------
{
    // setup the shared color panel
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
/// insert color code to the selection of the frontmost document
- (IBAction)insertCodeToDocument:(id)sender
// ------------------------------------------------------
{
    CEEditorWrapper *editor = [[self documentWindowController] editor];
    
    [editor replaceTextViewSelectedStringWithString:[self colorCode]];
    [[editor focusedTextView] scrollRangeToVisible:[[editor focusedTextView] selectedRange]];
}


// ------------------------------------------------------
/// a new color was selected on the panel
- (IBAction)selectColor:(id)sender
// ------------------------------------------------------
{
    [self setColor:[sender color]];
    [self updateCode:sender];
}


// ------------------------------------------------------
/// set color from the color code field in the panel
- (IBAction)applayColorCode:(id)sender
// ------------------------------------------------------
{
    [self setColorWithCode:[self colorCode]];
}


// ------------------------------------------------------
/// update color code in the field
- (IBAction)updateCode:(id)sender
// ------------------------------------------------------
{
    WFColorCodeType codeType = [[NSUserDefaults standardUserDefaults] integerForKey:CEDefaultColorCodeTypeKey];
    NSString *code = [[[self color] colorUsingColorSpaceName:NSCalibratedRGBColorSpace] colorCodeWithType:codeType];
    
    // keep lettercase if current Hex code is uppercase
    if ((codeType == WFColorCodeHex || codeType == WFColorCodeShortHex) &&
        [[self colorCode] rangeOfString:@"^#[0-9A-F]{1,6}$" options:NSRegularExpressionSearch].location != NSNotFound) {
        code = [code uppercaseString];
    }
    
    [self setColorCode:code];
}

@end
