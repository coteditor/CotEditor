/*
 * Name: MyMenuController.h
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

#import <Cocoa/Cocoa.h>

@interface MyMenuController : NSObject
{
}
- (IBAction)selectCr:(id)sender;
- (IBAction)selectCrLf:(id)sender;
- (IBAction)selectLf:(id)sender;
@end
