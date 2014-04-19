/*
 =================================================
 CEEditPaneController
 (for CotEditor)
 
 Copyright (C) 2004-2007 nakamuxu.
 Copyright (C) 2014 CotEditor Project
 http://coteditor.github.io
 =================================================
 
 encoding="UTF-8"
 Created:2014-04-18
 
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

#import "CEEditPaneController.h"
#import "CEDocument.h"
#import "CEUtilities.h"
#import "constants.h"


@interface CEEditPaneController ()

@property (nonatomic, weak) IBOutlet NSButton *smartQuoteCheckButton;

@property (nonatomic) NSArray *invisibleSpaces;
@property (nonatomic) NSArray *invisibleTabs;
@property (nonatomic) NSArray *invisibleNewLines;
@property (nonatomic) NSArray *invisibleFullWidthSpaces;

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
- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
// ------------------------------------------------------
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // 不可視文字表示ポップアップ用の選択肢をセットする
        NSUInteger i;
        NSMutableArray *spaces = [NSMutableArray array];
        for (i = 0; i < (sizeof(k_invisibleSpaceCharList) / sizeof(unichar)); i++) {
            [spaces addObject:[CEUtilities invisibleSpaceCharacter:i]];
        }
        [self setInvisibleSpaces:spaces];
        NSMutableArray *tabs = [NSMutableArray array];
        for (i = 0; i < (sizeof(k_invisibleTabCharList) / sizeof(unichar)); i++) {
            [tabs addObject:[CEUtilities invisibleTabCharacter:i]];
        }
        [self setInvisibleTabs:tabs];
        NSMutableArray *newLines = [NSMutableArray array];
        for (i = 0; i < (sizeof(k_invisibleNewLineCharList) / sizeof(unichar)); i++) {
            [newLines addObject:[CEUtilities invisibleNewLineCharacter:i]];
        }
        [self setInvisibleNewLines:newLines];
        NSMutableArray *fullWidthSpaces = [NSMutableArray array];
        for (i = 0; i < (sizeof(k_invisibleFullwidthSpaceCharList) / sizeof(unichar)); i++) {
            [fullWidthSpaces addObject:[CEUtilities invisibleFullwidthSpaceCharacter:i]];
        }
        [self setInvisibleFullWidthSpaces:fullWidthSpaces];
    }
    return self;
}


// ------------------------------------------------------
/// Nibファイル読み込み直後
- (void)awakeFromNib
// ------------------------------------------------------
{
    // Mavericks用の設定をMavericks以下では無効にする
    if (floor(NSAppKitVersionNumber) <= NSAppKitVersionNumber10_8) {
        [[self smartQuoteCheckButton] setEnabled:NO];
        [[self smartQuoteCheckButton] setState:NSOffState];
        [[self smartQuoteCheckButton] setTitle:[NSString stringWithFormat:@"%@%@", [[self smartQuoteCheckButton] title],
                                                NSLocalizedString(@" (on Mavericks and later)", nil)]];
    }
}



#pragma mark Action Messages

//=======================================================
// Action messages
//
//=======================================================

// ------------------------------------------------------
/// すべてのテキストビューのスマートインサート／デリート実行を設定
- (IBAction)setSmartInsertAndDeleteToAllTextView:(id)sender
// ------------------------------------------------------
{
    BOOL isEnabled = [[NSUserDefaults standardUserDefaults] boolForKey:k_key_smartInsertAndDelete];
    
    for (CEDocument *document in [NSApp orderedDocuments]) {
        [[[[document windowController] editorView] textView] setSmartInsertDeleteEnabled:isEnabled];
    }
}


// ------------------------------------------------------
/// すべてのテキストビューのスマート引用符／ダッシュ実行を設定
- (IBAction)setSmartQuotesToAllTextView:(id)sender
// ------------------------------------------------------
{
    BOOL isEnabled = [[NSUserDefaults standardUserDefaults] boolForKey:k_key_enableSmartQuotes];
    
    for (CEDocument *document in [NSApp orderedDocuments]) {
        [[[[document windowController] editorView] textView] setAutomaticDashSubstitutionEnabled:isEnabled];
        [[[[document windowController] editorView] textView] setAutomaticQuoteSubstitutionEnabled:isEnabled];
    }
}

@end
