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
#import "CEDocumentInspectorViewController.h"
#import "CEIncompatibleCharsViewController.h"
#import "CEDocument.h"


@interface CESidebarViewController ()

@property (nonatomic, nullable) NSViewController *documentInspectorViewController;
@property (nonatomic, nullable) NSViewController *incompatibleCharsViewController;

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
    
    self.documentInspectorViewController = [[CEDocumentInspectorViewController alloc] init];
    self.incompatibleCharsViewController = [[CEIncompatibleCharsViewController alloc] init];
    
    NSTabViewItem *inspectorTabViewItem = [NSTabViewItem tabViewItemWithViewController:[self documentInspectorViewController]];
    NSTabViewItem *incompatibleCharactersTabViewItem = [NSTabViewItem tabViewItemWithViewController:[self incompatibleCharsViewController]];
    [inspectorTabViewItem setImage:[NSImage imageNamed:@"DocumentTemplate"]];
    [incompatibleCharactersTabViewItem setImage:[NSImage imageNamed:@"ConflictsTemplate"]];
    [inspectorTabViewItem setToolTip:NSLocalizedString(@"Document Inspector", nil)];
    [incompatibleCharactersTabViewItem setToolTip:NSLocalizedString(@"Incompatible Characters", nil)];
    
    [self addTabViewItem:inspectorTabViewItem];
    [self addTabViewItem:incompatibleCharactersTabViewItem];
}


// ------------------------------------------------------
/// deliver passed-in document instance to child view controllers
- (void)setRepresentedObject:(nullable id)representedObject
// ------------------------------------------------------
{
    [super setRepresentedObject:representedObject];
    
    CEDocument *document = representedObject;
    
    if (![document isKindOfClass:[CEDocument class]]) { return; }
    
    [[self incompatibleCharsViewController] setRepresentedObject:[document incompatibleCharacterScanner]];
    [[self documentInspectorViewController] setRepresentedObject:[document analyzer]];
}

@end
