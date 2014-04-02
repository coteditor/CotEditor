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


typedef NS_ENUM(NSInteger, CESyntaxEditSheetMode) {
    CESyntaxEdit     = 0,
    CECopySyntaxEdit = -100,
    CENewSyntaxEdit  = -200
};


@interface CESyntaxManager : NSObject <NSTableViewDelegate>

@property (nonatomic) BOOL isOkButtonPressed;  // シートでOKボタンが押されたかどうか
@property (nonatomic) NSString *editedNewStyleName;  // 編集された新しいスタイル名

// readonly

/// 拡張子重複エラー辞書
@property (nonatomic, readonly) NSDictionary *extensionErrors;

/// カラーシンタックス編集シート用ウィンドウ
@property (nonatomic, readonly) NSWindow *editWindow;


// class method
+ (instancetype)sharedManager;

// Public method
- (BOOL)setSelectionIndexOfStyle:(NSInteger)styleIndex mode:(CESyntaxEditSheetMode)mode;

- (NSString *)syntaxNameFromExtension:(NSString *)extension;
- (NSDictionary *)syntaxWithStyleName:(NSString *)styleName;
- (BOOL)isDefaultSyntaxStyle:(NSString *)styleName;
- (NSArray *)styleNames;
- (BOOL)existsStyleFileWithStyleName:(NSString *)styleName;
- (BOOL)importStyleFile:(NSString *)styleFileName;
- (BOOL)removeStyleFileWithStyleName:(NSString *)styleName;
- (NSURL *)URLOfBundledStyle:(NSString *)styleName;
- (NSURL *)URLOfStyle:(NSString *)styleName;
- (BOOL)existsExtensionError;

@end
