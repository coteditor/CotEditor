/*
 ==============================================================================
 CEPrintView
 
 CotEditor
 http://coteditor.github.io
 
 Created on 2005-10-01 by nakamuxu
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
#import "CETextViewProtocol.h"
#import "CEPrintPanelAccessoryController.h"


@interface CEPrintView : NSTextView <CETextViewProtocol>

@property (nonatomic) CEPrintPanelAccessoryController *printPanelAccessoryController;

@property (nonatomic, copy) NSString *filePath;
@property (nonatomic, copy) NSString *documentName;
@property (nonatomic, copy) NSString *syntaxName;
@property (nonatomic) CGFloat lineSpacing;
@property (nonatomic) CETheme *theme;

// settings on current window to be set by CEDocument.
// These values are used if set option is "Same as document's setting"
@property (nonatomic) BOOL documentShowsLineNum;
@property (nonatomic) BOOL documentShowsInvisibles;

@end
