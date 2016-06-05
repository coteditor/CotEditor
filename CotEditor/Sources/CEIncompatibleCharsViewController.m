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
#import "CETextView.h"


@interface CEIncompatibleCharsViewController () <CEIncompatibleCharacterScannerDelegate, NSTableViewDelegate>

@property (nonatomic, getter=isCharAvailable) BOOL charAvailable;

@property (nonatomic, nullable) IBOutlet NSArrayController *incompatibleCharsController;

@end




#pragma mark -

@implementation CEIncompatibleCharsViewController

// ------------------------------------------------------
/// update content before display
- (void)viewWillAppear
// ------------------------------------------------------
{
    [[self scanner] scan];
    
    [super viewWillAppear];
}


// ------------------------------------------------------
/// clear incompatible chars markup
- (void)viewDidDisappear
// ------------------------------------------------------
{
    [[[[self scanner] document] editor] clearAllMarkup];
    
    [super viewDidDisappear];
}


// ------------------------------------------------------
/// set delegate
- (void)setRepresentedObject:(id)representedObject
// ------------------------------------------------------
{
    NSAssert([representedObject isKindOfClass:[CEIncompatibleCharacterScanner class]],
             @"representedObject of %@ must be an instance of %@", [self className], [CEIncompatibleCharacterScanner className]);
    
    [[self scanner] setDelegate:nil];
    
    [super setRepresentedObject:representedObject];
    
    [[self scanner] setDelegate:self];
    [[self scanner] scan];
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
/// incompatible characters list was updated
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



# pragma Private Medhods

// ------------------------------------------------------
/// cast representedObject to incompatible character scanner
- (nullable CEIncompatibleCharacterScanner *)scanner
// ------------------------------------------------------
{
    return [self representedObject];
}

@end
