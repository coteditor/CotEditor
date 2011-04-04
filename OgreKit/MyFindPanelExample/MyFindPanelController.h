/*
 * Name: MyFindPanelController.h
 * Project: OgreKit
 *
 * Creation Date: Nov 21 2003
 * Author: Isao Sonobe <sonoisa (AT) muse (DOT) ocn (DOT) ne (DOT) jp>
 * Copyright: Copyright (c) 2003 Isao Sonobe, All rights reserved.
 * License: OgreKit License
 *
 * Encoding: UTF8
 * Tabsize: 4
 */

#import <Foundation/Foundation.h>
#import <OgreKit/OgreKit.h>

@interface MyFindPanelController : OgreFindPanelController 
{
	IBOutlet id findTextField;
	IBOutlet id optionIgnoreCase;
	IBOutlet id optionRegex;
	IBOutlet id replaceTextField;
	IBOutlet id scopeMatrix;
	
	NSString	*_findHistory;
	NSString	*_replaceHistory;
}

- (IBAction)findNext:(id)sender;
- (IBAction)findPrevious:(id)sender;
- (IBAction)replace:(id)sender;
- (IBAction)replaceAll:(id)sender;
- (IBAction)replaceAndFind:(id)sender;
- (IBAction)jumpToSelection:(id)sender;
- (IBAction)useSelectionForFind:(id)sender;

- (unsigned)options;
- (OgreSyntax)syntax;
- (BOOL)isEntire;

// ìKêÿÇ»ê≥ãKï\åªÇ©Ç«Ç§Ç©í≤Ç◊ÇÈ
- (BOOL)alertIfInvalidRegex;

// óöóÇÃïúãA
- (void)restoreHistory:(NSDictionary*)history;

@end
