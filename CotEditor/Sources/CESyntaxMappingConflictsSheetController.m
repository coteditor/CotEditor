/*
 ==============================================================================
 CESyntaxMappingConflictsSheetController
 
 CotEditor
 http://coteditor.com
 
 Created on 2014-03-25 by 1024jp
 encoding="UTF-8"
 ------------------------------------------------------------------------------
 
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

#import "CESyntaxMappingConflictsSheetController.h"
#import "CESyntaxManager.h"


@interface CESyntaxMappingConflictsSheetController ()

@property (nonatomic, copy) NSArray *extensionConflicts;
@property (nonatomic, copy) NSArray *filenameConflicts;

@end




#pragma mark -

@implementation CESyntaxMappingConflictsSheetController

#pragma mark NSWindowController Methods

// ------------------------------------------------------
/// 初期化
- (instancetype)init
// ------------------------------------------------------
{
    self = [super initWithWindowNibName:@"SyntaxMappingConflictSheet"];
    if (self) {
        [[self window] setLevel:NSModalPanelWindowLevel];
        
        [self setExtensionConflicts:[[self class] parseConflictDict:[[CESyntaxManager sharedManager] extensionConflicts]]];
        [self setFilenameConflicts:[[self class] parseConflictDict:[[CESyntaxManager sharedManager] filenameConflicts]]];
    }
    return self;
}



#pragma mark Action Messages

// ------------------------------------------------------
/// シートの Done ボタンが押された
- (IBAction)closeSheet:(id)sender
// ------------------------------------------------------
{
    [NSApp stopModal];
    [NSApp endSheet:[self window]];
    [self close];
}



#pragma mark Private Methods

// ------------------------------------------------------
/// conflictDict をテーブル用に変換
+ (NSArray *)parseConflictDict:(NSDictionary *)conflictDict
// ------------------------------------------------------
{
    NSMutableArray *conflicts = [NSMutableArray array];
    for (NSString *key in conflictDict) {
        NSMutableArray *styles = [conflictDict[key] mutableCopy];
        NSString *primaryStyle = styles[0];
        [styles removeObjectAtIndex:0];
        [conflicts addObject:@{@"name": key,
                               @"primaryStyle": primaryStyle,
                               @"doubledStyles":  [styles componentsJoinedByString:@", "]}];
    }
    
    return conflicts;
}

@end
