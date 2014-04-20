/*
 =================================================
 CETheme
 (for CotEditor)
 
 Copyright (C) 2014 CotEditor Project
 http://coteditor.github.io
 =================================================
 
 encoding="UTF-8"
 Created:2014-04-12 by 1024jp
 
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

#import <Foundation/Foundation.h>


@interface CETheme : NSObject

/// name of the theme
@property (nonatomic, copy, readonly) NSString *name;

// basic colors
@property (nonatomic, readonly) NSColor *textColor;
@property (nonatomic, readonly) NSColor *backgroundColor;
@property (nonatomic, readonly) NSColor *invisiblesColor;
@property (nonatomic, readonly) NSColor *selectionColor;
@property (nonatomic, readonly) NSColor *insertionPointColor;
@property (nonatomic, readonly) NSColor *lineHighLightColor;

// syntax colors
@property (nonatomic, readonly) NSColor *keywordsColor;
@property (nonatomic, readonly) NSColor *commandsColor;
@property (nonatomic, readonly) NSColor *valuesColor;
@property (nonatomic, readonly) NSColor *numbersColor;
@property (nonatomic, readonly) NSColor *stringsColor;
@property (nonatomic, readonly) NSColor *charactersColor;
@property (nonatomic, readonly) NSColor *commentsColor;


/// default initializer
- (instancetype)initWithThemeName:(NSString *)themeName;


/// return corresponded color to the loop index in CESyntax
- (NSColor *)syntaxColorWithIndex:(NSUInteger)index;

@end
