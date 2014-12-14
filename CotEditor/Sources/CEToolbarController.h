/*
 ==============================================================================
 CEToolbarController
 
 CotEditor
 http://coteditor.com
 
 Created on 2005-01-07 by nakamuxu
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
};


@interface CEToolbarController : NSObject <NSToolbarDelegate>

// Public method
- (void)toggleItemWithTag:(CEToolbarItemTag)tag setOn:(BOOL)setOn;
- (void)buildEncodingPopupButton;
- (void)setSelectedEncoding:(NSStringEncoding)encoding;
- (void)setSelectedLineEnding:(CENewLineType)lineEnding;
- (void)setSelectedSyntaxWithName:(NSString *)name;

@end
