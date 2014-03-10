/*
=================================================
CELayoutManager
(for CotEditor)

 Copyright (C) 2004-2007 nakamuxu.
 Copyright (C) 2014 CotEditor Project
 http://coteditor.github.io
=================================================

encoding="UTF-8"
Created:2005.01.10

------------
This class is based on Smultron - SMLLayoutManager (written by Peter Borg – http://smultron.sourceforge.net)
Smultron  Copyright (c) 2004 Peter Borg, All rights reserved.
Smultron is released under GNU General Public License, http://www.gnu.org/copyleft/gpl.html
arranged by nakamuxu, Jan 2005.
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
#import "CEATSTypesetter.h"
#import "CEPrivateMutableArray.h"


@interface CELayoutManager : NSLayoutManager

@property (nonatomic, assign) BOOL showInvisibles;
@property (nonatomic, assign) BOOL showSpace;
@property (nonatomic, assign) BOOL showTab;
@property (nonatomic, assign) BOOL showNewLine;
@property (nonatomic, assign) BOOL showFullwidthSpace;
@property (nonatomic, assign) BOOL showOtherInvisibles;

@property (nonatomic, assign) BOOL fixLineHeight;  // 行高を固定するか
@property (nonatomic, assign) BOOL useAntialias;  // アンチエイリアスを適用するかどうか
@property (nonatomic, assign) BOOL isPrinting;  // プリンタ中かどうかを（[NSGraphicsContext currentContextDrawingToScreen] は真を返す時があるため、専用フラグを使う）
@property (nonatomic, retain) NSFont *textFont;

@property (nonatomic, assign, readonly) CGFloat textFontPointSize;
@property (nonatomic, assign, readonly) CGFloat defaultLineHeightForTextFont;  // 表示フォントでの行高
@property (nonatomic, assign, readonly) CGFloat textFontGlyphY;  // 表示フォントグリフのY位置を返す


- (void)setValuesForTextFont:(NSFont *)font;
- (CGFloat)lineHeight;

@end
