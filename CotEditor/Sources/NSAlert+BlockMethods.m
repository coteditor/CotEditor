//
//  NSAlert+BlockMethods.m
//
//  Created by Jakob Egger on 22/11/13.
//

#import "NSAlert+BlockMethods.h"

@implementation NSAlert (BlockMethods)

-(void)compatibleBeginSheetModalForWindow:(nonnull NSWindow *)sheetWindow completionHandler:(nullable void (^)(NSInteger returnCode))handler
{
	[self beginSheetModalForWindow:sheetWindow
					 modalDelegate:self
					didEndSelector:@selector(blockBasedAlertDidEnd:returnCode:contextInfo:)
					   contextInfo:(__bridge_retained void *)[handler copy] ];
}


- (void) blockBasedAlertDidEnd:(NSAlert *)alert returnCode:(NSInteger)returnCode contextInfo:(void *)contextInfo
{
	void(^handler)(NSInteger) = (__bridge_transfer void(^)(NSInteger))contextInfo;
    if (handler) {
        handler(returnCode);
    }
}

@end
