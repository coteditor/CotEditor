/*
=================================================
CESyntax
(for CotEditor)

 Copyright (C) 2004-2007 nakamuxu.
 Copyright (C) 2014 CotEditor Project
 http://coteditor.github.io
=================================================

encoding="UTF-8"
Created:2004.12.22
 
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


@class CELayoutManager;


@interface CESyntax : NSObject

// readonly
@property (nonatomic, copy, readonly) NSString *syntaxStyleName;
@property (nonatomic, copy, readonly) NSArray *completionWords;  // 入力補完文字列配列
@property (nonatomic, copy, readonly) NSCharacterSet *firstCompletionCharacterSet;  // 入力補完の最初の1文字のセット
@property (nonatomic, copy, readonly) NSString *inlineCommentDelimiter;
@property (nonatomic, copy, readonly) NSDictionary *blockCommentDelimiters;
@property (nonatomic, readonly) BOOL isNone;


/// designated initializer (return nil if no corresponded style dictionary can been found.)
- (instancetype)initWithStyleName:(NSString *)styleName layoutManager:(CELayoutManager *)layoutManager isPrinting:(BOOL)isPrinting;

// Public methods
- (void)colorAllString:(NSString *)wholeString;
- (void)colorVisibleRange:(NSRange)range wholeString:(NSString *)wholeString;
- (NSArray *)outlineMenuArrayWithWholeString:(NSString *)wholeString;

@end
