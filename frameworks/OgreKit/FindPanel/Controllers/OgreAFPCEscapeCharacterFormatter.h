/*
 * Name: OgreAFPCEscapeCharacterFormatter.h
 * Project: OgreKit
 *
 * Creation Date: Feb 21 2004
 * Author: Isao Sonobe <sonoisa (AT) muse (DOT) ocn (DOT) ne (DOT) jp>
 * Copyright: Copyright (c) 2003 Isao Sonobe, All rights reserved.
 * License: OgreKit License
 *
 * Encoding: UTF8
 * Tabsize: 4
 */
 
#import <Foundation/Foundation.h>

@class OGRegularExpression, OGRegularExpressionMatch;

/* 入力された文字列を頭の1文字にするformatter */
@protocol OgreAFPCEscapeCharacterFormatterDelegate
- (NSString*)escapeCharacter;
- (BOOL)shouldEquateYenWithBackslash;
@end

@interface OgreAFPCEscapeCharacterFormatter : NSFormatter
{
	id <OgreAFPCEscapeCharacterFormatterDelegate> _delegate;
	
	OGRegularExpression *_backslashRegex, *_yenRegex;
}

// 必須メソッド
//- (NSString*)stringForObjectValue:(id)anObject;
//- (NSAttributedString*)attributedStringForObjectValue:(id)anObject withDefaultAttributes:(NSDictionary*)attributes;
// エラー判定
//- (BOOL)getObjectValue:(id*)obj forString:(NSString*)string errorDescription:(NSString**)error;

// delegate
- (void)setDelegate:(id)aDelegate;
// 変換
- (NSString*)equateInString:(NSString*)string;
- (NSAttributedString*)equateInAttributedString:(NSAttributedString*)string;
- (NSString*)equateYenWithBackslash:(OGRegularExpressionMatch*)aMatch 
	contextInfo:(id)contextInfo;
- (NSAttributedString*)equateYenWithBackslashAttributed:(OGRegularExpressionMatch*)aMatch 
	contextInfo:(id)contextInfo;

@end
