/*
 ==============================================================================
 CEScriptMenuItem
 
 CotEditor
 http://coteditor.github.io
 
 Created on 2014-10-02 by 1024jp
 encoding="UTF-8"
 ------------------------------------------------------------------------------
 
 © 2014 CotEditor Project
 
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

#import "CEScriptMenuItem.h"


@implementation CEScriptMenuItem

#pragma mark Superclass Methods

// ------------------------------------------------------
// init
- (instancetype)initWithCoder:(NSCoder *)aDecoder
// ------------------------------------------------------
{
    self = [super initWithCoder:aDecoder];
    if (self) {
        if (floor(NSAppKitVersionNumber) > 1265) {  // 1265 = NSAppKitVersionNumber10_9
            [self updateIcon];
            
            // observe menu bar theme change on Yosemite
            [[NSDistributedNotificationCenter defaultCenter] addObserver:self
                                                                selector:@selector(updateIcon)
                                                                    name:@"AppleInterfaceThemeChangedNotification"
                                                                  object:nil];
        }
    }
    return self;
}



#pragma mark Private Methods

// ------------------------------------------------------
/// update script icon (for Yosemite's dark mode)
- (void)updateIcon
// ------------------------------------------------------
{
    NSDictionary *globalDefaults = [[NSUserDefaults standardUserDefaults] persistentDomainForName:NSGlobalDomain];
    NSString *theme = globalDefaults[@"AppleInterfaceStyle"];
    
    NSString *imageName = [theme isEqualToString:@"Dark"] ? @"ScriptWhite" : @"ScriptTemplate";
    NSImage *scriptIcon = [NSImage imageNamed:imageName];
    
    [self setImage:scriptIcon];
}

@end
