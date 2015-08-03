/*
 
 CELayoutManager.h
 
 CotEditor
 http://coteditor.com
 
 Created by nakamuxu on 2005-01-10.

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


@interface CELayoutManager : NSLayoutManager

@property (nonatomic) BOOL showsInvisibles;
@property (nonatomic) BOOL fixesLineHeight;  // 行高を固定するか
@property (nonatomic) BOOL usesAntialias;  // アンチエイリアスを適用するかどうか
@property (nonatomic, getter=isPrinting) BOOL printing;  // プリンタ中かどうかを（[NSGraphicsContext currentContextDrawingToScreen] は真を返す時があるため、専用フラグを使う）
@property (nonatomic, nullable) NSFont *textFont;

@property (readonly, nonatomic) CGFloat textFontPointSize;
@property (readonly, nonatomic) CGFloat defaultLineHeightForTextFont;  // 表示フォントでの行高


- (CGFloat)lineHeight;

@end
