/*
 ==============================================================================
 CEUnicodeInputPanelController
 
 CotEditor
 http://coteditor.com
 
 Created by 2014-05-06 by 1024jp
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

#import "CEUnicodeInputPanelController.h"


@interface CEUnicodeInputPanelController () <NSTextFieldDelegate>

@property (nonatomic, copy) NSString *unicode;
@property (nonatomic, getter=isValid) BOOL valid;

@end




#pragma mark -

@implementation CEUnicodeInputPanelController

static const NSRegularExpression *unicodeRegex;


#pragma mark Class Methods

// ------------------------------------------------------
/// initialize class
+ (void)initialize
// ------------------------------------------------------
{
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        unicodeRegex = [NSRegularExpression regularExpressionWithPattern:@"^(?:U\\+|0x|\\\\u)?([0-9a-f]{4,5})$"
                                                                 options:NSRegularExpressionCaseInsensitive
                                                                   error:nil];
    });
}


#pragma mark Superclass Methods

// ------------------------------------------------------
/// initializer of panelController
- (instancetype)init
// ------------------------------------------------------
{
    return [super initWithWindowNibName:@"UnicodePanel"];
}



#pragma mark Delegate

// ------------------------------------------------------
/// text in text field was changed
- (void)controlTextDidChange:(NSNotification *)notification
// ------------------------------------------------------
{
    NSString *input = [[notification object] stringValue];
    
    NSTextCheckingResult *result = [unicodeRegex firstMatchInString:input options:0
                                                              range:NSMakeRange(0, [input length])];
    
    [self setValid:(result != nil)];
}



#pragma mark Action Messages

// ------------------------------------------------------
/// input unicode character to the frontmost document
- (IBAction)insertToDocument:(id)sender
// ------------------------------------------------------
{
    unsigned int longChar;
    NSScanner *scanner = [NSScanner scannerWithString:[self unicode]];
    [scanner setCharactersToBeSkipped:[NSCharacterSet characterSetWithCharactersInString:@"uU+\\"]];
    [scanner scanHexInt:&longChar];
    
    UniChar chars[2];
    NSUInteger length = CFStringGetSurrogatePairForLongCharacter(longChar, chars) ? 2 : 1;
    NSString *character = [[NSString alloc] initWithCharacters:chars length:length];
    
    [[[[self documentWindowController] editor] textView] insertText:character];
    [[self window] performClose:sender];
    [self setUnicode:@""];
}

@end
