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


@interface CESyntaxManager : NSObject

// readonly
/// 拡張子重複エラー辞書
@property (nonatomic, readonly) NSDictionary *extensionErrors;


// class method
+ (instancetype)sharedManager;


// public methods
- (NSString *)syntaxNameFromExtension:(NSString *)extension;
- (NSDictionary *)syntaxWithStyleName:(NSString *)styleName;
- (BOOL)isDefaultSyntaxStyle:(NSString *)styleName;  // check only the name
- (BOOL)isEqualToBundledSyntaxStyle:(NSString *)styleName;  // check also the content
- (NSArray *)styleNames;
- (BOOL)existsStyleFileWithStyleName:(NSString *)styleName;
- (BOOL)importStyleFile:(NSString *)styleFileName;
- (BOOL)removeStyleFileWithStyleName:(NSString *)styleName;
- (NSURL *)URLOfBundledStyle:(NSString *)styleName;
- (NSURL *)URLOfStyle:(NSString *)styleName;
- (BOOL)existsExtensionError;
- (NSString *)copiedSyntaxName:(NSString *)originalName;
- (void)saveColoringStyle:(NSMutableDictionary *)style name:(NSString *)name oldName:(NSString *)oldName;
- (NSArray *)validateSyntax:(NSDictionary *)style;
- (NSDictionary *)emptyColoringStyle;

@end
