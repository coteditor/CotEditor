/*
 ==============================================================================
 CESyntaxMappingConflictsSheetController
 
 CotEditor
 http://coteditor.com
 
 Created on 2014-03-25 by 1024jp
 encoding="UTF-8"
 ------------------------------------------------------------------------------
 
 © 2014-2015 1024jp
 
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

@property (nonatomic, nonnull, copy) NSArray *extensionConflicts;
@property (nonatomic, nonnull, copy) NSArray *filenameConflicts;

@end




#pragma mark -

@implementation CESyntaxMappingConflictsSheetController

#pragma mark Superclass Methods

// ------------------------------------------------------
/// initialize
- (nonnull instancetype)init
// ------------------------------------------------------
{
    self = [super initWithWindowNibName:@"SyntaxMappingConflictSheet"];
    if (self) {
        _extensionConflicts = [[self class] parseConflictDict:[[CESyntaxManager sharedManager] extensionConflicts]];
        _filenameConflicts = [[self class] parseConflictDict:[[CESyntaxManager sharedManager] filenameConflicts]];
    }
    return self;
}



#pragma mark Action Messages

// ------------------------------------------------------
/// Done button was clicked
- (IBAction)closeSheet:(id)sender
// ------------------------------------------------------
{
    [NSApp stopModal];
    [NSApp endSheet:[self window]];
    [self close];
}



#pragma mark Private Methods

// ------------------------------------------------------
/// convert conflictDict data for table
+ (NSArray *)parseConflictDict:(NSDictionary *)conflictDict
// ------------------------------------------------------
{
    NSMutableArray *conflicts = [NSMutableArray array];
    for (NSString *key in conflictDict) {
        NSMutableArray *styles = [conflictDict[key] mutableCopy];
        NSString *primaryStyle = [styles firstObject];
        [styles removeObjectIdenticalTo:primaryStyle];
        [conflicts addObject:@{@"name": key,
                               @"primaryStyle": primaryStyle,
                               @"doubledStyles":  [styles componentsJoinedByString:@", "]}];
    }
    
    return [conflicts copy];
}

@end
