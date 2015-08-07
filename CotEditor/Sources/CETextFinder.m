/*
 
 CETextFinder.m
 
 CotEditor
 http://coteditor.com
 
 Created by 1024jp on 2015-01-03.

 ------------------------------------------------------------------------------
 
 © 2015 1024jp
 
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

#import "CETextFinder.h"
#import "Constants.h"


NSString *__nonnull const CETextFinderDidReplaceAllNotification = @"CETextFinderDidReplaceAllNotification";
NSString *__nonnull const CETextFinderDidUnhighlightNotification = @"CETextFinderDidUnhighlightNotification";


@implementation CETextFinder

#pragma mark Superclass Methods

// ------------------------------------------------------
/// register default setting for find panel
+ (void)initialize
// ------------------------------------------------------
{
    [super initialize];
    
    // register defaults for find panel here
    // sicne CEFindPanelController can be initialized before registering user defaults in CEAppDelegate. (2015-01 by 1024jp)
    NSDictionary *defaults = @{CEDefaultFindHistoryKey: @[],
                               CEDefaultReplaceHistoryKey: @[],
                               CEDefaultFindRegexSyntaxKey: @([OGRegularExpression defaultSyntax]),
                               CEDefaultFindOptionsKey: @(OgreCaptureGroupOption),
                               CEDefaultFindUsesRegularExpressionKey: @NO,
                               CEDefaultFindInSelectionKey: @NO,
                               CEDefaultFindIsWrapKey: @YES,
                               CEDefaultFindNextAfterReplaceKey: @YES,
                               CEDefaultFindClosesIndicatorWhenDoneKey: @YES,
                               };
    
    [[NSUserDefaults standardUserDefaults] registerDefaults:defaults];
}


// ------------------------------------------------------
/// specify custom find panel nib name
- (nonnull NSString *)findPanelNibName
// ------------------------------------------------------
{
    return @"FindPanel";
}

@end
