/*
 ==============================================================================
 CEPrintAccessoryViewController
 
 CotEditor
 http://coteditor.com
 
 Created on 2014-03-24 by 1024jp
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

@import Cocoa;
#import "constants.h"


@interface CEPrintPanelAccessoryController : NSViewController <NSPrintPanelAccessorizing>

@property (readonly, nonatomic, nonnull) NSString *theme;
@property (readonly, nonatomic) CELineNumberPrintMode lineNumberMode;
@property (readonly, nonatomic) CEInvisibleCharsPrintMode invisibleCharsMode;

@property (readonly, nonatomic) BOOL printsHeader;
@property (readonly, nonatomic) CEPrintInfoType headerOneInfoType;
@property (readonly, nonatomic) CEAlignmentType headerOneAlignmentType;
@property (readonly, nonatomic) CEPrintInfoType headerTwoInfoType;
@property (readonly, nonatomic) CEAlignmentType headerTwoAlignmentType;
@property (readonly, nonatomic) BOOL printsHeaderSeparator;

@property (readonly, nonatomic) BOOL printsFooter;
@property (readonly, nonatomic) CEPrintInfoType footerOneInfoType;
@property (readonly, nonatomic) CEAlignmentType footerOneAlignmentType;
@property (readonly, nonatomic) CEPrintInfoType footerTwoInfoType;
@property (readonly, nonatomic) CEAlignmentType footerTwoAlignmentType;
@property (readonly, nonatomic) BOOL printsFooterSeparator;

@end
