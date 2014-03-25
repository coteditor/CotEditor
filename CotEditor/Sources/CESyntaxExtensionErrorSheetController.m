/*
 =================================================
 CESyntaxExtensionErrosSheetController
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

#import "CESyntaxExtensionErrorSheetController.h"
#import "CESyntaxManager.h"


@interface CESyntaxExtensionErrorSheetController ()

@property (nonatomic) IBOutlet NSArrayController *arrayController;

@end




#pragma mark -

@implementation CESyntaxExtensionErrorSheetController

#pragma mark NSWindowController Methods

// ------------------------------------------------------
- (instancetype)init
// 初期化
// ------------------------------------------------------
{
    self = [super initWithWindowNibName:@"SyntaxExtensionErrorSheet"];
    if (self) {
        [[self window] setLevel:NSModalPanelWindowLevel];
    }
    return self;
}


// ------------------------------------------------------
- (void)awakeFromNib
// Nibファイル読み込み直後
// ------------------------------------------------------
{
    [self setupErrorDict];
}



#pragma mark Action Messages

// ------------------------------------------------------
- (IBAction)closeSheet:(id)sender
// シートの Done ボタンが押された
// ------------------------------------------------------
{
    [NSApp stopModal];
}



#pragma mark Private Methods

//------------------------------------------------------
- (void)setupErrorDict
// シートに表示するエラー内容をセット
//------------------------------------------------------
{
    NSDictionary *errorDict = [[CESyntaxManager sharedInstance] extensionErrors];
    
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
