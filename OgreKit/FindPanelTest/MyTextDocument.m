/*
 * Name: MyTextDocument.m
 * Project: OgreKit
 *
 * Creation Date: Sep 29 2003
 * Author: Isao Sonobe <sonoisa (AT) muse (DOT) ocn (DOT) ne (DOT) jp>
 * Copyright: Copyright (c) 2003 Isao Sonobe, All rights reserved.
 * License: OgreKit License
 *
 * Encoding: UTF8
 * Tabsize: 4
 */

#import "MyTextDocument.h"


@implementation MyTextDocument

// 検索対象となるTextViewをOgreTextFinderに教える。
// 検索させたくない場合はnilをsetする。
// 定義を省略した場合、main windowのfirst responderが検索可能ならばそれを採用する。
- (void)tellMeTargetToFindIn:(id)textFinder
{
	[textFinder setTargetToFindIn:textView];
}


/* ここから下はFind Panelに関係しないコード */
- (NSString*)windowNibName {
    return @"MyTextDocument";
}

- (id)init
{
    self = [super init];
    if (self != nil) {
		_newlineCharacter = OgreUnixNewlineCharacter;	// デフォルトの改行コード
        _string = [[NSString alloc] init];
    }
    return self;
}

- (void)dealloc
{
    [_string release];
    [super dealloc];
}

- (NSString*)string
{
    return _string;
}

- (void)setString:(NSString*)string
{
    [_string autorelease];
    _string = [string retain];
}

- (NSData*)dataRepresentationOfType:(NSString*)type {
	// 改行コードを(置換すべきなら)置換し、保存する。
    if ([myController isEditing]) [myController commitEditing];
    
	NSString *aString = [self string];
	if ([aString newlineCharacter] != _newlineCharacter) {
		aString = [OGRegularExpression replaceNewlineCharactersInString:aString 
			withCharacter:_newlineCharacter];
	}
	
    return [aString dataUsingEncoding:NSUTF8StringEncoding];
}

- (BOOL)loadDataRepresentation:(NSData*)data ofType:(NSString*)type {
	// ファイルから読み込む。(UTF8決めうち。)
	NSMutableString *aString = [[NSMutableString alloc] initWithData:data encoding:NSUTF8StringEncoding];
	
	// 改行コードの種類を得る。
	_newlineCharacter = [aString newlineCharacter];
	if (_newlineCharacter == OgreNonbreakingNewlineCharacter) {
		// 改行のない場合はOgreUnixNewlineCharacterとみなす。
		//NSLog(@"nonbreaking");
		_newlineCharacter = OgreUnixNewlineCharacter;
	}
	
	// 改行コードを(置換すべきなら)置換する。
	if (_newlineCharacter != OgreUnixNewlineCharacter) {
		[aString replaceNewlineCharactersWithCharacter:OgreUnixNewlineCharacter];
	}
	//NSLog(@"newline character: %d (-1:Nonbreaking 0:LF(Unix) 1:CR(Mac) 2:CR+LF(Windows) 3:UnicodeLineSeparator 4:UnicodeParagraphSeparator)", _newlineCharacter, [OgreTextFinder newlineCharacterInString:_tmpString]);
	//NSLog(@"%@", [OGRegularExpression chomp:_tmpString]);
	
    [self setString:aString];
    
    return YES;
}

- (void)windowControllerDidLoadNib:(NSWindowController*)controller
{
    [super windowControllerDidLoadNib:controller];
}

// 改行コードの変更
- (void)setNewlineCharacter:(OgreNewlineCharacter)aNewlineCharacter
{
	_newlineCharacter = aNewlineCharacter;
}

@end
