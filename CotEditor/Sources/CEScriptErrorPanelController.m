/*
 ==============================================================================
 CEScriptErrorPanelController
 
 CotEditor
 http://coteditor.com
 
 Created by 2014-03-12 by 1024jp
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

#import "CEScriptErrorPanelController.h"


@interface CEScriptErrorPanelController ()

@property (nonatomic, strong) IBOutlet NSTextView *textView;  // on 10.8 NSTextView cannot be weak
@property (nonatomic) IBOutlet NSTextFinder *textFinder;

@end




#pragma mark -

@implementation CEScriptErrorPanelController

#pragma mark Superclass Mthods

// ------------------------------------------------------
/// initializer of panelController
- (instancetype)init
// ------------------------------------------------------
{
    return [super initWithWindowNibName:@"ScriptErrorPanel"];
}


// ------------------------------------------------------
/// setup UI
- (void)windowDidLoad
// ------------------------------------------------------
{
    [super windowDidLoad];
    
    [[self textView] setFont:[NSFont messageFontOfSize:11]];
}



#pragma mark Public Methods

// ------------------------------------------------------
/// append given string to the script error console
- (void)addErrorString:(NSString *)string
// ------------------------------------------------------
{
    [[self textView] setEditable:YES];
    [[self textView] setSelectedRange:NSMakeRange([[[self textView] string] length], 0)];
    [[self textView] insertText:[NSString stringWithFormat:@"%@\n", string]];
    [[self textView] setEditable:NO];
}



#pragma mark Action Messages

// ------------------------------------------------------
/// flush script error console
- (IBAction)cleanScriptError:(id)sender
// ------------------------------------------------------
{
    [[self textView] setString:@""];
}

@end




#pragma mark -

@implementation CEScriptErrorView

// ------------------------------------------------------
/// catch shortcut input
- (BOOL)performKeyEquivalent:(NSEvent *)theEvent
// ------------------------------------------------------
{
    // Since the Find menu is overridden by OgreKit framework, we need catch shortcut input manually for find actions.
    NSTextFinder *textFinder = [(CEScriptErrorPanelController *)[[self window] windowController] textFinder];
    
    if ([[theEvent characters] isEqualToString:@"f"]) {
        [textFinder performAction:NSTextFinderActionShowFindInterface];
        return YES;
        
    } else if ([[theEvent characters] isEqualToString:@"g"] && [theEvent modifierFlags] & NSShiftKeyMask) {
        [textFinder performAction:NSTextFinderActionPreviousMatch];
        return YES;
        
    } else if ([[theEvent characters] isEqualToString:@"g"]) {
        [textFinder performAction:NSTextFinderActionNextMatch];
        return YES;
        
    } else if ([[theEvent characters] isEqualToString:@"e"]) {
        [textFinder performAction:NSTextFinderActionSetSearchString];
        return YES;
        
    }
    
    return NO;
}

@end
