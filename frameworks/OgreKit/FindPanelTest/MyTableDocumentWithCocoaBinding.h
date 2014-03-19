/*
 * Name: MyTableDocumentWithCocoaBinding.h
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

#import <AppKit/AppKit.h>
#import <OgreKit/OgreKit.h>

@interface MyTableDocumentWithCocoaBinding : NSDocument <OgreTextFindDataSource>
{
	IBOutlet NSTableView    *tableView;
	OgreNewlineCharacter	_newlineCharacter;	// 改行コードの種類
    
    NSMutableArray  *_modelArray;
}

// 改行コードの変更
- (void)setNewlineCharacter:(OgreNewlineCharacter)aNewlineCharacter;

- (IBAction)dump:(id)sender;

@end
