/*
 =================================================
 CEPrintAccessoryViewController
 (for CotEditor)
 
 Copyright (C) 2014 CotEditor Project
 http://coteditor.github.io
 =================================================
 
 encoding="UTF-8"
 Created:2014-03-24 by 1024jp
 
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

#import "CEPrintPanelAccessoryController.h"
#import "constants.h"


@interface CEPrintPanelAccessoryController ()

@property (nonatomic) IBOutlet NSObjectController *settingController;

@end



#pragma mark -

@implementation CEPrintPanelAccessoryController

#pragma mark NSViewController Methods

//=======================================================
// NSViewController Protocol
//
//=======================================================

// ------------------------------------------------------
- (void)loadView
// ビューのロード
// ------------------------------------------------------
{
    [super loadView];
    
    // 設定をセットアップ（ユーザデフォルトからローカル設定にコピー）
    // （プリンタ専用フォント設定は含まない。プリンタ専用フォント設定変更は、プリンタダイアログでは実装しない 20060927）
    NSArray *keys = @[k_printHeader,
                      k_headerOneStringIndex,
                      k_headerTwoStringIndex,
                      k_headerOneAlignIndex,
                      k_headerTwoAlignIndex,
                      k_printHeaderSeparator,
                      k_printFooter,
                      k_footerOneStringIndex,
                      k_footerTwoStringIndex,
                      k_footerOneAlignIndex,
                      k_footerTwoAlignIndex,
                      k_printFooterSeparator,
                      k_printLineNumIndex,
                      k_printInvisibleCharIndex,
                      k_printColorIndex];
    NSDictionary *settings = [[NSUserDefaults standardUserDefaults] dictionaryWithValuesForKeys:keys];
    
    [[self settingController] setContent:[settings mutableCopy]];
}



#pragma mark Protocol

//=======================================================
// NSPrintPanelAccessorizing Protocol
//
//=======================================================

// ------------------------------------------------------
-(NSArray *)localizedSummaryItems
//
// ------------------------------------------------------
{
    return nil;
}



#pragma mark Public Methods

//=======================================================
// Public method
//
//=======================================================

// ------------------------------------------------------
- (id)values
// プリンタローカル設定オブジェクトを返す
// ------------------------------------------------------
{
    return [[self settingController] content];
}

@end
