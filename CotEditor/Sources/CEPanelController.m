/*
 
 CEPanelController.m
 
 This class is an abstract class for panels related to document.
 
 CotEditor
 http://coteditor.com
 
 Created by 1024jp on 2014-03-18.

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

#import "CEPanelController.h"


@interface CEPanelController ()

@property (readwrite, nonatomic, nullable, weak) CEWindowController *documentWindowController;

@end




#pragma mark -

@implementation CEPanelController

static NSMutableDictionary *instances;


#pragma mark Singleton

// ------------------------------------------------------
/// return shared instance (inheritable)
+ (nonnull instancetype) sharedController
// ------------------------------------------------------
{
    // This method is based on the following article:
    // http://qiita.com/hal_sk/items/b4e51c33e7c9d29964ab
    
    __block id obj;
    @synchronized(self) {
        if (instances[NSStringFromClass(self)] == nil) {
            obj = [[self alloc] init];
        }
    }
    obj = instances[NSStringFromClass(self)];
    return obj;
}


// ------------------------------------------------------
/// allocate
+ (nonnull instancetype)allocWithZone:(nonnull NSZone *)zone
// ------------------------------------------------------
{
    // This method is based on the following article:
    // http://qiita.com/hal_sk/items/b4e51c33e7c9d29964ab
    
    @synchronized(self) {
        if (instances[NSStringFromClass(self)] == nil) {
            id instance = [super allocWithZone:zone];
            if (instances == nil) {
                instances = [NSMutableDictionary dictionary];
            }
            instances[NSStringFromClass(self)] = instance;
            return instance;
        }
    }
    return nil;
}



#pragma mark Superclass Methods

// ------------------------------------------------------
/// default initializer
- (nonnull instancetype)initWithWindow:(nullable NSWindow *)window
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
        NSNotification *notification = [NSNotification notificationWithName:NSWindowDidBecomeMainNotification object:window];
        [self windowDidBecomeMain:notification];
    }
    return self;
}


// ------------------------------------------------------
/// clean up
- (void)dealloc
// ------------------------------------------------------
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}



#pragma mark Notifications

//=======================================================
// NSWindow Notification  < window
//=======================================================

// ------------------------------------------------------
/// notification about main window change
- (void)windowDidBecomeMain:(nonnull NSNotification *)notification
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
/// invoke when frontmost document window changed (abstract)
- (void)keyDocumentDidChange
// ------------------------------------------------------
{
    // override in subclass
}

@end
