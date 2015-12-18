/*
 
 CEShareMenu.m
 
 CotEditor
 http://coteditor.com
 
 Created by nakamuxu on 2015-12-18.
 
 ------------------------------------------------------------------------------
 
 © 2015 1024jp
 
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

#import "CEShareMenu.h"


NSString *_Nonnull const ServiceKey = @"service";
NSString *_Nonnull const ItemsKey = @"items";


@interface CEShareMenu () <NSMenuDelegate>

@end




#pragma mark -

@implementation CEShareMenu

// ------------------------------------------------------
/// set delegate to itself
- (void)awakeFromNib
// ------------------------------------------------------
{
    [self setDelegate:self];
}



#pragma mark Menu Delegate

// ------------------------------------------------------
/// create share menu dynamically
- (void)menuWillOpen:(nonnull NSMenu *)menu
// ------------------------------------------------------
{
    [self removeAllItems];
    
    NSDocument *document = [[NSDocumentController sharedDocumentController] currentDocument];
    
    if (![document fileURL]) {
        NSString *message = (document != nil) ? @"Save the document to share": @"No document";
        NSMenuItem *item = [[NSMenuItem alloc] initWithTitle:NSLocalizedString(message, nil)
                                                      action:nil keyEquivalent:@""];
        [item setEnabled:NO];
        [self addItem:item];
        return;
    }
    
    NSArray<id> *items = @[[document fileURL]];
    NSArray<NSSharingService *> *sharingServices = [NSSharingService sharingServicesForItems:items];
    for (NSSharingService *service in sharingServices) {
        if (NSAppKitVersionNumber >= NSAppKitVersionNumber10_9) {
            [service setSubject:[document displayName]];
        }
        
        NSMenuItem *item = [[NSMenuItem alloc] initWithTitle:[service title]
                                                      action:@selector(shareFromService:)
                                               keyEquivalent:@""];
        [item setTarget:self];
        [item setImage:[service image]];
        [item setRepresentedObject:@{ServiceKey: service,
                                     ItemsKey: items}];
        
        [self addItem:item];
    }
    
}



#pragma mark Private Action Message

// ------------------------------------------------------
/// perform share
- (IBAction)shareFromService:(nullable id)sender
// ------------------------------------------------------
{
    if (![[sender representedObject] isKindOfClass:[NSDictionary class]]) { return; }
    
    NSSharingService *sharingService = [sender representedObject][ServiceKey];
    NSArray<id> *items = [sender representedObject][ItemsKey];
    
}

@end
