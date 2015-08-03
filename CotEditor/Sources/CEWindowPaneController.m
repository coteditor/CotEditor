/*
 
 CEWindowPaneController.m
 
 CotEditor
 http://coteditor.com
 
 Created by 1024jp on 2014-04-18.

 ------------------------------------------------------------------------------
 
 © 2004-2007 nakamuxu
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

#import "CEWindowPaneController.h"
#import "CESizeSampleWindowController.h"
#import "Constants.h"


@interface CEWindowPaneController ()

@property (nonatomic, getter=isViewOpaque) BOOL viewOpaque;

@end




#pragma mark -

@implementation CEWindowPaneController

#pragma mark Superclass Methods

// ------------------------------------------------------
/// initialize
- (nullable instancetype)initWithNibName:(nullable NSString *)nibNameOrNil bundle:(nullable NSBundle *)nibBundleOrNil
// ------------------------------------------------------
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        _viewOpaque = ([[NSUserDefaults standardUserDefaults] doubleForKey:CEDefaultWindowAlphaKey] == 1.0);
    }
    return self;
}



#pragma mark Action Messages

// ------------------------------------------------------
/// opaque setting did update
- (IBAction)changeViewOpaque:(nullable id)sender
// ------------------------------------------------------
{
    [self setViewOpaque:([sender doubleValue] == 1.0)];
}


// ------------------------------------------------------
/// open sample window for window size setting
- (IBAction)openSizeSampleWindow:(nullable id)sender
// ------------------------------------------------------
{
    // display modal
    CESizeSampleWindowController *sampleWindowController = [[CESizeSampleWindowController alloc] initWithWindowNibName:@"SizeSampleWindow"];
    [sampleWindowController showWindow:sender];
    [NSApp runModalForWindow:[sampleWindowController window]];
    
    [[[self view] window] makeKeyAndOrderFront:self];
}

@end
