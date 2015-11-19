/*
 
 CECharacterPopoverController.m
 
 CotEditor
 http://coteditor.com
 
 Created by 1024jp on 2014-05-01.

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

#import "CECharacterPopoverController.h"
#import "CECharacterInfo.h"


@interface CECharacterPopoverController () <NSPopoverDelegate>

@property (nonatomic, nonnull, copy) NSString *glyph;
@property (nonatomic, nonnull, copy) NSString *unicodeName;
@property (nonatomic, nullable, copy) NSString *unicodeGroupName;
@property (nonatomic, nonnull, copy) NSString *unicode;


@property (nonatomic, nullable, weak) IBOutlet NSTextField *unicodeGroupNameField;

@end




#pragma mark -

@implementation CECharacterPopoverController

#pragma mark Public Methods

// ------------------------------------------------------
/// failable initialize
- (nullable instancetype)initWithCharacter:(nonnull NSString *)singleString
// ------------------------------------------------------
{
    CECharacterInfo *characterInfo = [CECharacterInfo characterInfoWithString:singleString];
    
    if (!characterInfo) { return nil; }
    
    self = [super initWithNibName:@"CharacterPopover" bundle:nil];
    if (self) {
        _glyph = [characterInfo string];
        _unicode = [[characterInfo unicodes] componentsJoinedByString:@"  "];
        _unicodeName = [characterInfo unicodeName];
        _unicodeGroupName = [characterInfo localizedUnicodeGroupName];
    }
    return self;
}


// ------------------------------------------------------
/// modify xib items
- (void)viewDidAppear
// ------------------------------------------------------
{
    [super viewDidAppear];
    
    // remove group name field if not exists
    if (![self unicodeGroupName]) {
        [[self unicodeGroupNameField] removeFromSuperviewWithoutNeedingDisplay];
    }
}



// ------------------------------------------------------
/// show popover
- (void)showPopoverRelativeToRect:(NSRect)positioningRect ofView:(nonnull NSView *)parentView
// ------------------------------------------------------
{
    NSPopover *popover = [[NSPopover alloc] init];
    [popover setContentViewController:self];
    [popover setDelegate:self];
    [popover setBehavior:NSPopoverBehaviorSemitransient];
    [popover showRelativeToRect:positioningRect ofView:parentView preferredEdge:NSMinYEdge];
    [[parentView window] makeFirstResponder:parentView];
}



#pragma mark Delegate

//=======================================================
// NSPopoverDelegate
//=======================================================

// ------------------------------------------------------
/// make popover detachable (on Yosemite and later)
- (BOOL)popoverShouldDetach:(NSPopover *)popover
// ------------------------------------------------------
{
    return YES;
}

@end
