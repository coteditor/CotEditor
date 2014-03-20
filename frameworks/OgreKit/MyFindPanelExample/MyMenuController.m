/*
 * Name: MyMenuController.m
 * Project: OgreKit
 *
 * Creation Date: Oct 16 2003
 * Author: Isao Sonobe <sonoisa (AT) muse (DOT) ocn (DOT) ne (DOT) jp>
 * Copyright: Copyright (c) 2003 Isao Sonobe, All rights reserved.
 * License: OgreKit License
 *
 * Encoding: UTF8
 * Tabsize: 4
 */

#import "MyMenuController.h"
#import "MyDocument.h"

@implementation MyMenuController

/* 改行コードの変更をmain windowのdelegateに伝える (非常に手抜き) */
- (IBAction)selectCr:(id)sender
{
	[(MyDocument*)[[NSApp mainWindow] delegate] setNewlineCharacter:OgreCrNewlineCharacter];
}

- (IBAction)selectCrLf:(id)sender
{
	[(MyDocument*)[[NSApp mainWindow] delegate] setNewlineCharacter:OgreCrLfNewlineCharacter];
}

- (IBAction)selectLf:(id)sender
{
	[(MyDocument*)[[NSApp mainWindow] delegate] setNewlineCharacter:OgreLfNewlineCharacter];
}

@end
