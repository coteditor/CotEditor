/*
 
 CEUnicodeInputPanelController.m
 
 CotEditor
 http://coteditor.com
 
 Created by 1024jp on 2014-05-06.

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

#import "CEUnicodeInputPanelController.h"
#import "CEEditorWrapper.h"


@interface CEUnicodeInputPanelController () <NSTextFieldDelegate>

@property (nonatomic, nonnull, copy) NSString *unicode;
@property (nonatomic, getter=isValid) BOOL valid;

@end




#pragma mark -

@implementation CEUnicodeInputPanelController

static const NSRegularExpression *unicodeRegex;


#pragma mark Superclass Methods

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


// ------------------------------------------------------
/// initializer of panelController
- (nonnull instancetype)init
// ------------------------------------------------------
{
    self = [super initWithWindowNibName:@"UnicodePanel"];
    if (self) {
        _unicode = @"";
    }
    return self;
}



#pragma mark Delegate

// ------------------------------------------------------
/// text in text field was changed
- (void)controlTextDidChange:(nonnull NSNotification *)notification
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
- (IBAction)insertToDocument:(nullable id)sender
// ------------------------------------------------------
{
    unsigned int longChar;
    NSScanner *scanner = [NSScanner scannerWithString:[self unicode]];
    [scanner setCharactersToBeSkipped:[NSCharacterSet characterSetWithCharactersInString:@"uU+\\"]];
    [scanner scanHexInt:&longChar];
    
    NSTextView *textView = [[[self documentWindowController] editor] focusedTextView];
    UniChar chars[2];
    NSUInteger length = CFStringGetSurrogatePairForLongCharacter(longChar, chars) ? 2 : 1;
    NSString *character = [[NSString alloc] initWithCharacters:chars length:length];
    
    if ([textView shouldChangeTextInRange:[textView selectedRange] replacementString:character]) {
        [[textView textStorage] replaceCharactersInRange:[textView selectedRange] withString:character];
        [textView didChangeText];
        [[self window] performClose:sender];
        [self setUnicode:@""];
    } else {
        NSBeep();
    }
}

@end
