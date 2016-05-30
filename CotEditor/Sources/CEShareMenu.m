/*
 
 CEShareMenu.m
 
 CotEditor
 http://coteditor.com
 
 Created by nakamuxu on 2015-12-18.
 
 ------------------------------------------------------------------------------
 
 © 2015-2016 1024jp
 
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
#import "CEDocument.h"


// keys
NSString *_Nonnull const ServiceKey = @"service";
NSString *_Nonnull const ItemsKey = @"items";

// undefined service names
NSString *_Nonnull const SharingServiceNameAddToNotes = @"com.apple.Notes.SharingExtension";
NSString *_Nonnull const SharingServiceNameAddToRemainder = @"com.apple.reminders.RemindersShareExtension";


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
    
    if (!document) {
        NSMenuItem *item = [[NSMenuItem alloc] initWithTitle:NSLocalizedString(@"No document", nil)
                                                      action:nil keyEquivalent:@""];
        [item setEnabled:NO];
        [self addItem:item];
        return;
    }
    
    if ([document fileURL]) {
        [self addSharingItems:@[[document fileURL]]
                  displayName:[document displayName]
                        label:NSLocalizedString(@"File", nil)
            excludingSercives:@[SharingServiceNameAddToNotes]];
        [self addItem:[NSMenuItem separatorItem]];
    }
    
    [self addSharingItems:@[[(CEDocument *)document string]]
              displayName:[document displayName]
                    label:NSLocalizedString(@"Text", nil)
        excludingSercives:@[NSSharingServiceNamePostOnTwitter,
                            NSSharingServiceNameComposeMessage,
                            SharingServiceNameAddToRemainder]];
}



#pragma mark Private Methods

// ------------------------------------------------------
/// perform share
- (IBAction)shareFromService:(nullable id)sender
// ------------------------------------------------------
{
    if (![[sender representedObject] isKindOfClass:[NSDictionary class]]) { return; }
    
    NSSharingService *sharingService = [sender representedObject][ServiceKey];
    NSArray<id> *items = [sender representedObject][ItemsKey];
    
    [sharingService performWithItems:items];
}


// ------------------------------------------------------
/// append sharing menu items
- (void)addSharingItems:(nonnull NSArray<id> *)items displayName:(nullable NSString *)displayName label:(nonnull NSString *)label excludingSercives:(nonnull NSArray<NSString *> *)excludingServiceNames
// ------------------------------------------------------
{
    NSMenuItem *labelItem = [[NSMenuItem alloc] initWithTitle:label action:nil keyEquivalent:@""];
    [labelItem setEnabled:NO];
    [self addItem:labelItem];
    
    // create service to skip
    NSMutableArray<NSSharingService *> *excludingServices = [NSMutableArray arrayWithCapacity:[excludingServiceNames count]];
    for (NSString *serviceName in excludingServiceNames) {
        NSSharingService *service = [NSSharingService sharingServiceNamed:serviceName];
        if (service) {
            [excludingServices addObject:service];
        }
    }
    
    // add menu items dynamically
    for (NSSharingService *service in [NSSharingService sharingServicesForItems:items]) {
        if ([excludingServices containsObject:service]) { continue; }
        
        [service setSubject:displayName];
        
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

@end
