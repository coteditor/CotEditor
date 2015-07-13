//
//  NSString+Sandboxing.m
//
//
//  Created by Ivan Vasic on 2/3/13.
//  Copyright (c) 2013 IvanVasic. All rights reserved.
//

#import "NSString+Sandboxing.h"
#include <sys/types.h>
#include <pwd.h>


@implementation NSString (Sandboxing)

+ (NSString *)homeDirectory
{
    const struct passwd *passwd = getpwnam([NSUserName() UTF8String]);
    if (!passwd) {
        return nil;
    }
    
    const char *homeDir = getpwnam([NSUserName() UTF8String])->pw_dir;
    return [[NSFileManager defaultManager] stringWithFileSystemRepresentation:homeDir length:strlen(homeDir)];
}


- (NSString *)stringByAbbreviatingWithTildeInSandboxedPath
{
    NSString *homeDir = [NSString homeDirectory];
    if (![self hasPrefix:homeDir]) {
        return [self copy];
    }
    
    return [self stringByReplacingOccurrencesOfString:homeDir withString:@"~" options:0 range:NSMakeRange(0, [homeDir length])];
}

@end
