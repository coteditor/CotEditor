/*
 
 CETheme.h
 
 CotEditor
 http://coteditor.com
 
 Created by 1024jp on 2014-04-12.

 ------------------------------------------------------------------------------
 
 © 2014-2016 1024jp
 
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

@import Foundation;
@import AppKit.NSColor;


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

/// Is created from a valid theme dict? (Theme itself can be used even invalid since NSColor.grayColor() are substituted for invalid colors.)
@property (readonly, nonatomic, getter=isValid) BOOL valid;


/// return CETheme instance initialized with theme name
+ (nullable instancetype)themeWithDictinonary:(nonnull NSDictionary<NSString *, NSDictionary *> *)dictionary name:(nonnull NSString *)themeName;


/// designated initializer
- (nullable instancetype)initWithDictinonary:(nonnull NSDictionary<NSString *, NSDictionary *> *)dictionary name:(nonnull NSString *)themeName NS_DESIGNATED_INITIALIZER;
- (nullable instancetype)init NS_UNAVAILABLE;

- (nullable NSColor *)syntaxColorForType:(nonnull NSString *)syntaxType;

@end
