/*
 ==============================================================================
 CEToolbarController
 
 CotEditor
 http://coteditor.com
 
 Created on 2005-01-07 by nakamuxu
 encoding="UTF-8"
 ------------------------------------------------------------------------------
 
 © 2004-2007 nakamuxu
 © 2014 CotEditor Project
 
 This program is free software; you can redistribute it and/or modify it under
 the terms of the GNU General Public License as published by the Free Software
 Foundation; either version 2 of the License, or (at your option) any later
 version.
 
 This program is distributed in the hope that it will be useful, but WITHOUT
 ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS
 FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.
 
 You should have received a copy of the GNU General Public License along with
 this program; if not, write to the Free Software Foundation, Inc., 59 Temple
 Place - Suite 330, Boston, MA  02111-1307, USA.
 
 ==============================================================================
 */

#import "CEToolbarController.h"
#import "CEEncodingManager.h"
#import "CESyntaxManager.h"
#import "CEWindowController.h"
#import "constants.h"


@interface CEToolbarController ()

@property (nonatomic, weak) IBOutlet NSToolbar *toolbar;
@property (nonatomic, weak) IBOutlet CEWindowController *windowController;
@property (nonatomic, weak) IBOutlet NSPopUpButton *lineEndingPopupButton;
@property (nonatomic, weak) IBOutlet NSPopUpButton *encodingPopupButton;
@property (nonatomic, weak) IBOutlet NSPopUpButton *syntaxPopupButton;

@end




#pragma mark -

@implementation CEToolbarController

#pragma mark Superclass Methods

// ------------------------------------------------------
/// setup UI
- (void)awakeFromNib
// ------------------------------------------------------
{
    [self buildEncodingPopupButton];
    [self buildSyntaxPopupButton];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(buildSyntaxPopupButton)
                                                 name:CESyntaxListDidUpdateNotification
                                               object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(buildEncodingPopupButton)
                                                 name:CEEncodingListDidUpdateNotification
                                               object:nil];
}


// ------------------------------------------------------
/// clean up
- (void)dealloc
// ------------------------------------------------------
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
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
/// build encoding popup item
- (void)buildEncodingPopupButton
// ------------------------------------------------------
{
    NSArray *items = [[CEEncodingManager sharedManager] encodingMenuItems];
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
/// build syntax style popup menu
- (void)buildSyntaxPopupButton
// ------------------------------------------------------
{
    NSArray *styleNames = [[CESyntaxManager sharedManager] styleNames];
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


// ------------------------------------------------------
/// select item in the syntax style menu
- (void)setSelectedSyntaxWithName:(NSString *)name
// ------------------------------------------------------
{
    [[self syntaxPopupButton] selectItemWithTitle:name];
    if (![[self syntaxPopupButton] selectedItem]) {
        [[self syntaxPopupButton] selectItemAtIndex:0];  // select "None"
    }
}



#pragma mark Delegate


//=======================================================
// Delegate method (NSToolbarDelegate)
//  <== toolbar
//=======================================================

// ------------------------------------------------------
/// set state of toolbar item when it will be added
- (void)toolbarWillAddItem:(NSNotification *)notification
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
- (void)toggleItem:(NSToolbarItem *)item setOn:(BOOL)setOn
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

@end
