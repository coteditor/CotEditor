/*
 * Name: OnigurumaTest.h
 * Project: OgreKit
 *
 * Creation Date: May 20 2004
 * Author: Isao Sonobe <sonoisa (AT) muse (DOT) ocn (DOT) ne (DOT) jp>
 * Copyright: Copyright (c) 2004 Isao Sonobe, All rights reserved.
 * License: OgreKit License
 *
 * Encoding: UTF8
 * Tabsize: 4
 */

#import <Cocoa/Cocoa.h>

@interface OnigurumaTest : NSObject
{
    IBOutlet NSTextField    *targetField;
    IBOutlet NSTextField    *regexField;
    IBOutlet NSTextView     *resultTextView;
}

- (IBAction)match:(id)sender;

@end
