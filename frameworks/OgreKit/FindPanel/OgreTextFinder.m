/*
 * Name: OgreTextFinder.m
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

#import <OgreKit/OgreTextFinder.h>

/* Foundation */
#import <OgreKit/OGReplaceExpression.h>
#import <OgreKit/OGRegularExpressionMatch.h>
#import <OgreKit/OGPlainString.h>
#import <OgreKit/OGAttributedString.h>

/* Threads */
#import <OgreKit/OgreTextFindThread.h>
// concrete implementors
#import <OgreKit/OgreFindAllThread.h>
#import <OgreKit/OgreReplaceAllThread.h>
#import <OgreKit/OgreHighlightThread.h>
#import <OgreKit/OgreUnhighlightThread.h>
#import <OgreKit/OgreFindThread.h>
#import <OgreKit/OgreReplaceAndFindThread.h>

/* Adapters */
#import <OgreKit/OgreTextFindComponent.h>
#import <OgreKit/OgreTextFindLeaf.h>
#import <OgreKit/OgreTextFindBranch.h>
// concrete implementors
// TextView
#import <OgreKit/OgreTextViewAdapter.h>
// TableView
#import <OgreKit/OgreTableViewAdapter.h>
// OutlineView
#import <OgreKit/OgreOutlineViewAdapter.h>

/* Views */
#import <OgreKit/OgreView.h>

/* Find Results */
#import <OgreKit/OgreTextFindResult.h>
#import <OgreKit/OgreFindResultLeaf.h>
#import <OgreKit/OgreFindResultBranch.h>

/* Controllers */
#import <OgreKit/OgreTextFindProgressSheet.h>
#import <OgreKit/OgreFindPanelController.h>


// singleton
static OgreTextFinder	*_sharedTextFinder = nil;

// 例外名
NSString	*OgreTextFinderException = @"OgreTextFinderException";

// encode/decodeに使用するKey
static NSString	*OgreTextFinderHistoryKey         = @"Find Controller History";
static NSString	*OgreTextFinderSyntaxKey          = @"Syntax";
static NSString	*OgreTextFinderEscapeCharacterKey = @"Escape Character";

@implementation OgreTextFinder

+ (NSBundle*)ogreKitBundle
{
	static NSBundle *theBundle = nil;
	
	if (theBundle == nil) {
		/* OgreKit.framework bundle instanceを探す */
		NSArray			*allFrameworks = [NSBundle allFrameworks];  // リンクされている全フレームワーク
		NSEnumerator	*enumerator = [allFrameworks reverseObjectEnumerator];  // OgreKitは後ろにある可能性が高い
		NSBundle		*aBundle;
		while ((aBundle = [enumerator nextObject]) != nil) {
			if ([[[aBundle bundlePath] lastPathComponent] isEqualToString:@"OgreKit.framework"]) {
#ifdef DEBUG_OGRE_FIND_PANEL
				NSLog(@"Find out OgreKit: %@", [aBundle bundlePath]);
#endif
				theBundle = [aBundle retain];
				break;
			}
		}
	}
	
	return theBundle;
}

+ (id)sharedTextFinder
{
	if (_sharedTextFinder == nil) {
		_sharedTextFinder = [[[self class] alloc] init];
	}
	
	return _sharedTextFinder;
}

- (id)init
{
#ifdef DEBUG_OGRE_FIND_PANEL
	NSLog(@"-init of %@", [self className]);
#endif
	if (_sharedTextFinder != nil) {
		[super release];
		return _sharedTextFinder;
	}
	
	self = [super init];
	if (self != nil) {
		_busyTargetArray = [[NSMutableArray alloc] initWithCapacity:0];	// 使用中ターゲット
		
		NSUserDefaults	*defaults = [NSUserDefaults standardUserDefaults];
		NSDictionary	*fullHistory = [defaults dictionaryForKey:@"OgreTextFinder"];	// 履歴等
		
		if (fullHistory != nil) {
			_history = [[fullHistory objectForKey: OgreTextFinderHistoryKey] retain];

			id		anObject = [fullHistory objectForKey: OgreTextFinderSyntaxKey];
			if(anObject == nil) {
				[self setSyntax:[OGRegularExpression defaultSyntax]];
			} else {
				_syntax = [OGRegularExpression syntaxForIntValue:[anObject intValue]];
			}
				
			_escapeCharacter = [[fullHistory objectForKey: OgreTextFinderEscapeCharacterKey] retain];
			if(_escapeCharacter == nil) {
				[self setEscapeCharacter:[OGRegularExpression defaultEscapeCharacter]];
			}
		} else {
			_history = nil;
			[self setSyntax:[OGRegularExpression defaultSyntax]];
			[self setEscapeCharacter:[OGRegularExpression defaultEscapeCharacter]];
		}
		
		_saved = NO;
		// Applicationのterminationを拾う (履歴保存のタイミング)
		[[NSNotificationCenter defaultCenter] addObserver: self 
				selector: @selector(appWillTerminate:) 
				name: NSApplicationWillTerminateNotification
				object: NSApp];
		// Applicationのlaunchを拾う (Findメニューの設定のタイミング)
		[[NSNotificationCenter defaultCenter] addObserver: self 
				selector: @selector(appDidFinishLaunching:) 
				name: NSApplicationDidFinishLaunchingNotification
				object: NSApp];
		
		[NSBundle loadNibNamed:[self findPanelNibName] owner:self];
		
		_sharedTextFinder = self;
		_shouldHackFindMenu = YES;
		_useStylesInFindPanel = YES;
		
		/* registering adapters for targets */
		_adapterClassArray = [[NSMutableArray alloc] initWithCapacity:1];
		_targetClassArray = [[NSMutableArray alloc] initWithCapacity:1];
		// NSTextView
		[self registeringAdapterClass:[OgreTextViewAdapter class] forTargetClass:[NSTextView class]];
	}
	
	return self;
}

- (void)setShouldHackFindMenu:(BOOL)hack
{
	_shouldHackFindMenu = hack;
}

- (void)setUseStylesInFindPanel:(BOOL)use
{
	_useStylesInFindPanel = use;
}

- (BOOL)useStylesInFindPanel
{
	return _useStylesInFindPanel;
}


- (void)appDidFinishLaunching:(NSNotification*)aNotification
{
#ifdef DEBUG_OGRE_FIND_PANEL
	NSLog(@"-appDidFinishLaunching: of %@", [self className]);
#endif
	[[NSNotificationCenter defaultCenter] removeObserver:self 
		name: NSApplicationDidFinishLaunchingNotification 
		object: NSApp];
	
	/* send 'ogreKitWillHackFindMenu:' message to the responder chain */
	[NSApp sendAction:@selector(ogreKitWillHackFindMenu:) to:nil from:self];
	/*
		if you don't want to use OgreKit's Find Panel, 
		implement the following method in the subclass or delegate of NSApplication.
		- (void)ogreKitWillHackFindMenu:(OgreTextFinder*)textFinder
		{
			[textFinder setShouldHackFindMenu:NO];
		}
	*/
	
	/* send 'ogreKitShouldUseStylesInFindPanel:' message to the responder chain */
	[NSApp sendAction:@selector(ogreKitShouldUseStylesInFindPanel:) to:nil from:self];
	/*
		if you don't want to use "Replace With Styles" in the Find Panel, 
		add the following method to the subclass or delegate of NSApplication.
		- (void)ogreKitShouldUseStylesInFindPanel:(OgreTextFinder*)textFinder
		{
			[textFinder setShouldUseStylesInFindPanel:NO];
		}
	*/
	
	if (!_shouldHackFindMenu) return;
	
	/* Checking the Mac OS X version */
	if (floor(NSAppKitVersionNumber) <= NSAppKitVersionNumber10_0) {
		/* On a 10.0.x or earlier system */
		return; // use the default Find Panel
	} else if (floor(NSAppKitVersionNumber) <= NSAppKitVersionNumber10_1) {
		/* On a 10.1 - 10.1.x system */
		return; // use the default Find Panel
	} else if (floor(NSAppKitVersionNumber) <= NSAppKitVersionNumber10_2) {
		/* On a 10.2 - 10.2.x system */
		return; // use the default Find Panel
	} else {
		/* 10.3 or later system */
		[self hackFindMenu];
	}
}

- (void)hackFindMenu
{
	/* set up Find menu */
	if (findMenu == nil) {
		// findPanelNibの中にFindメニューが見つからなかったとき
		NSLog(@"Find Menu not found in %@.nib", [self findPanelNibName]);
	} else {
		// Findメニューのタイトル
		NSString    *titleOfFindMenu = OgreTextFinderLocalizedString(@"Find");
		
		// Findメニューの初期化
		[findMenu setTitle:titleOfFindMenu];
        NSMenuItem  *newFindMenuItem = [[[NSMenuItem allocWithZone:[NSMenu menuZone]] init] autorelease];
		[newFindMenuItem setTitle:titleOfFindMenu];
		[newFindMenuItem setSubmenu:findMenu];
		
		NSMenu		*mainMenu = [NSApp mainMenu];
		
		NSMenuItem  *oldFindMenuItem = [self findMenuItemNamed:titleOfFindMenu startAt:mainMenu];
		// Findメニューが既にある場合はそこをfindMenuに入れ替える
		// なければ左から4番目にFindメニューを作り、そこにfindMenuをセットする。
		if (oldFindMenuItem != nil) {
			//NSLog(@"Find found");
			NSMenu		*supermenu = [oldFindMenuItem menu];
			[supermenu insertItem:newFindMenuItem atIndex:[supermenu indexOfItem:oldFindMenuItem]];
			[supermenu removeItem:oldFindMenuItem];
		} else {
			//NSLog(@"Find not found");
			[mainMenu insertItem:newFindMenuItem atIndex:3];
		}
		[mainMenu update];
	}
}

// currentを起点に名前がnameのmenu itemを探す。
- (NSMenuItem*)findMenuItemNamed:(NSString*)name startAt:(NSMenu*)current
{
	NSMenuItem  *foundMenuItem = nil;
	if (current == nil) return nil;
	
	NSAutoreleasePool	*pool = [[NSAutoreleasePool alloc] init];
	
	int i, n;
	NSMutableArray	*menuArray = [NSMutableArray arrayWithObject:current];
	while ([menuArray count] > 0) {
		NSMenu      *aMenu = [menuArray objectAtIndex:0];
		NSMenuItem  *aMenuItem = [aMenu itemWithTitle:name];
		if (aMenuItem != nil) {
			// 見つかった場合
			foundMenuItem = [aMenuItem retain];
			break;
		}
		
		// 見つからなかった場合
		n = [aMenu numberOfItems];
		for (i=0; i<n; i++) {
			aMenuItem = [aMenu itemAtIndex:i];
			//NSLog(@"%@", [aMenuItem title]);
			if ([aMenuItem hasSubmenu]) [menuArray addObject:[aMenuItem submenu]];
		}
		[menuArray removeObjectAtIndex:0];
	}
	
	[pool release];
	
	return [foundMenuItem autorelease];
}

- (void)appWillTerminate:(NSNotification*)aNotification
{
#ifdef DEBUG_OGRE_FIND_PANEL
	NSLog(@"-appWillTerminate: of %@", [self className]);
#endif
	[[NSNotificationCenter defaultCenter] removeObserver:self 
		name: NSApplicationWillTerminateNotification 
		object: NSApp];
	
	// 検索履歴等の保存
	NSDictionary	*fullHistory = [NSDictionary dictionaryWithObjects:[NSArray arrayWithObjects: 
			[findPanelController history],
			[NSNumber numberWithInt:[OGRegularExpression intValueForSyntax:_syntax]], 
			_escapeCharacter, 
			nil]
		forKeys:[NSArray arrayWithObjects: 
			OgreTextFinderHistoryKey, 
			OgreTextFinderSyntaxKey,
			OgreTextFinderEscapeCharacterKey,
			nil]];
	
	NSUserDefaults	*defaults = [NSUserDefaults standardUserDefaults];
	[defaults setObject:fullHistory forKey:@"OgreTextFinder"];
	[defaults synchronize];
	
	_saved = YES;
}

- (NSDictionary*)history	// 非公開メソッド
{
#ifdef DEBUG_OGRE_FIND_PANEL
	NSLog(@"-history of %@", [self className]);
#endif
	NSDictionary	*history = _history;
	_history = nil;
	
	return [history autorelease];
}

#ifdef MAC_OS_X_VERSION_10_6
- (void)finalize
{
#ifdef DEBUG_OGRE_FIND_PANEL
	NSLog(@"CAUTION! -finalize of %@", [self className]);
#endif
	[[NSNotificationCenter defaultCenter] removeObserver:self];
	if (_saved == NO) [self appWillTerminate:nil];	// 履歴の保存がまだならば保存する。
	_sharedTextFinder = nil;
    [super finalize];
}
#endif

- (void)dealloc
{
#ifdef DEBUG_OGRE_FIND_PANEL
	NSLog(@"CAUTION! -dealloc of %@", [self className]);
#endif
	[[NSNotificationCenter defaultCenter] removeObserver:self];

	if (_saved == NO) [self appWillTerminate:nil];	// 履歴の保存がまだならば保存する。
	
	[_targetClassArray release];
	[_adapterClassArray release];
	[findPanelController release];
	[_history release];
	[_escapeCharacter release];
	[_busyTargetArray release];
	_sharedTextFinder = nil;
	
	[super dealloc];
}

- (IBAction)showFindPanel:(id)sender
{
	[findPanelController showFindPanel:self];
}

- (NSString *)findPanelNibName
{
	return @"OgreAdvancedFindPanel";
}

/* accessors */

- (void)setFindPanelController:(OgreFindPanelController*)aFindPanelController
{
	[findPanelController autorelease];
	findPanelController = [aFindPanelController retain];
}

- (OgreFindPanelController*)findPanelController
{
	return findPanelController;
}

- (void)setEscapeCharacter:(NSString*)character
{
	[character retain];
	[_escapeCharacter release];
	_escapeCharacter = character;
}

- (NSString*)escapeCharacter
{
	return _escapeCharacter;
}

- (void)setSyntax:(OgreSyntax)syntax
{
	//NSLog(@"%d", [OGRegularExpression intValueForSyntax:syntax]);
	_syntax = syntax;
}

- (OgreSyntax)syntax
{
	return _syntax;
}

/* 検索対象 */
- (void)setTargetToFindIn:(id)target
{
#ifdef DEBUG_OGRE_FIND_PANEL
	NSLog(@"-setTargetToFindIn:\"%@\" of %@", [target className], [self className]);
#endif
	_targetToFindIn = target;
}

- (id)targetToFindIn
{
#ifdef DEBUG_OGRE_FIND_PANEL
	NSLog(@"-targetToFindIn of %@", [self className]);
#endif
	id	target = nil;
	[self setTargetToFindIn:nil];
	[self setAdapterClassForTargetToFindIn:Nil];
	
	/* responder chainにtellMeTargetToFindIn:を投げる */
	if ([NSApp sendAction:@selector(tellMeTargetToFindIn:) to:nil from:self]) {
		// tellMeTargetToFindIn:に応答があった場合、
		//NSLog(@"succeed to perform tellMeTargetToFindIn:");
		if ([self hasAdapterClassForObject:_targetToFindIn]) target = _targetToFindIn;
	} else {
		// 応答がない場合、main windowのfirst responderがNSTextViewならばそれを採用する。
		//NSLog(@"failed to perform tellMeTargetToFindIn:");
		id	anObject = [[NSApp mainWindow] firstResponder];
		if (anObject != nil && [self hasAdapterClassForObject:anObject]) target = anObject;
	}
	
	return target;
}


- (BOOL)isBusyTarget:(id)target
{
	return [_busyTargetArray containsObject:target];
}

- (void)makeTargetBusy:(id)target
{
	if (target != nil) [_busyTargetArray addObject:target];
}

- (void)makeTargetFree:(id)target
{
	if (target != nil) [_busyTargetArray removeObject:target];
}

/* Find/Replace/Highlight... */

- (OgreTextFindResult*)find:(NSString*)expressionString 
	options:(unsigned)options
	fromTop:(BOOL)isFromTop
	forward:(BOOL)forward
	wrap:(BOOL)isWrap
{
	id	target = [self targetToFindIn];
	if ((target == nil) || [self isBusyTarget:target]) return [OgreTextFindResult textFindResultWithTarget:target thread:nil];
	[self makeTargetBusy:target];

	OgreFindThread			  *thread = nil;
	OgreTextFindProgressSheet	*sheet = nil;
	OgreTextFindResult		  *textFindResult = nil;
	
	NS_DURING
	
		OGRegularExpression	*regex = [OGRegularExpression regularExpressionWithString:expressionString
			options:options
			syntax:[self syntax] 
			escapeCharacter:[self escapeCharacter]];
		
		/* スレッドの生成 */
		id	adapter = [self adapterForTarget:target];
		thread = [[[OgreFindThread alloc] initWithComponent:adapter] autorelease];
		[thread setRegularExpression:regex];
		[thread setOptions:options];
		[thread setWrap:isWrap];
		[thread setBackward:!forward];
		[thread setFromTop:isFromTop];
		[thread setInSelection:NO];
		[thread setAsynchronous:NO];
		
		[thread detach];
		
		[self makeTargetFree:target];
		textFindResult = [thread result];
		
	NS_HANDLER
		
		textFindResult = [OgreTextFindResult textFindResultWithTarget:target thread:thread];
		[textFindResult setType:OgreTextFindResultError];
		[textFindResult setAlertSheet:sheet exception:localException];
		
	NS_ENDHANDLER
		
	return textFindResult;
}

- (OgreTextFindResult*)findAll:(NSString*)expressionString 
	color:(NSColor*)highlightColor 
	options:(unsigned)options
	inSelection:(BOOL)inSelection
{
#ifdef DEBUG_OGRE_FIND_PANEL
	NSLog(@"-findAll:... of %@", [self className]);
#endif

	id	target = [self targetToFindIn];
	if ((target == nil) || [self isBusyTarget:target]) return [OgreTextFindResult textFindResultWithTarget:target thread:nil];
	[self makeTargetBusy:target];

	OgreTextFindThread		  *thread = nil;
	OgreTextFindProgressSheet	*sheet = nil;
	OgreTextFindResult		  *textFindResult = nil;
	
	NS_DURING
	
		OGRegularExpression	*regex = [OGRegularExpression regularExpressionWithString:expressionString
			options:options
			syntax:[self syntax] 
			escapeCharacter:[self escapeCharacter]];
		
		/* 処理状況表示用シートの生成 */
		sheet = [[OgreTextFindProgressSheet alloc] initWithWindow:[target window] 
			title:OgreTextFinderLocalizedString(@"Find All") 
			didEndSelector:@selector(makeTargetFree:) 
			toTarget:self 
			withObject:target];
		
		/* スレッドの生成 */
		id	adapter = [self adapterForTarget:target];
		thread = [[[OgreFindAllThread alloc] initWithComponent:adapter] autorelease];
		[thread setRegularExpression:regex];
		[thread setHighlightColor:highlightColor];
		[thread setOptions:options];
		[thread setInSelection:inSelection];
		[thread setDidEndSelector:@selector(didEndThread:) toTarget:self];
		[thread setProgressDelegate:sheet];
		[thread setAsynchronous:YES];
		
		[thread detach];
		
		textFindResult = [OgreTextFindResult textFindResultWithTarget:target thread:thread];
		[textFindResult setType:OgreTextFindResultSuccess];
		
	NS_HANDLER
		
		textFindResult = [OgreTextFindResult textFindResultWithTarget:target thread:thread];
		[textFindResult setType:OgreTextFindResultError];
		[textFindResult setAlertSheet:sheet exception:localException];
		
	NS_ENDHANDLER
		
	return textFindResult;
}

- (OgreTextFindResult*)replace:(NSString*)expressionString 
	withString:(NSString*)replaceString
	options:(unsigned)options
{
	return [self replaceAndFind:[OGPlainString stringWithString:expressionString]
		withString:[OGPlainString stringWithString:replaceString] 
		options:options 
		replacingOnly:YES 
		wrap:NO];
}

- (OgreTextFindResult*)replace:(NSString*)expressionString 
	withAttributedString:(NSAttributedString*)replaceString
	options:(unsigned)options
{
	return [self replaceAndFind:[OGPlainString stringWithString:expressionString]
		withOGString:[OGAttributedString stringWithAttributedString:replaceString] 
		options:options 
		replacingOnly:YES 
		wrap:NO];
}

- (OgreTextFindResult*)replace:(NSObject<OGStringProtocol>*)expressionString 
	withOGString:(NSObject<OGStringProtocol>*)replaceString
	options:(unsigned)options
{
	return [self replaceAndFind:expressionString
		withOGString:replaceString 
		options:options 
		replacingOnly:YES 
		wrap:NO];
}

- (OgreTextFindResult*)replaceAndFind:(NSString*)expressionString 
	withString:(NSString*)replaceString
	options:(unsigned)options
	replacingOnly:(BOOL)replacingOnly 
	wrap:(BOOL)isWrap 
{
	return [self replaceAndFind:[OGPlainString stringWithString:expressionString] 
		withOGString:[OGPlainString stringWithString:replaceString] 
		options:options 
		replacingOnly:replacingOnly 
		wrap:isWrap];
}

- (OgreTextFindResult*)replaceAndFind:(NSString*)expressionString 
	withAttributedString:(NSAttributedString*)replaceString
	options:(unsigned)options
	replacingOnly:(BOOL)replacingOnly 
	wrap:(BOOL)isWrap 
{
	return [self replaceAndFind:[OGPlainString stringWithString:expressionString] 
		withOGString:[OGAttributedString stringWithAttributedString:replaceString] 
		options:options 
		replacingOnly:replacingOnly 
		wrap:isWrap];
}

- (OgreTextFindResult*)replaceAndFind:(NSObject<OGStringProtocol>*)expressionString 
	withOGString:(NSObject<OGStringProtocol>*)replaceString
	options:(unsigned)options
	replacingOnly:(BOOL)replacingOnly 
	wrap:(BOOL)isWrap 
{
#ifdef DEBUG_OGRE_FIND_PANEL
	NSLog(@"-replaceAndFind:... of %@", [self className]);
#endif

	id	target = [self targetToFindIn];
	if ((target == nil) || [self isBusyTarget:target] /*|| ![target isEditable]*/) return [OgreTextFindResult textFindResultWithTarget:target thread:nil];
	[self makeTargetBusy:target];
	
	OgreReplaceAndFindThread	*thread = nil;
	OgreTextFindProgressSheet	*sheet = nil;
	OgreTextFindResult			*textFindResult = nil;
	
	NS_DURING
	
		OGRegularExpression	*regex = [OGRegularExpression regularExpressionWithString:[expressionString string] 
			options:options
			syntax:[self syntax] 
			escapeCharacter:[self escapeCharacter]];
		
		OGReplaceExpression	*repex = [OGReplaceExpression replaceExpressionWithOGString:replaceString
			options:options 
			syntax:[self syntax] 
			escapeCharacter:[self escapeCharacter]];
		
		// スレッドの生成
		id	adapter = [self adapterForTarget:target];
		thread = [[[OgreReplaceAndFindThread alloc] initWithComponent:adapter] autorelease];
		[thread setRegularExpression:regex];
		[thread setReplaceExpression:repex];
		[thread setOptions:options];
		[thread setInSelection:NO];
		[thread setAsynchronous:NO];
		[thread setReplacingOnly:replacingOnly];
		[thread setWrap:isWrap];
		
		[thread detach];
		
		[self makeTargetFree:target];
		textFindResult = [thread result];
		
	NS_HANDLER
		
		textFindResult = [OgreTextFindResult textFindResultWithTarget:target thread:thread];
		[textFindResult setType:OgreTextFindResultError];
		[textFindResult setAlertSheet:sheet exception:localException];
		
	NS_ENDHANDLER
		
	return textFindResult;
}

- (OgreTextFindResult*)replaceAll:(NSString*)expressionString 
	withString:(NSString*)replaceString
	options:(unsigned)options
	inSelection:(BOOL)inSelection
{
	return [self replaceAll:[OGPlainString stringWithString:expressionString] 
		withOGString:[OGPlainString stringWithString:replaceString] 
		options:options 
		inSelection:inSelection];
}

- (OgreTextFindResult*)replaceAll:(NSString*)expressionString 
	withAttributedString:(NSAttributedString*)replaceString
	options:(unsigned)options
	inSelection:(BOOL)inSelection
{
	return [self replaceAll:[OGPlainString stringWithString:expressionString] 
		withOGString:[OGAttributedString stringWithAttributedString:replaceString] 
		options:options 
		inSelection:inSelection];
}

- (OgreTextFindResult*)replaceAll:(NSObject<OGStringProtocol>*)expressionString 
	withOGString:(NSObject<OGStringProtocol>*)replaceString
	options:(unsigned)options
	inSelection:(BOOL)inSelection
{
#ifdef DEBUG_OGRE_FIND_PANEL
	NSLog(@"-replaceAll:... of %@", [self className]);
#endif

	id	target = [self targetToFindIn];
	if ((target == nil) || [self isBusyTarget:target] /*|| ![target isEditable]*/) return [OgreTextFindResult textFindResultWithTarget:target thread:nil];
	[self makeTargetBusy:target];
	
	OgreTextFindThread			*thread = nil;
	OgreTextFindProgressSheet	*sheet = nil;
	OgreTextFindResult			*textFindResult = nil;
	
	NS_DURING
	
		OGRegularExpression	*regex = [OGRegularExpression regularExpressionWithString:[expressionString string] 
			options:options
			syntax:[self syntax] 
			escapeCharacter:[self escapeCharacter]];
		
		OGReplaceExpression	*repex = [OGReplaceExpression replaceExpressionWithOGString:replaceString
			options:options 
			syntax:[self syntax] 
			escapeCharacter:[self escapeCharacter]];
		
		/* 処理状況表示用シートの生成 */
		sheet = [[OgreTextFindProgressSheet alloc] initWithWindow:[target window] 
			title:OgreTextFinderLocalizedString(@"Replace All") 
			didEndSelector:@selector(makeTargetFree:) 
			toTarget:self 
			withObject:target];
		
		/* スレッドの生成 */
		id	adapter = [self adapterForTarget:target];
		thread = [[[OgreReplaceAllThread alloc] initWithComponent:adapter] autorelease];
		[thread setRegularExpression:regex];
		[thread setReplaceExpression:repex];
		[thread setOptions:options];
		[thread setInSelection:inSelection];
		[thread setDidEndSelector:@selector(didEndThread:) toTarget:self];
		[thread setProgressDelegate:sheet];
		[thread setAsynchronous:YES];
		
		[thread detach];
		
		textFindResult = [OgreTextFindResult textFindResultWithTarget:target thread:thread];
		[textFindResult setType:OgreTextFindResultSuccess];
		
	NS_HANDLER
		
		textFindResult = [OgreTextFindResult textFindResultWithTarget:target thread:thread];
		[textFindResult setType:OgreTextFindResultError];
		[textFindResult setAlertSheet:sheet exception:localException];
		
	NS_ENDHANDLER
		
	return textFindResult;
}


- (OgreTextFindResult*)unhightlight
{
#ifdef DEBUG_OGRE_FIND_PANEL
	NSLog(@"-unhightlight:... of %@", [self className]);
#endif

	id	target = [self targetToFindIn];
	if ((target == nil) || [self isBusyTarget:target]) return [OgreTextFindResult textFindResultWithTarget:target thread:nil];
	[self makeTargetBusy:target];
	
	OgreTextFindThread	*thread = nil;
	OgreTextFindResult	*textFindResult = nil;
	
	NS_DURING
	
		/* スレッドの生成 */
		id	adapter = [self adapterForTarget:target];
		thread = [[[OgreUnhighlightThread alloc] initWithComponent:adapter] autorelease];
		[thread setAsynchronous:NO];
		
		[thread detach];
		
		[self makeTargetFree:target];
		textFindResult = [thread result];
		
	NS_HANDLER
		
		textFindResult = [OgreTextFindResult textFindResultWithTarget:target thread:thread];
		[textFindResult setType:OgreTextFindResultError];
		[textFindResult setAlertSheet:nil exception:localException];
		
	NS_ENDHANDLER
		
	return textFindResult;
}

- (OgreTextFindResult*)hightlight:(NSString*)expressionString 
	color:(NSColor*)highlightColor 
	options:(unsigned)options
	inSelection:(BOOL)inSelection
{
#ifdef DEBUG_OGRE_FIND_PANEL
	NSLog(@"-hightlight:... of %@", [self className]);
#endif

	id	target = [self targetToFindIn];
	if ((target == nil) || [self isBusyTarget:target]) return [OgreTextFindResult textFindResultWithTarget:target thread:nil];
	[self makeTargetBusy:target];
	
	OgreTextFindThread			*thread = nil;
	OgreTextFindProgressSheet	*sheet = nil;
	OgreTextFindResult			*textFindResult = nil;
	
	NS_DURING
	
		OGRegularExpression	*regex = [OGRegularExpression regularExpressionWithString:expressionString
			options:options
			syntax:[self syntax] 
			escapeCharacter:[self escapeCharacter]];
		
		/* 処理状況表示用シートの生成 */
		sheet = [[OgreTextFindProgressSheet alloc] initWithWindow:[target window] 
			title:OgreTextFinderLocalizedString(@"Highlight") 
			didEndSelector:@selector(makeTargetFree:) 
			toTarget:self 
			withObject:target];
		
		/* スレッドの生成 */
		id	adapter = [self adapterForTarget:target];
		thread = [[[OgreHighlightThread alloc] initWithComponent:adapter] autorelease];
		[thread setRegularExpression:regex];
		[thread setHighlightColor:highlightColor];
		[thread setOptions:options];
		[thread setInSelection:inSelection];
		[thread setDidEndSelector:@selector(didEndThread:) toTarget:self];
		[thread setProgressDelegate:sheet];
		[thread setAsynchronous:YES];
		
		[thread detach];
		
		textFindResult = [OgreTextFindResult textFindResultWithTarget:target thread:thread];
		[textFindResult setType:OgreTextFindResultSuccess];
		
	NS_HANDLER
		
		textFindResult = [OgreTextFindResult textFindResultWithTarget:target thread:thread];
		[textFindResult setType:OgreTextFindResultError];
		[textFindResult setAlertSheet:sheet exception:localException];
		
	NS_ENDHANDLER
		
	return textFindResult;
}

/* selection */
- (NSString*)selectedString
{
	return [[self selectedOGString] string];
}

- (NSAttributedString*)selectedAttributedString
{
	return [[self selectedOGString] attributedString];
}

- (NSObject<OGStringProtocol>*)selectedOGString
{
	id	target = [self targetToFindIn];
	if ((target == nil) || [self isBusyTarget:target]) return nil;

	[self makeTargetBusy:target];
	OgreTextFindLeaf	*selectedLeaf = nil;
	NSObject<OGStringProtocol>			*string = nil;
	OgreTextFindResult	*textFindResult = nil;
	
	NS_DURING
	
		id	adapter = [self adapterForTarget:target];
		selectedLeaf = [adapter selectedLeaf];
		
		[selectedLeaf willProcessFinding:nil];
		string = [[selectedLeaf ogString] substringWithRange:[selectedLeaf selectedRange]];
		[selectedLeaf finalizeFinding];
		
		[self makeTargetFree:target];
		
	NS_HANDLER
		
		textFindResult = [OgreTextFindResult textFindResultWithTarget:target thread:nil];
		[textFindResult setType:OgreTextFindResultError];
		[textFindResult setAlertSheet:nil exception:localException];
		[textFindResult alertIfErrorOccurred];
		
	NS_ENDHANDLER
		
	return string;
}

- (BOOL)isSelectionEmpty
{
	id	target = [self targetToFindIn];
	if ((target == nil) || [self isBusyTarget:target]) return NO;

	[self makeTargetBusy:target];
	OgreTextFindLeaf	*selectedLeaf = nil;
	NSRange				selectedRange = NSMakeRange(0, 0);
	OgreTextFindResult	*textFindResult = nil;
	
	NS_DURING
	
		id	adapter = [self adapterForTarget:target];
		selectedLeaf = [adapter selectedLeaf];
		
		[selectedLeaf willProcessFinding:nil];
		selectedRange = [selectedLeaf selectedRange];
		[selectedLeaf finalizeFinding];
		
		[self makeTargetFree:target];
		
	NS_HANDLER
		
		textFindResult = [OgreTextFindResult textFindResultWithTarget:target thread:nil];
		[textFindResult setType:OgreTextFindResultError];
		[textFindResult setAlertSheet:nil exception:localException];
		[textFindResult alertIfErrorOccurred];
		
	NS_ENDHANDLER
		
	if (selectedRange.length > 0) return NO;
	
	return YES;
}

- (BOOL)jumpToSelection
{
	id	target = [self targetToFindIn];
	if ((target == nil) || [self isBusyTarget:target]) return NO;

	[self makeTargetBusy:target];
	OgreTextFindLeaf	*selectedLeaf = nil;
	OgreTextFindResult	*textFindResult = nil;
	
	NS_DURING
	
		id	adapter = [self adapterForTarget:target];
		selectedLeaf = [adapter selectedLeaf];
		
		[selectedLeaf willProcessFinding:nil];
		[[adapter window] makeKeyAndOrderFront:self];
		[selectedLeaf jumpToSelection];
		[selectedLeaf finalizeFinding];
		
		[self makeTargetFree:target];
		
	NS_HANDLER
		
		textFindResult = [OgreTextFindResult textFindResultWithTarget:target thread:nil];
		[textFindResult setType:OgreTextFindResultError];
		[textFindResult setAlertSheet:nil exception:localException];
		[textFindResult alertIfErrorOccurred];
		
	NS_ENDHANDLER
	
	return YES;
}

/* notify from Thread */
- (void)didEndThread:(OgreTextFindThread*)aTextFindThread
{
#ifdef DEBUG_OGRE_FIND_PANEL
	NSLog(@"-didEndThread of %@", [self className]);
#endif
	
	BOOL	shouldCloseProgressSheet = NO;
	SEL		didEndSelector = [aTextFindThread didEndSelectorForFindPanelController];
	id		result = [aTextFindThread result];
	shouldCloseProgressSheet = ([findPanelController performSelector:didEndSelector withObject:result] != nil);

	id		sheet = [aTextFindThread progressDelegate];
	
	if (shouldCloseProgressSheet) {
		// 自動的に閉じる。OKボタンではreleaseしないようにする。
		[(id <OgreTextFindProgressDelegate>)sheet setReleaseWhenOKButtonClicked:NO];
		[sheet performSelector:@selector(close:) withObject:self];
	}
	[sheet release];
}

/* alert sheet */
- (OgreTextFindProgressSheet*)alertSheetOnTarget:(id)aTerget
{
	OgreTextFindProgressSheet   *sheet = nil;
	
	if ((aTerget != nil) && ![self isBusyTarget:aTerget]) {
		[self makeTargetBusy:aTerget];
		sheet = [[OgreTextFindProgressSheet alloc] initWithWindow:[aTerget window] 
			title:@"" 
			didEndSelector:@selector(makeTargetFree:) 
			toTarget:self 
			withObject:aTerget];
	}
	
	return sheet;
}

/* Getting and registering adapters for targets */
- (id)adapterForTarget:(id)aTargetToFindIn
{
	if ([aTargetToFindIn respondsToSelector:@selector(ogreAdapter)]) return [(id <OgreView>)aTargetToFindIn ogreAdapter];
	
	Class	anAdapterClass = [self adapterClassForTargetToFindIn];
	
	if (anAdapterClass == Nil) {
		/* Searching in the adapter-target array */
		int	index, count = [_adapterClassArray count];
		for (index = count - 1; index >= 0; index--) {
			if ([aTargetToFindIn isKindOfClass:[_targetClassArray objectAtIndex:index]]) {
				anAdapterClass = [_adapterClassArray objectAtIndex:index];
				break;
			}
		}
	}
	
	return [[[anAdapterClass alloc] initWithTarget:aTargetToFindIn] autorelease];
}

- (void)registeringAdapterClass:(Class)anAdapterClass forTargetClass:(Class)aTargetClass
{
	[_adapterClassArray addObject:anAdapterClass];
	[_targetClassArray addObject:aTargetClass];
}

- (void)setAdapterClassForTargetToFindIn:(Class)adapterClass
{
	_adapterClassForTarget = adapterClass;
}

- (Class)adapterClassForTargetToFindIn;
{
	return _adapterClassForTarget;
}

- (BOOL)hasAdapterClassForObject:(id)anObject
{
	if (anObject == nil) return NO;
	
	if ([anObject respondsToSelector:@selector(ogreAdapter)]) return YES;
	
	int	index, count = [_targetClassArray count];
	for (index = count - 1; index >= 0; index--) {
		if ([anObject isKindOfClass:[_targetClassArray objectAtIndex:index]]) {
			return YES;
			break;
		}
	}
	
	return NO;
}

@end

