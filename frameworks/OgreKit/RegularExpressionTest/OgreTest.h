/*
 * Name: OgreTest.h
 * Project: OgreKit
 *
 * Creation Date: Sep 7 2003
 * Author: Isao Sonobe <sonoisa (AT) muse (DOT) ocn (DOT) ne (DOT) jp>
 * Copyright: Copyright (c) 2003 Isao Sonobe, All rights reserved.
 * License: OgreKit License
 *
 * Encoding: UTF8
 * Tabsize: 4
 */

#import <Cocoa/Cocoa.h>
#import <OgreKit/OgreKit.h>

@interface OgreTest : NSObject <OGRegularExpressionCaptureVisitor>
{
    IBOutlet NSTextField *replaceTextField;
    IBOutlet NSTextField *patternTextField;
    IBOutlet NSTextView *resultTextView;
    IBOutlet NSTextField *targetTextField;
	IBOutlet NSTextField *escapeCharacterTextField;
}
- (IBAction)match:(id)sender;
- (IBAction)replace:(id)sender;

- (void)replaceTest;
- (void)categoryTest;
- (void)captureTreeTest;

@end
