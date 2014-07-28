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
@property (nonatomic, readwrite) NSColor *markupColor;

// syntax colors
@property (nonatomic, readwrite) NSColor *keywordsColor;
@property (nonatomic, readwrite) NSColor *commandsColor;
@property (nonatomic, readwrite) NSColor *typesColor;
@property (nonatomic, readwrite) NSColor *attributesColor;
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
        _name = themeName;
        
        _textColor = themeDict[CEThemeTextColorKey];
        _backgroundColor = themeDict[CEThemeBackgroundColorKey];
        _invisiblesColor = themeDict[CEThemeInvisiblesColorKey];
        _selectionColor = themeDict[CEThemeSelectionColorKey];
        _insertionPointColor = themeDict[CEThemeInsertionPointColorKey];
        _lineHighLightColor = themeDict[CEThemeLineHighlightColorKey];
        _keywordsColor = themeDict[CEThemeKeywordsColorKey];
        _commandsColor = themeDict[CEThemeCommandsColorKey];
        _typesColor = themeDict[CEThemeTypesColorKey];
        _attributesColor = themeDict[CEThemeAttributesColorKey];
        _variablesColor = themeDict[CEThemeVariablesColorKey];
        _valuesColor = themeDict[CEThemeValuesColorKey];
        _numbersColor = themeDict[CEThemeNumbersColorKey];
        _stringsColor = themeDict[CEThemeStringsColorKey];
        _charactersColor = themeDict[CEThemeCharactersColorKey];
        _commentsColor = themeDict[CEThemeCommentsColorKey];
        
        _usesSystemSelectionColor = [themeDict[CEThemeUsesSystemSelectionColorKey] boolValue];
        
        // 文字カラーと背景カラーの中間色であるマークアップカラーを生成
        CGFloat BG_R, BG_G, BG_B, FG_R, FG_G, FG_B;
        [[_textColor colorUsingColorSpaceName:NSCalibratedRGBColorSpace] getRed:&FG_R green:&FG_G blue:&FG_B alpha:nil];
        [[_backgroundColor colorUsingColorSpaceName:NSCalibratedRGBColorSpace] getRed:&BG_R green:&BG_G blue:&BG_B alpha:nil];
        _markupColor = [NSColor colorWithCalibratedRed:((BG_R + FG_R) / 2)
                                                 green:((BG_G + FG_G) / 2)
                                                  blue:((BG_B + FG_B) / 2)
                                                 alpha:1.0];
        
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

@end
