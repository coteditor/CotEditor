/*
 
 CEGoToSheetController.m
 
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

#import "CEGoToSheetController.h"
#import "CEEditorWrapper.h"
#import "CETextView.h"


@interface CEGoToSheetController ()

@property (nonatomic, nullable, weak) CEEditorWrapper *editor;

@property (nonatomic, nullable, copy) NSString *location;
@property (nonatomic) CEGoToType gotoType;

@end




#pragma mark -

@implementation CEGoToSheetController

#pragma mark Superclass Methods

// ------------------------------------------------------
/// nib name
- (nullable NSString *)windowNibName
// ------------------------------------------------------
{
    return @"GoToSheet";
}



#pragma mark Public Methods

// ------------------------------------------------------
/// begin sheet for document
- (void)beginSheetForEditor:(nonnull CEEditorWrapper *)editor
// ------------------------------------------------------
{
    [self setEditor:editor];
    
    [[[editor focusedTextView] window] beginSheet:[self window] completionHandler:nil];
}



#pragma mark Action Messages

// ------------------------------------------------------
/// apply to the parent document window
- (IBAction)apply:(nullable id)sender
// ------------------------------------------------------
{
    NSArray<NSString *> *locLen = [[self location] componentsSeparatedByString:@":"];
    
    if ([locLen count] > 0) {
        NSInteger location = [locLen[0] integerValue];
        NSInteger length = ([locLen count] > 1) ? [locLen[1] integerValue] : 0;
        
        [[self editor] gotoLocation:location length:length type:[self gotoType]];
    }
    
    [[[self window] sheetParent] endSheet:[self window] returnCode:NSModalResponseOK];
}


// ------------------------------------------------------
/// close sheet
- (IBAction)close:(nullable id)sender
// ------------------------------------------------------
{
    [[[self window] sheetParent] endSheet:[self window] returnCode:NSModalResponseCancel];
}

@end
