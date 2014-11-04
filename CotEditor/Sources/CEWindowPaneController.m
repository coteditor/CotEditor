/*
 ==============================================================================
 CEWindowPaneController
 
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

#import "CEWindowPaneController.h"
#import "CESizeSampleWindowController.h"
#import "constants.h"


@interface CEWindowPaneController ()

@property (nonatomic, getter=isViewOpaque) BOOL viewOpaque;

@end




#pragma mark -

@implementation CEWindowPaneController

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
        _viewOpaque = ([[NSUserDefaults standardUserDefaults] doubleForKey:CEDefaultWindowAlphaKey] == 1.0);
    }
    return self;
}



#pragma mark Action Messages

//=======================================================
// Action messages
//
//=======================================================

// ------------------------------------------------------
/// ビューの不透明度設定が変更された
- (IBAction)changeViewOpaque:(id)sender
// ------------------------------------------------------
{
    [self setViewOpaque:([sender doubleValue] == 1.0)];
}


// ------------------------------------------------------
/// サイズ設定のためのサンプルウィンドウを開く
- (IBAction)openSizeSampleWindow:(id)sender
// ------------------------------------------------------
{
    // モーダルで表示
    CESizeSampleWindowController *sampleWindowController = [[CESizeSampleWindowController alloc] initWithWindowNibName:@"SizeSampleWindow"];
    [sampleWindowController showWindow:sender];
    [NSApp runModalForWindow:[sampleWindowController window]];
    
    [[[self view] window] makeKeyAndOrderFront:self];
}

@end
