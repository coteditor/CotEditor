/*
 ==============================================================================
 CETheme
 
 CotEditor
 http://coteditor.com
 
 Created on 2014-04-12 by 1024jp
 encoding="UTF-8"
 ------------------------------------------------------------------------------
 
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

@import AppKit;


@interface CETheme : NSObject

/// name of the theme
@property (readonly, nonatomic, nonnull, copy) NSString *name;

// basic colors
@property (readonly, nonatomic, nonnull) NSColor *textColor;
@property (readonly, nonatomic, nonnull) NSColor *backgroundColor;
@property (readonly, nonatomic, nonnull) NSColor *invisiblesColor;
@property (readonly, nonatomic, nonnull) NSColor *selectionColor;
@property (readonly, nonatomic, nonnull) NSColor *insertionPointColor;
@property (readonly, nonatomic, nonnull) NSColor *lineHighLightColor;

// auto genereted colors
@property (readonly, nonatomic, nonnull) NSColor *weakTextColor;
@property (readonly, nonatomic, nonnull) NSColor *markupColor;

// syntax colors
@property (readonly, nonatomic, nonnull) NSColor *keywordsColor;
@property (readonly, nonatomic, nonnull) NSColor *commandsColor;
@property (readonly, nonatomic, nonnull) NSColor *typesColor;
@property (readonly, nonatomic, nonnull) NSColor *attributesColor;
@property (readonly, nonatomic, nonnull) NSColor *variablesColor;
@property (readonly, nonatomic, nonnull) NSColor *valuesColor;
@property (readonly, nonatomic, nonnull) NSColor *numbersColor;
@property (readonly, nonatomic, nonnull) NSColor *stringsColor;
@property (readonly, nonatomic, nonnull) NSColor *charactersColor;
@property (readonly, nonatomic, nonnull) NSColor *commentsColor;

/// Is background color dark?
@property (readonly, nonatomic, getter=isDarkTheme) BOOL darkTheme;


/// return CETheme instance initialized with theme name
+ (nullable CETheme *)themeWithName:(nonnull NSString *)themeName;


/// designated initializer
- (nullable instancetype)initWithName:(nonnull NSString *)themeName NS_DESIGNATED_INITIALIZER;

// unavailable initializer
- (nullable instancetype)init __attribute__((unavailable("use -initWithName: instead")));

@end
