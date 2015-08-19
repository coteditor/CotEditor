/*
 
 NSWindow+ScriptingSupport.m
 
 CotEditor
 http://coteditor.com
 
 Created by 1024jp on 2014-03-12.

 ------------------------------------------------------------------------------
 
 © 2014-2015 1024jp
 
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

#import "NSWindow+ScriptingSupport.h"
#import "CEWindow.h"


@implementation NSWindow (ScriptingSupport)

#pragma mark AppleScript Accessores

// ------------------------------------------------------
/// return opacity of the editor view (real type)
- (nonnull NSNumber *)viewOpacity
// ------------------------------------------------------
{
    if ([self isDocumentWindow]) {
        return @([(CEWindow *)self backgroundAlpha]);
    }
    
    return @1.0;
}


// ------------------------------------------------------
/// set opacity of the editor view
- (void)setViewOpacity:(nonnull NSNumber *)viewOpacity
// ------------------------------------------------------
{
    if ([self isDocumentWindow]) {
        [(CEWindow *)self setBackgroundAlpha:(CGFloat)[viewOpacity doubleValue]];
    }
}



#pragma mark Private Methods

// ------------------------------------------------------
/// 自身が CEWindowController の支配下のウインドウかどうか
- (BOOL)isDocumentWindow
// ------------------------------------------------------
{
    return [self isKindOfClass:[CEWindow class]];
}

@end
