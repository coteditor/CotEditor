/*
 =================================================
 CESyntaxExtensionConflictSheetController
 (for CotEditor)
 
 Copyright (C) 2014 CotEditor Project
 http://coteditor.github.io
 =================================================
 
 encoding="UTF-8"
 Created:2014-03-25 by 1024jp
 
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

#import "CESyntaxExtensionConflictSheetController.h"
#import "CESyntaxManager.h"


@interface CESyntaxExtensionConflictSheetController ()

@property (nonatomic) IBOutlet NSArrayController *arrayController;

@end




#pragma mark -

@implementation CESyntaxExtensionConflictSheetController

#pragma mark NSWindowController Methods

// ------------------------------------------------------
/// 初期化
- (instancetype)init
// ------------------------------------------------------
{
    self = [super initWithWindowNibName:@"SyntaxExtensionConflictSheet"];
    if (self) {
        [[self window] setLevel:NSModalPanelWindowLevel];
    }
    return self;
}


// ------------------------------------------------------
/// Nibファイル読み込み直後
- (void)awakeFromNib
// ------------------------------------------------------
{
    [self setupErrorDict];
}



#pragma mark Action Messages

// ------------------------------------------------------
/// シートの Done ボタンが押された
- (IBAction)closeSheet:(id)sender
// ------------------------------------------------------
{
    [NSApp stopModal];
}



#pragma mark Private Methods

//------------------------------------------------------
/// シートに表示するエラー内容をセット
- (void)setupErrorDict
//------------------------------------------------------
{
    NSDictionary *errorDict = [[CESyntaxManager sharedManager] extensionConflicts];
    
    NSMutableArray *objects = [NSMutableArray array];
    for (id key in errorDict) {
        NSMutableArray *styles = [errorDict[key] mutableCopy];
        NSString *primaryStyle = styles[0];
        [styles removeObjectAtIndex:0];
        [objects addObject:@{@"extension": key,
                             @"primaryStyle": primaryStyle,
                             @"doubledStyles":  [styles componentsJoinedByString:@", "]}];
    }
    
    [[self arrayController] setContent:objects];
}

@end
