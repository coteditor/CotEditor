/*
 =================================================
 CEPanelController
 (for CotEditor)
 
 Copyright (C) 2014 CotEditor Project
 http://coteditor.github.io
 =================================================
 
 encoding="UTF-8"
 Created:2014-03-18 by 1024jp
 
 This class is an abstract class for panels related to document.
 
 -------------------------------------------------
 
 This program is free software; you can redistribute it and/or
 modify it under the terms of the GNU General Public License
 as published by the Free Software Foundation; either version 2
 of the License, or (at your option) any later version.
 
 This program is distributed in the hope that it will be useful,
 but WITHOUT ANY WARRANTY; without even the implied warranty of
 MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 GNU General Public License for more details.
 
 You should have received a copy of the GNU General Public License
 along with this program; if not, write to the Free Software
 Foundation, Inc., 59 Temple Place - Suite 330, Boston, MA  02111-1307, USA.
 
 
 =================================================
 */

#import "CEPanelController.h"


@interface CEPanelController ()

@property (nonatomic, weak, readwrite) CEWindowController *documentWindowController;

@end




#pragma mark -

@implementation CEPanelController

static NSMutableDictionary *instances;


#pragma mark Class Methods

// ------------------------------------------------------
+ (instancetype) sharedController
// return shared instance
// ------------------------------------------------------
{
    // This method is based on the following article:
    // http://qiita.com/hal_sk/items/b4e51c33e7c9d29964ab
    
    __block id obj;
    @synchronized(self) {
        if ([instances objectForKey:NSStringFromClass(self)] == nil) {
            obj = [[self alloc] init];
        }
    }
    obj = [instances objectForKey:NSStringFromClass(self)];
    return obj;
}


// ------------------------------------------------------
+ (instancetype)allocWithZone:(NSZone *)zone
// allocate
// ------------------------------------------------------
{
    // This method is based on the following article:
    // http://qiita.com/hal_sk/items/b4e51c33e7c9d29964ab
    
    @synchronized(self) {
        if ([instances objectForKey:NSStringFromClass(self)] == nil) {
            id instance = [super allocWithZone:zone];
            if (instances == nil) {
                instances = [[NSMutableDictionary alloc] initWithCapacity:0];
            }
            [instances setObject:instance forKey:NSStringFromClass(self)];
            return instance;
        }
    }
    return nil;
}



#pragma mark Superclass Methods

// ------------------------------------------------------
- (instancetype)initWithWindow:(NSWindow *)window
// default initializer
// ------------------------------------------------------
{
    self = [super initWithWindow:window];
    if (self) {
        // observe key window change
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(windowDidBecomeMain:)
                                                     name:NSWindowDidBecomeMainNotification
                                                   object:nil];
        // apply current window
        [self windowDidBecomeMain:nil];
    }
    return self;
}


// ------------------------------------------------------
- (void)dealloc
// clean up
// ------------------------------------------------------
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}



#pragma mark Notifications

//=======================================================
// Notification method (NSWindow)
//  <== NSWindow
//=======================================================

// ------------------------------------------------------
- (void)windowDidBecomeMain:(NSNotification *)notification
// notification about main window change
// ------------------------------------------------------
{
    // update properties if the new main window is a document window
    if ([[[NSApp mainWindow] windowController] isKindOfClass:[CEWindowController class]]) {
        [self setDocumentWindowController:(CEWindowController *)[[NSApp mainWindow] windowController]];
        
        [self keyDocumentDidChange];
    }
}



#pragma mark Abstract Methods

// ------------------------------------------------------
- (void)keyDocumentDidChange
// invoke when frontmost document window changed (abstract)
// ------------------------------------------------------
{
    // override in subclass
}

@end
