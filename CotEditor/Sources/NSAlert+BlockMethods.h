//
//  NSAlert+BlockMethods.h
//
//  Created by Jakob Egger on 22/11/13.
//
// cf. https://github.com/jakob/NSAlertBlockMethods

@import Cocoa;


/// a category to use a block based API on OS X before Mavericks.
@interface NSAlert (BlockMethods)

-(void)compatibleBeginSheetModalForWindow:(nonnull NSWindow *)sheetWindow completionHandler:(nullable void (^)(NSInteger returnCode))handler;

@end
