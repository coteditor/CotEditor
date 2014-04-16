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

#import "CETheme.h"
#import "CEThemeManager.h"


@interface CETheme ()

/// name of the theme
@property (nonatomic, readwrite) NSString *name;

// basic colors
@property (nonatomic, readwrite) NSColor *textColor;
@property (nonatomic, readwrite) NSColor *backgroundColor;
@property (nonatomic, readwrite) NSColor *invisiblesColor;
@property (nonatomic, readwrite) NSColor *selectionColor;
@property (nonatomic, readwrite) NSColor *cursorColor;
@property (nonatomic, readwrite) NSColor *lineHighLightColor;

// syntax colors
@property (nonatomic, readwrite) NSColor *keywordsColor;
@property (nonatomic, readwrite) NSColor *commandsColor;
@property (nonatomic, readwrite) NSColor *valuesColor;
@property (nonatomic, readwrite) NSColor *numbersColor;
@property (nonatomic, readwrite) NSColor *stringsColor;
@property (nonatomic, readwrite) NSColor *charactersColor;
@property (nonatomic, readwrite) NSColor *commentsColor;

@end




#pragma mark -

@implementation CETheme

#pragma mark Public Methods

//------------------------------------------------------
// 初期化
- (instancetype)initWithThemeName:(NSString *)themeName
//------------------------------------------------------
{
    self = [super init];
    if (self) {
        NSMutableDictionary *themeDict = [[CEThemeManager sharedManager] archivedTheme:themeName isBundled:NULL];
        
        // カラーを解凍
        for (NSString *key in themeDict) {
            if ([key isEqualToString:CEThemeUsesSystemSelectionColorKey]) { continue; }
            
            themeDict[key] = [NSUnarchiver unarchiveObjectWithData:themeDict[key]];
        }
        
        // プロパティをセット
        [self setName:themeName];
        
        [self setTextColor:themeDict[CEThemeTextColorKey]];
        [self setBackgroundColor:themeDict[CEThemeBackgroundColorKey]];
        [self setInvisiblesColor:themeDict[CEThemeInvisiblesColorKey]];
        [self setSelectionColor:themeDict[CEThemeSelectionColorKey]];
        [self setCursorColor:themeDict[CEThemeCursorColorKey]];
        [self setLineHighLightColor:themeDict[CEThemeLineHighlightColorKey]];
        [self setKeywordsColor:themeDict[CEThemeKeywordsColorKey]];
        [self setCommandsColor:themeDict[CEThemeCommandsColorKey]];
        [self setValuesColor:themeDict[CEThemeValuesColorKey]];
        [self setNumbersColor:themeDict[CEThemeNumbersColorKey]];
        [self setStringsColor:themeDict[CEThemeStringsColorKey]];
        [self setCharactersColor:themeDict[CEThemeCharactersColorKey]];
        [self setCommandsColor:themeDict[CEThemeCommentsColorKey]];
        
        // システム環境設定の設定を使う場合はここで再定義する
        if ([themeDict[CEThemeUsesSystemSelectionColorKey] boolValue]) {
            [self setSelectionColor:[NSColor selectedTextBackgroundColor]];
        }
    }
    return self;
}


//------------------------------------------------------
/// インデックスに対応したカラーを返す (CESyntaxが使用)
- (NSColor *)syntaxColorWithIndex:(NSUInteger)index
//------------------------------------------------------
{
    switch (index) {
        case 0: return [self keywordsColor];
        case 1: return [self commandsColor];
        case 2: return [self valuesColor];
        case 3: return [self numbersColor];
        case 4: return [self stringsColor];
        case 5: return [self charactersColor];
        case 6: return [self commandsColor];
            
        default: return [self textColor];
    }
}

@end
