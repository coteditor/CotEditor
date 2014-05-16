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
@property (nonatomic, copy, readwrite) NSString *name;


// basic colors
@property (nonatomic, readwrite) NSColor *textColor;
@property (nonatomic, readwrite) NSColor *backgroundColor;
@property (nonatomic, readwrite) NSColor *invisiblesColor;
@property (nonatomic, readwrite) NSColor *selectionColor;
@property (nonatomic, readwrite) NSColor *insertionPointColor;
@property (nonatomic, readwrite) NSColor *lineHighLightColor;

// syntax colors
@property (nonatomic, readwrite) NSColor *keywordsColor;
@property (nonatomic, readwrite) NSColor *commandsColor;
@property (nonatomic, readwrite) NSColor *typesColor;
@property (nonatomic, readwrite) NSColor *variablesColor;
@property (nonatomic, readwrite) NSColor *valuesColor;
@property (nonatomic, readwrite) NSColor *numbersColor;
@property (nonatomic, readwrite) NSColor *stringsColor;
@property (nonatomic, readwrite) NSColor *charactersColor;
@property (nonatomic, readwrite) NSColor *commentsColor;


// other options
@property (nonatomic) BOOL usesSystemSelectionColor;

@end




#pragma mark -

@implementation CETheme

#pragma mark Class Methods

//------------------------------------------------------
/// 簡易イニシャライザ
+ (CETheme *)themeWithName:(NSString *)themeName
//------------------------------------------------------
{
    return [[CETheme alloc] initWithName:themeName];
}



#pragma mark Public Methods

//------------------------------------------------------
// 初期化
- (instancetype)initWithName:(NSString *)themeName
//------------------------------------------------------
{
    self = [super init];
    if (self) {
        NSMutableDictionary *themeDict = [[CEThemeManager sharedManager] archivedTheme:themeName isBundled:NULL];
        
        // カラーを解凍
        for (NSString *key in [themeDict allKeys]) {
            if ([key isEqualToString:CEThemeUsesSystemSelectionColorKey]) { continue; }
            
            themeDict[key] = [NSUnarchiver unarchiveObjectWithData:themeDict[key]];
        }
        
        // プロパティをセット
        [self setName:themeName];
        
        [self setTextColor:themeDict[CEThemeTextColorKey]];
        [self setBackgroundColor:themeDict[CEThemeBackgroundColorKey]];
        [self setInvisiblesColor:themeDict[CEThemeInvisiblesColorKey]];
        [self setSelectionColor:themeDict[CEThemeSelectionColorKey]];
        [self setInsertionPointColor:themeDict[CEThemeInsertionPointColorKey]];
        [self setLineHighLightColor:themeDict[CEThemeLineHighlightColorKey]];
        [self setKeywordsColor:themeDict[CEThemeKeywordsColorKey]];
        [self setCommandsColor:themeDict[CEThemeCommandsColorKey]];
        [self setTypesColor:themeDict[CEThemeTypesColorKey]];
        [self setVariablesColor:themeDict[CEThemeVariablesColorKey]];
        [self setValuesColor:themeDict[CEThemeValuesColorKey]];
        [self setNumbersColor:themeDict[CEThemeNumbersColorKey]];
        [self setStringsColor:themeDict[CEThemeStringsColorKey]];
        [self setCharactersColor:themeDict[CEThemeCharactersColorKey]];
        [self setCommentsColor:themeDict[CEThemeCommentsColorKey]];
        
        [self setUsesSystemSelectionColor:[themeDict[CEThemeUsesSystemSelectionColorKey] boolValue]];
    }
    return self;
}


//------------------------------------------------------
/// 選択範囲のハイライトカラーを返す
- (NSColor *)selectionColor
//------------------------------------------------------
{
    // システム環境設定の設定を使う場合はここで再定義する
    if ([self usesSystemSelectionColor]) {
        return [NSColor selectedTextBackgroundColor];
    }
    return _selectionColor;
}


//------------------------------------------------------
/// インデックスに対応したカラーを返す (CESyntaxが使用)
- (NSColor *)syntaxColorWithIndex:(NSUInteger)index
//------------------------------------------------------
{
    switch (index) {
        case 0: return [self keywordsColor];
        case 1: return [self commandsColor];
        case 2: return [self typesColor];
        case 3: return [self variablesColor];
        case 4: return [self valuesColor];
        case 5: return [self numbersColor];
        case 6: return [self stringsColor];
        case 7: return [self charactersColor];
        case 8: return [self commentsColor];
            
        default: return [self textColor];
    }
}

@end
