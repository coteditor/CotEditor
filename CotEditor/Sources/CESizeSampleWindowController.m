/*
 
 CESizeSampleWindowController.m
 
 CotEditor
 http://coteditor.com
 
 Created by 1024jp on 2014-03-26.

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

#import "CESizeSampleWindowController.h"


@interface CESizeSampleWindowController ()

@property (nonatomic, nullable) IBOutlet NSUserDefaultsController *userDefaultsController;

@end




#pragma mark -

@implementation CESizeSampleWindowController

#pragma mark Superclass Methods

// ------------------------------------------------------
/// setup UI
- (void)windowDidLoad
// ------------------------------------------------------
{
    [super windowDidLoad];
    [[self window] center];
}



#pragma mark Action Messages

// ------------------------------------------------------
/// close window without save
- (IBAction)cancel:(nullable id)sender
// ------------------------------------------------------
{
    [[self userDefaultsController] revert:sender];
    [NSApp stopModal];
}


// ------------------------------------------------------
/// save window size to the user defaults and close window
- (IBAction)save:(nullable id)sender
// ------------------------------------------------------
{
    [[self userDefaultsController] save:sender];
    [NSApp stopModal];
}

@end
