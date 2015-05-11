/*
 ==============================================================================
 NSWindow+ScriptingSupport
 
 CotEditor
 http://coteditor.com
 
 Created:2014-03-12 by 1024jp
 encoding="UTF-8"
 ------------------------------------------------------------------------------
 
 © 2014-2015 1024jp
 
 This program is free software; you can redistribute it and/or modify it under
 the terms of the GNU General Public License as published by the Free Software
 Foundation; either version 2 of the License, or (at your option) any later
 version.
 
 This program is distributed in the hope that it will be useful, but WITHOUT
 ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS
 FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.
 
 You should have received a copy of the GNU General Public License along with
 this program; if not, write to the Free Software Foundation, Inc., 59 Temple
 Place - Suite 330, Boston, MA  02111-1307, USA.
 
 ==============================================================================
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
