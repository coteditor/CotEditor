/*
 
 CEIncompatibleCharsViewController.m
 
 CotEditor
 http://coteditor.com
 
 Created by 1024jp on 2014-12-18.

 ------------------------------------------------------------------------------
 
 © 2004-2007 nakamuxu
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

#import "CEIncompatibleCharsViewController.h"
#import "CEIncompatibleCharacterScanner.h"
#import "CEIncompatibleCharacter.h"
#import "CEDocument.h"
#import "CEEditorWrapper.h"

#import "CEDefaults.h"


@interface CEIncompatibleCharsViewController () <CEIncompatibleCharacterScannerDelegate, NSTableViewDelegate>

@property (nonatomic, getter=isCharAvailable) BOOL charAvailable;

@property (nonatomic, nullable) IBOutlet NSArrayController *incompatibleCharsController;

@end




#pragma mark -

@implementation CEIncompatibleCharsViewController

#pragma mark Public Methods

// ------------------------------------------------------
/// set delegate
- (void)setScanner:(CEIncompatibleCharacterScanner *)scanner
// ------------------------------------------------------
{
    [[self scanner] setDelegate:nil];
    
    _scanner = scanner;
    
    [scanner setDelegate:self];
    [scanner invalidate];
}



#pragma mark Delegate

//=======================================================
// Incompatible Character Scanner Delegate
//=======================================================

// ------------------------------------------------------
/// update list constantly only if the table is visible
- (BOOL)documentNeedsUpdateIncompatibleCharacter:(__kindof NSDocument *)document
// ------------------------------------------------------
{
    return ![[self view] isHidden];
}


// ------------------------------------------------------
- (void)document:(__kindof NSDocument *)document didUpdateIncompatibleCharacters:(NSArray<CEIncompatibleCharacter *> *)incompatibleCharacers
// ------------------------------------------------------
{
    [[self incompatibleCharsController] setContent:incompatibleCharacers];
    [self setCharAvailable:([incompatibleCharacers count] > 0)];
    
    NSMutableArray<NSValue *> *ranges = [NSMutableArray array];
    for (CEIncompatibleCharacter *incompatible in incompatibleCharacers) {
        [ranges addObject:[NSValue valueWithRange:[incompatible range]]];
    }
    [[document editor] clearAllMarkup];
    [[document editor] markupRanges:ranges];
}


//=======================================================
// Table View Delegate
//=======================================================

// ------------------------------------------------------
/// select correspondent char in text view
- (void)tableViewSelectionDidChange:(nonnull NSNotification *)notification
// ------------------------------------------------------
{
    CEIncompatibleCharacter *selectedIncompatible = [[[self incompatibleCharsController] selectedObjects] firstObject];
    
    if (!selectedIncompatible) { return; }
    
    NSRange range = [selectedIncompatible range];
    CEEditorWrapper *editor = [[[self scanner] document] editor];
    
    [editor setSelectedRange:range];
    
    // focus result
    // -> use textView's `selectedRange` since `range` is incompatible with CR/LF
    NSTextView *textView = [editor focusedTextView];
    [textView scrollRangeToVisible:[textView selectedRange]];
    [textView showFindIndicatorForRange:[textView selectedRange]];
}

@end
