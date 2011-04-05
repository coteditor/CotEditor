/*
 * Name: OgreFindPanelController.m
 * Project: OgreKit
 *
 * Creation Date: Sep 13 2003
 * Author: Isao Sonobe <sonoisa (AT) muse (DOT) ocn (DOT) ne (DOT) jp>
 * Copyright: Copyright (c) 2003 Isao Sonobe, All rights reserved.
 * License: OgreKit License
 *
 * Encoding: UTF8
 * Tabsize: 4
 */

#import <OgreKit/OgreTextFinder.h>
#import <OgreKit/OgreFindPanelController.h>

@implementation OgreFindPanelController

- (void)awakeFromNib
{
	/* 前回のFind Panelの位置を再現 */
    [[self findPanel] setFrameAutosaveName: @"Find Panel"];
    [[self findPanel] setFrameUsingName: @"Find Panel"];
}

- (OgreTextFinder*)textFinder
{
	return textFinder;
}

- (void)setTextFinder:(OgreTextFinder*)aTextFinder
{
	textFinder = aTextFinder;
}


- (IBAction)showFindPanel:(id)sender
{
	[findPanel makeKeyAndOrderFront:self];
	// WindowsメニューにFind Panelを追加
	[NSApp addWindowsItem:findPanel title:[findPanel title] filename:NO];
}

- (void)close
{
	[findPanel orderOut:self];
}

- (NSPanel*)findPanel
{
	return findPanel;
}

- (void)setFindPanel:(NSPanel*)aPanel
{
	[aPanel retain];
	[findPanel release];
	findPanel = aPanel;
}

// NSCoding protocols
- (NSDictionary*)history
{
	/* 履歴等を保存したい場合は、NSDictionaryで返す。 */
	return [NSDictionary dictionary];
}

@end
