/*
=================================================
CEPrintView
(for CotEditor)

Copyright (C) 2004-2007 nakamuxu.
http://www.aynimac.com/
=================================================

encoding="UTF-8"
Created:2005.10.01

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

#import <Cocoa/Cocoa.h>
#import "constants.h"


@interface CEPrintView : NSTextView
{
    NSString *_filePath;
    NSDictionary *_lineNumAttrs;
    NSDictionary *_headerFooterAttrs;
    id _printValues;
    NSAttributedString *_headerOneString;
    NSAttributedString *_headerTwoString;
    NSAttributedString *_footerOneString;
    NSAttributedString *_footerTwoString;
    NSInteger _headerOneAlignment;
    NSInteger _headerTwoAlignment;
    NSInteger _footerOneAlignment;
    NSInteger _footerTwoAlignment;
    CGFloat _lineSpacing;
    CGFloat _xOffset;
    BOOL _readyToPrint;
    BOOL _printLineNum;
    BOOL _printHeader;
    BOOL _printFooter;
    BOOL _printHeaderSeparator;
    BOOL _printFooterSeparator;
    BOOL _readyToDrawPageNum;
    BOOL _showingLineNum;
}

// Public method
- (void)setFilePath:(NSString *)inFilePath;
- (CGFloat)lineSpacing;
- (void)setLineSpacing:(CGFloat)inLineSpacing;
- (id)printValues;
- (void)setPrintValues:(id)inValues;
- (BOOL)isShowingLineNum;
- (void)setIsShowingLineNum:(BOOL)inValue;

@end
