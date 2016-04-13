/*
 
 CEDocumentController.m
 
 CotEditor
 http://coteditor.com
 
 Created by nakamuxu on 2004-12-14.

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

#import "CEDocumentController.h"
#import "CEEncodingManager.h"
#import "CEDefaults.h"
#import "CEEncodings.h"
#import "CEErrors.h"
#import "Constants.h"


// define UTIs for legacy system
//   -> They were defined first on OS X 10.10.
static const CFStringRef CEUTTypeScalableVectorGraphics = CFSTR("public.svg-image");
static const CFStringRef CEUTTypeGNUZipArchive = CFSTR("org.gnu.gnu-zip-archive");
static const CFStringRef CEUTTypeBzip2Archive = CFSTR("public.bzip2-archive");
static const CFStringRef CEUTTypeZipArchive = CFSTR("public.zip-archive");


@interface CEDocumentController ()

@property (nonatomic) BOOL showsHiddenFiles;  // binding

@property (nonatomic, nullable) IBOutlet NSView *openPanelAccessoryView;
@property (nonatomic, nullable) IBOutlet NSPopUpButton *accessoryEncodingMenu;
@property (nonatomic, nullable) IBOutlet NSButton *showHiddenFilesCheckbox;


// readonly
@property (readwrite, nonatomic) NSStringEncoding accessorySelectedEncoding;
@property (readwrite, nonatomic, nonnull) NSURL *autosaveDirectoryURL;

@end




#pragma mark -

@implementation CEDocumentController

#pragma mark Superclass Methods

// ------------------------------------------------------
/// ask if provide a window restoration
+ (void)restoreWindowWithIdentifier:(nonnull NSString *)identifier state:(nonnull NSCoder *)state completionHandler:(void (^)(NSWindow * _Nullable, NSError * _Nullable))completionHandler
// ------------------------------------------------------
{
    // do not restore document windows if Shift key is pressed. 
    if ([NSEvent modifierFlags] & NSShiftKeyMask) { return; }
    
    [super restoreWindowWithIdentifier:identifier state:state completionHandler:completionHandler];
}


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
- (nullable id)makeDocumentWithContentsOfURL:(nonnull NSURL *)url ofType:(nonnull NSString *)typeName error:(NSError * _Nullable __autoreleasing * _Nullable)outError
// ------------------------------------------------------
{
    // [caution] This method may be called from a background thread due to concurrent-opening.
    
    NSError *error = nil;
    
    // display alert if file may an image, video or other kind of binary file.
    CFStringRef typeNameRef = (__bridge CFStringRef)typeName;
    if ((UTTypeConformsTo(typeNameRef, kUTTypeImage) && !UTTypeEqual(typeNameRef, CEUTTypeScalableVectorGraphics)) ||  // SVG is plain-text (except SVGZ)
        UTTypeConformsTo(typeNameRef, kUTTypeAudiovisualContent) ||
        UTTypeConformsTo(typeNameRef, CEUTTypeGNUZipArchive) ||
        UTTypeConformsTo(typeNameRef, CEUTTypeZipArchive) ||
        UTTypeConformsTo(typeNameRef, CEUTTypeBzip2Archive))
    {
        NSString *localizedTypeName = (__bridge_transfer NSString *)UTTypeCopyDescription(typeNameRef);
        
        error = [NSError errorWithDomain:CEErrorDomain code:CEFileReadBinaryFileError
                                userInfo:@{NSLocalizedDescriptionKey: [NSString stringWithFormat:NSLocalizedString(@"The file “%@” doesn’t appear to be text data.", nil), [url lastPathComponent]],
                                           NSLocalizedRecoverySuggestionErrorKey: [NSString stringWithFormat:NSLocalizedString(@"The file is %@.\n\nDo you really want to open the file?", nil), localizedTypeName],
                                           NSLocalizedRecoveryOptionsErrorKey: @[NSLocalizedString(@"Open", nil),
                                                                                 NSLocalizedString(@"Cancel", nil)],
                                           NSRecoveryAttempterErrorKey: self,
                                           NSURLErrorKey: url,
                                           NSUnderlyingErrorKey: [NSError errorWithDomain:NSCocoaErrorDomain code:NSFileReadCorruptFileError userInfo:nil]}];
    }
    
    // display alert if file is enorm large
    NSUInteger fileSizeThreshold = [[NSUserDefaults standardUserDefaults] integerForKey:CEDefaultLargeFileAlertThresholdKey];
    if (fileSizeThreshold > 0) {
        NSNumber *fileSize = nil;
        [url getResourceValue:&fileSize forKey:NSURLFileSizeKey error:nil];
        
        if ([fileSize integerValue] > fileSizeThreshold) {
            NSByteCountFormatter *formatter = [[NSByteCountFormatter alloc] init];
            
            error = [NSError errorWithDomain:CEErrorDomain code:CEFileReadTooLargeError
                                    userInfo:@{NSLocalizedDescriptionKey: [NSString stringWithFormat:NSLocalizedString(@"The file “%@” has a size of %@.", nil),
                                                                           [url lastPathComponent],
                                                                           [formatter stringFromByteCount:[fileSize longLongValue]]],
                                               NSLocalizedRecoverySuggestionErrorKey: NSLocalizedString(@"Opening such a large file can make the application slow or unresponsive.\n\nDo you really want to open the file?", nil),
                                               NSLocalizedRecoveryOptionsErrorKey: @[NSLocalizedString(@"Open", nil),
                                                                                     NSLocalizedString(@"Cancel", nil)],
                                               NSRecoveryAttempterErrorKey: self,
                                               NSURLErrorKey: url,
                                               NSUnderlyingErrorKey: [NSError errorWithDomain:NSCocoaErrorDomain code:NSFileReadTooLargeError userInfo:nil]}];
        }
    }
    
    // ask user for opening file
    if (error) {
        __block BOOL wantsOpen = NO;
        __weak typeof(self) weakSelf = self;
        dispatch_sync_on_main_thread(^{
            wantsOpen = [weakSelf presentError:error];
        });
        // cancel operation
        if (!wantsOpen) {
            if (outError) {
                *outError = [NSError errorWithDomain:NSCocoaErrorDomain code:NSUserCancelledError userInfo:nil];
            }
            return nil;
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
- (void)beginOpenPanel:(nonnull NSOpenPanel *)openPanel forTypes:(nullable NSArray<NSString *> *)inTypes completionHandler:(nonnull void (^)(NSInteger))completionHandler
// ------------------------------------------------------
{
    // initialize encoding menu and set the accessory view
    if (![self openPanelAccessoryView]) {
        [[NSBundle mainBundle] loadNibNamed:@"OpenDocumentAccessory" owner:self topLevelObjects:nil];
        if (NSAppKitVersionNumber <= NSAppKitVersionNumber10_10_Max) {
            // real time togging of hidden files visibility works only on El Capitan (and later?)
            [[self showHiddenFilesCheckbox] removeFromSuperview];
        }
    }
    [self buildEncodingPopupButton];
    [openPanel setAccessoryView:[self openPanelAccessoryView]];
    
    // force accessory view visible
    if (NSAppKitVersionNumber > NSAppKitVersionNumber10_10_Max) {
        [openPanel setAccessoryViewDisclosed:YES];
    }
    
    // set visibility of hidden files in the panel
    [openPanel setShowsHiddenFiles:[self showsHiddenFiles]];
    [openPanel setTreatsFilePackagesAsDirectories:[self showsHiddenFiles]];
    // ->  bind showsHiddenFiles flag with openPanel (for El capitan and leter)
    [openPanel bind:@"showsHiddenFiles" toObject:self withKeyPath:@"showsHiddenFiles" options:nil];
    [openPanel bind:@"treatsFilePackagesAsDirectories" toObject:self withKeyPath:@"showsHiddenFiles" options:nil];
    
    // run non-modal open panel
    __weak typeof(self) weakSelf = self;
    [super beginOpenPanel:openPanel forTypes:inTypes completionHandler:^(NSInteger result) {
        typeof(self) self = weakSelf;  // strong self
        
        // reset encoding menu if cancelled
        if (result == NSCancelButton) {
            [self resetAccessorySelectedEncoding];
        }
        
        [self setShowsHiddenFiles:NO];  // reset flag
        
        completionHandler(result);
    }];
}


// ------------------------------------------------------
/// check if file opening is cancelled
- (BOOL)attemptRecoveryFromError:(nonnull NSError *)error optionIndex:(NSUInteger)recoveryOptionIndex
// ------------------------------------------------------
{
    if ([[error domain] isEqualToString:CEErrorDomain]) {
        switch ([error code]) {
            case CEFileReadBinaryFileError:
            case CEFileReadTooLargeError:
                return (recoveryOptionIndex == 0);
        }
    }
    
    return NO;
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
    NSArray<NSMenuItem *> *items = [[CEEncodingManager sharedManager] encodingMenuItems];
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
