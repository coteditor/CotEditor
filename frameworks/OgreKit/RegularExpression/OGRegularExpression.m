/*
 * Name: OGRegularExpression.m
 * Project: OgreKit
 *
 * Creation Date: Aug 30 2003
 * Author: Isao Sonobe <sonoisa (AT) muse (DOT) ocn (DOT) ne (DOT) jp>
 * Copyright: Copyright (c) 2003 Isao Sonobe, All rights reserved.
 * License: OgreKit License
 *
 * Encoding: UTF8
 * Tabsize: 4
 */
 
#ifndef NOT_RUBY
# define NOT_RUBY
#endif
#ifndef HAVE_CONFIG_H
# define HAVE_CONFIG_H
#endif
#import <OgreKit/oniguruma.h>

#import <OgreKit/OGRegularExpressionPrivate.h>
#import <OgreKit/OGRegularExpressionMatchPrivate.h>
#import <OgreKit/OGRegularExpressionEnumeratorPrivate.h>
#import <OgreKit/OGReplaceExpression.h>
#import <OgreKit/OGString.h>
#import <OgreKit/OGMutableString.h>
#import <OgreKit/OGPlainString.h>
#import <OgreKit/OGAttributedString.h>

/* constants */
// compile time options:
const unsigned	OgreNoneOption				= ONIG_OPTION_NONE;
const unsigned	OgreSingleLineOption		= ONIG_OPTION_SINGLELINE;
const unsigned	OgreMultilineOption			= ONIG_OPTION_MULTILINE;
const unsigned	OgreIgnoreCaseOption		= ONIG_OPTION_IGNORECASE;
const unsigned	OgreExtendOption			= ONIG_OPTION_EXTEND;
const unsigned	OgreFindLongestOption		= ONIG_OPTION_FIND_LONGEST;
const unsigned	OgreFindNotEmptyOption		= ONIG_OPTION_FIND_NOT_EMPTY;
const unsigned	OgreNegateSingleLineOption	= ONIG_OPTION_NEGATE_SINGLELINE;
const unsigned	OgreDontCaptureGroupOption	= ONIG_OPTION_DONT_CAPTURE_GROUP;
const unsigned	OgreCaptureGroupOption		= ONIG_OPTION_CAPTURE_GROUP;
// (ONIG_OPTION_POSIX_REGIONは使用しない)
// OgreDelimitByWhitespaceOptionはOgreSimpleMatchingSyntaxの使用時に、空白文字を単語の区切りとみなすかどうか
// 例: @"AAA BBB CCC" -> @"(AAA)|(BBB)|(CCC)"
const unsigned	OgreDelimitByWhitespaceOption	= ONIG_OPTION_POSIX_REGION;

// search time options:
const unsigned	OgreNotBOLOption			= ONIG_OPTION_NOTBOL;
const unsigned	OgreNotEOLOption			= ONIG_OPTION_NOTEOL;
const unsigned	OgreFindEmptyOption			= ONIG_OPTION_POSIX_REGION << 1;

// replace time options:
const unsigned	OgreReplaceWithAttributesOption	= ONIG_OPTION_POSIX_REGION << 2;
const unsigned	OgreReplaceFontsOption		= ONIG_OPTION_POSIX_REGION << 3;
const unsigned	OgreMergeAttributesOption	= ONIG_OPTION_POSIX_REGION << 4;

// exception name
NSString * const	OgreException = @"OGRegularExpressionException";
// 自身をencoding/decodingするためのkey
static NSString * const	OgreExpressionStringKey = @"OgreExpressionString";
static NSString * const OgreOptionsKey          = @"OgreOptions";
static NSString * const OgreSyntaxKey           = @"OgreSyntax";
static NSString * const OgreEscapeCharacterKey  = @"OgreEscapeCharacter";

// デフォルトの\の代替文字
static NSString			*OgrePrivateDefaultEscapeCharacter;
// デフォルトの構文。OgreSimpleMatchingを特別に扱うため。
static OgreSyntax		OgrePrivateDefaultSyntax;
// 特殊文字セット @"|().?*+{}^$[]-&#:=!<>@\\"
static NSCharacterSet	*OgrePrivateUnsafeCharacterSet = nil;
// 改行文字セット
static NSCharacterSet	*OgrePrivateNewlineCharacterSet = nil;
// Unicode改行文字
static NSString			*OgrePrivateUnicodeLineSeparator = nil;
static NSString			*OgrePrivateUnicodeParagraphSeparator = nil;



/* onig_foreach_namesのcallback関数 */
static int namedGroupCallback(const unsigned char *name, const unsigned char *name_end, int numberOfGroups, int* listOfGroupNumbers, regex_t* reg, void* nameDict)
{
	// 名前 -> グループ個数
	[(NSMutableDictionary*)nameDict setObject:[NSNumber numberWithUnsignedInt:numberOfGroups] forKey:[NSString stringWithCharacters:(unichar*)name length:((unichar*)name_end - (unichar*)name)]];
    
	return 0;  /* 0: continue, otherwise: stop(break) */
}


@implementation OGRegularExpression

+ (void)initialize
{
#ifdef DEBUG_OGRE
	NSLog(@"+initialize of %@", [self className]);
#endif
	// onigurumaの初期化
	onig_init();
	
	// デフォルト値の設定
	OgrePrivateDefaultEscapeCharacter = [[NSString alloc] initWithString:@"\\"];
	OgrePrivateDefaultSyntax = OgreRubySyntax;
	
	// linefeed characters of Unicode
	unichar	lineSeparator[2], paragraphSeparator[2];
	lineSeparator[0] = 0x2028;	lineSeparator[1] = 0;
	paragraphSeparator[0] = 0x2029;	paragraphSeparator[1] = 0;
	OgrePrivateUnicodeLineSeparator = [[NSString alloc] initWithCharacters:lineSeparator length:1];
	OgrePrivateUnicodeParagraphSeparator = [[NSString alloc] initWithCharacters:paragraphSeparator length:1];
	
	// 再利用可能な文字セットの生成
	OgrePrivateUnsafeCharacterSet = [[NSCharacterSet characterSetWithCharactersInString:@"|().?*+{}^$[]-&#:=!<>@\\"] retain];
	OgrePrivateNewlineCharacterSet = [[NSCharacterSet characterSetWithCharactersInString:[[@"\r\n" stringByAppendingString:OgrePrivateUnicodeLineSeparator] stringByAppendingString:OgrePrivateUnicodeParagraphSeparator]] retain];
	
	// copy original regular expression syntax
	onig_copy_syntax(&OgrePrivatePOSIXBasicSyntax, ONIG_SYNTAX_POSIX_BASIC);
	onig_copy_syntax(&OgrePrivatePOSIXExtendedSyntax, ONIG_SYNTAX_POSIX_EXTENDED);
	onig_copy_syntax(&OgrePrivateEmacsSyntax, ONIG_SYNTAX_EMACS);
	onig_copy_syntax(&OgrePrivateGrepSyntax, ONIG_SYNTAX_GREP);
	onig_copy_syntax(&OgrePrivateGNURegexSyntax, ONIG_SYNTAX_GNU_REGEX);
	onig_copy_syntax(&OgrePrivateJavaSyntax, ONIG_SYNTAX_JAVA);
	onig_copy_syntax(&OgrePrivatePerlSyntax, ONIG_SYNTAX_PERL);
	onig_copy_syntax(&OgrePrivateRubySyntax, ONIG_SYNTAX_RUBY);
	// enable capture hostory
	OgrePrivatePOSIXBasicSyntax.op2		|= ONIG_SYN_OP2_ATMARK_CAPTURE_HISTORY; 
	OgrePrivatePOSIXExtendedSyntax.op2  |= ONIG_SYN_OP2_ATMARK_CAPTURE_HISTORY; 
	OgrePrivateEmacsSyntax.op2			|= ONIG_SYN_OP2_ATMARK_CAPTURE_HISTORY; 
	OgrePrivateGrepSyntax.op2			|= ONIG_SYN_OP2_ATMARK_CAPTURE_HISTORY; 
	OgrePrivateGNURegexSyntax.op2		|= ONIG_SYN_OP2_ATMARK_CAPTURE_HISTORY; 
	OgrePrivateJavaSyntax.op2			|= ONIG_SYN_OP2_ATMARK_CAPTURE_HISTORY; 
	OgrePrivatePerlSyntax.op2			|= ONIG_SYN_OP2_ATMARK_CAPTURE_HISTORY; 
	OgrePrivateRubySyntax.op2			|= ONIG_SYN_OP2_ATMARK_CAPTURE_HISTORY; 
}

+ (id)regularExpressionWithString:(NSString*)expressionString
{
	return [[[self alloc]
		initWithString: expressionString
		options: OgreNoneOption
		syntax: [[self class] defaultSyntax]
		escapeCharacter: [[self class] defaultEscapeCharacter]] autorelease];
}

+ (id)regularExpressionWithString:(NSString*)expressionString 
	options:(unsigned)options
{
	return [[[self alloc]
		initWithString: expressionString
		options: options
		syntax: [[self class] defaultSyntax]
		escapeCharacter: [[self class] defaultEscapeCharacter]] autorelease];
}

+ (id)regularExpressionWithString:(NSString*)expressionString 
	options:(unsigned)options 
	syntax:(OgreSyntax)syntax 
	escapeCharacter:(NSString*)character
{
	return [[[self alloc] 
		initWithString: expressionString 
		options: options 
		syntax: syntax
		escapeCharacter: character] autorelease];
}


- (id)initWithString:(NSString*)expressionString
{
	return [self initWithString: expressionString 
		options: OgreNoneOption 
		syntax: [[self class] defaultSyntax]
		escapeCharacter: [[self class] defaultEscapeCharacter]];
}

- (id)initWithString:(NSString*)expressionString 
	options:(unsigned)options
{
	return [self initWithString: expressionString 
		options: options 
		syntax: [[self class] defaultSyntax]
		escapeCharacter: [[self class] defaultEscapeCharacter]];
}

- (id)initWithString:(NSString*)expressionString 
	options:(unsigned)options 
	syntax:(OgreSyntax)syntax 
	escapeCharacter:(NSString*)character
{
#ifdef DEBUG_OGRE
	NSLog(@"-initWithString: of %@", [self className]);
#endif
	self = [super init];
	if (self == nil) return nil;
	
	// 引数を保存
	// 正規表現を表す文字列をコピーして保持
	if(expressionString != nil) {
		_expressionString = [expressionString copy];
	} else {
		// expressionStringがnilの場合
		[self release];
		[NSException raise:NSInvalidArgumentException format:@"nil string (or other) argument"];
	}
	
	// オプション
	// OgreFindNotEmptyOptionとOgreDelimitByWhitespaceOptionを別に扱う。
	_options = OgreCompileTimeOptionMask(options);
	unsigned	compileTimeOptions = _options & ~OgreFindNotEmptyOption & ~OgreDelimitByWhitespaceOption;
	
	// 構文
	_syntax = syntax;
	
	// \の代替文字
	BOOL	isBackslashEscape = NO;
	// characterが使用可能な文字か調べる。
	switch ([[self class] kindOfCharacter:character]) {
		case OgreKindOfNil:
			// nilのとき、エラー
			[self release];
			[NSException raise:NSInvalidArgumentException format:@"nil string (or other) argument"];
			break;
		case OgreKindOfEmpty:
			// 空白のとき、エラー
			[self release];
			[NSException raise:NSInvalidArgumentException format:@"empty string argument"];
			break;
		case OgreKindOfBackslash:
			// @"\\"
			isBackslashEscape = YES;
			_escapeCharacter = [OgreBackslashCharacter retain];
			break;
		case OgreKindOfNormal:
			// 普通の文字
			_escapeCharacter = [[character substringWithRange:NSMakeRange(0,1)] retain];
			break;
		case OgreKindOfSpecial:
			// 特殊文字。エラー。
			[self release];
			[NSException raise:NSInvalidArgumentException format:@"invalid candidate for an escape character"];
			break;
	}
	
	int 			r;
	OnigErrorInfo	einfo;
	
	// UTF16文字列に変換する。(OgreSimpleMatchingSyntaxの場合は正規表現に変換してから)
	NSString        *compileTimeString;
    unsigned int    lengthOfCompileTimeString;
    
	if (syntax == OgreSimpleMatchingSyntax) {
		compileTimeString = [[self class] regularizeString:_expressionString];
		if (_options & OgreDelimitByWhitespaceOption) compileTimeString = [[self class] delimitByWhitespaceInString:compileTimeString];
	} else {
		if (isBackslashEscape) {
			compileTimeString = _expressionString;
		} else {
			compileTimeString = [[[self class] changeEscapeCharacterInOGString:[OGPlainString stringWithString:_expressionString] toCharacter:_escapeCharacter] string];
		}
	}
    
    lengthOfCompileTimeString = [compileTimeString length];
	_UTF16ExpressionString = (unichar*)NSZoneMalloc([self zone], sizeof(unichar) * lengthOfCompileTimeString);
    if (_UTF16ExpressionString == NULL) {
        [self release];
        [NSException raise:NSMallocException format:@"fail to allocate a memory"];
    }
    [compileTimeString getCharacters:_UTF16ExpressionString range:NSMakeRange(0, lengthOfCompileTimeString)];
	
	// 正規表現オブジェクトの作成
    OnigCompileInfo ci;
    ci.num_of_elements = 5;
	
	// Next seven lines by MATSUMOTO Satoshi, Sep 31 2005
#if defined( __BIG_ENDIAN__ )
    ci.pattern_enc = ONIG_ENCODING_UTF16_BE;
    ci.target_enc  = ONIG_ENCODING_UTF16_BE;
#else
    ci.pattern_enc = ONIG_ENCODING_UTF16_LE;
    ci.target_enc  = ONIG_ENCODING_UTF16_LE;
#endif

    ci.syntax         = [[self class] onigSyntaxTypeForSyntax:_syntax];
    ci.option         = compileTimeOptions;
    ci.case_fold_flag = ONIGENC_CASE_FOLD_DEFAULT;
    
	r = onig_new_deluxe(
        &_regexBuffer, 
        (unsigned char*)_UTF16ExpressionString, 
        (unsigned char*)(_UTF16ExpressionString + lengthOfCompileTimeString),
		&ci, 
        &einfo);
	if (r != ONIG_NORMAL) {
		// エラー。例外を発生させる。
		unsigned char s[ONIG_MAX_ERROR_MESSAGE_LEN];
		onig_error_code_to_str(s, r, &einfo);
		[self release];
		[NSException raise:OgreException format:@"%s", s];
	}
	
	// nameでgroup numberを引く辞書、(group number-1)でnameを引く逆引き辞書(配列)の作成
	if ([self numberOfNames] > 0) {
		// named groupを使用する場合
		// 辞書の作成
		// 例: /(?<a>a+)(?<b>b+)(?<a>c+)/
		// 構造: {"a" = (1,3), "b" = (2)}
		NSMutableDictionary *groupIndexForNameDictionary = [[NSMutableDictionary alloc] initWithCapacity:[self numberOfNames]];
		_groupIndexForNameDictionary = [[NSMutableDictionary alloc] initWithCapacity:[self numberOfNames]];
		r = onig_foreach_name(_regexBuffer, namedGroupCallback, groupIndexForNameDictionary);	// nameの一覧を得る
		
		NSEnumerator	*keyEnumerator = [groupIndexForNameDictionary keyEnumerator];
		NSString		*name;
		NSMutableArray	*array;
		int 			i, maxGroupIndex = 0;
		while ((name = [keyEnumerator nextObject]) != nil) {
            unsigned int    lengthOfName = [name length];
			unichar         *UTF16Name = (unichar*)NSZoneMalloc([self zone], sizeof(unichar) * lengthOfName);
            if (UTF16Name == NULL) {
                [self release];
                [NSException raise:NSMallocException format:@"fail to allocate a memory"];
            }
            [name getCharacters:UTF16Name range:NSMakeRange(0, lengthOfName)];

			/* nameに対応する部分文字列のindexを得る */
			int	*indexList;
			int n = onig_name_to_group_numbers(_regexBuffer, (unsigned char*)UTF16Name, (unsigned char*)(UTF16Name + lengthOfName), &indexList);
			
            NSZoneFree([self zone], UTF16Name);
            
			array = [[NSMutableArray alloc] initWithCapacity:n];
			for (i = 0; i < n; i++) {
				[array addObject:[NSNumber numberWithUnsignedInt: indexList[i] ]];
				if (indexList[i] > maxGroupIndex) maxGroupIndex = indexList[i];
			}
			[_groupIndexForNameDictionary setObject:array forKey:name];
			[array release];
		}
        [groupIndexForNameDictionary release];
		
		// 逆引き辞書の作成
		// 例: /(?<a>a+)(?<b>b+)(?<a>c+)/
		// 構造: ("a", "b", "a")
		_nameForGroupIndexArray = [[NSMutableArray alloc] initWithCapacity:maxGroupIndex];
		for(i=0; i<maxGroupIndex; i++) {
			[_nameForGroupIndexArray addObject:@""];
		}
		
		keyEnumerator = [_groupIndexForNameDictionary keyEnumerator];
		while ((name = [keyEnumerator nextObject]) != nil) {
			array = [_groupIndexForNameDictionary objectForKey:name];
			NSEnumerator	*arrayEnumerator = [array objectEnumerator];
			NSNumber		*index;
			while ((index = [arrayEnumerator nextObject]) != nil) {
				[_nameForGroupIndexArray replaceObjectAtIndex:([index unsignedIntValue] - 1) withObject:name];
			}
		}
		
	} else {
		// named groupを使用しない場合
		_groupIndexForNameDictionary = nil;
		_nameForGroupIndexArray = nil;
	}
	
	return self;
}

// 正規表現を表している文字列を返す。
- (NSString*)expressionString
{
	return _expressionString;
}

// 現在有効なオプション
- (unsigned)options
{
	return _options;
}

// 現在使用している正規表現の構文
- (OgreSyntax)syntax
{
	return _syntax;
}

// @"\\"の代替文字
- (NSString*)escapeCharacter
{
	return _escapeCharacter;
}


+ (BOOL)isValidExpressionString:(NSString*)expressionString
{
	return [self isValidExpressionString: expressionString 
		options: OgreNoneOption  
		syntax: [[self class] defaultSyntax] 
		escapeCharacter: [[self class] defaultEscapeCharacter]];
}

+ (BOOL)isValidExpressionString:(NSString*)expressionString options:(unsigned)options
{
	return [self isValidExpressionString: expressionString 
		options: options 
		syntax: [[self class] defaultSyntax] 
		escapeCharacter: [[self class] defaultEscapeCharacter]];
}

+ (BOOL)isValidExpressionString:(NSString*)expressionString 
	options:(unsigned)options 
	syntax:(OgreSyntax)syntax 
	escapeCharacter:(NSString*)character
{
	int 			r;
    unsigned int    length;
	unichar         *UTF16Str;
	OnigErrorInfo	einfo;
	regex_t			*regexBuffer;
	NSString		*escapeChar = nil;
	
	// characterが使用可能な文字か調べる。
	BOOL	isBackslashEscape = NO;
	switch ([[self class] kindOfCharacter:character]) {
		case OgreKindOfBackslash:
			// @"\\"
			escapeChar = OgreBackslashCharacter;
			isBackslashEscape = YES;
			break;
			
		case OgreKindOfNormal:
			// 普通の文字
			escapeChar = [character substringWithRange:NSMakeRange(0,1)];
			break;
			
		case OgreKindOfNil:
		case OgreKindOfEmpty:
		case OgreKindOfSpecial:
			// nil、空白文字、特殊文字の場合、エラー。
			return NO;
			break;
	}
		
	// オプション(ONIG_OPTION_POSIX_REGIONとOgreFindNotEmptyOptionとOgreDelimitByWhitespaceOptionが立っている場合は下げる)
	unsigned	compileTimeOptions = OgreCompileTimeOptionMask(options) & ~OgreFindNotEmptyOption & ~OgreDelimitByWhitespaceOption;
	
	// UTF16文字列に変換する。(OgreSimpleMatchingSyntaxの場合は正規表現に変換してから)
	NSString	*compileTimeString;
    
	if (syntax == OgreSimpleMatchingSyntax) {
		compileTimeString = [[self class] regularizeString:expressionString];
		if (options & OgreDelimitByWhitespaceOption) compileTimeString = [[self class] delimitByWhitespaceInString:compileTimeString];
	} else {
		if (isBackslashEscape) {
			compileTimeString = expressionString;
		} else {
			compileTimeString = [[[self class] changeEscapeCharacterInOGString:[OGPlainString stringWithString:expressionString] toCharacter:escapeChar] string];
		}
	}
    length = [compileTimeString length];
    
	UTF16Str = (unichar*)NSZoneMalloc([self zone], sizeof(unichar) * length);
    if (UTF16Str == NULL) {
        [NSException raise:NSMallocException format:@"fail to allocate a memory"];
    }
    [compileTimeString getCharacters:UTF16Str range:NSMakeRange(0, length)];
	
	// 正規表現オブジェクトの作成・解放

	// Next 11 lines by MATSUMOTO Satoshi, Sep 31 2005
#if defined( __BIG_ENDIAN__ )
 	r = onig_new(&regexBuffer, (unsigned char*)UTF16Str, (unsigned char*)(UTF16Str + length),
		compileTimeOptions, ONIG_ENCODING_UTF16_BE, 
			[[self class] onigSyntaxTypeForSyntax:syntax] 
		, &einfo);
#else
	r = onig_new(&regexBuffer, (unsigned char*)UTF16Str, (unsigned char*)(UTF16Str + length),
		compileTimeOptions, ONIG_ENCODING_UTF16_LE, 
			[[self class] onigSyntaxTypeForSyntax:syntax] 
		, &einfo);
#endif

	onig_free(regexBuffer);
    NSZoneFree([self zone], UTF16Str);
    
	if (r == ONIG_NORMAL) {
		// 正しい正規表現
		return YES;
	} else {
		// エラー
		return NO;
	}
}

// 文字列とマッチさせる。
- (OGRegularExpressionMatch*)matchInString:(NSString*)string
{
	return [self matchInString:string 
		options:OgreNoneOption 
		range:NSMakeRange(0, [string length])];	
}

- (OGRegularExpressionMatch*)matchInString:(NSString*)string 
	range:(NSRange)range
{
	return [self matchInString:string 
		options:OgreNoneOption 
		range:range];
}

- (OGRegularExpressionMatch*)matchInString:(NSString*)string 
	options:(unsigned)options
{
	return [self matchInString:string 
		options:options 
		range:NSMakeRange(0, [string length])];
}

- (OGRegularExpressionMatch*)matchInString:(NSString*)string 
	options:(unsigned)options 
	range:(NSRange)searchRange
{
	return [[self matchEnumeratorInString:string 
		options:options 
		range:searchRange] nextObject];
}


- (OGRegularExpressionMatch*)matchInAttributedString:(NSAttributedString*)string
{
	return [self matchInAttributedString:string 
		options:OgreNoneOption 
		range:NSMakeRange(0, [string length])];	
}

- (OGRegularExpressionMatch*)matchInAttributedString:(NSAttributedString*)string 
	range:(NSRange)range
{
	return [self matchInAttributedString:string 
		options:OgreNoneOption 
		range:range];
}

- (OGRegularExpressionMatch*)matchInAttributedString:(NSAttributedString*)string 
	options:(unsigned)options
{
	return [self matchInAttributedString:string 
		options:options 
		range:NSMakeRange(0, [string length])];
}

- (OGRegularExpressionMatch*)matchInAttributedString:(NSAttributedString*)string 
	options:(unsigned)options 
	range:(NSRange)searchRange
{
	return [[self matchEnumeratorInAttributedString:string 
		options:options 
		range:searchRange] nextObject];
}

- (OGRegularExpressionMatch*)matchInOGString:(NSObject<OGStringProtocol>*)string 
	options:(unsigned)options 
	range:(NSRange)searchRange
{
	return [[self matchEnumeratorInOGString:string 
		options:options 
		range:searchRange] nextObject];
}


- (NSEnumerator*)matchEnumeratorInString:(NSString*)string
{
	return [self matchEnumeratorInString:string 
		options:OgreNoneOption 
		range:NSMakeRange(0,[string length])];
}

- (NSEnumerator*)matchEnumeratorInString:(NSString*)string options:(unsigned)options
{
	return [self matchEnumeratorInString:string 
		options:options 
		range:NSMakeRange(0,[string length])];
}

- (NSEnumerator*)matchEnumeratorInString:(NSString*)string range:(NSRange)searchRange
{
	return [self matchEnumeratorInString:string 
		options:OgreNoneOption 
		range:searchRange];
}

- (NSEnumerator*)matchEnumeratorInString:(NSString*)string options:(unsigned)options range:(NSRange)searchRange
{
	return [self matchEnumeratorInOGString:[OGPlainString stringWithString:string] 
		options:options 
		range:searchRange];
}


- (NSEnumerator*)matchEnumeratorInAttributedString:(NSAttributedString*)string
{
	return [self matchEnumeratorInAttributedString:string 
		options:OgreNoneOption 
		range:NSMakeRange(0,[string length])];
}

- (NSEnumerator*)matchEnumeratorInAttributedString:(NSAttributedString*)string 
	options:(unsigned)options
{
	return [self matchEnumeratorInAttributedString:string 
		options:options 
		range:NSMakeRange(0,[string length])];
}

- (NSEnumerator*)matchEnumeratorInAttributedString:(NSAttributedString*)string 
	range:(NSRange)searchRange
{
	return [self matchEnumeratorInAttributedString:string 
		options:OgreNoneOption 
		range:searchRange];
}

- (NSEnumerator*)matchEnumeratorInAttributedString:(NSAttributedString*)string 
	options:(unsigned)options 
	range:(NSRange)searchRange
{
	return [self matchEnumeratorInOGString:[OGAttributedString stringWithAttributedString:string] 
		options:options 
		range:searchRange];
}


//
- (NSEnumerator*)matchEnumeratorInOGString:(NSObject<OGStringProtocol>*)string 
	options:(unsigned)options 
	range:(NSRange)searchRange
{
	if(string == nil) {
		// stringがnilの場合、例外を発生させる。
		[NSException raise:NSInvalidArgumentException format: @"nil string (or other) argument"];
	}
	
	OGRegularExpressionEnumerator	*enumerator;
	enumerator = [[[OGRegularExpressionEnumerator allocWithZone:[self zone]] 
		initWithOGString:[string substringWithRange:searchRange] 
		options:OgreSearchTimeOptionMask(options) 
		range:searchRange 
		regularExpression: self] autorelease];
		
	return enumerator;
}


// 文字列 targetString 中の正規表現にマッチした箇所を文字列 replaceString に置換したものを返す。
- (NSArray*)allMatchesInString:(NSString*)string
{
	return [self allMatchesInString:string
		options:OgreNoneOption 
		range:NSMakeRange(0, [string length])];
}

- (NSArray*)allMatchesInString:(NSString*)string
	options:(unsigned)options
{
	return [self allMatchesInString:string
		options:options 
		range:NSMakeRange(0, [string length])];
}

- (NSArray*)allMatchesInString:(NSString*)string
	range:(NSRange)searchRange
{
	return [self allMatchesInString:string
		options:OgreNoneOption 
		range:searchRange];
}

- (NSArray*)allMatchesInString:(NSString*)string
	options:(unsigned)options 
	range:(NSRange)searchRange
{
	return	[[self matchEnumeratorInString:string 
		options:options 
		range:searchRange] allObjects];
}


- (NSArray*)allMatchesInAttributedString:(NSAttributedString*)string
{
	return [self allMatchesInAttributedString:string
		options:OgreNoneOption 
		range:NSMakeRange(0, [string length])];
}

- (NSArray*)allMatchesInAttributedString:(NSAttributedString*)string
	options:(unsigned)options
{
	return [self allMatchesInAttributedString:string
		options:options 
		range:NSMakeRange(0, [string length])];
}

- (NSArray*)allMatchesInAttributedString:(NSAttributedString*)string
	range:(NSRange)searchRange
{
	return [self allMatchesInAttributedString:string
		options:OgreNoneOption 
		range:searchRange];
}

- (NSArray*)allMatchesInAttributedString:(NSAttributedString*)string
	options:(unsigned)options 
	range:(NSRange)searchRange
{
	return	[[self matchEnumeratorInAttributedString:string 
		options:options 
		range:searchRange] allObjects];
}


- (NSArray*)allMatchesInOGString:(NSObject<OGStringProtocol>*)string
	options:(unsigned)options 
	range:(NSRange)searchRange
{
	return	[[self matchEnumeratorInOGString:string 
		options:options 
		range:searchRange] allObjects];
}


// 最初にマッチした部分のみを置換
- (NSString*)replaceFirstMatchInString:(NSString*)targetString 
	withString:(NSString*)replaceString
{
	return [self replaceString:targetString 
		withString:replaceString 
		options:OgreNoneOption
		range:NSMakeRange(0,[targetString length]) 
		replaceAll:NO
		numberOfReplacement: NULL];
}

- (NSString*)replaceFirstMatchInString:(NSString*)targetString 
	withString:(NSString*)replaceString 
	options:(unsigned)options
{
	return [self replaceString: targetString 
		withString: replaceString 
		options: options
		range:NSMakeRange(0,[targetString length]) 
		replaceAll:NO
		numberOfReplacement:NULL];
}

- (NSString*)replaceFirstMatchInString:(NSString*)targetString 
	withString:(NSString*)replaceString 
	options:(unsigned)options
	range:(NSRange)replaceRange
{
	return [self replaceString: targetString 
		withString: replaceString 
		options: options
		range:replaceRange 
		replaceAll: NO
		numberOfReplacement: NULL];
}


- (NSAttributedString*)replaceFirstMatchInAttributedString:(NSAttributedString*)targetString 
	withAttributedString:(NSAttributedString*)replaceString
{
	return [self replaceAttributedString:targetString 
		withAttributedString:replaceString 
		options:OgreNoneOption
		range:NSMakeRange(0,[targetString length]) 
		replaceAll:NO
		numberOfReplacement: NULL];
}

- (NSAttributedString*)replaceFirstMatchInAttributedString:(NSAttributedString*)targetString 
	withAttributedString:(NSAttributedString*)replaceString 
	options:(unsigned)options
{
	return [self replaceAttributedString: targetString 
		withAttributedString: replaceString 
		options: options
		range:NSMakeRange(0,[targetString length]) 
		replaceAll:NO
		numberOfReplacement:NULL];
}

- (NSAttributedString*)replaceFirstMatchInAttributedString:(NSAttributedString*)targetString 
	withAttributedString:(NSAttributedString*)replaceString 
	options:(unsigned)options
	range:(NSRange)replaceRange
{
	return [self replaceAttributedString: targetString 
		withAttributedString: replaceString 
		options: options
		range:replaceRange 
		replaceAll: NO
		numberOfReplacement: NULL];
}


// 全てのマッチした部分を置換
- (NSString*)replaceAllMatchesInString:(NSString*)targetString 
	withString:(NSString*)replaceString
{
	return [self replaceString:targetString 
		withString:replaceString 
		options:OgreNoneOption
		range:NSMakeRange(0,[targetString length]) 
		replaceAll:YES
		numberOfReplacement:NULL];
}

- (NSString*)replaceAllMatchesInString:(NSString*)targetString 
	withString:(NSString*)replaceString 
	options:(unsigned)options
{
	return [self replaceString:targetString 
		withString:replaceString 
		options:options
		range:NSMakeRange(0,[targetString length]) 
		replaceAll:YES
		numberOfReplacement:NULL];
}

- (NSString*)replaceAllMatchesInString:(NSString*)targetString 
	withString:(NSString*)replaceString 
	options:(unsigned)options
	range:(NSRange)replaceRange
{
	return [self replaceString:targetString 
		withString:replaceString 
		options:options
		range:replaceRange
		replaceAll:YES
		numberOfReplacement:NULL];
}


- (NSAttributedString*)replaceAllMatchesInAttributedString:(NSAttributedString*)targetString 
	withAttributedString:(NSAttributedString*)replaceString
{
	return [self replaceAttributedString:targetString 
		withAttributedString:replaceString 
		options:OgreNoneOption
		range:NSMakeRange(0,[targetString length]) 
		replaceAll:YES
		numberOfReplacement:NULL];
}

- (NSAttributedString*)replaceAllMatchesInAttributedString:(NSAttributedString*)targetString 
	withAttributedString:(NSAttributedString*)replaceString 
	options:(unsigned)options
{
	return [self replaceAttributedString:targetString 
		withAttributedString:replaceString 
		options:options
		range:NSMakeRange(0,[targetString length]) 
		replaceAll:YES
		numberOfReplacement:NULL];
}

- (NSAttributedString*)replaceAllMatchesInAttributedString:(NSAttributedString*)targetString 
	withAttributedString:(NSAttributedString*)replaceString 
	options:(unsigned)options
	range:(NSRange)replaceRange
{
	return [self replaceAttributedString:targetString 
		withAttributedString:replaceString 
		options:options
		range:replaceRange
		replaceAll:YES
		numberOfReplacement:NULL];
}


// マッチした部分を置換
- (NSString*)replaceString:(NSString*)targetString 
	withString:(NSString*)replaceString 
	options:(unsigned)options 
	range:(NSRange)replaceRange 
	replaceAll:(BOOL)replaceAll
{
	return [self replaceString:targetString 
		withString:replaceString 
		options:options
		range:replaceRange
		replaceAll:replaceAll
		numberOfReplacement:NULL];
}

- (NSAttributedString*)replaceAttributedString:(NSAttributedString*)targetString 
	withAttributedString:(NSAttributedString*)replaceString 
	options:(unsigned)options 
	range:(NSRange)replaceRange 
	replaceAll:(BOOL)replaceAll
{
	return [self replaceAttributedString:targetString 
		withAttributedString:replaceString 
		options:options
		range:replaceRange
		replaceAll:replaceAll
		numberOfReplacement:NULL];
}

- (NSString*)replaceString:(NSString*)targetString 
	withString:(NSString*)replaceString 
	options:(unsigned)options 
	range:(NSRange)replaceRange 
	replaceAll:(BOOL)replaceAll
	numberOfReplacement:(unsigned*)numberOfReplacement 
{
	return [[self replaceOGString:[OGPlainString stringWithString:targetString] 
		withOGString:[OGPlainString stringWithString:replaceString] 
		options:options 
		range:replaceRange 
		replaceAll:replaceAll
		numberOfReplacement:numberOfReplacement] string];
}

- (NSAttributedString*)replaceAttributedString:(NSAttributedString*)targetString 
	withAttributedString:(NSAttributedString*)replaceString 
	options:(unsigned)options 
	range:(NSRange)replaceRange 
	replaceAll:(BOOL)replaceAll
	numberOfReplacement:(unsigned*)numberOfReplacement 
{
	return [[self replaceOGString:[OGAttributedString stringWithAttributedString:targetString] 
		withOGString:[OGAttributedString stringWithAttributedString:replaceString]  
		options:options 
		range:replaceRange 
		replaceAll:replaceAll
		numberOfReplacement:numberOfReplacement] attributedString];
}

- (NSObject<OGStringProtocol>*)replaceOGString:(NSObject<OGStringProtocol>*)targetString 
	withOGString:(NSObject<OGStringProtocol>*)replaceString 
	options:(unsigned)options 
	range:(NSRange)replaceRange 
	replaceAll:(BOOL)replaceAll
	numberOfReplacement:(unsigned*)numberOfReplacement 
{
	OGReplaceExpression	*repex = [[OGReplaceExpression alloc] initWithOGString:replaceString 
		options:options 
		syntax:[self syntax] 
		escapeCharacter:[self escapeCharacter]];
	
	NSEnumerator	*enumerator = [self matchEnumeratorInOGString:targetString 
		options:options 
		range:replaceRange];
	
	NSObject<OGStringProtocol,OGMutableStringProtocol>	*replacedString;
	replacedString = [[[[targetString mutableClass] alloc] init] autorelease];
	
	unsigned					matches = 0;
	OGRegularExpressionMatch	*match, *lastMatch = nil;
	
	NSAutoreleasePool	*pool = [[NSAutoreleasePool alloc] init];
	
	if (replaceAll) {
		while ((match = [enumerator nextObject]) != nil) {
			matches++;
			//NSLog(@"%@", [repex replaceMatchedString:match]);
			[replacedString appendOGString:[match ogStringBetweenMatchAndLastMatch]];
			[replacedString appendOGString:[repex replaceMatchedOGStringOf:match]];
			lastMatch = match;
			if (matches % 100 == 0) {
				[lastMatch retain];
				[pool release];
				pool = [[NSAutoreleasePool alloc] init];
				[lastMatch autorelease];
			}
		}
	} else {
		if ((match = [enumerator nextObject]) != nil) {
			matches++;
			[replacedString appendOGString:[match prematchOGString]];
			[replacedString appendOGString:[repex replaceMatchedOGStringOf:match]];
			lastMatch = match;
		}
	}
	if (lastMatch == nil) {
		// マッチ箇所がなかった場合は、そのまま返す。
		replacedString = (NSObject<OGStringProtocol,OGMutableStringProtocol>*)targetString;
	} else {
		// 最後のマッチ以降をコピー
		[replacedString appendOGString:[lastMatch postmatchOGString]];
	}
	
	[pool release];
	[repex release];
	
	if (numberOfReplacement != NULL) *numberOfReplacement = matches;
	return replacedString;
}


/* マッチした部分をaSelectorの返す文字列に置換する */
// 最初にマッチした部分のみを置換
- (NSString*)replaceFirstMatchInString:(NSString*)targetString 
	delegate:(id)aDelegate 
	replaceSelector:(SEL)aSelector 
	contextInfo:(id)contextInfo
{
	return [self replaceString:targetString 
		delegate:aDelegate 
		replaceSelector:aSelector 
		contextInfo:contextInfo
		options:OgreNoneOption
		range:NSMakeRange(0, [targetString length]) 
		replaceAll:NO
		numberOfReplacement:NULL];
}

- (NSString*)replaceFirstMatchInString:(NSString*)targetString 
	delegate:(id)aDelegate 
	replaceSelector:(SEL)aSelector 
	contextInfo:(id)contextInfo
	options:(unsigned)options
{
	return [self replaceString:targetString 
		delegate:aDelegate 
		replaceSelector:aSelector 
		contextInfo:contextInfo
		options:options
		range:NSMakeRange(0, [targetString length]) 
		replaceAll:NO
		numberOfReplacement:NULL];
}

- (NSString*)replaceFirstMatchInString:(NSString*)targetString 
	delegate:(id)aDelegate 
	replaceSelector:(SEL)aSelector 
	contextInfo:(id)contextInfo
	options:(unsigned)options
	range:(NSRange)replaceRange
{
	return [self replaceString:targetString 
		delegate:aDelegate 
		replaceSelector:aSelector 
		contextInfo:contextInfo
		options:options
		range:replaceRange 
		replaceAll:NO
		numberOfReplacement:NULL];
}

- (NSAttributedString*)replaceFirstMatchInAttributedString:(NSAttributedString*)targetString 
	delegate:(id)aDelegate 
	replaceSelector:(SEL)aSelector 
	contextInfo:(id)contextInfo
{
	return [self replaceAttributedString:targetString 
		delegate:aDelegate 
		replaceSelector:aSelector 
		contextInfo:contextInfo
		options:OgreNoneOption
		range:NSMakeRange(0, [targetString length]) 
		replaceAll:NO
		numberOfReplacement:NULL];
}

- (NSAttributedString*)replaceFirstMatchInAttributedString:(NSAttributedString*)targetString 
	delegate:(id)aDelegate 
	replaceSelector:(SEL)aSelector 
	contextInfo:(id)contextInfo
	options:(unsigned)options
{
	return [self replaceAttributedString:targetString 
		delegate:aDelegate 
		replaceSelector:aSelector 
		contextInfo:contextInfo
		options:options
		range:NSMakeRange(0, [targetString length]) 
		replaceAll:NO
		numberOfReplacement:NULL];
}

- (NSAttributedString*)replaceFirstMatchInAttributedString:(NSAttributedString*)targetString 
	delegate:(id)aDelegate 
	replaceSelector:(SEL)aSelector 
	contextInfo:(id)contextInfo
	options:(unsigned)options
	range:(NSRange)replaceRange
{
	return [self replaceAttributedString:targetString 
		delegate:aDelegate 
		replaceSelector:aSelector 
		contextInfo:contextInfo
		options:options
		range:replaceRange 
		replaceAll:NO
		numberOfReplacement:NULL];
}

- (NSObject<OGStringProtocol>*)replaceFirstMatchInOGString:(NSObject<OGStringProtocol>*)targetString 
	delegate:(id)aDelegate 
	replaceSelector:(SEL)aSelector 
	contextInfo:(id)contextInfo
	options:(unsigned)options
	range:(NSRange)replaceRange
{
	return [self replaceOGString:targetString 
		delegate:aDelegate 
		replaceSelector:aSelector 
		contextInfo:contextInfo
		options:options
		range:replaceRange 
		replaceAll:NO
		numberOfReplacement:NULL];
}


// 全てのマッチした部分を置換
- (NSString*)replaceAllMatchesInString:(NSString*)targetString 
	delegate:(id)aDelegate 
	replaceSelector:(SEL)aSelector 
	contextInfo:(id)contextInfo
{
	return [self replaceString: targetString 
		delegate:aDelegate 
		replaceSelector:aSelector 
		contextInfo:contextInfo
		options:OgreNoneOption
		range:NSMakeRange(0, [targetString length]) 
		replaceAll:YES
		numberOfReplacement:NULL];
}

- (NSString*)replaceAllMatchesInString:(NSString*)targetString 
	delegate:(id)aDelegate 
	replaceSelector:(SEL)aSelector 
	contextInfo:(id)contextInfo
	options:(unsigned)options
{
	return [self replaceString: targetString 
		delegate:aDelegate 
		replaceSelector:aSelector 
		contextInfo:contextInfo
		options:options
		range:NSMakeRange(0, [targetString length]) 
		replaceAll:YES
		numberOfReplacement:NULL];
}

- (NSString*)replaceAllMatchesInString:(NSString*)targetString 
	delegate:(id)aDelegate 
	replaceSelector:(SEL)aSelector 
	contextInfo:(id)contextInfo
	options:(unsigned)options
	range:(NSRange)replaceRange
{
	return [self replaceString: targetString 
		delegate:aDelegate 
		replaceSelector:aSelector 
		contextInfo:contextInfo
		options:options
		range:replaceRange
		replaceAll:YES
		numberOfReplacement:NULL];
}


- (NSAttributedString*)replaceAllMatchesInAttributedString:(NSAttributedString*)targetString 
	delegate:(id)aDelegate 
	replaceSelector:(SEL)aSelector 
	contextInfo:(id)contextInfo
{
	return [self replaceAttributedString: targetString 
		delegate:aDelegate 
		replaceSelector:aSelector 
		contextInfo:contextInfo
		options:OgreNoneOption
		range:NSMakeRange(0, [targetString length]) 
		replaceAll:YES
		numberOfReplacement:NULL];
}

- (NSAttributedString*)replaceAllMatchesInAttributedString:(NSAttributedString*)targetString 
	delegate:(id)aDelegate 
	replaceSelector:(SEL)aSelector 
	contextInfo:(id)contextInfo
	options:(unsigned)options
{
	return [self replaceAttributedString: targetString 
		delegate:aDelegate 
		replaceSelector:aSelector 
		contextInfo:contextInfo
		options:options
		range:NSMakeRange(0, [targetString length]) 
		replaceAll:YES
		numberOfReplacement:NULL];
}

- (NSAttributedString*)replaceAllMatchesInAttributedString:(NSAttributedString*)targetString 
	delegate:(id)aDelegate 
	replaceSelector:(SEL)aSelector 
	contextInfo:(id)contextInfo
	options:(unsigned)options
	range:(NSRange)replaceRange
{
	return [self replaceAttributedString: targetString 
		delegate:aDelegate 
		replaceSelector:aSelector 
		contextInfo:contextInfo
		options:options
		range:replaceRange
		replaceAll:YES
		numberOfReplacement:NULL];
}


- (NSObject<OGStringProtocol>*)replaceAllMatchesInOGString:(NSObject<OGStringProtocol>*)targetString 
	delegate:(id)aDelegate 
	replaceSelector:(SEL)aSelector 
	contextInfo:(id)contextInfo
	options:(unsigned)options
	range:(NSRange)replaceRange
{
	return [self replaceOGString:targetString 
		delegate:aDelegate 
		replaceSelector:aSelector 
		contextInfo:contextInfo
		options:options
		range:replaceRange
		replaceAll:YES
		numberOfReplacement:NULL];
}


// マッチした部分を置換
- (NSString*)replaceString:(NSString*)targetString 
	delegate:(id)aDelegate 
	replaceSelector:(SEL)aSelector 
	contextInfo:(id)contextInfo 
	options:(unsigned)options 
	range:(NSRange)replaceRange 
	replaceAll:(BOOL)replaceAll
{
	return [[self replaceOGString:[OGPlainString stringWithString:targetString] 
		delegate:aDelegate 
		replaceSelector:aSelector 
		contextInfo:contextInfo
		options:options
		range:replaceRange
		replaceAll:replaceAll
		numberOfReplacement:NULL] string];
}

- (NSString*)replaceString:(NSString*)targetString 
	delegate:(id)aDelegate 
	replaceSelector:(SEL)aSelector 
	contextInfo:(id)contextInfo 
	options:(unsigned)options 
	range:(NSRange)replaceRange 
	replaceAll:(BOOL)replaceAll
	numberOfReplacement:(unsigned*)numberOfReplacement
{
	return [[self replaceOGString:[OGPlainString stringWithString:targetString] 
		delegate:aDelegate 
		replaceSelector:aSelector 
		contextInfo:contextInfo
		options:options
		range:replaceRange
		replaceAll:replaceAll
		numberOfReplacement:numberOfReplacement] string];
}


- (NSAttributedString*)replaceAttributedString:(NSAttributedString*)targetString 
	delegate:(id)aDelegate 
	replaceSelector:(SEL)aSelector 
	contextInfo:(id)contextInfo 
	options:(unsigned)options 
	range:(NSRange)replaceRange 
	replaceAll:(BOOL)replaceAll
{
	return [[self replaceOGString:[OGAttributedString stringWithAttributedString:targetString] 
		delegate:aDelegate 
		replaceSelector:aSelector 
		contextInfo:contextInfo
		options:options
		range:replaceRange
		replaceAll:replaceAll
		numberOfReplacement:NULL] attributedString];
}

- (NSAttributedString*)replaceAttributedString:(NSAttributedString*)targetString 
	delegate:(id)aDelegate 
	replaceSelector:(SEL)aSelector 
	contextInfo:(id)contextInfo 
	options:(unsigned)options 
	range:(NSRange)replaceRange 
	replaceAll:(BOOL)replaceAll
	numberOfReplacement:(unsigned*)numberOfReplacement
{
	return [[self replaceOGString:[OGAttributedString stringWithAttributedString:targetString] 
		delegate:aDelegate 
		replaceSelector:aSelector 
		contextInfo:contextInfo
		options:options
		range:replaceRange
		replaceAll:replaceAll
		numberOfReplacement:numberOfReplacement] attributedString];
}


- (NSObject<OGStringProtocol>*)replaceOGString:(NSObject<OGStringProtocol>*)targetString 
	delegate:(id)aDelegate 
	replaceSelector:(SEL)aSelector 
	contextInfo:(id)contextInfo 
	options:(unsigned)options 
	range:(NSRange)replaceRange 
	replaceAll:(BOOL)replaceAll
	numberOfReplacement:(unsigned*)numberOfReplacement
{
	NSEnumerator	*enumerator = [self matchEnumeratorInOGString:targetString 
		options:options 
		range:replaceRange];
	
	NSObject<OGStringProtocol,OGMutableStringProtocol>	*replacedString;
	replacedString = [[[[targetString mutableClass] alloc] init] autorelease];
	
	id			returnedString;
	unsigned	matches = 0;
	OGRegularExpressionMatch	*match, *lastMatch = nil;
	
	// NSInvocationのセットアップ
	NSMethodSignature	*replaceSignature = [aDelegate methodSignatureForSelector:aSelector];
	NSInvocation		*replaceInvocation = [NSInvocation invocationWithMethodSignature:replaceSignature];
	[replaceInvocation setTarget:aDelegate];
	[replaceInvocation setSelector:aSelector];
	[replaceInvocation setArgument:&contextInfo atIndex:3];
	
	NSAutoreleasePool	*pool = [[NSAutoreleasePool alloc] init];
	
	if (replaceAll) {
		while ((match = [enumerator nextObject]) != nil) {
			matches++;
			
			// matchを置換する
			[replaceInvocation setArgument:&match atIndex:2];
			[replaceInvocation invoke];
			[replaceInvocation getReturnValue:&returnedString];
			if (returnedString == nil) {
				// nilが返された場合は置換を中止する。
				break;
			} else {
				[replacedString appendOGString:[match ogStringBetweenMatchAndLastMatch]];
				if ([returnedString isKindOfClass:[NSString class]]) {
					[replacedString appendString:(NSString*)returnedString];
				} else if ([returnedString isKindOfClass:[NSAttributedString class]]){
					[replacedString appendAttributedString:(NSAttributedString*)returnedString];
				}
				lastMatch = match;
			}
			
			if (matches % 100 == 0) {
				[lastMatch retain];
				[pool release];
				pool = [[NSAutoreleasePool alloc] init];
				[lastMatch autorelease];
			}
		}
	} else {
		if ((match = [enumerator nextObject]) != nil) {
			matches++;
			// matchを置換する
			[replaceInvocation setArgument:&match atIndex:2];
			[replaceInvocation invoke];
			[replaceInvocation getReturnValue:&returnedString];
			if (returnedString != nil) {
				[replacedString appendOGString:[match prematchOGString]];
				if ([returnedString isKindOfClass:[NSString class]]) {
					[replacedString appendString:(NSString*)returnedString];
				} else if ([returnedString isKindOfClass:[NSAttributedString class]]){
					[replacedString appendAttributedString:(NSAttributedString*)returnedString];
				}
				lastMatch = match;
			} /* nilが返された場合は何もしない。*/
		}
	}
	if (lastMatch == nil) {
		// マッチ箇所がなかった場合は、そのまま返す。
		replacedString = (NSObject<OGStringProtocol,OGMutableStringProtocol>*)targetString;
	} else {
		// 最後のマッチ以降をコピ
		[replacedString appendOGString:[lastMatch postmatchOGString]];
	}
	
	[pool release];
	
	if (numberOfReplacement != NULL) *numberOfReplacement = matches;
	return replacedString;
}



// 現在のデフォルトのエスケープ文字。初期値は@"\\"
+ (NSString*)defaultEscapeCharacter
{
	return OgrePrivateDefaultEscapeCharacter;
}

// デフォルトのエスケープ文字を変更する。変更すると数割遅くなります。
// 変更前に作成されたインスタンスのエスケープ文字には影響しない。
// character が使用できない文字の場合には例外を発生する。
+ (void)setDefaultEscapeCharacter:(NSString*)character
{
	// \の代替文字
	// characterが使用可能な文字か調べる。
	switch ([[self class] kindOfCharacter:character]) {
		case OgreKindOfNil:
			// nilのとき、エラー
			[NSException raise:NSInvalidArgumentException format:@"nil string (or other) argument"];
			break;
		case OgreKindOfEmpty:
			// 空白のとき、エラー
			[NSException raise:NSInvalidArgumentException format:@"empty string argument"];
			break;
		case OgreKindOfBackslash:
			// @"\\"
			[OgrePrivateDefaultEscapeCharacter autorelease];
			OgrePrivateDefaultEscapeCharacter = [OgreBackslashCharacter retain];
			break;
		case OgreKindOfNormal:
			// 普通の文字
			[OgrePrivateDefaultEscapeCharacter autorelease];
			OgrePrivateDefaultEscapeCharacter = [[character substringWithRange:NSMakeRange(0,1)] retain];
			break;
		case OgreKindOfSpecial:
			// 特殊文字。エラー。
			[NSException raise:NSInvalidArgumentException format:@"invalid candidate for an escape character"];
			break;
	}
}

// 現在のデフォルトの正規表現構文。初期値はRuby
+ (OgreSyntax)defaultSyntax
{
	return OgrePrivateDefaultSyntax;
}

// デフォルトの正規表現構文を変更する。
// 変更前に作成されたインスタンスには影響を与えない。
+ (void)setDefaultSyntax:(OgreSyntax)syntax
{
	onig_set_default_syntax([[self class] onigSyntaxTypeForSyntax:syntax]);
	
	OgrePrivateDefaultSyntax = syntax;
}


// OgreKitのバージョン文字列を返す
+ (NSString*)version
{
	return OgreVersionString;
}


// onigurumaのバージョン文字列を返す
+ (NSString*)onigurumaVersion
{
	return [NSString stringWithCString:onig_version() encoding:NSASCIIStringEncoding];
}


// NSCoding protocols
- (void)encodeWithCoder:(NSCoder*)encoder
{
#ifdef DEBUG_OGRE
	NSLog(@"-encodeWithCoder: of %@", [self className]);
#endif
	//[super encodeWithCoder:encoder]; NSObject does ont respond to method encodeWithCoder:

	// NSString			*_escapeCharacter;
	// NSString			*_expressionString;
	// unsigned		_options;
	// OnigSyntaxType		*_syntax;
	// onig_t				*_regexBuffer;はencodeしない。

    if ([encoder allowsKeyedCoding]) {
		[encoder encodeObject: [self escapeCharacter] forKey: OgreEscapeCharacterKey];
		[encoder encodeObject: [self expressionString] forKey: OgreExpressionStringKey];
		[encoder encodeObject: [NSNumber numberWithUnsignedInt: [self options]] forKey: OgreOptionsKey];
		[encoder encodeObject: [NSNumber numberWithInt: [self syntax]] forKey: OgreSyntaxKey];
	} else {
		[encoder encodeObject: [self escapeCharacter]];
		[encoder encodeObject: [self expressionString]];
		[encoder encodeObject: [NSNumber numberWithUnsignedInt: [self options]]];
		[encoder encodeObject: [NSNumber numberWithInt: [self syntax]]];
	}
}

- (id)initWithCoder:(NSCoder*)decoder
{
#ifdef DEBUG_OGRE
	NSLog(@"-initWithCoder: of %@", [self className]);
#endif
	NSString		*escapeCharacter;
	NSString		*expressionString;
	id				anObject;
	unsigned		options;
	OgreSyntax		syntax = 0;
	
	BOOL			allowsKeyedCoding = [decoder allowsKeyedCoding];
	
	
	// NSString			*_escapeCharacter;
    if (allowsKeyedCoding) {
		escapeCharacter = [decoder decodeObjectForKey:OgreEscapeCharacterKey];
	} else {
		escapeCharacter = [decoder decodeObject];
	}
	if(escapeCharacter == nil) {
		// エラー。例外を発生させる。
		[NSException raise:NSInvalidUnarchiveOperationException format:@"fail to decode"];
	}
	
	// NSString			*_expressionString;
    if (allowsKeyedCoding) {
		expressionString = [decoder decodeObjectForKey:OgreExpressionStringKey];
	} else {
		expressionString = [decoder decodeObject];
	}
	if(expressionString == nil) {
		// エラー。例外を発生させる。
		[NSException raise:NSInvalidUnarchiveOperationException format:@"fail to decode"];
	}

	// unsigned		_options;
    if (allowsKeyedCoding) {
		anObject = [decoder decodeObjectForKey:OgreOptionsKey];
	} else {
		anObject = [decoder decodeObject];
	}
	if(anObject == nil) {
		// エラー。例外を発生させる。
		[NSException raise:NSInvalidUnarchiveOperationException format:@"fail to decode"];
	}
	options = [anObject unsignedIntValue];

	// OnigSyntaxType		*_syntax;
	// 要改善点。独自のsyntaxを用意した場合はencodeできない。
    if (allowsKeyedCoding) {
		anObject = [decoder decodeObjectForKey:OgreSyntaxKey];
	} else {
		anObject = [decoder decodeObject];
	}
	if(anObject == nil) {
		// エラー。例外を発生させる。
		[NSException raise:NSInvalidUnarchiveOperationException format:@"fail to decode"];
	}
	syntax = [anObject intValue];

	// onig_t				*_regexBuffer;
	return [self initWithString:expressionString 
		options:options 
		syntax:syntax 
		escapeCharacter:escapeCharacter];	
}

// NSCopying protocol
- (id)copyWithZone:(NSZone*)zone
{
#ifdef DEBUG_OGRE
	NSLog(@"-copyWithZone: of %@", [self className]);
#endif
	return [[[self class] allocWithZone:zone]
		initWithString:[self expressionString] 
		options:[self options] 
		syntax:[self syntax] 
		escapeCharacter:[self escapeCharacter]];
}

// description
- (NSString*)description
{
	NSDictionary	*dictionary = [NSDictionary 
		dictionaryWithObjects: [NSArray arrayWithObjects: 
			[self escapeCharacter], 
			[self expressionString], 
			[[self class] stringsForOptions:[self options]], 
			[[self class] stringForSyntax:[self syntax]], 
			((_groupIndexForNameDictionary != nil)? (_groupIndexForNameDictionary) : ([NSDictionary dictionary])), 
			nil]
		forKeys: [NSArray arrayWithObjects: 
			@"Escape Character", 
			@"Expression String", 
			@"Options", 
			@"Syntax", 
			@"Group Index for Name", 
			nil]
		];

	return [dictionary description];
}

// capture groupの数
- (unsigned)numberOfGroups
{
    return onig_number_of_captures(_regexBuffer);
}

// name groupの数
- (unsigned)numberOfNames
{
	return onig_number_of_names(_regexBuffer);
}
// nameの配列
// named groupを使用していない場合はnilを返す。
- (NSArray*)names
{
	return [_groupIndexForNameDictionary allKeys];
}

// OgreSyntaxとintの相互変換
+ (int)intValueForSyntax:(OgreSyntax)syntax
{
	if(syntax == OgreSimpleMatchingSyntax) return 0;
	if(syntax == OgrePOSIXBasicSyntax) return 1;
	if(syntax == OgrePOSIXExtendedSyntax) return 2;
	if(syntax == OgreEmacsSyntax) return 3;
	if(syntax == OgreGrepSyntax) return 4;
	if(syntax == OgreGNURegexSyntax) return 5;
	if(syntax == OgreJavaSyntax) return 6;
	if(syntax == OgrePerlSyntax) return 7;
	if(syntax == OgreRubySyntax) return 8;
	
	[NSException raise:OgreException format:@"unknown syntax."];
	return -1;	// dummy
}

+ (OgreSyntax)syntaxForIntValue:(int)intValue
{
	if(intValue == 0) return OgreSimpleMatchingSyntax;
	if(intValue == 1) return OgrePOSIXBasicSyntax;
	if(intValue == 2) return OgrePOSIXExtendedSyntax;
	if(intValue == 3) return OgreEmacsSyntax;
	if(intValue == 4) return OgreGrepSyntax;
	if(intValue == 5) return OgreGNURegexSyntax;
	if(intValue == 6) return OgreJavaSyntax;
	if(intValue == 7) return OgrePerlSyntax;
	if(intValue == 8) return OgreRubySyntax;
	
	[NSException raise:OgreException format:@"unknown syntax."];
	return 0;	// dummy
}

// OgreSyntaxを表す文字列
+ (NSString*)stringForSyntax:(OgreSyntax)syntax
{
	if(syntax == OgreSimpleMatchingSyntax) return @"Simple Matching";
	if(syntax == OgrePOSIXBasicSyntax) return @"POSIX Basic";
	if(syntax == OgrePOSIXExtendedSyntax) return @"POSIX Extended";
	if(syntax == OgreEmacsSyntax) return @"Emacs";
	if(syntax == OgreGrepSyntax) return @"Grep";
	if(syntax == OgreGNURegexSyntax) return @"GNU Regex";
	if(syntax == OgreJavaSyntax) return @"Java";
	if(syntax == OgrePerlSyntax) return @"Perl";
	if(syntax == OgreRubySyntax) return @"Ruby";
	
	return @"Unknown";
}

// Optionsを表す文字列の配列
+ (NSArray*)stringsForOptions:(unsigned)options
{
	NSMutableArray	*array = [NSMutableArray arrayWithCapacity:0];
	
	if (options & OgreSingleLineOption) [array addObject:@"Single Line"];
	if (options & OgreMultilineOption) [array addObject:@"Multiline"];
	if (options & OgreIgnoreCaseOption) [array addObject:@"Ignore Case"];
	if (options & OgreExtendOption) [array addObject:@"Extend"];
	if (options & OgreFindLongestOption) [array addObject:@"Find Longest"];
	if (options & OgreFindNotEmptyOption) [array addObject:@"Find Not Empty"];
	if (options & OgreNegateSingleLineOption) [array addObject:@"Negate Single Line"];
	if (options & OgreDontCaptureGroupOption) [array addObject:@"Don't Capture Group"];
	if (options & OgreCaptureGroupOption) [array addObject:@"Capture Group"];
	if (options & OgreDelimitByWhitespaceOption) [array addObject:@"Delimit by Whitespace"];
	if (options & OgreNotBOLOption) [array addObject:@"Not Begin of Line"];
	if (options & OgreNotEOLOption) [array addObject:@"Not End Of Line"];
	if (options & OgreFindEmptyOption) [array addObject:@"Find Empty"];
	if (options & OgreReplaceWithAttributesOption) [array addObject:@"Replace With Attributes"];
	if (options & OgreReplaceFontsOption) [array addObject:@"Replace Fonts"];
	if (options & OgreMergeAttributesOption) [array addObject:@"Merge Attributes"];
	
	return array;
}

// 文字列を正規表現で安全な文字列に変換する。(特殊文字をする)
+ (NSString*)regularizeString:(NSString*)string
{
	if (string == nil) {
		[NSException raise:NSInvalidArgumentException format:@"nil string (or other) argument"];
	}

	NSMutableString	*regularizedString = [NSMutableString stringWithString:string];
	
	unsigned	counterOfAutorelease = 0;
	NSAutoreleasePool	*pool = [[NSAutoreleasePool alloc] init];
	
	unsigned	strlen;
	NSRange 	searchRange, matchRange;
	strlen = [regularizedString length];
	searchRange = NSMakeRange(0, strlen);
	
	/* @"|().?*+{}^$[]-&#:=!<>@"を退避する */
	while ( matchRange = [regularizedString rangeOfCharacterFromSet:OgrePrivateUnsafeCharacterSet options:0 range:searchRange], 
			matchRange.length > 0 ) {

		[regularizedString insertString:OgreBackslashCharacter atIndex:matchRange.location];
		strlen += 1;
		searchRange.location = matchRange.location + 2;
		searchRange.length   = strlen - searchRange.location;
		
		/* release autorelease pool */
		counterOfAutorelease++;
		if (counterOfAutorelease % 100 == 0) {
			[pool release];
			pool = [[NSAutoreleasePool alloc] init];
		}
	}
	[pool release];
	
	//NSLog(@"%@", regularizedString);
	return regularizedString;
}

/**************
 * 文字列の分割 *
 **************/
// マッチした部分で文字列を分割し、NSArrayに収めて返す。
- (NSArray*)splitString:(NSString*)aString
{
	return [self splitString:aString 
		options:OgreNoneOption 
		range:NSMakeRange(0, [aString length]) 
		limit:0];
}

- (NSArray*)splitString:(NSString*)aString 
	options:(unsigned)options
{
	return [self splitString:aString 
		options:options 
		range:NSMakeRange(0, [aString length]) 
		limit:0];
}
	
- (NSArray*)splitString:(NSString*)aString 
	options:(unsigned)options 
	range:(NSRange)searchRange
{
	return [self splitString:aString 
		options:options 
		range:searchRange 
		limit:0];
}
	
/*
 分割数limitの意味 (例は@","にマッチさせた場合のもの)
	limit >  0:				最大でlimit個の単語に分割する。limit==3のとき、@"a,b,c,d,e" -> (@"a", @"b", @"c,d,e")
	limit == 0(デフォルト):	最後が空文字列のときは無視する。@"a,b,c," -> (@"a", @"b", @"c")
	limit <  0:				最後が空文字列でも含める。@"a,b,c," -> (@"a", @"b", @"c", @"")
 */
- (NSArray*)splitString:(NSString*)aString 
	options:(unsigned)options 
	range:(NSRange)searchRange
	limit:(int)limit 
{
	NSMutableArray	*words = [NSMutableArray arrayWithCapacity:1];
	
	NSEnumerator	*enumerator = [self matchEnumeratorInString:aString 
		options:options 
		range:searchRange];
	
	unsigned	matches = 0;
	OGRegularExpressionMatch	*match, *lastMatch = nil;
	NSString	*remainingString;
	
	NSAutoreleasePool	*pool = [[NSAutoreleasePool alloc] init];
	
	while ((match = [enumerator nextObject]) != nil) {
		matches++;
		if ((limit > 0) && (matches == limit)) break; 
		
		// 単語を追加する。
		[words addObject:[match stringBetweenMatchAndLastMatch]];
		lastMatch = match;
		
		if (matches % 100 == 0) {
			[lastMatch retain];
			[pool release];
			pool = [[NSAutoreleasePool alloc] init];
			[lastMatch autorelease];
		}
	}
	
	remainingString = ((lastMatch)? [lastMatch postmatchString] : aString);
	if (([remainingString length] != 0) || (limit != 0) || (lastMatch == nil)) {
		// limit == 0 && [remainingString length] == 0 の場合以外は残りを加える。
		// (一つもマッチしなかった場合はaStringを加える。)
		[words addObject:remainingString];
	}
	
	[pool release];
	
	return words;
}

// 改行コードをnewlineCharacterに統一する。
+ (NSString*)replaceNewlineCharactersInString:(NSString*)aString withCharacter:(OgreNewlineCharacter)newlineCharacter;
{
	NSMutableString	*convertedString = [NSMutableString string];
	NSString		*aCharacter;
	NSString		*newlineString = nil;
	if (newlineCharacter == OgreLfNewlineCharacter) {
		// LF
		newlineString = @"\n";
	} else if (newlineCharacter == OgreCrNewlineCharacter) {
		// CR
		newlineString = @"\r";
	} else if (newlineCharacter == OgreCrLfNewlineCharacter) {
		// CR+LF
		newlineString = @"\r\n";
	}  else if (newlineCharacter == OgreUnicodeLineSeparatorNewlineCharacter) {
		// Unicode line separator
		newlineString = OgrePrivateUnicodeLineSeparator;
	} else if (newlineCharacter == OgreUnicodeParagraphSeparatorNewlineCharacter) {
		// Unicode paragraph separator
		newlineString = OgrePrivateUnicodeParagraphSeparator;
	} else if (newlineCharacter == OgreNonbreakingNewlineCharacter) {
		// 改行なしの場合
		newlineString = @"";
	}
	
	/* 改行コードを置換する */
	unsigned			counterOfAutorelease = 0;
	NSAutoreleasePool	*pool = [[NSAutoreleasePool alloc] init];
	
	unsigned	strlen = [aString length], 
				matchLocation, 
				copyLocation = 0;
	NSRange 	searchRange = NSMakeRange(0, strlen), 
				matchRange;
	while ( matchRange = [aString rangeOfCharacterFromSet:OgrePrivateNewlineCharacterSet options:0 range:searchRange], 
			matchRange.length > 0 ) {
		// マッチした部分より前をコピー
		matchLocation = matchRange.location;
		copyLocation = searchRange.location;
		[convertedString appendString:[aString substringWithRange:NSMakeRange(copyLocation, matchLocation - copyLocation)]];
		// 所望の改行コードをコピー
		[convertedString appendString:newlineString];
		
		// CR or LF以降を次の検索範囲にする。
		searchRange.location = matchLocation + 1;
		searchRange.length = strlen - (matchLocation + 1);
		
		// CR+LFにマッチした場合は次の検索範囲を更に1文字進める
		aCharacter = [aString substringWithRange:NSMakeRange(matchLocation, 1)];
		if ([aCharacter isEqualToString:@"\r"] && (matchLocation < (strlen - 1))) {
			aCharacter = [aString substringWithRange:NSMakeRange(matchLocation + 1, 1)];
			if ([aCharacter isEqualToString:@"\n"]) {
				searchRange.location++;
				searchRange.length--;
			}
		}
		
		/* release autorelease pool */
		counterOfAutorelease++;
		if (counterOfAutorelease % 100 == 0) {
			[pool release];
			pool = [[NSAutoreleasePool alloc] init];
		}
	}
	// 残りをコピー
	copyLocation = searchRange.location;
	[convertedString appendString:[aString substringWithRange:NSMakeRange(copyLocation, strlen - copyLocation)]];
	
	[pool release];
	
	return convertedString;
}

// 改行コードが何か調べる
+ (OgreNewlineCharacter)newlineCharacterInString:(NSString*)aString
{
	NSString				*aCharacter;
	OgreNewlineCharacter	newlineCharacter = OgreNonbreakingNewlineCharacter;	// no linefeeds
	
	/* search newline characters */
	unsigned	strlen = [aString length], matchLocation;
	NSRange 	searchRange = NSMakeRange(0, strlen), matchRange;
	if ( matchRange = [aString rangeOfCharacterFromSet:OgrePrivateNewlineCharacterSet options:0 range:searchRange], 
			matchRange.length > 0 ) {
		matchLocation = matchRange.location;
		aCharacter = [aString substringWithRange:NSMakeRange(matchLocation, 1)];
		if ([aCharacter isEqualToString:@"\n"]) {
			// LF
			newlineCharacter = OgreLfNewlineCharacter;
		} else if ([aCharacter isEqualToString:@"\r"]) {
			// CR
			if ((matchLocation < (strlen - 1)) && 
					[[aString substringWithRange:NSMakeRange(matchLocation + 1, 1)] isEqualToString:@"\n"]) {
				// CR+LF
				newlineCharacter = OgreCrLfNewlineCharacter;
			} else {
				// CR
				newlineCharacter = OgreCrNewlineCharacter;
			}
		} else if ([aCharacter isEqualToString:OgrePrivateUnicodeLineSeparator]) {
			// Unicode line separator
			newlineCharacter = OgreUnicodeLineSeparatorNewlineCharacter;
		} else if ([aCharacter isEqualToString:OgrePrivateUnicodeParagraphSeparator]) {
			// Unicode paragraph separator
			newlineCharacter = OgreUnicodeParagraphSeparatorNewlineCharacter;
		}
		
		
		if ([aCharacter isEqualToString:@"\r"] && (matchLocation < (strlen - 1))) {
			aCharacter = [aString substringWithRange:NSMakeRange(matchLocation + 1, 1)];
			if ([aCharacter isEqualToString:@"\n"]) {
				searchRange.location++;
				searchRange.length--;
			}
		}
	}
	
	return newlineCharacter;
}

// remove newline characters
+ (NSString*)chomp:(NSString*)aString
{
	return [[self class] replaceNewlineCharactersInString:aString withCharacter:OgreNonbreakingNewlineCharacter];
}

@end
