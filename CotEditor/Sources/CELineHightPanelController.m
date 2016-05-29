/*
 
 CELineHightPanelController.m
 
 CotEditor
 http://coteditor.com
 
 Created by 1024jp on 2014-03-16.

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

#import "CELineHightPanelController.h"
#import "CEWindowController.h"
#import "CEEditorWrapper.h"
#import "CETextView.h"


@interface CELineHightPanelController ()

@property (nonatomic) CGFloat lineSpacing;

@end




#pragma mark -

@implementation CELineHightPanelController

#pragma mark Superclass Methods

// ------------------------------------------------------
/// nib name
- (nullable NSString *)windowNibName
// ------------------------------------------------------
{
    return @"LineHightPanel";
}


// ------------------------------------------------------
/// invoke when frontmost document window changed
- (void)keyDocumentDidChange
// ------------------------------------------------------
{
    [self setLineSpacing:[[[self editor] focusedTextView] lineSpacing]];
}


// ------------------------------------------------------
/// auto close window if all document windows were closed
- (BOOL)autoCloses
// ------------------------------------------------------
{
    return YES;
}



#pragma mark Action Messages

// ------------------------------------------------------
/// apply to the frontmost document window
- (IBAction)apply:(nullable id)sender
// ------------------------------------------------------
{
    NSMenuItem *dummySender = [[NSMenuItem alloc] init];
    [dummySender setTitle:[NSString stringWithFormat:@"%g", [self lineSpacing] + 1.0]];
    
    [[self editor] changeLineHeight:dummySender];
    [[self window] close];
}



#pragma mark Private Methods

// ------------------------------------------------------
/// return text view to apply
- (nullable CEEditorWrapper *)editor
// ------------------------------------------------------
{
    return [[self documentWindowController] editor];
}

@end
