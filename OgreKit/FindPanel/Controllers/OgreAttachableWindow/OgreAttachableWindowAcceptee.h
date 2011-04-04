/*
 * Name: OgreAttachableWindowAcceptee.h
 * Project: OgreKit
 *
 * Creation Date: Aug 31 2004
 * Author: Isao Sonobe <sonoisa (AT) muse (DOT) ocn (DOT) ne (DOT) jp>
 * Copyright: Copyright (c) 2004 Isao Sonobe, All rights reserved.
 * License: OgreKit License
 *
 * Encoding: UTF8
 * Tabsize: 4
 */

#import <Cocoa/Cocoa.h>

@protocol OgreAttachableWindowAcceptorProtocol;

@protocol OgreAttachableWindowAccepteeProtocol
- (BOOL)dragging;
- (void)setDragging:(BOOL)dragging;
- (BOOL)resizing;
- (void)setResizing:(BOOL)resizing;
- (NSPoint)difference;
- (void)setDifference:(NSPoint)difference;
- (BOOL)isAttachableAccepteeEdge:(NSRectEdge)edge toAcceptor:(NSWindow<OgreAttachableWindowAcceptorProtocol>*)acceptor;
@end

@interface OgreAttachableWindowAcceptee : NSPanel <OgreAttachableWindowAccepteeProtocol>
{
	BOOL	_dragging;
	BOOL	_resizing;
	NSPoint	_diff;
}

@end
