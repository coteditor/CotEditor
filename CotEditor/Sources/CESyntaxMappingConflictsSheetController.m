/*
 
 CESyntaxMappingConflictsSheetController.m
 
 CotEditor
 http://coteditor.com
 
 Created by 1024jp on 2014-03-25.

 ------------------------------------------------------------------------------
 
 © 2014-2015 1024jp
 
 Licensed under the Apache License, Version 2.0 (the "License");
 you may not use this file except in compliance with the License.
 You may obtain a copy of the License at
 
 http://www.apache.org/licenses/LICENSE-2.0
 
 Unless required by applicable law or agreed to in writing, software
 distributed under the License is distributed on an "AS IS" BASIS,
 WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 See the License for the specific language governing permissions and
 limitations under the License.
 
 */

#import "CESyntaxMappingConflictsSheetController.h"
#import "CESyntaxManager.h"


@interface CESyntaxMappingConflictsSheetController ()

@property (nonatomic, nonnull, copy) NSArray<NSDictionary<NSString *, NSString *> *> *extensionConflicts;
@property (nonatomic, nonnull, copy) NSArray<NSDictionary<NSString *, NSString *> *> *filenameConflicts;

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
- (IBAction)closeSheet:(nullable id)sender
// ------------------------------------------------------
{
    [NSApp stopModal];
    [NSApp endSheet:[self window]];
    [self close];
}



#pragma mark Private Methods

// ------------------------------------------------------
/// convert conflictDict data for table
+ (nonnull NSArray<NSDictionary<NSString *, NSString *> *> *)parseConflictDict:(nonnull NSDictionary *)conflictDict
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
