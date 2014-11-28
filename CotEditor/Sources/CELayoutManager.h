/*
 ==============================================================================
 CELayoutManager
 
 CotEditor
 http://coteditor.com
 
 Created on 2005-01-10 by nakamuxu
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


@interface CELayoutManager : NSLayoutManager

@property (nonatomic) BOOL showsInvisibles;
@property (nonatomic) BOOL fixesLineHeight;  // 行高を固定するか
@property (nonatomic) BOOL usesAntialias;  // アンチエイリアスを適用するかどうか
@property (nonatomic, getter=isPrinting) BOOL printing;  // プリンタ中かどうかを（[NSGraphicsContext currentContextDrawingToScreen] は真を返す時があるため、専用フラグを使う）
@property (nonatomic) NSFont *textFont;

@property (readonly, nonatomic) CGFloat textFontPointSize;
@property (readonly, nonatomic) CGFloat defaultLineHeightForTextFont;  // 表示フォントでの行高
@property (readonly, nonatomic) CGFloat textFontGlyphY;  // 表示フォントグリフのY位置を返す


- (void)setValuesForTextFont:(NSFont *)font;
- (CGFloat)lineHeight;

@end
