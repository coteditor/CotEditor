/*
 
 CESidebarViewController.m
 
 CotEditor
 http://coteditor.com
 
 Created by 1024jp on 2016-06-05.
 
 ------------------------------------------------------------------------------
 
 © 2016 1024jp
 
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

#import "CESidebarViewController.h"
#import "CEDocument.h"


@interface CESidebarViewController () <NSTabViewDelegate>

@property (nonatomic, nullable) IBOutlet NSViewController *documentInspectorViewController;
@property (nonatomic, nullable) IBOutlet NSViewController *incompatibleCharsViewController;

@end




#pragma mark -

@implementation CESidebarViewController

#pragma mark Tab View Controller Methods

// ------------------------------------------------------
/// prepare tabs
- (void)viewDidLoad
// ------------------------------------------------------
{
    [super viewDidLoad];
    
    [[[self tabView] layer] setBackgroundColor:[[NSColor colorWithCalibratedWhite:0.94 alpha:1.0] CGColor]];
    
    NSTabViewItem *inspectorTabViewItem = [NSTabViewItem tabViewItemWithViewController:[self documentInspectorViewController]];
    NSTabViewItem *incompatibleCharactersTabViewItem = [NSTabViewItem tabViewItemWithViewController:[self incompatibleCharsViewController]];
    [inspectorTabViewItem setImage:[NSImage imageNamed:@"DocumentTemplate"]];
    [incompatibleCharactersTabViewItem setImage:[NSImage imageNamed:@"ConflictsTemplate"]];
    [inspectorTabViewItem setToolTip:NSLocalizedString(@"Document Inspector", nil)];  // TODO: Localized strings are not yet migrated. See DocumentWindow.strings for the previous one.
    [incompatibleCharactersTabViewItem setToolTip:NSLocalizedString(@"Incompatible Characters", nil)];
    
    [[self tabView] addTabViewItem:inspectorTabViewItem];
    [[self tabView] addTabViewItem:incompatibleCharactersTabViewItem];
    
    [self addChildViewController:[self documentInspectorViewController]];
    [self addChildViewController:[self incompatibleCharsViewController]];
    
}

// ------------------------------------------------------
/// apply passed-in document instance to window
- (void)setRepresentedObject:(nullable id)representedObject
// ------------------------------------------------------
{
    CEDocument *document = representedObject;
    [[self incompatibleCharsViewController] setRepresentedObject:[document incompatibleCharacterScanner]];
    [[self documentInspectorViewController] setRepresentedObject:[document analyzer]];
}




#pragma mark Private Methods

// ------------------------------------------------------
/// cast view to NSTabView
- (nullable NSTabView *)tabView
// ------------------------------------------------------
{
    return (NSTabView *)[self view];
}

@end
