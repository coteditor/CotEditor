/*
 ==============================================================================
 CESyntaxParser
 
 CotEditor
 http://coteditor.com
 
 Created on 2004-12-22 by nakamuxu
 encoding="UTF-8"
 ------------------------------------------------------------------------------
 
 © 2004-2007 nakamuxu
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


@interface CESyntaxParser : NSObject

// readonly
@property (readonly, nonatomic, nonnull, copy) NSString *styleName;
@property (readonly, nonatomic, nullable, copy) NSArray *completionWords;  // 入力補完文字列配列
@property (readonly, nonatomic, nullable, copy) NSCharacterSet *firstCompletionCharacterSet;  // 入力補完の最初の1文字のセット
@property (readonly, nonatomic, nullable, copy) NSString *inlineCommentDelimiter;
@property (readonly, nonatomic, nullable, copy) NSDictionary *blockCommentDelimiters;
@property (readonly, nonatomic, getter=isNone) BOOL none;


/// designated initializer (return nil if no corresponded style dictionary can be found.)
- (nullable instancetype)initWithStyleName:(nullable NSString *)styleName NS_DESIGNATED_INITIALIZER;

@end



@interface CESyntaxParser (Outline)

- (nonnull NSArray *)outlineItemsWithWholeString:(nullable NSString *)wholeString;

@end



@interface CESyntaxParser (Highlighting)

- (void)colorAllString:(nullable NSString *)wholeString layoutManager:(nonnull NSLayoutManager *)layoutManager temporal:(BOOL)isTemporal;
- (void)colorRange:(NSRange)range wholeString:(nullable NSString *)wholeString layoutManager:(nonnull NSLayoutManager *)layoutManager temporal:(BOOL)isTemporal;

@end
