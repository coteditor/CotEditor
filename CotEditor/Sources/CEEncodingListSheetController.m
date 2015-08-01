/*
 
 CEEncodingListSheetController.m
 
 CotEditor
 http://coteditor.com
 
 Created by 1024jp on 2014-03-26.

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

#import "CEEncodingListSheetController.h"
#import "CEPrefEncodingDataSource.h"


@interface CEEncodingListSheetController ()

@property (nonatomic, nullable, weak) IBOutlet CEPrefEncodingDataSource *dataSource;

@end




#pragma mark -

@implementation CEEncodingListSheetController

#pragma mark Superclass Methods

// ------------------------------------------------------
/// initialize
- (nonnull instancetype)init
// ------------------------------------------------------
{
    return [super initWithWindowNibName:@"EncodingListSheet"];
}



#pragma mark Action Messages

// ------------------------------------------------------
/// OK button was clicked
- (IBAction)save:(nullable id)sender
// ------------------------------------------------------
{
    [[self dataSource] writeToUserDefaults];  // save current setting
    
    [NSApp stopModal];
    [NSApp endSheet:[self window] returnCode:NSOKButton];
    [self close];
}


// ------------------------------------------------------
/// Cancel button was clicked
- (IBAction)cancel:(nullable id)sender
// ------------------------------------------------------
{
    [NSApp stopModal];
    [NSApp endSheet:[self window] returnCode:NSCancelButton];
    [self close];
}

@end
