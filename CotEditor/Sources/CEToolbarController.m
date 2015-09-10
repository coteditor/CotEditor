/*
 
 CEToolbarController.m
 
 CotEditor
 http://coteditor.com
 
 Created by nakamuxu on 2005-01-07.

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

#import "CEToolbarController.h"
#import "CEEditorWrapper.h"
#import "CEEncodingManager.h"
#import "CESyntaxManager.h"
#import "CEWindowController.h"
#import "Constants.h"


@interface CEToolbarController ()

@property (nonatomic, nullable, weak) IBOutlet NSToolbar *toolbar;
@property (nonatomic, nullable, weak) IBOutlet CEWindowController *windowController;
@property (nonatomic, nullable, weak) IBOutlet NSPopUpButton *lineEndingPopupButton;
@property (nonatomic, nullable, weak) IBOutlet NSPopUpButton *encodingPopupButton;
@property (nonatomic, nullable, weak) IBOutlet NSPopUpButton *syntaxPopupButton;

@end




#pragma mark -

@implementation CEToolbarController

#pragma mark Superclass Methods

// ------------------------------------------------------
/// clean up
- (void)dealloc
// ------------------------------------------------------
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}


// ------------------------------------------------------
/// setup UI
- (void)awakeFromNib
// ------------------------------------------------------
{
    [self buildEncodingPopupButton];
    [self buildSyntaxPopupButton];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(buildEncodingPopupButton)
                                                 name:CEEncodingListDidUpdateNotification
                                               object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(buildSyntaxPopupButton)
                                                 name:CESyntaxListDidUpdateNotification
                                               object:nil];
}



#pragma mark Public Method

// ------------------------------------------------------
/// update state of item which can be toggled
- (void)toggleItemWithTag:(CEToolbarItemTag)tag setOn:(BOOL)setOn
// ------------------------------------------------------
{
    for (NSToolbarItem *item in [[self toolbar] items]) {
        if ([item tag] == tag) {
            [self toggleItem:item setOn:setOn];
        }
    }
}


// ------------------------------------------------------
/// select item in the encoding popup menu
- (void)setSelectedEncoding:(NSStringEncoding)encoding
// ------------------------------------------------------
{
    for (NSMenuItem *menuItem in [[self encodingPopupButton] itemArray]) {
        if ([menuItem tag] == encoding) {
            [[self encodingPopupButton] selectItem:menuItem];
            break;
        }
    }
}


// ------------------------------------------------------
/// select item in the line ending menu
- (void)setSelectedLineEnding:(CENewLineType)lineEnding
// ------------------------------------------------------
{
    if (lineEnding >= [[self lineEndingPopupButton] numberOfItems]) { return; }

    [[self lineEndingPopupButton] selectItemAtIndex:lineEnding];
}


// ------------------------------------------------------
/// select item in the syntax style menu
- (void)setSelectedSyntaxWithName:(nonnull NSString *)name
// ------------------------------------------------------
{
    [[self syntaxPopupButton] selectItemWithTitle:name];
    if (![[self syntaxPopupButton] selectedItem]) {
        [[self syntaxPopupButton] selectItemAtIndex:0];  // select "None"
    }
}



#pragma mark Delegate

//=======================================================
// NSToolbarDelegate  < toolbar
//=======================================================

// ------------------------------------------------------
/// set state of toolbar item when it will be added
- (void)toolbarWillAddItem:(nonnull NSNotification *)notification
// ------------------------------------------------------
{
    NSToolbarItem *item = [notification userInfo][@"item"];
    CEEditorWrapper *editor = [[self windowController] editor];
    
    switch ([item tag]) {
        case CEToolbarShowInvisibleCharsItemTag:
            [self toggleItem:item setOn:[editor showsInvisibles]];
            
            // disable button if item cannot be enable
            if ([editor canActivateShowInvisibles]) {
                [item setAction:@selector(toggleInvisibleChars:)];
                [item setToolTip:NSLocalizedString(@"Show or hide invisible characters in document", nil)];
            } else {
                [item setAction:nil];
                [item setToolTip:NSLocalizedString(@"To display invisible characters, set them in Preferences and re-open the document.", nil)];
            }
            break;
        case CEToolbarAutoTabExpandItemTag:
            [self toggleItem:item setOn:[editor isAutoTabExpandEnabled]];
            break;
        case CEToolbarShowNavigationBarItemTag:
            [self toggleItem:item setOn:[editor showsNavigationBar]];
            break;
        case CEToolbarShowLineNumItemTag:
            [self toggleItem:item setOn:[editor showsLineNum]];
            break;
        case CEToolbarShowStatusBarItemTag:
            [self toggleItem:item setOn:[[self windowController] showsStatusBar]];
            break;
        case CEToolbarShowPageGuideItemTag:
            [self toggleItem:item setOn:[editor showsPageGuide]];
            break;
        case CEToolbarWrapLinesItemTag:
            [self toggleItem:item setOn:[editor wrapsLines]];
            break;
        default:
            break;
    }
}



#pragma mark Private Methods

// ------------------------------------------------------
/// update item which can be toggled
- (void)toggleItem:(nonnull NSToolbarItem *)item setOn:(BOOL)setOn
// ------------------------------------------------------
{
    NSString *imageName;
    
    switch ([item tag]) {
        case CEToolbarShowNavigationBarItemTag:
            imageName = setOn ? @"NaviBar_Show" : @"NaviBar_Hide";
            break;
        case CEToolbarShowLineNumItemTag:
            imageName = setOn ? @"LineNumber_Show" : @"LineNumber_Hide";
            break;
        case CEToolbarShowStatusBarItemTag:
            imageName = setOn ? @"StatusBar_Show" : @"StatusBar_Hide";
            break;
        case CEToolbarShowInvisibleCharsItemTag:
            imageName = setOn ? @"InvisibleChars_Show" : @"InvisibleChars_Hide";
            break;
        case CEToolbarShowPageGuideItemTag:
            imageName = setOn ? @"PageGuide_Show" : @"PageGuide_Hide";
            break;
        case CEToolbarWrapLinesItemTag:
            imageName = setOn ? @"WrapLines_On" : @"WrapLines_Off";
            break;
        case CEToolbarTextOrientationItemTag:
            imageName = setOn ? @"VerticalOrientation_On" : @"VerticalOrientation_Off";
            break;
        case CEToolbarAutoTabExpandItemTag:
            imageName = setOn ? @"AutoTabExpand_On" : @"AutoTabExpand_Off";
            break;
        default:
            return;
    }
    
    [item setImage:[NSImage imageNamed:imageName]];
}


// ------------------------------------------------------
/// build encoding popup item
- (void)buildEncodingPopupButton
// ------------------------------------------------------
{
    NSArray<NSMenuItem *> *items = [[CEEncodingManager sharedManager] encodingMenuItems];
    NSStringEncoding encoding = [[[self encodingPopupButton] selectedItem] tag];
    
    [[self encodingPopupButton] removeAllItems];
    for (NSMenuItem *item in items) {
        [item setAction:@selector(changeEncoding:)];
        [item setTarget:nil];
        [[[self encodingPopupButton] menu] addItem:item];
    }
    
    [self setSelectedEncoding:encoding];
}


// ------------------------------------------------------
/// build syntax style popup menu
- (void)buildSyntaxPopupButton
// ------------------------------------------------------
{
    NSArray<NSString *> *styleNames = [[CESyntaxManager sharedManager] styleNames];
    NSString *title = [[self syntaxPopupButton] titleOfSelectedItem];
    
    [[self syntaxPopupButton] removeAllItems];
    [[[self syntaxPopupButton] menu] addItemWithTitle:NSLocalizedString(@"None", nil)
                                               action:@selector(changeSyntaxStyle:)
                                        keyEquivalent:@""];
    [[[self syntaxPopupButton] menu] addItem:[NSMenuItem separatorItem]];
    for (NSString *styleName in styleNames) {
        [[[self syntaxPopupButton] menu] addItemWithTitle:styleName
                                                   action:@selector(changeSyntaxStyle:)
                                            keyEquivalent:@""];
    }
    
    [self setSelectedSyntaxWithName:title];
}

@end
