/*
 * Name: OgreAttachableWindowAcceptor.m
 * Project: OgreKit
 *
 * Creation Date: Aug 30 2004
 * Author: Isao Sonobe <sonoisa (AT) muse (DOT) ocn (DOT) ne (DOT) jp>
 * Copyright: Copyright (c) 2004 Isao Sonobe, All rights reserved.
 * License: OgreKit License
 *
 * Encoding: UTF8
 * Tabsize: 4
 */

#import <OgreKit/OgreAttachableWindowAcceptor.h>
#import <OgreKit/OgreAttachableWindowMediator.h>


@implementation OgreAttachableWindowAcceptor

- (void)awakeFromNib
{
	[[OgreAttachableWindowMediator sharedMediator] addAcceptor:self];	// 必須
	
	[[NSNotificationCenter defaultCenter] addObserver:self
		selector:@selector(windowWillMove:)
		name:NSWindowWillMoveNotification
		object:self];
}

#ifdef MAC_OS_X_VERSION_10_6
- (void)finalize
{
    [[NSNotificationCenter defaultCenter] removeObserver:self name:nil object:self];
	[[OgreAttachableWindowMediator sharedMediator] removeAcceptor:self];	// 必須
    [super finalize];
}
#endif

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self name:nil object:self];
	[[OgreAttachableWindowMediator sharedMediator] removeAcceptor:self];	// 必須
    [super dealloc];
}

- (BOOL)isAttachableAcceptorEdge:(NSRectEdge)edge toAcceptee:(NSWindow<OgreAttachableWindowAccepteeProtocol>*)acceptee
{
	return YES;
}

/* notifications */
- (void)windowWillMove:(id)notification
{
	[[self childWindows] makeObjectsPerformSelector:@selector(setDragging:) withObject:NO];
}

- (void)didAttachWindow:(NSWindow<OgreAttachableWindowAccepteeProtocol>*)acceptee
{
	/* do nothing */
}

- (void)didDetachWindow:(NSWindow<OgreAttachableWindowAccepteeProtocol>*)acceptee
{
	/* do nothing */
}

@end
