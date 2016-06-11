/*
 
 CESettingManager.m
 
 CotEditor
 http://coteditor.com
 
 Created by 1024jp on 2016-06-11.
 
 ------------------------------------------------------------------------------
 
 © 2016 1024jp
 
 Licensed under the Apache License, Version 2.0 (the "License");
 you may not use this file except in compliance with the License.
 You may obtain a copy of the License at
 
 http://www.apache.org/licenses/LICENSE-2.0
 
 Unless required by applicable law or agreed to in writing, software
 distributed under the License is distributed on an "AS IS" BASIS,
 WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 See the License for the specific language governing permissions and
 limitations under the License.
 
 */

#import "CESettingManager.h"


@interface CESettingManager ()

@end




#pragma mark -

@implementation CESettingManager

#pragma mark Public Methods

//------------------------------------------------------
/// directory name in both Application Support and bundled Resources
- (nonnull NSString *)directoryName
//------------------------------------------------------
{
    @throw nil;
}


//------------------------------------------------------
/// user setting directory URL in Application Support
- (nonnull NSURL *)userSettingDirectoryURL
//------------------------------------------------------
{
    return [[[self class] supportDirectoryURL] URLByAppendingPathComponent:[self directoryName]];
}


//------------------------------------------------------
/// create user setting directory if not yet exist
- (BOOL)prepareUserSettingDirectory
//------------------------------------------------------
{
    BOOL success = NO;
    NSURL *URL = [self userSettingDirectoryURL];
    NSNumber *isDirectory;
    
    if (![URL getResourceValue:&isDirectory forKey:NSURLIsDirectoryKey error:nil]) {
        success = [[NSFileManager defaultManager] createDirectoryAtURL:URL
                                           withIntermediateDirectories:YES attributes:nil error:nil];
    } else {
        success = [isDirectory boolValue];
    }
    
    if (!success) {
        NSLog(@"failed to create a directory at \"%@\".", URL);
    }
    
    return success;
}



#pragma mark Private Methods

// ------------------------------------------------------
/// application's support directory in user's `Application Suuport/`
+ (nonnull NSURL *)supportDirectoryURL
// ------------------------------------------------------
{
    static dispatch_once_t onceToken;
    static NSURL *supportDirectoryURL = nil;
    
    dispatch_once(&onceToken, ^{
        supportDirectoryURL = [[[NSFileManager defaultManager] URLForDirectory:NSApplicationSupportDirectory
                                                                      inDomain:NSUserDomainMask
                                                             appropriateForURL:nil
                                                                        create:NO
                                                                         error:nil]
                               URLByAppendingPathComponent:@"CotEditor"];
    });
    
    return supportDirectoryURL;
}

@end
