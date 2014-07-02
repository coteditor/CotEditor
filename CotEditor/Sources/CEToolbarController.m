/*
=================================================
CEToolbarController
(for CotEditor)

 Copyright (C) 2004-2007 nakamuxu.
 Copyright (C) 2014 CotEditor Project
 http://coteditor.github.io
=================================================

encoding="UTF-8"
Created:2005.01.07
 
-------------------------------------------------

This program is free software; you can redistribute it and/or
modify it under the terms of the GNU General Public License
as published by the Free Software Foundation; either version 2
of the License, or (at your option) any later version.

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU General Public License for more details.

You should have received a copy of the GNU General Public License
along with this program; if not, write to the Free Software
Foundation, Inc., 59 Temple Place - Suite 330, Boston, MA  02111-1307, USA. 


=================================================
*/

#import "CEToolbarController.h"
#import "CEDocument.h"
#import "constants.h"


@interface CEToolbarController ()

@property (nonatomic, weak) IBOutlet NSToolbar *toolbar;
@property (nonatomic, unsafe_unretained) IBOutlet NSWindow *window;  // NSWindow は 10.7 では weak で持てないため
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
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}


// ------------------------------------------------------
/// トグルアイテムの状態を更新
- (void)toggleItemWithIdentifier:(NSString *)identifer setOn:(BOOL)setOn
// ------------------------------------------------------
{
    for (NSToolbarItem *item in [[self toolbar] items]) {
        if ([[item itemIdentifier] isEqualToString:identifer]) {
            [self toggleItem:item setOn:setOn];
            break;
        }
    }
}


// ------------------------------------------------------
/// エンコーディングポップアップアイテムを生成
- (void)buildEncodingPopupButton
// ------------------------------------------------------
{
    NSArray *items = [[NSArray alloc] initWithArray:[(CEAppDelegate *)[NSApp delegate] encodingMenuItems] copyItems:YES];
    
    [[self encodingPopupButton] removeAllItems];
    for (NSMenuItem *item in items) {
        [item setAction:@selector(setEncoding:)];
        [item setTarget:nil];
        [[[self encodingPopupButton] menu] addItem:item];
    }
}


// ------------------------------------------------------
/// エンコーディングポップアップの選択項目を設定
- (void)setSelectEncoding:(NSInteger)encoding
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
- (void)setSelectEndingItemIndex:(NSInteger)index
// ------------------------------------------------------
{
    NSInteger max = [[[self lineEndingPopupButton] itemArray] count];
    if ((index < 0) || (index >= max)) { return; }

    [[self lineEndingPopupButton] selectItemAtIndex:index];
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
    
    [self selectSyntaxItemWithTitle:title];
}


// ------------------------------------------------------
/// シンタックスカラーリングポップアップの選択項目をタイトル名で設定
- (void)selectSyntaxItemWithTitle:(NSString *)title
// ------------------------------------------------------
{
    NSMenuItem *menuItem = [[self syntaxPopupButton] itemWithTitle:title];
    if (menuItem) {
        [[self syntaxPopupButton] selectItem:menuItem];
    } else {
        [[self syntaxPopupButton] selectItemAtIndex:0]; // "None" を選択
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
    for (NSToolbarItem *item in [[self toolbar] items]) {
        NSString *identifier = [item itemIdentifier];
        NSString *toggleKey = nil;
        
        if ([identifier isEqualToString:k_showInvisibleCharsItemID]) {
            // Show Invisible Characters
            BOOL canActivate = [[[[self window] windowController] document] canActivateShowInvisibleCharsItem];
            
            // ツールバーアイテムを有効化できなければツールチップを変更
            if (canActivate) {
                [item setToolTip:NSLocalizedString(@"Show or hide invisible characters in text",@"")];
                [self toggleItem:item setOn:YES];
                [item setAction:@selector(toggleShowInvisibleChars:)];
            } else {
                [item setToolTip:NSLocalizedString(@"To display invisible characters, set in Preferences and re-open the document.",@"")];
                [self toggleItem:item setOn:NO];
                [item setAction:nil];
            }
            
        } else if ([identifier isEqualToString:k_autoTabExpandItemID]) {
            toggleKey = k_key_autoExpandTab;
            
        } else if ([identifier isEqualToString:k_showNavigationBarItemID]) {
            toggleKey = k_key_showNavigationBar;
            
        } else if ([identifier isEqualToString:k_showLineNumItemID]) {
            toggleKey = k_key_showLineNumbers;
            
        } else if ([identifier isEqualToString:k_showStatusBarItemID]) {
            toggleKey = k_key_showStatusBar;
            
        } else if ([identifier isEqualToString:k_showPageGuideItemID]) {
            toggleKey = k_key_showPageGuide;
            
        } else if ([identifier isEqualToString:k_wrapLinesItemID]) {
            toggleKey = k_key_wrapLines;
        }
        
        if (toggleKey) {
            [self toggleItem:item setOn:[[NSUserDefaults standardUserDefaults] boolForKey:toggleKey]];
        }
    }
    
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
    NSString *identifer = [item itemIdentifier];
    NSString *imageName;
    if ([identifer isEqualToString:k_showNavigationBarItemID]) {
        imageName = setOn ? @"NaviBar_Show" : @"NaviBar_Hide";
        
    } else if ([identifer isEqualToString:k_showLineNumItemID]) {
        imageName = setOn ? @"LineNumber_Show" : @"LineNumber_Hide";
        
    } else if ([identifer isEqualToString:k_showStatusBarItemID]) {
        imageName = setOn ? @"StatusArea_Show" : @"StatusArea_Hide";
        
    } else if ([identifer isEqualToString:k_showInvisibleCharsItemID]) {
        imageName = setOn ? @"InvisibleChar_Show" : @"InvisibleChar_Hide";
        
    } else if ([identifer isEqualToString:k_showPageGuideItemID]) {
        imageName = setOn ? @"PageGuide_Show" : @"PageGuide_Hide";
        
    } else if ([identifer isEqualToString:k_wrapLinesItemID]) {
        imageName = setOn ? @"WrapLines_On" : @"WrapLines_Off";
        
    } else if ([identifer isEqualToString:k_autoTabExpandItemID]) {
        imageName = setOn ? @"AutoTabExpand_On" : @"AutoTabExpand_Off";
    }
    
    if (imageName) {
        [item setImage:[NSImage imageNamed:imageName]];
    }
}

@end
