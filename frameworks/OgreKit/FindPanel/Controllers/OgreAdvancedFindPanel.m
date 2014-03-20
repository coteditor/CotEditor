/*
 * Name: OgreAdvancedFindPanel.m
 * Project: OgreKit
 *
 * Creation Date: Jun 22 2004
 * Author: Isao Sonobe <sonoisa (AT) muse (DOT) ocn (DOT) ne (DOT) jp>
 * Copyright: Copyright (c) 2003 Isao Sonobe, All rights reserved.
 * License: OgreKit License
 *
 * Encoding: UTF8
 * Tabsize: 4
 */

#import <OgreKit/OgreAdvancedFindPanel.h>
#import <OgreKit/OgreAdvancedFindPanelController.h>

@implementation OgreAdvancedFindPanel

- (void)flagsChanged:(NSEvent*)theEvent
{
    [(OgreAdvancedFindPanelController*)[self delegate] findPanelFlagsChanged:[theEvent modifierFlags]];
    
    [super flagsChanged:theEvent];
}

/* OgreAttachableWindowAcceptorProtocol */
- (void)addChildWindow:(NSWindow*)childWin ordered:(NSWindowOrderingMode)place
{
	[super addChildWindow:childWin ordered:place];
	[(OgreAdvancedFindPanelController*)[self delegate] findPanelDidAddChildWindow:childWin];
}

- (void)removeChildWindow:(NSWindow*)childWin
{
	[super removeChildWindow:childWin];
	[(OgreAdvancedFindPanelController*)[self delegate] findPanelDidRemoveChildWindow:childWin];
}

- (BOOL)isAttachableAcceptorEdge:(NSRectEdge)edge toAcceptee:(NSWindow<OgreAttachableWindowAccepteeProtocol>*)acceptee
{
	switch (edge) {
		case NSMinYEdge:
			return ([[self childWindows] count] == 0 || [[self childWindows] containsObject:acceptee]);
		case NSMaxYEdge:
		case NSMaxXEdge:
		case NSMinXEdge:
		default:
			return NO;
	}
}

@end
