/*
 
 CELineHightPanelController.m
 
 CotEditor
 http://coteditor.com
 
 Created by 1024jp on 2014-03-16.

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

#import "CELineHightPanelController.h"
#import "CEEditorWrapper.h"


@interface CELineHightPanelController ()

@property (nonatomic) CGFloat lineSpacing;

@end




#pragma mark -

@implementation CELineHightPanelController

#pragma mark Superclass Methods

// ------------------------------------------------------
/// initializer of panelController
- (nonnull instancetype)init
// ------------------------------------------------------
{
    self = [super initWithWindowNibName:@"LineHightPanel"];
    
    return self;
}


// ------------------------------------------------------
/// invoke when frontmost document window changed
- (void)keyDocumentDidChange
// ------------------------------------------------------
{
    [self setLineSpacing:[[self textView] lineSpacing]];
    
}



#pragma mark Action Messages

// ------------------------------------------------------
/// apply to the frontmost document window
- (IBAction)apply:(nullable id)sender
// ------------------------------------------------------
{
    [[self textView] setLineSpacingAndUpdate:[self lineSpacing]];
    [[self window] close];
}



#pragma mark Private Methods

// ------------------------------------------------------
/// return text view to apply
- (nullable CETextView *)textView
// ------------------------------------------------------
{
    return [[[self documentWindowController] editor] focusedTextView];
}

@end
