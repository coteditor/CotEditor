//
//  NSString+Sandboxing.h
//
//
//  Created by Ivan Vasic on 2/3/13.
//  Copyright (c) 2013 IvanVasic. All rights reserved.
//

@import Cocoa;


@interface NSString (Sandboxing)

/**
 * @method stringByAbbreviatingWithTildeInSandboxedPath:
 * @abstract Returns a new string representing the receiver as a path with a tilde (~) substituted for the full path to the current user’s home directory.
 * @note This method should work in a sandboxed environment
 */
- (NSString *)stringByAbbreviatingWithTildeInSandboxedPath;

@end
