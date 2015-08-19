/*
 
 CEToolbarController.h
 
 CotEditor
 http://coteditor.com
 
 Created by nakamuxu on 2005-01-07.

 ------------------------------------------------------------------------------
 
 © 2004-2007 nakamuxu
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

@import Cocoa;
#import "NSString+CENewLine.h"


// Toolbar item tag
typedef NS_ENUM(NSInteger, CEToolbarItemTag) {
    CEToolbarLineEndingsItemTag = 1,
    CEToolbarFileEncodingsItemTag,
    CEToolbarSyntaxItemTag,
    CEToolbarGetInfoItemTag,
    CEToolbarShowIncompatibleCharItemTag,
    CEToolbarPrintItemTag,
    CEToolbarFontItemTag,
    CEToolbarBiggerFontItemTag,
    CEToolbarSmallerFontItemTag,
    CEToolbarShiftLeftItemTag,
    CEToolbarShiftRightItemTag,
    CEToolbarToggleCommentItemTag,
    CEToolbarAutoTabExpandItemTag,
    CEToolbarShowNavigationBarItemTag,
    CEToolbarShowLineNumItemTag,
    CEToolbarShowStatusBarItemTag,
    CEToolbarShowInvisibleCharsItemTag,
    CEToolbarShowPageGuideItemTag,
    CEToolbarWrapLinesItemTag,
    CEToolbarTextOrientationItemTag,
    CEToolbarEditColorCodeItemTag,
    CEToolbarSyntaxReColorAllItemTag,
    CEToolbarShareItemTag,
};


@interface CEToolbarController : NSObject <NSToolbarDelegate>

// Public method
- (void)toggleItemWithTag:(CEToolbarItemTag)tag setOn:(BOOL)setOn;
- (void)setSelectedEncoding:(NSStringEncoding)encoding;
- (void)setSelectedLineEnding:(CENewLineType)lineEnding;
- (void)setSelectedSyntaxWithName:(nonnull NSString *)name;

@end
