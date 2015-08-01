/*
 
 CEDocumentController.m
 
 CotEditor
 http://coteditor.com
 
 Created by nakamuxu on 2004-12-14.

 ------------------------------------------------------------------------------
 
 © 2004-2007 nakamuxu
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

#import "CEDocumentController.h"
#import "CEEncodingManager.h"
#import "Constants.h"


@interface CEDocumentController ()

@property (nonatomic) BOOL showsHiddenFiles;

@property (nonatomic, nullable) IBOutlet NSView *openPanelAccessoryView;
@property (nonatomic, nullable) IBOutlet NSPopUpButton *accessoryEncodingMenu;


// readonly
@property (readwrite, nonatomic) NSStringEncoding accessorySelectedEncoding;
@property (readwrite, nonatomic, nonnull) NSURL *autosaveDirectoryURL;

@end




#pragma mark -

@implementation CEDocumentController

#pragma mark Superclass Methods

// ------------------------------------------------------
/// inizialize instance
- (nonnull instancetype)init
// ------------------------------------------------------
{
    // [caution] This method can be called before the userDefaults are initialized.
    
    self = [super init];
    if (self) {
        _accessorySelectedEncoding = (NSStringEncoding)[[NSUserDefaults standardUserDefaults] integerForKey:CEDefaultEncodingInOpenKey];
        
        _autosaveDirectoryURL = [[NSFileManager defaultManager] URLForDirectory:NSAutosavedInformationDirectory
                                                                       inDomain:NSUserDomainMask
                                                              appropriateForURL:nil
                                                                         create:YES
                                                                          error:nil];
    }
    return self;
}


// ------------------------------------------------------
/// time interval for periodic autosaving in seconds
- (NSTimeInterval)autosavingDelay
// ------------------------------------------------------
{
    // [note] Better not to set this `autosavingDelay` on the documentController's `init`,
    //        since the `init` can be invoked before the userDefaults are initialized with the default values in CEAppDelegate.
    return (NSTimeInterval)[[NSUserDefaults standardUserDefaults] doubleForKey:CEDefaultAutosavingDelayKey];
}


// ------------------------------------------------------
/// check file before creating a new document instance
- (nullable id)makeDocumentWithContentsOfURL:(nonnull NSURL *)url ofType:(nonnull NSString *)typeName error:(NSError *__autoreleasing __nullable *)outError
// ------------------------------------------------------
{
    // display alert if file is enorm large
    NSUInteger fileSizeThreshold = [[NSUserDefaults standardUserDefaults] integerForKey:CEDefaultLargeFileAlertThresholdKey];
    if (fileSizeThreshold > 0) {
        NSNumber *fileSize = nil;
        [url getResourceValue:&fileSize forKey:NSURLFileSizeKey error:nil];
        
        if ([fileSize integerValue] > fileSizeThreshold) {
            NSByteCountFormatter *formatter = [[NSByteCountFormatter alloc] init];
            
            NSAlert *alert = [[NSAlert alloc] init];
            [alert setMessageText:[NSString stringWithFormat:NSLocalizedString(@"The file “%@” has a size of %@.", nil),
                                   [url lastPathComponent],
                                   [formatter stringFromByteCount:[fileSize longLongValue]]]];
            [alert setInformativeText:NSLocalizedString(@"Opening such a large file can make the application slow or unresponsive.\n\nDo you really want to open the file?", nil)];
            [alert addButtonWithTitle:NSLocalizedString(@"Open", nil)];
            [alert addButtonWithTitle:NSLocalizedString(@"Cancel", nil)];
            
            // cancel operation
            if ([alert runModal] == NSAlertSecondButtonReturn) {
                *outError = [NSError errorWithDomain:NSCocoaErrorDomain code:NSUserCancelledError userInfo:nil];
                return nil;
            }
        }
    }
    
    // let super make document
    id document = [super makeDocumentWithContentsOfURL:url ofType:typeName error:outError];
    
    // reset encoding menu
    [self resetAccessorySelectedEncoding];
    
    return document;
}


// ------------------------------------------------------
/// add encoding menu to open panel
- (void)beginOpenPanel:(nonnull NSOpenPanel *)openPanel forTypes:(nullable NSArray *)inTypes completionHandler:(void (^ __nonnull)(NSInteger))completionHandler
// ------------------------------------------------------
{
    // initialize encoding menu and set the accessory view
    if (![self openPanelAccessoryView]) {
        [[NSBundle mainBundle] loadNibNamed:@"OpenDocumentAccessory" owner:self topLevelObjects:nil];
    }
    [self buildEncodingPopupButton];
    [openPanel setAccessoryView:[self openPanelAccessoryView]];
    
    // set visibility of the hidden files
    [openPanel setTreatsFilePackagesAsDirectories:[self showsHiddenFiles]];
    [openPanel setShowsHiddenFiles:[self showsHiddenFiles]];
    [self setShowsHiddenFiles:NO];  // reset flag
    
    // run non-modal open panel
    __weak typeof(self) weakSelf = self;
    [super beginOpenPanel:openPanel forTypes:inTypes completionHandler:^(NSInteger result) {
        // reset encoding menu if cancelled
        if (result == NSCancelButton) {
            [weakSelf resetAccessorySelectedEncoding];
        }
        
        completionHandler(result);
    }];
}



#pragma mark Action Messages

// ------------------------------------------------------
/// show open panel displaying hidden files
- (IBAction)openHiddenDocument:(nullable id)sender
// ------------------------------------------------------
{
    [self setShowsHiddenFiles:YES];
    
    [self openDocument:sender];
}



#pragma mark Private Methods

// ------------------------------------------------------
/// update encoding menu in the open panel
- (void)buildEncodingPopupButton
// ------------------------------------------------------
{
    NSArray *items = [[CEEncodingManager sharedManager] encodingMenuItems];
    NSMenu *menu = [[self accessoryEncodingMenu] menu];
    
    [menu removeAllItems];
    
    [menu addItemWithTitle:NSLocalizedString(@"Auto-Detect", nil) action:NULL keyEquivalent:@""];
    [[menu itemAtIndex:0] setTag:CEAutoDetectEncoding];
    [menu addItem:[NSMenuItem separatorItem]];
    
    for (NSMenuItem *item in items) {
        [menu addItem:item];
    }
    
    [self resetAccessorySelectedEncoding];
}


// ------------------------------------------------------
/// reset selection of the encoding menu
- (void)resetAccessorySelectedEncoding
// ------------------------------------------------------
{
    NSStringEncoding defaultEncoding = (NSStringEncoding)[[NSUserDefaults standardUserDefaults] integerForKey:CEDefaultEncodingInOpenKey];
    
    __weak typeof(self) weakSelf = self;
    dispatch_async(dispatch_get_main_queue(), ^{
        [weakSelf setAccessorySelectedEncoding:defaultEncoding];
    });
}

@end
