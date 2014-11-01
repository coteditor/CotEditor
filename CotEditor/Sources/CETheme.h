/*
 ==============================================================================
 CETheme
 
 CotEditor
 http://coteditor.github.io
 
 Created on 2014-04-12 by 1024jp
 encoding="UTF-8"
 ------------------------------------------------------------------------------
 
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

@import AppKit;


@interface CETheme : NSObject

/// name of the theme
@property (readonly, nonatomic, copy) NSString *name;

// basic colors
@property (readonly, nonatomic) NSColor *textColor;
@property (readonly, nonatomic) NSColor *backgroundColor;
@property (readonly, nonatomic) NSColor *invisiblesColor;
@property (readonly, nonatomic) NSColor *selectionColor;
@property (readonly, nonatomic) NSColor *insertionPointColor;
@property (readonly, nonatomic) NSColor *lineHighLightColor;

// auto genereted colors
@property (readonly, nonatomic) NSColor *weakTextColor;
@property (readonly, nonatomic) NSColor *markupColor;

// syntax colors
@property (readonly, nonatomic) NSColor *keywordsColor;
@property (readonly, nonatomic) NSColor *commandsColor;
@property (readonly, nonatomic) NSColor *typesColor;
@property (readonly, nonatomic) NSColor *attributesColor;
@property (readonly, nonatomic) NSColor *variablesColor;
@property (readonly, nonatomic) NSColor *valuesColor;
@property (readonly, nonatomic) NSColor *numbersColor;
@property (readonly, nonatomic) NSColor *stringsColor;
@property (readonly, nonatomic) NSColor *charactersColor;
@property (readonly, nonatomic) NSColor *commentsColor;

/// Is background color dark?
@property (readonly, nonatomic, getter=isDarkTheme) BOOL darkTheme;


/// return CETheme instance initialized with theme name
+ (CETheme *)themeWithName:(NSString *)themeName;


/// default initializer
- (instancetype)initWithName:(NSString *)themeName;

@end
