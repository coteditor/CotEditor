/*
 * Name: OgreAttachableWindowAcceptee.m
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

#import <OgreKit/OgreAttachableWindowAcceptee.h>
#import <OgreKit/OgreAttachableWindowMediator.h>


@implementation OgreAttachableWindowAcceptee

- (BOOL)dragging
{
	return _dragging;
}

- (void)setDragging:(BOOL)dragging
{
	_dragging = dragging;
}

- (BOOL)resizing
{
	return _resizing;
}

- (void)setResizing:(BOOL)resizing
{
	_resizing = resizing;
}

- (NSPoint)difference
{
	return _diff;
}

- (void)setDifference:(NSPoint)difference
{
	_diff = difference;
}

- (void)miniaturize:(id)sender
{
	[[self parentWindow] removeChildWindow:self];
	[super miniaturize:sender];
}

- (BOOL)isAttachableAccepteeEdge:(NSRectEdge)edge toAcceptor:(NSWindow<OgreAttachableWindowAcceptorProtocol>*)acceptor;
{
	return YES;
}

/* overridden methods */
- (void)close
{
	[[self parentWindow] removeChildWindow:self];
	[[self childWindows] makeObjectsPerformSelector:@selector(close)];
    [super close];
}

@end
