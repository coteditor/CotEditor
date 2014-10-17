/*
 ==============================================================================
 CEToolbarController
 
 CotEditor
 http://coteditor.github.io
 
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
@property (nonatomic, strong) IBOutlet CEWindowController *windowController;  // Cannot be weak on Lion
@property (nonatomic, weak) IBOutlet NSPopUpButton *lineEndingPopupButton;
@property (nonatomic, weak) IBOutlet NSPopUpButton *encodingPopupButton;
@property (nonatomic, weak) IBOutlet NSPopUpButton *syntaxPopupButton;

@end




#pragma mark -

@implementation CEToolbarController

#pragma mark Public Method

//=======================================================
// Public method
//
//=======================================================

// ------------------------------------------------------
/// 後片付け
- (void)dealloc
// ------------------------------------------------------
{
    _windowController = nil;  // for Lion
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}


// ------------------------------------------------------
/// トグルアイテムの状態を更新
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
/// エンコーディングポップアップアイテムを生成
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
/// エンコーディングポップアップの選択項目を設定
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
/// 改行コードポップアップの選択項目を設定
- (void)setSelectedLineEnding:(CELineEnding)lineEnding
// ------------------------------------------------------
{
    if (lineEnding >= [[self lineEndingPopupButton] numberOfItems]) { return; }

    [[self lineEndingPopupButton] selectItemAtIndex:lineEnding];
}


// ------------------------------------------------------
/// シンタックスカラーリングポップアップアイテムを生成
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
/// シンタックスカラーリングポップアップの選択項目をタイトル名で設定
- (void)setSelectedSyntaxWithName:(NSString *)name
// ------------------------------------------------------
{
    [[self syntaxPopupButton] selectItemWithTitle:name];
    if (![[self syntaxPopupButton] selectedItem]) {
        [[self syntaxPopupButton] selectItemAtIndex:0];  // select "None"
    }
}



#pragma mark Protocol

//=======================================================
// NSNibAwaking Protocol
//
//=======================================================

// ------------------------------------------------------
/// Nibファイル読み込み直後
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


//=======================================================
// Delegate method (NSToolbarDelegate)
//  <== toolbar
//=======================================================

// ------------------------------------------------------
/// ツールバーアイテムの状態を設定
- (void)toolbarWillAddItem:(NSNotification *)notification
// ------------------------------------------------------
{
    NSToolbarItem *item = [notification userInfo][@"item"];
    CEEditorWrapper *editor = [[self windowController] editor];
    
    switch ([item tag]) {
        case CEToolbarShowInvisibleCharsItemTag:
            [self toggleItem:item setOn:[editor showsInvisibles]];
            
            // ツールバーアイテムを有効化できなければボタンを無効状態に
            if ([editor canActivateShowInvisibles]) {
                [item setAction:@selector(toggleInvisibleChars:)];
                [item setToolTip:NSLocalizedString(@"Show or hide invisible characters in document", nil)];
            } else {
                [item setAction:nil];
                [item setToolTip:NSLocalizedString(@"To display invisible characters, set in Preferences and re-open the document.", nil)];
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

//=======================================================
// Private method
//
//=======================================================

// ------------------------------------------------------
/// トグルアイテムの状態を更新
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
