/*
 
 NSURL+CEAdditions.m
 
 CotEditor
 http://coteditor.com
 
 Created by 1024jp on 2016-06-10.
 
 ------------------------------------------------------------------------------
 
 © 2004-2007 nakamuxu
 © 2014-2016 1024jp
 
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

#import "NSURL+CEAdditions.h"


@implementation NSURL (CEAdditions)

// ------------------------------------------------------
/// return relative-path string
- (nullable NSString *)pathRelativeToURL:(nullable NSURL *)baseURL
// ------------------------------------------------------
{
    if (!baseURL || [baseURL isEqual:self]) { return nil; }
    
    NSArray<NSString *> *pathComponents = [self pathComponents];
    NSArray<NSString *> *basePathComponents = [baseURL pathComponents];
    
    NSUInteger sameCount = 0;
    NSUInteger parentCount = 0;
    NSUInteger baseCompnentsCount = [basePathComponents count];
    NSUInteger compnentsCount = [pathComponents count];
    
    for (NSUInteger i = 0; i < baseCompnentsCount; i++) {
        if ([basePathComponents[i] isEqualToString:pathComponents[i]]) { continue; }
        
        sameCount = i;
        parentCount = baseCompnentsCount - sameCount - 1;
        break;
    }
    
    NSMutableArray<NSString *> *relativeComponents = [NSMutableArray array];
    for (NSUInteger _ = 0; _ < parentCount; _++) {
        [relativeComponents addObject:@".."];
    }
    for (NSUInteger i = sameCount; i < compnentsCount; i++) {
        [relativeComponents addObject:pathComponents[i]];
    }
    
    return [[NSURL fileURLWithPathComponents:relativeComponents] relativePath];
}

@end
