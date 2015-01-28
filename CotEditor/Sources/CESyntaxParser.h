/*
 ==============================================================================
 CESyntaxParser
 
 CotEditor
 http://coteditor.com
 
 Created on 2004-12-22 by nakamuxu
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


@class CELayoutManager;


@interface CESyntaxParser : NSObject

// readonly
@property (readonly, nonatomic, copy) NSString *styleName;
@property (readonly, nonatomic, copy) NSArray *completionWords;  // 入力補完文字列配列
@property (readonly, nonatomic, copy) NSCharacterSet *firstCompletionCharacterSet;  // 入力補完の最初の1文字のセット
@property (readonly, nonatomic, copy) NSString *inlineCommentDelimiter;
@property (readonly, nonatomic, copy) NSDictionary *blockCommentDelimiters;
@property (readonly, nonatomic, getter=isNone) BOOL none;


/// designated initializer (return nil if no corresponded style dictionary can be found.)
- (instancetype)initWithStyleName:(NSString *)styleName layoutManager:(CELayoutManager *)layoutManager NS_DESIGNATED_INITIALIZER;

// Public methods
- (void)colorAllString:(NSString *)wholeString;
- (void)colorRange:(NSRange)range wholeString:(NSString *)wholeString;
- (NSArray *)outlineMenuArrayWithWholeString:(NSString *)wholeString;

@end
