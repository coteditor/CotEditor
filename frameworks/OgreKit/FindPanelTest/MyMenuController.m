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

/* 新規ドキュメント */
- (IBAction)newTextDocument:(id)sender
{
    [[NSDocumentController sharedDocumentController] openUntitledDocumentOfType:@"MyTextDocumentType" display:YES];
}

- (IBAction)newRTFDocument:(id)sender
{
    [[NSDocumentController sharedDocumentController] openUntitledDocumentOfType:@"MyRTFDocumentType" display:YES];
}

- (IBAction)newTableDocument:(id)sender
{
    [[NSDocumentController sharedDocumentController] openUntitledDocumentOfType:@"MyTableDocumentType" display:YES];
}

- (IBAction)newOutlineDocument:(id)sender
{
    [[NSDocumentController sharedDocumentController] openUntitledDocumentOfType:@"MyOutlineDocumentType" display:YES];
}

- (IBAction)newTableDocumentWithCocoaBinding:(id)sender
{
    [[NSDocumentController sharedDocumentController] openUntitledDocumentOfType:@"MyTableDocumentWithCocoaBindingType" display:YES];
}


- (void)awakeFromNib
{
    [NSApp setDelegate:self];
}

- (BOOL)applicationShouldOpenUntitledFile:(NSApplication*)sender
{
    return NO;
}

- (void)ogreKitWillHackFindMenu:(OgreTextFinder*)textFinder
{
	[textFinder setShouldHackFindMenu:YES];
}

- (void)ogreKitShouldUseStylesInFindPanel:(OgreTextFinder*)textFinder
{
	[textFinder setUseStylesInFindPanel:YES];
}

@end
