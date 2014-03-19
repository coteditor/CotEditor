/*
 * Name: OgreAFPCOptionButton.m
 * Project: OgreKit
 *
 * Creation Date: Sep 27 2004
 * Author: Isao Sonobe <sonoisa (AT) muse (DOT) ocn (DOT) ne (DOT) jp>
 * Copyright: Copyright (c) 2004 Isao Sonobe, All rights reserved.
 * License: OgreKit License
 *
 * Encoding: UTF8
 * Tabsize: 4
 */

#import <OgreKit/OgreAFPCOptionButton.h>


@implementation OgreAFPCOptionButton

/*- (id)init
{
	self = [super init];
	if (self != nil) {
		[self setEnabled:NO];
		[super setState:NSOnState];
	}
	return self;
}

- (void)awakeFromNib
{
	[self setEnabled:[self isEnabled]];
	[self setState:[self state]];
}

- (void)setEnabled:(BOOL)flag
{
	//NSLog(@"-[%@ setEnabled: %@]", [self title], (flag? @"YES" : @"NO"));
	[super setEnabled:flag];
	int	state = [self state];
	[self setAllowsMixedState:!flag];
	[self setState:state];
}

- (void)setState:(int)value
{
	//NSLog(@"-[%@ setState: %d]", [self title], value);
	int	newValue = value;
	if (![self isEnabled]) {
		[self setAllowsMixedState:YES];
		if (value != NSOffState) {
			newValue = NSMixedState;
		}
	} else {
		[self setAllowsMixedState:NO];
	}
	
	//NSLog(@"new value = %d", newValue);
	[super setState:newValue];
}

- (int)state
{
	int	value;
	if ([super state] == NSOffState) {
		value = NSOffState;
	} else {
		value = NSOnState;
	}
	
	return value;
}*/

@end
