/*
 * Name: OgreTextFindProgressDelegate.h
 * Project: OgreKit
 *
 * Creation Date: Mar 06 2010
 * Author: Isao Sonobe <sonoisa (AT) muse (DOT) ocn (DOT) ne (DOT) jp>
 * Copyright: Copyright (c) 2010 Isao Sonobe, All rights reserved.
 * License: OgreKit License
 *
 * Encoding: UTF8
 * Tabsize: 4
 */

#import <Cocoa/Cocoa.h>

@protocol OgreTextFindProgressDelegate 
// show progress
- (void)setProgress:(double)progression message:(NSString*)message; // progression < 0: indeterminate
- (void)setDonePerTotalMessage:(NSString*)message;
// finish
- (void)done:(double)progression message:(NSString*)message; // progression < 0: indeterminate

// close
- (void)close:(id)sender;
- (void)setReleaseWhenOKButtonClicked:(BOOL)shouldRelease;

// cancel
- (void)setCancelSelector:(SEL)aSelector toTarget:(id)aTarget withObject:(id)anObject;

// show error alert
- (void)showErrorAlert:(NSString*)title message:(NSString*)errorMessage;
@end
