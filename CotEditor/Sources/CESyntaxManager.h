/*
=================================================
CESyntaxManager
(for CotEditor)

 Copyright (C) 2004-2007 nakamuxu.
 Copyright (C) 2014 CotEditor Project
 http://coteditor.github.io
=================================================

encoding="UTF-8"
Created:2004.12.24
 
 -fno-objc-arc
 
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

#import <Cocoa/Cocoa.h>
#import <OgreKit/OgreKit.h>
#import "RegexKitLite.h"


@interface CESyntaxManager : NSObject <NSTableViewDelegate>

@property (nonatomic) BOOL isOkButtonPressed;  // シートでOKボタンが押されたかどうか

@property (nonatomic, retain, readonly) NSString *selectedStyleName;  // 編集対象となっているスタイル名
@property (nonatomic, retain) NSString *editedNewStyleName;  // 編集された新しいスタイル名
@property (nonatomic, retain, readonly) NSDictionary *xtsnAndStyleTable;  // 拡張子<->styleファイルの変換テーブル辞書(key = 拡張子)
@property (nonatomic, retain, readonly) NSDictionary *xtsnErrors;  // 拡張子重複エラー辞書
@property (nonatomic, retain, readonly) NSArray *extensions;  // 拡張子配列
@property (nonatomic, retain, readonly) NSWindow *editWindow;  // カラーシンタックス編集シート用ウィンドウ


// class method
+ (CESyntaxManager *)sharedInstance;

// Public method
- (BOOL)setSelectionIndexOfStyle:(NSInteger)styleIndex mode:(NSInteger)mode;
- (NSString *)syntaxNameFromExtension:(NSString *)extension;
- (NSDictionary *)syntaxWithStyleName:(NSString *)styleName;
- (NSArray *)defaultSyntaxFileNames;
- (NSArray *)defaultSyntaxFileNamesWithoutPrefix;
- (BOOL)isDefaultSyntaxStyle:(NSString *)styleName;
- (BOOL)isEqualToDefaultSyntaxStyle:(NSString *)styleName;
- (NSArray *)styleNames;
- (NSWindow *)editWindow;
- (BOOL)existsStyleFileWithStyleName:(NSString *)styleName;
- (BOOL)importStyleFile:(NSString *)styleFileName;
- (BOOL)removeStyleFileWithStyleName:(NSString *)styleName;
- (NSURL *)URLOfStyle:(NSString *)styleName;
- (BOOL)existsExtensionError;
- (NSWindow *)extensionErrorWindow;

// Action Message
- (IBAction)setToFactoryDefaults:(id)sender;
- (IBAction)closeSyntaxEditSheet:(id)sender;
- (IBAction)closeSyntaxExtensionErrorSheet:(id)sender;
- (IBAction)startSyntaxElementCheck:(id)sender;

@end
