/*
 ==============================================================================
 CETextFinder
 
 CotEditor
 http://coteditor.com
 
 Created on 2015-01-03 by 1024jp
 encoding="UTF-8"
 ------------------------------------------------------------------------------
 
 © 2015 1024jp
 
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

#import "CETextFinder.h"
#import "constants.h"


NSString *const CETextFinderDidReplaceAllNotification = @"CETextFinderDidReplaceAllNotification";
NSString *const CETextFinderDidUnlighlightNotification = @"CETextFinderDidUnlighlightNotification";


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
                               CEDefaultFindEscapeCharacterKey: [OGRegularExpression defaultEscapeCharacter],
                               CEDefaultFindUsesRegularExpressionKey: @NO,
                               CEDefaultFindInSelectionKey: @NO,
                               CEDefaultFindIsWrapKey: @YES,
                               CEDefaultFindClosesIndicatorWhenDoneKey: @YES,
                               };
    
    [[NSUserDefaults standardUserDefaults] registerDefaults:defaults];
}


// ------------------------------------------------------
/// specify custom find panel nib name
- (NSString *)findPanelNibName
// ------------------------------------------------------
{
    return @"FindPanel";
}

@end
