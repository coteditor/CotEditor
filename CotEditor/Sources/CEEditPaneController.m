/*
 ==============================================================================
 CEEditPaneController
 
 CotEditor
 http://coteditor.com
 
 Created on 2014-04-18 by 1024jp
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

#import "CEEditPaneController.h"
#import "CEUtils.h"
#import "constants.h"


@interface CEEditPaneController ()

@property (nonatomic, weak) IBOutlet NSButton *smartQuoteCheckButton;

@property (nonatomic, copy) NSArray *invisibleSpaces;
@property (nonatomic, copy) NSArray *invisibleTabs;
@property (nonatomic, copy) NSArray *invisibleNewLines;
@property (nonatomic, copy) NSArray *invisibleFullWidthSpaces;

@end




#pragma mark -

@implementation CEEditPaneController

#pragma mark Superclass Methods

//=======================================================
// Superclass method
//
//=======================================================

// ------------------------------------------------------
/// 初期化
- (instancetype)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
// ------------------------------------------------------
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // 不可視文字表示ポップアップ用の選択肢をセットする
        NSMutableArray *spaces = [[NSMutableArray alloc] initWithCapacity:kSizeOfInvisibleSpaceCharList];
        for (NSUInteger i = 0; i < kSizeOfInvisibleSpaceCharList; i++) {
            [spaces addObject:[CEUtils invisibleSpaceCharacter:i]];
        }
        [self setInvisibleSpaces:spaces];
        NSMutableArray *tabs = [[NSMutableArray alloc] initWithCapacity:kSizeOfInvisibleTabCharList];
        for (NSUInteger i = 0; i < kSizeOfInvisibleTabCharList; i++) {
            [tabs addObject:[CEUtils invisibleTabCharacter:i]];
        }
        [self setInvisibleTabs:tabs];
        NSMutableArray *newLines = [[NSMutableArray alloc] initWithCapacity:kSizeOfInvisibleNewLineCharList];
        for (NSUInteger i = 0; i < kSizeOfInvisibleNewLineCharList; i++) {
            [newLines addObject:[CEUtils invisibleNewLineCharacter:i]];
        }
        [self setInvisibleNewLines:newLines];
        NSMutableArray *fullWidthSpaces = [[NSMutableArray alloc] initWithCapacity:kSizeOfInvisibleFullwidthSpaceCharList];
        for (NSUInteger i = 0; i < kSizeOfInvisibleFullwidthSpaceCharList; i++) {
            [fullWidthSpaces addObject:[CEUtils invisibleFullwidthSpaceCharacter:i]];
        }
        _invisibleFullWidthSpaces = fullWidthSpaces;
    }
    return self;
}


// ------------------------------------------------------
/// ビューの読み込み
- (void)loadView
// ------------------------------------------------------
{
    [super loadView];
    
    // Mavericks用の設定をMavericks以下では無効にする
    if (floor(NSAppKitVersionNumber) <= NSAppKitVersionNumber10_8) {
        [[self smartQuoteCheckButton] setEnabled:NO];
        [[self smartQuoteCheckButton] setState:NSOffState];
        [[self smartQuoteCheckButton] setTitle:[NSString stringWithFormat:@"%@%@", [[self smartQuoteCheckButton] title],
                                                NSLocalizedString(@" (on Mavericks and later)", nil)]];
    }
}

@end
