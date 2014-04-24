/*
 =================================================
 CEScriptErrorPanelController
 (for CotEditor)
 
 Copyright (C) 2014 CotEditor Project
 http://coteditor.github.io
 =================================================
 
 encoding="UTF-8"
 Created:2014-03-27 by 1024jp
 
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

#import "CEScriptErrorPanelController.h"


@interface CEScriptErrorPanelController ()

@property (nonatomic, strong) IBOutlet NSTextView *textView;  // on 10.8 NSTextView cannot be weak

@end




#pragma mark -

@implementation CEScriptErrorPanelController

#pragma mark Superclass Mthods

// ------------------------------------------------------
/// initializer of panelController
- (instancetype)init
// ------------------------------------------------------
{
    self = [super initWithWindowNibName:@"ScriptErrorPanel"];
    
    return self;
}


// ------------------------------------------------------
/// Scriptエラーログを追加する
- (void)awakeFromNib
// ------------------------------------------------------
{
    [[self textView] setFont:[NSFont messageFontOfSize:10]];
}



#pragma mark Public Methods

// ------------------------------------------------------
/// Scriptエラーログを追加する
- (void)addErrorString:(NSString *)string
// ------------------------------------------------------
{
    [[self textView] setEditable:YES];
    [[self textView] setSelectedRange:NSMakeRange([[[self textView] string] length], 0)];
    [[self textView] insertText:string];
    [[self textView] setEditable:NO];
}



#pragma mark Action Messages

// ------------------------------------------------------
/// Scriptエラーログを削除
- (IBAction)cleanScriptError:(id)sender
// ------------------------------------------------------
{
    [[self textView] setString:@""];
}

@end
