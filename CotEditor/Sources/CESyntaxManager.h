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


// notifications
/// Posted when the line-up of syntax styles is updated.  This will be used for syntax style menus.
extern NSString *const CESyntaxListDidUpdateNotification;

/// Posted when a syntax style is updated.  Information about new/previous style name is in userInfo.
extern NSString *const CESyntaxDidUpdateNotification;


@interface CESyntaxManager : NSObject

// readonly
/// 拡張子重複エラー辞書
@property (nonatomic, copy, readonly) NSDictionary *extensionConflicts;


// class method
+ (instancetype)sharedManager;


// public methods
- (NSArray *)styleNames;
- (NSString *)syntaxNameFromExtension:(NSString *)extension;
- (NSDictionary *)styleWithStyleName:(NSString *)styleName;
- (NSDictionary *)bundledStyleWithStyleName:(NSString *)styleName;
- (NSDictionary *)emptyStyle;
- (BOOL)isBundledStyle:(NSString *)styleName;  // check only the name
- (BOOL)isEqualToBundledStyle:(NSDictionary *)style name:(NSString *)styleName;
- (BOOL)existsStyleFileWithStyleName:(NSString *)styleName;
- (BOOL)importStyleFromURL:(NSURL *)fileURL;
- (BOOL)exportStyle:(NSString *)styleName toURL:(NSURL *)fileURL;
- (BOOL)removeStyleFileWithStyleName:(NSString *)styleName;
- (BOOL)existsExtensionConflict;
- (NSString *)copiedStyleName:(NSString *)originalName;
- (void)saveStyle:(NSMutableDictionary *)style name:(NSString *)name oldName:(NSString *)oldName;
- (NSArray *)validateSyntax:(NSDictionary *)style;

@end
