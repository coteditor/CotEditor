/*
 * Name: OgreTextFinder.h
 * Project: OgreKit
 *
 * Creation Date: Sep 20 2003
 * Author: Isao Sonobe <sonoisa (AT) muse (DOT) ocn (DOT) ne (DOT) jp>
 * Copyright: Copyright (c) 2003 Isao Sonobe, All rights reserved.
 * License: OgreKit License
 *
 * Encoding: UTF8
 * Tabsize: 4
 */

#import <Cocoa/Cocoa.h>
#import <OgreKit/OGRegularExpression.h>
#import <OgreKit/OGReplaceExpression.h>
#import <OgreKit/OGString.h>

// OgreTextFinderLocalizable.stringsを使用したローカライズ
#define OgreTextFinderLocalizedString(key)	[[OgreTextFinder ogreKitBundle] localizedStringForKey:(key) value:(key) table:@"OgreTextFinderLocalizable"]

@class OgreTextFinder, OgreFindPanelController, OgreTextFindResult, OgreTextFindThread, OgreTextFindProgressSheet;

@protocol OgreTextFindDataSource
/* OgreTextFinderが検索対象を知りたいときにresponder chain経由で呼ばれる 
   document windowのdelegateがimplementすることを想定している */
- (void)tellMeTargetToFindIn:(id)sender;
@end

@interface OgreTextFinder : NSObject 
{
	IBOutlet OgreFindPanelController	*findPanelController;	// FindPanelController
    IBOutlet NSMenu						*findMenu;				// Find manu
	
	OgreSyntax		_syntax;				// 正規表現の構文
	NSString		*_escapeCharacter;		// エスケープ文字
	
	id				_targetToFindIn;		// 検索対象
	Class			_adapterClassForTarget; // 検索対象のアダプタ(ラッパー)
	NSMutableArray	*_busyTargetArray;		// 使用中ターゲット

	NSDictionary	*_history;				// 検索履歴等
	BOOL			_saved;					// 履歴等が保存されたかどうか
	BOOL			_shouldHackFindMenu;	// FindメニューをOgreKitのものに置き換えるかどうか
	BOOL			_useStylesInFindPanel;	// 検索パネルでStyleを使用するかどうか。
    
    NSMutableArray  *_targetClassArray,     // 検索可能なクラスを収めた配列
                    *_adapterClassArray;    // 検索対象クラスのアダプタクラスを収めた配列
}

/* OgreKit.framework bundle */
+ (NSBundle*)ogreKitBundle;

/* Shared instance */
+ (id)sharedTextFinder;

/* nib name of Find Panel/Find Panel Controller */
- (NSString*)findPanelNibName;

/* Show Find Panel */
- (IBAction)showFindPanel:(id)sender;

/* Startup time configurations */
- (void)setShouldHackFindMenu:(BOOL)hack;
- (void)setUseStylesInFindPanel:(BOOL)use;
- (BOOL)useStylesInFindPanel;

/*************
 * Accessors *
 *************/
// target to find in
- (void)setTargetToFindIn:(id)target;
- (id)targetToFindIn;

- (void)setAdapterClassForTargetToFindIn:(Class)adapterClass;
- (Class)adapterClassForTargetToFindIn;

// Find Panel Controller
- (void)setFindPanelController:(OgreFindPanelController*)findPanelController;
- (OgreFindPanelController*)findPanelController;

// escape character
- (void)setEscapeCharacter:(NSString*)character;
- (NSString*)escapeCharacter;

// syntax
- (void)setSyntax:(OgreSyntax)syntax;
- (OgreSyntax)syntax;

/* Find/Replace/Highlight... */
- (OgreTextFindResult*)find:(NSString*)expressionString 
	options:(unsigned)options
	fromTop:(BOOL)isTop
	forward:(BOOL)forward
	wrap:(BOOL)isWrap;

- (OgreTextFindResult*)findAll:(NSString*)expressionString 
	color:(NSColor*)highlightColor 
	options:(unsigned)options
	inSelection:(BOOL)inSelection;

- (OgreTextFindResult*)replace:(NSString*)expressionString 
	withString:(NSString*)replaceString
	options:(unsigned)options;
- (OgreTextFindResult*)replace:(NSString*)expressionString 
	withAttributedString:(NSAttributedString*)replaceString
	options:(unsigned)options;
- (OgreTextFindResult*)replace:(NSObject<OGStringProtocol>*)expressionString 
	withOGString:(NSObject<OGStringProtocol>*)replaceString
	options:(unsigned)options;

- (OgreTextFindResult*)replaceAndFind:(NSString*)expressionString 
	withString:(NSString*)replaceString
	options:(unsigned)options 
    replacingOnly:(BOOL)replacingOnly 
	wrap:(BOOL)isWrap;
- (OgreTextFindResult*)replaceAndFind:(NSString*)expressionString 
	withAttributedString:(NSAttributedString*)replaceString
	options:(unsigned)options 
    replacingOnly:(BOOL)replacingOnly 
	wrap:(BOOL)isWrap;
- (OgreTextFindResult*)replaceAndFind:(NSObject<OGStringProtocol>*)expressionString 
	withOGString:(NSObject<OGStringProtocol>*)replaceString
	options:(unsigned)options 
    replacingOnly:(BOOL)replacingOnly 
	wrap:(BOOL)isWrap;

- (OgreTextFindResult*)replaceAll:(NSString*)expressionString 
	withString:(NSString*)replaceString
	options:(unsigned)options
	inSelection:(BOOL)inSelection;
- (OgreTextFindResult*)replaceAll:(NSString*)expressionString 
	withAttributedString:(NSAttributedString*)replaceString
	options:(unsigned)options
	inSelection:(BOOL)inSelection;
- (OgreTextFindResult*)replaceAll:(NSObject<OGStringProtocol>*)expressionString 
	withOGString:(NSObject<OGStringProtocol>*)replaceString
	options:(unsigned)options
	inSelection:(BOOL)inSelection;

- (OgreTextFindResult*)hightlight:(NSString*)expressionString 
	color:(NSColor*)highlightColor 
	options:(unsigned)options
	inSelection:(BOOL)inSelection;

- (OgreTextFindResult*)unhightlight;

- (NSString*)selectedString;
- (NSAttributedString*)selectedAttributedString;
- (NSObject<OGStringProtocol>*)selectedOGString;

- (BOOL)isSelectionEmpty;

- (BOOL)jumpToSelection;

/* creating an alert sheet */
- (OgreTextFindProgressSheet*)alertSheetOnTarget:(id)aTerget;

/* Getting and registering adapters for targets */
- (id)adapterForTarget:(id)aTargetToFindIn;
- (void)registeringAdapterClass:(Class)anAdapterClass forTargetClass:(Class)aTargetClass;
- (BOOL)hasAdapterClassForObject:(id)anObject;

/*******************
 * Private Methods *
 *******************/
// 前回保存された履歴
- (NSDictionary*)history;
// currentを起点に名前がnameのmenu itemを探す。
- (NSMenuItem*)findMenuItemNamed:(NSString*)name startAt:(NSMenu*)current;

// ターゲットが使用中かどうか
- (BOOL)isBusyTarget:(id)target;
// 使用中にする
- (void)makeTargetBusy:(id)target;
// 使用中でなくする
- (void)makeTargetFree:(id)target;

/* hack Find Menu */
- (void)hackFindMenu;

- (void)didEndThread:(OgreTextFindThread*)aTextFindThread;

@end

