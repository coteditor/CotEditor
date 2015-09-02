/*
 
 CEColorPanelController.m
 
 CotEditor
 http://coteditor.com
 
 Created by 1024jp on 2014-04-22.

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

#import "CEColorCodePanelController.h"
#import "CEDocument.h"
#import "NSColor+WFColorCode.h"
#import "Constants.h"


@interface CEColorCodePanelController ()

@property (nonatomic, nullable) IBOutlet NSView *accessoryView;
@property (nonatomic, nullable) NSColor *color;
@property (nonatomic, nullable) NSString *colorCode;

@end




#pragma mark -

@implementation CEColorCodePanelController

#pragma mark Singleton

// ------------------------------------------------------
/// return singleton instance
+ (nonnull instancetype)sharedController
// ------------------------------------------------------
{
    static dispatch_once_t onceToken;
    static id shared = nil;
    
    dispatch_once(&onceToken, ^{
        shared = [[self alloc] init];
    });
    
    return shared;
}



#pragma mark NSWindowPanel Methods

// ------------------------------------------------------
/// initialize
- (nonnull instancetype)init
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
- (void)setColorWithCode:(nullable NSString *)colorCode
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
- (void)windowWillClose:(nonnull NSNotification *)notification
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
- (void)showWindow:(nullable id)sender
// ------------------------------------------------------
{
    // setup the shared color panel
    NSColorPanel *colorPanel = [NSColorPanel sharedColorPanel];
    [colorPanel setAccessoryView:[self accessoryView]];
    [colorPanel setShowsAlpha:YES];
    [colorPanel setRestorable:NO];
    
    [colorPanel setDelegate:self];
    [colorPanel setAction:@selector(selectColor:)];
    [colorPanel setTarget:self];
    
    // make positoin of accessory view center
    [[[colorPanel accessoryView] superview] addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"|[accessory]|"
                                                                                                   options:0
                                                                                                   metrics:@{}
                                                                                                     views:@{@"accessory": [colorPanel accessoryView]}]];
    
    [self setWindow:colorPanel];
    [self setColor:[colorPanel color]];
    [self updateCode:self];
    
    [colorPanel orderFront:self];
}


// ------------------------------------------------------
/// insert color code to the selection of the frontmost document
- (IBAction)insertCodeToDocument:(nullable id)sender
// ------------------------------------------------------
{
    NSTextView *textView = [[[self documentWindowController] editor] focusedTextView];
    
    if ([textView shouldChangeTextInRange:[textView selectedRange] replacementString:[self colorCode]]) {
        [textView replaceCharactersInRange:[textView selectedRange] withString:[self colorCode]];
        [[textView undoManager] setActionName:NSLocalizedString(@"Insert Color Code", nil)];
        [textView didChangeText];
        [textView scrollRangeToVisible:[textView selectedRange]];
    }
}


// ------------------------------------------------------
/// a new color was selected on the panel
- (IBAction)selectColor:(nullable id)sender
// ------------------------------------------------------
{
    [self setColor:[sender color]];
    [self updateCode:sender];
}


// ------------------------------------------------------
/// set color from the color code field in the panel
- (IBAction)applayColorCode:(nullable id)sender
// ------------------------------------------------------
{
    [self setColorWithCode:[self colorCode]];
}


// ------------------------------------------------------
/// update color code in the field
- (IBAction)updateCode:(nullable id)sender
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
