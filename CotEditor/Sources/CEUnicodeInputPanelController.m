/*
 
 CEUnicodeInputPanelController.m
 
 CotEditor
 http://coteditor.com
 
 Created by 1024jp on 2014-05-06.

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

#import "CEUnicodeInputPanelController.h"

#import "CEUnicodeCharacter.h"


@interface CEUnicodeInputPanelController () <NSTextFieldDelegate>

@property (nonatomic, nonnull, copy) NSString *unicode;
@property (nonatomic, getter=isValid) BOOL valid;

@property (nonatomic, nullable) CEUnicodeCharacter *character;

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
        unicodeRegex = [NSRegularExpression regularExpressionWithPattern:@"^(?:U\\+|0x|\\\\u)?([0-9a-f]{1,5})$"
                                                                 options:NSRegularExpressionCaseInsensitive
                                                                   error:nil];
    });
}


// ------------------------------------------------------
/// initializer of panelController
- (nonnull instancetype)init
// ------------------------------------------------------
{
    self = [super init];
    if (self) {
        _unicode = @"";
    }
    return self;
}


// ------------------------------------------------------
/// nib name
- (nullable NSString *)windowNibName
// ------------------------------------------------------
{
    return @"UnicodePanel";
}


// ------------------------------------------------------
/// auto close window if all document windows were closed
- (BOOL)autoCloses
// ------------------------------------------------------
{
    return YES;
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
    [self setCharacter:([self isValid] ? [[CEUnicodeCharacter alloc] initWithCharacter:[self longChar]] : nil)];
}



#pragma mark Public Accessor

// ------------------------------------------------------
- (nullable NSString *)characterString
// ------------------------------------------------------
{
    return [[self character] string];
}



#pragma mark Action Messages

// ------------------------------------------------------
/// input unicode character to the frontmost document
- (IBAction)insertToDocument:(nullable id)sender
// ------------------------------------------------------
{
    if ([[self characterString] length] == 0) { return; }
    
    id<CEUnicodeReceiver> receiver = [NSApp targetForAction:@selector(insertUnicodeCharacter:)];
    
    if (!receiver) {
        NSBeep();
        return;
    }
    
    [receiver insertUnicodeCharacter:self];
    
    [self setUnicode:@""];
    [self setCharacter:nil];
    [self setValid:NO];
    
}



#pragma mark Private Methods

// ------------------------------------------------------
/// UTF32Char form of current input unicode
- (UTF32Char)longChar
// ------------------------------------------------------
{
    UTF32Char longChar;
    NSScanner *scanner = [NSScanner scannerWithString:[self unicode]];
    [scanner setCharactersToBeSkipped:[NSCharacterSet characterSetWithCharactersInString:@"uU+\\"]];
    [scanner scanHexInt:&longChar];
    
    return longChar;
}

@end
