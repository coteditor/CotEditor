/*
 =================================================
 CEPrintAccessoryViewController
 (for CotEditor)
 
 Copyright (C) 2014 CotEditor Project
 http://coteditor.github.io
 =================================================
 
 encoding="UTF-8"
 Created:2014-03-24 by 1024jp
 
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

@import Cocoa;
#import "constants.h"


@interface CEPrintPanelAccessoryController : NSViewController <NSPrintPanelAccessorizing>

@property (nonatomic, readonly) NSString *theme;
@property (nonatomic, readonly) CELineNumberPrintMode lineNumberMode;
@property (nonatomic, readonly) CEInvisibleCharsPrintMode invisibleCharsMode;

@property (nonatomic, readonly) BOOL printsHeader;
@property (nonatomic, readonly) CEPrintInfoType headerOneInfoType;
@property (nonatomic, readonly) CEAlignmentType headerOneAlignmentType;
@property (nonatomic, readonly) CEPrintInfoType headerTwoInfoType;
@property (nonatomic, readonly) CEAlignmentType headerTwoAlignmentType;
@property (nonatomic, readonly) BOOL printsHeaderSeparator;

@property (nonatomic, readonly) BOOL printsFooter;
@property (nonatomic, readonly) CEPrintInfoType footerOneInfoType;
@property (nonatomic, readonly) CEAlignmentType footerOneAlignmentType;
@property (nonatomic, readonly) CEPrintInfoType footerTwoInfoType;
@property (nonatomic, readonly) CEAlignmentType footerTwoAlignmentType;
@property (nonatomic, readonly) BOOL printsFooterSeparator;

@end
